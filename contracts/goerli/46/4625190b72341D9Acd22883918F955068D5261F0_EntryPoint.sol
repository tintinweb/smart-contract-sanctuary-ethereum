/**
 ** Account-Abstraction (EIP-4337) singleton EntryPoint implementation.
 ** Only one instance required on each chain.
 **/
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "./StakeManager.sol";
import "./UserOperation.sol";
import "./IWallet.sol";
import "./IPaymaster.sol";

import "./ICreate2Deployer.sol";

contract EntryPoint is StakeManager {

    using UserOperationLib for UserOperation;

    enum PaymentMode {
        paymasterDeposit, // if paymaster is set, use paymaster's deposit to pay.
        walletDeposit // pay with wallet deposit.
    }

    address public immutable create2factory;

    /***
     * An event emitted after each successful request
     * @param requestId - unique identifier for the request (hash its entire content, except signature).
     * @param sender - the account that generates this request.
     * @param paymaster - if non-null, the paymaster that pays for this request.
     * @param nonce - the nonce value from the request
     * @param actualGasCost - the total cost (in gas) of this request.
     * @param actualGasPrice - the actual gas price the sender agreed to pay.
     * @param success - true if the sender transaction succeeded, false if reverted.
     */
    event UserOperationEvent(bytes32 indexed requestId, address indexed sender, address indexed paymaster, uint256 nonce, uint256 actualGasCost, uint256 actualGasPrice, bool success);

    /**
     * An event emitted if the UserOperation "callData" reverted with non-zero length
     * @param requestId the request unique identifier.
     * @param sender the sender of this request
     * @param nonce the nonce used in the request
     * @param revertReason - the return bytes from the (reverted) call to "callData".
     */
    event UserOperationRevertReason(bytes32 indexed requestId, address indexed sender, uint256 nonce, bytes revertReason);

    /**
     * a custom revert error of handleOps, to identify the offending op.
     *  NOTE: if simulateValidation passes successfully, there should be no reason for handleOps to fail on it.
     *  @param opIndex - index into the array of ops to the failed one (in simulateValidation, this is always zero)
     *  @param paymaster - if paymaster.validatePaymasterUserOp fails, this will be the paymaster's address. if validateUserOp failed,
     *       this value will be zero (since it failed before accessing the paymaster)
     *  @param reason - revert reason
     *   Should be caught in off-chain handleOps simulation and not happen on-chain.
     *   Useful for mitigating DoS attempts against batchers or for troubleshooting of wallet/paymaster reverts.
     */
    error FailedOp(uint256 opIndex, address paymaster, string reason);

    /**
     * @param _create2factory - contract to "create2" wallets (not the EntryPoint itself, so that the EntryPoint can be upgraded)
     * @param _paymasterStake - minimum required locked stake for a paymaster
     * @param _unstakeDelaySec - minimum time (in seconds) a paymaster stake must be locked
     */
    constructor(address _create2factory, uint256 _paymasterStake, uint32 _unstakeDelaySec) StakeManager(_paymasterStake, _unstakeDelaySec) {
        require(_create2factory != address(0), "invalid create2factory");
        require(_unstakeDelaySec > 0, "invalid unstakeDelay");
        require(_paymasterStake > 0, "invalid paymasterStake");
        create2factory = _create2factory;
    }

    /**
     * compensate the caller's beneficiary address with the collected fees of all UserOperations.
     * @param beneficiary the address to receive the fees
     * @param amount amount to transfer.
     */
    function _compensate(address payable beneficiary, uint256 amount) internal {
        require(beneficiary != address(0), "invalid beneficiary");
        (bool success,) = beneficiary.call{value : amount}("");
        require(success);
    }

    /**
     * Execute a batch of UserOperation.
     * @param ops the operations to execute
     * @param beneficiary the address to receive the fees
     */
    function handleOps(UserOperation[] calldata ops, address payable beneficiary) public {

        uint256 opslen = ops.length;
        UserOpInfo[] memory opInfos = new UserOpInfo[](opslen);

    unchecked {
        for (uint256 i = 0; i < opslen; i++) {
            uint256 preGas = gasleft();
            UserOperation calldata op = ops[i];

            bytes memory context;
            uint256 contextOffset;
            bytes32 requestId = getRequestId(op);
            uint256 prefund;
            PaymentMode paymentMode;
            (prefund, paymentMode, context) = _validatePrepayment(i, op, requestId);
            assembly {contextOffset := context}
            opInfos[i] = UserOpInfo(
                requestId,
                prefund,
                paymentMode,
                contextOffset,
                preGas - gasleft() + op.preVerificationGas
            );
        }

        uint256 collected = 0;

        for (uint256 i = 0; i < ops.length; i++) {
            uint256 preGas = gasleft();
            UserOperation calldata op = ops[i];
            UserOpInfo memory opInfo = opInfos[i];
            uint256 contextOffset = opInfo.contextOffset;
            bytes memory context;
            assembly {context := contextOffset}

            try this.innerHandleOp(op, opInfo, context) returns (uint256 _actualGasCost) {
                collected += _actualGasCost;
            } catch {
                uint256 actualGas = preGas - gasleft() + opInfo.preOpGas;
                collected += _handlePostOp(i, IPaymaster.PostOpMode.postOpReverted, op, opInfo, context, actualGas);
            }
        }

        _compensate(beneficiary, collected);
    } //unchecked
    }

    struct UserOpInfo {
        bytes32 requestId;
        uint256 prefund;
        PaymentMode paymentMode;
        uint256 contextOffset;
        uint256 preOpGas;
    }

    /**
     * inner function to handle a UserOperation.
     * Must be declared "external" to open a call context, but it can only be called by handleOps.
     */
    function innerHandleOp(UserOperation calldata op, UserOpInfo calldata opInfo, bytes calldata context) external returns (uint256 actualGasCost) {
        uint256 preGas = gasleft();
        require(msg.sender == address(this));

        IPaymaster.PostOpMode mode = IPaymaster.PostOpMode.opSucceeded;
        if (op.callData.length > 0) {

            (bool success,bytes memory result) = address(op.getSender()).call{gas : op.callGas}(op.callData);
            if (!success) {
                if (result.length > 0) {
                    emit UserOperationRevertReason(opInfo.requestId, op.getSender(), op.nonce, result);
                }
                mode = IPaymaster.PostOpMode.opReverted;
            }
        }

    unchecked {
        uint256 actualGas = preGas - gasleft() + opInfo.preOpGas;
        //note: opIndex is ignored (relevant only if mode==postOpReverted, which is only possible outside of innerHandleOp)
        return _handlePostOp(0, mode, op, opInfo, context, actualGas);
    }
    }

    /**
     * generate a request Id - unique identifier for this request.
     * the request ID is a hash over the content of the userOp (except the signature), the entrypoint and the chainid.
     */
    function getRequestId(UserOperation calldata userOp) public view returns (bytes32) {
        return keccak256(abi.encode(userOp.hash(), address(this), block.chainid));
    }

    /**
    * Simulate a call to wallet.validateUserOp and paymaster.validatePaymasterUserOp.
    * Validation succeeds if the call doesn't revert.
    * @dev The node must also verify it doesn't use banned opcodes, and that it doesn't reference storage outside the wallet's data.
     *      In order to split the running opcodes of the wallet (validateUserOp) from the paymaster's validatePaymasterUserOp,
     *      it should look for the NUMBER opcode at depth=1 (which itself is a banned opcode)
     * @return preOpGas total gas used by validation (including contract creation)
     * @return prefund the amount the wallet had to prefund (zero in case a paymaster pays)
     */
    function simulateValidation(UserOperation calldata userOp) external returns (uint256 preOpGas, uint256 prefund) {
        uint256 preGas = gasleft();

        bytes32 requestId = getRequestId(userOp);
        (prefund,,) = _validatePrepayment(0, userOp, requestId);
        preOpGas = preGas - gasleft() + userOp.preVerificationGas;

        require(msg.sender == address(0), "must be called off-chain with from=zero-addr");
    }

    function _getPaymentInfo(UserOperation calldata userOp) internal view returns (uint256 requiredPrefund, PaymentMode paymentMode) {
        requiredPrefund = userOp.requiredPreFund();
        if (userOp.hasPaymaster()) {
            paymentMode = PaymentMode.paymasterDeposit;
        } else {
            paymentMode = PaymentMode.walletDeposit;
        }
    }

    // create the sender's contract if needed.
    function _createSenderIfNeeded(UserOperation calldata op) internal {
        if (op.initCode.length != 0) {
            // note that we're still under the gas limit of validate, so probably
            // this create2 creates a proxy account.
            // @dev initCode must be unique (e.g. contains the signer address), to make sure
            //   it can only be executed from the entryPoint, and called with its initialization code (callData)
            address sender1 = ICreate2Deployer(create2factory).deploy(op.initCode, bytes32(op.nonce));
            require(sender1 != address(0), "create2 failed");
            require(sender1 == op.getSender(), "sender doesn't match create2 address");
        }
    }

    /**
     * Get counterfactual sender address.
     *  Calculate the sender contract address that will be generated by the initCode and salt in the UserOperation.
     * @param initCode the constructor code to be passed into the UserOperation.
     * @param salt the salt parameter, to be passed as "nonce" in the UserOperation.
     */
    function getSenderAddress(bytes memory initCode, uint256 salt) public view returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(create2factory),
                salt,
                keccak256(initCode)
            )
        );

        // NOTE: cast last 20 bytes of hash to address
        return address(uint160(uint256(hash)));
    }

    /**
     * call wallet.validateUserOp.
     * revert (with FailedOp) in case validateUserOp reverts, or wallet didn't send required prefund.
     * decrement wallet's deposit if needed
     */
    function _validateWalletPrepayment(uint256 opIndex, UserOperation calldata op, bytes32 requestId, uint256 requiredPrefund, PaymentMode paymentMode) internal returns (uint256 gasUsedByValidateWalletPrepayment) {
    unchecked {
        uint256 preGas = gasleft();
        _createSenderIfNeeded(op);
        uint256 missingWalletFunds = 0;
        address sender = op.getSender();
        if (paymentMode != PaymentMode.paymasterDeposit) {
            uint256 bal = balanceOf(sender);
            missingWalletFunds = bal > requiredPrefund ? 0 : requiredPrefund - bal;
        }
        try IWallet(sender).validateUserOp{gas : op.verificationGas}(op, requestId, missingWalletFunds) {
        } catch Error(string memory revertReason) {
            revert FailedOp(opIndex, address(0), revertReason);
        } catch {
            revert FailedOp(opIndex, address(0), "");
        }
        if (paymentMode != PaymentMode.paymasterDeposit) {
            DepositInfo storage senderInfo = deposits[sender];
            uint deposit = senderInfo.deposit;
            if (requiredPrefund > deposit) {
                revert FailedOp(opIndex, address(0), "wallet didn't pay prefund");
            }
            senderInfo.deposit = uint112(deposit - requiredPrefund);
        }
        gasUsedByValidateWalletPrepayment = preGas - gasleft();
    }
    }

    /**
     * in case the request has a paymaster:
     * validate paymaster is staked and has enough deposit.
     * call paymaster.validatePaymasterUserOp.
     * revert with proper FailedOp in case paymaster reverts.
     * decrement paymaster's deposit
     */
    function _validatePaymasterPrepayment(uint256 opIndex, UserOperation calldata op, bytes32 requestId, uint256 requiredPreFund, uint256 gasUsedByValidateWalletPrepayment) internal returns (bytes memory context) {
    unchecked {
        address paymaster = op.paymaster;
        DepositInfo storage paymasterInfo = deposits[paymaster];
        uint deposit = paymasterInfo.deposit;
        bool staked = paymasterInfo.staked;
        if (!staked) {
            revert FailedOp(opIndex, paymaster, "not staked");
        }
        if (deposit < requiredPreFund) {
            revert FailedOp(opIndex, paymaster, "paymaster deposit too low");
        }
        paymasterInfo.deposit = uint112(deposit - requiredPreFund);
        uint256 gas = op.verificationGas - gasUsedByValidateWalletPrepayment;
        try IPaymaster(paymaster).validatePaymasterUserOp{gas : gas}(op, requestId, requiredPreFund) returns (bytes memory _context){
            context = _context;
        } catch Error(string memory revertReason) {
            revert FailedOp(opIndex, paymaster, revertReason);
        } catch {
            revert FailedOp(opIndex, paymaster, "");
        }
    }
    }

    /**
     * validate wallet and paymaster (if defined).
     * also make sure total validation doesn't exceed verificationGas
     * this method is called off-chain (simulateValidation()) and on-chain (from handleOps)
     */
    function _validatePrepayment(uint256 opIndex, UserOperation calldata userOp, bytes32 requestId) private returns (uint256 requiredPreFund, PaymentMode paymentMode, bytes memory context){

        uint256 preGas = gasleft();
        uint256 maxGasValues = userOp.preVerificationGas | userOp.verificationGas |
        userOp.callGas | userOp.maxFeePerGas | userOp.maxPriorityFeePerGas;
        require(maxGasValues <= type(uint120).max, "gas values overflow");
        uint256 gasUsedByValidateWalletPrepayment;
        (requiredPreFund, paymentMode) = _getPaymentInfo(userOp);

        (gasUsedByValidateWalletPrepayment) = _validateWalletPrepayment(opIndex, userOp, requestId, requiredPreFund, paymentMode);

        //a "marker" where wallet opcode validation is done and paymaster opcode validation is about to start
        // (used only by off-chain simulateValidation)
        uint256 marker = block.number;
        (marker);

        if (paymentMode == PaymentMode.paymasterDeposit) {
            (context) = _validatePaymasterPrepayment(opIndex, userOp, requestId, requiredPreFund, gasUsedByValidateWalletPrepayment);
        } else {
            context = "";
        }
    unchecked {
        uint256 gasUsed = preGas - gasleft();

        if (userOp.verificationGas < gasUsed) {
            revert FailedOp(opIndex, userOp.paymaster, "Used more than verificationGas");
        }
    }
    }

    /**
     * process post-operation.
     * called just after the callData is executed.
     * if a paymaster is defined and its validation returned a non-empty context, its postOp is called.
     * the excess amount is refunded to the wallet (or paymaster - if it is was used in the request)
     * @param opIndex index in the batch
     * @param mode - whether is called from innerHandleOp, or outside (postOpReverted)
     * @param op the user operation
     * @param opInfo info collected during validation
     * @param context the context returned in validatePaymasterUserOp
     * @param actualGas the gas used so far by this user operation
     */
    function _handlePostOp(uint256 opIndex, IPaymaster.PostOpMode mode, UserOperation calldata op, UserOpInfo memory opInfo, bytes memory context, uint256 actualGas) private returns (uint256 actualGasCost) {
        uint256 preGas = gasleft();
        uint256 gasPrice = UserOperationLib.gasPrice(op);
    unchecked {
        address refundAddress;

        address paymaster = op.paymaster;
        if (paymaster == address(0)) {
            refundAddress = op.getSender();
        } else {
            refundAddress = paymaster;
            if (context.length > 0) {
                actualGasCost = actualGas * gasPrice;
                if (mode != IPaymaster.PostOpMode.postOpReverted) {
                    IPaymaster(paymaster).postOp{gas : op.verificationGas}(mode, context, actualGasCost);
                } else {
                    try IPaymaster(paymaster).postOp{gas : op.verificationGas}(mode, context, actualGasCost) {}
                    catch Error(string memory reason) {
                        revert FailedOp(opIndex, paymaster, reason);
                    }
                    catch {
                        revert FailedOp(opIndex, paymaster, "postOp revert");
                    }
                }
            }
        }
        actualGas += preGas - gasleft();
        actualGasCost = actualGas * gasPrice;
        if (opInfo.prefund < actualGasCost) {
            revert FailedOp(opIndex, paymaster, "prefund below actualGasCost");
        }
        uint refund = opInfo.prefund - actualGasCost;
        internalIncrementDeposit(refundAddress, refund);
        bool success = mode == IPaymaster.PostOpMode.opSucceeded;
        emit UserOperationEvent(opInfo.requestId, op.getSender(), op.paymaster, op.nonce, actualGasCost, gasPrice, success);
    } // unchecked
    }

    /**
     * return the storage cells used internally by the EntryPoint for this sender address.
     * During `simulateValidation`, allow these storage cells to be accessed
     *  (that is, a wallet/paymaster are allowed to access their own deposit balance on the
     *  EntryPoint's storage, but no other account)
     */
    function getSenderStorage(address sender) external view returns (uint256[] memory senderStorageCells) {
        uint256 cell;
        DepositInfo storage info = deposits[sender];

        assembly {
            cell := info.slot
        }
        senderStorageCells = new uint256[](1);
        senderStorageCells[0] = cell;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

/**
 * create2-based deployer (eip-2470)
 */
interface ICreate2Deployer {
    function deploy(bytes memory initCode, bytes32 salt) external returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "./UserOperation.sol";

/**
 * the interface exposed by a paymaster contract, who agrees to pay the gas for user's operations.
 * a paymaster must hold a stake to cover the required entrypoint stake and also the gas for the transaction.
 */
interface IPaymaster {

    /**
     * payment validation: check if paymaster agree to pay (using its stake)
     * revert to reject this request.
     * actual payment is done after postOp is called, by deducting actual call cost form the paymaster's stake.
     * @param userOp the user operation
     * @param requestId hash of the user's request data.
     * @param maxCost the maximum cost of this transaction (based on maximum gas and gas price from userOp)
     * @return context value to send to a postOp
     *  zero length to signify postOp is not required.
     */
    function validatePaymasterUserOp(UserOperation calldata userOp, bytes32 requestId, uint256 maxCost) external view returns (bytes memory context);

    /**
     * post-operation handler.
     * Must verify sender is the entryPoint
     * @param mode enum with the following options:
     *      opSucceeded - user operation succeeded.
     *      opReverted  - user op reverted. still has to pay for gas.
     *      postOpReverted - user op succeeded, but caused postOp (in mode=opSucceeded) to revert.
     *                       Now this is the 2nd call, after user's op was deliberately reverted.
     * @param context - the context value returned by validatePaymasterUserOp
     * @param actualGasCost - actual gas used so far (without this postOp call).
     */
    function postOp(PostOpMode mode, bytes calldata context, uint256 actualGasCost) external;

    enum PostOpMode {
        opSucceeded, // user op succeeded
        opReverted, // user op reverted. still has to pay for gas.
        postOpReverted //user op succeeded, but caused postOp to revert. Now its a 2nd call, after user's op was deliberately reverted.
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "./UserOperation.sol";

interface IWallet {

    /**
     * Validate user's signature and nonce
     * the entryPoint will make the call to the recipient only if this validation call returns successfully.
     *
     * @dev Must validate caller is the entryPoint.
     *      Must validate the signature and nonce
     * @param userOp the operation that is about to be executed.
     * @param requestId hash of the user's request data. can be used as the basis for signature.
     * @param missingWalletFunds missing funds on the wallet's deposit in the entrypoint.
     *      This is the minimum amount to transfer to the sender(entryPoint) to be able to make the call.
     *      The excess is left as a deposit in the entrypoint, for future calls.
     *      can be withdrawn anytime using "entryPoint.withdrawTo()"
     *      In case there is a paymaster in the request (or the current deposit is high enough), this value will be zero.
     */
    function validateUserOp(UserOperation calldata userOp, bytes32 requestId, uint256 missingWalletFunds) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.12;

/**
 * manage deposits and stakes.
 * deposit is just a balance used to pay for UserOperations (either by a paymaster or a wallet)
 * stake is value locked for at least "unstakeDelay" by a paymaster.
 */
abstract contract StakeManager {

    /**
     * minimum time (in seconds) required to lock a paymaster stake before it can be withdraw.
     */
    uint32 immutable public unstakeDelaySec;

    /**
     * minimum value required to stake for a paymaster
     */
    uint256 immutable public paymasterStake;

    constructor(uint256 _paymasterStake, uint32 _unstakeDelaySec) {
        unstakeDelaySec = _unstakeDelaySec;
        paymasterStake = _paymasterStake;
    }

    event Deposited(
        address indexed account,
        uint256 totalDeposit
    );

    event Withdrawn(
        address indexed account,
        address withdrawAddress,
        uint256 amount
    );

    /// Emitted once a stake is scheduled for withdrawal
    event StakeLocked(
        address indexed account,
        uint256 totalStaked,
        uint256 withdrawTime
    );

    /// Emitted once a stake is scheduled for withdrawal
    event StakeUnlocked(
        address indexed account,
        uint256 withdrawTime
    );

    event StakeWithdrawn(
        address indexed account,
        address withdrawAddress,
        uint256 amount
    );

    /**
     * @param deposit the account's deposit
     * @param staked true if this account is staked as a paymaster
     * @param stake actual amount of ether staked for this paymaster. must be above paymasterStake
     * @param unstakeDelaySec minimum delay to withdraw the stake. must be above the global unstakeDelaySec
     * @param withdrawTime - first block timestamp where 'withdrawStake' will be callable, or zero if already locked
     * @dev sizes were chosen so that (deposit,staked) fit into one cell (used during handleOps)
     *    and the rest fit into a 2nd cell.
     *    112 bit allows for 2^15 eth
     *    64 bit for full timestamp
     *    32 bit allow 150 years for unstake delay
     */
    struct DepositInfo {
        uint112 deposit;
        bool staked;
        uint112 stake;
        uint32 unstakeDelaySec;
        uint64 withdrawTime;
    }

    /// maps paymaster to their deposits and stakes
    mapping(address => DepositInfo) public deposits;

    function getDepositInfo(address account) public view returns (DepositInfo memory info) {
        return deposits[account];
    }

    /// return the deposit (for gas payment) of the account
    function balanceOf(address account) public view returns (uint256) {
        return deposits[account].deposit;
    }

    receive() external payable {
        depositTo(msg.sender);
    }

    function internalIncrementDeposit(address account, uint256 amount) internal {
        DepositInfo storage info = deposits[account];
        uint256 newAmount = info.deposit + amount;
        require(newAmount <= type(uint112).max, 'deposit overflow');
        info.deposit = uint112(newAmount);
    }

    /**
     * add to the deposit of the given account
     */
    function depositTo(address account) public payable {
        internalIncrementDeposit(account, msg.value);
        DepositInfo storage info = deposits[account];
        emit Deposited(account, info.deposit);
    }

    /**
     * add to the account's stake - amount and delay
     * any pending unstake is first cancelled.
     * @param _unstakeDelaySec the new lock duration before the deposit can be withdrawn.
     */
    function addStake(uint32 _unstakeDelaySec) public payable {
        DepositInfo storage info = deposits[msg.sender];
        require(_unstakeDelaySec >= unstakeDelaySec, "unstake delay too low");
        require(_unstakeDelaySec >= info.unstakeDelaySec, "cannot decrease unstake time");
        uint256 stake = info.stake + msg.value;
        require(stake >= paymasterStake, "stake value too low");
        require(stake < type(uint112).max, "stake overflow");
        deposits[msg.sender] = DepositInfo(
            info.deposit,
            true,
            uint112(stake),
            _unstakeDelaySec,
            0
        );
        emit StakeLocked(msg.sender, stake, _unstakeDelaySec);
    }

    /**
     * attempt to unlock the stake.
     * the value can be withdrawn (using withdrawStake) after the unstake delay.
     */
    function unlockStake() external {
        DepositInfo storage info = deposits[msg.sender];
        require(info.unstakeDelaySec != 0, "not staked");
        require(info.staked, "already unstaking");
        uint64 withdrawTime = uint64(block.timestamp) + info.unstakeDelaySec;
        info.withdrawTime = withdrawTime;
        info.staked = false;
        emit StakeUnlocked(msg.sender, withdrawTime);
    }


    /**
     * withdraw from the (unlocked) stake.
     * must first call unlockStake and wait for the unstakeDelay to pass
     * @param withdrawAddress the address to send withdrawn value.
     */
    function withdrawStake(address payable withdrawAddress) external {
        DepositInfo storage info = deposits[msg.sender];
        uint256 stake = info.stake;
        require(stake > 0, "No stake to withdraw");
        require(info.withdrawTime > 0, "must call unlockStake() first");
        require(info.withdrawTime <= block.timestamp, "Stake withdrawal is not due");
        info.unstakeDelaySec = 0;
        info.withdrawTime = 0;
        info.stake = 0;
        emit StakeWithdrawn(msg.sender, withdrawAddress, stake);
        (bool success,) = withdrawAddress.call{value : stake}("");
        require(success, "failed to withdraw stake");
    }

    /**
     * withdraw from the deposit.
     * @param withdrawAddress the address to send withdrawn value.
     * @param withdrawAmount the amount to withdraw.
     */
    function withdrawTo(address payable withdrawAddress, uint256 withdrawAmount) external {
        DepositInfo memory info = deposits[msg.sender];
        require(withdrawAmount <= info.deposit, "Withdraw amount too large");
        info.deposit = uint112(info.deposit - withdrawAmount);
        emit Withdrawn(msg.sender, withdrawAddress, withdrawAmount);
        (bool success,) = withdrawAddress.call{value : withdrawAmount}("");
        require(success, "failed to withdraw");
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

    /**
     * User Operation struct
     * @param sender the sender account of this request
     * @param nonce unique value the sender uses to verify it is not a replay.
     * @param initCode if set, the account contract will be created by this constructor
     * @param callData the method call to execute on this account.
     * @param verificationGas gas used for validateUserOp and validatePaymasterUserOp
     * @param preVerificationGas gas not calculated by the handleOps method, but added to the gas paid. Covers batch overhead.
     * @param maxFeePerGas same as EIP-1559 gas parameter
     * @param maxPriorityFeePerGas same as EIP-1559 gas parameter
     * @param paymaster if set, the paymaster will pay for the transaction instead of the sender
     * @param paymasterData extra data used by the paymaster for validation
     * @param signature sender-verified signature over the entire request, the EntryPoint address and the chain ID.
     */
    struct UserOperation {

        address sender;
        uint256 nonce;
        bytes initCode;
        bytes callData;
        uint256 callGas;
        uint256 verificationGas;
        uint256 preVerificationGas;
        uint256 maxFeePerGas;
        uint256 maxPriorityFeePerGas;
        address paymaster;
        bytes paymasterData;
        bytes signature;
    }

library UserOperationLib {

    function getSender(UserOperation calldata userOp) internal pure returns (address) {
        address data;
        //read sender from userOp, which is first userOp member (saves 800 gas...)
        assembly {data := calldataload(userOp)}
        return address(uint160(data));
    }

    //relayer/miner might submit the TX with higher priorityFee, but the user should not
    // pay above what he signed for.
    function gasPrice(UserOperation calldata userOp) internal view returns (uint256) {
    unchecked {
        uint256 maxFeePerGas = userOp.maxFeePerGas;
        uint256 maxPriorityFeePerGas = userOp.maxPriorityFeePerGas;
        if (maxFeePerGas == maxPriorityFeePerGas) {
            //legacy mode (for networks that don't support basefee opcode)
            return maxFeePerGas;
        }
        return min(maxFeePerGas, maxPriorityFeePerGas + block.basefee);
    }
    }

    function requiredGas(UserOperation calldata userOp) internal pure returns (uint256) {
    unchecked {
        //when using a Paymaster, the verificationGas is used also to cover the postOp call.
        // our security model might call postOp eventually twice
        uint256 mul = hasPaymaster(userOp) ? 3 : 1;
        return userOp.callGas + userOp.verificationGas * mul + userOp.preVerificationGas;
    }
    }

    function requiredPreFund(UserOperation calldata userOp) internal view returns (uint256 prefund) {
    unchecked {
        return requiredGas(userOp) * gasPrice(userOp);
    }
    }

    function hasPaymaster(UserOperation calldata userOp) internal pure returns (bool) {
        return userOp.paymaster != address(0);
    }

    function pack(UserOperation calldata userOp) internal pure returns (bytes memory ret) {
        //lighter signature scheme. must match UserOp.ts#packUserOp
        bytes calldata sig = userOp.signature;
        // copy directly the userOp from calldata up to (but not including) the signature.
        // this encoding depends on the ABI encoding of calldata, but is much lighter to copy
        // than referencing each field separately.
        assembly {
            let ofs := userOp
            let len := sub(sub(sig.offset, ofs), 32)
            ret := mload(0x40)
            mstore(0x40, add(ret, add(len, 32)))
            mstore(ret, len)
            calldatacopy(add(ret, 32), ofs, len)
        }
    }

    function hash(UserOperation calldata userOp) internal pure returns (bytes32) {
        return keccak256(pack(userOp));
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}