/**
 *Submitted for verification at Etherscan.io on 2022-08-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


contract Web3RSVP {

///////////////////////////////////////////////////////////
// TODO creating event 

    event NewEventCreated(
        bytes32 eventId,
        address creatorAddress,
        uint256 eventTimestamp,
        uint256 maxCapacity,
        uint256 deposit,
        string eventDatCID
    );

    event NewRSVP(bytes32 eventId,address attendeeAddress);

    event ConfirmedAttendee(bytes32 eventId,address attendeeAddress);

    event DepositsPaidOut(bytes32 eventID);

//////////////////////////////////////////////////////////
// ! create a struct to hold data about new event


    struct CreateEvent{

        bytes32 eventId;
        string eventDataCID;
        address eventOwner;
        uint256 eventTimestamp;
        uint256 deposit;
        uint256 maxCapacity;
        address[] confirmedRSVPs;
        address[] claimedRSVPs;
        bool paidOut;
      
    }

    mapping(bytes32 => CreateEvent) public idToEvent;


    function createNewEvent(
    uint256 eventTimestamp, 
    uint256 deposit,
    uint256 maxCapacity,
    string calldata eventDataCID) external {

        bytes32 eventId = keccak256(
            abi.encodePacked(
                msg.sender,
                address(this),
                eventTimestamp,
                deposit,
                maxCapacity
            )
        );

        address[] memory confirmedRSVPs;
        address [] memory claimedRSVPs;

        idToEvent[eventId] =CreateEvent(
            eventId,
            eventDataCID,
            msg.sender,
            eventTimestamp,
            deposit,
            maxCapacity,
            confirmedRSVPs,
            claimedRSVPs,
            false
        );

    emit NewEventCreated(
    eventId,
    msg.sender,
    eventTimestamp,
    maxCapacity,
    deposit,
    eventDataCID
);
    }

    function createNewRSVP(bytes32 eventId) external payable {

        CreateEvent storage myEvent = idToEvent[eventId];

        require(msg.value == myEvent.deposit,
        "You do not have enough fund , add fund and try again");

        require(block.timestamp <= myEvent.eventTimestamp,
        "You missed the event, it already happened" );

        require(myEvent.confirmedRSVPs.length < myEvent.maxCapacity,
        "This event has reched maximum capicity of attendee");

        for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
        require(myEvent.confirmedRSVPs[i] != msg.sender, "ALREADY CONFIRMED");
    }

        myEvent.confirmedRSVPs.push(payable(msg.sender));
        
        emit NewRSVP(eventId, msg.sender);
    }

    function confirmedAttendee(bytes32 eventId, address attendee) public {
     
     CreateEvent storage myEvent = idToEvent[eventId];

     require(msg.sender == myEvent.eventOwner,
     "You did not created this event");

     address rsvpConfirm;

     for (uint8 i=0;i < myEvent.confirmedRSVPs.length;i++){
        if(myEvent.confirmedRSVPs[i] == attendee){
            rsvpConfirm = myEvent.confirmedRSVPs[i];
        }
     }
      require(rsvpConfirm== attendee,"No RSVP to confirm");

      for (uint8 i=0;i < myEvent.claimedRSVPs.length;i++){
        require(myEvent.claimedRSVPs[i] != attendee,"Already Claimed");
      }

      require(myEvent.paidOut == false,"Already Paid Out");
       myEvent.claimedRSVPs.push(attendee);
       (bool sent,) = attendee.call{value:myEvent.deposit}("");

       if(!sent){
        myEvent.claimedRSVPs.pop();
       }
       require(sent,"Failed to send Ether");
       emit ConfirmedAttendee(eventId, attendee);
    }

    function confirmedAllAttendees(bytes32 eventId) external {

        CreateEvent storage myEvent = idToEvent[eventId];

        require(msg.sender == myEvent.eventOwner,"You can not call this function,only author of contract can");

        for(uint8 i = 0; i < myEvent.confirmedRSVPs.length;i++){
            confirmedAttendee(eventId,myEvent.confirmedRSVPs[i]);
        }
    }

    function withdrawUnclaimedDeposits(bytes32 eventId) external {

        CreateEvent storage myEvent = idToEvent[eventId];

        require(!myEvent.paidOut,"Already Paid");

        require(
            block.timestamp >= (myEvent.eventTimestamp + 7 days),
                "Too Early");

        require(msg.sender == myEvent.eventOwner,"MUST BE an Event Owner");

        uint256 unclaimed = myEvent.confirmedRSVPs.length - myEvent.claimedRSVPs.length;

        uint256 payout = unclaimed * myEvent.deposit;

        myEvent.paidOut = true;

        (bool sent,) = msg.sender.call{value:payout}("");

        if(!sent){
            myEvent.paidOut == false;
        }

        require(sent,"Failed to sendt Ether");

        emit DepositsPaidOut(eventId);
    }
}