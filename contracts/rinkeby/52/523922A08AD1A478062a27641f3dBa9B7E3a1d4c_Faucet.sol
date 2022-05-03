/**
 *Submitted for verification at Etherscan.io on 2022-05-03
*/

// SPDX-License-Identifier: CC-BY-SA 4.0
//https://creativecommons.org/licenses/by-sa/4.0/

// a really quick DAI faucet I coded, feel free to use this however you want

pragma solidity >=0.7.0 <0.9.0;

contract Faucet{

    ERC20 DAI = ERC20(0xc7AD46e0b8a400Bb3C915120d284AafbA8fc4735);

    // Gives you 1,000 DAI

    function GetDAI() public {

        DAI.transfer(msg.sender, 1000*(10**18));
    }
}

interface ERC20{
    function transferFrom(address, address, uint256) external;
    function transfer(address, uint256) external;
    function balanceOf(address) external view returns(uint);
}