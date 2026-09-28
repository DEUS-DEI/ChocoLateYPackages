// Fake choco.exe for the tests: it never reaches Chocolatey. It appends one line per call to %FAKE_LOG%
// ("choco cwd=[...] [arg] [arg] ...", with API keys masked) and returns %FAKE_CHOCO_<VERB>_EXIT% (or 0).
// "choco pack" writes <id>.<version>.nupkg from the nuspec of the current folder, like the real one.
// It must be an .exe: the .bat scripts call choco without CALL, so a choco.cmd would never return to them.
using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using System.Text.RegularExpressions;

static class FakeChoco
{
    static int Main(string[] args)
    {
        var parts = new List<string>();
        bool nextIsKey = false;
        foreach (string arg in args)
        {
            string a = arg;
            if (nextIsKey) { a = "<apikey len=" + arg.Length + ">"; nextIsKey = false; }
            else if (arg.StartsWith("--api-key=", StringComparison.OrdinalIgnoreCase)) { a = "--api-key=<apikey len=" + (arg.Length - 10) + ">"; }
            else if (arg.Equals("--api-key", StringComparison.OrdinalIgnoreCase) || arg.Equals("-k")) { nextIsKey = true; }
            parts.Add("[" + a + "]");
        }
        string log = Environment.GetEnvironmentVariable("FAKE_LOG");
        if (string.IsNullOrEmpty(log)) log = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "fake.log");
        File.AppendAllText(log, "choco cwd=[" + Environment.CurrentDirectory + "] " + string.Join(" ", parts.ToArray()) + Environment.NewLine, new UTF8Encoding(false));

        string verb = args.Length > 0 ? args[0].ToLowerInvariant() : "";
        string code = Environment.GetEnvironmentVariable("FAKE_CHOCO_" + verb.ToUpperInvariant() + "_EXIT");
        int rc;
        if (!int.TryParse(code, out rc)) rc = 0;

        if (verb == "pack" && rc == 0)
        {
            string[] nuspecs = Directory.GetFiles(Environment.CurrentDirectory, "*.nuspec");
            if (nuspecs.Length != 1) { Console.Error.WriteLine("(fake) no single nuspec in " + Environment.CurrentDirectory); return 1; }
            string xml = File.ReadAllText(nuspecs[0]);
            string id = Regex.Match(xml, "<id>([^<]+)</id>").Groups[1].Value;
            string version = Regex.Match(xml, "<version>([^<]+)</version>").Groups[1].Value;
            File.WriteAllText(Path.Combine(Environment.CurrentDirectory, id + "." + version + ".nupkg"), "fake");
            Console.WriteLine("Successfully created package '" + id + "." + version + ".nupkg'");
        }
        if (verb == "push") Console.WriteLine("(fake) pushing " + (args.Length > 1 ? args[1] : ""));
        return rc;
    }
}
