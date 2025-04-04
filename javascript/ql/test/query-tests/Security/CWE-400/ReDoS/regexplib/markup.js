/<[^>]*\n?.*=("|')?(.*\.jpg)("|')?.*\n?[^<]*>/g;
/<[^>]*>/g;
/(<\/?)(?i:(?<element>a(bbr|cronym|ddress|pplet|rea)?|b(ase(font)?|do|ig|lockquote|ody|r|utton)?|c(aption|enter|ite|(o(de|l(group)?)))|d(d|el|fn|i(r|v)|l|t)|em|f(ieldset|o(nt|rm)|rame(set)?)|h([1-6]|ead|r|tml)|i(frame|mg|n(put|s)|sindex)?|kbd|l(abel|egend|i(nk)?)|m(ap|e(nu|ta))|no(frames|script)|o(bject|l|pt(group|ion))|p(aram|re)?|q|s(amp|cript|elect|mall|pan|t(r(ike|ong)|yle)|u(b|p))|t(able|body|d|extarea|foot|h|itle|r|t)|u(l)?|var))(\s(?<attr>.+?))*>/g; // $ Alert[js/redos]
/\xA9/g;
/(?'DateLiteral' (?# Per the VB Spec : DateLiteral ::= '#' [ Whitespace+ ] DateOrTime [ Whitespace+ ] '#' ) \#\s* (?'DateOrTime' (?# DateOrTime ::= DateValue Whitespace+ TimeValue | DateValue | TimeValue ) (?'DateValue' (?# DateValue ::= Whitespace+ TimeValue | DateValue | TimeValue ) ( (?# DateValue ::= MonthValue \/ DayValue \/ YearValue | MonthValue - DayValue - YearValue ) (?'Month'(0?[1-9])|1[0-2]) (?# Month 01 - 12 ) (?'Sep'[-/]) (?# Date separator '-' or '\/' ) (?'Day'0?[1-9]|[12]\d|3[01]) (?# Day 01 - 31 ) \k'Sep' (?# whatever date separator was previously matched ) (?'Year'\d{1,4}) \s+ (?# TimeValue ::= HourValue : MinuteValue [ : SecondValue ] [ WhiteSpace+ ] [ AMPM ] ) (?'HourValue'(0?[1-9])|1[0-9]|2[0-4]) (?# Hour 01 - 24 ) [:] (?'MinuteValue'0?[1-9]|[1-5]\d|60) (?# Minute 01 - 60 ) [:] (?'SecondValue':0?[1-9]|[1-5]\d|60)? (?# Optional Minute :01 - :60 ) \s* (?'AMPM'[AP]M)? ) | ( (?# DateValue ::= MonthValue \/ DayValue \/ YearValue | MonthValue - DayValue - YearValue ) (?'Month'(0?[1-9])|1[0-2]) (?# Month 01 - 12 ) (?'Sep'[-/]) (?# Date separator '-' or '\/' ) (?'Day'0?[1-9]|[12]\d|3[01]) (?# Month 01 - 31 ) \k'Sep' (?# whatever date separator was previously matched ) (?'Year'\d{4}) ) | ( (?# TimeValue ::= HourValue : MinuteValue [ : SecondValue ] [ WhiteSpace+ ] [ AMPM ] ) (?'HourValue'(0?[1-9])|1[0-9]|2[0-4]) (?# Hour 01 - 24 ) [:] (?'MinuteValue'0?[1-9]|[1-5]\d|60) (?# Minute 01 - 60 ) [:] (?'SecondValue':0?[1-9]|[1-5]\d|60)? (?# Optional Minute :01 - :60 ) \s* (?'AMPM'[AP]M)? ) ) ) \s*\# )/g;
/(SELECT\s[\w\*\)\(\,\s]+\sFROM\s[\w]+)| (UPDATE\s[\w]+\sSET\s[\w\,\'\=]+)| (INSERT\sINTO\s[\d\w]+[\s\w\d\)\(\,]*\sVALUES\s\([\d\w\'\,\)]+)| (DELETE\sFROM\s[\d\w\'\=]+)/g;
/"([^"](?:\\.|[^\\"]*)*)"/g; // $ Alert[js/redos]
/href=[\"\'](http:\/\/|\.\/|\/)?\w+(\.\w+)*(\/\w+(\.\w+)?)*(\/|\?\w*=\w*(&\w*=\w*)*)?[\"\']/g;
/<!--[\s\S]*?--[ \t\n\r]*>/g;
/href[ ]*=[ ]*('|\")([^\"'])*('|\")/g;
/<!--.*?-->/g;
/(?s)( class=\w+(?=([^<]*>)))|(<!--\[if.*?<!\[endif\]-->)|(<!\[if !\w+\]>)|(<!\[endif\]>)|(<o:p>[^<]*<\/o:p>)|(<span[^>]*>)|(<\/span>)|(font-family:[^>]*[;'])|(font-size:[^>]*[;'])(?-s)/g;
/<(?:[^"']+?|.+?(?:"|').*?(?:"|')?.*?)*?>/g; // $ Alert[js/redos]
/<(?<tag>.*).*>(?<text>.*)<\/\k<tag>>/g;
/<(\/{0,1})img(.*?)(\/{0,1})\>/g;
/src[^>]*[^/].(?:jpg|bmp|gif)(?:\"|\')/g;
/<(\w+)(\s(\w*=".*?")?)*((\/>)|((\/*?)>.*?<\/\1>))/g; // $ Alert[js/redos]
/(?i:on(blur|c(hange|lick)|dblclick|focus|keypress|(key|mouse)(down|up)|(un)?load|mouse(move|o(ut|ver))|reset|s(elect|ubmit)))/g;
/(<meta\s+)*((name\s*=\s*("|')(?<name>[^'("|')]*)("|')){1}|content\s*=\s*("|')(?<content>[^'("|')]*)("|')|scheme\s*=\s*("|')(?<scheme>[^'("|')]*)("|'))/g;
/<\*?font # Match start of Font Tag (?(?=[^>]+color.*>) #IF\/THEN lookahead color in tag (.*?color\s*?[=|:]\s*?) # IF found THEN move ahead ('+\#*?[\w\s]*'+ # CAPTURE ColorName\/Hex |"+\#*?[\w\s]*"+ # single or double |\#*\w*\b) # or no quotes	.*?> # & move to end of tag |.*?> # ELSE move to end of Tag ) # Close the If\/Then lookahead # Use Multiline and IgnoreCase # Replace the matches from RE with MatchEvaluator below: # if m.Groups(1).Value<>"" then # Return "<font color=" & m.Groups(1).Value & ">" # else # Return "<font>" # end if/g;
/(?'openingTag'<) \s*? (?'tagName'\w+) # Once we've got the tagname, match zero # or more attribute sequences (\s*? # Atomic Grouping for efficiency (?> (?!=[\/\?]?>) # Lookahead so that we can fail quickly # match Attribute pieces (?'attribName'\w+) (?:\s* (?'attribSign'=) \s* ) (?'attribValue' (?:\'[^\']*\'|\"[^\"]*\"|[^ >]+) ) ) )* \s*? # Closing Tag can be either > or \/> (?'closeTag'[\/\?]?>)/g;
/^#?(([fFcC0369])\2){3}$/g;
/&(?![a-zA-Z]{2,6};|#[0-9]{3};)/g;
/&lt;\/?([a-zA-Z][-A-Za-z\d\.]{0,71})(\s+(\S+)(\s*=\s*([-\w\.]{1,1024}|&quot;[^&quot;]{0,1024}&quot;|'[^']{0,1024}'))?)*\s*&gt;/g; // $ Alert[js/redos]
/<[a-zA-Z][^>]*\son\w+=(\w+|'[^']*'|"[^"]*")[^>]*>/g;
/>(?:(?<t>[^<]*))/g;
/<[^>]*name[\s]*=[\s]*"?[^\w_]*"?[^>]*>/g;
/^#?([a-f]|[A-F]|[0-9]){3}(([a-f]|[A-F]|[0-9]){3})?$/g;
/\/\*[\d\D]*?\*\//g;
/<[a-zA-Z]+(\s+[a-zA-Z]+\s*=\s*("([^"]*)"|'([^']*)'))*\s*\/>/g;
/^[^<>`~!/@\#}$%:;)(_^{&*=|'+]+$/g;
/<([^<>\s]*)(\s[^<>]*)?>/g;
/(?s)\/\*.*\*\//g;
/<([^\s>]*)(\s[^<]*)>/g;
/^[a-zA-Z_]{1}[a-zA-Z0-9_]+$/g;
/[0][x][0-9a-fA-F]+/g;
/(\[(\w+)\s*(([\w]*)=('|")?([a-zA-Z0-9|:|\/|=|-|.|\?|&]*)(\5)?)*\])([a-zA-Z0-9|:|\/|=|-|.|\?|&|\s]+)(\[\/\2\])/g; // $ Alert[js/redos]
/%[\-\+0\s\#]{0,1}(\d+){0,1}(\.\d+){0,1}[hlI]{0,1}[cCdiouxXeEfgGnpsS]{1}/g;
/^(Function|Sub)(\s+[\w]+)\([^\(\)]*\)/g;
/^(?<path>(\/?(?<step>\w+))+)(?<predicate>\[(?<comparison>\s*(?<lhs>@\w+)\s*(?<operator><=|>=|<>|=|<|>)\s*(?<rhs>('[^']*'|"[^"]*"))\s*(and|or)?)+\])*$/g; // $ Alert[js/redos]
/^(?<Code>([^"']|"[^"]*")*)'(?<Comment>.*)$/g;
/>(?:(?<t>[^<]*))/g;
/<[a-zA-Z][^>]*\son\w+=(\w+|'[^']*'|"[^"]*")[^>]*>/g;
/<[^>]*name[\s]*=[\s]*"?[^\w_]*"?[^>]*>/g;
/\/\*[\d\D]*?\*\//g;
/^#?([a-f]|[A-F]|[0-9]){3}(([a-f]|[A-F]|[0-9]){3})?$/g;
/&lt;\/?([a-zA-Z][-A-Za-z\d\.]{0,71})(\s+(\S+)(\s*=\s*([-\w\.]{1,1024}|&quot;[^&quot;]{0,1024}&quot;|'[^']{0,1024}'))?)*\s*&gt;/g; // $ Alert[js/redos]
/<!--[\s\S]*?-->/g;
/("[^"]*")|('[^\r]*)(\r\n)?/g;
/(?'openingTag'<) \s*? (?'tagName'\w+) # Once we've got the tagname, match zero # or more attribute sequences (\s*? # Atomic Grouping for efficiency (?> (?!=[\/\?]?>) # Lookahead so that we can fail quickly # match Attribute pieces (?'attribName'\w+) (?:\s* (?'attribSign'=) \s* ) (?'attribValue' (?:\'[^\']*\'|\"[^\"]*\"|[^ >]+) ) ) )* \s*? # Closing Tag can be either > or \/> (?'closeTag'[\/\?]?>)/g;
/&(?![a-zA-Z]{2,6};|#[0-9]{3};)/g;
/^#?(([fFcC0369])\2){3}$/g;
/(\[(\w+)\s*(([\w]*)=('|")?([a-zA-Z0-9|:|\/|=|-|.|\?|&]*)(\5)?)*\])([a-zA-Z0-9|:|\/|=|-|.|\?|&|\s]+)(\[\/\2\])/g; // $ Alert[js/redos]
/[0][x][0-9a-fA-F]+/g;
/%[\-\+0\s\#]{0,1}(\d+){0,1}(\.\d+){0,1}[hlI]{0,1}[cCdiouxXeEfgGnpsS]{1}/g;
/^(?<path>(\/?(?<step>\w+))+)(?<predicate>\[(?<comparison>\s*(?<lhs>@\w+)\s*(?<operator><=|>=|<>|=|<|>)\s*(?<rhs>('[^']*'|"[^"]*"))\s*(and|or)?)+\])*$/g; // $ Alert[js/redos]
/^(Function|Sub)(\s+[\w]+)\([^\(\)]*\)/g;
/^[a-zA-Z_]{1}[a-zA-Z0-9_]+$/g;
/^[^<>`~!/@\#}$%:;)(_^{&*=|'+]+$/g;
/<[a-zA-Z]+(\s+[a-zA-Z]+\s*=\s*("([^"]*)"|'([^']*)'))*\s*\/>/g;
/^[^']*?\<\s*Assembly\s*:\s*AssemblyVersion\s*\(\s*"(\*|[0-9]+.\*|[0-9]+.[0-9]+.\*|[0-9]+.[0-9]+.[0-9]+.\*|[0-9]+.[0-9]+.[0-9]+.[0-9]+)"\s*\)\s*\>.*$/g;
/<a[\s]+[^>]*?href[\s]?=[\s\"\']+(.*?)[\"\']+.*?>([^<]+|.*?)?<\/a>/g;
/(?<commentblock>((?m:^[\t ]*\/{2}[^\n\r\v\f]+[\n\r\v\f]*){2,})|(\/\*[\w\W]*?\*\/))/g;
