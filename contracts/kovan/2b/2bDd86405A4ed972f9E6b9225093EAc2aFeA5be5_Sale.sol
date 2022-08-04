import "contracts/position_trading/algorithms/OwnerAssetLock.sol";
import "contracts/position_trading/IPositionsController.sol";
import "contracts/position_trading/assets/IAsset.sol";

/// @dev производит простую распродажу ассета владельца за выходной ассет
contract Sale is OwnerAssetLock {
    mapping(uint256 => uint256) prices;

    event Sell(
        uint256 indexed positionId,
        address indexed buyer,
        uint256 count
    );

    constructor(address positionsControllerAddress)
        OwnerAssetLock(positionsControllerAddress)
    {}

    function setPrice(uint256 positionId, uint256 price)
        external
        onlyPositionOwner(positionId)
        ownerAssetUnlocked(positionId)
    {
        prices[positionId] = price;
    }

    function _afterAssetTransfer(
        uint256 positionId,
        address asset,
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        address ownerAssetAddr = positionsController
            .ownerAsset(positionId)
            .contractAddr;
        address outputAssetAddr = positionsController
            .outputAsset(positionId)
            .contractAddr;
        // если перевод переводы с ассетов не обрабатываются
        if (from == ownerAssetAddr || from == outputAssetAddr) return;
        // перевод на овнерский ассет не обрабатывавется (пополнение)
        if (to == ownerAssetAddr) return;

        require(
            !_allowEditPosition(positionId),
            "sale can be maked only if position editing is locked"
        );

        uint256 price = prices[positionId];
        require(
            price > 0,
            "the price is zero - owner of position must set price first"
        );
        IAsset ownerAsset = IAsset(ownerAssetAddr);
        IAsset outputAsset = IAsset(outputAssetAddr);
        require(
            to == address(outputAsset),
            "sale algorithm expects buyer transfer output asset"
        );
        require(amount >= price, "not enough amount to buy - see price");

        uint256 buyCount = amount / price;
        require(
            buyCount <= ownerAsset.count(),
            "not enough owner asset to buy"
        );

        ownerAsset.withdraw(from, buyCount);
        emit Sell(positionId, from, buyCount);
    }
}

import "contracts/position_trading/algorithms/PositionAlgorithm.sol";
import "contracts/position_trading/IPositionsController.sol";
import "contracts/position_trading/assets/IAsset.sol";

/// @dev лочит ассет владельца позиции на определенное время
contract OwnerAssetLock is PositionAlgorithm {
    mapping(uint256 => uint256) public unlockTimes; // время разлока по позициям

    modifier ownerAssetUnlocked(uint256 positionId) {
        require(_allowEditPosition(positionId), "the owner asset is locked");
        _;
    }

    modifier ownerAssetLocked(uint256 positionId) {
        require(!_allowEditPosition(positionId), "the owner asset is unlocked");
        _;
    }

    constructor(address positionsController)
        PositionAlgorithm(positionsController)
    {}

    function allowEditPosition(uint256 positionId)
        external
        view
        override
        returns (bool)
    {
        return _allowEditPosition(positionId);
    }

    function _allowEditPosition(uint256 positionId)
        internal
        view
        returns (bool)
    {
        return unlockTimes[positionId] <= block.timestamp;
    }

    function lockOwnerAsset(uint256 positionId, uint256 lockSeconds)
        external
        onlyPositionOwner(positionId)
        ownerAssetUnlocked(positionId)
    {
        unlockTimes[positionId] = block.timestamp + lockSeconds * 1 seconds;
    }

    function setAlgorithm(uint256 positionId)
        external
        onlyPositionOwner(positionId)
    {
        ContractData memory data;
        data.factory = address(0);
        data.contractAddr = address(this);
        positionsController.setAlgorithm(positionId, data);
    }

    function _beforeAssetTransfer(
        uint256 positionId,
        address asset,
        address from,
        address to,
        uint256 amount
    ) internal override {
        address ownerAsset = positionsController
            .ownerAsset(positionId)
            .contractAddr;
        if (asset != ownerAsset || from != ownerAsset) return;
    }

    function lapsedLockSeconds(uint256 positionId)
        external
        view
        returns (uint256)
    {
        if (_allowEditPosition(positionId)) return 0;
        return unlockTimes[positionId] - block.timestamp;
    }

    function _withdrawOwnerAsset(
        uint256 positionId,
        address recipient,
        uint256 amount
    ) internal override ownerAssetUnlocked(positionId) {
        super._withdrawOwnerAsset(positionId, recipient, amount);
    }
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

import "contracts/position_trading/algorithms/IPositionAlgorithm.sol";
import "contracts/position_trading/IPositionsController.sol";
import "contracts/position_trading/assets/IAsset.sol";

/// @dev базовый алгоритм позиции
contract PositionAlgorithm is IPositionAlgorithm {
    IPositionsController public positionsController;

    constructor(address positionsControllerAddress) {
        positionsController = IPositionsController(positionsControllerAddress);
    }

    modifier onlyPositionOwner(uint256 positionId) {
        require(
            positionsController.ownerOf(positionId) == msg.sender,
            "only for position owner"
        );
        _;
    }

    function allowEditPosition(uint256)
        external
        view
        virtual
        override
        returns (bool)
    {
        return true;
    }

    function beforeAssetTransfer(
        uint256 positionId,
        address asset,
        address from,
        address to,
        uint256 amount
    ) external override {
        _beforeAssetTransfer(positionId, asset, from, to, amount);
    }

    function _beforeAssetTransfer(
        uint256 positionId,
        address asset,
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function afterAssetTransfer(
        uint256 positionId,
        address asset,
        address from,
        address to,
        uint256 amount
    ) external override {
        _afterAssetTransfer(positionId, asset, from, to, amount);
    }

    function _afterAssetTransfer(
        uint256 positionId,
        address asset,
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function withdrawOwnerAsset(
        uint256 positionId,
        address recipient,
        uint256 amount
    ) external onlyPositionOwner(positionId) {
        _withdrawOwnerAsset(positionId, recipient, amount);
    }

    function _withdrawOwnerAsset(
        uint256 positionId,
        address recipient,
        uint256 amount
    ) internal virtual onlyPositionOwner(positionId) {
        address asset = positionsController
            .ownerAsset(positionId)
            .contractAddr;
        require(asset != address(0), "nas no owner asset");
        IAsset(asset).withdraw(recipient, amount);
    }

    function withdrawOutputAsset(
        uint256 positionId,
        address recipient,
        uint256 amount
    ) external onlyPositionOwner(positionId) {
        _withdrawOutputAsset(positionId, recipient, amount);
    }

    function _withdrawOutputAsset(
        uint256 positionId,
        address recipient,
        uint256 amount
    ) internal virtual onlyPositionOwner(positionId) {
        address asset = positionsController
            .outputAsset(positionId)
            .contractAddr;
        require(asset != address(0), "nas no output asset");
        IAsset(asset).withdraw(recipient, amount);
    }
}

interface IPositionAlgorithm{
    /// @dev если истина, то алгоритм позволяет редактировать позицию
    function allowEditPosition(uint256 positionId) external view returns(bool);
    function beforeAssetTransfer(uint256 positionId, address asset, address from, address to, uint256 amount) external;
    function afterAssetTransfer(uint256 positionId, address asset, address from, address to, uint256 amount) external;
}

import "contracts/position_trading/assets/IAsset.sol";

/// @dev данные порождаемого фабрикой контракта
struct ContractData {
    address factory; // фабрика
    address contractAddr; // контракт
}