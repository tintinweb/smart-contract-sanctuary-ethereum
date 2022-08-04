/**
 *Submitted for verification at Etherscan.io on 2022-08-04
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Counter {
    uint public count;

    event CountChanged(
        uint indexed oldCount,
        uint indexed newCount
    );

    function increaseCount () public payable {
        count++;
        emit CountChanged(count - 1, count);
    }

    function decreaseCount () public payable {
        count--;
        emit CountChanged(count + 1, count);
    }
}