// SPDX-License-Identifier: MIT

pragma solidity >=0.6.6;

/// @title The Platform's Funds Manager Contract
/// @author Amarandei Matei Alexandru (@Alex-Amarandei)
/**
 * @notice The contract is responsible with managing the in/outflow of funds
 * Its functions are called in several scripts in order to:
 * - pay the initial fee of placing an order
 * - refund users if they cancel their orders
 * - simulate using the users' "accounts" for paying the gas fees
 */
/// @dev Provides a low-level alternative to meta-transactions with relayers
contract FundsManager {
    address payable private owner;
    uint256 public fee;
    mapping(address => uint256) public userGasAmounts;

    /// @param _fee The fee to be paid when an order is placed by a user
    /// @dev The owner address for the later funding of the platform's wallet
    constructor(uint256 _fee) {
        owner = payable(msg.sender);
        fee = _fee;
    }

    modifier ownerOnly() {
        require(msg.sender == owner);
        _;
    }

    /// @notice Used by a user to fund the platform in order to compensate for the gas used
    function fundWithGas() external payable {
        require(msg.value == fee, "You need to send exactly the fee in ETH!");

        userGasAmounts[msg.sender] += msg.value;
    }

    /// @param _all Specifies if a user wants to cancel all their existing orders
    /// @notice Refunds the fees accumulated partially or fully
    function refundGas(bool _all, uint256 _fee) public {
        require(
            userGasAmounts[msg.sender] <= _fee,
            "This account has no associated funds left or not enough for the fee provided!"
        );

        address payable user = payable(msg.sender);

        if (_all) {
            user.transfer(userGasAmounts[msg.sender]);
            userGasAmounts[msg.sender] = 0;
        } else {
            require(_fee > 0, "The fee cannot be zero.");
            user.transfer(_fee);
            userGasAmounts[msg.sender] -= _fee;
        }
    }

    /// @param _userAddress The user "account" which is to be debited
    /// @notice The fee is debited in order to simulate using user funds for gas
    function useGas(address _userAddress, uint256 _fee) external ownerOnly {
        require(_fee > 0, "The fee cannot be zero.");
        require(
            userGasAmounts[msg.sender] >= _fee,
            "This account has no associated funds left or not enough for the fee provided!"
        );

        owner.transfer(_fee);
        userGasAmounts[_userAddress] -= _fee;
    }

    /// @param _newFee The new fee of placing an order
    /// @notice Updates the fee charged by the platform
    function updateFee(uint256 _newFee) external ownerOnly {
        fee = _newFee;
    }
}