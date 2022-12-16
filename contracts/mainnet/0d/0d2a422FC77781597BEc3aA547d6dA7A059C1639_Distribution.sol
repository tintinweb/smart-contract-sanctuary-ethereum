/**
 *Submitted for verification at Etherscan.io on 2022-12-16
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.4;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract Distribution {
    address private owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "owner");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    function distributeToken(IERC20 token, address[] memory addresses, uint256[] memory amounts) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            token.transfer(addresses[i], amounts[i]);
        }
    }

    function withdrawToken(IERC20 token, address to, uint256 amount) external onlyOwner {
        token.transfer(to, amount);
    }

    receive() external payable {}
}