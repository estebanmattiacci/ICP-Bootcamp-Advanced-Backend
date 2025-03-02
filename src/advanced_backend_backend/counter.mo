import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Env "env";
import Result "mo:base/Result";

//import Main "canister:advanced_backend_backend";

actor class Counter() {

    var counter : Nat = 0;

    public query func getCount() : async Nat {
        return counter;
    };

    public func increment() : async Nat {
        counter += 1;
        return counter;
    };

    public func getRandomFact() : async Text {
        let main = actor (Env.getPrincipalID()) : actor {
            outcall_ai_model : (Text) -> async Result.Result<{ paragraph : Text; result : Text }, Text>;
        };

        let response = await main.outcall_ai_model("Give me a random fact please.");
        switch (response) {
            case (#ok(result)) { return result.result };
            case (#err(errorMsg)) { return "Error: " # errorMsg };
        };

    };
};
