/**
 *Submitted for verification at Etherscan.io on 2022-08-19
*/

// SPDX-License-Identifier: None
pragma solidity 0.8.15;

interface IERC20 {
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

contract locker {
    constructor() {}

    function lockTokens(
        address _tokenAddress,
        address _withdrawalAddress,
        uint256 _amount,
        uint256 _unlockTime
    ) external payable returns (uint256 _id) {
        IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount);
        _id = 2;
    }

    function burnEmUp() public payable {}
}