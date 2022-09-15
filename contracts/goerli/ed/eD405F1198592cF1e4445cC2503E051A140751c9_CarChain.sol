//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract CarChain {
    //set an owner of contract
    address public immutable i_owner;

    constructor() {
        i_owner = msg.sender;
    }

    // Add yourself as renter
    struct Renter {
        address payable walletAddress;
        string firstName;
        string lastName;
        bool canRent;
        bool active;
        uint256 balance;
        uint256 due;
        uint256 start;
        uint256 end;
        uint256 withdrawable;
    }
    // key => value
    mapping(address => Renter) public renters;

    function addRenter(
        address payable walletAddress,
        string memory firstName,
        string memory lastName,
        bool canRent,
        bool active,
        uint256 balance,
        uint256 due,
        uint256 start,
        uint256 end,
        uint256 withdrawable
    ) public {
        // add renter to mapping. It is like a push in JS
        renters[walletAddress] = Renter(
            walletAddress,
            firstName,
            lastName,
            canRent,
            active,
            balance,
            due,
            start,
            end,
            withdrawable
        );
    }

    // deposit eth to the contract but add balance to specific person
    function deposit(address walletAddress) public payable {
        renters[walletAddress].balance += msg.value;
    }

    // withdraw eth deposited - due
    function withdrawMinusDue(address walletAddress) public payable {
        require(
            renters[walletAddress].walletAddress == msg.sender,
            "You can't withdraw not yours money"
        );
        require(renters[walletAddress].due == 0, "Pay the amount due first");
        require(renters[walletAddress].active == false);
        require(
            renters[walletAddress].balance > 0,
            "You have no money to withdraw"
        );
        renters[walletAddress].withdrawable =
            renters[walletAddress].balance -
            renters[walletAddress].due;
        bool sent = payable(msg.sender).send(
            renters[walletAddress].withdrawable
        );
        require(sent, "Failed to send Ether");
        renters[walletAddress].balance = renters[walletAddress].due;
        renters[walletAddress].withdrawable = 0;
    }

    // pickUp a car
    function pickUp(address walletAddress) public {
        //require rewert transaction before gas is spend
        require(renters[walletAddress].due == 0, "You have pending balance");
        require(
            renters[walletAddress].canRent == true,
            "You can not rent at this time"
        );
        require(
            renters[walletAddress].balance >= 1000000000000000,
            "Please make a deposit first to rent a car"
        );
        renters[walletAddress].active = true;
        renters[walletAddress].start = block.timestamp;
        renters[walletAddress].canRent = false;
    }

    // dropOff the car
    function dropOff(address walletAddress) public {
        require(
            renters[walletAddress].walletAddress == msg.sender,
            "You can't drop off car you don't picked up"
        );
        require(
            renters[walletAddress].active == true,
            "You don't renting car yet"
        );
        renters[walletAddress].active = false;
        renters[walletAddress].end = block.timestamp;
        //set amount of due
        setDue(walletAddress);
    }

    // get total duration of car use | pure don't touch any variable (doesn't read any). If i want use variables then will use view instead
    function renterTimespan(uint256 start, uint256 end)
        internal
        pure
        returns (uint256)
    {
        return end - start;
    }

    function getTotalDuration(address walletAddress)
        public
        view
        returns (uint256)
    {
        require(
            renters[walletAddress].active == false,
            "You have to drop off car first"
        );
        uint256 timespan = renterTimespan(
            renters[walletAddress].start,
            renters[walletAddress].end
        );
        uint256 timespanInMinutes = timespan / 60;
        return timespanInMinutes;
    }

    // get contract balance
    function getBalance() public view returns (uint256) {
        // this reffers to the CONTRACT
        return address(this).balance;
    }

    //get renter's balance
    function balanceOfRenter(address walletAddress)
        public
        view
        returns (uint256)
    {
        return renters[walletAddress].balance;
    }

    // Set due amount | will take 0.002 eth / 5min
    function setDue(address walletAddress) internal {
        uint256 timespanMinutes = getTotalDuration(walletAddress);
        uint256 twoMinuteIncrements = timespanMinutes / 2;
        renters[walletAddress].due = twoMinuteIncrements * 1000000000000000;
    }

    //Make payment
    function makePayment(address walletAddress) public {
        require(
            renters[walletAddress].due > 0,
            "You don't have to pay anything at this time"
        );
        require(
            renters[walletAddress].balance >= renters[walletAddress].due,
            "You don't have enought funds to cover payment. Please make a deposit."
        );
        renters[walletAddress].balance -= renters[walletAddress].due;
        renters[walletAddress].canRent = true;
        renters[walletAddress].due = 0;
        renters[walletAddress].start = 0;
        renters[walletAddress].end = 0;
    }

    function canRentCar(address walletAddress) public view returns (bool) {
        return renters[walletAddress].canRent;
    }
}