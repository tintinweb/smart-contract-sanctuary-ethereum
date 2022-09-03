// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;
/**
 * @title  Vault Contract
 * @notice The Vault contract defines the storage for the Vault contracts
 * @author BankOfChain Protocol Inc
 */

import "./ETHVaultStorage.sol";
import "../strategies/IETHStrategy.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract ETHVault is ETHVaultStorage {
    using StableMath for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSet for EnumerableSet.AddressSet;
    using IterableIntMap for IterableIntMap.AddressToIntMap;

    function initialize(
        address _accessControlProxy,
        address _treasury,
        address _exchangeManager,
        address _priceProvider
    ) public initializer {
        _initAccessControl(_accessControlProxy);

        treasury = _treasury;
        exchangeManager = _exchangeManager;
        priceProvider = _priceProvider;
        // 1 / 1000e4
        rebaseThreshold = 1;
        // one week
        maxTimestampBetweenTwoReported = 604800;
        underlyingUnitsPerShare = 1e18;
        minCheckedStrategyTotalDebt = 1e17;
    }

    modifier whenNotEmergency() {
        require(!emergencyShutdown, "ES");
        _;
    }

    modifier whenNotAdjustPosition() {
        require(!adjustPositionPeriod, "AD");
        _;
    }

    /**
     * @dev Verifies that the rebasing is not paused.
     */
    modifier whenNotRebasePaused() {
        require(!rebasePaused, "RP");
        _;
    }

    modifier isActiveStrategy(address _strategy) {
        checkActiveStrategy(_strategy);
        _;
    }

    /// @notice Version of vault
    function getVersion() external pure returns (string memory) {
        return "1.1.0";
    }

    /// @notice Minting ETHi supported assets
    function getSupportAssets() external view returns (address[] memory) {
        return assetSet.values();
    }

    /// @notice Check '_asset' is supported or not
    function checkIsSupportAsset(address _asset) public view {
        require(assetSet.contains(_asset), "The asset not support");
    }

    /// @notice Assets held by Vault
    function getTrackedAssets() external view returns (address[] memory) {
        return _getTrackedAssets();
    }

    /// @notice Vault holds asset value directly in ETH (1e18)
    function valueOfTrackedTokens() external view returns (uint256) {
        return _totalAssetInVault();
    }

    /// @notice Vault and vault buffer holds asset value directly ETH (1e18)
    function valueOfTrackedTokensIncludeVaultBuffer() external view returns (uint256) {
        return _totalAssetInVaultAndVaultBuffer();
    }

    /// @notice Vault total asset in ETH(1e18)
    function totalAssets() external view returns (uint256) {
        return _getTotalAssets();
    }

    /// @notice Vault and vault buffer total asset in USD
    function totalAssetsIncludeVaultBuffer() external view returns (uint256) {
        return _totalAssetInVaultAndVaultBuffer() + totalDebt;
    }

    /// @notice Vault total value(by chainlink price) in USD(1e18)
    function totalValue() external view returns (uint256) {
        return totalValueInVault() + totalValueInStrategies();
    }

    /**
     * @dev Internal to calculate total value of all assets held in Vault.
     * @return _value Total value(by chainlink price) in USD (1e18)
     */
    function totalValueInVault() public view returns (uint256 _value) {
        address[] memory _trackedAssets = _getTrackedAssets();
        for (uint256 i = 0; i < _trackedAssets.length; i++) {
            address _trackedAsset = _trackedAssets[i];
            uint256 _balance = _balanceOfToken(_trackedAsset, address(this));
            if (_balance > 0) {
                _value =
                    _value +
                    IPriceOracleConsumer(priceProvider).valueInUsd(_trackedAsset, _balance);
            }
        }
    }

    /**
     * @dev Internal to calculate total value of all assets held in Strategies.
     * @return _value Total value(by chainlink price) in USD (1e18)
     */
    function totalValueInStrategies() public view returns (uint256 _value) {
        uint256 _strategyLength = strategySet.length();
        for (uint256 i = 0; i < _strategyLength; i++) {
            uint256 _estimatedTotalAssets = IETHStrategy(strategySet.at(i)).estimatedTotalAssets();
            if (_estimatedTotalAssets > 0) {
                _value =
                    _value +
                    IPriceOracleConsumer(priceProvider).valueInUsd(
                        NativeToken.NATIVE_TOKEN,
                        _estimatedTotalAssets
                    );
            }
        }
    }

    /// @notice All strategies
    function getStrategies() external view returns (address[] memory) {
        return strategySet.values();
    }

    /**
     * @notice Get pegToken price in USD
     * @return  price in USD (1e18)
     */
    function getPegTokenPrice() external view returns (uint256) {
        uint256 _totalSupply = IPegToken(pegTokenAddress).totalSupply();
        uint256 _pegTokenPrice = 1e18;
        if (_totalSupply > 0) {
            address[] memory _trackedAssets = _getTrackedAssets();
            uint256 _trackedAssetsLength = _trackedAssets.length;
            uint256[] memory _assetPrices = new uint256[](_trackedAssetsLength);
            uint256[] memory _assetDecimals = new uint256[](_trackedAssetsLength);
            uint256 _totalValueInVault = 0;
            uint256 _totalTransferValue = 0;
            for (uint256 i = 0; i < _trackedAssetsLength; i++) {
                address _trackedAsset = _trackedAssets[i];
                uint256 _balance = _balanceOfToken(_trackedAsset, address(this));
                if (_balance > 0) {
                    _totalValueInVault =
                    _totalValueInVault +
                    _calculateAssetValue(_assetPrices, _assetDecimals, i, _trackedAsset, _balance);
                }
                _balance = transferFromVaultBufferAssetsMap[_trackedAsset];
                if (_balance > 0) {
                    _totalTransferValue =
                    _totalTransferValue +
                    _calculateAssetValue(_assetPrices, _assetDecimals, i, _trackedAsset, _balance);
                }
            }
            _pegTokenPrice = ((_totalValueInVault + totalDebt - _totalTransferValue) * 1e18) / _totalSupply;
        }
        return _pegTokenPrice;
    }

    /// @notice Check '_strategy' is active or not
    function checkActiveStrategy(address _strategy) public view {
        require(strategySet.contains(_strategy), "strategy not exist");
    }

    /// @notice estimate Minting pending share
    /// @param _amount Amount of the asset being deposited
    /// @return _pending Share Amount
    function estimateMint(address _asset, uint256 _amount) external view returns (uint256) {
        return _estimateMint(_asset, _amount);
    }

    /// @param _asset Address of the asset being deposited
    /// @param _amount Amount of the asset being deposited
    /// @dev Support single asset
    /// @return The amount of share minted
    function mint(
        address _asset,
        uint256 _amount,
        uint256 _minimumAmount
    ) external payable whenNotEmergency whenNotAdjustPosition nonReentrant returns (uint256) {
        uint256 _shareAmount = _estimateMint(_asset, _amount);
        if (_minimumAmount > 0) {
            require(_shareAmount >= _minimumAmount, "Mint amount lt minimum");
        }
        if (_asset == NativeToken.NATIVE_TOKEN) {
            uint256 _ethAmount = msg.value;
            require(_ethAmount == _amount, "Amount must eq transfer value");
            IVaultBuffer(vaultBufferAddress).mint{value: _ethAmount}(msg.sender, _shareAmount);
        } else {
            IERC20Upgradeable(_asset).safeTransferFrom(msg.sender, vaultBufferAddress, _amount);
            IVaultBuffer(vaultBufferAddress).mint(msg.sender, _shareAmount);
        }
        emit Mint(msg.sender, _asset, _amount, _shareAmount);
        return _shareAmount;
    }

    /// @notice burn ETHi,return stablecoins
    /// @param _amount Amount of ETHi to burn
    /// @param _minimumAmount Minimum stablecoin units to receive in return
    function burn(uint256 _amount, uint256 _minimumAmount)
        external
        whenNotEmergency
        whenNotAdjustPosition
        nonReentrant
        returns (address[] memory _assets, uint256[] memory _amounts)
    {
        uint256 _accountBalance = IPegToken(pegTokenAddress).balanceOf(msg.sender);
        require(_amount > 0 && _amount <= _accountBalance, "ETHi not enough");
        address[] memory _trackedAssets = _getTrackedAssets();
        uint256[] memory _assetPrices = new uint256[](_trackedAssets.length);
        uint256[] memory _assetDecimals = new uint256[](_trackedAssets.length);
        (uint256 _sharesAmount, uint256 _actualAsset) = _replayToVault(
            _amount,
            _accountBalance,
            _trackedAssets,
            _assetPrices,
            _assetDecimals
        );
        uint256 _actuallyReceivedAmount = 0;
        (_assets, _amounts, _actuallyReceivedAmount) = _calculateAndTransfer(
            _actualAsset,
            _trackedAssets,
            _assetPrices,
            _assetDecimals
        );
        if (_minimumAmount > 0) {
            require(_actuallyReceivedAmount >= _minimumAmount, "amount lower than minimum");
        }
        _burnRebaseAndEmit(
            _amount,
            _actuallyReceivedAmount,
            _sharesAmount,
            _assets,
            _amounts,
            _trackedAssets,
            _assetPrices,
            _assetDecimals
        );
    }

    /// @notice redeem the funds from specified strategy.
    function redeem(
        address _strategy,
        uint256 _amount,
        uint256 _outputCode
    ) external isKeeper isActiveStrategy(_strategy) nonReentrant {
        uint256 _strategyAssetValue = strategies[_strategy].totalDebt;
        require(_amount <= _strategyAssetValue);

        (address[] memory _assets, uint256[] memory _amounts) = IETHStrategy(_strategy).repay(
            _amount,
            _strategyAssetValue,
            _outputCode
        );
        if (adjustPositionPeriod) {
            uint256 _assetsLength = _assets.length;
            for (uint256 i = 0; i < _assetsLength; i++) {
                uint256 _amount = _amounts[i];
                if (_amount > 0) {
                    redeemAssetsMap[_assets[i]] += _amount;
                }
            }
        }
        uint256 _nowStrategyTotalDebt = strategies[_strategy].totalDebt;
        uint256 _thisWithdrawValue = (_nowStrategyTotalDebt * _amount) / _strategyAssetValue;
        strategies[_strategy].totalDebt = _nowStrategyTotalDebt - _thisWithdrawValue;
        totalDebt -= _thisWithdrawValue;

        emit Redeem(_strategy, _amount, _assets, _amounts);
    }

    /// @notice Allocate funds in Vault to strategies.
    function lend(address _strategy, IExchangeAggregator.ExchangeToken[] calldata _exchangeTokens)
        external
        isKeeper
        whenNotEmergency
        isActiveStrategy(_strategy)
        nonReentrant
    {
        (
            address[] memory _wants,
            uint256[] memory _ratios,
            uint256[] memory _toAmounts
        ) = _checkAndExchange(_strategy, _exchangeTokens);
        //Definition rule 0 means unconstrained, currencies that do not participate are not in the returned wants
        uint256 _minProductIndex = 0;
        bool _isWantRatioIgnorable = IETHStrategy(_strategy).isWantRatioIgnorable();
        if (!_isWantRatioIgnorable && _ratios.length > 1) {
            for (uint256 i = 1; i < _ratios.length; i++) {
                if (_ratios[i] == 0) {
                    //0 is free
                    continue;
                } else if (_ratios[_minProductIndex] == 0) {
                    //minProductIndex is assigned to the first index whose proportion is not 0
                    _minProductIndex = i;
                } else if (
                    _toAmounts[_minProductIndex] * _ratios[i] >
                    _toAmounts[i] * _ratios[_minProductIndex]
                ) {
                    _minProductIndex = i;
                }
            }
        }

        uint256 _minAmount = _toAmounts[_minProductIndex];
        uint256 _minAspect = _ratios[_minProductIndex];
        uint256 _lendValue;
        uint256 _ethAmount;
        for (uint256 i = 0; i < _toAmounts.length; i++) {
            uint256 _actualAmount = _toAmounts[i];
            if (_actualAmount > 0) {
                if (!_isWantRatioIgnorable && _ratios[i] > 0) {
                    _actualAmount = (_ratios[i] * _minAmount) / _minAspect;
                    _toAmounts[i] = _actualAmount;
                }
                if (_wants[i] == NativeToken.NATIVE_TOKEN) {
                    _lendValue += _actualAmount;
                    _ethAmount = _actualAmount;
                } else {
                    _lendValue += IPriceOracleConsumer(priceProvider).valueInEth(
                        _wants[i],
                        _actualAmount
                    );
                    IERC20Upgradeable(_wants[i]).safeTransfer(_strategy, _actualAmount);
                }
            }
        }
        IETHStrategy _ethStrategy = IETHStrategy(_strategy);
        if (_ethAmount > 0) {
            _ethStrategy.borrow{value: _ethAmount}(_wants, _toAmounts);
        } else {
            _ethStrategy.borrow(_wants, _toAmounts);
        }
        _report(_strategy, new address[](0), new uint256[](0), _lendValue);
        emit LendToStrategy(_strategy, _wants, _toAmounts, _lendValue);
    }

    function exchange(
        address _fromToken,
        address _toToken,
        uint256 _amount,
        IExchangeAggregator.ExchangeParam memory _exchangeParam
    ) external isKeeper nonReentrant returns (uint256) {
        return _exchange(_fromToken, _toToken, _amount, _exchangeParam);
    }

    /// @notice Change ETHi supply with Vault total assets.
    function rebase()
        external
        whenNotEmergency
        whenNotAdjustPosition
        whenNotRebasePaused
        nonReentrant
    {
        uint256 _totalAssets = _totalAssetInVault() + totalDebt;
        _rebase(_totalAssets);
    }

    /**
     * @dev Report the current asset of strategy caller
     * @param _rewardTokens The reward token list
     * @param _claimAmounts The claim amount list
     * Emits a {StrategyReported} event.
     */
    function report(address[] memory _rewardTokens, uint256[] memory _claimAmounts)
        external
        isActiveStrategy(msg.sender)
    {
        _report(msg.sender, _rewardTokens, _claimAmounts, 0);
    }

    /// @notice start  Adjust  Position
    function startAdjustPosition()
        external
        isKeeper
        whenNotAdjustPosition
        whenNotEmergency
        nonReentrant
    {
        adjustPositionPeriod = true;
        address[] memory _trackedAssets = _getTrackedAssets();

        (
            uint256[] memory _vaultAmounts,
            uint256[] memory _transferAmounts,
            bool _vaultBufferAboveZero
        ) = _calculateVault(_trackedAssets, true);
        uint256 _totalDebt = totalDebt;
        if (_vaultBufferAboveZero) {
            uint256 _trackedAssetsLength = _trackedAssets.length;
            uint256[] memory _assetPrices = new uint256[](_trackedAssetsLength);
            uint256[] memory _assetDecimals = new uint256[](_trackedAssetsLength);
            uint256 _totalValueInVault = 0;
            for (uint256 i = 0; i < _trackedAssetsLength; i++) {
                address _trackedAsset = _trackedAssets[i];
                uint256 _amount = _vaultAmounts[i];
                if (_amount > 0) {
                    _totalValueInVault =
                        _totalValueInVault +
                        _calculateAssetValue(
                            _assetPrices,
                            _assetDecimals,
                            i,
                            _trackedAsset,
                            _amount
                        );
                }
            }
            uint256 _totalAssets = _totalValueInVault + _totalDebt;
            uint256 _totalShares = IPegToken(pegTokenAddress).totalShares();
            if (!rebasePaused) {
                _rebase(_totalAssets, _totalShares);
            }
            IVaultBuffer(vaultBufferAddress).transferCashToVault(_trackedAssets, _transferAmounts);
        }
        uint256 _totalDebtOfBeforeAdjustPosition = _totalDebt;
        totalDebtOfBeforeAdjustPosition = _totalDebtOfBeforeAdjustPosition;
        emit StartAdjustPosition(
            _totalDebtOfBeforeAdjustPosition,
            _trackedAssets,
            _vaultAmounts,
            _transferAmounts
        );
    }

    /// @notice end  Adjust Position
    function endAdjustPosition() external isKeeper nonReentrant {
        require(adjustPositionPeriod, "AD OVER");
        address[] memory _trackedAssets = _getTrackedAssets();
        uint256 _trackedAssetsLength = _trackedAssets.length;
        uint256[] memory _assetPrices = new uint256[](_trackedAssetsLength);
        uint256[] memory _assetDecimals = new uint256[](_trackedAssetsLength);

        (uint256[] memory _vaultAmounts, , ) = _calculateVault(_trackedAssets, false);

        uint256 _transferValue = 0;
        uint256 _redeemValue = 0;
        uint256 _vaultValueOfNow = 0;
        uint256 _vaultValueOfBefore = 0;
        for (uint256 i = 0; i < _trackedAssetsLength; i++) {
            address _trackedAsset = _trackedAssets[i];
            _transferValue =
                _transferValue +
                _calculateAssetValue(
                    _assetPrices,
                    _assetDecimals,
                    i,
                    _trackedAsset,
                    transferFromVaultBufferAssetsMap[_trackedAsset]
                );
            _redeemValue =
                _redeemValue +
                _calculateAssetValue(
                    _assetPrices,
                    _assetDecimals,
                    i,
                    _trackedAsset,
                    redeemAssetsMap[_trackedAsset]
                );
            _vaultValueOfNow =
                _vaultValueOfNow +
                _calculateAssetValue(
                    _assetPrices,
                    _assetDecimals,
                    i,
                    _trackedAsset,
                    _vaultAmounts[i]
                );
            _vaultValueOfBefore =
                _vaultValueOfBefore +
                _calculateAssetValue(
                    _assetPrices,
                    _assetDecimals,
                    i,
                    _trackedAsset,
                    beforeAdjustPositionAssetsMap[_trackedAsset]
                );
        }

        uint256 _totalDebtOfBefore = totalDebtOfBeforeAdjustPosition;
        uint256 _totalDebtOfNow = totalDebt;

        uint256 _totalValueOfNow = _totalDebtOfNow + _vaultValueOfNow;
        uint256 _totalValueOfBefore = _totalDebtOfBefore + _vaultValueOfBefore;

        {
            uint256 _transferAssets = 0;
            uint256 _old2LendAssets = 0;
            if (_vaultValueOfNow + _transferValue < _vaultValueOfBefore) {
                _old2LendAssets = _vaultValueOfBefore - _vaultValueOfNow - _transferValue;
            }
            if (_redeemValue + _old2LendAssets > _totalValueOfBefore - _transferValue) {
                _redeemValue = _totalValueOfBefore - _transferValue - _old2LendAssets;
            }
            if (_totalValueOfNow > _totalValueOfBefore) {
                uint256 _gain = _totalValueOfNow - _totalValueOfBefore;
                if (_transferValue > 0) {
                    _transferAssets =
                        _transferValue +
                        (_gain * _transferValue) /
                        (_transferValue + _redeemValue + _old2LendAssets);
                }
            } else {
                uint256 _loss = _totalValueOfBefore - _totalValueOfNow;
                if (_transferValue > 0) {
                    _transferAssets =
                        _transferValue -
                        (_loss * _transferValue) /
                        (_transferValue + _redeemValue + _old2LendAssets);
                }
            }
            uint256 _totalShares = IPegToken(pegTokenAddress).totalShares();
            if (!rebasePaused && _totalShares > 0) {
                _totalShares = _rebase(_totalValueOfNow - _transferAssets, _totalShares);
            }
            if (_transferAssets > 0) {
                uint256 _sharesAmount = _calculateShare(
                    _transferAssets,
                    _totalValueOfNow - _transferAssets,
                    _totalShares
                );
                if (_sharesAmount > 0) {
                    IPegToken(pegTokenAddress).mintShares(vaultBufferAddress, _sharesAmount);
                }
            }
        }

        {
            totalDebtOfBeforeAdjustPosition = 0;
            for (uint256 i = 0; i < _trackedAssetsLength; i++) {
                address _trackedAsset = _trackedAssets[i];
                redeemAssetsMap[_trackedAsset] = 0;
                beforeAdjustPositionAssetsMap[_trackedAsset] = 0;
                transferFromVaultBufferAssetsMap[_trackedAsset] = 0;
            }
            if (!IVaultBuffer(vaultBufferAddress).isDistributing()) {
                IVaultBuffer(vaultBufferAddress).openDistribute();
            }
            adjustPositionPeriod = false;
        }

        emit EndAdjustPosition(
            _transferValue,
            _redeemValue,
            _totalDebtOfNow,
            _totalValueOfNow,
            _totalValueOfBefore
        );
    }

    function _calculateVault(address[] memory _trackedAssets, bool _dealVaultBuffer)
        internal
        returns (
            uint256[] memory,
            uint256[] memory,
            bool
        )
    {
        uint256 _trackedAssetsLength = _trackedAssets.length;
        uint256[] memory _transferAmounts = new uint256[](_trackedAssetsLength);
        uint256[] memory _vaultAmounts = new uint256[](_trackedAssetsLength);
        bool _vaultBufferAboveZero = false;
        for (uint256 i = 0; i < _trackedAssetsLength; i++) {
            address _trackedAsset = _trackedAssets[i];
            uint256 _balance = 0;
            if (_dealVaultBuffer && assetSet.contains(_trackedAsset)) {
                _balance = _balanceOfToken(_trackedAsset, vaultBufferAddress);
                if (_balance > 0) {
                    _transferAmounts[i] = _balance;
                    _vaultBufferAboveZero = true;
                    transferFromVaultBufferAssetsMap[_trackedAsset] = _balance;
                }
            }
            uint256 _vaultAmount = _balanceOfToken(_trackedAsset, address(this));
            if (_vaultAmount > 0) {
                _vaultAmounts[i] = _vaultAmount;
            }
            if (_dealVaultBuffer && _vaultAmount + _balance > 0) {
                beforeAdjustPositionAssetsMap[_trackedAsset] = _vaultAmount + _balance;
            }
        }
        return (_vaultAmounts, _transferAmounts, _vaultBufferAboveZero);
    }

    /// @notice Assets held by Vault
    function _getTrackedAssets() internal view returns (address[] memory) {
        return trackedAssetsMap._inner._keys.values();
    }

    /**
     * @dev Internal to calculate total value of all assets held in Vault.
     * @return Total value in ETH (1e18)
     */
    function _totalAssetInVault() internal view returns (uint256) {
        address[] memory _trackedAssets = _getTrackedAssets();
        uint256 _trackedAssetsLength = _trackedAssets.length;
        uint256[] memory _assetPrices = new uint256[](_trackedAssetsLength);
        uint256[] memory _assetDecimals = new uint256[](_trackedAssetsLength);
        uint256 _totalAssetInVault = _totalAssetInVault(
            _trackedAssets,
            _assetPrices,
            _assetDecimals
        );
        return _totalAssetInVault;
    }

    function _totalAssetInVault(
        address[] memory _trackedAssets,
        uint256[] memory _assetPrices,
        uint256[] memory _assetDecimals
    ) internal view returns (uint256) {
        return _totalAssetInOwner(_trackedAssets, _assetPrices, _assetDecimals, address(this));
    }

    function _totalAssetInVaultAndVaultBuffer() internal view returns (uint256) {
        address[] memory _trackedAssets = _getTrackedAssets();
        uint256 _trackedAssetsLength = _trackedAssets.length;
        uint256[] memory _assetPrices = new uint256[](_trackedAssetsLength);
        uint256[] memory _assetDecimals = new uint256[](_trackedAssetsLength);
        uint256 _totalAssetInVault = _totalAssetInOwner(
            _trackedAssets,
            _assetPrices,
            _assetDecimals,
            address(this)
        );
        uint256 _totalAssetInVaultBuffer = _totalAssetInOwner(
            _trackedAssets,
            _assetPrices,
            _assetDecimals,
            vaultBufferAddress
        );
        return _totalAssetInVault + _totalAssetInVaultBuffer;
    }

    function _estimateMint(address _asset, uint256 _amount) private view returns (uint256) {
        require(_amount > 0, "Amount must be gt 0");
        require(!(IVaultBuffer(vaultBufferAddress).isDistributing()), "is distributing");
        checkIsSupportAsset(_asset);
        uint256 _mintAmount = _amount;
        if (_asset != NativeToken.NATIVE_TOKEN) {
            _mintAmount = IPriceOracleConsumer(priceProvider).valueInEth(_asset, _amount);
        }
        uint256 _minimumInvestmentAmount = minimumInvestmentAmount;
        if (_minimumInvestmentAmount > 0) {
            require(
                _mintAmount >= _minimumInvestmentAmount,
                "Amount must be gt minimum Investment Amount"
            );
        }
        return _mintAmount;
    }

    /// @notice withdraw from strategy queue
    function _repayFromWithdrawQueue(uint256 _needWithdrawValue) internal {
        uint256 _totalWithdrawValue;
        for (uint256 i = 0; i < withdrawQueue.length; i++) {
            address _strategy = withdrawQueue[i];
            if (_strategy == ZERO_ADDRESS) break;

            uint256 _strategyTotalValue = strategies[_strategy].totalDebt;
            if (_strategyTotalValue <= 0) {
                continue;
            }

            uint256 _strategyWithdrawValue;
            if (_needWithdrawValue > _strategyTotalValue) {
                _strategyWithdrawValue = _strategyTotalValue;
                _needWithdrawValue -= _strategyWithdrawValue;
            } else {
                //If there is less than 0.001 ETH left, then all redemption
                if (_needWithdrawValue + 1e15 >= _strategyTotalValue) {
                    _strategyWithdrawValue = _strategyTotalValue;
                } else {
                    _strategyWithdrawValue = _needWithdrawValue;
                }
                _needWithdrawValue = 0;
            }
            (address[] memory _assets, uint256[] memory _amounts) = IETHStrategy(_strategy).repay(
                _strategyWithdrawValue,
                _strategyTotalValue,
                0
            );
            emit RepayFromStrategy(
                _strategy,
                _strategyWithdrawValue,
                _strategyTotalValue,
                _assets,
                _amounts
            );

            uint256 _nowStrategyTotalDebt = strategies[_strategy].totalDebt;
            uint256 _thisWithdrawValue = (_nowStrategyTotalDebt * _strategyWithdrawValue) /
                _strategyTotalValue;
            strategies[_strategy].totalDebt = _nowStrategyTotalDebt - _thisWithdrawValue;
            _totalWithdrawValue += _thisWithdrawValue;

            if (_needWithdrawValue <= 0) {
                break;
            }
        }
        totalDebt -= _totalWithdrawValue;
    }

    /// @notice withdraw from vault buffer
    function _repayFromVaultBuffer(
        uint256 _needTransferValue,
        address[] memory _trackedAssets,
        uint256[] memory _assetPrices,
        uint256[] memory _assetDecimals,
        uint256 _totalAssets,
        uint256 _totalShares
    ) internal returns (uint256) {
        address[] memory _transferAssets = _trackedAssets;
        uint256 _transferAssetsLength = _transferAssets.length;
        uint256[] memory _amounts = new uint256[](_transferAssetsLength);
        uint256 _totalTransferValue;
        //price in vault
        for (uint256 i = 0; i < _transferAssetsLength; i++) {
            address _trackedAsset = _transferAssets[i];
            if (assetSet.contains(_trackedAsset)) {
                uint256 _assetBalancesInVaultBuffer = _balanceOfToken(
                    _trackedAsset,
                    vaultBufferAddress
                );
                if (_assetBalancesInVaultBuffer > 0) {
                    uint256 _value = _calculateAssetValue(
                        _assetPrices,
                        _assetDecimals,
                        i,
                        _trackedAsset,
                        _assetBalancesInVaultBuffer
                    );

                    if (_needTransferValue > _value) {
                        _totalTransferValue = _totalTransferValue + _value;
                        _needTransferValue = _needTransferValue - _value;
                        _amounts[i] = _assetBalancesInVaultBuffer;
                    } else {
                        _totalTransferValue = _totalTransferValue + _needTransferValue;
                        _amounts[i] = (_assetBalancesInVaultBuffer * _needTransferValue) / _value;
                        _needTransferValue = 0;
                        break;
                    }
                }
            }
        }
        if (_totalTransferValue > 0) {
            IVaultBuffer(vaultBufferAddress).transferCashToVault(_transferAssets, _amounts);

            uint256 _totalTransferShares = _calculateShare(
                _totalTransferValue,
                _totalAssets,
                _totalShares
            );
            IPegToken(pegTokenAddress).mintShares(vaultBufferAddress, _totalTransferShares);

            emit PegTokenSwapCash(_totalTransferValue, _transferAssets, _amounts);
        }
        return _totalTransferValue;
    }

    function _calculateShare(
        uint256 _amount,
        uint256 _totalAssets,
        uint256 _totalShares
    ) internal view returns (uint256) {
        uint256 _shareAmount = 0;
        if (_totalAssets > 0 && _totalShares > 0) {
            _shareAmount = (_amount * _totalShares) / _totalAssets;
        }
        if (_shareAmount == 0) {
            uint256 _underlyingUnitsPerShare = underlyingUnitsPerShare;
            if (_underlyingUnitsPerShare > 0) {
                _shareAmount = _amount.divPreciselyScale(_underlyingUnitsPerShare, 1e27);
            } else {
                _shareAmount = _amount * 1e9;
            }
        }
        return _shareAmount;
    }

    /// @notice calculate need transfer amount from vault ,set to outputs
    function _calculateOutputs(
        uint256 _needTransferAmount,
        address[] memory _trackedAssets,
        uint256[] memory _assetPrices,
        uint256[] memory _assetDecimals
    ) internal view returns (uint256[] memory) {
        uint256 _trackedAssetsLength = _trackedAssets.length;
        uint256[] memory _outputs = new uint256[](_trackedAssetsLength);

        for (uint256 i = 0; i < _trackedAssetsLength; i++) {
            address _trackedAsset = _trackedAssets[i];
            uint256 _balance = _balanceOfToken(_trackedAsset, address(this));
            if (_balance > 0) {
                uint256 _value = _calculateAssetValue(
                    _assetPrices,
                    _assetDecimals,
                    i,
                    _trackedAsset,
                    _balance
                );
                if (_value >= _needTransferAmount) {
                    _outputs[i] = (_balance * _needTransferAmount) / _value;
                    break;
                } else {
                    _outputs[i] = _balance;
                    _needTransferAmount = _needTransferAmount - _value;
                }
            }
        }
        return _outputs;
    }

    /// @notice calculate Asset value in eth by oracle price
    /// @param _assetPrices array of asset price
    /// @param _assetDecimals array of asset decimal
    /// @param _assetIndex index of the asset in trackedAssets array
    /// @param _trackedAsset address of the asset
    /// @return shareAmount
    function _calculateAssetValue(
        uint256[] memory _assetPrices,
        uint256[] memory _assetDecimals,
        uint256 _assetIndex,
        address _trackedAsset,
        uint256 _balance
    ) private view returns (uint256) {
        uint256 _assetPrice = _getAssetPrice(_assetPrices, _assetIndex, _trackedAsset);
        uint256 _assetDecimal = _getAssetDecimals(_assetDecimals, _assetIndex, _trackedAsset);

        uint256 _value = _balance.mulTruncateScale(_assetPrice, 10**_assetDecimal);
        return _value;
    }

    // @notice without exchange token and transfer form vault to user
    function _transfer(
        uint256[] memory _outputs,
        address[] memory _trackedAssets,
        uint256[] memory _assetPrices,
        uint256[] memory _assetDecimals
    ) internal returns (uint256) {
        uint256 _actualAmount;
        uint256 _trackedAssetsLength = _trackedAssets.length;
        for (uint256 i = 0; i < _trackedAssetsLength; i++) {
            uint256 _amount = _outputs[i];
            if (_amount > 0) {
                address _trackedAsset = _trackedAssets[i];
                if (_trackedAsset == NativeToken.NATIVE_TOKEN) {
                    _actualAmount = _actualAmount + _amount;
                    payable(msg.sender).transfer(_amount);
                } else {
                    _actualAmount =
                        _actualAmount +
                        _calculateAssetValue(
                            _assetPrices,
                            _assetDecimals,
                            i,
                            _trackedAsset,
                            _amount
                        );
                    IERC20Upgradeable(_trackedAsset).safeTransfer(msg.sender, _amount);
                }
            }
        }
        return _actualAmount;
    }

    function _replayToVault(
        uint256 _amount,
        uint256 _accountBalance,
        address[] memory _trackedAssets,
        uint256[] memory _assetPrices,
        uint256[] memory _assetDecimals
    ) internal returns (uint256 _sharesAmount, uint256 _actualAsset) {
        uint256 _totalAssetInVault = _totalAssetInVault(
            _trackedAssets,
            _assetPrices,
            _assetDecimals
        );
        uint256 _actualAmount = _amount;
        uint256 _currentTotalAssets = _totalAssetInVault + totalDebt;
        uint256 _currentTotalShares = IPegToken(pegTokenAddress).totalShares();
        {
            uint256 _underlyingUnitsPerShare = underlyingUnitsPerShare;
            if (_accountBalance == _actualAmount) {
                _sharesAmount = IPegToken(pegTokenAddress).sharesOf(msg.sender);
            } else {
                _sharesAmount = _actualAmount.divPreciselyScale(_underlyingUnitsPerShare, 1e27);
            }
            // Calculate redeem fee
            if (redeemFeeBps > 0) {
                _actualAmount = _actualAmount - (_actualAmount * redeemFeeBps) / MAX_BPS;
            }
            uint256 _currentTotalSupply = _currentTotalShares.mulTruncateScale(
                _underlyingUnitsPerShare,
                1e27
            );
            _actualAsset = (_actualAmount * _currentTotalAssets) / _currentTotalSupply;
        }

        // vault not enough,withdraw from vault buffer
        if (_totalAssetInVault < _actualAsset) {
            _totalAssetInVault =
                _totalAssetInVault +
                _repayFromVaultBuffer(
                    _actualAsset - _totalAssetInVault,
                    _trackedAssets,
                    _assetPrices,
                    _assetDecimals,
                    _currentTotalAssets,
                    _currentTotalShares
                );
        }

        // vault not enough,withdraw from withdraw queue strategy
        if (_totalAssetInVault < _actualAsset) {
            _repayFromWithdrawQueue(_actualAsset - _totalAssetInVault);
        }
    }

    function _calculateAndTransfer(
        uint256 _actualAsset,
        address[] memory _trackedAssets,
        uint256[] memory _assetPrices,
        uint256[] memory _assetDecimals
    )
        internal
        returns (
            address[] memory,
            uint256[] memory,
            uint256
        )
    {
        // calculate need transfer amount from vault ,set to outputs
        uint256[] memory _outputs = _calculateOutputs(
            _actualAsset,
            _trackedAssets,
            _assetPrices,
            _assetDecimals
        );

        uint256 _actuallyReceivedAmount = _transfer(
            _outputs,
            _trackedAssets,
            _assetPrices,
            _assetDecimals
        );
        return (_trackedAssets, _outputs, _actuallyReceivedAmount);
    }

    // @notice burn ETHi and check rebase
    function _burnRebaseAndEmit(
        uint256 _amount,
        uint256 _actualAmount,
        uint256 _shareAmount,
        address[] memory _assets,
        uint256[] memory _amounts,
        address[] memory _trackedAssets,
        uint256[] memory _assetPrices,
        uint256[] memory _assetDecimals
    ) internal {
        IPegToken(pegTokenAddress).burnShares(msg.sender, _shareAmount);

        // Until we can prove that we won't affect the prices of our assets
        // by withdrawing them, this should be here.
        // It's possible that a strategy was off on its asset total, perhaps
        // a reward token sold for more or for less than anticipated.
        if (!rebasePaused) {
            uint256 _totalAssetInVault = _totalAssetInVault(
                _trackedAssets,
                _assetPrices,
                _assetDecimals
            );
            _rebase(_totalAssetInVault + totalDebt);
        }
        emit Burn(msg.sender, _amount, _actualAmount, _shareAmount, _assets, _amounts);
    }

    /**
     * @dev Calculate the total value of assets held by the Vault and all
     *      strategies and update the supply of ETHi, optionally sending a
     *      portion of the yield to the trustee.
     */
    function _rebase(uint256 _totalAssets) internal {
        uint256 _totalShares = IPegToken(pegTokenAddress).totalShares();
        _rebase(_totalAssets, _totalShares);
    }

    function _rebase(uint256 _totalAssets, uint256 _totalShares) internal returns (uint256) {
        if (_totalShares == 0) {
            return _totalShares;
        }

        uint256 _underlyingUnitsPerShare = underlyingUnitsPerShare;
        uint256 _totalSupply = _totalShares.mulTruncateScale(_underlyingUnitsPerShare, 1e27);

        // Final check should use latest value
        if (
            _totalAssets > _totalSupply &&
            (_totalAssets - _totalSupply) * TEN_MILLION_BPS > _totalSupply * rebaseThreshold
        ) {
            // Yield fee collection
            address _treasuryAddress = treasury;
            uint256 _trusteeFeeBps = trusteeFeeBps;
            if (_trusteeFeeBps > 0 && _treasuryAddress != address(0)) {
                uint256 _yield = _totalAssets - _totalSupply;
                uint256 _fee = (_yield * _trusteeFeeBps) / MAX_BPS;
                require(_yield > _fee, "Fee must not be greater than yield");
                if (_fee > 0) {
                    uint256 _sharesAmount = (_fee * _totalShares) / (_totalAssets - _fee);
                    if (_sharesAmount > 0) {
                        IPegToken(pegTokenAddress).mintShares(_treasuryAddress, _sharesAmount);
                        _totalShares = _totalShares + _sharesAmount;
                    }
                }
            }
            uint256 _newUnderlyingUnitsPerShare = _totalAssets.divPreciselyScale(
                _totalShares,
                1e27
            );
            if (_newUnderlyingUnitsPerShare != _underlyingUnitsPerShare) {
                underlyingUnitsPerShare = _newUnderlyingUnitsPerShare;
                emit Rebase(_totalShares, _totalAssets, _newUnderlyingUnitsPerShare);
            }
        }
        return _totalShares;
    }

    /// @notice check valid and exchange to want token
    function _checkAndExchange(
        address _strategy,
        IExchangeAggregator.ExchangeToken[] calldata _exchangeTokens
    )
        internal
        returns (
            address[] memory _wants,
            uint256[] memory _ratios,
            uint256[] memory toAmounts
        )
    {
        (_wants, _ratios) = IETHStrategy(_strategy).getWantsInfo();
        uint256 _wantsLength = _wants.length;
        toAmounts = new uint256[](_wantsLength);
        uint256 _exchangeTokensLength = _exchangeTokens.length;
        for (uint256 i = 0; i < _exchangeTokensLength; i++) {
            bool _findToToken = false;
            for (uint256 j = 0; j < _wantsLength; j++) {
                if (_exchangeTokens[i].toToken == _wants[j]) {
                    _findToToken = true;
                    break;
                }
            }
            require(_findToToken, "toToken invalid");
        }

        for (uint256 j = 0; j < _wantsLength; j++) {
            for (uint256 i = 0; i < _exchangeTokensLength; i++) {
                IExchangeAggregator.ExchangeToken memory _exchangeToken = _exchangeTokens[i];

                // not strategy need token,skip
                if (_wants[j] != _exchangeToken.toToken) continue;

                uint256 _toAmount;
                if (_exchangeToken.fromToken == _exchangeToken.toToken) {
                    _toAmount = _exchangeToken.fromAmount;
                } else {
                    if (_exchangeToken.fromAmount > 0) {
                        _toAmount = _exchange(
                            _exchangeToken.fromToken,
                            _exchangeToken.toToken,
                            _exchangeToken.fromAmount,
                            _exchangeToken.exchangeParam
                        );
                    }
                }

                toAmounts[j] = _toAmount;
                break;
            }
        }
    }

    function _exchange(
        address _fromToken,
        address _toToken,
        uint256 _amount,
        IExchangeAggregator.ExchangeParam memory _exchangeParam
    ) internal returns (uint256 _exchangeAmount) {
        require(trackedAssetsMap.contains(_toToken), "!T");

        IExchangeAdapter.SwapDescription memory _swapDescription = IExchangeAdapter
            .SwapDescription({
                amount: _amount,
                srcToken: _fromToken,
                dstToken: _toToken,
                receiver: address(this)
            });
        if (_fromToken == NativeToken.NATIVE_TOKEN) {
            // payable(exchangeManager).transfer(_amount);
            _exchangeAmount = IExchangeAggregator(exchangeManager).swap{value: _amount}(
                _exchangeParam.platform,
                _exchangeParam.method,
                _exchangeParam.encodeExchangeArgs,
                _swapDescription
            );
        } else {
            IERC20Upgradeable(_fromToken).safeApprove(exchangeManager, 0);
            IERC20Upgradeable(_fromToken).safeApprove(exchangeManager, _amount);
            _exchangeAmount = IExchangeAggregator(exchangeManager).swap(
                _exchangeParam.platform,
                _exchangeParam.method,
                _exchangeParam.encodeExchangeArgs,
                _swapDescription
            );
        }

        uint256 _oracleExpectedAmount = IPriceOracleConsumer(priceProvider).valueInTargetToken(
            _fromToken,
            _amount,
            _toToken
        );
        require(
            _exchangeAmount >=
                (_oracleExpectedAmount *
                    (MAX_BPS -
                        _exchangeParam.slippage -
                        _exchangeParam.oracleAdditionalSlippage)) /
                    MAX_BPS,
            "OL"
        );
        emit Exchange(_exchangeParam.platform, _fromToken, _amount, _toToken, _exchangeAmount);
    }

    function _report(
        address _strategy,
        address[] memory _rewardTokens,
        uint256[] memory _claimAmounts,
        uint256 _lendValue
    ) private {
        StrategyParams memory _strategyParam = strategies[_strategy];
        uint256 _lastStrategyTotalDebt = _strategyParam.totalDebt + _lendValue;
        uint256 _nowStrategyTotalDebt = IETHStrategy(_strategy).estimatedTotalAssets();
        uint256 _gain = 0;
        uint256 _loss = 0;

        if (_nowStrategyTotalDebt > _lastStrategyTotalDebt) {
            _gain = _nowStrategyTotalDebt - _lastStrategyTotalDebt;
        } else if (_nowStrategyTotalDebt < _lastStrategyTotalDebt) {
            _loss = _lastStrategyTotalDebt - _nowStrategyTotalDebt;
        }

        if (_strategyParam.enforceChangeLimit) {
            if (
                block.timestamp - strategies[_strategy].lastReport <
                maxTimestampBetweenTwoReported &&
                (_lastStrategyTotalDebt > minCheckedStrategyTotalDebt ||
                    _nowStrategyTotalDebt > minCheckedStrategyTotalDebt)
            ) {
                if (_gain > 0) {
                    require(
                        _gain <=
                            ((_lastStrategyTotalDebt * _strategyParam.profitLimitRatio) / MAX_BPS),
                        "GL"
                    );
                } else if (_loss > 0) {
                    require(
                        _loss <=
                            ((_lastStrategyTotalDebt * _strategyParam.lossLimitRatio) / MAX_BPS),
                        "LL"
                    );
                }
            }
        } else {
            strategies[_strategy].enforceChangeLimit = true;
            // The check is turned off only once and turned back on.
        }
        strategies[_strategy].totalDebt = _nowStrategyTotalDebt;
        totalDebt = totalDebt + _nowStrategyTotalDebt + _lendValue - _lastStrategyTotalDebt;

        strategies[_strategy].lastReport = block.timestamp;
        uint256 _type = 0;
        if (_lendValue > 0) {
            _type = 1;
        }
        emit StrategyReported(
            _strategy,
            _gain,
            _loss,
            _lastStrategyTotalDebt,
            _nowStrategyTotalDebt,
            _rewardTokens,
            _claimAmounts,
            _type
        );
    }

    function _balanceOfToken(address _trackedAsset, address _owner)
        internal
        view
        returns (uint256)
    {
        uint256 _balance;
        if (_trackedAsset == NativeToken.NATIVE_TOKEN) {
            _balance = _owner.balance;
        } else {
            _balance = IERC20Upgradeable(_trackedAsset).balanceOf(_owner);
        }
        return _balance;
    }

    /**
     * @notice Get the supported asset Decimal
     * @return _assetDecimal asset Decimals
     */
    function _getAssetDecimals(
        uint256[] memory _assetDecimals,
        uint256 _assetIndex,
        address _asset
    ) internal view returns (uint256) {
        uint256 _decimal = _assetDecimals[_assetIndex];
        if (_decimal == 0) {
            if (_asset == NativeToken.NATIVE_TOKEN) {
                _decimal = 18;
            } else {
                _decimal = IERC20Metadata(_asset).decimals();
            }
            _assetDecimals[_assetIndex] = _decimal;
        }
        return _decimal;
    }

    /**
     * @notice Get an array of the supported asset prices in USD
     * @return  prices in USD (1e18)
     */
    function _getAssetPrice(
        uint256[] memory _assetPrices,
        uint256 _assetIndex,
        address _asset
    ) internal view returns (uint256) {
        uint256 _price = _assetPrices[_assetIndex];
        if (_price == 0) {
            if (_asset == NativeToken.NATIVE_TOKEN) {
                _price = 1e18;
            } else {
                _price = IPriceOracleConsumer(priceProvider).priceInEth(_asset);
            }
            _assetPrices[_assetIndex] = _price;
        }
        return _price;
    }

    function _totalAssetInOwner(
        address[] memory _trackedAssets,
        uint256[] memory _assetPrices,
        uint256[] memory _assetDecimals,
        address _owner
    ) internal view returns (uint256) {
        uint256 _totalAssetInOwne;
        uint256 _trackedAssetsLength = _trackedAssets.length;
        for (uint256 i = 0; i < _trackedAssetsLength; i++) {
            address _trackedAsset = _trackedAssets[i];
            uint256 _balance = _balanceOfToken(_trackedAsset, _owner);
            if (_balance > 0) {
                _totalAssetInOwne =
                    _totalAssetInOwne +
                    _calculateAssetValue(_assetPrices, _assetDecimals, i, _trackedAsset, _balance);
            }
        }
        return _totalAssetInOwne;
    }

    /// @notice Vault total asset in ETH(1e18)
    function _getTotalAssets() private view returns (uint256) {
        return _totalAssetInVault() + totalDebt;
    }

    /**
     * @notice Send funds to the pool
     * @dev Users are able to submit their funds by transacting to the fallback function.
     * Unlike vanilla Eth2.0 Deposit contract, accepting only 32-Ether transactions, Lido
     * accepts payments of any size. Submitted Ethers are stored in Buffer until someone calls
     * depositBufferedEther() and pushes them to the ETH2 Deposit contract.
     */
    receive() external payable {}

    /**
     * @dev Falldown to the admin implementation
     * @notice This is a catch all for all functions not declared in core
     */
    fallback() external payable {
        bytes32 slot = ADMIN_IMPL_POSITION;

        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), sload(slot), 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;
import "boc-contract-core/contracts/access-control/AccessControlMixin.sol";
import "boc-contract-core/contracts/library/IterableIntMap.sol";
import "boc-contract-core/contracts/library/StableMath.sol";
import "boc-contract-core/contracts/token/IPegToken.sol";
import "boc-contract-core/contracts/vault/IVaultBuffer.sol";
import "boc-contract-core/contracts/library/BocRoles.sol";
import "../strategies/IETHStrategy.sol";
import "boc-contract-core/contracts/library/NativeToken.sol";
import "boc-contract-core/contracts/exchanges/IExchangeAggregator.sol";
import "../oracle/IPriceOracleConsumer.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract ETHVaultStorage is Initializable, ReentrancyGuardUpgradeable, AccessControlMixin {
    using StableMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    using IterableIntMap for IterableIntMap.AddressToIntMap;

    struct StrategyParams {
        //last report timestamp
        uint256 lastReport;
        //total asset
        uint256 totalDebt;
        uint256 profitLimitRatio;
        uint256 lossLimitRatio;
        bool enforceChangeLimit;
    }

    struct StrategyAdd {
        address strategy;
        uint256 profitLimitRatio;
        uint256 lossLimitRatio;
    }

    event AddAsset(address _asset);
    event RemoveAsset(address _asset);
    event AddStrategies(address[] _strategies);
    event RemoveStrategies(address[] _strategies);
    event RemoveStrategyByForce(address _strategy);

    event Mint(address _account, address _asset, uint256 _amount, uint256 _mintAmount);
    event Burn(
        address _account,
        uint256 _amount,
        uint256 _actualAmount,
        uint256 _shareAmount,
        address[] _assets,
        uint256[] _amounts
    );
    event Exchange(
        address _platform,
        address _srcAsset,
        uint256 _srcAmount,
        address _distAsset,
        uint256 _distAmount
    );
    event Redeem(
        address _strategy,
        uint256 _debtChangeAmount,
        address[] _assets,
        uint256[] _amounts
    );
    event LendToStrategy(
        address indexed _strategy,
        address[] _wants,
        uint256[] _amounts,
        uint256 _lendValue
    );
    event RepayFromStrategy(
        address indexed _strategy,
        uint256 _strategyWithdrawValue,
        uint256 _strategyTotalValue,
        address[] _assets,
        uint256[] _amounts
    );
    event StrategyReported(
        address indexed _strategy,
        uint256 _gain,
        uint256 _loss,
        uint256 _lastStrategyTotalDebt,
        uint256 _nowStrategyTotalDebt,
        address[] _rewardTokens,
        uint256[] _claimAmounts,
        uint256 _type
    );
    event RemoveStrategyFromQueue(address[] _strategies);
    event SetEmergencyShutdown(bool _shutdown);
    event RebasePaused();
    event RebaseUnpaused();
    event RebaseThresholdUpdated(uint256 _threshold);
    event TrusteeFeeBpsChanged(uint256 _basis);
    event MaxTimestampBetweenTwoReportedChanged(uint256 _maxTimestampBetweenTwoReported);
    event MinCheckedStrategyTotalDebtChanged(uint256 _minCheckedStrategyTotalDebt);
    event MinimumInvestmentAmountChanged(uint256 _minimumInvestmentAmount);
    event TreasuryAddressChanged(address _address);
    event ExchangeManagerAddressChanged(address _address);
    event SetAdjustPositionPeriod(bool _adjustPositionPeriod);
    event RedeemFeeUpdated(uint256 _redeemFeeBps);
    event SetWithdrawalQueue(address[] _queues);
    event Rebase(uint256 _totalShares, uint256 _totalValue, uint256 _newUnderlyingUnitsPerShare);
    event StartAdjustPosition(
        uint256 _totalDebtOfBeforeAdjustPosition,
        address[] _trackedAssets,
        uint256[] _vaultCashDetatil,
        uint256[] _vaultBufferCashDetail
    );
    event EndAdjustPosition(
        uint256 _transferValue,
        uint256 _redeemValue,
        uint256 _totalDebt,
        uint256 _totalValueOfAfterAdjustPosition,
        uint256 _totalValueOfBeforeAdjustPosition
    );
    event PegTokenSwapCash(uint256 _pegTokenAmount, address[] _assets, uint256[] _amounts);

    address internal constant ZERO_ADDRESS = address(0);

    //max percentage 100%
    uint256 internal constant MAX_BPS = 10000;

    // all strategy
    EnumerableSet.AddressSet internal strategySet;
    // Assets supported by the Vault, i.e. Stablecoins
    EnumerableSet.AddressSet internal assetSet;
    // Assets held by Vault
    IterableIntMap.AddressToIntMap internal trackedAssetsMap;

    //adjust Position Period
    bool public adjustPositionPeriod;

    // emergency shutdown
    bool public emergencyShutdown;

    // Amount of yield collected in basis points
    uint256 public trusteeFeeBps;
    // Redemption fee in basis points
    uint256 public redeemFeeBps;
    //all strategy asset
    uint256 public totalDebt;
    // treasury contract that can collect a percentage of yield
    address public treasury;
    // Address of the Oracle price provider contract
    address public priceProvider;
    //exchangeManager
    address public exchangeManager;
    // strategy info
    mapping(address => StrategyParams) public strategies;

    //withdraw strategy set
    address[] public withdrawQueue;
    //keccak256("ETHi.vault.governor.admin.impl");
    bytes32 internal constant ADMIN_IMPL_POSITION =
        0xfa89c25d41afc3612e6438675f8ecd0190711981b04c08aa14be180784e299e7;

    // Pausing bools
    bool public rebasePaused;
    // over this difference ratio automatically rebase. rebaseThreshold is the numerator and the denominator is 10000000 x/10000000.
    uint256 public rebaseThreshold;

    //vault Buffer Address
    address public vaultBufferAddress;
    // ethi PegToken address
    address public pegTokenAddress;
    // Assets held in Vault from vault buffer
    mapping(address => uint256) internal transferFromVaultBufferAssetsMap;
    // redeem Assets where ad
    mapping(address => uint256) internal redeemAssetsMap;
    // Assets held in Vault and buffer before Adjust Position
    mapping(address => uint256) internal beforeAdjustPositionAssetsMap;
    // totalDebt before Adjust Position
    uint256 internal totalDebtOfBeforeAdjustPosition;
    // totalAsset/totalShare
    uint256 public underlyingUnitsPerShare;
    //Maximum timestamp between two reported
    uint256 public maxTimestampBetweenTwoReported;
    //Minimum strategy total debt that will be checked for the strategy reporting
    uint256 public minCheckedStrategyTotalDebt;
    //Minimum investment amount
    uint256 public minimumInvestmentAmount;

    //max percentage 10000000/10000000
    uint256 internal constant TEN_MILLION_BPS = 10000000;

    /**
     * @dev set the implementation for the admin, this needs to be in a base class else we cannot set it
     * @param _newImpl address of the implementation
     */
    function setAdminImpl(address _newImpl) external onlyGovOrDelegate {
        require(AddressUpgradeable.isContract(_newImpl), "new implementation is not a contract");
        bytes32 _position = ADMIN_IMPL_POSITION;
        assembly {
            sstore(_position, _newImpl)
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

interface IETHStrategy {
    event Borrow(address[] _assets, uint256[] _amounts);
    event Repay(
        uint256 _withdrawShares,
        uint256 _totalShares,
        address[] _assets,
        uint256[] _amounts
    );
    event SetIsWantRatioIgnorable(bool _oldValue, bool _newValue);

    /// @notice Version of strategy
    function getVersion() external pure returns (string memory);

    /// @notice Name of strategy
    function name() external pure returns (string memory);

    /// @notice ID of protocol, it marks which third protocol does this strategy belong to
    function protocol() external pure returns (uint16);

    /// @notice Vault address
    function vault() external view returns (address);

    /// @notice Provide the strategy need underlying token and ratio
    function getWantsInfo()
        external
        view
        returns (address[] memory _assets, uint256[] memory _ratios);

    /// @notice Provide the strategy need underlying token
    function getWants() external view returns (address[] memory _wants);

    /// @notice Returns the position details or ETH value of the strategy.
    function getPositionDetail()
        external
        view
        returns (
            address[] memory _tokens,
            uint256[] memory _amounts,
            bool _isETH,
            uint256 _ethValue
        );

    /// @notice Total assets of strategy in ETH.
    function estimatedTotalAssets() external view returns (uint256);

    /// @notice 3rd protocol's pool total assets in ETH.
    function get3rdPoolAssets() external view returns (uint256);

    /// @notice Harvests the Strategy, recognizing any profits or losses and adjusting the Strategy's position.
    function harvest() external returns (address[] memory _rewardsTokens, uint256[] memory _claimAmounts);

    /// @notice Strategy borrow funds from vault, enable payable because it needs to receive ETH from vault
    /// @param _assets borrow token address
    /// @param _amounts borrow token amount
    function borrow(address[] memory _assets, uint256[] memory _amounts) external payable;

    /// @notice Strategy repay the funds to vault
    /// @param _withdrawShares Numerator
    /// @param _totalShares Denominator
    function repay(
        uint256 _withdrawShares,
        uint256 _totalShares,
        uint256 _ouputCode
    ) external returns (address[] memory _assets, uint256[] memory _amounts);

    /// @notice getter isWantRatioIgnorable
    function isWantRatioIgnorable() external view returns (bool);
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

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.6.0 <0.9.0;

import "./IAccessControlProxy.sol";

abstract contract AccessControlMixin {
    IAccessControlProxy public accessControlProxy;

    function _initAccessControl(address _accessControlProxy) internal {
        accessControlProxy = IAccessControlProxy(_accessControlProxy);
    }

    modifier hasRole(bytes32 _role, address _account) {
        accessControlProxy.checkRole(_role, _account);
        _;
    }

    modifier onlyRole(bytes32 _role) {
        accessControlProxy.checkRole(_role, msg.sender);
        _;
    }

    modifier onlyGovOrDelegate() {
        accessControlProxy.checkGovOrDelegate(msg.sender);
        _;
    }

    modifier isVaultManager() {
        accessControlProxy.checkVaultOrGov(msg.sender);
        _;
    }

    modifier isKeeper() {
        accessControlProxy.checkKeeperOrVaultOrGov(msg.sender);
        _;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

library IterableIntMap {

    using EnumerableSet for EnumerableSet.AddressSet;

    struct Map {
        // Storage of keys
        EnumerableSet.AddressSet _keys;

        mapping (address => int256) _values;
    }

    /**
    * @dev Adds a key-value pair to a map, or updates the value for an existing
    * key. O(1).
    *
    * Returns true if the key was added to the map, that is if it was not
    * already present.
    */
    function _set(Map storage map, address key, int256 value) private returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
    * @dev plus a key‘s value pair in a map
    * key. O(1).
    *
    * Returns true if the key was added to the map, that is if it was not
    * already present.
    */
    function _plus(Map storage map, address key, int256 value) private {
        map._values[key] += value;
        map._keys.add(key);
    }

    /**
    * @dev minus a key‘s value pair in a map
    * key. O(1).
    *
    * Returns true if the key was added to the map, that is if it was not
    * already present.
    */
    function _minus(Map storage map, address key, int256 value) private {
        map._values[key] -= value;
        map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, address key) private returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, address key) private view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._keys.length();
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Map storage map, uint256 index) private view returns (address, int256) {
        address key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, address key) private view returns (int256) {
        int256 value = map._values[key];
        return value;
    }

    struct AddressToIntMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(AddressToIntMap storage map, address key, int256 value) internal returns (bool) {
        return _set(map._inner, key, value);
    }

    /**
    * @dev plus a key‘s value pair in a map
    * key. O(1).
    *
    * Returns true if the key was added to the map, that is if it was not
    * already present.
    */
    function plus(AddressToIntMap storage map, address key, int256 value) internal {
        return _plus(map._inner, key, value);
    }

    /**
    * @dev minus a key‘s value pair in a map
    * key. O(1).
    *
    * Returns true if the key was added to the map, that is if it was not
    * already present.
    */
    function minus(AddressToIntMap storage map, address key, int256 value) internal {
        return _minus(map._inner, key, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(AddressToIntMap storage map, address key) internal returns (bool) {
        return _remove(map._inner, key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(AddressToIntMap storage map, address key) internal view returns (bool) {
        return _contains(map._inner, key);
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(AddressToIntMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressToIntMap storage map, uint256 index) internal view returns (address, int256) {
        return _at(map._inner, index);
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(AddressToIntMap storage map, address key) internal view returns (int256) {
        return _get(map._inner, key);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Based on StableMath from Stability Labs Pty. Ltd.
// https://github.com/mstable/mStable-contracts/blob/master/contracts/shared/StableMath.sol

library StableMath {

    /**
     * @dev Scaling unit for use in specific calculations,
     * where 1 * 10**18, or 1e18 represents a unit '1'
     */
    uint256 private constant FULL_SCALE = 1e18;

    /***************************************
                    Helpers
    ****************************************/

    /**
     * @dev Adjust the scale of an integer
     * @param to Decimals to scale to
     * @param from Decimals to scale from
     */
    function scaleBy(
        uint256 x,
        uint256 to,
        uint256 from
    ) internal pure returns (uint256) {
        if (to > from) {
            x = x * (10 ** (to - from));
        } else if (to < from) {
            x = x / (10 ** (from - to));
        }
        return x;
    }

    /***************************************
               Precise Arithmetic
    ****************************************/

    /**
     * @dev Multiplies two precise units, and then truncates by the full scale
     * @param x Left hand input to multiplication
     * @param y Right hand input to multiplication
     * @return Result after multiplying the two inputs and then dividing by the shared
     *         scale unit
     */
    function mulTruncate(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulTruncateScale(x, y, FULL_SCALE);
    }

    /**
     * @dev Multiplies two precise units, and then truncates by the given scale. For example,
     * when calculating 90% of 10e18, (10e18 * 9e17) / 1e18 = (9e36) / 1e18 = 9e18
     * @param x Left hand input to multiplication
     * @param y Right hand input to multiplication
     * @param scale Scale unit
     * @return Result after multiplying the two inputs and then dividing by the shared
     *         scale unit
     */
    function mulTruncateScale(
        uint256 x,
        uint256 y,
        uint256 scale
    ) internal pure returns (uint256) {
        // e.g. assume scale = fullScale
        // z = 10e18 * 9e17 = 9e36
        uint256 z = x * y;
        // return 9e36 / 1e18 = 9e18
        return z / scale;
    }

    /**
     * @dev Multiplies two precise units, and then truncates by the full scale, rounding up the result
     * @param x Left hand input to multiplication
     * @param y Right hand input to multiplication
     * @return Result after multiplying the two inputs and then dividing by the shared
     *          scale unit, rounded up to the closest base unit.
     */
    function mulTruncateCeil(uint256 x, uint256 y)
    internal
    pure
    returns (uint256)
    {
        // e.g. 8e17 * 17268172638 = 138145381104e17
        uint256 scaled = x * y;
        // e.g. 138145381104e17 + 9.99...e17 = 138145381113.99...e17
        uint256 ceil = scaled + (FULL_SCALE - 1);
        // e.g. 13814538111.399...e18 / 1e18 = 13814538111
        return ceil / FULL_SCALE;
    }

    /**
     * @dev Precisely divides two units, by first scaling the left hand operand. Useful
     *      for finding percentage weightings, i.e. 8e18/10e18 = 80% (or 8e17)
     * @param x Left hand input to division
     * @param y Right hand input to division
     * @return Result after multiplying the left operand by the scale, and
     *         executing the division on the right hand input.
     */
    function divPrecisely(uint256 x, uint256 y)
    internal
    pure
    returns (uint256)
    {
        // e.g. 8e18 * 1e18 = 8e36
        uint256 z = x * FULL_SCALE;
        // e.g. 8e36 / 10e18 = 8e17
        return z / y;
    }

    /**
     * @dev Precisely divides two units, by first scaling the left hand operand. Useful
     *      for finding percentage weightings, i.e. 8e18/10e18 = 80% (or 8e17)
     * @param x Left hand input to division
     * @param y Right hand input to division
     * @return Result after multiplying the left operand by the scale, and
     *         executing the division on the right hand input.
     */
    function divPreciselyScale(uint256 x, uint256 y, uint256 scale)
    internal
    pure
    returns (uint256)
    {
        // e.g. 8e18 * 1e18 = 8e36
        uint256 z = x * scale;
        // e.g. 8e36 / 10e18 = 8e17
        return z / y;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPegToken is IERC20 {

    /**
     * @return the total shares minted.
     */
    function totalShares() external view returns (uint256);

    /**
     * @return the shares of specified address.
     */
    function sharesOf(address _account) external view returns (uint256);

    /**
     * @dev query the value that can be returned for a specified number of shares.
     * @return underlying units etc usd/eth.
     */
    function getUnderlyingUnitsByShares(uint256 _sharesAmount) external view returns (uint256);

    /**
     * @dev query the shares that can be returned for a specified number of underlying uints.
     * @return the shares.
     */
    function getSharesByUnderlyingUnits(uint256 _underlyingUnits) external view returns (uint256);
    
    /**
     * @dev change the pause state.
     * @param _isPaused.
     */
    function changePauseState(bool _isPaused) external;

    /**
     * @notice Creates `_sharesAmount` shares and assigns them to `_recipient`, increasing the total amount of shares.
     * @dev This doesn't increase the token total supply.
     *
     * Requirements:
     *
     * - `_recipient` cannot be the zero address.
     * - the contract must not be paused.
     */
    function mintShares(address _recipient, uint256 _sharesAmount) external;

    /**
     * @notice Destroys `_sharesAmount` shares from `_account`'s holdings, decreasing the total amount of shares.
     * @dev This doesn't decrease the token total supply.
     *
     * Requirements:
     *
     * - `_account` cannot be the zero address.
     * - `_account` must hold at least `_sharesAmount` shares.
     * - the contract must not be paused.
     */
    function burnShares(address _account, uint256 _sharesAmount) external;

}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

interface IVaultBuffer {
    event OpenDistribute();
    event CloseDistribute();

    /// @notice mint pending shares
    /// @param _sender user account address
    /// @param _amount mint amount
    function mint(address _sender, uint256 _amount) external payable;

    /// @notice transfer cash to vault
    /// @param _assets transfer token
    /// @param _amounts transfer token amount
    function transferCashToVault(address[] memory _assets, uint256[] memory _amounts) external;

    function openDistribute() external;

    function distributeWhenDistributing() external returns (bool);

    function distributeOnce() external returns (bool);

    function isDistributing() external view returns (bool);

    function getDistributeLimit() external view returns (uint256);

    function setDistributeLimit(uint256 _limit) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.6.0 <0.9.0;

library BocRoles {
    bytes32 internal constant GOV_ROLE = 0x00;

    bytes32 internal constant DELEGATE_ROLE = keccak256("DELEGATE_ROLE");

    bytes32 internal constant VAULT_ROLE = keccak256("VAULT_ROLE");

    bytes32 internal constant KEEPER_ROLE = keccak256("KEEPER_ROLE");
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.6.0 <0.9.0;

library NativeToken {
    address constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "./IExchangeAdapter.sol";

interface IExchangeAggregator {
    /**
     * @param platform Called exchange platforms
     * @param method The method of the exchange platform
     * @param encodeExchangeArgs The encoded parameters to call
     * @param slippage The slippage when exchange
     * @param oracleAdditionalSlippage The additional slippage for oracle estimated
     */
    struct ExchangeParam {
        address platform;
        uint8 method;
        bytes encodeExchangeArgs;
        uint256 slippage;
        uint256 oracleAdditionalSlippage;
    }

    /**
     * @param platform Called exchange platforms
     * @param method The method of the exchange platform
     * @param data The encoded parameters to call
     * @param swapDescription swap info
     */
    struct SwapParam {
        address platform;
        uint8 method;
        bytes data;
        IExchangeAdapter.SwapDescription swapDescription;
    }

    /**
     * @param srcToken The token swap from
     * @param dstToken The token swap to
     * @param amount The amount to swap
     * @param exchangeParam The struct of ExchangeParam
     */
    struct ExchangeToken {
        address fromToken;
        address toToken;
        uint256 fromAmount;
        ExchangeParam exchangeParam;
    }

    event ExchangeAdapterAdded(address[] _exchangeAdapters);

    event ExchangeAdapterRemoved(address[] _exchangeAdapters);

    event Swap(
        address _platform,
        uint256 _amount,
        address _srcToken,
        address _dstToken,
        uint256 _exchangeAmount,
        address indexed _receiver,
        address _sender
    );

    function swap(
        address _platform,
        uint8 _method,
        bytes calldata _data,
        IExchangeAdapter.SwapDescription calldata _sd
    ) external payable returns (uint256);

    function batchSwap(SwapParam[] calldata _swapParams) external payable returns (uint256[] memory);

    function getExchangeAdapters()
        external
        view
        returns (address[] memory _exchangeAdapters, string[] memory _identifiers);

    function addExchangeAdapters(address[] calldata _exchangeAdapters) external;

    function removeExchangeAdapters(address[] calldata _exchangeAdapters) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

interface IPriceOracleConsumer {

    function decimals() external view returns(uint8);

    function stEthPriceInEth() external view returns(uint);
    function wstEthPriceInEth() external view returns(uint);
    function rEthPriceInEth() external view returns(uint);
    function wEthPriceInEth() external view returns(uint);
    function sEthPriceInEth() external view returns(uint);
    function sEth2PriceInEth() external view returns(uint);
    function rEth2PriceInEth() external view returns (uint);

    function ethPriceInUsd() external view returns(uint);
    function stEthPriceInUsd() external view returns(uint);
    function wstEthPriceInUsd() external view returns(uint);
    function rEthPriceInUsd() external view returns(uint);
    function wEthPriceInUsd() external view returns(uint);
    function sEth2PriceInUsd() external view returns(uint);
    function rEth2PriceInUsd() external view returns (uint);

    function priceInEth(address _asset) external view returns(uint);
    function priceInUSD(address _asset) external view returns(uint);

    function valueInEth(address _asset,uint _amount) external view returns(uint);
    function valueInUsd(address _asset,uint _amount) external view returns(uint);

    function valueInTargetToken(address _fromToken, uint256 _amount, address _toToken) external view returns(uint256);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.6.0 <0.9.0;

interface IAccessControlProxy {
    function isGovOrDelegate(address _account) external view returns (bool);

    function isVaultOrGov(address _account) external view returns (bool);

    function isKeeperOrVaultOrGov(address _account) external view returns (bool);

    function hasRole(bytes32 _role, address _account) external view returns (bool);

    function checkRole(bytes32 _role, address _account) external view;

    function checkGovOrDelegate(address _account) external view;

    function checkVaultOrGov(address _account) external view;

    function checkKeeperOrVaultOrGov(address _account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
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

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.6.0 <0.9.0;
pragma experimental ABIEncoderV2;

interface IExchangeAdapter {
    /**
     * @param amount The amount to swap
     * @param srcToken The token swap from
     * @param dstToken The token swap to
     * @param receiver The user to receive `dstToken`
     */
    struct SwapDescription {
        uint256 amount;
        address srcToken;
        address dstToken;
        address receiver;
    }

    /// @notice The identifier of this exchange adapter
    function identifier() external pure returns (string memory _identifier);

    /**
     * @notice Swap with `_sd` data by using `_method` and `_data` on `_platform`.
     * @param _method The method of the exchange platform
     * @param _encodedCallArgs The encoded parameters to call
     * @param _sd The description info of this swap
     * @return The expected amountIn to swap
     */
    function swap(
        uint8 _method,
        bytes calldata _encodedCallArgs,
        SwapDescription calldata _sd
    ) external payable returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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