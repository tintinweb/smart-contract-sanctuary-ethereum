/**
 *Submitted for verification at Etherscan.io on 2022-01-29
*/

/*
 * SPDX-License-Identifier: MIT
 */
 
pragma solidity ^0.8.1;

interface IERC20 {
    function totalSupply() external view  returns (uint256 supply);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

contract marginHolding {

    bool isSet = false;
    address IRSContract;

    function returnFunds (address address_, address token, uint256 amount) public returns (bool success) {
        require(msg.sender == IRSContract);
        IERC20(token).transferFrom(address(this), address_, amount);
        return true;
    }

    function setIRS (address addr) public {
        require(isSet == false);
        IRSContract = addr;
        isSet = true;
    }
}

interface marginInterface {
    function returnFunds (address address_, address token, uint256 amount) external returns (bool success);
    function setIRS (address addr) external;
}

contract IRS {

    address holding; // dummy address refences marginHolding contract
    marginInterface marginContract = marginInterface(holding);

    address owner;
    address token;
    uint256 rate = 0;
    uint256 fixedRate = 0;

    struct transaction {
        bool isSwap;
        uint256 notional;
        uint256 initialTime;
        uint256 duration;
        uint256 fixedInterest;
    }

    mapping(address => transaction) transactions;

    constructor (uint256 intitalRate, address availableToken, address marginHolding_) {
        owner = msg.sender;
        token = availableToken;
        rate = intitalRate;
        fixedRate = intitalRate;
        holding = marginHolding_;
        floatingRate(intitalRate);
    }

    function initiateSwap (
        uint256 notional,
        uint256 duration
    ) public {
        marginContract.setIRS(address(this));
        require(IERC20(token).balanceOf(msg.sender) >= notional / 10);
        require(IERC20(token).balanceOf(address(this)) >= notional / 10);
        transaction memory newSwap;
        newSwap.isSwap = true;
        newSwap.notional = notional;
        newSwap.initialTime = block.timestamp;
        newSwap.duration = duration;
        newSwap.fixedInterest = fixedRate;
        transactions[msg.sender] = newSwap;
        IERC20(token).transferFrom(msg.sender, holding, notional / 10);
        IERC20(token).transferFrom(address(this), holding, notional / 10);
    }

    function liquidateSwap () public {
        bool isSender = transactions[msg.sender].isSwap == true;
        bool isOwner = msg.sender == address(this);
        require(isSender || isOwner);
        uint256 timeLimit = block.timestamp - transactions[msg.sender].initialTime;
        uint256 duration = transactions[msg.sender].duration;
        require(timeLimit >= duration);
        uint256 interestFixed = duration * fixedRate * transactions[msg.sender].notional / 100;
        uint256 interestFlux = duration * rate * transactions[msg.sender].notional / 100;
        transactions[msg.sender].isSwap = false;
        marginContract.returnFunds(msg.sender, token, interestFixed);
        marginContract.returnFunds(address(this), token, interestFlux);
    }

    function floatingRate (uint256 newRate) public onlyOwner() {
        require(newRate <= 100 && newRate >= 0);
        rate = newRate;
    }

    modifier onlyOwner () {
        require(msg.sender == owner);
        _;
    }
}