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
        uint256     direct;             // 直接解锁到账，分母是1000
        uint256     lock;               // 锁定期
        uint256     unlock;             // 解锁期
    }

    struct Reward {
        uint256     time;               // 奖励创建时间
        uint256     lock;               // 奖励锁定时间
        uint256     day;                // 开始计息的天份
        uint256     start;              // 开始计息的位置(月)
        uint256     total;              // 总数量
        uint256     done;               // 已发放数量
        uint256     await;              // 未发放数量
        uint256     stage;              // 每期发放数量
        uint256     cycle;              // 总周期
        uint256     past;               // 发放周期
        uint256     future;             // 未发放周期
        uint256     end;                // 截止计息的位置(月)
    }

    DateTime    public dateTime = new DateTime();   // 时间处理工具
    NftRule     public nftRule;         // NFT拍卖规则

    uint256     public min;             // 公开销售最小买入量
    uint256     public max;             // 公开销售最大买入量
    uint256     public rate;            // ETH兑换平台币比例
    uint256     public total;           // 公开销售最大数量
    uint256     public sold;            // 已卖出数量
    uint256     public usable;          // 未卖出数量

    uint256     public asset;           // 累计收到的ETH数量

    IERC20      public token;           // 平台币合约
    address     public stake;           // 质押合约地址
    address     public output;          // 平台币拥有者地址

    mapping(address => Reward) rewards; // 领奖列表

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
    // 初始化 公开售卖 规则
    function plan(uint256 _min, uint256 _max, uint256 _rate, uint256 _total) public returns (bool) {
        min     = _min;     // 公开售卖专用，最少购买量
        max     = _max;     // 公开售卖专用，最多购买量
        rate    = _rate;    // 折合ETH价格
        total   = _total;   // 总卖出数量限制
        usable  = _total;   // 剩余售卖数量
        return true;
    }

    //设置 NFT 拍卖 奖励平台币规则
    function setNftRule(uint256 _direct, uint256 _lock, uint256 _unlock) public returns (bool) {
        require(1 <= _direct && _direct <= 10000, "Earnings time not yet reached");
        nftRule = NftRule({
            direct  : _direct,  // 直接解锁百分比，1000是10%, 10000是100%
            lock    : _lock,    // 锁仓时长(月)
            unlock  : _unlock   // 释放时长(月)
        });
        return true;
    }

    // 修改 外部 合约地址
    function modify(uint8 _type, address _addr) public returns (bool) {
        if (1 == _type) {           // 平台币合约
            token = IERC20(_addr);
        } else if (2 == _type) {    // 质押地址
            stake = _addr;
        } else if (3 == _type) {    // 提现地址
            output = _addr;
        }
        return true;
    }

    // NFT拍卖数量进入
    function add(address _receive, uint256 _amount) public returns (bool) {
        require(stake != msg.sender, "Earnings time not yet reached");          // 检查是否是由拍卖合约调用
        require(
            total > sold &&                                                     // 已发放数量必须小于总数量
            total == sold.add(usable) &&                                        // 已发放数量加上未发放数量必须等于总数量
            usable > 0 &&                                                       // 未发放数量必须大于0
            usable.sub(_amount) >= 0 &&                                         // 可用数量减去购买数量必须大于或等于0
            total >= sold.add(_amount),                                         // 已发放数量 + 领取数量 <= 总数量 
            "Sales volume overflow");

        uint256 done = _amount.mul(nftRule.direct).div(10000);                  // 直接解锁数量
        uint256 await = _amount.sub(done);                                      // 剩余解锁数量
        uint256 stage = await.div(nftRule.unlock);                              // 每期解锁数量

        bool flag = token.transferFrom(output, _receive, done);                 // 我 秦始皇 打钱
        require(flag, "Failed to make money");
        
        uint256 year = dateTime.getYear();
        uint256 month = dateTime.getMonth();
        uint256 start = year.mul(12);                                           // 根据年份换算成月份
        start = start.add(month);                                               // 加上当前月
        start = start.add(nftRule.lock);                                        // 加上锁定时长(月)

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
        sold = sold.add(_amount);                                               // 增加已卖出数量
        usable = usable.sub(_amount);                                           // 减少未卖出数量
        return true;
    }

    // 领奖
    function draw() public returns (bool) {
        address addr = msg.sender;

        Reward memory reward = rewards[addr];
        require(reward.day != 0, "Do you have any rewards to receive");         // 你没有奖励可领取

        uint256 year    = dateTime.getYear();
        uint256 month   = dateTime.getMonth();
        uint256 day     = dateTime.getDay();

        uint256 share = year.mul(12);                                           // 年份转为月份
        share = share.add(month);                                               // 加上当前月

        if (day < reward.day) share = share.sub(1);                             // 如果今天小于领奖的天，则月份减1
        require(
            0 < share &&                                                        // 月份要大于0 
            share > reward.start,                                               // 月份要大于上次领取的月份
            "You have no new rewards to claim");                                // 您还没有产生新的奖励可领取

        uint256 actual = share.sub(reward.start);                               // 计算实际可领取奖励的月份


        uint256 amount = actual.mul(reward.stage);                              // 计算可领取的奖励数量

        bool flag = token.transferFrom(output, addr, amount);                   // 我 秦始皇 打钱
        require(flag, "Failed to make money");                                  // 检查打钱是否成功

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

    // 公开售卖
    function open() public payable returns (bool) {
        require(0 < msg.value, "Your eth quantity is insufficient");                        // 你的ETH不足

        uint256 value = msg.value;                                                          // 获取用户的 ETH 数量
        uint volume = value.div(rate);                                                      // 计算能买到多少数量的代币

        require(min <= volume, "Purchase quantity below minimum limit");                    // 检查购买数量是否大于最小购买数量
        require(max >= volume, "Purchase quantity is higher than the maximum limit");       // 检查购买数量是否小于最大购买数量
        require(
            total   >   sold                &&                                              // 已发放数量必须小于总数量
            total   ==  sold.add(usable)    &&                                              // 已发放数量加上未发放数量必须等于总数量
            0       <   usable              &&                                              // 未发放数量必须大于0
            0       <=  usable.sub(volume)  &&                                              // 可用数量减去购买数量必须大于或等于0
            total   >=  sold.add(volume),                                                   // 已发放数量 + 领取数量 <= 总数量 
            "Sales volume overflow");                                                       // 检查公开售卖条件限制


        bool flag = token.transferFrom(output, msg.sender, volume);                         // 4:向用户发送代币
        require(flag, "Failed to make money");                                              // 检查代币是否发送成功

        asset = asset.add(value);                                                           // 累加收到的ETH
        sold = sold.add(volume);                                                            // 增加已卖出数量
        usable = usable.sub(volume);                                                        // 减少未卖出数量

        return true;                                                                        // 5:返回购买成功
    }

    // 提现
    function withdraw(address _to) external payable returns(bool) {
        require(_to != address(0), "XCC: invalid status for withdrawn.");                   // 检查接收地址是否合法
        require(0 < asset, "XCC: invalid status for withdrawn.");                           // 检查 未提取的 ETH 数量是否大于 0

        payable(address(this)).transfer(asset);                                             // 提取 ETH 到指定地址

		return true;                                                                        // 返回执行状态
    }

}