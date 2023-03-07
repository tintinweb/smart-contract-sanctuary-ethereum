// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "./String.sol";

contract texasHoldEm {
    mapping(address => uint) public userBalance;
    mapping(address => uint) public userClaimed;
    mapping(string => address) public rmIdToUser; //get owner from room id
    mapping(string => uint8) public rmIdToType; //get room type from room id
    mapping(address => mapping(uint8 => string[])) public userRms; //get user owned room from room type and roomId
    mapping(address => mapping(uint8 => uint)) public userOwnedRmsNum; //get number of room that user owned by room type and roomId

    event Deposit(address userAddress, uint256 ETH);
    event Withdraw(address userAddress, uint256 ETH, uint256 BETCOIN);
    event WithdrawList(address[] users, uint256[] ETH, uint256[] BETCOIN);
    event CreateRoom(address user, uint8 roomType, string roomId);

    address public owner;
    uint256 public processFee;
    uint256 public largeRmFee; 
    uint256 public middleRmFee;
    uint256 public smallRmFee;
    uint256 public totalRoomNumber;
    uint256 public maxRoomNumber;
    uint256 public exchangeRateETH;
    uint256 public exchangeRateBetcoin;

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    constructor() {
        owner = msg.sender;
        processFee = 1 * 10 ** 15;
        smallRmFee = 1 * 10 ** 15;
        middleRmFee = 1 * 10 ** 16;
        largeRmFee = 1 * 10 ** 17;
        totalRoomNumber = 0;
        maxRoomNumber = 1;
        exchangeRateETH = 7000000000000000;
        exchangeRateBetcoin = 1000000;
    }

    function deposit() public payable {
        uint256 _BETCOIN = exchangeRateBetcoin / exchangeRateETH * msg.value;
        require(_BETCOIN % 10 == 0, "deposit amount needs to be a multiple of 10.");

        userBalance[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(address _claimer, uint256 _BETCOIN) public onlyOwner {
        require(_BETCOIN % 10 == 0, "withdrawal needs to be a multiple of 10.");

        uint256 _claim = _BETCOIN * exchangeRateETH / exchangeRateBetcoin;
        require(_claim - processFee > 0, "value does not reach the minimum withdrawal amount");

        payable(owner).transfer(processFee);
        payable(_claimer).transfer(_claim - processFee);
        userClaimed[_claimer] += _claim;
        emit Withdraw(_claimer, _claim - processFee, _BETCOIN);
    }

    function withdrawList(address[] memory _claimers, uint256[] memory _BETCOINs) public onlyOwner {
        require(_claimers.length == _BETCOINs.length, "Array input lengths do not match.");

        uint256[] memory _claimFees = new uint256[](_claimers.length);
        uint256 _totalProcessFee = 0;

        for(uint i = 0; i < _claimers.length; i++) {
            require(_BETCOINs[i] % 10 == 0, "(list) withdraw betcoin needs to be a multiple of 10.");

            uint256 _claim = _BETCOINs[i] * exchangeRateETH / exchangeRateBetcoin;
            require(_claim - processFee > 0, "value does not reach the minimum withdrawal amount");

            payable(_claimers[i]).transfer(_claim - processFee);
            userClaimed[_claimers[i]] += _claim;
            _claimFees[i] = _claim - processFee;
            _totalProcessFee += processFee;
        }
        payable(owner).transfer(_totalProcessFee);

        emit WithdrawList(_claimers, _claimFees, _BETCOINs);
    }

    function updateProcessFee(uint256 _fee) public onlyOwner {
        processFee = _fee;
    }

    function updateMaxRoomNumber(uint256 _maxNumber) public onlyOwner {
        maxRoomNumber = _maxNumber;
    }

    function updateRoomFee(uint256 _fee, uint8 _roomType) public onlyOwner {
        //1 = small, 2 = middle, 3 = large
        if(_roomType == 1) {
            smallRmFee = _fee;
        }

        if(_roomType == 2) {
            middleRmFee = _fee;
        }

        if(_roomType == 3) {
            largeRmFee = _fee;
        }
    }

    function updateExchangeRate(uint256 _exchangeRateETH, uint256 _exchangeRateBetcoin) public onlyOwner {
        exchangeRateETH = _exchangeRateETH;
        exchangeRateBetcoin = _exchangeRateBetcoin;
    }

    function createRoom(uint8 _roomType) public payable{
        require(_roomType > 0 && _roomType < 4, "invalid room type");
        require(userOwnedRmsNum[msg.sender][_roomType] < maxRoomNumber, "user has reached the maximum number of created rooms");

        string memory _roomCode;

        //1 = small, 2 = middle, 3 = large
        if(_roomType == 1) {
            require(msg.value == smallRmFee, "price is too low");
            _roomCode = "S";
        }

        if(_roomType == 2) {
            require(msg.value == middleRmFee, "price is too low");
            _roomCode = "M";
        }

        if(_roomType == 3) {
            require(msg.value == largeRmFee, "price is too low");
            _roomCode = "L";
        }

        string memory _roomId = string.concat(_roomCode, getTime(), "_", Strings.toString(totalRoomNumber));
        totalRoomNumber += 1;

        rmIdToUser[_roomId] = msg.sender;
        rmIdToType[_roomId] = _roomType;
        userRms[msg.sender][_roomType].push(_roomId);
        userOwnedRmsNum[msg.sender][_roomType]++;

        emit CreateRoom(msg.sender, _roomType, _roomId);
    }

    //return date time in string (U.K)
    function getTime() internal view returns (string memory _date) {
        uint _year;
        uint _month;
        uint _day;
        uint _hour;
        uint _minute;
        uint _second;

        (_year, _month, _day, _hour, _minute, _second) = timestampToDateTime(block.timestamp);
        _date = string.concat(Strings.toString(_year), Strings.toString(_month), Strings.toString(_day), Strings.toString(_hour), Strings.toString(_minute), Strings.toString(_second));
    }


    //functions from https://github.com/RollaProject/solidity-datetime/blob/master/contracts/TestDateTime.sol
    function _daysToDate(uint256 _days) internal pure returns (uint256 year, uint256 month, uint256 day) {
        unchecked {
            int256 OFFSET19700101 = 2440588;

            int256 __days = int256(_days);

            int256 L = __days + 68569 + OFFSET19700101;
            int256 N = (4 * L) / 146097;
            L = L - (146097 * N + 3) / 4;
            int256 _year = (4000 * (L + 1)) / 1461001;
            L = L - (1461 * _year) / 4 + 31;
            int256 _month = (80 * L) / 2447;
            int256 _day = L - (2447 * _month) / 80;
            L = _month / 11;
            _month = _month + 2 - 12 * L;
            _year = 100 * (N - 49) + _year + L;

            year = uint256(_year);
            month = uint256(_month);
            day = uint256(_day);
        }
    }

    function timestampToDateTime(uint256 timestamp)
        internal
        pure
        returns (uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second)
    {
        uint256 SECONDS_PER_DAY = 24 * 60 * 60;
        uint256 SECONDS_PER_HOUR = 60 * 60;
        uint256 SECONDS_PER_MINUTE = 60;

        unchecked {
            (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
            uint256 secs = timestamp % SECONDS_PER_DAY;
            hour = secs / SECONDS_PER_HOUR;
            secs = secs % SECONDS_PER_HOUR;
            minute = secs / SECONDS_PER_MINUTE;
            second = secs % SECONDS_PER_MINUTE;
        }
    }

}