// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./EntryPoint.sol";
import "./BasePaymaster.sol";

/**
 * Paymaster that accepts WETH tokens as payment.
 * The paymaster must be approved to transfer tokens from the user wallet.
 */
contract WETHTokenPaymaster is BasePaymaster {
    //calculated cost of the postOp
    uint256 constant COST_OF_POST = 15000;

    using UserOperationLib for UserOperation;
    IERC20 public WETHToken;
    mapping(bytes32 => bool) public KnownWallets;

    constructor(EntryPoint _entryPoint,address _owner, IERC20 _WETHToken)
        BasePaymaster(_entryPoint, _owner)
    {
        WETHToken = _WETHToken;
    }

    function addWallet(bytes32 walletCodeHash) public onlyOwner {
        KnownWallets[walletCodeHash] = true;
    }

    function removeWallet(bytes32 walletCodeHash) public onlyOwner {
        delete KnownWallets[walletCodeHash];
    }

    function withdraw(address payable to) public onlyOwner {
        uint256 balance = WETHToken.balanceOf(address(this));
        require(balance >= 0, "not enough balance");
        WETHToken.transfer(to, balance);
    }

    /**
     * @dev check allowance amount and user wallet banlance
     */
    function validatePaymasterUserOp(
        UserOperation calldata userOp,
        bytes32, /*requestId*/
        uint256 requiredPreFund
    ) external view override returns (bytes memory context) {
        // make sure that verificationGas is high enough to handle postOp
        require(
            userOp.verificationGas > 45000,
            "WETH-TokenPaymaster: gas too low for postOp"
        );

        address sender = userOp.getSender();

        if (userOp.initCode.length != 0) {
            _validateConstructor(userOp);
        } else {
            require(
                WETHToken.allowance(sender, address(this)) >= requiredPreFund,
                "WETH-TokenPaymaster: not enough allowance"
            );
        }

        require(
            WETHToken.balanceOf(sender) >= requiredPreFund,
            "WETH-TokenPaymaster: not enough balance"
        );
        
        return abi.encode(userOp.sender);
    }

    // when constructing a wallet, validate constructor code and parameters
    function _validateConstructor(UserOperation calldata userOp)
        internal
        view
        virtual
    {
        //constructor(EntryPoint anEntryPoint, address anOwner, IERC20 token, address paymaster)
        bytes32 bytecodeHash = keccak256(
            userOp.initCode[0:userOp.initCode.length - 128]
        );

        // no check on POC
        (bytecodeHash);
        // require(
        //     KnownWallets[bytecodeHash],
        //     "TokenPaymaster: unknown wallet constructor"
        // );


        // first param (of 4) should be our entryPoint
        bytes32 entryPointParam = bytes32(
            userOp.initCode[userOp.initCode.length - 128:]
        );
        require(
            address(uint160(uint256(entryPointParam))) == address(entryPoint),
            "wrong paymaster in constructor"
        );

        //the 3rd parameter is WETH token
        bytes32 tokenParam = bytes32(
            userOp.initCode[userOp.initCode.length - 64:]
        );
        require(
            address(uint160(uint256(tokenParam))) == address(WETHToken),
            "wrong token in constructor"
        );

        //the 4th parameter is this paymaster
        bytes32 paymasterParam = bytes32(
            userOp.initCode[userOp.initCode.length - 32:]
        );
        require(
            address(uint160(uint256(paymasterParam))) == address(this),
            "wrong paymaster in constructor"
        );
    }

    //actual charge of user.
    // this method will be called just after the user's TX with mode==OpSucceeded|OpReverted.
    // BUT: if the user changed its balance in a way that will cause  postOp to revert, then it gets called again, after reverting
    // the user's TX
    function _postOp(
        PostOpMode mode,
        bytes calldata context,
        uint256 actualGasCost
    ) internal override {
        (mode);
        address sender = abi.decode(context, (address));
        //actualGasCost is known to be no larger than the above requiredPreFund, so the transfer should succeed.
        WETHToken.transferFrom(
            sender,
            address(this),
            actualGasCost + COST_OF_POST
        );
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;
import "./Ownable.sol";
import "./IPaymaster.sol";
import "./EntryPoint.sol";

/**
 * Helper class for creating a paymaster.
 * provider helper methods for staking.
 * validates that the postOp is called only by the entryPoint
 */
abstract contract BasePaymaster is IPaymaster, Ownable {

    EntryPoint public entryPoint;

    constructor(EntryPoint _entryPoint, address _owner) Ownable(_owner) {
        _setEntrypoint(_entryPoint);
    }

    function _setEntrypoint(EntryPoint _entryPoint) private {
        entryPoint = _entryPoint;
    }

    function setEntrypoint(EntryPoint _entryPoint) public onlyOwner {
        _setEntrypoint(_entryPoint);
    }

    function validatePaymasterUserOp(UserOperation calldata userOp, bytes32 requestId, uint maxCost) external virtual override view returns (bytes memory context);

    function postOp(PostOpMode mode, bytes calldata context, uint actualGasCost) external override {
        _requireFromEntrypoint();
        _postOp(mode, context, actualGasCost);
    }

    /**
     * post-operation handler.
     * (verified to be called only through the entryPoint)
     * @dev if subclass returns a non-empty context from validatePaymasterUserOp, it must also implement this method.
     * @param mode enum with the following options:
     *      opSucceeded - user operation succeeded.
     *      opReverted  - user op reverted. still has to pay for gas.
     *      postOpReverted - user op succeeded, but caused postOp (in mode=opSucceeded) to revert.
     *                       Now this is the 2nd call, after user's op was deliberately reverted.
     * @param context - the context value returned by validatePaymasterUserOp
     * @param actualGasCost - actual gas used so far (without this postOp call).
     */
    function _postOp(PostOpMode mode, bytes calldata context, uint actualGasCost) internal virtual {

        (mode,context,actualGasCost); // unused params
        // subclass must override this method if validatePaymasterUserOp returns a context
        revert("must override");
    }

    /**
     * add stake for this paymaster
     * @param extraUnstakeDelaySec - extra delay (above the minimum required unstakeDelay of the entrypoint)
     */
    function addStake(uint32 extraUnstakeDelaySec) external payable onlyOwner {
        entryPoint.addStakeTo{value:msg.value}(address(this), entryPoint.unstakeDelaySec() + extraUnstakeDelaySec);
    }

    function getDeposit() public view returns (uint) {
        return entryPoint.balanceOf(address(this));
    }

    /**
     * attempt to unstake the deposit.
     * The paymaster can't serve requests once unstaked.
     */
    function unstakeDeposit() external onlyOwner {
        entryPoint.unstakeDeposit();
    }

    /**
     * withdraw from the paymaster's stake.
     * stake must be unlocked first.
     * after a paymaster unlocks and withdraws some of the value, it must call addStake() to stake the value again.
     * @param withdrawAddress the address to send withdrawn value.
     * @param withdrawAmount the amount to withdraw.
     */
    function withdrawTo(address payable withdrawAddress, uint withdrawAmount) external onlyOwner {
        entryPoint.withdrawTo(withdrawAddress, withdrawAmount);
    }

    /// validate the call is made from a valid entrypoint
    function _requireFromEntrypoint() internal virtual {
        require(msg.sender == address(entryPoint));
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "./StakeManager.sol";
import "./UserOperation.sol";
import "./IWallet.sol";
import "./IPaymaster.sol";

interface ICreate2Deployer {
    function deploy(bytes memory _initCode, bytes32 _salt) external returns (address);
}

contract EntryPoint is StakeManager {

    using UserOperationLib for UserOperation;

    enum PaymentMode {
        paymasterStake, // if paymaster is set, use paymaster's stake to pay.
        walletStake // pay with wallet deposit.
    }

    uint public immutable paymasterStake;
    address public immutable create2factory;

    event UserOperationEvent(bytes32 indexed requestId, address indexed sender, address indexed paymaster, uint nonce, uint actualGasCost, uint actualGasPrice, bool success);
    event UserOperationRevertReason(bytes32 indexed requestId, address indexed sender, uint nonce, bytes revertReason);

    //handleOps reverts with this error struct, to mark the offending op
    // NOTE: if simulateOp passes successfully, there should be no reason for handleOps to fail on it.
    // @param opIndex - index into the array of ops to the failed one (in simulateOp, this is always zero)
    // @param paymaster - if paymaster.validatePaymasterUserOp fails, this will be the paymaster's address. if validateUserOp failed,
    //      this value will be zero (since it failed before accessing the paymaster)
    // @param reason - revert reason
    //  only to aid troubleshooting of wallet/paymaster reverts
    error FailedOp(uint opIndex, address paymaster, string reason);

    /**
     * @param _create2factory - contract to "create2" wallets (not the EntryPoint itself, so that it can be upgraded)
     * @param _paymasterStake - locked stake of paymaster (actual value should also cover TX cost)
     * @param _unstakeDelaySec - minimum time (in seconds) a paymaster stake must be locked
     */
    constructor(address _create2factory, uint _paymasterStake, uint32 _unstakeDelaySec) StakeManager(_unstakeDelaySec) {
        create2factory = _create2factory;
        paymasterStake = _paymasterStake;
    }

    /**
     * Execute the given UserOperation.
     * @param op the operation to execute
     * @param beneficiary the address to receive the fees
     */
    function handleOp(UserOperation calldata op, address payable beneficiary) public {

        uint preGas = gasleft();

    unchecked {
        bytes32 requestId = getRequestId(op);
        (uint256 prefund, PaymentMode paymentMode, bytes memory context) = _validatePrepayment(0, op, requestId);
        UserOpInfo memory opInfo = UserOpInfo(
            requestId,
            prefund,
            paymentMode,
            0,
            preGas - gasleft() + op.preVerificationGas
        );

        uint actualGasCost;

        try this.internalHandleOp(op, opInfo, context) returns (uint _actualGasCost) {
            actualGasCost = _actualGasCost;
        } catch {
            uint actualGas = preGas - gasleft() + opInfo.preOpGas;
            actualGasCost = handlePostOp(0, IPaymaster.PostOpMode.postOpReverted, op, opInfo, context, actualGas);
        }

        compensate(beneficiary, actualGasCost);
    } // unchecked
    }

    function compensate(address payable beneficiary, uint amount) internal {
        (bool success,) = beneficiary.call{value : amount}("");
        require(success);
    }

    /**
     * Execute a batch of UserOperation.
     * @param ops the operations to execute
     * @param beneficiary the address to receive the fees
     */
    function handleOps(UserOperation[] calldata ops, address payable beneficiary) public {

        uint opslen = ops.length;
        UserOpInfo[] memory opInfos = new UserOpInfo[](opslen);

    unchecked {
        for (uint i = 0; i < opslen; i++) {
            uint preGas = gasleft();
            UserOperation calldata op = ops[i];

            bytes memory context;
            uint contextOffset;
            bytes32 requestId = getRequestId(op);
            uint prefund;
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

        uint collected = 0;

        for (uint i = 0; i < ops.length; i++) {
            uint preGas = gasleft();
            UserOperation calldata op = ops[i];
            UserOpInfo memory opInfo = opInfos[i];
            uint contextOffset = opInfo._context;
            bytes memory context;
            assembly {context := contextOffset}

            try this.internalHandleOp(op, opInfo, context) returns (uint _actualGasCost) {
                collected += _actualGasCost;
            } catch {
                uint actualGas = preGas - gasleft() + opInfo.preOpGas;
                collected += handlePostOp(i, IPaymaster.PostOpMode.postOpReverted, op, opInfo, context, actualGas);
            }
        }

        compensate(beneficiary, collected);
    } //unchecked
    }

    struct UserOpInfo {
        bytes32 requestId;
        uint prefund;
        PaymentMode paymentMode;
        uint _context;
        uint preOpGas;
    }

    function internalHandleOp(UserOperation calldata op, UserOpInfo calldata opInfo, bytes calldata context) external returns (uint actualGasCost) {
        uint preGas = gasleft();
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
        uint actualGas = preGas - gasleft() + opInfo.preOpGas;
        return handlePostOp(0, mode, op, opInfo, context, actualGas);
    }
    }

    /**
     * generate a request Id - unique identifier for this request.
     * the request ID is a hash over the content of the userOp (except the signature).
     */
    function getRequestId(UserOperation calldata userOp) public view returns (bytes32) {
        return keccak256(abi.encode(userOp.hash(), address(this), block.chainid));
    }

    /**
    * Simulate a call to wallet.validateUserOp and paymaster.validatePaymasterUserOp.
    * Validation succeeds of the call doesn't revert.
    * @dev The node must also verify it doesn't use banned opcodes, and that it doesn't reference storage outside the wallet's data.
     *      In order to split the running opcodes of the wallet (validateUserOp) from the paymaster's validatePaymasterUserOp,
     *      it should look for the NUMBER opcode at depth=1 (which itself is a banned opcode)
     * @return preOpGas total gas used by validation (including contract creation)
     * @return prefund the amount the wallet had to prefund (zero in case a paymaster pays)
     */
    function simulateValidation(UserOperation calldata userOp) external returns (uint preOpGas, uint prefund) {
        uint preGas = gasleft();

        bytes32 requestId = getRequestId(userOp);
        (prefund,,) = _validatePrepayment(0, userOp, requestId);
        preOpGas = preGas - gasleft() + userOp.preVerificationGas;

        require(msg.sender == address(0), "must be called off-chain with from=zero-addr");
    }

    function _getPaymentInfo(UserOperation calldata userOp) internal view returns (uint requiredPrefund, PaymentMode paymentMode) {
        requiredPrefund = userOp.requiredPreFund();
        if (userOp.hasPaymaster()) {
            paymentMode = PaymentMode.paymasterStake;
        } else {
            paymentMode = PaymentMode.walletStake;
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

    /// Get counterfactual sender address.
    ///  Calculate the sender contract address that will be generated by the initCode and salt in the UserOperation.
    function getSenderAddress(bytes memory initCode, uint _salt) public view returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(create2factory),
                _salt,
                keccak256(initCode)
            )
        );

        // NOTE: cast last 20 bytes of hash to address
        return address(uint160(uint256(hash)));
    }

    //call wallet.validateUserOp, and validate that it paid as needed.
    // return actual value sent from wallet to "this"
    function _validateWalletPrepayment(uint opIndex, UserOperation calldata op, bytes32 requestId, uint requiredPrefund, PaymentMode paymentMode) internal returns (uint gasUsedByValidateUserOp, uint prefund) {
    unchecked {
        uint preGas = gasleft();
        _createSenderIfNeeded(op);
        uint missingWalletFunds = 0;
        address sender = op.getSender();
        if (paymentMode != PaymentMode.paymasterStake) {
            uint bal = balanceOf(sender);
            missingWalletFunds = bal > requiredPrefund ? 0 : requiredPrefund - bal;
        }
        try IWallet(sender).validateUserOp{gas : op.verificationGas}(op, requestId, missingWalletFunds) {
        } catch Error(string memory revertReason) {
            revert FailedOp(opIndex, address(0), revertReason);
        } catch {
            revert FailedOp(opIndex, address(0), "");
        }
        if (paymentMode != PaymentMode.paymasterStake) {
            if (requiredPrefund > balanceOf(sender)) {
                revert FailedOp(opIndex, address(0), "wallet didn't pay prefund");
            }
            internalDecrementDeposit(sender, requiredPrefund);
            prefund = requiredPrefund;
        } else {
            prefund = 0;
        }
        gasUsedByValidateUserOp = preGas - gasleft();
    }
    }

    //validate paymaster.validatePaymasterUserOp
    function _validatePaymasterPrepayment(uint opIndex, UserOperation calldata op, bytes32 requestId, uint requiredPreFund, uint gasUsedByValidateUserOp) internal view returns (bytes memory context) {
    unchecked {
        //validate a paymaster has enough stake (including for payment for this TX)
        // NOTE: when submitting a batch, caller has to make sure a paymaster has enough stake to cover
        // all its transactions in the batch.
        if (!isPaymasterStaked(op.paymaster, paymasterStake + requiredPreFund)) {
            revert FailedOp(opIndex, op.paymaster, "not enough stake");
        }
        //no pre-pay from paymaster
        uint gas = op.verificationGas - gasUsedByValidateUserOp;
        try IPaymaster(op.paymaster).validatePaymasterUserOp{gas : gas}(op, requestId, requiredPreFund) returns (bytes memory _context){
            context = _context;
        } catch Error(string memory revertReason) {
            revert FailedOp(opIndex, op.paymaster, revertReason);
        } catch {
            revert FailedOp(opIndex, op.paymaster, "");
        }
    }
    }

    function _validatePrepayment(uint opIndex, UserOperation calldata userOp, bytes32 requestId) private returns (uint prefund, PaymentMode paymentMode, bytes memory context){

        uint preGas = gasleft();
        uint maxGasValues = userOp.preVerificationGas | userOp.verificationGas |
        userOp.callGas | userOp.maxFeePerGas | userOp.maxPriorityFeePerGas;
        require(maxGasValues < type(uint120).max, "gas values overflow");
        uint gasUsedByValidateUserOp;
        uint requiredPreFund;
        (requiredPreFund, paymentMode) = _getPaymentInfo(userOp);

        (gasUsedByValidateUserOp, prefund) = _validateWalletPrepayment(opIndex, userOp, requestId, requiredPreFund, paymentMode);

        //a "marker" where wallet opcode validation is done, by paymaster opcode validation is about to start
        // (used only by off-chain simulateValidation)
        uint marker = block.number;
        (marker);

        if (paymentMode == PaymentMode.paymasterStake) {
            (context) = _validatePaymasterPrepayment(opIndex, userOp, requestId, requiredPreFund, gasUsedByValidateUserOp);
        } else {
            context = "";
        }
    unchecked {
        uint gasUsed = preGas - gasleft();

        if (userOp.verificationGas < gasUsed) {
            revert FailedOp(opIndex, userOp.paymaster, "Used more than verificationGas");
        }
    }
    }

    function handlePostOp(uint opIndex, IPaymaster.PostOpMode mode, UserOperation calldata op, UserOpInfo memory opInfo, bytes memory context, uint actualGas) private returns (uint actualGasCost) {
        uint preGas = gasleft();
        uint gasPrice = UserOperationLib.gasPrice(op);
    unchecked {
        actualGasCost = actualGas * gasPrice;
        if (opInfo.paymentMode != PaymentMode.paymasterStake) {
            if (opInfo.prefund < actualGasCost) {
                revert ("wallet prefund below actualGasCost");
            }
            uint refund = opInfo.prefund - actualGasCost;
            internalIncrementDeposit(op.getSender(), refund);
        } else {
            if (context.length > 0) {
                if (mode != IPaymaster.PostOpMode.postOpReverted) {
                    IPaymaster(op.paymaster).postOp{gas : op.verificationGas}(mode, context, actualGasCost);
                } else {
                    try IPaymaster(op.paymaster).postOp{gas : op.verificationGas}(mode, context, actualGasCost) {}
                    catch Error(string memory reason) {
                        revert FailedOp(opIndex, op.paymaster, reason);
                    }
                    catch {
                        revert FailedOp(opIndex, op.paymaster, "postOp revert");
                    }
                }
            }
            //paymaster pays for full gas, including for postOp
            actualGas += preGas - gasleft();
            actualGasCost = actualGas * gasPrice;
            //paymaster balance known to be high enough, and to be locked for this block
            internalDecrementDeposit(op.paymaster, actualGasCost);
        }
        bool success = mode == IPaymaster.PostOpMode.opSucceeded;
        emit UserOperationEvent(opInfo.requestId, op.getSender(), op.paymaster, op.nonce, actualGasCost, gasPrice, success);
    } // unchecked
    }


    function isPaymasterStaked(address paymaster, uint stake) public view returns (bool) {
        return isStaked(paymaster, stake, unstakeDelaySec);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

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
    function validatePaymasterUserOp(UserOperation calldata userOp, bytes32 requestId, uint maxCost) external view returns (bytes memory context);

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
    function postOp(PostOpMode mode, bytes calldata context, uint actualGasCost) external;

    enum PostOpMode {
        opSucceeded, // user op succeeded
        opReverted, // user op reverted. still has to pay for gas.
        postOpReverted //user op succeeded, but caused postOp to revert. Now its a 2nd call, after user's op was deliberately reverted.
    }
}

// source: OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.4;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor(address owner_) {
        _transferOwnership(owner_);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

    struct UserOperation {

        address sender;
        uint256 nonce;
        bytes initCode;
        bytes callData;
        uint callGas;
        uint verificationGas;
        uint preVerificationGas;
        uint maxFeePerGas;
        uint maxPriorityFeePerGas;
        address paymaster;
        bytes paymasterData;
        bytes signature;
    }

library UserOperationLib {

    function getSender(UserOperation calldata userOp) internal pure returns (address ret) {
        assembly {ret := calldataload(userOp)}
    }

    //relayer/miner might submit the TX with higher priorityFee, but the user should not
    // pay above what he signed for.
    function gasPrice(UserOperation calldata userOp) internal view returns (uint) {
    unchecked {
        uint maxFeePerGas = userOp.maxFeePerGas;
        uint maxPriorityFeePerGas = userOp.maxPriorityFeePerGas;
        if (maxFeePerGas == maxPriorityFeePerGas) {
            //legacy mode (for networks that don't support basefee opcode)
            return min(tx.gasprice, maxFeePerGas);
        }
        return min(tx.gasprice, min(maxFeePerGas, maxPriorityFeePerGas + block.basefee));
    }
    }

    function requiredGas(UserOperation calldata userOp) internal pure returns (uint) {
    unchecked {
        //when using a Paymaster, the verificationGas is used also to cover the postOp call.
        // our security model might call postOp eventually twice
        uint mul = userOp.paymaster != address(0) ? 1 : 3;
        return userOp.callGas + userOp.verificationGas * mul + userOp.preVerificationGas;
    }
    }

    function requiredPreFund(UserOperation calldata userOp) internal view returns (uint prefund) {
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
        assembly {
            let ofs := userOp
            let len := sub(sub(sig.offset, ofs), 32)
            ret := mload(0x40)
            mstore(0x40, add(ret, add(len, 32)))
            mstore(ret, len)
            calldatacopy(add(ret, 32), ofs, len)
        }
        return ret;
    }

    function hash(UserOperation calldata userOp) internal pure returns (bytes32) {
        return keccak256(pack(userOp));
    }

    function min(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8;

/**
 * manage deposit of sender or paymaster, to pay for gas.
 * paymaster must stake some of the deposit.
 */
contract StakeManager {

    /// minimum number of blocks to after 'unlock' before amount can be withdrawn.
    uint32 immutable public unstakeDelaySec;

    constructor(uint32 _unstakeDelaySec) {
        unstakeDelaySec = _unstakeDelaySec;
    }

    event Deposited(
        address indexed account,
        uint256 totalDeposit,
        uint256 unstakeDelaySec
    );


    /// Emitted once a stake is scheduled for withdrawal
    event DepositUnstaked(
        address indexed account,
        uint256 withdrawTime
    );

    event Withdrawn(
        address indexed account,
        address withdrawAddress,
        uint256 withdrawAmount
    );

    /// @param amount of ether deposited for this account
    /// @param unstakeDelaySec - time the deposit is locked, after calling unlock (or zero if deposit is not locked)
    /// @param withdrawTime - first block timestamp where 'withdrawTo' will be callable, or zero if not locked
    struct DepositInfo {
        uint112 amount;
        uint32 unstakeDelaySec;
        uint64 withdrawTime;
    }

    /// maps accounts to their deposits
    mapping(address => DepositInfo) public deposits;

    function getDepositInfo(address account) external view returns (DepositInfo memory info) {
        return deposits[account];
    }

    function balanceOf(address account) public view returns (uint) {
        return deposits[account].amount;
    }

    receive() external payable {
        depositTo(msg.sender);
    }

    function internalIncrementDeposit(address account, uint amount) internal {
        deposits[account].amount += uint112(amount);
    }

    function internalDecrementDeposit(address account, uint amount) internal {
        deposits[account].amount -= uint112(amount);
    }

    /**
     * add to the deposit of the given account
     */
    function depositTo(address account) public payable {
        internalIncrementDeposit(account, msg.value);
        DepositInfo storage info = deposits[account];
        emit Deposited(msg.sender, info.amount, info.unstakeDelaySec);
    }

    /**
     * stake the account's deposit.
     * any pending unstakeDeposit is first cancelled.
     * can also set (or increase) the deposit with call.
     * @param _unstakeDelaySec the new lock time before the deposit can be withdrawn.
     */
    function addStakeTo(address account, uint32 _unstakeDelaySec) public payable {
        DepositInfo storage info = deposits[account];
        require(_unstakeDelaySec >= info.unstakeDelaySec, "cannot decrease unstake time");
        uint112 amount = deposits[msg.sender].amount + uint112(msg.value);
        deposits[account] = DepositInfo(
            amount,
            _unstakeDelaySec,
            0);
        emit Deposited(account, amount, _unstakeDelaySec);
    }

    /**
     * attempt to unstake the deposit.
     * the value can be withdrawn (using withdrawTo) after the unstake delay.
     */
    function unstakeDeposit() external {
        DepositInfo storage info = deposits[msg.sender];
        require(info.withdrawTime == 0, "already unstaking");
        require(info.unstakeDelaySec != 0, "not staked");
        uint64 withdrawTime = uint64(block.timestamp) + info.unstakeDelaySec;
        info.withdrawTime = withdrawTime;
        emit DepositUnstaked(msg.sender, withdrawTime);
    }

    /**
     * withdraw from the deposit.
     * will fail if the deposit is already staked or too low.
     * after a paymaster unlocks and withdraws some of the value, it must call addStake() to stake the value again.
     * @param withdrawAddress the address to send withdrawn value.
     * @param withdrawAmount the amount to withdraw.
     */
    function withdrawTo(address payable withdrawAddress, uint withdrawAmount) external {
        DepositInfo memory info = deposits[msg.sender];
        if (info.unstakeDelaySec != 0) {
            require(info.withdrawTime > 0, "must call unstakeDeposit() first");
            require(info.withdrawTime <= block.timestamp, "Withdrawal is not due");
        }
        require(withdrawAmount <= info.amount, "Withdraw amount too large");

        // store the remaining value, with stake info cleared.
        deposits[msg.sender] = DepositInfo(
            info.amount - uint112(withdrawAmount),
            0,
            0);
        withdrawAddress.transfer(withdrawAmount);
        emit Withdrawn(msg.sender, withdrawAddress, withdrawAmount);
    }

    /**
     * check if the given account is staked and didn't unlock it yet.
     * @param account the account (paymaster) to check
     * @param requiredStake the minimum deposit
     * @param requiredDelaySec the minimum required stake time.
     */
    function isStaked(address account, uint requiredStake, uint requiredDelaySec) public view returns (bool) {
        DepositInfo memory info = deposits[account];
        return info.amount >= requiredStake &&
        info.unstakeDelaySec >= requiredDelaySec &&
        info.withdrawTime == 0;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "./UserOperation.sol";

interface IWallet {

    /**
     * Validate user's signature and nonce
     * the entryPoint will make the call to the recipient only if this validation call returns successfuly.
     *
     * @dev Must validate caller is the entryPoint.
     *      Must validate the signature and nonce
     * @param userOp the operation that is about to be executed.
     * @param requestId hash of the user's request data. can be used as the basis for signature.
     * @param requiredPrefund the minimum amount to transfer to the sender(entryPoint) to be able to make the call.
     *      The excess is left as a deposit in the entrypoint, for future calls.
     *      can be withdrawn anytime using "entryPoint.withdrawTo()"
     *      In case there is a paymaster in the request (or the current deposit is high enough), this value will be zero.
     */
    function validateUserOp(UserOperation calldata userOp, bytes32 requestId, uint requiredPrefund) external;
}