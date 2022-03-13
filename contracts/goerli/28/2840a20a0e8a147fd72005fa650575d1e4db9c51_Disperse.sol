/**
 *Submitted for verification at Etherscan.io on 2022-03-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract Disperse {
    function disperseEther(address payable[] calldata recipients, uint256[] calldata values) public payable {
        // for (uint256 i = 0; i < recipients.length; i++)
        //     recipients[i].transfer(values[i]);
        uint length = recipients.length - 1;
        address payable to;
        uint256 amount;
        bool success;
        while (length != 0) {
            to = recipients[length];
            amount = values[length];
            assembly {
                // Transfer the ETH and store if it succeeded or not.
                success := call(gas(), to, amount, 0, 0, 0, 0)
                if iszero(success) {
                    revert(0x00, 0x00)
                }
            }
            unchecked { length--; }
        }
        to = recipients[0];
        amount = values[0];
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
            if iszero(success) {
                revert(0x00, 0x00)
            }
            to := caller()
            amount := selfbalance()
            if gt(amount, 0) {
                success := call(gas(), to, amount, 0, 0, 0, 0)
                if iszero(success) {
                    revert(0x00, 0x00)
                }
            }
        }
    }

    function disperseToken(address token, address[] calldata recipients, uint256[] calldata values) public {
        uint256 total;
        address to;
        uint256 amount;
        bool success;
        // for (uint256 i = 0; i < recipients.length; i++)
        //     total += values[i];
        total = sumPureAsm(values);
        // require(token.transferFrom(msg.sender, address(this), total));

        /// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
        /// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
        /// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
        /// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)
            to := caller()
            amount := address()

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), total) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (not just any non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the addition in the
                // order of operations or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
            if iszero(success) {
                revert(0x00, 0x00)
            }
        }
        // for (i = 0; i < recipients.length; i++)
        //     require(token.transfer(recipients[i], values[i]));
        uint length = recipients.length - 1;
        while (length != 0) {
            to = recipients[length];
            amount = values[length];
            assembly {
                // Get a pointer to some free memory.
                let freeMemoryPointer := mload(0x40)

                // Write the abi-encoded calldata into memory, beginning with the function selector.
                mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
                mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
                mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

                success := and(
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (not just any non-zero data), or had no return data.
                    or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                    // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                    // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                    // Counterintuitively, this call must be positioned second to the addition in the
                    // order of operations or else returndatasize() will be zero during the computation.
                    call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
                )
                if iszero(success) {
                    revert(0x00, 0x00)
                }
            }
            unchecked { length--; }
        }
        to = recipients[0];
        amount = values[0];
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (not just any non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the addition in the
                // order of operations or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
            if iszero(success) {
                revert(0x00, 0x00)
            }
        }
    }

    function disperseTokenSimple(address token, address[] memory recipients, uint256[] memory values) public {
        // for (uint256 i = 0; i < recipients.length; i++)
        //     require(token.transferFrom(msg.sender, recipients[i], values[i]));
        uint length = recipients.length - 1;
        address from = msg.sender;
        address to;
        uint256 amount;
        bool success;
        while (length != 0) {
            to = recipients[length];
            amount = values[length];
            assembly {
                // Get a pointer to some free memory.
                let freeMemoryPointer := mload(0x40)

                // Write the abi-encoded calldata into memory, beginning with the function selector.
                mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
                mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
                mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
                mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

                success := and(
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (not just any non-zero data), or had no return data.
                    or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                    // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                    // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                    // Counterintuitively, this call must be positioned second to the addition in the
                    // order of operations or else returndatasize() will be zero during the computation.
                    call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
                )
                if iszero(success) {
                    revert(0x00, 0x00)
                }
            }
            unchecked { length--; }
        }
        to = recipients[0];
        amount = values[0];
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (not just any non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the addition in the
                // order of operations or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
            if iszero(success) {
                revert(0x00, 0x00)
            }
        }
    }

    // Same as above, but accomplish the entire code within inline assembly.
    function sumPureAsm(uint256[] memory _data) internal pure returns (uint256 sum) {
        assembly {
            // Load the length (first 32 bytes)
            let len := mload(_data)

            // Skip over the length field.
            //
            // Keep temporary variable so it can be incremented in place.
            //
            // NOTE: incrementing _data would result in an unusable
            //       _data variable after this assembly block
            let data := add(_data, 0x20)

            // Iterate until the bound is not met.
            for
                { let end := add(data, mul(len, 0x20)) }
                lt(data, end)
                { data := add(data, 0x20) }
            {
                sum := add(sum, mload(data))
            }
        }
    }
}