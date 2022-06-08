/**
 *Submitted for verification at Etherscan.io on 2022-06-08
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Calculator{

    // Just a calculator to calculate the rewards for this contract: https://github.com/LogETH/commissions/blob/main/Finished%20Commissions/CustomizableStaking.sol

    function APYtoBPS(uint APY) public pure returns(uint){

        APY *= 10e18;
        APY /= 365;

        return APY/10e15;
    }
}