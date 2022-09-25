// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract Airbnb {

    address public owner;
    uint256 private counter;

    constructor() {
        counter = 0;
        owner = msg.sender;
    }

    struct rentalInfo {
        string name;
        string city;
        string lat;
        string long;
        string unoDescription;
        string dosDescription;
        string imgUrl;
        uint256 maxGuests;
        uint256 pricePerDay;
        string[] datesBooked;
        uint256 id;
        address renter;
    }

    event rentalCreated (
        string name,
        string city,
        string lat,
        string long,
        string unoDescription,
        string dosDescription,
        string imgUrl,
        uint256 maxGuests,
        uint256 pricePerDay,
        string[] datesbooked,
        uint256 id,
        address renter
    );

    event newDatesBooked(
        string[] datesBooked,
        uint256 id,
        address boooker,
        string city,
        string imgUrl
    );

    mapping(uint256 => rentalInfo) rentals;
    uint256[] public rentalIds;

    function addRentals(
        string memory name,
        string memory city,
        string memory lat,
        string memory long,
        string memory unoDescription,
        string memory dosDescription,
        string memory imgUrl,
        uint256 maxGuests,
        uint256 pricePerDay,
        string[] memory datesbooked
    ) public {
        require(msg.sender == owner, "Only owner can put up rentals");
        rentalInfo memory newRental = rentalInfo(
            name,
            city,
            lat,
            long,
            unoDescription,
            dosDescription,
            imgUrl,
            maxGuests,
            pricePerDay,
            datesbooked,
            counter,
            owner
        );

        rentals[counter] = newRental;
        rentalIds.push(counter);

        emit rentalCreated(name, city, lat, long, unoDescription, dosDescription, imgUrl, maxGuests, pricePerDay, datesbooked, counter, owner);
    }

    function checkBookings(uint256 id, string[] memory newBookings) private view returns(bool) {
        for(uint i=0; i< newBookings.length; i++) {
            for(uint j = 0; j<rentals[id].datesBooked.length; j++) {
                if(keccak256(abi.encodePacked(rentals[id].datesBooked[j])) == keccak256(abi.encodePacked(newBookings[i]))) {
                    return false;
                }
            }
        }
        return true;
    }

    function addDatesBooked(uint256 id, string[] memory newBookings) public payable {
        require(id < counter, "No such rentals");
        require(checkBookings(id, newBookings), "Already Booked for Requested dates");
        require(msg.value == (rentals[id].pricePerDay * 1 ether * newBookings.length), "Please submit the asking price in order to complete the purchase");

        for(uint i=0; i<newBookings.length; i++) {
            rentals[id].datesBooked.push(newBookings[i]);
        }

        payable(owner).transfer(msg.value);

        emit newDatesBooked(newBookings, id, msg.sender, rentals[id].city, rentals[id].imgUrl);
    }

    function getRental(uint256 id) public view returns(string memory, uint256, string[] memory) {
        require(id < counter, "No such rental!");

        rentalInfo storage s_rental = rentals[id];
        return(s_rental.name, s_rental.pricePerDay, s_rental.datesBooked);
    }
    
}