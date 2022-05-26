/**
 *Submitted for verification at Etherscan.io on 2022-05-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract modifier1 {
    bool public paused;
    uint public count;

    function setPause(bool _paused) external {
        paused = _paused;
    }
modifier whenNotPaused (){
    require(!paused,'paused');
    _;
}

function inc() external whenNotPaused {
    count +=1;
}

function dec() external whenNotPaused {
    count -=1;
}

}