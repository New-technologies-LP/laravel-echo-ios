//
// Created by valentin vivies on 21/07/2017.
//

import Foundation
import SocketIO


/// This class creates a connnector to a Socket.io server.
class SocketIOConnector: IConnector {

    
    /// The Socket.io connection instance.
    
    private var manager: SocketManager?
    
    private var socket: SocketIOClient? {
        guard let manager = self.manager else { return nil }
        return manager.defaultSocket
    }

    
    /// Default connector options.
    private var _defaultOptions: [String: Any] = [ "auth": ["headers": []], "authEndpoint": "/broadcasting/auth", "broadcaster": "socket.io", "host": "", "key": "", "namespace": "App.Events"]

    
    /// Connector options.
    private var options: [String: Any]

    
    /// All of the subscribed channels.
    var channels: [String: IChannel] = [String: IChannel]()

    
    /// Create a new class instance.
    ///
    /// - Parameter options: options
    init(options: [String: Any]){
        manager = nil
        self.options = options
        self.channels = [:]
        //self.setOptions(options: options)
        self.connect()
    }

    
    /// Merge the custom options with the defaults.
    ///
    /// - Parameter options: options
    func setOptions(options: [String: Any]){
        self.options = _defaultOptions
        self.options.merge(options, uniquingKeysWith: { (first, _) in first })
    }

    
    /// Create a fresh Socket.io connection.
    func connect(){
        guard let stringUrl = options["host"] as? String else  {
            debugPrint("Error, host is missing \n")
            return
        }
    
        guard let url: URL = URL(string: stringUrl) else {
            debugPrint("Error, can't create URL class varible from \(stringUrl) \n")
            return
        }
        
        manager = SocketManager(socketURL: url, config: [.log(true), .compress])
        
        socket?.connect(timeoutAfter: 5, withHandler: {
            debugPrint("Error, timeout connect to host \n \(url) \n with options \n \(self.options) ")
        })
        
//        self.socket?.connect(timeoutAfter: 5, withHandler: {
//
//        })

    }
    
    
    /// Add other handler type
    ///
    /// - Parameters:
    ///   - event: event name
    ///   - callback: callback
    func on(event: String, callback: @escaping NormalCallback){
        socket!.on(event, callback: callback)
    }
    
    /// Add client handler
    ///
    /// - Parameters:
    ///   - event: event name
    ///   - callback: callback
    func on(clientEvent: SocketClientEvent, callback: @escaping NormalCallback) {
        socket?.on(clientEvent: clientEvent, callback: callback)
    }
    
    /// Listen for an event on a channel instance.
    ///
    /// - Parameters:
    ///   - name: channel name
    ///   - event: event name
    ///   - callback: callback
    /// - Returns: the channel
    func listen(name : String, event: String, callback: @escaping NormalCallback) -> IChannel {
        return channel(name: name).listen(event: event, callback: callback)
    }

    
    /// Get a channel instance by name.
    ///
    /// - Parameter name: channel name
    /// - Returns: the channel
    func channel(name: String) -> IChannel{
        if channels[name] == nil {
            channels[name] = SocketIoChannel(socket: socket!,
                                             name: name,
                                             options: options)
        }
        return channels[name]!
    }

    
    /// Get a private channel instance by name.
    ///
    /// - Parameter name: channel name
    /// - Returns: the private channel
    func privateChannel(name: String) -> IPrivateChannel{
        if channels["private-" + name] == nil {
           channels["private-" + name] = SocketIOPrivateChannel(socket: socket!,
                                                                name: "private-" + name,
                                                                options: options)
        }
        return channels["private-" + name]! as! IPrivateChannel
    }

    
    /// Get a presence channel instance by name.
    ///
    /// - Parameter name: channel name
    /// - Returns: the presence channel
    func presenceChannel(name: String) -> IPresenceChannel{
        if channels["presence-" + name] == nil {
            channels["presence-" + name] = SocketIOPresenceChannel(socket: socket!,
                                                                   name: "presence-" + name,
                                                                   options: options)
        }
        return channels["presence-" + name]! as! IPresenceChannel
    }

    
    /// Leave the given channel.
    ///
    /// - Parameter name: channel name
    func leave(name : String){
        let namesOfChannels: [String] = [name, "private-" + name, "presence-" + name]
        for name in namesOfChannels {
            if let channel = channels[name] {
                channel.unsubscribe()
                channels[name] = nil
            }
        }
    }

    
    /// Get the socket_id of the connection.
    ///
    /// - Returns: the socket id
    func socketId() -> String {
        guard let socket = self.socket else { return String() }
        return socket.sid
    }

    
    /// Disconnect from the Echo server.
    func disconnect(){
        guard let socket = self.socket else { return }
        socket.disconnect()
    }
    
    
    /// Merge options with default
    ///
    /// - Parameter options: the options
    /// - Returns: merged options
    func mergeOptions(options : [String: Any]) -> [String: Any]{
        var def = self._defaultOptions
        for (k, v) in options{
            def[k] = v
        }
        return def
    }

}
