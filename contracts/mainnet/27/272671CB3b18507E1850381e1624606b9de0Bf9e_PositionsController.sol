pragma solidity ^0.8.17;
import '../lib/factories/HasFactories.sol';
//import '../lib/factories/ContractData.sol';
import 'contracts/interfaces/position_trading/IPositionAlgorithm.sol';
import 'contracts/interfaces/position_trading/IPositionsController.sol';
import 'contracts/fee/IFeeSettings.sol';

contract PositionsController is
    HasFactories,
    IPositionsController,
    IAssetListener
{
    IFeeSettings feeSettings;
    uint256 public totalPositions; // total positions created
    mapping(uint256 => address) public owners; // position owners
    mapping(uint256 => ContractData) public ownerAssets; // owner's asset (what is offered)
    mapping(uint256 => ContractData) public outputAssets; // output asset (what they want in return), may be absent, in case of locks
    mapping(uint256 => ContractData) public algorithms; // algorithm for processing the input and output asset
    mapping(uint256 => bool) public editingLocks; // locks on editing positions
    mapping(address => mapping(uint256 => uint256)) _ownedPositions; // indexed from position 0 for each account
    mapping(uint256 => uint256) _ownedPositionsIndex; // mapping from position ID to index in owner list
    mapping(address => uint256) _positionCountsByAccounts; // counts of positions by account
    mapping(address => uint256) _positionsByAssets; // asset positions

    event NewPosition(address indexed account, uint256 indexed positionId);
    event SetPositionAlgorithm(uint256 indexed positionId, ContractData data);
    event TransferPositionOwnership(
        uint256 indexed positionId,
        address lastOwner,
        address newOwner
    );

    constructor(address feeSettings_) {
        feeSettings = IFeeSettings(feeSettings_);
    }

    modifier positionUnLocked(uint256 positionId) {
        require(!editingLocks[positionId], 'position editing is locked');
        ContractData memory data = algorithms[positionId];
        if (data.contractAddr != address(0)) {
            require(
                !IPositionAlgorithm(data.contractAddr).isPositionLocked(
                    positionId
                ),
                'position algogithm is not allowed to edit position'
            );
        }
        _;
    }

    modifier onlyPositionOwner(uint256 positionId) {
        require(owners[positionId] == msg.sender, 'only for position owner');
        _;
    }

    function getFeeSettings() external view returns (IFeeSettings) {
        return feeSettings;
    }

    function positionOfOwnerByIndex(address account, uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            index < _positionCountsByAccounts[account],
            'account positions index out of bounds'
        );
        return _ownedPositions[account][index];
    }

    function _addPositionToOwnerEnumeration(address to, uint256 positionId)
        private
    {
        uint256 length = _positionCountsByAccounts[to];
        _ownedPositions[to][length] = positionId;
        _ownedPositionsIndex[positionId] = length;
    }

    function _removePositionFromOwnerEnumeration(
        address from,
        uint256 positionId
    ) private {
        uint256 lastPositionIndex = _positionCountsByAccounts[from] - 1;
        uint256 positionIndex = _ownedPositionsIndex[positionId];

        // When the position to delete is the last posiiton, the swap operation is unnecessary
        if (positionIndex != lastPositionIndex) {
            uint256 lastPositionId = _ownedPositions[from][lastPositionIndex];

            _ownedPositions[from][positionIndex] = lastPositionId; // Move the last position to the slot of the to-delete token
            _ownedPositionsIndex[lastPositionId] = positionIndex; // Update the moved position's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedPositionsIndex[positionId];
        delete _ownedPositions[from][lastPositionIndex];
    }

    function transferPositionOwnership(uint256 positionId, address newOwner)
        external
        onlyPositionOwner(positionId)
    {
        _removePositionFromOwnerEnumeration(msg.sender, positionId);
        _addPositionToOwnerEnumeration(newOwner, positionId);
        --_positionCountsByAccounts[msg.sender];
        ++_positionCountsByAccounts[newOwner];
        owners[positionId] = newOwner;
        emit TransferPositionOwnership(positionId, msg.sender, newOwner);
    }

    function ownedPositionsCount(address account)
        external
        view
        override
        returns (uint256)
    {
        return _positionCountsByAccounts[account];
    }

    function getAssetPositionId(address assetAddress)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return _positionsByAssets[assetAddress];
    }

    function ownerOf(uint256 positionId)
        external
        view
        override
        returns (address)
    {
        return owners[positionId];
    }

    function getAsset(uint256 positionId, uint256 assetCode)
        external
        view
        returns (ContractData memory)
    {
        if (assetCode == 1) return ownerAssets[positionId];
        else if (assetCode == 2) return outputAssets[positionId];
        else revert('unknown asset code');
    }

    function createPosition() external override {
        ++totalPositions;
        owners[totalPositions] = msg.sender;
        _addPositionToOwnerEnumeration(msg.sender, totalPositions);
        _positionCountsByAccounts[msg.sender]++;
        emit NewPosition(msg.sender, totalPositions);
    }

    function setAsset(
        uint256 positionId,
        uint256 assetCode,
        ContractData calldata data
    ) external override onlyFactory positionUnLocked(positionId) {
        if (assetCode == 1) {
            delete _positionsByAssets[ownerAssets[positionId].contractAddr];
            ownerAssets[positionId] = data;
        } else if (assetCode == 2) {
            delete _positionsByAssets[outputAssets[positionId].contractAddr];
            outputAssets[positionId] = data;
        } else revert('unknown asset code');
        _positionsByAssets[data.contractAddr] = positionId;
        trySetAssetOwnershipToAlgorithm(positionId, data);
    }

    function trySetAssetOwnershipToAlgorithm(
        uint256 positionId,
        ContractData calldata assetData
    ) internal {
        if (algorithms[positionId].contractAddr != address(0))
            IOwnable(assetData.contractAddr).transferOwnership(
                algorithms[positionId].contractAddr
            );
    }

    function setAlgorithm(uint256 positionId, ContractData calldata algData)
        external
        override
        onlyFactory
        positionUnLocked(positionId)
    {
        // if there is already an algorithm, then transfer the asset ownership to the current controller or to a new algorithm
        // owner's asset
        if (ownerAssets[positionId].contractAddr != address(0)) {
            if (algorithms[positionId].contractAddr != address(0)) {
                IPositionAlgorithm(algorithms[positionId].contractAddr)
                    .transferAssetOwnerShipTo(
                        ownerAssets[positionId].contractAddr,
                        algData.contractAddr != address(0)
                            ? algData.contractAddr
                            : address(this)
                    );
            } else {
                IOwnable(ownerAssets[positionId].contractAddr)
                    .transferOwnership(algData.contractAddr);
            }
        }
        // output asset
        if (outputAssets[positionId].contractAddr != address(0)) {
            if (algorithms[positionId].contractAddr != address(0)) {
                IPositionAlgorithm(algorithms[positionId].contractAddr)
                    .transferAssetOwnerShipTo(
                        outputAssets[positionId].contractAddr,
                        algData.contractAddr != address(0)
                            ? algData.contractAddr
                            : address(this)
                    );
            } else {
                IOwnable(outputAssets[positionId].contractAddr)
                    .transferOwnership(algData.contractAddr);
            }
        }

        // set a new algorithm
        algorithms[positionId] = algData;

        emit SetPositionAlgorithm(positionId, algData);
    }

    function getAlgorithm(uint256 positionId)
        external
        view
        override
        returns (ContractData memory data)
    {
        return algorithms[positionId];
    }

    function disableEdit(uint256 positionId)
        external
        override
        onlyPositionOwner(positionId)
        positionUnLocked(positionId)
    {
        editingLocks[positionId] = false;
    }

    function beforeAssetTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256[] memory data
    ) external pure override {
        revert('has no algorithm');
    }

    function afterAssetTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256[] memory data
    ) external pure override {
        revert('has no algorithm');
    }
}

pragma solidity ^0.8.17;
import '../ownable/Ownable.sol';

abstract contract HasFactories is Ownable {
    mapping(address => bool) factories; // factories

    modifier onlyFactory() {
        require(factories[msg.sender], 'only for factories');
        _;
    }

    function addFactory(address factory) public onlyOwner {
        factories[factory] = true;
    }

    function removeFactory(address factory) public onlyOwner {
        factories[factory] = false;
    }

    function setFactories(address[] calldata addresses, bool isFactory)
        public
        onlyOwner
    {
        uint256 len = addresses.length;
        for (uint256 i = 0; i < len; ++i) {
            factories[addresses[i]] = isFactory;
        }
    }
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
interface IFeeSettings {
    function feeAddress() external returns (address); // address to pay fee

    function feePercent() external returns (uint256); // fee in 1/decimals for deviding values

    function feeDecimals() external view returns(uint256); // fee decimals

    function feeEth() external returns (uint256); // fee value for not dividing deal points
}

pragma solidity ^0.8.17;
import 'contracts/interfaces/IOwnable.sol';

contract Ownable is IOwnable {
    address _owner;

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, 'caller is not the owner');
        _;
    }

    function owner() external virtual override returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) external override onlyOwner {
        _owner = newOwner;
    }
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
// todo cut out
struct PositionSnapshot {
    uint256 owner;
    uint256 output;
    uint256 slippage;
}

pragma solidity ^0.8.17;
/// @dev data is generated by factory of contract
struct ContractData {
    address factory; // factory
    address contractAddr; // contract
}