pragma solidity ^0.8.17;
import './Erc20Asset.sol';
import 'contracts/lib/factories/ContractData.sol';
import 'contracts/interfaces/position_trading/IPositionsController.sol';
import 'contracts/position_trading/assets/AssetFactoryBase.sol';
import 'contracts/interfaces/assets/typed/IErc20Asset.sol';
import 'contracts/interfaces/assets/typed/IErc20AssetFactory.sol';

contract Erc20AssetFactory is AssetFactoryBase, IErc20AssetFactory {
    constructor(address positionsController_)
        AssetFactoryBase(positionsController_)
    {}

    function setAsset(
        uint256 positionId,
        uint256 assetCode,
        address contractAddress
    ) external {
        _setAsset(positionId, assetCode, createAsset(contractAddress));
    }

    function createAsset(address contractAddress)
        internal
        returns (ContractData memory)
    {
        ContractData memory data;
        data.factory = address(this);
        data.contractAddr = address(
            new Erc20Asset(address(positionsController), this, contractAddress)
        );
        return data;
    }

    function _clone(address asset, address owner)
        internal
        override
        returns (IAsset)
    {
        return
            new Erc20Asset(
                owner,
                this,
                IErc20Asset(asset).getContractAddress()
            );
    }
}

pragma solidity ^0.8.17;
import 'contracts/position_trading/assets/AssetBase.sol';
import 'contracts/position_trading/PositionSnapshot.sol';
import 'contracts/interfaces/position_trading/IPositionAlgorithm.sol';
import 'contracts/interfaces/assets/typed/IErc20Asset.sol';

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract Erc20Asset is AssetBase, IErc20Asset {
    address contractAddress;

    constructor(
        address owner_,
        IAssetCloneFactory factory_,
        address contractAddress_
    ) AssetBase(owner_, factory_) {
        contractAddress = contractAddress_;
    }

    function count() external view override returns (uint256) {
        return IERC20(contractAddress).balanceOf(address(this));
    }

    function getContractAddress() external view override returns (address) {
        return contractAddress;
    }

    function withdrawInternal(address recipient, uint256 amount)
        internal
        virtual
        override
    {
        IERC20(contractAddress).transfer(recipient, amount);
    }

    function transferToAsset(
        uint256 amount,
        uint256[] calldata data
    ) external {
        listener().beforeAssetTransfer(
            address(this),
            msg.sender,
            address(this),
            amount,
            data
        );
        IERC20(contractAddress).transferFrom(msg.sender, address(this), amount);
        listener().afterAssetTransfer(
            address(this),
            msg.sender,
            address(this),
            amount,
            data
        );
    }

    function clone(address owner) external override returns (IAsset) {
        return factory.clone(address(this), owner);
    }

    function assetTypeId() external pure override returns (uint256) {
        return 2;
    }
}

pragma solidity ^0.8.17;
/// @dev данные порождаемого фабрикой контракта
struct ContractData {
    address factory; // фабрика
    address contractAddr; // контракт
}

pragma solidity ^0.8.17;
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

pragma solidity ^0.8.17;
import 'contracts/lib/factories/ContractData.sol';
import 'contracts/interfaces/position_trading/IPositionsController.sol';
import 'contracts/interfaces/assets/IAssetCloneFactory.sol';

abstract contract AssetFactoryBase is IAssetCloneFactory {
    IPositionsController public positionsController;

    constructor(address positionsController_) {
        positionsController = IPositionsController(positionsController_);
    }

    modifier onlyPositionOwner(uint256 positionId) {
        require(positionsController.ownerOf(positionId) == msg.sender);
        _;
    }

    function _setAsset(
        uint256 positionId,
        uint256 assetCode,
        ContractData memory contractData
    ) internal onlyPositionOwner(positionId) {
        positionsController.setAsset(positionId, assetCode, contractData);
    }

    function clone(address asset, address owner)
        external
        override
        returns (IAsset)
    {
        require(msg.sender == asset, 'only for assets');
        return _clone(asset, owner);
    }

    function _clone(address asset, address owner)
        internal
        virtual
        returns (IAsset);
}

pragma solidity ^0.8.17;
interface IErc20Asset {
    function getContractAddress() external returns (address);
}

pragma solidity ^0.8.17;
interface IErc20AssetFactory {
    function setAsset(
        uint256 positionId,
        uint256 assetCode,
        address contractAddress
    ) external;
}

pragma solidity ^0.8.17;
import 'contracts/interfaces/assets/IAsset.sol';
import 'contracts/interfaces/assets/IAssetListener.sol';
import 'contracts/lib/ownable/OwnableSimple.sol';
import 'contracts/interfaces/assets/IAssetCloneFactory.sol';

/// @dev ассет всегда имеет овнером алгоритм, листенер событий ассета
abstract contract AssetBase is IAsset, OwnableSimple {
    IAssetCloneFactory public factory;
    bool internal _isNotifyListener;

    constructor(address owner_, IAssetCloneFactory factory_)
        OwnableSimple(owner_)
    {
        _owner = address(owner_);
        factory = factory_;
    }

    function listener() internal view returns (IAssetListener) {
        return IAssetListener(_owner);
    }

    function withdraw(address recipient, uint256 amount)
        external
        virtual
        override
        onlyOwner
    {
        uint256[] memory data;
        if (_isNotifyListener)
            listener().beforeAssetTransfer(
                address(this),
                address(this),
                recipient,
                amount,
                data
            );
        withdrawInternal(recipient, amount);
        if (_isNotifyListener)
            listener().afterAssetTransfer(
                address(this),
                address(this),
                recipient,
                amount,
                data
            );
    }

    function withdrawInternal(address recipient, uint256 amount)
        internal
        virtual;

    function isNotifyListener() external view returns (bool) {
        return _isNotifyListener;
    }

    function setNotifyListener(bool value) external onlyOwner {
        _isNotifyListener = value;
    }
}

pragma solidity ^0.8.17;
// todo вырезать
struct PositionSnapshot {
    uint256 owner;
    uint256 output;
    uint256 slippage;
}

pragma solidity ^0.8.17;
import 'contracts/interfaces/assets/IAssetListener.sol';

interface IPositionAlgorithm is IAssetListener {
    /// @dev если истина, то алгоритм блокирует редактирование позиции
    function isPositionLocked(uint256 positionId) external view returns (bool);

    /// @dev передаtn право владения ассетом указанному адресу
    function transferAssetOwnerShipTo(address asset, address newOwner) external;
}

pragma solidity ^0.8.17;
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
import 'contracts/interfaces/IOwnable.sol';

/// @dev овнабл, оптимизированый, для динамически порождаемых контрактов
contract OwnableSimple is IOwnable {
    address internal _owner;

    constructor(address owner_) {
        _owner = owner_;
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
import 'contracts/interfaces/assets/IAsset.sol';

interface IAssetCloneFactory {
    /// @dev делает копию ассета (количество ассета будет 0)
    function clone(address asset, address owner) external returns (IAsset);
}

pragma solidity ^0.8.17;
interface IOwnable {
    function owner() external returns (address);

    function transferOwnership(address newOwner) external;
}

pragma solidity ^0.8.17;
interface IFeeSettings {
    function feeAddress() external returns (address); // address to pay fee

    function feePercent() external returns (uint256); // fee in 1/decimals for deviding values

    function feeDecimals() external view returns(uint256); // fee decimals

    function feeEth() external returns (uint256); // fee value for not dividing deal points
}