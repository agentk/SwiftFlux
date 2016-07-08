public typealias StoreListenerToken = String

public protocol Store : AnyObject {}

private var EventEmitterObjectKey: UInt8 = 0

extension Store {

    private var eventEmitter: EventEmitter {
        guard let eventEmitter = objc_getAssociatedObject(self, &EventEmitterObjectKey) as? EventEmitter else {
            let eventEmitter = DefaultEventEmitter()
            objc_setAssociatedObject(self, &EventEmitterObjectKey, eventEmitter, .OBJC_ASSOCIATION_RETAIN)
            return eventEmitter
        }
        return eventEmitter
    }

    public func subscribe(handler: () -> ()) -> StoreListenerToken {
        return eventEmitter.subscribe(self, handler: handler)
    }

    public func unsubscribe(listenerToken: StoreListenerToken) {
        eventEmitter.unsubscribe(self, listenerToken: listenerToken)
    }

    public func unsubscribeAll() {
        eventEmitter.unsubscribe(self)
    }

    public func emitChange()  {
        eventEmitter.emitChange(self)
    }
}

public protocol EventEmitter {
    func subscribe<T: Store>(store: T, handler: () -> ()) -> String
    func unsubscribe<T: Store>(store: T)
    func unsubscribe<T: Store>(store: T, listenerToken: StoreListenerToken)
    func emitChange<T: Store>(store: T)
}

public class DefaultEventEmitter: EventEmitter {

    private var eventListeners: [StoreListenerToken: EventListener] = [:]

    public init() {}

    deinit {
        eventListeners.removeAll()
    }

    public func subscribe<T: Store>(store: T, handler: () -> ()) -> StoreListenerToken {
        let nextListenerToken = NSUUID().UUIDString
        eventListeners[nextListenerToken] = EventListener(store: store, handler: handler)
        return nextListenerToken
    }

    public func unsubscribe<T: Store>(store: T) {
        eventListeners.forEach { (token, listener) -> () in
            if (listener.store === store) {
                eventListeners.removeValueForKey(token)
            }
        }
    }

    public func unsubscribe<T: Store>(store: T, listenerToken: StoreListenerToken) {
        eventListeners.removeValueForKey(listenerToken)
    }

    public func emitChange<T: Store>(store: T) {
        eventListeners.forEach { (_, listener) -> () in
            if (listener.store === store) { listener.handler() }
        }
    }
}

private class EventListener {
    let store: Store
    let handler: () -> ()

    init(store: Store, handler: () -> ()) {
        self.store = store
        self.handler = handler
    }
}
