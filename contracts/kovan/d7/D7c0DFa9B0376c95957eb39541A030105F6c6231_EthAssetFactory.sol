import "./EthAsset.sol";
import "contracts/position_trading/IPositionsController.sol";
import "contracts/position_trading/ContractData.sol";
import "contracts/position_trading/assets/AssetFactory.sol";

contract EthAssetFactory is AssetFactory {
    constructor(address positionsController_) AssetFactory(positionsController_) {}

    function setOwnerAsset(uint256 positionId) external {
        _setOwnerAsset(positionId, createAsset(positionId));
    }

    function setOutputAsset(uint256 positionId) external {
        _setOutputAsset(positionId, createAsset(positionId));
    }

    function createAsset(uint256 positionId)
        internal
        returns (ContractData memory)
    {
        ContractData memory data;
        data.factory = address(this);
        data.contractAddr = address(
            new EthAsset(address(positionsController), positionId)
        );
        return data;
    }
}

import "contracts/position_trading/assets/AssetBase.sol";

contract EthAsset is AssetBase {
    constructor(address positionsController, uint256 positionId)
        AssetBase(positionsController, positionId)
    {}

    function count() external view override returns (uint256) {
        return address(this).balance;
    }

    function withdrawInternal(address recipient, uint256 amount)
        internal
        virtual
        override
    {
        payable(recipient).transfer(amount);
    }

    receive() external payable {
        address alg = _algorithm();
        if (alg != address(0))
            IPositionAlgorithm(alg).beforeAssetTransfer(
                positionId,
                address(this),
                msg.sender,
                address(this),
                msg.value
            );
        if (alg != address(0))
            IPositionAlgorithm(alg).afterAssetTransfer(
                positionId,
                address(this),
                msg.sender,
                address(this),
                msg.value
            );
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

import "contracts/position_trading/assets/IAsset.sol";

/// @dev данные порождаемого фабрикой контракта
struct ContractData {
    address factory; // фабрика
    address contractAddr; // контракт
}

import "contracts/position_trading/ContractData.sol";
import "contracts/position_trading/IPositionsController.sol";
import "contracts/position_trading/ContractData.sol";

contract AssetFactory {
    IPositionsController public positionsController;

    modifier onlyPositionOwner(uint256 positionId) {
        require(positionsController.ownerOf(positionId) == msg.sender);
        _;
    }

    constructor(address positionsController_) {
        positionsController = IPositionsController(positionsController_);
    }

    function _setOwnerAsset(
        uint256 positionId,
        ContractData memory contractData
    ) internal onlyPositionOwner(positionId) {
        positionsController.setOwnerAsset(positionId, contractData);
    }

    function _setOutputAsset(
        uint256 positionId,
        ContractData memory contractData
    ) internal onlyPositionOwner(positionId) {
        positionsController.setOutputAsset(positionId, contractData);
    }
}

import "contracts/position_trading/assets/IAsset.sol";
import "contracts/position_trading/algorithms/IPositionAlgorithm.sol";
import "contracts/position_trading/IPositionsController.sol";

abstract contract AssetBase is IAsset {
    IPositionsController public positionsController;
    uint256 public positionId;

    constructor(address positionsController_, uint256 positionId_) {
        positionsController = IPositionsController(positionsController_);
        positionId = positionId_;
    }

    modifier onlyAlgorithm() {
        require(msg.sender == _algorithm(), 'algorithms only');
        _;
    }
    /*modifier onlyAlgorithmOrOwner() {
        require(
            msg.sender == this.algorithm() ||
                msg.sender == positionsController.ownerOf(positionId)
        );
        _;
    }*/

    function algorithm() external view override returns (address) {
        return address(_algorithm());
    }

    function _algorithm() internal view returns (address) {
        return positionsController.getAlgorithm(positionId).contractAddr;
    }

    function withdraw(address recipient, uint256 amount)
        external
        override
        onlyAlgorithm
    {
        address alg = _algorithm();
        if (alg != address(0))
            IPositionAlgorithm(alg).beforeAssetTransfer(
                positionId,
                address(this),
                address(this),
                recipient,
                amount
            );
        withdrawInternal(recipient, amount);
        if (alg != address(0))
            IPositionAlgorithm(alg).afterAssetTransfer(
                positionId,
                address(this),
                address(this),
                recipient,
                amount
            );
    }

    function withdrawInternal(address recipient, uint256 amount)
        internal
        virtual;
}

interface IAsset{
    /// @dev обслуживающий алгоритм
    function algorithm() external view returns(address);
    /// @dev количество ассета
    function count() external view returns(uint256);
    /// @dev вывод определенного количества ассета на определенный адрес
    function withdraw(address recipient, uint256 amount) external;
}

interface IPositionAlgorithm{
    /// @dev если истина, то алгоритм позволяет редактировать позицию
    function allowEditPosition(uint256 positionId) external view returns(bool);
    function beforeAssetTransfer(uint256 positionId, address asset, address from, address to, uint256 amount) external;
    function afterAssetTransfer(uint256 positionId, address asset, address from, address to, uint256 amount) external;
}