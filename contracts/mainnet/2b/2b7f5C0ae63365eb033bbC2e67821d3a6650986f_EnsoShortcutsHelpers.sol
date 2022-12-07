// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/**
 * @dev SignedMathHelpers contract is recommended to use only in Shortcuts passed to EnsoWallet.
 *
 * This contract functions allow to dynamically get the data during Shortcut transaction execution
 * that usually would be read between transactions
 */
contract EnsoShortcutsHelpers {
    uint256 public constant VERSION = 2;

    /**
     * @dev Returns the ether balance of given `balanceAdderess`.
     */
    function getBalance(address balanceAddress) external view returns (uint256 balance) {
        return address(balanceAddress).balance;
    }

    /**
     * @dev Returns the current block timestamp.
     */
    function getBlockTimestamp() external view returns (uint256 timestamp) {
        return block.timestamp;
    }

    /**
     * @dev Returns a value depending on a truth condition
     */
    function toggle(bool condition, uint256 a, uint256 b) external pure returns (uint256) {
        if (condition) {
            return a;
        } else {
            return b;
        }
    }

    /**
     * @dev Returns the inverse bool
     */
    function not(bool condition) external pure returns (bool) {
        return !condition;
    }

    /**
     * @dev Returns bool for a == b
     */
    function isEqual(uint256 a, uint256 b) external pure returns (bool) {
        return a == b;
    }

    /**
     * @dev Returns bool for a < b
     */
    function isLessThan(uint256 a, uint256 b) external pure returns (bool) {
        return a < b;
    }

    /**
     * @dev Returns bool for a <= b
     */
    function isEqualOrLessThan(uint256 a, uint256 b) external pure returns (bool) {
        return a <= b;
    }

    /**
     * @dev Returns bool for a > b
     */
    function isGreaterThan(uint256 a, uint256 b) external pure returns (bool) {
        return a > b;
    }

    /**
     * @dev Returns bool for a >= b
     */
    function isEqualOrGreaterThan(uint256 a, uint256 b) external pure returns (bool) {
        return a >= b;
    }

    /**
     * @dev Returns bool for a == b
     */
    function isAddressEqual(address a, address b) external pure returns (bool) {
        return a == b;
    }

    /**
     * @dev Returns `input` bytes as string.
     */
    function bytesToString(bytes calldata input) external pure returns (string memory) {
        return string(abi.encodePacked(input));
    }

    /**
     * @dev Returns `input` bytes as uint256.
     */
    function bytesToUint256(bytes calldata input) external pure returns (uint256) {
        require(input.length == 32, "EnsoShortcutsHelpers: input length is not 32 bytes");
        return uint256(bytes32(input));
    }

    /**
     * @dev Returns `input` bytes as bytes32.
     */
    function bytesToBytes32(bytes calldata input) external pure returns (bytes32) {
        return bytes32(input);
    }

    /**
     * @dev Returns `input` bytes32 as uint256.
     */
    function bytes32ToUint256(bytes32 input) external pure returns (uint256) {
        return uint256(input);
    }

    /**
     * @dev Returns `input` bytes32 as address.
     */
    function bytes32ToAddress(bytes32 input) external pure returns (address) {
        return address(uint160(uint256(input)));
    }

    /**
     * @dev Returns uint256 `value` as int256.
     */
    function uint256ToInt256(uint256 value) public pure returns (int256) {
        require(value <= uint256(type(int256).max), "Value does not fit in an int256");
        return int256(value);
    }

    /**
     * @dev Returns int256 `value` as uint256.
     */
    function int256ToUint256(int256 value) public pure returns (uint256) {
        require(value >= 0, "Value must be positive");
        return uint256(value);
    }
}