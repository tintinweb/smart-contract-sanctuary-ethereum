/**
 *Submitted for verification at Etherscan.io on 2022-11-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract booker {

    address public owner;
    uint256 private counter;

    constructor() {
        counter = 0;
        owner = msg.sender;
     }

    struct bookingInfo {
        string name;
        string city;
        string unoDescription;
        string dosDescription;
        string imgUrl;
        uint256 pricePerDay;
        string[] datesBooked;
        uint256 id;
        address renter;
    }

    event bookingCreated (
        string name,
        string city,
        string unoDescription,
        string dosDescription,
        string imgUrl,
        uint256 pricePerDay,
        string[] datesBooked,
        uint256 id,
        address renter
    );

    event newDatesBooked (
        string[] datesBooked,
        uint256 id,
        address booker,
        string city,
        string imgUrl 
    );

    mapping(uint256 => bookingInfo) bookings;
    uint256[] public bookingIds;


    function addbookings(
        string memory name,
        string memory city,
        string memory unoDescription,
        string memory dosDescription,
        string memory imgUrl,
        uint256 pricePerDay,
        string[] memory datesBooked
    ) public {
        require(msg.sender == owner, "Only owner of smart contract can put up bookings");
        bookingInfo storage newbooking = bookings[counter];
        newbooking.name = name;
        newbooking.city = city;
        newbooking.unoDescription = unoDescription;
        newbooking.dosDescription = dosDescription;
        newbooking.imgUrl = imgUrl;
        newbooking.pricePerDay = pricePerDay;
        newbooking.datesBooked = datesBooked;
        newbooking.id = counter;
        newbooking.renter = owner;
        bookingIds.push(counter);
        emit bookingCreated(
                name, 
                city,
                unoDescription, 
                dosDescription, 
                imgUrl,
                pricePerDay, 
                datesBooked, 
                counter, 
                owner);
        counter++;
    }

    function checkBookings(uint256 id, string[] memory newBookings) private view returns (bool){
        
        for (uint i = 0; i < newBookings.length; i++) {
            for (uint j = 0; j < bookings[id].datesBooked.length; j++) {
                if (keccak256(abi.encodePacked(bookings[id].datesBooked[j])) == keccak256(abi.encodePacked(newBookings[i]))) {
                    return false;
                }
            }
        }
        return true;
    }


    function addDatesBooked(uint256 id, string[] memory newBookings) public payable {
        
        require(id < counter, "No such booking");
        require(checkBookings(id, newBookings), "Already Booked For Requested Date");
        require(msg.value == (bookings[id].pricePerDay * 1 ether * newBookings.length) , "Please submit the asking price in order to complete the purchase");
    
        for (uint i = 0; i < newBookings.length; i++) {
            bookings[id].datesBooked.push(newBookings[i]);
        }

        payable(owner).transfer(msg.value);
        emit newDatesBooked(newBookings, id, msg.sender, bookings[id].city,  bookings[id].imgUrl);
    
    }

    function getbooking(uint256 id) public view returns (string memory, uint256, string[] memory){
        require(id < counter, "No such booking");

        bookingInfo storage s = bookings[id];
        return (s.name,s.pricePerDay,s.datesBooked);
    }
}