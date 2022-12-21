// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract PaymentReceiver {
    address public owner;
    address public pendingOwner;

    event OwnershipTransferStarted(address indexed from, address indexed to);
    event OwnershipTransferred(address indexed from, address indexed newOwner);
    event PaymentReceived(address indexed from, uint256 amount);
    event BalancePulled(address indexed to, uint256 amount);

    error Unauthorized();
    error InvalidAddress();
    error TransferFailed();

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert Unauthorized();
        }

        _;
    }

    /// @param _owner The owner of the contract
    constructor(address _owner) {
        if (_owner == address(0)) {
            revert InvalidAddress();
        }

        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    receive() external payable {
        emit PaymentReceived(msg.sender, msg.value);
    }

    fallback() external payable {
        emit PaymentReceived(msg.sender, msg.value);
    }

    /// @notice Starts the ownership transfer to `_newOwner`
    /// @param _newOwner The future owner of the contract
    function transferOwnership(address _newOwner) external onlyOwner {
        if (_newOwner == address(0)) {
            revert InvalidAddress();
        }

        pendingOwner = _newOwner;

        emit OwnershipTransferStarted(msg.sender, _newOwner);
    }

    /// @notice Used by the `pendingOwner` to accept the ownership of the contract
    function acceptOwnership() external {
        address futureOwner = pendingOwner;

        if (msg.sender != futureOwner) {
            revert Unauthorized();
        }

        delete pendingOwner;

        owner = futureOwner;

        emit OwnershipTransferred(owner, futureOwner);
    }

    /// @notice pulls the ETH balance to `_to`
    /// @param _to The address that will receive the balance of the contract
    function pull(address _to) public onlyOwner {
        uint256 balance = address(this).balance;

        (bool success,) = _to.call{value: balance}("");

        if (!success) {
            revert TransferFailed();
        }

        emit BalancePulled(_to, balance);
    }

    /// @notice pulls the ETH balance to the `owner`
    function pull() public {
        pull(msg.sender);
    }
}