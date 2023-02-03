// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (finance/VestingWallet.sol)
// This contract is a copy of OpenZeppelin VestingWallet Contract. Copied specially for ZENF Token of Zenland. This contract would be used to lock and vest token allocation of Marketing, Development, Team and Community. Each category of allocation would be on seperate contract for users to better understand the total allocation of $ZENF and how it being spend.

pragma solidity 0.8.9;

import "./SafeERC20.sol";
import "./Context.sol";

/**
 * @title VestingWallet
 * @dev This contract handles the vesting of Eth and ERC20 tokens for a given beneficiary. Custody of multiple tokens
 * can be given to this contract, which will release the token to the beneficiary following a given vesting schedule.
 * The vesting schedule is customizable through the {vestedAmount} function.
 *
 * Any token transferred to this contract will follow the vesting schedule as if they were locked from the beginning.
 * Consequently, if the vesting has already started, any amount of tokens sent to this contract will (at least partly)
 * be immediately releasable.
 */



contract VestingWallet is Context {
    event ERC20Released(address indexed token, uint256 amount);

    mapping(address => uint256) private _erc20Released;
    address private immutable _token;
    address private immutable _beneficiary;
    uint64 private immutable _start;
    uint64 private immutable _duration;

    /**
     * @dev Set the beneficiary, start timestamp and vesting duration of the vesting wallet.
     */
    constructor(address token, address beneficiaryAddress, uint64 startTimestamp, uint64 durationSeconds) {
        require(token != address(0), "Token is zero address");
        require(beneficiaryAddress != address(0), "Beneficiary is zero address");
        require(startTimestamp >= block.timestamp, "startTimestamp cannot be in the past");
        require(durationSeconds >= 2592000 && durationSeconds <= 63072000, "Duration must be >= 1 month and <= 2 years");
        _token = token;
        _beneficiary = beneficiaryAddress;
        _start = startTimestamp;
        _duration = durationSeconds;
    }

    /**
     * @dev Getter for the beneficiary address.
     */
    function beneficiary() public view virtual returns (address) {
        return _beneficiary;
    }

    /**
     * @dev Getter for the start timestamp.
     */
    function start() public view virtual returns (uint256) {
        return _start;
    }

    /**
     * @dev Getter for the vesting duration.
     */
    function duration() public view virtual returns (uint256) {
        return _duration;
    }

    /**
     * @dev Amount of token already released
     */
    function released() public view virtual returns (uint256) {
        return _erc20Released[_token];
    }

    /**
     * @dev Getter for the amount of releasable `token` tokens. `token` should be the address of an
     * IERC20 contract.
     */
    function releasable() public view virtual returns (uint256) {
        return vestedAmount(uint64(block.timestamp)) - released();
    }

    /**
     * @dev Release the tokens that have already vested.
     *
     * Emits a {ERC20Released} event.
     */
    function release() external virtual {
        uint256 amount = releasable();
        _erc20Released[_token] += amount;
        emit ERC20Released(_token, amount);
        SafeERC20.safeTransfer(IERC20(_token), beneficiary(), amount);
    }

    /**
     * @dev Calculates the amount of tokens that has already vested. Default implementation is a linear vesting curve.
     */
    function vestedAmount(uint64 timestamp) public view virtual returns (uint256) {
        return _vestingSchedule(IERC20(_token).balanceOf(address(this)) + released(), timestamp);
    }

    /**
     * @dev Virtual implementation of the vesting formula. This returns the amount vested, as a function of time, for
     * an asset given its total historical allocation.
     */
    function _vestingSchedule(uint256 totalAllocation, uint64 timestamp) internal view virtual returns (uint256) {
        if (timestamp < start()) {
            return 0;
        } else if (timestamp > start() + duration()) {
            return totalAllocation;
        } else {
            return (totalAllocation * (timestamp - start())) / duration();
        }
    }

    /**
     * @dev Release wrong tokens transferred to the contract.
     *
     * Emits a {ERC20Released} event.
     */
    function releaseWrongToken(IERC20 token) external virtual {
        require(address(token) != address(0), "Token is zero address");
        require(address(token) != _token, "Token address must be different");
        require(token.balanceOf(address(this)) > 0, "Not enough tokens");
        emit ERC20Released(address(token), token.balanceOf(address(this)));
        SafeERC20.safeTransfer(token, beneficiary(), token.balanceOf(address(this)));
    }
}