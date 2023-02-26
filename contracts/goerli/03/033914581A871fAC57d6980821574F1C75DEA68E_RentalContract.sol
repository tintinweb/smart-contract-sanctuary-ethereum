/*
    Terms::
        - Rent for a specific time
        - struct appartment [id, Address , rent, details]   -- Done
        - Create an appartment   -- Done
        - Multiple Appartments [List of appartments] -- Done
        - User can rent out appartment -- Done
        - Terms of rental Agreement [i.e starting date, ending date] --Done  -- On basis of appartment --> Can not be changed once contract is finalised
        
        - rental agreement renewal after month or so  --Done
        - Get balance of Contract  --Done
        - Get balance of single rented appartment  --Done
        - Get remaining time of rented apartment  --Done
        - Withdraw rent to the landlords   -- Done
        - Withdrawl of security/advance by renter  -- Done
        - delete any apartment from list --Done

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract RentalContract {
    address immutable owner;

    // Struct for appartment
    struct Apartment {
        address landlord; // On Creation
        address renter; // On Rent
        bool isRented; // On rent == true
        uint rentAmount; // on creation
        uint rentalPeriod; // on rent
        uint advancePayment; // on creation
        uint balance; // on rent    -- Determines the balance in the contract from this apartment
        uint startRentTime; // On rent
        uint startMonthTime; // Changes every month when payment is made
    }

    mapping(uint => Apartment) public apartments;

    modifier onlyOwner() {
        require(msg.sender == owner, "You're not the owner");
        _;
    }

    modifier onlyLandlord(uint _id) {
        require(
            apartments[_id].landlord == msg.sender,
            "You are not landlord of this apartment"
        );
        _;
    }

    modifier appartmentExists(uint _id) {
        require(
            apartments[_id].landlord != address(0),
            "Apartment doesn't exist"
        );
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // Adding department to the contract
    function addApartment(
        uint _apartmentID,
        address _landlord,
        uint _rentAmount,
        uint _advancePayment
    ) public onlyOwner {
        // In order to check if appartment already exists or not, the landlord address of it should be none as the appartment object will not exist
        require(
            apartments[_apartmentID].landlord == address(0),
            "The Appartmet already exists"
        );
        // Adding appartment to the appartment mapping based on uint id
        apartments[_apartmentID] = Apartment(
            _landlord,
            address(0),
            false, // Not Rented
            _rentAmount,
            0, // Rental Period not specified
            _advancePayment,
            0, // 0 Balance at start
            0, // Not start rent
            0 // Not started rent
        );
    }

    // Remove any Apartment
    function deleteApartmet(
        uint _apartmentId
    ) public onlyOwner appartmentExists(_apartmentId) {
        delete apartments[_apartmentId];
    }

    // Rent appartmet
    function rentApartment(
        uint _apartmentId,
        address _renter,
        uint _rentalPeriod
    ) public payable appartmentExists(_apartmentId) {
        Apartment memory selectedApartment = apartments[_apartmentId];
        // Check conditions for renting apartment

        // If the apartment against this id exist
        require(
            selectedApartment.landlord != address(0),
            "The apartment doesn't exist"
        );

        // If the apartment is already rented or not
        require(
            selectedApartment.isRented == false,
            "The apartment is already rented"
        );
        // If the price sent is ok or not i.e should equal the sum of advance as well as first payment
        require(
            msg.value ==
                selectedApartment.advancePayment + selectedApartment.rentAmount,
            "The amount sent is low"
        );
        // Change the apartment status
        selectedApartment.renter = _renter;
        selectedApartment.rentalPeriod = _rentalPeriod;
        selectedApartment.isRented = true;
        selectedApartment.balance =
            selectedApartment.advancePayment +
            selectedApartment.rentAmount;
        selectedApartment.startRentTime = block.timestamp;
        selectedApartment.startMonthTime = block.timestamp;
        // Set storage appartment details according to updated one's
        apartments[_apartmentId] = selectedApartment;
    }

    // Make rental Payment
    function makeRentPayment(
        uint _apartmentId
    ) public payable appartmentExists(_apartmentId) {
        // Getting the apartment against apartment id
        Apartment memory selectedApartment = apartments[_apartmentId];
        // Checking the conditions for payment of rent
        require(
            msg.sender == selectedApartment.renter,
            "You do not rent this apartment"
        );
        require(
            block.timestamp - selectedApartment.startMonthTime >= 2592000,
            "Your 30 days have not been completed yet"
        );
        require(
            msg.value == selectedApartment.rentAmount,
            "The amount you sent is not correct"
        );
        // Adding 30 days to the initial month start to start the next month
        apartments[_apartmentId].startMonthTime =
            selectedApartment.startMonthTime +
            2592000;
    }

    // Withdraw funds to landlord for the rent only as security stays in the contract

    function withdrawFunds(
        uint _apartmentId
    ) public payable onlyLandlord(_apartmentId) appartmentExists(_apartmentId) {
        payable(msg.sender).transfer(
            apartments[_apartmentId].balance -
                apartments[_apartmentId].advancePayment
        );
        apartments[_apartmentId].balance = apartments[_apartmentId]
            .advancePayment;
    }

    // Withdraw security
    function getAdvanceBack(
        uint _apartmentId
    ) public payable appartmentExists(_apartmentId) {
        Apartment memory selectedApartment = apartments[_apartmentId];
        require(
            msg.sender == selectedApartment.renter,
            "You're not renter of the apartment"
        );
        require(
            block.timestamp - selectedApartment.startRentTime >
                selectedApartment.rentalPeriod,
            "Your rental period is not over"
        );
        payable(msg.sender).transfer(selectedApartment.advancePayment);
        // Resets the appartment as if it is not rented after withdrawing the advance payment

        selectedApartment.renter = address(0);
        selectedApartment.rentalPeriod = 0;
        selectedApartment.isRented = false;
        selectedApartment.balance = 0;
        selectedApartment.startRentTime = 0;
        selectedApartment.startMonthTime = 0;

        apartments[_apartmentId] = selectedApartment;
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getApartmentBalance(
        uint _apartmentId
    ) public view appartmentExists(_apartmentId) returns (uint) {
        return apartments[_apartmentId].balance;
    }

    function getRemainingTime(
        uint _apartmentId
    ) public view appartmentExists(_apartmentId) returns (int) {
        return
            int(apartments[_apartmentId].rentalPeriod) -
            int(apartments[_apartmentId].startRentTime);
    }
}