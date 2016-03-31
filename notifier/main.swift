import Foundation;

let cli = CommandLine();

let paths = MultiStringOption(shortFlag: "v", longFlag: "path", required: false, helpMessage: "Path(s) to watch");
let ip = StringOption(shortFlag: "i", longFlag: "ip", required: false, helpMessage: "IP-address to bind. Default to all");
let port = IntOption(shortFlag: "p", longFlag: "port", required: false, helpMessage: "Port for which to listen for connections (default: 2050)");
let filters = MultiStringOption(shortFlag: "f", longFlag: "filter", required: false, helpMessage: "Regexp. Matching will be sent.");
let config = StringOption(shortFlag: "c", longFlag: "config", required: false, helpMessage: "Path to JSON config file");
let fileTypes = MultiStringOption(shortFlag: "t", longFlag: "fileType", required: false, helpMessage: "File types to be scanned for. Will be scanned in addition to filters");
let debug = BoolOption(longFlag: "debug", helpMessage: "Print running config");

cli.addOptions([config, paths, ip, port, filters, fileTypes, debug]);

do {
  try cli.parse()
} catch {
  cli.printUsage(error)
  exit(EX_USAGE)
}

// Default values
var configIp:String?;
var configPort:Int = 2050;
var configPaths:[String] = [];
var configFilters:[String] = [];
var configFileTypes:[String] = [];

if config.value != nil
{
    let location = config.value!;
    let fileManager = NSFileManager.defaultManager()
    if !fileManager.fileExistsAtPath(location)
    {
        print("Config file \""+location+"\" not found");
        exit(EXIT_FAILURE);
    }

    let data: NSData? = NSData(contentsOfFile: location);
    if data == nil
    {
        print("Could not read content from config file \""+location+"\"");
        exit(EXIT_FAILURE);
    }

    do
    {
        let jsonResult: NSDictionary = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary;
        if let ip = jsonResult["ip"] as? String
        {
            configIp = ip;
        }
        if let port = jsonResult["port"] as? Int
        {
            configPort = port;
        }
        if let paths = jsonResult["paths"] as? [String]
        {
            configPaths = paths;
        }
        if let filters = jsonResult["filters"] as? [String]
        {
            configFilters = filters;
        }
        if let fileTypes = jsonResult["fileTypes"] as? [String]
        {
            configFileTypes = fileTypes;
        }
    }
    catch
    {
        print("Config file \""+location+"\" does not contain valid JSON");
        exit(EXIT_FAILURE);
    }
}

if filters.value != nil
{
    configFilters = filters.value!;
}
if fileTypes.value != nil
{
    configFileTypes = [];
    for fileType in fileTypes.value!
    {
        let fileTypeRegex = "\\."+fileType+"$";
        configFileTypes.append(fileTypeRegex);
    }
}
if port.value != nil
{
    configPort = port.value!;
}
if(paths.value != nil)
{
    configPaths = paths.value!
}

if ip.value != nil
{
    configIp = ip.value!;
}

// Merge filters and fileType regexes
configFilters.appendContentsOf(configFileTypes);

// Validate necessary config
if configPaths.count == 0
{
    print("Missing paths to watch\n");
    cli.printUsage();
    exit(EX_USAGE);
}

if debug.value
{
    print("Running with config:");
    print("IP: " + (configIp ?? "All IPs"));
    print("Port: "+configPort.description);
    print("Paths: "+configPaths.description);
    print("Filters: "+configFilters.description);
}

let broadcaster:Broadcaster = Broadcaster(configIp, UInt16(configPort));
let fileWatcher:FileSystemWatcher = FileSystemWatcher(configPaths);
let notifier:Notifier = Notifier(broadcaster, fileWatcher, configFilters);

notifier.start();
