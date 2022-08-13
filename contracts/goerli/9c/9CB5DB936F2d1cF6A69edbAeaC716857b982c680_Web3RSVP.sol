/**
 *Submitted for verification at Etherscan.io on 2022-08-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract Web3RSVP {

    event NewEventCreated(
    bytes32 eventID,
    address creatorAddress,
    uint256 eventTimestamp,
    uint256 maxCapacity,
    uint256 deposit,
    string eventDataCID
    );

    event NewRSVP(bytes32 eventID, address attendeeAddress);

    event ConfirmedAttendee(bytes32 eventID, address attendeeAddress);
    
    event DepositsPaidOut(bytes32 eventID);


 


// lets create a custom datatype to uphold info about event

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

// this will store all event in one place where each event will have
// unique identifier

    mapping(bytes32 => CreateEvent) public idToEvent;

// This is a function which will create a new event when triggered by
// user from the fronted

    function createNewEvent(
        uint256 eventTimestamp,
        uint256 deposit,
        uint256 maxCapacity,
        string calldata eventDataCID
    ) external {
        bytes32 eventId = keccak256(
            abi.encodePacked(
                msg.sender,
                address(this),
                eventTimestamp,
                deposit,
                maxCapacity
            )
        );

        require(
            idToEvent[eventId].eventTimestamp == 0,
            "Already Registered"
        );

        address[] memory confirmedRSVPs;
        address[] memory claimedRSVPs;

        idToEvent[eventId] = CreateEvent(
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

// This will will allow user to RSVP in a particular Event

    function createNewRSVP(bytes32 eventId) external payable {

        CreateEvent storage myEvent = idToEvent[eventId];

        require(msg.value >= myEvent.deposit,"Not Enough Fund in your wallet");
        require(myEvent.eventTimestamp >= block.timestamp,"Already Happened");
        require(myEvent.confirmedRSVPs.length < myEvent.maxCapacity,"Registration Close,max capacity reached");

        for(uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++){
            require(myEvent.confirmedRSVPs[i] != msg.sender);
        }

        myEvent.confirmedRSVPs.push(payable(msg.sender));

        emit NewRSVP(eventId, msg.sender);
    }

    function confirmAttendee(bytes32 eventId,address attendee) public {
       
        CreateEvent storage myEvent = idToEvent[eventId];

        require(msg.sender == myEvent.eventOwner,"You are not an event organiser");
        
        address rsvpConfirm;

        for(uint8 i=0;i < myEvent.confirmedRSVPs.length;i++){
            if(myEvent.confirmedRSVPs[i] == attendee){
                rsvpConfirm = myEvent.confirmedRSVPs[i];
            }
        }

        require(rsvpConfirm == attendee, "NO RSVP TO CONFIRM");

        for(uint8 i=0;i < myEvent.claimedRSVPs.length;i++){
            require(myEvent.claimedRSVPs[i] != attendee,"Already confirmed");
        }

        require(myEvent.paidOut == false,"Already paid ");

        myEvent.claimedRSVPs.push(attendee);

        (bool sent,) = attendee.call{value:myEvent.deposit}("");

        if(!sent){
          myEvent.claimedRSVPs.pop();
        }

        require(sent,"Failed to send Ether");

        emit ConfirmedAttendee(eventId, attendee);

    }

    function confirmAllAttendee(bytes32 eventId) external {

        CreateEvent memory myEvent = idToEvent[eventId];
        require(msg.sender == myEvent.eventOwner,"You are not an organiser this event");
        for(uint8 i = 0;i < myEvent.confirmedRSVPs.length; i++){
            confirmAttendee(eventId,myEvent.confirmedRSVPs[i]);
        }
    }
   

   function withdrawUnclaimedDeposits(bytes32 eventId) external {

    CreateEvent memory myEvent = idToEvent[eventId];
    require(!myEvent.paidOut,"Already Paid");

    require(
        block.timestamp >= (myEvent.eventTimestamp + 7 days),
        "TOO EARLY"
    );

    // only the event owner can withdraw
    require(msg.sender == myEvent.eventOwner, "MUST BE EVENT OWNER");

    // calculate how many people didn't claim by comparing
    uint256 unclaimed = myEvent.confirmedRSVPs.length - myEvent.claimedRSVPs.length;

    uint256 payout = unclaimed * myEvent.deposit;

    // mark as paid before sending to avoid reentrancy attack
    myEvent.paidOut = true;

    // send the payout to the owner
    (bool sent, ) = msg.sender.call{value: payout}("");

    // if this fails
    if (!sent) {
        myEvent.paidOut = false;
    }

    require(sent, "Failed to send Ether");

    emit DepositsPaidOut(eventId);

   }
}