// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./libraries/TransferHelper.sol";
import "./DelegateInterface.sol";
import "./Adminable.sol";
import "./IOPLimitOrder.sol";

contract OPLimitOrder is DelegateInterface, Adminable, ReentrancyGuard, EIP712("OpenLeverage Limit Order", "1"), IOPLimitOrder, OPLimitOrderStorage {
    using TransferHelper for IERC20;

    uint256 private constant MILLION = 10**6;
    uint256 private constant DECIMAL = 24;

    uint32 private constant TWAP = 60; // seconds

    uint256 private constant _ORDER_DOES_NOT_EXIST = 0;
    uint256 private constant _ORDER_FILLED = 1;

    /// @notice Stores unfilled amounts for each order plus one.
    /// Therefore "0" means order doesn't exist and "1" means order has been filled
    mapping(bytes32 => uint256) private _remaining;

    function initialize(OpenLevInterface _openLev, DexAggregatorInterface _dexAgg) external {
        require(msg.sender == admin, "NAD");
        require(address(openLev) == address(0), "IOC");
        openLev = _openLev;
        dexAgg = _dexAgg;
    }

    /// @notice Fills open order
    /// @param order Order quote to fill
    /// @param signature Signature to confirm quote ownership
    /// @param fillingDeposit the deposit amount to margin trade
    /// @param dexData The dex data for openLev
    /// @dev Successful execution requires two conditions at least
    ///1. The real-time price is lower than the buying price
    ///2. The increased position held is greater than expect held
    function fillOpenOrder(
        OpenOrder memory order,
        bytes calldata signature,
        uint256 fillingDeposit,
        bytes calldata dexData
    ) external override nonReentrant {
        require(block.timestamp <= order.deadline, "EXR");
        bytes32 orderId = _openOrderId(order);
        uint256 remainingDeposit = _remaining[orderId];
        require(remainingDeposit != _ORDER_FILLED, "RD0");
        if (remainingDeposit == _ORDER_DOES_NOT_EXIST) {
            remainingDeposit = order.deposit;
        } else {
            --remainingDeposit;
        }
        require(fillingDeposit <= remainingDeposit, "FTB");
        require(SignatureChecker.isValidSignatureNow(order.owner, _hashOpenOrder(order), signature), "SNE");

        uint256 fillingRatio = (fillingDeposit * MILLION) / order.deposit;
        require(fillingRatio > 0, "FR0");

        OpenLevInterface.Market memory market = openLev.markets(order.marketId);
        // long token0 price lower than price0 or long token1 price higher than price0
        uint256 price = _getPrice(market.token0, market.token1, dexData);
        require((!order.longToken && price <= order.price0) || (order.longToken && price >= order.price0), "PRE");

        IERC20 depositToken = IERC20(order.depositToken ? market.token1 : market.token0);
        uint256 actualDepositAmount = depositToken.safeTransferFrom(order.owner, address(this), fillingDeposit);
        depositToken.safeApprove(address(openLev), actualDepositAmount);

        // check that increased position is greater than expected increased held
        require(_marginTrade(order, actualDepositAmount, fillingRatio, dexData) * MILLION >= order.expectHeld * fillingRatio, "NEG");

        uint256 commission = (order.commission * fillingRatio) / MILLION;
        if (commission > 0) {
            // fix stack too deep
            IERC20 _commissionToken = IERC20(order.commissionToken);
            _commissionToken.safeTransferFrom(order.owner, msg.sender, commission);
        }
        remainingDeposit = remainingDeposit - fillingDeposit;
        emit OrderFilled(msg.sender, orderId, commission, remainingDeposit, fillingDeposit);
        _remaining[orderId] = remainingDeposit + 1;
    }

    /// @notice Fills close order
    /// @param order Order quote to fill
    /// @param signature Signature to confirm quote ownership
    /// @param closeAmount the position held to close trade
    /// @param dexData The dex data for openLev
    /// @dev Successful execution requires two conditions at least
    ///1. Take profit order: the real-time price is higher than the selling price, or
    ///2. Stop loss order: the TWAP price is lower than the selling price
    ///3. The deposit return is greater than expect return
    function fillCloseOrder(
        CloseOrder memory order,
        bytes calldata signature,
        uint256 closeAmount,
        bytes memory dexData
    ) external override nonReentrant {
        require(block.timestamp <= order.deadline, "EXR");
        bytes32 orderId = _closeOrderId(order);
        uint256 remainingHeld = _remaining[orderId];
        require(remainingHeld != _ORDER_FILLED, "RD0");
        if (remainingHeld == _ORDER_DOES_NOT_EXIST) {
            remainingHeld = order.closeHeld;
        } else {
            --remainingHeld;
        }
        require(closeAmount <= remainingHeld, "FTB");
        require(SignatureChecker.isValidSignatureNow(order.owner, _hashCloseOrder(order), signature), "SNE");

        uint256 fillingRatio = (closeAmount * MILLION) / order.closeHeld;
        require(fillingRatio > 0, "FR0");
        OpenLevInterface.Market memory market = openLev.markets(order.marketId);

        // take profit
        if (!order.isStopLoss) {
            uint256 price = _getPrice(market.token0, market.token1, dexData);
            // long token0: price needs to be higher than price0
            // long token1: price needs to be lower than price0
            require((!order.longToken && price >= order.price0) || (order.longToken && price <= order.price0), "PRE");
        }
        // stop loss
        else {
            openLev.updatePrice(order.marketId, dexData);
            (uint256 price, uint256 cAvgPrice, uint256 hAvgPrice) = _getTwapPrice(market.token0, market.token1, dexData);
            require(
                (!order.longToken && (price <= order.price0 && cAvgPrice <= order.price0 && hAvgPrice <= order.price0)) ||
                    (order.longToken && (price >= order.price0 && cAvgPrice >= order.price0 && hAvgPrice >= order.price0)),
                "UPF"
            );
        }

        uint256 depositReturn = _closeTrade(order, closeAmount, dexData);
        // check that deposit return is greater than expect return
        require(depositReturn * MILLION >= order.expectReturn * fillingRatio, "NEG");

        uint256 commission = (order.commission * fillingRatio) / MILLION;
        if (commission > 0) {
            IERC20(order.commissionToken).safeTransferFrom(order.owner, msg.sender, commission);
        }

        remainingHeld = remainingHeld - closeAmount;
        emit OrderFilled(msg.sender, orderId, commission, remainingHeld, closeAmount);
        _remaining[orderId] = remainingHeld + 1;
    }

    /// @notice Close trade and cancels stopLoss or takeProfit orders by owner
    function closeTradeAndCancel(
        uint16 marketId,
        bool longToken,
        uint256 closeHeld,
        uint256 minOrMaxAmount,
        bytes memory dexData,
        OPLimitOrderStorage.Order[] memory orders
    ) external override nonReentrant {
        openLev.closeTradeFor(msg.sender, marketId, longToken, closeHeld, minOrMaxAmount, dexData);
        for (uint256 i = 0; i < orders.length; i++) {
            _cancelOrder(orders[i]);
        }
    }

    /// @notice Cancels order by setting remaining amount to zero
    function cancelOrder(Order memory order) external override {
        _cancelOrder(order);
    }

    /// @notice Same as `cancelOrder` but for multiple orders
    function cancelOrders(Order[] calldata orders) external override {
        for (uint256 i = 0; i < orders.length; i++) {
            _cancelOrder(orders[i]);
        }
    }

    /// @notice Returns unfilled amount for order. Throws if order does not exist
    function remaining(bytes32 _orderId) external view override returns (uint256) {
        uint256 amount = _remaining[_orderId];
        require(amount != _ORDER_DOES_NOT_EXIST, "UKO");
        amount -= 1;
        return amount;
    }

    /// @notice Returns unfilled amount for order
    /// @return Result Unfilled amount of order plus one if order exists. Otherwise 0
    function remainingRaw(bytes32 _orderId) external view override returns (uint256) {
        return _remaining[_orderId];
    }

    /// @notice Returns the order id
    function getOrderId(Order memory order) external view override returns (bytes32) {
        return _getOrderId(order);
    }

    /// @notice Returns the open order hash
    function hashOpenOrder(OPLimitOrderStorage.OpenOrder memory order) external view override returns (bytes32) {
        return _hashOpenOrder(order);
    }

    /// @notice Returns the close order hash
    function hashCloseOrder(OPLimitOrderStorage.CloseOrder memory order) external view override returns (bytes32) {
        return _hashCloseOrder(order);
    }

    function _cancelOrder(Order memory order) internal {
        require(order.owner == msg.sender, "OON");
        bytes32 orderId = _getOrderId(order);
        uint256 orderRemaining = _remaining[orderId];
        require(orderRemaining != _ORDER_FILLED, "ALF");
        emit OrderCanceled(msg.sender, orderId, orderRemaining);
        _remaining[orderId] = _ORDER_FILLED;
    }

    /// @notice Call openLev to margin trade. returns the position held increasement.
    function _marginTrade(
        OPLimitOrderStorage.OpenOrder memory order,
        uint256 fillingDeposit,
        uint256 fillingRatio,
        bytes memory dexData
    ) internal returns (uint256) {
        return
            openLev.marginTradeFor(
                order.owner,
                order.marketId,
                order.longToken,
                order.depositToken,
                fillingDeposit,
                (order.borrow * fillingRatio) / MILLION,
                0,
                dexData
            );
    }

    /// @notice Call openLev to close trade. returns the deposit token amount back.
    function _closeTrade(
        OPLimitOrderStorage.CloseOrder memory order,
        uint256 fillingHeld,
        bytes memory dexData
    ) internal returns (uint256) {
        return
            openLev.closeTradeFor(
                order.owner,
                order.marketId,
                order.longToken,
                fillingHeld,
                order.longToken == order.depositToken ? type(uint256).max : 0,
                dexData
            );
    }

    /// @notice Returns the twap price from dex aggregator.
    function _getTwapPrice(
        address token0,
        address token1,
        bytes memory dexData
    )
        internal
        view
        returns (
            uint256 price,
            uint256 cAvgPrice,
            uint256 hAvgPrice
        )
    {
        uint8 decimals;
        uint256 lastUpdateTime;
        (price, cAvgPrice, hAvgPrice, decimals, lastUpdateTime) = dexAgg.getPriceCAvgPriceHAvgPrice(token0, token1, TWAP, dexData);
        //ignore hAvgPrice
        if (block.timestamp >= lastUpdateTime + TWAP) {
            hAvgPrice = cAvgPrice;
        }
        if (decimals < DECIMAL) {
            price = price * (10 ** (DECIMAL - decimals));
            cAvgPrice = cAvgPrice * (10 ** (DECIMAL - decimals));
            hAvgPrice = hAvgPrice * (10 ** (DECIMAL - decimals));
        } else {
            price = price / (10 ** (decimals - DECIMAL));
            cAvgPrice = cAvgPrice / (10 ** (decimals - DECIMAL));
            hAvgPrice = hAvgPrice / (10 ** (decimals - DECIMAL));
        }
    }

    /// @notice Returns the real price from dex aggregator.
    function _getPrice(
        address token0,
        address token1,
        bytes memory dexData
    ) internal view returns (uint256 price) {
        uint8 decimals;
        (price, decimals) = dexAgg.getPrice(token0, token1, dexData);
        if (decimals < DECIMAL) {
            price = price * (10 ** (DECIMAL - decimals));
        } else {
            price = price / (10 ** (decimals - DECIMAL));
        }
    }

    function _getOrderId(Order memory order) internal view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(ORDER_TYPEHASH, order)));
    }

    function _openOrderId(OpenOrder memory openOrder) internal view returns (bytes32) {
        Order memory order;
        assembly {
            // solhint-disable-line no-inline-assembly
            order := openOrder
        }
        return _getOrderId(order);
    }

    function _closeOrderId(CloseOrder memory closeOrder) internal view returns (bytes32) {
        Order memory order;
        assembly {
            // solhint-disable-line no-inline-assembly
            order := closeOrder
        }
        return _getOrderId(order);
    }

    function _hashOpenOrder(OpenOrder memory order) internal view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(OPEN_ORDER_TYPEHASH, order)));
    }

    function _hashCloseOrder(CloseOrder memory order) internal view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(CLOSE_ORDER_TYPEHASH, order)));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title TransferHelper
 * @dev Wrappers around ERC20 operations that returns the value received by recipent and the actual allowance of approval.
 * To use this library you can add a `using TransferHelper for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library TransferHelper {
    function safeTransfer(
        IERC20 _token,
        address _to,
        uint256 _amount
    ) internal returns (uint256 amountReceived) {
        if (_amount > 0) {
            bool success;
            uint256 balanceBefore = _token.balanceOf(_to);
            (success, ) = address(_token).call(abi.encodeWithSelector(_token.transfer.selector, _to, _amount));
            require(success, "TF");
            uint256 balanceAfter = _token.balanceOf(_to);
            require(balanceAfter > balanceBefore, "TF");
            amountReceived = balanceAfter - balanceBefore;
        }
    }

    function safeTransferFrom(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _amount
    ) internal returns (uint256 amountReceived) {
        if (_amount > 0) {
            bool success;
            uint256 balanceBefore = _token.balanceOf(_to);
            (success, ) = address(_token).call(abi.encodeWithSelector(_token.transferFrom.selector, _from, _to, _amount));
            require(success, "TFF");
            uint256 balanceAfter = _token.balanceOf(_to);
            require(balanceAfter > balanceBefore, "TFF");
            amountReceived = balanceAfter - balanceBefore;
        }
    }

    function safeApprove(
        IERC20 _token,
        address _spender,
        uint256 _amount
    ) internal returns (uint256) {
        bool success;
        if (_token.allowance(address(this), _spender) != 0) {
            (success, ) = address(_token).call(abi.encodeWithSelector(_token.approve.selector, _spender, 0));
            require(success, "AF");
        }
        (success, ) = address(_token).call(abi.encodeWithSelector(_token.approve.selector, _spender, _amount));
        require(success, "AF");

        return _token.allowance(address(this), _spender);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >0.7.6;

pragma experimental ABIEncoderV2;

/**
 * @title OpenLevInterface
 * @author OpenLeverage
 */
interface OpenLevInterface {
    struct Market {
        // Market info
        address pool0; // Lending Pool 0
        address pool1; // Lending Pool 1
        address token0; // Lending Token 0
        address token1; // Lending Token 1
        uint16 marginLimit; // Margin ratio limit for specific trading pair. Two decimal in percentage, ex. 15.32% => 1532
        uint16 feesRate; // feesRate 30=>0.3%
        uint16 priceDiffientRatio;
        address priceUpdater;
        uint256 pool0Insurance; // Insurance balance for token 0
        uint256 pool1Insurance; // Insurance balance for token 1
    }

    struct Trade {
        // Trade storage
        uint256 deposited; // Balance of deposit token
        uint256 held; // Balance of held position
        bool depositToken; // Indicate if the deposit token is token 0 or token 1
        uint128 lastBlockNum; // Block number when the trade was touched last time, to prevent more than one operation within same block
    }

    function markets(uint16 marketId) external view returns (Market memory market);

    function activeTrades(
        address trader,
        uint16 marketId,
        bool longToken
    ) external view returns (Trade memory trade);

    function updatePrice(uint16 marketId, bytes memory dexData) external;

    function marginTradeFor(
        address trader,
        uint16 marketId,
        bool longToken,
        bool depositToken,
        uint256 deposit,
        uint256 borrow,
        uint256 minBuyAmount,
        bytes memory dexData
    ) external payable returns (uint256 newHeld);

    function closeTradeFor(
        address trader,
        uint16 marketId,
        bool longToken,
        uint256 closeHeld,
        uint256 minOrMaxAmount,
        bytes memory dexData
    ) external returns (uint256 depositReturn);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >0.7.6;
pragma experimental ABIEncoderV2;

interface DexAggregatorInterface {
    function getPrice(
        address desToken,
        address quoteToken,
        bytes memory data
    ) external view returns (uint256 price, uint8 decimals);

    function getPriceCAvgPriceHAvgPrice(
        address desToken,
        address quoteToken,
        uint32 secondsAgo,
        bytes memory dexData
    )
        external
        view
        returns (
            uint256 price,
            uint256 cAvgPrice,
            uint256 hAvgPrice,
            uint8 decimals,
            uint256 timestamp
        );

    function updatePriceOracle(
        address desToken,
        address quoteToken,
        uint32 timeWindow,
        bytes memory data
    ) external returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

import "./interfaces/DexAggregatorInterface.sol";
import "./interfaces/OpenLevInterface.sol";
import "./IOPLimitOrder.sol";

abstract contract OPLimitOrderStorage {
    event OrderCanceled(address indexed trader, bytes32 orderId, uint256 remaining);

    event OrderFilled(address indexed trader, bytes32 orderId, uint256 commission, uint256 remaining, uint256 filling);

    struct Order {
        uint256 salt;
        address owner;
        uint32 deadline;
        uint16 marketId;
        bool longToken;
        bool depositToken;
        address commissionToken;
        uint256 commission;
        uint256 price0; // tokanA-tokenB pair, the price of tokenA relative to tokenB, scale 10**24.
    }

    struct OpenOrder {
        uint256 salt;
        address owner;
        uint32 deadline; // in seconds
        uint16 marketId;
        bool longToken;
        bool depositToken;
        address commissionToken;
        uint256 commission;
        uint256 price0;
        uint256 deposit; // the deposit amount for margin trade.
        uint256 borrow; // the borrow amount for margin trade.
        uint256 expectHeld; // the minimum position held after the order gets fully filled.
    }

    struct CloseOrder {
        uint256 salt;
        address owner;
        uint32 deadline;
        uint16 marketId;
        bool longToken;
        bool depositToken;
        address commissionToken;
        uint256 commission;
        uint256 price0;
        bool isStopLoss; // true = stopLoss, false = takeProfit.
        uint256 closeHeld; // how many position will be closed.
        uint256 expectReturn; // the minimum deposit returns after gets filled.
    }

    bytes32 public constant ORDER_TYPEHASH =
        keccak256(
            "Order(uint256 salt,address owner,uint32 deadline,uint16 marketId,bool longToken,bool depositToken,address commissionToken,uint256 commission,uint256 price0)"
        );
    bytes32 public constant OPEN_ORDER_TYPEHASH =
        keccak256(
            "OpenOrder(uint256 salt,address owner,uint32 deadline,uint16 marketId,bool longToken,bool depositToken,address commissionToken,uint256 commission,uint256 price0,uint256 deposit,uint256 borrow,uint256 expectHeld)"
        );
    bytes32 public constant CLOSE_ORDER_TYPEHASH =
        keccak256(
            "CloseOrder(uint256 salt,address owner,uint32 deadline,uint16 marketId,bool longToken,bool depositToken,address commissionToken,uint256 commission,uint256 price0,bool isStopLoss,uint256 closeHeld,uint256 expectReturn)"
        );

    OpenLevInterface public openLev;
    DexAggregatorInterface public dexAgg;
}

interface IOPLimitOrder {
    function fillOpenOrder(
        OPLimitOrderStorage.OpenOrder memory order,
        bytes calldata signature,
        uint256 fillingDeposit,
        bytes memory dexData
    ) external;

    function fillCloseOrder(
        OPLimitOrderStorage.CloseOrder memory order,
        bytes calldata signature,
        uint256 fillingHeld,
        bytes memory dexData
    ) external;

    function closeTradeAndCancel(
        uint16 marketId,
        bool longToken,
        uint256 closeHeld,
        uint256 minOrMaxAmount,
        bytes memory dexData,
        OPLimitOrderStorage.Order[] memory orders
    ) external;

    function cancelOrder(OPLimitOrderStorage.Order memory order) external;

    function cancelOrders(OPLimitOrderStorage.Order[] calldata orders) external;

    function remaining(bytes32 _orderId) external view returns (uint256);

    function remainingRaw(bytes32 _orderId) external view returns (uint256);

    function getOrderId(OPLimitOrderStorage.Order memory order) external view returns (bytes32);

    function hashOpenOrder(OPLimitOrderStorage.OpenOrder memory order) external view returns (bytes32);

    function hashCloseOrder(OPLimitOrderStorage.CloseOrder memory order) external view returns (bytes32);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >0.7.6;

contract DelegateInterface {
    /**
     * Implementation address for this contract
     */
    address public implementation;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >0.7.6;

abstract contract Adminable {
    address payable public admin;
    address payable public pendingAdmin;
    address payable public developer;

    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    event NewAdmin(address oldAdmin, address newAdmin);

    constructor() {
        developer = payable(msg.sender);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "caller must be admin");
        _;
    }
    modifier onlyAdminOrDeveloper() {
        require(msg.sender == admin || msg.sender == developer, "caller must be admin or developer");
        _;
    }

    function setPendingAdmin(address payable newPendingAdmin) external virtual onlyAdmin {
        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = pendingAdmin;
        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;
        // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);
    }

    function acceptAdmin() external virtual {
        require(msg.sender == pendingAdmin, "only pendingAdmin can accept admin");
        // Save current values for inclusion in log
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;
        // Store admin with value pendingAdmin
        admin = payable(oldPendingAdmin);
        // Clear the pending value
        pendingAdmin = payable(0);
        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.1) (utils/cryptography/SignatureChecker.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "../Address.sol";
import "../../interfaces/IERC1271.sol";

/**
 * @dev Signature verification helper that can be used instead of `ECDSA.recover` to seamlessly support both ECDSA
 * signatures from externally owned accounts (EOAs) as well as ERC1271 signatures from smart contract wallets like
 * Argent and Gnosis Safe.
 *
 * _Available since v4.1._
 */
library SignatureChecker {
    /**
     * @dev Checks if a signature is valid for a given signer and data hash. If the signer is a smart contract, the
     * signature is validated against that smart contract using ERC1271, otherwise it's validated using `ECDSA.recover`.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
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
        return (success &&
            result.length == 32 &&
            abi.decode(result, (bytes32)) == bytes32(IERC1271.isValidSignature.selector));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

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