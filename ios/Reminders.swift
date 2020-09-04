import EventKit;

@objc(Reminders)
class Reminders: NSObject {
    let eventStore = EKEventStore();

//    @objc(multiply:withB:withResolver:withRejecter:)
//    func multiply(a: Float, b: Float, resolve:RCTPromiseResolveBlock,reject:RCTPromiseRejectBlock) -> Void {
//        resolve(a*b)
//    }
    
    @objc
    func requestPermission(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) -> Void {
        eventStore.requestAccess(to: .reminder, completion: {
            granted, error in
            if(error != nil){
                let nsError:NSError = NSError(
                    domain: "domain",
                    code: 200,
                    userInfo: ["debugDescription": error.debugDescription, "localizedDescription": error?.localizedDescription ?? ""]
                );

                reject("ERROR", "Failed to request access", nsError);
            } else {
                resolve(granted);
            }
        });
    }
    
    func toDictionary(reminder: EKReminder) -> Dictionary<String, Any?> {
        let alarms = reminder.alarms?.map({[
                "offset": $0.relativeOffset,
                "date": $0.absoluteDate?.description as Any,
            ]});
        
        return [
            "id": reminder.calendarItemIdentifier,
            "title": reminder.title,
            "note": reminder.notes,
            "alarms": alarms,
        ];
    }
    
    @objc
    func getReminders(_ resolve: @escaping RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) -> Void {
        let matching: NSPredicate = eventStore.predicateForReminders(in: nil);

        eventStore.fetchReminders(matching: matching, completion: {
            reminders in
            let dictionaries = reminders?.map({ self.toDictionary(reminder: $0) });

            resolve(dictionaries ?? []);
        });
    }
    
    @objc
    func addReminder(_ config: NSDictionary, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) -> Void {
        let reminder = EKReminder(eventStore: eventStore);
        reminder.priority = 2;
        reminder.notes = config["note"] as? String;
        reminder.title = config["title"] as? String;
        reminder.addAlarm(EKAlarm(absoluteDate: Date()));
        reminder.calendar = eventStore.defaultCalendarForNewReminders();
        
        do {
            try eventStore.save(reminder, commit: true);
            resolve(toDictionary(reminder: reminder));
        } catch {
            reject("ERROR", error.localizedDescription, NSError());
        }
    }
}