// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import 'contracts/position_trading/algorithms/PositionAlgorithm.sol';
import 'contracts/position_trading/IPositionsController.sol';
import 'contracts/position_trading/PositionSnapshot.sol';
import 'contracts/lib/erc20/Erc20ForFactory.sol';
import 'contracts/position_trading/algorithms/TradingPair/TradingPairFeeDistributer.sol';
import 'contracts/position_trading/algorithms/TradingPair/ITradingPairFeeDistributer.sol';
import 'contracts/position_trading/algorithms/TradingPair/ITradingPairAlgorithm.sol';
import 'contracts/position_trading/algorithms/TradingPair/FeeSettings.sol';
import 'contracts/position_trading/AssetTransferData.sol';

struct SwapVars {
    uint256 inputlastCount;
    uint256 buyCount;
    uint256 lastPrice;
    uint256 newPrice;
    uint256 snapPrice;
    uint256 outFee;
    uint256 priceImpact;
    uint256 slippage;
}

struct AddLiquidityVars {
    uint256 assetBCode;
    uint256 countB;
    uint256 lastAssetACount;
    uint256 lastCountA;
    uint256 lastCountB;
    uint256 liquidityTokensToMint;
}

struct SwapSnapshot {
    uint256 input;
    uint256 output;
    uint256 slippage;
}

struct PositionAddingAssets {
    ItemRef asset1;
    ItemRef asset2;
}

contract TradingPairAlgorithm is PositionAlgorithm, ITradingPairAlgorithm {
    using ItemRefAsAssetLibrary for ItemRef;

    uint256 public constant priceDecimals = 1e18;

    mapping(uint256 => FeeSettings) public fee;
    mapping(uint256 => address) public liquidityTokens;
    mapping(uint256 => address) public feeTokens;
    mapping(uint256 => address) public feeDistributers;

    constructor(address positionsControllerAddress)
        PositionAlgorithm(positionsControllerAddress)
    {}

    receive() external payable {}

    function createAlgorithm(
        uint256 positionId,
        FeeSettings calldata feeSettings
    ) external onlyFactory {
        positionsController.setAlgorithm(positionId, address(this));

        // set fee settings
        fee[positionId] = feeSettings;

        Erc20ForFactory liquidityToken = new Erc20ForFactory(
            'liquidity',
            'LIQ',
            0
        );
        Erc20ForFactory feeToken = new Erc20ForFactory('fee', 'FEE', 0);
        liquidityTokens[positionId] = address(liquidityToken);
        feeTokens[positionId] = address(feeToken);
        (ItemRef memory own, ItemRef memory out) = _getAssets(positionId);
        liquidityToken.mintTo(
            positionsController.ownerOf(positionId),
            own.count() * out.count()
        );
        feeToken.mintTo(
            positionsController.ownerOf(positionId),
            own.count() * out.count()
        );
        // create fee distributor
        TradingPairFeeDistributer feeDistributer = new TradingPairFeeDistributer(
                positionId,
                address(this),
                address(feeToken),
                positionsController.getAssetReference(positionId, 1),
                positionsController.getAssetReference(positionId, 2),
                feeSettings.feeRoundIntervalHours
            );
        feeDistributers[positionId] = address(feeDistributer);
        // transfer the owner to the fee distributor
        //feeasset1.transferOwnership(address(feeDistributer)); // todo проверить работоспособность!!!
        //feeasset2.transferOwnership(address(feeDistributer));
    }

    function getFeeSettings(uint256 positionId)
        external
        view
        returns (FeeSettings memory)
    {
        return fee[positionId];
    }

    function _positionLocked(uint256 positionId)
        internal
        view
        override
        returns (bool)
    {
        return address(liquidityTokens[positionId]) != address(0); // position lock automatically, after adding the algorithm
    }

    function _isPermanentLock(uint256 positionId)
        internal
        view
        override
        returns (bool)
    {
        return _positionLocked(positionId); // position lock automatically, after adding the algorithm
    }

    function addLiquidity(
        uint256 positionId,
        uint256 assetCode,
        uint256 count
    ) external payable returns (uint256 ethSurplus) {
        ethSurplus = msg.value;
        // position must be created
        require(
            liquidityTokens[positionId] != address(0),
            'position id is not exists'
        );
        AddLiquidityVars memory vars;
        vars.assetBCode = 1;
        if (assetCode == vars.assetBCode) vars.assetBCode = 2;
        // get assets
        ItemRef memory assetA = positionsController.getAssetReference(
            positionId,
            assetCode
        );
        ItemRef memory assetB = positionsController.getAssetReference(
            positionId,
            vars.assetBCode
        );
        // take total supply of liquidity tokens
        Erc20ForFactory liquidityToken = Erc20ForFactory(
            liquidityTokens[positionId]
        );

        vars.countB = (count * assetB.count()) / assetA.count();

        // save the last asset count
        vars.lastAssetACount = assetA.count();
        //uint256 lastAssetBCount = assetB.count();
        // transfer from adding assets
        assetA.setNotifyListener(false);
        assetB.setNotifyListener(false);
        uint256[] memory data;
        vars.lastCountA = assetA.count();
        vars.lastCountB = assetB.count();
        ethSurplus = positionsController.transferToAssetFrom{
            value: ethSurplus
        }(msg.sender, positionId, assetCode, count, data);
        ethSurplus = positionsController.transferToAssetFrom{
            value: ethSurplus
        }(msg.sender, positionId, vars.assetBCode, vars.countB, data);
        require(
            assetA.count() == vars.lastCountA + count,
            'transferred asset 1 count to pair is not correct'
        );
        require(
            assetB.count() == vars.lastCountB + vars.countB,
            'transferred asset 2 count to pair is not correct'
        );
        assetA.setNotifyListener(true);
        assetB.setNotifyListener(true);
        // mint liquidity tokens
        vars.liquidityTokensToMint =
            (liquidityToken.totalSupply() *
                (assetA.count() - vars.lastAssetACount)) /
            vars.lastAssetACount;
        liquidityToken.mintTo(msg.sender, vars.liquidityTokensToMint);

        // log event
        if (assetCode == 1) {
            emit OnAddLiquidity(
                positionId,
                msg.sender,
                count,
                vars.countB,
                vars.liquidityTokensToMint
            );
        } else {
            emit OnAddLiquidity(
                positionId,
                msg.sender,
                vars.countB,
                count,
                vars.liquidityTokensToMint
            );
        }

        // revert eth surplus
        if (ethSurplus > 0) {
            (bool surplusSent, ) = msg.sender.call{ value: ethSurplus }('');
            require(surplusSent, 'ethereum surplus is not sent');
        }
    }

    function _getAssets(uint256 positionId)
        internal
        view
        returns (ItemRef memory asset1, ItemRef memory asset2)
    {
        ItemRef memory asset1 = positionsController.getAssetReference(
            positionId,
            1
        );
        ItemRef memory asset2 = positionsController.getAssetReference(
            positionId,
            2
        );
        require(asset1.id != 0, 'owner asset required');
        require(asset2.id != 0, 'output asset required');

        return (asset1, asset2);
    }

    function getAsset1Price(uint256 positionId)
        external
        view
        returns (uint256)
    {
        return _getAsset1Price(positionId);
    }

    function _getAsset1Price(uint256 positionId)
        internal
        view
        returns (uint256)
    {
        (ItemRef memory asset1, ItemRef memory asset2) = _getAssets(positionId);
        uint256 ownerCount = asset1.count();
        uint256 outputCount = asset2.count();
        require(outputCount > 0, 'has no output count');
        return ownerCount / outputCount;
    }

    function getAsset2Price(uint256 positionId)
        external
        view
        returns (uint256)
    {
        return _getAsset2Price(positionId);
    }

    function _getAsset2Price(uint256 positionId)
        internal
        view
        returns (uint256)
    {
        (ItemRef memory asset1, ItemRef memory asset2) = _getAssets(positionId);
        uint256 ownerCount = asset1.count();
        uint256 outputCount = asset2.count();
        require(outputCount > 0, 'has no output count');
        return outputCount / ownerCount;
    }

    function getBuyCount(
        uint256 positionId,
        uint256 inputAssetCode,
        uint256 amount
    ) external view returns (uint256) {
        (ItemRef memory asset1, ItemRef memory asset2) = _getAssets(positionId);
        uint256 inputLastCount;
        uint256 outputLastCount;
        if (inputAssetCode == 1) {
            inputLastCount = asset1.count();
            outputLastCount = asset2.count();
        } else if (inputAssetCode == 2) {
            inputLastCount = asset2.count();
            outputLastCount = asset1.count();
        } else revert('incorrect asset code');
        return
            _getBuyCount(
                inputLastCount,
                inputLastCount + amount,
                outputLastCount
            );
    }

    function _getBuyCount(
        uint256 inputLastCount,
        uint256 inputNewCount,
        uint256 outputLastCount
    ) internal pure returns (uint256) {
        return
            outputLastCount -
            ((inputLastCount * outputLastCount) / inputNewCount);
    }

    function _afterAssetTransfer(AssetTransferData calldata arg)
        internal
        virtual
        override
    {
        (ItemRef memory asset1, ItemRef memory asset2) = _getAssets(
            arg.positionId
        );
        // transfers from assets are not processed
        if (arg.from == asset1.addr || arg.from == asset2.addr) return;
        // swap only if editing is locked
        require(
            _positionLocked(arg.positionId), 
            'no lk pos'
        );
        // if there is no snapshot, then we do nothing
        require(
            arg.data.length == 3,
            'no snpsht'
        );

        // take fee
        FeeSettings memory feeSettings = fee[arg.positionId];
        // make a swap
        if (arg.assetCode == 2)
            // if the exchange is direct
            _swap(
                arg.positionId,
                arg.from,
                arg.count,
                asset2,
                asset1,
                feeSettings.asset2,
                feeSettings.asset1,
                SwapSnapshot(arg.data[1], arg.data[0], arg.data[2]),
                ITradingPairFeeDistributer(feeDistributers[arg.positionId])
                    .asset(2),
                ITradingPairFeeDistributer(feeDistributers[arg.positionId])
                    .asset(1)
            );
        else
            _swap(
                arg.positionId,
                arg.from,
                arg.count,
                asset1,
                asset2,
                feeSettings.asset1,
                feeSettings.asset2,
                SwapSnapshot(arg.data[0], arg.data[1], arg.data[2]),
                ITradingPairFeeDistributer(feeDistributers[arg.positionId])
                    .asset(1),
                ITradingPairFeeDistributer(feeDistributers[arg.positionId])
                    .asset(2)
            );
    }

    function _swap(
        uint256 positionId,
        address from,
        uint256 amount,
        ItemRef memory input,
        ItemRef memory output,
        AssetFee memory inputFee,
        AssetFee memory outputFee,
        SwapSnapshot memory snapshot,
        ItemRef memory inputFeeAsset,
        ItemRef memory outputFeeAsset
    ) internal {
        SwapVars memory vars;
        // count how much bought
        vars.inputlastCount = input.count() - amount;
        vars.buyCount = _getBuyCount(
            vars.inputlastCount,
            input.count(),
            output.count()
        );
        require(vars.buyCount <= output.count(), 'not enough asset to buy');

        // count the old price
        vars.lastPrice = (vars.inputlastCount * priceDecimals) / output.count();
        if (vars.lastPrice == 0) vars.lastPrice = 1;

        // fee counting
        if (inputFee.input > 0) {
            positionsController.transferToAnotherAssetInternal(
                input,
                inputFeeAsset,
                (inputFee.input * amount) / 10000
            );
        }
        if (outputFee.output > 0) {
            vars.outFee = (outputFee.output * vars.buyCount) / 10000;
            vars.buyCount -= vars.outFee;
            positionsController.transferToAnotherAssetInternal(
                output,
                outputFeeAsset,
                vars.outFee
            );
        }

        // transfer the asset
        uint256 devFee = (vars.buyCount *
            positionsController.getFeeSettings().feePercent()) /
            positionsController.getFeeSettings().feeDecimals();
        if (devFee > 0) {
            positionsController.withdrawInternal(
                output,
                positionsController.getFeeSettings().feeAddress(),
                devFee
            );
            positionsController.withdrawInternal(
                output,
                from,
                vars.buyCount - devFee
            );
        } else {
            positionsController.withdrawInternal(output, from, vars.buyCount);
        }

        // count the old price
        vars.newPrice = (input.count() * priceDecimals) / output.count();
        if (vars.newPrice == 0) vars.newPrice = 1;

        // count the snapshot price
        vars.snapPrice = (snapshot.input * priceDecimals) / snapshot.output;
        if (vars.snapPrice == 0) vars.snapPrice = 1;
        // slippage limiter
        if (vars.newPrice >= vars.snapPrice)
            vars.slippage = (vars.newPrice * priceDecimals) / vars.snapPrice;
        else vars.slippage = (vars.snapPrice * priceDecimals) / vars.newPrice;

        require(
            vars.slippage <= snapshot.slippage,
            'chngd more than slppg'
        );

        // price should not change more than 50%
        vars.priceImpact = (vars.newPrice * priceDecimals) / vars.lastPrice;
        require(
            vars.priceImpact <= priceDecimals + priceDecimals / 2, // 150% of priceDecimals
            'large impct'
        );

        // event
        emit OnSwap(
            positionId,
            from,
            input.id,
            output.id,
            amount,
            vars.buyCount
        );
    }

    function withdraw(uint256 positionId, uint256 liquidityCount) external {
        // take a token
        address liquidityAddr = liquidityTokens[positionId];
        require(
            liquidityAddr != address(0),
            'no lqdty tkns'
        );
        // take assets
        (ItemRef memory own, ItemRef memory out) = _getAssets(positionId);
        // withdraw of owner asset
        uint256 asset1Count = (own.count() * liquidityCount) /
            Erc20ForFactory(liquidityAddr).totalSupply();
        positionsController.withdrawInternal(own, msg.sender, asset1Count);
        // withdraw asset output
        uint256 asset2Count = (out.count() * liquidityCount) /
            Erc20ForFactory(liquidityAddr).totalSupply();
        positionsController.withdrawInternal(out, msg.sender, asset2Count);

        // burn liquidity token
        Erc20ForFactory(liquidityAddr).burn(msg.sender, liquidityCount);

        // log event
        emit OnRemoveLiquidity(
            positionId,
            msg.sender,
            asset1Count,
            asset2Count,
            liquidityCount
        );
    }

    function checkCanWithdraw(
        ItemRef calldata asset,
        uint256 assetCode,
        uint256 count
    ) external view {
        require(
            !this.positionLocked(asset.getPositionId()),
            'locked'
        );
    }

    function getSnapshot(uint256 positionId, uint256 slippage)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (
            positionsController.getAssetReference(positionId, 1).count(),
            positionsController.getAssetReference(positionId, 2).count(),
            priceDecimals + slippage
        );
    }

    function getPositionsController() external view returns (address) {
        return address(positionsController);
    }

    function getLiquidityToken(uint256 positionId)
        external
        view
        returns (address)
    {
        return liquidityTokens[positionId];
    }

    function getFeeToken(uint256 positionId) external view returns (address) {
        return feeTokens[positionId];
    }

    function getFeeDistributer(uint256 positionId)
        external
        view
        returns (address)
    {
        return feeDistributers[positionId];
    }

    function ClaimFeeReward(
        uint256 positionId,
        address account,
        uint256 asset1Count,
        uint256 asset2Count,
        uint256 feeTokensCount
    ) external {
        require(feeDistributers[positionId] == msg.sender);
        emit OnClaimFeeReward(
            positionId,
            account,
            asset1Count,
            asset2Count,
            feeTokensCount
        );
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import '../IPositionAlgorithm.sol';
import 'contracts/position_trading/IPositionsController.sol';
import 'contracts/position_trading/PositionSnapshot.sol';
import '../ItemRef.sol';
import '../IAssetsController.sol';
import 'contracts/position_trading/ItemRefAsAssetLibrary.sol';
import 'contracts/position_trading/AssetTransferData.sol';
import './PositionLockerBase.sol';

/// @dev basic algorithm position
abstract contract PositionAlgorithm is PositionLockerBase {
    using ItemRefAsAssetLibrary for ItemRef;
    IPositionsController public immutable positionsController;

    constructor(address positionsControllerAddress) {
        positionsController = IPositionsController(positionsControllerAddress);
    }

    modifier onlyPositionOwner(uint256 positionId) {
        require(
            positionsController.ownerOf(positionId) == msg.sender,
            'only for position owner'
        );
        _;
    }

    modifier onlyFactory() {
        require(
            positionsController.isFactory(msg.sender),
            'only for factories'
        );
        _;
    }

    modifier onlyPositionsController() {
        require(
            msg.sender == address(positionsController),
            'only for positions controller'
        );
        _;
    }

    modifier onlyBuildMode(uint256 positionId) {
        require(
            positionsController.isBuildMode(positionId),
            'only for position build mode'
        );
        _;
    }

    function beforeAssetTransfer(AssetTransferData calldata arg)
        external
        onlyPositionsController
    {
        _beforeAssetTransfer(arg);
    }

    function _beforeAssetTransfer(AssetTransferData calldata arg)
        internal
        virtual
    {}

    function afterAssetTransfer(AssetTransferData calldata arg)
        external
        payable
        onlyPositionsController
    {
        _afterAssetTransfer(arg);
    }

    function _afterAssetTransfer(AssetTransferData calldata arg)
        internal
        virtual
    {}

    function withdrawAsset(
        uint256 positionId,
        uint256 assetCode,
        address recipient,
        uint256 amount
    ) external onlyPositionOwner(positionId) {
        _withdrawAsset(positionId, assetCode, recipient, amount);
    }

    function _withdrawAsset(
        // todo упростить - сделать где нужно метод проверки
        uint256 positionId,
        uint256 assetCode,
        address recipient,
        uint256 amount
    ) internal virtual onlyPositionOwner(positionId) {
        positionsController.getAssetReference(positionId, assetCode).withdraw(
            recipient,
            amount
        );
    }

    function lockPosition(uint256 positionId, uint256 lockSeconds)
        external
        onlyUnlockedPosition(positionId)
    {
        if (positionsController.isBuildMode(positionId)) {
            require(
                positionsController.isFactory(msg.sender),
                'only for factories'
            );
        } else {
            require(
                positionsController.ownerOf(positionId) == msg.sender,
                'only for position owner'
            );
        }
        unlockTimes[positionId] = block.timestamp + lockSeconds * 1 seconds;
    }

    function lockPermanent(uint256 positionId)
        external
        onlyPositionOwner(positionId)
    {
        _permamentLocks[positionId] = true;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import 'contracts/lib/factories/ContractData.sol';
import 'contracts/fee/IFeeSettings.sol';
import './AssetData.sol';
import './ItemRef.sol';
import './IAssetListener.sol';
import '../lib/factories/IHasFactories.sol';

interface IPositionsController is IHasFactories, IAssetListener {
    /// @dev new position created
    event NewPosition(
        address indexed account,
        address indexed algorithmAddress,
        uint256 positionId
    );

    /// @dev returns fee settings
    function getFeeSettings() external view returns (IFeeSettings);

    /// @dev creates a position
    /// @return id of new position
    /// @param owner the owner of the position
    /// only factory, only build mode
    function createPosition(address owner) external returns (uint256);

    /// @dev returns position data
    function getPosition(uint256 positionId)
        external
        view
        returns (
            address algorithm,
            AssetData memory asset1,
            AssetData memory asset2
        );

    /// @dev returns total positions count
    function positionsCount() external returns (uint256);

    /// @dev returns the position owner
    function ownerOf(uint256 positionId) external view returns (address);

    /// @dev returns an asset by its code in position 1 or 2
    function getAsset(uint256 positionId, uint256 assetCode)
        external
        view
        returns (AssetData memory data);

    /// @dev returns position assets references
    function getAllPositionAssetReferences(uint256 positionId)
        external
        view
        returns (ItemRef memory position1, ItemRef memory position2);

    /// @dev returns asset reference by its code in position 1 or 2
    function getAssetReference(uint256 positionId, uint256 assetCode)
        external
        view
        returns (ItemRef memory);

    /// @dev returns position of tne specific asset id
    function getAssetPositionId(uint256 assetId)
        external
        view
        returns (uint256);

    /// @dev creates an asset to position, generates asset reference
    /// @param positionId position ID
    /// @param assetCode asset code 1 - owner asset 2 - output asset
    /// @param assetsController reference to asset
    /// only factories, only build mode
    function createAsset(
        uint256 positionId,
        uint256 assetCode,
        address assetsController
    ) external returns (ItemRef memory);

    /// @dev sets the position algorithm
    /// id of algorithm is id of the position
    /// only factory, only build mode
    function setAlgorithm(uint256 positionId, address algorithmController)
        external;

    /// @dev returns the position algorithm contract
    function getAlgorithm(uint256 positionId) external view returns (address);

    /// @dev if true, than position in build mode
    function isBuildMode(uint256 positionId) external view returns (bool);

    /// @dev stops the position build mode
    /// onlyFactories, onlyBuildMode
    function stopBuild(uint256 positionId) external;

    /// @dev returns total assets count
    function assetsCount() external view returns (uint256);

    /// @dev returns new asset id and increments assetsCount
    /// only factories
    function createNewAssetId() external returns (uint256);

    /// @dev transfers caller asset to asset
    function transferToAsset(
        uint256 positionId,
        uint256 assetCode,
        uint256 count,
        uint256[] calldata data
    ) external payable returns (uint256 ethSurplus);

    /// @dev transfers to asset from account
    /// @dev returns ethereum surplus sent back to the sender
    /// onlyFactory
    function transferToAssetFrom(
        address from,
        uint256 positionId,
        uint256 assetCode,
        uint256 count,
        uint256[] calldata data
    ) external payable returns (uint256 ethSurplus);

    /// @dev withdraw asset by its position and code (makes all checks)
    /// only position owner
    function withdraw(
        uint256 positionId,
        uint256 assetCode,
        uint256 count
    ) external;

    /// @dev withdraws asset to specific address
    /// only position owner
    function withdrawTo(
        uint256 positionId,
        uint256 assetCode,
        address to,
        uint256 count
    ) external;

    /// @dev internal withdraw asset for algorithms
    /// oplyPositionAlgorithm
    function withdrawInternal(
        ItemRef calldata asset,
        address to,
        uint256 count
    ) external;

    /// @dev transfers asset to another same type asset
    /// oplyPositionAlgorithm
    function transferToAnotherAssetInternal(
        ItemRef calldata from,
        ItemRef calldata to,
        uint256 count
    ) external;

    /// @dev returns the count of the asset
    function count(ItemRef calldata asset) external view returns (uint256);

    /// @dev returns all counts of the position
    /// usefull for get snapshot for same algotithms
    function getCounts(uint256 positionId)
        external
        view
        returns (uint256, uint256);

    /// @dev if returns true than position is locked
    function positionLocked(uint256 positionId) external view returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

// todo cut out
struct PositionSnapshot {
    uint256 owner;
    uint256 output;
    uint256 slippage;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract Erc20ForFactory is ERC20 {
    uint8 _decimals;
    address public factory;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) ERC20(name_, symbol_) {
        _decimals = decimals_;
        factory = msg.sender;
    }

    modifier onlyFactory() {
        require(msg.sender == factory, 'only for factory');
        _;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function mint(uint256 count) external onlyFactory {
        _mint(msg.sender, count);
    }

    function mintTo(address account, uint256 count) external onlyFactory {
        _mint(account, count);
    }

    function burn(address account, uint256 count) external onlyFactory {
        _burn(account, count);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import 'contracts/lib/ownable/OwnableSimple.sol';
import 'contracts/position_trading/ItemRefAsAssetLibrary.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import 'contracts/position_trading/algorithms/TradingPair/ITradingPairAlgorithm.sol';
import 'contracts/position_trading/algorithms/TradingPair/ITradingPairFeeDistributer.sol';
import 'contracts/position_trading/AssetTransferData.sol';

contract TradingPairFeeDistributer is
    OwnableSimple,
    ITradingPairFeeDistributer
{
    using ItemRefAsAssetLibrary for ItemRef;

    uint256 immutable _positionId;

    // fee token
    IERC20 public immutable feeToken;
    // fee token user locks
    mapping(address => uint256) public feeTokenLocks;
    mapping(address => uint256) public claimRounds;
    uint256 public totalFeetokensLocked;
    // fee round
    uint256 public feeRoundNumber;
    uint256 public immutable feeRoundInterval;
    uint256 public nextFeeRoundTime;
    // assets
    ItemRef _asset1;
    ItemRef _asset2;
    // distribution snapshot
    uint256 public distributeRoundTotalFeeTokensLock;
    uint256 public ownerAssetToDistribute;
    uint256 public outputAssetToDistribute;
    // statistics
    uint256 public ownerAssetDistributedTotal;
    uint256 public outputAssetDistributedTotal;
    // events
    event OnLock(address indexed account, uint256 amount);
    event OnUnlock(address indexed account, uint256 amount);

    constructor(
        uint256 positionId_,
        address tradingPair_,
        address feeTokenAddress_,
        ItemRef memory asset1_,
        ItemRef memory asset2_,
        uint256 feeRoundIntervalHours_
    ) OwnableSimple(tradingPair_) {
        _positionId = positionId_;
        feeToken = IERC20(feeTokenAddress_);
        feeRoundInterval = feeRoundIntervalHours_ * 1 hours;
        nextFeeRoundTime = block.timestamp + feeRoundInterval;

        // create assets for fee
        _asset1 = asset1_.clone(
            address(this)
        );
        _asset2 = asset2_.clone(
            address(this)
        );
    }

    function lockFeeTokens(uint256 amount) external {
        _claimRewards(msg.sender);
        _tryNextFeeRound();
        feeToken.transferFrom(msg.sender, address(this), amount);
        feeTokenLocks[msg.sender] += amount;
        totalFeetokensLocked += amount;
        emit OnLock(msg.sender, amount);
    }

    function unlockFeeTokens(uint256 amount) external {
        _claimRewards(msg.sender);
        _tryNextFeeRound();
        require(feeTokenLocks[msg.sender] >= amount, 'not enough fee tkns');
        feeTokenLocks[msg.sender] -= amount;
        totalFeetokensLocked -= amount;
        emit OnUnlock(msg.sender, amount);
    }

    function tryNextFeeRound() external {
        _tryNextFeeRound();
    }

    function _tryNextFeeRound() internal {
        //console.log('nextFeeRoundTime-block.timestamp', nextFeeRoundTime-block.timestamp);
        if (block.timestamp < nextFeeRoundTime) return;
        ++feeRoundNumber;
        nextFeeRoundTime = block.timestamp + feeRoundInterval;
        // snapshot for distribute
        distributeRoundTotalFeeTokensLock = totalFeetokensLocked;
        ownerAssetToDistribute = _asset1.count();
        outputAssetToDistribute = _asset2.count();
    }

    function claimRewards() external {
        _tryNextFeeRound();
        require(feeRoundNumber > 0, 'nthing claim');
        require(claimRounds[msg.sender] < feeRoundNumber, 'climd yet');
        require(feeTokenLocks[msg.sender] > 0, 'has no lck');
        _claimRewards(msg.sender);
    }

    function _claimRewards(address account) internal {
        if (claimRounds[account] >= feeRoundNumber) return;
        claimRounds[account] = feeRoundNumber;
        uint256 feeTokensCount = feeTokenLocks[account];

        (uint256 asset1Count, uint256 asset2Count) = this
            .getRewardForTokensCount(feeTokensCount);
        ownerAssetDistributedTotal += asset1Count;
        outputAssetDistributedTotal += asset2Count;
        if (asset1Count > 0) _asset1.withdraw(account, asset1Count);
        if (asset2Count > 0) _asset2.withdraw(account, asset2Count);

        ITradingPairAlgorithm(this.tradingPair()).ClaimFeeReward(
            _positionId,
            account,
            asset1Count,
            asset2Count,
            feeTokensCount
        );
    }

    /// @dev reward for tokens count
    function getRewardForTokensCount(uint256 feeTokensCount)
        external
        view
        returns (uint256, uint256)
    {
        return (
            distributeRoundTotalFeeTokensLock > 0
                ? (ownerAssetToDistribute * feeTokensCount) /
                    distributeRoundTotalFeeTokensLock
                : 0,
            distributeRoundTotalFeeTokensLock > 0
                ? (outputAssetToDistribute * feeTokensCount) /
                    distributeRoundTotalFeeTokensLock
                : 0
        );
    }

    function nextFeeRoundLapsedMinutes() external view returns (uint256) {
        if (block.timestamp >= nextFeeRoundTime) return 0;
        return (nextFeeRoundTime - block.timestamp) / (1 minutes);
    }

    function asset(uint256 assetCode) external view returns (ItemRef memory) {
        if (assetCode == 1) return _asset1;
        else if (assetCode == 2) return _asset2;
        else revert('bad asset code');
    }

    function assetCount(uint256 assetCode) external view returns (uint256) {
        if (assetCode == 1) return _asset1.count();
        else if (assetCode == 2) return _asset2.count();
        else revert('bad asset code');
    }

    function allAssetsCounts()
        external
        view
        returns (uint256 asset1Count, uint256 asset2Count)
    {
        asset1Count = _asset1.count();
        asset2Count = _asset2.count();
    }

    function tradingPair() external view returns (address) {
        return _owner;
    }

    function positionId() external view returns (uint256) {
        return _positionId;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import 'contracts/position_trading/ItemRef.sol';

interface ITradingPairFeeDistributer {
    function lockFeeTokens(uint256 amount) external;

    function unlockFeeTokens(uint256 amount) external;

    function claimRewards() external;

    function nextFeeRoundLapsedMinutes() external view returns (uint256);

    function tryNextFeeRound() external;

    function asset(uint256 assetCode) external view returns (ItemRef memory);

    function assetCount(uint256 assetCode) external view returns (uint256);

    function allAssetsCounts()
        external
        view
        returns (uint256 asset1Count, uint256 asset2Count);

    /// @dev the trading pair algorithm contract
    function tradingPair() external view returns (address);

    /// @dev the position id
    function positionId() external view returns (uint256);

    /// @dev reward for tokens count
    function getRewardForTokensCount(uint256 feeTokensCount)
        external
        view
        returns (uint256, uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import 'contracts/position_trading/algorithms/TradingPair/FeeSettings.sol';
import 'contracts/position_trading/AssetData.sol';

interface ITradingPairAlgorithm {
    /// @dev swap event
    event OnSwap(
        uint256 indexed positionId,
        address indexed account,
        uint256 inputAssetId,
        uint256 outputAssetId,
        uint256 inputCount,
        uint256 outputCount
    );

    /// @dev add liquidity event
    event OnAddLiquidity(
        uint256 indexed positionId,
        address indexed account,
        uint256 asset1Count,
        uint256 asset2Count,
        uint256 liquidityTokensCount
    );

    /// @dev remove liquidity event
    event OnRemoveLiquidity(
        uint256 indexed positionId,
        address indexed account,
        uint256 asset1Count,
        uint256 asset2Count,
        uint256 liquidityTokensCount
    );

    /// @dev fee reward claimed
    event OnClaimFeeReward(
        uint256 indexed positionId,
        address indexed account,
        uint256 asset1Count,
        uint256 asset2Count,
        uint256 feeTokensCount
    );

    /// @dev creates the algorithm
    /// onlyFactory
    function createAlgorithm(
        uint256 positionId,
        FeeSettings calldata feeSettings
    ) external;

    /// @dev the positions controller
    function getPositionsController() external view returns (address);

    /// @dev the liquidity token address
    function getLiquidityToken(uint256 positionId)
        external
        view
        returns (address);

    /// @dev the fee token address
    function getFeeToken(uint256 positionId) external view returns (address);

    /// @dev get fee settings of trading pair
    function getFeeSettings(uint256 positionId)
        external
        view
        returns (FeeSettings memory);

    /// @dev returns the fee distributer for position
    function getFeeDistributer(uint256 positionId)
        external
        view
        returns (address);

    /// @dev withdraw
    function withdraw(uint256 positionId, uint256 liquidityCount) external;

    /// @dev adds liquidity
    /// @param assetCode the asset code for count to add (another asset count is calculates)
    /// @param count count of the asset (another asset count is calculates)
    /// @dev returns ethereum surplus sent back to the sender
    function addLiquidity(
        uint256 position,
        uint256 assetCode,
        uint256 count
    ) external payable returns (uint256 ethSurplus);

    /// @dev returns snapshot for make swap
    /// @param positionId id of the position
    /// @param slippage slippage in 1/100000 parts (for example 20% slippage is 20000)
    function getSnapshot(uint256 positionId, uint256 slippage)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    /// @dev notify that fee reward has claimed
    /// only for fee distributers
    function ClaimFeeReward(
        uint256 positionId,
        address account,
        uint256 asset1Count,
        uint256 asset2Count,
        uint256 feeTokensCount
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

struct AssetFee {
    uint256 input; // position entry fee 1/10000
    uint256 output; // position exit fee 1/10000
}

struct FeeSettings {
    uint256 feeRoundIntervalHours;
    AssetFee asset1;
    AssetFee asset2;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;
import './ItemRef.sol';

struct AssetTransferData {
    uint256 positionId;
    ItemRef asset;
    uint256 assetCode;
    address from;
    address to;
    uint256 count;
    uint256[] data;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import './IAssetListener.sol';

interface IPositionAlgorithm is IAssetListener {
    /// @dev if asset can not be withdraw - revert
    function checkCanWithdraw(
        ItemRef calldata asset,
        uint256 assetCode,
        uint256 count
    ) external view;

    /// @dev if true than position is locked and can not withdraw
    function positionLocked(uint256 positionId) external view returns (bool);

    /// @dev locks the position
    /// only position owner
    function lockPosition(uint256 positionId, uint256 lockSeconds) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

/// @dev reference to the item
struct ItemRef {
    address addr; // referenced contract address
    uint256 id; // id of the item
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import './AssetData.sol';
import 'contracts/position_trading/ItemRef.sol';
import 'contracts/position_trading/AssetCreationData.sol';
import 'contracts/position_trading/AssetData.sol';
import 'contracts/position_trading/AssetTransferData.sol';

interface IAssetsController {
    /// @dev initializes the asset by its data
    /// onlyBuildMode
    function initialize(
        address from,
        uint256 assetId,
        AssetCreationData calldata data
    ) external payable returns (uint256 ethSurplus);

    /// @dev algorithm-controller address
    function algorithm(uint256 assetId) external view returns (address);

    /// @dev positions controller
    function positionsController() external view returns (address);

    /// @dev returns the asset type code (also used to check asset interface support)
    /// @return uint256 1-eth 2-erc20 3-erc721Item 4-Erc721Count
    function assetTypeId() external pure returns (uint256);

    /// @dev returns the position id by asset id
    function getPositionId(uint256 assetId) external view returns (uint256);

    /// @dev the algorithm of the asset that controls it
    function getAlgorithm(uint256 assetId)
        external
        view
        returns (address algorithm);

    /// @dev returns the asset code 1 or 2
    function getCode(uint256 assetId) external view returns (uint256);

    /// @dev asset count
    function count(uint256 assetId) external view returns (uint256);

    /// @dev external value of the asset (nft token id for example)
    function value(uint256 assetId) external view returns (uint256);

    /// @dev the address of the contract that is wrapped in the asset
    function contractAddr(uint256 assetId) external view returns (address);

    /// @dev returns the full assets data
    function getData(uint256 assetId) external view returns (AssetData memory);

    /// @dev withdraw the asset
    /// @param recepient recepient of asset
    /// @param count count to withdraw
    /// onlyPositionsController or algorithm
    function withdraw(
        uint256 assetId,
        address recepient,
        uint256 count
    ) external;

    /// @dev add count to asset
    /// onlyPositionsController
    function addCount(uint256 assetId, uint256 count) external;

    /// @dev remove asset count
    /// onlyPositionsController
    function removeCount(uint256 assetId, uint256 count) external;

    /// @dev transfers to current asset from specific account
    /// @dev returns ethereum surplus sent back to the sender
    /// onlyPositionsController
    function transferToAsset(AssetTransferData calldata arg)
        external
        payable
        returns (uint256 ethSurplus);

    /// @dev creates a copy of the current asset, with 0 count and the specified owner
    /// @return uint256 new asset reference
    function clone(uint256 assetId, address owner)
        external
        returns (ItemRef memory);

    /// @dev owner of the asset
    function owner(uint256 assetId) external view returns (address);

    /// @dev if true, then asset notifies its observer (owner)
    function isNotifyListener(uint256 assetId) external view returns (bool);

    /// @dev enables or disables the observer notification mechanism
    /// only factories
    function setNotifyListener(uint256 assetId, bool value) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import 'contracts/position_trading/ItemRef.sol';
import 'contracts/position_trading/IAssetsController.sol';

/// @dev item reference as asset wrapper functions
library ItemRefAsAssetLibrary {
    function assetsController(ItemRef memory ref)
        internal
        pure
        returns (IAssetsController)
    {
        return IAssetsController(ref.addr);
    }

    function assetTypeId(ItemRef memory ref) internal pure returns (uint256) {
        return assetsController(ref).assetTypeId();
    }

    function count(ItemRef memory ref) internal view returns (uint256) {
        return assetsController(ref).count(ref.id);
    }

    function addCount(ItemRef memory ref, uint256 countToAdd) internal {
        assetsController(ref).addCount(ref.id, countToAdd);
    }

    function removeCount(ItemRef memory ref, uint256 countToRemove) internal {
        assetsController(ref).removeCount(ref.id, countToRemove);
    }

    function withdraw(
        ItemRef memory ref,
        address recepient,
        uint256 cnt
    ) internal {
        assetsController(ref).withdraw(ref.id, recepient, cnt);
    }

    function getPositionId(ItemRef memory ref) internal view returns (uint256) {
        return assetsController(ref).getPositionId(ref.id);
    }

    function clone(ItemRef memory ref, address owner)
        internal
        returns (ItemRef memory)
    {
        return assetsController(ref).clone(ref.id, owner);
    }

    function setNotifyListener(ItemRef memory ref, bool value) internal {
        assetsController(ref).setNotifyListener(ref.id, value);
    }

    function initialize(
        ItemRef memory ref,
        address from,
        AssetCreationData calldata data
    ) internal {
        assetsController(ref).initialize(from, ref.id, data);
    }

    function getData(ItemRef memory ref)
        internal
        view
        returns (AssetData memory data)
    {
        return assetsController(ref).getData(ref.id);
    }

    function getCode(ItemRef memory ref) internal view returns (uint256) {
        return assetsController(ref).getCode(ref.id);
    }

    function contractAddr(ItemRef memory ref)
        internal
        view
        returns (address)
    {
        return assetsController(ref).contractAddr(ref.id);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import 'contracts/position_trading/IPositionsController.sol';

/// @dev locks the asset of the position owner for a certain time
abstract contract PositionLockerBase {
    mapping(uint256 => uint256) public unlockTimes; // unlock time by position
    mapping(uint256 => bool) _permamentLocks;

    modifier onlyUnlockedPosition(uint256 positionId) {
        require(!_positionLocked(positionId), 'for unlocked positions only');
        _;
    }

    modifier onlyLockedPosition(uint256 positionId) {
        require(_positionLocked(positionId), 'for locked positions only');
        _;
    }

    function positionLocked(uint256 positionId) external view returns (bool) {
        return _positionLocked(positionId);
    }

    function _positionLocked(uint256 positionId)
        internal
        view
        virtual
        returns (bool)
    {
        return
            _isPermanentLock(positionId) ||
            block.timestamp < unlockTimes[positionId];
    }

    function isPermanentLock(uint256 positionId) external view returns (bool) {
        return _isPermanentLock(positionId);
    }

    function _isPermanentLock(uint256 positionId)
        internal
        view
        virtual
        returns (bool)
    {
        return _permamentLocks[positionId];
    }

    function lapsedLockSeconds(uint256 positionId)
        external
        view
        returns (uint256)
    {
        if (!_positionLocked(positionId)) return 0;
        if (unlockTimes[positionId] > block.timestamp)
            return unlockTimes[positionId] - block.timestamp;
        else return 0;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import 'contracts/position_trading/PositionSnapshot.sol';
import 'contracts/position_trading/AssetTransferData.sol';
import './ItemRef.sol';

interface IAssetListener {
    function beforeAssetTransfer(AssetTransferData calldata arg) external;

    function afterAssetTransfer(AssetTransferData calldata arg)
        external
        payable;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

/// @dev data is generated by factory of contract
struct ContractData {
    address factory; // factory
    address contractAddr; // contract
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

interface IFeeSettings {
    function feeAddress() external returns (address); // address to pay fee

    function feePercent() external returns (uint256); // fee in 1/decimals for deviding values

    function feeDecimals() external view returns(uint256); // fee decimals

    function feeEth() external returns (uint256); // fee value for not dividing deal points
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

/// @dev read only struct, represents asset
struct AssetData {
    address addr; // the asset contract address
    uint256 id; // asset id or zero if asset is not exists
    uint256 assetTypeId; // 1-eth 2-erc20 3-erc721Item 4-Erc721Count
    uint256 positionId;
    uint256 positionAssetCode; // code of the asset - 1 or 2
    address owner;
    uint256 count; // current count of the asset
    address contractAddr; // contract, using in asset  or zero if ether
    uint256 value; // extended asset value (nft id for example)
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import '../ownable/IOwnable.sol';

interface IHasFactories is IOwnable {
    /// @dev returns true, if addres is factory
    function isFactory(address addr) external view returns (bool);

    /// @dev mark address as factory (only owner)
    function addFactory(address factory) external;

    /// @dev mark address as not factory (only owner)
    function removeFactory(address factory) external;

    /// @dev mark addresses as factory or not (only owner)
    function setFactories(address[] calldata addresses, bool isFactory_)
        external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

interface IOwnable {
    function owner() external view returns (address);

    function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

/// @dev asset creation data
struct AssetCreationData {
    /// @dev asset codes:
    /// 0 - asset is missing
    /// 1 - EthAsset
    /// 2 - Erc20Asset
    /// 3 - Erc721ItemAsset
    uint256 assetTypeCode;
    address contractAddress;
    /// @dev value for asset creation (count or tokenId)
    uint256 value;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import 'contracts/lib/ownable/IOwnable.sol';

/// @dev owanble, optimized, for dynamically generated contracts
contract OwnableSimple is IOwnable {
    address internal _owner;

    constructor(address owner_) {
        _owner = owner_;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, 'caller is not the owner');
        _;
    }

    function owner() external view virtual returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) external override onlyOwner {
        _owner = newOwner;
    }
}