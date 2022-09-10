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
    mapping(uint256 => address) public owners; // владельцы позиций
    mapping(uint256 => ContractData) public ownerAssets; // актив владельца (что предлагают)
    mapping(uint256 => ContractData) public outputAssets; // выходной актив (что хотят взамен), может отсуствовать, в случае локов
    mapping(uint256 => ContractData) public algorithms; // алгоритм обработки входного и выходного актива (ассета)
    mapping(uint256 => bool) public editingLocks; // запреты на редактирование позиций
    mapping(address => mapping(uint256 => uint256)) _ownedPositions; // индексированные с 0 позиции для каждого аккаунта
    mapping(uint256 => uint256) _ownedPositionsIndex; // мапинг из ID позиции в индекс в списке владельца
    mapping(address => uint256) _positionCountsByAccounts; // количества позиций по аккаунтам
    mapping(address => uint256) _positionsByAssets; // позиции ассетов

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
                IPositionAlgorithm(data.contractAddr).isPositionLocked(
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
        if (assetCode == 1) ownerAssets[positionId] = data;
        else if (assetCode == 2) outputAssets[positionId] = data;
        else revert('unknown asset code');
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
        // если уже есть алгоритм, то передаем овнершип ассетов текущему контролеру или на новый алгоритм
        // овнерский ассет
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
        // выходной ассет
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

        // задаем новый алгоритм
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
    ) external override {}

    function afterAssetTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256[] memory data
    ) external override {}
}

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

import 'contracts/interfaces/assets/IAssetListener.sol';

interface IPositionAlgorithm is IAssetListener {
    /// @dev если истина, то алгоритм блокирует редактирование позиции
    function isPositionLocked(uint256 positionId) external view returns (bool);

    /// @dev передаtn право владения ассетом указанному адресу
    function transferAssetOwnerShipTo(address asset, address newOwner) external;
}

import 'contracts/lib/factories/ContractData.sol';
import 'contracts/fee/IFeeSettings.sol';

interface IPositionsController {
    /// @dev возвращает налоговые настройки
    function getFeeSettings() external view returns(IFeeSettings);

    /// @dev возвращает владельца позиции
    function ownerOf(uint256 positionId) external view returns (address);

    /// @dev меняет владельца позиции
    function transferPositionOwnership(uint256 positionId, address newOwner)
        external;

    /// @dev возаращает позицию ассета его адресу
    function getAssetPositionId(address assetAddress)
        external
        view
        returns (uint256);

    /// @dev возвращает актив по его коду в позиции 1 или 2
    function getAsset(uint256 positionId, uint256 assetCode)
        external
        view
        returns (ContractData memory);

    /// @dev создает позицию
    function createPosition() external;

    /// @dev задает ассет на позицию
    /// @param positionId ID позиции
    /// @param assetCode код ассета 1 - овнер ассет 2 - выходной ассет
    /// @param data данные контракта ассета
    function setAsset(
        uint256 positionId,
        uint256 assetCode,
        ContractData calldata data
    ) external;

    /// @dev задает алгоритм позиции
    function setAlgorithm(uint256 positionId, ContractData calldata data)
        external;

    /// @dev возвращает алгоритм позиции
    function getAlgorithm(uint256 positionId)
        external
        view
        returns (ContractData memory data);

    /// @dev запрещает редактировать позицию
    function disableEdit(uint256 positionId) external;

    /// @dev возвращает позицию из списка позиций аккаунта
    function positionOfOwnerByIndex(address account, uint256 index)
        external
        view
        returns (uint256);

    /// @dev возвращает количество позиций, которыми владеет аккаунт
    function ownedPositionsCount(address account)
        external
        view
        returns (uint256);
}

interface IFeeSettings {
    function feeAddress() external returns (address); // address to pay fee

    function feePercent() external returns (uint256); // fee in 1/decimals for deviding values

    function feeDecimals() external view returns(uint256); // fee decimals

    function feeEth() external returns (uint256); // fee value for not dividing deal points
}

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

interface IOwnable {
    function owner() external returns (address);

    function transferOwnership(address newOwner) external;
}

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

// todo вырезать
struct PositionSnapshot {
    uint256 owner;
    uint256 output;
    uint256 slippage;
}

/// @dev данные порождаемого фабрикой контракта
struct ContractData {
    address factory; // фабрика
    address contractAddr; // контракт
}