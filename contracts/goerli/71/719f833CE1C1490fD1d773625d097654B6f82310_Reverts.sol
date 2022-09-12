// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

contract Reverts {
    error CustomError();
    error CustomErrorWithArgs(address addressArg, uint256 uintArg);

    function requireWithoutMessage() public pure {
        // solhint-disable-next-line reason-string
        require(false);
    }

    function requireWithMessage() public pure {
        require(false, "Reverts: requireWithMessage");
    }

    function revertWithoutMessage() public pure {
        // solhint-disable-next-line reason-string
        revert();
    }

    function revertWithMessage() public pure {
        revert("Reverts: revertWithMessage");
    }

    function revertWithCustomError() public pure {
        revert CustomError();
    }

    function revertWithCustomErrorWithArgs() public view {
        revert CustomErrorWithArgs(address(msg.sender), msg.sender.balance);
    }
}