// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// external dependencies
import "./interfaces/IDeposit.sol";

/// @notice  Batch ETH2 deposits, uses the official Deposit contract from the ETH
///          Foundation for each atomic deposit. This contract acts as a for loop.
///          Each deposit size will be an optimal 32 ETH.
///
/// @dev     The batch size has an upper bound due to the block gas limit. Each atomic
///          deposit costs ~62,000 gas. The current block gas-limit is ~12,400,000 gas.
///
contract BatchDeposit {

    /*************** STORAGE VARIABLE DECLARATIONS **************/

    uint256 public immutable DEPOSIT_AMOUNT;
    IDeposit public immutable DEPOSIT_CONTRACT;

    constructor(address _depositContract, uint256 _depositAmount) {
        DEPOSIT_AMOUNT = _depositAmount;
        DEPOSIT_CONTRACT = IDeposit(_depositContract);
    }

    /*************** EVENT DECLARATIONS **************/

    /// @notice  Signals a refund of sent-in Ether that was extra and not required.
    ///
    /// @dev     The refund is sent to the msg.sender.
    ///
    /// @param  to - The ETH address receiving the ETH.
    /// @param  amount - The amount of ETH being refunded.
    event LogSendDepositLeftover(address to, uint256 amount);

    /////////////////////// FUNCTION DECLARATIONS BEGIN ///////////////////////

    /********************* PUBLIC FUNCTIONS **********************/

    /// @notice  Fallback function.
    ///
    /// @dev     Used to address parties trying to send in Ether with a helpful
    ///          error message.
    fallback() external payable {
        revert("#BatchDeposit fallback(): Use the `batchDeposit(...)` function to send Ether to this contract.");
    }

    /// @notice  Receive function.
    ///
    /// @dev     Used to address parties trying to send in Ether with a helpful
    ///          error message.
    receive() external payable {
        revert("#BatchDeposit receive(): Use the `batchDeposit(...)` function to send Ether to this contract.");
    }

    /// @notice Submit index-matching arrays that form Phase 0 DepositData objects.
    ///         Will create a deposit transaction per index of the arrays submitted.
    ///
    /// @param pubkeys - An array of BLS12-381 public keys.
    /// @param withdrawal_credentials - An array of commitment to public key for withdrawals.
    /// @param signatures - An array of BLS12-381 signatures.
    /// @param deposit_data_roots - An array of the SHA-256 hash of the SSZ-encoded DepositData object.
    function batchDeposit(
        bytes[] calldata pubkeys,
        bytes[] calldata withdrawal_credentials,
        bytes[] calldata signatures,
        bytes32[] calldata deposit_data_roots
    ) external payable {
        require(
            pubkeys.length == withdrawal_credentials.length &&
            pubkeys.length == signatures.length &&
            pubkeys.length == deposit_data_roots.length,
            "#BatchDeposit batchDeposit(): All parameter array's must have the same length."
        );
        require(
            pubkeys.length > 0,
            "#BatchDeposit batchDeposit(): All parameter array's must have a length greater than zero."
        );
        require(
            msg.value >= DEPOSIT_AMOUNT * pubkeys.length,
            "#BatchDeposit batchDeposit(): Ether deposited needs to be at least: 32 * (parameter `pubkeys[]` length)."
        );
        uint256 deposited = 0;

        // Loop through DepositData arrays submitting deposits
        for (uint256 i = 0; i < pubkeys.length; i++) {
            DEPOSIT_CONTRACT.deposit{value: DEPOSIT_AMOUNT}(
                pubkeys[i],
                withdrawal_credentials[i],
                signatures[i],
                deposit_data_roots[i]
            );
            deposited = deposited + DEPOSIT_AMOUNT;
        }
        assert(deposited == DEPOSIT_AMOUNT * pubkeys.length);
        uint256 ethToReturn = msg.value - deposited;
        if (ethToReturn > 0) {

          emit LogSendDepositLeftover(msg.sender, ethToReturn);

          (bool success, ) =  payable(msg.sender).call{value: ethToReturn}("");
          require(success, "unable to send value, recipient may have reverted");
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/// @notice  Interface of the official Deposit contract from the ETH
///          Foundation.
interface IDeposit {

    /// @notice Submit a Phase 0 DepositData object.
    ///
    /// @param pubkey - A BLS12-381 public key.
    /// @param withdrawal_credentials - Commitment to a public key for withdrawals.
    /// @param signature - A BLS12-381 signature.
    /// @param deposit_data_root - The SHA-256 hash of the SSZ-encoded DepositData object.
    ///                            Used as a protection against malformed input.
    function deposit(
        bytes calldata pubkey,
        bytes calldata withdrawal_credentials,
        bytes calldata signature,
        bytes32 deposit_data_root
    ) external payable;

}