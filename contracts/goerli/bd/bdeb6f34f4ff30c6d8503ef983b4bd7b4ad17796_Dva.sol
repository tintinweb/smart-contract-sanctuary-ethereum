/**
 *Submitted for verification at Etherscan.io on 2023-01-22
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract Dva{
    address public eden;

    constructor(address _eden){
        eden = _eden;
    }

    fallback() external{

    if (msg.data.length > 0) {
      eden.delegatecall(msg.data);
    }
}
}