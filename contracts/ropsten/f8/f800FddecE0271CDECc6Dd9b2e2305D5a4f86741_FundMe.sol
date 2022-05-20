// SPDX-License-Identifier: MIT

pragma solidity >=0.7.3;


contract FundMe {

    address[] public funders;
    address owner;

    mapping(address => uint256) public addressToAmountFunded;

    constructor(){
        owner = msg.sender;
    }

    function fund() public payable {
        uint256 minFundingAmount = 0.1*10**18;
        require(msg.value >= minFundingAmount, "You need to spend min 0.1 ETH");
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }   

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
        //This place holder is replaced by the code of the function being modified
    }

    function withdraw() payable onlyOwner public {
        
        payable(msg.sender).transfer(address(this).balance);
        
        for(uint256 i=0; i < funders.length; i++) {
            address funder = funders[i];
            addressToAmountFunded[funder] = 0;

        }
        funders = new address[](0);
    }

}