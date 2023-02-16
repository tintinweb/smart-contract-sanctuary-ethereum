// contracts/HighTableVault.sol
// SPDX-License-Identifier: BUSL
// Teahouse Finance

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "./IHighTableVault.sol";


/// @title An investment vault for working with TeaVaultV2
/// @author Teahouse Finance
contract HighTableVault is IHighTableVault, AccessControl, ERC20 {

    using SafeERC20 for IERC20;

    uint256 public constant SECONDS_IN_A_YEAR = 365 * 86400;             // for calculating management fee
    bytes32 public constant AUDITOR_ROLE = keccak256("AUDITOR_ROLE");

    IERC20 internal immutable assetToken;

    FeeConfig public feeConfig;
    FundConfig public fundConfig;
    address[] public nftEnabled;

    GlobalState public globalState;
    mapping(uint32 => CycleState) public cycleState;
    mapping(address => UserState) public userState;

    Price public initialPrice;          // initial price
    Price public closePrice;            // price after fund is closed

    /// @param _name name of the vault token
    /// @param _symbol symbol of the vault token
    /// @param _asset address of the asset token
    /// @param _priceNumerator initial price for each vault token in asset token
    /// @param _priceDenominator price denominator (actual price = _initialPrice / _priceDenominator)
    /// @param _startTimestamp starting timestamp of the first cycle
    /// @param _initialAdmin address of the initial admin
    /// @notice To setup a HighTableVault, the procedure should be
    /// @notice 1. Deploy HighTableVault
    /// @notice 2. Set FeeConfig
    /// @notice 3. (optionally) Deploy TeaVaultV2
    /// @notice 4. Set TeaVaultV2's investor to HighTableVault
    /// @notice 5. Set TeaVaultV2 address (setTeaVaultV2)
    /// @notice 6. Grant auditor role to an address (grantRole)
    /// @notice 7. Set fund locking timestamp for initial cycle (setFundLockingTimestamp)
    /// @notice 8. Set deposit limit for initial cycle (setDepositLimit)
    /// @notice 9. Set enabled NFT list, or disable NFT check (setEnabledNFTs or setDisableNFTChecks)
    /// @notice 10. Users will be able to request deposits
    /// @notice On initial price: the vault token has 18 decimals, so if the asset token is not 18 decimals,
    /// @notice should take extra care in setting the initial price.
    /// @notice For example, if using USDC (has 6 decimals), and want to have 1:1 inital price,
    /// @notice the initial price should be numerator = 1_000_000 and denominator = 1_000_000_000_000_000_000.
    constructor(
        string memory _name,
        string memory _symbol,
        address _asset,
        uint128 _priceNumerator,
        uint128 _priceDenominator,
        uint64 _startTimestamp,
        address _initialAdmin)
        ERC20(_name, _symbol) {
        if (_priceNumerator == 0 || _priceDenominator == 0) revert InvalidInitialPrice();
        
        _grantRole(DEFAULT_ADMIN_ROLE, _initialAdmin);

        assetToken = IERC20(_asset);
        initialPrice = Price(_priceNumerator, _priceDenominator);

        globalState.cycleStartTimestamp = _startTimestamp;

        emit FundInitialized(msg.sender, _priceNumerator, _priceDenominator, _startTimestamp, _initialAdmin);
    }

    /// @inheritdoc IHighTableVault
    function setEnabledNFTs(address[] calldata _nfts) external override {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert OnlyAvailableToAdmins();

        nftEnabled = _nfts;

        emit NFTEnabled(msg.sender, globalState.cycleIndex, _nfts);
    }

    /// @inheritdoc IHighTableVault
    function setDisableNFTChecks(bool _checks) external override {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert OnlyAvailableToAdmins();

        fundConfig.disableNFTChecks = _checks;

        emit DisableNFTChecks(msg.sender, globalState.cycleIndex, _checks);
    }

    /// @inheritdoc IHighTableVault
    function setFeeConfig(FeeConfig calldata _feeConfig) external override {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert OnlyAvailableToAdmins();

        if (_feeConfig.managerEntryFee + _feeConfig.platformEntryFee +
            _feeConfig.managerExitFee + _feeConfig.platformExitFee > 1000000) revert InvalidFeePercentage();
        if (_feeConfig.managerPerformanceFee + _feeConfig.platformPerformanceFee > 1000000) revert InvalidFeePercentage();
        if (_feeConfig.managerManagementFee + _feeConfig.platformManagementFee > 1000000) revert InvalidFeePercentage();

        feeConfig = _feeConfig;

        emit FeeConfigChanged(msg.sender, globalState.cycleIndex, _feeConfig);
    }

    /// @inheritdoc IHighTableVault
    function setTeaVaultV2(address _teaVaultV2) external override {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert OnlyAvailableToAdmins();
        
        fundConfig.teaVaultV2 = ITeaVaultV2(_teaVaultV2);

        emit UpdateTeaVaultV2(msg.sender, globalState.cycleIndex, _teaVaultV2);
    }

    /// @inheritdoc IHighTableVault
    /// @dev Does not use nonReentrant because it can only be called from auditors
    function enterNextCycle(
        uint32 _cycleIndex,
        uint128 _fundValue,
        uint128 _depositLimit,
        uint128 _withdrawAmount,
        uint64 _cycleStartTimestamp,
        uint64 _fundingLockTimestamp,
        bool _closeFund) external override returns (uint256 platformFee, uint256 managerFee) {

        // withdraw from vault
        if (_withdrawAmount > 0) {
            fundConfig.teaVaultV2.withdraw(address(this), address(assetToken), _withdrawAmount);
        }

        // permission checks are done in the internal function
        (platformFee, managerFee) = _internalEnterNextCycle(_cycleIndex, _fundValue, _depositLimit, _cycleStartTimestamp, _fundingLockTimestamp, _closeFund);

        // distribute fees
        if (platformFee > 0) {
            assetToken.safeTransfer(feeConfig.platformVault, platformFee);
        }

        if (managerFee > 0) {
            assetToken.safeTransfer(feeConfig.managerVault, managerFee);
        }

        // check if the remaining balance is enough for locked assets
        // and deposit extra balance back to the vault
        uint256 deposits = _internalCheckDeposits();
        if (deposits > 0) {
            assetToken.safeApprove(address(fundConfig.teaVaultV2), deposits);
            fundConfig.teaVaultV2.deposit(address(assetToken), deposits);
        }
    }

    /// @inheritdoc IHighTableVault
    function previewNextCycle(uint128 _fundValue, uint64 _timestamp) external override view returns (uint256 withdrawAmount) {
        if (globalState.cycleIndex > 0) {
            // calculate performance and management fees
            (uint256 pFee, uint256 mFee) = _calculatePMFees(_fundValue, _timestamp);
            withdrawAmount += pFee + mFee;
        }

        uint32 cycleIndex = globalState.cycleIndex;

        // convert total withdrawals to assets
        if (cycleState[cycleIndex].requestedWithdrawals > 0) {
            // if requestedWithdrawals > 0, there must be some remaining shares so totalSupply() won't be zero
            uint256 fundValueAfterPMFee = _fundValue - withdrawAmount;
            withdrawAmount += uint256(cycleState[cycleIndex].requestedWithdrawals) * fundValueAfterPMFee / totalSupply();
        }

        if (cycleState[cycleIndex].requestedDeposits > 0) {
            uint256 requestedDeposits = cycleState[cycleIndex].requestedDeposits;
            uint256 platformFee = requestedDeposits * feeConfig.platformEntryFee / 1000000;
            uint256 managerFee = requestedDeposits * feeConfig.managerEntryFee / 1000000;
            withdrawAmount += platformFee + managerFee;

            if (withdrawAmount > requestedDeposits) {
                withdrawAmount -= requestedDeposits;
            }
            else {
                withdrawAmount = 0;
            }
        }
    }

    /// @inheritdoc IHighTableVault
    function setFundLockingTimestamp(uint64 _fundLockingTimestamp) external override {
        if (!hasRole(AUDITOR_ROLE, msg.sender)) revert OnlyAvailableToAuditors();

        globalState.fundingLockTimestamp = _fundLockingTimestamp;

        emit FundLockingTimestampUpdated(msg.sender, globalState.cycleIndex, _fundLockingTimestamp);
    }

    /// @inheritdoc IHighTableVault
    function setDepositLimit(uint128 _depositLimit) external override {
        if (!hasRole(AUDITOR_ROLE, msg.sender)) revert OnlyAvailableToAuditors();

        globalState.depositLimit = _depositLimit;

        emit DepositLimitUpdated(msg.sender, globalState.cycleIndex, _depositLimit);
    }

    /// @inheritdoc IHighTableVault
    function setDisableFunding(bool _disableDepositing, bool _disableWithdrawing, bool _disableCancelDepositing, bool _disableCancelWithdrawing) external override {
        if (!hasRole(AUDITOR_ROLE, msg.sender)) revert OnlyAvailableToAuditors();

        fundConfig.disableDepositing = _disableDepositing;
        fundConfig.disableWithdrawing = _disableWithdrawing;
        fundConfig.disableCancelDepositing = _disableCancelDepositing;
        fundConfig.disableCancelWithdrawing = _disableCancelWithdrawing; 

        emit FundingChanged(msg.sender, globalState.cycleIndex, _disableDepositing, _disableWithdrawing, _disableCancelDepositing, _disableCancelWithdrawing);
    }

    /// @inheritdoc IHighTableVault
    /// @dev No need for nonReentrant because there is no danger of reentrance attack
    /// @dev since there is no checking nor recording of amount of assets    
    function depositToVault(uint256 _value) external override {
        if (!hasRole(AUDITOR_ROLE, msg.sender)) revert OnlyAvailableToAuditors();

        uint256 balance = assetToken.balanceOf(address(this));
        if (balance - globalState.lockedAssets < _value) revert NotEnoughAssets();

        assetToken.safeApprove(address(fundConfig.teaVaultV2), _value);
        fundConfig.teaVaultV2.deposit(address(assetToken), _value);

        emit DepositToVault(msg.sender, globalState.cycleIndex, address(fundConfig.teaVaultV2), _value);
    }

    /// @inheritdoc IHighTableVault
    /// @dev No need for nonReentrant because there is no danger of reentrance attack
    /// @dev since there is no checking nor recording of amount of assets
    function withdrawFromVault(uint256 _value) external override {
        if (!hasRole(AUDITOR_ROLE, msg.sender)) revert OnlyAvailableToAuditors();

        fundConfig.teaVaultV2.withdraw(address(this), address(assetToken), _value);

        emit WithdrawFromVault(msg.sender, globalState.cycleIndex, address(fundConfig.teaVaultV2), _value);
    }

    /// @inheritdoc IHighTableVault
    function asset() external override view returns (address assetTokenAddress) {
        return address(assetToken);
    }

    /// @inheritdoc IHighTableVault
    /// @dev No need for nonReentrant because there is no danger of reentrance attack
    /// @dev since recording of deposited assets happens after receiving assets
    /// @dev and assetToken has to be attacked in some way to perform reentrance
    function requestDeposit(uint256 _assets, address _receiver) public override {
        assetToken.safeTransferFrom(msg.sender, address(this), _assets);
        _internalRequestDeposit(_assets, _receiver);
    }

    /// @inheritdoc IHighTableVault
    /// @dev No need for nonReentrant because there is no danger of reentrance attack
    /// @dev since recording of deposited assets happens after receiving assets
    /// @dev and assetToken has to be attacked in some way to perform reentrance
    function claimAndRequestDeposit(uint256 _assets, address _receiver) external override returns (uint256 assets) {
        assets = claimOwedAssets(msg.sender);
        requestDeposit(_assets, _receiver);
    }

    /// @inheritdoc IHighTableVault
    /// @dev No need for nonReentrant because there is no danger of reentrance attack
    /// @dev since removing of deposited assets happens before receiving assets
    /// @dev and assetToken has to be attacked in some way to perform reentrance
    function cancelDeposit(uint256 _assets, address _receiver) external override {
        _internalCancelDeposit(_assets, _receiver);
        assetToken.safeTransfer(_receiver, _assets);
    }

    /// @inheritdoc IHighTableVault
    /// @dev No need for nonReentrant because this function does not call other contracts    
    function requestWithdraw(uint256 _shares, address _owner) public override {
        if (fundConfig.disableWithdrawing) revert WithdrawDisabled();
        if (globalState.fundClosed) revert FundIsClosed();
        if (block.timestamp > globalState.fundingLockTimestamp) revert FundingLocked();

        if (_owner != msg.sender) {
            _spendAllowance(_owner, msg.sender, _shares);
        }

        _transfer(_owner, address(this), _shares);

        uint32 cycleIndex = globalState.cycleIndex;
        uint128 shares = SafeCast.toUint128(_shares);
        cycleState[cycleIndex].requestedWithdrawals += shares;

        // if user has previously requested deposits or withdrawals, convert them
        _convertPreviousRequests(_owner);

        userState[_owner].requestedWithdrawals += shares;
        userState[_owner].requestCycleIndex = cycleIndex;

        emit WithdrawalRequested(msg.sender, cycleIndex, _owner, _shares);
    }

    /// @inheritdoc IHighTableVault
    /// @dev No need for nonReentrant because this function does not call other contracts
    function claimAndRequestWithdraw(uint256 _shares, address _owner) external override returns (uint256 shares) {
        shares = claimOwedShares(msg.sender);
        requestWithdraw(_shares, _owner);
    }

    /// @inheritdoc IHighTableVault
    /// @dev No need for nonReentrant because this function does not call other contracts
    function cancelWithdraw(uint256 _shares, address _receiver) external override {
        if (block.timestamp > globalState.fundingLockTimestamp) revert FundingLocked();
        if (fundConfig.disableCancelWithdrawing) revert CancelWithdrawDisabled();

        uint32 cycleIndex = globalState.cycleIndex;

        if (userState[msg.sender].requestCycleIndex != cycleIndex) revert NotEnoughWithdrawals();
        if (userState[msg.sender].requestedWithdrawals < _shares) revert NotEnoughWithdrawals();

        uint128 shares = SafeCast.toUint128(_shares);
        cycleState[cycleIndex].requestedWithdrawals -= shares;
        userState[msg.sender].requestedWithdrawals -= shares;

        _transfer(address(this), _receiver, _shares);

        emit WithdrawalCanceled(msg.sender, cycleIndex, _receiver, _shares);
    }

    /// @inheritdoc IHighTableVault
    function requestedFunds(address _owner) external override view returns (uint256 assets, uint256 shares) {
        if (userState[_owner].requestCycleIndex != globalState.cycleIndex) {
            return (0, 0);
        }

        assets = userState[_owner].requestedDeposits;
        shares = userState[_owner].requestedWithdrawals;
    }

    /// @inheritdoc IHighTableVault
    /// @dev No need for nonReentrant because there is no danger of reentrance attack
    /// @dev since owed assets are cleared before sending out
    /// @dev and assetToken has to be attacked in some way to perform reentrance
    function claimOwedAssets(address _receiver) public override returns (uint256 assets) {
        assets = _internalClaimOwedAssets(_receiver);
        if (assets > 0) {
            assetToken.safeTransfer(_receiver, assets);
        }
    }

    /// @inheritdoc IHighTableVault
    /// @dev No need for nonReentrant because this function does not call other contracts
    function claimOwedShares(address _receiver) public override returns (uint256 shares) {
        _convertPreviousRequests(msg.sender);

        if (userState[msg.sender].owedShares > 0) {
            shares = userState[msg.sender].owedShares;
            userState[msg.sender].owedShares = 0;
            _transfer(address(this), _receiver, shares);

            emit ClaimOwedShares(msg.sender, _receiver, shares);
        }
    }

    /// @inheritdoc IHighTableVault
    function claimOwedFunds(address _receiver) external override returns (uint256 assets, uint256 shares) {
        assets = claimOwedAssets(_receiver);
        shares = claimOwedShares(_receiver);
    }

    /// @inheritdoc IHighTableVault
    function closePosition(uint256 _shares, address _owner) public override returns (uint256 assets) {
        if (!globalState.fundClosed) revert FundIsNotClosed();

        if (_owner != msg.sender) {
            _spendAllowance(_owner, msg.sender, _shares);
        }

        _burn(_owner, _shares);

        // closePrice.denominator is the remaining amount of shares when the fund is closed
        // so if it's zero, no one would have any remaining shares to call closePosition
        assets = _shares * closePrice.numerator / closePrice.denominator;
        userState[_owner].owedAssets += SafeCast.toUint128(assets);
    }

    /// @inheritdoc IHighTableVault
    function closePositionAndClaim(address _receiver) external override returns (uint256 assets) {
        claimOwedShares(msg.sender);
        uint256 shares = balanceOf(msg.sender);
        closePosition(shares, msg.sender);
        assets = claimOwedAssets(_receiver);
    }

    /// @notice Internal function for entering next cycle
    function _internalEnterNextCycle(
        uint32 _cycleIndex,
        uint128 _fundValue,
        uint128 _depositLimit,
        uint64 _cycleStartTimestamp,
        uint64 _fundingLockTimestamp,
        bool _closeFund) internal returns (uint256 platformFee, uint256 managerFee) {
        if (!hasRole(AUDITOR_ROLE, msg.sender)) revert OnlyAvailableToAuditors();
        if (address(fundConfig.teaVaultV2) == address(0)) revert IncorrectVaultAddress();
        if (feeConfig.platformVault == address(0)) revert IncorrectVaultAddress();
        if (feeConfig.managerVault == address(0)) revert IncorrectVaultAddress();
        if (globalState.fundClosed) revert FundIsClosed();
        if (_cycleIndex != globalState.cycleIndex) revert IncorrectCycleIndex();
        if (_cycleStartTimestamp <= globalState.cycleStartTimestamp || _cycleStartTimestamp > block.timestamp) revert IncorrectCycleStartTimestamp();

        // record current cycle state
        cycleState[_cycleIndex].totalFundValue = _fundValue;

        uint256 pFee;
        uint256 mFee;
        if (_cycleIndex > 0) {
            // distribute performance and management fees
            (pFee, mFee) = _calculatePMFees(_fundValue, _cycleStartTimestamp);
            platformFee += pFee;
            managerFee += mFee;
        }

        uint256 fundValueAfterPMFees = _fundValue - platformFee - managerFee;
        uint256 currentTotalSupply = totalSupply();

        if (currentTotalSupply > 0 && fundValueAfterPMFees == 0) revert InvalidFundValue();
        if (currentTotalSupply == 0 && cycleState[_cycleIndex].requestedDeposits == 0) revert NoDeposits();

        (pFee, mFee) = _processRequests(fundValueAfterPMFees);
        platformFee += pFee;
        managerFee += mFee;

        if (_closeFund) {
            // calculate exit fees for all remaining funds
            (pFee, mFee) = _calculateCloseFundFees();
            platformFee += pFee;
            managerFee += mFee;

            // set price for closing position
            uint128 finalFundValue = SafeCast.toUint128(cycleState[globalState.cycleIndex].fundValueAfterRequests - pFee - mFee);
            closePrice = Price(finalFundValue, SafeCast.toUint128(totalSupply()));
            globalState.lockedAssets += finalFundValue;
            globalState.fundClosed = true;
        }

        if (currentTotalSupply == 0) {
            emit EnterNextCycle(
                msg.sender,
                _cycleIndex,
                _fundValue,
                initialPrice.numerator,
                initialPrice.denominator,
                _depositLimit,
                _cycleStartTimestamp,
                _fundingLockTimestamp,
                _closeFund,
                platformFee,
                managerFee);
        }
        else {
            emit EnterNextCycle(
                msg.sender,
                _cycleIndex,
                _fundValue,
                fundValueAfterPMFees,
                currentTotalSupply,
                _depositLimit,
                _cycleStartTimestamp,
                _fundingLockTimestamp,
                _closeFund,
                platformFee,
                managerFee);
        }

        // enter next cycle
        globalState.cycleIndex ++;
        globalState.cycleStartTimestamp = _cycleStartTimestamp;
        globalState.depositLimit = _depositLimit;
        globalState.fundingLockTimestamp = _fundingLockTimestamp;
    }

    /// @notice Interal function for checking if the remaining balance is enough for locked assets
    function _internalCheckDeposits() internal view returns (uint256 deposits) {
        deposits = assetToken.balanceOf(address(this));
        if (deposits < globalState.lockedAssets) revert NotEnoughAssets();
        unchecked {
            deposits = deposits - globalState.lockedAssets;
        }
    }

    /// @notice Calculate performance and management fees
    function _calculatePMFees(uint128 _fundValue, uint64 _timestamp) internal view returns (uint256 platformFee, uint256 managerFee) {
        // calculate management fees
        uint256 fundValue = _fundValue;
        uint64 timeDiff = _timestamp - globalState.cycleStartTimestamp;
        unchecked {
            platformFee = fundValue * feeConfig.platformManagementFee * timeDiff / (SECONDS_IN_A_YEAR * 1000000);
            managerFee = fundValue * feeConfig.managerManagementFee * timeDiff / (SECONDS_IN_A_YEAR * 1000000);
        }

        // calculate and distribute performance fees
        if (fundValue > cycleState[globalState.cycleIndex - 1].fundValueAfterRequests) {
            unchecked {
                uint256 profits = fundValue - cycleState[globalState.cycleIndex - 1].fundValueAfterRequests;
                platformFee += profits * feeConfig.platformPerformanceFee / 1000000;
                managerFee += profits * feeConfig.managerPerformanceFee / 1000000;
            }
        }
    }

    /// @notice Calculate exit fees when closing fund
    function _calculateCloseFundFees() internal view returns (uint256 platformFee, uint256 managerFee) {
        // calculate exit fees for remaining funds
        uint256 fundValue = cycleState[globalState.cycleIndex].fundValueAfterRequests;

        unchecked {
            platformFee = fundValue * feeConfig.platformExitFee / 1000000;
            managerFee = fundValue * feeConfig.managerExitFee / 1000000;
        }
    }

    /// @notice Process requested withdrawals and deposits
    function _processRequests(uint256 _fundValueAfterPMFees) internal returns (uint256 platformFee, uint256 managerFee) {
        uint32 cycleIndex = globalState.cycleIndex;
        uint256 currentTotalSupply = totalSupply();
        uint256 fundValueAfterRequests = _fundValueAfterPMFees;

        // convert total withdrawals to assets and calculate exit fees
        if (cycleState[cycleIndex].requestedWithdrawals > 0) {
            // if requestedWithdrawals > 0, there must be some remaining shares so totalSupply() won't be zero
            uint256 withdrawnAssets = _fundValueAfterPMFees * cycleState[cycleIndex].requestedWithdrawals / currentTotalSupply;
            uint256 pFee;
            uint256 mFee;

            unchecked {
                pFee = withdrawnAssets * feeConfig.platformExitFee / 1000000;
                mFee = withdrawnAssets * feeConfig.managerExitFee / 1000000;
            }

            // record remaining assets available for withdrawals
            cycleState[cycleIndex].convertedWithdrawals = SafeCast.toUint128(withdrawnAssets - pFee - mFee);
            globalState.lockedAssets += cycleState[cycleIndex].convertedWithdrawals;
            fundValueAfterRequests -= SafeCast.toUint128(withdrawnAssets);

            platformFee += pFee;
            managerFee += mFee;

            // burn converted share tokens
            _burn(address(this), cycleState[cycleIndex].requestedWithdrawals);
        }

        // convert total deposits to shares and calculate entry fees
        if (cycleState[cycleIndex].requestedDeposits > 0) {
            uint256 requestedDeposits = cycleState[cycleIndex].requestedDeposits;
            uint256 pFee;
            uint256 mFee;
            
            unchecked {
                pFee = requestedDeposits * feeConfig.platformEntryFee / 1000000;
                mFee = requestedDeposits * feeConfig.managerEntryFee / 1000000;
            }

            globalState.lockedAssets -= cycleState[cycleIndex].requestedDeposits;
            requestedDeposits = requestedDeposits - pFee - mFee;
            fundValueAfterRequests += SafeCast.toUint128(requestedDeposits);

            if (currentTotalSupply == 0) {
                // use initial price if there's no share tokens
                cycleState[cycleIndex].convertedDeposits = SafeCast.toUint128(requestedDeposits * initialPrice.denominator / initialPrice.numerator);
            }
            else {
                // _fundValueAfterPMFees is checked to be non-zero when total supply is non-zero
                cycleState[cycleIndex].convertedDeposits = SafeCast.toUint128(requestedDeposits * currentTotalSupply / _fundValueAfterPMFees);
            }

            platformFee += pFee;
            managerFee += mFee;

            // mint new share tokens
            _mint(address(this), cycleState[cycleIndex].convertedDeposits);
        }

        cycleState[cycleIndex].fundValueAfterRequests = SafeCast.toUint128(fundValueAfterRequests);
    }

    /// @notice Convert previous requested deposits and withdrawls
    function _convertPreviousRequests(address _receiver) internal {
        uint32 cycleIndex = userState[_receiver].requestCycleIndex;

        if (cycleIndex >= globalState.cycleIndex) {
            return;
        }

        if (userState[_receiver].requestedDeposits > 0) {
            // if requestedDeposits of a user > 0 then requestedDeposits of the cycle must be > 0
            uint256 owedShares = uint256(userState[_receiver].requestedDeposits) * cycleState[cycleIndex].convertedDeposits / cycleState[cycleIndex].requestedDeposits;
            userState[_receiver].owedShares += SafeCast.toUint128(owedShares);
            emit ConvertToShares(_receiver, cycleIndex, userState[_receiver].requestedDeposits, owedShares);
            userState[_receiver].requestedDeposits = 0;
        }

        if (userState[_receiver].requestedWithdrawals > 0) {
            // if requestedWithdrawals of a user > 0 then requestedWithdrawals of the cycle must be > 0
            uint256 owedAssets = uint256(userState[_receiver].requestedWithdrawals) * cycleState[cycleIndex].convertedWithdrawals / cycleState[cycleIndex].requestedWithdrawals;
            userState[_receiver].owedAssets += SafeCast.toUint128(owedAssets);
            emit ConvertToAssets(_receiver, cycleIndex, userState[_receiver].requestedWithdrawals, owedAssets);
            userState[_receiver].requestedWithdrawals = 0;
        }
    }

    /// @notice Internal function for processing deposit requests
    function _internalRequestDeposit(uint256 _assets, address _receiver) internal {
        if (fundConfig.disableDepositing) revert DepositDisabled();
        if (globalState.fundClosed) revert FundIsClosed();
        if (block.timestamp > globalState.fundingLockTimestamp) revert FundingLocked();
        if (_assets + cycleState[globalState.cycleIndex].requestedDeposits > globalState.depositLimit) revert ExceedDepositLimit();
        if (!_hasNFT(_receiver)) revert ReceiverDoNotHasNFT();

        uint32 cycleIndex = globalState.cycleIndex;
        uint128 assets = SafeCast.toUint128(_assets);
        cycleState[cycleIndex].requestedDeposits += assets;
        globalState.lockedAssets += assets;

        // if user has previously requested deposits or withdrawals, convert them
        _convertPreviousRequests(_receiver);

        userState[_receiver].requestedDeposits += assets;
        userState[_receiver].requestCycleIndex = cycleIndex;

        emit DepositRequested(msg.sender, cycleIndex, _receiver, _assets);
    }

    /// @notice Internal function for canceling deposit requests
    function _internalCancelDeposit(uint256 _assets, address _receiver) internal {
        if (block.timestamp > globalState.fundingLockTimestamp) revert FundingLocked();
        if (fundConfig.disableCancelDepositing) revert CancelDepositDisabled();

        uint32 cycleIndex = globalState.cycleIndex;

        if (userState[msg.sender].requestCycleIndex != cycleIndex) revert NotEnoughDeposits();
        if (userState[msg.sender].requestedDeposits < _assets) revert NotEnoughDeposits();

        uint128 assets = SafeCast.toUint128(_assets);
        cycleState[cycleIndex].requestedDeposits -= assets;
        globalState.lockedAssets -= assets;
        userState[msg.sender].requestedDeposits -= assets;

        emit DepositCanceled(msg.sender, cycleIndex, _receiver, _assets);
    }

    /// @notice Internal function for claiming owed assets
    function _internalClaimOwedAssets(address _receiver) internal returns (uint256 assets) {
        _convertPreviousRequests(msg.sender);

        if (userState[msg.sender].owedAssets > 0) {
            assets = userState[msg.sender].owedAssets;
            globalState.lockedAssets -= userState[msg.sender].owedAssets;
            userState[msg.sender].owedAssets = 0;

            emit ClaimOwedAssets(msg.sender, _receiver, assets);
        }
    }

    /// @notice Internal NFT checker
    /// @param _receiver address of the receiver
    /// @return hasNFT true if the receiver has at least one of the NFT, false if not
    /// @dev always returns true if disableNFTChecks is enabled
    function _hasNFT(address _receiver) internal view returns (bool hasNFT) {
        if (fundConfig.disableNFTChecks) {
            return true;
        }

        uint256 i;
        uint256 length = nftEnabled.length;
        for (i = 0; i < length; ) {
            if (IERC721(nftEnabled[i]).balanceOf(_receiver) > 0) {
                return true;
            }

            unchecked {
                ++i;
            }
        }

        return false;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248) {
        require(value >= type(int248).min && value <= type(int248).max, "SafeCast: value doesn't fit in 248 bits");
        return int248(value);
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240) {
        require(value >= type(int240).min && value <= type(int240).max, "SafeCast: value doesn't fit in 240 bits");
        return int240(value);
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232) {
        require(value >= type(int232).min && value <= type(int232).max, "SafeCast: value doesn't fit in 232 bits");
        return int232(value);
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224) {
        require(value >= type(int224).min && value <= type(int224).max, "SafeCast: value doesn't fit in 224 bits");
        return int224(value);
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216) {
        require(value >= type(int216).min && value <= type(int216).max, "SafeCast: value doesn't fit in 216 bits");
        return int216(value);
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208) {
        require(value >= type(int208).min && value <= type(int208).max, "SafeCast: value doesn't fit in 208 bits");
        return int208(value);
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200) {
        require(value >= type(int200).min && value <= type(int200).max, "SafeCast: value doesn't fit in 200 bits");
        return int200(value);
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192) {
        require(value >= type(int192).min && value <= type(int192).max, "SafeCast: value doesn't fit in 192 bits");
        return int192(value);
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184) {
        require(value >= type(int184).min && value <= type(int184).max, "SafeCast: value doesn't fit in 184 bits");
        return int184(value);
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176) {
        require(value >= type(int176).min && value <= type(int176).max, "SafeCast: value doesn't fit in 176 bits");
        return int176(value);
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168) {
        require(value >= type(int168).min && value <= type(int168).max, "SafeCast: value doesn't fit in 168 bits");
        return int168(value);
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160) {
        require(value >= type(int160).min && value <= type(int160).max, "SafeCast: value doesn't fit in 160 bits");
        return int160(value);
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152) {
        require(value >= type(int152).min && value <= type(int152).max, "SafeCast: value doesn't fit in 152 bits");
        return int152(value);
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144) {
        require(value >= type(int144).min && value <= type(int144).max, "SafeCast: value doesn't fit in 144 bits");
        return int144(value);
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136) {
        require(value >= type(int136).min && value <= type(int136).max, "SafeCast: value doesn't fit in 136 bits");
        return int136(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120) {
        require(value >= type(int120).min && value <= type(int120).max, "SafeCast: value doesn't fit in 120 bits");
        return int120(value);
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112) {
        require(value >= type(int112).min && value <= type(int112).max, "SafeCast: value doesn't fit in 112 bits");
        return int112(value);
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104) {
        require(value >= type(int104).min && value <= type(int104).max, "SafeCast: value doesn't fit in 104 bits");
        return int104(value);
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96) {
        require(value >= type(int96).min && value <= type(int96).max, "SafeCast: value doesn't fit in 96 bits");
        return int96(value);
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88) {
        require(value >= type(int88).min && value <= type(int88).max, "SafeCast: value doesn't fit in 88 bits");
        return int88(value);
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80) {
        require(value >= type(int80).min && value <= type(int80).max, "SafeCast: value doesn't fit in 80 bits");
        return int80(value);
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72) {
        require(value >= type(int72).min && value <= type(int72).max, "SafeCast: value doesn't fit in 72 bits");
        return int72(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56) {
        require(value >= type(int56).min && value <= type(int56).max, "SafeCast: value doesn't fit in 56 bits");
        return int56(value);
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48) {
        require(value >= type(int48).min && value <= type(int48).max, "SafeCast: value doesn't fit in 48 bits");
        return int48(value);
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40) {
        require(value >= type(int40).min && value <= type(int40).max, "SafeCast: value doesn't fit in 40 bits");
        return int40(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24) {
        require(value >= type(int24).min && value <= type(int24).max, "SafeCast: value doesn't fit in 24 bits");
        return int24(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// contracts/IHighTableVault.sol
// SPDX-License-Identifier: BUSL
// Teahouse Finance

pragma solidity ^0.8.0;

import "./ITeaVaultV2.sol";

error OnlyAvailableToAdmins();              // operation is available only to admins
error OnlyAvailableToAuditors();            // operation is available only to auditors
error ReceiverDoNotHasNFT();                // receiver does not have required NFT to deposit
error IncorrectVaultAddress();              // TeaVaultV2, managerVault, or platformVault is 0
error IncorrectReceiverAddress();           // receiver address is 0
error NotEnoughAssets();                    // does not have enough asset tokens
error FundingLocked();                      // deposit and withdraw are not allowed in locked period
error ExceedDepositLimit();                 // requested deposit exceeds current deposit limit
error DepositDisabled();                    // deposit request is disabled
error WithdrawDisabled();                   // withdraw request is disabled
error NotEnoughDeposits();                  // user does not have enough deposit requested to cancel
error NotEnoughWithdrawals();               // user does not have enough withdrawals requested to cancel
error InvalidInitialPrice();                // invalid initial price
error FundIsClosed();                       // fund is closed, requests are not allowed
error FundIsNotClosed();                    // fund is not closed, can't close position
error InvalidFeePercentage();               // incorrect fee percentage
error IncorrectCycleIndex();                // incorrect cycle index
error IncorrectCycleStartTimestamp();       // incorrect cycle start timestamp (before previous cycle start timestamp or later than current time)
error InvalidFundValue();                   // incorrect fund value (zero or very close to zero)
error NoDeposits();                         // can not enter next cycle if there's no share and no requested deposits
error CancelDepositDisabled();              // canceling deposit is disabled
error CancelWithdrawDisabled();             // canceling withdraw is disabled

interface IHighTableVault {

    struct Price {
        uint128 numerator;              // numerator of the price
        uint128 denominator;            // denominator of the price
    }

    struct FeeConfig {
        address platformVault;          // platform fee goes here
        address managerVault;           // manager fee goes here
        uint24 platformEntryFee;        // platform entry fee in 0.0001% (collected when depositing)
        uint24 managerEntryFee;         // manager entry fee in 0.0001% (colleceted when depositing)
        uint24 platformExitFee;         // platform exit fee (collected when withdrawing)
        uint24 managerExitFee;          // manager exit fee (collected when withdrawing)
        uint24 platformPerformanceFee;  // platform performance fee (collected for each cycle, from profits)
        uint24 managerPerformanceFee;   // manager performance fee (collected for each cycle, from profits)
        uint24 platformManagementFee;   // platform yearly management fee (collected for each cycle, from total value)
        uint24 managerManagementFee;    // manager yearly management fee (collected for each cycle, from total value)
    }

    struct FundConfig {
        ITeaVaultV2 teaVaultV2;         // TeaVaultV2 address
        bool disableNFTChecks;          // allow everyone to access the vault
        bool disableDepositing;         // disable requesting depositing
        bool disableWithdrawing;        // disable requesting withdrawing
        bool disableCancelDepositing;   // disable canceling depositing
        bool disableCancelWithdrawing;  // disable canceling withdrawing
    }

    struct GlobalState {
        uint128 depositLimit;           // deposit limit (in asset)
        uint128 lockedAssets;           // locked assets (assets waiting to be withdrawn, or deposited by users but not converted to shares yet)

        uint32 cycleIndex;              // current cycle index
        uint64 cycleStartTimestamp;     // start timestamp of current cycle
        uint64 fundingLockTimestamp;    // timestamp for locking depositing/withdrawing
        bool fundClosed;                // fund is closed
    }

    struct CycleState {
        uint128 totalFundValue;         // total fund value in asset tokens, at the end of the cycle
        uint128 fundValueAfterRequests; // fund value after requests are processed in asset tokens, at the end of the cycle
        uint128 requestedDeposits;      // total requested deposits during this cycle (in assets)
        uint128 convertedDeposits;      // converted deposits at the end of the cycle (in shares)
        uint128 requestedWithdrawals;   // total requested withdrawals during this cycle (in shares)
        uint128 convertedWithdrawals;   // converted withdrawals at the end of the cycle (in assets)
    }

    struct UserState {
        uint128 requestedDeposits;      // deposits requested but not converted (in assets)
        uint128 owedShares;             // shares available to be withdrawn
        uint128 requestedWithdrawals;   // withdrawals requested but not converted (in shares)
        uint128 owedAssets;             // assets available to be withdrawn
        uint32 requestCycleIndex;       // cycle index for requests (for both deposits and withdrawals)
    }

    // ------
    // events
    // ------

    event FundInitialized(address indexed caller, uint256 priceNumerator, uint256 priceDenominator, uint64 startTimestamp, address admin);
    event NFTEnabled(address indexed caller, uint32 indexed cycleIndex, address[] nfts);
    event DisableNFTChecks(address indexed caller, uint32 indexed cycleIndex, bool disableChecks);
    event FeeConfigChanged(address indexed caller, uint32 indexed cycleIndex, FeeConfig feeConfig);
    event EnterNextCycle(address indexed caller, uint32 indexed cycleIndex, uint256 fundValue, uint256 priceNumerator, uint256 priceDenominator, uint256 depositLimit, uint64 startTimestamp, uint64 lockTimestamp, bool fundClosed, uint256 platformFee, uint256 managerFee);
    event FundLockingTimestampUpdated(address indexed caller, uint32 indexed cycleIndex, uint64 lockTimestamp);
    event DepositLimitUpdated(address indexed caller, uint32 indexed cycleIndex, uint256 depositLimit);
    event UpdateTeaVaultV2(address indexed caller, uint32 indexed cycleIndex, address teaVaultV2);
    event DepositToVault(address indexed caller, uint32 indexed cycleIndex, address teaVaultV2, uint256 value);
    event WithdrawFromVault(address indexed caller, uint32 indexed cycleIndex, address teaVaultV2, uint256 value);
    event FundingChanged(address indexed caller, uint32 indexed cycleIndex, bool disableDepositing, bool disableWithdrawing, bool disableCancelDepositing, bool disableCancelWithdrawing);
    event DepositRequested(address indexed caller, uint32 indexed cycleIndex, address indexed receiver, uint256 assets);
    event DepositCanceled(address indexed caller, uint32 indexed cycleIndex, address indexed receiver, uint256 assets);
    event WithdrawalRequested(address indexed caller, uint32 indexed cycleIndex, address indexed owner, uint256 shares);
    event WithdrawalCanceled(address indexed caller, uint32 indexed cycleIndex, address indexed receiver, uint256 shares);
    event ClaimOwedAssets(address indexed caller, address indexed receiver, uint256 assets);
    event ClaimOwedShares(address indexed caller, address indexed receiver, uint256 shares);
    event ConvertToShares(address indexed owner, uint32 indexed cycleIndex, uint256 assets, uint256 shares);
    event ConvertToAssets(address indexed owner, uint32 indexed cycleIndex, uint256 shares, uint256 assets);

    // ---------------
    // admin functions
    // ---------------

    /// @notice Set the list of NFTs for allowing depositing
    /// @param _nfts addresses of the NFTs
    /// @notice Only available to admins
    function setEnabledNFTs(address[] memory _nfts) external;

    /// @notice Disable/enable NFT checks
    /// @param _checks true to disable NFT checks, false to enable
    /// @notice Only available to admins
    function setDisableNFTChecks(bool _checks) external;

    /// @notice Set fee structure and platform/manager vault addresses
    /// @param _feeConfig fee structure settings
    /// @notice Only available to admins
    function setFeeConfig(FeeConfig calldata _feeConfig) external;

    /// @notice Set TeaVaultV2 address
    /// @param _teaVaultV2 address to TeaVaultV2
    /// @notice Only available to admins
    function setTeaVaultV2(address _teaVaultV2) external;

    // -----------------
    // auditor functions
    // -----------------

    /// @notice Enter next cycle
    /// @param _cycleIndex current cycle index (to prevent accidental replay)
    /// @param _fundValue total fund value for this cycle
    /// @param _withdrawAmount amount to withdraw from TeaVaultV2
    /// @param _cycleStartTimestamp starting timestamp of the next cycle
    /// @param _fundingLockTimestamp funding lock timestamp for next cycle
    /// @param _closeFund true to close fund, irreversible
    /// @return platformFee total fee paid to the platform
    /// @return managerFee total fee paid to the manager
    /// @notice Only available to auditors
    /// @notice Use previewNextCycle function to get an estimation of required _withdrawAmount
    /// @notice _cycleStartTimestamp must be later than start timestamp of current cycle
    /// @notice and before the block timestamp when the transaction is confirmed
    /// @notice _fundValue can't be zero or close to zero except for the first first cycle
    function enterNextCycle(
        uint32 _cycleIndex,
        uint128 _fundValue,
        uint128 _depositLimit,
        uint128 _withdrawAmount,
        uint64 _cycleStartTimestamp,
        uint64 _fundingLockTimestamp,
        bool _closeFund) external returns (uint256 platformFee, uint256 managerFee);
    
    /// @notice Update fund locking timestamp
    /// @param _fundLockingTimestamp new timestamp for locking withdraw/deposits
    /// @notice Only available to auditors    
    function setFundLockingTimestamp(uint64 _fundLockingTimestamp) external;

    /// @notice Update deposit limit
    /// @param _depositLimit new deposit limit
    /// @notice Only available to auditors
    function setDepositLimit(uint128 _depositLimit) external;

    /// @notice Allowing/disabling depositing/withdrawing
    /// @param _disableDepositing true to allow depositing, false to disallow
    /// @param _disableWithdrawing true to allow withdrawing, false to disallow
    /// @param _disableCancelDepositing true to allow withdrawing, false to disallow
    /// @param _disableCancelWithdrawing true to allow withdrawing, false to disallow
    /// @notice Only available to auditors    
    function setDisableFunding(bool _disableDepositing, bool _disableWithdrawing, bool _disableCancelDepositing, bool _disableCancelWithdrawing) external;

    /// @notice Deposit fund to TeaVaultV2
    /// @notice Can not deposit locked assets
    /// @param _value value to deposit
    /// @notice Only available to auditors
    function depositToVault(uint256 _value) external;

    /// @notice Withdraw fund from TeaVaultV2
    /// @param _value value to withdraw
    /// @notice Only available to auditors
    function withdrawFromVault(uint256 _value) external;

    // --------------------------
    // functions available to all
    // --------------------------

    /// @notice Returns address of the asset token
    /// @return assetTokenAddress address of the asset token
    function asset() external view returns (address assetTokenAddress);

    /// @notice Request deposits
    /// @notice Actual deposits will be executed when entering the next cycle
    /// @param _assets amount of asset tokens to deposit
    /// @param _receiver address where the deposit is credited
    /// @notice _receiver need to have the required NFT
    /// @notice Request is disabled when time is later than fundingLockTimestamp
    function requestDeposit(uint256 _assets, address _receiver) external;

    /// @notice Claim owed assets and request deposits
    /// @notice Actual deposits will be executed when entering the next cycle
    /// @param _assets amount of asset tokens to deposit
    /// @param _receiver address where the deposit is credited
    /// @return assets amount of owed asset tokens claimed
    /// @notice _receiver need to have the required NFT
    /// @notice Request is disabled when time is later than fundingLockTimestamp
    function claimAndRequestDeposit(uint256 _assets, address _receiver) external returns (uint256 assets);

    /// @notice Cancel deposit requests
    /// @param _assets amount of asset tokens to cancel deposit
    /// @param _receiver address to receive the asset tokens
    /// @notice Request is disabled when time is later than fundingLockTimestamp
    function cancelDeposit(uint256 _assets, address _receiver) external;

    /// @notice Request withdrawals
    /// @notice Actual withdrawals will be executed when entering the next cycle
    /// @param _shares amount of share tokens to withdraw
    /// @param _owner owner address of share tokens
    /// @notice If _owner is different from msg.sender, _owner must approve msg.sender to spend share tokens
    /// @notice Request is disabled when time is later than fundingLockTimestamp
    function requestWithdraw(uint256 _shares, address _owner) external;

    /// @notice Claim owed shares and request withdrawals
    /// @notice Actual withdrawals will be executed when entering the next cycle
    /// @param _shares amount of share tokens to withdraw
    /// @param _owner owner address of share tokens
    /// @return shares amount of owed share tokens claimed
    /// @notice If _owner is different from msg.sender, _owner must approve msg.sender to spend share tokens
    /// @notice Request is disabled when time is later than fundingLockTimestamp
    function claimAndRequestWithdraw(uint256 _shares, address _owner) external returns (uint256 shares);

    /// @notice Cancel withdrawal requests
    /// @param _shares amount of share tokens to cancel withdrawal
    /// @param _receiver address to receive the share tokens
    /// @notice Request is disabled when time is later than fundingLockTimestamp
    function cancelWithdraw(uint256 _shares, address _receiver) external;

    /// @notice Returns currently requested deposits and withdrawals
    /// @param _owner address of the owner
    /// @return assets amount of asset tokens requested to be deposited
    /// @return shares amount of asset tokens requested to be withdrawn    
    function requestedFunds(address _owner) external view returns (uint256 assets, uint256 shares);

    /// @notice Claim owed assets
    /// @param _receiver address to receive the tokens
    /// @return assets amount of owed asset tokens claimed
    function claimOwedAssets(address _receiver) external returns (uint256 assets);

    /// @notice Claim owed shares
    /// @param _receiver address to receive the tokens
    /// @return shares amount of owed share tokens claimed
    function claimOwedShares(address _receiver) external returns (uint256 shares);

    /// @notice Claim owed assets and shares
    /// @param _receiver address to receive the tokens
    /// @return assets amount of owed asset tokens claimed
    /// @return shares amount of owed share tokens claimed
    function claimOwedFunds(address _receiver) external returns (uint256 assets, uint256 shares);

    /// @notice Close positions
    /// @notice Converted assets are added to owed assets
    /// @notice Only available when fund is closed
    /// @param _shares amount of share tokens to close
    /// @param _owner owner address of share tokens
    /// @return assets amount of assets converted
    /// @notice If _owner is different from msg.sender, _owner must approve msg.sender to spend share tokens
    function closePosition(uint256 _shares, address _owner) external returns (uint256 assets);

    /// @notice Close positions and claim all assets
    /// @notice Only available when fund is closed
    /// @param _receiver address to receive asset tokens
    /// @return assets amount of asset tokens withdrawn
    function closePositionAndClaim(address _receiver) external returns (uint256 assets);

    /// @notice Preview how much assets is required for entering next cycle
    /// @param _fundValue total fund value for this cycle
    /// @param _timestamp predicted timestamp for start of next cycle
    /// @return withdrawAmount amount of assets required
    function previewNextCycle(uint128 _fundValue, uint64 _timestamp) external view returns (uint256 withdrawAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
                /// @solidity memory-safe-assembly
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

// contracts/ITeaVaultV2.sol
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;


interface ITeaVaultV2 {

    function deposit(address _token, uint256 _amount) external;
    function withdraw(address _recipient, address _token, uint256 _amount) external;
    function deposit721(address _token, uint256 _tokenId) external;
    function withdraw721(address _recipient, address _token, uint256 _tokenId) external;
    function deposit1155(address _token, uint256 _tokenId, uint256 _amount) external;
    function withdraw1155(address _recipient, address _token, uint256 _tokenId, uint256 _amount) external;
    function depositETH(uint256 _amount) external payable;
    function withdrawETH(address payable _recipient, uint256 _amount) external;
    
}