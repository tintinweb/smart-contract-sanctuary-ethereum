pragma solidity >=0.7.3;

contract EventReceiver {

   event EventReceived(string ehash, string did, string url);
   
   struct Event {
        string event_hash;
        string addressee_did;
        string endpoint_url;
    }
   Event [] events_from_mesh;

   constructor() {
        //initialize
   }

   function newEvent (string memory ehash, string memory did, string memory url) public {
      events_from_mesh.push( Event(ehash, did, url) );
      emit EventReceived(ehash, did, url);
   }
   function getEvents () public view returns (Event[] memory){
     return events_from_mesh;
   }
}