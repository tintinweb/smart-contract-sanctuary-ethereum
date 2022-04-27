/**
 *Submitted for verification at Etherscan.io on 2022-04-27
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

// 1. anyone can fund to the contract
// 2. fund at least 50 USD
// 3. only contract owner can widthraw all the money
contract FundMe {
    uint256 public total_fund;   // try public, internal, private
    mapping(address => uint256) public addrToFundMapping;
    function fundMe(uint256 _eth) public payable {  // check the contract balance
        addrToFundMapping[msg.sender] = _eth;  // try the decimal
        total_fund += _eth;
    }

}