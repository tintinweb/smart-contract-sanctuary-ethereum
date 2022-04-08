/**
 *Submitted for verification at Etherscan.io on 2022-04-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

interface IERC721Enumerable is IERC721 {

    function totalSupply() external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) external view returns (uint256);
}

library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface IDOGERC721 is IERC721Enumerable{
    function mint(string memory uri) external payable;
    function onlyOwnerMint(string memory uri) external;
    function batchTrans(address[] memory receives,uint256[] memory tokens) external;
    function tokenURI(uint256 tokenId) external view  returns (string memory);
    function transfer(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

interface IDOGERC20 is IERC20{
    function mint(address sender,uint256 amount) external;
    function batchTrans(address[] memory receives,uint256 amount) external;
}

abstract contract DepositNFTEnumerable{
    mapping(address => uint256[]) private _depositTokens;
    mapping(address => uint) private _depositTokenIndex;

    function _addDepositToken(address owner, uint256 tokenId) internal virtual{
        uint index = _depositTokenIndex[owner];

        if(index > 0){
            uint le = _depositTokens[owner].length;
            if(le > index){
                _depositTokens[owner][index] = tokenId; 
            }else{
                _depositTokens[owner].push(tokenId); 
            }
            _depositTokenIndex[owner] += 1;
        }else{
            _depositTokens[owner].push(tokenId);
            _depositTokenIndex[owner] = 1;
        }
    }

    function _burnDepositToken(address owner,uint256 tokenId) internal virtual {
        uint tokenIndex = _depositOwnerTokenIndex(owner,tokenId);
        if(tokenIndex > 0){
            _burnDepositTokenIndex(owner,tokenIndex);
        }
    }

    function _burnDepositTokenIndex(address owner, uint index) internal {
        uint256 tokenIndex = _depositTokenIndex[owner];

        if(tokenIndex > 0){
            uint256 lastTokenid = _depositTokenOfOwnerByIndex(owner,tokenIndex-1);

            if (tokenIndex > index) {
                _depositTokens[owner][index-1] = lastTokenid;
            }
            delete _depositTokens[owner][tokenIndex-1];
            _depositTokenIndex[owner] -= 1;
        }
    }

    function depositOwnerTokenList(address owner) external view returns (uint256[] memory) {
        uint256 tokenIndex = _depositTokenIndex[owner];
        uint256[] memory tokens = new uint256[](tokenIndex);
        if(tokenIndex > 0){
            for(uint i=0;i<tokenIndex;i++){
                tokens[i] = _depositTokens[owner][i];
            }
        }
        return tokens;
    }
    function _depositTokenOfOwnerByIndex(address owner, uint index) internal view returns (uint256) {
        return _depositTokens[owner][index];
    }
    function _depositOwnerTokenIndex(address owner, uint256 tokenId) internal view returns (uint256 index) {
        uint tokenIndex = _depositTokenIndex[owner];
        if(tokenIndex > 0){
            for(uint i=1;i<=tokenIndex;i++){
                if(_depositTokens[owner][i-1]==tokenId){
                    index = i;
                    break;
                }
            }
        }
    }
    function _getOwnerTokenIndex(address owner) internal view returns (uint256 index) {
         return _depositTokenIndex[owner];
    }
    
}

abstract contract DeposiNFTTimeEnumerable{
    mapping(address => mapping(uint256 => uint32)) private _depositTimes;

    function _depositTokenTime(address owner,uint256 tokenId) internal view returns (uint32){
        return _depositTimes[owner][tokenId]; 
    }

    function _addDepositTokenTime(address owner, uint256 tokenId,uint32 tokenTime)  internal virtual {
          _depositTimes[owner][tokenId] = tokenTime;
    }
    function _removeDepositTokenTime(address owner, uint256 tokenId)  internal virtual {
        delete _depositTimes[owner][tokenId];
    }

    function isDeposit(address caster,uint256 tokenId) internal view returns (bool) {
        if(_depositTokenTime(caster,tokenId) >0 ){
            return true;
        }else{
            return false;
        }  
    }
}

abstract contract DeposiDaiTimeEnumerable {
    mapping(address => uint256) private _depositDais;
    mapping(address => uint32) private _depositDaiTimes;

    function _addDepositAmountTime(address own,uint256 amount) internal{
        uint256 pamount = _depositDais[own]; 

        _depositDais[own] = pamount + amount;
        _depositDaiTimes[own] = uint32(block.timestamp % 2 ** 32);
    }
    function _removeDepositAmountTime(address own,uint256 amount) internal{
        uint256 pamount = _depositDais[own];
        pamount = pamount - amount;

        if(pamount > 0){
            _depositDais[own] = pamount;
            _depositDaiTimes[own] = uint32(block.timestamp % 2 ** 32);
        }else{
            delete _depositDais[own];
            delete _depositDaiTimes[own];
        }
    }

    function _getDepositAmountTime(address own) internal view returns(uint32) {
        return _depositDaiTimes[own];
    }
    function _setDepositAmountTime(address own) internal {
        _depositDaiTimes[own] = uint32(block.timestamp % 2 ** 32);
    }

    function _getDepositAmount(address own) internal view returns(uint){
        return _depositDais[own];
    }

}

interface IDOGRouter {
    function depositNFT(uint256 tokenId) external;
    function retrieveNFT(uint256 tokenId) external;
    function extractNFTDai(uint256 tokenId) external;
    function findDepositNFTToDai(uint256 tokenId)
        external
		view
		returns (uint256 amount);
    function findOwnDepositNFTToDai(address own) 
        external
		view
		returns  (uint256 amount);
    function findOwnerNFTTokens(address owner) 
        external
        view
		returns (uint256[] memory,string[] memory,uint32[] memory);
    function depositDai(uint256 amount) external;
    function retrieveDai(uint256 amount) external;
    function extractDai(uint256 amount) external;
    function findGainDai(address own) external view  returns (uint256 amount);
    function findDepositDai(address own) external view  returns (uint256 amount);
}

contract DOGRouter is IDOGRouter, DepositNFTEnumerable, DeposiNFTTimeEnumerable,DeposiDaiTimeEnumerable{
    address private nftAddress;
    address private daiAddress;
    uint32  private blockStartTime;

    uint32 constant private DAY_PROFIT = 300000;
    uint8 constant private PDOG_PRV = 1;
    uint16 constant private PDOG_PRV_M = 100;

    constructor(address _nftAddress,address _daiAddress) {
        nftAddress = _nftAddress;
        daiAddress = _daiAddress;
        blockStartTime = uint32(block.timestamp % 2 ** 32);
    }

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'DepositDai: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function depositNFT(uint256 tokenId) external override lock {
        require(msg.sender == IDOGERC721(nftAddress).ownerOf(tokenId), "ERC721: transfer of token that is not own");
        require(isDeposit(msg.sender,tokenId) == false, "ERC721: deposit query for existent token");
        IDOGERC721(nftAddress).transfer(msg.sender,address(this),tokenId);
        addDepositToken(tokenId);
    }

    function retrieveNFT(uint256 tokenId) external override lock {
        uint32 starTime = _depositTokenTime(msg.sender,tokenId);
        require(starTime > 0, "ERC721: deposit query for nonexistent token");

        require(address(this) == IDOGERC721(nftAddress).ownerOf(tokenId), "ERC721: transfer of token that is not own");
        require(isDeposit(msg.sender,tokenId), "ERC721: deposit query for existent token");

        uint32 endTime = uint32(block.timestamp % 2 ** 32);
        uint256 amount = CalProfitMath.calStepProfitAmount(blockStartTime,starTime,endTime,DAY_PROFIT);

        if(amount > 0 ){
           IDOGERC20(daiAddress).mint(msg.sender,amount);
        }

        IDOGERC721(nftAddress).transferFrom(address(this),msg.sender,tokenId);
        removeDepositToken(tokenId);
    }

    function extractNFTDai(uint256 tokenId) external override lock{
        uint32 starTime = _depositTokenTime(msg.sender,tokenId);
        require(starTime > 0, "ERC721: deposit query for nonexistent token");

        require(address(this) == IDOGERC721(nftAddress).ownerOf(tokenId), "ERC721: transfer of token that is not own");
        require(isDeposit(msg.sender,tokenId), "ERC721: deposit query for existent token");

        uint32 endTime = uint32(block.timestamp % 2 ** 32);
        uint256 amount = CalProfitMath.calStepProfitAmount(blockStartTime,starTime,endTime,DAY_PROFIT);

        if(amount > 0 ){
            IDOGERC20(daiAddress).mint(msg.sender,amount);
            _addDepositTokenTime(msg.sender,tokenId,uint32(block.timestamp % 2 ** 32));
        }
    }

    function findDepositNFTToDai(uint256 tokenId)
        public
		view
		virtual override returns (uint256 amount) {
        uint32 starTime = _depositTokenTime(msg.sender,tokenId);
        require(starTime > 0, "ERC721: deposit query for nonexistent token");

        uint32 endTime = uint32(block.timestamp % 2 ** 32);
        amount = CalProfitMath.calStepProfitAmount(blockStartTime,starTime,endTime,DAY_PROFIT);
    }

    function findOwnDepositNFTToDai(address own) 
        public
		view
		virtual override returns  (uint256 amount) {
        (uint256[] memory _tokens,,uint32[] memory _pledgeTimes) = findOwnerNFTTokens(own);
        require(_tokens.length > 0, "ERC721: pledge query for nonexistent token");

        uint32 endTime = uint32(block.timestamp % 2 ** 32);
        uint len = _tokens.length;
        for(uint i=0;i<len;i++){
            amount += CalProfitMath.calStepProfitAmount(blockStartTime,_pledgeTimes[i],endTime,DAY_PROFIT);
        }
    }

    function findOwnerNFTTokens(address owner) 
        public
        view
		virtual
		override
		returns (uint256[] memory,string[] memory,uint32[] memory){
        uint tokenIndex = _getOwnerTokenIndex(owner);
      
        uint256[] memory _tokens = new uint256[](tokenIndex);
        string[] memory _URIs = new string[](tokenIndex);
        uint32[] memory _pledgeTimes = new uint32[](tokenIndex);

        uint j = 0;
        for(uint i=1;i<=tokenIndex;i++){
            uint256 tokenId = _depositTokenOfOwnerByIndex(owner,i);
            if(tokenId > 0){
                _tokens[j] = tokenId;
                _URIs[j] = IDOGERC721(nftAddress).tokenURI(tokenId);
                _pledgeTimes[j] = _depositTokenTime(owner,tokenId); 
                j++;
            }
        }
        return (_tokens,_URIs,_pledgeTimes);
    }

    function depositDai(uint256 amount) external override lock {
        require(amount < IDOGERC20(daiAddress).balanceOf(msg.sender), "pledge CDOG amount not enough");

        uint32 starTime = _getDepositAmountTime(msg.sender);
        if(starTime > 0){
            uint256 pamount =  _getDepositAmount(msg.sender); 
            uint256 pgamount = CalProfitMath.colProfitAmount(starTime,uint32(block.timestamp % 2 ** 32),pamount,PDOG_PRV,PDOG_PRV_M);
            if(pgamount > 0){
                IDOGERC20(daiAddress).mint(msg.sender,pgamount);
            } 
        }
        IDOGERC20(daiAddress).transferFrom(msg.sender,address(this),amount);
        _addDepositAmountTime(msg.sender,amount);
    }

    function retrieveDai(uint256 amount) external override lock {
        uint256 pamount = _getDepositAmount(msg.sender);
        require(pamount > 0 && amount <= pamount, "deposit CDOG amount not enough"); 

        uint32 starTime = _getDepositAmountTime(msg.sender);
        if(starTime > 0){
            uint256 pgamount = CalProfitMath.colProfitAmount(starTime,uint32(block.timestamp % 2 ** 32),pamount,PDOG_PRV,PDOG_PRV_M);
            if(pgamount > 0){
                 IDOGERC20(daiAddress).mint(msg.sender,pgamount);
            }
        }
        IDOGERC20(daiAddress).transferFrom(address(this),msg.sender,amount);
        _removeDepositAmountTime(msg.sender,amount);
    }

    function extractDai(uint256 amount) external override lock {
        uint256 pamount = _getDepositAmount(msg.sender);
        require(pamount > 0 && amount <= pamount, "deposit CDOG amount not enough"); 

        uint32 starTime = _getDepositAmountTime(msg.sender);
        if(starTime > 0){
            uint256 pgamount = CalProfitMath.colProfitAmount(starTime,uint32(block.timestamp % 2 ** 32),pamount,PDOG_PRV,PDOG_PRV_M);
            if(pgamount > 0){
                 IDOGERC20(daiAddress).mint(msg.sender,pgamount);
            }
        }
        _removeDepositAmountTime(msg.sender,amount);
    }

    function findGainDai(address own)
        public
		view
		virtual override returns (uint256 amount) {
        uint32 starTime =  _getDepositAmountTime(own);

        if(starTime < 1){
            amount = 0;
            return 0;
        }

        uint32 endTime = uint32(block.timestamp % 2 ** 32);
        uint256 pamount = _getDepositAmount(own);
        amount = CalProfitMath.colProfitAmount(starTime,endTime,pamount,PDOG_PRV,PDOG_PRV_M);
    }

    function findDepositDai(address own)
        public
		view
		virtual override returns (uint256 amount) {
        uint32 starTime =  _getDepositAmountTime(own);
        if(starTime < 1){
            amount = 0;
            return 0;
        }
        amount = _getDepositAmount(own);
    }

    function addDepositToken(uint256 tokenId)  internal virtual {
        uint32 blocktime = uint32(block.timestamp % 2 ** 32);
        _addDepositTokenTime(msg.sender,tokenId,blocktime);
        _addDepositToken(msg.sender,tokenId);
    }

    function removeDepositToken(uint256 tokenId)  internal virtual {
        _removeDepositTokenTime(msg.sender,tokenId);
        _burnDepositToken(msg.sender,tokenId);
    }
    
}

library CalProfitMath {
    uint constant SECONDS_PER_DAY = 24 * 60 * 60;

    function calStepProfit(uint256 amount, uint8 p, uint8 d) internal pure returns (uint256 z) {
        z = SafeMath.mul(amount,p);
        z = SafeMath.div(z,d);
    }
    function calProfit(uint256 dayProfit, uint second) internal pure returns (uint256 z) {
        z = SafeMath.mul(dayProfit,second);
        z = SafeMath.div(z,SECONDS_PER_DAY);
    }

    function calStepProfitAmount(uint32 blockStartTime, uint32 startime, uint32 endtime,uint32 DAY_PROFIT) internal pure returns (uint256 totalAmount) {
        totalAmount = 0;
        uint32 stepTime = blockStartTime;
        uint256 stepAmount = DAY_PROFIT;
        uint8 step = 0;
        while(true){
            stepTime = uint32(DateUtil.addMonths(stepTime,1) % 2 ** 32);
            if(stepTime > startime){
                if(endtime < stepTime){
                    totalAmount = SafeMath.add(totalAmount,calProfit(stepAmount,SafeMath.sub(endtime,startime)));
                    break;
                }else{
                    totalAmount = SafeMath.add(totalAmount,calProfit(stepAmount,SafeMath.sub(stepTime,startime)));
                    startime = stepTime;
                } 
            }
            if(step < 12){
                stepAmount = calStepProfit(stepAmount,95,100);
                step++;
            }
        }
        return totalAmount;
    }
    function colProfitAmount(uint32 startime, uint32 endtime, uint256 depositAmount, uint256 m, uint256 d) internal pure returns (uint256 totalAmount) {
        uint dayAmount = SafeMath.div(SafeMath.mul(depositAmount,m),d);
        totalAmount = calProfit(dayAmount,SafeMath.sub(endtime,startime));
        return totalAmount;
    }
}

library DateUtil {
    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_MINUTE = 60;
    int constant OFFSET19700101 = 2440588;
 
    uint constant DOW_MON = 1;
    uint constant DOW_TUE = 2;
    uint constant DOW_WED = 3;
    uint constant DOW_THU = 4;
    uint constant DOW_FRI = 5;
    uint constant DOW_SAT = 6;
    uint constant DOW_SUN = 7;

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(uint year, uint month, uint day) internal pure returns (uint _days) {
        require(year >= 1970);
        int _year = int(year);
        int _month = int(month);
        int _day = int(day);
 
        int __days = _day
          - 32075
          + 1461 * (_year + 4800 + (_month - 14) / 12) / 4
          + 367 * (_month - 2 - (_month - 14) / 12 * 12) / 12
          - 3 * ((_year + 4900 + (_month - 14) / 12) / 100) / 4
          - OFFSET19700101;
 
        _days = uint(__days);
    }
 
    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);
 
        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;
 
        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }
 
    function timestampFromDate(uint year, uint month, uint day) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }
    function timestampFromDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR + minute * SECONDS_PER_MINUTE + second;
    }
    function timestampToDate(uint timestamp) internal pure returns (uint year, uint month, uint day) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function timestampToDateTime(uint timestamp) internal pure returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }


 
    function isValidDate(uint year, uint month, uint day) internal pure returns (bool valid) {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }
    function isValidDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (bool valid) {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }
    function isLeapYear(uint timestamp) internal pure returns (bool leapYear) {
        (uint year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }
    function _isLeapYear(uint year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }
    function isWeekDay(uint timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }
    function isWeekEnd(uint timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }
    function getDaysInMonth(uint timestamp) internal pure returns (uint daysInMonth) {
        (uint year, uint month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }
    function _getDaysInMonth(uint year, uint month) internal pure returns (uint daysInMonth) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }
    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint timestamp) internal pure returns (uint dayOfWeek) {
        uint _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = (_days + 3) % 7 + 1;
    }
 
    function getYear(uint timestamp) internal pure returns (uint year) {
        (year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getMonth(uint timestamp) internal pure returns (uint month) {
        (,month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getDay(uint timestamp) internal pure returns (uint day) {
        (,,day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getHour(uint timestamp) internal pure returns (uint hour) {
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }
    function getMinute(uint timestamp) internal pure returns (uint minute) {
        uint secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }
    function getSecond(uint timestamp) internal pure returns (uint second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }
 
    function addYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = (month - 1) % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }
    function addMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }
    function addSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }
 
    function subYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = yearMonth % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }

    function subDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }
    function subMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }
    function subSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }
 
    function diffYears(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _years) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear,,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear,,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }
    function diffMonths(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _months) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear, uint fromMonth,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear, uint toMonth,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }
    function diffDays(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }
    function diffHours(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _hours) {
        require(fromTimestamp <= toTimestamp);
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }
    function diffMinutes(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _minutes) {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }
    function diffSeconds(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _seconds) {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
    }
}