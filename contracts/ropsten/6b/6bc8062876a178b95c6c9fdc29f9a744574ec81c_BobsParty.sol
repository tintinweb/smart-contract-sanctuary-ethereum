/**
 *Submitted for verification at Etherscan.io on 2022-02-17
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity >0.4.99;
pragma experimental ABIEncoderV2;

/// @title Attendance Smart Contract.
contract BobsParty {
    
    // Our contract will create Attendee structs which hold basic info about attendants.
    struct Attendee {
        string id; // The ID chosen by the attendee.
        bool present; // Boolean (True/False) if the person is coming.
        address creator; // The account address of the creator.
        uint256 donation; // The amount donated by person to party!
    }
    
    mapping(string => Attendee) AttendeeMap; 
    mapping(uint => string) AttendeeIndex; 
    uint256 mapsize; 

    function addToList(string memory _id) public payable returns (bool) {
        Attendee memory new_attendee = Attendee(_id, true, msg.sender, msg.value);
        AttendeeMap[_id] = new_attendee;
        AttendeeIndex[mapsize] = _id;
        mapsize++;
        return true;
    }
    
    // Only the address that added the attendee can rescind the RSVP.
    function rescindRSVP(string memory _id) public returns (bool) {
        if (msg.sender == AttendeeMap[_id].creator){
            AttendeeMap[_id].present = false;
            payable(msg.sender).transfer(AttendeeMap[_id].donation);
            AttendeeMap[_id].donation = 0;
            return true;
        }
        return false;
    }

    function checkStatus(string memory _id) public view returns (Attendee memory){
        return AttendeeMap[_id];
    }

    function showGuestList() public view returns (string[] memory){
        string[] memory attending = new string[] (mapsize);
        uint counter;
        for(uint i = 0; i < mapsize; i++){
            string memory id = AttendeeIndex[i];
            if (AttendeeMap[id].present){
                attending[counter] = id;
                counter++;
            }
        }
        return attending;
    }
    
        
   
}