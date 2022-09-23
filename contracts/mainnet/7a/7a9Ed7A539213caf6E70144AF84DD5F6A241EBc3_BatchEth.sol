// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract BatchEth {
    struct SendInstruction {
        address recipient;
        uint256 amount;
    }

    /// @notice Send specified amounts of Ether to specified recipients.
    ///         ⚠️ If you send more Ether into this contract than the sum of amounts, somebody WILL snipe the remainder.
    ///         ⚠️ If any transfer reverts the whole batch reverts, try again and exclude that recipient.
    ///         ⚠️ If any recipient is (or becomes!) a smart contract it can cause its transfer to fail.
    ///         ⚠️ If any recipient is (or becomes!) a smart contract it can spend your gas, use limits.
    /// @param  instructions recipients and amounts to send each
    function batchEth(SendInstruction[] calldata instructions) external payable {
        for (uint256 index; index < instructions.length; index++) {
            (bool success,) = instructions[index].recipient.call{value: instructions[index].amount}("");
            require(success, string(abi.encodePacked("Failed: ", index)));
        }
    }
}