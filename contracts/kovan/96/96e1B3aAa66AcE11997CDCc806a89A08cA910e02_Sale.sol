import 'contracts/position_trading/algorithms/PositionLockerAlgorithm.sol';
import 'contracts/interfaces/position_trading/IPositionsController.sol';
import 'contracts/interfaces/assets/IAsset.sol';
import 'contracts/position_trading/algorithms/PositionLockerBase.sol';

/// @dev производит простую распродажу ассета владельца за выходной ассет
contract Sale is PositionLockerBase {
    mapping(uint256 => uint256) public prices;

    event Sell(
        uint256 indexed positionId,
        address indexed buyer,
        uint256 count
    );

    constructor(address positionsControllerAddress)
        PositionLockerBase(positionsControllerAddress)
    {}

    function outputAssetLocked(uint256 positionId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return false;
    }

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

    function setPrice(uint256 positionId, uint256 price)
        external
        onlyPositionOwner(positionId)
        positionUnlocked(positionId)
    {
        prices[positionId] = price;
    }

    function _afterAssetTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256[] memory data
    ) internal virtual override {
        uint256 positionId = positionsController.getAssetPositionId(asset);
        address ownerAssetAddr = positionsController
            .ownerAsset(positionId)
            .contractAddr;
        address outputAssetAddr = positionsController
            .outputAsset(positionId)
            .contractAddr;
        // переводы с ассетов не обрабатываются
        if (from == ownerAssetAddr || from == outputAssetAddr) return;
        // перевод на овнерский ассет не обрабатывавется (пополнение)
        if (to == ownerAssetAddr) return;

        require(
            _positionLocked(positionId),
            'sale can be maked only if position editing is locked'
        );

        uint256 price = prices[positionId];
        require(
            price > 0,
            'the price is zero - owner of position must set price first'
        );
        IAsset ownerAsset = IAsset(ownerAssetAddr);
        IAsset outputAsset = IAsset(outputAssetAddr);
        require(
            to == address(outputAsset),
            'sale algorithm expects buyer transfer output asset'
        );
        require(amount >= price, 'not enough amount to buy - see price');

        uint256 buyCount = amount / price;
        require(
            buyCount <= ownerAsset.count(),
            'not enough owner asset to buy'
        );

        ownerAsset.withdraw(from, buyCount);
        emit Sell(positionId, from, buyCount);
    }
}

import './PositionAlgorithm.sol';
import 'contracts/interfaces/position_trading/IPositionsController.sol';
import 'contracts/interfaces/assets/IAsset.sol';
import './PositionLockerBase.sol';

/// @dev лочит ассет владельца позиции на определенное время
contract PositionLockerAlgorithm is PositionLockerBase {
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

/// @dev абстракция ассета
/// владелец ассета всегда алгоритм-наблюдатель ассета
interface IAsset is IOwnable {
    /// @dev количество ассета
    function count() external view returns (uint256);

    /// @dev вывод определенного количества ассета на определенный адрес
    function withdraw(address recipient, uint256 amount) external;

    /// @dev создает копию текущего ассета, с 0 балансом и указанным овнером
    function clone(address owner) external returns (IAsset);

    /// @dev возвращает код типа ассета (также используется для проверки потдержки интерфейса ассета)
    function assetTypeId() external returns (uint256);

    /// @dev если истина, то оповещает своего наблюдателя (овнера)
    function isNotifyListener() external returns (bool);

    /// @dev включает или отключает механизм оповещения наблюдателя
    function setNotifyListener(bool value) external;
}

import './PositionAlgorithm.sol';
import 'contracts/interfaces/position_trading/IPositionsController.sol';
import 'contracts/interfaces/assets/IAsset.sol';

/// @dev лочит ассет владельца позиции на определенное время
contract PositionLockerBase is PositionAlgorithm {
    mapping(uint256 => uint256) public unlockTimes; // время разлока по позициям

    modifier positionUnlocked(uint256 positionId) {
        require(!_positionLocked(positionId), 'the position need to be unlocked');
        _;
    }

    modifier positionLocked(uint256 positionId) {
        require(_positionLocked(positionId), 'the position need to be locked');
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

    function _positionLocked(uint256 positionId) internal virtual view returns (bool) {
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

    function _withdrawOwnerAsset(
        uint256 positionId,
        address recipient,
        uint256 amount
    ) internal override positionUnlocked(positionId) {
        super._withdrawOwnerAsset(positionId, recipient, amount);
    }

    function _withdrawOutputAsset(
        uint256 positionId,
        address recipient,
        uint256 amount
    ) internal override positionUnlocked(positionId) {
        super._withdrawOutputAsset(positionId, recipient, amount);
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

import 'contracts/interfaces/assets/IAsset.sol';
import 'contracts/interfaces/position_trading/IPositionAlgorithm.sol';
import 'contracts/interfaces/position_trading/IPositionsController.sol';
import 'contracts/position_trading/PositionSnapshot.sol';

/// @dev базовый алгоритм позиции
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
    ) external override {
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
    ) external override {
        _afterAssetTransfer(asset, from, to, amount, data);
    }

    function _afterAssetTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256[] memory data
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
        address asset = positionsController.ownerAsset(positionId).contractAddr;
        require(asset != address(0), 'nas no owner asset');
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
        require(asset != address(0), 'nas no output asset');
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

import 'contracts/interfaces/assets/IAssetListener.sol';

interface IPositionAlgorithm is IAssetListener {
    /// @dev если истина, то алгоритм блокирует редактирование позиции
    function isPositionLocked(uint256 positionId) external view returns (bool);
    /// @dev передаtn право владения ассетом указанному адресу
    function transferAssetOwnerShipTo(address asset, address newOwner) external;
}

// todo вырезать
struct PositionSnapshot {
    uint256 owner;
    uint256 output;
    uint256 slippage;
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

/// @dev данные порождаемого фабрикой контракта
struct ContractData {
    address factory; // фабрика
    address contractAddr; // контракт
}