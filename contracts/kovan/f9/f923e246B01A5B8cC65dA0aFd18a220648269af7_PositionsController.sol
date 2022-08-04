import "../lib/ownable/Ownable.sol";
import "../lib/factories/HasFactories.sol";
import "contracts/position_trading/ContractData.sol";
import "contracts/position_trading/algorithms/IPositionAlgorithm.sol";
import "./IPositionsController.sol";

contract PositionsController is HasFactories, IPositionsController {
    uint256 public totalPositions; // total positions created
    mapping(uint256 => address) public owners; // владельцы позиций
    mapping(uint256 => ContractData) public ownerAssets; // актив владельца (что предлагают)
    mapping(uint256 => ContractData) public outputAssets; // выходной актив (что хотят взамен), может отсуствовать, в случае локов
    mapping(uint256 => ContractData) public algorithms; // алгоритм обработки входного и выходного актива (ассета)
    mapping(uint256 => bool) public editingLocks; // запреты на редактирование позиций
    mapping(address => mapping(uint256 => uint256)) public positionListsByAccounts; // индексированные с 0 позиции для каждого аккаунта
    mapping(address => uint256) public positionCountsByAccounts; // количества позиций по аккаунтам

    event NewPosition(address indexed account, uint256 indexed positionId);

    modifier ifCanEditPosition(uint256 positionId) {
        require(!editingLocks[positionId], "position editing is locked");
        ContractData memory data = algorithms[positionId];
        if (data.contractAddr != address(0)) {
            require(
                !IPositionAlgorithm(data.contractAddr).allowEditPosition(
                    positionId
                ),
                "position algogithm is not allowed to edit position"
            );
        }
        _;
    }

    modifier onlyPositionOwner(uint256 positionId) {
        require(
            owners[positionId] == msg.sender,
            "can call only position owner"
        );
        _;
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
        ifCanEditPosition(positionId)
    {
        ownerAssets[positionId] = data;
    }

    function setOutputAsset(uint256 positionId, ContractData calldata data)
        external
        override
        onlyFactory
        ifCanEditPosition(positionId)
    {
        outputAssets[positionId] = data;
    }

    function setAlgorithm(uint256 positionId, ContractData calldata data)
        external
        override
        onlyFactory
        ifCanEditPosition(positionId)
    {
        algorithms[positionId] = data;
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
        ifCanEditPosition(positionId)
    {
        editingLocks[positionId] = false;
    }
}

contract Ownable {
    address _owner;

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        _owner = newOwner;
    }
}

import "../ownable/Ownable.sol";

abstract contract HasFactories is Ownable {
    mapping(address => bool) factories; // factories

    modifier onlyFactory() {
        require(factories[msg.sender], "only for factories");
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

import "contracts/position_trading/assets/IAsset.sol";

/// @dev данные порождаемого фабрикой контракта
struct ContractData {
    address factory; // фабрика
    address contractAddr; // контракт
}

interface IPositionAlgorithm{
    /// @dev если истина, то алгоритм позволяет редактировать позицию
    function allowEditPosition(uint256 positionId) external view returns(bool);
    function beforeAssetTransfer(uint256 positionId, address asset, address from, address to, uint256 amount) external;
    function afterAssetTransfer(uint256 positionId, address asset, address from, address to, uint256 amount) external;
}

import "contracts/position_trading/ContractData.sol";

interface IPositionsController {
    /// @dev возвращает владельца позиции
    function ownerOf(uint256 positionId) external view returns (address);

    /// @dev возвращает актив владельца позиции
    function ownerAsset(uint256 positionId)
        external view
        returns (ContractData memory);

    /// @dev возвращает актив владельца позиции
    function outputAsset(uint256 positionId)
        external view
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
    function getAlgorithm(uint256 positionId) external view returns(ContractData memory data);

    /// @dev запрещает редактировать позицию
    function disableEdit(uint256 positionId) external;
}

interface IAsset{
    /// @dev обслуживающий алгоритм
    function algorithm() external view returns(address);
    /// @dev количество ассета
    function count() external view returns(uint256);
    /// @dev вывод определенного количества ассета на определенный адрес
    function withdraw(address recipient, uint256 amount) external;
}