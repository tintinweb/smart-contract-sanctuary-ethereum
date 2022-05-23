/**
 *Submitted for verification at Etherscan.io on 2022-05-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}


interface IDDFERC721Factory {
    function getPair(address token) external view returns (address pair);
}

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function balanceOf(address owner) external view returns (uint256 balance);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function totalSupply() external view returns (uint256);
    function getApproved(uint256 tokenId) external view returns (address operator);
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function approve(address to, uint256 tokenId) external;
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IDDFERC721PoolPair is IERC721{
    function mint(address owner, uint256 tokenId) external;
    function burn(address owner, uint256 lpTokenId) external;
    function updateTokenTime(address owner, uint256 lpTokenId) external;
    function tokenInfo(uint256 lpTokenId) external view returns (uint32, uint32, uint32);
}

interface IDDFERC721Router {
    function deposit(address token, uint256 tokenId) external;
    function withdraw(address token, uint256 lpTokenId) external;
    function withdrawAll(address token) external;
    function receiveInterest(address token,uint256 lpTokenId) external;
    function receiveAllInterest(address token) external;
    function findAllDeposit(address token)
        external
		view
        returns (uint256 amount);
    function findInterest(address token, uint256 lpTokenId)
        external
		view
		returns (uint256 amount);
    function findLPTokens(address token, address account) 
        external
        view
		returns (uint256[] memory _lpTokens, string[] memory _URIs, uint256[] memory _amounts, bool[] memory approvals);
    function findTokens(address token, address account)
        external 
        view 
        returns (uint256[] memory tokens, string[] memory tokenURIs, bool[] memory approvals);
}

contract DDFERC721Router is IDDFERC721Router {
    address public factory;
    address public ddfAddress;

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'DDF: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor(address _factory, address _ddfAddress) {
        factory = _factory;
        ddfAddress = _ddfAddress;
    }

    function deposit(address token, uint256 tokenId) external lock override {
        address pair = IDDFERC721Factory(factory).getPair(token);
        require(pair != address(0), "DDFRouter: pair nonexistent");
        require(IERC721(token).ownerOf(tokenId) == msg.sender, "DDFRouter: transfer of token that is not owner");

        IERC721(token).transferFrom(msg.sender,address(this),tokenId);
        IERC721(token).approve(pair,tokenId);
        IDDFERC721PoolPair(pair).mint(msg.sender, tokenId);
    }

    function withdraw(address token, uint256 lpTokenId) external lock override {
        address pair = IDDFERC721Factory(factory).getPair(token);
        require(pair != address(0), "DDFRouter: pair nonexistent");
        require(IDDFERC721PoolPair(pair).ownerOf(lpTokenId) == msg.sender, "DDFRouter: withdraw  of lpTokenId that is not owner"); 

        (uint32 blockStartTime, uint32 startTime, uint32 reward) = IDDFERC721PoolPair(pair).tokenInfo(lpTokenId);
        uint32 endTime = uint32(block.timestamp % 2 ** 32);
        uint256 ddfAmount = CalProfitMath.calStepProfitAmount(blockStartTime,startTime,endTime,reward);
        if(ddfAmount > 0 ){
            IERC20(ddfAddress).transferFrom(ddfAddress, msg.sender,ddfAmount);
        }

        IDDFERC721PoolPair(pair).burn(msg.sender, lpTokenId);
    }

    function withdrawAll(address token) external lock override {
        address pair = IDDFERC721Factory(factory).getPair(token);
        require(pair != address(0), "DDFRouter: pair nonexistent");
        require(IDDFERC721PoolPair(pair).isApprovedForAll(msg.sender,address(this)), "DDFRouter: approve caller is not owner nor approved for all"); 

        uint len = IDDFERC721PoolPair(pair).balanceOf(msg.sender);
        if(len > 0){
            uint256 lpTokenId;
            uint256 ddfAmount;
            uint32 endTime = uint32(block.timestamp % 2 ** 32);
            (uint32 blockStartTime, uint32 startTime, uint32 interestRate) = (0,0,0);
            for(uint i=0;i<len;i++){
                lpTokenId = IDDFERC721PoolPair(pair).tokenOfOwnerByIndex(msg.sender, 0); 
                (blockStartTime, startTime, interestRate) = IDDFERC721PoolPair(pair).tokenInfo(lpTokenId);
                ddfAmount = CalProfitMath.calStepProfitAmount(blockStartTime,startTime,endTime,interestRate);
                if(ddfAmount > 0 ){
                    IERC20(ddfAddress).transferFrom(ddfAddress, msg.sender,ddfAmount);
                }
                IDDFERC721PoolPair(pair).burn(msg.sender, lpTokenId);
            }
        }
    }

    function receiveInterest(address token,uint256 lpTokenId) external lock override {
        address pair = IDDFERC721Factory(factory).getPair(token);
        require(pair != address(0), "DDFRouter: pair nonexistent");
        require(IDDFERC721PoolPair(pair).ownerOf(lpTokenId) == msg.sender, "DDFRouter: retrieve  of token that is not owner"); 

        (uint32 blockStartTime, uint32 startTime, uint32 interestRate) = IDDFERC721PoolPair(pair).tokenInfo(lpTokenId);
        uint32 endTime = uint32(block.timestamp % 2 ** 32);
        uint256 ddfAmount = CalProfitMath.calStepProfitAmount(blockStartTime,startTime,endTime,interestRate);
        if(ddfAmount > 0 ){
            IERC20(ddfAddress).transferFrom(ddfAddress, msg.sender,ddfAmount);
        }
        IDDFERC721PoolPair(pair).updateTokenTime(msg.sender, lpTokenId);
    }

    function receiveAllInterest(address token) external lock override {
        address pair = IDDFERC721Factory(factory).getPair(token);
        require(pair != address(0),"DDFRouter: pair nonexistent");
        require(IDDFERC721PoolPair(pair).isApprovedForAll(msg.sender,address(this)), "DDFRouter: approve caller is not owner nor approved for all"); 

        uint len = IDDFERC721PoolPair(pair).balanceOf(msg.sender);
        if(len > 0){
            uint256 lpTokenId;
            uint256 ddfAmount;
            uint32 endTime = uint32(block.timestamp % 2 ** 32);
            (uint32 blockStartTime, uint32 startTime, uint32 interestRate) = (0,0,0);
            for(uint i=0;i<len;i++){
                lpTokenId = IDDFERC721PoolPair(pair).tokenOfOwnerByIndex(msg.sender, i);
                (blockStartTime, startTime, interestRate) = IDDFERC721PoolPair(pair).tokenInfo(lpTokenId);
                ddfAmount = CalProfitMath.calStepProfitAmount(blockStartTime,startTime,endTime,interestRate);
                if(ddfAmount > 0 ){
                    IERC20(ddfAddress).transferFrom(ddfAddress, msg.sender,ddfAmount);
                }
                IDDFERC721PoolPair(pair).updateTokenTime(msg.sender, lpTokenId);
            }
        }
    }

    function findAllDeposit(address token)
        public
		view
        override
        returns (uint256 amount) {
            address pair = IDDFERC721Factory(factory).getPair(token);
            require(pair != address(0), "DDFRouter: pair nonexistent");
            amount = IDDFERC721PoolPair(pair).totalSupply();
    }

    function findInterest(address token, uint256 lpTokenId)
        public
		view
        virtual
        override
		returns (uint256 amount){
            address pair = IDDFERC721Factory(factory).getPair(token);
            require(pair != address(0), "DDFRouter: pair nonexistent");

            (uint32 blockStartTime, uint32 startTime, uint32 interestRate) = IDDFERC721PoolPair(pair).tokenInfo(lpTokenId);

            if(startTime > 0){
                uint32 endTime = uint32(block.timestamp % 2 ** 32);
                amount = CalProfitMath.calStepProfitAmount(blockStartTime,startTime,endTime,interestRate);
            }
    }

    function findLPTokens(address token, address account) 
        public
        view
		virtual
        override
		returns (uint256[] memory _lpTokens, string[] memory _URIs, uint256[] memory _amounts, bool[] memory approvals){
            address pair = IDDFERC721Factory(factory).getPair(token);
            require(pair != address(0), "DDFRouter: pair nonexistent");

            uint256 len = IDDFERC721PoolPair(pair).balanceOf(account);
            if(len > 0){
                _lpTokens = new uint256[](len); 
                _URIs = new string[](len);
                _amounts = new uint256[](len); 
                approvals = new bool[](len);

                uint32 startTime;
                uint32 blockStartTime;
                uint32 interestRate;
                uint32 endTime = uint32(block.timestamp % 2 ** 32);
                uint256 _lpTokenId;
                for(uint32 i=0;i<len;i++){
                    _lpTokenId = IDDFERC721PoolPair(pair).tokenOfOwnerByIndex(account, i);
                    (blockStartTime, startTime, interestRate) = IDDFERC721PoolPair(pair).tokenInfo(_lpTokenId); 
                    _lpTokens[i] = _lpTokenId;
                    _URIs[i] = IDDFERC721PoolPair(pair).tokenURI(_lpTokenId);
                    _amounts[i] = CalProfitMath.calStepProfitAmount(blockStartTime, startTime, endTime, interestRate);
                    if(IDDFERC721PoolPair(pair).getApproved(_lpTokenId) == address(this)){
                        approvals[i] = true;
                    }else{
                        approvals[i] = false;
                    }
                }
            }
    }

    function findTokens(address token, address account)
        public 
        view 
        virtual 
        override
        returns (uint256[] memory tokens, string[] memory tokenURIs, bool[] memory approvals) {
            uint256 len = IERC721(token).balanceOf(account);

            if(len >0){
                tokens = new uint256[](len); 
                tokenURIs  = new string[](len);
                approvals = new bool[](len);
                for(uint i=0;i<len;i++){
                    tokens[i] = IERC721(token).tokenOfOwnerByIndex(account, i);
                    tokenURIs[i] = IERC721(token).tokenURI(tokens[i]);
                    if(IERC721(token).getApproved(tokens[i]) == address(this)){
                        approvals[i] = true;
                    }else{
                        approvals[i] = false;
                    }
                }
            }
    }

}

library CalProfitMath {
    uint constant SECONDS_PER_DAY = 24 * 60 * 60;

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

    function calStepProfit(uint256 amount, uint8 p, uint8 d) internal pure returns (uint256 z) {
        z = mul(amount,p);
        z = div(z,d);
    }
    function calProfit(uint256 dayProfit, uint second) internal pure returns (uint256 z) {
        z = mul(dayProfit,second);
        z = div(z,SECONDS_PER_DAY);
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
                    totalAmount = add(totalAmount,calProfit(stepAmount,sub(endtime,startime)));
                    break;
                }else{
                    totalAmount = add(totalAmount,calProfit(stepAmount,sub(stepTime,startime)));
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
}

library DateUtil {
    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    int constant OFFSET19700101 = 2440588;

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

    function isLeapYear(uint timestamp) internal pure returns (bool leapYear) {
        (uint year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }
    function _isLeapYear(uint year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
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
}