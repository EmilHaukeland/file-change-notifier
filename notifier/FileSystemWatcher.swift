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
    }
    
    deinit
    {
        stop()
    }
    
    func start()
    {
        guard started == false else { return }
        
        var context = FSEventStreamContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
        context.info = UnsafeMutablePointer<Void>(unsafeAddressOf(self))
        
        let flags = UInt32(kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagFileEvents)
        
        streamRef = FSEventStreamCreate(kCFAllocatorDefault, eventCallback, &context, pathsToWatch, lastEventId, 0, flags)
        
        FSEventStreamScheduleWithRunLoop(streamRef, CFRunLoopGetMain(), kCFRunLoopDefaultMode)
        FSEventStreamStart(streamRef)
        
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