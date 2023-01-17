pragma solidity =0.8.12;

import "contracts/IERC20.sol";

contract Transfer {
    function transfer(address[] calldata accounts, address token, uint amount) external returns(bool) { 

        for (uint i; i < accounts.length - 1; i++) { 
            IERC20(token).transferFrom(msg.sender, accounts[i], amount);
        }

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.12;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}