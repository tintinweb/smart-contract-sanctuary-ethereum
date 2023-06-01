/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ILove {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract TheFaucetOfLove {

    ILove immutable love;
    address bleedingHeart;

    constructor(address _love, address _bleedingHeart) {
        love = ILove(_love);
        bleedingHeart = _bleedingHeart;
    }

    receive() external payable {
        require(msg.value == 0.05 ether, "Must learn to receive love");
        love.transfer(msg.sender, 1 ether);
    }

    function drip() public {
        payable(bleedingHeart).call{value: address(this).balance}("");
    }

}