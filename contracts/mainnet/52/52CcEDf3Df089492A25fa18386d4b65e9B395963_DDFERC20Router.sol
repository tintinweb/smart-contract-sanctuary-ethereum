/**
 *Submitted for verification at Etherscan.io on 2022-05-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}


interface IDDFERC20Factory {
    function getPair(address token) external view returns (address pair);
    function indexPairs(uint index) external view returns (address pair);
    function allTokensLength() external view returns (uint);
}

interface IDDFERC20PoolPair {
    function totalSupply() external view returns (uint256);
    
    function pairInfo(address owner) external view returns (uint32, uint, uint32, uint32);
    function mint(address owner, uint256 amount) external;
    function burn(address owner, uint256 amount) external;
    function updateTokenTime(address owner) external;
}

interface IDDFERC20Router {
    function deposit(address token, uint256 amount) external;
    function withdraw(address token, uint256 amount) external;
    function receiveInterest(address token) external;
    function findAllDeposit(address token)
        external
		view
        returns (uint256 amount);
    function findInterest(address token ,address account) 
        external 
        view 
        returns (uint256 amount,uint256 interest);
}

contract DDFERC20Router is IDDFERC20Router {
    address public factory;
    address public ddfAddress;
    address public ddfSender;

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'DDFNFT: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor(address _factory, address _ddfAddress) {
        factory = _factory;
        ddfAddress = _ddfAddress;
        ddfSender = msg.sender;
    }

    function deposit(address token, uint256 amount) external lock override {
        address pair = IDDFERC20Factory(factory).getPair(token);
        require(pair != address(0), "DDFRouter:pair nonexistent");
        require(amount <= IERC20(token).balanceOf(msg.sender), "DDFRouter:deposit amount not enough");

        (uint32 startTime, uint _amount, uint32 interestRate, uint32 INTEREST_RATE_MOL) = IDDFERC20PoolPair(pair).pairInfo(msg.sender);
        if(_amount > 0 && startTime > 0){
            uint32 endTime = uint32(block.timestamp % 2 ** 32);
            uint ddfAmount = CalProfitMath.colProfitAmount(startTime, endTime, _amount, interestRate, INTEREST_RATE_MOL);
            IERC20(ddfAddress).transferFrom(ddfSender, msg.sender,ddfAmount);
        }

        IERC20(token).transferFrom(msg.sender, address(this), amount);
        IERC20(token).approve(pair,amount);
        IDDFERC20PoolPair(pair).mint(msg.sender, amount);
    }

    function withdraw(address token, uint256 amount) external lock override {
        address pair = IDDFERC20Factory(factory).getPair(token);
        require(pair != address(0), "DDFRouter: pair nonexistent");

        (uint32 startTime, uint allAmount, uint32 interestRate, uint32 INTEREST_RATE_MOL) = IDDFERC20PoolPair(pair).pairInfo(msg.sender);
        require(amount > 0, "DDFRouter: withdraw amount not enough"); 

        if(allAmount > 0 && startTime > 0){ 
            uint32 endTime = uint32(block.timestamp % 2 ** 32);
            uint ddfAmount = CalProfitMath.colProfitAmount(startTime, endTime, allAmount, interestRate, INTEREST_RATE_MOL);
            if(ddfAmount > 0){
                IERC20(ddfAddress).transferFrom(ddfSender, msg.sender,ddfAmount);
            }
        }

        IDDFERC20PoolPair(pair).burn(msg.sender,amount);
    }

    function receiveInterest(address token) external lock override {
        address pair = IDDFERC20Factory(factory).getPair(token);
        require(pair != address(0), "DDFRouter: pair nonexistent");

        (uint32 startTime, uint amount, uint32 interestRate, uint32 INTEREST_RATE_MOL) = IDDFERC20PoolPair(pair).pairInfo(msg.sender);
        require(amount > 0, "DDFRouter: withdraw amount not enough"); 

        if(amount > 0 && startTime > 0){ 
            uint32 endTime = uint32(block.timestamp % 2 ** 32);
            uint ddfAmount = CalProfitMath.colProfitAmount(startTime, endTime, amount, interestRate, INTEREST_RATE_MOL);
            if(ddfAmount > 0){
                IERC20(ddfAddress).transferFrom(ddfSender, msg.sender, ddfAmount);
            }
        }

        IDDFERC20PoolPair(pair).updateTokenTime(msg.sender);
    }

    function findAllDeposit(address token)
        public
		view
        override
        returns (uint256 amount) {
            address pair = IDDFERC20Factory(factory).getPair(token);
            require(pair != address(0), "DDFRouter: pair nonexistent");
            amount = IDDFERC20PoolPair(pair).totalSupply();
    }

    function findInterest(address token ,address account)
        public
		view
        override
        returns (uint256 amount,uint256 interest) {
            address pair = IDDFERC20Factory(factory).getPair(token);
            require(pair != address(0), "DDFRouter: pair nonexistent");

            (uint32 startTime, uint _amount, uint32 interestRate, uint32 INTEREST_RATE_MOL) = IDDFERC20PoolPair(pair).pairInfo(account);

            if(_amount > 0){
                uint32 endTime = uint32(block.timestamp % 2 ** 32);
                interest = CalProfitMath.colProfitAmount(startTime, endTime, _amount, interestRate, INTEREST_RATE_MOL);
                amount = _amount;
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

    function calProfit(uint256 dayProfit, uint second) internal pure returns (uint256 z) {
        z = mul(dayProfit,second);
        z = div(z,SECONDS_PER_DAY);
    }
    
    function colProfitAmount(uint32 startime, uint32 endtime, uint256 depositAmount, uint256 m, uint256 d) internal pure returns (uint256 totalAmount) {
        uint dayAmount = div(mul(depositAmount,m),d);
        totalAmount = calProfit(dayAmount,sub(endtime,startime));
        return totalAmount;
    }
}