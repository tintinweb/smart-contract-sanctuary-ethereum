// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.13;

import "./ZeroBTCConfig.sol";
import "./ZeroBTCLoans.sol";

contract ZeroBTC is ZeroBTCBase, ZeroBTCCache, ZeroBTCConfig, ZeroBTCLoans {
  constructor(
    IGatewayRegistry gatewayRegistry,
    IChainlinkOracle btcEthPriceOracle,
    IChainlinkOracle gasPriceOracle,
    IRenBtcEthConverter renBtcConverter,
    uint256 cacheTimeToLive,
    uint256 maxLoanDuration,
    uint256 targetEthReserve,
    uint256 maxGasProfitShareBips,
    address zeroFeeRecipient,
    address _asset,
    address _proxyContract
  )
    ZeroBTCBase(
      gatewayRegistry,
      btcEthPriceOracle,
      gasPriceOracle,
      renBtcConverter,
      cacheTimeToLive,
      maxLoanDuration,
      targetEthReserve,
      maxGasProfitShareBips,
      zeroFeeRecipient,
      _asset,
      _proxyContract
    )
  {}

  function initialize(
    address initialGovernance,
    uint256 zeroBorrowFeeBips,
    uint256 renBorrowFeeBips,
    uint256 zeroBorrowFeeStatic,
    uint256 renBorrowFeeStatic,
    uint256 zeroFeeShareBips,
    address initialHarvester
  ) public payable virtual override {
    ZeroBTCBase.initialize(
      initialGovernance,
      zeroBorrowFeeBips,
      renBorrowFeeBips,
      zeroBorrowFeeStatic,
      renBorrowFeeStatic,
      zeroFeeShareBips,
      initialHarvester
    );
    _updateGlobalCache(_state);
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.13;

import "./ZeroBTCCache.sol";
import "../utils/Math.sol";
import { IStrategy } from "../../interfaces/IStrategy.sol";

abstract contract ZeroBTCConfig is ZeroBTCCache {
  using ModuleStateCoder for ModuleState;
  using GlobalStateCoder for GlobalState;
  using LoanRecordCoder for LoanRecord;
  using Math for uint256;

  /*//////////////////////////////////////////////////////////////
                         Governance Actions
  //////////////////////////////////////////////////////////////*/

  function setGlobalFees(
    uint256 zeroBorrowFeeBips,
    uint256 renBorrowFeeBips,
    uint256 zeroBorrowFeeStatic,
    uint256 renBorrowFeeStatic,
    uint256 zeroFeeShareBips
  ) external onlyGovernance nonReentrant {
    _setFees(zeroBorrowFeeBips, renBorrowFeeBips, zeroBorrowFeeStatic, renBorrowFeeStatic, zeroFeeShareBips);
  }

  function setModuleGasFees(
    address module,
    uint256 loanGas,
    uint256 repayGas
  ) external onlyGovernance nonReentrant {
    (GlobalState state, ) = _getUpdatedGlobalState();
    ModuleState moduleState = _getExistingModuleState(module);
    // Divide loan and repay gas by 10000
    uint256 loanGasE4 = loanGas.uncheckedDivUpE4();
    uint256 repayGasE4 = repayGas.uncheckedDivUpE4();
    moduleState = moduleState.setGasParams(loanGasE4, repayGasE4);
    _updateModuleCache(state, moduleState, module);
  }

  function addModule(
    address module,
    ModuleType moduleType,
    uint256 loanGas,
    uint256 repayGas
  ) external onlyGovernance nonReentrant {
    if (module != address(0)) {
      address moduleAsset = IZeroModule(module).asset();
      if (moduleAsset != asset) {
        revert ModuleAssetDoesNotMatch(moduleAsset);
      }
    }

    if (loanGas == 0 || repayGas == 0) {
      revert InvalidNullValue();
    }

    // Module type can not be null unless address is 0
    // If address is 0, module type must be null
    if ((moduleType == ModuleType.Null) != (module == address(0))) {
      revert InvalidModuleType();
    }

    // Divide loan and repay gas by 10000
    uint256 loanGasE4 = loanGas.uncheckedDivUpE4();
    uint256 repayGasE4 = repayGas.uncheckedDivUpE4();

    // Get updated global state, with cache refreshed if it had expired
    (GlobalState state, ) = _getUpdatedGlobalState();

    // Calculate the new gas refunds for the module
    (
      uint256 ethRefundForLoanGas,
      uint256 ethRefundForRepayGas,
      uint256 btcFeeForLoanGas,
      uint256 btcFeeForRepayGas
    ) = _calculateModuleGasFees(state, loanGasE4, repayGasE4);

    // Write the module data to storage
    _moduleFees[module] = ModuleStateCoder.encode(
      moduleType,
      loanGasE4,
      repayGasE4,
      ethRefundForLoanGas,
      ethRefundForRepayGas,
      btcFeeForLoanGas,
      btcFeeForRepayGas,
      block.timestamp
    );

    // delegatecall initialize on the module
    (bool success, ) = module.delegatecall(abi.encodeWithSelector(IZeroModule.initialize.selector));
    require(success, "module uninitialized");

    emit ModuleStateUpdated(module, moduleType, loanGasE4, repayGasE4);
  }

  function removeModule(address module) external onlyGovernance nonReentrant {
    _moduleFees[module] = DefaultModuleState;
  }

  function setHarvesters(address[] memory users) external onlyGovernance nonReentrant {
    for (uint256 i = 0; i < users.length; i++) _isHarvester[users[i]] = true;
  }

  function removeHarvesters(address[] memory users) external onlyGovernance nonReentrant {
    for (uint256 i = 0; i < users.length; i++) _isHarvester[users[i]] = false;
  }

  function setAuthorizedUsers(address[] memory users) external onlyGovernance nonReentrant {
    for (uint256 i = 0; i < users.length; i++) _authorized[users[i]] = true;
  }

  function removeAuthorizedUsers(address[] memory users) external onlyGovernance nonReentrant {
    for (uint256 i = 0; i < users.length; i++) _authorized[users[i]] = false;
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.13;

import "./ZeroBTCCache.sol";
import { DefaultLoanRecord } from "../utils/LoanRecordCoder.sol";
import { BaseModule } from "../BaseModule.sol";
import "../utils/FixedPointMathLib.sol";

uint256 constant ReceiveLoanError_selector = 0x83f44e2200000000000000000000000000000000000000000000000000000000;
uint256 constant RepayLoanError_selector = 0x0ccaea8800000000000000000000000000000000000000000000000000000000;
uint256 constant RepayLoan_selector = 0x2584dde800000000000000000000000000000000000000000000000000000000;
uint256 constant ReceiveLoan_selector = 0x332b578c00000000000000000000000000000000000000000000000000000000;

uint256 constant ModuleCall_borrower_offset = 0x04;
uint256 constant ModuleCall_amount_offset = 0x24;
uint256 constant ModuleCall_loanId_offset = 0x44;
uint256 constant ModuleCall_data_head_offset = 0x64;
uint256 constant ModuleCall_data_length_offset = 0x84;
uint256 constant ModuleCall_data_offset = 0x80;
uint256 constant ModuleCall_calldata_baseLength = 0xa4;

abstract contract ZeroBTCLoans is ZeroBTCCache {
  using ModuleStateCoder for ModuleState;
  using GlobalStateCoder for GlobalState;
  using LoanRecordCoder for LoanRecord;
  using SafeTransferLib for address;
  using FixedPointMathLib for uint256;
  using Math for uint256;

  modifier onlyHarvester() {
    require(_isHarvester[msg.sender], "cannot call unless harvester");
    _;
  }

  /*//////////////////////////////////////////////////////////////
                             Constructor
  //////////////////////////////////////////////////////////////*/

  constructor() {
    if (
      uint256(bytes32(IZeroModule.receiveLoan.selector)) != ReceiveLoan_selector ||
      uint256(bytes32(IZeroModule.repayLoan.selector)) != RepayLoan_selector ||
      uint256(bytes32(ReceiveLoanError.selector)) != ReceiveLoanError_selector ||
      uint256(bytes32(RepayLoanError.selector)) != RepayLoanError_selector
    ) {
      revert InvalidSelector();
    }
  }

  /*//////////////////////////////////////////////////////////////
                        External Loan Actions
  //////////////////////////////////////////////////////////////*/

  /**
   * @param module Module to use for conversion
   * @param borrower Account to receive loan
   * @param borrowAmount Amount of vault's underlying asset to borrow
   * @param nonce Nonce for the loan, provided by keeper
   * @param data User provided data
   */
  function loan(
    address module,
    address borrower,
    uint256 borrowAmount,
    uint256 nonce,
    bytes memory data
  ) external override nonReentrant {
    (GlobalState state, ModuleState moduleState) = _getUpdatedGlobalAndModuleState(module);

    uint256 loanId = _deriveLoanId(msg.sender, _deriveLoanPHash(data));

    (uint256 actualBorrowAmount, uint256 lenderDebt, uint256 btcFeeForLoanGas) = _calculateLoanFees(
      state,
      moduleState,
      borrowAmount
    );

    // Store loan information and lock lender's shares
    _borrowFrom(uint256(loanId), msg.sender, borrower, actualBorrowAmount, lenderDebt, btcFeeForLoanGas);

    if (uint256(moduleState.getModuleType()) > 0) {
      // Execute module interaction
      _executeReceiveLoan(module, borrower, loanId, actualBorrowAmount, data);
    } else {
      // If module does not override loan behavior,
      asset.safeTransfer(borrower, actualBorrowAmount);
    }

    tx.origin.safeTransferETH(moduleState.getEthRefundForLoanGas());
  }

  /**
   * @param module Module used for the loan
   * @param borrower Address of account that took out the loan
   * @param borrowAmount Original loan amount before fees
   * @param nonce Nonce for the loan
   * @param data Extra data used by module
   * @param lender Address of account that gave the loan
   * @param nHash Nonce hash from RenVM deposit
   * @param renSignature Signature from RenVM
   */
  function repay(
    address module,
    address borrower,
    uint256 borrowAmount,
    uint256 nonce,
    bytes memory data,
    address lender,
    bytes32 nHash,
    bytes memory renSignature
  ) external override nonReentrant {
    (GlobalState state, ModuleState moduleState) = _getUpdatedGlobalAndModuleState(module);

    bytes32 pHash = _deriveLoanPHash(data);
    uint256 repaidAmount = _getGateway().mint(pHash, borrowAmount, nHash, renSignature);

    uint256 loanId = _deriveLoanId(lender, pHash);
    if (moduleState.getModuleType() == ModuleType.LoanAndRepayOverride) {
      repaidAmount = _executeRepayLoan(module, borrower, loanId, repaidAmount, data);
    }
    LoanRecord loanRecord = _deleteLoan(loanId);

    _repayTo(state, moduleState, loanRecord, lender, loanId, repaidAmount);

    tx.origin.safeTransferETH(moduleState.getEthRefundForRepayGas());
  }

  function closeExpiredLoan(
    address module,
    address borrower,
    uint256 borrowAmount,
    uint256 nonce,
    bytes memory data,
    address lender
  ) external override nonReentrant {
    uint256 loanId = _deriveLoanId(lender, _deriveLoanPHash(data));
    LoanRecord loanRecord = _deleteLoan(loanId);
    if (loanRecord.getExpiry() >= block.timestamp) {
      revert LoanNotExpired(loanId);
    }
    (GlobalState state, ModuleState moduleState) = _getUpdatedGlobalAndModuleState(module);
    ModuleType moduleType = moduleState.getModuleType();
    uint256 repaidAmount = 0;
    if (moduleType == ModuleType.LoanAndRepayOverride) {
      repaidAmount = _executeRepayLoan(module, borrower, loanId, repaidAmount, data);
    }

    _repayTo(state, moduleState, loanRecord, lender, loanId, repaidAmount);

    tx.origin.safeTransferETH(moduleState.getEthRefundForRepayGas());
  }

  function earn() external override onlyHarvester nonReentrant {
    (GlobalState state, ) = _getUpdatedGlobalState();
    (uint256 unburnedGasReserveShares, uint256 unburnedZeroFeeShares) = state.getUnburnedShares();
    _state = state.setUnburnedShares(0, 0);
    uint256 totalFeeShares;
    uint256 totalFees;
    uint256 supply = _totalSupply;
    uint256 assets = totalAssets();
    unchecked {
      totalFeeShares = unburnedGasReserveShares + unburnedZeroFeeShares;
      totalFees = totalFeeShares.mulDivDown(assets, supply);
      _totalSupply = supply - totalFeeShares;
    }
    uint256 minimumEthOut = (_btcToEth(totalFees, state.getSatoshiPerEth()) * 98) / 100;
    asset.safeTransfer(address(_renBtcConverter), totalFees);
    uint256 actualEthOut = _renBtcConverter.convertToEth(minimumEthOut);
    uint256 ethForZero = unburnedZeroFeeShares.mulDivDown(actualEthOut, totalFeeShares);
    _zeroFeeRecipient.safeTransferETH(ethForZero);
    emit FeeSharesBurned(actualEthOut - ethForZero, unburnedGasReserveShares, ethForZero, unburnedZeroFeeShares);
  }

  /*//////////////////////////////////////////////////////////////
                          External Getters
  //////////////////////////////////////////////////////////////*/

  function getOutstandingLoan(uint256 loanId)
    external
    view
    override
    returns (
      uint256 sharesLocked,
      uint256 actualBorrowAmount,
      uint256 lenderDebt,
      uint256 btcFeeForLoanGas,
      uint256 expiry
    )
  {
    return _outstandingLoans[loanId].decode();
  }

  /**
   * @dev Derives a loan ID from the combination of the loan's
   * pHash, derived from the loan parameters (module, borrower,
   * borrowAmount, nonce, data), and the lender's address.
   */
  function calculateLoanId(
    address module,
    address borrower,
    uint256 borrowAmount,
    uint256 nonce,
    bytes memory data,
    address lender
  ) external view override returns (uint256) {
    return _deriveLoanId(lender, _deriveLoanPHash(data));
  }

  /*//////////////////////////////////////////////////////////////
                          Module Interactions
  //////////////////////////////////////////////////////////////*/

  // function _prepareModuleCalldata(
  //   uint256 selector,
  //   address borrower,
  //   uint256 amount,
  //   uint256 loanId,
  //   bytes memory data
  // ) internal view {
  //   bytes32 startptr;
  //   bytes32 datalocation;
  //   console.log(amount);
  //   assembly {
  //     let startPtr := sub(data, ModuleCall_data_offset)
  //     startptr := startPtr
  //     // Write function selector
  //     mstore(startPtr, selector)
  //     // Write borrower
  //     mstore(add(startPtr, ModuleCall_borrower_offset), amount)
  //     datalocation := mload(add(startPtr, ModuleCall_amount_offset))
  //   }
  //   console.logBytes32(datalocation);
  //   assembly {
  //     let startPtr := sub(data, ModuleCall_data_offset)
  //     // Write borrowAmount or repaidAmount
  //     mstore(add(startPtr, ModuleCall_amount_offset), amount)
  //     // Write loanId
  //     mstore(add(startPtr, ModuleCall_loanId_offset), loanId)
  //     // Write data offset
  //     mstore(add(startPtr, ModuleCall_data_head_offset), ModuleCall_data_length_offset)
  //   }
  // }

  function _executeReceiveLoan(
    address module,
    address borrower,
    uint256 loanId,
    uint256 borrowAmount,
    bytes memory data
  ) internal {
    // _prepareModuleCalldata(ReceiveLoan_selector, borrower, borrowAmount, loanId, data);
    (bool success, ) = module.delegatecall(
      abi.encodeWithSelector(bytes4(bytes32(ReceiveLoan_selector)), borrower, borrowAmount, loanId, data)
    );
    require(success, "!module");
    /* assembly {
      let startPtr := sub(data, ModuleCall_data_offset)
      // Size of data + (selector, borrower, borrowAmount, loanId, data_offset, data_length)
      let calldataLength := add(mload(data), ModuleCall_calldata_baseLength)
      // Delegatecall module
      let status := delegatecall(gas(), module, startPtr, calldataLength, 0, 0)

      // Handle failures
      if iszero(status) {
        // If return data was provided, bubble up
        if returndatasize() {
          returndatacopy(0, 0, returndatasize())
          revert(0, returndatasize())
        }
        // If no return data was provided, throw generic error
        // Write ReceiveLoanError.selector
        mstore(sub(startPtr, 0x20), ReceiveLoanError_selector)
        // Write module to memory
        mstore(sub(startPtr, 0x1c), module)
        // Update data offset
        mstore(add(startPtr, 0x64), 0xa0)
        // Revert with ReceiveLoanError
        revert(sub(startPtr, 0x20), add(calldataLength, 0x20))
      }
    }*/
  }

  function _executeRepayLoan(
    address module,
    address borrower,
    uint256 loanId,
    uint256 repaidAmount,
    bytes memory data
  ) internal returns (uint256 collateralToUnlock) {
    // _prepareModuleCalldata(RepayLoan_selector, borrower, repaidAmount, loanId, data);
    (bool success, bytes memory _data) = module.delegatecall(
      abi.encodeWithSelector(bytes4(bytes32(RepayLoan_selector)), borrower, repaidAmount, loanId, data)
    );
    require(success, "!module");
    (collateralToUnlock) = abi.decode(_data, (uint256));
    /* assembly {
      let startPtr := sub(data, ModuleCall_data_offset)
      // Size of data + (selector, borrower, borrowAmount, loanId, data_offset, data_length)
      let calldataLength := add(mload(data), ModuleCall_calldata_baseLength)
      // Delegatecall module
      let status := delegatecall(gas(), module, startPtr, calldataLength, 0, 0x20)

      // Handle failures
      if iszero(status) {
        // If return data was provided, bubble up
        if returndatasize() {
          returndatacopy(0, 0, returndatasize())
          revert(0, returndatasize())
        }
        // If no return data was provided, throw generic error
        // Write RepayLoanError.selector
        mstore(sub(startPtr, 0x20), RepayLoanError_selector)
        // Write module to memory
        mstore(sub(startPtr, 0x1c), module)
        // Update data offset
        mstore(add(startPtr, 0x64), 0xa0)
        // Revert with RepayLoanError
        revert(sub(startPtr, 0x20), add(calldataLength, 0x20))
      }
      collateralToUnlock := mload(0)
    } */
  }

  /*//////////////////////////////////////////////////////////////
                       Internal Loan Handling
  //////////////////////////////////////////////////////////////*/

  function _deriveLoanPHash(bytes memory data)
    internal
    view
    RestoreFreeMemoryPointer
    RestoreZeroSlot
    RestoreFirstTwoUnreservedSlots
    returns (bytes32 pHash)
  {
    assembly {
      // Write data hash first, since its buffer will be overwritten by the following section
      mstore(0xa0, keccak256(add(data, 0x20), mload(data)))
      // Write vault address
      mstore(0, address())
      // Copy module, borrower, borrowAmount, nonce to hash buffer
      calldatacopy(0x20, 0x04, 0x80)
      pHash := keccak256(0, 0xc0)
    }
  }

  function _deriveLoanId(address lender, bytes32 pHash) internal pure returns (uint256 loanId) {
    assembly {
      mstore(0, lender)
      mstore(0x20, pHash)
      loanId := keccak256(0, 0x40)
    }
  }

  function _getAndSetLoan(uint256 loanId, LoanRecord newRecord) internal returns (LoanRecord oldRecord) {
    assembly {
      mstore(0, loanId)
      mstore(0x20, _outstandingLoans.slot)
      let loanSlot := keccak256(0, 0x40)
      oldRecord := sload(loanSlot)
      sstore(loanSlot, newRecord)
    }
  }

  function _deleteLoan(uint256 loanId) internal returns (LoanRecord loanRecord) {
    loanRecord = _getAndSetLoan(loanId, DefaultLoanRecord);

    // Ensure the loan exists
    if (loanRecord.isNull()) {
      revert LoanDoesNotExist(loanId);
    }
  }

  /**
   * @notice Lock lender shares until they repay `borrowedAmount`.
   *
   * `lenderDebt` is higher than `borrowAmount`, the amount leaving
   * the contract, to account for gas fees paid to keepers in ETH
   * as well as protocol fees from Zero.
   *
   * The lender will have an amount of shares equivalent to `lenderDebt` locked,
   * and will have a fraction of those shares unlocked on repayment.
   *
   * @param loanId Identifier for the loan
   * @param lender Account lending assets
   * @param borrower Account borrowing assets
   * @param actualBorrowAmount Amount of `asset` sent to borrower
   * @param lenderDebt Amount of `asset` lender is responsible for repaying
   * @param vaultExpenseWithoutRepayFee Amount of `asset` vault is expecting back without
   * accounting for btc value of repay gas refund
   */
  function _borrowFrom(
    uint256 loanId,
    address lender,
    address borrower,
    uint256 actualBorrowAmount,
    uint256 lenderDebt,
    uint256 vaultExpenseWithoutRepayFee
  ) internal {
    // Calculate the amount of shares to lock
    uint256 shares = previewWithdraw(lenderDebt);

    unchecked {
      GlobalState state = _state;
      uint256 totalBitcoinBorrowed = state.getTotalBitcoinBorrowed();
      _state = state.setTotalBitcoinBorrowed(totalBitcoinBorrowed + actualBorrowAmount);
    }

    LoanRecord oldRecord = _getAndSetLoan(
      loanId,
      LoanRecordCoder.encode(
        shares,
        actualBorrowAmount,
        lenderDebt,
        vaultExpenseWithoutRepayFee,
        block.timestamp + _maxLoanDuration
      )
    );

    if (!oldRecord.isNull()) {
      revert LoanIdNotUnique(loanId);
    }
    // Reduce lender's balance to lock shares for their debt
    _balanceOf[lender] -= shares;

    // Emit transfer event so indexing services can correctly track the
    // lender's balance
    emit Transfer(lender, address(this), shares);

    // Emit event for loan creation
    emit LoanCreated(lender, borrower, loanId, actualBorrowAmount, shares);
  }

  /**
   * @notice Repay assets for a loan and unlock the shares of the lender
   * at the original price they were locked at. If less than the full
   * amount is repaid, the remainder of the shares are burned. This can
   * only be called once so full repayment will not eventually occur if
   * the loan is only partially repaid first.
   *
   * Note: amountRepaid MUST have already been received by the vault
   * before this function is called.
   *
   * @param state Global state
   * @param moduleState Module state
   * @param loanRecord Loan record
   * @param lender Account that gave the loan
   * @param loanId Identifier for the loan
   * @param repaidAmount Amount of underlying repaid
   */
  function _repayTo(
    GlobalState state,
    ModuleState moduleState,
    LoanRecord loanRecord,
    address lender,
    uint256 loanId,
    uint256 repaidAmount
  ) internal {
    // Unlock/burn shares for repaid amount
    (uint256 sharesUnlocked, uint256 sharesBurned) = _unlockSharesForLoan(loanRecord, lender, repaidAmount);

    // Handle fees for gas reserves and ZeroDAO
    _state = _collectLoanFees(state, moduleState, loanRecord, repaidAmount, lender);

    // Emit event for loan repayment
    emit LoanClosed(loanId, repaidAmount, sharesUnlocked, sharesBurned);
  }

  function _unlockSharesForLoan(
    LoanRecord loanRecord,
    address lender,
    uint256 repaidAmount
  ) internal returns (uint256 sharesUnlocked, uint256 sharesBurned) {
    (uint256 sharesLocked, uint256 lenderDebt) = loanRecord.getSharesAndDebt();

    sharesUnlocked = sharesLocked;

    // If loan is less than fully repaid
    if (repaidAmount < lenderDebt) {
      // Unlock shares proportional to the fraction repaid
      sharesUnlocked = repaidAmount.mulDivDown(sharesLocked, lenderDebt);
      unchecked {
        // sharesUnlocked will always be less than sharesLocked
        sharesBurned = sharesLocked - sharesUnlocked;
        // The shares have already been subtracted from the lender's balance
        // so no balance update is needed.
        // totalSupply will always be greater than sharesBurned.
        _totalSupply -= sharesBurned;
      }
      // Emit transfer event so indexing services can correctly track the
      // totalSupply.
      emit Transfer(address(this), address(0), sharesBurned);
    }

    // If any shares should be unlocked, add them back to the lender's balance
    if (sharesUnlocked > 0) {
      // Cannot overflow because the sum of all user balances
      // can't exceed the max uint256 value.
      unchecked {
        _balanceOf[lender] += sharesUnlocked;
      }
      // Emit transfer event so indexing services can correctly track the
      // lender's balance
      emit Transfer(address(this), lender, sharesUnlocked);
    }
  }

  function _collectLoanFees(
    GlobalState state,
    ModuleState moduleState,
    LoanRecord loanRecord,
    uint256 repaidAmount,
    address lender
  ) internal returns (GlobalState) {
    (uint256 btcForGasReserve, uint256 ethForGasReserve) = _getEffectiveGasCosts(state, moduleState, loanRecord);
    uint256 newBalance = address(this).balance + ethForGasReserve;
    uint256 actualBorrowAmount = loanRecord.getActualBorrowAmount();
    unchecked {
      // `actualBorrowAmount` has already been added to `totalBitcoinBorrowed`
      uint256 totalBitcoinBorrowed = state.getTotalBitcoinBorrowed();
      state = state.setTotalBitcoinBorrowed(totalBitcoinBorrowed - actualBorrowAmount);
    }

    uint256 profit = repaidAmount.subMinZero(actualBorrowAmount + btcForGasReserve);
    if (profit == 0) {
      return state;
    }

    // If vault's gas reserves are below the target, reduce the profit shared
    // with ZeroDAO and vault LPs by up to `(profit * maxGasProfitShareBips) / 10000`
    if (newBalance < _targetEthReserve) {
      // Calculate amount of ETH needed to reach target gas reserves
      uint256 btcNeededForTarget = _ethToBtc(_targetEthReserve - newBalance, state.getSatoshiPerEth());
      // Calculate maximum amount of profit that can be used to meet reserves
      uint256 maxReservedBtcForGas = profit.uncheckedMulBipsUp(_maxGasProfitShareBips);
      // Take the minimum of the two values
      uint256 reservedProfit = Math.min(btcNeededForTarget, maxReservedBtcForGas);
      unchecked {
        // Reduce the profit that will be split between the vault's LPs and ZeroDAO
        profit -= reservedProfit;
        // Increase the BTC value that will be withheld for gas reserves
        btcForGasReserve += reservedProfit;
      }
    }
    return _mintFeeShares(state, profit, btcForGasReserve, lender);
  }

  function _mintFeeShares(
    GlobalState state,
    uint256 profit,
    uint256 btcForGasReserve,
    address lender
  ) internal returns (GlobalState) {
    // @todo Clean up - nested scopes temporary to get around stack too deep
    uint256 newSupply;
    uint256 _totalAssets;

    // Cache the total supply to avoid extra SLOADs
    uint256 supply = _totalSupply;

    {
      uint256 gasReserveShares;
      uint256 zeroFeeShares;
      {
        // Calculate share of profits owed to ZeroDAO
        uint256 btcForZeroDAO = profit.uncheckedMulBipsUp(state.getZeroFeeShareBips());

        // Keeper receives profits not allocated for gas reserves or ZeroDAO
        uint256 btcForKeeper = profit - btcForZeroDAO;

        // Get the underlying assets held by the vault or in outstanding loans and subtract
        // the fees that will be charged in order to calculate the number of shares to mint
        // that will be worth the fees.
        _totalAssets =
          (ERC4626.totalAssets() + state.getTotalBitcoinBorrowed()) -
          (btcForGasReserve + btcForZeroDAO + btcForKeeper);

        // Calculate shares to mint for the gas reserves and ZeroDAO fees
        gasReserveShares = btcForGasReserve.mulDivDown(supply, _totalAssets);
        zeroFeeShares = (btcForZeroDAO).mulDivDown(supply, _totalAssets);
        // Emit event for fee shares
        emit FeeSharesMinted(btcForGasReserve, gasReserveShares, btcForZeroDAO, zeroFeeShares);
      }

      newSupply = supply + gasReserveShares + zeroFeeShares;

      // Get the current fee share totals
      (uint256 unburnedGasReserveShares, uint256 unburnedZeroFeeShares) = state.getUnburnedShares();

      // Write the new fee share totals to the global state on the stack
      state = state.setUnburnedShares(
        unburnedGasReserveShares + gasReserveShares,
        unburnedZeroFeeShares + zeroFeeShares
      );
    }

    {
      uint256 keeperShares = profit.mulDivDown(supply, _totalAssets);
      // Emit transfer for mint of keeper shares
      emit Transfer(address(0), lender, keeperShares);
      newSupply += keeperShares;

      // Add keeper shares to lender's balance
      unchecked {
        _balanceOf[lender] += keeperShares;
      }
    }

    // Add the new shares to the total supply. They are not added to any balance but we track
    // them in the global state.
    _totalSupply = newSupply;

    return state;
  }

  function _getEffectiveGasCosts(
    GlobalState state,
    ModuleState moduleState,
    LoanRecord loanRecord
  ) internal pure returns (uint256 btcSpentOnGas, uint256 ethSpentOnGas) {
    uint256 satoshiPerEth = state.getSatoshiPerEth();
    uint256 btcForLoanGas = loanRecord.getBtcFeeForLoanGas();
    btcSpentOnGas = btcForLoanGas + moduleState.getBtcFeeForRepayGas();
    ethSpentOnGas = _btcToEth(btcForLoanGas, satoshiPerEth) + moduleState.getEthRefundForRepayGas();
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.13;

import "./ZeroBTCBase.sol";

abstract contract ZeroBTCCache is ZeroBTCBase {
  using ModuleStateCoder for ModuleState;
  using GlobalStateCoder for GlobalState;
  using LoanRecordCoder for LoanRecord;
  using Math for uint256;

  /*//////////////////////////////////////////////////////////////
                          External Updaters
  //////////////////////////////////////////////////////////////*/

  function pokeGlobalCache() external nonReentrant {
    _updateGlobalCache(_state);
  }

  function pokeModuleCache(address module) external nonReentrant {
    _getUpdatedGlobalAndModuleState(module);
  }

  /*//////////////////////////////////////////////////////////////
                  Internal Fee Getters and Updaters               
  //////////////////////////////////////////////////////////////*/

  function _updateGlobalCache(GlobalState state) internal returns (GlobalState) {
    uint256 satoshiPerEth = _getSatoshiPerEth();
    uint256 gweiPerGas = _getGweiPerGas();
    state = state.setCached(satoshiPerEth, gweiPerGas, block.timestamp);
    _state = state;
    emit GlobalStateCacheUpdated(satoshiPerEth, gweiPerGas);
    return state;
  }

  function _updateModuleCache(
    GlobalState state,
    ModuleState moduleState,
    address module
  ) internal returns (ModuleState) {
    // Read the gas parameters
    (uint256 loanGasE4, uint256 repayGasE4) = moduleState.getGasParams();
    // Calculate the new gas refunds for the module
    (
      uint256 ethRefundForLoanGas,
      uint256 ethRefundForRepayGas,
      uint256 btcFeeForLoanGas,
      uint256 btcFeeForRepayGas
    ) = _calculateModuleGasFees(state, loanGasE4, repayGasE4);
    // Update the module's cache and write it to storage
    moduleState = moduleState.setCached(
      ethRefundForLoanGas,
      ethRefundForRepayGas,
      btcFeeForLoanGas,
      btcFeeForRepayGas,
      block.timestamp
    );
    _moduleFees[module] = moduleState;
    return moduleState;
  }

  function _getUpdatedGlobalState() internal returns (GlobalState state, uint256 lastUpdateTimestamp) {
    state = _state;
    lastUpdateTimestamp = state.getLastUpdateTimestamp();
    if (block.timestamp - lastUpdateTimestamp > _cacheTimeToLive) {
      state = _updateGlobalCache(state);
    }
  }

  function _getUpdatedGlobalAndModuleState(address module)
    internal
    returns (GlobalState state, ModuleState moduleState)
  {
    // Get updated global state, with cache refreshed if it had expired
    uint256 lastGlobalUpdateTimestamp;
    (state, lastGlobalUpdateTimestamp) = _getUpdatedGlobalState();
    // Read module state from storage
    moduleState = _getExistingModuleState(module);
    // Check if module's cache is older than global cache
    if (moduleState.getLastUpdateTimestamp() < lastGlobalUpdateTimestamp) {
      moduleState = _updateModuleCache(state, moduleState, module);
    }
  }

  /*//////////////////////////////////////////////////////////////
                      Internal Fee Calculators
  //////////////////////////////////////////////////////////////*/

  function _calculateModuleGasFees(
    GlobalState state,
    uint256 loanGasE4,
    uint256 repayGasE4
  )
    internal
    pure
    returns (
      uint256 ethRefundForLoanGas,
      uint256 ethRefundForRepayGas,
      uint256 btcFeeForLoanGas,
      uint256 btcFeeForRepayGas
    )
  {
    (uint256 satoshiPerEth, uint256 gasPrice) = state.getParamsForModuleFees();
    // Unchecked because gasPrice can not exceed 60 bits,
    // refunds can not exceed 68 bits and the numerator for
    // borrowGasFeeBitcoin can not exceed 108 bits
    unchecked {
      // Multiply gasPrice (expressed in gwei) by 1e9 to convert to wei, and by 1e4 to convert
      // the gas values (expressed as gas * 1e-4) to ETH
      gasPrice *= 1e13;
      // Compute ETH cost of running loan function
      ethRefundForLoanGas = loanGasE4 * gasPrice;
      // Compute ETH cost of running repay function
      ethRefundForRepayGas = repayGasE4 * gasPrice;
      // Compute BTC value of `ethRefundForLoanGas`
      btcFeeForLoanGas = (satoshiPerEth * ethRefundForLoanGas) / OneEth;
      // Compute BTC value of `ethRefundForRepayGas`
      btcFeeForRepayGas = (satoshiPerEth * ethRefundForRepayGas) / OneEth;
    }
  }

  function _calculateRenAndZeroFees(GlobalState state, uint256 borrowAmount)
    internal
    pure
    returns (uint256 renFees, uint256 zeroFees)
  {
    (
      uint256 zeroBorrowFeeBips,
      uint256 renBorrowFeeBips,
      uint256 zeroBorrowFeeStatic,
      uint256 renBorrowFeeStatic
    ) = state.getBorrowFees();

    renFees = renBorrowFeeStatic + borrowAmount.uncheckedMulBipsUp(renBorrowFeeBips);
    zeroFees = zeroBorrowFeeStatic + borrowAmount.uncheckedMulBipsUp(zeroBorrowFeeBips);
  }

  function _calculateLoanFees(
    GlobalState state,
    ModuleState moduleState,
    uint256 borrowAmount
  )
    internal
    pure
    returns (
      uint256 actualBorrowAmount,
      uint256 lenderDebt,
      uint256 btcFeeForLoanGas
    )
  {
    (uint256 renFees, uint256 zeroFees) = _calculateRenAndZeroFees(state, borrowAmount);
    uint256 btcFeeForRepayGas;
    (btcFeeForLoanGas, btcFeeForRepayGas) = moduleState.getBitcoinGasFees();

    // Lender is responsible for actualBorrowAmount, zeroFees and gas refunds.
    lenderDebt = borrowAmount - renFees;

    // Subtract ren, zero and gas fees
    actualBorrowAmount = lenderDebt - (zeroFees + btcFeeForLoanGas + btcFeeForRepayGas);
  }

  function _ethToBtc(uint256 ethAmount, uint256 satoshiPerEth) internal pure returns (uint256 btcAmount) {
    return (ethAmount * satoshiPerEth) / OneEth;
  }

  function _btcToEth(uint256 btcAmount, uint256 satoshiPerEth) internal pure returns (uint256 ethAmount) {
    return (btcAmount * OneEth) / satoshiPerEth;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;
import "./CoderConstants.sol";

uint256 constant TenThousand = 1e4;
uint256 constant OneGwei = 1e9;
uint256 constant OneEth = 1e18;

library Math {
  function avg(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = (a & b) + (a ^ b) / 2;
  }

  function min(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = ternary(a < b, a, b);
  }

  function max(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = ternary(a < b, b, a);
  }

  function subMinZero(uint256 a, uint256 b) internal pure returns (uint256 c) {
    unchecked {
      c = ternary(a > b, a - b, 0);
    }
  }

  function uncheckedMulBipsUp(uint256 x, uint256 bips) internal pure returns (uint256 y) {
    assembly {
      let numerator := mul(x, bips)
      y := mul(iszero(iszero(numerator)), add(div(sub(numerator, 1), TenThousand), 1))
    }
  }

  function uncheckedMulBipsUpWithMultiplier(
    uint256 x,
    uint256 bips,
    uint8 multiplier
  ) internal pure returns (uint256) {
    return uncheckedMulBipsUp(x, (bips * multiplier) / 100);
  }

  // Equivalent to ceil((x)e-4)
  function uncheckedDivUpE4(uint256 x) internal pure returns (uint256 y) {
    assembly {
      y := add(div(sub(x, 1), TenThousand), 1)
    }
  }

  // Equivalent to ceil((x)e-9)
  function uncheckedDivUpE9(uint256 x) internal pure returns (uint256 y) {
    assembly {
      y := add(div(sub(x, 1), OneGwei), 1)
    }
  }

  function mulBips(uint256 n, uint256 bips) internal pure returns (uint256 result) {
    result = (n * bips) / TenThousand;
  }

  function ternary(
    bool condition,
    uint256 valueIfTrue,
    uint256 valueIfFalse
  ) internal pure returns (uint256 c) {
    assembly {
      c := add(valueIfFalse, mul(condition, sub(valueIfTrue, valueIfFalse)))
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import { GlobalState } from "../erc4626/storage/ZeroBTCStorage.sol";

interface IStrategy {
  function manage(GlobalState old) external returns (GlobalState state);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import './CoderConstants.sol';

// ============================== NOTICE ==============================
// This library was automatically generated with stackpacker.
// Be very careful about modifying it, as doing so incorrectly could
// result in corrupted reads/writes.
// ====================================================================

// struct LoanRecord {
//   uint48 sharesLocked;
//   uint48 actualBorrowAmount;
//   uint48 lenderDebt;
//   uint48 btcFeeForLoanGas;
//   uint32 expiry;
// }
type LoanRecord is uint256;

LoanRecord constant DefaultLoanRecord = LoanRecord
  .wrap(0);

library LoanRecordCoder {
  /*//////////////////////////////////////////////////////////////
                           LoanRecord
//////////////////////////////////////////////////////////////*/

  function decode(LoanRecord encoded)
    internal
    pure
    returns (
      uint256 sharesLocked,
      uint256 actualBorrowAmount,
      uint256 lenderDebt,
      uint256 btcFeeForLoanGas,
      uint256 expiry
    )
  {
    assembly {
      sharesLocked := shr(
        LoanRecord_sharesLocked_bitsAfter,
        encoded
      )
      actualBorrowAmount := and(
        MaxUint48,
        shr(
          LoanRecord_actualBorrowAmount_bitsAfter,
          encoded
        )
      )
      lenderDebt := and(
        MaxUint48,
        shr(
          LoanRecord_lenderDebt_bitsAfter,
          encoded
        )
      )
      btcFeeForLoanGas := and(
        MaxUint48,
        shr(
          LoanRecord_btcFeeForLoanGas_bitsAfter,
          encoded
        )
      )
      expiry := and(
        MaxUint32,
        shr(LoanRecord_expiry_bitsAfter, encoded)
      )
    }
  }

  function encode(
    uint256 sharesLocked,
    uint256 actualBorrowAmount,
    uint256 lenderDebt,
    uint256 btcFeeForLoanGas,
    uint256 expiry
  ) internal pure returns (LoanRecord encoded) {
    assembly {
      if or(
        gt(sharesLocked, MaxUint48),
        or(
          gt(actualBorrowAmount, MaxUint48),
          or(
            gt(lenderDebt, MaxUint48),
            or(
              gt(btcFeeForLoanGas, MaxUint48),
              gt(expiry, MaxUint32)
            )
          )
        )
      ) {
        mstore(0, Panic_error_signature)
        mstore(
          Panic_error_offset,
          Panic_arithmetic
        )
        revert(0, Panic_error_length)
      }
      encoded := or(
        shl(
          LoanRecord_sharesLocked_bitsAfter,
          sharesLocked
        ),
        or(
          shl(
            LoanRecord_actualBorrowAmount_bitsAfter,
            actualBorrowAmount
          ),
          or(
            shl(
              LoanRecord_lenderDebt_bitsAfter,
              lenderDebt
            ),
            or(
              shl(
                LoanRecord_btcFeeForLoanGas_bitsAfter,
                btcFeeForLoanGas
              ),
              shl(
                LoanRecord_expiry_bitsAfter,
                expiry
              )
            )
          )
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
                 LoanRecord SharesAndDebt coders
//////////////////////////////////////////////////////////////*/

  function getSharesAndDebt(LoanRecord encoded)
    internal
    pure
    returns (
      uint256 sharesLocked,
      uint256 lenderDebt
    )
  {
    assembly {
      sharesLocked := shr(
        LoanRecord_sharesLocked_bitsAfter,
        encoded
      )
      lenderDebt := and(
        MaxUint48,
        shr(
          LoanRecord_lenderDebt_bitsAfter,
          encoded
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
              LoanRecord.actualBorrowAmount coders
//////////////////////////////////////////////////////////////*/

  function getActualBorrowAmount(
    LoanRecord encoded
  )
    internal
    pure
    returns (uint256 actualBorrowAmount)
  {
    assembly {
      actualBorrowAmount := and(
        MaxUint48,
        shr(
          LoanRecord_actualBorrowAmount_bitsAfter,
          encoded
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
               LoanRecord.btcFeeForLoanGas coders
//////////////////////////////////////////////////////////////*/

  function getBtcFeeForLoanGas(LoanRecord encoded)
    internal
    pure
    returns (uint256 btcFeeForLoanGas)
  {
    assembly {
      btcFeeForLoanGas := and(
        MaxUint48,
        shr(
          LoanRecord_btcFeeForLoanGas_bitsAfter,
          encoded
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
                    LoanRecord.expiry coders
//////////////////////////////////////////////////////////////*/

  function getExpiry(LoanRecord encoded)
    internal
    pure
    returns (uint256 expiry)
  {
    assembly {
      expiry := and(
        MaxUint32,
        shr(LoanRecord_expiry_bitsAfter, encoded)
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
                  LoanRecord comparison methods
//////////////////////////////////////////////////////////////*/

  function equals(LoanRecord a, LoanRecord b)
    internal
    pure
    returns (bool _equals)
  {
    assembly {
      _equals := eq(a, b)
    }
  }

  function isNull(LoanRecord a)
    internal
    pure
    returns (bool _isNull)
  {
    _isNull = equals(a, DefaultLoanRecord);
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.13;

import { FixedPointMathLib } from "./utils/FixedPointMathLib.sol";
import "./utils/ModuleStateCoder.sol";
import { ZeroBTCStorage } from "./storage/ZeroBTCStorage.sol";

/**
 * @notice Base contract that must be inherited by all modules.
 */
abstract contract BaseModule is ZeroBTCStorage {
  using ModuleStateCoder for ModuleState;
  using FixedPointMathLib for uint256;

  /// @notice Base asset of the vault which is calling the module.
  /// This value is private because it is read only to the module.
  address public immutable asset;

  /// @notice Isolated storage pointer for any data that the module must write
  /// Use like so:
  address internal immutable _moduleSlot;

  constructor(address _asset) {
    asset = _asset;
    _moduleSlot = address(this);
  }

  function initialize() external virtual {}

  function _getModuleState() internal returns (ModuleState moduleState) {
    moduleState = _moduleFees[_moduleSlot];
  }

  /**
   * @notice Repays a loan.
   *
   * This is always called in a delegatecall.
   *
   * `collateralToUnlock` should be equal to `repaidAmount` unless the vault
   * has less than 100% collateralization or the loan is underpaid.
   *
   * @param borrower Recipient of the loan
   * @param repaidAmount Amount of `asset` being repaid.
   * @param loanId Unique (per vault) identifier for a loan.
   * @param data Any additional data provided to the module.
   * @return collateralToUnlock Amount of collateral to unlock for the lender.
   */
  function repayLoan(
    address borrower,
    uint256 repaidAmount,
    uint256 loanId,
    bytes calldata data
  ) external virtual returns (uint256 collateralToUnlock) {
    // Handle loan using module's logic, reducing borrow amount by the value of gas used
    collateralToUnlock = _repayLoan(borrower, repaidAmount, loanId, data);
  }

  /**
   * @notice Take out a loan.
   *
   * This is always called in a delegatecall.
   *
   * `collateralToLock` should be equal to `borrowAmount` unless the vault
   * has less than 100% collateralization.
   *
   * @param borrower Recipient of the loan
   * @param borrowAmount Amount of `asset` being borrowed.
   * @param loanId Unique (per vault) identifier for a loan.
   * @param data Any additional data provided to the module.
   * @return collateralToLock Amount of collateral to lock for the lender.
   */
  function receiveLoan(
    address borrower,
    uint256 borrowAmount,
    uint256 loanId,
    bytes calldata data
  ) external virtual returns (uint256 collateralToLock) {
    // Handle loan using module's logic, reducing borrow amount by the value of gas used
    collateralToLock = _receiveLoan(borrower, borrowAmount, loanId, data);
  }

  struct ConvertLocals {
    address borrower;
    uint256 minOut;
    uint256 amount;
    uint256 nonce;
  }

  /* ---- Override These In Child ---- */
  function swap(ConvertLocals memory) internal virtual returns (uint256 amountOut);

  function swapBack(ConvertLocals memory) internal virtual returns (uint256 amountOut);

  function transfer(address to, uint256 amount) internal virtual;

  function _receiveLoan(
    address borrower,
    uint256 borrowAmount,
    uint256 loanId,
    bytes calldata data
  ) internal virtual returns (uint256 collateralToLock);

  function _repayLoan(
    address borrower,
    uint256 repaidAmount,
    uint256 loanId,
    bytes calldata data
  ) internal virtual returns (uint256 collateralToUnlock);

  /* ---- Leave Empty For Now ---- */

  /// @notice Return recent average gas price in wei per unit of gas
  function getGasPrice() internal view virtual returns (uint256) {
    return 1;
  }

  /// @notice Get current price of ETH in terms of `asset`
  function getEthPrice() internal view virtual returns (uint256) {
    return 1;
  }
}

contract ABC {
  function x(uint256 a) external pure {
    assembly {
      a := or(shr(96, a), or(shr(96, a), or(shr(96, a), or(shr(96, a), or(shr(96, a), shr(96, a))))))
    }
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.13;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
  /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

  uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

  function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
    return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
  }

  function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
    return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
  }

  function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
    return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
  }

  function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
    return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
  }

  /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

  function mulDivDown(
    uint256 x,
    uint256 y,
    uint256 denominator
  ) internal pure returns (uint256 z) {
    assembly {
      // Store x * y in z for now.
      z := mul(x, y)

      // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
      if iszero(
        and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))
      ) {
        revert(0, 0)
      }

      // Divide z by the denominator.
      z := div(z, denominator)
    }
  }

  function mulDivUp(
    uint256 x,
    uint256 y,
    uint256 denominator
  ) internal pure returns (uint256 z) {
    assembly {
      // Store x * y in z for now.
      z := mul(x, y)

      // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
      if iszero(
        and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))
      ) {
        revert(0, 0)
      }

      // First, divide z - 1 by the denominator and add 1.
      // We allow z - 1 to underflow if z is 0, because we multiply the
      // end result by 0 if z is zero, ensuring we return 0 if z is zero.
      z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
    }
  }

  function divUp(uint256 numerator, uint256 denominator)
    internal
    pure
    returns (uint256 z)
  {
    assembly {
      // Equivalent to require(denominator != 0)
      if iszero(denominator) {
        revert(0, 0)
      }

      // First, divide numerator - 1 by the denominator and add 1.
      // We allow z - 1 to underflow if z is 0, because we multiply the
      // end result by 0 if z is zero, ensuring we return 0 if z is zero.
      z := mul(
        iszero(iszero(numerator)),
        add(div(sub(numerator, 1), denominator), 1)
      )
    }
  }

  function rpow(
    uint256 x,
    uint256 n,
    uint256 scalar
  ) internal pure returns (uint256 z) {
    assembly {
      switch x
      case 0 {
        switch n
        case 0 {
          // 0 ** 0 = 1
          z := scalar
        }
        default {
          // 0 ** n = 0
          z := 0
        }
      }
      default {
        switch mod(n, 2)
        case 0 {
          // If n is even, store scalar in z for now.
          z := scalar
        }
        default {
          // If n is odd, store x in z for now.
          z := x
        }

        // Shifting right by 1 is like dividing by 2.
        let half := shr(1, scalar)

        for {
          // Shift n right by 1 before looping to halve it.
          n := shr(1, n)
        } n {
          // Shift n right by 1 each iteration to halve it.
          n := shr(1, n)
        } {
          // Revert immediately if x ** 2 would overflow.
          // Equivalent to iszero(eq(div(xx, x), x)) here.
          if shr(128, x) {
            revert(0, 0)
          }

          // Store x squared.
          let xx := mul(x, x)

          // Round to the nearest number.
          let xxRound := add(xx, half)

          // Revert if xx + half overflowed.
          if lt(xxRound, xx) {
            revert(0, 0)
          }

          // Set x to scaled xxRound.
          x := div(xxRound, scalar)

          // If n is even:
          if mod(n, 2) {
            // Compute z * x.
            let zx := mul(z, x)

            // If z * x overflowed:
            if iszero(eq(div(zx, x), z)) {
              // Revert if x is non-zero.
              if iszero(iszero(x)) {
                revert(0, 0)
              }
            }

            // Round to the nearest number.
            let zxRound := add(zx, half)

            // Revert if zx + half overflowed.
            if lt(zxRound, zx) {
              revert(0, 0)
            }

            // Return properly scaled zxRound.
            z := div(zxRound, scalar)
          }
        }
      }
    }
  }

  /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

  function sqrt(uint256 x) internal pure returns (uint256 z) {
    assembly {
      // Start off with z at 1.
      z := 1

      // Used below to help find a nearby power of 2.
      let y := x

      // Find the lowest power of 2 that is at least sqrt(x).
      if iszero(lt(y, 0x100000000000000000000000000000000)) {
        y := shr(128, y) // Like dividing by 2 ** 128.
        z := shl(64, z) // Like multiplying by 2 ** 64.
      }
      if iszero(lt(y, 0x10000000000000000)) {
        y := shr(64, y) // Like dividing by 2 ** 64.
        z := shl(32, z) // Like multiplying by 2 ** 32.
      }
      if iszero(lt(y, 0x100000000)) {
        y := shr(32, y) // Like dividing by 2 ** 32.
        z := shl(16, z) // Like multiplying by 2 ** 16.
      }
      if iszero(lt(y, 0x10000)) {
        y := shr(16, y) // Like dividing by 2 ** 16.
        z := shl(8, z) // Like multiplying by 2 ** 8.
      }
      if iszero(lt(y, 0x100)) {
        y := shr(8, y) // Like dividing by 2 ** 8.
        z := shl(4, z) // Like multiplying by 2 ** 4.
      }
      if iszero(lt(y, 0x10)) {
        y := shr(4, y) // Like dividing by 2 ** 4.
        z := shl(2, z) // Like multiplying by 2 ** 2.
      }
      if iszero(lt(y, 0x8)) {
        // Equivalent to 2 ** z.
        z := shl(1, z)
      }

      // Shifting right by 1 is like dividing by 2.
      z := shr(1, add(z, div(x, z)))
      z := shr(1, add(z, div(x, z)))
      z := shr(1, add(z, div(x, z)))
      z := shr(1, add(z, div(x, z)))
      z := shr(1, add(z, div(x, z)))
      z := shr(1, add(z, div(x, z)))
      z := shr(1, add(z, div(x, z)))

      // Compute a rounded down version of z.
      let zRoundDown := div(x, z)

      // If zRoundDown is smaller, use it.
      if lt(zRoundDown, z) {
        z := zRoundDown
      }
    }
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import { ZeroBTCStorage, ModuleStateCoder, DefaultModuleState, ModuleType, ModuleState, GlobalStateCoder, GlobalState, LoanRecordCoder, LoanRecord } from "../storage/ZeroBTCStorage.sol";
import { IGateway, IGatewayRegistry } from "../../interfaces/IGatewayRegistry.sol";
import "../token/ERC4626.sol";
import "../utils/Governable.sol";
import "../interfaces/IZeroModule.sol";
import "../interfaces/IZeroBTC.sol";
import "../interfaces/IRenBtcEthConverter.sol";
import { IGateway, IGatewayRegistry } from "../../interfaces/IGatewayRegistry.sol";
import { IChainlinkOracle } from "../../interfaces/IChainlinkOracle.sol";
import "../utils/Math.sol";

uint256 constant OneBitcoin = 1e8;

// Used to convert a price expressed as wei per btc to one expressed
// as satoshi per ETH
uint256 constant BtcEthPriceInversionNumerator = 1e26;

abstract contract ZeroBTCBase is ZeroBTCStorage, ERC4626, Governable, IZeroBTC {
  using Math for uint256;
  using ModuleStateCoder for ModuleState;
  using GlobalStateCoder for GlobalState;
  using LoanRecordCoder for LoanRecord;

  receive() external payable {}

  /*//////////////////////////////////////////////////////////////
                          Immutables
  //////////////////////////////////////////////////////////////*/

  // RenVM gateway registry
  IGatewayRegistry internal immutable _gatewayRegistry;
  // _btcEthPriceOracle MUST return prices expressed as wei per full bitcoin
  IChainlinkOracle internal immutable _btcEthPriceOracle;
  // _gasPriceOracle MUST return gas prices expressed as wei per unit of gas
  IChainlinkOracle internal immutable _gasPriceOracle;
  // Contract for swapping renBTC to ETH
  IRenBtcEthConverter internal immutable _renBtcConverter;
  // TTL for global cache
  uint256 internal immutable _cacheTimeToLive;
  // Maximum time a loan can remain outstanding
  uint256 internal immutable _maxLoanDuration;
  // Target ETH reserves for gas refunds
  uint256 internal immutable _targetEthReserve;
  // Target ETH reserves for gas refunds
  uint256 internal immutable _maxGasProfitShareBips;
  // Recipient of Zero DAO fees
  address internal immutable _zeroFeeRecipient;

  constructor(
    IGatewayRegistry gatewayRegistry,
    IChainlinkOracle btcEthPriceOracle,
    IChainlinkOracle gasPriceOracle,
    IRenBtcEthConverter renBtcConverter,
    uint256 cacheTimeToLive,
    uint256 maxLoanDuration,
    uint256 targetEthReserve,
    uint256 maxGasProfitShareBips,
    address zeroFeeRecipient,
    address _asset,
    address _proxyContract
  ) ERC4626(_asset, "ZeroBTC", "ZBTC", 8, _proxyContract, "v1") {
    _gatewayRegistry = gatewayRegistry;
    _btcEthPriceOracle = btcEthPriceOracle;
    _gasPriceOracle = gasPriceOracle;
    _renBtcConverter = renBtcConverter;
    _cacheTimeToLive = cacheTimeToLive;
    _maxLoanDuration = maxLoanDuration;
    _targetEthReserve = targetEthReserve;
    _maxGasProfitShareBips = maxGasProfitShareBips;
    _zeroFeeRecipient = zeroFeeRecipient;
  }

  /*//////////////////////////////////////////////////////////////
                        State Initialization
  //////////////////////////////////////////////////////////////*/

  function initialize(
    address initialGovernance,
    uint256 zeroBorrowFeeBips,
    uint256 renBorrowFeeBips,
    uint256 zeroBorrowFeeStatic,
    uint256 renBorrowFeeStatic,
    uint256 zeroFeeShareBips,
    address initialHarvester
  ) public payable virtual override {
    if (_governance != address(0)) {
      revert AlreadyInitialized();
    }
    // Initialize governance address
    Governable._initialize(initialGovernance);
    _authorized[initialGovernance] = true;
    // Initialize UpgradeableEIP712 and ReentrancyGuard
    super._initialize();

    // Set initial global state
    _setFees(zeroBorrowFeeBips, renBorrowFeeBips, zeroBorrowFeeStatic, renBorrowFeeStatic, zeroFeeShareBips);

    // set harvester
    _isHarvester[initialHarvester] = true;
  }

  /*//////////////////////////////////////////////////////////////
                          External Getters
  //////////////////////////////////////////////////////////////*/

  function getConfig()
    external
    view
    virtual
    override
    returns (
      address gatewayRegistry,
      address btcEthPriceOracle,
      address gasPriceOracle,
      address renBtcConverter,
      uint256 cacheTimeToLive,
      uint256 maxLoanDuration,
      uint256 targetEthReserve,
      uint256 maxGasProfitShareBips,
      address zeroFeeRecipient
    )
  {
    gatewayRegistry = address(_gatewayRegistry);
    btcEthPriceOracle = address(_btcEthPriceOracle);
    gasPriceOracle = address(_gasPriceOracle);
    renBtcConverter = address(_renBtcConverter);
    cacheTimeToLive = _cacheTimeToLive;
    maxLoanDuration = _maxLoanDuration;
    targetEthReserve = _targetEthReserve;
    maxGasProfitShareBips = _maxGasProfitShareBips;
    zeroFeeRecipient = _zeroFeeRecipient;
  }

  function getGlobalState()
    external
    view
    override
    returns (
      uint256 zeroBorrowFeeBips,
      uint256 renBorrowFeeBips,
      uint256 zeroFeeShareBips,
      uint256 zeroBorrowFeeStatic,
      uint256 renBorrowFeeStatic,
      uint256 satoshiPerEth,
      uint256 gweiPerGas,
      uint256 lastUpdateTimestamp,
      uint256 totalBitcoinBorrowed,
      uint256 unburnedGasReserveShares,
      uint256 unburnedZeroFeeShares
    )
  {
    return _state.decode();
  }

  function getModuleState(address module)
    external
    view
    override
    returns (
      ModuleType moduleType,
      uint256 loanGasE4,
      uint256 repayGasE4,
      uint256 ethRefundForLoanGas,
      uint256 ethRefundForRepayGas,
      uint256 btcFeeForLoanGas,
      uint256 btcFeeForRepayGas,
      uint256 lastUpdateTimestamp
    )
  {
    return _getExistingModuleState(module).decode();
  }

  function totalAssets() public view virtual override(ERC4626, IERC4626) returns (uint256) {
    return ERC4626.totalAssets() + _state.getTotalBitcoinBorrowed();
  }

  /*//////////////////////////////////////////////////////////////
                          Internal Getters
  //////////////////////////////////////////////////////////////*/

  function _getSatoshiPerEth() internal view returns (uint256) {
    uint256 ethPerBitcoin = _btcEthPriceOracle.latestAnswer();
    return BtcEthPriceInversionNumerator / ethPerBitcoin;
  }

  function _getGweiPerGas() internal view returns (uint256) {
    uint256 gasPrice = _gasPriceOracle.latestAnswer();
    return gasPrice.uncheckedDivUpE9();
  }

  function _getGateway() internal view returns (IGateway gateway) {
    gateway = IGateway(_gatewayRegistry.getGatewayByToken(asset));
  }

  function _getExistingModuleState(address module) internal view returns (ModuleState moduleState) {
    moduleState = _moduleFees[module];
    if (moduleState.isNull()) {
      revert ModuleDoesNotExist();
    }
  }

  /*//////////////////////////////////////////////////////////////
                          Internal Setters
  //////////////////////////////////////////////////////////////*/

  function _setFees(
    uint256 zeroBorrowFeeBips,
    uint256 renBorrowFeeBips,
    uint256 zeroBorrowFeeStatic,
    uint256 renBorrowFeeStatic,
    uint256 zeroFeeShareBips
  ) internal {
    if (
      (zeroBorrowFeeBips | renBorrowFeeBips) > 2000 ||
      (zeroFeeShareBips) > 8000 ||
      zeroBorrowFeeBips == 0 ||
      renBorrowFeeBips == 0 ||
      zeroFeeShareBips == 0
    ) {
      revert InvalidDynamicBorrowFee();
    }
    _state = _state.setFees(
      zeroBorrowFeeBips,
      renBorrowFeeBips,
      zeroBorrowFeeStatic,
      renBorrowFeeStatic,
      zeroFeeShareBips
    );
  }

  /*//////////////////////////////////////////////////////////////
                          External Setters
  //////////////////////////////////////////////////////////////*/

  function authorize(address user) external onlyGovernance {
    _authorized[user] = true;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;


// ============================== NOTICE ==============================
// This library was automatically generated with stackpacker.
// Be very careful about modifying it, as doing so incorrectly could
// result in corrupted reads/writes.
// ====================================================================

uint256 constant GlobalState_BorrowFees_maskOut = 0x000003ffe000000000007fffffffffffffffffffffffffffffffffffffffffff;
uint256 constant GlobalState_Cached_maskOut = 0xffffffffffffffffffff80000000000000000001ffffffffffffffffffffffff;
uint256 constant GlobalState_Fees_maskOut = 0x000000000000000000007fffffffffffffffffffffffffffffffffffffffffff;
uint256 constant GlobalState_LoanInfo_maskOut = 0xfffffffffffffffffffffffffffffffffffffffe0000000001ffffffffffffff;
uint256 constant GlobalState_ParamsForModuleFees_maskOut = 0xffffffffffffffffffff800000000001ffffffffffffffffffffffffffffffff;
uint256 constant GlobalState_UnburnedShares_maskOut = 0xfffffffffffffffffffffffffffffffffffffffffffffffffe00000000000001;
uint256 constant GlobalState_gweiPerGas_bitsAfter = 0x81;
uint256 constant GlobalState_gweiPerGas_maskOut = 0xfffffffffffffffffffffffffffe0001ffffffffffffffffffffffffffffffff;
uint256 constant GlobalState_lastUpdateTimestamp_bitsAfter = 0x61;
uint256 constant GlobalState_lastUpdateTimestamp_maskOut = 0xfffffffffffffffffffffffffffffffe00000001ffffffffffffffffffffffff;
uint256 constant GlobalState_renBorrowFeeBips_bitsAfter = 0xea;
uint256 constant GlobalState_renBorrowFeeBips_maskOut = 0xffe003ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
uint256 constant GlobalState_renBorrowFeeStatic_bitsAfter = 0xaf;
uint256 constant GlobalState_renBorrowFeeStatic_maskOut = 0xffffffffffffffc000007fffffffffffffffffffffffffffffffffffffffffff;
uint256 constant GlobalState_satoshiPerEth_bitsAfter = 0x91;
uint256 constant GlobalState_satoshiPerEth_maskOut = 0xffffffffffffffffffff80000001ffffffffffffffffffffffffffffffffffff;
uint256 constant GlobalState_totalBitcoinBorrowed_bitsAfter = 0x39;
uint256 constant GlobalState_totalBitcoinBorrowed_maskOut = 0xfffffffffffffffffffffffffffffffffffffffe0000000001ffffffffffffff;
uint256 constant GlobalState_unburnedGasReserveShares_bitsAfter = 0x1d;
uint256 constant GlobalState_unburnedGasReserveShares_maskOut = 0xfffffffffffffffffffffffffffffffffffffffffffffffffe0000001fffffff;
uint256 constant GlobalState_unburnedZeroFeeShares_bitsAfter = 0x01;
uint256 constant GlobalState_unburnedZeroFeeShares_maskOut = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0000001;
uint256 constant GlobalState_zeroBorrowFeeBips_bitsAfter = 0xf5;
uint256 constant GlobalState_zeroBorrowFeeBips_maskOut = 0x001fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
uint256 constant GlobalState_zeroBorrowFeeStatic_bitsAfter = 0xc6;
uint256 constant GlobalState_zeroBorrowFeeStatic_maskOut = 0xffffffffe000003fffffffffffffffffffffffffffffffffffffffffffffffff;
uint256 constant GlobalState_zeroFeeShareBips_bitsAfter = 0xdd;
uint256 constant GlobalState_zeroFeeShareBips_maskOut = 0xfffffc001fffffffffffffffffffffffffffffffffffffffffffffffffffffff;
uint256 constant LoanRecord_SharesAndDebt_maskOut = 0x000000000000ffffffffffff000000000000ffffffffffffffffffffffffffff;
uint256 constant LoanRecord_actualBorrowAmount_bitsAfter = 0xa0;
uint256 constant LoanRecord_actualBorrowAmount_maskOut = 0xffffffffffff000000000000ffffffffffffffffffffffffffffffffffffffff;
uint256 constant LoanRecord_btcFeeForLoanGas_bitsAfter = 0x40;
uint256 constant LoanRecord_btcFeeForLoanGas_maskOut = 0xffffffffffffffffffffffffffffffffffff000000000000ffffffffffffffff;
uint256 constant LoanRecord_expiry_bitsAfter = 0x20;
uint256 constant LoanRecord_expiry_maskOut = 0xffffffffffffffffffffffffffffffffffffffffffffffff00000000ffffffff;
uint256 constant LoanRecord_lenderDebt_bitsAfter = 0x70;
uint256 constant LoanRecord_lenderDebt_maskOut = 0xffffffffffffffffffffffff000000000000ffffffffffffffffffffffffffff;
uint256 constant LoanRecord_sharesLocked_bitsAfter = 0xd0;
uint256 constant LoanRecord_sharesLocked_maskOut = 0x000000000000ffffffffffffffffffffffffffffffffffffffffffffffffffff;
uint256 constant MaxUint11 = 0x07ff;
uint256 constant MaxUint13 = 0x1fff;
uint256 constant MaxUint16 = 0xffff;
uint256 constant MaxUint2 = 0x03;
uint256 constant MaxUint23 = 0x7fffff;
uint256 constant MaxUint24 = 0xffffff;
uint256 constant MaxUint28 = 0x0fffffff;
uint256 constant MaxUint30 = 0x3fffffff;
uint256 constant MaxUint32 = 0xffffffff;
uint256 constant MaxUint40 = 0xffffffffff;
uint256 constant MaxUint48 = 0xffffffffffff;
uint256 constant MaxUint64 = 0xffffffffffffffff;
uint256 constant MaxUint8 = 0xff;
uint256 constant ModuleState_BitcoinGasFees_maskOut = 0xffffffffffffffffffffffffffffffffffffc000000000003fffffffffffffff;
uint256 constant ModuleState_Cached_maskOut = 0xffffc0000000000000000000000000000000000000000000000000003fffffff;
uint256 constant ModuleState_GasParams_maskOut = 0xc0003fffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
uint256 constant ModuleState_LoanParams_maskOut = 0x3fffc0000000000000003fffffffffffffffffffffffffffffffffffffffffff;
uint256 constant ModuleState_RepayParams_maskOut = 0x3fffffffffffffffffffc0000000000000003fffffc000003fffffffffffffff;
uint256 constant ModuleState_btcFeeForLoanGas_bitsAfter = 0x56;
uint256 constant ModuleState_btcFeeForLoanGas_maskOut = 0xffffffffffffffffffffffffffffffffffffc000003fffffffffffffffffffff;
uint256 constant ModuleState_btcFeeForRepayGas_bitsAfter = 0x3e;
uint256 constant ModuleState_btcFeeForRepayGas_maskOut = 0xffffffffffffffffffffffffffffffffffffffffffc000003fffffffffffffff;
uint256 constant ModuleState_ethRefundForLoanGas_bitsAfter = 0xae;
uint256 constant ModuleState_ethRefundForLoanGas_maskOut = 0xffffc0000000000000003fffffffffffffffffffffffffffffffffffffffffff;
uint256 constant ModuleState_ethRefundForRepayGas_bitsAfter = 0x6e;
uint256 constant ModuleState_ethRefundForRepayGas_maskOut = 0xffffffffffffffffffffc0000000000000003fffffffffffffffffffffffffff;
uint256 constant ModuleState_lastUpdateTimestamp_bitsAfter = 0x1e;
uint256 constant ModuleState_lastUpdateTimestamp_maskOut = 0xffffffffffffffffffffffffffffffffffffffffffffffffc00000003fffffff;
uint256 constant ModuleState_loanGasE4_bitsAfter = 0xf6;
uint256 constant ModuleState_loanGasE4_maskOut = 0xc03fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
uint256 constant ModuleState_moduleType_bitsAfter = 0xfe;
uint256 constant ModuleState_moduleType_maskOut = 0x3fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
uint256 constant ModuleState_repayGasE4_bitsAfter = 0xee;
uint256 constant ModuleState_repayGasE4_maskOut = 0xffc03fffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
uint256 constant Panic_arithmetic = 0x11;
uint256 constant Panic_error_length = 0x24;
uint256 constant Panic_error_offset = 0x04;
uint256 constant Panic_error_signature = 0x4e487b7100000000000000000000000000000000000000000000000000000000;

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.13;

import "./ERC4626Storage.sol";
import "./GovernableStorage.sol";
import "../utils/ModuleStateCoder.sol";
import "../utils/GlobalStateCoder.sol";
import "../utils/LoanRecordCoder.sol";

contract ZeroBTCStorage is ERC4626Storage, GovernableStorage {
  GlobalState internal _state;

  mapping(address => ModuleState) internal _moduleFees;

  // Maps loanId => LoanRecord
  mapping(uint256 => LoanRecord) internal _outstandingLoans;

  // maps wallets => whether they can call earn
  mapping(address => bool) internal _isHarvester;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import './CoderConstants.sol';

// ============================== NOTICE ==============================
// This library was automatically generated with stackpacker.
// Be very careful about modifying it, as doing so incorrectly could
// result in corrupted reads/writes.
// ====================================================================

// struct ModuleState {
//   ModuleType moduleType;
//   uint8 loanGasE4;
//   uint8 repayGasE4;
//   uint64 ethRefundForLoanGas;
//   uint64 ethRefundForRepayGas;
//   uint24 btcFeeForLoanGas;
//   uint24 btcFeeForRepayGas;
//   uint32 lastUpdateTimestamp;
// }
type ModuleState is uint256;

ModuleState constant DefaultModuleState = ModuleState
  .wrap(0);

library ModuleStateCoder {
  /*//////////////////////////////////////////////////////////////
                           ModuleState
//////////////////////////////////////////////////////////////*/

  function decode(ModuleState encoded)
    internal
    pure
    returns (
      ModuleType moduleType,
      uint256 loanGasE4,
      uint256 repayGasE4,
      uint256 ethRefundForLoanGas,
      uint256 ethRefundForRepayGas,
      uint256 btcFeeForLoanGas,
      uint256 btcFeeForRepayGas,
      uint256 lastUpdateTimestamp
    )
  {
    assembly {
      moduleType := shr(
        ModuleState_moduleType_bitsAfter,
        encoded
      )
      loanGasE4 := and(
        MaxUint8,
        shr(
          ModuleState_loanGasE4_bitsAfter,
          encoded
        )
      )
      repayGasE4 := and(
        MaxUint8,
        shr(
          ModuleState_repayGasE4_bitsAfter,
          encoded
        )
      )
      ethRefundForLoanGas := and(
        MaxUint64,
        shr(
          ModuleState_ethRefundForLoanGas_bitsAfter,
          encoded
        )
      )
      ethRefundForRepayGas := and(
        MaxUint64,
        shr(
          ModuleState_ethRefundForRepayGas_bitsAfter,
          encoded
        )
      )
      btcFeeForLoanGas := and(
        MaxUint24,
        shr(
          ModuleState_btcFeeForLoanGas_bitsAfter,
          encoded
        )
      )
      btcFeeForRepayGas := and(
        MaxUint24,
        shr(
          ModuleState_btcFeeForRepayGas_bitsAfter,
          encoded
        )
      )
      lastUpdateTimestamp := and(
        MaxUint32,
        shr(
          ModuleState_lastUpdateTimestamp_bitsAfter,
          encoded
        )
      )
    }
  }

  function encode(
    ModuleType moduleType,
    uint256 loanGasE4,
    uint256 repayGasE4,
    uint256 ethRefundForLoanGas,
    uint256 ethRefundForRepayGas,
    uint256 btcFeeForLoanGas,
    uint256 btcFeeForRepayGas,
    uint256 lastUpdateTimestamp
  ) internal pure returns (ModuleState encoded) {
    assembly {
      if or(
        gt(loanGasE4, MaxUint8),
        or(
          gt(repayGasE4, MaxUint8),
          or(
            gt(ethRefundForLoanGas, MaxUint64),
            or(
              gt(ethRefundForRepayGas, MaxUint64),
              or(
                gt(btcFeeForLoanGas, MaxUint24),
                or(
                  gt(
                    btcFeeForRepayGas,
                    MaxUint24
                  ),
                  gt(
                    lastUpdateTimestamp,
                    MaxUint32
                  )
                )
              )
            )
          )
        )
      ) {
        mstore(0, Panic_error_signature)
        mstore(
          Panic_error_offset,
          Panic_arithmetic
        )
        revert(0, Panic_error_length)
      }
      encoded := or(
        shl(
          ModuleState_moduleType_bitsAfter,
          moduleType
        ),
        or(
          shl(
            ModuleState_loanGasE4_bitsAfter,
            loanGasE4
          ),
          or(
            shl(
              ModuleState_repayGasE4_bitsAfter,
              repayGasE4
            ),
            or(
              shl(
                ModuleState_ethRefundForLoanGas_bitsAfter,
                ethRefundForLoanGas
              ),
              or(
                shl(
                  ModuleState_ethRefundForRepayGas_bitsAfter,
                  ethRefundForRepayGas
                ),
                or(
                  shl(
                    ModuleState_btcFeeForLoanGas_bitsAfter,
                    btcFeeForLoanGas
                  ),
                  or(
                    shl(
                      ModuleState_btcFeeForRepayGas_bitsAfter,
                      btcFeeForRepayGas
                    ),
                    shl(
                      ModuleState_lastUpdateTimestamp_bitsAfter,
                      lastUpdateTimestamp
                    )
                  )
                )
              )
            )
          )
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
                  ModuleState LoanParams coders
//////////////////////////////////////////////////////////////*/

  function getLoanParams(ModuleState encoded)
    internal
    pure
    returns (
      ModuleType moduleType,
      uint256 ethRefundForLoanGas
    )
  {
    assembly {
      moduleType := shr(
        ModuleState_moduleType_bitsAfter,
        encoded
      )
      ethRefundForLoanGas := and(
        MaxUint64,
        shr(
          ModuleState_ethRefundForLoanGas_bitsAfter,
          encoded
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
                ModuleState BitcoinGasFees coders
//////////////////////////////////////////////////////////////*/

  function getBitcoinGasFees(ModuleState encoded)
    internal
    pure
    returns (
      uint256 btcFeeForLoanGas,
      uint256 btcFeeForRepayGas
    )
  {
    assembly {
      btcFeeForLoanGas := and(
        MaxUint24,
        shr(
          ModuleState_btcFeeForLoanGas_bitsAfter,
          encoded
        )
      )
      btcFeeForRepayGas := and(
        MaxUint24,
        shr(
          ModuleState_btcFeeForRepayGas_bitsAfter,
          encoded
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
                 ModuleState RepayParams coders
//////////////////////////////////////////////////////////////*/

  function setRepayParams(
    ModuleState old,
    ModuleType moduleType,
    uint256 ethRefundForRepayGas,
    uint256 btcFeeForRepayGas
  ) internal pure returns (ModuleState updated) {
    assembly {
      if or(
        gt(ethRefundForRepayGas, MaxUint64),
        gt(btcFeeForRepayGas, MaxUint24)
      ) {
        mstore(0, Panic_error_signature)
        mstore(
          Panic_error_offset,
          Panic_arithmetic
        )
        revert(0, Panic_error_length)
      }
      updated := or(
        and(old, ModuleState_RepayParams_maskOut),
        or(
          shl(
            ModuleState_moduleType_bitsAfter,
            moduleType
          ),
          or(
            shl(
              ModuleState_ethRefundForRepayGas_bitsAfter,
              ethRefundForRepayGas
            ),
            shl(
              ModuleState_btcFeeForRepayGas_bitsAfter,
              btcFeeForRepayGas
            )
          )
        )
      )
    }
  }

  function getRepayParams(ModuleState encoded)
    internal
    pure
    returns (
      ModuleType moduleType,
      uint256 ethRefundForRepayGas,
      uint256 btcFeeForRepayGas
    )
  {
    assembly {
      moduleType := shr(
        ModuleState_moduleType_bitsAfter,
        encoded
      )
      ethRefundForRepayGas := and(
        MaxUint64,
        shr(
          ModuleState_ethRefundForRepayGas_bitsAfter,
          encoded
        )
      )
      btcFeeForRepayGas := and(
        MaxUint24,
        shr(
          ModuleState_btcFeeForRepayGas_bitsAfter,
          encoded
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
                    ModuleState Cached coders
//////////////////////////////////////////////////////////////*/

  function setCached(
    ModuleState old,
    uint256 ethRefundForLoanGas,
    uint256 ethRefundForRepayGas,
    uint256 btcFeeForLoanGas,
    uint256 btcFeeForRepayGas,
    uint256 lastUpdateTimestamp
  ) internal pure returns (ModuleState updated) {
    assembly {
      if or(
        gt(ethRefundForLoanGas, MaxUint64),
        or(
          gt(ethRefundForRepayGas, MaxUint64),
          or(
            gt(btcFeeForLoanGas, MaxUint24),
            or(
              gt(btcFeeForRepayGas, MaxUint24),
              gt(lastUpdateTimestamp, MaxUint32)
            )
          )
        )
      ) {
        mstore(0, Panic_error_signature)
        mstore(
          Panic_error_offset,
          Panic_arithmetic
        )
        revert(0, Panic_error_length)
      }
      updated := or(
        and(old, ModuleState_Cached_maskOut),
        or(
          shl(
            ModuleState_ethRefundForLoanGas_bitsAfter,
            ethRefundForLoanGas
          ),
          or(
            shl(
              ModuleState_ethRefundForRepayGas_bitsAfter,
              ethRefundForRepayGas
            ),
            or(
              shl(
                ModuleState_btcFeeForLoanGas_bitsAfter,
                btcFeeForLoanGas
              ),
              or(
                shl(
                  ModuleState_btcFeeForRepayGas_bitsAfter,
                  btcFeeForRepayGas
                ),
                shl(
                  ModuleState_lastUpdateTimestamp_bitsAfter,
                  lastUpdateTimestamp
                )
              )
            )
          )
        )
      )
    }
  }

  function getCached(ModuleState encoded)
    internal
    pure
    returns (
      uint256 ethRefundForLoanGas,
      uint256 ethRefundForRepayGas,
      uint256 btcFeeForLoanGas,
      uint256 btcFeeForRepayGas,
      uint256 lastUpdateTimestamp
    )
  {
    assembly {
      ethRefundForLoanGas := and(
        MaxUint64,
        shr(
          ModuleState_ethRefundForLoanGas_bitsAfter,
          encoded
        )
      )
      ethRefundForRepayGas := and(
        MaxUint64,
        shr(
          ModuleState_ethRefundForRepayGas_bitsAfter,
          encoded
        )
      )
      btcFeeForLoanGas := and(
        MaxUint24,
        shr(
          ModuleState_btcFeeForLoanGas_bitsAfter,
          encoded
        )
      )
      btcFeeForRepayGas := and(
        MaxUint24,
        shr(
          ModuleState_btcFeeForRepayGas_bitsAfter,
          encoded
        )
      )
      lastUpdateTimestamp := and(
        MaxUint32,
        shr(
          ModuleState_lastUpdateTimestamp_bitsAfter,
          encoded
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
                  ModuleState GasParams coders
//////////////////////////////////////////////////////////////*/

  function setGasParams(
    ModuleState old,
    uint256 loanGasE4,
    uint256 repayGasE4
  ) internal pure returns (ModuleState updated) {
    assembly {
      if or(
        gt(loanGasE4, MaxUint8),
        gt(repayGasE4, MaxUint8)
      ) {
        mstore(0, Panic_error_signature)
        mstore(
          Panic_error_offset,
          Panic_arithmetic
        )
        revert(0, Panic_error_length)
      }
      updated := or(
        and(old, ModuleState_GasParams_maskOut),
        or(
          shl(
            ModuleState_loanGasE4_bitsAfter,
            loanGasE4
          ),
          shl(
            ModuleState_repayGasE4_bitsAfter,
            repayGasE4
          )
        )
      )
    }
  }

  function getGasParams(ModuleState encoded)
    internal
    pure
    returns (
      uint256 loanGasE4,
      uint256 repayGasE4
    )
  {
    assembly {
      loanGasE4 := and(
        MaxUint8,
        shr(
          ModuleState_loanGasE4_bitsAfter,
          encoded
        )
      )
      repayGasE4 := and(
        MaxUint8,
        shr(
          ModuleState_repayGasE4_bitsAfter,
          encoded
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
                  ModuleState.moduleType coders
//////////////////////////////////////////////////////////////*/

  function getModuleType(ModuleState encoded)
    internal
    pure
    returns (ModuleType moduleType)
  {
    assembly {
      moduleType := shr(
        ModuleState_moduleType_bitsAfter,
        encoded
      )
    }
  }

  function setModuleType(
    ModuleState old,
    ModuleType moduleType
  ) internal pure returns (ModuleState updated) {
    assembly {
      updated := or(
        and(old, ModuleState_moduleType_maskOut),
        shl(
          ModuleState_moduleType_bitsAfter,
          moduleType
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
                  ModuleState.loanGasE4 coders
//////////////////////////////////////////////////////////////*/

  function getLoanGasE4(ModuleState encoded)
    internal
    pure
    returns (uint256 loanGasE4)
  {
    assembly {
      loanGasE4 := and(
        MaxUint8,
        shr(
          ModuleState_loanGasE4_bitsAfter,
          encoded
        )
      )
    }
  }

  function setLoanGasE4(
    ModuleState old,
    uint256 loanGasE4
  ) internal pure returns (ModuleState updated) {
    assembly {
      if gt(loanGasE4, MaxUint8) {
        mstore(0, Panic_error_signature)
        mstore(
          Panic_error_offset,
          Panic_arithmetic
        )
        revert(0, Panic_error_length)
      }
      updated := or(
        and(old, ModuleState_loanGasE4_maskOut),
        shl(
          ModuleState_loanGasE4_bitsAfter,
          loanGasE4
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
                  ModuleState.repayGasE4 coders
//////////////////////////////////////////////////////////////*/

  function getRepayGasE4(ModuleState encoded)
    internal
    pure
    returns (uint256 repayGasE4)
  {
    assembly {
      repayGasE4 := and(
        MaxUint8,
        shr(
          ModuleState_repayGasE4_bitsAfter,
          encoded
        )
      )
    }
  }

  function setRepayGasE4(
    ModuleState old,
    uint256 repayGasE4
  ) internal pure returns (ModuleState updated) {
    assembly {
      if gt(repayGasE4, MaxUint8) {
        mstore(0, Panic_error_signature)
        mstore(
          Panic_error_offset,
          Panic_arithmetic
        )
        revert(0, Panic_error_length)
      }
      updated := or(
        and(old, ModuleState_repayGasE4_maskOut),
        shl(
          ModuleState_repayGasE4_bitsAfter,
          repayGasE4
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
             ModuleState.ethRefundForLoanGas coders
//////////////////////////////////////////////////////////////*/

  function getEthRefundForLoanGas(
    ModuleState encoded
  )
    internal
    pure
    returns (uint256 ethRefundForLoanGas)
  {
    assembly {
      ethRefundForLoanGas := and(
        MaxUint64,
        shr(
          ModuleState_ethRefundForLoanGas_bitsAfter,
          encoded
        )
      )
    }
  }

  function setEthRefundForLoanGas(
    ModuleState old,
    uint256 ethRefundForLoanGas
  ) internal pure returns (ModuleState updated) {
    assembly {
      if gt(ethRefundForLoanGas, MaxUint64) {
        mstore(0, Panic_error_signature)
        mstore(
          Panic_error_offset,
          Panic_arithmetic
        )
        revert(0, Panic_error_length)
      }
      updated := or(
        and(
          old,
          ModuleState_ethRefundForLoanGas_maskOut
        ),
        shl(
          ModuleState_ethRefundForLoanGas_bitsAfter,
          ethRefundForLoanGas
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
             ModuleState.ethRefundForRepayGas coders
//////////////////////////////////////////////////////////////*/

  function getEthRefundForRepayGas(
    ModuleState encoded
  )
    internal
    pure
    returns (uint256 ethRefundForRepayGas)
  {
    assembly {
      ethRefundForRepayGas := and(
        MaxUint64,
        shr(
          ModuleState_ethRefundForRepayGas_bitsAfter,
          encoded
        )
      )
    }
  }

  function setEthRefundForRepayGas(
    ModuleState old,
    uint256 ethRefundForRepayGas
  ) internal pure returns (ModuleState updated) {
    assembly {
      if gt(ethRefundForRepayGas, MaxUint64) {
        mstore(0, Panic_error_signature)
        mstore(
          Panic_error_offset,
          Panic_arithmetic
        )
        revert(0, Panic_error_length)
      }
      updated := or(
        and(
          old,
          ModuleState_ethRefundForRepayGas_maskOut
        ),
        shl(
          ModuleState_ethRefundForRepayGas_bitsAfter,
          ethRefundForRepayGas
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
               ModuleState.btcFeeForLoanGas coders
//////////////////////////////////////////////////////////////*/

  function getBtcFeeForLoanGas(
    ModuleState encoded
  )
    internal
    pure
    returns (uint256 btcFeeForLoanGas)
  {
    assembly {
      btcFeeForLoanGas := and(
        MaxUint24,
        shr(
          ModuleState_btcFeeForLoanGas_bitsAfter,
          encoded
        )
      )
    }
  }

  function setBtcFeeForLoanGas(
    ModuleState old,
    uint256 btcFeeForLoanGas
  ) internal pure returns (ModuleState updated) {
    assembly {
      if gt(btcFeeForLoanGas, MaxUint24) {
        mstore(0, Panic_error_signature)
        mstore(
          Panic_error_offset,
          Panic_arithmetic
        )
        revert(0, Panic_error_length)
      }
      updated := or(
        and(
          old,
          ModuleState_btcFeeForLoanGas_maskOut
        ),
        shl(
          ModuleState_btcFeeForLoanGas_bitsAfter,
          btcFeeForLoanGas
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
              ModuleState.btcFeeForRepayGas coders
//////////////////////////////////////////////////////////////*/

  function getBtcFeeForRepayGas(
    ModuleState encoded
  )
    internal
    pure
    returns (uint256 btcFeeForRepayGas)
  {
    assembly {
      btcFeeForRepayGas := and(
        MaxUint24,
        shr(
          ModuleState_btcFeeForRepayGas_bitsAfter,
          encoded
        )
      )
    }
  }

  function setBtcFeeForRepayGas(
    ModuleState old,
    uint256 btcFeeForRepayGas
  ) internal pure returns (ModuleState updated) {
    assembly {
      if gt(btcFeeForRepayGas, MaxUint24) {
        mstore(0, Panic_error_signature)
        mstore(
          Panic_error_offset,
          Panic_arithmetic
        )
        revert(0, Panic_error_length)
      }
      updated := or(
        and(
          old,
          ModuleState_btcFeeForRepayGas_maskOut
        ),
        shl(
          ModuleState_btcFeeForRepayGas_bitsAfter,
          btcFeeForRepayGas
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
             ModuleState.lastUpdateTimestamp coders
//////////////////////////////////////////////////////////////*/

  function getLastUpdateTimestamp(
    ModuleState encoded
  )
    internal
    pure
    returns (uint256 lastUpdateTimestamp)
  {
    assembly {
      lastUpdateTimestamp := and(
        MaxUint32,
        shr(
          ModuleState_lastUpdateTimestamp_bitsAfter,
          encoded
        )
      )
    }
  }

  function setLastUpdateTimestamp(
    ModuleState old,
    uint256 lastUpdateTimestamp
  ) internal pure returns (ModuleState updated) {
    assembly {
      if gt(lastUpdateTimestamp, MaxUint32) {
        mstore(0, Panic_error_signature)
        mstore(
          Panic_error_offset,
          Panic_arithmetic
        )
        revert(0, Panic_error_length)
      }
      updated := or(
        and(
          old,
          ModuleState_lastUpdateTimestamp_maskOut
        ),
        shl(
          ModuleState_lastUpdateTimestamp_bitsAfter,
          lastUpdateTimestamp
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
                 ModuleState comparison methods
//////////////////////////////////////////////////////////////*/

  function equals(ModuleState a, ModuleState b)
    internal
    pure
    returns (bool _equals)
  {
    assembly {
      _equals := eq(a, b)
    }
  }

  function isNull(ModuleState a)
    internal
    pure
    returns (bool _isNull)
  {
    _isNull = equals(a, DefaultModuleState);
  }
}

enum ModuleType {
  Null,
  LoanOverride,
  LoanAndRepayOverride
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import { IERC20 } from "./IERC20.sol";

import "./IGateway.sol";

/// @notice GatewayRegistry is a mapping from assets to their associated
/// RenERC20 and Gateway contracts.
interface IGatewayRegistry {
  /// @dev The symbol is included twice because strings have to be hashed
  /// first in order to be used as a log index/topic.
  event LogGatewayRegistered(
    string _symbol,
    string indexed _indexedSymbol,
    address indexed _tokenAddress,
    address indexed _gatewayAddress
  );
  event LogGatewayDeregistered(
    string _symbol,
    string indexed _indexedSymbol,
    address indexed _tokenAddress,
    address indexed _gatewayAddress
  );
  event LogGatewayUpdated(
    address indexed _tokenAddress,
    address indexed _currentGatewayAddress,
    address indexed _newGatewayAddress
  );

  /// @dev To get all the registered gateways use count = 0.
  function getGateways(address _start, uint256 _count)
    external
    view
    returns (address[] memory);

  /// @dev To get all the registered RenERC20s use count = 0.
  function getRenTokens(address _start, uint256 _count)
    external
    view
    returns (address[] memory);

  /// @notice Returns the Gateway contract for the given RenERC20
  ///         address.
  ///
  /// @param _tokenAddress The address of the RenERC20 contract.
  function getGatewayByToken(address _tokenAddress)
    external
    view
    returns (IGateway);

  /// @notice Returns the Gateway contract for the given RenERC20
  ///         symbol.
  ///
  /// @param _tokenSymbol The symbol of the RenERC20 contract.
  function getGatewayBySymbol(string calldata _tokenSymbol)
    external
    view
    returns (IGateway);

  /// @notice Returns the RenERC20 address for the given token symbol.
  ///
  /// @param _tokenSymbol The symbol of the RenERC20 contract to
  ///        lookup.
  function getTokenBySymbol(string calldata _tokenSymbol)
    external
    view
    returns (IERC20);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.13;

import { FixedPointMathLib } from "../utils/FixedPointMathLib.sol";
import { SafeTransferLib } from "../utils/SafeTransferLib.sol";
import { ReentrancyGuard } from "../utils/ReentrancyGuard.sol";
import { ERC2612, UpgradeableEIP712 } from "./ERC2612.sol";
import { ERC4626Storage } from "../storage/ERC4626Storage.sol";
import "../interfaces/IERC4626.sol";

/// @notice Minimal ERC4626 tokenized Vault implementation.
/// @author ZeroDAO
/// @author Modified from Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/mixins/ERC4626.sol)
/// All functions which can affect the ratio of shares to underlying assets must be nonreentrant
contract ERC4626 is ERC4626Storage, ERC2612, ReentrancyGuard, IERC4626 {
  using SafeTransferLib for address;
  using FixedPointMathLib for uint256;

  /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

  address public immutable override asset;

  constructor(
    address _asset,
    string memory _name,
    string memory _symbol,
    uint8 _decimals,
    address _proxyContract,
    string memory _version
  ) ERC2612(_proxyContract, _name, _symbol, _decimals, _version) {
    asset = _asset;
  }

  modifier onlyAuthorized() {
    require(_authorized[msg.sender], "unauthorized");
    _;
  }

  function _initialize() internal virtual override(UpgradeableEIP712, ReentrancyGuard) {
    UpgradeableEIP712._initialize();
    ReentrancyGuard._initialize();
  }

  /*//////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

  function deposit(uint256 assets, address receiver)
    public
    virtual
    override
    onlyAuthorized
    nonReentrant
    returns (uint256 shares)
  {
    // Check for rounding error since we round down in previewDeposit.
    if ((shares = previewDeposit(assets)) == 0) {
      revert ZeroShares();
    }

    // Need to transfer before minting or ERC777s could reenter.
    asset.safeTransferFrom(msg.sender, address(this), assets);

    _mint(receiver, shares);

    emit Deposit(msg.sender, receiver, assets, shares);

    afterDeposit(assets, shares);
  }

  function mint(uint256 shares, address receiver) public virtual override nonReentrant returns (uint256 assets) {
    assets = previewMint(shares); // No need to check for rounding error, previewMint rounds up.

    // Need to transfer before minting or ERC777s could reenter.
    asset.safeTransferFrom(msg.sender, address(this), assets);

    _mint(receiver, shares);

    emit Deposit(msg.sender, receiver, assets, shares);

    afterDeposit(assets, shares);
  }

  function withdraw(
    uint256 assets,
    address receiver,
    address owner
  ) public virtual override nonReentrant returns (uint256 shares) {
    shares = previewWithdraw(assets); // No need to check for rounding error, previewWithdraw rounds up.

    if (msg.sender != owner) {
      uint256 allowed = _allowance[owner][msg.sender]; // Saves gas for limited approvals.

      if (allowed != type(uint256).max) _allowance[owner][msg.sender] = allowed - shares;
    }

    beforeWithdraw(assets, shares);

    _burn(owner, shares);

    emit Withdraw(msg.sender, receiver, owner, assets, shares);

    asset.safeTransfer(receiver, assets);
  }

  function redeem(
    uint256 shares,
    address receiver,
    address owner
  ) public virtual override nonReentrant returns (uint256 assets) {
    if (msg.sender != owner) {
      uint256 allowed = _allowance[owner][msg.sender]; // Saves gas for limited approvals.

      if (allowed != type(uint256).max) {
        _allowance[owner][msg.sender] = allowed - shares;
      }
    }

    // Check for rounding error since we round down in previewRedeem.
    if ((assets = previewRedeem(shares)) == 0) {
      revert ZeroShares();
    }

    beforeWithdraw(assets, shares);

    _burn(owner, shares);

    emit Withdraw(msg.sender, receiver, owner, assets, shares);

    asset.safeTransfer(receiver, assets);
  }

  /*//////////////////////////////////////////////////////////////
                            ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

  function totalAssets() public view virtual override returns (uint256) {
    return IERC20(asset).balanceOf(address(this));
  }

  function convertToShares(uint256 assets) public view virtual override returns (uint256) {
    uint256 supply = _totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

    return supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());
  }

  function convertToAssets(uint256 shares) public view virtual override returns (uint256) {
    uint256 supply = _totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

    return supply == 0 ? shares : shares.mulDivDown(totalAssets(), supply);
  }

  function previewDeposit(uint256 assets) public view virtual override returns (uint256) {
    return convertToShares(assets);
  }

  function previewMint(uint256 shares) public view virtual override returns (uint256) {
    uint256 supply = _totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

    return supply == 0 ? shares : shares.mulDivUp(totalAssets(), supply);
  }

  function previewWithdraw(uint256 assets) public view virtual override returns (uint256) {
    uint256 supply = _totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

    return supply == 0 ? assets : assets.mulDivUp(supply, totalAssets());
  }

  function previewRedeem(uint256 shares) public view virtual override returns (uint256) {
    return convertToAssets(shares);
  }

  function previewWithdrawForCheckpoint(
    uint256 assets,
    uint256 checkpointSupply,
    uint256 checkpointTotalAssets
  ) internal pure virtual returns (uint256) {
    return checkpointSupply == 0 ? assets : assets.mulDivUp(checkpointSupply, checkpointTotalAssets);
  }

  function checkpointWithdrawParams() internal view returns (uint256 checkpointSupply, uint256 checkpointTotalAssets) {
    checkpointSupply = _totalSupply;
    checkpointTotalAssets = totalAssets();
  }

  /*//////////////////////////////////////////////////////////////
                     DEPOSIT/WITHDRAWAL LIMIT LOGIC
    //////////////////////////////////////////////////////////////*/

  function maxDeposit(address) public view virtual override returns (uint256) {
    return type(uint256).max;
  }

  function maxMint(address) public view virtual override returns (uint256) {
    return type(uint256).max;
  }

  function maxWithdraw(address owner) public view virtual override returns (uint256) {
    return convertToAssets(_balanceOf[owner]);
  }

  function maxRedeem(address owner) public view virtual override returns (uint256) {
    return _balanceOf[owner];
  }

  /*//////////////////////////////////////////////////////////////
                          INTERNAL HOOKS LOGIC
    //////////////////////////////////////////////////////////////*/

  function beforeWithdraw(uint256 assets, uint256 shares) internal virtual {}

  function afterDeposit(uint256 assets, uint256 shares) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "../storage/GovernableStorage.sol";
import "../interfaces/IGovernable.sol";

contract Governable is GovernableStorage, IGovernable {
  function _initialize(address initialGovernance) internal virtual {
    _governance = initialGovernance;
  }

  function governance() external view override returns (address) {
    return _governance;
  }

  modifier onlyGovernance() {
    if (msg.sender != _governance) {
      revert NotGovernance();
    }
    _;
  }

  function setGovernance(address newGovernance) public onlyGovernance {
    emit GovernanceTransferred(_governance, newGovernance);
    _governance = newGovernance;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

interface IZeroModule {
  function initialize() external;

  function asset() external view returns (address);

  function repayLoan(
    address borrower,
    uint256 repaidAmount,
    uint256 loanId,
    bytes calldata data
  ) external;

  function receiveLoan(
    address borrower,
    uint256 borrowAmount,
    uint256 loanId,
    bytes calldata data
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { ModuleType } from "../utils/ModuleStateCoder.sol";
import { IERC4626 } from "./IERC4626.sol";
import "./IGovernable.sol";
import "./InitializationErrors.sol";

interface IZeroBTC is IERC4626, IGovernable, InitializationErrors {
  /*//////////////////////////////////////////////////////////////
                               Actions
  //////////////////////////////////////////////////////////////*/

  function loan(
    address module,
    address borrower,
    uint256 borrowAmount,
    uint256 nonce,
    bytes memory data
  ) external;

  function repay(
    address module,
    address borrower,
    uint256 borrowAmount,
    uint256 nonce,
    bytes memory data,
    address lender,
    bytes32 nHash,
    bytes memory renSignature
  ) external;

  function closeExpiredLoan(
    address module,
    address borrower,
    uint256 borrowAmount,
    uint256 nonce,
    bytes memory data,
    address lender
  ) external;

  function earn() external;

  function setGlobalFees(
    uint256 zeroBorrowFeeBips,
    uint256 renBorrowFeeBips,
    uint256 zeroBorrowFeeStatic,
    uint256 renBorrowFeeStatic,
    uint256 zeroFeeShareBips
  ) external;

  function setModuleGasFees(
    address module,
    uint256 loanGas,
    uint256 repayGas
  ) external;

  function addModule(
    address module,
    ModuleType moduleType,
    uint256 loanGas,
    uint256 repayGas
  ) external;

  function removeModule(address module) external;

  function pokeGlobalCache() external;

  function pokeModuleCache(address module) external;

  function initialize(
    address initialGovernance,
    uint256 zeroBorrowFeeBips,
    uint256 renBorrowFeeBips,
    uint256 zeroBorrowFeeStatic,
    uint256 renBorrowFeeStatic,
    uint256 zeroFeeShareBips,
    address initialHarvester
  ) external payable;

  /*//////////////////////////////////////////////////////////////
                               Getters
  //////////////////////////////////////////////////////////////*/

  function getConfig()
    external
    view
    returns (
      address gatewayRegistry,
      address btcEthPriceOracle,
      address gasPriceOracle,
      address renBtcConverter,
      uint256 cacheTimeToLive,
      uint256 maxLoanDuration,
      uint256 targetEthReserve,
      uint256 maxGasProfitShareBips,
      address zeroFeeRecipient
    );

  function getGlobalState()
    external
    view
    returns (
      uint256 zeroBorrowFeeBips,
      uint256 renBorrowFeeBips,
      uint256 zeroFeeShareBips,
      uint256 zeroBorrowFeeStatic,
      uint256 renBorrowFeeStatic,
      uint256 satoshiPerEth,
      uint256 gweiPerGas,
      uint256 lastUpdateTimestamp,
      uint256 totalBitcoinBorrowed,
      uint256 unburnedGasReserveShares,
      uint256 unburnedZeroFeeShares
    );

  function getModuleState(address module)
    external
    view
    returns (
      ModuleType moduleType,
      uint256 loanGasE4,
      uint256 repayGasE4,
      uint256 ethRefundForLoanGas,
      uint256 ethRefundForRepayGas,
      uint256 btcFeeForLoanGas,
      uint256 btcFeeForRepayGas,
      uint256 lastUpdateTimestamp
    );

  function getOutstandingLoan(uint256 loanId)
    external
    view
    returns (
      uint256 sharesLocked,
      uint256 actualBorrowAmount,
      uint256 lenderDebt,
      uint256 vaultExpenseWithoutRepayFee,
      uint256 expiry
    );

  function calculateLoanId(
    address module,
    address borrower,
    uint256 borrowAmount,
    uint256 nonce,
    bytes memory data,
    address lender
  ) external view returns (uint256);

  /*//////////////////////////////////////////////////////////////
                               Errors
  //////////////////////////////////////////////////////////////*/

  error ModuleDoesNotExist();

  error ReceiveLoanError(address module, address borrower, uint256 borrowAmount, uint256 loanId, bytes data);

  error RepayLoanError(address module, address borrower, uint256 repaidAmount, uint256 loanId, bytes data);

  error ModuleAssetDoesNotMatch(address moduleAsset);

  error InvalidModuleType();

  error InvalidDynamicBorrowFee();

  error LoanDoesNotExist(uint256 loanId);

  error LoanIdNotUnique(uint256 loanId);

  error InvalidNullValue();

  error InvalidSelector();

  error LoanNotExpired(uint256 loanId);

  /*//////////////////////////////////////////////////////////////
                                Events
  //////////////////////////////////////////////////////////////*/

  event LoanCreated(address lender, address borrower, uint256 loanId, uint256 assetsBorrowed, uint256 sharesLocked);

  event LoanClosed(uint256 loanId, uint256 assetsRepaid, uint256 sharesUnlocked, uint256 sharesBurned);

  event ModuleStateUpdated(address module, ModuleType moduleType, uint256 loanGasE4, uint256 repayGasE4);

  event GlobalStateConfigUpdated(uint256 dynamicBorrowFee, uint256 staticBorrowFee);

  event GlobalStateCacheUpdated(uint256 satoshiPerEth, uint256 getGweiPerGas);

  event FeeSharesMinted(uint256 gasReserveFees, uint256 gasReserveShares, uint256 zeroFees, uint256 zeroFeeShares);

  event FeeSharesBurned(uint256 gasReserveFees, uint256 gasReserveShares, uint256 zeroFees, uint256 zeroFeeShares);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

interface IRenBtcEthConverter {
  function convertToEth(uint256 minimumEthOut)
    external
    returns (uint256 actualEthOut);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IChainlinkOracle {
  function latestAnswer() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.13;

import "./ERC2612Storage.sol";
import "./ReentrancyGuardStorage.sol";

contract ERC4626Storage is ERC2612Storage, ReentrancyGuardStorage {
  // maps user => authorized
  mapping(address => bool) internal _authorized;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.13;

contract GovernableStorage {
  address internal _governance;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import './CoderConstants.sol';

// ============================== NOTICE ==============================
// This library was automatically generated with stackpacker.
// Be very careful about modifying it, as doing so incorrectly could
// result in corrupted reads/writes.
// ====================================================================

// struct GlobalState {
//   uint11 zeroBorrowFeeBips;
//   uint11 renBorrowFeeBips;
//   uint13 zeroFeeShareBips;
//   uint23 zeroBorrowFeeStatic;
//   uint23 renBorrowFeeStatic;
//   uint30 satoshiPerEth;
//   uint16 gweiPerGas;
//   uint32 lastUpdateTimestamp;
//   uint40 totalBitcoinBorrowed;
//   uint28 unburnedGasReserveShares;
//   uint28 unburnedZeroFeeShares;
// }
type GlobalState is uint256;

GlobalState constant DefaultGlobalState = GlobalState
  .wrap(0);

library GlobalStateCoder {
  /*//////////////////////////////////////////////////////////////
                           GlobalState
//////////////////////////////////////////////////////////////*/

  function decode(GlobalState encoded)
    internal
    pure
    returns (
      uint256 zeroBorrowFeeBips,
      uint256 renBorrowFeeBips,
      uint256 zeroFeeShareBips,
      uint256 zeroBorrowFeeStatic,
      uint256 renBorrowFeeStatic,
      uint256 satoshiPerEth,
      uint256 gweiPerGas,
      uint256 lastUpdateTimestamp,
      uint256 totalBitcoinBorrowed,
      uint256 unburnedGasReserveShares,
      uint256 unburnedZeroFeeShares
    )
  {
    assembly {
      zeroBorrowFeeBips := shr(
        GlobalState_zeroBorrowFeeBips_bitsAfter,
        encoded
      )
      renBorrowFeeBips := and(
        MaxUint11,
        shr(
          GlobalState_renBorrowFeeBips_bitsAfter,
          encoded
        )
      )
      zeroFeeShareBips := and(
        MaxUint13,
        shr(
          GlobalState_zeroFeeShareBips_bitsAfter,
          encoded
        )
      )
      zeroBorrowFeeStatic := and(
        MaxUint23,
        shr(
          GlobalState_zeroBorrowFeeStatic_bitsAfter,
          encoded
        )
      )
      renBorrowFeeStatic := and(
        MaxUint23,
        shr(
          GlobalState_renBorrowFeeStatic_bitsAfter,
          encoded
        )
      )
      satoshiPerEth := and(
        MaxUint30,
        shr(
          GlobalState_satoshiPerEth_bitsAfter,
          encoded
        )
      )
      gweiPerGas := and(
        MaxUint16,
        shr(
          GlobalState_gweiPerGas_bitsAfter,
          encoded
        )
      )
      lastUpdateTimestamp := and(
        MaxUint32,
        shr(
          GlobalState_lastUpdateTimestamp_bitsAfter,
          encoded
        )
      )
      totalBitcoinBorrowed := and(
        MaxUint40,
        shr(
          GlobalState_totalBitcoinBorrowed_bitsAfter,
          encoded
        )
      )
      unburnedGasReserveShares := and(
        MaxUint28,
        shr(
          GlobalState_unburnedGasReserveShares_bitsAfter,
          encoded
        )
      )
      unburnedZeroFeeShares := and(
        MaxUint28,
        shr(
          GlobalState_unburnedZeroFeeShares_bitsAfter,
          encoded
        )
      )
    }
  }

  function encode(
    uint256 zeroBorrowFeeBips,
    uint256 renBorrowFeeBips,
    uint256 zeroFeeShareBips,
    uint256 zeroBorrowFeeStatic,
    uint256 renBorrowFeeStatic,
    uint256 satoshiPerEth,
    uint256 gweiPerGas,
    uint256 lastUpdateTimestamp,
    uint256 totalBitcoinBorrowed,
    uint256 unburnedGasReserveShares,
    uint256 unburnedZeroFeeShares
  ) internal pure returns (GlobalState encoded) {
    assembly {
      if or(
        gt(zeroBorrowFeeStatic, MaxUint23),
        or(
          gt(renBorrowFeeStatic, MaxUint23),
          or(
            gt(satoshiPerEth, MaxUint30),
            or(
              gt(gweiPerGas, MaxUint16),
              or(
                gt(
                  lastUpdateTimestamp,
                  MaxUint32
                ),
                or(
                  gt(
                    totalBitcoinBorrowed,
                    MaxUint40
                  ),
                  or(
                    gt(
                      unburnedGasReserveShares,
                      MaxUint28
                    ),
                    gt(
                      unburnedZeroFeeShares,
                      MaxUint28
                    )
                  )
                )
              )
            )
          )
        )
      ) {
        mstore(0, Panic_error_signature)
        mstore(
          Panic_error_offset,
          Panic_arithmetic
        )
        revert(0, Panic_error_length)
      }
      encoded := or(
        shl(
          GlobalState_zeroBorrowFeeBips_bitsAfter,
          zeroBorrowFeeBips
        ),
        or(
          shl(
            GlobalState_renBorrowFeeBips_bitsAfter,
            renBorrowFeeBips
          ),
          or(
            shl(
              GlobalState_zeroFeeShareBips_bitsAfter,
              zeroFeeShareBips
            ),
            or(
              shl(
                GlobalState_zeroBorrowFeeStatic_bitsAfter,
                zeroBorrowFeeStatic
              ),
              or(
                shl(
                  GlobalState_renBorrowFeeStatic_bitsAfter,
                  renBorrowFeeStatic
                ),
                or(
                  shl(
                    GlobalState_satoshiPerEth_bitsAfter,
                    satoshiPerEth
                  ),
                  or(
                    shl(
                      GlobalState_gweiPerGas_bitsAfter,
                      gweiPerGas
                    ),
                    or(
                      shl(
                        GlobalState_lastUpdateTimestamp_bitsAfter,
                        lastUpdateTimestamp
                      ),
                      or(
                        shl(
                          GlobalState_totalBitcoinBorrowed_bitsAfter,
                          totalBitcoinBorrowed
                        ),
                        or(
                          shl(
                            GlobalState_unburnedGasReserveShares_bitsAfter,
                            unburnedGasReserveShares
                          ),
                          shl(
                            GlobalState_unburnedZeroFeeShares_bitsAfter,
                            unburnedZeroFeeShares
                          )
                        )
                      )
                    )
                  )
                )
              )
            )
          )
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
                   GlobalState LoanInfo coders
//////////////////////////////////////////////////////////////*/

  function setLoanInfo(
    GlobalState old,
    uint256 totalBitcoinBorrowed
  ) internal pure returns (GlobalState updated) {
    assembly {
      if gt(totalBitcoinBorrowed, MaxUint40) {
        mstore(0, Panic_error_signature)
        mstore(
          Panic_error_offset,
          Panic_arithmetic
        )
        revert(0, Panic_error_length)
      }
      updated := or(
        and(old, GlobalState_LoanInfo_maskOut),
        shl(
          GlobalState_totalBitcoinBorrowed_bitsAfter,
          totalBitcoinBorrowed
        )
      )
    }
  }

  function getLoanInfo(GlobalState encoded)
    internal
    pure
    returns (uint256 totalBitcoinBorrowed)
  {
    assembly {
      totalBitcoinBorrowed := and(
        MaxUint40,
        shr(
          GlobalState_totalBitcoinBorrowed_bitsAfter,
          encoded
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
                     GlobalState Fees coders
//////////////////////////////////////////////////////////////*/

  function setFees(
    GlobalState old,
    uint256 zeroBorrowFeeBips,
    uint256 renBorrowFeeBips,
    uint256 zeroBorrowFeeStatic,
    uint256 renBorrowFeeStatic,
    uint256 zeroFeeShareBips
  ) internal pure returns (GlobalState updated) {
    assembly {
      if or(
        gt(zeroBorrowFeeBips, MaxUint11),
        or(
          gt(renBorrowFeeBips, MaxUint11),
          or(
            gt(zeroBorrowFeeStatic, MaxUint23),
            or(
              gt(renBorrowFeeStatic, MaxUint23),
              gt(zeroFeeShareBips, MaxUint13)
            )
          )
        )
      ) {
        mstore(0, Panic_error_signature)
        mstore(
          Panic_error_offset,
          Panic_arithmetic
        )
        revert(0, Panic_error_length)
      }
      updated := or(
        and(old, GlobalState_Fees_maskOut),
        or(
          shl(
            GlobalState_zeroBorrowFeeBips_bitsAfter,
            zeroBorrowFeeBips
          ),
          or(
            shl(
              GlobalState_renBorrowFeeBips_bitsAfter,
              renBorrowFeeBips
            ),
            or(
              shl(
                GlobalState_zeroBorrowFeeStatic_bitsAfter,
                zeroBorrowFeeStatic
              ),
              or(
                shl(
                  GlobalState_renBorrowFeeStatic_bitsAfter,
                  renBorrowFeeStatic
                ),
                shl(
                  GlobalState_zeroFeeShareBips_bitsAfter,
                  zeroFeeShareBips
                )
              )
            )
          )
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
                  GlobalState BorrowFees coders
//////////////////////////////////////////////////////////////*/

  function getBorrowFees(GlobalState encoded)
    internal
    pure
    returns (
      uint256 zeroBorrowFeeBips,
      uint256 renBorrowFeeBips,
      uint256 zeroBorrowFeeStatic,
      uint256 renBorrowFeeStatic
    )
  {
    assembly {
      zeroBorrowFeeBips := shr(
        GlobalState_zeroBorrowFeeBips_bitsAfter,
        encoded
      )
      renBorrowFeeBips := and(
        MaxUint11,
        shr(
          GlobalState_renBorrowFeeBips_bitsAfter,
          encoded
        )
      )
      zeroBorrowFeeStatic := and(
        MaxUint23,
        shr(
          GlobalState_zeroBorrowFeeStatic_bitsAfter,
          encoded
        )
      )
      renBorrowFeeStatic := and(
        MaxUint23,
        shr(
          GlobalState_renBorrowFeeStatic_bitsAfter,
          encoded
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
                    GlobalState Cached coders
//////////////////////////////////////////////////////////////*/

  function setCached(
    GlobalState old,
    uint256 satoshiPerEth,
    uint256 gweiPerGas,
    uint256 lastUpdateTimestamp
  ) internal pure returns (GlobalState updated) {
    assembly {
      if or(
        gt(satoshiPerEth, MaxUint30),
        or(
          gt(gweiPerGas, MaxUint16),
          gt(lastUpdateTimestamp, MaxUint32)
        )
      ) {
        mstore(0, Panic_error_signature)
        mstore(
          Panic_error_offset,
          Panic_arithmetic
        )
        revert(0, Panic_error_length)
      }
      updated := or(
        and(old, GlobalState_Cached_maskOut),
        or(
          shl(
            GlobalState_satoshiPerEth_bitsAfter,
            satoshiPerEth
          ),
          or(
            shl(
              GlobalState_gweiPerGas_bitsAfter,
              gweiPerGas
            ),
            shl(
              GlobalState_lastUpdateTimestamp_bitsAfter,
              lastUpdateTimestamp
            )
          )
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
             GlobalState ParamsForModuleFees coders
//////////////////////////////////////////////////////////////*/

  function setParamsForModuleFees(
    GlobalState old,
    uint256 satoshiPerEth,
    uint256 gweiPerGas
  ) internal pure returns (GlobalState updated) {
    assembly {
      if or(
        gt(satoshiPerEth, MaxUint30),
        gt(gweiPerGas, MaxUint16)
      ) {
        mstore(0, Panic_error_signature)
        mstore(
          Panic_error_offset,
          Panic_arithmetic
        )
        revert(0, Panic_error_length)
      }
      updated := or(
        and(
          old,
          GlobalState_ParamsForModuleFees_maskOut
        ),
        or(
          shl(
            GlobalState_satoshiPerEth_bitsAfter,
            satoshiPerEth
          ),
          shl(
            GlobalState_gweiPerGas_bitsAfter,
            gweiPerGas
          )
        )
      )
    }
  }

  function getParamsForModuleFees(
    GlobalState encoded
  )
    internal
    pure
    returns (
      uint256 satoshiPerEth,
      uint256 gweiPerGas
    )
  {
    assembly {
      satoshiPerEth := and(
        MaxUint30,
        shr(
          GlobalState_satoshiPerEth_bitsAfter,
          encoded
        )
      )
      gweiPerGas := and(
        MaxUint16,
        shr(
          GlobalState_gweiPerGas_bitsAfter,
          encoded
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
                GlobalState UnburnedShares coders
//////////////////////////////////////////////////////////////*/

  function setUnburnedShares(
    GlobalState old,
    uint256 unburnedGasReserveShares,
    uint256 unburnedZeroFeeShares
  ) internal pure returns (GlobalState updated) {
    assembly {
      if or(
        gt(unburnedGasReserveShares, MaxUint28),
        gt(unburnedZeroFeeShares, MaxUint28)
      ) {
        mstore(0, Panic_error_signature)
        mstore(
          Panic_error_offset,
          Panic_arithmetic
        )
        revert(0, Panic_error_length)
      }
      updated := or(
        and(
          old,
          GlobalState_UnburnedShares_maskOut
        ),
        or(
          shl(
            GlobalState_unburnedGasReserveShares_bitsAfter,
            unburnedGasReserveShares
          ),
          shl(
            GlobalState_unburnedZeroFeeShares_bitsAfter,
            unburnedZeroFeeShares
          )
        )
      )
    }
  }

  function getUnburnedShares(GlobalState encoded)
    internal
    pure
    returns (
      uint256 unburnedGasReserveShares,
      uint256 unburnedZeroFeeShares
    )
  {
    assembly {
      unburnedGasReserveShares := and(
        MaxUint28,
        shr(
          GlobalState_unburnedGasReserveShares_bitsAfter,
          encoded
        )
      )
      unburnedZeroFeeShares := and(
        MaxUint28,
        shr(
          GlobalState_unburnedZeroFeeShares_bitsAfter,
          encoded
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
              GlobalState.zeroBorrowFeeBips coders
//////////////////////////////////////////////////////////////*/

  function getZeroBorrowFeeBips(
    GlobalState encoded
  )
    internal
    pure
    returns (uint256 zeroBorrowFeeBips)
  {
    assembly {
      zeroBorrowFeeBips := shr(
        GlobalState_zeroBorrowFeeBips_bitsAfter,
        encoded
      )
    }
  }

  function setZeroBorrowFeeBips(
    GlobalState old,
    uint256 zeroBorrowFeeBips
  ) internal pure returns (GlobalState updated) {
    assembly {
      updated := or(
        and(
          old,
          GlobalState_zeroBorrowFeeBips_maskOut
        ),
        shl(
          GlobalState_zeroBorrowFeeBips_bitsAfter,
          zeroBorrowFeeBips
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
               GlobalState.renBorrowFeeBips coders
//////////////////////////////////////////////////////////////*/

  function getRenBorrowFeeBips(
    GlobalState encoded
  )
    internal
    pure
    returns (uint256 renBorrowFeeBips)
  {
    assembly {
      renBorrowFeeBips := and(
        MaxUint11,
        shr(
          GlobalState_renBorrowFeeBips_bitsAfter,
          encoded
        )
      )
    }
  }

  function setRenBorrowFeeBips(
    GlobalState old,
    uint256 renBorrowFeeBips
  ) internal pure returns (GlobalState updated) {
    assembly {
      updated := or(
        and(
          old,
          GlobalState_renBorrowFeeBips_maskOut
        ),
        shl(
          GlobalState_renBorrowFeeBips_bitsAfter,
          renBorrowFeeBips
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
               GlobalState.zeroFeeShareBips coders
//////////////////////////////////////////////////////////////*/

  function getZeroFeeShareBips(
    GlobalState encoded
  )
    internal
    pure
    returns (uint256 zeroFeeShareBips)
  {
    assembly {
      zeroFeeShareBips := and(
        MaxUint13,
        shr(
          GlobalState_zeroFeeShareBips_bitsAfter,
          encoded
        )
      )
    }
  }

  function setZeroFeeShareBips(
    GlobalState old,
    uint256 zeroFeeShareBips
  ) internal pure returns (GlobalState updated) {
    assembly {
      updated := or(
        and(
          old,
          GlobalState_zeroFeeShareBips_maskOut
        ),
        shl(
          GlobalState_zeroFeeShareBips_bitsAfter,
          zeroFeeShareBips
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
             GlobalState.zeroBorrowFeeStatic coders
//////////////////////////////////////////////////////////////*/

  function getZeroBorrowFeeStatic(
    GlobalState encoded
  )
    internal
    pure
    returns (uint256 zeroBorrowFeeStatic)
  {
    assembly {
      zeroBorrowFeeStatic := and(
        MaxUint23,
        shr(
          GlobalState_zeroBorrowFeeStatic_bitsAfter,
          encoded
        )
      )
    }
  }

  function setZeroBorrowFeeStatic(
    GlobalState old,
    uint256 zeroBorrowFeeStatic
  ) internal pure returns (GlobalState updated) {
    assembly {
      if gt(zeroBorrowFeeStatic, MaxUint23) {
        mstore(0, Panic_error_signature)
        mstore(
          Panic_error_offset,
          Panic_arithmetic
        )
        revert(0, Panic_error_length)
      }
      updated := or(
        and(
          old,
          GlobalState_zeroBorrowFeeStatic_maskOut
        ),
        shl(
          GlobalState_zeroBorrowFeeStatic_bitsAfter,
          zeroBorrowFeeStatic
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
              GlobalState.renBorrowFeeStatic coders
//////////////////////////////////////////////////////////////*/

  function getRenBorrowFeeStatic(
    GlobalState encoded
  )
    internal
    pure
    returns (uint256 renBorrowFeeStatic)
  {
    assembly {
      renBorrowFeeStatic := and(
        MaxUint23,
        shr(
          GlobalState_renBorrowFeeStatic_bitsAfter,
          encoded
        )
      )
    }
  }

  function setRenBorrowFeeStatic(
    GlobalState old,
    uint256 renBorrowFeeStatic
  ) internal pure returns (GlobalState updated) {
    assembly {
      if gt(renBorrowFeeStatic, MaxUint23) {
        mstore(0, Panic_error_signature)
        mstore(
          Panic_error_offset,
          Panic_arithmetic
        )
        revert(0, Panic_error_length)
      }
      updated := or(
        and(
          old,
          GlobalState_renBorrowFeeStatic_maskOut
        ),
        shl(
          GlobalState_renBorrowFeeStatic_bitsAfter,
          renBorrowFeeStatic
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
                GlobalState.satoshiPerEth coders
//////////////////////////////////////////////////////////////*/

  function getSatoshiPerEth(GlobalState encoded)
    internal
    pure
    returns (uint256 satoshiPerEth)
  {
    assembly {
      satoshiPerEth := and(
        MaxUint30,
        shr(
          GlobalState_satoshiPerEth_bitsAfter,
          encoded
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
                  GlobalState.gweiPerGas coders
//////////////////////////////////////////////////////////////*/

  function getGweiPerGas(GlobalState encoded)
    internal
    pure
    returns (uint256 gweiPerGas)
  {
    assembly {
      gweiPerGas := and(
        MaxUint16,
        shr(
          GlobalState_gweiPerGas_bitsAfter,
          encoded
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
             GlobalState.lastUpdateTimestamp coders
//////////////////////////////////////////////////////////////*/

  function getLastUpdateTimestamp(
    GlobalState encoded
  )
    internal
    pure
    returns (uint256 lastUpdateTimestamp)
  {
    assembly {
      lastUpdateTimestamp := and(
        MaxUint32,
        shr(
          GlobalState_lastUpdateTimestamp_bitsAfter,
          encoded
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
             GlobalState.totalBitcoinBorrowed coders
//////////////////////////////////////////////////////////////*/

  function getTotalBitcoinBorrowed(
    GlobalState encoded
  )
    internal
    pure
    returns (uint256 totalBitcoinBorrowed)
  {
    assembly {
      totalBitcoinBorrowed := and(
        MaxUint40,
        shr(
          GlobalState_totalBitcoinBorrowed_bitsAfter,
          encoded
        )
      )
    }
  }

  function setTotalBitcoinBorrowed(
    GlobalState old,
    uint256 totalBitcoinBorrowed
  ) internal pure returns (GlobalState updated) {
    assembly {
      if gt(totalBitcoinBorrowed, MaxUint40) {
        mstore(0, Panic_error_signature)
        mstore(
          Panic_error_offset,
          Panic_arithmetic
        )
        revert(0, Panic_error_length)
      }
      updated := or(
        and(
          old,
          GlobalState_totalBitcoinBorrowed_maskOut
        ),
        shl(
          GlobalState_totalBitcoinBorrowed_bitsAfter,
          totalBitcoinBorrowed
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
           GlobalState.unburnedGasReserveShares coders
//////////////////////////////////////////////////////////////*/

  function getUnburnedGasReserveShares(
    GlobalState encoded
  )
    internal
    pure
    returns (uint256 unburnedGasReserveShares)
  {
    assembly {
      unburnedGasReserveShares := and(
        MaxUint28,
        shr(
          GlobalState_unburnedGasReserveShares_bitsAfter,
          encoded
        )
      )
    }
  }

  function setUnburnedGasReserveShares(
    GlobalState old,
    uint256 unburnedGasReserveShares
  ) internal pure returns (GlobalState updated) {
    assembly {
      if gt(unburnedGasReserveShares, MaxUint28) {
        mstore(0, Panic_error_signature)
        mstore(
          Panic_error_offset,
          Panic_arithmetic
        )
        revert(0, Panic_error_length)
      }
      updated := or(
        and(
          old,
          GlobalState_unburnedGasReserveShares_maskOut
        ),
        shl(
          GlobalState_unburnedGasReserveShares_bitsAfter,
          unburnedGasReserveShares
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
            GlobalState.unburnedZeroFeeShares coders
//////////////////////////////////////////////////////////////*/

  function getUnburnedZeroFeeShares(
    GlobalState encoded
  )
    internal
    pure
    returns (uint256 unburnedZeroFeeShares)
  {
    assembly {
      unburnedZeroFeeShares := and(
        MaxUint28,
        shr(
          GlobalState_unburnedZeroFeeShares_bitsAfter,
          encoded
        )
      )
    }
  }

  function setUnburnedZeroFeeShares(
    GlobalState old,
    uint256 unburnedZeroFeeShares
  ) internal pure returns (GlobalState updated) {
    assembly {
      if gt(unburnedZeroFeeShares, MaxUint28) {
        mstore(0, Panic_error_signature)
        mstore(
          Panic_error_offset,
          Panic_arithmetic
        )
        revert(0, Panic_error_length)
      }
      updated := or(
        and(
          old,
          GlobalState_unburnedZeroFeeShares_maskOut
        ),
        shl(
          GlobalState_unburnedZeroFeeShares_bitsAfter,
          unburnedZeroFeeShares
        )
      )
    }
  }

  /*//////////////////////////////////////////////////////////////
                 GlobalState comparison methods
//////////////////////////////////////////////////////////////*/

  function equals(GlobalState a, GlobalState b)
    internal
    pure
    returns (bool _equals)
  {
    assembly {
      _equals := eq(a, b)
    }
  }

  function isNull(GlobalState a)
    internal
    pure
    returns (bool _isNull)
  {
    _isNull = equals(a, DefaultGlobalState);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

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
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface IMintGateway {
  function mint(
    bytes32 _pHash,
    uint256 _amount,
    bytes32 _nHash,
    bytes calldata _sig
  ) external returns (uint256);

  function mintFee() external view returns (uint256);
}

interface IBurnGateway {
  function burn(bytes memory _to, uint256 _amountScaled)
    external
    returns (uint256);

  function burnFee() external view returns (uint256);
}

interface IGateway is IMintGateway, IBurnGateway {

}

/*
interface IGateway is IMintGateway, IBurnGateway {
    function mint(
        bytes32 _pHash,
        uint256 _amount,
        bytes32 _nHash,
        bytes calldata _sig
    ) external returns (uint256);

    function mintFee() external view returns (uint256);

    function burn(bytes calldata _to, uint256 _amountScaled)
        external
        returns (uint256);

    function burnFee() external view returns (uint256);
}
*/

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.13;

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author ZeroDAO
/// @author Modified from Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
  /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

  function safeTransferETH(address to, uint256 amount) internal {
    bool success;

    assembly {
      // Transfer the ETH and store if it succeeded or not.
      success := call(gas(), to, amount, 0, 0, 0, 0)
    }

    require(success, "ETH_TRANSFER_FAILED");
  }

  /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

  function safeTransferFrom(
    address token,
    address from,
    address to,
    uint256 amount
  ) internal {
    bool success;

    assembly {
      // Get a pointer to some free memory.
      let freeMemoryPointer := mload(0x40)

      // Write the abi-encoded calldata into memory, beginning with the function selector.
      mstore(
        freeMemoryPointer,
        0x23b872dd00000000000000000000000000000000000000000000000000000000
      )
      mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
      mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
      mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

      success := and(
        // Set success to whether the call reverted, if not we check it either
        // returned exactly 1 (can't just be non-zero data), or had no return data.
        or(
          and(eq(mload(0), 1), gt(returndatasize(), 31)),
          iszero(returndatasize())
        ),
        // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
        // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
        // Counterintuitively, this call must be positioned second to the or() call in the
        // surrounding and() call or else returndatasize() will be zero during the computation.
        call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
      )
    }

    require(success, "TRANSFER_FROM_FAILED");
  }

  function safeTransfer(
    address token,
    address to,
    uint256 amount
  ) internal {
    bool success;

    assembly {
      // Get a pointer to some free memory.
      let freeMemoryPointer := mload(0x40)

      // Write the abi-encoded calldata into memory, beginning with the function selector.
      mstore(
        freeMemoryPointer,
        0xa9059cbb00000000000000000000000000000000000000000000000000000000
      )
      mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
      mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

      success := and(
        // Set success to whether the call reverted, if not we check it either
        // returned exactly 1 (can't just be non-zero data), or had no return data.
        or(
          and(eq(mload(0), 1), gt(returndatasize(), 31)),
          iszero(returndatasize())
        ),
        // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
        // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
        // Counterintuitively, this call must be positioned second to the or() call in the
        // surrounding and() call or else returndatasize() will be zero during the computation.
        call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
      )
    }

    require(success, "TRANSFER_FAILED");
  }

  function safeApprove(
    address token,
    address to,
    uint256 amount
  ) internal {
    bool success;

    assembly {
      // Get a pointer to some free memory.
      let freeMemoryPointer := mload(0x40)

      // Write the abi-encoded calldata into memory, beginning with the function selector.
      mstore(
        freeMemoryPointer,
        0x095ea7b300000000000000000000000000000000000000000000000000000000
      )
      mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
      mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

      success := and(
        // Set success to whether the call reverted, if not we check it either
        // returned exactly 1 (can't just be non-zero data), or had no return data.
        or(
          and(eq(mload(0), 1), gt(returndatasize(), 31)),
          iszero(returndatasize())
        ),
        // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
        // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
        // Counterintuitively, this call must be positioned second to the or() call in the
        // surrounding and() call or else returndatasize() will be zero during the computation.
        call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
      )
    }

    require(success, "APPROVE_FAILED");
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.13;
import "../interfaces/ReentrancyErrors.sol";
import "../storage/ReentrancyGuardStorage.sol";

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard is ReentrancyGuardStorage, ReentrancyErrors {
  function _initialize() internal virtual {
    locked = 1;
  }

  modifier nonReentrant() virtual {
    if (locked != 1) {
      revert Reentrancy();
    }

    locked = 2;
    _;
    locked = 1;
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.13;

import "../storage/ERC2612Storage.sol";
import "../utils/SignatureVerification.sol";
import "../interfaces/IERC2612.sol";
import "./ERC20.sol";

contract ERC2612 is ERC2612Storage, ERC20, SignatureVerification, IERC2612 {
  /*//////////////////////////////////////////////////////////////
                             Constructor
  //////////////////////////////////////////////////////////////*/

  constructor(
    address _proxyContract,
    string memory _name,
    string memory _symbol,
    uint8 _decimals,
    string memory _version
  )
    ERC20(_name, _symbol, _decimals)
    SignatureVerification(_proxyContract, _name, _version)
  {}

  /*//////////////////////////////////////////////////////////////
                               Queries
  //////////////////////////////////////////////////////////////*/

  function DOMAIN_SEPARATOR() external view override returns (bytes32) {
    return getDomainSeparator();
  }

  function nonces(address account) external view override returns (uint256) {
    return _nonces[account];
  }

  /*//////////////////////////////////////////////////////////////
                               Actions
  //////////////////////////////////////////////////////////////*/

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8,
    bytes32,
    bytes32
  ) external virtual override {
    if (deadline < block.timestamp) {
      revert PermitDeadlineExpired(deadline, block.timestamp);
    }
    _verifyPermitSignature(owner, _nonces[owner]++, deadline);

    // Unchecked because the only math done is incrementing
    // the owner's nonce which cannot realistically overflow.
    unchecked {
      _allowance[owner][spender] = value;
    }

    emit Approval(owner, spender, value);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "./IERC2612.sol";
import "./ReentrancyErrors.sol";

interface IERC4626 is IERC2612, ReentrancyErrors {
  function asset() external view returns (address);

  function deposit(uint256 assets, address receiver)
    external
    returns (uint256 shares);

  function mint(uint256 shares, address receiver)
    external
    returns (uint256 assets);

  function withdraw(
    uint256 assets,
    address receiver,
    address owner
  ) external returns (uint256 shares);

  function redeem(
    uint256 shares,
    address receiver,
    address owner
  ) external returns (uint256 assets);

  function totalAssets() external view returns (uint256);

  function convertToShares(uint256 assets) external view returns (uint256);

  function convertToAssets(uint256 shares) external view returns (uint256);

  function previewDeposit(uint256 assets) external view returns (uint256);

  function previewMint(uint256 shares) external view returns (uint256);

  function previewWithdraw(uint256 assets) external view returns (uint256);

  function previewRedeem(uint256 shares) external view returns (uint256);

  function maxDeposit(address) external view returns (uint256);

  function maxMint(address) external view returns (uint256);

  function maxWithdraw(address owner) external view returns (uint256);

  function maxRedeem(address owner) external view returns (uint256);

  /*//////////////////////////////////////////////////////////////
                                ERRORS
  //////////////////////////////////////////////////////////////*/

  error ZeroShares();

  /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

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
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

interface IGovernable {
  function setGovernance(address _governance) external;

  function governance() external view returns (address);

  /*//////////////////////////////////////////////////////////////
                            Errors
    //////////////////////////////////////////////////////////////*/

  error NotGovernance();

  /*//////////////////////////////////////////////////////////////
                            Events
    //////////////////////////////////////////////////////////////*/

  event GovernanceTransferred(
    address indexed oldGovernance,
    address indexed newGovernance
  );
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

interface InitializationErrors {
  error AlreadyInitialized();
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.13;

import "./ERC20Storage.sol";

contract ERC2612Storage is ERC20Storage {
  mapping(address => uint256) internal _nonces;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.13;

contract ReentrancyGuardStorage {
  uint256 internal locked;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

interface ReentrancyErrors {
  error Reentrancy();
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "../EIP712/UpgradeableEIP712.sol";
import { ECDSA } from "oz460/utils/cryptography/ECDSA.sol";

bytes constant Permit_typeString = "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)";
bytes32 constant Permit_typeHash = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
uint256 constant Permit_typeHash_ptr = 0x0;
uint256 constant Permit_owner_ptr = 0x20;
uint256 constant Permit_nonce_ptr = 0x80;
uint256 constant Permit_deadline_ptr = 0xa0;
uint256 constant Permit_owner_cdPtr = 0x04;
uint256 constant Permit_v_cdPtr = 0x84;
uint256 constant Permit_signature_length = 0x60;
uint256 constant Permit_calldata_params_length = 0x60;
uint256 constant Permit_length = 0xc0;

uint256 constant ECRecover_precompile = 0x01;
uint256 constant ECRecover_digest_ptr = 0x0;
uint256 constant ECRecover_v_ptr = 0x20;
uint256 constant ECRecover_calldata_length = 0x80;

contract SignatureVerification is UpgradeableEIP712 {
  /*//////////////////////////////////////////////////////////////
                             Constructor
  //////////////////////////////////////////////////////////////*/

  constructor(
    address _proxyContract,
    string memory _name,
    string memory _version
  ) UpgradeableEIP712(_proxyContract, _name, _version) {
    if (Permit_typeHash != keccak256(Permit_typeString)) {
      revert InvalidTypeHash();
    }
  }

  /*//////////////////////////////////////////////////////////////
                               Permit
  //////////////////////////////////////////////////////////////*/

  function _digestPermit(uint256 nonce, uint256 deadline) internal view returns (bytes32 digest) {
    bytes32 domainSeparator = getDomainSeparator();
    assembly {
      mstore(Permit_typeHash_ptr, Permit_typeHash)
      calldatacopy(Permit_owner_ptr, Permit_owner_cdPtr, Permit_calldata_params_length)
      mstore(Permit_nonce_ptr, nonce)
      mstore(Permit_deadline_ptr, deadline)
      let permitHash := keccak256(Permit_typeHash_ptr, Permit_length)
      mstore(0, EIP712Signature_prefix)
      mstore(EIP712Signature_domainSeparator_ptr, domainSeparator)
      mstore(EIP712Signature_digest_ptr, permitHash)
      digest := keccak256(0, EIP712Signature_length)
    }
  }

  function _verifyPermitSignature(
    address owner,
    uint256 nonce,
    uint256 deadline
  ) internal view RestoreFirstTwoUnreservedSlots RestoreFreeMemoryPointer RestoreZeroSlot {
    bytes32 digest = _digestPermit(nonce, deadline);
    bool validSignature;
    assembly {
      mstore(ECRecover_digest_ptr, digest)
      // Copy v, r, s from calldata
      calldatacopy(ECRecover_v_ptr, Permit_v_cdPtr, Permit_signature_length)
      // Call ecrecover precompile to validate signature
      let success := staticcall(
        gas(),
        ECRecover_precompile, // ecrecover precompile
        ECRecover_digest_ptr,
        ECRecover_calldata_length,
        0x0,
        0x20
      )
      validSignature := and(
        success, // call succeeded
        and(
          gt(owner, 0), // owner != 0
          eq(owner, mload(0)) // owner == recoveredAddress
        )
      )
    }
    if (!validSignature) {
      revert InvalidSigner();
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "./IERC20.sol";

interface IERC2612 is IERC20 {
  error PermitDeadlineExpired(uint256 deadline, uint256 timestamp);

  /**
   * @dev Sets `value` as the allowance of `spender` over `owner`'s tokens,
   * given `owner`'s signed approval.
   *
   * IMPORTANT: The same issues {IERC20-approve} has related to transaction
   * ordering also apply here.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `owner` cannot be the zero address.
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
   * @dev Returns the current ERC2612 nonce for `owner`. This value must be
   * included whenever a signature is generated for {permit}.
   *
   * Every successful call to {permit} increases ``owner``'s nonce by one. This
   * prevents a signature from being used multiple times.
   */
  function nonces(address owner) external view returns (uint256);

  function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.13;

import "../utils/CompactStrings.sol";
import "../storage/ERC20Storage.sol";
import "../interfaces/IERC20.sol";

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Zero Protocol
/// @author Modified from Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
contract ERC20 is ERC20Storage, CompactStrings, IERC20 {
  /*//////////////////////////////////////////////////////////////
                             Immutables
  //////////////////////////////////////////////////////////////*/

  bytes32 private immutable _packedName;

  bytes32 private immutable _packedSymbol;

  uint8 public immutable override decimals;

  constructor(
    string memory _name,
    string memory _symbol,
    uint8 _decimals
  ) {
    _packedName = packString(_name);
    _packedSymbol = packString(_symbol);
    decimals = _decimals;
  }

  /*//////////////////////////////////////////////////////////////
                               Queries
  //////////////////////////////////////////////////////////////*/

  function name() external view override returns (string memory) {
    return unpackString(_packedName);
  }

  function symbol() external view override returns (string memory) {
    return unpackString(_packedSymbol);
  }

  function totalSupply() external view override returns (uint256) {
    return _totalSupply;
  }

  function allowance(address owner, address spender)
    external
    view
    override
    returns (uint256)
  {
    return _allowance[owner][spender];
  }

  function balanceOf(address account) external view override returns (uint256) {
    return _balanceOf[account];
  }

  /*//////////////////////////////////////////////////////////////
                               Actions
  //////////////////////////////////////////////////////////////*/

  function approve(address spender, uint256 amount)
    external
    virtual
    override
    returns (bool)
  {
    _allowance[msg.sender][spender] = amount;

    emit Approval(msg.sender, spender, amount);

    return true;
  }

  function transfer(address to, uint256 amount)
    external
    virtual
    override
    returns (bool)
  {
    _balanceOf[msg.sender] -= amount;

    // Cannot overflow because the sum of all user
    // balances can't exceed the max uint256 value.
    unchecked {
      _balanceOf[to] += amount;
    }

    emit Transfer(msg.sender, to, amount);

    return true;
  }

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) external virtual override returns (bool) {
    uint256 allowed = _allowance[from][msg.sender]; // Saves gas for limited approvals.

    if (allowed != type(uint256).max) {
      _allowance[from][msg.sender] = allowed - amount;
    }

    _balanceOf[from] -= amount;

    // Cannot overflow because the sum of all user
    // balances can't exceed the max uint256 value.
    unchecked {
      _balanceOf[to] += amount;
    }

    emit Transfer(from, to, amount);

    return true;
  }

  /*//////////////////////////////////////////////////////////////
                       Internal State Handlers
  //////////////////////////////////////////////////////////////*/

  function _mint(address to, uint256 amount) internal virtual {
    _totalSupply += amount;

    // Cannot overflow because the sum of all user
    // balances can't exceed the max uint256 value.
    unchecked {
      _balanceOf[to] += amount;
    }

    emit Transfer(address(0), to, amount);
  }

  function _burn(address from, uint256 amount) internal virtual {
    _balanceOf[from] -= amount;

    // Cannot underflow because a user's balance
    // will never be larger than the total supply.
    unchecked {
      _totalSupply -= amount;
    }

    emit Transfer(from, address(0), amount);
  }

  function _transfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual {
    _balanceOf[from] -= amount;

    // Cannot overflow because the sum of all user
    // balances can't exceed the max uint256 value.
    unchecked {
      _balanceOf[to] += amount;
    }

    emit Transfer(from, to, amount);
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.13;

contract ERC20Storage {
  uint256 internal _totalSupply;

  mapping(address => uint256) internal _balanceOf;

  mapping(address => mapping(address => uint256)) internal _allowance;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.13;

import "./AbstractEIP712.sol";

// @todo Rename UpgradeableEIP712 to UpgradeableSingletonEIP712
/**
 * @dev ProxyImmutable is used to set `proxyContract` in UpgradeableEIP712
 * before the constructor of AbstractEIP712 runs, giving it access to the
 * `verifyingContract` function. The address of the proxy contract must be
 * known when the implementation is deployed.
 */
contract ProxyImmutable {
  address internal immutable proxyContract;

  constructor(address _proxyContract) {
    proxyContract = _proxyContract;
  }
}

contract UpgradeableEIP712 is ProxyImmutable, AbstractEIP712 {
  constructor(
    address _proxyContract,
    string memory _name,
    string memory _version
  ) ProxyImmutable(_proxyContract) AbstractEIP712(_name, _version) {}

  function _initialize() internal virtual {
    if (address(this) != _verifyingContract()) {
      revert InvalidVerifyingContract();
    }
  }

  function _verifyingContract()
    internal
    view
    virtual
    override
    returns (address)
  {
    return proxyContract;
  }
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
        InvalidSignatureV // Deprecated in v4.8
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);

  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

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
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "../interfaces/CompactStringErrors.sol";

contract CompactStrings is CompactStringErrors {
  function packString(string memory unpackedString)
    internal
    pure
    returns (bytes32 packedString)
  {
    if (bytes(unpackedString).length > 31) {
      revert InvalidCompactString();
    }
    assembly {
      packedString := mload(add(unpackedString, 31))
    }
  }

  function unpackString(bytes32 packedString)
    internal
    pure
    returns (string memory unpackedString)
  {
    assembly {
      // Get free memory pointer
      let freeMemPtr := mload(0x40)
      // Increase free memory pointer by 64 bytes
      mstore(0x40, add(freeMemPtr, 0x40))
      // Set pointer to string
      unpackedString := freeMemPtr
      // Overwrite buffer with zeroes in case it has already been used
      mstore(freeMemPtr, 0)
      mstore(add(freeMemPtr, 0x20), 0)
      // Write length and name to string
      mstore(add(freeMemPtr, 0x1f), packedString)
    }
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.13;

import "../utils/MemoryRestoration.sol";
import "../interfaces/EIP712Errors.sol";

bytes constant EIP712Domain_typeString = "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)";
bytes32 constant EIP712Domain_typeHash = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

uint256 constant EIP712Signature_prefix = 0x1901000000000000000000000000000000000000000000000000000000000000;
uint256 constant EIP712Signature_domainSeparator_ptr = 0x2;
uint256 constant EIP712Signature_digest_ptr = 0x22;
uint256 constant EIP712Signature_length = 0x42;

uint256 constant DomainSeparator_nameHash_offset = 0x20;
uint256 constant DomainSeparator_versionHash_offset = 0x40;
uint256 constant DomainSeparator_chainId_offset = 0x60;
uint256 constant DomainSeparator_verifyingContract_offset = 0x80;
uint256 constant DomainSeparator_length = 0xa0;

abstract contract AbstractEIP712 is MemoryRestoration, EIP712Errors {
  uint256 private immutable _CHAIN_ID;
  bytes32 private immutable _DOMAIN_SEPARATOR;
  bytes32 private immutable _NAME_HASH;
  bytes32 private immutable _VERSION_HASH;

  constructor(string memory _name, string memory _version) {
    _CHAIN_ID = block.chainid;
    _NAME_HASH = keccak256(bytes(_name));
    _VERSION_HASH = keccak256(bytes(_version));
    _DOMAIN_SEPARATOR = _computeDomainSeparator();
    if (EIP712Domain_typeHash != keccak256(EIP712Domain_typeString)) {
      revert InvalidTypeHash();
    }
  }

  function _computeDomainSeparator() internal view returns (bytes32 separator) {
    address verifyingContract = _verifyingContract();
    bytes32 nameHash = _NAME_HASH;
    bytes32 versionHash = _VERSION_HASH;
    assembly {
      let ptr := mload(0x40)
      mstore(ptr, EIP712Domain_typeHash)
      mstore(add(ptr, DomainSeparator_nameHash_offset), nameHash)
      mstore(add(ptr, DomainSeparator_versionHash_offset), versionHash)
      mstore(add(ptr, DomainSeparator_chainId_offset), chainid())
      mstore(
        add(ptr, DomainSeparator_verifyingContract_offset),
        verifyingContract
      )
      separator := keccak256(ptr, DomainSeparator_length)
    }
  }

  function getDomainSeparator() internal view virtual returns (bytes32) {
    return
      block.chainid == _CHAIN_ID
        ? _DOMAIN_SEPARATOR
        : _computeDomainSeparator();
  }

  function _verifyingContract() internal view virtual returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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
pragma solidity >=0.8.13;

interface CompactStringErrors {
  error InvalidCompactString();
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.13;

contract MemoryRestoration {
  modifier RestoreOneWord(uint256 slot1) {
    uint256 cachedValue;
    assembly {
      cachedValue := mload(slot1)
    }
    _;
    assembly {
      mstore(slot1, cachedValue)
    }
  }

  modifier RestoreTwoWords(uint256 slot1, uint256 slot2) {
    uint256 cachedValue1;
    uint256 cachedValue2;
    assembly {
      cachedValue1 := mload(slot1)
      cachedValue2 := mload(slot2)
    }
    _;
    assembly {
      mstore(slot1, cachedValue1)
      mstore(slot2, cachedValue2)
    }
  }

  modifier RestoreThreeWords(
    uint256 slot1,
    uint256 slot2,
    uint256 slot3
  ) {
    uint256 cachedValue1;
    uint256 cachedValue2;
    uint256 cachedValue3;
    assembly {
      cachedValue1 := mload(slot1)
      cachedValue2 := mload(slot2)
      cachedValue3 := mload(slot3)
    }
    _;
    assembly {
      mstore(slot1, cachedValue1)
      mstore(slot2, cachedValue2)
      mstore(slot3, cachedValue3)
    }
  }

  modifier RestoreFourWords(
    uint256 slot1,
    uint256 slot2,
    uint256 slot3,
    uint256 slot4
  ) {
    uint256 cachedValue1;
    uint256 cachedValue2;
    uint256 cachedValue3;
    uint256 cachedValue4;
    assembly {
      cachedValue1 := mload(slot1)
      cachedValue2 := mload(slot2)
      cachedValue3 := mload(slot3)
      cachedValue4 := mload(slot4)
    }
    _;
    assembly {
      mstore(slot1, cachedValue1)
      mstore(slot2, cachedValue2)
      mstore(slot3, cachedValue3)
      mstore(slot4, cachedValue4)
    }
  }

  modifier RestoreFourWordsBefore(bytes memory data) {
    uint256 cachedValue1;
    uint256 cachedValue2;
    uint256 cachedValue3;
    uint256 cachedValue4;
    assembly {
      cachedValue1 := mload(sub(data, 0x20))
      cachedValue2 := mload(sub(data, 0x40))
      cachedValue3 := mload(sub(data, 0x60))
      cachedValue4 := mload(sub(data, 0x80))
    }
    _;
    assembly {
      mstore(sub(data, 0x20), cachedValue1)
      mstore(sub(data, 0x40), cachedValue2)
      mstore(sub(data, 0x60), cachedValue3)
      mstore(sub(data, 0x80), cachedValue4)
    }
  }

  modifier RestoreFirstTwoUnreservedSlots() {
    uint256 cachedValue1;
    uint256 cachedValue2;
    assembly {
      cachedValue1 := mload(0x80)
      cachedValue2 := mload(0xa0)
    }
    _;
    assembly {
      mstore(0x80, cachedValue1)
      mstore(0xa0, cachedValue2)
    }
  }

  modifier RestoreFreeMemoryPointer() {
    uint256 freeMemoryPointer;
    assembly {
      freeMemoryPointer := mload(0x40)
    }
    _;
    assembly {
      mstore(0x40, freeMemoryPointer)
    }
  }

  modifier RestoreZeroSlot() {
    _;
    assembly {
      mstore(0x60, 0)
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

interface EIP712Errors {
  error InvalidTypeHash();

  error InvalidSigner();

  error InvalidVerifyingContract();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}