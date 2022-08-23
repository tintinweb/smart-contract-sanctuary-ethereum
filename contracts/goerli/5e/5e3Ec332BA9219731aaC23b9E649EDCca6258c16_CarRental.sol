//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// @title A Car Rental Smart Contract
///@notice Allows renter to rent a car

contract CarRental {
    struct Renter {
        address walletAddress;
        string name;
        bool active;
        bool canRent;
        uint start;
        uint end;
        uint due;
    }

    address immutable owner;

    mapping(address => Renter) private renters;

    event Receive(string func, address sender, uint value, bytes data);
    event RenterAdded(string name, address renterAddress, uint time);
    event Withdraw(address to, uint time);
    event BikeOut(address indexed who, uint time);
    event BikeIn(address indexed who, uint time);
    event DuePaid(address indexed who, uint amount, uint time);

    modifier onlyOwner() {
        require(msg.sender == owner, "you are not the owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {
        emit Receive("fallback", msg.sender, msg.value, "");
    }

    function addRenter(
        address _walletAddress,
        string memory _name,
        bool _active,
        bool _canRent,
        uint _start,
        uint _end,
        uint _due
    ) public {
        renters[_walletAddress] = Renter(
            _walletAddress,
            _name,
            _active,
            _canRent,
            _start,
            _end,
            _due
        );
        emit RenterAdded(_name, _walletAddress, block.timestamp);
    }

    function takingOut(address _walletAddress) public {
        require(
            renters[_walletAddress].walletAddress == msg.sender,
            "please only use your wallet Address"
        );
        require(
            renters[_walletAddress].due == 0,
            "you have to clear your dues first"
        );
        require(
            renters[_walletAddress].canRent == true,
            "you have an active session or you have to clear your dues"
        );
        Renter storage renter = renters[_walletAddress];
        renter.active = true;
        renter.start = block.timestamp;
        renter.canRent = false;
        emit BikeOut(msg.sender, block.timestamp);
    }

    function returning(address _walletAddress) public {
        require(
            renters[_walletAddress].walletAddress == msg.sender,
            "please only use your wallet Address"
        );
        require(
            renters[_walletAddress].active == true,
            "please take Out a bike first"
        );
        Renter storage renter = renters[_walletAddress];
        renter.active = false;
        renter.end = block.timestamp;
        renter.canRent = true;
        totalDue(_walletAddress);
        emit BikeIn(msg.sender, block.timestamp);
    }

    function withdrawBalance() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
        emit Withdraw(msg.sender, block.timestamp);
    }

    function payDue(address _walletAddress) public payable {
        require(renters[_walletAddress].due > 0, "you don't have any dues");
        require(
            renters[_walletAddress].active == false,
            "please return bike and pay"
        );
        require(
            msg.value >= renters[_walletAddress].due,
            "Please enter the exact due amount"
        );
        Renter storage renter = renters[_walletAddress];
        renter.due -= msg.value;
        renter.canRent = true;
        renter.due = 0;
        renter.start = 0;
        renter.end = 0;
        emit DuePaid(msg.sender, msg.value, block.timestamp);
    }

    function dueOfRide(address _walletAddress) public view returns (uint) {
        require(
            renters[_walletAddress].canRent == true,
            "your session is active please checkIn"
        );
        require(
            renters[_walletAddress].active == false,
            "your session is active please checkIn or please checkout  to see Due "
        );
        return renters[_walletAddress].due;
    }

    function balanceOfContract() public view returns (uint) {
        return address(this).balance;
    }

    function totalDue(address _walletAddress) internal {
        require(
            renters[_walletAddress].active == false,
            "you have active session please return bike to get due"
        );
        uint finaldue = renters[_walletAddress].due +
            costOfRide(_walletAddress);
        renters[_walletAddress].due = finaldue;
    }

    function timeDifference(uint _end, uint _start)
        internal
        pure
        returns (uint256)
    {
        return _end - _start;
    }

    ///@dev converting timestamps to minutes

    function rideTime(address _walletAddress) internal view returns (uint256) {
        uint rideDuration = timeDifference(
            renters[_walletAddress].end,
            renters[_walletAddress].start
        );
        uint rideDurationMin = rideDuration / 60;
        return (rideDurationMin);
    }

    function costOfRide(address _walletAddress) private view returns (uint) {
        uint costPerMinute = 50000000000; //just typed as many zeroes as i wanted ;)
        return rideTime(_walletAddress) * costPerMinute;
    }
}