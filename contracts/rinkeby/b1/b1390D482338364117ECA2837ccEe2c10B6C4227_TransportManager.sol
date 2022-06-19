// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TransportManager {
    uint256 public balance;
    uint256 public staffRecordNumber;
    uint256 public constant MINIMUM_DEPOSIT = 50000000000000000;

    mapping(address => uint256) public passenger;
    address[] public passengers;

    mapping(address => uint256) public staffRecord;
    address[] public staffRecords;

    struct Trip {
        address passenger;
        string tripCode;
        uint256 price;
    }

    Trip[] public trips;

    mapping(string => uint256) public tripSchedule;
    string[5] public tripCode = [
        "LOSIBD",
        "LOSABK",
        "LOSABJ",
        "LOSPHC",
        "LOSKAN"
    ];
    uint256[5] public tripCost = [
        10000000000000000,
        15000000000000000,
        22000000000000000,
        25000000000000000,
        35000000000000000
    ];

    address public immutable i_contractDeployer;

    constructor() {
        i_contractDeployer = msg.sender;

        for (uint256 tripIndex = 0; tripIndex < tripCode.length; tripIndex++) {
            tripSchedule[tripCode[tripIndex]] = tripCost[tripIndex];
        }
    }

    function fundWallet() public payable {
        require(msg.value >= MINIMUM_DEPOSIT, "Your deposit is not enough!");
        passenger[msg.sender] += msg.value;
        passengers.push(msg.sender);
    }

    function startTrip(string memory _tripCode) public {
        require(tripSchedule[_tripCode] > 0, "Invalid Trip Code");
        require(
            passenger[msg.sender] >= tripSchedule[_tripCode],
            "Insufficient balance!"
        );
        passenger[msg.sender] -= tripSchedule[_tripCode];
        balance += tripSchedule[_tripCode];

        trips.push(Trip(msg.sender, _tripCode, tripSchedule[_tripCode]));
    }

    function checkBalance() public view returns (uint256) {
        uint256 accountBalance = passenger[msg.sender];
        return accountBalance;
    }

    function withdraw() public onlyOwner {
        require(balance > 0, "No fund to withdraw!");

        (bool callSuccess, ) = payable(msg.sender).call{value: balance}("");
        require(callSuccess, "Withdrawal failed!");

        balance = 0;
    }

    function staffRecorder() public {
        uint256 currentTime = block.timestamp;
        uint256 timeDif = currentTime - staffRecord[msg.sender];
        uint256 waitPeriod = 1 days;
        require(timeDif >= waitPeriod, "You can only log once in 24 hours");
        staffRecord[msg.sender] = currentTime;
        staffRecords.push(msg.sender);
        staffRecordNumber += 1;
    }

    modifier onlyOwner() {
        require(msg.sender == i_contractDeployer, "Access denied!");
        _;
    }
}