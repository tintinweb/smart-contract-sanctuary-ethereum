/**
 *Submitted for verification at Etherscan.io on 2022-01-27
*/

// Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract ATM {

 address private subAddress_one = 0x4322E8912748cCBB56F273B45CE545A84c25f548;
 address private subAddress_two = 0x4322E8912748cCBB56F273B45CE545A84c25f548;
 address private subAddress_three = 0x4322E8912748cCBB56F273B45CE545A84c25f548;

 receive() external payable {}

 function setSubAccount_one(address _subAddress_one) public {
    subAddress_one = _subAddress_one;
}
 function setSubAccount_two(address _subAddress_two) public {
    subAddress_two = _subAddress_two;
}
 function setSubAccount_three(address _subAddress_three) public {
    subAddress_three = _subAddress_three;
}

 function getBalance() public view returns (uint){
     return address(this).balance;
 }

 function withdraw(address to) public {
    uint256 balance = address(this).balance;
    payable(subAddress_one).transfer(balance * 5 / 100);
    payable(subAddress_two).transfer(balance * 5 / 100);
    payable(subAddress_three).transfer(balance * 5 / 100);
    payable(to).transfer(balance * 85 / 100);
  }
}