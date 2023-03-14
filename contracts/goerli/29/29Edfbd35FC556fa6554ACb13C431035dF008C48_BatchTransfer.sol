/**
 *Submitted for verification at Etherscan.io on 2023-03-14
*/

pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external returns (uint256);

    function allowance(address owner, address spender)
        external
        returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract BatchTransfer {
    constructor() {}

    function batchTransfer(
        address token,
        address[] memory receivers,
        uint256 amount
    ) public payable {
        uint256 totalAmount = receivers.length * amount;
        if (token == address(0)) {
            // gas token transfer
            require(msg.value >= totalAmount, "insufficient value");
            for (uint256 i = 0; i < receivers.length; i++) {
                (bool sent, ) = receivers[i].call{value: amount}("");
                require(sent);
            }
        } else {
            // ERC20 transfer
            require(
                IERC20(token).allowance(msg.sender, address(this)) >=
                    totalAmount,
                "insufficient allowance"
            );
            require(
                IERC20(token).balanceOf(msg.sender) >= totalAmount,
                "insufficient balance"
            );
            for (uint256 i = 0; i < receivers.length; i++) {
                IERC20(token).transferFrom(msg.sender, receivers[i], amount);
            }
        }
    }
}