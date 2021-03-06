// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.10;

import "./IAuthority.sol";

contract AuthorityControlled {
    
    event AuthorityUpdated(address indexed authority);

    string UNAUTHORIZED = "UNAUTHORIZED"; // save gas

    IAuthority public authority;

    constructor(address _authority) {
        _setAuthority(_authority);
    }

    modifier onlyOwner() {
        require(msg.sender == authority.owner(), UNAUTHORIZED);
        _;
    }

    modifier onlyManager() {
        (bool isManager, uint256 idx) = authority.checkIsManager(msg.sender);
        require(isManager, UNAUTHORIZED);
        _;
    }

    function setAuthority(address _newAuthority) external onlyManager {
        _setAuthority(_newAuthority);
    }

    function _setAuthority(address _newAuthority) private {
        authority = IAuthority(_newAuthority);
        emit AuthorityUpdated(_newAuthority);
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.10;

contract DateTime {
    /*
     *  Date and Time utilities for ethereum contracts
     *
     */
    struct _DateTime {
        uint16 year;
        uint8 month;
        uint8 day;
        uint8 hour;
        uint8 minute;
        uint8 second;
        uint8 weekday;
    }

    uint256 constant DAY_IN_SECONDS = 86400;
    uint256 constant YEAR_IN_SECONDS = 31536000;
    uint256 constant LEAP_YEAR_IN_SECONDS = 31622400;

    uint256 constant HOUR_IN_SECONDS = 3600;
    uint256 constant MINUTE_IN_SECONDS = 60;

    uint16 constant ORIGIN_YEAR = 1970;

    function isLeapYear(uint16 year) public pure returns (bool) {
        if (year % 4 != 0) {
            return false;
        }
        if (year % 100 != 0) {
            return true;
        }
        if (year % 400 != 0) {
            return false;
        }
        return true;
    }

    function leapYearsBefore(uint256 year) public pure returns (uint256) {
        year -= 1;
        return year / 4 - year / 100 + year / 400;
    }

    function getDaysInMonth(uint8 month, uint16 year)
        public
        pure
        returns (uint8)
    {
        if (
            month == 1 ||
            month == 3 ||
            month == 5 ||
            month == 7 ||
            month == 8 ||
            month == 10 ||
            month == 12
        ) {
            return 31;
        } else if (month == 4 || month == 6 || month == 9 || month == 11) {
            return 30;
        } else if (isLeapYear(year)) {
            return 29;
        } else {
            return 28;
        }
    }

    function parseTimestamp() public view returns (_DateTime memory dt) {
        uint256 timestamp = block.timestamp;

        uint256 secondsAccountedFor = 0;
        uint256 buf;
        uint8 i;

        // Year
        dt.year = getYear(timestamp);
        buf = leapYearsBefore(dt.year) - leapYearsBefore(ORIGIN_YEAR);

        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
        secondsAccountedFor += YEAR_IN_SECONDS * (dt.year - ORIGIN_YEAR - buf);

        // Month
        uint256 secondsInMonth;
        for (i = 1; i <= 12; i++) {
            secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, dt.year);
            if (secondsInMonth + secondsAccountedFor > timestamp) {
                dt.month = i;
                break;
            }
            secondsAccountedFor += secondsInMonth;
        }

        // Day
        for (i = 1; i <= getDaysInMonth(dt.month, dt.year); i++) {
            if (DAY_IN_SECONDS + secondsAccountedFor > timestamp) {
                dt.day = i;
                break;
            }
            secondsAccountedFor += DAY_IN_SECONDS;
        }

        // Hour
        dt.hour = getHour(timestamp);

        // Minute
        dt.minute = getMinute(timestamp);

        // Second
        dt.second = getSecond(timestamp);

        // Day of week.
        dt.weekday = getWeekday(timestamp);
    }

    function getYear(uint256 timestamp) internal pure returns (uint16) {
        uint256 secondsAccountedFor = 0;
        uint16 year;
        uint256 numLeapYears;

        // Year
        year = uint16(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
        numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
        secondsAccountedFor +=
            YEAR_IN_SECONDS *
            (year - ORIGIN_YEAR - numLeapYears);

        while (secondsAccountedFor > timestamp) {
            if (isLeapYear(uint16(year - 1))) {
                secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
            } else {
                secondsAccountedFor -= YEAR_IN_SECONDS;
            }
            year -= 1;
        }
        return year;
    }

    function getMonth() public view returns (uint8) {
        return parseTimestamp().month;
    }

    function getYear() public view returns (uint16) {
        return parseTimestamp().year;
    }

    function getDay() public view returns (uint8) {
        return parseTimestamp().day;
    }

    function getHour(uint256 timestamp) public pure returns (uint8) {
        return uint8((timestamp / 60 / 60) % 24);
    }

    function getMinute(uint256 timestamp) public pure returns (uint8) {
        return uint8((timestamp / 60) % 60);
    }

    function getSecond(uint256 timestamp) public pure returns (uint8) {
        return uint8(timestamp % 60);
    }

    function getWeekday(uint256 timestamp) public pure returns (uint8) {
        return uint8((timestamp / DAY_IN_SECONDS + 4) % 7);
    }

    function toTimestamp(
        uint16 year,
        uint8 month,
        uint8 day
    ) public pure returns (uint256 timestamp) {
        return toTimestamp(year, month, day, 0, 0, 0);
    }

    function toTimestamp(
        uint16 year,
        uint8 month,
        uint8 day,
        uint8 hour
    ) public pure returns (uint256 timestamp) {
        return toTimestamp(year, month, day, hour, 0, 0);
    }

    function toTimestamp(
        uint16 year,
        uint8 month,
        uint8 day,
        uint8 hour,
        uint8 minute
    ) public pure returns (uint256 timestamp) {
        return toTimestamp(year, month, day, hour, minute, 0);
    }

    function toTimestamp(
        uint16 year,
        uint8 month,
        uint8 day,
        uint8 hour,
        uint8 minute,
        uint8 second
    ) public pure returns (uint256 timestamp) {
        uint16 i;

        // Year
        for (i = ORIGIN_YEAR; i < year; i++) {
            if (isLeapYear(i)) {
                timestamp += LEAP_YEAR_IN_SECONDS;
            } else {
                timestamp += YEAR_IN_SECONDS;
            }
        }

        // Month
        uint8[12] memory monthDayCounts;
        monthDayCounts[0] = 31;
        if (isLeapYear(year)) {
            monthDayCounts[1] = 29;
        } else {
            monthDayCounts[1] = 28;
        }
        monthDayCounts[2] = 31;
        monthDayCounts[3] = 30;
        monthDayCounts[4] = 31;
        monthDayCounts[5] = 30;
        monthDayCounts[6] = 31;
        monthDayCounts[7] = 31;
        monthDayCounts[8] = 30;
        monthDayCounts[9] = 31;
        monthDayCounts[10] = 30;
        monthDayCounts[11] = 31;

        for (i = 1; i < month; i++) {
            timestamp += DAY_IN_SECONDS * monthDayCounts[i - 1];
        }

        // Day
        timestamp += DAY_IN_SECONDS * (day - 1);

        // Hour
        timestamp += HOUR_IN_SECONDS * (hour);

        // Minute
        timestamp += MINUTE_IN_SECONDS * (minute);

        // Second
        timestamp += second;

        return timestamp;
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.10;

interface IAuthority {
    /* ========== EVENTS ========== */
    event OwnerPushed(
        address indexed from,
        address indexed to,
        bool _effectiveImmediately
    );
    event OwnerPulled(address indexed from, address indexed to);
    event AddManager(address[] addrs);
    event DeleteManager(address[] addrs);

    /* ========== VIEW ========== */
    function owner() external view returns (address);

    function managers() external view returns (address[] memory);

    function addManager(address[] memory addrs) external;

    function deleteManager(address[] memory addrs) external;

    function checkIsManager(address addr) external view returns (bool, uint256);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.10;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.10;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        assert(a == b * c + (a % b)); // There is no case in which this doesn't hold

        return c;
    }

    // Only used in the  BondingCalculator.sol
    function sqrrt(uint256 a) internal pure returns (uint256 c) {
        if (a > 3) {
            c = a;
            uint256 b = add(div(a, 2), 1);
            while (b < c) {
                c = b;
                b = div(add(div(a, b), b), 2);
            }
        } else if (a != 0) {
            c = 1;
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.10;

library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function uintToString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function strConcat(string memory _a, string memory _b)
        internal
        pure
        returns (string memory)
    {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ret = new string(_ba.length + _bb.length);
        bytes memory bret = bytes(ret);
        uint256 k = 0;
        for (uint256 i = 0; i < _ba.length; i++) bret[k++] = _ba[i];
        for (uint256 i = 0; i < _bb.length; i++) bret[k++] = _bb[i];
        return string(ret);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import "../SafeMath.sol";
import "../IERC20.sol";
import "../AuthorityControlled.sol";
import "../Strings.sol";
import "../DateTime.sol";

contract Market is AuthorityControlled {
    using SafeMath for uint256;
    using Strings for string;

    struct NftRule {
        uint256     direct;             // ??????????????????????????????1000
        uint256     lock;               // ?????????
        uint256     unlock;             // ?????????
    }

    struct Reward {
        uint256     time;               // ??????????????????
        uint256     lock;               // ??????????????????
        uint256     day;                // ?????????????????????
        uint256     start;              // ?????????????????????(???)
        uint256     total;              // ?????????
        uint256     done;               // ???????????????
        uint256     await;              // ???????????????
        uint256     stage;              // ??????????????????
        uint256     cycle;              // ?????????
        uint256     past;               // ????????????
        uint256     future;             // ???????????????
        uint256     end;                // ?????????????????????(???)
    }

    DateTime    public dateTime = new DateTime();   // ??????????????????
    NftRule     public nftRule;         // NFT????????????

    uint256     public min;             // ???????????????????????????
    uint256     public max;             // ???????????????????????????
    uint256     public rate;            // ETH?????????????????????
    uint256     public total;           // ????????????????????????
    uint256     public sold;            // ???????????????
    uint256     public usable;          // ???????????????

    uint256     public asset;           // ???????????????ETH??????

    IERC20      public token;           // ???????????????
    address     public stake;           // ??????????????????
    address     public output;          // ????????????????????????

    mapping(address => Reward) rewards; // ????????????

    constructor(address authority_) AuthorityControlled(authority_){
        min = 10;
        max = 10000;
        rate = 20000000000000000;
        total = 21000000000000;
        usable = 21000000000000;
        nftRule = NftRule({
            direct: 1200, 
            lock: 3, 
            unlock: 6
        });
    }
    // ????????? ???????????? ??????
    function plan(uint256 _min, uint256 _max, uint256 _rate, uint256 _total) public returns (bool) {
        min     = _min;     // ????????????????????????????????????
        max     = _max;     // ????????????????????????????????????
        rate    = _rate;    // ??????ETH??????
        total   = _total;   // ?????????????????????
        usable  = _total;   // ??????????????????
        return true;
    }

    //?????? NFT ?????? ?????????????????????
    function setNftRule(uint256 _direct, uint256 _lock, uint256 _unlock) public returns (bool) {
        require(1 <= _direct && _direct <= 10000, "Earnings time not yet reached");
        nftRule = NftRule({
            direct  : _direct,  // ????????????????????????1000???10%, 10000???100%
            lock    : _lock,    // ????????????(???)
            unlock  : _unlock   // ????????????(???)
        });
        return true;
    }

    // ?????? ?????? ????????????
    function modify(uint8 _type, address _addr) public returns (bool) {
        if (1 == _type) {           // ???????????????
            token = IERC20(_addr);
        } else if (2 == _type) {    // ????????????
            stake = _addr;
        } else if (3 == _type) {    // ????????????
            output = _addr;
        }
        return true;
    }

    // NFT??????????????????
    function add(address _receive, uint256 _amount) public returns (bool) {
        require(stake != msg.sender, "Earnings time not yet reached");          // ????????????????????????????????????
        require(
            total > sold &&                                                     // ????????????????????????????????????
            total == sold.add(usable) &&                                        // ?????????????????????????????????????????????????????????
            usable > 0 &&                                                       // ???????????????????????????0
            usable.sub(_amount) >= 0 &&                                         // ???????????????????????????????????????????????????0
            total >= sold.add(_amount),                                         // ??????????????? + ???????????? <= ????????? 
            "Sales volume overflow");

        uint256 done = _amount.mul(nftRule.direct).div(10000);                  // ??????????????????
        uint256 await = _amount.sub(done);                                      // ??????????????????
        uint256 stage = await.div(nftRule.unlock);                              // ??????????????????

        bool flag = token.transferFrom(output, _receive, done);                 // ??? ????????? ??????
        require(flag, "Failed to make money");
        
        uint256 year = dateTime.getYear();
        uint256 month = dateTime.getMonth();
        uint256 start = year.mul(12);                                           // ???????????????????????????
        start = start.add(month);                                               // ???????????????
        start = start.add(nftRule.lock);                                        // ??????????????????(???)

        uint256 end = start.add(nftRule.unlock);
        rewards[_receive] = Reward({
            time    : block.timestamp,
            lock    : nftRule.lock,
            day     : dateTime.getDay(),
            start   : start,
            total   : _amount,
            done    : done,
            await   : await,
            stage   : stage,
            cycle   : nftRule.unlock,
            past    : 0,
            future  : nftRule.unlock,
            end     : end
        });
        sold = sold.add(_amount);                                               // ?????????????????????
        usable = usable.sub(_amount);                                           // ?????????????????????
        return true;
    }

    // ??????
    function draw() public returns (bool) {
        address addr = msg.sender;

        Reward memory reward = rewards[addr];
        require(reward.day != 0, "Do you have any rewards to receive");         // ????????????????????????

        uint256 year    = dateTime.getYear();
        uint256 month   = dateTime.getMonth();
        uint256 day     = dateTime.getDay();

        uint256 share = year.mul(12);                                           // ??????????????????
        share = share.add(month);                                               // ???????????????

        if (day < reward.day) share = share.sub(1);                             // ?????????????????????????????????????????????1
        require(
            0 < share &&                                                        // ???????????????0 
            share > reward.start,                                               // ????????????????????????????????????
            "You have no new rewards to claim");                                // ???????????????????????????????????????

        uint256 actual = share.sub(reward.start);                               // ????????????????????????????????????


        uint256 amount = actual.mul(reward.stage);                              // ??????????????????????????????

        bool flag = token.transferFrom(output, addr, amount);                   // ??? ????????? ??????
        require(flag, "Failed to make money");                                  // ????????????????????????

        rewards[addr] = Reward({
            time    : reward.time,
            lock    : reward.lock,
            day     : reward.day,
            start   : reward.start.add(share),
            total   : reward.total,
            done    : reward.done.add(amount),
            await   : reward.await.sub(amount),
            stage   : reward.stage,
            cycle   : reward.cycle,
            past    : reward.past.add(share),
            future  : reward.future.sub(share),
            end     : reward.end
        });
        return true;
    }

    // ????????????
    function open() public payable returns (bool) {
        require(0 < msg.value, "Your eth quantity is insufficient");                        // ??????ETH??????

        uint256 value = msg.value;                                                          // ??????????????? ETH ??????
        uint volume = value.div(rate);                                                      // ????????????????????????????????????

        require(min <= volume, "Purchase quantity below minimum limit");                    // ????????????????????????????????????????????????
        require(max >= volume, "Purchase quantity is higher than the maximum limit");       // ????????????????????????????????????????????????
        require(
            total   >   sold                &&                                              // ????????????????????????????????????
            total   ==  sold.add(usable)    &&                                              // ?????????????????????????????????????????????????????????
            0       <   usable              &&                                              // ???????????????????????????0
            0       <=  usable.sub(volume)  &&                                              // ???????????????????????????????????????????????????0
            total   >=  sold.add(volume),                                                   // ??????????????? + ???????????? <= ????????? 
            "Sales volume overflow");                                                       // ??????????????????????????????


        bool flag = token.transferFrom(output, msg.sender, volume);                         // 4:?????????????????????
        require(flag, "Failed to make money");                                              // ??????????????????????????????

        asset = asset.add(value);                                                           // ???????????????ETH
        sold = sold.add(volume);                                                            // ?????????????????????
        usable = usable.sub(volume);                                                        // ?????????????????????

        return true;                                                                        // 5:??????????????????
    }

    // ??????
    function withdraw(address _to) external payable returns(bool) {
        require(_to != address(0), "XCC: invalid status for withdrawn.");                   // ??????????????????????????????
        require(0 < asset, "XCC: invalid status for withdrawn.");                           // ?????? ???????????? ETH ?????????????????? 0

        payable(address(this)).transfer(asset);                                             // ?????? ETH ???????????????

		return true;                                                                        // ??????????????????
    }

}