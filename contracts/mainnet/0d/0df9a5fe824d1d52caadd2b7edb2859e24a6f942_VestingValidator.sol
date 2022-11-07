/**
 *Submitted for verification at Etherscan.io on 2022-11-07
*/

// File @openzeppelin/contracts/utils/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}


// File @openzeppelin/contracts/token/ERC20/[email protected]


pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// File contracts/VestingValidator.sol


pragma solidity ^0.6.12;


interface IStepVesting {
    function started() external returns(uint256);
    function token() external returns(IERC20);
    function cliffDuration() external returns(uint256);
    function stepDuration() external returns(uint256);
    function cliffAmount() external returns(uint256);
    function stepAmount() external returns(uint256);
    function numOfSteps() external returns(uint256);
    function receiver() external returns(address);
}

contract VestingValidator {
    using Strings for uint256;

    IERC20 public constant TOKEN = IERC20(0x111111111117dC0aa78b770fA6A738034120C302);

    function check(
        IStepVesting[] memory contracts,
        address[] memory receivers,
        uint256[] memory amounts,
        uint256[] memory starts,
        uint256[] memory cliffs
    ) external {
        uint256 len = contracts.length;
        require(len == receivers.length, "Invalid receivers length");
        require(len == amounts.length, "Invalid amounts length");
        require(len == starts.length, "Invalid starts length");
        require(len == cliffs.length, "Invalid cliffs length");

        for (uint i = 0; i < len; i++) {
            IStepVesting vesting = contracts[i];
            require(
                vesting.receiver() == receivers[i],
                string(abi.encodePacked("Invalid receiver #", (i + 1).toString()))
            );
            require(
                vesting.started() == starts[i],
                string(abi.encodePacked("Invalid start date #", (i + 1).toString()))
            );
            require(
                vesting.cliffDuration() == cliffs[i],
                string(abi.encodePacked("Invalid cliff duration #", (i + 1).toString()))
            );
            require(
                vesting.stepDuration() == 15768000, // 182.5 days
                string(abi.encodePacked("Invalid step duration #", (i + 1).toString()))
            );
            require(
                vesting.cliffAmount() + vesting.stepAmount() * vesting.numOfSteps() == amounts[i],
                string(abi.encodePacked("Invalid amount #", (i + 1).toString()))
            );
            require(
                TOKEN.balanceOf(address(vesting)) == amounts[i],
                string(abi.encodePacked("Invalid balance #", (i + 1).toString()))
            );
        }
    }
}