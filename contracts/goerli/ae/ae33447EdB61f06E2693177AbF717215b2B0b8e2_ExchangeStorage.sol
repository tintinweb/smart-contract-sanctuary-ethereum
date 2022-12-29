// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;
pragma abicoder v2;

import { Pausable } from '../Pausable.sol';
import { StorageBase } from '../StorageBase.sol';
import { NonReentrant } from '../NonReentrant.sol';
import { ExchangeAutoProxy } from './ExchangeAutoProxy.sol';

import { SafeMath } from '../libraries/SafeMath.sol';
import { LibAssetClasses } from '../libraries/LibAssetClasses.sol';
import { LibAssetTypes } from '../libraries/LibAssetTypes.sol';
import { LibOrderTypes } from '../libraries/LibOrderTypes.sol';
import { LibFillTypes } from '../libraries/LibFillTypes.sol';
import { LibPartTypes } from '../libraries/LibPartTypes.sol';
import { LibFeeSideTypes } from '../libraries/LibFeeSideTypes.sol';
import { LibOrderDataV1Types } from '../libraries/LibOrderDataV1Types.sol';

import { IERC20 } from '../interfaces/IERC20.sol';
import { IERC721 } from '../interfaces/IERC721.sol';
import { IERC165 } from '../interfaces/IERC165.sol';
import { IERC1155 } from '../interfaces/IERC1155.sol';
import { IWrappedCoin } from '../interfaces/IWrappedCoin.sol';
import { IERC2981Royalties } from '../interfaces/IERC2981Royalties.sol';
import { IWhitelist } from '../interfaces/IWhitelist.sol';
import { IStorageBase } from '../interfaces/IStorageBase.sol';
import { IGovernedProxy } from '../interfaces/IGovernedProxy.sol';
import { IGovernedContract } from '../interfaces/IGovernedContract.sol';
import { IExchange } from './IExchange.sol';
import { IExchangeHelper } from './helper/IExchangeHelper.sol';
import { IExchangeStorage } from './IExchangeStorage.sol';
import { IExchangeGovernedProxy } from '../interfaces/IExchangeGovernedProxy.sol';

contract ExchangeStorage is StorageBase, IExchangeStorage {
    // Settings
    address private helperProxy;
    address private whitelistProxy;
    address private orderBook; // Order-book service public key
    address private royaltiesRegistryProxy; // Registers details of royalties to be paid when an NFT asset is sold
    address private defaultFeeReceiver; // Receives protocol fee by default
    address private weth; // Wrapped ETH
    mapping(address => address) private feeReceivers; // Can be set for different addresses to receive protocol fee
    // when paid in different ERC20 assets
    mapping(bytes32 => uint256) private fills; // Order fills indexed by order key hashes
    // 100% of makerOrder is filled when => getFillsValue(rightOrderKeyHash) == rightOrder.takeAsset.value
    // 100% of takerOrder is filled when => getFillsValue(leftOrderKeyHash) == leftOrder.takeAsset.value
    // Fill values are only recorded on-chain for orders with non-zero salt (maker orders registered in off-chain OrderBook and taker
    // orders submitted by third party after being registered in off-chain OrderBook)
    mapping(address => bool) private allowedERC20Assets; // We only allow trading of ETH and some select ERC20 tokens
    // for ERC721 and ERC1155 assets
    uint16 private protocolFeeBps; // Protocol fee (basis points: 10000 <=> 100%) to be paid by seller of ERC721/ERC1155 asset
    // Chain Id (passing it here because Energi testnet chain doesn't return correct chain id)
    uint256 private chainId;

    constructor(
        address _helperProxy,
        address _whitelistProxy,
        address _orderBook,
        address _defaultFeeReceiver,
        address _royaltiesRegistryProxy,
        address _weth, // WETH token address (only ERC20 token allowed by default)
        uint16 _protocolFeeBps,
        uint256 _chainId
    ) {
        helperProxy = _helperProxy;
        whitelistProxy = _whitelistProxy;
        orderBook = _orderBook;
        defaultFeeReceiver = _defaultFeeReceiver;
        royaltiesRegistryProxy = _royaltiesRegistryProxy;
        weth = _weth;
        allowedERC20Assets[_weth] = true;
        protocolFeeBps = _protocolFeeBps;
        chainId = _chainId;
    }

    // Getter functions
    //
    function getHelperProxy() external view override returns (address) {
        return helperProxy;
    }

    function getWhitelistProxy() external view override returns (address) {
        return whitelistProxy;
    }

    function getOrderBook() external view override returns (address) {
        return orderBook;
    }

    function getDefaultFeeReceiver() external view override returns (address) {
        return defaultFeeReceiver;
    }

    function getRoyaltiesRegistryProxy() external view override returns (address) {
        return royaltiesRegistryProxy;
    }

    function getFeeReceiver(address _token) external view override returns (address) {
        // Use address(0) as token address for ETH
        if (feeReceivers[_token] == address(0)) {
            return defaultFeeReceiver;
        }
        return feeReceivers[_token];
    }

    function getWETH() external view override returns (address) {
        return weth;
    }

    function getFill(bytes32 _orderKeyHash) external view override returns (uint256) {
        return fills[_orderKeyHash];
    }

    function isERC20AssetAllowed(address _erc20AssetAddress) external view override returns (bool) {
        return allowedERC20Assets[_erc20AssetAddress];
    }

    function getProtocolFeeBps() external view override returns (uint16) {
        return protocolFeeBps;
    }

    function getChainId() external view override returns (uint256) {
        return chainId;
    }

    // Setter functions (not all implemented in Exchange contract but available for future upgrades)
    //
    function setHelperProxy(address _helperProxy) external override requireOwner {
        helperProxy = _helperProxy;
    }

    function setWhitelistProxy(address _whitelistProxy) external override requireOwner {
        whitelistProxy = _whitelistProxy;
    }

    function setOrderBook(address _orderBook) external override requireOwner {
        orderBook = _orderBook;
    }

    function setDefaultFeeReceiver(address _newDefaultFeeReceiver) public override requireOwner {
        defaultFeeReceiver = _newDefaultFeeReceiver;
    }

    function setRoyaltiesRegistryProxy(address _royaltiesRegistryProxy)
        public
        override
        requireOwner
    {
        royaltiesRegistryProxy = _royaltiesRegistryProxy;
    }

    function setFeeReceiver(address _token, address _recipient) public override requireOwner {
        // Use address(0) as token address for ETH
        feeReceivers[_token] = _recipient;
    }

    function setWETH(address _weth) public override requireOwner {
        weth = _weth;
    }

    function setFill(bytes32 _orderKeyHash, uint256 _value) external override requireOwner {
        fills[_orderKeyHash] = _value;
    }

    function setERC20AssetAllowed(address _erc20AssetAddress, bool _isAllowed)
        external
        override
        requireOwner
    {
        allowedERC20Assets[_erc20AssetAddress] = _isAllowed;
    }

    function setProtocolFeeBps(uint16 _newProtocolFeeBps) public override requireOwner {
        protocolFeeBps = _newProtocolFeeBps;
    }

    function setChainId(uint256 _newChainId) public override requireOwner {
        chainId = _newChainId;
    }
}

contract Exchange is Pausable, NonReentrant, ExchangeAutoProxy, IExchange {
    using SafeMath for uint256;
    // Constants
    bytes4 constant INTERFACE_ID_ERC2981 = bytes4(keccak256('royaltyInfo(uint256,uint256)'));
    bytes4 constant TO_MAKER = bytes4(keccak256('TO_MAKER'));
    bytes4 constant TO_TAKER = bytes4(keccak256('TO_TAKER'));
    bytes4 constant PROTOCOL = bytes4(keccak256('PROTOCOL'));
    bytes4 constant ROYALTY = bytes4(keccak256('ROYALTY'));
    bytes4 constant ORIGIN = bytes4(keccak256('ORIGIN'));
    bytes4 constant PAYOUT = bytes4(keccak256('PAYOUT'));
    uint256 private constant UINT256_MAX = 2**256 - 1;

    // Storage
    ExchangeStorage public _storage;

    // Calls to functions with this modifier must come from proxy or from a whitelisted smart contract
    modifier requireWhitelisted() {
        require(
            msg.sender == proxy || IWhitelist(getWhitelistImpl()).isWhitelisted(msg.sender),
            'Exchange: FORBIDDEN, not whitelisted'
        );
        _;
    }

    modifier onlyWETH() {
        require(
            msg.sender == _storage.getWETH(),
            'Exchange: FORBIDDEN, ETH can only be received from the WETH contract'
        );
        _;
    }

    // ExchangeGovernedProxy should be deployed first and its address passed to this constructor
    constructor(
        address _proxy,
        address _helperProxy,
        address _whitelistProxy,
        address _orderBook, // Order-book service public key
        address _defaultFeeReceiver, // Protocol fee is forwarded to this address by default
        address _royaltiesRegistryProxy,
        address _weth, // WETH token address (only ERC20 token allowed by default)
        address _owner, // Owner of the implementation smart contract
        uint16 _protocolFeeBps,
        uint256 _chainId
    ) Pausable(_owner) ExchangeAutoProxy(_proxy, address(this)) {
        _storage = new ExchangeStorage(
            _helperProxy,
            _whitelistProxy,
            _orderBook,
            _defaultFeeReceiver,
            _royaltiesRegistryProxy,
            _weth,
            _protocolFeeBps,
            _chainId
        );
    }

    // Governance functions
    //
    // This function allows to set sporkProxy address after deployment in order to enable upgrades
    function setSporkProxy(address payable _sporkProxy) public onlyOwner {
        IExchangeGovernedProxy(proxy).setSporkProxy(_sporkProxy);
    }

    // This function is called in order to upgrade to a new Exchange implementation
    function destroy(IGovernedContract _newImpl) external requireProxy {
        IStorageBase(address(_storage)).setOwner(address(_newImpl));
        // Self destruct
        _destroy(_newImpl);
    }

    // This function (placeholder) would be called on the new implementation if necessary for the upgrade
    function migrate(IGovernedContract _oldImpl) external requireProxy {
        _migrate(_oldImpl);
    }

    // Getter functions for implementation contracts addresses
    //
    function getExchangeHelperImpl() private view returns (IExchangeHelper _helper) {
        _helper = IExchangeHelper(
            address(IGovernedProxy(address(uint160(_storage.getHelperProxy()))).impl())
        );
    }

    function getWhitelistImpl() private view returns (address _whitelist) {
        _whitelist = address(IGovernedProxy(address(uint160(_storage.getWhitelistProxy()))).impl());
    }

    function getRoyaltiesRegistryImpl() private view returns (address _royaltiesRegistry) {
        _royaltiesRegistry = address(
            IGovernedProxy(address(uint160(_storage.getRoyaltiesRegistryProxy()))).impl()
        );
    }

    // Exchange functions
    //
    // Cancel an order by setting its fill to Max(uint256) so that it can't ever be matched
    function cancelOrder(LibOrderTypes.Order memory order)
        public
        override
        requireWhitelisted
        whenNotPaused
    {
        require(_callerAddress() == order.maker, 'Exchange: not order maker');
        require(order.salt != 0, 'Exchange: 0 salt cannot be used');
        bytes32 orderKeyHash = getExchangeHelperImpl().hashKey(order);
        _storage.setFill(orderKeyHash, UINT256_MAX);
        // Emit CancelOrder event from proxy
        IExchangeGovernedProxy(proxy).emitCancelOrder(orderKeyHash);
    }

    // Cancel orders by batch
    function batchCancelOrders(LibOrderTypes.Order[] calldata orders) external override {
        // Loop over orders array
        for (uint256 i = 0; i < orders.length; i++) {
            // Cancel order at index i
            cancelOrder(orders[i]);
        }
    }

    // Match orders
    function matchOrders(
        LibOrderTypes.Order memory orderLeft, // Taker order
        bytes memory signatureLeft, // Taker order hash signature
        uint256 matchLeftBeforeTimestamp, // Timestamp after which matching taker order is not allowed by order-book
        bytes memory orderBookSignatureLeft, // Order-book signature for taker order matchAllowance
        LibOrderTypes.Order memory orderRight, // Maker order
        bytes memory signatureRight, // Maker order hash signature
        uint256 matchRightBeforeTimestamp, // Timestamp after which matching maker order is not allowed by order-book
        bytes memory orderBookSignatureRight // Order-book signature for maker order matchAllowance
    ) external payable override requireWhitelisted whenNotPaused {
        // Validate maker and taker orders:
        // Make sure maker does not pay with ETH
        require(
            orderRight.makeAsset.assetType.assetClass != LibAssetClasses.ETH_ASSET_CLASS,
            'Exchange: maker cannot pay with ETH, use WETH instead'
        );
        // Make sure orders are both currently open and not expired, and assets classes are allowed
        getExchangeHelperImpl().validate(orderRight);
        getExchangeHelperImpl().validate(orderLeft);
        // Make sure specific ERC20 tokens used in orders are allowed
        checkERC20TokensAllowed(orderLeft, orderRight);
        // Validate taker and maker addresses if they are specified in orders
        getExchangeHelperImpl().checkCounterparties(orderLeft, orderRight);
        // Validate order-book's matchAllowance signature(s)
        uint256 chainId = _storage.getChainId(); // Assign chainId first to avoid multiple calls
        (bytes32 leftOrderKeyHash, bytes32 rightOrderKeyHash) = getExchangeHelperImpl()
            .validateMatch(
                orderLeft,
                orderRight,
                matchLeftBeforeTimestamp,
                matchRightBeforeTimestamp,
                orderBookSignatureLeft,
                orderBookSignatureRight,
                proxy,
                _storage.getOrderBook(),
                chainId
            );
        // Validate maker and taker orders signatures
        getExchangeHelperImpl().validateOrder(
            orderRight,
            signatureRight,
            _callerAddress(),
            proxy,
            chainId
        );
        getExchangeHelperImpl().validateOrder(
            orderLeft,
            signatureLeft,
            _callerAddress(),
            proxy,
            chainId
        );
        // Match assets and proceed to transfers
        matchAndTransfer(orderLeft, orderRight, leftOrderKeyHash, rightOrderKeyHash);
    }

    function matchAndTransfer(
        LibOrderTypes.Order memory orderLeft, // Taker order
        LibOrderTypes.Order memory orderRight, // Maker order
        bytes32 leftOrderKeyHash, // Taker order keyHash
        bytes32 rightOrderKeyHash // Maker order keyHash
    ) internal {
        // Match assets and return AssetType objects
        (
            LibAssetTypes.AssetType memory makerAssetType, // Asset type order maker expects to receive
            LibAssetTypes.AssetType memory takerAssetType // Asset type order taker expects to receive
        ) = getExchangeHelperImpl().matchAssets(orderLeft, orderRight);
        // Calculate orders fills
        LibFillTypes.FillResult memory newFill = calculateFills(
            orderLeft,
            orderRight,
            leftOrderKeyHash,
            rightOrderKeyHash
        );
        // Process ETH and WETH conversions and transfers to proxy and update makerAssetType if needed
        (makerAssetType) = processEthAndWeth(
            makerAssetType,
            takerAssetType,
            orderLeft,
            orderRight,
            newFill
        );
        // Transfer assets
        doTransfers(takerAssetType, makerAssetType, newFill, orderLeft, orderRight);
        // Emit Match and MatchAssetDetails events from proxy
        IExchangeGovernedProxy(proxy).emitMatch(
            leftOrderKeyHash,
            rightOrderKeyHash,
            orderLeft.maker,
            orderRight.maker,
            newFill.leftOrderTakeValue,
            newFill.rightOrderTakeValue
        );
    }

    function checkERC20TokensAllowed(
        LibOrderTypes.Order memory orderLeft, // Taker order
        LibOrderTypes.Order memory orderRight // Maker order
    ) internal view {
        // If orders involve an ERC20 token, make sure it is allowed
        if (orderRight.makeAsset.assetType.assetClass == LibAssetClasses.ERC20_ASSET_CLASS) {
            require(
                _storage.isERC20AssetAllowed(
                    abi.decode(orderRight.makeAsset.assetType.data, (address))
                ),
                'Exchange: maker order make asset is not allowed'
            );
        }
        if (orderRight.takeAsset.assetType.assetClass == LibAssetClasses.ERC20_ASSET_CLASS) {
            require(
                _storage.isERC20AssetAllowed(
                    abi.decode(orderRight.takeAsset.assetType.data, (address))
                ),
                'Exchange: maker order take asset is not allowed'
            );
        }
        if (orderLeft.makeAsset.assetType.assetClass == LibAssetClasses.ERC20_ASSET_CLASS) {
            require(
                _storage.isERC20AssetAllowed(
                    abi.decode(orderLeft.makeAsset.assetType.data, (address))
                ),
                'Exchange: taker order make asset is not allowed'
            );
        }
        if (orderLeft.takeAsset.assetType.assetClass == LibAssetClasses.ERC20_ASSET_CLASS) {
            require(
                _storage.isERC20AssetAllowed(
                    abi.decode(orderLeft.takeAsset.assetType.data, (address))
                ),
                'Exchange: taker order take asset is not allowed'
            );
        }
    }

    function calculateFills(
        LibOrderTypes.Order memory orderLeft,
        LibOrderTypes.Order memory orderRight,
        bytes32 leftOrderKeyHash,
        bytes32 rightOrderKeyHash
    ) internal returns (LibFillTypes.FillResult memory newFill) {
        // Get recorded orders fills (in case orders were already partially matched)
        uint256 leftOrderTakeAssetFill = getOrderFill(orderLeft, leftOrderKeyHash);
        uint256 rightOrderTakeAssetFill = getOrderFill(orderRight, rightOrderKeyHash);
        // Calculate new orders fills
        newFill = getExchangeHelperImpl().fillOrder(
            orderLeft,
            orderRight,
            leftOrderTakeAssetFill,
            rightOrderTakeAssetFill
        );
        require(newFill.leftOrderTakeValue > 0, 'Exchange: nothing to fill');
        // Set new order fills for orders with non-zero salt (maker orders registered in off-chain OrderBook and taker
        // orders submitted by third party after being registered in off-chain OrderBook)
        if (orderLeft.salt != 0) {
            _storage.setFill(
                leftOrderKeyHash,
                leftOrderTakeAssetFill.add(newFill.leftOrderTakeValue)
            );
        }
        if (orderRight.salt != 0) {
            _storage.setFill(
                rightOrderKeyHash,
                rightOrderTakeAssetFill.add(newFill.rightOrderTakeValue)
            );
        }
    }

    function getOrderFill(LibOrderTypes.Order memory order, bytes32 hash)
        internal
        view
        returns (uint256 fill)
    {
        if (order.salt == 0) {
            // order.salt can be zero for orders that are not registered in off-chain OrderBook
            fill = 0;
        } else {
            fill = _storage.getFill(hash);
        }
    }

    function processEthAndWeth(
        LibAssetTypes.AssetType memory makerAssetType, // Asset type order maker expects to receive
        LibAssetTypes.AssetType memory takerAssetType, // Asset type order taker expects to receive
        LibOrderTypes.Order memory orderLeft,
        LibOrderTypes.Order memory orderRight,
        LibFillTypes.FillResult memory newFill
    ) internal returns (LibAssetTypes.AssetType memory _makerAssetType) {
        // Calculate totalMakeValue and totalTakeValue
        uint256 totalMakeValue; // Total value to be sent by maker to taker
        uint256 totalTakeValue; // Total value to be sent by taker to maker
        (totalMakeValue, totalTakeValue) = getExchangeHelperImpl().calculateTotalTakeAndMakeValues(
            orderLeft,
            orderRight,
            takerAssetType,
            makerAssetType,
            newFill
        );
        _makerAssetType = makerAssetType;
        // Check msg.value
        if (msg.value > 0) {
            // If msg.value > 0, taker should be sending ETH and maker should expect to receive ETH or WETH
            require(
                orderLeft.makeAsset.assetType.assetClass == LibAssetClasses.ETH_ASSET_CLASS &&
                    (makerAssetType.assetClass == LibAssetClasses.ETH_ASSET_CLASS ||
                        makerAssetType.assetClass == LibAssetClasses.WETH_ASSET_CLASS),
                'Exchange: msg.value should be 0'
            );
            // Check if sender sent more ETH than necessary
            if (msg.value > totalTakeValue) {
                // Transfer excess ETH back to sender
                (bool success, bytes memory data) = _callerAddress().call{
                    value: msg.value.sub(totalTakeValue)
                }('');
                require(
                    success && (data.length == 0 || abi.decode(data, (bool))),
                    'Exchange: failed to return excess ETH to sender'
                );
            }
            // Check if maker wishes to receive ETH or WETH
            if (makerAssetType.assetClass == LibAssetClasses.ETH_ASSET_CLASS) {
                // Maker wishes to receive ETH
                // Forward totalTakeValue to proxy (proxy holds funds)
                // selector = bytes4(keccak256(bytes('receiveETH()')))
                (bool success, bytes memory data) = proxy.call{ value: totalTakeValue }(
                    abi.encodeWithSelector(0x3ecfd51e)
                );
                require(
                    success && (data.length == 0 || abi.decode(data, (bool))),
                    'Exchange: failed to forward totalTakeValue to proxy'
                );
            } else {
                // Maker wishes to receive WETH, but taker sent ETH
                // Deposit ETH to get WETH
                address weth = _storage.getWETH();
                IWrappedCoin(weth).deposit{ value: totalTakeValue }();
                // Transfer WETH to proxy (proxy holds funds)
                IERC20(weth).transfer(proxy, totalTakeValue);
                // Update maker asset class (maker will receive WETH from proxy)
                _makerAssetType.assetClass = LibAssetClasses.PROXY_WETH_ASSET_CLASS;
            }
        } else if (makerAssetType.assetClass == LibAssetClasses.ETH_ASSET_CLASS) {
            // If msg.value == 0 and maker wishes to receive ETH
            // Taker must be sending WETH
            require(
                orderLeft.makeAsset.assetType.assetClass == LibAssetClasses.WETH_ASSET_CLASS,
                'Exchange: msg.value should be > 0 or taker should be sending WETH'
            );
            // Transfer WETH from taker to implementation
            address weth = _storage.getWETH();
            IExchangeGovernedProxy(proxy).safeTransferERC20From(
                IERC20(weth),
                orderLeft.maker,
                address(this),
                totalTakeValue
            );
            // Redeem ETH for WETH
            IWrappedCoin(weth).withdraw(totalTakeValue);
            // Forward ETH to proxy via receiveETH function (proxy holds funds)
            // selector = bytes4(keccak256(bytes('receiveETH()')))
            (bool success, bytes memory data) = proxy.call{ value: totalTakeValue }(
                abi.encodeWithSelector(0x3ecfd51e)
            );
            require(
                success && (data.length == 0 || abi.decode(data, (bool))),
                'Exchange: failed to forward redeemed ETH to proxy after redeeming from taker WETH'
            );
        } else if (makerAssetType.assetClass == LibAssetClasses.WETH_ASSET_CLASS) {
            // If msg.value == 0 and maker wishes to receive WETH
            // Taker must be sending WETH
            require(
                orderLeft.makeAsset.assetType.assetClass == LibAssetClasses.WETH_ASSET_CLASS,
                'Exchange: msg.value should be > 0 or taker should be sending WETH'
            );
        } else if (takerAssetType.assetClass == LibAssetClasses.ETH_ASSET_CLASS) {
            // If msg.value == 0 and taker is expecting ETH
            // Maker must be sending WETH (because it is not allowed for maker to be sending ETH)
            require(
                orderRight.makeAsset.assetType.assetClass == LibAssetClasses.WETH_ASSET_CLASS,
                'Exchange: maker should be sending WETH'
            );
            // Transfer WETH from maker to implementation
            address weth = _storage.getWETH();
            IExchangeGovernedProxy(proxy).safeTransferERC20From(
                IERC20(weth),
                orderRight.maker,
                address(this),
                totalMakeValue
            );
            // Redeem ETH for WETH
            IWrappedCoin(weth).withdraw(totalMakeValue);
            // Forward ETH to proxy via receiveETH function (proxy holds funds)
            // selector = bytes4(keccak256(bytes('receiveETH()')))
            (bool success, bytes memory data) = proxy.call{ value: totalMakeValue }(
                abi.encodeWithSelector(0x3ecfd51e)
            );
            require(
                success && (data.length == 0 || abi.decode(data, (bool))),
                'Exchange: failed to forward ETH to proxy after redeeming from maker WETH'
            );
        }
        // In all other cases no ETH will be transferred
    }

    function doTransfers(
        LibAssetTypes.AssetType memory _takerAssetType,
        LibAssetTypes.AssetType memory _makerAssetType,
        LibFillTypes.FillResult memory _fill,
        LibOrderTypes.Order memory _leftOrder,
        LibOrderTypes.Order memory _rightOrder
    ) internal {
        // Determine fee side (and fee asset)
        LibFeeSideTypes.FeeSide feeSide = getExchangeHelperImpl().getFeeSide(
            _makerAssetType.assetClass,
            _takerAssetType.assetClass
        );
        // Get right and left order data (parse payouts and origin fees)
        LibOrderDataV1Types.DataV1 memory leftOrderData = getExchangeHelperImpl().parse(_leftOrder);
        LibOrderDataV1Types.DataV1 memory rightOrderData = getExchangeHelperImpl().parse(
            _rightOrder
        );
        if (feeSide == LibFeeSideTypes.FeeSide.MAKE) {
            // If maker is paying the protocol fee
            // Transfer make asset from maker to taker and transfer protocol fee, royalties and origin fees
            doTransfersWithFees(
                _fill.leftOrderTakeValue, // Value to be transferred from maker to taker
                _rightOrder.maker, // Maker
                rightOrderData, // Maker order data
                leftOrderData, // Taker order data
                _makerAssetType, // Maker asset type
                _takerAssetType, // Taker asset type
                TO_TAKER // Payouts will be transferred to taker side
            );
            // Transfer order payouts from taker side to maker side
            transferPayouts(
                _makerAssetType, // Maker asset type
                _fill.rightOrderTakeValue, // Value to be transferred from taker to maker
                _leftOrder.maker, // Taker
                rightOrderData.payouts, // Maker order payouts data
                TO_MAKER // Payouts will be transferred to maker side
            );
        } else if (feeSide == LibFeeSideTypes.FeeSide.TAKE) {
            // If taker is paying the protocol fee
            // Transfer take asset from taker to maker and transfer protocol fee, royalties and origin fees
            doTransfersWithFees(
                _fill.rightOrderTakeValue, // Value to be transferred from taker to maker
                _leftOrder.maker, // Taker
                leftOrderData, // Taker order data
                rightOrderData, // Maker order data
                _takerAssetType, // Taker asset type
                _makerAssetType, // Maker asset type
                TO_MAKER // Payouts will be transferred to maker side
            );
            // Transfer order payouts from maker side to taker side
            transferPayouts(
                _takerAssetType, // Taker asset type
                _fill.leftOrderTakeValue, // Value to be transferred from maker to taker
                _rightOrder.maker, // Maker
                leftOrderData.payouts, // Taker order payouts data
                TO_TAKER // Payouts will be transferred to taker side
            );
        } else {
            // If no trading fee is paid: transfer payouts to taker and maker
            transferPayouts(
                _makerAssetType,
                _fill.leftOrderTakeValue,
                _leftOrder.maker,
                rightOrderData.payouts,
                TO_MAKER
            );
            transferPayouts(
                _takerAssetType,
                _fill.rightOrderTakeValue,
                _rightOrder.maker,
                leftOrderData.payouts,
                TO_TAKER
            );
        }
    }

    function doTransfersWithFees(
        uint256 _amount,
        address _from,
        LibOrderDataV1Types.DataV1 memory _feePayerOrderData,
        LibOrderDataV1Types.DataV1 memory _otherOrderData,
        LibAssetTypes.AssetType memory _feePayerAssetType,
        LibAssetTypes.AssetType memory _otherAssetType,
        bytes4 _transferDirection
    ) internal {
        // Add origin fees to order amount to get _totalAmount
        // Origin fees are paid by taker if they are defined in taker order, and/or by maker if they are defined in
        // maker order. Only taker origin fees are added on top of _totalAmount, while maker origin fees are subtracted
        // from the amount that is paid to maker.
        uint256 _totalAmount = getExchangeHelperImpl().calculateTotalAmount(
            _amount,
            _feePayerOrderData.originFees
        );
        // Transfer protocol fee (ERC721/ERC1155 seller pays protocol fee by receiving less than the order amount)
        uint256 rest = transferProtocolFee(
            _totalAmount,
            _amount,
            _from,
            _otherAssetType,
            _transferDirection
        );
        // Transfer royalties
        rest = transferRoyalties(
            _otherAssetType,
            _feePayerAssetType,
            rest,
            _amount,
            _from,
            _transferDirection
        );
        // Transfer origin fees (both sides)
        // Order data may carry instructions to distribute origin fees to several addresses as a percentage of the order
        // amount
        (rest, ) = transferFees(
            _otherAssetType,
            rest,
            _amount,
            _feePayerOrderData.originFees,
            _from,
            _transferDirection,
            ORIGIN
        );
        (rest, ) = transferFees(
            _otherAssetType,
            rest,
            _amount,
            _otherOrderData.originFees,
            _from,
            _transferDirection,
            ORIGIN
        );
        // Transfer order payouts (one side)
        // Order data may carry instructions to distribute payouts to several addresses as a percentage of the order
        // amount. If this is not the case, by default all payouts are made to order maker.
        transferPayouts(_otherAssetType, rest, _from, _otherOrderData.payouts, _transferDirection);
    }

    // Transfer functions
    //
    function transferProtocolFee(
        uint256 _totalAmount,
        uint256 _amount,
        address _from,
        LibAssetTypes.AssetType memory _assetType,
        bytes4 _transferDirection
    ) internal returns (uint256) {
        // We calculate the following:
        // 1) _protocolFee: it is the total protocol fee to be transferred by feePayer. Expressed as a percentage of the
        // order amount, it is the value of PROTOCOL_FEE. It is paid by the side of the order that sells the
        // ERC721/ERC1155 asset (transferred by feePayer but subtracted from the amount that will be
        // received by the other side of the order). This is achieved by passing protocolFee to
        // LibExchange.subFeeInBps function below, and subtracting it from the totalAmount value which has been calculated
        // as totalAmount = amount + originFees
        // 2) _rest: it is the amount that will remain after transferring protocol fee. It is calculated in
        // LibExchange.subFeeInBps as _rest = _totalAmount - protocolFee
        (uint256 _rest, uint256 _protocolFee) = getExchangeHelperImpl().subFeeInBps(
            _totalAmount,
            _amount,
            _storage.getProtocolFeeBps()
        );
        // Determine fee asset address in cases where fee asset is ERC20 or ERC1155
        if (_protocolFee > 0) {
            address tokenAddress = address(0);
            if (
                _assetType.assetClass == LibAssetClasses.ERC20_ASSET_CLASS ||
                _assetType.assetClass == LibAssetClasses.WETH_ASSET_CLASS ||
                _assetType.assetClass == LibAssetClasses.PROXY_WETH_ASSET_CLASS
            ) {
                tokenAddress = abi.decode(_assetType.data, (address));
                // If token is WETH, ETH is redeemed before transferring protocol fee in ETH
                address weth = _storage.getWETH();
                if (tokenAddress == weth) {
                    if (_assetType.assetClass == LibAssetClasses.PROXY_WETH_ASSET_CLASS) {
                        // Transfer WETH from proxy to implementation
                        IExchangeGovernedProxy(proxy).safeTransferERC20(
                            IERC20(_storage.getWETH()),
                            address(this),
                            _protocolFee
                        );
                    } else {
                        // Transfer WETH from user to implementation via proxy
                        IExchangeGovernedProxy(proxy).safeTransferERC20From(
                            IERC20(tokenAddress),
                            _from,
                            address(this),
                            _protocolFee
                        );
                    }
                    // Redeem ETH for WETH
                    IWrappedCoin(weth).withdraw(_protocolFee);
                    // Forward ETH to proxy via receiveETH function (proxy holds funds)
                    // selector = bytes4(keccak256(bytes('receiveETH()')))
                    (bool success, bytes memory data) = proxy.call{ value: _protocolFee }(
                        abi.encodeWithSelector(0x3ecfd51e)
                    );
                    require(
                        success && (data.length == 0 || abi.decode(data, (bool))),
                        'Exchange::transferProtocolFee: failed to forward redeemed ETH to proxy'
                    );
                    // Update _assetType to ETH
                    _assetType = LibAssetTypes.AssetType(
                        LibAssetClasses.ETH_ASSET_CLASS,
                        bytes('')
                    );
                    // Update tokenAddress accordingly (address(0) <=> ETH)
                    tokenAddress = address(0);
                }
            } else if (_assetType.assetClass == LibAssetClasses.ERC1155_ASSET_CLASS) {
                uint256 tokenId;
                (tokenAddress, tokenId) = abi.decode(_assetType.data, (address, uint256));
            }
            // Transfer protocol fee
            transfer(
                LibAssetTypes.Asset(_assetType, _protocolFee),
                _from,
                _storage.getFeeReceiver(tokenAddress),
                _transferDirection,
                PROTOCOL
            );
        }
        return _rest;
    }

    function transferRoyalties(
        LibAssetTypes.AssetType memory _otherAssetType,
        LibAssetTypes.AssetType memory _feePayerAssetType,
        uint256 _rest,
        uint256 _amount,
        address _from,
        bytes4 _transferDirection
    ) internal returns (uint256 _newRest) {
        // Get royalties to be paid for considered asset (expressed in bps of order amount)
        LibPartTypes.Part[] memory royalties = getExchangeHelperImpl().getRoyaltiesByAssetType(
            _feePayerAssetType,
            getRoyaltiesRegistryImpl()
        );
        // Initialize _newRest in case no royalty is paid
        _newRest = _rest;
        // Transfer royalties
        uint256 totalRoyaltiesBps;
        if (royalties.length == 0) {
            // Try to get royalties from the token contract itself assuming it implements EIP-2981 standard
            (address tokenAddress, uint256 tokenId) = abi.decode(
                _feePayerAssetType.data,
                (address, uint256)
            );
            // Check first if token supports ERC2981 interface
            try IERC165(tokenAddress).supportsInterface(INTERFACE_ID_ERC2981) returns (
                bool isSupported
            ) {
                if (isSupported) {
                    // If token supports ERC2981 interface, call royaltyInfo()
                    (address _royaltyReceiver, uint256 _royaltyAmount) = IERC2981Royalties(
                        tokenAddress
                    ).royaltyInfo(tokenId, _amount);
                    // ERC-2981 royaltyInfo returns absolute royalty amount, here we calculate the royalty value in bps
                    totalRoyaltiesBps = (_royaltyAmount * 10000) / _amount;
                    // Transfer royalties
                    _newRest = transferERC2981Royalties(
                        _otherAssetType,
                        _rest,
                        _royaltyReceiver,
                        _royaltyAmount,
                        _from,
                        _transferDirection,
                        ROYALTY
                    );
                }
            } catch {}
        } else {
            // Transfer royalties
            (_newRest, totalRoyaltiesBps) = transferFees(
                _otherAssetType,
                _rest,
                _amount,
                royalties,
                _from,
                _transferDirection,
                ROYALTY
            );
        }
        // Make sure royalties are not above 50% of sale price
        require(totalRoyaltiesBps <= 5000, 'Exchange: royalties can not be above 50%');
    }

    // This function transfers royalties or origin fees
    function transferFees(
        LibAssetTypes.AssetType memory _otherAssetType,
        uint256 _rest,
        uint256 _amount,
        LibPartTypes.Part[] memory _fees,
        address _from,
        bytes4 _transferDirection,
        bytes4 _transferType
    ) internal returns (uint256 _newRest, uint256 _totalFeesBps) {
        _totalFeesBps = 0;
        _newRest = _rest;
        for (uint256 i = 0; i < _fees.length; i++) {
            // Add fee expressed in bps to _totalFeesBps
            _totalFeesBps = _totalFeesBps.add(_fees[i].value);
            // Subtract fee as a percentage of _amount from _newRest  and get feeValue
            (uint256 newRestValue, uint256 feeValue) = getExchangeHelperImpl().subFeeInBps(
                _newRest,
                _amount,
                _fees[i].value
            );
            _newRest = newRestValue;
            // Transfer fee
            if (feeValue > 0) {
                transfer(
                    LibAssetTypes.Asset(_otherAssetType, feeValue),
                    _from,
                    _fees[i].account,
                    _transferDirection,
                    _transferType
                );
            }
        }
    }

    // This function transfers ERC2981 royalties
    function transferERC2981Royalties(
        LibAssetTypes.AssetType memory _otherAssetType,
        uint256 _rest,
        address _royaltyReceiver,
        uint256 _royaltyAmount,
        address _from,
        bytes4 _transferDirection,
        bytes4 _transferType
    ) internal returns (uint256 _newRest) {
        // Subtract royalty amount from rest
        _newRest = _rest.sub(_royaltyAmount);
        // Transfer royalty
        if (_royaltyAmount > 0) {
            transfer(
                LibAssetTypes.Asset(_otherAssetType, _royaltyAmount),
                _from,
                _royaltyReceiver,
                _transferDirection,
                _transferType
            );
        }
    }

    // This function transfers the remaining amount after protocol fee, royalties and origin fees have been transferred
    function transferPayouts(
        LibAssetTypes.AssetType memory _assetType,
        uint256 _amount,
        address _from,
        LibPartTypes.Part[] memory _payouts,
        bytes4 _transferDirection
    ) internal {
        uint256 sumBps = 0; // 10,000 Bps == 100%
        uint256 rest = _amount;
        // Iterate over all payout addresses except the last one and transfer respective payouts
        for (uint256 i = 0; i < _payouts.length - 1; i++) {
            // Calculate value to transfer as a percentage of remaining amount
            uint256 payoutAmount = getExchangeHelperImpl().bps(_amount, _payouts[i].value);
            // Add payout expressed as bps to sumBps
            sumBps = sumBps.add(_payouts[i].value);
            if (payoutAmount > 0) {
                // Subtract payoutAmount from rest
                rest = rest.sub(payoutAmount);
                // Transfer payout
                transfer(
                    LibAssetTypes.Asset(_assetType, payoutAmount),
                    _from,
                    _payouts[i].account,
                    _transferDirection,
                    PAYOUT
                );
            }
        }
        // The last payout receives whatever is left to ensure that there are no rounding issues
        LibPartTypes.Part memory lastPayout = _payouts[_payouts.length - 1];
        sumBps = sumBps.add(lastPayout.value);
        // Make sure all payouts add up to 100%
        require(
            sumBps == 10000,
            'Exchange: the sum of all payouts did not add up to 100% of the available funds'
        );
        if (rest > 0) {
            // Transfer last payout
            transfer(
                LibAssetTypes.Asset(_assetType, rest),
                _from,
                lastPayout.account,
                _transferDirection,
                PAYOUT
            );
        }
    }

    function transfer(
        LibAssetTypes.Asset memory _asset,
        address _from,
        address _to,
        bytes4 _transferDirection,
        bytes4 _transferType
    ) internal noReentry whenNotPaused {
        require(_to != address(0), 'Exchange: can not transfer to zero address');
        require(_asset.value != 0, 'Exchange: transfer amount can not be zero');

        if (_asset.assetType.assetClass == LibAssetClasses.ETH_ASSET_CLASS) {
            // Transfer ETH from proxy
            IExchangeGovernedProxy(proxy).safeTransferETH(_to, _asset.value);
        } else if (_asset.assetType.assetClass == LibAssetClasses.PROXY_WETH_ASSET_CLASS) {
            // Transfer WETH from proxy
            IExchangeGovernedProxy(proxy).safeTransferERC20(
                IERC20(_storage.getWETH()),
                _to,
                _asset.value
            );
        } else if (_asset.assetType.assetClass == LibAssetClasses.WETH_ASSET_CLASS) {
            // Transfer WETH from user via proxy
            IExchangeGovernedProxy(proxy).safeTransferERC20From(
                IERC20(_storage.getWETH()),
                _from,
                _to,
                _asset.value
            );
        } else if (_asset.assetType.assetClass == LibAssetClasses.ERC20_ASSET_CLASS) {
            address token = abi.decode(_asset.assetType.data, (address));
            // Transfer ERC20 token from user via proxy
            IExchangeGovernedProxy(proxy).safeTransferERC20From(
                IERC20(token),
                _from,
                _to,
                _asset.value
            );
        } else if (_asset.assetType.assetClass == LibAssetClasses.ERC721_ASSET_CLASS) {
            (address token, uint256 tokenId) = abi.decode(
                _asset.assetType.data,
                (address, uint256)
            );
            require(_asset.value == 1, 'Exchange: can only transfer one ERC721');
            // Transfer ERC721 token from user via proxy
            IExchangeGovernedProxy(proxy).safeTransferERC721From(
                IERC721(token),
                _from,
                _to,
                tokenId
            );
        } else if (_asset.assetType.assetClass == LibAssetClasses.ERC1155_ASSET_CLASS) {
            (address token, uint256 tokenId) = abi.decode(
                _asset.assetType.data,
                (address, uint256)
            );
            // Transfer ERC1155 token from user via proxy
            IExchangeGovernedProxy(proxy).safeTransferERC1155From(
                IERC1155(token),
                _from,
                _to,
                tokenId,
                _asset.value,
                ''
            );
        } else {
            // Revert if asset class is unknown
            revert('Exchange: asset class unknown');
        }
        // Emit Transfer event from proxy
        IExchangeGovernedProxy(proxy).emitTransfer(
            _asset.assetType.assetClass,
            _from,
            _to,
            _asset.assetType.data,
            _asset.value,
            _transferDirection,
            _transferType
        );
    }

    // Payable fallback function only accepts ETH redemptions from the WETH contract
    receive() external payable onlyWETH {}

    // ERC20 Asset transfer function (should never be needed but are implemented for safety)
    //
    // N.B. If it is ever needed to transfer ETH out of this contract this can be achieved by upgrading the contract.
    // Any ETH held by this contract would be transferred via self destruct to the new implementation which should
    // implement the ETH transfer function (it was not possible to implement such a function here due to contract size
    // limitation)
    //
    function safeTransferERC20(
        address token,
        address to,
        uint256 value
    ) external override noReentry onlyOwner {
        require(IERC20(token).transfer(to, value), 'Exchange: failed to transfer ERC20');
    }

    // Setter functions
    //
    // Set protocol fee
    function setProtocolFeeBps(uint16 newProtocolFeeBps) external override onlyOwner {
        _storage.setProtocolFeeBps(newProtocolFeeBps);
    }

    // Set defaultFeeReceiver address
    function setDefaultFeeReceiver(address recipient) external override onlyOwner {
        _storage.setDefaultFeeReceiver(recipient);
    }

    // Set feeReceiver address to receive fees for a specific token
    function setFeeReceiver(address token, address recipient) external override onlyOwner {
        // Use address(0) as token address for ETH
        _storage.setFeeReceiver(token, recipient);
    }

    // Allow/disallow ERC20 asset to be used in orders
    function setERC20AssetAllowed(address _erc20AssetAddress, bool _isAllowed)
        external
        override
        onlyOwner
    {
        _storage.setERC20AssetAllowed(_erc20AssetAddress, _isAllowed);
    }

    // External getter functions
    //
    function getOrderKeyHash(LibOrderTypes.Order calldata order)
        external
        view
        override
        returns (bytes32 _orderKeyHash)
    {
        _orderKeyHash = getExchangeHelperImpl().hashKey(order);
    }

    function getWhitelistProxy() external view override returns (address _whitelistProxy) {
        _whitelistProxy = _storage.getWhitelistProxy();
    }

    function getOrderBook() external view override returns (address _orderBook) {
        _orderBook = _storage.getOrderBook();
    }

    function getProtocolFeeBps() external view override returns (uint16) {
        return _storage.getProtocolFeeBps();
    }

    function getDefaultFeeReceiver() external view override returns (address) {
        return _storage.getDefaultFeeReceiver();
    }

    function getRoyaltiesRegistryProxy() external view override returns (address) {
        return _storage.getRoyaltiesRegistryProxy();
    }

    function getFeeReceiver(address _token) external view override returns (address) {
        // Use address(0) as token address for ETH
        return _storage.getFeeReceiver(_token);
    }

    function getOrderFill(bytes32 orderKeyHash) external view override returns (uint256) {
        return _storage.getFill(orderKeyHash);
    }

    function getOrdersFills(bytes32[] calldata ordersKeyHashes)
        external
        view
        override
        returns (uint256[] memory)
    {
        uint256[] memory ordersFills = new uint256[](ordersKeyHashes.length);
        // Loop over ordersKeyHashes array
        for (uint256 i = 0; i < ordersKeyHashes.length; i++) {
            // Push order fill to ordersFills array
            ordersFills[i] = _storage.getFill(ordersKeyHashes[i]);
        }
        return ordersFills;
    }

    function isERC20AssetAllowed(address _erc20AssetAddress) external view override returns (bool) {
        return _storage.isERC20AssetAllowed(_erc20AssetAddress);
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;

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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;

library LibPartTypes {
    struct Part {
        address payable account;
        // `value` is used to capture basepoints (bps) for royalties, origin fees, and payouts
        // `value` can only range from 0 to 10,000, therefore uint16 with a range of 0 to 65,535 suffices
        uint16 value;
    }

    // use for external providers that implement values based on uint96 (e.g. Rarible)
    struct Part96 {
        address payable account;
        uint96 value;
    }

    // use for external providers following the LooksRare pattern
    struct FeeInfo {
        address setter;
        address receiver;
        uint256 fee;
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;

import { LibAssetTypes } from './LibAssetTypes.sol';

library LibOrderTypes {
    struct Order {
        address maker;
        LibAssetTypes.Asset makeAsset;
        address taker;
        LibAssetTypes.Asset takeAsset;
        uint256 salt;
        uint256 start;
        uint256 end;
        bytes4 dataType;
        bytes data;
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;
pragma abicoder v2;

import { LibPartTypes } from './LibPartTypes.sol';

library LibOrderDataV1Types {
    bytes4 public constant V1 = bytes4(keccak256('V1'));

    struct DataV1 {
        LibPartTypes.Part[] payouts;
        LibPartTypes.Part[] originFees;
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;

library LibFillTypes {
    struct FillResult {
        uint256 rightOrderTakeValue;
        uint256 leftOrderTakeValue;
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;

library LibFeeSideTypes {
    enum FeeSide {
        NONE,
        MAKE,
        TAKE
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;

library LibAssetTypes {
    struct AssetType {
        bytes4 assetClass;
        bytes data; // Token address (and id in the case of ERC721 and ERC1155)
    }

    struct Asset {
        AssetType assetType;
        uint256 value;
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;

library LibAssetClasses {
    // Asset classes
    bytes4 public constant ETH_ASSET_CLASS = bytes4(keccak256('ETH'));
    bytes4 public constant WETH_ASSET_CLASS = bytes4(keccak256('WETH'));
    bytes4 public constant PROXY_WETH_ASSET_CLASS = bytes4(keccak256('PROXY_WETH'));
    bytes4 public constant ERC20_ASSET_CLASS = bytes4(keccak256('ERC20'));
    bytes4 public constant ERC721_ASSET_CLASS = bytes4(keccak256('ERC721'));
    bytes4 public constant ERC1155_ASSET_CLASS = bytes4(keccak256('ERC1155'));
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;

interface IWrappedCoin {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;

interface IWhitelist {
    function isWhitelisted(address _item) external view returns (bool);
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

// Energi Governance system is the fundamental part of Energi Core.

// NOTE: It's not allowed to change the compiler due to byte-to-byte
// match requirement.

pragma solidity 0.7.6;

import { IProposal } from './IProposal.sol';
import { IGovernedContract } from './IGovernedContract.sol';

/**
 * Interface of UpgradeProposal
 */
interface IUpgradeProposal is IProposal {
    function impl() external view returns (IGovernedContract);
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;

interface IStorageBase {
    function setOwner(address _newOwner) external;
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

// Energi Governance system is the fundamental part of Energi Core.

// NOTE: It's not allowed to change the compiler due to byte-to-byte
// match requirement.

pragma solidity 0.7.6;

interface IProposal {
    function parent() external view returns (address);

    function created_block() external view returns (uint256);

    function deadline() external view returns (uint256);

    function fee_payer() external view returns (address payable);

    function fee_amount() external view returns (uint256);

    function accepted_weight() external view returns (uint256);

    function rejected_weight() external view returns (uint256);

    function total_weight() external view returns (uint256);

    function quorum_weight() external view returns (uint256);

    function isFinished() external view returns (bool);

    function isAccepted() external view returns (bool);

    function withdraw() external;

    function destroy() external;

    function collect() external;

    function voteAccept() external;

    function voteReject() external;

    function setFee() external payable;

    function canVote(address owner) external view returns (bool);
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

// Energi Governance system is the fundamental part of Energi Core.

// NOTE: It's not allowed to change the compiler due to byte-to-byte
// match requirement.

pragma solidity 0.7.6;
//pragma experimental SMTChecker;

import { IGovernedContract } from './IGovernedContract.sol';
import { IUpgradeProposal } from './IUpgradeProposal.sol';

/**
 * Genesis version of IGovernedProxy interface.
 *
 * Base Consensus interface for upgradable contracts proxy.
 * Unlike common approach, the implementation is NOT expected to be
 * called through delegatecall() to minimize risks of shared storage.
 *
 * NOTE: it MUST NOT change after blockchain launch!
 */
interface IGovernedProxy {
    event UpgradeProposal(IGovernedContract indexed impl, IUpgradeProposal proposal);

    event Upgraded(IGovernedContract indexed impl, IUpgradeProposal proposal);

    function impl() external view returns (IGovernedContract);

    function initialize(address _impl) external;

    function proposeUpgrade(IGovernedContract _newImpl, uint256 _period)
        external
        payable
        returns (IUpgradeProposal);

    function upgrade(IUpgradeProposal _proposal) external;

    function upgradeProposalImpl(IUpgradeProposal _proposal)
        external
        view
        returns (IGovernedContract new_impl);

    function listUpgradeProposals() external view returns (IUpgradeProposal[] memory proposals);

    function collectUpgradeProposal(IUpgradeProposal _proposal) external;

    fallback() external;

    receive() external payable;
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

// Energi Governance system is the fundamental part of Energi Core.

// NOTE: It's not allowed to change the compiler due to byte-to-byte
// match requirement.

pragma solidity 0.7.6;

/**
 * Genesis version of GovernedContract interface.
 *
 * Base Consensus interface for upgradable contracts.
 * Unlike common approach, the implementation is NOT expected to be
 * called through delegatecall() to minimize risks of shared storage.
 *
 * NOTE: it MUST NOT change after blockchain launch!
 */

interface IGovernedContract {
    // Return actual proxy address for secure validation
    function proxy() external view returns (address);
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;

import { IERC20 } from './IERC20.sol';
import { IERC721 } from './IERC721.sol';
import { IERC1155 } from './IERC1155.sol';

interface IExchangeGovernedProxy {
    function initialize(address _impl) external;

    function setSporkProxy(address payable _sporkProxy) external;

    function safeTransferERC20(
        IERC20 token,
        address to,
        uint256 value
    ) external;

    function safeTransferERC20From(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) external;

    function safeTransferERC721From(
        IERC721 token,
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferERC1155From(
        IERC1155 token,
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external;

    function safeTransferETH(address to, uint256 amount) external;

    function receiveETH() external payable;

    function emitMatch(
        bytes32 leftHash,
        bytes32 rightHash,
        address leftMaker,
        address rightMaker,
        uint256 newLeftFill,
        uint256 newRightFill
    ) external;

    function emitCancelOrder(bytes32 hash) external;

    function emitTransfer(
        bytes4 assetClass,
        address from,
        address to,
        bytes calldata assetData,
        uint256 assetValue,
        bytes4 transferDirection,
        bytes4 transferType
    ) external;
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;

import { IERC165 } from './IERC165.sol';

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;

/// @title IERC2981Royalties
/// @dev Interface for the ERC2981 - Token Royalty standard
interface IERC2981Royalties {
    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _value - the sale price of the NFT asset specified by _tokenId
    /// @return _receiver - address of who should be sent the royalty payment
    /// @return _royaltyAmount - the royalty payment amount for value sale price
    function royaltyInfo(uint256 _tokenId, uint256 _value)
        external
        view
        returns (address _receiver, uint256 _royaltyAmount);

    function setRoyalty(
        uint256 _tokenId,
        address _receiver,
        uint256 _royaltyBps
    ) external;
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;

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

// Copyright 2022 Energi Core

pragma solidity 0.7.6;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
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

// Copyright 2022 Energi Core

pragma solidity 0.7.6;

import { IERC165 } from './IERC165.sol';

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;
pragma abicoder v2;

import { LibAssetTypes } from '../../libraries/LibAssetTypes.sol';
import { LibOrderTypes } from '../../libraries/LibOrderTypes.sol';
import { LibFillTypes } from '../../libraries/LibFillTypes.sol';
import { LibPartTypes } from '../../libraries/LibPartTypes.sol';
import { LibFeeSideTypes } from '../../libraries/LibFeeSideTypes.sol';
import { LibOrderDataV1Types } from '../../libraries/LibOrderDataV1Types.sol';

interface IExchangeHelper {
    // Functions
    function bps(uint256 value, uint16 bpsValue) external pure returns (uint256);

    function fillOrder(
        LibOrderTypes.Order calldata leftOrder,
        LibOrderTypes.Order calldata rightOrder,
        uint256 leftOrderTakeAssetFill,
        uint256 rightOrderTakeAssetFill
    ) external pure returns (LibFillTypes.FillResult memory);

    function hashKey(LibOrderTypes.Order calldata order) external pure returns (bytes32);

    function validate(LibOrderTypes.Order calldata order) external view;

    function validateOrder(
        LibOrderTypes.Order calldata order,
        bytes calldata _signature,
        address _callerAddress,
        address _verifyingContractProxy,
        uint256 chainId
    ) external view;

    function validateMatch(
        LibOrderTypes.Order calldata orderLeft,
        LibOrderTypes.Order calldata orderRight,
        uint256 matchLeftBeforeTimestamp,
        uint256 matchRightBeforeTimestamp,
        bytes memory orderBookSignatureLeft,
        bytes memory orderBookSignatureRight,
        address verifyingContractProxy,
        address orderBook,
        uint256 chainId
    ) external view returns (bytes32, bytes32);

    function matchAssets(
        LibOrderTypes.Order calldata orderLeft,
        LibOrderTypes.Order calldata orderRight
    ) external pure returns (LibAssetTypes.AssetType memory, LibAssetTypes.AssetType memory);

    function calculateTotalAmount(uint256 _amount, LibPartTypes.Part[] calldata _orderOriginFees)
        external
        pure
        returns (uint256);

    function subFeeInBps(
        uint256 _rest,
        uint256 _total,
        uint16 _feeInBps
    ) external pure returns (uint256, uint256);

    function getRoyaltiesByAssetType(
        LibAssetTypes.AssetType calldata assetType,
        address _royaltiesRegistry
    ) external view returns (LibPartTypes.Part[] memory);

    function parse(LibOrderTypes.Order memory order)
        external
        pure
        returns (LibOrderDataV1Types.DataV1 memory);

    function getFeeSide(bytes4 makerAssetClass, bytes4 takerAssetClass)
        external
        pure
        returns (LibFeeSideTypes.FeeSide);

    function checkCounterparties(
        LibOrderTypes.Order memory orderLeft,
        LibOrderTypes.Order memory orderRight
    ) external pure;

    function calculateTotalTakeAndMakeValues(
        LibOrderTypes.Order memory _leftOrder,
        LibOrderTypes.Order memory _rightOrder,
        LibAssetTypes.AssetType memory _takerAssetType,
        LibAssetTypes.AssetType memory _makerAssetType,
        LibFillTypes.FillResult memory _fill
    ) external pure returns (uint256 _totalMakeValue, uint256 _totalTakeValue);
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;

interface IExchangeStorage {
    function getHelperProxy() external view returns (address);

    function getWhitelistProxy() external view returns (address);

    function getOrderBook() external view returns (address);

    function getDefaultFeeReceiver() external view returns (address);

    function getRoyaltiesRegistryProxy() external view returns (address);

    function getFeeReceiver(address _token) external view returns (address);

    function getWETH() external view returns (address);

    function getFill(bytes32 _orderKeyHash) external view returns (uint256);

    function isERC20AssetAllowed(address _erc20AssetAddress) external view returns (bool);

    function getProtocolFeeBps() external view returns (uint16);

    function getChainId() external view returns (uint256);

    function setHelperProxy(address _helperProxy) external;

    function setWhitelistProxy(address _whitelistProxy) external;

    function setOrderBook(address _orderBook) external;

    function setDefaultFeeReceiver(address _newDefaultFeeReceiver) external;

    function setRoyaltiesRegistryProxy(address _royaltiesRegistryProxy) external;

    function setFeeReceiver(address _token, address _recipient) external;

    function setWETH(address _weth) external;

    function setFill(bytes32 _orderKeyHash, uint256 _value) external;

    function setERC20AssetAllowed(address _erc20AssetAddress, bool _isAllowed) external;

    function setProtocolFeeBps(uint16 _newProtocolFeeBps) external;

    function setChainId(uint256 _newChainId) external;
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;
pragma abicoder v2;

import { LibOrderTypes } from '../libraries/LibOrderTypes.sol';

interface IExchange {
    // Core features
    function matchOrders(
        LibOrderTypes.Order memory orderLeft,
        bytes memory signatureLeft,
        uint256 matchLeftBeforeTimestamp,
        bytes memory orderBookSignatureLeft,
        LibOrderTypes.Order memory orderRight,
        bytes memory signatureRight,
        uint256 matchRightBeforeTimestamp,
        bytes memory orderBookSignatureRight
    ) external payable;

    function cancelOrder(LibOrderTypes.Order memory order) external;

    function batchCancelOrders(LibOrderTypes.Order[] calldata orders) external;

    // Asset transfer
    function safeTransferERC20(
        address token,
        address to,
        uint256 value
    ) external;

    // Setter functions
    function setProtocolFeeBps(uint16 newProtocolFeeBps) external;

    function setDefaultFeeReceiver(address recipient) external;

    function setFeeReceiver(address token, address recipient) external;

    function setERC20AssetAllowed(address _erc20AssetAddress, bool _isAllowed) external;

    // Getter functions
    function getOrderKeyHash(LibOrderTypes.Order calldata order)
        external
        view
        returns (bytes32 _orderKeyHash);

    function getWhitelistProxy() external view returns (address _whitelistProxy);

    function getOrderBook() external view returns (address _orderBook);

    function getProtocolFeeBps() external view returns (uint16);

    function getDefaultFeeReceiver() external view returns (address);

    function getRoyaltiesRegistryProxy() external view returns (address);

    function getFeeReceiver(address _token) external view returns (address);

    function getOrderFill(bytes32 orderKeyHash) external returns (uint256);

    function getOrdersFills(bytes32[] calldata ordersKeyHashes)
        external
        view
        returns (uint256[] memory);

    function isERC20AssetAllowed(address _erc20AssetAddress) external view returns (bool);
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;

import { GovernedContract } from '../GovernedContract.sol';
import { IGovernedProxy } from '../interfaces/IGovernedProxy.sol';

/**
 * ExchangeAutoProxy is a version of GovernedContract which deploys its own proxy.
 * This is useful to avoid a circular dependency between GovernedContract and GovernedProxy
 * wherein they need each other's address in the constructor.
 * If you want a new governed contract to create a proxy, pass address(0) when deploying
 * otherwise, you can pass a proxy address like in normal GovernedContract
 */

contract ExchangeAutoProxy is GovernedContract {
    constructor(address _proxy, address _impl) GovernedContract(_proxy) {
        proxy = _proxy;
        IGovernedProxy(payable(proxy)).initialize(_impl);
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;

import { IGovernedContract } from './interfaces/IGovernedContract.sol';

/**
 * Base for contract storage (SC-14).
 *
 * NOTE: it MUST NOT change after blockchain launch!
 */

contract StorageBase {
    address payable internal owner;

    modifier requireOwner() {
        require(msg.sender == address(owner), 'StorageBase: Not owner!');
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function setOwner(IGovernedContract _newOwner) external requireOwner {
        owner = address(uint160(address(_newOwner)));
    }

    function kill() external requireOwner {
        selfdestruct(msg.sender);
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;

import { Context } from './Context.sol';
import { Ownable } from './Ownable.sol';
import { SafeMath } from './libraries/SafeMath.sol';

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Context, Ownable {
    using SafeMath for uint256;

    /**
     * @dev Emitted when pause() is called.
     * @param account of contract owner issuing the event.
     * @param unpauseBlock block number when contract will be unpaused.
     */
    event Paused(address account, uint256 unpauseBlock);

    /**
     * @dev Emitted when pause is lifted by unpause() by
     * @param account.
     */
    event Unpaused(address account);

    /**
     * @dev state variable
     */
    uint256 public blockNumberWhenToUnpause = 0;

    constructor(address _owner) Ownable(_owner) {}

    /**
     * @dev Modifier to make a function callable only when the contract is not
     *      paused. It checks whether the current block number
     *      has already reached blockNumberWhenToUnpause.
     */
    modifier whenNotPaused() {
        require(
            block.number >= blockNumberWhenToUnpause,
            'Pausable: Revert - Code execution is still paused'
        );
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(
            block.number < blockNumberWhenToUnpause,
            'Pausable: Revert - Code execution is not paused'
        );
        _;
    }

    /**
     * @dev Triggers or extends pause state.
     *
     * Requirements:
     *
     * - @param blocks needs to be greater than 0.
     */
    function pause(uint256 blocks) external onlyOwner {
        require(
            blocks > 0,
            'Pausable: Revert - Pause did not activate. Please enter a positive integer.'
        );
        blockNumberWhenToUnpause = block.number.add(blocks);
        emit Paused(_msgSender(), blockNumberWhenToUnpause);
    }

    /**
     * @dev Returns to normal code execution.
     */
    function unpause() external onlyOwner {
        blockNumberWhenToUnpause = block.number;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of 'user permissions'.
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor(address _owner) {
        owner = _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, 'Ownable: Not owner');
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), 'Ownable: Zero address not allowed');
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;

/**
 * A little helper to protect contract from being re-entrant in state
 * modifying functions.
 */

contract NonReentrant {
    uint256 private entry_guard;

    modifier noReentry() {
        require(entry_guard == 0, 'NonReentrant: Reentry');
        entry_guard = 1;
        _;
        entry_guard = 0;
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

// Energi Governance system is the fundamental part of Energi Core.

// NOTE: It's not allowed to change the compiler due to byte-to-byte
// match requirement.

pragma solidity 0.7.6;

import { IGovernedContract } from './interfaces/IGovernedContract.sol';

/**
 * Genesis version of GovernedContract common base.
 *
 * Base Consensus interface for upgradable contracts.
 * Unlike common approach, the implementation is NOT expected to be
 * called through delegatecall() to minimize risks of shared storage.
 *
 * NOTE: it MUST NOT change after blockchain launch!
 */
contract GovernedContract {
    address public proxy;

    constructor(address _proxy) {
        proxy = _proxy;
    }

    modifier requireProxy() {
        require(msg.sender == proxy, 'Governed Contract: Not proxy');
        _;
    }

    function getProxy() internal view returns (address _proxy) {
        _proxy = proxy;
    }

    // solium-disable-next-line no-empty-blocks
    function _migrate(IGovernedContract) internal {}

    function _destroy(IGovernedContract _newImpl) internal {
        selfdestruct(address(uint160(address(_newImpl))));
    }

    function _callerAddress() internal view returns (address payable) {
        if (msg.sender == proxy) {
            // This is guarantee of the GovernedProxy
            // solium-disable-next-line security/no-tx-origin
            return tx.origin;
        } else {
            return msg.sender;
        }
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() {}

    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _txOrigin() internal view returns (address payable) {
        return tx.origin;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}