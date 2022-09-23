/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

interface IERC20 {
    function transfer(address _to, uint256 _value) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    // don't need to define other functions, only using `transfer()` in this case
}

contract NewMaraDonate {
    // Do not use in production
    // This function can be executed by anyone

    receive() external payable {}

    function sendUSDC(address _to, uint256 _amount) external {
        IERC20 usdc = IERC20(
            address(0x07865c6E87B9F70255377e024ace6630C1Eaa37F)
        );

        // transfers USDT that belong to your contract to the specified address
        usdc.transfer(_to, _amount);
    }

    function balanceOf() public view returns (uint256) {
        IERC20 usdc = IERC20(
            address(0x07865c6E87B9F70255377e024ace6630C1Eaa37F)
        );
        uint256 balance = usdc.balanceOf(address(this));
        return balance;
    }
}