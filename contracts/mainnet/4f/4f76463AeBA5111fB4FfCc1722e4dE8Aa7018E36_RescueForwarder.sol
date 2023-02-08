// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IOwnable {
    function owner() external view returns (address);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);
}

interface EIP2771Recipient {
    function isTrustedForwarder(address forwarder) external view returns (bool);
}

contract RescueForwarder {
    event Rescued(address tokenOwner, address token, address to, uint256 amount);
    event Destroyed(address tokenOwner);

    address public immutable token;

    constructor(address tokenToRescue) {
        require(tokenToRescue != address(0), "target token can not be zero address");
        token = tokenToRescue;
    }

    function rescueStuckToken(address to) external {
        require(IOwnable(token).owner() == msg.sender, "message sender is not token owner");
        require(EIP2771Recipient(token).isTrustedForwarder(address(this)), "rescue forwarder is not trusted");

        uint256 balanceBefore = IERC20(token).balanceOf(to);
        uint256 amount = IERC20(token).balanceOf(token);

        bytes memory callData = abi.encodePacked(abi.encodeWithSelector(IERC20.transfer.selector, to, amount), token);
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = token.call(callData);
        require(success, "rescue call failed");

        uint256 balanceAfter = IERC20(token).balanceOf(to);
        require(balanceAfter == balanceBefore + amount, "erc20 transfer failed");

        emit Rescued(msg.sender, token, to, amount);
    }

    function destroy(address payable to) external {
        require(IOwnable(token).owner() == msg.sender, "message sender is not token owner");
        emit Destroyed(msg.sender);
        selfdestruct(to);
    }
}