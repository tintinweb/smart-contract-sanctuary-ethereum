/**
 *Submitted for verification at Etherscan.io on 2022-04-26
*/

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.7;

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


// File contracts/Strings.sol

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


// File contracts/DateTime.sol
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


// File contracts/IERC20_CHIMP.sol
interface IERC20_CHIMP {
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


// File contracts/IERC20_USDT.sol
interface IERC20_USDT {
    function allowance(address owner, address spender)
        external
        returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external;

    function approve(address spender, uint256 value) external;

    function totalSupply() external returns (uint256);

    function balanceOf(address who) external returns (uint256);

    function transfer(address to, uint256 value) external;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


// File contracts/IAuthority.sol
interface IAuthority {
    /* ========== EVENTS ========== */
    event OwnerPushed(
        address indexed from,
        address indexed to,
        bool _effectiveImmediately
    );
    event OwnerPulled(
        address indexed from,
        address indexed to,
        bool _effectiveImmediately
    );
    event AddApprover(address addrs);
    event DeleteApprover(address addrs);
    event SetRate(uint256 oldRate, uint256 newRate);

    /* ========== VIEW ========== */
    function owner() external view returns (address);

    function checkIsApprover(address addr) external view returns (bool, uint256);

    function approveRate() external view returns (uint256);

    function checkRate(uint256 _length) external view returns (bool);
}


// File contracts/AuthorityControlled.sols
contract AuthorityControlled {
    using SafeMath for uint256;
    
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
    
    modifier onlyApprover() {
        bool isApprover;
        uint256 idx;
        (isApprover, idx) = authority.checkIsApprover(msg.sender);
        require(isApprover, UNAUTHORIZED);
        _;
    }

    function setAuthority(address _newAuthority) external onlyOwner {
        _setAuthority(_newAuthority);
    }

    function _setAuthority(address _newAuthority) private {
        authority = IAuthority(_newAuthority);
        emit AuthorityUpdated(_newAuthority);
    }

    function checkRate(uint256 _length) public view returns (bool) {
        return authority.checkRate(_length);
    }
}


// File contracts/market/Market.sol
contract Market is AuthorityControlled {
    using SafeMath  for uint256;
    using Strings   for string;

    struct NftRule {
        uint256 direct;                                                                 // ??????????????????????????????10000
        uint256 lock;                                                                   // ?????????
        uint256 cycle;                                                                  // ?????????
    }

    struct NftRecord {
        uint256 time;                                                                   // ??????????????????
        uint256 lock;                                                                   // ??????????????????
        uint256 total;                                                                  // ?????????
        uint256 done;                                                                   // ???????????????
        uint256 await;                                                                  // ???????????????
        uint256 stage;                                                                  // ??????????????????
        uint256 cycle;                                                                  // ?????????
        uint256 past;                                                                   // ????????????
        uint256 future;                                                                 // ???????????????
        bool flag;                                                                      // ??????????????????
    }

    struct NftTime {
        uint256 year;                                                                   // ?????????????????????
        uint256 month;                                                                  // ?????????????????????
        uint256 day;                                                                    // ?????????????????????                                                                // ?????????????????????(???)
    }

    struct NftDetail {
        address addr;                                                                   // ??????????????????
        uint256 first;                                                                  // ??????????????????
        uint256 stage;                                                                  // ??????????????????
        uint256 amount;                                                                 // ?????????????????????
        uint256 time;                                                                   // ?????????
    }

    struct OpenRecord {
        address addr;                                                                   // ??????????????????
        uint256 amount;                                                                 // ??????????????????
        uint256 price;                                                                  // ?????????????????????
        uint256 volume;                                                                 // ?????????????????????(???)
        uint256 time;                                                                   // ?????????
    }

    DateTime dateTime = new DateTime();                                                 // ??????????????????
    NftRule public nftRule;                                                             // NFT????????????
    NftTime public nftTime;

    uint256 public nft_index = 0;
    uint256 public open_index = 0;

    uint256 public startTime;                                                           // ??????????????????
    uint256 public endTime;                                                             // ??????????????????

    uint256 public min;                                                                 // ???????????????????????????
    uint256 public max;                                                                 // ???????????????????????????
    uint256 public price;                                                               // ETH?????????????????????
    uint256 public total;  
    uint256 public saleTotal;
    uint256 public sold = 0;                                                            // ???????????????
    uint256 public usable;                                                              // ???????????????

    address[] public payoutApprove;
    address public payoutAddr;

    uint256 public asset;                                                               // ???????????????ETH??????

    IERC20_CHIMP    public token_chimp;                                                 // ???????????????
    IERC20_USDT     public token_usdt;                                                  // ???????????????
    address public auction;                                                             // ??????????????????
    address public output;                                                              // ????????????????????????

    mapping(address => NftRecord)   public nftRecords;                                  // ????????????
    mapping(uint256 => NftDetail)   public nftDetails;                                  // ????????????
    mapping(uint256 => OpenRecord)  public openRecords;                                 // ????????????
    mapping(address => uint8)       public whiteLists;                                  // ????????????

    constructor(address authority_, uint256 year_, uint256 month_, uint256 day_) AuthorityControlled(authority_) {
        nftTime = NftTime({
            year    : year_,
            month   : month_,
            day     : day_
        });
        startTime   = block.timestamp;                                                  // ?????????????????????
        endTime     = block.timestamp.add(8_640_000);                                   // ???????????????100???
        min         = 10_000_000;
        max         = 10_000_000_000;
        price       = 2_000_000;
        total       = 560_000_000_000_000;
        saleTotal   = 336_000_000_000_000;
        usable      = 336_000_000_000_000;
        nftRule 	= NftRule({
            direct  : 1_200, 
            lock    : 3, 
            cycle   : 6
        });
    }

    function setNftTime(uint256 year_, uint256 month_, uint256 day_) external onlyOwner {
        nftTime = NftTime({
            year    : year_,
            month   : month_,
            day     : day_
        });
    }

    // ????????? ???????????? ?????????????????????
    function range(uint8 _type, uint256 _time) public onlyOwner returns (bool) {
        require(1 == _type || 2 == _type, "Incorrect time type");
        if (1 == _type) {
            startTime = _time;
        } else if (2 == _type) {
            endTime = _time;
        } else {
            require(false, "Incorrect time type");
        }
        return true;
    }

    // ????????? ???????????? ??????
    function plan(uint256 _min, uint256 _max, uint256 _price, uint256 _total) public onlyOwner returns (bool) {
        min       = _min;                                                                 // ????????????????????????????????????
        max       = _max;                                                                 // ????????????????????????????????????
        price     = _price;                                                               // ??????ETH??????
        saleTotal = _total;                                                               // ?????????????????????
        usable    = _total.sub(sold);                                                     // ??????????????????
        return true;
    }

    // ?????? NFT ?????? ?????????????????????
    function setNftRule(uint256 _direct, uint256 _lock, uint256 _cycle) public onlyOwner returns (bool) {
        require(1 <= _direct && _direct <= 10000, "Earnings time not yet reached");
        nftRule = NftRule({
            direct  : _direct,                                                          // ????????????????????????1000???10%, 10000???100%
            lock    : _lock,                                                            // ????????????(???)
            cycle   : _cycle                                                            // ????????????(???)
        });
        return true;
    }

    // ?????? ?????? ????????????
    function modify(uint8 _type, address _addr) public onlyOwner returns (bool) {
        if (1 == _type) {
            token_chimp = IERC20_CHIMP(_addr);                                          // ???????????????
        } else if (2 == _type) {
            token_usdt = IERC20_USDT(_addr);                                            // ????????????
        } else if (3 == _type) {
            output = _addr;                                                             // ????????????
        } else if (4 == _type) {
            auction = _addr;                                                            // ????????????
        }
        return true;
    }

    // ???????????????
    function roster(uint8 _type, address _addr) public onlyOwner returns (bool) {
        require(1 == _type || 2 == _type, "Incorrect whitelist type");                  // ????????????????????????????????????
        whiteLists[_addr] = _type;
        return true;
    }

    function getAvaible(address addr) public view returns (uint256) {
        NftRecord memory nftRecord = nftRecords[addr];
        if(nftRecord.total == 0) return 0;

        uint256 avaible = 0;
        uint256 yearT   = dateTime.getYear();
        uint256 monthT  = dateTime.getMonth();
        uint256 dayT    = dateTime.getDay();
        uint256 share   = yearT.mul(12).add(monthT);                                     // ??????????????????

        uint256 start = nftTime.year.mul(12).add(nftTime.month); 
        if(dayT < nftTime.day) share = share - 1;
        if(share >= start) {
            avaible = avaible.add(nftRecord.total.mul(nftRule.direct).div(10_000));     // ????????????????????????
        }
        
        start = start.add(nftRule.lock);
        if(share >= start) {
            uint256 actual = share - start + 1;                                 // ????????????????????????????????????
            actual = actual > nftRule.cycle ? nftRule.cycle : actual;
            avaible = avaible.add(actual.mul(nftRecord.stage));                         // ??????????????????????????????
        }
        avaible = avaible.sub(nftRecord.done);
        return avaible;
    }

    // NFT??????????????????
    function add(address _receive, uint256 _amount) public returns (bool) {
        require(auction == msg.sender, "The initiator is illegal");                     // ????????????????????????????????????
        uint256 stage = (_amount.sub(_amount.mul(nftRule.direct).div(10_000))).div(nftRule.cycle); // ??????????????????

        nftRecords[_receive] = NftRecord({
            time    : block.timestamp,
            lock    : nftRule.lock,
            total   : _amount,
            done    : 0,
            await   : _amount,
            stage   : stage,
            cycle   : nftRule.cycle,
            past    : 0,
            future  : nftRule.cycle,
            flag    : false
        });
        
        nftDetails[nft_index++] = NftDetail({
            addr    : _receive,
            first   : 1,
            stage   : 0,
            amount  : 0,
            time    : block.timestamp
        });
        return true;
    }

    // ??????
    function draw() public returns (bool, uint256) {
        NftRecord memory nftRecord = nftRecords[msg.sender];
        require(nftRecord.total != 0, "Do you have any rewards to receive");                   // ????????????????????????

        uint256 yearT   = dateTime.getYear();
        uint256 monthT  = dateTime.getMonth();
        uint256 dayT    = dateTime.getDay();
        uint256 share   = yearT.mul(12).add(monthT);

        if(dayT < nftTime.day) share = share - 1;
        uint256 start  = nftTime.year.mul(12).add(nftTime.month);    
        bool firstFlag = share >= start;                     // ???????????????????????? 
        start = start.add(nftRule.lock);

        uint256 actual = share - start + 1 - nftRecord.past; // ????????????????????????????????????
        bool linearFlag = actual > 0;                        // ????????????????????????
        require((firstFlag && !nftRecord.flag) || linearFlag, "You have no new rewards to claim"); // ???????????????0??????????????????????????????????????????

        uint256 done    = nftRecord.done;                    // ??????????????????
        uint256 await   = nftRecord.await;                   // ??????????????????
        uint256 amount  = 0;
            
        if(firstFlag && !nftRecord.flag) {
            done  = nftRecord.total.mul(nftRule.direct).div(10_000);
            await = nftRecord.total.sub(done);
            amount = amount.add(done);
            require(token_chimp.transferFrom(output, msg.sender, done), "Acquisition Token failed");
        }

        if(linearFlag) {
            actual = actual > nftRecord.future ? nftRecord.future : actual;
            uint256 avaible = actual.mul(nftRecord.stage);                            
            done   = done.add(avaible);
            await  = await.sub(avaible);
            amount = amount.add(avaible);
            require(token_chimp.transferFrom(output, msg.sender, avaible), "Failed to make money");  
        }

        nftDetails[nft_index++] = NftDetail({
            addr    : msg.sender,
            first   : share >= start ? 2 : 1,
            stage   : actual,
            amount  : amount,
            time    : block.timestamp
        });
        nftRecords[msg.sender] = NftRecord({
            time    : nftRecord.time,
            lock    : nftRecord.lock,
            total   : nftRecord.total,
            done    : done,
            await   : await,
            stage   : nftRecord.stage,
            cycle   : nftRecord.cycle,
            past    : nftRecord.past.add(actual),
            future  : nftRecord.future.sub(actual),
            flag    : firstFlag
        });
        return (true, share);
    }

    // ????????????
    function open(uint256 amount) public returns (bool) {
        if(1 != whiteLists[msg.sender]) {                                               // ??????????????????
            require(startTime < block.timestamp, "Public sale has not started");        // ????????????????????????
            require(endTime > block.timestamp, "Public sale has ended");                // ????????????????????????
        }

        uint256 balance = token_usdt.balanceOf(msg.sender);                             // ??????????????? USDT ??????
        require(amount <= balance, "Insufficient actual balance");                      // ???????????????USDT??????????????????
        uint256 allowance = token_usdt.allowance(msg.sender, address(this));            // ?????????????????????USDT??????
        require(amount <= allowance, "Insufficient number of approvals");               // ?????????????????????USDT??????????????????

        uint256 volume = amount.div(price);                                             // ????????????????????????????????????
        volume = volume.mul(1_000_000); 												// ???????????????1000000

        require(min <= volume, "Purchase quantity below minimum limit");                // ????????????????????????????????????????????????
        require(max >= volume, "Purchase quantity is higher than the maximum limit");   // ????????????????????????????????????????????????

        require(
            saleTotal   >   sold                &&                                      // ????????? > ???????????????
            saleTotal   ==  sold.add(usable)    &&                                      // ????????? = ??????????????? + ???????????????
            0           <   usable              &&                                      // 0 < ???????????????
            0           <=  usable.sub(volume)  &&                                      // ???????????????????????????????????????????????????0
            saleTotal   >=  sold.add(volume),                                           // ??????????????? + ???????????? <= ?????????
            "Illegal sales"                                                             // ??????????????????
        );

        token_usdt.transferFrom(msg.sender, address(this), amount);                     // ??????

        bool flag = token_chimp.transferFrom(output, msg.sender, volume);               // ?????????????????????
        require(flag, "Failed to send platform currency");                              // ??????????????????????????????

        asset   = asset.add(amount);                                                    // ???????????????ETH
        sold    = sold.add(volume);                                                     // ?????????????????????
        usable  = usable.sub(volume);                                                   // ?????????????????????

        openRecords[open_index++] = OpenRecord({
            addr    : msg.sender,
            amount  : amount,
            price   : price,
            volume  : volume,
            time    : block.timestamp
        });

        return true;                                                                    // ??????????????????
    }

    function withdraw(address _to, uint256 amount) public virtual onlyApprover {
        require(_to != address(0), "Incorrect withdrawal address");                     // ??????????????????????????????
        require(0 < asset && amount <= asset, "Accumulated USDT deficiency");   
        bool isPayout;
        uint256 idx;
        (isPayout, idx) = checkPayout(msg.sender);
        require(!isPayout, "payout: approve payout repeat");
        payoutApprove.push(msg.sender);
        if (checkRate(payoutApprove.length)) {
            token_usdt.transfer(_to, amount);
            asset = asset.sub(amount);     
            delete payoutApprove;
            delete payoutAddr;   
            return;
        }
        if (payoutAddr == address(0)) {
            payoutAddr = _to;
        }
    }

    function checkPayout(address addr) public view returns (bool, uint256) {
        for (uint256 i = 0; i < payoutApprove.length; i++) {
            if (payoutApprove[i] == addr) {
                return (true, i);
            }
        }
        return (false, 0);
    }
}