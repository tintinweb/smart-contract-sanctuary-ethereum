pragma solidity ^0.8.17;
import './PositionAlgorithm.sol';
import 'contracts/interfaces/position_trading/IPositionsController.sol';
import 'contracts/interfaces/assets/IAsset.sol';
import './PositionLockerBase.sol';
import 'contracts/interfaces/position_trading/algorithms/IPositionLockerAlgorithmInstaller.sol';

/// @dev locks the asset of the position owner for a certain time
contract PositionLockerAlgorithm is
    PositionLockerBase,
    IPositionLockerAlgorithmInstaller
{
    constructor(address positionsController)
        PositionLockerBase(positionsController)
    {}

    function setAlgorithm(uint256 positionId) external {
        _setAlgorithm(positionId);
    }

    function _setAlgorithm(uint256 positionId)
        internal
        onlyPositionOwner(positionId)
        positionUnlocked(positionId)
    {
        ContractData memory data;
        data.factory = address(0);
        data.contractAddr = address(this);
        positionsController.setAlgorithm(positionId, data);
    }
}

pragma solidity ^0.8.17;
import 'contracts/interfaces/assets/IAsset.sol';
import 'contracts/interfaces/position_trading/IPositionAlgorithm.sol';
import 'contracts/interfaces/position_trading/IPositionsController.sol';
import 'contracts/position_trading/PositionSnapshot.sol';

/// @dev basic algorithm position
contract PositionAlgorithm is IPositionAlgorithm {
    IPositionsController public positionsController;

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

    modifier onlyPositionsController() {
        require(
            msg.sender == address(positionsController),
            'only for positions controller'
        );
        _;
    }

    modifier onlyAsset() {
        uint256 positionId = positionsController.getAssetPositionId(msg.sender);
        require(positionId > 0, 'only for assets');
        _;
    }

    function isPositionLocked(uint256)
        external
        view
        virtual
        override
        returns (bool)
    {
        return true;
    }

    function beforeAssetTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256[] memory data
    ) external override onlyAsset {
        _beforeAssetTransfer(asset, from, to, amount, data);
    }

    function _beforeAssetTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256[] memory data
    ) internal virtual {}

    function afterAssetTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256[] memory data
    ) external override onlyAsset {
        _afterAssetTransfer(asset, from, to, amount, data);
    }

    function _afterAssetTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256[] memory data
    ) internal virtual {}

    function withdrawAsset(
        uint256 positionId,
        uint256 assetCode,
        address recipient,
        uint256 amount
    ) external onlyPositionOwner(positionId) {
        _withdrawAsset(positionId, assetCode, recipient, amount);
    }

    function _withdrawAsset(
        uint256 positionId,
        uint256 assetCode,
        address recipient,
        uint256 amount
    ) internal virtual onlyPositionOwner(positionId) {
        address asset = positionsController
            .getAsset(positionId, assetCode)
            .contractAddr;
        require(asset != address(0), 'nas no owner asset');
        IAsset(asset).withdraw(recipient, amount);
    }

    function transferAssetOwnerShipTo(address asset, address newOwner)
        external
        override
        onlyPositionsController
    {
        _transferAssetOwnerShipTo(asset, newOwner);
    }

    function _transferAssetOwnerShipTo(address asset, address newOwner)
        internal
    {
        IOwnable(asset).transferOwnership(newOwner);
    }
}

pragma solidity ^0.8.17;
import 'contracts/lib/factories/ContractData.sol';
import 'contracts/fee/IFeeSettings.sol';

interface IPositionsController {
    /// @dev returns fee settings
    function getFeeSettings() external view returns(IFeeSettings);

    /// @dev returns the position owner
    function ownerOf(uint256 positionId) external view returns (address);

    /// @dev changes position owner
    function transferPositionOwnership(uint256 positionId, address newOwner)
        external;

    /// @dev returns the position of the asset to its address
    function getAssetPositionId(address assetAddress)
        external
        view
        returns (uint256);

    /// @dev returns an asset by its code in position 1 or 2
    function getAsset(uint256 positionId, uint256 assetCode)
        external
        view
        returns (ContractData memory);

    /// @dev creates a position
    function createPosition() external;

    /// @dev sets an asset to position
    /// @param positionId position ID
    /// @param assetCode asset code 1 - owner asset 2 - output asset
    /// @param data asset contract data
    function setAsset(
        uint256 positionId,
        uint256 assetCode,
        ContractData calldata data
    ) external;

    /// @dev sets the position algorithm
    function setAlgorithm(uint256 positionId, ContractData calldata data)
        external;

    /// @dev returns the position algorithm
    function getAlgorithm(uint256 positionId)
        external
        view
        returns (ContractData memory data);

    /// @dev disables position editing
    function disableEdit(uint256 positionId) external;

    /// @dev returns position from the account's list of positions
    function positionOfOwnerByIndex(address account, uint256 index)
        external
        view
        returns (uint256);

    /// @dev returns the number of positions the account owns
    function ownedPositionsCount(address account)
        external
        view
        returns (uint256);
}

pragma solidity ^0.8.17;
import 'contracts/interfaces/IOwnable.sol';

/// @dev asset abstraction
/// the owner of the asset is always the algorithm-observer of the asset
interface IAsset is IOwnable {
    /// @dev asset amount
    function count() external view returns (uint256);

    /// @dev withdrawal of a certain amount of asset to a certain address
    function withdraw(address recipient, uint256 amount) external;

    /// @dev creates a copy of the current asset, with 0 balance and the specified owner
    function clone(address owner) external returns (IAsset);

    /// @dev returns the asset type code (also used to check asset interface support)
    function assetTypeId() external returns (uint256);

    /// @dev if true, then notifies its observer (owner)
    function isNotifyListener() external returns (bool);

    /// @dev enables or disables the observer notification mechanism
    function setNotifyListener(bool value) external;
}

pragma solidity ^0.8.17;
import './PositionAlgorithm.sol';
import 'contracts/interfaces/position_trading/IPositionsController.sol';
import 'contracts/interfaces/assets/IAsset.sol';

/// @dev locks the asset of the position owner for a certain time
contract PositionLockerBase is PositionAlgorithm {
    mapping(uint256 => uint256) public unlockTimes; // unlock time by position

    modifier positionUnlocked(uint256 positionId) {
        require(!_positionLocked(positionId), 'for unlocked positions only');
        _;
    }

    modifier positionLocked(uint256 positionId) {
        require(_positionLocked(positionId), 'for locked positions only');
        _;
    }

    modifier assetUnLocked(uint256 positionId, uint256 assetCode) {
        if(!_positionLocked(positionId)){
             _;
             return;
        }
        if (assetCode == 1)
            require(!ownerAssetLocked(positionId), 'owner asset locked');
        else if (assetCode == 2)
            require(!outputAssetLocked(positionId), 'output asset locked');
        _;
    }

    constructor(address positionsController)
        PositionAlgorithm(positionsController)
    {}

    function isPositionLocked(uint256 positionId)
        external
        view
        virtual
        override
        returns (bool)
    {
        return _positionLocked(positionId);
    }

    function _positionLocked(uint256 positionId)
        internal
        view
        virtual
        returns (bool)
    {
        return block.timestamp < unlockTimes[positionId];
    }

    function lockPosition(uint256 positionId, uint256 lockSeconds)
        external
        onlyPositionOwner(positionId)
        positionUnlocked(positionId)
    {
        unlockTimes[positionId] = block.timestamp + lockSeconds * 1 seconds;
    }

    function lapsedLockSeconds(uint256 positionId)
        external
        view
        returns (uint256)
    {
        if (!_positionLocked(positionId)) return 0;
        return unlockTimes[positionId] - block.timestamp;
    }

    function _withdrawAsset(
        uint256 positionId,
        uint256 assetCode,
        address recipient,
        uint256 amount
    ) internal override assetUnLocked(positionId, assetCode) {
        super._withdrawAsset(positionId, assetCode, recipient, amount);
    }

    function ownerAssetLocked(uint256 positionId)
        public
        view
        virtual
        returns (bool)
    {
        return _positionLocked(positionId);
    }

    function outputAssetLocked(uint256 positionId)
        public
        view
        virtual
        returns (bool)
    {
        return _positionLocked(positionId);
    }
}

pragma solidity ^0.8.17;
interface IPositionLockerAlgorithmInstaller {
    /// @dev sets the position lock algorithm
    function setAlgorithm(uint256 positionId) external;
}

pragma solidity ^0.8.17;
import 'contracts/interfaces/assets/IAssetListener.sol';

interface IPositionAlgorithm is IAssetListener {
    /// @dev if true, the algorithm locks position editing
    function isPositionLocked(uint256 positionId) external view returns (bool);

    /// @dev transfers ownership of the asset to the specified address
    function transferAssetOwnerShipTo(address asset, address newOwner) external;
}

pragma solidity ^0.8.17;
// todo cut out
struct PositionSnapshot {
    uint256 owner;
    uint256 output;
    uint256 slippage;
}

pragma solidity ^0.8.17;
interface IOwnable {
    function owner() external returns (address);

    function transferOwnership(address newOwner) external;
}

pragma solidity ^0.8.17;
import 'contracts/position_trading/PositionSnapshot.sol';

interface IAssetListener {
    function beforeAssetTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256[] memory data
    ) external;

    function afterAssetTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256[] memory data
    ) external;
}

pragma solidity ^0.8.17;
/// @dev data is generated by factory of contract
struct ContractData {
    address factory; // factory
    address contractAddr; // contract
}

pragma solidity ^0.8.17;
interface IFeeSettings {
    function feeAddress() external returns (address); // address to pay fee

    function feePercent() external returns (uint256); // fee in 1/decimals for deviding values

    function feeDecimals() external view returns(uint256); // fee decimals

    function feeEth() external returns (uint256); // fee value for not dividing deal points
}