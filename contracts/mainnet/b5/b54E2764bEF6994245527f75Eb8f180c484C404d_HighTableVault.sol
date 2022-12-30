// contracts/HighTableVault.sol
// SPDX-License-Identifier: BUSL
// Teahouse Finance

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./IHighTableVault.sol";


/// @title An investment vault for working with TeaVaultV2
/// @author Teahouse Finance
contract HighTableVault is IHighTableVault, AccessControl, ERC20 {

    uint256 public constant SECONDS_IN_A_YEAR = 365 * 86400;             // for calculating management fee
    bytes32 public constant AUDITOR_ROLE = keccak256("AUDITOR_ROLE");

    IERC20 internal assetToken;

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
    function setDepositSignature(bool _enableSignature, address _signatureAddress) external override {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert OnlyAvailableToAdmins();

        fundConfig.enableSignature = _enableSignature;
        fundConfig.signatureAddress = _signatureAddress;

        emit SignatureChanged(msg.sender, globalState.cycleIndex, _enableSignature, _signatureAddress);
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
            safeTransfer(assetToken, feeConfig.platformVault, platformFee);
        }

        if (managerFee > 0) {
            safeTransfer(assetToken, feeConfig.managerVault, managerFee);
        }

        // check if the remaining balance is enough for locked assets
        // and deposit extra balance back to the vault
        uint256 deposits = _internalCheckDeposits();
        if (deposits > 0) {
            safeApprove(assetToken, address(fundConfig.teaVaultV2), deposits);
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

        safeApprove(assetToken, address(fundConfig.teaVaultV2), _value);
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
        if (!_hasNFT(_receiver)) revert ReceiverDoNotHasNFT();

        safeTransferFrom(assetToken, msg.sender, address(this), _assets);
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
    /// @dev since recording of deposited assets happens after receiving assets
    /// @dev and assetToken has to be attacked in some way to perform reentrance
    function requestDepositWithSignature(uint256 _assets, address _receiver, uint64 _deadline, bytes calldata _signature) public override {
        _internalCheckSignature(_assets, _receiver, _deadline, _signature);
        safeTransferFrom(assetToken, msg.sender, address(this), _assets);
        _internalRequestDeposit(_assets, _receiver);
    }

    /// @inheritdoc IHighTableVault
    /// @dev No need for nonReentrant because there is no danger of reentrance attack
    /// @dev since recording of deposited assets happens after receiving assets
    /// @dev and assetToken has to be attacked in some way to perform reentrance
    function claimAndRequestDepositWithSignature(uint256 _assets, address _receiver, uint64 _deadline, bytes calldata _signature) external override returns (uint256 assets) {
        assets = claimOwedAssets(msg.sender);
        requestDepositWithSignature(_assets, _receiver, _deadline, _signature);
    }

    /// @inheritdoc IHighTableVault
    /// @dev No need for nonReentrant because there is no danger of reentrance attack
    /// @dev since removing of deposited assets happens before receiving assets
    /// @dev and assetToken has to be attacked in some way to perform reentrance
    function cancelDeposit(uint256 _assets, address _receiver) external override {
        _internalCancelDeposit(_assets, _receiver);
        safeTransfer(assetToken, _receiver, _assets);
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
        uint128 shares = toUint128(_shares);
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

        uint128 shares = toUint128(_shares);
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
            safeTransfer(assetToken, _receiver, assets);
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
        userState[_owner].owedAssets += toUint128(assets);
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
            uint128 finalFundValue = toUint128(cycleState[globalState.cycleIndex].fundValueAfterRequests - pFee - mFee);
            closePrice = Price(finalFundValue, toUint128(totalSupply()));
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
            cycleState[cycleIndex].convertedWithdrawals = toUint128(withdrawnAssets - pFee - mFee);
            globalState.lockedAssets += cycleState[cycleIndex].convertedWithdrawals;
            fundValueAfterRequests -= toUint128(withdrawnAssets);

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
            fundValueAfterRequests += toUint128(requestedDeposits);

            if (currentTotalSupply == 0) {
                // use initial price if there's no share tokens
                cycleState[cycleIndex].convertedDeposits = toUint128(requestedDeposits * initialPrice.denominator / initialPrice.numerator);
            }
            else {
                // _fundValueAfterPMFees is checked to be non-zero when total supply is non-zero
                cycleState[cycleIndex].convertedDeposits = toUint128(requestedDeposits * currentTotalSupply / _fundValueAfterPMFees);
            }

            platformFee += pFee;
            managerFee += mFee;

            // mint new share tokens
            _mint(address(this), cycleState[cycleIndex].convertedDeposits);
        }

        cycleState[cycleIndex].fundValueAfterRequests = toUint128(fundValueAfterRequests);
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
            userState[_receiver].owedShares += toUint128(owedShares);
            emit ConvertToShares(_receiver, cycleIndex, userState[_receiver].requestedDeposits, owedShares);
            userState[_receiver].requestedDeposits = 0;
        }

        if (userState[_receiver].requestedWithdrawals > 0) {
            // if requestedWithdrawals of a user > 0 then requestedWithdrawals of the cycle must be > 0
            uint256 owedAssets = uint256(userState[_receiver].requestedWithdrawals) * cycleState[cycleIndex].convertedWithdrawals / cycleState[cycleIndex].requestedWithdrawals;
            userState[_receiver].owedAssets += toUint128(owedAssets);
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

        uint32 cycleIndex = globalState.cycleIndex;
        uint128 assets = toUint128(_assets);
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

        uint128 assets = toUint128(_assets);
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

    /// @notice Internal signature checker
    /// @param _assets amount of asset tokens to deposit
    /// @param _receiver address where the deposit is credited
    /// @param _deadline timestamp which the signature is valid before
    /// @param _signature signature provided by the server
    function _internalCheckSignature(uint256 _assets, address _receiver, uint64 _deadline, bytes calldata _signature) internal view {
        if (!fundConfig.enableSignature) revert DepositSignatureNotEnabled();
        if (fundConfig.signatureAddress == address(0)) revert SignatureAddressNotSet();
        if (block.timestamp > _deadline) revert PassedSignatureDeadline();

        bytes32 hash = keccak256(abi.encodePacked(msg.sender, _assets, _receiver, _deadline));
        hash = ECDSA.toEthSignedMessageHash(hash);
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, _signature);
        if (error != ECDSA.RecoverError.NoError) revert IncorrectDepositSignature();
        if (recovered != fundConfig.signatureAddress) revert IncorrectDepositSignature();
    }

    /// @dev Copied from OpenZeppelin's SafeCast in order to reduce code size
    function toUint128(uint256 value) internal pure returns (uint128) {
        if (value > type(uint128).max) revert ValueDoesNotFitIn128Bits();
        return uint128(value);
    }

    /// @dev Copied from OpenZeppelin's SafeERC20 in order to reduce code size
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /// @dev Copied from OpenZeppelin's SafeERC20 in order to reduce code size
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }    

    /// @dev Copied from OpenZeppelin's SafeERC20 in order to reduce code size
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @dev Copied from OpenZeppelin's SafeERC20 in order to reduce code size.
     * @param _token The token targeted by the call.
     * @param _data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 _token, bytes memory _data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = _functionCall(address(_token), _data);
        if (returndata.length > 0) {
            // Return data is optional
            if (!abi.decode(returndata, (bool))) revert ERC20CallFailed();
        }
    }

    /// @dev Adapted from Openzeppelin's Address in order to reduce code size
    /// @param _target Must be a contract
    /// @param _data The call data (encoded using abi.encode or one of its variants).
    function _functionCall(address _target, bytes memory _data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = _target.call(_data);
        if (success) {
            if (returndata.length == 0) {
                if (_target.code.length == 0) revert FunctionCallFailed();
            }

            return returndata;
        }
        else {
           if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            }
            else {
                revert FunctionCallFailed();
            }
        }
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
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
error DepositSignatureNotEnabled();         // deposit with signature not enabled
error SignatureAddressNotSet();             // deposit signature address not set
error PassedSignatureDeadline();            // signature deadline is already passed
error IncorrectDepositSignature();          // incorrect deposit signature
error FunctionCallFailed();                 // function call failed
error ERC20CallFailed();                    // ERC20 call returned false
error ValueDoesNotFitIn128Bits();           // Value too large to fit into uint128

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
        bool enableSignature;           // enable deposits with signature
        address signatureAddress;       // signature address
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
    event SignatureChanged(address indexed caller, uint32 indexed cycleIndex, bool enableSignature, address signatureAddress);
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

    /// @notice Enabling/disabling deposit with signature function
    /// @param _enableSignature true to enable deposit with signature, false to disable
    /// @param _signatureAddress signature address
    /// @notice Only available to admins
    function setDepositSignature(bool _enableSignature, address _signatureAddress) external;    

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

    /// @notice Request deposits with signature
    /// @notice Actual deposits will be executed when entering the next cycle
    /// @param _assets amount of asset tokens to deposit
    /// @param _receiver address where the deposit is credited
    /// @param _deadline timestamp which the signature is valid before
    /// @param _signature signature provided by the server
    /// @notice Request is disabled when time is later than fundingLockTimestamp
    function requestDepositWithSignature(uint256 _assets, address _receiver, uint64 _deadline,  bytes calldata _signature) external;

    /// @notice Claim owed assets and request deposits with signature
    /// @notice Actual deposits will be executed when entering the next cycle
    /// @param _assets amount of asset tokens to deposit
    /// @param _receiver address where the deposit is credited
    /// @param _deadline timestamp which the signature is valid before
    /// @param _signature signature provided by the server
    /// @return assets amount of owed asset tokens claimed
    /// @notice Request is disabled when time is later than fundingLockTimestamp
    function claimAndRequestDepositWithSignature(uint256 _assets, address _receiver, uint64 _deadline, bytes calldata _signature) external returns (uint256 assets);    

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