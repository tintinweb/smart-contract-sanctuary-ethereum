// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import 'contracts/position_trading/algorithms/PositionAlgorithm.sol';
import 'contracts/position_trading/IPositionsController.sol';
import 'contracts/position_trading/PositionSnapshot.sol';
import 'contracts/lib/erc20/IErc20ForFactoryFactory.sol';
import 'contracts/position_trading/algorithms/TradingPair/TradingPairFeeDistributer.sol';
import 'contracts/position_trading/algorithms/TradingPair/ITradingPairFeeDistributer.sol';
import 'contracts/position_trading/algorithms/TradingPair/ITradingPairAlgorithm.sol';
import 'contracts/position_trading/algorithms/TradingPair/FeeSettings.sol';
import 'contracts/position_trading/algorithms/TradingPair/TradingPairConstraints.sol';
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

///
/// error codes:
/// 1 - no lquidity tokens
/// 2 - not enough liquidity tokens balance
/// 3 - locked
/// 4 - not enough fee tokens balance
/// 5 - not enough asset to buy
/// 6 - price changed more than slppage
/// 7 - too large price impact
/// 8 - the position is not locked
/// 9 - has no snapshot
/// 10 - forward swap is disallowed
/// 11 - back swap is disallowed
/// 12 - position id is not exists
/// 13 - transferred asset 1 count to pair is not correct
/// 14 - transferred asset 2 count to pair is not correct
/// 15 - block use limit
contract TradingPairAlgorithm is PositionAlgorithm, ITradingPairAlgorithm {
    using ItemRefAsAssetLibrary for ItemRef;

    uint256 public constant priceDecimals = 1e18;

    mapping(uint256 => FeeSettings) public fee;
    mapping(uint256 => TradingPairConstraints) public constraints;
    mapping(uint256 => IErc20ForFactory) public liquidityTokens;
    mapping(uint256 => IErc20ForFactory) public feeTokens;
    mapping(uint256 => address) public feeDistributers;
    mapping(uint256 => mapping(address => uint256)) public lastUseBlocks;
    IErc20ForFactoryFactory public erc20Factory;

    constructor(
        address positionsControllerAddress,
        address erc20Factory_
    ) PositionAlgorithm(positionsControllerAddress) {
        erc20Factory = IErc20ForFactoryFactory(erc20Factory_);
    }

    receive() external payable {}

    function createAlgorithm(
        uint256 positionId,
        FeeSettings calldata feeSettings,
        TradingPairConstraints calldata constraints_
    ) external onlyFactory {
        positionsController.setAlgorithm(positionId, address(this));

        // set fee settings
        fee[positionId] = feeSettings;

        // constraints
        constraints[positionId] = constraints_;

        // getting assets refs
        (ItemRef memory own, ItemRef memory out) = _getAssets(positionId);

        // calc support decimals
        uint8 decimals = own.getDecimals();
        if (out.getDecimals() > decimals) decimals = out.getDecimals();

        // liquidity token
        IErc20ForFactory liquidityToken = erc20Factory.create(
            'liquidity',
            'LIQ',
            decimals
        );
        liquidityTokens[positionId] = liquidityToken;
        liquidityToken.mintTo(
            positionsController.ownerOf(positionId),
            own.count() * out.count()
        );

        // fee token
        if (
            feeSettings.asset1.input != 0 ||
            feeSettings.asset1.output != 0 ||
            feeSettings.asset2.input != 0 ||
            feeSettings.asset2.output != 0
        ) {
            IErc20ForFactory feeToken = erc20Factory.create(
                'fee',
                'FEE',
                decimals
            );
            feeTokens[positionId] = feeToken;
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
        }
        // transfer the owner to the fee distributor
        //feeasset1.transferOwnership(address(feeDistributer)); // todo проверить работоспособность!!!
        //feeasset2.transferOwnership(address(feeDistributer));
    }

    function getFeeSettings(
        uint256 positionId
    ) external view returns (FeeSettings memory) {
        return fee[positionId];
    }

    function getConstraints(
        uint256 positionId
    ) external view returns (TradingPairConstraints memory) {
        return constraints[positionId];
    }

    function _positionLocked(
        uint256 positionId
    ) internal view override returns (bool) {
        return address(liquidityTokens[positionId]) != address(0); // position lock automatically, after adding the algorithm
    }

    function _isPermanentLock(
        uint256 positionId
    ) internal view override returns (bool) {
        return _positionLocked(positionId); // position lock automatically, after adding the algorithm
    }

    function addLiquidity(
        uint256 positionId,
        uint256 assetCode,
        uint256 count
    ) external payable returns (uint256 ethSurplus) {
        ethSurplus = msg.value;
        // position must be created
        require(address(liquidityTokens[positionId]) != address(0), '#12');
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
        IErc20ForFactory liquidityToken = liquidityTokens[positionId];

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
        require(assetA.count() == vars.lastCountA + count, '#13');
        require(assetB.count() == vars.lastCountB + vars.countB, '#14');
        assetA.setNotifyListener(true);
        assetB.setNotifyListener(true);
        // mint liquidity tokens
        vars.liquidityTokensToMint =
            (liquidityToken.totalSupply() *
                (assetA.count() - vars.lastAssetACount)) /
            vars.lastAssetACount;
        liquidityToken.mintTo(msg.sender, vars.liquidityTokensToMint);
        // mint fee tokens
        IErc20ForFactory feeToken = feeTokens[positionId];
        if (address(0) != address(feeToken)) {
            feeToken.mintTo(
                msg.sender,
                (feeToken.totalSupply() *
                    (assetA.count() - vars.lastAssetACount)) /
                    vars.lastAssetACount
            );
        }

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

    function _getAssets(
        uint256 positionId
    ) internal view returns (ItemRef memory asset1, ItemRef memory asset2) {
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

    function getAsset1Price(
        uint256 positionId
    ) external view returns (uint256) {
        return _getAsset1Price(positionId);
    }

    function _getAsset1Price(
        uint256 positionId
    ) internal view returns (uint256) {
        (ItemRef memory asset1, ItemRef memory asset2) = _getAssets(positionId);
        uint256 ownerCount = asset1.count();
        uint256 outputCount = asset2.count();
        require(outputCount > 0, 'has no output count');
        return ownerCount / outputCount;
    }

    function getAsset2Price(
        uint256 positionId
    ) external view returns (uint256) {
        return _getAsset2Price(positionId);
    }

    function _getAsset2Price(
        uint256 positionId
    ) internal view returns (uint256) {
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

    function _afterAssetTransfer(
        AssetTransferData calldata arg
    ) internal virtual override {
        (ItemRef memory asset1, ItemRef memory asset2) = _getAssets(
            arg.positionId
        );
        // transfers from assets are not processed
        if (arg.from == asset1.addr || arg.from == asset2.addr) return;
        // swap only if editing is locked
        require(_positionLocked(arg.positionId), '#8');
        // if there is no snapshot, then we do nothing
        require(arg.data.length == 3, '#9');

        // take fee
        FeeSettings memory feeSettings = fee[arg.positionId];
        // make a swap
        ItemRef memory feeDistributerAsset1;
        ItemRef memory feeDistributerAsset2;
        if (address(feeDistributers[arg.positionId]) != address(0)) {
            feeDistributerAsset1 = ITradingPairFeeDistributer(
                feeDistributers[arg.positionId]
            ).asset(1);
            feeDistributerAsset2 = ITradingPairFeeDistributer(
                feeDistributers[arg.positionId]
            ).asset(2);
        }
        if (arg.assetCode == 2) {
            // if the exchange is direct
            require(!constraints[arg.positionId].disableForwardSwap, '#10');
            _swap(
                arg.positionId,
                arg.from,
                arg.count,
                asset2,
                asset1,
                feeSettings.asset2,
                feeSettings.asset1,
                SwapSnapshot(arg.data[1], arg.data[0], arg.data[2]),
                feeDistributerAsset2,
                feeDistributerAsset1
            );
        } else {
            require(!constraints[arg.positionId].disableBackSwap, '#11');
            _swap(
                arg.positionId,
                arg.from,
                arg.count,
                asset1,
                asset2,
                feeSettings.asset1,
                feeSettings.asset2,
                SwapSnapshot(arg.data[0], arg.data[1], arg.data[2]),
                feeDistributerAsset1,
                feeDistributerAsset2
            );
        }
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
        // use blockLimit
        require(lastUseBlocks[positionId][from] + 1 < block.number, '#15');
        lastUseBlocks[positionId][from] = block.number;
        SwapVars memory vars;
        // count how much bought
        vars.inputlastCount = input.count() - amount;
        vars.buyCount = _getBuyCount(
            vars.inputlastCount,
            input.count(),
            output.count()
        );
        require(vars.buyCount <= output.count(), '#5');

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
        if (vars.lastPrice >= vars.snapPrice)
            vars.slippage = (vars.lastPrice * priceDecimals) / vars.snapPrice;
        else vars.slippage = (vars.snapPrice * priceDecimals) / vars.lastPrice;

        require(vars.slippage <= snapshot.slippage, '#6');

        // price should not change more than 50%
        vars.priceImpact = (vars.newPrice * priceDecimals) / vars.lastPrice;
        require(
            vars.priceImpact <= priceDecimals + priceDecimals / 2, // 150% of priceDecimals
            '#7'
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
        // take a tokens
        IErc20ForFactory liquidityToken = liquidityTokens[positionId];
        IErc20ForFactory feeToken = feeTokens[positionId];
        require(address(liquidityToken) != address(0), '#1');
        require(liquidityToken.balanceOf(msg.sender) >= liquidityCount, '#2');
        require(
            address(feeToken) == address(0) ||
                feeToken.balanceOf(msg.sender) >= liquidityCount,
            '#4'
        );
        // take assets
        (ItemRef memory own, ItemRef memory out) = _getAssets(positionId);
        // withdraw of owner asset
        uint256 asset1Count = (own.count() * liquidityCount) /
            liquidityToken.totalSupply();
        positionsController.withdrawInternal(own, msg.sender, asset1Count);
        // withdraw asset output
        uint256 asset2Count = (out.count() * liquidityCount) /
            liquidityToken.totalSupply();
        positionsController.withdrawInternal(out, msg.sender, asset2Count);

        // burn liquidity and fee tokens
        liquidityToken.burn(msg.sender, liquidityCount);
        if (address(feeToken) != address(0))
            feeToken.burn(msg.sender, liquidityCount);

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
        require(!this.positionLocked(asset.getPositionId()), '#3');
    }

    function getSnapshot(
        uint256 positionId,
        uint256 slippage
    ) external view returns (uint256, uint256, uint256) {
        return (
            positionsController.getAssetReference(positionId, 1).count(),
            positionsController.getAssetReference(positionId, 2).count(),
            priceDecimals + slippage
        );
    }

    function getPositionsController() external view returns (address) {
        return address(positionsController);
    }

    function getLiquidityToken(
        uint256 positionId
    ) external view returns (address) {
        return address(liquidityTokens[positionId]);
    }

    function getFeeToken(uint256 positionId) external view returns (address) {
        return address(feeTokens[positionId]);
    }

    function getFeeDistributer(
        uint256 positionId
    ) external view returns (address) {
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

import './IErc20ForFactory.sol';

interface IErc20ForFactoryFactory {
    /// @dev creates specific erc20 contract
    function create(string memory name, string memory symbol, uint8 decimals) external returns (IErc20ForFactory);
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
    mapping(address => uint256) _feeTokenLocks;
    mapping(address => uint256) _claimRounds;
    uint256 _totalFeetokensLocked;
    // fee round
    uint256 _feeRoundNumber;
    uint256 immutable _feeRoundInterval;
    uint256 _nextFeeRoundTime;
    // assets
    ItemRef _asset1;
    ItemRef _asset2;
    // distribution snapshot
    uint256 _currentRoundBeginingTotalFeeTokensLocked;
    uint256 _asset1ToDistributeCurrentRound;
    uint256 _asset2ToDistributeCurrentRound;
    // statistics
    uint256 _asset1DistributedTotal;
    uint256 _asset2DistributedTotal;

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
        _feeRoundInterval = feeRoundIntervalHours_ * 1 hours;
        _nextFeeRoundTime = block.timestamp + _feeRoundInterval;

        // create assets for fee
        _asset1 = asset1_.clone(address(this));
        _asset2 = asset2_.clone(address(this));
    }

    function feeRoundNumber() external view returns (uint256) {
        if (this.nextFeeRoundLapsedTime() == 0) return _feeRoundNumber + 1;
        return _feeRoundNumber;
    }

    function feeRoundInterval() external view returns (uint256) {
        return _feeRoundInterval;
    }

    function getLock(address account) external view returns (uint256) {
        return _feeTokenLocks[account];
    }

    function getClaimRound(address account) external view returns (uint256) {
        return _claimRounds[account];
    }

    function lockFeeTokens(uint256 amount) external {
        _tryNextFeeRound();
        _claimRewards(msg.sender);
        feeToken.transferFrom(msg.sender, address(this), amount);
        _feeTokenLocks[msg.sender] += amount;
        _totalFeetokensLocked += amount;
        emit OnLock(msg.sender, amount);
    }

    function unlockFeeTokens(uint256 amount) external {
        _tryNextFeeRound();
        _claimRewards(msg.sender);
        require(_feeTokenLocks[msg.sender] >= amount, 'not enough fee tokens');
        feeToken.transfer(msg.sender, amount);
        _feeTokenLocks[msg.sender] -= amount;
        _totalFeetokensLocked -= amount;
        emit OnUnlock(msg.sender, amount);
    }

    function totalFeeTokensLocked() external view returns (uint256) {
        return _totalFeetokensLocked;
    }

    function currentRoundBeginingTotalFeeTokensLocked()
        external
        view
        returns (uint256)
    {
        return _currentRoundBeginingTotalFeeTokensLocked;
    }

    function asset1ToDistributeCurrentRound() external view returns (uint256) {
        uint256 expectedAsset1ToDistributeCurrentRound = _asset1ToDistributeCurrentRound;
        if (this.nextFeeRoundLapsedTime() == 0) {
            expectedAsset1ToDistributeCurrentRound = _asset1.count();
        }
        return expectedAsset1ToDistributeCurrentRound;
    }

    function asset2ToDistributeCurrentRound() external view returns (uint256) {
        uint256 expectedAsset2ToDistributeCurrentRound = _asset2ToDistributeCurrentRound;
        if (this.nextFeeRoundLapsedTime() == 0) {
            expectedAsset2ToDistributeCurrentRound = _asset2.count();
        }
        return expectedAsset2ToDistributeCurrentRound;
    }

    function assetsToDistributeCurrentRound()
        external
        view
        returns (uint256, uint256)
    {
        uint256 expectedAsset1ToDistributeCurrentRound = _asset1ToDistributeCurrentRound;
        uint256 expectedAsset2ToDistributeCurrentRound = _asset2ToDistributeCurrentRound;
        if (this.nextFeeRoundLapsedTime() == 0) {
            expectedAsset1ToDistributeCurrentRound = _asset1.count();
            expectedAsset2ToDistributeCurrentRound = _asset2.count();
        }

        return (
            expectedAsset1ToDistributeCurrentRound,
            expectedAsset2ToDistributeCurrentRound
        );
    }

    function asset1DistributedTotal() external view returns (uint256) {
        return _asset1DistributedTotal;
    }

    function asset2DistributedTotal() external view returns (uint256) {
        return _asset2DistributedTotal;
    }

    function assetsDistributedTotal() external view returns (uint256, uint256) {
        return (_asset1DistributedTotal, _asset2DistributedTotal);
    }

    function tryNextFeeRound() external {
        _tryNextFeeRound();
    }

    function _tryNextFeeRound() internal {
        //console.log('_nextFeeRoundTime-block.timestamp', _nextFeeRoundTime-block.timestamp);
        if (block.timestamp < _nextFeeRoundTime) return;
        ++_feeRoundNumber;
        _nextFeeRoundTime = block.timestamp + _feeRoundInterval;
        // snapshot for distribute
        _currentRoundBeginingTotalFeeTokensLocked = _totalFeetokensLocked;
        _asset1ToDistributeCurrentRound = _asset1.count();
        _asset2ToDistributeCurrentRound = _asset2.count();
    }

    function getExpectedRewardForAccount(address account)
        external
        view
        returns (uint256, uint256)
    {
        uint256 expectedRoundNumber = _feeRoundNumber;
        if (this.nextFeeRoundLapsedTime() == 0) ++expectedRoundNumber;
        if (_claimRounds[msg.sender] >= expectedRoundNumber) return (0, 0);
        return this.getExpectedRewardForTokensCount(_feeTokenLocks[account]);
    }

    function getExpectedRewardForAccountNextRound(address account)
        external
        view
        returns (uint256, uint256)
    {
        return
            this.getExpectedRewardForTokensCountNextRound(
                _feeTokenLocks[account]
            );
    }

    function claimRewards() external {
        _tryNextFeeRound();
        require(_feeRoundNumber > 0, 'nothing to claim');
        require(
            _claimRounds[msg.sender] < _feeRoundNumber,
            'claimed yet or stacked on current round - wait for next round'
        );
        require(_feeTokenLocks[msg.sender] > 0, 'has no lock');
        _claimRewards(msg.sender);
    }

    function _claimRewards(address account) internal {
        if (_claimRounds[account] >= _feeRoundNumber) return;
        _claimRounds[account] = _feeRoundNumber;
        uint256 feeTokensCount = _feeTokenLocks[account];

        (uint256 asset1Count, uint256 asset2Count) = _getRewardForTokensCount(
            feeTokensCount,
            _currentRoundBeginingTotalFeeTokensLocked,
            _asset1ToDistributeCurrentRound,
            _asset2ToDistributeCurrentRound
        );
        _asset1DistributedTotal += asset1Count;
        _asset2DistributedTotal += asset2Count;
        if (asset1Count > 0) _asset1.withdraw(account, asset1Count);
        if (asset2Count > 0) _asset2.withdraw(account, asset2Count);

        ITradingPairAlgorithm(this.tradingPair()).ClaimFeeReward(
            _positionId,
            account,
            asset1Count,
            asset2Count,
            feeTokensCount
        );

        emit OnClaim(account, asset1Count, asset2Count);
    }

    /// @dev reward for tokens count
    function getExpectedRewardForTokensCount(uint256 feeTokensCount)
        external
        view
        returns (uint256, uint256)
    {
        uint256 expectedRoundNumber = _feeRoundNumber;
        uint256 expectedCurrentRoundBeginingTotalFeeTokensLocked = _currentRoundBeginingTotalFeeTokensLocked;
        uint256 expectedAsset1ToDistributeCurrentRound = _asset1ToDistributeCurrentRound;
        uint256 expectedAsset2ToDistributeCurrentRound = _asset2ToDistributeCurrentRound;
        if (this.nextFeeRoundLapsedTime() == 0) {
            ++expectedRoundNumber;
            expectedCurrentRoundBeginingTotalFeeTokensLocked = _totalFeetokensLocked;
            expectedAsset1ToDistributeCurrentRound = _asset1.count();
            expectedAsset2ToDistributeCurrentRound = _asset2.count();
        }

        return
            _getRewardForTokensCount(
                feeTokensCount,
                expectedCurrentRoundBeginingTotalFeeTokensLocked,
                expectedAsset1ToDistributeCurrentRound,
                expectedAsset2ToDistributeCurrentRound
            );
    }

    function getExpectedRewardForTokensCountNextRound(uint256 feeTokensCount)
        external
        view
        returns (uint256, uint256)
    {
        return
            _getRewardForTokensCount(
                feeTokensCount,
                _totalFeetokensLocked,
                _asset1.count(),
                _asset2.count()
            );
    }

    function _getRewardForTokensCount(
        uint256 feeTokensCount,
        uint256 totalFeeTokensLockedAtRound,
        uint256 asset1ToDistributeAtRound,
        uint256 asset2ToDistributeAtRound
    ) internal pure returns (uint256, uint256) {
        return (
            totalFeeTokensLockedAtRound > 0
                ? (asset1ToDistributeAtRound * feeTokensCount) /
                    totalFeeTokensLockedAtRound
                : (feeTokensCount > 0 ? asset1ToDistributeAtRound : 0),
            totalFeeTokensLockedAtRound > 0
                ? (asset2ToDistributeAtRound * feeTokensCount) /
                    totalFeeTokensLockedAtRound
                : (feeTokensCount > 0 ? asset2ToDistributeAtRound : 0)
        );
    }

    function nextFeeRoundLapsedMinutes() external view returns (uint256) {
        return this.nextFeeRoundLapsedTime() / (1 minutes);
    }

    function nextFeeRoundLapsedTime() external view returns (uint256) {
        if (block.timestamp >= _nextFeeRoundTime) return 0;
        return _nextFeeRoundTime - block.timestamp;
    }

    function nextFeeRoundTime() external view returns (uint256) {
        return _nextFeeRoundTime;
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

/// @dev the fee rewards distributer interface
interface ITradingPairFeeDistributer {
    /// @dev the lock event
    event OnLock(address indexed account, uint256 amount);

    /// @dev the unlock event
    event OnUnlock(address indexed account, uint256 amount);

    /// @dev the claim event
    event OnClaim(address indexed account, uint256 asset1Count, uint256 asset2Count);

    /// @dev locks the certain ammount of tokens
    function lockFeeTokens(uint256 amount) external;

    /// @dev unlocks certain ammount of tokens
    function unlockFeeTokens(uint256 amount) external;

    /// @dev the total number of fee tokens locked
    function totalFeeTokensLocked() external view returns (uint256);

    /// @dev tokens locked at the beginning of the current round
    function currentRoundBeginingTotalFeeTokensLocked()
        external
        view
        returns (uint256);

    /// @dev the asset1 to distrubute at current fee round
    function asset1ToDistributeCurrentRound() external view returns (uint256);

    /// @dev the asset2 to distrubute at current fee round
    function asset2ToDistributeCurrentRound() external view returns (uint256);

    /// @dev the assets to distrubute at current fee round
    function assetsToDistributeCurrentRound()
        external
        view
        returns (uint256, uint256);

    /// @dev the asset1 total distributed counts for statistics
    function asset1DistributedTotal() external view returns (uint256);

    /// @dev the asset1 total distributed counts for statistics
    function asset2DistributedTotal() external view returns (uint256);

    /// @dev the assets total distributed counts for statistics
    function assetsDistributedTotal() external view returns (uint256, uint256);

    /// @dev returns the number of the last round in which the account received a reward
    function getClaimRound(address account) external view returns (uint256);

    /// @dev returns the account ammount of tokens lock
    function getLock(address account) external view returns (uint256);

    /// @dev returns current time rewards counts for speciffic account
    function getExpectedRewardForAccount(address account)
        external
        view
        returns (uint256, uint256);

    /// @dev current reward for account current stack
    /// this value may be decrease (if claimed rewards or added stacks) or increase (if fee arrives)
    function getExpectedRewardForAccountNextRound(address account)
        external
        view
        returns (uint256, uint256);

    /// @dev reward for tokens count
    function getExpectedRewardForTokensCount(uint256 feeTokensCount)
        external
        view
        returns (uint256, uint256);

    /// @dev current reward for tokens count on next round
    /// this value may be decrease (if claimed rewards or added stacks) or increase (if fee arrives)
    function getExpectedRewardForTokensCountNextRound(uint256 feeTokensCount)
        external
        view
        returns (uint256, uint256);

    /// @dev grants rewards to sender
    function claimRewards() external;

    /// @dev returns the time between the fee rounds
    function feeRoundInterval() external view returns (uint256);

    /// @dev retruns the current fee round number
    function feeRoundNumber() external view returns (uint256);

    /// @dev remaining minutes until the next fee round
    function nextFeeRoundLapsedMinutes() external view returns (uint256);

    /// @dev remaining time until next fee round
    function nextFeeRoundLapsedTime() external view returns (uint256);

    /// @dev the time when available transfer the system to next fee round
    /// this transfer happens automatically when call any write function
    function nextFeeRoundTime() external view returns (uint256);

    /// @dev transfers the system into next fee round.
    /// this is technical function, available for everyone.
    /// despite this happens automatically when call any write function, sometimes it can be useful to scroll the state manually
    function tryNextFeeRound() external;

    /// @dev returns the fee asset reference
    function asset(uint256 assetCode) external view returns (ItemRef memory);

    /// @dev returns the fee asset count
    function assetCount(uint256 assetCode) external view returns (uint256);

    /// @dev returns the all fee assets counts
    function allAssetsCounts()
        external
        view
        returns (uint256 asset1Count, uint256 asset2Count);

    /// @dev the trading pair algorithm contract
    function tradingPair() external view returns (address);

    /// @dev the position id
    function positionId() external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import 'contracts/position_trading/algorithms/TradingPair/FeeSettings.sol';
import 'contracts/position_trading/AssetData.sol';
import 'contracts/position_trading/algorithms/TradingPair/TradingPairConstraints.sol';

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
        FeeSettings calldata feeSettings,
        TradingPairConstraints calldata constraints
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

    /// @dev returns the positions constraints
    function getConstraints(uint256 positionId)
        external
        view
        returns (TradingPairConstraints memory);

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

// @dev the trading pair constraints
struct TradingPairConstraints {
    /// @dev disallows forward swap
    bool disableForwardSwap;
    /// @dev disallows back swap
    bool disableBackSwap;
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

    function contractAddr(ItemRef memory ref) internal view returns (address) {
        return assetsController(ref).contractAddr(ref.id);
    }

    function getDecimals(ItemRef memory ref) internal view returns (uint8) {
        AssetData memory data = assetsController(ref).getData(ref.id);
        if (data.assetTypeId == 1) return 18;
        if (data.assetTypeId == 2) return 9;
        return 0;
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
    function feeAddress() external view returns (address); // address to pay fee

    function feePercent() external view returns (uint256); // fee in 1/decimals for deviding values

    function feePercentFor(address account) external view returns (uint256); // fee in 1/decimals for deviding values

    function feeDecimals() external view returns (uint256); // fee decimals

    function feeEth() external view returns (uint256); // fee value for not dividing deal points

    function feeEthFor(address account) external view returns (uint256); // fee in 1/decimals for deviding values

    function zeroFeeShare() external view returns (uint256); // if this account balance than zero fee
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
    address contractAddr; // contract, using in asset or zero if ether
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IErc20ForFactory is IERC20 {
    /// @dev mint
    /// pnlyFactory
    function mint(uint256 count) external;

    /// @dev mint to address
    /// pnlyFactory
    function mintTo(address account, uint256 count) external;

    /// @dev burn tokens
    /// onlyFactory
    function burn(address account, uint256 count) external;
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