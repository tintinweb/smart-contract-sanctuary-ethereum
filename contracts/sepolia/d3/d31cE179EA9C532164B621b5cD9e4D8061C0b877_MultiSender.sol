/**
 *Submitted for verification at Etherscan.io on 2023-06-12
*/

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}


contract MultiSender {
    address public tokenAddress;

    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;
    }

    function sendTokens(address[] memory _recipients, uint[] memory _amounts) public  {
        require(_recipients.length == _amounts.length, "Arrays length mismatch");

        for (uint256 i = 0; i < _recipients.length; i++) {
            IERC20(tokenAddress).transferFrom(msg.sender, _recipients[i], _amounts[i]);
        }
    }
}