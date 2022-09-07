import 'contracts/position_trading/algorithms/PositionLockerAlgorithm.sol';
import 'contracts/interfaces/position_trading/IPositionsController.sol';
import 'contracts/position_trading/PositionSnapshot.sol';
import 'contracts/lib/erc20/Erc20ForFactory.sol';
import 'contracts/interfaces/assets/IAsset.sol';
import 'contracts/position_trading/FeeDistributer.sol';
import 'contracts/interfaces/IFeeDistributer.sol';
import 'contracts/position_trading/algorithms/PositionLockerBase.sol';

struct AssetFee {
    uint256 input; // налог на вход в позицию 1/10000
    uint256 output; // налог на выход из позиции 1/10000
}

struct FeeSettings {
    AssetFee ownerAsset;
    AssetFee outputAsset;
}

struct SwapData {
    uint256 inputlastCount;
    uint256 buyCount;
    uint256 lastPrice;
    uint256 newPrice;
    uint256 snapPrice;
    uint256 outFee;
    uint256 priceImpact;
    uint256 slippage;
}

struct SwapSnapshot {
    uint256 input;
    uint256 output;
    uint256 slippage;
}

struct PositionAddingAssets {
    IAsset ownerAsset;
    IAsset outputAsset;
}

contract TradingPair is PositionLockerBase {
    mapping(uint256 => FeeSettings) public fee;
    mapping(uint256 => address) public liquidityTokens;
    mapping(uint256 => address) public feeTokens;
    mapping(uint256 => address) public feeDistributers;
    mapping(uint256 => mapping(address => PositionAddingAssets)) _liquidityAddingAssets;

    event Swap(
        uint256 indexed positionId,
        address indexed account,
        address indexed inputAsset,
        address outputAsset,
        uint256 inputCount,
        uint256 outputCount
    );

    constructor(address positionsControllerAddress)
        PositionLockerBase(positionsControllerAddress)
    {}

    function setAlgorithm(uint256 positionId, FeeSettings calldata feeSettings)
        external
    {
        _setAlgorithm(positionId, feeSettings);
    }

    function _setAlgorithm(uint256 positionId, FeeSettings calldata feeSettings)
        internal
        virtual
        onlyPositionOwner(positionId)
        positionUnlocked(positionId)
    {
        // задаем алгоритм
        ContractData memory data;
        data.factory = address(0);
        data.contractAddr = address(this);
        positionsController.setAlgorithm(positionId, data);

        // задаем настройки налогов
        fee[positionId] = feeSettings;

        Erc20ForFactory liquidityToken = new Erc20ForFactory(
            'liquidity',
            'LIQ',
            0
        );
        Erc20ForFactory feeToken = new Erc20ForFactory('fee', 'FEE', 0);
        liquidityTokens[positionId] = address(liquidityToken);
        feeTokens[positionId] = address(feeToken);
        (IAsset own, IAsset out) = _getAssets(positionId);
        liquidityToken.mintTo(msg.sender, own.count() * out.count());
        feeToken.mintTo(msg.sender, own.count() * out.count());
        // создаем ассеты для налогов
        IAsset feeOwnerAsset = IAsset(
            positionsController.getAsset(positionId, 1).contractAddr
        ).clone(address(this));
        IAsset feeOutputAsset = IAsset(
            positionsController.getAsset(positionId, 2).contractAddr
        ).clone(address(this));
        // создаем распределитель налогов
        FeeDistributer feeDistributer = new FeeDistributer(
            address(this),
            address(feeToken),
            address(feeOwnerAsset),
            address(feeOutputAsset)
        );
        feeDistributers[positionId] = address(feeDistributer);
        // передаем овнера на распределитель налогов
        feeOwnerAsset.transferOwnership(address(feeDistributer));
        feeOutputAsset.transferOwnership(address(feeDistributer));
    }

    function _positionLocked(uint256 positionId)
        internal
        view
        override
        returns (bool)
    {
        return address(liquidityTokens[positionId]) != address(0); // лок позиции автоматом, после добавления алгоритма
    }

    function createAddLiquidityAssets(uint256 positionId) external {
        // позиция должна быть создана
        require(
            liquidityTokens[positionId] != address(0),
            'position id is not exists'
        );
        // повторное создание не допускается
        require(
            address(
                _liquidityAddingAssets[positionId][msg.sender].ownerAsset
            ) == address(0),
            'assets for adding liquidity is already exists'
        );
        // получаем ассеты позиции, чтобы их клонировать
        IAsset ownerAsset = IAsset(
            positionsController.getAsset(positionId, 1).contractAddr
        );
        IAsset outputAsset = IAsset(
            positionsController.getAsset(positionId, 2).contractAddr
        );
        // создаем ассеты пополнения ликвидности
        _liquidityAddingAssets[positionId][msg.sender].ownerAsset = ownerAsset
            .clone(address(this));
        _liquidityAddingAssets[positionId][msg.sender].outputAsset = outputAsset
            .clone(address(this));

        _liquidityAddingAssets[positionId][msg.sender]
            .ownerAsset
            .setNotifyListener(false);
        _liquidityAddingAssets[positionId][msg.sender]
            .outputAsset
            .setNotifyListener(false);
    }

    function liquidityAddingAssets(uint256 positionId, address owner)
        external
        view
        returns (PositionAddingAssets memory)
    {
        return _liquidityAddingAssets[positionId][owner];
    }

    function addLiquidityByOwnerAsset(uint256 positionId)
        external
        positionLocked(positionId)
    {
        // позиция должна быть создана
        require(
            liquidityTokens[positionId] != address(0),
            'position id is not exists'
        );
        // ассеты пополнения должны существовать
        PositionAddingAssets memory assets = _liquidityAddingAssets[positionId][
            msg.sender
        ];
        require(
            address(assets.ownerAsset) != address(0) &&
                address(assets.outputAsset) != address(0),
            'assets for adding liquidity is not exists'
        );
        // берем ассеты позиции
        IAsset ownerAsset = IAsset(
            positionsController.getAsset(positionId, 1).contractAddr
        );
        IAsset outputAsset = IAsset(
            positionsController.getAsset(positionId, 2).contractAddr
        );
        // расчет нужного количества выходного ассета пополнения
        uint256 outputCount = (assets.ownerAsset.count() *
            outputAsset.count()) / ownerAsset.count();
        require(
            assets.outputAsset.count() >= outputCount,
            'not enough output adding asset count'
        );
        // минтим токены ликвидности
        uint256 liquidityTokensToMint = assets.ownerAsset.count() * outputCount;
        Erc20ForFactory(liquidityTokens[positionId]).mintTo(
            msg.sender,
            liquidityTokensToMint
        );
        // переводим с ассетов пополнения
        assets.ownerAsset.withdraw(
            address(ownerAsset),
            assets.ownerAsset.count()
        );
        assets.outputAsset.withdraw(address(outputAsset), outputCount);
    }

    function withdrawOwnerAddingLiquidityAsset(uint256 positionId) external {
        // позиция должна быть создана
        require(
            liquidityTokens[positionId] != address(0),
            'position id is not exists'
        );
        // ассеты пополнения должны существовать
        PositionAddingAssets memory assets = _liquidityAddingAssets[positionId][
            msg.sender
        ];
        require(
            address(assets.ownerAsset) != address(0),
            'asset for adding liquidity is not exists'
        );
        assets.ownerAsset.withdraw(msg.sender, assets.ownerAsset.count());
    }

    function withdrawOutputAddingLiquidityAsset(uint256 positionId) external {
        // позиция должна быть создана
        require(
            liquidityTokens[positionId] != address(0),
            'position id is not exists'
        );
        // ассеты пополнения должны существовать
        PositionAddingAssets memory assets = _liquidityAddingAssets[positionId][
            msg.sender
        ];
        require(
            address(assets.outputAsset) != address(0),
            'asset for adding liquidity is not exists'
        );
        assets.outputAsset.withdraw(msg.sender, assets.outputAsset.count());
    }

    function _getAssetsAddresses(uint256 positionId)
        internal
        view
        returns (address ownerAsset, address outputAsset)
    {
        address ownerAssetAddr = positionsController
            .getAsset(positionId, 1)
            .contractAddr;
        address outputAssetAddr = positionsController
            .getAsset(positionId, 2)
            .contractAddr;

        return (ownerAssetAddr, outputAssetAddr);
    }

    function _getAssets(uint256 positionId)
        internal
        view
        returns (IAsset ownerAsset, IAsset outputAsset)
    {
        (address ownerAssetAddr, address outputAssetAddr) = _getAssetsAddresses(
            positionId
        );
        require(ownerAssetAddr != address(0), 'owner asset required');
        require(outputAssetAddr != address(0), 'output asset required');

        return (IAsset(ownerAssetAddr), IAsset(outputAssetAddr));
    }

    function getOwnerAssetPrice(uint256 positionId)
        external
        view
        returns (uint256)
    {
        return _getOwnerAssetPrice(positionId);
    }

    function _getOwnerAssetPrice(uint256 positionId)
        internal
        view
        returns (uint256)
    {
        (IAsset ownerAsset, IAsset outputAsset) = _getAssets(positionId);
        uint256 ownerCount = ownerAsset.count();
        uint256 outputCount = outputAsset.count();
        require(outputCount > 0, 'has no output count');
        return ownerCount / outputCount;
    }

    function getOutputAssetPrice(uint256 positionId)
        external
        view
        returns (uint256)
    {
        return _getOutputAssetPrice(positionId);
    }

    function _getOutputAssetPrice(uint256 positionId)
        internal
        view
        returns (uint256)
    {
        (IAsset ownerAsset, IAsset outputAsset) = _getAssets(positionId);
        uint256 ownerCount = ownerAsset.count();
        uint256 outputCount = outputAsset.count();
        require(outputCount > 0, 'has no output count');
        return outputCount / ownerCount;
    }

    function _afterAssetTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256[] memory data
    ) internal virtual override {
        uint256 positionId = positionsController.getAssetPositionId(asset);
        (address ownerAssetAddr, address outputAssetAddr) = _getAssetsAddresses(
            positionId
        );
        // переводы с ассетов не обрабатываются
        if (from == ownerAssetAddr || from == outputAssetAddr) return;
        // свап только если заблокировано редактирование
        require(
            _positionLocked(positionId),
            'swap can be maked only if position editing is locked'
        );
        // если снапшота нет то ничего не едлаем
        require(
            data.length == 3,
            'data must be snapshot, where [owner asset, output asset, slippage]'
        );

        // берем налоги
        FeeSettings memory feeSettings = fee[positionId];
        // производим свап
        if (to == outputAssetAddr)
            // если обмен прямой
            _swap(
                positionId,
                from,
                amount,
                IAsset(outputAssetAddr),
                IAsset(ownerAssetAddr),
                feeSettings.outputAsset,
                feeSettings.ownerAsset,
                SwapSnapshot(data[1], data[0], data[2]),
                IFeeDistributer(feeDistributers[positionId]).outputAsset(),
                IFeeDistributer(feeDistributers[positionId]).ownerAsset()
            );
        else
            _swap(
                positionId,
                from,
                amount,
                IAsset(ownerAssetAddr),
                IAsset(outputAssetAddr),
                feeSettings.ownerAsset,
                feeSettings.outputAsset,
                SwapSnapshot(data[0], data[1], data[2]),
                IFeeDistributer(feeDistributers[positionId]).ownerAsset(),
                IFeeDistributer(feeDistributers[positionId]).outputAsset()
            );
    }

    function _swap(
        uint256 positionId,
        address from,
        uint256 amount,
        IAsset input,
        IAsset output,
        AssetFee memory inputFee,
        AssetFee memory outputFee,
        SwapSnapshot memory snapshot,
        IAsset inputFeeAsset,
        IAsset outputFeeAsset
    ) internal {
        SwapData memory data;
        // определяем сколько куплено
        data.inputlastCount = input.count() - amount;
        data.buyCount = (amount * output.count()) / data.inputlastCount;
        require(data.buyCount <= output.count(), 'not enough asset to buy');

        // определяем старую цену
        data.lastPrice = (data.inputlastCount * 100000) / output.count();
        // определяем цену снапшота
        data.snapPrice = (snapshot.input * 100000) / snapshot.output;
        // ограничитель проскальзывания
        if (data.lastPrice >= snapshot.slippage)
            data.slippage = (data.lastPrice * 100000) / data.snapPrice;
        else data.slippage = (data.snapPrice * 100000) / data.lastPrice;
        require(
            data.slippage <= snapshot.slippage,
            'price has changed by more than slippage'
        );

        // расчет налога
        if (inputFee.input > 0) {
            input.withdraw(
                address(inputFeeAsset),
                (inputFee.input * amount) / 10000
            );
        }
        if (outputFee.output > 0) {
            data.outFee = (outputFee.output * data.buyCount) / 10000;
            data.buyCount -= data.outFee;
            output.withdraw(address(outputFeeAsset), data.outFee);
        }

        // передаем ассет
        output.withdraw(from, data.buyCount);

        // определяем старую цену
        data.newPrice = (input.count() * 100000) / output.count();

        // цена не должна уходить больше чем на 50%
        data.priceImpact = (data.newPrice * 100000) / data.lastPrice;
        require(data.priceImpact < 150000, 'too large price impact');

        // эвент
        emit Swap(
            positionId,
            from,
            address(input),
            address(output),
            amount,
            data.buyCount
        );
    }

    function withdraw(uint256 positionId, uint256 liquidityCount) external {
        // берем токен
        address liquidityAddr = liquidityTokens[positionId];
        require(
            liquidityAddr != address(0),
            'algorithm has no liquidity tokens'
        );
        // берем ассеты
        (IAsset own, IAsset out) = _getAssets(positionId);
        // вывод овнерского ассета
        own.withdraw(
            msg.sender,
            (own.count() * liquidityCount) /
                Erc20ForFactory(liquidityAddr).totalSupply()
        );
        // вывод выходного ассета
        out.withdraw(
            msg.sender,
            (out.count() * liquidityCount) /
                Erc20ForFactory(liquidityAddr).totalSupply()
        );

        // жжем токен ликвидности
        Erc20ForFactory(liquidityAddr).burn(msg.sender, liquidityCount);
    }
}

import './PositionAlgorithm.sol';
import 'contracts/interfaces/position_trading/IPositionsController.sol';
import 'contracts/interfaces/assets/IAsset.sol';
import './PositionLockerBase.sol';
import 'contracts/interfaces/position_trading/algorithms/IPositionLockerAlgorithmInstaller.sol';

/// @dev лочит ассет владельца позиции на определенное время
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

import 'contracts/lib/factories/ContractData.sol';

interface IPositionsController {
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

// todo вырезать
struct PositionSnapshot {
    uint256 owner;
    uint256 output;
    uint256 slippage;
}

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract Erc20ForFactory is ERC20 {
    uint8 _decimals;
    address public factory;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) ERC20(name_, symbol_) {
        _decimals = decimals_;
        factory = msg.sender;
    }

    modifier onlyFactory() {
        require(msg.sender == factory, 'only for factory');
        _;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function mint(uint256 count) external onlyFactory {
        _mint(msg.sender, count);
    }

    function mintTo(address account, uint256 count) external onlyFactory {
        _mint(account, count);
    }

    function burn(address account, uint256 count) external onlyFactory {
        _burn(account, count);
    }
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

import 'contracts/lib/ownable/OwnableSimple.sol';
import 'contracts/interfaces/assets/IAsset.sol';
import 'contracts/position_trading/assets/AssetListenerBase.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import 'contracts/interfaces/IFeeDistributer.sol';

contract FeeDistributer is OwnableSimple, AssetListenerBase, IFeeDistributer {
    // fee token
    IERC20 public feeToken;
    // fee token user locks
    mapping(address => uint256) public feeTokenLocks;
    mapping(address => uint256) public claimRounds;
    uint256 public totalFeetokensLocked;
    // fee round
    uint256 public feeRoundNumber;
    uint256 public constant feeRoundInterval = 1 days;
    uint256 public nextFeeRoundTime;
    // assets
    IAsset _ownerAsset;
    IAsset _outputAsset;
    // distribution snapshot
    uint256 public distributeRoundTotalFeeTokensLock;
    uint256 public ownerAssetToDistribute;
    uint256 public outputAssetToDistribute;
    // statistics
    uint256 public ownerAssetDistributedTotal;
    uint256 public outputAssetDistributedTotal;
    // events
    event OnLock(address indexed account, uint256 amount);
    event OnUnlock(address indexed account, uint256 amount);

    constructor(
        address owner_,
        address feeTokenAddress_,
        address ownerAsset_,
        address outputAsset_
    ) OwnableSimple(owner_) {
        feeToken = IERC20(feeTokenAddress_);
        _ownerAsset = IAsset(ownerAsset_);
        _outputAsset = IAsset(outputAsset_);
        nextFeeRoundTime = block.timestamp + feeRoundInterval;
    }

    function lockFeeTokens(uint256 amount) external {
        _claimRewards(msg.sender);
        tryNextFeeRound();
        feeToken.transferFrom(msg.sender, address(this), amount);
        feeTokenLocks[msg.sender] = amount;
        totalFeetokensLocked += amount;
        emit OnLock(msg.sender, amount);
    }

    function unlockFeeTokens(uint256 amount) external {
        _claimRewards(msg.sender);
        tryNextFeeRound();
        require(feeTokenLocks[msg.sender] >= amount, 'not enough fee tokens');
        feeTokenLocks[msg.sender] -= amount;
        totalFeetokensLocked -= amount;
        emit OnUnlock(msg.sender, amount);
    }

    function tryNextFeeRound() public {
        //console.log('nextFeeRoundTime-block.timestamp', nextFeeRoundTime-block.timestamp);
        if (block.timestamp < nextFeeRoundTime) return;
        ++feeRoundNumber;
        nextFeeRoundTime = block.timestamp + feeRoundInterval;
        // snapshot for distribute
        distributeRoundTotalFeeTokensLock = totalFeetokensLocked;
        ownerAssetToDistribute = _ownerAsset.count();
        outputAssetToDistribute = _outputAsset.count();
    }

    function claimRewards() external {
        require(feeRoundNumber > 0, 'nothing to claim');
        require(claimRounds[msg.sender] < feeRoundNumber, 'reward claimed yet');
        _claimRewards(msg.sender);
        tryNextFeeRound();
    }

    function _claimRewards(address account) internal {
        if (claimRounds[account] >= feeRoundNumber) return;
        claimRounds[account] = feeRoundNumber;
        uint256 ownerCount = (ownerAssetToDistribute * feeTokenLocks[account]) /
            distributeRoundTotalFeeTokensLock;
        uint256 outputCount = (outputAssetToDistribute *
            feeTokenLocks[account]) / distributeRoundTotalFeeTokensLock;
        ownerAssetDistributedTotal += ownerCount;
        outputAssetDistributedTotal += outputCount;
        if (ownerCount > 0) _ownerAsset.withdraw(account, ownerCount);
        if (outputCount > 0) _outputAsset.withdraw(account, outputCount);
    }

    function nextFeeRoundLapsedMinutes() external view returns (uint256) {
        if (block.timestamp >= nextFeeRoundTime) return 0;
        return (nextFeeRoundTime - block.timestamp) / (1 minutes);
    }

    function ownerAsset() external view override returns (IAsset) {
        return _ownerAsset;
    }

    function outputAsset() external view override returns (IAsset) {
        return _outputAsset;
    }
}

import 'contracts/interfaces/assets/IAsset.sol';

interface IFeeDistributer {
    function ownerAsset() external returns (IAsset);

    function outputAsset() external returns (IAsset);
}

import './PositionAlgorithm.sol';
import 'contracts/interfaces/position_trading/IPositionsController.sol';
import 'contracts/interfaces/assets/IAsset.sol';

/// @dev лочит ассет владельца позиции на определенное время
contract PositionLockerBase is PositionAlgorithm {
    mapping(uint256 => uint256) public unlockTimes; // время разлока по позициям

    modifier positionUnlocked(uint256 positionId) {
        require(!_positionLocked(positionId), 'for unlocked positions only');
        _;
    }

    modifier positionLocked(uint256 positionId) {
        require(_positionLocked(positionId), 'for locked positions only');
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
    ) internal override positionUnlocked(positionId) {
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

interface IPositionLockerAlgorithmInstaller {
    /// @dev задает алгоритм лока позиции
    function setAlgorithm(uint256 positionId) external;
}

import 'contracts/interfaces/assets/IAssetListener.sol';

interface IPositionAlgorithm is IAssetListener {
    /// @dev если истина, то алгоритм блокирует редактирование позиции
    function isPositionLocked(uint256 positionId) external view returns (bool);

    /// @dev передаtn право владения ассетом указанному адресу
    function transferAssetOwnerShipTo(address asset, address newOwner) external;
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

/// @dev данные порождаемого фабрикой контракта
struct ContractData {
    address factory; // фабрика
    address contractAddr; // контракт
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

import 'contracts/interfaces/assets/IAssetListener.sol';

/// @dev base contract for IAssetListener interface
contract AssetListenerBase is IAssetListener {
    function beforeAssetTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256[] memory data
    ) external virtual override {}

    function afterAssetTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256[] memory data
    ) external virtual override {}
}