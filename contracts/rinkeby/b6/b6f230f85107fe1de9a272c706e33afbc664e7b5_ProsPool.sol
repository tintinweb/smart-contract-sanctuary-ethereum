/**
 *Submitted for verification at Etherscan.io on 2022-02-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface ERC20 {

  function transfer(address to, uint value) external returns (bool);

}

contract ProsPool {

    address _stakeAddress = 0x7b2C8e460dfAa156F87fd1C85B2075Cc8f07C5E2; //assuming 0X35...eE3 as stake pool contract address
    
    function distributePool(address receiver) public {
        require(msg.sender == _stakeAddress, "incorrect stake address");
        ERC20(0xE19E91c6F71B29a72DF31c115D1687193BE93907).transfer(receiver, 1); //assuming 0xe1...3907 as ERC-20 token address
    }

}