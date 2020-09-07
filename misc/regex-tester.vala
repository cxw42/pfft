
static int main(string[] args)
{
    Regex re;
    if(args.length < 3) {
        return 2;
    }

    try {
        re = new Regex(args[1]);
    } catch(RegexError e) { // LCOV_EXCL_START
        printerr("Could not create regex qr{%s}\n", args[0]);
        return 1;
    }

    print(@"Regex: qr{$(re.get_pattern())}\n");
    for(int argidx = 2; argidx<args.length; ++argidx) {
        var arg = args[argidx];
        MatchInfo matches;
        print("-%s-:\n", arg);
        if(!re.match(arg, 0, out matches)) {
            print("  no matches\n");
            continue;
        }
        for(int i=0; i<matches.get_match_count(); ++i) {
            print("  %s\n", matches.fetch(0));
        }
    }

    var after = re.replace_eval(args[2], -1, 0, 0, (m,s)=>{
        s.append("REPL");
        return false;
    });
    print("after: -%s-\n", after);

    return 0;
}
