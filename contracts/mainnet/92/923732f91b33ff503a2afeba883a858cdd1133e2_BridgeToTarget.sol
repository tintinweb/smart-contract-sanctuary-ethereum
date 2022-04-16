/**
 *Submitted for verification at Etherscan.io on 2022-04-15
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
}


contract BridgeToTarget {
    uint256 public immutable rootChainId;
    uint256 public immutable childChainId;
    address public immutable rootToken;
    address public immutable childToken;
    address public immutable bridge;
    address public immutable target;

    constructor(
        uint256 _rootChainId,
        uint256 _childChainId,
        address _rootToken,
        address _childToken,
        address _bridge,
        address _target
    ) public {
        rootChainId = _rootChainId;
        childChainId = _childChainId;
        rootToken = _rootToken;
        childToken = _childToken;
        bridge = _bridge;
        target = _target;
    }

    function run() external {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        if (chainId == rootChainId) {
            uint256 balance = IERC20(rootToken).balanceOf(address(this));
            if (balance > 0) IERC20(rootToken).transfer(bridge, balance);
        } else if (chainId == childChainId) {
            uint256 balance = IERC20(childToken).balanceOf(address(this));
            if (balance > 0) IERC20(childToken).transfer(target, balance);
        } else {
            revert('bad chain');
        }
    }
}