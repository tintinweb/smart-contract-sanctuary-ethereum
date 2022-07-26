// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";

import "./libraries/BP.sol";
import "./libraries/FullMath.sol";
import "./libraries/FixedPoint112.sol";

import "./interfaces/IvToken.sol";
import "./interfaces/IIndex.sol";
import "./interfaces/IOrderer.sol";
import "./interfaces/IOrdererV2.sol";
import "./interfaces/IvTokenFactory.sol";
import "./interfaces/IIndexRegistry.sol";
import "./interfaces/IReweightableIndex.sol";
import "./interfaces/IPhuturePriceOracle.sol";

/// @title Orderer
/// @notice Contains logic for reweigh execution, order creation and execution
contract Orderer is IOrderer, IOrdererV2, UUPSUpgradeable, ERC165Upgradeable {
    using FullMath for uint;
    using ERC165CheckerUpgradeable for address;
    using SafeERC20 for IERC20;

    /// @notice Order details structure containing assets list, creator address, creation timestamp and assetDetails
    struct OrderDetails {
        uint creationTimestamp;
        address creator;
        address[] assets;
        mapping(address => AssetDetails) assetDetails;
    }

    /// @notice Asset details structure containing order side (buy/sell) and order shares amount
    struct AssetDetails {
        OrderSide side;
        uint248 shares;
    }

    struct SwapDetails {
        address sellAsset;
        address buyAsset;
        IvToken sellVToken;
        IvToken buyVToken;
        IPhuturePriceOracle priceOracle;
    }

    struct InternalSwapVaultsInfo {
        address sellAccount;
        address buyAccount;
        uint maxSellShares;
        IvToken buyVTokenSellAccount;
        IvToken buyVTokenBuyAccount;
        SwapDetails details;
    }

    /// @notice Min amount in BASE to swap during burning
    uint internal constant MIN_SWAP_AMOUNT = 1_000_000;

    /// @notice Index role
    bytes32 internal constant INDEX_ROLE = keccak256("INDEX_ROLE");
    /// @notice Keeper job role
    bytes32 internal constant KEEPER_JOB_ROLE = keccak256("KEEPER_JOB_ROLE");
    /// @notice Exchange factory role
    bytes32 internal constant EXCHANGE_FACTORY_ROLE = keccak256("EXCHANGE_FACTORY_ROLE");
    /// @notice Role allows configure ordering related data/components
    bytes32 internal constant ORDERING_MANAGER_ROLE = keccak256("ORDERING_MANAGER_ROLE");

    /// @notice Last placed order id
    uint internal _lastOrderId;

    /// @notice Index registry address
    address internal registry;

    /// @inheritdoc IOrderer
    uint64 public override orderLifetime;

    /// @inheritdoc IOrderer
    uint16 public override maxAllowedPriceImpactInBP;

    /// @inheritdoc IOrdererV2
    uint16 public override maxSlippageInBP;

    /// @inheritdoc IOrderer
    mapping(address => uint) public override lastOrderIdOf;

    /// @notice Mapping of order id to order details
    mapping(uint => OrderDetails) internal orderDetailsOf;

    /// @notice Requires msg.sender to have `_role` role
    /// @param _role Required role
    modifier onlyRole(bytes32 _role) {
        require(IAccessControl(registry).hasRole(_role, msg.sender), "Orderer: FORBIDDEN");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @inheritdoc IOrdererV2
    function initialize(
        address _registry,
        uint64 _orderLifetime,
        uint16 _maxSlippageInBP
    ) external override(IOrderer, IOrdererV2) initializer {
        bytes4[] memory interfaceIds = new bytes4[](2);
        interfaceIds[0] = type(IAccessControl).interfaceId;
        interfaceIds[1] = type(IIndexRegistry).interfaceId;
        require(_registry.supportsAllInterfaces(interfaceIds), "Orderer: INTERFACE");

        __ERC165_init();
        __UUPSUpgradeable_init();

        registry = _registry;
        orderLifetime = _orderLifetime;
        maxSlippageInBP = _maxSlippageInBP;
    }

    /// @inheritdoc IOrderer
    function setMaxAllowedPriceImpactInBP(uint16 _maxAllowedPriceImpactInBP) external {
        revert("OUTDATED");
    }

    /// @inheritdoc IOrdererV2
    function setMaxSlippageInBP(uint16 _maxSlippageInBP) external override onlyRole(ORDERING_MANAGER_ROLE) {
        require(_maxSlippageInBP != 0 && _maxSlippageInBP <= BP.DECIMAL_FACTOR, "Orderer: INVALID");

        maxSlippageInBP = _maxSlippageInBP;
    }

    /// @inheritdoc IOrderer
    function setOrderLifetime(uint64 _orderLifetime) external override onlyRole(ORDERING_MANAGER_ROLE) {
        require(_orderLifetime != 0, "Orderer: INVALID");

        orderLifetime = _orderLifetime;
    }

    /// @inheritdoc IOrderer
    function placeOrder() external override onlyRole(INDEX_ROLE) returns (uint _orderId) {
        delete orderDetailsOf[lastOrderIdOf[msg.sender]];
        unchecked {
            ++_lastOrderId;
        }
        _orderId = _lastOrderId;
        OrderDetails storage order = orderDetailsOf[_orderId];
        order.creationTimestamp = block.timestamp;
        order.creator = msg.sender;
        lastOrderIdOf[msg.sender] = _orderId;
        emit PlaceOrder(msg.sender, _orderId);
    }

    /// @inheritdoc IOrderer
    function addOrderDetails(
        uint _orderId,
        address _asset,
        uint _shares,
        OrderSide _side
    ) external override onlyRole(INDEX_ROLE) {
        if (_asset != address(0) && _shares != 0) {
            OrderDetails storage order = orderDetailsOf[_orderId];
            order.assets.push(_asset);
            order.assetDetails[_asset] = AssetDetails({ side: _side, shares: uint248(_shares) });
            emit UpdateOrder(_orderId, _asset, _shares, _side == OrderSide.Sell);
        }
    }

    function updateOrderDetails(address _asset, uint _shares) external override onlyRole(INDEX_ROLE) {
        uint lastOrderId = lastOrderIdOf[msg.sender];
        if (lastOrderId != 0 && _asset != address(0)) {
            uint248 shares = uint248(_shares);
            OrderDetails storage order = orderDetailsOf[lastOrderId];
            order.assetDetails[_asset].shares = shares;
            emit UpdateOrder(lastOrderId, _asset, shares, order.assetDetails[_asset].side == OrderSide.Sell);
        }
    }

    /// @inheritdoc IOrderer
    function reduceOrderAsset(
        address _asset,
        uint _newTotalSupply,
        uint _oldTotalSupply
    ) external override onlyRole(INDEX_ROLE) {
        uint lastOrderId = lastOrderIdOf[msg.sender];
        if (lastOrderId != 0) {
            OrderDetails storage order = orderDetailsOf[lastOrderId];
            uint shares = order.assetDetails[_asset].shares;
            if (shares != 0) {
                uint248 newShares = uint248((shares * _newTotalSupply) / _oldTotalSupply);
                order.assetDetails[_asset].shares = newShares;
                emit UpdateOrder(lastOrderId, _asset, newShares, order.assetDetails[_asset].side == OrderSide.Sell);
            }
        }
    }

    /// @inheritdoc IOrderer
    function reweight(address _index) external override onlyRole(KEEPER_JOB_ROLE) {
        IReweightableIndex(_index).reweight();
    }

    /// @inheritdoc IOrderer
    function internalSwap(InternalSwap calldata _info) external override {
        revert("OUTDATED");
    }

    /// @inheritdoc IOrderer
    function externalSwap(ExternalSwap calldata _info) external override {
        revert("OUTDATED");
    }

    /// @inheritdoc IOrdererV2
    function internalSwap(InternalSwapV2 calldata _info) external override onlyRole(KEEPER_JOB_ROLE) {
        require(_info.maxSellShares != 0 && _info.buyAccount != _info.sellAccount, "Orderer: INVALID");
        require(
            IAccessControl(registry).hasRole(INDEX_ROLE, _info.buyAccount) &&
                IAccessControl(registry).hasRole(INDEX_ROLE, _info.sellAccount),
            "Orderer: INDEX"
        );

        address sellVTokenFactory = IIndex(_info.sellAccount).vTokenFactory();
        address buyVTokenFactory = IIndex(_info.buyAccount).vTokenFactory();
        SwapDetails memory _details = _swapDetails(
            sellVTokenFactory,
            buyVTokenFactory,
            _info.sellAsset,
            _info.buyAsset
        );

        if (sellVTokenFactory == buyVTokenFactory) {
            _internalWithinVaultSwap(_info, _details);
        } else {
            _internalBetweenVaultsSwap(
                InternalSwapVaultsInfo(
                    _info.sellAccount,
                    _info.buyAccount,
                    _info.maxSellShares,
                    IvToken(IvTokenFactory(sellVTokenFactory).vTokenOf(_details.buyAsset)),
                    IvToken(IvTokenFactory(buyVTokenFactory).vTokenOf(_details.sellAsset)),
                    _details
                )
            );
        }
    }

    /// @inheritdoc IOrdererV2
    function externalSwap(ExternalSwapV2 calldata _info) external override onlyRole(KEEPER_JOB_ROLE) {
        require(_info.swapTarget != address(0) && _info.swapData.length > 0, "Orderer: INVALID");
        require(IAccessControl(registry).hasRole(INDEX_ROLE, _info.account), "Orderer: INVALID");

        SwapDetails memory _details = _swapDetails(
            IIndex(_info.account).vTokenFactory(),
            address(0),
            _info.sellAsset,
            _info.buyAsset
        );

        (uint lastOrderId, AssetDetails storage orderSellAsset, AssetDetails storage orderBuyAsset) = _validatedOrder(
            _info.account,
            _details.sellAsset,
            _details.buyAsset
        );

        require(orderSellAsset.shares >= _info.sellShares, "Orderer: MAX");

        uint sellAssetPerBase = _details.priceOracle.refreshedAssetPerBaseInUQ(_details.sellAsset);

        if (
            orderSellAsset.shares == _details.sellVToken.balanceOf(_info.account) &&
            _details.sellVToken.assetDataOf(_info.account, orderSellAsset.shares).amountInAsset.mulDiv(
                FixedPoint112.Q112,
                sellAssetPerBase
            ) <
            MIN_SWAP_AMOUNT
        ) {
            _details.sellVToken.transferFrom(_info.account, address(_details.sellVToken), orderSellAsset.shares);
            _details.sellVToken.burnFor(address(_details.sellVToken));

            emit CompleteOrder(lastOrderId, _details.sellAsset, orderSellAsset.shares, _details.buyAsset, 0);
        } else {
            uint sellAmount = _details.sellVToken.assetDataOf(_info.account, _info.sellShares).amountInAsset;

            _details.sellVToken.transferFrom(_info.account, address(_details.sellVToken), _info.sellShares);
            _details.sellVToken.burnFor(address(this));

            uint sellBalanceBefore = IERC20(_details.sellAsset).balanceOf(address(this));

            {
                uint allowance = IERC20(_details.sellAsset).allowance(address(this), _info.swapTarget);
                IERC20(_details.sellAsset).safeIncreaseAllowance(_info.swapTarget, type(uint256).max - allowance);
            }

            {
                (bool success, bytes memory data) = _info.swapTarget.call(_info.swapData);
                if (!success) {
                    if (data.length == 0) {
                        revert("Orderer: SWAP_FAILED");
                    } else {
                        assembly {
                            revert(add(32, data), mload(data))
                        }
                    }
                }
            }

            {
                uint sellAmountInBase = sellAmount.mulDiv(FixedPoint112.Q112, sellAssetPerBase);

                uint soldAmount = sellBalanceBefore - IERC20(_details.sellAsset).balanceOf(address(this));
                uint soldAmountInBase = soldAmount.mulDiv(FixedPoint112.Q112, sellAssetPerBase);

                // checks diff between input and swap amounts
                require(sellAmountInBase - soldAmountInBase <= MIN_SWAP_AMOUNT, "Orderer: AMOUNT");

                uint boughtAmount = IERC20(_details.buyAsset).balanceOf(address(this));
                uint boughtAmountInBase = boughtAmount.mulDiv(
                    FixedPoint112.Q112,
                    _details.priceOracle.refreshedAssetPerBaseInUQ(_details.buyAsset)
                );
                uint ratio = (boughtAmountInBase * BP.DECIMAL_FACTOR) / (soldAmountInBase);

                require(
                    ratio >= BP.DECIMAL_FACTOR - maxSlippageInBP && ratio <= BP.DECIMAL_FACTOR + maxSlippageInBP,
                    "Orderer: SLIPPAGE"
                );

                IERC20(_details.buyAsset).safeTransfer(address(_details.buyVToken), boughtAmount);
            }

            uint248 _buyShares = uint248(Math.min(_details.buyVToken.mintFor(_info.account), orderBuyAsset.shares));

            orderSellAsset.shares -= uint248(_info.sellShares);
            orderBuyAsset.shares -= _buyShares;

            emit CompleteOrder(lastOrderId, _details.sellAsset, _info.sellShares, _details.buyAsset, _buyShares);

            uint change = IERC20(_details.sellAsset).balanceOf(address(this));
            if (change > 0) {
                IERC20(_details.sellAsset).safeTransfer(address(_details.sellVToken), change);
                _details.sellVToken.sync();
            }

            IERC20(_details.sellAsset).safeApprove(_info.swapTarget, 0);
        }
    }

    /// @inheritdoc IOrderer
    function orderOf(address _account) external view override returns (Order memory order) {
        OrderDetails storage _order = orderDetailsOf[lastOrderIdOf[_account]];
        order = Order({ creationTimestamp: _order.creationTimestamp, assets: new OrderAsset[](_order.assets.length) });

        uint assetsCount = _order.assets.length;
        for (uint i; i < assetsCount; ) {
            address asset = _order.assets[i];
            order.assets[i] = OrderAsset({
                asset: asset,
                side: _order.assetDetails[asset].side,
                shares: _order.assetDetails[asset].shares
            });

            unchecked {
                i = i + 1;
            }
        }
    }

    /// @inheritdoc ERC165Upgradeable
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return
            _interfaceId == type(IOrdererV2).interfaceId ||
            _interfaceId == type(IOrderer).interfaceId ||
            super.supportsInterface(_interfaceId);
    }

    /// @notice Executes internal swap within single vault
    function _internalWithinVaultSwap(InternalSwapV2 calldata _info, SwapDetails memory _details) internal {
        (
            uint lastSellOrderId,
            AssetDetails storage sellOrderSellAsset,
            AssetDetails storage sellOrderBuyAsset
        ) = _validatedOrder(_info.sellAccount, _details.sellAsset, _details.buyAsset);
        (
            uint lastBuyOrderId,
            AssetDetails storage buyOrderSellAsset,
            AssetDetails storage buyOrderBuyAsset
        ) = _validatedOrder(_info.buyAccount, _details.buyAsset, _details.sellAsset);

        uint248 sellShares;
        uint248 buyShares;
        {
            uint _sellShares = Math.min(
                Math.min(_info.maxSellShares, sellOrderSellAsset.shares),
                buyOrderBuyAsset.shares
            );
            uint _buyShares = Math.min(sellOrderBuyAsset.shares, buyOrderSellAsset.shares);
            (sellShares, buyShares) = _calculateInternalSwapShares(
                _info.sellAccount,
                _info.buyAccount,
                _details,
                _sellShares,
                _buyShares
            );
        }

        if (sellShares != 0 && buyShares != 0) {
            _details.sellVToken.transferFrom(_info.sellAccount, _info.buyAccount, sellShares);
            _details.buyVToken.transferFrom(_info.buyAccount, _info.sellAccount, buyShares);

            sellOrderSellAsset.shares -= sellShares;
            sellOrderBuyAsset.shares -= buyShares;
            buyOrderSellAsset.shares -= buyShares;
            buyOrderBuyAsset.shares -= sellShares;

            emit CompleteOrder(lastSellOrderId, _details.sellAsset, sellShares, _details.buyAsset, buyShares);
            emit CompleteOrder(lastBuyOrderId, _details.buyAsset, buyShares, _details.sellAsset, sellShares);
        }
    }

    /// @notice Executes internal swap between different vaults
    function _internalBetweenVaultsSwap(InternalSwapVaultsInfo memory _info) internal {
        (
            uint lastSellOrderId,
            AssetDetails storage sellOrderSellAsset,
            AssetDetails storage sellOrderBuyAsset
        ) = _validatedOrder(_info.sellAccount, _info.details.sellAsset, _info.details.buyAsset);
        (
            uint lastBuyOrderId,
            AssetDetails storage buyOrderSellAsset,
            AssetDetails storage buyOrderBuyAsset
        ) = _validatedOrder(_info.buyAccount, _info.details.buyAsset, _info.details.sellAsset);

        uint248 sellSharesSellAccount;
        uint248 sellSharesBuyAccount;
        {
            uint _sellSharesSellAccount = _scaleShares(
                Math.min(_info.maxSellShares, sellOrderSellAsset.shares),
                buyOrderBuyAsset.shares,
                _info.sellAccount,
                _info.details.sellVToken,
                _info.buyVTokenBuyAccount
            );
            uint _buySharesBuyAccount = _scaleShares(
                buyOrderSellAsset.shares,
                sellOrderBuyAsset.shares,
                _info.buyAccount,
                _info.details.buyVToken,
                _info.buyVTokenSellAccount
            );

            (sellSharesSellAccount, sellSharesBuyAccount) = _calculateInternalSwapShares(
                _info.sellAccount,
                _info.buyAccount,
                _info.details,
                _sellSharesSellAccount,
                _buySharesBuyAccount
            );
        }

        _info.details.sellVToken.transferFrom(
            _info.sellAccount,
            address(_info.details.sellVToken),
            sellSharesSellAccount
        );
        _info.details.sellVToken.burnFor(address(_info.buyVTokenBuyAccount));
        uint248 buySharesBuyAccount = uint248(_info.buyVTokenBuyAccount.mintFor(_info.buyAccount));

        _info.details.buyVToken.transferFrom(_info.buyAccount, address(_info.details.buyVToken), sellSharesBuyAccount);
        _info.details.buyVToken.burnFor(address(_info.buyVTokenSellAccount));
        uint248 buySharesSellAccount = uint248(_info.buyVTokenSellAccount.mintFor(_info.sellAccount));

        sellOrderSellAsset.shares -= sellSharesSellAccount;
        sellOrderBuyAsset.shares -= buySharesSellAccount;
        buyOrderSellAsset.shares -= sellSharesBuyAccount;
        buyOrderBuyAsset.shares -= buySharesBuyAccount;

        emit CompleteOrder(
            lastSellOrderId,
            _info.details.sellAsset,
            sellSharesSellAccount,
            _info.details.buyAsset,
            buySharesSellAccount
        );
        emit CompleteOrder(
            lastBuyOrderId,
            _info.details.buyAsset,
            sellSharesBuyAccount,
            _info.details.sellAsset,
            buySharesBuyAccount
        );
    }

    /// @notice Returns validated order's info
    /// @param _index Index address
    /// @param _sellAsset Sell asset address
    /// @param _buyAsset Buy asset address
    /// @return lastOrderId Id of last order
    /// @return orderSellAsset Order's details for sell asset
    /// @return orderBuyAsset Order's details for buy asset
    function _validatedOrder(
        address _index,
        address _sellAsset,
        address _buyAsset
    )
        internal
        view
        returns (
            uint lastOrderId,
            AssetDetails storage orderSellAsset,
            AssetDetails storage orderBuyAsset
        )
    {
        lastOrderId = lastOrderIdOf[_index];
        OrderDetails storage order = orderDetailsOf[lastOrderId];

        orderSellAsset = order.assetDetails[_sellAsset];
        orderBuyAsset = order.assetDetails[_buyAsset];

        require(order.creationTimestamp + orderLifetime > block.timestamp, "Orderer: EXPIRED");
        require(orderSellAsset.side == OrderSide.Sell && orderBuyAsset.side == OrderSide.Buy, "Orderer: SIDE");
    }

    /// @inheritdoc UUPSUpgradeable
    function _authorizeUpgrade(address _newImpl) internal view override onlyRole(ORDERING_MANAGER_ROLE) {
        require(_newImpl.supportsInterface(type(IOrderer).interfaceId), "Orderer: INTERFACE");
    }

    /// @notice Scales down shares
    function _scaleShares(
        uint _sellShares,
        uint _buyShares,
        address _sellAccount,
        IvToken _sellVToken,
        IvToken _buyVToken
    ) internal view returns (uint) {
        uint sharesInAsset = _sellVToken.assetDataOf(_sellAccount, _sellShares).amountInAsset;
        uint mintableShares = _buyVToken.mintableShares(sharesInAsset);
        return Math.min(_sellShares, (_sellShares * _buyShares) / mintableShares);
    }

    /// @notice Calculates internal swap shares (buy and sell) for the given swap details
    function _calculateInternalSwapShares(
        address sellAccount,
        address buyAccount,
        SwapDetails memory _details,
        uint _sellOrderShares,
        uint _buyOrderShares
    ) internal returns (uint248 _sellShares, uint248 _buyShares) {
        uint sellAssetPerBaseInUQ = _details.priceOracle.refreshedAssetPerBaseInUQ(_details.sellAsset);
        uint buyAssetPerBaseInUQ = _details.priceOracle.refreshedAssetPerBaseInUQ(_details.buyAsset);
        {
            uint buyAmountInBuyAsset = _details.buyVToken.assetBalanceForShares(_buyOrderShares);
            uint buyAmountInSellAsset = buyAmountInBuyAsset.mulDiv(sellAssetPerBaseInUQ, buyAssetPerBaseInUQ);
            _sellOrderShares = Math.min(_sellOrderShares, _details.sellVToken.mintableShares(buyAmountInSellAsset));
        }
        {
            uint sellAmountInSellAsset = _details.sellVToken.assetDataOf(sellAccount, _sellOrderShares).amountInAsset;
            uint sellAmountInBuyAsset = sellAmountInSellAsset.mulDiv(buyAssetPerBaseInUQ, sellAssetPerBaseInUQ);
            _buyOrderShares = Math.min(_buyOrderShares, _details.buyVToken.mintableShares(sellAmountInBuyAsset));
        }
        _sellShares = uint248(_sellOrderShares);
        _buyShares = uint248(_buyOrderShares);
    }

    /// @notice Returns swap details for the provided buy path
    /// @param _sellVTokenFactory vTokenFactory address of sell account
    /// @param _buyVTokenFactory vTokenFactory address of buy account
    /// @param _sellAsset Address of sell asset
    /// @param _buyAsset Address address of buy asset
    /// @return Swap details
    function _swapDetails(
        address _sellVTokenFactory,
        address _buyVTokenFactory,
        address _sellAsset,
        address _buyAsset
    ) internal view returns (SwapDetails memory) {
        require(_sellAsset != address(0) && _buyAsset != address(0), "Orderer: ZERO");
        require(_sellAsset != _buyAsset, "Orderer: INVALID");

        address buyVToken = IvTokenFactory(
            (_sellVTokenFactory == _buyVTokenFactory || _buyVTokenFactory == address(0))
                ? _sellVTokenFactory
                : _buyVTokenFactory
        ).vTokenOf(_buyAsset);

        return
            SwapDetails({
                sellAsset: _sellAsset,
                buyAsset: _buyAsset,
                sellVToken: IvToken(IvTokenFactory(_sellVTokenFactory).vTokenOf(_sellAsset)),
                buyVToken: IvToken(buyVToken),
                priceOracle: IPhuturePriceOracle(IIndexRegistry(registry).priceOracle())
            });
    }

    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

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
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165CheckerUpgradeable {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165Upgradeable).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165Upgradeable.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.13;

/// @title Base point library
/// @notice Contains constant used to prevent underflow of math operations
library BP {
    /// @notice Base point number
    /// @dev Used to prevent underflow of math operations
    uint16 constant DECIMAL_FACTOR = 10_000;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
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
        unchecked {
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
            uint256 twos = (~denominator + 1) & denominator;
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
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.13;

/// @title FixedPoint112
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
library FixedPoint112 {
    uint8 internal constant RESOLUTION = 112;
    /// @dev 2**112
    uint256 internal constant Q112 = 0x10000000000000000000000000000;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

/// @title Vault token interface
/// @notice Contains logic for index's asset management
interface IvToken {
    struct AssetData {
        uint maxShares;
        uint amountInAsset;
    }

    event UpdateDeposit(address indexed account, uint depositedAmount);
    event SetVaultController(address vaultController);
    event VTokenTransfer(address indexed from, address indexed to, uint amount);

    /// @notice Initializes vToken with the given parameters
    /// @param _asset Asset that will be stored
    /// @param _registry Index registry address
    function initialize(address _asset, address _registry) external;

    /// @notice Sets vault controller for the vault
    /// @param _vaultController Vault controller to set
    function setController(address _vaultController) external;

    /// @notice Updates reserve to expected deposit target
    function deposit() external;

    /// @notice Withdraws all deposited amount
    function withdraw() external;

    /// @notice Transfers shares between given accounts
    /// @param _from Account to transfer shares from
    /// @param _to Account to transfer shares to
    /// @param _shares Amount of shares to transfer
    function transferFrom(
        address _from,
        address _to,
        uint _shares
    ) external;

    /// @notice Transfers asset to the given recipient
    /// @dev Method is restricted to orderer
    /// @param _recipient Recipient address
    /// @param _amount Amount to transfer
    function transferAsset(address _recipient, uint _amount) external;

    /// @notice Mints shares for the current sender
    /// @return shares Amount of minted shares
    function mint() external returns (uint shares);

    /// @notice Burns shares for the given recipient and returns assets to the given recipient
    /// @param _recipient Recipient to send assets to
    /// @return amount Amount of sent assets
    function burn(address _recipient) external returns (uint amount);

    /// @notice Transfers shares from the sender to the given recipient
    /// @param _recipient Account to transfer shares to
    /// @param _amount Amount of shares to transfer
    function transfer(address _recipient, uint _amount) external;

    /// @notice Manually synchronizes shares balances
    function sync() external;

    /// @notice Mints shares for the given recipient
    /// @param _recipient Recipient to mint shares for
    /// @return Returns minted shares amount
    function mintFor(address _recipient) external returns (uint);

    /// @notice Burns shares and sends assets to the given recipient
    /// @param _recipient Recipient to send assets to
    /// @return Returns amount of sent assets
    function burnFor(address _recipient) external returns (uint);

    /// @notice Virtual supply amount: current balance + expected to be withdrawn using vault controller
    /// @return Returns virtual supply amount
    function virtualTotalAssetSupply() external view returns (uint);

    /// @notice Total supply amount: current balance + deposited using vault controller
    /// @return Returns total supply amount
    function totalAssetSupply() external view returns (uint);

    /// @notice Amount deposited using vault controller
    /// @return Returns amount deposited using vault controller
    function deposited() external view returns (uint);

    /// @notice Returns mintable amount of shares for given asset's amount
    /// @param _amount Amount of assets to mint shares for
    /// @return Returns amount of shares available for minting
    function mintableShares(uint _amount) external view returns (uint);

    /// @notice Returns amount of assets for the given account with the given shares amount
    /// @return Amount of assets for the given account with the given shares amount
    function assetDataOf(address _account, uint _shares) external view returns (AssetData memory);

    /// @notice Returns amount of assets for the given shares amount
    /// @param _shares Amount of shares
    /// @return Amount of assets
    function assetBalanceForShares(uint _shares) external view returns (uint);

    /// @notice Asset balance of the given address
    /// @param _account Address to check balance of
    /// @return Returns asset balance of the given address
    function assetBalanceOf(address _account) external view returns (uint);

    /// @notice Last asset balance for the given address
    /// @param _account Address to check balance of
    /// @return Returns last asset balance for the given address
    function lastAssetBalanceOf(address _account) external view returns (uint);

    /// @notice Last asset balance
    /// @return Returns last asset balance
    function lastAssetBalance() external view returns (uint);

    /// @notice Total shares supply
    /// @return Returns total shares supply
    function totalSupply() external view returns (uint);

    /// @notice Shares balance of the given address
    /// @param _account Address to check balance of
    /// @return Returns shares balance of the given address
    function balanceOf(address _account) external view returns (uint);

    /// @notice Returns the change in shares for a given amount of an asset
    /// @param _account Account to calculate shares for
    /// @param _amountInAsset Amount of asset to calculate shares
    /// @return newShares New shares value
    /// @return oldShares Old shares value
    function shareChange(address _account, uint _amountInAsset) external view returns (uint newShares, uint oldShares);

    /// @notice Vault controller address
    /// @return Returns vault controller address
    function vaultController() external view returns (address);

    /// @notice Stored asset address
    /// @return Returns stored asset address
    function asset() external view returns (address);

    /// @notice Index registry address
    /// @return Returns index registry address
    function registry() external view returns (address);

    /// @notice Percentage deposited using vault controller
    /// @return Returns percentage deposited using vault controller
    function currentDepositedPercentageInBP() external view returns (uint);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

import "./IIndexLayout.sol";
import "./IAnatomyUpdater.sol";

/// @title Index interface
/// @notice Interface containing basic logic for indexes: mint, burn, anatomy info
interface IIndex is IIndexLayout, IAnatomyUpdater {
    /// @notice Index minting
    /// @param _recipient Recipient address
    function mint(address _recipient) external;

    /// @notice Index burning
    /// @param _recipient Recipient address
    function burn(address _recipient) external;

    /// @notice Returns index assets weights information
    /// @return _assets Assets list
    /// @return _weights List of assets corresponding weights
    function anatomy() external view returns (address[] memory _assets, uint8[] memory _weights);

    /// @notice Returns inactive assets
    /// @return Assets list
    function inactiveAnatomy() external view returns (address[] memory);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

import "./IvToken.sol";

/// @title Orderer interface
/// @notice Describes methods for reweigh execution, order creation and execution
interface IOrderer {
    struct Order {
        uint creationTimestamp;
        OrderAsset[] assets;
    }

    struct OrderAsset {
        address asset;
        OrderSide side;
        uint shares;
    }

    struct InternalSwap {
        address sellAccount;
        address buyAccount;
        uint maxSellShares;
        address[] buyPath;
    }

    struct ExternalSwap {
        address factory;
        address account;
        uint maxSellShares;
        uint minSwapOutputAmount;
        address[] buyPath;
    }

    enum OrderSide {
        Sell,
        Buy
    }

    event PlaceOrder(address creator, uint id);
    event UpdateOrder(uint id, address asset, uint share, bool isSellSide);
    event CompleteOrder(uint id, address sellAsset, uint soldShares, address buyAsset, uint boughtShares);

    /// @notice Initializes orderer with the given params
    /// @param _registry Index registry address
    /// @param _orderLifetime Order lifetime in which it stays valid
    /// @param _maxAllowedPriceImpactInBP Max allowed exchange price impact
    function initialize(
        address _registry,
        uint64 _orderLifetime,
        uint16 _maxAllowedPriceImpactInBP
    ) external;

    /// @notice Sets max allowed exchange price impact
    /// @param _maxAllowedPriceImpactInBP Max allowed exchange price impact
    function setMaxAllowedPriceImpactInBP(uint16 _maxAllowedPriceImpactInBP) external;

    /// @notice Sets order lifetime in which it stays valid
    /// @param _orderLifetime Order lifetime in which it stays valid
    function setOrderLifetime(uint64 _orderLifetime) external;

    /// @notice Places order to orderer queue and returns order id
    /// @return Order id of the placed order
    function placeOrder() external returns (uint);

    /// @notice Fulfills specified order with order details
    /// @param _orderId Order id to fulfill
    /// @param _asset Asset address to be exchanged
    /// @param _shares Amount of asset to be exchanged
    /// @param _side Order side: buy or sell
    function addOrderDetails(
        uint _orderId,
        address _asset,
        uint _shares,
        OrderSide _side
    ) external;

    /// @notice Updates shares for order
    /// @param _asset Asset address
    /// @param _shares New amount of shares
    function updateOrderDetails(address _asset, uint _shares) external;

    /// @notice Updates asset amount for the latest order placed by the sender
    /// @param _asset Asset to change amount for
    /// @param _newTotalSupply New amount value
    /// @param _oldTotalSupply Old amount value
    function reduceOrderAsset(
        address _asset,
        uint _newTotalSupply,
        uint _oldTotalSupply
    ) external;

    /// @notice Reweighs the given index
    /// @param _index Index address to call reweight for
    function reweight(address _index) external;

    /// @notice Swap shares between given indexes
    /// @param _info Swap info objects with exchange details
    function internalSwap(InternalSwap calldata _info) external;

    /// @notice Swap shares using DEX
    /// @param _info Swap info objects with exchange details
    function externalSwap(ExternalSwap calldata _info) external;

    /// @notice Max allowed exchange price impact
    /// @return Returns max allowed exchange price impact
    function maxAllowedPriceImpactInBP() external view returns (uint16);

    /// @notice Order lifetime in which it stays valid
    /// @return Returns order lifetime in which it stays valid
    function orderLifetime() external view returns (uint64);

    /// @notice Returns last order of the given account
    /// @param _account Account to get last order for
    /// @return order Last order of the given account
    function orderOf(address _account) external view returns (Order memory order);

    /// @notice Returns last order id of the given account
    /// @param _account Account to get last order for
    /// @return Last order id of the given account
    function lastOrderIdOf(address _account) external view returns (uint);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

/// @title Orderer interface
/// @notice Describes methods for reweigh execution, order creation and execution
interface IOrdererV2 {
    struct InternalSwapV2 {
        address sellAccount;
        address buyAccount;
        address sellAsset;
        address buyAsset;
        uint maxSellShares;
    }

    struct ExternalSwapV2 {
        address account;
        address sellAsset;
        address buyAsset;
        uint sellShares;
        address swapTarget;
        bytes swapData;
    }

    /// @notice Initializes orderer with the given params (overrides IOrderer's initialize)
    /// @param _registry Index registry address
    /// @param _orderLifetime Order lifetime in which it stays valid
    /// @param _maxSlippageInBP Max slippage in BP
    function initialize(
        address _registry,
        uint64 _orderLifetime,
        uint16 _maxSlippageInBP
    ) external;

    /// @notice Sets max allowed slippage
    /// @param _maxSlippageInBP Max allowed slippage
    function setMaxSlippageInBP(uint16 _maxSlippageInBP) external;

    /// @notice Swap shares between given indexes
    /// @param _info Swap info objects with exchange details
    function internalSwap(InternalSwapV2 calldata _info) external;

    /// @notice Swap shares using DEX
    /// @param _info Swap info objects with exchange details
    function externalSwap(ExternalSwapV2 calldata _info) external;

    /// @notice Max allowed exchange price impact
    /// @return Returns max allowed exchange price impact
    function maxSlippageInBP() external view returns (uint16);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

/// @title vToken factory interface
/// @notice Contains vToken creation logic
interface IvTokenFactory {
    event VTokenCreated(address vToken, address asset);

    /// @notice Initialize vToken factory with the given params
    /// @param _registry Index registry address
    /// @param _vTokenImpl Address of vToken implementation
    function initialize(address _registry, address _vTokenImpl) external;

    /// @notice Upgrades beacon implementation
    /// @param _vTokenImpl Address of vToken implementation
    function upgradeBeaconTo(address _vTokenImpl) external;

    /// @notice Creates vToken for the given asset
    /// @param _asset Asset to create vToken for
    function createVToken(address _asset) external;

    /// @notice Creates and returns or returns address of previously created vToken for the given asset
    /// @param _asset Asset to create or return vToken for
    function createdVTokenOf(address _asset) external returns (address);

    /// @notice Returns beacon address
    /// @return Beacon address
    function beacon() external view returns (address);

    /// @notice Returns vToken for the given asset
    /// @param _asset Asset to retrieve vToken for
    /// @return vToken for the given asset
    function vTokenOf(address _asset) external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

import "./IIndexFactory.sol";

/// @title Index registry interface
/// @notice Contains core components, addresses and asset market capitalizations
interface IIndexRegistry {
    event SetIndexLogic(address indexed account, address indexLogic);
    event SetMaxComponents(address indexed account, uint maxComponents);
    event UpdateAsset(address indexed asset, uint marketCap);
    event SetOrderer(address indexed account, address orderer);
    event SetFeePool(address indexed account, address feePool);
    event SetPriceOracle(address indexed account, address priceOracle);

    /// @notice Initializes IndexRegistry with the given params
    /// @param _indexLogic Index logic address
    /// @param _maxComponents Maximum assets for an index
    function initialize(address _indexLogic, uint _maxComponents) external;

    /// @notice Sets maximum assets for an index
    /// @param _maxComponents Maximum assets for an index
    function setMaxComponents(uint _maxComponents) external;

    /// @notice Index logic address
    /// @return Returns index logic address
    function indexLogic() external returns (address);

    /// @notice Sets index logic address
    /// @param _indexLogic Index logic address
    function setIndexLogic(address _indexLogic) external;

    /// @notice Sets adminRole as role's admin role.
    /// @param _role Role
    /// @param _adminRole AdminRole of given role
    function setRoleAdmin(bytes32 _role, bytes32 _adminRole) external;

    /// @notice Registers new index
    /// @param _index Index address
    /// @param _nameDetails Name details (name and symbol) for provided index
    function registerIndex(address _index, IIndexFactory.NameDetails calldata _nameDetails) external;

    /// @notice Registers asset in the system, updates it's market capitalization and assigns required roles
    /// @param _asset Asset to register
    /// @param _marketCap It's current market capitalization
    function addAsset(address _asset, uint _marketCap) external;

    /// @notice Removes assets from the system
    /// @param _asset Asset to remove
    function removeAsset(address _asset) external;

    /// @notice Updates market capitalization for the given asset
    /// @param _asset Asset address to update market capitalization for
    /// @param _marketCap Market capitalization value
    function updateAssetMarketCap(address _asset, uint _marketCap) external;

    /// @notice Sets price oracle address
    /// @param _priceOracle Price oracle address
    function setPriceOracle(address _priceOracle) external;

    /// @notice Sets orderer address
    /// @param _orderer Orderer address
    function setOrderer(address _orderer) external;

    /// @notice Sets fee pool address
    /// @param _feePool Fee pool address
    function setFeePool(address _feePool) external;

    /// @notice Maximum assets for an index
    /// @return Returns maximum assets for an index
    function maxComponents() external view returns (uint);

    /// @notice Market capitalization of provided asset
    /// @return _asset Returns market capitalization of provided asset
    function marketCapOf(address _asset) external view returns (uint);

    /// @notice Returns total market capitalization of the given assets
    /// @param _assets Assets array to calculate market capitalization of
    /// @return _marketCaps Corresponding capitalizations of the given asset
    /// @return _totalMarketCap Total market capitalization of the given assets
    function marketCapsOf(address[] calldata _assets)
        external
        view
        returns (uint[] memory _marketCaps, uint _totalMarketCap);

    /// @notice Total market capitalization of all registered assets
    /// @return Returns total market capitalization of all registered assets
    function totalMarketCap() external view returns (uint);

    /// @notice Price oracle address
    /// @return Returns price oracle address
    function priceOracle() external view returns (address);

    /// @notice Orderer address
    /// @return Returns orderer address
    function orderer() external view returns (address);

    /// @notice Fee pool address
    /// @return Returns fee pool address
    function feePool() external view returns (address);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.13;

/// @title Rewightable index interface
/// @notice Contains reweighting logic
interface IReweightableIndex {
    /// @notice Call index reweight process
    function reweight() external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

import "./IPriceOracle.sol";

/// @title Phuture price oracle interface
/// @notice Aggregates all price oracles and works with them through IPriceOracle interface
interface IPhuturePriceOracle is IPriceOracle {
    /// @notice Initializes price oracle
    /// @param _registry Index registry address
    /// @param _base Base asset
    function initialize(address _registry, address _base) external;

    /// @notice Assigns given oracle to specified asset. Then oracle will be used to manage asset price
    /// @param _asset Asset to register
    /// @param _oracle Oracle to assign
    function setOracleOf(address _asset, address _oracle) external;

    /// @notice Removes oracle of specified asset
    /// @param _asset Asset to remove oracle from
    function removeOracleOf(address _asset) external;

    /// @notice Converts to index amount
    /// @param _baseAmount Amount in base
    /// @param _indexDecimals Index's decimals
    /// @return Asset per base in UQ with index decimals
    function convertToIndex(uint _baseAmount, uint8 _indexDecimals) external view returns (uint);

    /// @notice Checks if the given asset has oracle assigned
    /// @param _asset Asset to check
    /// @return Returns boolean flag defining if the given asset has oracle assigned
    function containsOracleOf(address _asset) external view returns (bool);

    /// @notice Price oracle assigned to the given `_asset`
    /// @param _asset Asset to obtain price oracle for
    /// @return Returns price oracle assigned to the `_asset`
    function priceOracleOf(address _asset) external view returns (address);
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
        bool isTopLevelCall = _setInitializedVersion(1);
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
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
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

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

/// @title Index layout interface
/// @notice Contains storage layout of index
interface IIndexLayout {
    /// @notice Index factory address
    /// @return Returns index factory address
    function factory() external view returns (address);

    /// @notice vTokenFactory address
    /// @return Returns vTokenFactory address
    function vTokenFactory() external view returns (address);

    /// @notice Registry address
    /// @return Returns registry address
    function registry() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

/// @title Anatomy Updater interface
/// @notice Contains event for aatomy update
interface IAnatomyUpdater {
    event UpdateAnatomy(address asset, uint8 weight);
    event AssetRemoved(address asset);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

/// @title Index factory interface
/// @notice Contains logic for initial fee management for indexes which will be created by this factory
interface IIndexFactory {
    struct NameDetails {
        string name;
        string symbol;
    }

    event SetVTokenFactory(address vTokenFactory);
    event SetDefaultMintingFeeInBP(address indexed account, uint16 mintingFeeInBP);
    event SetDefaultBurningFeeInBP(address indexed account, uint16 burningFeeInBP);
    event SetDefaultAUMScaledPerSecondsRate(address indexed account, uint AUMScaledPerSecondsRate);

    /// @notice Sets default index minting fee in base point (BP) format
    /// @dev Will be set in FeePool on index creation
    /// @param _mintingFeeInBP New minting fee value
    function setDefaultMintingFeeInBP(uint16 _mintingFeeInBP) external;

    /// @notice Sets default index burning fee in base point (BP) format
    /// @dev Will be set in FeePool on index creation
    /// @param _burningFeeInBP New burning fee value
    function setDefaultBurningFeeInBP(uint16 _burningFeeInBP) external;

    /// @notice Sets reweighting logic address
    /// @param _reweightingLogic Reweighting logic address
    function setReweightingLogic(address _reweightingLogic) external;

    /// @notice Sets default AUM scaled per seconds rate that will be used for fee calculation
    /**
        @dev Will be set in FeePool on index creation.
        Effective management fee rate (annual, in percent, after dilution) is calculated by the given formula:
        fee = (rpow(scaledPerSecondRate, numberOfSeconds, 10*27) - 10**27) * totalSupply / 10**27, where:

        totalSupply - total index supply;
        numberOfSeconds - delta time for calculation period;
        scaledPerSecondRate - scaled rate, calculated off chain by the given formula:

        scaledPerSecondRate = ((1 + k) ** (1 / 365 days)) * AUMCalculationLibrary.RATE_SCALE_BASE, where:
        k = (aumFeeInBP / BP) / (1 - aumFeeInBP / BP);

        Note: rpow and RATE_SCALE_BASE are provided by AUMCalculationLibrary
        More info: https://docs.enzyme.finance/fee-formulas/management-fee

        After value calculated off chain, scaledPerSecondRate is set to setDefaultAUMScaledPerSecondsRate
    */
    /// @param _AUMScaledPerSecondsRate New AUM scaled per seconds rate
    function setDefaultAUMScaledPerSecondsRate(uint _AUMScaledPerSecondsRate) external;

    /// @notice Withdraw fee balance to fee pool for a given index
    /// @param _index Index to withdraw fee balance from
    function withdrawToFeePool(address _index) external;

    /// @notice Index registry address
    /// @return Returns index registry address
    function registry() external view returns (address);

    /// @notice vTokenFactory address
    /// @return Returns vTokenFactory address
    function vTokenFactory() external view returns (address);

    /// @notice Minting fee in base point (BP) format
    /// @return Returns minting fee in base point (BP) format
    function defaultMintingFeeInBP() external view returns (uint16);

    /// @notice Burning fee in base point (BP) format
    /// @return Returns burning fee in base point (BP) format
    function defaultBurningFeeInBP() external view returns (uint16);

    /// @notice AUM scaled per seconds rate
    ///         See setDefaultAUMScaledPerSecondsRate method description for more details.
    /// @return Returns AUM scaled per seconds rate
    function defaultAUMScaledPerSecondsRate() external view returns (uint);

    /// @notice Reweighting logic address
    /// @return Returns reweighting logic address
    function reweightingLogic() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

/// @title Price oracle interface
/// @notice Returns price of single asset in relation to base
interface IPriceOracle {
    /// @notice Updates and returns asset per base
    /// @return Asset per base in UQ
    function refreshedAssetPerBaseInUQ(address _asset) external returns (uint);

    /// @notice Returns last asset per base
    /// @return Asset per base in UQ
    function lastAssetPerBaseInUQ(address _asset) external view returns (uint);
}