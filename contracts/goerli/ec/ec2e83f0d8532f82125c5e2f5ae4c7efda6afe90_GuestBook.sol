/**
 *Submitted for verification at Etherscan.io on 2022-11-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract GuestBook {
    
    // show how many guests have already signed and current guest name
    event NewGuest(uint guestCount, string guestName);
    
    // define guests struct
    struct Guests {
        string guestName;
        string guestMessage;
    }
    // guests array
    Guests[] public guests;

    // private function to add guest to array
    function _createGuestEntry(string memory _guestName, string memory _guestMsg) private {
        guests.push(Guests(_guestName, _guestMsg));
        uint guestCount = guests.length - 1; 
        emit NewGuest(guestCount, _guestName);
    }

    // public function to take input and send to createGuestEntry
    function createGuest(string memory _name, string memory _msg) public {
        _createGuestEntry(_name, _msg);
    }

    function howManyGuests() public view returns (uint) {
        uint totalGuests = guests.length; 
        return totalGuests;
    }
    
}