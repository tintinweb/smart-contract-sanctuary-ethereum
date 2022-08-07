/**
 *Submitted for verification at Etherscan.io on 2022-08-07
*/

// SPDX-License-Identifier: MIT

// File: ..\node_modules\@openzeppelin\contracts\utils\Context.sol

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin\contracts\access\Ownable.sol

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts\SceneSchedule.sol


pragma solidity 0.8.7;
contract FeeCache {
    uint256 private feeWeiPerSecond;
    uint256 private feeWeiPerMinute;
    uint256 private feeWeiPerHour;
    uint256 private feeWeiPerDay;

    constructor() {
        setFee(1);
    }

    function setFee(uint256 newFeeWeiPerSecond) public {
        feeWeiPerSecond = newFeeWeiPerSecond;
        feeWeiPerMinute = 60 * feeWeiPerSecond;
        feeWeiPerHour = 60 * feeWeiPerMinute;
        feeWeiPerDay = 24 * feeWeiPerHour;
    }

    function getFeePerSecond() public view returns (uint256 weiPerSecond) {
        return feeWeiPerSecond;
    }

    function getFeePerMinute() public view returns (uint256 weiPerMinute) {
        return feeWeiPerMinute;
    }

    function getFeePerHour() public view returns (uint256 weiPerHour) {
        return feeWeiPerHour;
    }

    function getFeePerDay() public view returns (uint256 weiPerDay) {
        return feeWeiPerDay;
    }
}

contract ScheduleInfo {
    uint constant InvalidId = 0;
    uint public id = InvalidId;
    uint public startTimestamp = 0; // inclusive
    uint public endTimestamp = 0; // exclusive
    address public booker = address(0);
    string public data;
    bool public removed = false;
    uint public paidEth = 0;

    constructor (uint _id, uint _startTimestamp, uint _endTimestamp, address _booker, string memory _data) {
        id = _id;
        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;
        booker = _booker;
        data = _data;
        removed = false;
    }

    function remove() public {
        removed = true;
    }

    function getLengthInSeconds() public view returns (uint) {
        return (endTimestamp - startTimestamp);
    }

    function setBooker(address _booker) public {
        booker = _booker;
    }

    function setData(string memory _data) public {
        data = _data;
    }

    function setPaidEth(uint _paidEth) public {
        paidEth = _paidEth;
    }

    function isValid() public view returns (bool) {
        return id != InvalidId;
    }
}

contract SceneSchedule is Ownable {
    FeeCache private fee;
    ScheduleInfo [] schedules;
    mapping(uint => uint) scheduleMap; // each starting hour timpstamp => index in schedules
    uint constant NotReserved = 0; // value for representing not reserved in scheduleMap
    uint constant MinuteInSeconds = 60;
    uint constant HourInSeconds = MinuteInSeconds * 60;
    uint constant DayInSeconds = HourInSeconds * 24;
    uint private createScheduleLimitSeconds; // from present point only can create schedule within this value of seconds in the future
    uint private getMySchedulesLimitSeconds;
    uint private changeScheduleLimitSeconds;

    uint constant PermissionAdmin = 0xffffffffffffffffffffffffffffffff;
    uint constant PermissionReadOthersSchedule = 0x1;
    uint constant PermissionRemoveOthersSchedule = 0x2;
    mapping(address => uint) permissionMap;

    constructor() payable {
        fee = new FeeCache();

        // add dummy info at the index=0, to use index 0 as NotReserved
        ScheduleInfo dummyInfo = new ScheduleInfo(0, 0, 0, address(0), "");
        schedules.push(dummyInfo);
        createScheduleLimitSeconds = DayInSeconds * 30; // 30 days
        getMySchedulesLimitSeconds = DayInSeconds * 7; // 7 days
        changeScheduleLimitSeconds = DayInSeconds; // 24 hours
        
        permissionMap[owner()] = PermissionAdmin; // grant all the permission to owner
    }

    receive() external payable {} // need payable keyword to get ETH

    function getScheduleMapValue(uint keyTimestamp) public view onlyOwner returns (uint) {
        return scheduleMap[keyTimestamp];
    }

    function getTimestampNow() public view returns (uint) {
        return block.timestamp;
    }

    function balance() public view onlyOwner returns (uint) {        
        return address(this).balance;
    }
    
    function setFee(uint newFeeWeiPerSecond) public onlyOwner {
        fee.setFee(newFeeWeiPerSecond);
    }

    function isOwner() public view returns (bool) {
        return owner() == msg.sender;
    }

    function getCreateScheduleLimitSeconds() public view returns (uint) {
        return createScheduleLimitSeconds;
    }
    function setCreateScheduleLimitSeconds(uint newValue) public onlyOwner {
        createScheduleLimitSeconds = newValue;
    }

    function getChangeScheduleLimitSeconds() public view returns (uint) {
        return changeScheduleLimitSeconds;
    }
    function setChangeScheduleLimitSeconds(uint newValue) public onlyOwner {
        changeScheduleLimitSeconds = newValue;
    }

    function getFeePerSecond() public view returns (uint256 weiPerSecond) {
        return fee.getFeePerSecond();
    }

    function getFeePerMinute() public view returns (uint256 weiPerMinute) {
        return fee.getFeePerMinute();
    }

    function getFeePerHour() public view returns (uint256 weiPerHour) {
        return fee.getFeePerHour();
    }
    
    function getFeePerDay() public view returns (uint256 weiPerDay) {
        return fee.getFeePerDay();
    }

    function getNotReserved() external pure returns (uint) {
        return NotReserved;
    }

    function getEarliestStartingHourTimestampWithPresentTimestamp() public view returns (uint earliestStartTime, uint timestampNow) {
        timestampNow = block.timestamp;
        uint remainder = timestampNow % HourInSeconds;
        earliestStartTime = timestampNow - remainder + HourInSeconds;
    }

    function getEarliestStartingHourTimestamp() public view returns (uint earliestStartTimestamp) {
        (earliestStartTimestamp, ) = getEarliestStartingHourTimestampWithPresentTimestamp();
    }

    function _getSchedules(uint searchStartTimestamp, uint searchEndTimestamp, bool onlyMine) internal view returns (ScheduleInfo[] memory searchedSchedules) {        
        require(searchStartTimestamp % HourInSeconds == 0, "searchStartTimpstamp should point at the starting of an hour.");
        if (searchEndTimestamp == 0)
            searchEndTimestamp = searchStartTimestamp + DayInSeconds*7;
        require(searchEndTimestamp % HourInSeconds == 0, "searchEndTimestamp should point at the starting of an hour.");
        require(searchStartTimestamp < searchEndTimestamp, "searchStarTimestamp should be earlier than searchEndTimestamp.");
        require(searchEndTimestamp - searchStartTimestamp <= getMySchedulesLimitSeconds, "Search range is too broad. searchEndTimestamp - searchStartTimestamp should not be greater than 7 days.");

        uint cacheSize = (searchEndTimestamp - searchStartTimestamp) / HourInSeconds + 1;
        uint [] memory myScheduleStartings = new uint[](cacheSize);
        uint count = 0;
        // calculate size of return array and cache the starting time of my schedules
        for (uint t = searchStartTimestamp; t < searchEndTimestamp; t += HourInSeconds) {
            uint scheduleIndex = scheduleMap[t];            
            if (scheduleIndex != NotReserved) {
                ScheduleInfo info = schedules[scheduleIndex];
                if (onlyMine == false || info.booker() == msg.sender) {
                    myScheduleStartings[count] = t;
                    count++;
                    t = info.endTimestamp() - HourInSeconds;
                }                
            }
        }
   
        searchedSchedules = new ScheduleInfo[](count);

        // fill the array for return
        for (uint i = 0; i < count; i++) {
            uint t = myScheduleStartings[i];
            uint scheduleIndex = scheduleMap[t];
            searchedSchedules[i] = schedules[scheduleIndex];
        }

        return searchedSchedules;
    }

    function getSchedules(uint searchStartTimestamp, uint searchEndTimestamp) public view returns (ScheduleInfo[] memory) {
        return _getSchedules(searchStartTimestamp, searchEndTimestamp, false);
    }

    function getMySchedules(uint searchStartTimestamp, uint searchEndTimestamp) public view returns (ScheduleInfo[] memory) {
        return _getSchedules(searchStartTimestamp, searchEndTimestamp, true);
    }

    function getPresentScheduleStartingTimestamp() public view returns (uint) {
        uint timestampNow = block.timestamp;        
        return timestampNow - (timestampNow % HourInSeconds);
    }

    function getScheduleNow() public view returns (bool scheduleExist, ScheduleInfo scheduleNow) {
        uint presentScheduleStartTimestamp = getPresentScheduleStartingTimestamp();
        uint scheduleIndex = scheduleMap[presentScheduleStartTimestamp];
        if (NotReserved != scheduleMap[presentScheduleStartTimestamp])            
            return (true, schedules[scheduleIndex]);
        scheduleExist = false;
    }

    function getScheduleIndex(uint _startTimestamp) public view returns (uint) {
        require(_startTimestamp % HourInSeconds == 0, "_startTimestamp should point at the starting of each hour");
        return scheduleMap[_startTimestamp];
    }

    function createSchedule(uint _startTimestamp, uint _endTimestamp, string memory _data) public payable returns (ScheduleInfo createdScheduleInfo) {
        createdScheduleInfo = _createSchedule(_startTimestamp, _endTimestamp, _data);

        // check sent ETH amount        
        uint totalFee = createdScheduleInfo.getLengthInSeconds() * fee.getFeePerSecond();
        if (msg.value < totalFee)
            revert("ETH amount is not enough to create schedule for given period.");
        else if (msg.value > totalFee)
            revert("ETH amount is too much to create schedule for given period.");

        (bool ret, ) = payable(address(this)).call{value: msg.value}("");
        require(ret, "Failed to send ETH to contract");
        createdScheduleInfo.setPaidEth(msg.value);
    }

    function _createSchedule(uint _startTimestamp, uint _endTimestamp, string memory _data) internal returns (ScheduleInfo info) {
        // check if timestamp is hour base
        // check start time
        if (isOwner() == false)
            require(_startTimestamp >= block.timestamp, "_startTimestamp should not be past time.");
        require(_startTimestamp % HourInSeconds == 0, "_startTimestamp should point at starting of each hour.");
        uint timestampLimit = getEarliestStartingHourTimestamp() + createScheduleLimitSeconds;
        require(_startTimestamp < timestampLimit, "Too much future time. Check the limit of seconds with getCreateScheduleLimitSeconds()");

        // check end time
        if (_endTimestamp == 0)
            _endTimestamp = _startTimestamp + HourInSeconds;
        else
            require(_endTimestamp % HourInSeconds == 0, "_endTimestamp should point at the starting of each hour.");
        require(_startTimestamp < _endTimestamp, "_startTimestamp should be earlier than _endTimpstamp.");

        // check if time slot is avaiable
        for (uint t = _startTimestamp; t < _endTimestamp ; t += HourInSeconds) {
            require(NotReserved == scheduleMap[t], "There's already reserved time.") ;
        }

        // execute creating schedule
        info = new ScheduleInfo(schedules.length, _startTimestamp, _endTimestamp, msg.sender, _data);
        schedules.push(info);
        require(schedules[schedules.length-1].id() == schedules.length-1, "new schedule id should be the same as the index in schedules array.");

        for (uint t = _startTimestamp; t < _endTimestamp ; t += HourInSeconds) {
            scheduleMap[t] = info.id();
        }
        
        return info;
    }

    function getPermission() internal view returns (uint) {
        return permissionMap[msg.sender];
    }

    function hasPermission(uint permission) internal view returns (bool) {
        return getPermission() & permission == permission;
    }

    function modifySchedule(uint scheduleIndex, uint newStartTimestamp, uint newEndTimestamp, string memory newData) 
        public payable returns (ScheduleInfo newScheduleInfo)
    {
        ScheduleInfo removedScheduleInfo = _removeSchedule(scheduleIndex);
        newScheduleInfo = _createSchedule(newStartTimestamp, newEndTimestamp, newData);
        
        // check sent ETH amount
        uint feeForCreate = newScheduleInfo.getLengthInSeconds() * fee.getFeePerSecond();
        if (feeForCreate > removedScheduleInfo.paidEth()) {
            uint ethToPay = feeForCreate - removedScheduleInfo.paidEth();
            if (msg.value < ethToPay)
                revert("ETH amount is not enough to create schedule for given period.");
            else if (msg.value > ethToPay)
                revert("ETH amount is too much to create schedule for given period.");

            (bool ret, ) = payable(address(this)).call{value: ethToPay}("");
            require(ret, "Failed to send ETH to contract");
        }
        else if (feeForCreate < removedScheduleInfo.paidEth()) {
            uint ethToRefund = removedScheduleInfo.paidEth() - feeForCreate;
            (bool ret, ) = payable(msg.sender).call{value: ethToRefund}("");
            require(ret, "Failed to send back ETH to booker");            
        }
        newScheduleInfo.setPaidEth(feeForCreate);
        removedScheduleInfo.setPaidEth(0);
    }

    function removeSchedule(uint scheduleId) public payable {
        ScheduleInfo removedScheduleInfo = _removeSchedule(scheduleId);        
        (bool ret, ) = payable(msg.sender).call{value: removedScheduleInfo.paidEth()}("");
        require(ret, "Failed to send back ETH to booker");
        removedScheduleInfo.setPaidEth(0);
    }

    function _removeSchedule(uint scheduleIndex) internal returns (ScheduleInfo) {
        ScheduleInfo info = schedules[scheduleIndex];
        require(info.isValid(), "You can remove only valid schedules.");
        require(info.removed() == false, "You can't remove the schedule already removed.");
        require(msg.sender == info.booker() || hasPermission(PermissionRemoveOthersSchedule), "No permission to remove given schedule.");
        uint nowTimestamp = block.timestamp;
        require(nowTimestamp < info.startTimestamp(), "schedule you want to remove should not be the past");
        if (hasPermission(PermissionRemoveOthersSchedule) == false)
            require(info.startTimestamp() - nowTimestamp > changeScheduleLimitSeconds, "You can't remove this schedule now.");

        for (uint t = info.startTimestamp(); t < info.endTimestamp(); t += HourInSeconds) {
            require(scheduleMap[t] == scheduleIndex, "The time is not occupied by this schedule.");
            scheduleMap[t] = NotReserved;
        }
        info.remove();

        return info;
    }
}