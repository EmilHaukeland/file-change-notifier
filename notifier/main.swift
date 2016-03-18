import Foundation;

let cli = CommandLine();

let paths = MultiStringOption(shortFlag: "v", longFlag: "path", required: true, helpMessage: "Path(s) to watch");
let ip = StringOption(shortFlag: "i", longFlag: "ip", required: false, helpMessage: "IP-address to bind. Default to all");
let port = IntOption(shortFlag: "p", longFlag: "port", required: false, helpMessage: "Port for which to listen for connections (default: 2050)");
let filters = MultiStringOption(shortFlag: "f", longFlag: "filter", required: false, helpMessage: "Regexp. Matching will be sent.");
let ts = BoolOption(longFlag: "ts", helpMessage: "Include TypeScript-files");
let less = BoolOption(longFlag: "less", helpMessage: "Include Less-files");

cli.addOptions([paths, ip, port, filters, ts, less]);

do {
  try cli.parse()
} catch {
  cli.printUsage(error)
  exit(EX_USAGE)
}

var parsedFilters:[String] = [];
if filters.value != nil
{
    parsedFilters.appendContentsOf(filters.value!);
}
if ts.value
{
    parsedFilters.append("\\.ts$");
}
if less.value
{
    parsedFilters.append("\\.less$");
}

let parsedPort:UInt16 = port.value != nil ? UInt16(port.value!) : 2050;

let broadcaster:Broadcaster = Broadcaster(ip.value, parsedPort);
let fileWatcher:FileSystemWatcher = FileSystemWatcher(paths.value!);
let notifier:Notifier = Notifier(broadcaster, fileWatcher, parsedFilters);

notifier.start();
