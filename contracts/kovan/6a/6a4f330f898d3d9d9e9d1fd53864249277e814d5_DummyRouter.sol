/**
 *Submitted for verification at Etherscan.io on 2022-06-29
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external;
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

contract DummyRouter {
    function swap(
        address fromToken,
        uint256 amount
    ) public {
        IERC20(fromToken).transferFrom(msg.sender, address(this), amount);
    }
    function swapWithPermit(
        address token,
        //address owner,
        //address spender,
        uint swapAmount,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        permitToken(token, value, deadline, v, r, s);
        swap(token, swapAmount);
    }
    function permitToken(
        address token,
        //address owner,
        //address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        IERC20(token).permit(msg.sender, address(this), value, deadline, v, r, s);
    }
    function batch(bytes[] memory datas) external {
        for (uint i = 0; i < datas.length; i++) {
            bytes memory data = datas[i];
            (bool success,) = address(this).delegatecall(data);
            require(success, "batch failed");
        }
    }
}