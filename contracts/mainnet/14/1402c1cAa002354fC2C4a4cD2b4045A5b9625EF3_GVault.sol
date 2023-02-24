// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

import {ERC20} from "ERC20.sol";
import {SafeTransferLib} from "SafeTransferLib.sol";
import {Math} from "Math.sol";
import {Ownable} from "Ownable.sol";
import {ReentrancyGuard} from "ReentrancyGuard.sol";
import {IStrategy} from "IStrategy.sol";
import {ERC4626} from "ERC4626.sol";
import {Constants} from "Constants.sol";
import {Errors} from "Errors.sol";
import {StrategyQueue} from "StrategyQueue.sol";

//  ________  ________  ________
//  |\   ____\|\   __  \|\   __  \
//  \ \  \___|\ \  \|\  \ \  \|\  \
//   \ \  \  __\ \   _  _\ \  \\\  \
//    \ \  \|\  \ \  \\  \\ \  \\\  \
//     \ \_______\ \__\\ _\\ \_______\
//      \|_______|\|__|\|__|\|_______|

// gro protocol: https://github.com/groLabs/GSquared

/// @notice GVault - Gro protocol stand alone vault for generating yield
/// @title GVault
/// @notice  Gro protocol stand alone vault for generating yield on
/// stablecoins following the EIP-4626 Standard
contract GVault is Constants, ERC4626, StrategyQueue, Ownable, ReentrancyGuard {
    using SafeTransferLib for ERC20;

    /*//////////////////////////////////////////////////////////////
                        CONSTANTS & IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    // Underlying token
    ERC20 public immutable override asset;
    uint256 public immutable minDeposit;

    /*//////////////////////////////////////////////////////////////
                    STORAGE VARIABLES & TYPES
    //////////////////////////////////////////////////////////////*/

    struct StrategyParams {
        bool active;
        uint256 debtRatio;
        uint256 lastReport;
        uint256 totalDebt;
        uint256 totalGain;
        uint256 totalLoss;
    }

    mapping(address => StrategyParams) public strategies;
    uint256 public vaultAssets;

    // Slow release of profit
    uint256 public lockedProfit;
    uint256 public releaseTime;

    uint256 public vaultDebtRatio;
    uint256 public vaultTotalDebt;
    uint256 public lastReport;

    // Vault fee
    address public feeCollector;
    uint256 public vaultFee;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    // Strategy events
    event LogStrategyHarvestReport(
        address indexed strategy,
        uint256 gain,
        uint256 loss,
        uint256 debtPaid,
        uint256 debtAdded,
        uint256 lockedProfit,
        uint256 lockedProfitBeforeLoss
    );

    event LogStrategyTotalChanges(
        address indexed strategy,
        uint256 totalGain,
        uint256 totalLoss,
        uint256 totalDebt
    );

    event LogWithdrawalFromStrategy(
        uint48 strategyId,
        uint256 strategyDebt,
        uint256 totalVaultDebt,
        uint256 lossFromStrategyWithdrawal
    );

    // Vault events
    event LogNewDebtRatio(
        address indexed strategy,
        uint256 debtRatio,
        uint256 vaultDebtRatio
    );

    event LogNewReleaseFactor(uint256 factor);
    event LogNewVaultFee(uint256 vaultFee);
    event LogNewfeeCollector(address feeCollector);

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(ERC20 _asset)
        ERC20(
            string(abi.encodePacked("Gro ", _asset.symbol(), " Vault")),
            string(abi.encodePacked("gro", _asset.symbol())),
            _asset.decimals()
        )
    {
        asset = _asset;
        minDeposit = 10**_asset.decimals();
        // 24 hours release window in seconds
        releaseTime = 86400;
    }

    /*//////////////////////////////////////////////////////////////
                            GETTERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Get number of strategies in underlying vault
    /// @return number of strategies in the withdrawal queue
    function getNoOfStrategies() external view returns (uint256) {
        return noOfStrategies();
    }

    /// @notice Helper function for strategy to get debt from vault
    function getStrategyDebt() external view returns (uint256) {
        return strategies[msg.sender].totalDebt;
    }

    /// @notice Get total invested in strategy
    /// @param _index index of strategy
    /// @return amount of total debt the strategies have to the GVault
    function getStrategyDebt(uint256 _index)
        external
        view
        returns (uint256 amount)
    {
        return strategies[nodes[_index].strategy].totalDebt;
    }

    /// @notice Helper function for strategy to get harvest data from vault
    function getStrategyData()
        external
        view
        returns (
            bool,
            uint256,
            uint256
        )
    {
        StrategyParams storage stratData = strategies[msg.sender];
        return (stratData.active, stratData.totalDebt, stratData.lastReport);
    }

    /*//////////////////////////////////////////////////////////////
                            SETTERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Set contract that will receive vault fees
    /// @param _feeCollector address of feeCollector contract
    function setFeeCollector(address _feeCollector) external onlyOwner {
        feeCollector = _feeCollector;
        emit LogNewfeeCollector(_feeCollector);
    }

    /// @notice Set fee that is reduced from strategy yields when harvests are called
    /// @param _fee new strategy fee
    function setVaultFee(uint256 _fee) external onlyOwner {
        if (_fee >= 3000) revert Errors.VaultFeeTooHigh();
        vaultFee = _fee;
        emit LogNewVaultFee(_fee);
    }

    /// @notice Set how quickly profits are released
    /// @param _time how quickly profits are released in seconds
    function setProfitRelease(uint256 _time) external onlyOwner {
        releaseTime = _time;
        emit LogNewReleaseFactor(_time);
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAW LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Deposit assets into the GVault
    /// @param _assets user deposit amount
    /// @param _receiver Address receiving the shares
    /// @return shares the number of shares minted during the deposit
    function deposit(uint256 _assets, address _receiver)
        external
        override
        nonReentrant
        returns (uint256 shares)
    {
        // Check for rounding error since we round down in previewDeposit.
        if (_assets < minDeposit) revert Errors.MinDeposit();
        if ((shares = previewDeposit(_assets)) == 0) revert Errors.ZeroShares();

        asset.safeTransferFrom(msg.sender, address(this), _assets);
        vaultAssets += _assets;

        _mint(_receiver, shares);

        emit Deposit(msg.sender, _receiver, _assets, shares);

        return shares;
    }

    /// @notice Request shares to be minted by depositing assets into the GVault
    /// @param _shares Amount of shares to be minted
    /// @param _receiver Address receiving the shares
    /// @return assets the number of asset tokens deposited during the mint of the
    /// vault shares
    function mint(uint256 _shares, address _receiver)
        external
        override
        nonReentrant
        returns (uint256 assets)
    {
        // Check for rounding error in previewMint.
        if ((assets = previewMint(_shares)) < minDeposit)
            revert Errors.MinDeposit();

        asset.safeTransferFrom(msg.sender, address(this), assets);
        vaultAssets += assets;

        _mint(_receiver, _shares);

        emit Deposit(msg.sender, _receiver, assets, _shares);

        return assets;
    }

    /// @notice withdraw assets from the GVault
    /// @param _assets the amount of want token the caller wants to withdraw
    /// @param _receiver address receiving the asset token
    /// @param _owner address that owns the 4626 shares that will be burnt
    /// @param _minAmount minAmount of assets to return
    /// @return shares the number of shares burnt during the withdrawal
    function withdraw(
        uint256 _assets,
        address _receiver,
        address _owner,
        uint256 _minAmount
    ) external nonReentrant returns (uint256 shares) {
        return _withdraw(_assets, _receiver, _owner, _minAmount);
    }

    /// @notice withdraw assets from the GVault
    /// @param _assets the amount of want token the caller wants to withdraw
    /// @param _receiver address receiving the asset token
    /// @param _owner address that owns the 4626 shares that will be burnt
    /// @return shares the number of shares burnt during the withdrawal
    function withdraw(
        uint256 _assets,
        address _receiver,
        address _owner
    ) external override nonReentrant returns (uint256 shares) {
        return _withdraw(_assets, _receiver, _owner, 0);
    }

    /// @notice Internal helper function for withdrawal - called by EIP-4626 standard withdraw function
    ///     or custom withdraw function with minAmount.
    function _withdraw(
        uint256 _assets,
        address _receiver,
        address _owner,
        uint256 _minAmount
    ) internal returns (uint256 shares) {
        if (_assets == 0) revert Errors.ZeroAssets();

        shares = previewWithdraw(_assets);

        if (shares > balanceOf[_owner]) revert Errors.InsufficientShares();

        if (msg.sender != _owner) {
            uint256 allowed = allowance[_owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max)
                allowance[_owner][msg.sender] = allowed - shares;
        }

        uint256 vaultBalance;
        (_assets, vaultBalance) = beforeWithdraw(_assets);

        if (_assets < _minAmount) revert Errors.InsufficientAssets();

        _burn(_owner, shares);

        asset.safeTransfer(_receiver, _assets);
        vaultAssets = vaultBalance - _assets;

        emit Withdraw(msg.sender, _receiver, _owner, _assets, shares);

        return shares;
    }

    /// @notice Redeem GVault shares for the equivalent amount of assets
    /// @param _shares the number of vault shares the caller wants to burn
    /// @param _receiver the address that will receive the asset tokens
    /// @param _owner the owner of the shares that will be burnt
    /// @return assets the amount of asset tokens sent to the receiver
    function redeem(
        uint256 _shares,
        address _receiver,
        address _owner
    ) external override nonReentrant returns (uint256 assets) {
        if (_shares == 0) revert Errors.ZeroShares();

        if (_shares > balanceOf[_owner]) revert Errors.InsufficientShares();

        if (msg.sender != _owner) {
            uint256 allowed = allowance[_owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max)
                allowance[_owner][msg.sender] = allowed - _shares;
        }

        assets = convertToAssets(_shares);
        uint256 vaultBalance;
        (assets, vaultBalance) = beforeWithdraw(assets);

        _burn(_owner, _shares);

        asset.safeTransfer(_receiver, assets);
        vaultAssets = vaultBalance - assets;

        emit Withdraw(msg.sender, _receiver, _owner, assets, _shares);

        return assets;
    }

    /*//////////////////////////////////////////////////////////////
                    DEPOSIT/WITHDRAWAL LIMIT LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice The maximum amount a user can deposit into the vault
    function maxDeposit(address)
        public
        view
        override
        returns (uint256 maxAssets)
    {
        return type(uint256).max - convertToAssets(totalSupply);
    }

    /// @notice Simulate the shares issued for a given deposit
    /// @param _assets number of asset tokens being deposited
    /// @return shares number of shares issued for the number of assets provided
    function previewDeposit(uint256 _assets)
        public
        view
        override
        returns (uint256 shares)
    {
        return convertToShares(_assets);
    }

    /// @notice maximum number of shares that can be minted
    function maxMint(address) public view override returns (uint256 maxShares) {
        return type(uint256).max - totalSupply;
    }

    /// @notice Simulate the number of assets required to mint a specific number of shares
    /// @param _shares number of shares to mint
    /// @return assets number of assets required to issue the shares inputted
    function previewMint(uint256 _shares)
        public
        view
        override
        returns (uint256 assets)
    {
        uint256 _totalSupply = totalSupply; // Saves an extra SLOAD if _totalSupply is non-zero.
        return
            _totalSupply == 0
                ? _shares
                : Math.ceilDiv((_shares * _freeFunds()), _totalSupply);
    }

    /// @notice maximum amount of asset tokens the owner can withdraw
    /// @param _owner address of the owner of the GVault Shares
    /// @return maxAssets maximum amount of asset tokens the owner can withdraw
    function maxWithdraw(address _owner)
        public
        view
        override
        returns (uint256 maxAssets)
    {
        return convertToAssets(balanceOf[_owner]);
    }

    /// @notice return the amount of shares that would be burned for a given number of assets
    /// @param _assets number of assert tokens to withdraw
    /// @return shares burnt during withdrawal
    function previewWithdraw(uint256 _assets)
        public
        view
        override
        returns (uint256 shares)
    {
        uint256 freeFunds_ = _freeFunds(); // Saves an extra SLOAD if _freeFunds is non-zero.
        return
            freeFunds_ == 0
                ? _assets
                : Math.ceilDiv(_assets * totalSupply, freeFunds_);
    }

    /// @notice maximum number of shares the owner can redeem
    /// @param _owner address for the owner of the GVault shares
    /// @return maxShares number of GVault shares the owner has
    function maxRedeem(address _owner)
        public
        view
        override
        returns (uint256 maxShares)
    {
        return balanceOf[_owner];
    }

    /// @notice Returns the amount of assets that can be redeemed with the shares
    /// @param _shares the number of shares the caller wants to redeem
    /// @return assets the number of asset tokens the caller would receive
    function previewRedeem(uint256 _shares)
        public
        view
        override
        returns (uint256 assets)
    {
        return convertToAssets(_shares);
    }

    /*//////////////////////////////////////////////////////////////
                        VAULT ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Calculate system total assets including estimated profits
    function totalAssets() external view override returns (uint256) {
        return _estimatedTotalAssets();
    }

    /// @notice Calculate system total assets excluding estimated profits
    function realizedTotalAssets() external view returns (uint256) {
        return _totalAssets();
    }

    /// @notice Value of asset in shares
    /// @param _assets amount of asset to convert to shares
    function convertToShares(uint256 _assets)
        public
        view
        override
        returns (uint256 shares)
    {
        uint256 freeFunds_ = _freeFunds(); // Saves an extra SLOAD if _freeFunds is non-zero.
        return freeFunds_ == 0 ? _assets : (_assets * totalSupply) / freeFunds_;
    }

    /// @notice Value of shares in underlying asset
    /// @param _shares amount of shares to convert to tokens
    function convertToAssets(uint256 _shares)
        public
        view
        override
        returns (uint256 assets)
    {
        uint256 _totalSupply = totalSupply; // Saves an extra SLOAD if _totalSupply is non-zero.
        return
            _totalSupply == 0
                ? _shares
                : ((_shares * _freeFunds()) / _totalSupply);
    }

    /// @notice Gives the price for a single Vault share.
    /// @return The value of a single share.
    function getPricePerShare() external view returns (uint256) {
        return convertToAssets(10**decimals);
    }

    /*//////////////////////////////////////////////////////////////
                            STRATEGY LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Number of active strategies in the vaultAdapter
    function noOfStrategies() internal view returns (uint256) {
        return strategyQueue.totalNodes;
    }

    /// @notice Update the debtRatio of a specific strategy
    /// @param _strategy target strategy
    /// @param _debtRatio new debt ratio
    function setDebtRatio(address _strategy, uint256 _debtRatio)
        external
        onlyOwner
    {
        if (!strategies[_strategy].active) revert Errors.StrategyNotActive();
        _setDebtRatio(_strategy, _debtRatio);
    }

    /// @notice Add a new strategy to the vault adapter
    /// @param _strategy target strategy to add
    /// @param _debtRatio target debtRatio of strategy
    function addStrategy(address _strategy, uint256 _debtRatio)
        external
        onlyOwner
    {
        if (_strategy == ZERO_ADDRESS) revert Errors.ZeroAddress();
        if (strategies[_strategy].active) revert Errors.StrategyActive();
        if (address(this) != IStrategy(_strategy).vault())
            revert Errors.IncorrectVaultOnStrategy();

        StrategyParams storage newStrat = strategies[_strategy];
        newStrat.active = true;
        _setDebtRatio(_strategy, _debtRatio);
        newStrat.lastReport = block.timestamp;

        _push(_strategy);
    }

    /// @notice remove existing strategy from vault by revoking and removing
    ///     from the withdrawal queue
    /// @param _strategy address of old strategy
    /// @dev Should be called when all the debt has been paid back to the vault
    function removeStrategy(address _strategy) external onlyOwner {
        if (!strategies[_strategy].active) revert Errors.StrategyNotActive();
        _revokeStrategy(_strategy);
        _removeStrategy(_strategy);
    }

    /// @notice remove strategy from the withdrawal queue
    /// @param _strategy address of strategy to remove
    function _removeStrategy(address _strategy) internal {
        if (strategies[_strategy].active) revert Errors.StrategyActive();
        if (strategies[_strategy].totalDebt > 0)
            revert Errors.StrategyDebtNotZero();

        _pop(_strategy);
    }

    /// @notice Remove strategy from vault adapter
    function revokeStrategy() external {
        if (!strategies[msg.sender].active) revert Errors.StrategyNotActive();
        _revokeStrategy(msg.sender);
    }

    /// @notice Move the strategy to a new position
    /// @param _strategy Target strategy to move
    /// @param _pos desired position of strategy
    /// @dev if the _pos value is >= number of strategies in the queue,
    ///      the strategy will be moved to the tail position
    function moveStrategy(address _strategy, uint256 _pos) external onlyOwner {
        uint256 currentPos = getStrategyPositions(_strategy);
        uint256 _strategyId = strategyId[_strategy];
        if (currentPos > _pos)
            move(uint48(_strategyId), uint48(currentPos - _pos), false);
        else move(uint48(_strategyId), uint48(_pos - currentPos), true);
    }

    /// @notice Check how much credits are available for the strategy
    /// @param _strategy Target strategy
    function creditAvailable(address _strategy)
        external
        view
        returns (uint256)
    {
        return _creditAvailable(_strategy);
    }

    /// @notice Same as above but called by the streategy
    function creditAvailable() external view returns (uint256) {
        return _creditAvailable(msg.sender);
    }

    /// @notice Amount of debt the strategy has to pay back to the vault at next harvest
    /// @param _strategy target strategy
    /// @return amount of debt the strategy has to pay back and the current debt ratio of the strategy
    function excessDebt(address _strategy)
        external
        view
        returns (uint256, uint256)
    {
        return _excessDebt(_strategy);
    }

    /// @notice Helper function to get strategy's total debt to the vault
    /// @dev here to simplify strategy's life when trying to get the totalDebt
    function strategyDebt() external view returns (uint256) {
        return strategies[msg.sender].totalDebt;
    }

    /// @notice Report back any gains/losses from a (strategy) harvest, vault adapter
    ///     calls back debt or gives out more credit to the strategy depending on available
    ///     credit and the strategies current position.
    /// @param _gain Strategy gains from latest harvest
    /// @param _loss Strategy losses from latest harvest
    /// @param _debtPayment Amount strategy can pay back to vault
    /// @param _emergency Flag to indicate if the harvest was an emergency harvest
    function report(
        uint256 _gain,
        uint256 _loss,
        uint256 _debtPayment,
        bool _emergency
    ) external returns (uint256) {
        StrategyParams storage _strategy = strategies[msg.sender];
        if (!_strategy.active) revert Errors.StrategyNotActive();
        if (asset.balanceOf(msg.sender) < _debtPayment)
            revert Errors.IncorrectStrategyAccounting();

        if (_loss > 0) {
            _reportLoss(msg.sender, _loss);
        }
        if (_gain > 0) {
            _strategy.totalGain += _gain;
            _strategy.totalDebt += _gain;
            vaultTotalDebt += _gain;
        }

        if (_emergency) {
            _revokeStrategy(msg.sender);
        }

        (uint256 debt, ) = _excessDebt(msg.sender);
        uint256 debtPayment = Math.min(_debtPayment, debt);

        if (debtPayment > 0) {
            _strategy.totalDebt = _strategy.totalDebt - debtPayment;
            vaultTotalDebt -= debtPayment;
            debt -= debtPayment;
        }

        uint256 credit = _creditAvailable(msg.sender);

        if (credit > 0) {
            _strategy.totalDebt += credit;
            vaultTotalDebt += credit;
        }

        uint256 totalAvailable = debtPayment;

        if (totalAvailable < credit) {
            asset.safeTransfer(msg.sender, credit - totalAvailable);
            vaultAssets -= credit - totalAvailable;
        } else if (totalAvailable > credit) {
            asset.safeTransferFrom(
                msg.sender,
                address(this),
                totalAvailable - credit
            );
            vaultAssets += totalAvailable - credit;
        }

        // Profit is locked and gradually released per block
        // this computes current locked profit and replace with
        // the sum of the current and the new profit
        uint256 lockedProfitBeforeLoss = _calculateLockedProfit() +
            _calcFees(_gain);
        // Store how much loss remains after locked profit is removed,
        // here only for logging purposes
        if (lockedProfitBeforeLoss > _loss) {
            lockedProfit = lockedProfitBeforeLoss - _loss;
        } else {
            lockedProfit = 0;
        }

        lastReport = block.timestamp;
        _strategy.lastReport = lastReport;

        if (_emergency) {
            _removeStrategy(msg.sender);
        }

        emit LogStrategyHarvestReport(
            msg.sender,
            _gain,
            _loss,
            debtPayment,
            credit,
            lockedProfit,
            lockedProfitBeforeLoss
        );

        emit LogStrategyTotalChanges(
            msg.sender,
            _strategy.totalGain,
            _strategy.totalLoss,
            _strategy.totalDebt
        );

        return credit;
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL HOOKS
    //////////////////////////////////////////////////////////////*/

    /// @notice Runs before any withdraw function mainly to ensure vault has enough assets
    /// @param _assets Amount of assets to withdraw
    /// @return Amount of assets withdrawn and amount of assets in vault
    function beforeWithdraw(uint256 _assets)
        internal
        returns (uint256, uint256)
    {
        // If reserves dont cover the withdrawal, start withdrawing from strategies
        ERC20 _token = asset;
        uint256 vaultBalance = vaultAssets;
        if (_assets > vaultBalance) {
            uint48 _strategyId = strategyQueue.head;
            while (true) {
                address _strategy = nodes[_strategyId].strategy;
                // break if we have withdrawn all we need
                if (_assets <= vaultBalance) break;
                uint256 amountNeeded = _assets - vaultBalance;

                StrategyParams storage _strategyData = strategies[_strategy];
                amountNeeded = Math.min(amountNeeded, _strategyData.totalDebt);
                // If nothing is needed or strategy has no assets, continue
                if (amountNeeded > 0) {
                    (uint256 withdrawn, uint256 loss) = IStrategy(_strategy)
                        .withdraw(amountNeeded);

                    // Handle the loss if any
                    if (loss > 0) {
                        _assets = _assets - loss;
                        _reportLoss(_strategy, loss);
                    }
                    // Remove withdrawn amount from strategy and vault debts
                    _strategyData.totalDebt -= withdrawn;
                    vaultTotalDebt -= withdrawn;
                    vaultBalance += withdrawn;
                    emit LogWithdrawalFromStrategy(
                        _strategyId,
                        _strategyData.totalDebt,
                        vaultTotalDebt,
                        loss
                    );
                }
                _strategyId = nodes[_strategyId].next;
                if (_strategyId == 0) break;
            }
            if (_assets > vaultBalance) {
                _assets = vaultBalance;
            }
        }
        return (_assets, vaultBalance);
    }

    /// @notice Calculate how much profit is currently locked
    function _calculateLockedProfit() internal view returns (uint256) {
        uint256 _releaseTime = releaseTime;
        uint256 _timeSinceLastReport = block.timestamp - lastReport;
        if (_releaseTime > _timeSinceLastReport) {
            uint256 _lockedProfit = lockedProfit;
            return
                _lockedProfit -
                ((_lockedProfit * _timeSinceLastReport) / _releaseTime);
        } else {
            return 0;
        }
    }

    /// @notice the number of total assets the GVault has excluding profits
    /// and losses
    function _freeFunds() internal view returns (uint256) {
        return _totalAssets() - _calculateLockedProfit();
    }

    /// @notice Calculate the amount of assets the vault has available for the strategy to pull and invest,
    ///     the available credit is based on the strategies debt ratio and the total available assets
    ///     the vault has
    /// @param _strategy target strategy
    /// @dev called during harvest
    function _creditAvailable(address _strategy)
        internal
        view
        returns (uint256)
    {
        StrategyParams memory _strategyData = strategies[_strategy];
        uint256 vaultTotalAssets = _totalAssets();
        uint256 vaultDebtLimit = (vaultDebtRatio * vaultTotalAssets) /
            PERCENTAGE_DECIMAL_FACTOR;
        uint256 _vaultTotalDebt = vaultTotalDebt;
        uint256 strategyDebtLimit = (_strategyData.debtRatio *
            vaultTotalAssets) / PERCENTAGE_DECIMAL_FACTOR;
        uint256 strategyTotalDebt = _strategyData.totalDebt;

        if (
            strategyDebtLimit <= strategyTotalDebt ||
            vaultDebtLimit <= _vaultTotalDebt
        ) {
            return 0;
        }

        uint256 available = strategyDebtLimit - strategyTotalDebt;

        available = Math.min(available, vaultDebtLimit - _vaultTotalDebt);

        return Math.min(available, vaultAssets);
    }

    /// @notice Deal with any loss that a strategy has realized
    /// @param _strategy target strategy
    /// @param _loss amount of loss realized
    function _reportLoss(address _strategy, uint256 _loss) internal {
        StrategyParams storage strategy = strategies[_strategy];
        // Loss can only be up the amount of debt issued to strategy
        if (strategy.totalDebt < _loss) revert Errors.StrategyLossTooHigh();
        // Add loss to strategy and remove loss from strategyDebt
        strategy.totalLoss += _loss;
        strategy.totalDebt -= _loss;
        vaultTotalDebt -= _loss;
    }

    /// @notice Amount by which a strategy exceeds its current debt limit
    /// @param _strategy target strategy
    /// @return amount of debt the strategy has to pay back and the current debt ratio of the strategy
    function _excessDebt(address _strategy)
        internal
        view
        returns (uint256, uint256)
    {
        StrategyParams storage strategy = strategies[_strategy];
        uint256 _debtRatio = strategy.debtRatio;
        uint256 strategyDebtLimit = (_debtRatio * _totalAssets()) /
            PERCENTAGE_DECIMAL_FACTOR;
        uint256 strategyTotalDebt = strategy.totalDebt;

        if (strategyTotalDebt <= strategyDebtLimit) {
            return (0, _debtRatio);
        } else {
            return (strategyTotalDebt - strategyDebtLimit, _debtRatio);
        }
    }

    function _calcFees(uint256 _gain) internal returns (uint256) {
        uint256 fees = (_gain * vaultFee) / PERCENTAGE_DECIMAL_FACTOR;
        if (fees > 0) {
            uint256 shares = convertToShares(fees);
            _mint(feeCollector, shares);
        }
        return _gain - fees;
    }

    /// @notice Update a given strategys debt ratio
    /// @param _strategy target strategy
    /// @param _debtRatio new debt ratio
    /// @dev See setDebtRatio functions
    function _setDebtRatio(address _strategy, uint256 _debtRatio) internal {
        uint256 _vaultDebtRatio = vaultDebtRatio -
            strategies[_strategy].debtRatio +
            _debtRatio;
        if (_vaultDebtRatio > PERCENTAGE_DECIMAL_FACTOR)
            revert Errors.VaultDebtRatioTooHigh();
        strategies[_strategy].debtRatio = _debtRatio;
        vaultDebtRatio = _vaultDebtRatio;
        emit LogNewDebtRatio(_strategy, _debtRatio, _vaultDebtRatio);
    }

    /// @notice Get current estimated amount of assets in strategy
    /// @param _index index of strategy
    function _getStrategyEstimatedTotalAssets(uint256 _index)
        internal
        view
        returns (uint256)
    {
        return IStrategy(nodes[_index].strategy).estimatedTotalAssets();
    }

    /// @notice Remove strategy from vault
    /// @param _strategy address of strategy
    function _revokeStrategy(address _strategy) internal {
        vaultDebtRatio -= strategies[_strategy].debtRatio;
        strategies[_strategy].debtRatio = 0;
        strategies[_strategy].active = false;
    }

    /// @notice Vault adapters total assets including loose assets and debts
    /// @dev note that this does not consider estimated gains/losses from the strategies
    function _totalAssets() private view returns (uint256) {
        return vaultAssets + vaultTotalDebt;
    }

    /// @notice Vault adapters total assets including loose assets and estimated returns
    /// @dev note that this does consider estimated gains/losses from the strategies
    function _estimatedTotalAssets() private view returns (uint256) {
        uint256 total = vaultAssets;
        uint256[MAXIMUM_STRATEGIES] memory _queue = fullWithdrawalQueue();
        for (uint256 i = 0; i < noOfStrategies(); ++i) {
            total += _getStrategyEstimatedTotalAssets(_queue[i]);
        }
        return total;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount)
        public
        virtual
        returns (bool)
    {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount)
        public
        virtual
        returns (bool)
    {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max)
            allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                              EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            PERMIT_TYPEHASH,
                            owner,
                            spender,
                            value,
                            nonces[owner]++,
                            deadline
                        )
                    )
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

            require(
                recoveredAddress != address(0) && recoveredAddress == owner,
                "INVALID_SIGNER"
            );

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return
            block.chainid == INITIAL_CHAIN_ID
                ? INITIAL_DOMAIN_SEPARATOR
                : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Gnosis (https://github.com/gnosis/gp-v2-contracts/blob/main/src/contracts/libraries/GPv2SafeERC20.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
library SafeTransferLib {
    /*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool callStatus;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(callStatus, "ETH_TRANSFER_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                           ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(
                freeMemoryPointer,
                0x23b872dd00000000000000000000000000000000000000000000000000000000
            ) // Begin with the function selector.
            mstore(
                add(freeMemoryPointer, 4),
                and(from, 0xffffffffffffffffffffffffffffffffffffffff)
            ) // Mask and append the "from" argument.
            mstore(
                add(freeMemoryPointer, 36),
                and(to, 0xffffffffffffffffffffffffffffffffffffffff)
            ) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 100 because the calldata length is 4 + 32 * 3.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)
        }

        require(
            didLastOptionalReturnCallSucceed(callStatus),
            "TRANSFER_FROM_FAILED"
        );
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(
                freeMemoryPointer,
                0xa9059cbb00000000000000000000000000000000000000000000000000000000
            ) // Begin with the function selector.
            mstore(
                add(freeMemoryPointer, 4),
                and(to, 0xffffffffffffffffffffffffffffffffffffffff)
            ) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(
            didLastOptionalReturnCallSucceed(callStatus),
            "TRANSFER_FAILED"
        );
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(
                freeMemoryPointer,
                0x095ea7b300000000000000000000000000000000000000000000000000000000
            ) // Begin with the function selector.
            mstore(
                add(freeMemoryPointer, 4),
                and(to, 0xffffffffffffffffffffffffffffffffffffffff)
            ) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "APPROVE_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                         INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function didLastOptionalReturnCallSucceed(bool callStatus)
        private
        pure
        returns (bool success)
    {
        assembly {
            // Get how many bytes the call returned.
            let returnDataSize := returndatasize()

            // If the call reverted:
            if iszero(callStatus) {
                // Copy the revert message into memory.
                returndatacopy(0, 0, returnDataSize)

                // Revert with the same message.
                revert(0, returnDataSize)
            }

            switch returnDataSize
            case 32 {
                // Copy the return data into memory.
                returndatacopy(0, 0, returnDataSize)

                // Set success to whether it returned true.
                success := iszero(iszero(mload(0)))
            }
            case 0 {
                // There was no return data.
                success := 1
            }
            default {
                // It returned some malformed input.
                success := 0
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

interface IStrategy {
    function asset() external view returns (address);

    function vault() external view returns (address);

    function isActive() external view returns (bool);

    function estimatedTotalAssets() external view returns (uint256);

    function withdraw(uint256 _amount) external returns (uint256, uint256);

    function canHarvest() external view returns (bool);

    function runHarvest() external;

    function canStopLoss() external view returns (bool);

    function stopLoss() external returns (bool);

    function getMetaPool() external view returns (address);
}

// SPDX-License-Identifier: MIT
// Adpated from OZ Draft Implementation

pragma solidity 0.8.10;

import {ERC20} from "ERC20.sol";

abstract contract ERC4626 is ERC20 {
    event Deposit(
        address indexed caller,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * @dev Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
     *
     * - MUST be an ERC-20 token contract.
     * - MUST NOT revert.
     */
    function asset() external view virtual returns (ERC20);

    /**
     * @dev Returns the total amount of the underlying asset that is “managed” by Vault.
     *
     * - SHOULD include any compounding that occurs from yield.
     * - MUST be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT revert.
     */
    function totalAssets()
        external
        view
        virtual
        returns (uint256 totalManagedAssets);

    /**
     * @dev Returns the amount of shares that the Vault would exchange for the amount of assets provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToShares(uint256 assets)
        external
        view
        virtual
        returns (uint256 shares);

    /**
     * @dev Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToAssets(uint256 shares)
        external
        view
        virtual
        returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
     * through a deposit call.
     *
     * - MUST return a limited value if receiver is subject to some deposit limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
     * - MUST NOT revert.
     */
    function maxDeposit(address receiver)
        external
        view
        virtual
        returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of Vault shares that would be minted in a deposit
     *   call in the same transaction. I.e. deposit should return the same or more shares as previewDeposit if called
     *   in the same transaction.
     * - MUST NOT account for deposit limits like those returned from maxDeposit and should always act as though the
     *   deposit would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewDeposit(uint256 assets)
        external
        view
        virtual
        returns (uint256 shares);

    /**
     * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   deposit execution, and are accounted for during deposit.
     * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function deposit(uint256 assets, address receiver)
        external
        virtual
        returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call.
     * - MUST return a limited value if receiver is subject to some mint limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of shares that may be minted.
     * - MUST NOT revert.
     */
    function maxMint(address receiver)
        external
        view
        virtual
        returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of assets that would be deposited in a mint call
     *   in the same transaction. I.e. mint should return the same or fewer assets as previewMint if called in the
     *   same transaction.
     * - MUST NOT account for mint limits like those returned from maxMint and should always act as though the mint
     *   would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewMint SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by minting.
     */
    function previewMint(uint256 shares)
        external
        view
        virtual
        returns (uint256 assets);

    /**
     * @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the mint
     *   execution, and are accounted for during mint.
     * - MUST revert if all of shares cannot be minted (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function mint(uint256 shares, address receiver)
        external
        virtual
        returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
     * Vault, through a withdraw call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxWithdraw(address owner)
        external
        view
        virtual
        returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a withdraw
     *   call in the same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if
     *   called
     *   in the same transaction.
     * - MUST NOT account for withdrawal limits like those returned from maxWithdraw and should always act as though
     *   the withdrawal would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewWithdraw(uint256 assets)
        external
        view
        virtual
        returns (uint256 shares);

    /**
     * @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   withdraw execution, and are accounted for during withdraw.
     * - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external virtual returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
     * through a redeem call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxRedeem(address owner)
        external
        view
        virtual
        returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call
     *   in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the
     *   same transaction.
     * - MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
     *   redemption would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by redeeming.
     */
    function previewRedeem(uint256 shares)
        external
        view
        virtual
        returns (uint256 assets);

    /**
     * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   redeem execution, and are accounted for during redeem.
     * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external virtual returns (uint256 assets);
}

// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

contract Constants {
    uint8 public constant N_COINS = 3;
    uint8 public constant DEFAULT_DECIMALS = 18; // GToken and Controller use these decimals
    uint256 public constant DEFAULT_DECIMALS_FACTOR =
        uint256(10)**DEFAULT_DECIMALS;
    uint8 public constant CHAINLINK_PRICE_DECIMALS = 8;
    uint256 public constant CHAINLINK_PRICE_DECIMAL_FACTOR =
        uint256(10)**CHAINLINK_PRICE_DECIMALS;
    uint8 public constant PERCENTAGE_DECIMALS = 4;
    uint256 public constant PERCENTAGE_DECIMAL_FACTOR =
        uint256(10)**PERCENTAGE_DECIMALS;
    uint256 public constant CURVE_RATIO_DECIMALS = 6;
    uint256 public constant CURVE_RATIO_DECIMALS_FACTOR =
        uint256(10)**CURVE_RATIO_DECIMALS;
}

// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

library Errors {
    // Common
    error AlreadyMigrated(); // 0xca1c3cbc
    error AmountIsZero(); // 0x43ad20fc
    error ChainLinkFeedStale(); //0x3bc80ea6
    error IndexTooHigh(); // 0xfbf22ac0
    error IncorrectSweepToken(); // 0x25371b04
    error LTMinAmountExpected(); //less than 0x3d93e699
    error NotEnoughBalance(); // 0xad3a8b9e
    error ZeroAddress(); //0xd92e233d
    error MinDeposit(); //0x11bcd830

    // GMigration
    error TrancheAlreadySet(); //0xe8ce7222
    error TrancheNotSet(); //0xc7896cf2

    // GTranche
    error UtilisationTooHigh(); // 0x01dbe4de
    error MsgSenderNotTranche(); // 0x7cda3092
    error NoAssets(); // 0x5373815f

    // GVault
    error InsufficientShares(); // 0x39996567
    error InsufficientAssets(); // 0x96d80433
    error IncorrectStrategyAccounting(); //0x7b6d99a5
    error IncorrectVaultOnStrategy(); //0x7408aa63
    error OverDepositLimit(); //0xbf41e3d0
    error StrategyActive(); // 0xebb33d91
    error StrategyNotActive(); // 0xdc974a98
    error StrategyDebtNotZero(); // 0x332c333c
    error StrategyLossTooHigh(); // 0xa9aba8bd
    error VaultDebtRatioTooHigh(); //0xf6f34eca
    error VaultFeeTooHigh(); //0xb6659cb6
    error ZeroAssets(); //0x32d971dc
    error ZeroShares(); //0x9811e0c7

    //Whitelist
    error NotInWhitelist(); // 0x5b0aa2ba
}

// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

//  ________  ________  ________
//  |\   ____\|\   __  \|\   __  \
//  \ \  \___|\ \  \|\  \ \  \|\  \
//   \ \  \  __\ \   _  _\ \  \\\  \
//    \ \  \|\  \ \  \\  \\ \  \\\  \
//     \ \_______\ \__\\ _\\ \_______\
//      \|_______|\|__|\|__|\|_______|

// gro protocol: https://github.com/groLabs/GSquared

/// @title StrategyQueue
/// @notice StrategyQueue - logic for handling ordering of vault strategies
///     ---------    ---------    ---------
///     | Strat |    | Strat |    | Strat |
///     |  ---  |    |  ---  |    |  ---  |
/// 0<--|  prev-|<---|  prev-|<---|  prev-|
///     |  next-|--->|  next-|--->|  next-|-->0
///     ---------    ---------    ---------
///       Head                      Tail
contract StrategyQueue {
    /*//////////////////////////////////////////////////////////////
                    STORAGE VARIABLES & TYPES
    //////////////////////////////////////////////////////////////*/

    // node in queue
    struct Strategy {
        uint48 next;
        uint48 prev;
        address strategy;
    }

    // Information regarding queue
    struct Queue {
        uint48 head;
        uint48 tail;
        uint48 totalNodes;
        uint48 nextAvailableNode;
    }

    /*//////////////////////////////////////////////////////////////
                        CONSTANTS & IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    uint256 public constant MAXIMUM_STRATEGIES = 5;
    address internal constant ZERO_ADDRESS = address(0);
    uint48 internal constant EMPTY_NODE = 0;

    mapping(address => uint256) public strategyId;
    mapping(uint256 => Strategy) internal nodes;

    Queue internal strategyQueue;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event LogStrategyRemoved(address indexed strategy, uint256 indexed id);
    event LogStrategyAdded(
        address indexed strategy,
        uint256 indexed id,
        uint256 pos
    );
    event LogNewQueueLink(uint256 indexed id, uint256 next);
    event LogNewQueueHead(uint256 indexed id);
    event LogNewQueueTail(uint256 indexed id);

    /*//////////////////////////////////////////////////////////////
                            ERRORS HANDLING
    //////////////////////////////////////////////////////////////*/

    error NoIdEntry(uint256 id);
    error StrategyNotMoved(uint256 errorNo);
    // 1 - no move specified
    // 2 - strategy cant be moved further up/down the queue
    // 3 - strategy moved to its own position
    error NoStrategyEntry(address strategy);
    error StrategyExists(address strategy);
    error MaxStrategyExceeded();

    /*//////////////////////////////////////////////////////////////
                               GETTERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Get strategy at position i of withdrawal queue
    /// @param i position in withdrawal queue
    /// @return strategy strategy at position i
    function withdrawalQueueAt(uint256 i)
        external
        view
        returns (address strategy)
    {
        if (i == 0 || i == strategyQueue.totalNodes - 1) {
            strategy = i == 0
                ? nodes[strategyQueue.head].strategy
                : nodes[strategyQueue.tail].strategy;
        } else {
            uint256 index = strategyQueue.head;
            for (uint256 j; j <= i; j++) {
                if (j == i) return nodes[index].strategy;
                index = nodes[index].next;
            }
        }
    }

    /// @notice Get the entire withdrawal queue
    /// @return queue list of all strategy ids in order of withdrawal priority
    function fullWithdrawalQueue()
        internal
        view
        returns (uint256[MAXIMUM_STRATEGIES] memory queue)
    {
        uint256 index = strategyQueue.head;
        uint256 _totalNodes = strategyQueue.totalNodes;
        queue[0] = index;
        for (uint256 i = 1; i < _totalNodes; ++i) {
            index = nodes[index].next;
            queue[i] = index;
        }
    }

    /// @notice Get position of strategy in withdrawal queue
    /// @param _strategy address of strategy
    /// @return returns position of strategy in withdrawal queue
    function getStrategyPositions(address _strategy)
        public
        view
        returns (uint256)
    {
        uint48 index = strategyQueue.head;
        uint48 _totalNodes = strategyQueue.totalNodes;
        for (uint48 i = 0; i <= _totalNodes; ++i) {
            if (_strategy == nodes[index].strategy) {
                return i;
            }
            index = nodes[index].next;
        }
        revert NoStrategyEntry(_strategy);
    }

    /*//////////////////////////////////////////////////////////////
                          QUEUE LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Add a strategy to the end of the queue
    /// @param _strategy address of strategy to add
    /// @dev creates a new node which is inserted at the end of the
    ///     strategy queue. the strategy is assigned an id and is
    ///     linked to the previous tail. Note that this ID isnt
    ///        necessarily the same as the position in the withdrawal queue
    function _push(address _strategy) internal returns (uint256) {
        if (strategyId[_strategy] > 0) revert StrategyExists(_strategy);
        uint48 nodeId = _createNode(_strategy);
        return uint256(nodeId);
    }

    /// @notice Remove strategy from queue
    /// @param _strategy strategy to remove
    /// @dev removes a node and links the nodes neighbours
    function _pop(address _strategy) internal {
        uint256 id = strategyId[_strategy];
        if (id == 0) revert NoStrategyEntry(_strategy);
        Strategy storage removeNode = nodes[uint48(id)];
        address strategy = removeNode.strategy;
        if (strategy == ZERO_ADDRESS) revert NoIdEntry(id);
        _link(removeNode.prev, removeNode.next);
        strategyId[_strategy] = 0;
        emit LogStrategyRemoved(strategy, id);
        delete nodes[uint48(id)];
        strategyQueue.totalNodes -= 1;
    }

    /// @notice move a strategy to a new position in the queue
    /// @param _id id of strategy to move
    /// @param _steps number of steps to move the strategy
    /// @param _back move towards tail (true) or head (false)
    /// @dev Moves a strategy a given number of steps. If the number
    ///        of steps exceeds the position of the head/tail, the
    ///        strategy will take the place of the current head/tail
    function move(
        uint48 _id,
        uint48 _steps,
        bool _back
    ) internal {
        Strategy storage oldPos = nodes[_id];
        if (_steps == 0) revert StrategyNotMoved(1);
        if (oldPos.strategy == ZERO_ADDRESS) revert NoIdEntry(_id);
        uint48 _newPos = !_back ? oldPos.prev : oldPos.next;
        if (_newPos == 0) revert StrategyNotMoved(2);

        for (uint256 i = 1; i < _steps; ++i) {
            _newPos = !_back ? nodes[_newPos].prev : nodes[_newPos].next;
            if (_newPos == 0) {
                _newPos = !_back ? strategyQueue.head : strategyQueue.tail;
                break;
            }
        }
        if (_newPos == _id) revert StrategyNotMoved(3);
        Strategy memory newPos = nodes[_newPos];
        _link(oldPos.prev, oldPos.next);
        if (!_back) {
            _link(newPos.prev, _id);
            _link(_id, _newPos);
        } else {
            _link(_id, newPos.next);
            _link(_newPos, _id);
        }
    }

    /// @notice Create a new node to be inserted at the tail of the queue
    /// @param _strategy address of strategy to add
    /// @return id of strategy
    function _createNode(address _strategy) internal returns (uint48) {
        uint48 _totalNodes = strategyQueue.totalNodes;
        if (_totalNodes >= MAXIMUM_STRATEGIES) revert MaxStrategyExceeded();
        strategyQueue.nextAvailableNode += 1;
        strategyQueue.totalNodes = _totalNodes + 1;
        uint48 newId = uint48(strategyQueue.nextAvailableNode);
        strategyId[_strategy] = newId;

        uint48 _tail = strategyQueue.tail;
        Strategy memory node = Strategy(EMPTY_NODE, _tail, _strategy);

        _link(_tail, newId);
        _setTail(newId);
        nodes[newId] = node;

        emit LogStrategyAdded(_strategy, newId, _totalNodes + 1);

        return newId;
    }

    /// @notice Set the head of the queue
    /// @param _id Id of the strategy to set the head to
    function _setHead(uint256 _id) internal {
        strategyQueue.head = uint48(_id);
        emit LogNewQueueHead(_id);
    }

    /// @notice Set the tail of the queue
    /// @param _id Id of the strategy to set the tail to
    function _setTail(uint256 _id) internal {
        strategyQueue.tail = uint48(_id);
        emit LogNewQueueTail(_id);
    }

    /// @notice Link two nodes
    /// @param _prevId id of previous node
    /// @param _nextId id of next node
    function _link(uint48 _prevId, uint48 _nextId) internal {
        if (_prevId == EMPTY_NODE) {
            _setHead(_nextId);
        } else {
            nodes[_prevId].next = _nextId;
        }
        if (_nextId == EMPTY_NODE) {
            _setTail(_prevId);
        } else {
            nodes[_nextId].prev = _prevId;
        }
        emit LogNewQueueLink(_prevId, _nextId);
    }
}