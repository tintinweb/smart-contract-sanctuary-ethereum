// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./interfaces/ILimitOrder.sol";
import "./interfaces/IPermanentStorage.sol";
import "./interfaces/ISpender.sol";
import "./interfaces/IWeth.sol";
import "./utils/BaseLibEIP712.sol";
import "./utils/LibConstant.sol";
import "./utils/LibUniswapV2.sol";
import "./utils/LibUniswapV3.sol";
import "./utils/LibOrderStorage.sol";
import "./utils/LimitOrderLibEIP712.sol";
import "./utils/SignatureValidator.sol";

contract LimitOrder is ILimitOrder, BaseLibEIP712, SignatureValidator, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    string public constant version = "1.0.0";
    IPermanentStorage public immutable permStorage;
    address public immutable userProxy;
    IWETH public immutable weth;

    // AMM
    address public immutable uniswapV3RouterAddress;
    address public immutable sushiswapRouterAddress;

    // Below are the variables which consume storage slots.
    address public operator;
    address public coordinator;
    ISpender public spender;
    address public feeCollector;

    // Factors
    uint16 public makerFeeFactor = 0;
    uint16 public takerFeeFactor = 0;
    uint16 public profitFeeFactor = 0;
    uint16 public profitCapFactor = LibConstant.BPS_MAX;

    constructor(
        address _operator,
        address _coordinator,
        address _userProxy,
        ISpender _spender,
        IPermanentStorage _permStorage,
        IWETH _weth,
        address _uniswapV3RouterAddress,
        address _sushiswapRouterAddress,
        address _feeCollector
    ) {
        operator = _operator;
        coordinator = _coordinator;
        userProxy = _userProxy;
        spender = _spender;
        permStorage = _permStorage;
        weth = _weth;
        uniswapV3RouterAddress = _uniswapV3RouterAddress;
        sushiswapRouterAddress = _sushiswapRouterAddress;
        feeCollector = _feeCollector;
    }

    receive() external payable {}

    modifier onlyOperator() {
        require(operator == msg.sender, "LimitOrder: not operator");
        _;
    }

    modifier onlyUserProxy() {
        require(address(userProxy) == msg.sender, "LimitOrder: not the UserProxy contract");
        _;
    }

    function transferOwnership(address _newOperator) external onlyOperator {
        require(_newOperator != address(0), "LimitOrder: operator can not be zero address");
        operator = _newOperator;

        emit TransferOwnership(_newOperator);
    }

    function upgradeSpender(address _newSpender) external onlyOperator {
        require(_newSpender != address(0), "LimitOrder: spender can not be zero address");
        spender = ISpender(_newSpender);

        emit UpgradeSpender(_newSpender);
    }

    function upgradeCoordinator(address _newCoordinator) external onlyOperator {
        require(_newCoordinator != address(0), "LimitOrder: coordinator can not be zero address");
        coordinator = _newCoordinator;

        emit UpgradeCoordinator(_newCoordinator);
    }

    /**
     * @dev approve spender to transfer tokens from this contract. This is used to collect fee.
     */
    function setAllowance(address[] calldata _tokenList, address _spender) external onlyOperator {
        for (uint256 i = 0; i < _tokenList.length; i++) {
            IERC20(_tokenList[i]).safeApprove(_spender, LibConstant.MAX_UINT);

            emit AllowTransfer(_spender);
        }
    }

    function closeAllowance(address[] calldata _tokenList, address _spender) external onlyOperator {
        for (uint256 i = 0; i < _tokenList.length; i++) {
            IERC20(_tokenList[i]).safeApprove(_spender, 0);

            emit DisallowTransfer(_spender);
        }
    }

    /**
     * @dev convert collected ETH to WETH
     */
    function depositETH() external onlyOperator {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            weth.deposit{ value: balance }();

            emit DepositETH(balance);
        }
    }

    function setFactors(
        uint16 _makerFeeFactor,
        uint16 _takerFeeFactor,
        uint16 _profitFeeFactor,
        uint16 _profitCapFactor
    ) external onlyOperator {
        require(_makerFeeFactor <= LibConstant.BPS_MAX, "LimitOrder: Invalid maker fee factor");
        require(_takerFeeFactor <= LibConstant.BPS_MAX, "LimitOrder: Invalid taker fee factor");
        require(_profitFeeFactor <= LibConstant.BPS_MAX, "LimitOrder: Invalid profit fee factor");
        require(_profitCapFactor <= LibConstant.BPS_MAX, "LimitOrder: Invalid profit cap factor");

        makerFeeFactor = _makerFeeFactor;
        takerFeeFactor = _takerFeeFactor;
        profitFeeFactor = _profitFeeFactor;
        profitCapFactor = _profitCapFactor;

        emit FactorsUpdated(_makerFeeFactor, _takerFeeFactor, _profitFeeFactor, _profitCapFactor);
    }

    /**
     * @dev set fee collector
     */
    function setFeeCollector(address _newFeeCollector) external onlyOperator {
        require(_newFeeCollector != address(0), "LimitOrder: fee collector can not be zero address");
        feeCollector = _newFeeCollector;

        emit SetFeeCollector(_newFeeCollector);
    }

    /**
     * Fill limit order by trader
     */
    function fillLimitOrderByTrader(
        LimitOrderLibEIP712.Order calldata _order,
        bytes calldata _orderMakerSig,
        TraderParams calldata _params,
        CoordinatorParams calldata _crdParams
    ) external override onlyUserProxy nonReentrant returns (uint256, uint256) {
        bytes32 orderHash = getEIP712Hash(LimitOrderLibEIP712._getOrderStructHash(_order));

        _validateOrder(_order, orderHash, _orderMakerSig);
        bytes32 allowFillHash = _validateFillPermission(orderHash, _params.takerTokenAmount, _params.taker, _crdParams);
        _validateOrderTaker(_order, _params.taker);

        {
            LimitOrderLibEIP712.Fill memory fill = LimitOrderLibEIP712.Fill({
                orderHash: orderHash,
                taker: _params.taker,
                recipient: _params.recipient,
                takerTokenAmount: _params.takerTokenAmount,
                takerSalt: _params.salt,
                expiry: _params.expiry
            });
            _validateTraderFill(fill, _params.takerSig);
        }

        (uint256 makerTokenAmount, uint256 takerTokenAmount, uint256 remainingAmount) = _quoteOrder(_order, orderHash, _params.takerTokenAmount);

        uint256 makerTokenOut = _settleForTrader(
            TraderSettlement({
                orderHash: orderHash,
                allowFillHash: allowFillHash,
                trader: _params.taker,
                recipient: _params.recipient,
                maker: _order.maker,
                taker: _order.taker,
                makerToken: _order.makerToken,
                takerToken: _order.takerToken,
                makerTokenAmount: makerTokenAmount,
                takerTokenAmount: takerTokenAmount,
                remainingAmount: remainingAmount
            })
        );

        _recordOrderFilled(orderHash, takerTokenAmount);

        return (takerTokenAmount, makerTokenOut);
    }

    function _validateTraderFill(LimitOrderLibEIP712.Fill memory _fill, bytes memory _fillTakerSig) internal {
        require(_fill.expiry > uint64(block.timestamp), "LimitOrder: Fill request is expired");

        bytes32 fillHash = getEIP712Hash(LimitOrderLibEIP712._getFillStructHash(_fill));
        require(isValidSignature(_fill.taker, fillHash, bytes(""), _fillTakerSig), "LimitOrder: Fill is not signed by taker");

        // Set fill seen to avoid replay attack.
        // PermanentStorage would throw error if fill is already seen.
        permStorage.setLimitOrderTransactionSeen(fillHash);
    }

    function _validateFillPermission(
        bytes32 _orderHash,
        uint256 _fillAmount,
        address _executor,
        CoordinatorParams memory _crdParams
    ) internal returns (bytes32) {
        require(_crdParams.expiry > uint64(block.timestamp), "LimitOrder: Fill permission is expired");

        bytes32 allowFillHash = getEIP712Hash(
            LimitOrderLibEIP712._getAllowFillStructHash(
                LimitOrderLibEIP712.AllowFill({
                    orderHash: _orderHash,
                    executor: _executor,
                    fillAmount: _fillAmount,
                    salt: _crdParams.salt,
                    expiry: _crdParams.expiry
                })
            )
        );
        require(isValidSignature(coordinator, allowFillHash, bytes(""), _crdParams.sig), "LimitOrder: AllowFill is not signed by coordinator");

        // Set allow fill seen to avoid replay attack
        // PermanentStorage would throw error if allow fill is already seen.
        permStorage.setLimitOrderAllowFillSeen(allowFillHash);

        return allowFillHash;
    }

    struct TraderSettlement {
        bytes32 orderHash;
        bytes32 allowFillHash;
        address trader;
        address recipient;
        address maker;
        address taker;
        IERC20 makerToken;
        IERC20 takerToken;
        uint256 makerTokenAmount;
        uint256 takerTokenAmount;
        uint256 remainingAmount;
    }

    function _settleForTrader(TraderSettlement memory _settlement) internal returns (uint256) {
        // Calculate maker fee (maker receives taker token so fee is charged in taker token)
        uint256 takerTokenFee = _mulFactor(_settlement.takerTokenAmount, makerFeeFactor);
        uint256 takerTokenForMaker = _settlement.takerTokenAmount.sub(takerTokenFee);

        // Calculate taker fee (taker receives maker token so fee is charged in maker token)
        uint256 makerTokenFee = _mulFactor(_settlement.makerTokenAmount, takerFeeFactor);
        uint256 makerTokenForTrader = _settlement.makerTokenAmount.sub(makerTokenFee);

        // trader -> maker
        spender.spendFromUserTo(_settlement.trader, address(_settlement.takerToken), _settlement.maker, takerTokenForMaker);

        // maker -> recipient
        spender.spendFromUserTo(_settlement.maker, address(_settlement.makerToken), _settlement.recipient, makerTokenForTrader);

        // Collect maker fee (charged in taker token)
        if (takerTokenFee > 0) {
            spender.spendFromUserTo(_settlement.trader, address(_settlement.takerToken), feeCollector, takerTokenFee);
        }
        // Collect taker fee (charged in maker token)
        if (makerTokenFee > 0) {
            spender.spendFromUserTo(_settlement.maker, address(_settlement.makerToken), feeCollector, makerTokenFee);
        }

        // bypass stack too deep error
        _emitLimitOrderFilledByTrader(
            LimitOrderFilledByTraderParams({
                orderHash: _settlement.orderHash,
                maker: _settlement.maker,
                taker: _settlement.trader,
                allowFillHash: _settlement.allowFillHash,
                recipient: _settlement.recipient,
                makerToken: address(_settlement.makerToken),
                takerToken: address(_settlement.takerToken),
                makerTokenFilledAmount: _settlement.makerTokenAmount,
                takerTokenFilledAmount: _settlement.takerTokenAmount,
                remainingAmount: _settlement.remainingAmount,
                makerTokenFee: makerTokenFee,
                takerTokenFee: takerTokenFee
            })
        );

        return makerTokenForTrader;
    }

    /**
     * Fill limit order by protocol
     */
    function fillLimitOrderByProtocol(
        LimitOrderLibEIP712.Order calldata _order,
        bytes calldata _orderMakerSig,
        ProtocolParams calldata _params,
        CoordinatorParams calldata _crdParams
    ) external override onlyUserProxy nonReentrant returns (uint256) {
        bytes32 orderHash = getEIP712Hash(LimitOrderLibEIP712._getOrderStructHash(_order));

        _validateOrder(_order, orderHash, _orderMakerSig);
        bytes32 allowFillHash = _validateFillPermission(orderHash, _params.takerTokenAmount, tx.origin, _crdParams);

        address protocolAddress = _getProtocolAddress(_params.protocol);
        _validateOrderTaker(_order, protocolAddress);

        (uint256 makerTokenAmount, uint256 takerTokenAmount, uint256 remainingAmount) = _quoteOrder(_order, orderHash, _params.takerTokenAmount);

        uint256 takerTokenProfit = _settleForProtocol(
            ProtocolSettlement({
                orderHash: orderHash,
                allowFillHash: allowFillHash,
                protocolAddress: protocolAddress,
                protocol: _params.protocol,
                data: _params.data,
                relayer: tx.origin,
                profitRecipient: _params.profitRecipient,
                maker: _order.maker,
                taker: _order.taker,
                makerToken: _order.makerToken,
                takerToken: _order.takerToken,
                makerTokenAmount: makerTokenAmount,
                takerTokenAmount: takerTokenAmount,
                remainingAmount: remainingAmount,
                protocolOutMinimum: _params.protocolOutMinimum,
                expiry: _params.expiry
            })
        );

        _recordOrderFilled(orderHash, takerTokenAmount);

        return takerTokenProfit;
    }

    function _getProtocolAddress(Protocol protocol) internal view returns (address) {
        if (protocol == Protocol.UniswapV3) {
            return uniswapV3RouterAddress;
        }
        if (protocol == Protocol.Sushiswap) {
            return sushiswapRouterAddress;
        }
        revert("LimitOrder: Unknown protocol");
    }

    struct ProtocolSettlement {
        bytes32 orderHash;
        bytes32 allowFillHash;
        address protocolAddress;
        Protocol protocol;
        bytes data;
        address relayer;
        address profitRecipient;
        address maker;
        address taker;
        IERC20 makerToken;
        IERC20 takerToken;
        uint256 makerTokenAmount;
        uint256 takerTokenAmount;
        uint256 remainingAmount;
        uint256 protocolOutMinimum;
        uint64 expiry;
    }

    function _settleForProtocol(ProtocolSettlement memory _settlement) internal returns (uint256) {
        // Collect maker token from maker in order to swap through protocol
        spender.spendFromUserTo(_settlement.maker, address(_settlement.makerToken), address(this), _settlement.makerTokenAmount);

        uint256 takerTokenOut = _swapByProtocol(_settlement);

        require(takerTokenOut >= _settlement.takerTokenAmount, "LimitOrder: Insufficient token amount out from protocol");

        uint256 takerTokenExtra = takerTokenOut.sub(_settlement.takerTokenAmount);

        // Cap taker token profit
        uint256 takerTokenProfitCap = _mulFactor(_settlement.takerTokenAmount, profitCapFactor);
        uint256 takerTokenProfit = takerTokenExtra > takerTokenProfitCap ? takerTokenProfitCap : takerTokenExtra;

        // Calculate taker token profit for relayer
        uint256 takerTokenProfitFee = _mulFactor(takerTokenProfit, profitFeeFactor);
        uint256 takerTokenProfitForRelayer = takerTokenProfit.sub(takerTokenProfitFee);

        // Distribute taker token profit to profit recipient assigned by relayer
        _settlement.takerToken.safeTransfer(_settlement.profitRecipient, takerTokenProfitForRelayer);
        if (takerTokenProfitFee > 0) {
            _settlement.takerToken.safeTransfer(feeCollector, takerTokenProfitFee);
        }

        // Calculate maker fee (maker receives taker token so fee is charged in taker token)
        uint256 takerTokenFee = _mulFactor(_settlement.takerTokenAmount, makerFeeFactor);
        uint256 takerTokenForMaker = _settlement.takerTokenAmount.sub(takerTokenFee);

        // Calculate taker token profit back to maker
        uint256 takerTokenProfitBackToMaker = takerTokenExtra > takerTokenProfit ? takerTokenExtra.sub(takerTokenProfit) : 0;

        // Distribute taker token to maker
        _settlement.takerToken.safeTransfer(_settlement.maker, takerTokenForMaker.add(takerTokenProfitBackToMaker));
        if (takerTokenFee > 0) {
            _settlement.takerToken.safeTransfer(feeCollector, takerTokenFee);
        }

        // Bypass stack too deep error
        _emitLimitOrderFilledByProtocol(
            LimitOrderFilledByProtocolParams({
                orderHash: _settlement.orderHash,
                maker: _settlement.maker,
                taker: _settlement.protocolAddress,
                allowFillHash: _settlement.allowFillHash,
                relayer: _settlement.relayer,
                profitRecipient: _settlement.profitRecipient,
                makerToken: address(_settlement.makerToken),
                takerToken: address(_settlement.takerToken),
                makerTokenFilledAmount: _settlement.makerTokenAmount,
                takerTokenFilledAmount: _settlement.takerTokenAmount,
                remainingAmount: _settlement.remainingAmount,
                makerTokenFee: 0,
                takerTokenFee: takerTokenFee,
                takerTokenProfit: takerTokenProfit,
                takerTokenProfitFee: takerTokenProfitFee,
                takerTokenProfitBackToMaker: takerTokenProfitBackToMaker
            })
        );

        return takerTokenProfitForRelayer;
    }

    function _swapByProtocol(ProtocolSettlement memory _settlement) internal returns (uint256 amountOut) {
        _settlement.makerToken.safeApprove(_settlement.protocolAddress, _settlement.makerTokenAmount);

        // UniswapV3
        if (_settlement.protocol == Protocol.UniswapV3) {
            amountOut = LibUniswapV3.exactInput(
                _settlement.protocolAddress,
                LibUniswapV3.ExactInputParams({
                    tokenIn: address(_settlement.makerToken),
                    tokenOut: address(_settlement.takerToken),
                    path: _settlement.data,
                    recipient: address(this),
                    deadline: _settlement.expiry,
                    amountIn: _settlement.makerTokenAmount,
                    amountOutMinimum: _settlement.protocolOutMinimum
                })
            );
        } else {
            // Sushiswap
            address[] memory path = abi.decode(_settlement.data, (address[]));
            amountOut = LibUniswapV2.swapExactTokensForTokens(
                _settlement.protocolAddress,
                LibUniswapV2.SwapExactTokensForTokensParams({
                    tokenIn: address(_settlement.makerToken),
                    tokenInAmount: _settlement.makerTokenAmount,
                    tokenOut: address(_settlement.takerToken),
                    tokenOutAmountMin: _settlement.protocolOutMinimum,
                    path: path,
                    to: address(this),
                    deadline: _settlement.expiry
                })
            );
        }

        _settlement.makerToken.safeApprove(_settlement.protocolAddress, 0);
    }

    /**
     * Cancel limit order
     */
    function cancelLimitOrder(LimitOrderLibEIP712.Order calldata _order, bytes calldata _cancelOrderMakerSig) external override onlyUserProxy nonReentrant {
        require(_order.expiry > uint64(block.timestamp), "LimitOrder: Order is expired");
        bytes32 orderHash = getEIP712Hash(LimitOrderLibEIP712._getOrderStructHash(_order));
        bool isCancelled = LibOrderStorage.getStorage().orderHashToCancelled[orderHash];
        require(!isCancelled, "LimitOrder: Order is cancelled already");
        {
            LimitOrderLibEIP712.Order memory cancelledOrder = _order;
            cancelledOrder.takerTokenAmount = 0;

            bytes32 cancelledOrderHash = getEIP712Hash(LimitOrderLibEIP712._getOrderStructHash(cancelledOrder));
            require(isValidSignature(_order.maker, cancelledOrderHash, bytes(""), _cancelOrderMakerSig), "LimitOrder: Cancel request is not signed by maker");
        }

        // Set cancelled state to storage
        LibOrderStorage.getStorage().orderHashToCancelled[orderHash] = true;
        emit OrderCancelled(orderHash, _order.maker);
    }

    /* order utils */

    function _validateOrder(
        LimitOrderLibEIP712.Order memory _order,
        bytes32 _orderHash,
        bytes memory _orderMakerSig
    ) internal view {
        require(_order.expiry > uint64(block.timestamp), "LimitOrder: Order is expired");
        bool isCancelled = LibOrderStorage.getStorage().orderHashToCancelled[_orderHash];
        require(!isCancelled, "LimitOrder: Order is cancelled");

        require(isValidSignature(_order.maker, _orderHash, bytes(""), _orderMakerSig), "LimitOrder: Order is not signed by maker");
    }

    function _validateOrderTaker(LimitOrderLibEIP712.Order memory _order, address _taker) internal pure {
        if (_order.taker != address(0)) {
            require(_order.taker == _taker, "LimitOrder: Order cannot be filled by this taker");
        }
    }

    function _quoteOrder(
        LimitOrderLibEIP712.Order memory _order,
        bytes32 _orderHash,
        uint256 _takerTokenAmount
    )
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 takerTokenFilledAmount = LibOrderStorage.getStorage().orderHashToTakerTokenFilledAmount[_orderHash];

        require(takerTokenFilledAmount < _order.takerTokenAmount, "LimitOrder: Order is filled");

        uint256 takerTokenFillableAmount = _order.takerTokenAmount.sub(takerTokenFilledAmount);
        uint256 takerTokenQuota = Math.min(_takerTokenAmount, takerTokenFillableAmount);
        uint256 makerTokenQuota = takerTokenQuota.mul(_order.makerTokenAmount).div(_order.takerTokenAmount);
        uint256 remainingAfterFill = takerTokenFillableAmount.sub(takerTokenQuota);

        return (makerTokenQuota, takerTokenQuota, remainingAfterFill);
    }

    function _recordOrderFilled(bytes32 _orderHash, uint256 _takerTokenAmount) internal {
        LibOrderStorage.Storage storage stor = LibOrderStorage.getStorage();
        uint256 takerTokenFilledAmount = stor.orderHashToTakerTokenFilledAmount[_orderHash];
        stor.orderHashToTakerTokenFilledAmount[_orderHash] = takerTokenFilledAmount.add(_takerTokenAmount);
    }

    /* math utils */

    function _mulFactor(uint256 amount, uint256 factor) internal returns (uint256) {
        return amount.mul(factor).div(LibConstant.BPS_MAX);
    }

    /* event utils */

    struct LimitOrderFilledByTraderParams {
        bytes32 orderHash;
        address maker;
        address taker;
        bytes32 allowFillHash;
        address recipient;
        address makerToken;
        address takerToken;
        uint256 makerTokenFilledAmount;
        uint256 takerTokenFilledAmount;
        uint256 remainingAmount;
        uint256 makerTokenFee;
        uint256 takerTokenFee;
    }

    function _emitLimitOrderFilledByTrader(LimitOrderFilledByTraderParams memory _params) internal {
        emit LimitOrderFilledByTrader(
            _params.orderHash,
            _params.maker,
            _params.taker,
            _params.allowFillHash,
            _params.recipient,
            FillReceipt({
                makerToken: _params.makerToken,
                takerToken: _params.takerToken,
                makerTokenFilledAmount: _params.makerTokenFilledAmount,
                takerTokenFilledAmount: _params.takerTokenFilledAmount,
                remainingAmount: _params.remainingAmount,
                makerTokenFee: _params.makerTokenFee,
                takerTokenFee: _params.takerTokenFee
            })
        );
    }

    struct LimitOrderFilledByProtocolParams {
        bytes32 orderHash;
        address maker;
        address taker;
        bytes32 allowFillHash;
        address relayer;
        address profitRecipient;
        address makerToken;
        address takerToken;
        uint256 makerTokenFilledAmount;
        uint256 takerTokenFilledAmount;
        uint256 remainingAmount;
        uint256 makerTokenFee;
        uint256 takerTokenFee;
        uint256 takerTokenProfit;
        uint256 takerTokenProfitFee;
        uint256 takerTokenProfitBackToMaker;
    }

    function _emitLimitOrderFilledByProtocol(LimitOrderFilledByProtocolParams memory _params) internal {
        emit LimitOrderFilledByProtocol(
            _params.orderHash,
            _params.maker,
            _params.taker,
            _params.allowFillHash,
            _params.relayer,
            _params.profitRecipient,
            FillReceipt({
                makerToken: _params.makerToken,
                takerToken: _params.takerToken,
                makerTokenFilledAmount: _params.makerTokenFilledAmount,
                takerTokenFilledAmount: _params.takerTokenFilledAmount,
                remainingAmount: _params.remainingAmount,
                makerTokenFee: _params.makerTokenFee,
                takerTokenFee: _params.takerTokenFee
            }),
            _params.takerTokenProfit,
            _params.takerTokenProfitFee,
            _params.takerTokenProfitBackToMaker
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity ^0.7.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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
pragma solidity >=0.7.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../utils/LimitOrderLibEIP712.sol";

interface ILimitOrder {
    event TransferOwnership(address newOperator);
    event UpgradeSpender(address newSpender);
    event UpgradeCoordinator(address newCoordinator);
    event AllowTransfer(address spender);
    event DisallowTransfer(address spender);
    event DepositETH(uint256 ethBalance);
    event FactorsUpdated(uint16 makerFeeFactor, uint16 takerFeeFactor, uint16 profitFeeFactor, uint16 profitCapFactor);
    event SetFeeCollector(address newFeeCollector);
    event LimitOrderFilledByTrader(
        bytes32 indexed orderHash,
        address indexed maker,
        address indexed taker,
        bytes32 allowFillHash,
        address recipient,
        FillReceipt fillReceipt
    );
    event LimitOrderFilledByProtocol(
        bytes32 indexed orderHash,
        address indexed maker,
        address indexed taker,
        bytes32 allowFillHash,
        address relayer,
        address profitRecipient,
        FillReceipt fillReceipt,
        uint256 takerTokenProfit,
        uint256 takerTokenProfitFee,
        uint256 takerTokenProfitBackToMaker
    );
    event OrderCancelled(bytes32 orderHash, address maker);

    struct FillReceipt {
        address makerToken;
        address takerToken;
        uint256 makerTokenFilledAmount;
        uint256 takerTokenFilledAmount;
        uint256 remainingAmount;
        uint256 makerTokenFee;
        uint256 takerTokenFee;
    }

    struct CoordinatorParams {
        bytes sig;
        uint256 salt;
        uint64 expiry;
    }

    struct TraderParams {
        address taker;
        address recipient;
        uint256 takerTokenAmount;
        uint256 salt;
        uint64 expiry;
        bytes takerSig;
    }

    /**
     * Fill limit order by trader
     */
    function fillLimitOrderByTrader(
        LimitOrderLibEIP712.Order calldata _order,
        bytes calldata _orderMakerSig,
        TraderParams calldata _params,
        CoordinatorParams calldata _crdParams
    ) external returns (uint256, uint256);

    enum Protocol {
        UniswapV3,
        Sushiswap
    }

    struct ProtocolParams {
        Protocol protocol;
        bytes data;
        address profitRecipient;
        uint256 takerTokenAmount;
        uint256 protocolOutMinimum;
        uint64 expiry;
    }

    /**
     * Fill limit order by protocol
     */
    function fillLimitOrderByProtocol(
        LimitOrderLibEIP712.Order calldata _order,
        bytes calldata _orderMakerSig,
        ProtocolParams calldata _params,
        CoordinatorParams calldata _crdParams
    ) external returns (uint256);

    /**
     * Cancel limit order
     */
    function cancelLimitOrder(LimitOrderLibEIP712.Order calldata _order, bytes calldata _cancelMakerSig) external;
}

pragma solidity >=0.7.0;

interface IPermanentStorage {
    function wethAddr() external view returns (address);

    function getCurvePoolInfo(
        address _makerAddr,
        address _takerAssetAddr,
        address _makerAssetAddr
    )
        external
        view
        returns (
            int128 takerAssetIndex,
            int128 makerAssetIndex,
            uint16 swapMethod,
            bool supportGetDx
        );

    function setCurvePoolInfo(
        address _makerAddr,
        address[] calldata _underlyingCoins,
        address[] calldata _coins,
        bool _supportGetDx
    ) external;

    function isTransactionSeen(bytes32 _transactionHash) external view returns (bool); // Kept for backward compatability. Should be removed from AMM 5.2.1 upward

    function isAMMTransactionSeen(bytes32 _transactionHash) external view returns (bool);

    function isRFQTransactionSeen(bytes32 _transactionHash) external view returns (bool);

    function isLimitOrderTransactionSeen(bytes32 _transactionHash) external view returns (bool);

    function isLimitOrderAllowFillSeen(bytes32 _allowFillHash) external view returns (bool);

    function isRelayerValid(address _relayer) external view returns (bool);

    function setTransactionSeen(bytes32 _transactionHash) external; // Kept for backward compatability. Should be removed from AMM 5.2.1 upward

    function setAMMTransactionSeen(bytes32 _transactionHash) external;

    function setRFQTransactionSeen(bytes32 _transactionHash) external;

    function setLimitOrderTransactionSeen(bytes32 _transactionHash) external;

    function setLimitOrderAllowFillSeen(bytes32 _allowFillHash) external;

    function setRelayersValid(address[] memory _relayers, bool[] memory _isValids) external;
}

pragma solidity >=0.7.0;

interface ISpender {
    function spendFromUser(
        address _user,
        address _tokenAddr,
        uint256 _amount
    ) external;

    function spendFromUserTo(
        address _user,
        address _tokenAddr,
        address _receiverAddr,
        uint256 _amount
    ) external;
}

pragma solidity >=0.7.0;

interface IWETH {
    function balanceOf(address account) external view returns (uint256);

    function deposit() external payable;

    function withdraw(uint256 amount) external;

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

abstract contract BaseLibEIP712 {
    /***********************************|
    |             Constants             |
    |__________________________________*/

    // EIP-191 Header
    string public constant EIP191_HEADER = "\x19\x01";

    // EIP712Domain
    string public constant EIP712_DOMAIN_NAME = "Tokenlon";
    string public constant EIP712_DOMAIN_VERSION = "v5";

    // EIP712Domain Separator
    bytes32 public immutable EIP712_DOMAIN_SEPARATOR =
        keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(EIP712_DOMAIN_NAME)),
                keccak256(bytes(EIP712_DOMAIN_VERSION)),
                getChainID(),
                address(this)
            )
        );

    /**
     * @dev Return `chainId`
     */
    function getChainID() internal pure returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }

    function getEIP712Hash(bytes32 structHash) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(EIP191_HEADER, EIP712_DOMAIN_SEPARATOR, structHash));
    }
}

pragma solidity ^0.7.6;

library LibConstant {
    int256 internal constant MAX_INT = 2**255 - 1;
    uint256 internal constant MAX_UINT = 2**256 - 1;
    uint16 internal constant BPS_MAX = 10000;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "../interfaces/IUniswapRouterV2.sol";

library LibUniswapV2 {
    struct SwapExactTokensForTokensParams {
        address tokenIn;
        uint256 tokenInAmount;
        address tokenOut;
        uint256 tokenOutAmountMin;
        address[] path;
        address to;
        uint256 deadline;
    }

    function swapExactTokensForTokens(address _uniswapV2Router, SwapExactTokensForTokensParams memory _params) internal returns (uint256 amount) {
        _validatePath(_params.path, _params.tokenIn, _params.tokenOut);

        uint256[] memory amounts = IUniswapRouterV2(_uniswapV2Router).swapExactTokensForTokens(
            _params.tokenInAmount,
            _params.tokenOutAmountMin,
            _params.path,
            _params.to,
            _params.deadline
        );

        return amounts[amounts.length - 1];
    }

    function _validatePath(
        address[] memory _path,
        address _tokenIn,
        address _tokenOut
    ) internal {
        require(_path.length >= 2, "UniswapV2: Path length must be at least two");
        require(_path[0] == _tokenIn, "UniswapV2: First element of path must match token in");
        require(_path[_path.length - 1] == _tokenOut, "UniswapV2: Last element of path must match token out");
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.7.6;
pragma abicoder v2;

import { ISwapRouter } from "../interfaces/IUniswapV3SwapRouter.sol";

import { Path } from "./UniswapV3PathLib.sol";

library LibUniswapV3 {
    using Path for bytes;

    enum SwapType {
        None,
        ExactInputSingle,
        ExactInput
    }

    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    function exactInputSingle(address _uniswapV3Router, ExactInputSingleParams memory _params) internal returns (uint256 amount) {
        return
            ISwapRouter(_uniswapV3Router).exactInputSingle(
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: _params.tokenIn,
                    tokenOut: _params.tokenOut,
                    fee: _params.fee,
                    recipient: _params.recipient,
                    deadline: _params.deadline,
                    amountIn: _params.amountIn,
                    amountOutMinimum: _params.amountOutMinimum,
                    sqrtPriceLimitX96: 0
                })
            );
    }

    struct ExactInputParams {
        address tokenIn;
        address tokenOut;
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    function exactInput(address _uniswapV3Router, ExactInputParams memory _params) internal returns (uint256 amount) {
        _validatePath(_params.path, _params.tokenIn, _params.tokenOut);
        return
            ISwapRouter(_uniswapV3Router).exactInput(
                ISwapRouter.ExactInputParams({
                    path: _params.path,
                    recipient: _params.recipient,
                    deadline: _params.deadline,
                    amountIn: _params.amountIn,
                    amountOutMinimum: _params.amountOutMinimum
                })
            );
    }

    function _validatePath(
        bytes memory _path,
        address _tokenIn,
        address _tokenOut
    ) internal {
        (address tokenA, address tokenB, ) = _path.decodeFirstPool();

        if (_path.hasMultiplePools()) {
            _path = _path.skipToken();
            while (_path.hasMultiplePools()) {
                _path = _path.skipToken();
            }
            (, tokenB, ) = _path.decodeFirstPool();
        }

        require(tokenA == _tokenIn, "UniswapV3: first element of path must match token in");
        require(tokenB == _tokenOut, "UniswapV3: last element of path must match token out");
    }
}

pragma solidity ^0.7.6;

library LibOrderStorage {
    bytes32 private constant STORAGE_SLOT = 0x341a85fd45142738553ca9f88acd66d751d05662e7332a1dd940f22830435fb4;
    /// @dev Storage bucket for this feature.
    struct Storage {
        // How much taker token has been filled in order.
        mapping(bytes32 => uint256) orderHashToTakerTokenFilledAmount;
        // Whether order is cancelled or not.
        mapping(bytes32 => bool) orderHashToCancelled;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        assert(STORAGE_SLOT == bytes32(uint256(keccak256("limitorder.order.storage")) - 1));

        // Dip into assembly to change the slot pointed to by the local
        // variable `stor`.
        // See https://solidity.readthedocs.io/en/v0.6.8/assembly.html?highlight=slot#access-to-external-variables-functions-and-libraries
        assembly {
            stor.slot := STORAGE_SLOT
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/ILimitOrder.sol";

library LimitOrderLibEIP712 {
    struct Order {
        IERC20 makerToken;
        IERC20 takerToken;
        uint256 makerTokenAmount;
        uint256 takerTokenAmount;
        address maker;
        address taker;
        uint256 salt;
        uint64 expiry;
    }

    /*
        keccak256(
            abi.encodePacked(
                "Order(",
                "address makerToken,",
                "address takerToken,",
                "uint256 makerTokenAmount,",
                "uint256 takerTokenAmount,",
                "address maker,",
                "address taker,",
                "uint256 salt,",
                "uint64 expiry",
                ")"
            )
        );
    */
    uint256 private constant ORDER_TYPEHASH = 0x025174f0ee45736f4e018e96c368bd4baf3dce8d278860936559209f568c8ecb;

    function _getOrderStructHash(Order memory _order) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ORDER_TYPEHASH,
                    address(_order.makerToken),
                    address(_order.takerToken),
                    _order.makerTokenAmount,
                    _order.takerTokenAmount,
                    _order.maker,
                    _order.taker,
                    _order.salt,
                    _order.expiry
                )
            );
    }

    struct Fill {
        bytes32 orderHash; // EIP712 hash
        address taker;
        address recipient;
        uint256 takerTokenAmount;
        uint256 takerSalt;
        uint64 expiry;
    }

    /*
        keccak256(
            abi.encodePacked(
                "Fill(",
                "bytes32 orderHash,",
                "address taker,",
                "address recipient,",
                "uint256 takerTokenAmount,",
                "uint256 takerSalt,",
                "uint64 expiry",
                ")"
            )
        );
    */
    uint256 private constant FILL_TYPEHASH = 0x4ef294060cea2f973f7fe2a6d78624328586118efb1c4d640855aac3ba70e9c9;

    function _getFillStructHash(Fill memory _fill) internal pure returns (bytes32) {
        return keccak256(abi.encode(FILL_TYPEHASH, _fill.orderHash, _fill.taker, _fill.recipient, _fill.takerTokenAmount, _fill.takerSalt, _fill.expiry));
    }

    struct AllowFill {
        bytes32 orderHash; // EIP712 hash
        address executor;
        uint256 fillAmount;
        uint256 salt;
        uint64 expiry;
    }

    /*
        keccak256(abi.encodePacked("AllowFill(", "bytes32 orderHash,", "address executor,", "uint256 fillAmount,", "uint256 salt,", "uint64 expiry", ")"));
    */
    uint256 private constant ALLOW_FILL_TYPEHASH = 0xa471a3189b88889758f25ee2ce05f58964c40b03edc9cc9066079fd2b547f074;

    function _getAllowFillStructHash(AllowFill memory _allowFill) internal pure returns (bytes32) {
        return keccak256(abi.encode(ALLOW_FILL_TYPEHASH, _allowFill.orderHash, _allowFill.executor, _allowFill.fillAmount, _allowFill.salt, _allowFill.expiry));
    }
}

pragma solidity 0.7.6;

import "../interfaces/IERC1271Wallet.sol";
import "./LibBytes.sol";

interface IWallet {
    /// @dev Verifies that a signature is valid.
    /// @param hash Message hash that is signed.
    /// @param signature Proof of signing.
    /// @return isValid Validity of order signature.
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bool isValid);
}

/**
 * @dev Contains logic for signature validation.
 * Signatures from wallet contracts assume ERC-1271 support (https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1271.md)
 * Notes: Methods are strongly inspired by contracts in https://github.com/0xProject/0x-monorepo/blob/development/
 */
contract SignatureValidator {
    using LibBytes for bytes;

    /***********************************|
  |             Variables             |
  |__________________________________*/

    // bytes4(keccak256("isValidSignature(bytes,bytes)"))
    bytes4 internal constant ERC1271_MAGICVALUE = 0x20c13b0b;

    // bytes4(keccak256("isValidSignature(bytes32,bytes)"))
    bytes4 internal constant ERC1271_MAGICVALUE_BYTES32 = 0x1626ba7e;

    // keccak256("isValidWalletSignature(bytes32,address,bytes)")
    bytes4 internal constant ERC1271_FALLBACK_MAGICVALUE_BYTES32 = 0xb0671381;

    // Allowed signature types.
    enum SignatureType {
        Illegal, // 0x00, default value
        Invalid, // 0x01
        EIP712, // 0x02
        EthSign, // 0x03
        WalletBytes, // 0x04  standard 1271 wallet type
        WalletBytes32, // 0x05  standard 1271 wallet type
        Wallet, // 0x06  0x wallet type for signature compatibility
        NSignatureTypes // 0x07, number of signature types. Always leave at end.
    }

    /***********************************|
  |        Signature Functions        |
  |__________________________________*/

    /**
     * @dev Verifies that a hash has been signed by the given signer.
     * @param _signerAddress  Address that should have signed the given hash.
     * @param _hash           Hash of the EIP-712 encoded data
     * @param _data           Full EIP-712 data structure that was hashed and signed
     * @param _sig            Proof that the hash has been signed by signer.
     *      For non wallet signatures, _sig is expected to be an array tightly encoded as
     *      (bytes32 r, bytes32 s, uint8 v, uint256 nonce, SignatureType sigType)
     * @return isValid True if the address recovered from the provided signature matches the input signer address.
     */
    function isValidSignature(
        address _signerAddress,
        bytes32 _hash,
        bytes memory _data,
        bytes memory _sig
    ) public view returns (bool isValid) {
        require(_sig.length > 0, "SignatureValidator#isValidSignature: length greater than 0 required");

        require(_signerAddress != address(0x0), "SignatureValidator#isValidSignature: invalid signer");

        // Pop last byte off of signature byte array.
        uint8 signatureTypeRaw = uint8(_sig.popLastByte());

        // Ensure signature is supported
        require(signatureTypeRaw < uint8(SignatureType.NSignatureTypes), "SignatureValidator#isValidSignature: unsupported signature");

        // Extract signature type
        SignatureType signatureType = SignatureType(signatureTypeRaw);

        // Variables are not scoped in Solidity.
        uint8 v;
        bytes32 r;
        bytes32 s;
        address recovered;

        // Always illegal signature.
        // This is always an implicit option since a signer can create a
        // signature array with invalid type or length. We may as well make
        // it an explicit option. This aids testing and analysis. It is
        // also the initialization value for the enum type.
        if (signatureType == SignatureType.Illegal) {
            revert("SignatureValidator#isValidSignature: illegal signature");

            // Signature using EIP712
        } else if (signatureType == SignatureType.EIP712) {
            require(_sig.length == 97, "SignatureValidator#isValidSignature: length 97 required");
            r = _sig.readBytes32(0);
            s = _sig.readBytes32(32);
            v = uint8(_sig[64]);
            recovered = ecrecover(_hash, v, r, s);
            isValid = _signerAddress == recovered;
            return isValid;

            // Signed using web3.eth_sign() or Ethers wallet.signMessage()
        } else if (signatureType == SignatureType.EthSign) {
            require(_sig.length == 97, "SignatureValidator#isValidSignature: length 97 required");
            r = _sig.readBytes32(0);
            s = _sig.readBytes32(32);
            v = uint8(_sig[64]);
            recovered = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)), v, r, s);
            isValid = _signerAddress == recovered;
            return isValid;

            // Signature verified by wallet contract with data validation.
        } else if (signatureType == SignatureType.WalletBytes) {
            isValid = ERC1271_MAGICVALUE == IERC1271Wallet(_signerAddress).isValidSignature(_data, _sig);
            return isValid;

            // Signature verified by wallet contract without data validation.
        } else if (signatureType == SignatureType.WalletBytes32) {
            isValid = ERC1271_MAGICVALUE_BYTES32 == IERC1271Wallet(_signerAddress).isValidSignature(_hash, _sig);
            return isValid;
        } else if (signatureType == SignatureType.Wallet) {
            isValid = isValidWalletSignature(_hash, _signerAddress, _sig);
            return isValid;
        }

        // Anything else is illegal (We do not return false because
        // the signature may actually be valid, just not in a format
        // that we currently support. In this case returning false
        // may lead the caller to incorrectly believe that the
        // signature was invalid.)
        revert("SignatureValidator#isValidSignature: unsupported signature");
    }

    /// @dev Verifies signature using logic defined by Wallet contract.
    /// @param hash Any 32 byte hash.
    /// @param walletAddress Address that should have signed the given hash
    ///                      and defines its own signature verification method.
    /// @param signature Proof that the hash has been signed by signer.
    /// @return isValid True if signature is valid for given wallet..
    function isValidWalletSignature(
        bytes32 hash,
        address walletAddress,
        bytes memory signature
    ) internal view returns (bool isValid) {
        bytes memory _calldata = abi.encodeWithSelector(IWallet(walletAddress).isValidSignature.selector, hash, signature);
        bytes32 magic_salt = bytes32(bytes4(keccak256("isValidWalletSignature(bytes32,address,bytes)")));
        assembly {
            if iszero(extcodesize(walletAddress)) {
                // Revert with `Error("WALLET_ERROR")`
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
                mstore(64, 0x0000000c57414c4c45545f4552524f5200000000000000000000000000000000)
                mstore(96, 0)
                revert(0, 100)
            }

            let cdStart := add(_calldata, 32)
            let success := staticcall(
                gas(), // forward all gas
                walletAddress, // address of Wallet contract
                cdStart, // pointer to start of input
                mload(_calldata), // length of input
                cdStart, // write output over input
                32 // output size is 32 bytes
            )

            if iszero(eq(returndatasize(), 32)) {
                // Revert with `Error("WALLET_ERROR")`
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
                mstore(64, 0x0000000c57414c4c45545f4552524f5200000000000000000000000000000000)
                mstore(96, 0)
                revert(0, 100)
            }

            switch success
            case 0 {
                // Revert with `Error("WALLET_ERROR")`
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
                mstore(64, 0x0000000c57414c4c45545f4552524f5200000000000000000000000000000000)
                mstore(96, 0)
                revert(0, 100)
            }
            case 1 {
                // Signature is valid if call did not revert and returned true
                isValid := eq(
                    and(mload(cdStart), 0xffffffff00000000000000000000000000000000000000000000000000000000),
                    and(magic_salt, 0xffffffff00000000000000000000000000000000000000000000000000000000)
                )
            }
        }
        return isValid;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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
pragma solidity >=0.7.0;

interface IUniswapRouterV2 {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.0;
pragma abicoder v2;

import "./IUniswapV3SwapCallback.sol";

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.0;

library BytesLib {
    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_start + _length >= _start, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_start + 20 >= _start, "toAddress_overflow");
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint24(bytes memory _bytes, uint256 _start) internal pure returns (uint24) {
        require(_start + 3 >= _start, "toUint24_overflow");
        require(_bytes.length >= _start + 3, "toUint24_outOfBounds");
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }

        return tempUint;
    }
}

/// @title Functions for manipulating path data for multihop swaps
library Path {
    using BytesLib for bytes;

    /// @dev The length of the bytes encoded address
    uint256 private constant ADDR_SIZE = 20;
    /// @dev The length of the bytes encoded fee
    uint256 private constant FEE_SIZE = 3;

    /// @dev The offset of a single token address and pool fee
    uint256 private constant NEXT_OFFSET = ADDR_SIZE + FEE_SIZE;
    /// @dev The offset of an encoded pool key
    uint256 private constant POP_OFFSET = NEXT_OFFSET + ADDR_SIZE;
    /// @dev The minimum length of an encoding that contains 2 or more pools
    uint256 private constant MULTIPLE_POOLS_MIN_LENGTH = POP_OFFSET + NEXT_OFFSET;

    /// @notice Returns true iff the path contains two or more pools
    /// @param path The encoded swap path
    /// @return True if path contains two or more pools, otherwise false
    function hasMultiplePools(bytes memory path) internal pure returns (bool) {
        return path.length >= MULTIPLE_POOLS_MIN_LENGTH;
    }

    /// @notice Decodes the first pool in path
    /// @param path The bytes encoded swap path
    /// @return tokenA The first token of the given pool
    /// @return tokenB The second token of the given pool
    /// @return fee The fee level of the pool
    function decodeFirstPool(bytes memory path)
        internal
        pure
        returns (
            address tokenA,
            address tokenB,
            uint24 fee
        )
    {
        tokenA = path.toAddress(0);
        fee = path.toUint24(ADDR_SIZE);
        tokenB = path.toAddress(NEXT_OFFSET);
    }

    /// @notice Skips a token + fee element from the buffer and returns the remainder
    /// @param path The swap path
    /// @return The remaining token + fee elements in the path
    function skipToken(bytes memory path) internal pure returns (bytes memory) {
        return path.slice(NEXT_OFFSET, path.length - NEXT_OFFSET);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

pragma solidity >=0.7.0;

interface IERC1271Wallet {
    /**
     * @notice Verifies whether the provided signature is valid with respect to the provided data
     * @dev MUST return the correct magic value if the signature provided is valid for the provided data
     *   > The bytes4 magic value to return when signature is valid is 0x20c13b0b : bytes4(keccak256("isValidSignature(bytes,bytes)")
     *   > This function MAY modify Ethereum's state
     * @param _data       Arbitrary length data signed on the behalf of address(this)
     * @param _signature  Signature byte array associated with _data
     * @return magicValue Magic value 0x20c13b0b if the signature is valid and 0x0 otherwise
     *
     */
    function isValidSignature(bytes calldata _data, bytes calldata _signature) external view returns (bytes4 magicValue);

    /**
     * @notice Verifies whether the provided signature is valid with respect to the provided hash
     * @dev MUST return the correct magic value if the signature provided is valid for the provided hash
     *   > The bytes4 magic value to return when signature is valid is 0x20c13b0b : bytes4(keccak256("isValidSignature(bytes,bytes)")
     *   > This function MAY modify Ethereum's state
     * @param _hash       keccak256 hash that was signed
     * @param _signature  Signature byte array associated with _data
     * @return magicValue Magic value 0x20c13b0b if the signature is valid and 0x0 otherwise
     */
    function isValidSignature(bytes32 _hash, bytes calldata _signature) external view returns (bytes4 magicValue);
}

/*
  Copyright 2018 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
  http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
  This is a truncated version of the original LibBytes.sol library from ZeroEx.
*/

pragma solidity ^0.7.6;

library LibBytes {
    using LibBytes for bytes;

    /***********************************|
  |        Pop Bytes Functions        |
  |__________________________________*/

    /**
     * @dev Pops the last byte off of a byte array by modifying its length.
     * @param b Byte array that will be modified.
     * @return result The byte that was popped off.
     */
    function popLastByte(bytes memory b) internal pure returns (bytes1 result) {
        require(b.length > 0, "LibBytes#popLastByte: greater than zero length required");

        // Store last byte.
        result = b[b.length - 1];

        assembly {
            // Decrement length of byte array.
            let newLen := sub(mload(b), 1)
            mstore(b, newLen)
        }
        return result;
    }

    /// @dev Reads an address from a position in a byte array.
    /// @param b Byte array containing an address.
    /// @param index Index in byte array of address.
    /// @return result address from byte array.
    function readAddress(bytes memory b, uint256 index) internal pure returns (address result) {
        require(
            b.length >= index + 20, // 20 is length of address
            "LibBytes#readAddress greater or equal to 20 length required"
        );

        // Add offset to index:
        // 1. Arrays are prefixed by 32-byte length parameter (add 32 to index)
        // 2. Account for size difference between address length and 32-byte storage word (subtract 12 from index)
        index += 20;

        // Read address from array memory
        assembly {
            // 1. Add index to address of bytes array
            // 2. Load 32-byte word from memory
            // 3. Apply 20-byte mask to obtain address
            result := and(mload(add(b, index)), 0xffffffffffffffffffffffffffffffffffffffff)
        }
        return result;
    }

    /***********************************|
  |        Read Bytes Functions       |
  |__________________________________*/

    /**
     * @dev Reads a bytes32 value from a position in a byte array.
     * @param b Byte array containing a bytes32 value.
     * @param index Index in byte array of bytes32 value.
     * @return result bytes32 value from byte array.
     */
    function readBytes32(bytes memory b, uint256 index) internal pure returns (bytes32 result) {
        require(b.length >= index + 32, "LibBytes#readBytes32 greater or equal to 32 length required");

        // Arrays are prefixed by a 256 bit length parameter
        index += 32;

        // Read the bytes32 from array memory
        assembly {
            result := mload(add(b, index))
        }
        return result;
    }

    /// @dev Reads an unpadded bytes4 value from a position in a byte array.
    /// @param b Byte array containing a bytes4 value.
    /// @param index Index in byte array of bytes4 value.
    /// @return result bytes4 value from byte array.
    function readBytes4(bytes memory b, uint256 index) internal pure returns (bytes4 result) {
        require(b.length >= index + 4, "LibBytes#readBytes4 greater or equal to 4 length required");

        // Arrays are prefixed by a 32 byte length field
        index += 32;

        // Read the bytes4 from array memory
        assembly {
            result := mload(add(b, index))
            // Solidity does not require us to clean the trailing bytes.
            // We do it anyway
            result := and(result, 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000)
        }
        return result;
    }

    function readBytes2(bytes memory b, uint256 index) internal pure returns (bytes2 result) {
        require(b.length >= index + 2, "LibBytes#readBytes2 greater or equal to 2 length required");

        // Arrays are prefixed by a 32 byte length field
        index += 32;

        // Read the bytes4 from array memory
        assembly {
            result := mload(add(b, index))
            // Solidity does not require us to clean the trailing bytes.
            // We do it anyway
            result := and(result, 0xFFFF000000000000000000000000000000000000000000000000000000000000)
        }
        return result;
    }
}