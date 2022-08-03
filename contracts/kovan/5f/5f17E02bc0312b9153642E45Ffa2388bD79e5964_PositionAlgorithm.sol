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

import "contracts/position_trading/assets/IAsset.sol";

/// @dev данные порождаемого фабрикой контракта
struct ContractData {
    address factory; // фабрика
    address contractAddr; // контракт
}