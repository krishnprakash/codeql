/** Provides classes for working with files and folders. */
overlay[local?]
module;

/** Provides the input specification of the files and folders implementation. */
signature module InputSig {
  /**
   * A base class for files and folders.
   *
   * Typically `@container`.
   */
  class ContainerBase {
    /**
     * Gets the absolute path of this container.
     *
     * Typically `folders(this, result) or files(this, result)`.
     */
    string getAbsolutePath();

    /**
     * Gets the parent container of this container, if any.
     *
     * Typically `containerparent(result, this)`.
     */
    ContainerBase getParentContainer();
  }

  /**
   * A base class for files.
   *
   * Typically `@file`.
   */
  class FileBase extends ContainerBase;

  /**
   * A base class for folders.
   *
   * Typically `@folder`.
   */
  class FolderBase extends ContainerBase;

  /**
   * Holds if `s` is the source location prefix.
   *
   * Typically `sourceLocationPrefix(s)`.
   */
  predicate hasSourceLocationPrefix(string s);
}

/** Provides a class hierarchy for working with files and folders. */
module Make<InputSig Input> {
  /** A file or folder. */
  class Container instanceof Input::ContainerBase {
    /** Gets a file or sub-folder in this container. */
    Container getAChildContainer() { this = result.getParentContainer() }

    /** Gets a file in this container. */
    File getAFile() { result = this.getAChildContainer() }

    /** Gets a sub-folder in this container. */
    Folder getAFolder() { result = this.getAChildContainer() }

    /**
     * Gets the absolute, canonical path of this container, using forward slashes
     * as path separator.
     *
     * The path starts with a _root prefix_ followed by zero or more _path
     * segments_ separated by forward slashes.
     *
     * The root prefix is of one of the following forms:
     *
     *   1. A single forward slash `/` (Unix-style)
     *   2. An upper-case drive letter followed by a colon and a forward slash,
     *      such as `C:/` (Windows-style)
     *   3. Two forward slashes, a computer name, and then another forward slash,
     *      such as `//FileServer/` (UNC-style)
     *
     * Path segments are never empty (that is, absolute paths never contain two
     * contiguous slashes, except as part of a UNC-style root prefix). Also, path
     * segments never contain forward slashes, and no path segment is of the
     * form `.` (one dot) or `..` (two dots).
     *
     * Note that an absolute path never ends with a forward slash, except if it is
     * a bare root prefix, that is, the path has no path segments. A container
     * whose absolute path has no segments is always a `Folder`, not a `File`.
     */
    string getAbsolutePath() { result = super.getAbsolutePath() }

    /**
     * Holds if either,
     * - `part` is the base name of this container and `i = 1`, or
     * - `part` is the stem of this container and `i = 2`, or
     * - `part` is the extension of this container and `i = 3`.
     */
    cached
    private predicate splitAbsolutePath(string part, int i) {
      part = this.getAbsolutePath().regexpCapture(".*/(([^/]*?)(?:\\.([^.]*))?)", i)
    }

    /**
     * Gets the base name of this container including extension, that is, the last
     * segment of its absolute path, or the empty string if it has no segments.
     *
     * Here are some examples of absolute paths and the corresponding base names
     * (surrounded with quotes to avoid ambiguity):
     *
     * <table border="1">
     * <tr><th>Absolute path</th><th>Base name</th></tr>
     * <tr><td>"/tmp/tst.txt"</td><td>"tst.txt"</td></tr>
     * <tr><td>"C:/Program Files (x86)"</td><td>"Program Files (x86)"</td></tr>
     * <tr><td>"/"</td><td>""</td></tr>
     * <tr><td>"C:/"</td><td>""</td></tr>
     * <tr><td>"D:/"</td><td>""</td></tr>
     * <tr><td>"//FileServer/"</td><td>""</td></tr>
     * </table>
     */
    string getBaseName() { this.splitAbsolutePath(result, 1) }

    /**
     * Gets the extension of this container, that is, the suffix of its base name
     * after the last dot character, if any.
     *
     * In particular,
     *
     *  - if the name does not include a dot, there is no extension, so this
     *    predicate has no result;
     *  - if the name ends in a dot, the extension is the empty string;
     *  - if the name contains multiple dots, the extension follows the last dot.
     *
     * Here are some examples of absolute paths and the corresponding extensions
     * (surrounded with quotes to avoid ambiguity):
     *
     * <table border="1">
     * <tr><th>Absolute path</th><th>Extension</th></tr>
     * <tr><td>"/tmp/tst.txt"</td><td>"txt"</td></tr>
     * <tr><td>"/tmp/.classpath"</td><td>"classpath"</td></tr>
     * <tr><td>"/bin/bash"</td><td>not defined</td></tr>
     * <tr><td>"/tmp/tst2."</td><td>""</td></tr>
     * <tr><td>"/tmp/x.tar.gz"</td><td>"gz"</td></tr>
     * </table>
     */
    string getExtension() { this.splitAbsolutePath(result, 3) }

    /** Gets the file in this container that has the given `baseName`, if any. */
    File getFile(string baseName) {
      result = this.getAFile() and
      result.getBaseName() = baseName
    }

    /** Gets the sub-folder in this container that has the given `baseName`, if any. */
    Folder getFolder(string baseName) {
      result = this.getAFolder() and
      result.getBaseName() = baseName
    }

    /** Gets the parent container of this file or folder, if any. */
    Container getParentContainer() { result = super.getParentContainer() }

    /**
     * Gets the relative path of this file or folder from the root folder of the
     * analyzed source location. The relative path of the root folder itself is
     * the empty string.
     *
     * This has no result if the container is outside the source root, that is,
     * if the root folder is not a reflexive, transitive parent of this container.
     */
    string getRelativePath() {
      exists(string absPath, string pref |
        absPath = this.getAbsolutePath() and Input::hasSourceLocationPrefix(pref)
      |
        absPath = pref and result = ""
        or
        absPath = pref.regexpReplaceAll("/$", "") + "/" + result and
        not result.matches("/%")
      )
    }

    /**
     * Gets the stem of this container, that is, the prefix of its base name up to
     * (but not including) the last dot character if there is one, or the entire
     * base name if there is not.
     *
     * Here are some examples of absolute paths and the corresponding stems
     * (surrounded with quotes to avoid ambiguity):
     *
     * <table border="1">
     * <tr><th>Absolute path</th><th>Stem</th></tr>
     * <tr><td>"/tmp/tst.txt"</td><td>"tst"</td></tr>
     * <tr><td>"/tmp/.classpath"</td><td>""</td></tr>
     * <tr><td>"/bin/bash"</td><td>"bash"</td></tr>
     * <tr><td>"/tmp/tst2."</td><td>"tst2"</td></tr>
     * <tr><td>"/tmp/x.tar.gz"</td><td>"x.tar"</td></tr>
     * </table>
     */
    string getStem() { this.splitAbsolutePath(result, 2) }

    /**
     * Gets a URL representing the location of this container.
     *
     * For more information see https://codeql.github.com/docs/writing-codeql-queries/providing-locations-in-codeql-queries/#providing-urls.
     */
    string getURL() { none() }

    /**
     * Gets a textual representation of the path of this container.
     *
     * This is the absolute path of the container.
     */
    string toString() { result = this.getAbsolutePath() }
  }

  /** A folder. */
  class Folder extends Container instanceof Input::FolderBase {
    /** Gets the URL of this folder. */
    override string getURL() { result = "folder://" + this.getAbsolutePath() }
  }

  /** A file. */
  class File extends Container instanceof Input::FileBase {
    /** Gets the URL of this file. */
    override string getURL() { result = "file://" + this.getAbsolutePath() + ":0:0:0:0" }
  }

  /** Provides logic related to `Folder`s. */
  module Folder {
    pragma[nomagic]
    private Container getAChildContainer(Container c, string baseName) {
      result = c.getAChildContainer() and
      baseName = result.getBaseName()
    }

    /** Holds if `relativePath` needs to be appended to `f`. */
    signature predicate shouldAppendSig(Folder f, string relativePath);

    /** Provides the `append` predicate for appending a relative path onto a folder. */
    module Append<shouldAppendSig/2 shouldAppend> {
      private module Config implements ResolveSig {
        predicate shouldResolve(Container c, string name) { shouldAppend(c, name) }
      }

      predicate append = Resolve<Config>::resolve/2;
    }

    /**
     * Signature for modules to pass to `Resolve`.
     */
    signature module ResolveSig {
      /**
       * Holds if `path` should be resolved to a file or folder, relative to `base`.
       */
      predicate shouldResolve(Container base, string path);

      /**
       * Gets an additional file or folder to consider a child of `base`.
       */
      default Container getAnAdditionalChild(Container base, string name) { none() }

      /**
       * Holds if `component` may be treated as `.` if it does not match a child.
       */
      default predicate isOptionalPathComponent(string component) { none() }

      /**
       * Holds if globs should be interpreted in the paths being resolved.
       *
       * The following types of globs are supported:
       * - `*` (matches any child)
       * - `**` (matches any child recursively)
       * - Complex patterns like `foo-*.txt` are also supported
       */
      default predicate allowGlobs() { none() }

      /**
       * Gets an alternative path segment to try if `segment` did not match a child.
       *
       * The motivating use-case is to map compiler-generated file names back to their sources files,
       * for example, `foo.min.js` could be mapped to `foo.ts`.
       */
      bindingset[segment]
      default string rewritePathSegment(string segment) { none() }
    }

    /**
     * Provides a mechanism for resolving file paths relative to a given directory.
     */
    module Resolve<ResolveSig Config> {
      private import Config

      pragma[nomagic]
      private string getPathSegment(string path, int n) {
        shouldResolve(_, path) and
        result = path.replaceAll("\\", "/").splitAt("/", n)
      }

      pragma[nomagic]
      private string getPathSegmentAsGlobRegexp(string segment) {
        allowGlobs() and
        segment = getPathSegment(_, _) and
        segment.matches("%*%") and
        not segment = ["*", "**"] and // these are special-cased
        result = segment.regexpReplaceAll("[^a-zA-Z0-9*]", "\\\\$0").replaceAll("*", ".*")
      }

      pragma[nomagic]
      private int getNumPathSegment(string path) {
        result = strictcount(int n | exists(getPathSegment(path, n)))
      }

      private Container getChild(Container base, string name) {
        result = getAChildContainer(base, name)
        or
        result = getAnAdditionalChild(base, name)
      }

      pragma[nomagic]
      private Container resolve(Container base, string path, int n) {
        shouldResolve(base, path) and n = 0 and result = base
        or
        exists(Container current, string segment |
          current = resolve(base, path, n - 1) and
          segment = getPathSegment(path, n - 1)
        |
          result = getChild(current, segment)
          or
          segment = [".", ""] and
          result = current
          or
          segment = ".." and
          result = current.getParentContainer()
          or
          not exists(getChild(current, segment)) and
          (
            isOptionalPathComponent(segment) and
            result = current
            or
            result = getChild(current, rewritePathSegment(segment))
          )
          or
          allowGlobs() and
          (
            segment = "*" and
            result = getChild(current, _)
            or
            segment = "**" and // allow empty match
            result = current
            or
            exists(string name |
              result = getChild(current, name) and
              name.regexpMatch(getPathSegmentAsGlobRegexp(segment))
            )
          )
        )
        or
        exists(Container current, string segment |
          current = resolve(base, path, n) and
          segment = getPathSegment(path, n)
        |
          // Follow child without advancing 'n'
          allowGlobs() and
          segment = "**" and
          result = getChild(current, _)
        )
      }

      /**
       * Gets the file or folder that `path` resolves to when resolved from `base`.
       *
       * Only has results for the `(base, path)` pairs provided by `shouldResolve`
       * in the instantiation of this module.
       */
      pragma[nomagic]
      Container resolve(Container base, string path) {
        result = resolve(base, path, getNumPathSegment(path))
      }
    }
  }
}

/** A file. */
signature class FileSig {
  /**
   * Gets the absolute, canonical path of this container, using forward slashes
   * as path separator.
   *
   * The path starts with a _root prefix_ followed by zero or more _path
   * segments_ separated by forward slashes.
   *
   * The root prefix is of one of the following forms:
   *
   *   1. A single forward slash `/` (Unix-style)
   *   2. An upper-case drive letter followed by a colon and a forward slash,
   *      such as `C:/` (Windows-style)
   *   3. Two forward slashes, a computer name, and then another forward slash,
   *      such as `//FileServer/` (UNC-style)
   *
   * Path segments are never empty (that is, absolute paths never contain two
   * contiguous slashes, except as part of a UNC-style root prefix). Also, path
   * segments never contain forward slashes, and no path segment is of the
   * form `.` (one dot) or `..` (two dots).
   *
   * Note that an absolute path never ends with a forward slash, except if it is
   * a bare root prefix, that is, the path has no path segments. A container
   * whose absolute path has no segments is always a `Folder`, not a `File`.
   */
  string getAbsolutePath();

  /**
   * Gets the base name of this container including extension, that is, the last
   * segment of its absolute path, or the empty string if it has no segments.
   *
   * Here are some examples of absolute paths and the corresponding base names
   * (surrounded with quotes to avoid ambiguity):
   *
   * <table border="1">
   * <tr><th>Absolute path</th><th>Base name</th></tr>
   * <tr><td>"/tmp/tst.txt"</td><td>"tst.txt"</td></tr>
   * <tr><td>"C:/Program Files (x86)"</td><td>"Program Files (x86)"</td></tr>
   * <tr><td>"/"</td><td>""</td></tr>
   * <tr><td>"C:/"</td><td>""</td></tr>
   * <tr><td>"D:/"</td><td>""</td></tr>
   * <tr><td>"//FileServer/"</td><td>""</td></tr>
   * </table>
   */
  string getBaseName();

  /**
   * Gets the extension of this container, that is, the suffix of its base name
   * after the last dot character, if any.
   *
   * In particular,
   *
   *  - if the name does not include a dot, there is no extension, so this
   *    predicate has no result;
   *  - if the name ends in a dot, the extension is the empty string;
   *  - if the name contains multiple dots, the extension follows the last dot.
   *
   * Here are some examples of absolute paths and the corresponding extensions
   * (surrounded with quotes to avoid ambiguity):
   *
   * <table border="1">
   * <tr><th>Absolute path</th><th>Extension</th></tr>
   * <tr><td>"/tmp/tst.txt"</td><td>"txt"</td></tr>
   * <tr><td>"/tmp/.classpath"</td><td>"classpath"</td></tr>
   * <tr><td>"/bin/bash"</td><td>not defined</td></tr>
   * <tr><td>"/tmp/tst2."</td><td>""</td></tr>
   * <tr><td>"/tmp/x.tar.gz"</td><td>"gz"</td></tr>
   * </table>
   */
  string getExtension();

  /**
   * Gets the relative path of this file or folder from the root folder of the
   * analyzed source location. The relative path of the root folder itself is
   * the empty string.
   *
   * This has no result if the container is outside the source root, that is,
   * if the root folder is not a reflexive, transitive parent of this container.
   */
  string getRelativePath();

  /**
   * Gets the stem of this container, that is, the prefix of its base name up to
   * (but not including) the last dot character if there is one, or the entire
   * base name if there is not.
   *
   * Here are some examples of absolute paths and the corresponding stems
   * (surrounded with quotes to avoid ambiguity):
   *
   * <table border="1">
   * <tr><th>Absolute path</th><th>Stem</th></tr>
   * <tr><td>"/tmp/tst.txt"</td><td>"tst"</td></tr>
   * <tr><td>"/tmp/.classpath"</td><td>""</td></tr>
   * <tr><td>"/bin/bash"</td><td>"bash"</td></tr>
   * <tr><td>"/tmp/tst2."</td><td>"tst2"</td></tr>
   * <tr><td>"/tmp/x.tar.gz"</td><td>"x.tar"</td></tr>
   * </table>
   */
  string getStem();

  /**
   * Gets a URL representing the location of this container.
   *
   * For more information see https://codeql.github.com/docs/writing-codeql-queries/providing-locations-in-codeql-queries/#providing-urls.
   */
  string getURL();

  /**
   * Gets a textual representation of the path of this container.
   *
   * This is the absolute path of the container.
   */
  string toString();
}

/**
 * Provides shared predicates related to contextual queries in the code viewer.
 */
module IdeContextual<FileSig File> {
  /**
   * Returns the `File` matching the given source file name as encoded by the VS
   * Code extension.
   */
  File getFileBySourceArchiveName(string name) {
    // The name provided for a file in the source archive by the VS Code extension
    // has some differences from the absolute path in the database:
    // 1. colons are replaced by underscores
    // 2. there's a leading slash, even for Windows paths: "C:/foo/bar" ->
    //    "/C_/foo/bar"
    // 3. double slashes in UNC prefixes are replaced with a single slash
    // We can handle 2 and 3 together by unconditionally adding a leading slash
    // before replacing double slashes.
    name = ("/" + result.getAbsolutePath().replaceAll(":", "_")).replaceAll("//", "/")
  }
}
