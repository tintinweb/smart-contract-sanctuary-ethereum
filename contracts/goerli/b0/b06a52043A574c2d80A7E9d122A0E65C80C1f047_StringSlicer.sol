// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library StringSlicer {
    /// @notice Abbreviates a string.
    /// @dev This function uses Array Slices (https://blog.soliditylang.org/2020/05/26/array-slices/), which only work on calldata. The function must therefore live in a separate contract for a Token Resolver to use Array Slices.
    /// @param _str The string to mutate.
    /// @param _start The first index of the input string to include in the output.
    /// @param _end The last index of the input string to include in the output.
    /// @return string The abbreviated string.
    function slice(
        string calldata _str,
        uint256 _start,
        uint256 _end
    ) external pure returns (string memory) {
        return string(bytes(_str)[_start:_end]);
    }
}