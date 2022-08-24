import '../lib/factories/HasFactories.sol';
//import '../lib/factories/ContractData.sol';
import 'contracts/interfaces/position_trading/IPositionAlgorithm.sol';
import 'contracts/interfaces/position_trading/IPositionsController.sol';

contract PositionsController is
    HasFactories,
    IPositionsController,
    IAssetListener
{
    uint256 public totalPositions; // total positions created
    mapping(uint256 => address) public owners; // владельцы позиций
    mapping(uint256 => ContractData) public ownerAssets; // актив владельца (что предлагают)
    mapping(uint256 => ContractData) public outputAssets; // выходной актив (что хотят взамен), может отсуствовать, в случае локов
    mapping(uint256 => ContractData) public algorithms; // алгоритм обработки входного и выходного актива (ассета)
    mapping(uint256 => bool) public editingLocks; // запреты на редактирование позиций
    mapping(address => mapping(uint256 => uint256))
        public positionListsByAccounts; // индексированные с 0 позиции для каждого аккаунта
    mapping(address => uint256) public positionCountsByAccounts; // количества позиций по аккаунтам
    mapping(address => uint256) _positionsByAssets; // позиции ассетов

    event NewPosition(address indexed account, uint256 indexed positionId);

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
        require(
            owners[positionId] == msg.sender,
            'can call only position owner'
        );
        _;
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

    function ownerAsset(uint256 positionId)
        external
        view
        override
        returns (ContractData memory)
    {
        return ownerAssets[positionId];
    }

    function outputAsset(uint256 positionId)
        external
        view
        returns (ContractData memory)
    {
        return outputAssets[positionId];
    }

    function createPosition() external override {
        ++totalPositions;
        positionListsByAccounts[msg.sender][
            positionCountsByAccounts[msg.sender]++
        ] = totalPositions;

        owners[totalPositions] = msg.sender;

        emit NewPosition(msg.sender, totalPositions);
    }

    function setOwnerAsset(uint256 positionId, ContractData calldata data)
        external
        override
        onlyFactory
        positionUnLocked(positionId)
    {
        ownerAssets[positionId] = data;
        _positionsByAssets[data.contractAddr] = positionId;
        trySetAssetOwnershipToAlgorithm(positionId, data);
    }

    function setOutputAsset(uint256 positionId, ContractData calldata data)
        external
        override
        onlyFactory
        positionUnLocked(positionId)
    {
        outputAssets[positionId] = data;
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
            if (algorithms[positionId].contractAddr != address(0)){
                IPositionAlgorithm(algorithms[positionId].contractAddr)
                    .transferAssetOwnerShipTo(
                        ownerAssets[positionId].contractAddr,
                        algData.contractAddr != address(0)
                            ? algData.contractAddr
                            : address(this)
                    );
            }
            else{
                IOwnable(ownerAssets[positionId].contractAddr)
                    .transferOwnership(algData.contractAddr);
            }
        }
        // выходной ассет
        if (outputAssets[positionId].contractAddr != address(0)) {
            if (algorithms[positionId].contractAddr != address(0)){
                IPositionAlgorithm(algorithms[positionId].contractAddr)
                    .transferAssetOwnerShipTo(
                        outputAssets[positionId].contractAddr,
                        algData.contractAddr != address(0)
                            ? algData.contractAddr
                            : address(this)
                    );
            }
            else{
                IOwnable(outputAssets[positionId].contractAddr)
                    .transferOwnership(algData.contractAddr);
            }
        }

        // задаем новый алгоритм
        algorithms[positionId] = algData;
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

interface IPositionsController {
    /// @dev возвращает владельца позиции
    function ownerOf(uint256 positionId) external view returns (address);

    /// @dev возаращает позицию ассета его адресу
    function getAssetPositionId(address assetAddress)
        external
        view      
        returns (uint256);

    /// @dev возвращает актив владельца позиции
    function ownerAsset(uint256 positionId)
        external
        view
        returns (ContractData memory);

    /// @dev возвращает актив владельца позиции
    function outputAsset(uint256 positionId)
        external
        view
        returns (ContractData memory);

    /// @dev создает позицию
    function createPosition() external;

    /// @dev задает ассет владельца
    function setOwnerAsset(uint256 positionId, ContractData calldata data)
        external;

    /// @dev задает выходной ассет
    function setOutputAsset(uint256 positionId, ContractData calldata data)
        external;

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
    function owner() external returns(address);
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