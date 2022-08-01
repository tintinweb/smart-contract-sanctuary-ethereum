// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

contract FundMe {
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;
    
    // if you're following along with the freecodecamp video
    // Please see https://github.com/PatrickAlphaC/fund_me
    // to get the starting solidity contract code, it'll be slightly different than this!
    constructor() {
        owner = msg.sender;
    }

    function fund() public payable {
        uint256 minimumUSD = 50;
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "You need to spend more ETH!"
        );
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getPrice() public pure returns (uint256) {
        return 2;
    }

    // 1000000000
    function getConversionRate(uint256 ethAmount)
        public
        pure
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = ethPrice * ethAmount;
        return ethAmountInUsd;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function withdraw() public payable onlyOwner {
        msg.sender.transfer(address(this).balance);

        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
    }
}