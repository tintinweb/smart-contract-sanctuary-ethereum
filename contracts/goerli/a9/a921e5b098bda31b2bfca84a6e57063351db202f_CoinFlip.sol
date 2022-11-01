/**
 *Submitted for verification at Etherscan.io on 2022-10-31
*/

//SPDX-License-Identifier: <SPDX-License>

pragma solidity ^0.8.4;

error Unauthorized();


contract CoinFlip{
    function recieve() external payable {}

    function _generateNumber() internal pure returns (uint) {
        return 1;
    }

function coinflip(
    uint256 number
) payable external {
    require(msg.value == 0.1 ether);
    
    if(number == _generateNumber()){
        payable(msg.sender).transfer(0.2 ether);
    }

}

}