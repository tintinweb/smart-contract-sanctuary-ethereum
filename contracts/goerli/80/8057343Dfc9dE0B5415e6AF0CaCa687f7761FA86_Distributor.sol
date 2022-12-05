/**
 *Submitted for verification at Etherscan.io on 2022-12-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Distributor {
  event Distributed(address addr, uint256 amount);

  function distribute(address[] calldata addrs, uint256[] calldata values) public payable {
    uint256 i = 0;
    uint256 balance = msg.value;
    uint256 addrsLen = addrs.length;
    while (i < addrsLen) {
        require(balance >= values[i], "not enough funds");
        balance -= values[i];

        (bool sent, ) = payable(addrs[i]).call{value: values[i]}("");
        require(sent, "failed to send ether");

        emit Distributed(addrs[i], values[i]);
        i++;
    }
  }

}