// SPDX-License-Identifier: BUSL - 1.1
pragma solidity =0.8.12;

import { AddressUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import { ContextUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import { EIP712Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import {
    ReentrancyGuardUpgradeable
} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import { LibAccountMarket } from "../libs/LibAccountMarket.sol";
import { LibOrder } from "../libs/LibOrder.sol";
import { LibFill } from "../libs/LibFill.sol";
import { LibDeal } from "../libs/LibDeal.sol";
import { LibAsset } from "../libs/LibAsset.sol";
import { LibPerpMath } from "../libs/LibPerpMath.sol";
import { LibSafeCastInt } from "../libs/LibSafeCastInt.sol";
import { LibSafeCastUint } from "../libs/LibSafeCastUint.sol";
import { LibSignature } from "../libs/LibSignature.sol";
import { EncodeDecode } from "../libs/EncodeDecode.sol";

import { IAccountBalance } from "../interfaces/IAccountBalance.sol";
import { IERC1271 } from "../interfaces/IERC1271.sol";
import { IERC20Metadata } from "../interfaces/IERC20Metadata.sol";
import { IIndexPrice } from "../interfaces/IIndexPrice.sol";
import { IMatchingEngine } from "../interfaces/IMatchingEngine.sol";
import { IMarketRegistry } from "../interfaces/IMarketRegistry.sol";
import { IPositioning } from "../interfaces/IPositioning.sol";
import { IPositioningConfig } from "../interfaces/IPositioningConfig.sol";
import { IVirtualToken } from "../interfaces/IVirtualToken.sol";
import { IVaultController } from "../interfaces/IVaultController.sol";

import { BlockContext } from "../helpers/BlockContext.sol";
import { FundingRate } from "../funding-rate/FundingRate.sol";
import { OwnerPausable } from "../helpers/OwnerPausable.sol";
import { OrderValidator } from "./OrderValidator.sol";
import { PositioningStorageV1 } from "../storage/PositioningStorage.sol";
import { PositioningCallee } from "../helpers/PositioningCallee.sol";

// TODO : Create bulk match order for perp
// never inherit any new stateful contract. never change the orders of parent stateful contracts
contract Positioning is
    IPositioning,
    BlockContext,
    ReentrancyGuardUpgradeable,
    OwnerPausable,
    PositioningStorageV1,
    FundingRate,
    EIP712Upgradeable,
    OrderValidator
{
    using AddressUpgradeable for address;
    using LibSafeCastUint for uint256;
    using LibSafeCastInt for int256;
    using LibPerpMath for uint256;
    using LibPerpMath for int256;
    using LibSignature for bytes32;
    using EncodeDecode for bytes;

    /// @dev this function is public for testing
    // solhint-disable-next-line func-order
    function initialize(
        address PositioningConfigArg,
        address vaultControllerArg,
        address accountBalanceArg,
        address matchingEngineArg,
        address markPriceArg,
        address indexPriceArg,
        uint64 underlyingPriceIndex
    ) external initializer {
        // CH_VANC: Vault address is not contract
        require(vaultControllerArg.isContract(), "CH_VANC");
        // PositioningConfig address is not contract
        require(PositioningConfigArg.isContract(), "CH_PCNC");
        // AccountBalance is not contract
        require(accountBalanceArg.isContract(), "CH_ABNC");
        // CH_MENC: Matching Engine is not contract
        require(matchingEngineArg.isContract(), "CH_MENC");

        __ReentrancyGuard_init();
        __OwnerPausable_init();
        __FundingRate_init(markPriceArg, indexPriceArg);
        __OrderValidator_init_unchained();

        _positioningConfig = PositioningConfigArg;
        _vaultController = vaultControllerArg;
        _accountBalance = accountBalanceArg;
        _matchingEngine = matchingEngineArg;
        _underlyingPriceIndex = underlyingPriceIndex;
        // TODO: Set settlement token
        // _settlementTokenDecimals = 0;
        setPositioning(address(this));
        _grantRole(POSITIONING_ADMIN, _msgSender());
    }

    function setMarketRegistry(address marketRegistryArg) external {
        _requirePositioningAdmin();
        // V_VPMM: Positioning is not contract
        require(marketRegistryArg.isContract(), "V_VPMM");
        _marketRegistry = marketRegistryArg;
    }

    /// @inheritdoc IPositioning
    function settleAllFunding(address trader) external virtual override {
        address[] memory baseTokens = IAccountBalance(_accountBalance).getBaseTokens(trader);
        uint256 baseTokenLength = baseTokens.length;
        for (uint256 i = 0; i < baseTokenLength; i++) {
            _settleFunding(trader, baseTokens[i]);
        }
    }

    /// @inheritdoc IPositioning
    function setDefaultFeeReceiver(address _newDefaultFeeReceiver) external onlyOwner {
        // Default Fee Receiver is zero
        require(_newDefaultFeeReceiver != address(0), "PC_DFRZ");
        defaultFeeReceiver = _newDefaultFeeReceiver;
        emit DefaultFeeReceiverChanged(defaultFeeReceiver);
    }

    /// @inheritdoc IPositioning
    function openPosition(
        LibOrder.Order memory orderLeft,
        bytes memory signatureLeft,
        LibOrder.Order memory orderRight,
        bytes memory signatureRight,
        bytes memory liquidator
    ) public override whenNotPaused nonReentrant {

        // short = selling base token
        address baseToken = orderLeft.isShort ? orderLeft.makeAsset.virtualToken : orderLeft.takeAsset.virtualToken;

        require(
            IMarketRegistry(_marketRegistry).checkBaseToken(baseToken),
            "V_PERP: Basetoken not registered at market"
        );

        // register base token for account balance calculations
        IAccountBalance(_accountBalance).registerBaseToken(orderLeft.trader, baseToken);
        IAccountBalance(_accountBalance).registerBaseToken(orderRight.trader, baseToken);

        // must settle funding first
        _settleFunding(orderLeft.trader, baseToken);
        _settleFunding(orderRight.trader, baseToken);

        InternalData memory internalData = _openPosition(orderLeft, orderRight, baseToken);
        address positionLiquidator = liquidator.decodeAddress();

        if (_validateOrder(orderLeft, signatureLeft, baseToken)) {
            _takeLiquidationFees(
                orderLeft,
                internalData.leftExchangedPositionNotional,
                internalData.leftExchangedPositionSize,
                baseToken,
                positionLiquidator
            );
        }
        if (_validateOrder(orderRight, signatureRight, baseToken)) {
            _takeLiquidationFees(
                orderRight,
                internalData.rightExchangedPositionNotional,
                internalData.rightExchangedPositionSize,
                baseToken,
                positionLiquidator
            );
        }
    }

    /// @inheritdoc IPositioning
    function getPositioningConfig() public view override returns (address) {
        return _positioningConfig;
    }

    /// @inheritdoc IPositioning
    function getVaultController() public view override returns (address) {
        return _vaultController;
    }

    /// @inheritdoc IPositioning
    function getAccountBalance() public view override returns (address) {
        return _accountBalance;
    }

    function getMaxLiquidationAmount(address trader) public view returns (int256) {
        return IAccountBalance(_accountBalance).getMarginRequirementForLiquidation(trader) - _getAccountValue(trader);
    }

    ///@dev this function calculates total pending funding payment of a trader
    function getAllPendingFundingPayment(address trader)
        public
        view
        virtual
        override
        returns (int256 pendingFundingPayment)
    {
        address[] memory baseTokens = IAccountBalance(_accountBalance).getBaseTokens(trader);
        uint256 baseTokenLength = baseTokens.length;

        for (uint256 i = 0; i < baseTokenLength; i++) {
            pendingFundingPayment = pendingFundingPayment + (getPendingFundingPayment(trader, baseTokens[i]));
        }
        return pendingFundingPayment;
    }

    //
    // INTERNAL NON-VIEW
    //

    /// @dev Settle trader's funding payment to his/her realized pnl.
    function _settleFunding(address trader, address baseToken) internal returns (int256 growthTwPremium) {
        int256 fundingPayment;
        (fundingPayment, growthTwPremium) = settleFunding(trader, baseToken);

        if (fundingPayment != 0) {
            IAccountBalance(_accountBalance).modifyOwedRealizedPnl(trader, fundingPayment.neg256());
            emit FundingPaymentSettled(trader, baseToken, fundingPayment);
        }

        IAccountBalance(_accountBalance).updateTwPremiumGrowthGlobal(trader, baseToken, growthTwPremium);
        return growthTwPremium;
    }

    /// @dev Add given amount to PnL of the address provided
    function _modifyOwedRealizedPnl(address trader, int256 amount) internal {
        IAccountBalance(_accountBalance).modifyOwedRealizedPnl(trader, amount);
    }

    function setPositioning(address PositioningArg) public override(PositioningCallee, IPositioning) {
        _Positioning = PositioningArg;
    }

    /// @dev this function matches the both orders and opens the position
    function _openPosition(
        LibOrder.Order memory orderLeft,
        LibOrder.Order memory orderRight,
        address baseToken
    ) internal returns (InternalData memory internalData) {
        LibFill.FillResult memory newFill = IMatchingEngine(_matchingEngine).matchOrders(orderLeft, orderRight);

        if (orderLeft.isShort) {
            internalData.leftExchangedPositionSize = newFill.leftValue.neg256();
            internalData.rightExchangedPositionSize = newFill.leftValue.toInt256();

            internalData.leftExchangedPositionNotional = newFill.rightValue.toInt256();
            internalData.rightExchangedPositionNotional = newFill.rightValue.neg256();
        } else {
            internalData.leftExchangedPositionSize = newFill.rightValue.toInt256();
            internalData.rightExchangedPositionSize = newFill.rightValue.neg256();

            internalData.leftExchangedPositionNotional = newFill.leftValue.neg256();
            internalData.rightExchangedPositionNotional = newFill.leftValue.toInt256();
        }

        // TODO: This is hardcoded right now but changes it during relayer development
        bool isLeftMaker = true;
        OrderFees memory orderFees =
            _calculateFees(
                isLeftMaker,
                internalData.leftExchangedPositionNotional,
                internalData.rightExchangedPositionNotional
            );

        // modifies PnL of fee receiver
        _modifyOwedRealizedPnl(_getFeeReceiver(), (orderFees.orderLeftFee + orderFees.orderRightFee).toInt256());

        // modifies positionSize and openNotional
        (internalData.leftPositionSize, internalData.leftOpenNotional) = IAccountBalance(_accountBalance)
            .modifyTakerBalance(
            orderLeft.trader,
            baseToken,
            internalData.leftExchangedPositionSize,
            internalData.leftExchangedPositionNotional - orderFees.orderLeftFee.toInt256()
        );
        (internalData.rightPositionSize, internalData.rightOpenNotional) = IAccountBalance(_accountBalance)
            .modifyTakerBalance(
            orderRight.trader,
            baseToken,
            internalData.rightExchangedPositionSize,
            internalData.rightExchangedPositionNotional - orderFees.orderRightFee.toInt256()
        );

        if (_firstTradedTimestampMap[baseToken] == 0) {
            _firstTradedTimestampMap[baseToken] = _blockTimestamp();
        }

        // if not closing a position, check margin ratio after swap
        if (internalData.leftPositionSize != 0) {
            _requireEnoughFreeCollateral(orderLeft.trader);
        }

        if (internalData.rightPositionSize != 0) {
            _requireEnoughFreeCollateral(orderRight.trader);
        }

        emit PositionChanged(
            orderLeft.trader,
            baseToken,
            internalData.leftExchangedPositionSize,
            internalData.leftExchangedPositionNotional,
            orderFees.orderLeftFee,
            internalData.leftOpenNotional
        );

        emit PositionChanged(
            orderRight.trader,
            baseToken,
            internalData.rightExchangedPositionSize,
            internalData.rightExchangedPositionNotional,
            orderFees.orderRightFee,
            internalData.rightOpenNotional
        );

        IAccountBalance(_accountBalance).deregisterBaseToken(orderLeft.trader, baseToken);
        IAccountBalance(_accountBalance).deregisterBaseToken(orderRight.trader, baseToken);
        return internalData;
    }

    function registerBaseToken(address trader, address token) external {
        IAccountBalance(_accountBalance).registerBaseToken(trader, token);
    }

    function _takeLiquidationFees(
        LibOrder.Order memory order,
        int256 exchangedPositionNotional,
        int256 exchangedPositionSize,
        address baseToken,
        address liquidator
    ) internal {
        uint256 liquidationFee;
        // trader's pnl-- as liquidation penalty
        liquidationFee = exchangedPositionNotional.abs().mulRatio(
            IPositioningConfig(_positioningConfig).getLiquidationPenaltyRatio()
        );

        //2.5 % liquidation fees to fee receiver
        _modifyOwedRealizedPnl(_getFeeReceiver(), liquidationFee.toInt256());

        //2.5 % liquidation fees to liquidator, increase liquidator's pnl liquidation reward
        _modifyOwedRealizedPnl(liquidator, liquidationFee.toInt256());
        _modifyOwedRealizedPnl(order.trader, (liquidationFee * 2).neg256());

        emit PositionLiquidated(
            order.trader,
            baseToken,
            exchangedPositionNotional.abs(),
            exchangedPositionSize,
            liquidationFee,
            liquidator
        );
    }

    //
    // INTERNAL VIEW
    //

    function _validateOrder(
        LibOrder.Order memory order,
        bytes memory signature,
        address baseToken
    ) internal view returns (bool isLiquidation) {
        LibOrder.validate(order);
        if (_isAccountLiquidatable(order.trader)) {
            _isOrderLiquidatable(order, baseToken);
            return true;
        }
        _validateFull(order, signature);
        return false;
    }

    function _calculateFees(
        bool isLeftMaker,
        int256 leftExchangedPositionNotional,
        int256 rightExchangedPositionNotional
    ) internal view returns (OrderFees memory orderFees) {
        orderFees.orderLeftFee = isLeftMaker
            ? leftExchangedPositionNotional.abs().mulRatio(IMarketRegistry(_marketRegistry).getMakerFeeRatio())
            : leftExchangedPositionNotional.abs().mulRatio(IMarketRegistry(_marketRegistry).getTakerFeeRatio());

        orderFees.orderRightFee = isLeftMaker
            ? rightExchangedPositionNotional.abs().mulRatio(IMarketRegistry(_marketRegistry).getTakerFeeRatio())
            : rightExchangedPositionNotional.abs().mulRatio(IMarketRegistry(_marketRegistry).getMakerFeeRatio());
    }

    /// @dev this function validate the signature of order
    function _validateFull(LibOrder.Order memory order, bytes memory signature) internal view {
        _validate(order, signature);
    }

    /// @dev this function checks if correct order is received for liquidation
    function _isOrderLiquidatable(LibOrder.Order memory order, address baseToken) internal view {
        int256 positionSize = _getTakerPosition(order.trader, baseToken);

        // P_PSZ: position size is zero
        require(positionSize != 0, "P_PSZ");

        // P_WAP: wrong argument passed
        require(positionSize > 0 == order.isShort, "P_WAP");

        uint24 partialCloseRatio = IPositioningConfig(_positioningConfig).getPartialLiquidationRatio();

        uint256 amount = positionSize.abs().mulRatio(partialCloseRatio);

        int256 maxLiquidation = getMaxLiquidationAmount(order.trader);

        uint256 orderAmount = order.isShort ? order.makeAsset.value : order.takeAsset.value;

        require(orderAmount >= amount && orderAmount <= maxLiquidation.abs(), "P_WTV");
    }

    /// @dev This function checks if account of trader is eligible for liquidation
    function _isAccountLiquidatable(address trader) internal view returns (bool) {
        return _getAccountValue(trader) < IAccountBalance(_accountBalance).getMarginRequirementForLiquidation(trader);
    }

    /// @dev This function returns position size of trader
    function _getTakerPosition(address trader, address baseToken) internal view returns (int256) {
        return IAccountBalance(_accountBalance).getTakerPositionSize(trader, baseToken);
    }

    /// @dev This function checks if free collateral of trader is available
    function _requireEnoughFreeCollateral(address trader) internal view {
        // CH_NEFCI: not enough free collateral by imRatio
        require(_getFreeCollateralByRatio(trader, IPositioningConfig(_positioningConfig).getImRatio()) > 0, "CH_NEFCI");
    }

    /// @dev this function returns address of the fee receiver
    function _getFeeReceiver() internal view returns (address) {
        return defaultFeeReceiver;
    }

    /// @dev this function returns total account value of the trader
    function _getAccountValue(address trader) internal view returns (int256) {
        return IVaultController(_vaultController).getAccountValue(trader);
    }

    /// @dev this function returns total free collateral available of trader
    function _getFreeCollateralByRatio(address trader, uint24 ratio) internal view returns (int256) {
        return IVaultController(_vaultController).getFreeCollateralByRatio(trader, ratio);
    }

    function _msgSender() internal view override(OwnerPausable, ContextUpgradeable) returns (address) {
        return super._msgSender();
    }

    function _msgData() internal view virtual override(ContextUpgradeable) returns (bytes calldata) {
        return msg.data;
    }

    function _requirePositioningAdmin() internal view {
        require(hasRole(POSITIONING_ADMIN, _msgSender()), "Positioning: Not admin");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
 *
 * @custom:storage-size 52
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

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
    function __EIP712_init(string memory name, string memory version) internal onlyInitializing {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal onlyInitializing {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
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
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: BUSL - 1.1
pragma solidity =0.8.12;

library LibAccountMarket {
    /// @param lastTwPremiumGrowthGlobal the last time weighted premiumGrowthGlobalX96
    struct Info {
        int256 takerPositionSize;
        int256 takerOpenNotional;
        int256 lastTwPremiumGrowthGlobal;
    }
}

// SPDX-License-Identifier: BUSL - 1.1

pragma solidity =0.8.12;

import "./LibMath.sol";
import "./LibAsset.sol";
import "../interfaces/IVirtualToken.sol";

library LibOrder {
    bytes32 constant ORDER_TYPEHASH =
        keccak256(
            "Order(bytes4 orderType,uint64 deadline,address trader,Asset makeAsset,Asset takeAsset,uint256 salt,uint128 triggerPrice,bool isShort)Asset(address virtualToken,uint256 value)"
        );

    // Generated using bytes4(keccack256(abi.encodePacked("Order")))
    bytes4 public constant ORDER = 0xf555eb98;
    // Generated using bytes4(keccack256(abi.encodePacked("StopLossLimitOrder")))
    bytes4 public constant STOP_LOSS_LIMIT_ORDER = 0xeeaed735;
    // Generated using bytes4(keccack256(abi.encodePacked("TakeProfitLimitOrder")))
    bytes4 public constant TAKE_PROFIT_LIMIT_ORDER = 0xe0fc7f94;

    struct Order {
        bytes4 orderType;
        uint64 deadline;
        address trader;
        LibAsset.Asset makeAsset;
        LibAsset.Asset takeAsset;
        uint256 salt;
        uint128 triggerPrice;
        bool isShort;
    }

    function calculateRemaining(Order memory order, uint256 fill)
        internal
        pure
        returns (uint256 baseValue, uint256 quoteValue)
    {
        baseValue = order.makeAsset.value - fill;
        quoteValue = LibMath.safeGetPartialAmountFloor(order.takeAsset.value, order.makeAsset.value, baseValue);
    }

    function hashKey(Order memory order) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(order.orderType, order.deadline, order.trader, LibAsset.hash(order.makeAsset), LibAsset.hash(order.takeAsset), order.salt, order.triggerPrice, order.isShort)
            );
    }

    function hash(Order memory order) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ORDER_TYPEHASH,
                    order.orderType,
                    order.deadline,
                    order.trader,
                    LibAsset.hash(order.makeAsset),
                    LibAsset.hash(order.takeAsset),
                    order.salt,
                    order.triggerPrice,
                    order.isShort
                )
            );
    }

    function validate(LibOrder.Order memory order) internal view {
        require(order.deadline > block.timestamp, "V_PERP_M: Order deadline validation failed");
        
        bool isMakeAssetBase = IVirtualToken(order.makeAsset.virtualToken).isBase();
        bool isTakeAssetBase = IVirtualToken(order.takeAsset.virtualToken).isBase();

        require(
            (isMakeAssetBase && !isTakeAssetBase) || (!isMakeAssetBase && isTakeAssetBase), 
            "Both makeAsset & takeAsset can't be baseTokens"
        );

        require(
            (order.isShort && isMakeAssetBase && !isTakeAssetBase) ||
            (!order.isShort && !isMakeAssetBase && isTakeAssetBase), 
            "Short order can't have takeAsset as a baseToken/Long order can't have makeAsset as baseToken"
        );
    }
}

// SPDX-License-Identifier: BUSL - 1.1

pragma solidity =0.8.12;

import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

import "./LibOrder.sol";

library LibFill {
    struct FillResult {
        uint256 leftValue;
        uint256 rightValue;
    }

    struct IsMakeFill {
        bool leftMake;
        bool rightMake;
    }

    /**
     * @dev Should return filled values
     * @param leftOrder left order
     * @param rightOrder right order
     * @param leftOrderFill current fill of the left order (0 if order is unfilled)
     * @param rightOrderFill current fill of the right order (0 if order is unfilled)
     */
    function fillOrder(
        LibOrder.Order memory leftOrder,
        LibOrder.Order memory rightOrder,
        uint256 leftOrderFill,
        uint256 rightOrderFill
    ) internal pure returns (FillResult memory) {
        (uint256 leftBaseValue, uint256 leftQuoteValue) = LibOrder.calculateRemaining(leftOrder, leftOrderFill); //q,b
        (uint256 rightBaseValue, uint256 rightQuoteValue) = LibOrder.calculateRemaining(rightOrder, rightOrderFill); //b,q

        //We have 3 cases here:
        if (rightQuoteValue > leftBaseValue) {//1nd: left order should be fully filled
            return fillLeft(leftBaseValue, leftQuoteValue, rightOrder.makeAsset.value, rightOrder.takeAsset.value);//lq,lb,rb,rq
        }
        //2st: right order should be fully filled or 3d: both should be fully filled if required values are the same
        return fillRight(leftOrder.makeAsset.value, leftOrder.takeAsset.value, rightBaseValue, rightQuoteValue); //lq,lb,rb,rq
    }

    function fillRight(
        uint256 leftMakeValue,
        uint256 leftTakeValue,
        uint256 rightMakeValue,
        uint256 rightTakeValue
    ) internal pure returns (FillResult memory result) {
        uint256 makerValue = LibMath.safeGetPartialAmountFloor(rightTakeValue, leftMakeValue, leftTakeValue); //rq * lb / lq
        require(makerValue <= rightMakeValue, "V_PERP_M: fillRight: unable to fill");
        return FillResult(rightTakeValue, makerValue); //rq, lb == left goes long ; rb, lq ==left goes short
    }

    function fillLeft(
        uint256 leftMakeValue,
        uint256 leftTakeValue,
        uint256 rightMakeValue,
        uint256 rightTakeValue
    ) internal pure returns (FillResult memory result) {
        uint256 rightTake = LibMath.safeGetPartialAmountFloor(leftTakeValue, rightMakeValue, rightTakeValue);//lb *rq / rb = rq
        require(rightTake <= leftMakeValue, "V_PERP_M: fillLeft: unable to fill");
        return FillResult(leftMakeValue, leftTakeValue); //lq,lb
    }
}

// SPDX-License-Identifier: BUSL - 1.1
pragma solidity =0.8.12;

import "./LibFeeSide.sol";
import "./LibAsset.sol";

library LibDeal {
    struct DealSide {
        LibAsset.Asset asset;
        address proxy;
        address from;
    }

    struct DealData {
        uint256 protocolFee;
        uint256 maxFeesBasePoint;
        LibFeeSide.FeeSide feeSide;
    }
}

// SPDX-License-Identifier: BUSL - 1.1
pragma solidity =0.8.12;

library LibAsset {
    bytes32 constant ASSET_TYPEHASH = keccak256("Asset(address virtualToken,uint256 value)");

    struct Asset {
        address virtualToken;
        uint256 value;
    }

    function hash(Asset memory asset) internal pure returns (bytes32) {
        return keccak256(abi.encode(ASSET_TYPEHASH, asset.virtualToken, asset.value));
    }
}

// SPDX-License-Identifier: BUSL - 1.1
pragma solidity =0.8.12;

import { FixedPoint96 } from "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";
import { LibFullMath } from "../libs/LibFullMath.sol";
import { LibSafeCastInt } from "./LibSafeCastInt.sol";
import { LibSafeCastUint } from "./LibSafeCastUint.sol";

library LibPerpMath {
    using LibSafeCastInt for int256;
    using LibSafeCastUint for uint256;

    function formatX96ToX10_18(uint256 valueX96) internal pure returns (uint256) {
        return LibFullMath.mulDiv(valueX96, 1 ether, FixedPoint96.Q96);
    }

    function max(int256 a, int256 b) internal pure returns (int256) {
        return a >= b ? a : b;
    }

    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    function abs(int256 value) internal pure returns (uint256) {
        return value >= 0 ? value.toUint256() : neg256(value).toUint256();
    }

    function neg256(int256 a) internal pure returns (int256) {
        require(a > -2**255, "LibPerpMath: inversion overflow");
        return -a;
    }

    function neg256(uint256 a) internal pure returns (int256) {
        return -LibSafeCastUint.toInt256(a);
    }

    function neg128(int128 a) internal pure returns (int128) {
        require(a > -2**127, "LibPerpMath: inversion overflow");
        return -a;
    }

    function neg128(uint128 a) internal pure returns (int128) {
        return -LibSafeCastUint.toInt128(int128(a));
    }

    function mulRatio(uint256 value, uint24 ratio) internal pure returns (uint256) {
        return LibFullMath.mulDiv(value, ratio, 1e6);
    }

    /// @param denominator cannot be 0 and is checked in LibFullMath.mulDiv()
    function mulDiv(
        int256 a,
        int256 b,
        uint256 denominator
    ) internal pure returns (int256 result) {
        uint256 unsignedA = a < 0 ? uint256(neg256(a)) : uint256(a);
        uint256 unsignedB = b < 0 ? uint256(neg256(b)) : uint256(b);
        bool negative = ((a < 0 && b > 0) || (a > 0 && b < 0)) ? true : false;

        uint256 unsignedResult = LibFullMath.mulDiv(unsignedA, unsignedB, denominator);

        result = negative ? neg256(unsignedResult) : LibSafeCastUint.toInt256(unsignedResult);

        return result;
    }
}

// SPDX-License-Identifier: BUSL - 1.1
pragma solidity =0.8.12;

/**
 * @dev copy from "@openzeppelin/contracts-upgradeable/utils/SafeCastUpgradeable.sol"
 * and rename to avoid naming conflict with uniswap
 */
library LibSafeCastInt {
    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128 returnValue) {
        require(((returnValue = uint128(value)) == value), "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64 returnValue) {
        require(((returnValue = uint64(value)) == value), "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32 returnValue) {
        require(((returnValue = uint32(value)) == value), "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16 returnValue) {
        require(((returnValue = uint16(value)) == value), "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8 returnValue) {
        require(((returnValue = uint8(value)) == value), "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }
}

// SPDX-License-Identifier: BUSL - 1.1
pragma solidity =0.8.12;

/**
 * @dev copy from "@openzeppelin/contracts-upgradeable/utils/SafeCastUpgradeable.sol"
 * and rename to avoid naming conflict with uniswap
 */
library LibSafeCastUint {
    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 returnValue) {
        require(((returnValue = int128(value)) == value), "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 returnValue) {
        require(((returnValue = int64(value)) == value), "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 returnValue) {
        require(((returnValue = int32(value)) == value), "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 returnValue) {
        require(((returnValue = int16(value)) == value), "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 returnValue) {
        require(((returnValue = int8(value)) == value), "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     */
    function toInt24(int256 value) internal pure returns (int24 returnValue) {
        require(((returnValue = int24(value)) == value), "SafeCast: value doesn't fit in an 24 bits");
    }
}

// SPDX-License-Identifier: BUSL - 1.1

pragma solidity =0.8.12;

library LibSignature {
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
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(
            uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "ECDSA: invalid signature 's' value"
        );

        // If the signature is valid (and not malleable), return the signer address
        // v > 30 is a special case, we need to adjust hash with "\x19Ethereum Signed Message:\n32"
        // and v = v - 4
        address signer;
        if (v > 30) {
            require(v - 4 == 27 || v - 4 == 28, "ECDSA: invalid signature 'v' value");
            signer = ecrecover(toEthSignedMessageHash(hash), v - 4, r, s);
        } else {
            require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");
            signer = ecrecover(hash, v, r, s);
        }

        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// SPDX-License-Identifier: BUSL - 1.1

pragma solidity =0.8.12;

library EncodeDecode {
    /**
     * @dev Used to encode address to bytes
     *
     * @param _account type address
     * @return hash of encoded address
     */
    function encodeAddress(address _account) internal pure returns (bytes memory) {
        return abi.encode(_account);
    }

    /**
     * @dev Used to decode bytes for address
     *
     * @param _account type bytes
     * @return address of decode hash
     */
    function decodeAddress(bytes memory _account) internal pure returns (address) {
        return abi.decode(_account, (address));
    }
}

// SPDX-License-Identifier: BUSL - 1.1
pragma solidity =0.8.12;

import { LibAccountMarket } from "../libs/LibAccountMarket.sol";

interface IAccountBalance {
    /// @param vault The address of the vault contract
    event VaultChanged(address indexed vault);

    /// @dev Emit whenever a trader's `owedRealizedPnl` is updated
    /// @param trader The address of the trader
    /// @param amount The amount changed
    event PnlRealized(address indexed trader, int256 amount);

    function initialize(address positioningConfigArg) external;

    /// @notice Modify trader account balance
    /// @dev Only used by `Positioning` contract
    /// @param trader The address of the trader
    /// @param baseToken The address of the baseToken
    /// @param base Modified amount of base
    /// @param quote Modified amount of quote
    /// @return takerPositionSize Taker position size after modified
    /// @return takerOpenNotional Taker open notional after modified
    function modifyTakerBalance(
        address trader,
        address baseToken,
        int256 base,
        int256 quote
    ) external returns (int256, int256);

    /// @notice Modify trader owedRealizedPnl
    /// @dev Only used by `Positioning` contract
    /// @param trader The address of the trader
    /// @param amount Modified amount of owedRealizedPnl
    function modifyOwedRealizedPnl(address trader, int256 amount) external;

    /// @notice Settle owedRealizedPnl
    /// @dev Only used by `Vault.withdraw()`
    /// @param trader The address of the trader
    /// @return pnl Settled owedRealizedPnl
    function settleOwedRealizedPnl(address trader) external returns (int256 pnl);

    /// @notice Modify trader owedRealizedPnl
    /// @dev Only used by `Positioning` contract
    /// @param trader The address of the trader
    /// @param baseToken The address of the baseToken
    /// @param amount Settled quote amount
    function settleQuoteToOwedRealizedPnl(
        address trader,
        address baseToken,
        int256 amount
    ) external;

    /// @notice Every time a trader's position value is checked, the base token list of this trader will be traversed;
    /// thus, this list should be kept as short as possible
    /// @dev Only used by `Positioning` contract
    /// @param trader The address of the trader
    /// @param baseToken The address of the trader's base token
    function registerBaseToken(address trader, address baseToken) external;

    /// @notice Deregister baseToken from trader accountInfo
    /// @dev Only used by `Positioning` contract, this function is expensive, due to for loop
    /// @param trader The address of the trader
    /// @param baseToken The address of the trader's base token
    function deregisterBaseToken(address trader, address baseToken) external;

    /// @notice Update trader Twap premium info
    /// @dev Only used by `Positioning` contract
    /// @param trader The address of trader
    /// @param baseToken The address of baseToken
    /// @param lastTwPremiumGrowthGlobal The last Twap Premium
    function updateTwPremiumGrowthGlobal(
        address trader,
        address baseToken,
        int256 lastTwPremiumGrowthGlobal
    ) external;

    /// @notice Get `PositioningConfig` address
    /// @return PositioningConfig The address of PositioningConfig
    function getPositioningConfig() external view returns (address);

    /// @notice Get `Vault` address
    /// @return vault The address of Vault
    function getVault() external view returns (address);

    /// @notice Get trader registered baseTokens
    /// @param trader The address of trader
    /// @return baseTokens The array of baseToken address
    function getBaseTokens(address trader) external view returns (address[] memory);

    /// @notice Get trader account info
    /// @param trader The address of trader
    /// @param baseToken The address of baseToken
    /// @return traderAccountInfo The baseToken account info of trader
    function getAccountInfo(address trader, address baseToken) external view returns (LibAccountMarket.Info memory);

    /// @notice Get taker cost of trader's baseToken
    /// @param trader The address of trader
    /// @param baseToken The address of baseToken
    /// @return openNotional The taker cost of trader's baseToken
    function getTakerOpenNotional(address trader, address baseToken) external view returns (int256);

    /// @notice Get total debt value of trader
    /// @param trader The address of trader
    /// @dev Total debt value will relate to `Vault.getFreeCollateral()`
    /// @return totalDebtValue The debt value of trader
    function getTotalDebtValue(address trader) external view returns (uint256);

    /// @notice Get margin requirement to check whether trader will be able to liquidate
    /// @dev This is different from `Vault._getTotalMarginRequirement()`, which is for freeCollateral calculation
    /// @param trader The address of trader
    /// @return marginRequirementForLiquidation It is compared with `Positioning.getAccountValue`
    function getMarginRequirementForLiquidation(address trader) external view returns (int256);

    /// @notice Get owedRealizedPnl, realizedPnl and pending fee
    /// @param trader The address of trader
    /// @return owedRealizedPnl the pnl realized already but stored temporarily in AccountBalance
    /// @return unrealizedPnl the pnl not yet realized
    function getPnlAndPendingFee(address trader)
        external
        view
        returns (
            int256 owedRealizedPnl,
            int256 unrealizedPnl
        );

    /// @notice Get taker position size of trader's baseToken market
    /// @dev This will only has taker position, can get maker impermanent position through `getTotalPositionSize`
    /// @param trader The address of trader
    /// @param baseToken The address of baseToken
    /// @return takerPositionSize The taker position size of trader's baseToken market
    function getTakerPositionSize(address trader, address baseToken) external view returns (int256);

    /// @notice Get total position value of trader's baseToken market
    /// @dev A negative returned value is only be used when calculating pnl,
    /// @dev we use `15 mins` twap to calc position value
    /// @param trader The address of trader
    /// @param baseToken The address of baseToken
    /// @return totalPositionValue Total position value of trader's baseToken market
    function getTotalPositionValue(address trader, address baseToken) external view returns (int256);

    /// @notice Get all market position abs value of trader
    /// @param trader The address of trader
    /// @return totalAbsPositionValue Sum up positions value of every market
    function getTotalAbsPositionValue(address trader) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL - 1.1

pragma solidity =0.8.12;

interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param _hash Hash of the data signed on the behalf of address(this)
     * @param _signature Signature byte array associated with _data
     *
     * MUST return the bytes4 magic value 0x1626ba7e when function passes.
     * MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
     * MUST allow external calls
     */
    function isValidSignature(bytes32 _hash, bytes calldata _signature)
        external
        view
        returns (bytes4 magicValue);
}

// SPDX-License-Identifier: BUSL - 1.1

pragma solidity =0.8.12;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: BUSL - 1.1
pragma solidity =0.8.12;

interface IIndexPrice {
    /// @notice Returns the index price of the token.
    /// @param interval The interval represents twap interval.
    /// @return indexPrice Twap price with interval
    function getIndexPrice(uint256 interval) external view returns (uint256 indexPrice);
}

// SPDX-License-Identifier: BUSL - 1.1

pragma solidity =0.8.12;

import "../libs/LibOrder.sol";
import "../libs/LibFill.sol";
import "../libs/LibDeal.sol";

interface IMatchingEngine {
    function cancelOrder(LibOrder.Order memory order) external;
    function cancelOrdersInBatch(LibOrder.Order[] memory orders) external;
    function cancelAllOrders(uint256 minSalt) external;
    function matchOrders(LibOrder.Order memory orderLeft, LibOrder.Order memory orderRight)
        external
        returns (
            LibFill.FillResult memory
        );
    function grantMatchOrders(address account) external;
}

// SPDX-License-Identifier: BUSL - 1.1
pragma solidity =0.8.12;

interface IMarketRegistry {

    /// @notice Emitted when the max orders per market is updated.
    /// @param maxOrdersPerMarket Max orders per market
    event MaxOrdersPerMarketChanged(uint8 maxOrdersPerMarket);

    /// @dev Set max allowed orders per market
    /// @param maxOrdersPerMarketArg The max allowed orders per market
    function setMaxOrdersPerMarket(uint8 maxOrdersPerMarketArg) external;

    /// @dev Set maker fee ratio
    /// @param makerFeeRatio The maker fee ratio
    function setMakerFeeRatio( uint24 makerFeeRatio) external;

    /// @dev Set taker fee ratio
    /// @param takerFeeRatio The taker fee ratio
    function setTakerFeeRatio( uint24 takerFeeRatio) external;

    /// @dev Function to add base token in the market
    /// @param baseToken address of the baseToken
    function addBaseToken(address baseToken) external;

    /// @dev Function to check base token in the market
    /// @param baseToken address of the baseToken
    function checkBaseToken(address baseToken) external returns (bool);

    /// @notice Get the maker fee ration
    function getMakerFeeRatio() external view returns (uint24);

    /// @notice Get the taker fee ration
    function getTakerFeeRatio() external view returns (uint24);

    /// @notice Get the quote token address
    /// @return quoteToken The address of the quote token
    function getQuoteToken() external view returns (address quoteToken);

    /// @notice Get max allowed orders per market
    /// @return maxOrdersPerMarket The max allowed orders per market
    function getMaxOrdersPerMarket() external view returns (uint8 maxOrdersPerMarket);
}

// SPDX-License-Identifier: BUSL - 1.1
pragma solidity =0.8.12;
import "../libs/LibOrder.sol";
import "../libs/LibFill.sol";
import "../libs/LibDeal.sol";

interface IPositioning {
    struct InternalData {
        int256 leftExchangedPositionSize;
        int256 leftExchangedPositionNotional;
        int256 rightExchangedPositionSize;
        int256 rightExchangedPositionNotional;
        int256 leftPositionSize;
        int256 rightPositionSize;
        int256 leftOpenNotional;
        int256 rightOpenNotional;
    }

    struct OrderFees {
            uint256 orderLeftFee;
            uint256 orderRightFee;
        }

    /// @notice Emitted when taker position is being liquidated
    /// @param trader The trader who has been liquidated
    /// @param baseToken Virtual base token(ETH, BTC, etc...) address
    /// @param positionNotional The cost of position
    /// @param positionSize The size of position
    /// @param liquidationFee The fee of liquidate
    /// @param liquidator The address of liquidator
    event PositionLiquidated(
        address indexed trader,
        address indexed baseToken,
        uint256 positionNotional,
        int256 positionSize,
        uint256 liquidationFee,
        address liquidator
    );

    // TODO: Implement this event
    /// @notice Emitted when open position with non-zero referral code
    /// @param referralCode The referral code by partners
    event ReferredPositionChanged(bytes32 indexed referralCode);

    /// @notice Emitted when defualt fee receiver is changed
    event DefaultFeeReceiverChanged(address defaultFeeReceiver);

    /// @notice Emitted when taker's position is being changed
    /// @param trader Trader address
    /// @param baseToken The address of virtual base token(ETH, BTC, etc...)
    /// @param exchangedPositionSize The actual amount swap to uniswapV3 pool
    /// @param exchangedPositionNotional The cost of position, include fee
    /// @param fee The fee of open/close position
    /// @param openNotional The cost of open/close position, < 0: long, > 0: short
    event PositionChanged(
        address indexed trader,
        address indexed baseToken,
        int256 exchangedPositionSize,
        int256 exchangedPositionNotional,
        uint256 fee,
        int256 openNotional
    );

    /// @notice Emitted when settling a trader's funding payment
    /// @param trader The address of trader
    /// @param baseToken The address of virtual base token(ETH, BTC, etc...)
    /// @param fundingPayment The fundingPayment of trader on baseToken market, > 0: payment, < 0 : receipt
    event FundingPaymentSettled(address indexed trader, address indexed baseToken, int256 fundingPayment);

    /// @notice Emitted when trusted forwarder address changed
    /// @dev TrustedForward is only used for metaTx
    /// @param forwarder The trusted forwarder address
    event TrustedForwarderChanged(address indexed forwarder);

    /// @dev this function is public for testing
    function initialize(
        address PositioningConfigArg,
        address vaultControllerArg,
        address accountBalanceArg,
        address matchingEngineArg,
        address markPriceArg,
        address indexPriceArg,
        uint64 underlyingPriceIndex
    ) external;

    /// @notice Settle all markets fundingPayment to owedRealized Pnl
    /// @param trader The address of trader
    function settleAllFunding(address trader) external;

    /// @notice Function to set fee receiver
    function setDefaultFeeReceiver(address newDefaultFeeReceiver) external;

    /// @notice Trader can call `openPosition` to long/short on baseToken market
    /// @param orderLeft PositionParams struct
    /// @param orderRight PositionParams struct
    function openPosition(
        LibOrder.Order memory orderLeft,
        bytes memory signatureLeft,
        LibOrder.Order memory orderRight,
        bytes memory signatureRight,
        bytes memory liquidator
    ) external;
    
    /// @notice Set Positioning address
    function setPositioning(address positioning) external;

    /// @notice Get PositioningConfig address
    /// @return PositioningConfig PositioningConfig address
    function getPositioningConfig() external view returns (address PositioningConfig);

    /// @notice Get total pending funding payment of trader
    /// @param trader address of the trader
    /// @return pendingFundingPayment  total pending funding
    function getAllPendingFundingPayment(address trader) external view returns (int256 pendingFundingPayment);

    /// @notice Get `Vault` address
    /// @return vault `Vault` address
    function getVaultController() external view returns (address vault);

    /// @notice Get AccountBalance address
    /// @return accountBalance `AccountBalance` address
    function getAccountBalance() external view returns (address accountBalance);
}

// SPDX-License-Identifier: BUSL - 1.1
pragma solidity =0.8.12;

interface IPositioningConfig {
    /// @return maxMarketsPerAccount Max value of total markets per account
    function getMaxMarketsPerAccount() external view returns (uint8 maxMarketsPerAccount);

    /// @return imRatio Initial margin ratio
    function getImRatio() external view returns (uint24 imRatio);

    /// @return mmRatio Maintenance margin requirement ratio
    function getMmRatio() external view returns (uint24 mmRatio);

    /// @return liquidationPenaltyRatio Liquidation penalty ratio
    function getLiquidationPenaltyRatio() external view returns (uint24 liquidationPenaltyRatio);

    /// @return partialCloseRatio Partial close ratio
    function getPartialCloseRatio() external view returns (uint24 partialCloseRatio);

    /// @return twapInterval TwapInterval for funding and prices (mark & index) calculations
    function getTwapInterval() external view returns (uint32 twapInterval);

    /// @return settlementTokenBalanceCap Max value of settlement token balance
    function getSettlementTokenBalanceCap() external view returns (uint256 settlementTokenBalanceCap);

    /// @return maxFundingRate Max value of funding rate
    function getMaxFundingRate() external view returns (uint24 maxFundingRate);

    /// @return partial liquidation ratio
    function getPartialLiquidationRatio() external view returns (uint24);
}

// SPDX-License-Identifier: BUSL - 1.1
pragma solidity =0.8.12;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IVirtualToken is IERC20Upgradeable {
    // Getters
    function isInWhitelist(address account) external view returns (bool);
    function isBase() external view returns (bool);

    // Setters
    function mint(address recipient, uint256 amount) external;
    function burn(address recipient, uint256 amount) external;
    function mintMaximumTo(address recipient) external;
    function addWhitelist(address account) external;
    function removeWhitelist(address account) external;
}

// SPDX-License-Identifier: BUSL - 1.1
pragma solidity =0.8.12;

import "./IVolmexPerpPeriphery.sol";

interface IVaultController{

    function initialize(
        address positioningConfig,
        address accountBalanceArg
    ) external;

    /// @notice Deposit collateral into vault
    /// @param token The address of the token to deposit
    /// @param amount The amount of the token to deposit
    function deposit(IVolmexPerpPeriphery periphery, address token, address from, uint256 amount) external payable;

    /// @notice Withdraw collateral from vault
    /// @param token The address of the token sender is going to withdraw
    /// @param amount The amount of the token to withdraw
    function withdraw(address token, address payable to, uint256 amount) external;

    /// @notice Function to register new vault
    function registerVault(address _vault, address _token) external;

    /// @notice Function to get total account value of a trader
    function getAccountValue(address trader)  external view returns (int256);

    /// @notice Function to get total free collateral of a trader by given ratio
    function getFreeCollateralByRatio(address trader, uint24 ratio) external view returns (int256);

    /// @notice Function to get address of the vault related to given token
    function getVault(address _token) external view returns (address);

    /// @notice Function to balance of the trader in 18 Decimals
    function getBalance(address trader) external view returns (int256);

    /// @notice Function to balance of the trader on the basis of token in 18 Decimals
    function getBalanceByToken(address trader, address token) external view returns (int256);

    /// @notice Function to set positioning contract
    function setPositioning(address PositioningArg) external;
}

// SPDX-License-Identifier: BUSL - 1.1
pragma solidity =0.8.12;

abstract contract BlockContext {
    function _blockTimestamp() internal view virtual returns (uint256) {
        // Reply from Arbitrum
        // block.timestamp returns timestamp at the time at which the sequencer receives the tx.
        // It may not actually correspond to a particular L1 block
        return block.timestamp;
    }

    function _networkId() internal view virtual returns (uint256 networkId) {
        assembly {
            networkId := chainid()
        }
    }
}

// SPDX-License-Identifier: BUSL - 1.1
pragma solidity =0.8.12;
pragma abicoder v2;

import { AddressUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import { LibSafeCastInt } from "../libs/LibSafeCastInt.sol";
import { LibSafeCastUint } from "../libs/LibSafeCastUint.sol";
import { LibPerpMath } from "../libs/LibPerpMath.sol";

import { IAccountBalance } from "../interfaces/IAccountBalance.sol";
import { IIndexPriceOracle } from "../interfaces/IIndexPriceOracle.sol";
import { IFundingRate } from "../interfaces/IFundingRate.sol";
import { IMarkPriceOracle } from "../interfaces/IMarkPriceOracle.sol";
import { IPositioningConfig } from "../interfaces/IPositioningConfig.sol";

import { BlockContext } from "../helpers/BlockContext.sol";
import { FundingRateStorage } from "../storage/FundingRateStorage.sol";
import { PositioningCallee } from "../helpers/PositioningCallee.sol";
import { PositioningStorageV1 } from "../storage/PositioningStorage.sol";

contract FundingRate is IFundingRate, BlockContext, PositioningCallee, FundingRateStorage, PositioningStorageV1 {
    using AddressUpgradeable for address;
    using LibPerpMath for uint256;
    using LibPerpMath for int256;
    using LibSafeCastUint for uint256;

    function __FundingRate_init(address markPriceOracleArg, address indexPriceOracleArg) internal onlyInitializing {
        __PositioningCallee_init();
        _markPriceOracleArg = markPriceOracleArg;
        _indexPriceOracleArg = indexPriceOracleArg;
    }

    /// @inheritdoc IFundingRate
    function settleFunding(address trader, address baseToken)
        public
        virtual
        override
        returns (int256 fundingPayment, int256 growthTwPremium)
    {
        uint256 markTwap;
        uint256 indexTwap;
        (growthTwPremium, markTwap, indexTwap) = _getFundingGrowthGlobalAndTwaps(baseToken);

        fundingPayment = _getFundingPayment(trader, baseToken, markTwap.toInt256(), indexTwap.toInt256());

        uint256 timestamp = _blockTimestamp();
        // update states before further actions in this block; once per block
        if (timestamp != _lastSettledTimestampMap[baseToken]) {
            // update growthTwPremium and _lastSettledTimestamp
            int256 lastGrowthTwPremium = _globalFundingGrowthMap[baseToken];
            (_lastSettledTimestampMap[baseToken], lastGrowthTwPremium) = (timestamp, growthTwPremium);
            emit FundingUpdated(baseToken, markTwap, indexTwap);
        }
        return (fundingPayment, growthTwPremium);
    }

    /**
    TODO:   we should check use cases here whether marketFundingRate goes -ve or not
     */
    /// @dev this function calculates pending funding payment of user
    /// @param markTwap only for settleFunding()
    /// @param indexTwap only for settleFunding()
    /// @return pendingFundingPayment pending funding payment of user
    function _getFundingPayment(
        address trader,
        address baseToken,
        int256 markTwap,
        int256 indexTwap
    ) internal view virtual returns (int256 pendingFundingPayment) {
        int256 marketFundingRate = ((markTwap - indexTwap) / indexTwap) / (24);
        int256 PositionSize = IAccountBalance(_accountBalance).getTakerPositionSize(trader, baseToken);
        pendingFundingPayment = PositionSize * marketFundingRate;
    }

    /// @dev this function calculates the up-to-date growthTwPremium and twaps and pass them out
    /// @param baseToken address of the baseToken
    /// @return growthTwPremium the up-to-date growthTwPremium
    /// @return markTwap only for settleFunding()
    /// @return indexTwap only for settleFunding()
    function _getFundingGrowthGlobalAndTwaps(address baseToken)
        internal
        view
        virtual
        returns (
            int256 growthTwPremium,
            uint256 markTwap,
            uint256 indexTwap
        )
    {
        uint256 twapInterval;
        uint256 timestamp = _blockTimestamp();
        // shorten twapInterval if prior observations are not enough
        if (_firstTradedTimestampMap[baseToken] != 0) {
            twapInterval = IPositioningConfig(_positioningConfig).getTwapInterval();
            uint256 deltaTimestamp = (timestamp - _firstTradedTimestampMap[baseToken]);
            // TODO: this differs from perp-curie
            twapInterval = twapInterval < deltaTimestamp ? deltaTimestamp : twapInterval;
        }

        markTwap =
            IMarkPriceOracle(_markPriceOracleArg).getCumulativePrice(twapInterval, _underlyingPriceIndex);

        //TODOCHANGE: review if we need this formatting
        // markTwap = markTwapX96.formatX96ToX10_18();
        // TODO: getIndexTwap method takes _index of underlying to fetch the price, not the time interval
        (indexTwap, , ) = IIndexPriceOracle(_indexPriceOracleArg).getIndexTwap(_underlyingPriceIndex);

        uint256 lastSettledTimestamp = _lastSettledTimestampMap[baseToken];
        int256 lastTwPremium = _globalFundingGrowthMap[baseToken];
        if (timestamp == lastSettledTimestamp || lastSettledTimestamp == 0) {
            // if this is the latest updated timestamp, values in _globalFundingGrowthX96Map are up-to-date already
            growthTwPremium = lastTwPremium;
        } else {
            // deltaTwPremium = (markTwap - indexTwap) * (now - lastSettledTimestamp)
            int256 deltaTwPremium =
                _getDeltaTwap(markTwap, indexTwap) * ((timestamp - lastSettledTimestamp).toInt256());
            growthTwPremium = lastTwPremium + deltaTwPremium;
        }

        return (growthTwPremium, markTwap, indexTwap);
    }

    function _getDeltaTwap(uint256 markTwap, uint256 indexTwap) internal view virtual returns (int256 deltaTwap) {
        uint24 maxFundingRate = IPositioningConfig(_positioningConfig).getMaxFundingRate();
        uint256 maxDeltaTwap = indexTwap.mulRatio(maxFundingRate);
        uint256 absDeltaTwap;
        if (markTwap > indexTwap) {
            absDeltaTwap = markTwap - indexTwap;
            deltaTwap = absDeltaTwap > maxDeltaTwap ? maxDeltaTwap.toInt256() : absDeltaTwap.toInt256();
        } else {
            absDeltaTwap = indexTwap - markTwap;
            deltaTwap = absDeltaTwap > maxDeltaTwap ? maxDeltaTwap.neg256() : absDeltaTwap.neg256();
        }
    }

    /// @inheritdoc IFundingRate
    function getPendingFundingPayment(address trader, address baseToken) public view virtual override returns (int256) {
        (, uint256 markTwap, uint256 indexTwap) = _getFundingGrowthGlobalAndTwaps(baseToken);
        return _getFundingPayment(trader, baseToken, markTwap.toInt256(), indexTwap.toInt256());
    }
}

// SPDX-License-Identifier: BUSL - 1.1
pragma solidity =0.8.12;

import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract OwnerPausable is OwnableUpgradeable, PausableUpgradeable {
    // solhint-disable-next-line func-order
    function __OwnerPausable_init() internal onlyInitializing {
        __Ownable_init();
        __Pausable_init();
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function _msgSender() internal view virtual override returns (address) {
        return super._msgSender();
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: BUSL - 1.1
pragma solidity =0.8.12;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";

import "../interfaces/IERC1271.sol";
import { LibOrder } from "../libs/LibOrder.sol";
import "../libs/LibSignature.sol";

abstract contract OrderValidator is Initializable, ContextUpgradeable, EIP712Upgradeable {
    using LibSignature for bytes32;
    using AddressUpgradeable for address;

    bytes4 constant internal MAGICVALUE = 0x1626ba7e;

    mapping(address => uint256) public makerMinSalt;

    function __OrderValidator_init_unchained() internal onlyInitializing {
        __EIP712_init_unchained("V_PERP", "1");
    }

    function _validate(LibOrder.Order memory order, bytes memory signature) internal view {
        if (order.salt == 0) {
            if (order.trader != address(0)) {
                require(_msgSender() == order.trader, "V_PERP_M: maker is not tx sender");
            } else {
                order.trader = _msgSender();
            }
        } else {
            require(
                (order.salt >= makerMinSalt[order.trader]),
                "V_PERP_M: Order canceled"
            );
            if (_msgSender() != order.trader) {
                bytes32 hash = LibOrder.hash(order);
                address signer;
                if (signature.length == 65) {
                    signer = _hashTypedDataV4(hash).recover(signature);
                }
                if  (signer != order.trader) {
                    if (order.trader.isContract()) {
                        require(
                            IERC1271(order.trader).isValidSignature(_hashTypedDataV4(hash), signature) == MAGICVALUE,
                            "V_PERP_M: contract order signature verification error"
                        );
                    } else {
                        revert("V_PERP_M: order signature verification error");
                    }
                } else {
                    require (order.trader != address(0), "V_PERP_M: no trader");
                }
            }
        }
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: BUSL - 1.1
pragma solidity =0.8.12;

/// @notice For future upgrades, do not change PositioningStorageV1. Create a new
/// contract which implements PositioningStorageV1 and following the naming convention
/// PositioningStorageVX.
abstract contract PositioningStorageV1 {
    // --------- IMMUTABLE ---------

    // cache the settlement token's decimals for gas optimization
    uint8 internal _settlementTokenDecimals;
    // --------- ^^^^^^^^^ ---------
    mapping(address => uint256) internal _firstTradedTimestampMap;
    address internal _positioningConfig;
    address internal _vaultController;
    address internal _accountBalance;
    address internal _matchingEngine;
    address internal _marketRegistry;

    address public defaultFeeReceiver;

    uint256[50] private __gap;
}

// SPDX-License-Identifier: BUSL - 1.1
pragma solidity =0.8.12;

import { Context } from "@openzeppelin/contracts/utils/Context.sol";
import { ContextUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "./RoleManager.sol";

abstract contract PositioningCallee is RoleManager {
    //
    // STATE
    //
    address internal _Positioning;

    //
    // EVENT
    //
    event PositioningCalleeChanged(address indexed PositioningCallee);

    //
    // CONSTRUCTOR
    //

    // solhint-disable-next-line func-order
    function __PositioningCallee_init() internal onlyInitializing {
        _grantRole(POSITIONING_CALLEE_ADMIN, _msgSender());
    }

    function setPositioning(address PositioningArg) external virtual {
        require(hasRole(POSITIONING_CALLEE_ADMIN, _msgSender()), "PositioningCallee: Not admin");
        _Positioning = PositioningArg;
        _grantRole(CAN_MATCH_ORDERS, PositioningArg);
        emit PositioningCalleeChanged(PositioningArg);
    }

    function getPositioning() external view returns (address) {
        return _Positioning;
    }

    function _requireOnlyPositioning() internal view {
        // only Positioning
        require(_msgSender() == _Positioning, "CHD_OCH");
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
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
            /// @solidity memory-safe-assembly
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
            /// @solidity memory-safe-assembly
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
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
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
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: BUSL - 1.1

pragma solidity =0.8.12;

library LibMath {
    /// @dev Calculates partial value given a numerator and denominator rounded down.
    ///      Reverts if rounding error is >= 0.1%
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to calculate partial of.
    /// @return partialAmount value of target rounded down.
    function safeGetPartialAmountFloor(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    ) internal pure returns (uint256 partialAmount) {
        if (isRoundingErrorFloor(numerator, denominator, target)) {
            revert("rounding error");
        }
        partialAmount = (numerator * target) / denominator;
    }

    /// @dev Checks if rounding error >= 0.1% when rounding down.
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to multiply with numerator/denominator.
    /// @return isError Rounding error is present.
    function isRoundingErrorFloor(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    ) internal pure returns (bool isError) {
        if (denominator == 0) {
            revert("division by zero");
        }

        // The absolute rounding error is the difference between the rounded
        // value and the ideal value. The relative rounding error is the
        // absolute rounding error divided by the absolute value of the
        // ideal value. This is undefined when the ideal value is zero.
        //
        // The ideal value is `numerator * target / denominator`.
        // Let's call `numerator * target % denominator` the remainder.
        // The absolute error is `remainder / denominator`.
        //
        // When the ideal value is zero, we require the absolute error to
        // be zero. Fortunately, this is always the case. The ideal value is
        // zero iff `numerator == 0` and/or `target == 0`. In this case the
        // remainder and absolute error are also zero.
        if (target == 0 || numerator == 0) {
            return false;
        }

        // Otherwise, we want the relative rounding error to be strictly
        // less than 0.1%.
        // The relative error is `remainder / (numerator * target)`.
        // We want the relative error less than 1 / 1000:
        //        remainder / (numerator * target)  <  1 / 1000
        // or equivalently:
        //        1000 * remainder  <  numerator * target
        // so we have a rounding error iff:
        //        1000 * remainder  >=  numerator * target
        uint256 remainder = mulmod(target, numerator, denominator);
        isError = (remainder * 1000) >= (numerator * target);
    }

    function safeGetPartialAmountCeil(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    ) internal pure returns (uint256 partialAmount) {
        if (isRoundingErrorCeil(numerator, denominator, target)) {
            revert("rounding error");
        }
        partialAmount = ((numerator * target) + (denominator - 1)) / denominator;
    }

    /// @dev Checks if rounding error >= 0.1% when rounding up.
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to multiply with numerator/denominator.
    /// @return isError Rounding error is present.
    function isRoundingErrorCeil(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    ) internal pure returns (bool isError) {
        if (denominator == 0) {
            revert("V_PERP_M: division by zero");
        }

        // See the comments in `isRoundingError`.
        if (target == 0 || numerator == 0) {
            // When either is zero, the ideal value and rounded value are zero
            // and there is no rounding error. (Although the relative error
            // is undefined.)
            return false;
        }
        // Compute remainder as before
        uint256 remainder = mulmod(target, numerator, denominator);
        remainder = (denominator - remainder) % denominator;
        isError = (remainder * 1000) >= (numerator * target);
        return isError;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: BUSL - 1.1
pragma solidity =0.8.12;

import "./LibOrder.sol";
import "../interfaces/IVirtualToken.sol";

library LibFeeSide {
    enum FeeSide {
        LEFT,
        RIGHT,
        NONE
    }

    function getFeeSide(LibOrder.Order memory orderLeft, LibOrder.Order memory orderRight) internal view returns (FeeSide) {
        if (!IVirtualToken(orderLeft.makeAsset.virtualToken).isBase()) {
            return FeeSide.LEFT;
        }
        if (!IVirtualToken(orderRight.makeAsset.virtualToken).isBase()) {
            return FeeSide.LEFT;
        }
        return FeeSide.NONE;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

// SPDX-License-Identifier: BUSL - 1.1
pragma solidity =0.8.12;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library LibFullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = denominator & (~denominator + 1);
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.12;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "../libs/LibOrder.sol";

import "./IPositioning.sol";
import "./IVaultController.sol";

interface IVolmexPerpPeriphery {
    event VaultControllerAdded(uint256 indexed vaultControllerIndex, address indexed vaultController);
    event VaultControllerUpdated(
        uint256 indexed vaultControllerIndex,
        address indexed oldVaultController,
        address indexed newVaultController
    );
    event PositioningAdded(uint256 indexed positioningIndex, address indexed positionings);
    event PositioningUpdated(
        uint256 indexed positioningIndex,
        address indexed oldPositionings,
        address indexed newPositionings
    );
    event RelayerUpdated(address indexed oldRelayerAddress, address indexed newRelayerAddress);
    event VaultWhitelisted(address indexed vault, bool isWhitelist);

    function depositToVault(
        uint64 _index,
        address _token,
        uint256 _amount
    ) external payable;

    function withdrawFromVault(
        uint64 _index,
        address _token,
        address payable _to,
        uint256 _amount
    ) external;

    function openPosition(
        uint64 _index,
        LibOrder.Order memory _orderLeft,
        bytes memory _signatureLeft,
        LibOrder.Order memory _orderRight,
        bytes memory _signatureRight,
        bytes memory liquidator
    ) external;

    function transferToVault(
        IERC20Upgradeable _token,
        address _from,
        uint256 _amount
    ) external;

    function addPositioning(IPositioning _positioning) external;

    function addVaultController(IVaultController _vaultController) external;

    function updatePositioningAtIndex(
        IPositioning _oldPositioning,
        IPositioning _newPositioning,
        uint256 _index
    ) external;

    function updateVaultControllerAtIndex(
        IVaultController _oldVaultController,
        IVaultController _newVaultController,
        uint256 _index
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.12;

import "./IVolmexProtocol.sol";

interface IIndexPriceOracle {
    event SymbolIndexUpdated(uint256 indexed _index);
    event BaseVolatilityIndexUpdated(uint256 indexed baseVolatilityIndex);
    event BatchVolatilityTokenPriceUpdated(
        uint256[] _volatilityIndexes,
        uint256[] _volatilityTokenPrices,
        bytes32[] _proofHashes
    );
    event VolatilityIndexAdded(
        uint256 indexed volatilityTokenIndex,
        uint256 volatilityCapRatio,
        string volatilityTokenSymbol,
        uint256 volatilityTokenPrice
    );
    event LeveragedVolatilityIndexAdded(
        uint256 indexed volatilityTokenIndex,
        uint256 volatilityCapRatio,
        string volatilityTokenSymbol,
        uint256 leverage,
        uint256 baseVolatilityIndex
    );

    // Getter  methods
    function volatilityCapRatioByIndex(uint256 _index) external view returns (uint256);
    function volatilityTokenPriceProofHash(uint256 _index) external view returns (bytes32);
    function volatilityIndexBySymbol(string calldata _tokenSymbol) external view returns (uint256);
    function volatilityLastUpdateTimestamp(uint256 _index) external view returns (uint256);
    function volatilityLeverageByIndex(uint256 _index) external view returns (uint256);
    function baseVolatilityIndex(uint256 _index) external view returns (uint256);
    function indexCount() external view returns (uint256);
    function latestRoundData(uint256 _index)
        external
        view
        returns (uint256 answer, uint256 lastUpdateTimestamp);
    function getIndexTwap(uint256 _index)
        external
        view
        returns (
            uint256 volatilityTokenTwap,
            uint256 iVolatilityTokenTwap,
            uint256 lastUpdateTimestamp
        );
    function getVolatilityTokenPriceByIndex(uint256 _index)
        external
        view
        returns (
            uint256 volatilityTokenPrice,
            uint256 iVolatilityTokenPrice,
            uint256 lastUpdateTimestamp
        );
    function getVolatilityPriceBySymbol(string calldata _volatilityTokenSymbol)
        external
        view
        returns (
            uint256 volatilityTokenPrice,
            uint256 iVolatilityTokenPrice,
            uint256 lastUpdateTimestamp
        );

    // Setter methods
    function updateIndexBySymbol(string calldata _tokenSymbol, uint256 _index) external;
    function updateBaseVolatilityIndex(
        uint256 _leverageVolatilityIndex,
        uint256 _newBaseVolatilityIndex
    ) external;
    function updateBatchVolatilityTokenPrice(
        uint256[] memory _volatilityIndexes,
        uint256[] memory _volatilityTokenPrices,
        bytes32[] memory _proofHashes
    ) external;
    function addVolatilityIndex(
        uint256 _volatilityTokenPrice,
        IVolmexProtocol _protocol,
        string calldata _volatilityTokenSymbol,
        uint256 _leverage,
        uint256 _baseVolatilityIndex,
        bytes32 _proofHash
    ) external;
}

// SPDX-License-Identifier: BUSL - 1.1
pragma solidity =0.8.12;
pragma abicoder v2;

interface IFundingRate {
    /// @notice event to emit after funding updated
    event FundingUpdated(address indexed baseToken, uint256 markTwap, uint256 indexTwap);

    /// @dev this function is used to settle funding f a trader on the basis of given basetoken
    /// @param trader address of the trader
    /// @param baseToken address of the baseToken
    /// @return fundingPayment pnding funding payment on this basetoken
    /// @return growthTwPremium global funding growth of the basetoken
    function settleFunding(address trader, address baseToken)
        external
        returns (int256 fundingPayment, int256 growthTwPremium);

    ///@dev this function calculates pending funding payment of a trader respective to basetoken
    /// @param trader address of the trader
    /// @param baseToken address of the baseToken
    function getPendingFundingPayment(address trader, address baseToken) external view returns (int256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.12;

interface IMarkPriceOracle {
    function addObservation(uint256 _priceCumulative, uint64 _index) external;

    function exchange() external view returns (address);
    function getCumulativePrice(uint256 _twInterval, uint64 _index) external view returns (uint256 priceCumulative);
    function indexByBaseToken(address _baseToken) external view returns (uint64 _index);
    function addAssets(uint256[] memory _priceCumulative, address[] memory _asset) external;
}

// SPDX-License-Identifier: BUSL - 1.1
pragma solidity =0.8.12;

/// @notice For future upgrades, do not change ExchangeStorageV1. Create a new
/// contract which implements ExchangeStorageV1 and following the naming convention
/// ExchangeStorageVX.
abstract contract FundingRateStorage {
    address internal _markPriceOracleArg;
    address internal _indexPriceOracleArg;
    uint64 internal _underlyingPriceIndex;

    mapping(address => uint256) internal _lastSettledTimestampMap;
    // mapping basetoken => twpremium(time weighted)
    mapping(address => int256) internal _globalFundingGrowthMap;
    
    uint256[50] private __gap;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.12;

import "./IERC20Modified.sol";

interface IVolmexProtocol {
    //getter methods
    function minimumCollateralQty() external view returns (uint256);
    function active() external view returns (bool);
    function isSettled() external view returns (bool);
    function volatilityToken() external view returns (IERC20Modified);
    function inverseVolatilityToken() external view returns (IERC20Modified);
    function collateral() external view returns (IERC20Modified);
    function issuanceFees() external view returns (uint256);
    function redeemFees() external view returns (uint256);
    function accumulatedFees() external view returns (uint256);
    function volatilityCapRatio() external view returns (uint256);
    function settlementPrice() external view returns (uint256);
    function precisionRatio() external view returns (uint256);

    //setter methods
    function toggleActive() external;
    function updateMinimumCollQty(uint256 _newMinimumCollQty) external;
    function updatePositionToken(address _positionToken, bool _isVolatilityIndex) external;
    function collateralize(uint256 _collateralQty) external;
    function redeem(uint256 _positionTokenQty) external;
    function redeemSettled(
        uint256 _volatilityIndexTokenQty,
        uint256 _inverseVolatilityIndexTokenQty
    ) external;
    function settle(uint256 _settlementPrice) external;
    function recoverTokens(
        address _token,
        address _toWhom,
        uint256 _howMuch
    ) external;
    function updateFees(uint256 _issuanceFees, uint256 _redeemFees) external;
    function claimAccumulatedFees() external;
    function togglePause(bool _isPause) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.12;

interface IERC20Modified {
    // IERC20 Methods
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    // Custom Methods
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function decimals() external view returns (uint8);
    function mint(address _toWhom, uint256 amount) external;
    function burn(address _whose, uint256 amount) external;
    function grantRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
    function pause() external;
    function unpause() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: BUSL - 1.1

pragma solidity =0.8.12;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract RoleManager is AccessControlUpgradeable {
    bytes32 public constant CLONES_DEPLOYER = keccak256("CLONES_DEPLOYER");
    bytes32 public constant ONLY_ADMIN = keccak256("ONLY_ADMIN");
    bytes32 public constant CAN_CANCEL_ALL_ORDERS = keccak256("CAN_CANCEL_ALL_ORDERS");
    bytes32 public constant CAN_MATCH_ORDERS = keccak256("CAN_MATCH_ORDERS");
    bytes32 public constant CAN_ADD_ASSETS = keccak256("CAN_ADD_ASSETS");
    bytes32 public constant CAN_ADD_OBSERVATION = keccak256("CAN_ADD_OBSERVATION");
    bytes32 public constant CAN_SETTLE_REALIZED_PNL = keccak256("CAN_SETTLE_REALIZED_PNL");
    bytes32 public constant DEPOSIT_WITHDRAW_IN_VAULT = keccak256("DEPOSIT_WITHDRAW_IN_VAULT");
    bytes32 public constant MARKET_REGISTRY_ADMIN = keccak256("MARKET_REGISTRY_ADMIN");
    bytes32 public constant POSITIONING_CALLEE_ADMIN = keccak256("POSITIONING_CALLEE_ADMIN");
    bytes32 public constant MATCHING_ENGINE_CORE_ADMIN = keccak256("MATCHING_ENGINE_CORE_ADMIN");
    bytes32 public constant TRANSFER_EXECUTOR = keccak256("TRANSFER_EXECUTOR");
    bytes32 public constant INDEX_PRICE_ORACLE_ADMIN = keccak256("INDEX_PRICE_ORACLE_ADMIN");
    bytes32 public constant MARK_PRICE_ORACLE_ADMIN = keccak256("MARK_PRICE_ORACLE_ADMIN");
    bytes32 public constant ACCOUNT_BALANCE_ADMIN = keccak256("ACCOUNT_BALANCE_ADMIN");
    bytes32 public constant POSITIONING_ADMIN = keccak256("POSITIONING_ADMIN");
    bytes32 public constant POSITIONING_CONFIG_ADMIN = keccak256("POSITIONING_CONFIG_ADMIN");
    bytes32 public constant VAULT_ADMIN = keccak256("VAULT_ADMIN");
    bytes32 public constant VAULT_CONTROLLER_ADMIN = keccak256("VAULT_CONTROLLER_ADMIN");
    bytes32 public constant VIRTUAL_TOKEN_ADMIN = keccak256("VIRTUAL_TOKEN_ADMIN");
    bytes32 public constant VOLMEX_PERP_PERIPHERY = keccak256("VOLMEX_PERP_PERIPHERY");
    bytes32 public constant LIMIT_ORDER_ADMIN = keccak256("LIMIT_ORDER_ADMIN");
    bytes32 public constant TRANSFER_PROXY_ADMIN = keccak256("TRANSFER_PROXY_ADMIN");
    bytes32 public constant TRANSFER_PROXY_CALLER = keccak256("TRANSFER_PROXY_CALLER");
    bytes32 public constant MINTER = keccak256("MINTER");
    bytes32 public constant BURNER = keccak256("BURNER");
    bytes32 public constant RELAYER_MULTISIG = keccak256("RELAYER_MULTISIG");
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}