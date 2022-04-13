/**
 *Submitted for verification at Etherscan.io on 2022-04-13
*/

pragma solidity 0.6.0;

contract FundMe {

mapping (address => uint256) public addressToAmountFunded;
constructor() public payable{
}

function fund () public payable { 
    addressToAmountFunded[msg.sender] += msg.value;
}

}