// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC20.sol";

contract EHIVE_TRANSFER is Ownable {
    bool public isEnabled = true;

    IERC20 public oldToken;
    IERC20 public newToken;

    constructor(IERC20 _oldToken, IERC20 _newToken) {
        oldToken = _oldToken;
        newToken = _newToken;
    }

    function setContractState(bool onoff) external onlyOwner {
        isEnabled = onoff;
    }

    function withdrawTokens(IERC20 token) external onlyOwner {
        uint256 amount = token.balanceOf(address(this));
        token.transfer(msg.sender, amount);
    }

    function convertTokens() external {
        require(isEnabled, "Contract is not enabled.");

        uint256 amount = oldToken.balanceOf(msg.sender);

        // Take old token
        oldToken.transferFrom(msg.sender, address(this), amount);

        // Send new token
        newToken.transfer(msg.sender, amount);
    }
}