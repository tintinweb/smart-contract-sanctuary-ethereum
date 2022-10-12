// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom( address src, address dst, uint256 rawAmount) external returns (bool);
}

/// A RAD Faucet
contract FaucetV1 {
    address public owner;
    uint256 public maxWithdrawAmount;

    mapping(address => uint256) public lastWithdrawalByUser;

    constructor(
        uint256 _maxWithdrawAmount
    ) {
        owner = msg.sender;
        maxWithdrawAmount = _maxWithdrawAmount;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Faucet: Only the faucet owner can perform this action.");
        _;
    }

    /// @notice Sets a new owner to the faucet
    /// @param _newOwner Address of new owner
    function setOwner(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Faucet: New owner is the zero address");
        address _oldOwner = owner;
        owner = _newOwner;

        emit OwnershipTransferred(_oldOwner, _newOwner);
    }

    /// @notice Calculates the the amount of hours to wait, relative to the amount withdrawed.
    /// @dev If the value is between 1 and 4 tokens the result is zero, in that case we return 360 seconds.
    /// @param _amount The amount of tokens to be withdrawed
    /// @return The amount of seconds the requester has to wait for their next withdrawal.
    function calculateTimeLock(uint256 _amount) public pure returns (uint256) {
        uint timelock = (_amount / 10**18)**2 * 1 / 10 * 3600;
        return max(timelock, 360 seconds);
    }

    /// @notice Returns the higher value of two
    /// @param a Number to compare
    /// @param b Number to compare
    /// @return The higher value of two
    function max(uint a, uint b) private pure returns (uint) {
        return a > b ? a : b;
    }

    /// @notice Sets the max amount available to withdraw in one withdrawal.
    /// @param _amount The max amount of tokens to be withdrawed
    function setMaxAmount(uint256 _amount) public onlyOwner {
        maxWithdrawAmount = _amount;
    }

    /// @notice Recover funds in faucet to owner
    function recoverFunds(IERC20 _token, uint256 _amount) public onlyOwner {
        _token.transferFrom(address(this), owner, _amount);
    }

    /// @notice Creates a transaction to withdraw a defined amount of tokens
    /// @param _amount The amount of tokens to be withdrawed
    function withdraw(IERC20 _token, uint256 _amount) public {
        require(_amount <= maxWithdrawAmount, "Faucet: Only able to withdraw maxWithdrawAmount or less");
        require(lastWithdrawalByUser[msg.sender] + calculateTimeLock(_amount) < block.timestamp, "Faucet: Not allowed to withdrawal at the moment");

        _token.transferFrom(address(this), msg.sender, _amount);
        lastWithdrawalByUser[msg.sender] = block.timestamp; 
    }
}