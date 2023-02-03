// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import '../lib/factories/HasFactories.sol';
import './ItemRef.sol';
import 'contracts/position_trading/IPositionAlgorithm.sol';
import './IPositionsController.sol';
import 'contracts/fee/IFeeSettings.sol';
import 'contracts/position_trading/ItemRefAsAssetLibrary.sol';
import 'contracts/position_trading/AssetTransferData.sol';

interface IErc20Balance {
    function balanceOf(address account) external view returns (uint256);
}

contract PositionsController is HasFactories, IPositionsController {
    using ItemRefAsAssetLibrary for ItemRef;

    IFeeSettings feeSettings;
    uint256 _positionsCount; // total positions created
    uint256 _assetsCount;
    mapping(uint256 => address) public owners; // position owners
    mapping(uint256 => ItemRef) public ownerAssets; // owner's asset (what is offered). by position ids
    mapping(uint256 => ItemRef) public outputAssets; // output asset (what they want in return), may be absent, in case of locks. by position ids
    mapping(uint256 => address) public algorithms; // algorithm for processing the input and output asset
    mapping(uint256 => bool) _buildModes; // build modes by positions
    mapping(uint256 => uint256) _positionsByAssets;

    constructor(address feeSettings_) {
        feeSettings = IFeeSettings(feeSettings_);
    }

    receive() external payable {}

    modifier onlyPositionOwner(uint256 positionId) {
        require(owners[positionId] == msg.sender, 'only for position owner');
        _;
    }

    modifier onlyBuildMode(uint256 positionId) {
        require(this.isBuildMode(positionId), 'only for position build mode');
        _;
    }

    modifier oplyPositionAlgorithm(uint256 positionId) {
        require(
            this.getAlgorithm(positionId) == msg.sender,
            'only for position algotithm'
        );
        _;
    }

    function createPosition(address owner)
        external
        onlyFactory
        returns (uint256)
    {
        ++_positionsCount;
        owners[_positionsCount] = owner;
        _buildModes[_positionsCount] = true;
        return _positionsCount;
    }

    function getPosition(uint256 positionId)
        external
        view
        returns (
            address algorithm,
            AssetData memory asset1,
            AssetData memory asset2
        )
    {
        algorithm = algorithms[positionId];
        ItemRef memory ref = this.getAssetReference(positionId, 1);
        if (ref.addr != address(0)) asset1 = ref.getData();
        ref = this.getAssetReference(positionId, 2);
        if (ref.addr != address(0)) asset2 = ref.getData();
    }

    function positionsCount() external returns (uint256) {
        return _positionsCount;
    }

    function isBuildMode(uint256 positionId) external view returns (bool) {
        return _buildModes[positionId];
    }

    function stopBuild(uint256 positionId)
        external
        onlyFactory
        onlyBuildMode(positionId)
    {
        address alg = algorithms[positionId];
        require(alg != address(0), 'has no algorithm');

        delete _buildModes[positionId];

        emit NewPosition(
            owners[positionId],
            algorithms[positionId],
            positionId
        );
    }

    function getFeeSettings() external view returns (IFeeSettings) {
        return feeSettings;
    }

    function ownerOf(uint256 positionId)
        external
        view
        override
        returns (address)
    {
        return owners[positionId];
    }

    function getAssetReference(uint256 positionId, uint256 assetCode)
        external
        view
        returns (ItemRef memory)
    {
        if (assetCode == 1) return ownerAssets[positionId];
        else if (assetCode == 2) return outputAssets[positionId];
        else revert('unknown asset code');
    }

    function getAllPositionAssetReferences(uint256 positionId)
        external
        view
        returns (ItemRef memory position1, ItemRef memory position2)
    {
        return (ownerAssets[positionId], outputAssets[positionId]);
    }

    function getAsset(uint256 positionId, uint256 assetCode)
        external
        view
        returns (AssetData memory data)
    {
        return this.getAssetReference(positionId, assetCode).getData();
    }

    function createAsset(
        uint256 positionId,
        uint256 assetCode,
        address assetsController
    ) external onlyFactory returns (ItemRef memory) {
        ItemRef memory asset = ItemRef(assetsController, _createNewAssetId());
        _positionsByAssets[asset.id] = positionId;

        if (assetCode == 1) ownerAssets[positionId] = asset;
        else if (assetCode == 2) outputAssets[positionId] = asset;
        else revert('unknown asset code');

        return asset;
    }

    function setAlgorithm(uint256 positionId, address algorithm)
        external
        onlyFactory
        onlyBuildMode(positionId)
    {
        algorithms[positionId] = algorithm;
    }

    function getAlgorithm(uint256 positionId)
        external
        view
        override
        returns (address)
    {
        return algorithms[positionId];
    }

    function assetsCount() external view returns (uint256) {
        return _assetsCount;
    }

    function createNewAssetId() external onlyFactory returns (uint256) {
        return _createNewAssetId();
    }

    function _createNewAssetId() internal onlyFactory returns (uint256) {
        return ++_assetsCount;
    }

    function getAssetPositionId(uint256 assetId)
        external
        view
        returns (uint256)
    {
        return _positionsByAssets[assetId];
    }

    function beforeAssetTransfer(AssetTransferData calldata arg)
        external
        onlyFactory
    {
        uint256 positionId = arg.asset.getPositionId();
        IPositionAlgorithm alg = IPositionAlgorithm(algorithms[positionId]);
        if (address(alg) == address(0)) return;
        alg.beforeAssetTransfer(arg);
    }

    function afterAssetTransfer(AssetTransferData calldata arg)
        external
        payable
        onlyFactory
    {
        uint256 positionId = arg.asset.getPositionId();
        IPositionAlgorithm alg = IPositionAlgorithm(algorithms[positionId]);
        if (address(alg) == address(0)) return;
        alg.afterAssetTransfer{ value: msg.value }(arg);
    }

    function transferToAsset(
        uint256 positionId,
        uint256 assetCode,
        uint256 count,
        uint256[] calldata data
    ) external payable returns (uint256 ethSurplus) {
        ItemRef memory asset = this.getAssetReference(positionId, assetCode);
        ethSurplus = IAssetsController(asset.addr).transferToAsset{
            value: msg.value
        }(
            AssetTransferData(
                positionId,
                asset,
                assetCode,
                msg.sender,
                asset.addr,
                count,
                data
            )
        );
        if (ethSurplus > 0) {
            (bool surplusSent, ) = payable(msg.sender).call{
                value: ethSurplus
            }('');
            require(surplusSent, 'ethereum surplus is not sent');
        }
    }

    function transferToAssetFrom(
        address from,
        uint256 positionId,
        uint256 assetCode,
        uint256 count,
        uint256[] calldata data
    ) external payable onlyFactory returns (uint256 ethSurplus) {
        ItemRef memory asset = this.getAssetReference(positionId, assetCode);
        ethSurplus = IAssetsController(asset.addr).transferToAsset{
            value: msg.value
        }(
            AssetTransferData(
                positionId,
                asset,
                assetCode,
                from,
                asset.addr,
                count,
                data
            )
        );
        if (ethSurplus > 0) {
            (bool surplusSent, ) = msg.sender.call{ value: ethSurplus }('');
            require(surplusSent, 'ethereum surplus is not sent');
        }
    }

    function transferToAnotherAssetInternal(
        ItemRef calldata from,
        ItemRef calldata to,
        uint256 count
    ) external oplyPositionAlgorithm(from.getPositionId()) {
        require(
            from.assetTypeId() == to.assetTypeId(),
            'transfer from asset to must be same types'
        );
        if (to.assetTypeId() == 2) {
            uint256 lastBalance = IErc20Balance(to.contractAddr()).balanceOf(to.addr);
            from.withdraw(to.addr, count);
            to.addCount(IErc20Balance(to.contractAddr()).balanceOf(to.addr) - lastBalance);
        } else {
            from.withdraw(to.addr, count);
            to.addCount(count);
        }
    }

    function withdraw(
        uint256 positionId,
        uint256 assetCode,
        uint256 count
    ) external onlyPositionOwner(positionId) {
        _withdrawTo(positionId, assetCode, msg.sender, count);
    }

    function withdrawTo(
        uint256 positionId,
        uint256 assetCode,
        address to,
        uint256 count
    ) external {
        _withdrawTo(positionId, assetCode, to, count);
    }

    function _withdrawTo(
        uint256 positionId,
        uint256 assetCode,
        address to,
        uint256 count
    ) internal {
        address algAddr = this.getAlgorithm(positionId);
        ItemRef memory asset = this.getAssetReference(positionId, assetCode);
        if (algAddr != address(0)) {
            IPositionAlgorithm(algAddr).checkCanWithdraw(
                asset,
                assetCode,
                count
            );
        }
        asset.withdraw(to, count);
    }

    function withdrawInternal(
        ItemRef calldata asset,
        address to,
        uint256 count
    ) external oplyPositionAlgorithm(asset.getPositionId()) {
        asset.withdraw(to, count);
    }

    function count(ItemRef calldata asset) external view returns (uint256) {
        return asset.count();
    }

    function getCounts(uint256 positionId)
        external
        view
        returns (uint256, uint256)
    {
        return (
            this.getAssetReference(positionId, 1).count(),
            this.getAssetReference(positionId, 2).count()
        );
    }

    function positionLocked(uint256 positionId) external view returns (bool) {
        address algAddr = this.getAlgorithm(positionId);
        if (algAddr == address(0)) return false;
        return IPositionAlgorithm(algAddr).positionLocked(positionId);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import '../ownable/Ownable.sol';
import './IHasFactories.sol';

contract HasFactories is Ownable, IHasFactories {
    mapping(address => bool) internal _factories; // factories

    modifier onlyFactory() {
        require(_isFactory(msg.sender), 'only for factories');
        _;
    }

    function isFactory(address addr) external view returns (bool) {
        return _isFactory(addr);
    }

    function _isFactory(address addr) internal view returns (bool) {
        if (addr == address(this)) return true;
        return _factories[addr];
    }

    function addFactory(address factory) external onlyOwner {
        _factories[factory] = true;
    }

    function removeFactory(address factory) external onlyOwner {
        _factories[factory] = false;
    }

    function setFactories(address[] calldata addresses, bool isFactory_)
        external
        onlyOwner
    {
        uint256 len = addresses.length;
        for (uint256 i = 0; i < len; ++i) {
            _factories[addresses[i]] = isFactory_;
        }
    }
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

interface IFeeSettings {
    function feeAddress() external returns (address); // address to pay fee

    function feePercent() external returns (uint256); // fee in 1/decimals for deviding values

    function feeDecimals() external view returns(uint256); // fee decimals

    function feeEth() external returns (uint256); // fee value for not dividing deal points
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

import './IOwnable.sol';

contract Ownable is IOwnable {
    address _owner;

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, 'caller is not the owner');
        _;
    }

    function owner() external virtual view returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) external override onlyOwner {
        _owner = newOwner;
    }
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

// todo cut out
struct PositionSnapshot {
    uint256 owner;
    uint256 output;
    uint256 slippage;
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