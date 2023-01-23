// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";

contract MultiVestingRound1 {
    using SafeERC20 for IERC20;

    struct Vesting {
        uint256 createdAt; // Timestamp when vesting object was created
        uint256 cliff; // Period (in seconds) after which the allocation should start
        uint256 duration; // Period (in seconds) during which the tokens will be allocated
        uint256 totalAmount; // Vested amount
        uint256 releasedAmount; // Amount that beneficiary withdraw
        bool exists; // Boolean to check if address is in mapping
    }

    address public immutable owner;
    uint256 public totalVestedAmount;
    uint256 public totalReleasedAmount;
    IERC20 public immutable token;
    mapping(address => Vesting) vestingMap;

    constructor(IERC20 _token) {
        token = _token;
        owner = msg.sender;
    }

    /// Creates vesting for beneficiary, with a given amount of funds to allocate
    function addVesting(address _beneficiary, uint256 _amount, uint256 _cliff, uint256 _duration) public onlyOwner {
        require(_cliff >= 0, "Cliff cannot be negative.");
        require(_cliff <= 60 * 60 * 24 * 365 * 2, "Cliff cannot be more than 2 years.");
        require(token.balanceOf(address(this)) - (totalVestedAmount - totalReleasedAmount) >= _amount, "Not enough tokens.");
        if(vestingMap[_beneficiary].exists) revert("Vesting object for this beneficiary already exists.");

        Vesting memory v = Vesting({
            createdAt: block.timestamp,
            cliff: _cliff,
            duration: _duration,
            totalAmount: _amount,
            releasedAmount: 0,
            exists: true
        });

        vestingMap[_beneficiary] = v;
        totalVestedAmount = totalVestedAmount + _amount;
    }

    /// Method that allows a beneficiary to withdraw their allocated funds
    function withdraw() external {
        uint256 amount = getReleasableAmount(msg.sender);
        require(amount > 0, "Don't have released tokens.");

        // Increase released amount in in mapping
        vestingMap[msg.sender].releasedAmount = vestingMap[msg.sender].releasedAmount + amount;

        // Increase total released in contract
        totalReleasedAmount = totalReleasedAmount + amount;
        token.safeTransfer(msg.sender, amount);
    }

    /// Method that allows the owner to withdraw unallocated funds to a specific address
    function withdrawUnallocatedFunds(address _receiver) external onlyOwner {
        uint256 amount = getUnallocatedFundsAmount();
        require(amount > 0, "Don't have unallocated tokens.");
        token.safeTransfer(_receiver, amount);
    }

    // ===============================================================================================================
    // Getters
    // ===============================================================================================================

    /// Returns the amount vested, as a function of time, for an asset given its total historical allocation.
    function _vestingSchedule(address _beneficiary, uint256 _timestamp) internal view virtual returns (uint256) {
        Vesting memory vesting = vestingMap[_beneficiary];
        uint256 startedAt = vesting.createdAt + vesting.cliff;
        if (_timestamp < startedAt) {
            return 0;
        } else if (_timestamp > startedAt +  vesting.duration) {
            return vesting.totalAmount;
        } else {
            return (vesting.totalAmount * (_timestamp - startedAt)) / vesting.duration;
        }
    }

    /// Returns amount of funds that beneficiary will be able to withdraw at the given timestamp
    function getReleasableAmountAtTimestamp(address _beneficiary, uint256 _timestamp) public view returns (uint256) {
        return _vestingSchedule(_beneficiary, _timestamp) - vestingMap[_beneficiary].releasedAmount;
    }

    /// Returns amount of funds that beneficiary will be able to withdraw at the current moment
    function getReleasableAmount(address _beneficiary) public view returns (uint256) {
        return getReleasableAmountAtTimestamp(_beneficiary, block.timestamp);
    }

    /// Returns amount of unallocated funds that contract owner can withdraw
    function getUnallocatedFundsAmount() public view returns (uint256) {
        return token.balanceOf(address(this)) - (totalVestedAmount - totalReleasedAmount);
    }

    /// Returns the amount of beneficiary's tokens that still will be allocated at the given timestamp
    function getVestingAmountAtTimestamp(address _beneficiary, uint256 _timestamp) public view returns (uint256) {
        return vestingMap[_beneficiary].totalAmount - _vestingSchedule(_beneficiary, _timestamp);
    }

    /// Returns the amount of beneficiary's tokens that still will be allocated at the current moment
    function getVestingAmount(address _beneficiary) public view returns (uint256) {
        return getVestingAmountAtTimestamp(_beneficiary, block.timestamp);
    }

    /// Returns the total amount of beneficiary's tokens in the contract
    function getTotalVestingAmount(address _beneficiary) public view returns (uint256) {
        return vestingMap[_beneficiary].totalAmount;
    }

    // ===============================================================================================================
    // Modifiers
    // ===============================================================================================================

    /// Throws if called by any account other than the owner
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /// Throws if the sender is not the owner
    function _checkOwner() internal view virtual {
        require(owner == msg.sender, "Caller is not the owner");
    }
}