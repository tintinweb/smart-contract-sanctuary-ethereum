/**
 *Submitted for verification at Etherscan.io on 2022-08-31
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address, uint) external;
}

contract Faucet {

    IERC20 public immutable token1;
    IERC20 public immutable token2;
    
    constructor(address _token1, address _token2) {
        token1 = IERC20(_token1);
        token2 = IERC20(_token2);
    }

    function faucet() external {
        token1.transfer(msg.sender, 500e18);
        token2.transfer(msg.sender, 500e18);
    }
}