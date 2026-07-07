//! Adapter that converts the swift-syntax JSON tree (see [`crate::parse_to_json`])
//! into a [`yeast::Ast`], the in-memory format the CodeQL desugaring rules
//! operate on.
//!
//! The mapping mirrors tree-sitter's node model, which is what yeast (and the
//! extractor's rewrite rules) expect:
//!
//! * **Layout nodes** (e.g. `functionDecl`) and **varying tokens** (identifiers,
//!   literals, operators — the ones whose text is not determined by their kind)
//!   become **named** nodes, keyed by their kind name.
//! * **Fixed tokens** (keywords and punctuation, whose text is fully determined
//!   by their kind) become **anonymous** nodes, keyed by their text — exactly
//!   how tree-sitter models anonymous tokens (e.g. `"func"`, `"->"`).
//! * Collection nodes are already elided to JSON arrays upstream, so a
//!   list-valued field maps directly to that field holding several children.
//!
//! Note: this preserves swift-syntax's own kind/field names. Aligning those
//! names with the tree-sitter-swift schema (so the existing rewrite rules fire)
//! is a separate, later step; this module is only concerned with getting the
//! tree into yeast's format.

use std::collections::BTreeMap;

use serde_json::Value;
use yeast::schema::Schema;
use yeast::{Ast, Id, NodeContent, Point, Range};

/// swift-syntax `TokenKind` cases whose text is *not* determined by the kind
/// (i.e. `TokenKind.defaultText == nil`). These carry varying information and
/// are modelled as named leaf nodes; every other token is a fixed
/// keyword/punctuation token modelled as an anonymous token keyed by its text.
const VARYING_TOKEN_KINDS: &[&str] = &[
    "identifier",
    "integerLiteral",
    "floatLiteral",
    "stringSegment",
    "binaryOperator",
    "prefixOperator",
    "postfixOperator",
    "dollarIdentifier",
    "regexLiteralPattern",
    "rawStringPoundDelimiter",
    "regexPoundDelimiter",
    "shebang",
    "unknown",
];

/// Keys of a node object that carry metadata rather than a structural child.
fn is_metadata_key(key: &str) -> bool {
    matches!(
        key,
        "kind" | "range" | "tokenKind" | "text" | "leadingTrivia" | "trailingTrivia"
    )
}

/// The classification of a JSON node into a yeast kind name and named-ness.
struct KindInfo {
    /// The name under which the kind is registered in the schema.
    name: String,
    /// `true` for named nodes (layout nodes + varying tokens), `false` for
    /// anonymous tokens (fixed keywords/punctuation).
    is_named: bool,
    /// The leaf text for tokens (empty for layout nodes).
    text: String,
}

/// Determine the kind name / named-ness / text for a JSON node object.
fn classify(node: &Value) -> Result<KindInfo, String> {
    let kind = node
        .get("kind")
        .and_then(Value::as_str)
        .ok_or("node object is missing a string `kind`")?;

    if kind != "token" {
        // Layout node: named, keyed by its kind, no leaf text.
        return Ok(KindInfo {
            name: kind.to_string(),
            is_named: true,
            text: String::new(),
        });
    }

    let token_kind = node
        .get("tokenKind")
        .and_then(Value::as_str)
        .ok_or("token is missing a string `tokenKind`")?;
    let text = node
        .get("text")
        .and_then(Value::as_str)
        .unwrap_or("")
        .to_string();

    // The case name is the part before any `(payload)` in the debug rendering.
    let case_name = token_kind.split('(').next().unwrap_or(token_kind);

    if VARYING_TOKEN_KINDS.contains(&case_name) {
        // Varying token: named leaf, keyed by its case name.
        Ok(KindInfo {
            name: case_name.to_string(),
            is_named: true,
            text,
        })
    } else {
        // Fixed token: anonymous, keyed by its text (as tree-sitter does).
        // `endOfFile` has empty text, so fall back to the case name there.
        let name = if text.is_empty() {
            case_name.to_string()
        } else {
            text.clone()
        };
        Ok(KindInfo {
            name,
            is_named: false,
            text,
        })
    }
}

/// Iterate over a node object's structural (field, value) pairs in a stable
/// order, skipping metadata keys.
fn field_entries(node: &Value) -> Vec<(&str, &Value)> {
    node.as_object()
        .map(|map| {
            map.iter()
                .filter(|(k, _)| !is_metadata_key(k))
                .map(|(k, v)| (k.as_str(), v))
                .collect()
        })
        .unwrap_or_default()
}

/// The child node objects held by a field value, which is either a single node
/// object or an array of them (an elided collection).
fn children_of(value: &Value) -> Vec<&Value> {
    match value {
        Value::Array(items) => items.iter().collect(),
        other => vec![other],
    }
}

/// Recursively build `node` (and its descendants) into `ast`, returning its id.
///
/// This is a single traversal: each node's kind and field names are registered
/// in the schema on the fly, immediately before the node is created. Children
/// are built first so a parent's field lists reference existing ids.
fn build(node: &Value, ast: &mut Ast) -> Result<Id, String> {
    let info = classify(node)?;

    let mut fields: BTreeMap<u16, Vec<Id>> = BTreeMap::new();
    for (field, value) in field_entries(node) {
        let field_id = ast.register_field(field);
        let mut ids = Vec::new();
        for child in children_of(value) {
            ids.push(build(child, ast)?);
        }
        fields.insert(field_id, ids);
    }

    let kind_id = if info.is_named {
        ast.register_kind(&info.name)
    } else {
        ast.register_unnamed_kind(&info.name)
    };

    Ok(ast.create_node_with_range(
        kind_id,
        NodeContent::DynamicString(info.text),
        fields,
        info.is_named,
        parse_range(node),
    ))
}

/// Parse a node's `range` into a [`yeast::Range`].
///
/// The JSON carries, for `start` and `end`, a 0-based UTF-8 file byte `offset`,
/// a 1-based `line`, and a 1-based UTF-8 byte `column`. yeast (like tree-sitter)
/// uses byte offsets with 0-based rows/columns and an exclusive end, so the
/// line/column are shifted down by one. swift-syntax's end position is already
/// exclusive, so the byte offsets map across directly.
fn parse_range(node: &Value) -> Option<Range> {
    let range = node.get("range")?;
    let point = |key: &str| -> Option<(usize, Point)> {
        let p = range.get(key)?;
        let offset = p.get("offset")?.as_u64()? as usize;
        let line = p.get("line")?.as_u64()? as usize;
        let column = p.get("column")?.as_u64()? as usize;
        Some((
            offset,
            Point::new(line.saturating_sub(1), column.saturating_sub(1)),
        ))
    };
    let (start_byte, start_point) = point("start")?;
    let (end_byte, end_point) = point("end")?;
    Some(Range {
        start_byte,
        end_byte,
        start_point,
        end_point,
    })
}

/// Convert a swift-syntax JSON tree (as produced by [`crate::parse_to_json`])
/// into a [`yeast::Ast`].
pub fn json_to_ast(json: &str) -> Result<Ast, String> {
    let root: Value = serde_json::from_str(json).map_err(|e| format!("invalid JSON: {e}"))?;

    let mut ast = Ast::with_schema(Schema::new());
    let root_id = build(&root, &mut ast)?;
    ast.set_root(root_id);
    Ok(ast)
}

#[cfg(test)]
mod tests {
    use super::*;

    /// A hand-written JSON tree exercising layout nodes, a named (varying)
    /// token, a fixed keyword token, and an elided collection field — so the
    /// adapter is tested without needing the Swift toolchain.
    fn sample_json() -> &'static str {
        r#"{
            "kind": "sourceFile",
            "range": {"start":{"offset":0,"line":1,"column":1},"end":{"offset":9,"line":1,"column":10}},
            "statements": [
                {
                    "kind": "variableDecl",
                    "range": {"start":{"offset":0,"line":1,"column":1},"end":{"offset":9,"line":1,"column":10}},
                    "bindingSpecifier": {
                        "kind": "token",
                        "tokenKind": "keyword(SwiftSyntax.Keyword.let)",
                        "text": "let",
                        "range": {"start":{"offset":0,"line":1,"column":1},"end":{"offset":3,"line":1,"column":4}}
                    },
                    "name": {
                        "kind": "token",
                        "tokenKind": "identifier(\"x\")",
                        "text": "x",
                        "range": {"start":{"offset":4,"line":1,"column":5},"end":{"offset":5,"line":1,"column":6}}
                    }
                }
            ]
        }"#
    }

    #[test]
    fn builds_ast_from_json() {
        let ast = json_to_ast(sample_json()).expect("adapter should succeed");
        let root = ast.get_root();
        let root_node = ast.get_node(root).expect("root exists");
        assert_eq!(root_node.kind_name(), "sourceFile");
        assert!(root_node.is_named());
    }

    #[test]
    fn classifies_named_and_anonymous_tokens() {
        let ast = json_to_ast(sample_json()).expect("adapter should succeed");
        // Walk all nodes and collect (kind_name, is_named) for the two tokens.
        let mut let_named = None;
        let mut ident_named = None;
        for node in ast.nodes() {
            match node.kind_name() {
                "let" => let_named = Some(node.is_named()),
                "identifier" => ident_named = Some(node.is_named()),
                _ => {}
            }
        }
        // Fixed keyword `let` is anonymous (keyed by its text "let").
        assert_eq!(let_named, Some(false));
        // Varying `identifier` is a named leaf.
        assert_eq!(ident_named, Some(true));
    }

    #[test]
    fn preserves_leaf_text() {
        let ast = json_to_ast(sample_json()).expect("adapter should succeed");
        let ident = ast
            .nodes()
            .iter()
            .enumerate()
            .find(|(_, n)| n.kind_name() == "identifier")
            .map(|(i, _)| Id(i))
            .expect("identifier node exists");
        assert_eq!(ast.source_text(ident), "x");
    }

    #[test]
    fn maps_source_locations() {
        let ast = json_to_ast(sample_json()).expect("adapter should succeed");
        let ident = ast
            .nodes()
            .iter()
            .find(|n| n.kind_name() == "identifier")
            .expect("identifier node exists");
        // `x` is at file offset 4..5, line 1, column 5 (1-based) in the JSON,
        // which maps to 0-based row 0, column 4 and byte range 4..5.
        assert_eq!(ident.start_byte(), 4);
        assert_eq!(ident.end_byte(), 5);
        assert_eq!(ident.start_position(), Point::new(0, 4));
        assert_eq!(ident.end_position(), Point::new(0, 5));
    }

    /// End-to-end: real Swift source parsed by the shim, then adapted into a
    /// `yeast::Ast`. Requires the Swift toolchain (like the crate's FFI tests).
    #[test]
    fn end_to_end_from_swift_source() {
        let json = crate::parse_to_json("func f(n: Int) -> Int { return n }")
            .expect("parsing should succeed");
        let ast = json_to_ast(&json).expect("adapter should succeed");

        let root = ast.get_node(ast.get_root()).expect("root exists");
        assert_eq!(root.kind_name(), "sourceFile");

        // The tree contains a `functionDecl` layout node and an anonymous
        // `func` keyword token keyed by its text.
        let mut kinds: Vec<&str> = ast.nodes().iter().map(|n| n.kind_name()).collect();
        kinds.sort_unstable();
        assert!(
            kinds.contains(&"functionDecl"),
            "expected a functionDecl node, got kinds: {kinds:?}"
        );
        assert!(
            kinds.contains(&"func"),
            "expected an anonymous `func` token, got kinds: {kinds:?}"
        );
    }
}
