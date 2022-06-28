// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

error TransportManager__NotOwner();
error TransportManager__Fallback();
error TransportManager__InsufficientDeposit();
error TransportManager__InvalidTripCode();
error TransportManager__InsufficientBalance();
error TransportManager__BalanceIsZero();
error TransportManager__WithdrawFailed();
error TransportManager__LogOnceIn24Hours();

contract TransportManager {
    uint256 private s_balance;
    uint256 private s_staffRecordNumber;
    uint256 public constant MINIMUM_DEPOSIT = 50000000000000000;

    mapping(address => uint256) private s_passenger;
    address[] private s_passengers;

    mapping(address => uint256) private s_staffRecord;
    address[] private s_staffRecords;

    struct Trip {
        address passenger;
        string tripCode;
        uint256 price;
    }

    Trip[] private s_trips;

    mapping(string => uint256) private s_tripSchedule;
    string[5] private s_tripCode = [
        "LOSIBD",
        "LOSABK",
        "LOSABJ",
        "LOSPHC",
        "LOSKAN"
    ];
    uint256[5] private s_tripCost = [
        10000000000000000,
        15000000000000000,
        22000000000000000,
        25000000000000000,
        35000000000000000
    ];

    address private immutable i_contractDeployer;

    modifier onlyOwner() {
        // require(msg.sender == i_contractDeployer, "Access denied!");
        if (msg.sender != i_contractDeployer)
            revert TransportManager__NotOwner();
        _;
    }

    constructor() {
        i_contractDeployer = msg.sender;
        string[5] memory tripCode = s_tripCode;
        uint256[5] memory tripCost = s_tripCost;
        for (uint256 tripIndex = 0; tripIndex < tripCode.length; tripIndex++) {
            s_tripSchedule[tripCode[tripIndex]] = tripCost[tripIndex];
        }
    }

    receive() external payable {
        fundWallet();
    }

    fallback() external {
        revert TransportManager__Fallback();
    }

    function fundWallet() public payable {
        // require(msg.value >= MINIMUM_DEPOSIT, "Your deposit is not enough!");
        if (msg.value < MINIMUM_DEPOSIT)
            revert TransportManager__InsufficientDeposit();

        s_passenger[msg.sender] += msg.value;
        s_passengers.push(msg.sender);
    }

    function withdraw() public payable onlyOwner {
        // require(s_balance > 0, "No fund to withdraw!");
        if (s_balance <= 0) revert TransportManager__BalanceIsZero();

        (bool callSuccess, ) = i_contractDeployer.call{value: s_balance}("");
        // require(callSuccess, "Withdrawal failed!");
        if (!callSuccess) revert TransportManager__WithdrawFailed();

        s_balance = 0;
    }

    function startTrip(string memory _tripCode) public {
        // require(s_tripSchedule[_tripCode] > 0, "Invalid Trip Code");
        // require(
        //     s_passenger[msg.sender] >= s_tripSchedule[_tripCode],
        //     "Insufficient balance!"
        // );
        if (s_tripSchedule[_tripCode] < 0)
            revert TransportManager__InvalidTripCode();
        if (s_passenger[msg.sender] < s_tripSchedule[_tripCode])
            revert TransportManager__InsufficientBalance();

        s_passenger[msg.sender] -= s_tripSchedule[_tripCode];
        s_balance += s_tripSchedule[_tripCode];

        s_trips.push(Trip(msg.sender, _tripCode, s_tripSchedule[_tripCode]));
    }

    function checkBalance() public view returns (uint256) {
        uint256 accountBalance = s_passenger[msg.sender];
        return accountBalance;
    }

    function staffRecorder() public {
        uint256 currentTime = block.timestamp;
        uint256 timeDif = currentTime - s_staffRecord[msg.sender];
        uint256 waitPeriod = 1 days;
        // require(timeDif >= waitPeriod, "You can only log once in 24 hours");
        if (timeDif < waitPeriod) revert TransportManager__LogOnceIn24Hours();

        s_staffRecord[msg.sender] = currentTime;
        s_staffRecords.push(msg.sender);
        s_staffRecordNumber += 1;
    }

    function getBalance() public view returns (uint256) {
        return s_balance;
    }

    function getStaffRecordNumber() public view returns (uint256) {
        return s_staffRecordNumber;
    }

    function getPassenger(address passenger) public view returns (uint256) {
        return s_passenger[passenger];
    }

    function getPassengers(uint256 index) public view returns (address) {
        return s_passengers[index];
    }

    function getStaffRecord(address staff) public view returns (uint256) {
        return s_staffRecord[staff];
    }

    function getStaffRecords(uint256 index) public view returns (address) {
        return s_staffRecords[index];
    }

    function getTripSchedule(string memory tripCode)
        public
        view
        returns (uint256)
    {
        return s_tripSchedule[tripCode];
    }

    function getTrips(uint256 index)
        public
        view
        returns (
            address passenger,
            string memory tripCode,
            uint256 price
        )
    {
        return (
            s_trips[index].passenger,
            s_trips[index].tripCode,
            s_trips[index].price
        );
    }

    function getTripCode(uint256 index) public view returns (string memory) {
        return s_tripCode[index];
    }
}