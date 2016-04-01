import Foundation

class Connection : NSObject
{
    var handle =  NSSocketNativeHandle();
    var addressData = NSData();
    
    init(handle: NSSocketNativeHandle, addressData: NSData)
    {
        self.addressData = addressData;
        self.handle = handle;
    }
}

class Broadcaster
{
    let EVENT_DATA_RECEIVED:String = "Broadcaster.DataReveived";
    
    private var keepRunning:Bool = true;
    private var address:NSMutableData = NSMutableData();
    private let handle:NSSocketNativeHandle;
    private let events:EventManager = EventManager();
    
    init(_ ip:String?, _ port:UInt16)
    {
        handle = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP);
        address = createIPv4Address(ip, port: port);
    }
    
    func start() -> Void
    {
        bind(handle, UnsafePointer<sockaddr>(address.bytes), socklen_t(address.length));
        listen(handle, 5);
        
        let thread:NSThread = NSThread(target:self, selector:Selector("listenForConnections:"), object:nil);
        thread.start();
    }
    
    func stop() -> Void
    {
        keepRunning = false;
    }
    
    func send(data:String) -> Void
    {
        events.trigger(EVENT_DATA_RECEIVED, information:data);
    }
    
    dynamic func listenForConnections(object:String?) -> Void
    {
        while(keepRunning)
        {
            let connection:Connection = self.getIncomingConnection()!;
            let thread : NSThread =  NSThread(target:self, selector:Selector("runner:"), object:connection);
            thread.start();
        }
    }
    
    dynamic func runner(connection:Connection) -> Void
    {
        print("Client connected");
        events.listenTo(self.EVENT_DATA_RECEIVED, action: {(information:Any?) in
            let data:String = information as! String;
            print("Sending data: '"+data+"' to client");
            write(connection.handle, data, Int(data.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)));
        });
        CFRunLoopRun();
    }
    
    private func createIPv4Address(ip:String?, port:UInt16) -> NSMutableData
    {
        let len = sizeof(sockaddr_in);
        let data = NSMutableData(length: len)!;
        let addr = UnsafeMutablePointer<sockaddr_in>(data.mutableBytes);
        
        addr.memory.sin_len = __uint8_t(len);
        addr.memory.sin_family = sa_family_t(AF_INET);
        addr.memory.sin_port = _OSSwapInt16(__uint16_t(port));
        
        if ip != nil && inet_pton(Int32(AF_INET), (ip! as NSString).UTF8String, &addr.memory.sin_addr) != 1
        {
            // throw error
        }
        return data;
    }
    
    private func getIncomingConnection() -> Connection?
    {
        let addressData = NSMutableData(length: sizeof(sockaddr_in))!;
        var addressLength = socklen_t(addressData.length);
        
        let incomingHandle = accept(handle, UnsafeMutablePointer<sockaddr>(addressData.mutableBytes), &addressLength);
        if incomingHandle < 0
        {
            return nil;
        }
        
        return Connection(handle: incomingHandle, addressData: addressData.subdataWithRange(NSMakeRange(0, Int(addressLength))));
    }
}
