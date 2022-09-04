// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./AggregatorV3Interface.sol";

contract paymentTester{

    AggregatorV3Interface internal priceFeed;

    constructor() {
        priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
    }

    mapping (address => uint) public getDeposit;
    mapping (address => uint) public getUsdBal;

    function getEthPrice() public view returns (int) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return price / 10**8;
    }

    function deposit() public payable{
        getDeposit[msg.sender] += msg.value;
    }
    
    function withdraw(uint256 amount) public{
        address payable _to = payable(msg.sender);
        require((getDeposit[msg.sender] - amount) >= 0, "Withdrawal amount exceeds deposit");
        _to.transfer(amount);
        getDeposit[msg.sender] -= amount;
    }

    function gift(uint256 amount, address receiver) public{
        require((getDeposit[msg.sender] - amount) >= 0, "Gift amount exceeds deposit");
        getDeposit[msg.sender] -= amount;
        getDeposit[receiver] += amount;
    }

    function sellEth(uint256 amount) public{
        require((getDeposit[msg.sender] - amount) >= 0, "Convert amount exceeds deposit");
        getDeposit[msg.sender] -= amount;
        getUsdBal[msg.sender] += (uint(getEthPrice()) * amount / 10 ** 18);
    }

    function buyEth(uint256 amount) public{
        require((getUsdBal[msg.sender] - amount) >= 0, "Convert amount exceeds deposit");
        getDeposit[msg.sender] += (amount  * 10 ** 18 / uint(getEthPrice()));
        getUsdBal[msg.sender] -= amount;
    }
}