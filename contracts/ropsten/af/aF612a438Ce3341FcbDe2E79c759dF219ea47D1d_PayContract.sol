/**
 *Submitted for verification at Etherscan.io on 2022-05-19
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;


contract PayContract {
    uint totalDonations; // the amount of donations
  address payable owner; // contract creator's address
    function donate() public payable {
    (bool success,) = owner.call{value: msg.value}("");
    require(success, "Failed to send money");
  }

       function ContractBalance() public view returns (uint256){
       return address(this).balance;
   }

}