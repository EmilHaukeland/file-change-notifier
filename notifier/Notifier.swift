//
//  Notifier.swift
//  notifier
//
//  Created by Emil Haukeland on 13/03/16.
//  Copyright © 2016 Emil Haukeland. All rights reserved.
//

import Foundation

class Notifier
{
    private let filters:[String];
    
    private let broadcaster:Broadcaster;
    private let fileWatcher:FileSystemWatcher;
    
    init(_ broadcaster:Broadcaster, _ fileWatcher:FileSystemWatcher, _ filters:[String])
    {
        self.broadcaster = broadcaster;
        self.fileWatcher = fileWatcher;
        self.filters = filters
        
        fileWatcher.events.listenTo(fileWatcher.EVENT_FILE_CHANGED, action: self.onFileChanged);
    }
    
    func start() -> Void
    {
        broadcaster.start();
        fileWatcher.start();

        CFRunLoopRun();
    }
    
    func stop() -> Void
    {
        broadcaster.stop();
        fileWatcher.stop();
        
        CFRunLoopStop(CFRunLoopGetCurrent());
    }
    
    private func onFileChanged(information:Any?) -> Void
    {
        let data:String = information as! String;
        if isAbleToPassFiltering(data)
        {
            broadcaster.send("file " + data + "\n");
        }
    }
    
    private func isAbleToPassFiltering(path:String) -> Bool
    {
        if filters.count == 0
        {
            return true;
        }
        
        for filter in filters
        {
            if (path.rangeOfString(filter, options: .RegularExpressionSearch) != nil)
            {
                return true;
            }
        }
        return false;
    }
}
