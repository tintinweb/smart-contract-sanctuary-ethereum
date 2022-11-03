// SPDX-License-Identifier: MIT

pragma solidity 0.5.11;
pragma experimental ABIEncoderV2;

import "./Address.sol";
import "./SafeMath.sol";

import "./IDeposit.sol";

/// @notice  Batch ETH2 deposits, uses the official Deposit contract from the ETH
///          Foundation for each atomic deposit. This contract acts as a for loop.
///          Each deposit size will be an optimal 32 ETH.
///
/// @dev     The batch size has an upper bound due to the block gas limit. Each atomic
///          deposit costs ~62,000 gas. The current block gas-limit is ~12,400,000 gas.
///
/// Author:  Staked Securely, Inc. (https://staked.us/)
contract BatchDeposit {
    using Address for address payable;
    using SafeMath for uint256;

    /*************** STORAGE VARIABLE DECLARATIONS **************/

    uint256 public constant DEPOSIT_AMOUNT = 32 ether;
    // currently points at the Mainnet Deposit Contract
    address public constant DEPOSIT_CONTRACT_ADDRESS = 0xff50ed3d0ec03aC01D4C79aAd74928BFF48a7b2b;
    IDeposit private constant DEPOSIT_CONTRACT = IDeposit(DEPOSIT_CONTRACT_ADDRESS);

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

    /// @notice  Empty constructor.
    constructor() public {}

    /// @notice  Fallback function.
    ///
    /// @dev     Used to address parties trying to send in Ether with a helpful
    ///          error message.
    function() external payable {
        revert("#BatchDeposit fallback(): Use the `batchDeposit(...)` function to send Ether to this contract.");
    }

    /// @notice Submit index-matching arrays that form Phase 0 DepositData objects.
    ///         Will create a deposit transaction per index of the arrays submitted.
    ///
    /// @param pubkeys - An array of BLS12-381 public keys.
    /// @param withdrawal_credentials - An array of public keys for withdrawals.
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
            msg.value >= DEPOSIT_AMOUNT.mul(pubkeys.length),
            "#BatchDeposit batchDeposit(): Ether deposited needs to be at least: 32 * (parameter `pubkeys[]` length)."
        );
        uint256 deposited = 0;

        // Loop through DepositData arrays submitting deposits
        for (uint256 i = 0; i < pubkeys.length; i++) {
            DEPOSIT_CONTRACT.deposit.value(DEPOSIT_AMOUNT)(
                pubkeys[i],
                withdrawal_credentials[i],
                signatures[i],
                deposit_data_roots[i]
            );
            deposited = deposited.add(DEPOSIT_AMOUNT);
        }
        assert(deposited == DEPOSIT_AMOUNT.mul(pubkeys.length));
        uint256 ethToReturn = msg.value.sub(deposited);
        if (ethToReturn > 0) {

          // Emit `LogSendDepositLeftover` log
          emit LogSendDepositLeftover(msg.sender, ethToReturn);

          // This function doesn't guard against re-entrancy, and we're calling an
          // untrusted address, but in this situation there is no state, etc. to
          // take advantage of, so re-entrancy guard is unneccesary gas cost.
          // This function uses call.value(), and handles return values/failures by
          // reverting the transaction.
          (msg.sender).sendValue(ethToReturn);
        }
    }
}