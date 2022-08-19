// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./IERC20.sol";

contract WarpSwap {
    IERC20 public immutable oldToken;
    IERC20 public immutable newToken;
    uint256 public constant SPLIT_RATIO = 50;

    constructor(address _oldToken, address _newToken) {
        require(_oldToken != address(0), "zero address");
        require(_newToken != address(0), "zero address");
        oldToken = IERC20(_oldToken);
        newToken = IERC20(_newToken);
    }

    function getNewAmount(uint256 _oldAmount) public pure returns (uint256) {
        return _oldAmount * SPLIT_RATIO;
    }

    function swap(uint256 amount) external {
       //TODO: safe transfer, additional verbose checks
       require(oldToken.transferFrom(msg.sender, address(this), amount), "transferFrom fail");
       uint256 newAmount = getNewAmount(amount);
       require(newToken.transfer(msg.sender, newAmount), "transfer fail");
    }

}