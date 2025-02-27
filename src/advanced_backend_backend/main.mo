import Blob "mo:base/Blob";
import Cycles "mo:base/ExperimentalCycles";
import Nat64 "mo:base/Nat64";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Map "mo:map/Map";
import { phash; nhash } "mo:map/Map";
import Vector "mo:vector";
import Result "mo:base/Result";
import Float "mo:base/Float";
import { JSON } "mo:serde";
import Debug "mo:base/Debug";
import IC "ic:aaaaa-aa";
import Env "./env";

// import the custom types we have in Types.mo
import Types "types";

actor {

  // ==== CHALLENGE 1 ====
  stable var adminsVector = Vector.init<Principal>(1, Principal.fromText("2vxsx-fae")); // feel free to change to your own principal instead of the anonymous one

  public shared ({ caller }) func getAdmins() : async [Principal] {
    return Vector.toArray(adminsVector);
  };

  public shared ({ caller }) func addAdmin(principal : Principal) : async Result.Result<Text, Text> {

    switch (isAdmin(principal)) {
      case (true) {
        return #ok("Admin " # debug_show principal # " is already present");
      };
      case (false) {
        Vector.add(adminsVector, principal);
        return #ok("Admin " # debug_show principal # " was added!");
      };
    };

    //return #ok("Admin " # debug_show principal # " added");
  };

  public shared ({ caller }) func removeAdmin(principal : Principal) : async Result.Result<Text, Text> {

    if (isAdmin(principal)) {
      let newAdminsVector = Vector.new<Principal>();

      for (i in Vector.vals(adminsVector)) {
        if (i != principal) {
          Vector.add(newAdminsVector, i);
        };
      };
      adminsVector := newAdminsVector;
      return #ok("Admin " # debug_show principal # " was removed");
    } else {
      return #ok("Admin " # debug_show principal # " does not exist");
    };
  };

  private func isAdmin(principal : Principal) : Bool {
    return Vector.contains<Principal>(adminsVector, principal, Principal.equal);
  };
  public shared ({ caller }) func callProtectedMethod() : async Result.Result<Text, Text> {

    switch (isAdmin(caller)) {
      case (true) {
        return #ok("Access Authorized");
      };
      case (false) {
        return #err("Access not Authorized");
      };
    }

    //return #ok("Ups, this was meant to be protected");
  };

  // ==== CHALLENGE 2 ====
  public query func transform(raw : Types.TransformArgs) : async Types.CanisterHttpResponsePayload {
    let transformed : Types.CanisterHttpResponsePayload = {
      status = raw.response.status;
      body = raw.response.body;
      headers = [
        {
          name = "Content-Security-Policy";
          value = "default-src 'self'";
        },
        { name = "Referrer-Policy"; value = "strict-origin" },
        { name = "Permissions-Policy"; value = "geolocation=(self)" },
        {
          name = "Strict-Transport-Security";
          value = "max-age=63072000";
        },
        { name = "X-Frame-Options"; value = "DENY" },
        { name = "X-Content-Type-Options"; value = "nosniff" },
      ];
    };
    transformed;
  };

  public func outcall_ai_model_for_sentiment_analysis(paragraph : Text) : async Result.Result<{ paragraph : Text; result : Text }, Text> {

    let ic : Types.IC = actor ("aaaaa-aa");
    let host : Text = "api.mistral.ai";
    let url = "https://" # host # "/v1/chat/completions";

    let key = Env.getAPIKey();

    let request_header = [
      {
        name = "Authorization";
        value = "Bearer " # key;
      },
      {
        name = "Content-Type";
        value = "application/json";
      },
    ];

    let model = "mistral-small-latest";
    let role = "user";

    let request_body_json : Text = "{ \"model\": \"" # model # "\", \"messages\": [{ \"role\": \"" # role # "\", \"content\": \"" # paragraph # "\" }]}";
    let request_body_as_Blob : Blob = Text.encodeUtf8(request_body_json);
    let request_body_as_nat8 : [Nat8] = Blob.toArray(request_body_as_Blob);

    let transform_context : Types.TransformContext = {
      function = transform;
      context = Blob.fromArray([]);
    };

    let http_request : Types.HttpRequestArgs = {
      url = url;
      max_response_bytes = null; //optional for request
      headers = request_header;
      //note: type of `body` is ?[Nat8] so you pass it here as "?request_body_as_nat8" instead of "request_body_as_nat8"
      body = ?request_body_as_nat8;
      method = #post;
      transform = ?transform_context;
    };

    Cycles.add<system>(230_949_972_000);

    let http_response : Types.HttpResponsePayload = await ic.http_request(http_request);

    let response_body : Blob = Blob.fromArray(http_response.body);
    let decoded_text : Text = switch (Text.decodeUtf8(response_body)) {
      case (null) { "No value returned" };
      case (?y) { y };
    };

    return #ok({
      paragraph = paragraph;
      result = decoded_text;
    });

  };

  // ==== CHALLENGE 3 ====

  public func callOtherCanister() : async Result.Result<Text, Text> {
    return #ok("Not Implemented ");
  };

  public func callOutsideCanister() : async Result.Result<Text, Text> {
    return #ok("Not Implemented ");
  };

  public func callManagementCanister() : async Result.Result<Text, Text> {
    return #ok("Not Implemented ");
  };

  // ==== CHALLENGE 4 ====

  // - create a " job " method (meant to be called by the Timer);
  // - create a " cron " job that runs " every 1 h ".
  // - create a " queued " job that you set to run in " 1 min ".

  // ==== CHALLENGE 5 ====

  // - Add **tests** to your repo (suggest Mops Test with PocketIC as param)
  // - Run tests, format lint and audits on **github workflow (Action)**
  // - Deploy on mainnet (ask Tiago for Faucet Coupon) and:
  // - Implement monitoring with CycleOps
  // - Cause a trap and then see it in the logs (and also query stats)

};
