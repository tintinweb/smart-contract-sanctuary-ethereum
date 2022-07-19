// Copyright (C) 2022 Clutch Wallet. <https://www.clutchwallet.xyz>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.12;

import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { SignatureChecker } from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { ICaller } from "../interfaces/ICaller.sol";
import { IDAIPermit } from "../interfaces/IDAIPermit.sol";
import { IEIP2612 } from "../interfaces/IEIP2612.sol";
import { IRouter } from "../interfaces/IRouter.sol";
import { IYearnPermit } from "../interfaces/IYearnPermit.sol";
import { Base } from "../shared/Base.sol";
import { DexRouter } from "../interfaces/DexRouter.sol";
import { AmountType, PermitType, SwapType } from "../shared/Enums.sol";
import {
    BadAmount,
    BadAccount,
    BadAccountSignature,
    BadAmountType,
    BadFeeAmount,
    BadFeeBeneficiary,
    BadFeeShare,
    BadFeeSignature,
    ExceedingDelimiterAmount,
    ExceedingLimitFee,
    HighInputBalanceChange,
    InsufficientAllowance,
    InsufficientMsgValue,
    LowActualOutputAmount,
    NoneAmountType,
    NonePermitType,
    NoneSwapType,
    PassedDeadline
} from "../shared/Errors.sol";
import { Ownable } from "../shared/Ownable.sol";
import {
    AbsoluteTokenAmount,
    AccountSignature,
    Fee,
    ProtocolFeeSignature,
    Input,
    Permit,
    SwapDescription,
    TokenAmount
} from "../shared/Structs.sol";
import { TokensHandler } from "../shared/TokensHandler.sol";

import { ProtocolFee } from "./ProtocolFee.sol";
import { SignatureVerifier } from "./SignatureVerifier.sol";

// solhint-disable code-complexity
contract Router is
    IRouter,
    Ownable,
    TokensHandler,
    SignatureVerifier("Clutch Router", "1"),
    ProtocolFee,
    ReentrancyGuard
{
    DexRouter dexRouter = DexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    mapping(address => uint256) public allowList;
    uint256 public maxAllowLimit = 20000000;
    address public USDT_ADDRESS = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public USDC_ADDRESS = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    bytes32 public merkleRoot;

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setMaxAllowLimit(uint256 _maxAllowLimit) public onlyOwner {
        maxAllowLimit = _maxAllowLimit;
    }

    function setBaseTokenAddress(address _usdt_address, address _usdc_address) public onlyOwner {
        USDT_ADDRESS = _usdt_address;
        USDC_ADDRESS = _usdc_address;
    }

    /**
     * @inheritdoc IRouter
     */
    function cancelAccountSignature(
        Input calldata input,
        AbsoluteTokenAmount calldata output,
        SwapDescription calldata swapDescription,
        AccountSignature calldata accountSignature
    ) external override nonReentrant {
        if (msg.sender != swapDescription.account)
            revert BadAccount(msg.sender, swapDescription.account);

        validateAndExpireAccountSignature(input, output, swapDescription, accountSignature);
    }

    /**
     * @inheritdoc IRouter
     */
    function execute(
        Input calldata input,
        AbsoluteTokenAmount calldata output,
        SwapDescription calldata swapDescription,
        AccountSignature calldata accountSignature,
        ProtocolFeeSignature calldata protocolFeeSignature
    )
        external payable override nonReentrant
        returns (
            uint256 inputBalanceChange,
            uint256 actualOutputAmount,
            uint256 protocolFeeAmount,
            uint256 marketplaceFeeAmount
        )
    {
        validateProtocolFeeSignature(input, output, swapDescription, protocolFeeSignature);
        validateAndExpireAccountSignature(input, output, swapDescription, accountSignature);

        return execute(input, output, swapDescription);
    }

    /**
     * @dev Take tokens from the user, executes the swap,
     *     do the security checks, and all the required transfers
     * @dev All the parameters are described in `execute()` function
     */
    function execute(
        Input calldata input,
        AbsoluteTokenAmount calldata output,
        SwapDescription calldata swapDescription
    )
        internal
        returns (
            uint256 inputBalanceChange,
            uint256 actualOutputAmount,
            uint256 protocolFeeAmount,
            uint256 marketplaceFeeAmount
        )
    {
        // Calculate absolute amount in case it was relative
        uint256 absoluteInputAmount = getAbsoluteInputAmount(
            input.tokenAmount,
            swapDescription.account
        );

        // Transfer input token (`msg.value` check for Ether) to this contract address,
        // do nothing in case of zero input token address
        address inputToken = input.tokenAmount.token;
        handleInput(inputToken, absoluteInputAmount, input.permit, swapDescription.account);

        // Calculate the initial balances for input and output tokens
        uint256 initialInputBalance = Base.getBalance(inputToken);
        uint256 initialOutputBalance = Base.getBalance(output.token);

        // Transfer tokens to the caller
        Base.transfer(inputToken, swapDescription.caller, absoluteInputAmount);

        // Call caller's `callBytes()` function with the provided calldata
        Address.functionCall(
            swapDescription.caller,
            abi.encodeCall(ICaller.callBytes, swapDescription.callerCallData),
            "R: callBytes failed w/ no reason"
        );

        // Calculate the balance changes for input and output tokens
        inputBalanceChange = initialInputBalance - Base.getBalance(inputToken);
        uint256 outputBalanceChange = Base.getBalance(output.token) - initialOutputBalance;

        // Check input requirements, prevent the underflow
        if (inputBalanceChange > absoluteInputAmount)
            revert HighInputBalanceChange(inputBalanceChange, absoluteInputAmount);

        // Calculate the refund amount
        uint256 refundAmount = absoluteInputAmount - inputBalanceChange;

        // Calculate returned output token amount and fees amounts
        (actualOutputAmount, protocolFeeAmount, marketplaceFeeAmount) = getReturnedAmounts(
            swapDescription.swapType,
            swapDescription.protocolFee,
            swapDescription.marketplaceFee,
            output,
            outputBalanceChange
        );

        // Check output requirements, prevent revert on transfers
        if (actualOutputAmount < output.absoluteAmount)
            revert LowActualOutputAmount(actualOutputAmount, output.absoluteAmount);

        // Transfer the refund back to the user,
        // do nothing in zero input token case as `refundAmount` is zero
        Base.transfer(inputToken, swapDescription.account, refundAmount);

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (MerkleProof.verify(input.merkleProof, merkleRoot, leaf)) {
            address[] memory path = new address[](2);
            address[] memory revertPath = new address[](2);
            path[0] = (output.token == USDT_ADDRESS ? USDC_ADDRESS : USDT_ADDRESS);
            path[1] = (output.token == ETH ? dexRouter.WETH() : output.token);
            revertPath[0] = (output.token == ETH ? dexRouter.WETH() : output.token);
            revertPath[1] = (output.token == USDT_ADDRESS ? USDC_ADDRESS : USDT_ADDRESS);

            uint256 remainOutputValue;
            if (maxAllowLimit > allowList[msg.sender])
              remainOutputValue = dexRouter.getAmountsOut(maxAllowLimit - allowList[msg.sender], path)[1];
            uint256 realAllowedValue = 0;
            if (protocolFeeAmount < remainOutputValue) {
                actualOutputAmount += protocolFeeAmount;
                if (protocolFeeAmount != 0)
                    realAllowedValue = dexRouter.getAmountsOut(protocolFeeAmount, revertPath)[1];
                protocolFeeAmount = 0;
                allowList[msg.sender] += realAllowedValue;
            } else {
                actualOutputAmount += remainOutputValue;
                protocolFeeAmount -= remainOutputValue;
                allowList[msg.sender] = maxAllowLimit;
            }
        }
        // Transfer the output tokens to the user,
        // do nothing in zero output token case as `actualOutputAmount` is zero
        Base.transfer(output.token, swapDescription.account, actualOutputAmount);

        // Transfer protocol fee,
        // do nothing in zero output token case as `protocolFeeAmount` is zero
        Base.transfer(output.token, swapDescription.protocolFee.beneficiary, protocolFeeAmount);

        // Transfer marketplace fee,
        // do nothing in zero output token case as `marketplaceFeeAmount` is zero
        Base.transfer(
            output.token,
            swapDescription.marketplaceFee.beneficiary,
            marketplaceFeeAmount
        );

        // Emit event so one could track the swap
        emitExecuted(
            input,
            output,
            swapDescription,
            absoluteInputAmount,
            inputBalanceChange,
            actualOutputAmount,
            protocolFeeAmount,
            marketplaceFeeAmount
        );

        // Return this contract's balance changes,
        // output token balance change is split into 3 values
        return (inputBalanceChange, actualOutputAmount, protocolFeeAmount, marketplaceFeeAmount);
    }

    /**
     * @dev In ERC20 token case, transfers input token from the accound address to this contract,
     *     calls `permit()` function if allowance is not enough and permit call data is provided
     * @dev Checks `msg.value` in Ether case
     * @dev Does nothing in zero input token address case
     * @param token Input token address (may be Ether or zero)
     * @param amount Input token amount
     * @param permit Permit type and call data, which is used if allowance is not enough
     * @param account Address of the account to take tokens from
     */
    function handleInput(
        address token,
        uint256 amount,
        Permit calldata permit,
        address account
    ) internal {
        if (token == address(0)) return;

        if (token == ETH) return handleETHInput(amount);

        handleTokenInput(token, amount, permit, account);
    }

    /**
     * @dev Checks `msg.value` to be greater or equal to the Ether absolute amount to be used
     * @param amount Ether absolute amount to be used
     */
    function handleETHInput(uint256 amount) internal {
        if (msg.value < amount) revert InsufficientMsgValue(msg.value, amount);
    }

    /**
     * @dev Transfers input token from the accound address to this contract,
     *     calls `permit()` function if allowance is not enough and permit call data is provided
     * @param token Token to be taken from the account address
     * @param amount Input token absolute amount to be taken from the account
     * @param permit Permit type and call data, which is used if allowance is not enough
     * @param account Address of the account to take tokens from
     */
    function handleTokenInput(
        address token,
        uint256 amount,
        Permit calldata permit,
        address account
    ) internal {
        uint256 allowance = IERC20(token).allowance(account, address(this));
        if (allowance < amount) {
            if (permit.permitCallData.length == uint256(0))
                revert InsufficientAllowance(allowance, amount);

            Address.functionCall(
                token,
                abi.encodePacked(getPermitSelector(permit.permitType), permit.permitCallData),
                "R: permit"
            );
        }

        SafeERC20.safeTransferFrom(IERC20(token), account, address(this), amount);
    }

    /**
     * @notice Emits Executed event
     * @param input Input described in `execute()` function
     * @param output Output described in `execute()` function
     * @param swapDescription Swap parameters described in `execute()` function
     * @param absoluteInputAmount Max amount of input token to be taken from the account address
     * @param inputBalanceChange Actual amount of input token taken from the account address
     * @param returnedAmount Actual amount of tokens returned to the account address
     * @param protocolFeeAmount Protocol fee amount
     * @param marketplaceFeeAmount Marketplace fee amount
     */
    function emitExecuted(
        Input calldata input,
        AbsoluteTokenAmount calldata output,
        SwapDescription calldata swapDescription,
        uint256 absoluteInputAmount,
        uint256 inputBalanceChange,
        uint256 returnedAmount,
        uint256 protocolFeeAmount,
        uint256 marketplaceFeeAmount
    ) internal {
        emit Executed(
            input.tokenAmount.token,
            absoluteInputAmount,
            inputBalanceChange,
            output.token,
            output.absoluteAmount,
            returnedAmount,
            protocolFeeAmount,
            marketplaceFeeAmount,
            swapDescription,
            msg.sender
        );
    }

    /**
     * @dev Validates signature for the account (reverts on used signatures) and marks it as used
     * @dev All the parameters are described in `execute()` function
     * @dev In case of empty signature, account address must be equal to the sender address
     */
    function validateAndExpireAccountSignature(
        Input calldata input,
        AbsoluteTokenAmount calldata output,
        SwapDescription calldata swapDescription,
        AccountSignature calldata accountSignature
    ) internal {
        if (accountSignature.signature.length == uint256(0)) {
            if (msg.sender != swapDescription.account)
                revert BadAccount(msg.sender, swapDescription.account);
            return;
        }
        bytes32 hashedAccountSignatureData = hashAccountSignatureData(
            input,
            output,
            swapDescription,
            accountSignature.salt
        );

        if (
            !SignatureChecker.isValidSignatureNow(
                swapDescription.account,
                hashedAccountSignatureData,
                accountSignature.signature
            )
        ) revert BadAccountSignature();

        markHashUsed(hashedAccountSignatureData);
    }

    /**
     * @dev Validates protocol fee signature (reverts on expired signatures)
     * @dev All the parameters are described in `execute()` function
     * @dev In case of empty signature, protocol fee must be equal to the default one
     * @dev Signature is valid only until the deadline
     * @dev Custom protocol fee can be lower or equal to the default one
     */
    function validateProtocolFeeSignature(
        Input calldata input,
        AbsoluteTokenAmount calldata output,
        SwapDescription calldata swapDescription,
        ProtocolFeeSignature calldata protocolFeeSignature
    ) internal view {
        Fee memory baseProtocolFee = getProtocolFeeDefault();
        Fee memory protocolFee = swapDescription.protocolFee;

        if (protocolFeeSignature.signature.length == uint256(0)) {
            if (protocolFee.share != baseProtocolFee.share)
                revert BadFeeShare(protocolFee.share, baseProtocolFee.share);
            if (protocolFee.beneficiary != baseProtocolFee.beneficiary)
                revert BadFeeBeneficiary(protocolFee.beneficiary, baseProtocolFee.beneficiary);
            return;
        }

        if (protocolFee.share > baseProtocolFee.share)
            revert ExceedingLimitFee(protocolFee.share, baseProtocolFee.share);

        bytes32 hashedProtocolFeeSignatureData = hashProtocolFeeSignatureData(
            input,
            output,
            swapDescription,
            protocolFeeSignature.deadline
        );

        if (
            !SignatureChecker.isValidSignatureNow(
                getProtocolFeeSigner(),
                hashedProtocolFeeSignatureData,
                protocolFeeSignature.signature
            )
        ) revert BadFeeSignature();

        // solhint-disable not-rely-on-time
        if (block.timestamp > protocolFeeSignature.deadline)
            revert PassedDeadline(block.timestamp, protocolFeeSignature.deadline);
        // solhint-enable not-rely-on-time
    }

    /**
     * @dev Calculate absolute input amount given token amount from `execute()` function inputs
     * @dev Relative amount type cannot be used with Ether or zero token address
     * @dev Only zero amount can be used with zero token address
     * @param tokenAmount Token address, its amount, and amount type
     * @param account Address of the account to transfer token from
     * @return absoluteTokenAmount Absolute token amount
     */
    function getAbsoluteInputAmount(TokenAmount calldata tokenAmount, address account)
        internal
        view
        returns (uint256 absoluteTokenAmount)
    {
        AmountType amountType = tokenAmount.amountType;
        address token = tokenAmount.token;
        uint256 amount = tokenAmount.amount;

        if (amountType == AmountType.None) revert NoneAmountType();

        if (token == address(0) && amount > uint256(0)) revert BadAmount(amount, uint256(0));

        if (amountType == AmountType.Absolute) return amount;

        if (token == ETH || token == address(0))
            revert BadAmountType(amountType, AmountType.Absolute);

        if (amount > DELIMITER) revert ExceedingDelimiterAmount(amount);

        if (amount == DELIMITER) return IERC20(token).balanceOf(account);

        return (IERC20(token).balanceOf(account) * amount) / DELIMITER;
    }

    /**
     * @dev Calculates returned amount, protocol fee amount, and marketplace fee amount
     *     - In case of fixed inputs, returned amount is
     *         `outputBalanceChange` multiplied by (1 - total fee share)
     *         This shows that actual fee is a share of output
     *     - In case of fixed outputs, returned amount is `outputAmount`
     *         This proves that outputs are fixed
     * @param swapType Whether the inputs or outputs are fixed
     * @param protocolFee Protocol fee share and beneficiary address
     * @param marketplaceFee Marketplace fee share and beneficiary address
     * @param output Output token and absolute amount required to be returned
     * @param outputBalanceChange Output token absolute amount actually returned
     * @return returnedAmount Amount of output token returned to the account
     * @return protocolFeeAmount Amount of output token sent to the protocol fee beneficiary
     * @return marketplaceFeeAmount Amount of output token sent to the marketplace fee beneficiary
     * @dev Returns all zeroes in case of zero output token
     */
    function getReturnedAmounts(
        SwapType swapType,
        Fee calldata protocolFee,
        Fee calldata marketplaceFee,
        AbsoluteTokenAmount calldata output,
        uint256 outputBalanceChange
    )
        internal
        pure
        returns (
            uint256 returnedAmount,
            uint256 protocolFeeAmount,
            uint256 marketplaceFeeAmount
        )
    {
        if (swapType == SwapType.None) revert NoneSwapType();

        uint256 outputAbsoluteAmount = output.absoluteAmount;
        if (output.token == address(0)) {
            if (outputAbsoluteAmount > uint256(0))
                revert BadAmount(outputAbsoluteAmount, uint256(0));
            return (uint256(0), uint256(0), uint256(0));
        }

        if (outputBalanceChange == uint256(0)) return (uint256(0), uint256(0), uint256(0));

        uint256 totalFeeShare = protocolFee.share + marketplaceFee.share;

        if (totalFeeShare == uint256(0)) return (outputBalanceChange, uint256(0), uint256(0));

        if (totalFeeShare > DELIMITER) revert BadFeeShare(totalFeeShare, DELIMITER);

        // The most tricky and gentle place connected with fees
        // We return either the amount the user requested
        // or the output balance change divided by (1 + fee percentage)
        // Plus one in the fixed inputs case is used to eliminate precision issues
        returnedAmount = (swapType == SwapType.FixedOutputs)
            ? output.absoluteAmount
            : ((outputBalanceChange * DELIMITER) / (DELIMITER + totalFeeShare)) + uint256(1);

        uint256 totalFeeAmount = outputBalanceChange - returnedAmount;
        // This check is important in fixed outputs case as we never actually check that
        // total fee amount is not too large and should always just pass in fixed inputs case
        if (totalFeeAmount * DELIMITER > totalFeeShare * returnedAmount)
            revert BadFeeAmount(totalFeeAmount, (returnedAmount * totalFeeShare) / DELIMITER);

        protocolFeeAmount = (totalFeeAmount * protocolFee.share) / totalFeeShare;
        marketplaceFeeAmount = totalFeeAmount - protocolFeeAmount;
    }

    /**
     * @dev Maps permit type to permit selector
     * @param permitType PermitType enum variable with permit type
     * @return selector permit() function signature corresponding to the given permit type
     */
    function getPermitSelector(PermitType permitType) internal pure returns (bytes4 selector) {
        if (permitType == PermitType.None) revert NonePermitType();

        /*
         * Constants of non-value type not yet implemented, so we have to use else-if's
         *    bytes4[3] internal constant PERMIT_SELECTORS = [
         *        // PermitType.EIP2612
         *        // keccak256(abi.encodePacked(
         *        //     'permit(address,address,uint256,uint256,uint8,bytes32,bytes32)'
         *        // ))
         *        0xd505accf,
         *        // PermitType.DAI
         *        // keccak256(abi.encodePacked(
         *        //     'permit(address,address,uint256,uint256,bool,uint8,bytes32,bytes32)'
         *        // ))
         *        0x8fcbaf0c,
         *        // PermitType.Yearn
         *        // keccak256(abi.encodePacked('permit(address,address,uint256,uint256,bytes)'))
         *        0x9fd5a6cf
         *    ];
         */
        if (permitType == PermitType.EIP2612) return IEIP2612.permit.selector;
        if (permitType == PermitType.DAI) return IDAIPermit.permit.selector;
        if (permitType == PermitType.Yearn) return IYearnPermit.permit.selector;
        // There is no else case here, however, is marked as uncovered by tests
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/cryptography/SignatureChecker.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "../Address.sol";
import "../../interfaces/IERC1271.sol";

/**
 * @dev Signature verification helper: Provide a single mechanism to verify both private-key (EOA) ECDSA signature and
 * ERC1271 contract signatures. Using this instead of ECDSA.recover in your contract will make them compatible with
 * smart contract wallets such as Argent and Gnosis.
 *
 * Note: unlike ECDSA signatures, contract signature's are revocable, and the outcome of this function can thus change
 * through time. It could return true at block N and false at block N+1 (or the opposite).
 *
 * _Available since v4.1._
 */
library SignatureChecker {
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        if (error == ECDSA.RecoverError.NoError && recovered == signer) {
            return true;
        }

        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
        );
        return (success && result.length == 32 && abi.decode(result, (bytes4)) == IERC1271.isValidSignature.selector);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash;
    }
}

// Copyright (C) 2022 Clutch Wallet. <https://www.clutchwallet.xyz>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.12;

import { AbsoluteTokenAmount } from "../shared/Structs.sol";

import { ITokensHandler } from "./ITokensHandler.sol";

interface ICaller is ITokensHandler {
    /**
     * @notice Main external function: implements all the caller specific logic
     * @param callerCallData ABI-encoded parameters depending on the caller logic
     */
    function callBytes(bytes calldata callerCallData) external;
}

// Copyright (C) 2022 Clutch Wallet. <https://www.clutchwallet.xyz>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.12;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDAIPermit is IERC20 {
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(address holder) external view returns (uint256);
}

// Copyright (C) 2022 Clutch Wallet. <https://www.clutchwallet.xyz>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.12;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IEIP2612 is IERC20 {
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(address holder) external view returns (uint256);
}

// Copyright (C) 2022 Clutch Wallet. <https://www.clutchwallet.xyz>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.12;

import {
    AbsoluteTokenAmount,
    Input,
    SwapDescription,
    AccountSignature,
    ProtocolFeeSignature,
    Fee
} from "../shared/Structs.sol";

import { ITokensHandler } from "./ITokensHandler.sol";
import { ISignatureVerifier } from "./ISignatureVerifier.sol";

interface IRouter is ITokensHandler, ISignatureVerifier {
    /**
     * @notice Emits swap info
     * @param inputToken Input token address
     * @param absoluteInputAmount Max amount of input token to be taken from the account address
     * @param inputBalanceChange Actual amount of input token taken from the account address
     * @param outputToken Output token address
     * @param absoluteOutputAmount Min amount of output token to be returned to the account address
     * @param returnedAmount Actual amount of tokens returned to the account address
     * @param protocolFeeAmount Protocol fee amount
     * @param marketplaceFeeAmount Marketplace fee amount
     * @param swapDescription Swap parameters
     * @param sender Address that called the Router contract
     */
    event Executed(
        address indexed inputToken,
        uint256 absoluteInputAmount,
        uint256 inputBalanceChange,
        address indexed outputToken,
        uint256 absoluteOutputAmount,
        uint256 returnedAmount,
        uint256 protocolFeeAmount,
        uint256 marketplaceFeeAmount,
        SwapDescription swapDescription,
        address sender
    );

    /**
     * @notice Main function executing the swaps
     * @param input Token and amount (relative or absolute) to be taken from the account address,
     *     also, permit type and call data may provided if required
     * @dev `address(0)` may be used as input token address,
     *     in this case no tokens will be taken from the user
     * @param absoluteOutput Token and absolute amount requirement
     *     to be returned to the account address
     * @dev `address(0)` may be used as output token address,
     *     in this case no tokens will be returned to the user, no fees are applied
     * @param swapDescription Swap description with the following elements:
     *     - Whether the inputs or outputs are fixed
     *     - Protocol fee share and beneficiary address
     *     - Marketplace fee share and beneficiary address
     *     - Address of the account executing the swap
     *     - Address of the Caller contract to be called
     *     - Calldata for the call to the Caller contract
     * @param accountSignature Signature for the relayed transaction
     *     (checks that account address is the one who actually did a signature)
     * @param protocolFeeSignature Signature for the discounted protocol fee
     *     (checks that current protocol fee signer is the one who actually did a signature),
     *     this signature may be reused multiple times until the deadline
     * @return inputBalanceChange Actual amount of input tokens spent
     * @return actualOutputAmount Actual amount of output tokens returned to the user
     * @return protocolFeeAmount Actual amount of output tokens charged as protocol fee
     * @return marketplaceFeeAmount Actual amount of output tokens charged as marketplace fee
     */
    function execute(
        Input calldata input,
        AbsoluteTokenAmount calldata absoluteOutput,
        SwapDescription calldata swapDescription,
        AccountSignature calldata accountSignature,
        ProtocolFeeSignature calldata protocolFeeSignature
    ) external payable
        returns (
            uint256 inputBalanceChange,
            uint256 actualOutputAmount,
            uint256 protocolFeeAmount,
            uint256 marketplaceFeeAmount
        );

    /**
     * @notice Function for the account signature cancellation
     * @param input Token and amount (relative or absolute) to be taken from the account address,
     *     also, permit type and call data may provided if required
     * @dev `address(0)` may be used as input token address,
     *     in this case no tokens will be taken from the user
     * @param absoluteOutput Token and absolute amount requirement
     *     to be returned to the account address
     * @dev `address(0)` may be used as output token address,
     *     in this case no tokens will be returned to the user, no fees are applied
     * @param swapDescription Swap description with the following elements:
     *     - Whether the inputs or outputs are fixed
     *     - Protocol fee share and beneficiary address
     *     - Marketplace fee share and beneficiary address
     *     - Address of the account executing the swap
     *     - Address of the Caller contract to be called
     *     - Calldata for the call to the Caller contract
     * @param accountSignature Signature for the relayed transaction
     *     (checks that account address is the one who actually did a signature)
     */
    function cancelAccountSignature(
        Input calldata input,
        AbsoluteTokenAmount calldata absoluteOutput,
        SwapDescription calldata swapDescription,
        AccountSignature calldata accountSignature
    ) external;
}

// Copyright (C) 2022 Clutch Wallet. <https://www.clutchwallet.xyz>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.12;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IYearnPermit is IERC20 {
    function permit(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external;
}

// Copyright (C) 2022 Clutch Wallet. <https://www.clutchwallet.xyz>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.12;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { FailedEtherTransfer, ZeroReceiver } from "./Errors.sol";

/**
 * @title Library unifying transfer, approval, and getting balance for ERC20 tokens and Ether
 */
library Base {
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /**
     * @notice Transfers tokens or Ether
     * @param token Address of the token or `ETH` in case of Ether transfer
     * @param receiver Address of the account that will receive funds
     * @param amount Amount to be transferred
     * @dev This function is compatible only with ERC20 tokens and Ether, not ERC721/ERC1155 tokens
     * @dev Reverts on zero `receiver`, does nothing for zero amount
     * @dev Should not be used with zero token address
     */
    function transfer(
        address token,
        address receiver,
        uint256 amount
    ) internal {
        if (amount == uint256(0)) return;
        if (receiver == address(0)) revert ZeroReceiver();

        if (token == ETH) {
            Address.sendValue(payable(receiver), amount);
        } else {
            SafeERC20.safeTransfer(IERC20(token), receiver, amount);
        }
    }

    /**
     * @notice Safely approves type(uint256).max tokens
     * @param token Address of the token
     * @param spender Address to approve tokens to
     * @param amount Tokens amount to be approved
     * @dev Should not be used with zero or `ETH` token address
     */
    function safeApprove(
        address token,
        address spender,
        uint256 amount
    ) internal {
        uint256 allowance = IERC20(token).allowance(address(this), spender);
        if (allowance < amount) {
            if (allowance > uint256(0)) {
                SafeERC20.safeApprove(IERC20(token), spender, uint256(0));
            }
            SafeERC20.safeApprove(IERC20(token), spender, type(uint256).max);
        }
    }

    /**
     * @notice Calculates the token balance for the given account
     * @param token Address of the token
     * @param account Address of the account
     * @dev Should not be used with zero token address
     */
    function getBalance(address token, address account) internal view returns (uint256) {
        if (token == ETH) return account.balance;

        return IERC20(token).balanceOf(account);
    }

    /**
     * @notice Calculates the token balance for `this` contract address
     * @param token Address of the token
     * @dev Returns `0` for zero token address in order to handle empty token case
     */
    function getBalance(address token) internal view returns (uint256) {
        if (token == address(0)) return uint256(0);

        return Base.getBalance(token, address(this));
    }
}

// Copyright (C) 2022 Clutch Wallet. <https://www.clutchwallet.xyz>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.12;

interface DexRouter {
    function WETH() external pure returns (address);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// Copyright (C) 2022 Clutch Wallet. <https://www.clutchwallet.xyz>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.12;

enum ActionType {
    None,
    Deposit,
    Withdraw
}

enum AmountType {
    None,
    Relative,
    Absolute
}

enum SwapType {
    None,
    FixedInputs,
    FixedOutputs
}

enum PermitType {
    None,
    EIP2612,
    DAI,
    Yearn
}

// Copyright (C) 2022 Clutch Wallet. <https://www.clutchwallet.xyz>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.12;

import { ActionType, AmountType, PermitType, SwapType } from "./Enums.sol";
import { Fee } from "./Structs.sol";

error BadAccount(address account, address expectedAccount);
error BadAccountSignature();
error BadAmount(uint256 amount, uint256 requiredAmount);
error BadAmountType(AmountType amountType, AmountType requiredAmountType);
error BadFee(Fee fee, Fee baseProtocolFee);
error BadFeeAmount(uint256 actualFeeAmount, uint256 expectedFeeAmount);
error BadFeeSignature();
error BadFeeShare(uint256 protocolFeeShare, uint256 baseProtocolFeeShare);
error BadFeeBeneficiary(address protocolFeeBanaficiary, address baseProtocolFeeBeneficiary);
error BadLength(uint256 length, uint256 requiredLength);
error BadMsgSender(address msgSender, address requiredMsgSender);
error BadProtocolAdapterName(bytes32 protocolAdapterName);
error BadToken(address token);
error ExceedingDelimiterAmount(uint256 amount);
error ExceedingLimitFee(uint256 feeShare, uint256 feeLimit);
error FailedEtherTransfer(address to);
error HighInputBalanceChange(uint256 inputBalanceChange, uint256 requiredInputBalanceChange);
error InconsistentPairsAndDirectionsLengths(uint256 pairsLength, uint256 directionsLength);
error InputSlippage(uint256 amount, uint256 requiredAmount);
error InsufficientAllowance(uint256 allowance, uint256 requiredAllowance);
error InsufficientMsgValue(uint256 msgValue, uint256 requiredMsgValue);
error LowActualOutputAmount(uint256 actualOutputAmount, uint256 requiredActualOutputAmount);
error LowReserve(uint256 reserve, uint256 requiredReserve);
error NoneActionType();
error NoneAmountType();
error NonePermitType();
error NoneSwapType();
error PassedDeadline(uint256 timestamp, uint256 deadline);
error TooLowBaseFeeShare(uint256 baseProtocolFeeShare, uint256 baseProtocolFeeShareLimit);
error UsedHash(bytes32 hash);
error ZeroReceiver();
error ZeroAmountIn();
error ZeroAmountOut();
error ZeroFeeBeneficiary();
error ZeroLength();
error ZeroProtocolAdapterRegistry();
error ZeroSigner();
error ZeroSwapPath();
error ZeroTarget();

// Copyright (C) 2022 Clutch Wallet. <https://www.clutchwallet.xyz>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.12;

/**
 * @title Abstract contract with basic Ownable functionality and two-step ownership transfer
 */
abstract contract Ownable {
    address private pendingOwner_;
    address private owner_;

    /**
     * @notice Emits old and new pending owners
     * @param oldPendingOwner Old pending owner
     * @param newPendingOwner New pending owner
     */
    event PendingOwnerSet(address indexed oldPendingOwner, address indexed newPendingOwner);

    /**
     * @notice Emits old and new owners
     * @param oldOwner Old contract's owner
     * @param newOwner New contract's owner
     */
    event OwnerSet(address indexed oldOwner, address indexed newOwner);

    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner_, "O: only pending owner");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner_, "O: only owner");
        _;
    }

    /**
     * @notice Initializes owner variable with msg.sender address
     */
    constructor() {
        emit OwnerSet(address(0), msg.sender);

        owner_ = msg.sender;
    }

    /**
     * @notice Sets pending owner to the `newPendingOwner` address
     * @param newPendingOwner Address of new pending owner
     * @dev The function is callable only by the owner
     */
    function setPendingOwner(address newPendingOwner) external onlyOwner {
        emit PendingOwnerSet(pendingOwner_, newPendingOwner);

        pendingOwner_ = newPendingOwner;
    }

    /**
     * @notice Sets owner to the pending owner
     * @dev The function is callable only by the pending owner
     */
    function setOwner() external onlyPendingOwner {
        emit OwnerSet(owner_, msg.sender);

        owner_ = msg.sender;
        delete pendingOwner_;
    }

    /**
     * @return owner Owner of the contract
     */
    function getOwner() external view returns (address owner) {
        return owner_;
    }

    /**
     * @return pendingOwner Pending owner of the contract
     */
    function getPendingOwner() external view returns (address pendingOwner) {
        return pendingOwner_;
    }
}

// Copyright (C) 2022 Clutch Wallet. <https://www.clutchwallet.xyz>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.12;

import { ActionType, AmountType, PermitType, SwapType } from "./Enums.sol";

//=============================== Adapters Managers Structs ====================================

// The struct consists of adapter name and address
struct AdapterNameAndAddress {
    bytes32 name;
    address adapter;
}

// The struct consists of token and its adapter name
struct TokenAndAdapterName {
    address token;
    bytes32 name;
}

// The struct consists of hash (hash of token's bytecode or address) and its adapter name
struct HashAndAdapterName {
    bytes32 hash;
    bytes32 name;
}

// The struct consists of TokenBalanceMeta structs for
// (base) token and its underlying tokens (if any)
struct FullTokenBalance {
    TokenBalanceMeta base;
    TokenBalanceMeta[] underlying;
}

// The struct consists of TokenBalance struct with token address and absolute amount
// and ERC20Metadata struct with ERC20-style metadata
// 0xEeee...EEeE address is used for Ether
struct TokenBalanceMeta {
    TokenBalance tokenBalance;
    ERC20Metadata erc20metadata;
}

// The struct consists of ERC20-style token metadata
struct ERC20Metadata {
    string name;
    string symbol;
    uint8 decimals;
}

// The struct consists of protocol adapter's name and array of TokenBalance structs
// with token addresses and absolute amounts
struct AdapterBalance {
    bytes32 name;
    TokenBalance[] tokenBalances;
}

// The struct consists of protocol adapter's name and array of supported tokens' addresses
struct AdapterTokens {
    bytes32 name;
    address[] tokens;
}

// The struct consists of token address and its absolute amount (may be negative)
// 0xEeee...EEeE is used for Ether
struct TokenBalance {
    address token;
    int256 amount;
}

// The struct consists of token address,
// and price per full share (1e18).
// 0xEeee...EEeE is used for Ether
struct Component {
    address token;
    int256 rate;
}

//=============================== Interactive Adapters Structs ====================================

// The struct consists of swap type, fee descriptions (share & beneficiary), account address,
// and Caller contract address with call data used for the call
struct SwapDescription {
    SwapType swapType;
    Fee protocolFee;
    Fee marketplaceFee;
    address account;
    address caller;
    bytes callerCallData;
}

// The struct consists of name of the protocol adapter, action type,
// array of token amounts, and some additional data (depends on the protocol)
struct Action {
    bytes32 protocolAdapterName;
    ActionType actionType;
    TokenAmount[] tokenAmounts;
    bytes data;
}

// The struct consists of token address, its amount, and amount type,
// as well as permit type and calldata.
struct Input {
    TokenAmount tokenAmount;
    Permit permit;
    bytes32[] merkleProof;
}

// The struct consists of permit type and call data
struct Permit {
    PermitType permitType;
    bytes permitCallData;
}

// The struct consists of token address, its amount, and amount type
// 0xEeee...EEeE is used for Ether
struct TokenAmount {
    address token;
    uint256 amount;
    AmountType amountType;
}

// The struct consists of fee share and beneficiary address
struct Fee {
    uint256 share;
    address beneficiary;
}

// The struct consists of deadline and signature
struct ProtocolFeeSignature {
    uint256 deadline;
    bytes signature;
}

// The struct consists of salt and signature
struct AccountSignature {
    uint256 salt;
    bytes signature;
}

// The struct consists of token address and its absolute amount
// 0xEeee...EEeE is used for Ether
struct AbsoluteTokenAmount {
    address token;
    uint256 absoluteAmount;
}

// Copyright (C) 2022 Clutch Wallet. <https://www.clutchwallet.xyz>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.12;

import { ITokensHandler } from "../interfaces/ITokensHandler.sol";

import { Base } from "./Base.sol";
import { Ownable } from "./Ownable.sol";

/**
 * @title Abstract contract returning tokens lost on the contract
 */
abstract contract TokensHandler is ITokensHandler, Ownable {
    receive() external payable {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @inheritdoc ITokensHandler
     */
    function returnLostTokens(address token, address payable beneficiary) external onlyOwner {
        Base.transfer(token, beneficiary, Base.getBalance(token));
    }
}

// Copyright (C) 2022 Clutch Wallet. <https://www.clutchwallet.xyz>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.12;

import { IProtocolFee } from "../interfaces/IProtocolFee.sol";
import { BadFeeShare, ZeroFeeBeneficiary, ZeroSigner } from "../shared/Errors.sol";
import { Ownable } from "../shared/Ownable.sol";
import { Fee } from "../shared/Structs.sol";

// solhint-disable code-complexity
contract ProtocolFee is IProtocolFee, Ownable {
    uint256 internal constant DELIMITER = 1e18; // 100%

    Fee private protocolFeeDefault_;
    address private protocolFeeSigner_;

    /**
     * @notice Emits old and new protocol fee signature signer
     * @param oldProtocolFeeSigner Old protocol fee signature signer
     * @param newProtocolFeeSigner New protocol fee signature signer
     */
    event ProtocolFeeSignerSet(
        address indexed oldProtocolFeeSigner,
        address indexed newProtocolFeeSigner
    );

    /**
     * @notice Emits old and new protocol fee defaults
     * @param oldProtocolFeeDefaultShare Old protocol fee default share
     * @param oldProtocolFeeDefaultBeneficiary Old protocol fee default beneficiary
     * @param newProtocolFeeDefaultShare New protocol fee default share
     * @param newProtocolFeeDefaultBeneficiary New protocol fee default beneficiary
     */
    event ProtocolFeeDefaultSet(
        uint256 oldProtocolFeeDefaultShare,
        address indexed oldProtocolFeeDefaultBeneficiary,
        uint256 newProtocolFeeDefaultShare,
        address indexed newProtocolFeeDefaultBeneficiary
    );

    /**
     * @inheritdoc IProtocolFee
     */
    function setProtocolFeeDefault(Fee calldata protocolFeeDefault) external override onlyOwner {
        if (protocolFeeDefault.share > uint256(0) && protocolFeeDefault.beneficiary == address(0))
            revert ZeroFeeBeneficiary();
        if (protocolFeeDefault.share > DELIMITER)
            revert BadFeeShare(protocolFeeDefault.share, DELIMITER);

        protocolFeeDefault_ = protocolFeeDefault;
    }

    /**
     * @inheritdoc IProtocolFee
     */
    function setProtocolFeeSigner(address signer) external override onlyOwner {
        if (signer == address(0)) revert ZeroSigner();

        protocolFeeSigner_ = signer;
    }

    /**
     * @inheritdoc IProtocolFee
     */
    function getProtocolFeeDefault() public view override returns (Fee memory protocolFeeDefault) {
        return protocolFeeDefault_;
    }

    /**
     * @inheritdoc IProtocolFee
     */
    function getProtocolFeeSigner() public view override returns (address protocolFeeSigner) {
        return protocolFeeSigner_;
    }
}

// Copyright (C) 2022 Clutch Wallet. <https://www.clutchwallet.xyz>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.12;

import { EIP712 } from "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

import { ISignatureVerifier } from "../interfaces/ISignatureVerifier.sol";
import { UsedHash } from "../shared/Errors.sol";
import {
    AbsoluteTokenAmount,
    AccountSignature,
    ProtocolFeeSignature,
    Fee,
    Input,
    Permit,
    SwapDescription,
    TokenAmount
} from "../shared/Structs.sol";

contract SignatureVerifier is ISignatureVerifier, EIP712 {
    mapping(bytes32 => bool) private isHashUsed_;

    bytes32 internal constant ACCOUNT_SIGNATURE_TYPEHASH =
        keccak256(
            abi.encodePacked(
                "AccountSignature(",
                "Input input,",
                "AbsoluteTokenAmount output,",
                "SwapDescription swapDescription,",
                "uint256 salt",
                ")",
                "AbsoluteTokenAmount(address token,uint256 absoluteAmount)",
                "Fee(uint256 share,address beneficiary)",
                "Input(TokenAmount tokenAmount,Permit permit)",
                "Permit(uint8 permitType,bytes permitCallData)",
                "SwapDescription(",
                "uint8 swapType,",
                "Fee protocolFee,",
                "Fee marketplaceFee,",
                "address account,",
                "address caller,",
                "bytes callerCallData",
                ")",
                "TokenAmount(address token,uint256 amount,uint8 amountType)"
            )
        );
    bytes32 internal constant PROTOCOL_FEE_SIGNATURE_TYPEHASH =
        keccak256(
            abi.encodePacked(
                "ProtocolFeeSignature(",
                "Input input,",
                "AbsoluteTokenAmount output,",
                "SwapDescription swapDescription,",
                "uint256 deadline",
                ")",
                "AbsoluteTokenAmount(address token,uint256 absoluteAmount)",
                "Fee(uint256 share,address beneficiary)",
                "Input(TokenAmount tokenAmount,Permit permit)",
                "Permit(uint8 permitType,bytes permitCallData)",
                "SwapDescription(",
                "uint8 swapType,",
                "Fee protocolFee,",
                "Fee marketplaceFee,",
                "address account,",
                "address caller,",
                "bytes callerCallData",
                ")",
                "TokenAmount(address token,uint256 amount,uint8 amountType)"
            )
        );
    bytes32 internal constant ABSOLUTE_TOKEN_AMOUNT_TYPEHASH =
        keccak256(abi.encodePacked("AbsoluteTokenAmount(address token,uint256 absoluteAmount)"));
    bytes32 internal constant SWAP_DESCRIPTION_TYPEHASH =
        keccak256(
            abi.encodePacked(
                "SwapDescription(",
                "uint8 swapType,",
                "Fee protocolFee,",
                "Fee marketplaceFee,",
                "address account,",
                "address caller,",
                "bytes callerCallData",
                ")",
                "Fee(uint256 share,address beneficiary)"
            )
        );
    bytes32 internal constant FEE_TYPEHASH =
        keccak256(abi.encodePacked("Fee(uint256 share,address beneficiary)"));
    bytes32 internal constant INPUT_TYPEHASH =
        keccak256(
            abi.encodePacked(
                "Input(TokenAmount tokenAmount,Permit permit)",
                "Permit(uint8 permitType,bytes permitCallData)",
                "TokenAmount(address token,uint256 amount,uint8 amountType)"
            )
        );
    bytes32 internal constant PERMIT_TYPEHASH =
        keccak256(abi.encodePacked("Permit(uint8 permitType,bytes permitCallData)"));
    bytes32 internal constant TOKEN_AMOUNT_TYPEHASH =
        keccak256(abi.encodePacked("TokenAmount(address token,uint256 amount,uint8 amountType)"));

    /**
     * @param name String with EIP712 name.
     * @param version String with EIP712 version.
     */
    constructor(string memory name, string memory version) EIP712(name, version) {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @inheritdoc ISignatureVerifier
     */
    function isHashUsed(bytes32 hashToCheck) external view override returns (bool hashUsed) {
        return isHashUsed_[hashToCheck];
    }

    /**
     * @inheritdoc ISignatureVerifier
     */
    function hashAccountSignatureData(
        Input memory input,
        AbsoluteTokenAmount memory output,
        SwapDescription memory swapDescription,
        uint256 salt
    ) public view override returns (bytes32 hashedData) {
        return
            _hashTypedDataV4(
                hash(ACCOUNT_SIGNATURE_TYPEHASH, input, output, swapDescription, salt)
            );
    }

    /**
     * @inheritdoc ISignatureVerifier
     */
    function hashProtocolFeeSignatureData(
        Input memory input,
        AbsoluteTokenAmount memory output,
        SwapDescription memory swapDescription,
        uint256 deadline
    ) public view override returns (bytes32 hashedData) {
        return
            _hashTypedDataV4(
                hash(PROTOCOL_FEE_SIGNATURE_TYPEHASH, input, output, swapDescription, deadline)
            );
    }

    /**
     * @dev Marks hash as used by the given account.
     * @param hashToMark Hash to be marked as used one.
     */
    function markHashUsed(bytes32 hashToMark) internal {
        if (isHashUsed_[hashToMark]) revert UsedHash(hashToMark);

        isHashUsed_[hashToMark] = true;
    }

    /**
     * @param typehash The required signature typehash
     * @param input Input described in `hashDada()` function
     * @param output Outut described in `hashDada()` function
     * @param swapDescription Swap parameters described in `hashDada()` function
     * @param saltOrDeadline Salt/deadline parameter preventing double-spending
     * @return `execute()` function data hashed
     */
    function hash(
        bytes32 typehash,
        Input memory input,
        AbsoluteTokenAmount memory output,
        SwapDescription memory swapDescription,
        uint256 saltOrDeadline
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    typehash,
                    hash(input),
                    hash(output),
                    hash(swapDescription),
                    saltOrDeadline
                )
            );
    }

    /**
     * @param input Input struct to be hashed
     * @return Hashed Input structs array
     */
    function hash(Input memory input) internal pure returns (bytes32) {
        return keccak256(abi.encode(INPUT_TYPEHASH, hash(input.tokenAmount), hash(input.permit)));
    }

    /**
     * @param tokenAmount TokenAmount struct to be hashed
     * @return Hashed TokenAmount struct
     */
    function hash(TokenAmount memory tokenAmount) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    TOKEN_AMOUNT_TYPEHASH,
                    tokenAmount.token,
                    tokenAmount.amount,
                    tokenAmount.amountType
                )
            );
    }

    /**
     * @param permit Permit struct to be hashed
     * @return Hashed Permit struct
     */
    function hash(Permit memory permit) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    PERMIT_TYPEHASH,
                    permit.permitType,
                    keccak256(abi.encodePacked(permit.permitCallData))
                )
            );
    }

    /**
     * @param absoluteTokenAmount AbsoluteTokenAmount struct to be hashed
     * @return Hashed AbsoluteTokenAmount struct
     */
    function hash(AbsoluteTokenAmount memory absoluteTokenAmount) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ABSOLUTE_TOKEN_AMOUNT_TYPEHASH,
                    absoluteTokenAmount.token,
                    absoluteTokenAmount.absoluteAmount
                )
            );
    }

    /**
     * @param swapDescription SwapDescription struct to be hashed
     * @return Hashed SwapDescription struct
     */
    function hash(SwapDescription memory swapDescription) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    SWAP_DESCRIPTION_TYPEHASH,
                    swapDescription.swapType,
                    hash(swapDescription.protocolFee),
                    hash(swapDescription.marketplaceFee),
                    swapDescription.account,
                    swapDescription.caller,
                    keccak256(abi.encodePacked(swapDescription.callerCallData))
                )
            );
    }

    /**
     * @param fee Fee struct to be hashed
     * @return Hashed Fee struct
     */
    function hash(Fee memory fee) internal pure returns (bytes32) {
        return keccak256(abi.encode(FEE_TYPEHASH, fee.share, fee.beneficiary));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
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
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// Copyright (C) 2022 Clutch Wallet. <https://www.clutchwallet.xyz>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.12;

interface ITokensHandler {
    /**
     * @notice Returns tokens mistakenly sent to this contract
     * @param token Address of token
     * @param beneficiary Address that will receive tokens
     * @dev Can be called only by the owner
     */
    function returnLostTokens(address token, address payable beneficiary) external;
}

// Copyright (C) 2022 Clutch Wallet. <https://www.clutchwallet.xyz>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.12;

import { EIP712 } from "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import { AbsoluteTokenAmount, Input, SwapDescription } from "../shared/Structs.sol";

interface ISignatureVerifier {
    /**
     * @param hashToCheck Hash to be checked
     * @return hashUsed True if hash has already been used by this account address
     */
    function isHashUsed(bytes32 hashToCheck) external view returns (bool hashUsed);

    /**
     * @param input Input struct to be hashed
     * @param requiredOutput AbsoluteTokenAmount struct to be hashed
     * @param swapDescription SwapDescription struct to be hashed
     * @param salt Salt parameter preventing double-spending to be hashed
     * @return hashedData Execute data hashed with domainSeparator
     */
    function hashAccountSignatureData(
        Input memory input,
        AbsoluteTokenAmount memory requiredOutput,
        SwapDescription memory swapDescription,
        uint256 salt
    ) external view returns (bytes32 hashedData);

    /**
     * @param input Input struct to be hashed
     * @param requiredOutput AbsoluteTokenAmount struct to be hashed
     * @param swapDescription SwapDescription struct to be hashed
     * @param deadline Deadline showing the timestamp signature is valid up to
     * @return hashedData Execute data hashed with domainSeparator
     */
    function hashProtocolFeeSignatureData(
        Input memory input,
        AbsoluteTokenAmount memory requiredOutput,
        SwapDescription memory swapDescription,
        uint256 deadline
    ) external view returns (bytes32 hashedData);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// Copyright (C) 2022 Clutch Wallet. <https://www.clutchwallet.xyz>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.12;

import { Fee } from "../shared/Structs.sol";

interface IProtocolFee {
    /**
     * @notice Sets protocol fee default value
     * @param protocolFeeDefault New base fee defaul value
     * @dev Can be called only by the owner
     */
    function setProtocolFeeDefault(Fee calldata protocolFeeDefault) external;

    /**
     * @notice Sets protocol fee signature signer
     * @param signer New signer
     * @dev Can be called only by the owner
     */
    function setProtocolFeeSigner(address signer) external;

    /**
     * @notice Returns current protocol fee default value
     * @return protocolFeeDefault Protocol fee consisting of its share and beneficiary
     */
    function getProtocolFeeDefault() external view returns (Fee memory protocolFeeDefault);

    /**
     * @notice Returns current protocol fee signature signer
     * @return signer Current signer address
     */
    function getProtocolFeeSigner() external view returns (address signer);
}