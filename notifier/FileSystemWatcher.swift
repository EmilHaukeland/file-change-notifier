import Foundation

class FileSystemWatcher
{
    let EVENT_FILE_CHANGED:String = "FileSystemWatcher.FileChanged"
    let events = EventManager()
    
    private(set) var lastEventId: FSEventStreamEventId
    
    private let eventCallback: FSEventStreamCallback = {
        (
            stream: ConstFSEventStreamRef,
            contextInfo: UnsafeMutablePointer<Void>,
            numEvents: Int,
            eventPaths: UnsafeMutablePointer<Void>,
            eventFlags: UnsafePointer<FSEventStreamEventFlags>,
            eventIds: UnsafePointer<FSEventStreamEventId>
        ) in

        print("eventCallback");
        let fileSystemWatcher: FileSystemWatcher = unsafeBitCast(contextInfo, FileSystemWatcher.self)
        let paths = unsafeBitCast(eventPaths, NSArray.self) as! [String]
        
        for index in 0..<numEvents
        {
            fileSystemWatcher.events.trigger(fileSystemWatcher.EVENT_FILE_CHANGED, information: paths[index])
        }
        
        fileSystemWatcher.lastEventId = eventIds[numEvents - 1]
    }
    
    private let pathsToWatch: [String]
    private var started = false
    private var streamRef: FSEventStreamRef!
    
    init(_ pathsToWatch: [String])
    {
        self.lastEventId = FSEventStreamEventId(kFSEventStreamEventIdSinceNow)
        self.pathsToWatch = pathsToWatch
        print("FileSystemWatcher paths to watch: "+pathsToWatch.description);

        let eventString:String = String(self.lastEventId);
        print("FileSystemWatcher eventOd: "+eventString);
    }
    
    deinit
    {
        stop()
    }
    
    func start()
    {
        print("started guard");
        guard started == false else { return }

        print("context");
        var context = FSEventStreamContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
        context.info = UnsafeMutablePointer<Void>(unsafeAddressOf(self))

        print("flags");
        let flags = UInt32(kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagFileEvents)


        print("stream ref");
        streamRef = FSEventStreamCreate(kCFAllocatorDefault, eventCallback, &context, pathsToWatch, lastEventId, 0, flags)

        print("stream ref loop");
        FSEventStreamScheduleWithRunLoop(streamRef, CFRunLoopGetMain(), kCFRunLoopDefaultMode)
        print("stream ref start");
        FSEventStreamStart(streamRef)

        print("stream ref started");
        
        started = true
    }
    
    func stop()
    {
        guard started == true else { return }
        
        FSEventStreamStop(streamRef)
        FSEventStreamInvalidate(streamRef)
        FSEventStreamRelease(streamRef)
        streamRef = nil
        
        started = false
    }
    
}