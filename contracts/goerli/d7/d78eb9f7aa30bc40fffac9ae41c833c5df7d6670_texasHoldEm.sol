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

    event Deposit(address user, uint value);
    event Withdraw(address user, uint value);
    event CreateRoom(address user, uint8 roomType, string roomId);

    address public owner;
    uint256 public processFee;
    uint256 public largeRmFee;
    uint256 public middleRmFee;
    uint256 public smallRmFee;
    uint256 public totalRoomNumber;
    uint256 public maxRoomNumber;
    uint256 internal _roomCreated = 0;
    string internal _previousRoomId = "";
    uint256 internal _duplicatedTimes = 0;

    uint256 constant internal SECONDS_PER_DAY = 24 * 60 * 60;
    uint256 constant internal SECONDS_PER_HOUR = 60 * 60;
    uint256 constant internal SECONDS_PER_MINUTE = 60;
    int256 constant internal OFFSET19700101 = 2440588;

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
    }

    function deposit() public payable {
        userBalance[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(address _claimer, uint256 _fee) public onlyOwner {
        payable(owner).transfer(processFee);
        payable(_claimer).transfer(_fee - processFee);
        userClaimed[_claimer] += _fee;
        emit Withdraw(_claimer, _fee);
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

    function createRoom(uint8 _roomType) public payable{
        require(_roomType > 0 && _roomType < 4, "invalid room type");
        require(userOwnedRmsNum[msg.sender][_roomType] < maxRoomNumber, "user has reached the maximum number of created rooms");

        //1 = small, 2 = middle, 3 = large
        if(_roomType == 1) {
            require(msg.value == smallRmFee, "price is too low");
        }

        if(_roomType == 2) {
            require(msg.value == middleRmFee, "price is too low");
        }

        if(_roomType == 3) {
            require(msg.value == largeRmFee, "price is too low");
        }

        totalRoomNumber += 1;
        string memory _roomId = getTime();
        if(keccak256(abi.encodePacked(_previousRoomId)) == keccak256(abi.encodePacked(_roomId))) {
            _duplicatedTimes++;
            _roomId = string.concat(_roomId, Strings.toString(_duplicatedTimes));
        } else {
            _previousRoomId = _roomId;
            _duplicatedTimes = 0;
        }

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
        string memory year = split2(Strings.toString(_year));
        string memory month = split2(Strings.toString(_month));
        string memory day = split2(Strings.toString(_day));
        string memory hour = split2(Strings.toString(_hour));
        string memory minute = split2(Strings.toString(_minute));
        string memory second = split2(Strings.toString(_second));

        _date = string.concat(year, month, day, hour, minute, second);
    }

    //get the last 2 text from string
    function split2(string memory text) public pure returns (string memory) {
        bytes memory a = new bytes(2);
        uint bytelength = bytes(text).length;
        uint position = 0;

        for(uint i=bytelength; i>bytelength-2; i--) {
            a[position] = bytes(text)[i-1];
            position++;
        }

        bytes memory result = new bytes(2);
        result[0] = a[1];
        result[1] = a[0];

        return string(result);
    }

    //functions from https://github.com/RollaProject/solidity-datetime/blob/master/contracts/TestDateTime.sol
    function _daysToDate(uint256 _days) internal pure returns (uint256 year, uint256 month, uint256 day) {
        unchecked {
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
        unchecked {
            (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
            uint256 secs = timestamp % SECONDS_PER_DAY;
            hour = secs / SECONDS_PER_HOUR;
            secs = secs % SECONDS_PER_HOUR;
            minute = secs / SECONDS_PER_MINUTE;
            second = secs % SECONDS_PER_MINUTE;
        }
    }

    //////test//////
    function createRoom2(uint8 _roomType, string memory _iRoomId) public payable{

        require(_roomType > 0 && _roomType < 4, "invalid room type");
        // require(userOwnedRmsNum[msg.sender][_roomType] < maxRoomNumber, "user has reached the maximum number of created rooms");

        //1 = small, 2 = middle, 3 = large
        if(_roomType == 1) {
            require(msg.value == smallRmFee, "price is too low");
        }

        if(_roomType == 2) {
            require(msg.value == middleRmFee, "price is too low");
        }

        if(_roomType == 3) {
            require(msg.value == largeRmFee, "price is too low");
        }

        totalRoomNumber += 1;
        string memory _roomId = _iRoomId;
        if(keccak256(abi.encodePacked(_previousRoomId)) == keccak256(abi.encodePacked(_roomId))) {
            _duplicatedTimes++;
            _roomId = string.concat(_roomId, "_", Strings.toString(_duplicatedTimes));
        } else {
            _previousRoomId = _roomId;
            _duplicatedTimes = 0;
        }

        rmIdToUser[_roomId] = msg.sender;
        rmIdToType[_roomId] = _roomType;
        userRms[msg.sender][_roomType].push(_roomId);
        userOwnedRmsNum[msg.sender][_roomType]++;

        emit CreateRoom(msg.sender, _roomType, _roomId);
    }
}