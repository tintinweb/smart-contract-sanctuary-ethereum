// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './ImperpetualPoolBase.sol';

contract ImperpetualPoolV1 is ImperpetualPoolBase, IWeightedPoolInit {
  uint256 private constant CONTRACT_REVISION = 1;
  uint8 internal constant DECIMALS = 18;

  constructor(ImperpetualPoolExtension extension, JoinablePoolExtension joinExtension)
    ERC20DetailsBase('', '', DECIMALS)
    ImperpetualPoolBase(extension, joinExtension)
  {}

  function initializeWeighted(
    address governor_,
    string calldata tokenName,
    string calldata tokenSymbol,
    WeightedPoolParams calldata params
  ) public override initializer(CONTRACT_REVISION) {
    _initializeERC20(tokenName, tokenSymbol, DECIMALS);
    internalSetGovernor(governor_);
    internalSetPoolParams(params);
  }

  function getRevision() internal pure override returns (uint256) {
    return CONTRACT_REVISION;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './ImperpetualPoolStorage.sol';
import './ImperpetualPoolExtension.sol';
import './WeightedPoolBase.sol';

/// @title Index Pool Base with Perpetual Index Pool Tokens
/// @notice Handles adding coverage by users.
abstract contract ImperpetualPoolBase is ImperpetualPoolStorage {
  using Math for uint256;
  using WadRayMath for uint256;
  using PercentageMath for uint256;
  using Balances for Balances.RateAcc;

  constructor(ImperpetualPoolExtension extension, JoinablePoolExtension joinExtension) WeightedPoolBase(extension, joinExtension) {}

  function _addCoverage(uint256 value)
    private
    returns (
      bool done,
      AddCoverageParams memory params,
      PartialState memory part
    )
  {
    uint256 excessCoverage = _excessCoverage;
    if (excessCoverage > 0 || value > 0) {
      uint256 newExcess;
      uint256 loopLimit;
      (newExcess, loopLimit, params, part) = super.internalAddCoverage(value + excessCoverage, defaultLoopLimit(LoopLimitType.AddCoverage, 0));

      if (newExcess != excessCoverage) {
        internalSetExcess(newExcess);
      }

      internalAutoPullDemand(params, loopLimit, newExcess > 0, value);

      done = true;
    }
  }

  /// @dev Updates the user's balance based upon the current exchange rate of $CC to $Pool_Coverage
  /// @dev Update the new amount of excess coverage
  function internalMintForCoverage(address account, uint256 value) internal override {
    (bool done, AddCoverageParams memory params, PartialState memory part) = _addCoverage(value);

    // TODO:TEST test adding coverage to an empty pool
    _mint(account, done ? value.rayDiv(exchangeRate(super.internalGetPremiumTotals(part, params.premium), value)) : 0, value);
  }

  function internalSubrogated(uint256 value) internal override {
    internalSetExcess(_excessCoverage + value);
    internalSyncStake();
  }

  function updateCoverageOnCancel(
    address insured,
    uint256 payoutValue,
    uint256 advanceValue,
    uint256 recoveredValue,
    uint256 premiumDebt
  ) external onlySelf returns (uint256) {
    uint256 givenOutValue = _insuredBalances[insured];
    Value.require(givenOutValue <= advanceValue);

    delete _insuredBalances[insured];
    uint256 givenValue = givenOutValue + premiumDebt;
    bool syncStake;

    if (givenValue != payoutValue) {
      if (givenValue > payoutValue) {
        recoveredValue += advanceValue - givenValue;

        // try to take back the given coverage
        uint256 recovered = transferAvailableCollateralFrom(insured, address(this), givenValue - payoutValue);

        // only the outstanding premium debt should be deducted, an outstanding coverage debt is managed as reduction of coverage itself
        if (premiumDebt > recovered) {
          _decrementTotalValue(premiumDebt - recovered);
          syncStake = true;
        }

        recoveredValue += recovered;
      } else {
        uint256 underpay = payoutValue - givenValue;

        if (recoveredValue < underpay) {
          recoveredValue += _calcAvailableDrawdownReserve(recoveredValue + advanceValue);
          if (recoveredValue < underpay) {
            underpay = recoveredValue;
          }
          recoveredValue = 0;
        } else {
          recoveredValue -= underpay;
        }

        if (underpay > 0) {
          transferCollateral(insured, underpay);
        }
        payoutValue = givenValue + underpay;
      }
    }

    if (recoveredValue > 0) {
      internalSetExcess(_excessCoverage + recoveredValue);
      internalOnCoverageRecovered();
      syncStake = true;
    }
    if (syncStake) {
      internalSyncStake();
    }

    return payoutValue;
  }

  function updateCoverageOnReconcile(
    address insured,
    uint256 receivedCoverage,
    uint256 totalCovered
  ) external onlySelf returns (uint256) {
    uint256 expectedAmount = totalCovered.percentMul(_params.coveragePrepayPct);
    uint256 actualAmount = _insuredBalances[insured];

    if (actualAmount < expectedAmount) {
      uint256 d = expectedAmount - actualAmount;
      if (d < receivedCoverage) {
        receivedCoverage = d;
      }
      if ((d = balanceOfCollateral(address(this))) < receivedCoverage) {
        receivedCoverage = d;
      }

      if (receivedCoverage > 0) {
        _insuredBalances[insured] = actualAmount + receivedCoverage;
        transferCollateral(insured, receivedCoverage);
      }
    } else {
      receivedCoverage = 0;
    }

    return receivedCoverage;
  }

  function _decrementTotalValue(uint256 valueLoss) private {
    _valueAdjustment -= valueLoss.asInt128();
  }

  function _incrementTotalValue(uint256 valueGain) private {
    _valueAdjustment += valueGain.asInt128();
  }

  /// @dev Attempt to take the excess coverage and fill batches
  /// @dev Occurs when there is excess and a new batch is ready (more demand added)
  function pushCoverageExcess() public override {
    _addCoverage(0);
  }

  function totalSupplyValue(DemandedCoverage memory coverage, uint256 added) private view returns (uint256 v) {
    v = coverage.totalCovered - _burntDrawdown;
    v += coverage.pendingCovered + _excessCoverage;
    v = v - added;

    {
      int256 va = _valueAdjustment;
      if (va >= 0) {
        v += uint256(va);
      } else {
        v -= uint256(-va);
      }
    }
    v += coverage.totalPremium - _burntPremium;
  }

  function totalSupplyValue() public view returns (uint256) {
    return totalSupplyValue(super.internalGetPremiumTotals(), 0);
  }

  function exchangeRate(DemandedCoverage memory coverage, uint256 added) private view returns (uint256 v) {
    if ((v = totalSupply()) > 0) {
      v = totalSupplyValue(coverage, added).rayDiv(v);
    } else {
      v = WadRayMath.RAY;
    }
  }

  function exchangeRate() public view override returns (uint256 v) {
    return exchangeRate(super.internalGetPremiumTotals(), 0);
  }

  function balanceOf(address account) public view override returns (uint256) {
    return _balances[account].balance;
  }

  function balancesOf(address account)
    public
    view
    returns (
      uint256 value,
      uint256 balance,
      uint256 swappable
    )
  {
    balance = balanceOf(account);
    swappable = value = balance.rayMul(exchangeRate());
  }

  ///@notice Transfer a balance to a recipient, syncs the balances before performing the transfer
  ///@param sender  The sender
  ///@param recipient The receiver
  ///@param amount  Amount to transfer
  function transferBalance(
    address sender,
    address recipient,
    uint256 amount
  ) internal override {
    _balances[sender].balance = uint128(_balances[sender].balance - amount);
    _balances[recipient].balance += uint128(amount);
  }

  function _burnValue(
    address account,
    uint256 value,
    DemandedCoverage memory coverage
  ) private returns (uint256 burntAmount) {
    _burn(account, burntAmount = value.rayDiv(exchangeRate(coverage, 0)), value);
  }

  function _burnPremium(
    address account,
    uint256 value,
    DemandedCoverage memory coverage
  ) internal returns (uint256 burntAmount) {
    Value.require(coverage.totalPremium >= _burntPremium + value);
    burntAmount = _burnValue(account, value, coverage);
    _burntPremium += value.asUint128();
  }

  function _burnCoverage(
    address account,
    uint256 value,
    address recepient,
    DemandedCoverage memory coverage
  ) internal returns (uint256 burntAmount) {
    // NB! removed for performance reasons - use carefully
    // Value.require(value <= _calcAvailableUserDrawdown(totalCovered + pendingCovered));

    burntAmount = _burnValue(account, value, coverage);

    _burntDrawdown += value.asUint128();
    transferCollateral(recepient, value);
  }

  function internalBurnPremium(
    address account,
    uint256 value,
    address drawdownRecepient
  ) internal override {
    DemandedCoverage memory coverage = super.internalGetPremiumTotals();
    drawdownRecepient != address(0) ? _burnCoverage(account, value, drawdownRecepient, coverage) : _burnPremium(account, value, coverage);
  }

  function __calcAvailableDrawdown(uint256 totalCovered, uint16 maxDrawdown) internal view returns (uint256) {
    uint256 burntDrawdown = _burntDrawdown;
    totalCovered += _excessCoverage;
    totalCovered = totalCovered.percentMul(maxDrawdown);
    return totalCovered.boundedSub(burntDrawdown);
  }

  function _calcAvailableDrawdownReserve(uint256 extra) internal view returns (uint256) {
    return __calcAvailableDrawdown(_coveredTotal() + extra, PercentageMath.ONE - _params.coveragePrepayPct);
  }

  function _calcAvailableUserDrawdown() internal view returns (uint256) {
    return _calcAvailableUserDrawdown(_coveredTotal());
  }

  function _calcAvailableUserDrawdown(uint256 totalCovered) internal view returns (uint256) {
    return __calcAvailableDrawdown(totalCovered, _params.maxUserDrawdownPct);
  }

  function internalCollectDrawdownPremium() internal view override returns (uint256) {
    return _calcAvailableUserDrawdown();
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../tools/tokens/ERC20BalancelessBase.sol';
import '../tools/Errors.sol';
import '../libraries/Balances.sol';
import './WeightedPoolBase.sol';

abstract contract ImperpetualPoolStorage is WeightedPoolBase, ERC20BalancelessBase {
  using Math for uint256;
  using WadRayMath for uint256;

  mapping(address => uint256) internal _insuredBalances; // [insured]

  uint128 private _totalSupply;

  uint128 internal _burntDrawdown;
  uint128 internal _burntPremium;

  /// @dev decreased on losses (e.g. premium underpaid or collateral loss), increased on external value streams, e.g. collateral yield
  int128 internal _valueAdjustment;

  function totalSupply() public view override(IERC20, WeightedPoolBase) returns (uint256) {
    return _totalSupply;
  }

  function _mint(
    address account,
    uint256 amount256,
    uint256 value
  ) internal {
    value;
    uint128 amount = amount256.asUint128();

    emit Transfer(address(0), account, amount);
    _totalSupply += amount;
    _balances[account].balance += amount;
  }

  function _burn(
    address account,
    uint256 amount256,
    uint256 value
  ) internal {
    uint128 amount = amount256.asUint128();

    emit Transfer(account, address(0), amount);
    _balances[account].balance -= amount;
    unchecked {
      // overflow doesnt matter much here
      _balances[account].extra += uint128(value);
    }
    _totalSupply -= amount;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './WeightedPoolExtension.sol';
import './ImperpetualPoolBase.sol';

/// @dev NB! MUST HAVE NO STORAGE
contract ImperpetualPoolExtension is WeightedPoolExtension {
  using WadRayMath for uint256;
  using PercentageMath for uint256;
  using Balances for Balances.RateAcc;

  constructor(
    IAccessController acl,
    uint256 unitSize,
    address collateral_
  ) WeightedPoolConfig(acl, unitSize, collateral_) {}

  function internalTransferCancelledCoverage(
    address insured,
    uint256 payoutValue,
    uint256 advanceValue,
    uint256 recoveredValue,
    uint256 premiumDebt
  ) internal override returns (uint256) {
    return ImperpetualPoolBase(address(this)).updateCoverageOnCancel(insured, payoutValue, advanceValue, recoveredValue, premiumDebt);
    // ^^ this call avoids code to be duplicated within PoolExtension to reduce contract size
  }

  function internalTransferDemandedCoverage(
    address insured,
    uint256 receivedCoverage,
    DemandedCoverage memory coverage
  ) internal override returns (uint256) {
    if (receivedCoverage > 0) {
      return ImperpetualPoolBase(address(this)).updateCoverageOnReconcile(insured, receivedCoverage, coverage.totalCovered);
      // ^^ this call avoids code to be duplicated within PoolExtension to reduce contract size
    }
    return receivedCoverage;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../tools/upgradeability/VersionedInitializable.sol';
import '../tools/upgradeability/Delegator.sol';
import '../tools/tokens/ERC1363ReceiverBase.sol';
import '../interfaces/ICollateralStakeManager.sol';
import '../interfaces/IYieldStakeAsset.sol';
import '../interfaces/IPremiumActuary.sol';
import '../interfaces/IInsurerPool.sol';
import '../interfaces/IJoinable.sol';
import './WeightedPoolExtension.sol';
import './JoinablePoolExtension.sol';
import './WeightedPoolStorage.sol';

abstract contract WeightedPoolBase is
  IJoinableBase,
  IInsurerPoolBase,
  IPremiumActuary,
  IYieldStakeAsset,
  Delegator,
  ERC1363ReceiverBase,
  WeightedPoolStorage,
  VersionedInitializable
{
  address internal immutable _extension;
  address internal immutable _joinExtension;

  constructor(WeightedPoolExtension extension, JoinablePoolExtension joinExtension)
    WeightedPoolConfig(joinExtension.accessController(), extension.coverageUnitSize(), extension.collateral())
  {
    // TODO check for the same access controller
    // Value.require(extension.accessController() == joinExtension.accessController());
    Value.require(extension.collateral() == joinExtension.collateral());
    Value.require(extension.coverageUnitSize() == joinExtension.coverageUnitSize());
    _extension = address(extension);
    _joinExtension = address(joinExtension);
  }

  // solhint-disable-next-line payable-fallback
  fallback() external {
    // all IAddableCoverageDistributor etc functions should be delegated to the extension
    _delegate(_extension);
  }

  function charteredDemand() external pure override returns (bool) {
    return true;
  }

  function pushCoverageExcess() public virtual;

  function internalOnCoverageRecovered() internal virtual {
    pushCoverageExcess();
  }

  /// @dev initiates evaluation of the insured pool by this insurer. May involve governance activities etc.
  /// IInsuredPool.joinProcessed will be called after the decision is made.
  function requestJoin(address) external override {
    _delegate(_joinExtension);
  }

  function approveJoiner(address, bool) external {
    _delegate(_joinExtension);
  }

  function cancelJoin() external returns (MemberStatus) {
    _delegate(_joinExtension);
  }

  function cancelCoverageDemand(
    address,
    uint256,
    uint256
  ) external returns (uint256) {
    _delegate(_joinExtension);
  }

  function governor() public view returns (address) {
    return governorAccount();
  }

  function _onlyPremiumDistributor() private view {
    Access.require(msg.sender == premiumDistributor());
  }

  modifier onlyPremiumDistributor() virtual {
    _onlyPremiumDistributor();
    _;
  }

  function burnPremium(
    address account,
    uint256 value,
    address drawdownRecepient
  ) external override onlyPremiumDistributor {
    internalBurnPremium(account, value, drawdownRecepient);
  }

  function internalBurnPremium(
    address account,
    uint256 value,
    address drawdownRecepient
  ) internal virtual;

  function collectDrawdownPremium() external override onlyPremiumDistributor returns (uint256) {
    return internalCollectDrawdownPremium();
  }

  function internalCollectDrawdownPremium() internal virtual returns (uint256);

  event SubrogationAdded(uint256 value);

  function addSubrogation(address donor, uint256 value) external aclHas(AccessFlags.INSURER_OPS) {
    if (value > 0) {
      transferCollateralFrom(donor, address(this), value);
      internalSubrogated(value);
      internalOnCoverageRecovered();
      internalOnCoveredUpdated();
      emit SubrogationAdded(value);
    }
  }

  function internalSubrogated(uint256 value) internal virtual;

  function setGovernor(address addr) external aclHas(AccessFlags.INSURER_ADMIN) {
    internalSetGovernor(addr);
  }

  function setPremiumDistributor(address addr) external aclHas(AccessFlags.INSURER_ADMIN) {
    internalSetPremiumDistributor(addr);
  }

  function setPoolParams(WeightedPoolParams calldata params) external onlyGovernorOr(AccessFlags.INSURER_ADMIN) {
    internalSetPoolParams(params);
  }

  // TODO setLoopLimits
  // function setLoopLimits(uint16[] calldata limits) external onlyGovernorOr(AccessFlags.INSURER_OPS) {
  //   internalSetLoopLimits(limits);
  // }

  /// @return status The status of the account, NotApplicable if unknown about this address or account is an investor
  function statusOf(address account) external view returns (MemberStatus status) {
    return internalStatusOf(account);
  }

  function premiumDistributor() public view override returns (address) {
    return address(_premiumDistributor);
  }

  function internalReceiveTransfer(
    address operator,
    address account,
    uint256 amount,
    bytes calldata data
  ) internal override onlyCollateralCurrency onlyUnpaused {
    Access.require(operator != address(this) && account != address(this) && internalGetStatus(account) == MemberStatus.Unknown);
    Value.require(data.length == 0);

    internalMintForCoverage(account, amount);
    internalOnCoveredUpdated();
  }

  function internalMintForCoverage(address account, uint256 value) internal virtual;

  event Paused(bool);

  function setPaused(bool paused) external onlyEmergencyAdmin {
    _paused = paused;
    emit Paused(paused);
  }

  function isPaused() public view returns (bool) {
    return _paused;
  }

  function internalOnCoveredUpdated() internal {}

  function internalSyncStake() internal {
    ICollateralStakeManager m = ICollateralStakeManager(IManagedCollateralCurrency(collateral()).borrowManager());
    if (address(m) != address(0)) {
      m.syncByStakeAsset(totalSupply(), collateralSupply());
    }
  }

  function _coveredTotal() internal view returns (uint256) {
    (uint256 totalCovered, uint256 pendingCovered) = super.internalGetCoveredTotals();
    return totalCovered + pendingCovered;
  }

  function totalSupply() public view virtual override returns (uint256);

  function collateralSupply() public view override returns (uint256) {
    return _coveredTotal() + _excessCoverage;
  }

  function totalPremiumRate() external view returns (uint256) {
    return super.internalGetPremiumTotals().premiumRate;
  }

  function internalPullDemand(uint256 loopLimit) internal {
    uint256 insuredLimit = defaultLoopLimit(LoopLimitType.AddCoverageDemandByPull, 0);

    for (; loopLimit > 0; ) {
      address insured;
      (insured, loopLimit) = super.internalPullDemandCandidate(loopLimit, false);
      if (insured == address(0)) {
        break;
      }
      if (IInsuredPool(insured).pullCoverageDemand(internalOpenBatchRounds() * internalUnitSize(), insuredLimit)) {
        if (loopLimit <= insuredLimit) {
          break;
        }
        loopLimit -= insuredLimit;
      }
    }
  }

  function internalAutoPullDemand(
    AddCoverageParams memory params,
    uint256 loopLimit,
    bool hasExcess,
    uint256 value
  ) internal {
    if (loopLimit > 0 && (hasExcess || params.openBatchNo == 0)) {
      uint256 n = _params.unitsPerAutoPull;
      if (n == 0) {
        return;
      }

      if (value != 0) {
        n = value / (n * internalUnitSize());
        if (n < loopLimit) {
          loopLimit = n;
        }
      }

      if (!hasExcess) {
        super.internalPullDemandCandidate(loopLimit == 0 ? 1 : loopLimit, true);
      } else if (loopLimit > 0) {
        internalPullDemand(loopLimit);
      }
    }
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './ERC20DetailsBase.sol';
import './ERC20AllowanceBase.sol';
import './ERC20MintableBase.sol';
import './ERC20PermitBase.sol';

abstract contract ERC20BalancelessBase is ERC20DetailsBase, ERC20AllowanceBase, ERC20PermitBase, ERC20TransferBase {
  function _getPermitDomainName() internal view override returns (bytes memory) {
    return bytes(super.name());
  }

  function _approveByPermit(
    address owner,
    address spender,
    uint256 value
  ) internal override {
    _approve(owner, spender, value);
  }

  function _approveTransferFrom(address owner, uint256 amount) internal override(ERC20AllowanceBase, ERC20TransferBase) {
    ERC20AllowanceBase._approveTransferFrom(owner, amount);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/Address.sol';

library Errors {
  function illegalState(bool ok) internal pure {
    if (!ok) {
      revert IllegalState();
    }
  }

  function illegalValue(bool ok) internal pure {
    if (!ok) {
      revert IllegalValue();
    }
  }

  function accessDenied(bool ok) internal pure {
    if (!ok) {
      revert AccessDenied();
    }
  }

  function panic(uint256 code) internal pure {
    // solhint-disable no-inline-assembly
    assembly {
      mstore(0x00, 0x4e487b71)
      mstore(0x20, code)
      revert(0x1C, 0x24)
    }
  }

  function overflow() internal pure {
    // solhint-disable no-inline-assembly
    assembly {
      mstore(0x00, 0x4e487b71)
      mstore(0x20, 0x11)
      revert(0x1C, 0x24)
    }
  }

  function _mutable() private returns (bool) {}

  function notImplemented() internal {
    if (!_mutable()) {
      revert NotImplemented();
    }
  }

  error OperationPaused();
  error IllegalState();
  error Impossible();
  error IllegalValue();
  error NotSupported();
  error NotImplemented();
  error AccessDenied();

  error ExpiredPermit();
  error WrongPermitSignature();

  error ExcessiveVolatility();
  error ExcessiveVolatilityLock(uint256 mask);

  error CallerNotProxyOwner();
  error CallerNotEmergencyAdmin();
  error CallerNotSweepAdmin();
  error CallerNotOracleAdmin();

  error CollateralTransferFailed();

  error ContractRequired();
  error ImplementationRequired();

  error UnknownPriceAsset(address asset);
  error PriceExpired(address asset);
}

library Sanity {
  // slither-disable-next-line shadowing-builtin
  function require(bool ok) internal pure {
    // This code should be commented out on release
    if (!ok) {
      revert Errors.Impossible();
    }
  }
}

library State {
  // slither-disable-next-line shadowing-builtin
  function require(bool ok) internal pure {
    if (!ok) {
      revert Errors.IllegalState();
    }
  }
}

library Value {
  // slither-disable-next-line shadowing-builtin
  function require(bool ok) internal pure {
    if (!ok) {
      revert Errors.IllegalValue();
    }
  }

  function requireContract(address a) internal view {
    if (!Address.isContract(a)) {
      revert Errors.ContractRequired();
    }
  }
}

library Access {
  // slither-disable-next-line shadowing-builtin
  function require(bool ok) internal pure {
    if (!ok) {
      revert Errors.AccessDenied();
    }
  }
}

library Arithmetic {
  // slither-disable-next-line shadowing-builtin
  function require(bool ok) internal pure {
    if (!ok) {
      Errors.overflow();
    }
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../tools/Errors.sol';

library Balances {
  struct RateAcc {
    uint128 accum;
    uint96 rate;
    uint32 updatedAt;
  }

  function sync(RateAcc memory b, uint32 at) internal pure returns (RateAcc memory) {
    uint256 adjustment = at - b.updatedAt;
    if (adjustment > 0 && (adjustment = adjustment * b.rate) > 0) {
      adjustment += b.accum;
      Arithmetic.require(adjustment == (b.accum = uint128(adjustment)));
    }
    b.updatedAt = at;
    return b;
  }

  // function syncStorage(RateAcc storage b, uint32 at) internal {
  //   uint256 adjustment = at - b.updatedAt;
  //   if (adjustment > 0 && (adjustment = adjustment * b.rate) > 0) {
  //     adjustment += b.accum;
  //     Arithmetic.require(adjustment == (b.accum = uint128(adjustment)));
  //   }
  //   b.updatedAt = at;
  // }

  // function setRateStorage(
  //   RateAcc storage b,
  //   uint32 at,
  //   uint256 rate
  // ) internal {
  //   syncStorage(b, at);
  //   Arithmetic.require(rate == (b.rate = uint96(rate)));
  // }

  // function setRate(
  //   RateAcc memory b,
  //   uint32 at,
  //   uint256 rate
  // ) internal pure returns (RateAcc memory) {
  //   b = sync(b, at);
  //   Arithmetic.require(rate == (b.rate = uint96(rate)));
  //   return b;
  // }

  function setRateAfterSync(RateAcc memory b, uint256 rate) internal view returns (RateAcc memory) {
    Value.require(b.updatedAt == block.timestamp);
    Arithmetic.require(rate == (b.rate = uint96(rate)));
    return b;
  }

  // function incRate(
  //   RateAcc memory b,
  //   uint32 at,
  //   uint256 rateIncrement
  // ) internal pure returns (RateAcc memory) {
  //   return setRate(b, at, b.rate + rateIncrement);
  // }

  // function decRate(
  //   RateAcc memory b,
  //   uint32 at,
  //   uint256 rateDecrement
  // ) internal pure returns (RateAcc memory) {
  //   return setRate(b, at, b.rate - rateDecrement);
  // }

  // struct RateAccWithUint8 {
  //   uint120 accum;
  //   uint96 rate;
  //   uint32 updatedAt;
  //   uint8 extra;
  // }

  // function sync(RateAccWithUint8 memory b, uint32 at) internal pure returns (RateAccWithUint8 memory) {
  //   uint256 adjustment = at - b.updatedAt;
  //   if (adjustment > 0 && (adjustment = adjustment * b.rate) > 0) {
  //     adjustment += b.accum;
  //     Arithmetic.require(adjustment == (b.accum = uint120(adjustment)));
  //   }
  //   b.updatedAt = at;
  //   return b;
  // }

  // function syncStorage(RateAccWithUint8 storage b, uint32 at) internal {
  //   uint256 adjustment = at - b.updatedAt;
  //   if (adjustment > 0 && (adjustment = adjustment * b.rate) > 0) {
  //     adjustment += b.accum;
  //     Arithmetic.require(adjustment == (b.accum = uint120(adjustment)));
  //   }
  //   b.updatedAt = at;
  // }

  // function setRateStorage(
  //   RateAccWithUint8 storage b,
  //   uint32 at,
  //   uint256 rate
  // ) internal {
  //   syncStorage(b, at);
  //   Arithmetic.require(rate == (b.rate = uint96(rate)));
  // }

  // function setRate(
  //   RateAccWithUint8 memory b,
  //   uint32 at,
  //   uint256 rate
  // ) internal pure returns (RateAccWithUint8 memory) {
  //   b = sync(b, at);
  //   Arithmetic.require(rate == (b.rate = uint96(rate)));
  //   return b;
  // }

  // function incRate(
  //   RateAccWithUint8 memory b,
  //   uint32 at,
  //   uint256 rateIncrement
  // ) internal pure returns (RateAccWithUint8 memory) {
  //   return setRate(b, at, b.rate + rateIncrement);
  // }

  // function decRate(
  //   RateAccWithUint8 memory b,
  //   uint32 at,
  //   uint256 rateDecrement
  // ) internal pure returns (RateAccWithUint8 memory) {
  //   return setRate(b, at, b.rate - rateDecrement);
  // }

  struct RateAccWithUint16 {
    uint120 accum;
    uint88 rate;
    uint32 updatedAt;
    uint16 extra;
  }

  function sync(RateAccWithUint16 memory b, uint32 at) internal pure returns (RateAccWithUint16 memory) {
    uint256 adjustment = at - b.updatedAt;
    if (adjustment > 0 && (adjustment = adjustment * b.rate) > 0) {
      adjustment += b.accum;
      Arithmetic.require(adjustment == (b.accum = uint120(adjustment)));
    }
    b.updatedAt = at;
    return b;
  }

  // function syncStorage(RateAccWithUint16 storage b, uint32 at) internal {
  //   uint256 adjustment = at - b.updatedAt;
  //   if (adjustment > 0 && (adjustment = adjustment * b.rate) > 0) {
  //     adjustment += b.accum;
  //     Arithmetic.require(adjustment == (b.accum = uint120(adjustment)));
  //   }
  //   b.updatedAt = at;
  // }

  // function setRateStorage(
  //   RateAccWithUint16 storage b,
  //   uint32 at,
  //   uint256 rate
  // ) internal {
  //   syncStorage(b, at);
  //   Arithmetic.require(rate == (b.rate = uint88(rate)));
  // }

  // function setRate(
  //   RateAccWithUint16 memory b,
  //   uint32 at,
  //   uint256 rate
  // ) internal pure returns (RateAccWithUint16 memory) {
  //   b = sync(b, at);
  //   Arithmetic.require(rate == (b.rate = uint88(rate)));
  //   return b;
  // }

  // function incRate(
  //   RateAccWithUint16 memory b,
  //   uint32 at,
  //   uint256 rateIncrement
  // ) internal pure returns (RateAccWithUint16 memory) {
  //   return setRate(b, at, b.rate + rateIncrement);
  // }

  // function decRate(
  //   RateAccWithUint16 memory b,
  //   uint32 at,
  //   uint256 rateDecrement
  // ) internal pure returns (RateAccWithUint16 memory) {
  //   return setRate(b, at, b.rate - rateDecrement);
  // }

  // struct RateAccWithUint32 {
  //   uint112 accum;
  //   uint80 rate;
  //   uint32 updatedAt;
  //   uint32 extra;
  // }

  // function sync(RateAccWithUint32 memory b, uint32 at) internal pure returns (RateAccWithUint32 memory) {
  //   uint256 adjustment = at - b.updatedAt;
  //   if (adjustment > 0 && (adjustment = adjustment * b.rate) > 0) {
  //     adjustment += b.accum;
  //     Arithmetic.require(adjustment == (b.accum = uint112(adjustment)));
  //   }
  //   b.updatedAt = at;
  //   return b;
  // }

  // function syncStorage(RateAccWithUint32 storage b, uint32 at) internal {
  //   uint256 adjustment = at - b.updatedAt;
  //   if (adjustment > 0 && (adjustment = adjustment * b.rate) > 0) {
  //     adjustment += b.accum;
  //    Arithmetic.require(adjustment == (b.accum = uint112(adjustment)));
  //   }
  //   b.updatedAt = at;
  // }

  // function setRateStorage(
  //   RateAccWithUint32 storage b,
  //   uint32 at,
  //   uint256 rate
  // ) internal {
  //   syncStorage(b, at);
  //   Arithmetic.require(rate == (b.rate = uint80(rate)));
  // }

  // function setRate(
  //   RateAccWithUint32 memory b,
  //   uint32 at,
  //   uint256 rate
  // ) internal pure returns (RateAccWithUint32 memory) {
  //   b = sync(b, at);
  //   Arithmetic.require(rate == (b.rate = uint80(rate)));
  //   return b;
  // }

  // function incRate(
  //   RateAccWithUint32 memory b,
  //   uint32 at,
  //   uint256 rateIncrement
  // ) internal pure returns (RateAccWithUint32 memory) {
  //   return setRate(b, at, b.rate + rateIncrement);
  // }

  // function decRate(
  //   RateAccWithUint32 memory b,
  //   uint32 at,
  //   uint256 rateDecrement
  // ) internal pure returns (RateAccWithUint32 memory) {
  //   return setRate(b, at, b.rate - rateDecrement);
  // }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './IERC20Details.sol';

abstract contract ERC20DetailsBase is IERC20Details {
  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor(
    string memory name_,
    string memory symbol_,
    uint8 decimals_
  ) {
    _name = name_;
    _symbol = symbol_;
    _decimals = decimals_;
  }

  function _initializeERC20(
    string memory name_,
    string memory symbol_,
    uint8 decimals_
  ) internal {
    _name = name_;
    _symbol = symbol_;
    _decimals = decimals_;
  }

  function name() public view override returns (string memory) {
    return _name;
  }

  function symbol() public view override returns (string memory) {
    return _symbol;
  }

  function decimals() public view override returns (uint8) {
    return _decimals;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../../tools/tokens/IERC20.sol';

abstract contract ERC20AllowanceBase is IERC20 {
  mapping(address => mapping(address => uint256)) private _allowances;

  function allowance(address owner, address spender) public view virtual override returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) public virtual override returns (bool) {
    _approve(msg.sender, spender, amount);
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
    _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
    _decAllowance(msg.sender, spender, subtractedValue, false);
    return true;
  }

  function useAllowance(address owner, uint256 subtractedValue) public virtual returns (bool) {
    _decAllowance(owner, msg.sender, subtractedValue, false);
    return true;
  }

  function _decAllowance(
    address owner,
    address spender,
    uint256 subtractedValue,
    bool transfer_
  ) private {
    uint256 limit = _allowances[owner][spender];
    if (limit == 0 && subtractedValue > 0 && transfer_ && delegatedAllownance(owner, spender, subtractedValue)) {
      return;
    }

    require(limit >= subtractedValue, 'ERC20: decreased allowance below zero');
    unchecked {
      _approve(owner, spender, limit - subtractedValue);
    }
  }

  function delegatedAllownance(
    address owner,
    address spender,
    uint256 subtractedValue
  ) internal virtual returns (bool) {}

  /**
   * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
   *
   * This is internal function is equivalent to `approve`, and can be used to
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
  ) internal {
    require(owner != address(0), 'ERC20: approve from the zero address');
    require(spender != address(0), 'ERC20: approve to the zero address');

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  event Approval(address indexed owner, address indexed spender, uint256 value);

  function _approveTransferFrom(address owner, uint256 amount) internal virtual {
    _decAllowance(owner, msg.sender, amount, true);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './ERC20TransferBase.sol';

abstract contract ERC20MintableBase is ERC20TransferBase {
  uint256 private _totalSupply;

  function totalSupply() public view override returns (uint256) {
    return _totalSupply;
  }

  /** @dev Creates `amount` tokens and assigns them to `account`, increasing
   * the total supply.
   *
   * Emits a {Transfer} event with `from` set to the zero address.
   *
   * Requirements
   *
   * - `to` cannot be the zero address.
   */
  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0), 'ERC20: mint to the zero address');

    _beforeTokenTransfer(address(0), account, amount);

    _totalSupply = _totalSupply + amount;
    incrementBalance(account, amount);

    emit Transfer(address(0), account, amount);
  }

  function _mintAndTransfer(
    address account,
    address recipient,
    uint256 amount
  ) internal virtual {
    require(account != address(0), 'ERC20: mint to the zero address');
    require(recipient != address(0), 'ERC20: transfer to the zero address');

    _beforeTokenTransfer(address(0), account, amount);
    _beforeTokenTransfer(account, recipient, amount);

    _totalSupply = _totalSupply + amount;
    incrementBalance(recipient, amount);

    emit Transfer(address(0), account, amount);
    emit Transfer(account, recipient, amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`, reducing the
   * total supply.
   *
   * Emits a {Transfer} event with `to` set to the zero address.
   *
   * Requirements
   *
   * - `account` cannot be the zero address.
   * - `account` must have at least `amount` tokens.
   */
  function _burn(address account, uint256 amount) internal virtual {
    require(account != address(0), 'ERC20: burn from the zero address');

    _beforeTokenTransfer(account, address(0), amount);

    _totalSupply = _totalSupply - amount;
    decrementBalance(account, amount);

    emit Transfer(account, address(0), amount);
  }

  function transferBalance(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual override {
    decrementBalance(sender, amount);
    incrementBalance(recipient, amount);
  }

  function incrementBalance(address account, uint256 amount) internal virtual;

  function decrementBalance(address account, uint256 amount) internal virtual;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './IERC20WithPermit.sol';
import './EIP712Base.sol';

abstract contract ERC20PermitBase is IERC20WithPermit, EIP712Base {
  bytes32 public constant PERMIT_TYPEHASH = keccak256('Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)');

  constructor() {
    _initializeDomainSeparator();
  }

  function _initializeDomainSeparator() internal {
    super._initializeDomainSeparator(_getPermitDomainName());
  }

  /**
   * @dev implements the permit function as for https://github.com/ethereum/EIPs/blob/8a34d644aacf0f9f8f00815307fd7dd5da07655f/EIPS/eip-2612.md
   * @param owner the owner of the funds
   * @param spender the spender
   * @param value the amount
   * @param deadline the deadline timestamp, type(uint256).max for no deadline
   * @param v signature param
   * @param s signature param
   * @param r signature param
   */

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external override {
    Value.require(owner != address(0));
    internalPermit(owner, spender, value, deadline, v, r, s, PERMIT_TYPEHASH);
    _approveByPermit(owner, spender, value);
  }

  function _approveByPermit(
    address owner,
    address spender,
    uint256 value
  ) internal virtual;

  function _getPermitDomainName() internal view virtual returns (bytes memory);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IERC20Details {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP excluding events to avoid linearization issues.
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
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

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
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../../tools/tokens/IERC20.sol';

abstract contract ERC20TransferBase is IERC20 {
  event Transfer(address indexed from, address indexed to, uint256 value);

  function transfer(address recipient, uint256 amount) public override returns (bool) {
    _transfer(msg.sender, recipient, amount);
    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public override returns (bool) {
    _transfer(sender, recipient, amount);
    _approveTransferFrom(sender, amount);
    return true;
  }

  function _approveTransferFrom(address owner, uint256 amount) internal virtual;

  /**
   * @dev Moves tokens `amount` from `sender` to `recipient`.
   *
   * This is internal function is equivalent to {transfer}, and can be used to
   * e.g. implement automatic token fees, slashing mechanisms, etc.
   *
   * Emits a {Transfer} event.
   *
   * Requirements:
   *
   * - `sender` cannot be the zero address.
   * - `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   */
  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual {
    _ensure(sender, recipient);

    _beforeTokenTransfer(sender, recipient, amount);
    _transferAndEmit(sender, recipient, amount, sender);
  }

  function _transferOnBehalf(
    address sender,
    address recipient,
    uint256 amount,
    address onBehalf
  ) internal virtual {
    _ensure(sender, recipient);
    require(onBehalf != address(0), 'ERC20: transfer on behalf of the zero address');

    _beforeTokenTransfer(sender, recipient, amount);
    _transferAndEmit(sender, recipient, amount, onBehalf);
  }

  function _ensure(address sender, address recipient) private pure {
    require(sender != address(0), 'ERC20: transfer from the zero address');
    require(recipient != address(0), 'ERC20: transfer to the zero address');
  }

  function _transferAndEmit(
    address sender,
    address recipient,
    uint256 amount,
    address onBehalf
  ) internal virtual {
    if (sender != recipient) {
      transferBalance(sender, recipient, amount);
    }
    if (onBehalf != sender) {
      emit Transfer(sender, onBehalf, amount);
    }
    emit Transfer(onBehalf, recipient, amount);
  }

  function transferBalance(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual;

  /**
   * @dev Hook that is called before any transfer of tokens. This includes
   * minting and burning.
   *
   * Calling conditions:
   *
   * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
   * will be to transferred to `to`.
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
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../../tools/tokens/IERC20.sol';

interface IERC20WithPermit is IERC20 {
  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../EIP712Lib.sol';

abstract contract EIP712Base {
  // solhint-disable-next-line var-name-mixedcase
  bytes32 public DOMAIN_SEPARATOR;

  mapping(address => uint256) private _nonces;

  /// @dev returns nonce, to comply with eip-2612
  function nonces(address addr) external view returns (uint256) {
    return _nonces[addr];
  }

  // solhint-disable-next-line func-name-mixedcase
  function EIP712_REVISION() external pure returns (bytes memory) {
    return EIP712Lib.EIP712_REVISION;
  }

  function _initializeDomainSeparator(bytes memory permitDomainName) internal {
    DOMAIN_SEPARATOR = EIP712Lib.domainSeparator(permitDomainName);
  }

  /**
   * @param owner the owner of the funds
   * @param spender the spender
   * @param value the amount
   * @param deadline the deadline timestamp, type(uint256).max for no deadline
   * @param v signature param
   * @param s signature param
   * @param r signature param
   */

  function internalPermit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s,
    bytes32 typeHash
  ) internal {
    uint256 currentValidNonce = _nonces[owner]++;
    EIP712Lib.verifyPermit(owner, spender, bytes32(value), deadline, v, r, s, typeHash, DOMAIN_SEPARATOR, currentValidNonce);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './Errors.sol';

library EIP712Lib {
  bytes internal constant EIP712_REVISION = '1';
  bytes32 internal constant EIP712_DOMAIN = keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)');

  function chainId() internal view returns (uint256 id) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      id := chainid()
    }
  }

  function domainSeparator(bytes memory permitDomainName) internal view returns (bytes32) {
    return keccak256(abi.encode(EIP712_DOMAIN, keccak256(permitDomainName), keccak256(EIP712_REVISION), chainId(), address(this)));
  }

  /**
   * @param owner the owner of the funds
   * @param spender the spender
   * @param value the amount
   * @param deadline the deadline timestamp, type(uint256).max for no deadline
   * @param v signature param
   * @param s signature param
   * @param r signature param
   */
  function verifyPermit(
    address owner,
    address spender,
    bytes32 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s,
    bytes32 typeHash,
    bytes32 domainSep,
    uint256 nonce
  ) internal view {
    verifyCustomPermit(owner, abi.encode(typeHash, owner, spender, value, nonce, deadline), deadline, v, r, s, domainSep);
  }

  function verifyCustomPermit(
    address owner,
    bytes memory params,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s,
    bytes32 domainSep
  ) internal view {
    Value.require(owner != address(0));
    if (block.timestamp > deadline) {
      revert Errors.ExpiredPermit();
    }

    bytes32 digest = keccak256(abi.encodePacked('\x19\x01', domainSep, keccak256(params)));

    if (owner != ecrecover(digest, v, r, s)) {
      revert Errors.WrongPermitSignature();
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './IVersioned.sol';

/**
 * @title VersionedInitializable
 *
 * @dev Helper contract to implement versioned initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` or `initializerRunAlways` modifier.
 * The revision number should be defined as a private constant, returned by getRevision() and used by initializer() modifier.
 *
 * ATTN: There is a built-in protection from implementation self-destruct exploits. This protection
 * prevents initializers from being called on an implementation inself, but only on proxied contracts.
 * To override this protection, call _unsafeResetVersionedInitializers() from a constructor.
 *
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an initializable contract, as well
 * as extending an initializable contract via inheritance.
 *
 * ATTN: When used with inheritance, parent initializers with `initializer` modifier are prevented by calling twice,
 * but can only be called in child-to-parent sequence.
 *
 * WARNING: When used with inheritance, parent initializers with `initializerRunAlways` modifier
 * are NOT protected from multiple calls by another initializer.
 */
abstract contract VersionedInitializable is IVersioned {
  uint256 private constant BLOCK_REVISION = type(uint256).max;
  // This revision number is applied to implementations
  uint256 private constant IMPL_REVISION = BLOCK_REVISION - 1;

  /// @dev Indicates that the contract has been initialized. The default value blocks initializers from being called on an implementation.
  uint256 private lastInitializedRevision = IMPL_REVISION;

  /// @dev Indicates that the contract is in the process of being initialized.
  uint256 private lastInitializingRevision = 0;

  error OnlyInsideConstructor();
  error OnlyBeforeInitializer();

  /**
   * @dev There is a built-in protection from self-destruct of implementation exploits. This protection
   * prevents initializers from being called on an implementation inself, but only on proxied contracts.
   * Function _unsafeResetVersionedInitializers() can be called from a constructor to disable this protection.
   * It must be called before any initializers, otherwise it will fail.
   */
  function _unsafeResetVersionedInitializers() internal {
    if (!isConstructor()) {
      revert OnlyInsideConstructor();
    }

    if (lastInitializedRevision == IMPL_REVISION) {
      lastInitializedRevision = 0;
    } else if (lastInitializedRevision != 0) {
      revert OnlyBeforeInitializer();
    }
  }

  /// @dev Modifier to use in the initializer function of a contract.
  // slither-disable-next-line incorrect-modifier
  modifier initializer(uint256 localRevision) {
    (uint256 topRevision, bool initializing, bool skip) = _preInitializer(localRevision);

    if (!skip) {
      lastInitializingRevision = localRevision;
      _;
      lastInitializedRevision = localRevision;
    }

    if (!initializing) {
      lastInitializedRevision = topRevision;
      lastInitializingRevision = 0;
    }
  }

  modifier initializerRunAlways(uint256 localRevision) {
    (uint256 topRevision, bool initializing, bool skip) = _preInitializer(localRevision);

    if (!skip) {
      lastInitializingRevision = localRevision;
    }
    _;
    if (!skip) {
      lastInitializedRevision = localRevision;
    }

    if (!initializing) {
      lastInitializedRevision = topRevision;
      lastInitializingRevision = 0;
    }
  }

  error WrongContractRevision();
  error WrongInitializerRevision();
  error InconsistentContractRevision();
  error AlreadyInitialized();
  error InitializerBlockedOff();
  error WrongOrderOfInitializers();

  function _preInitializer(uint256 localRevision)
    private
    returns (
      uint256 topRevision,
      bool initializing,
      bool skip
    )
  {
    topRevision = getRevision();
    if (topRevision >= IMPL_REVISION) {
      revert WrongContractRevision();
    }

    if (localRevision > topRevision) {
      revert InconsistentContractRevision();
    } else if (localRevision == 0) {
      revert WrongInitializerRevision();
    }

    if (lastInitializedRevision < IMPL_REVISION) {
      // normal initialization
      initializing = lastInitializingRevision > 0 && lastInitializedRevision < topRevision;
      if (!(initializing || isConstructor() || topRevision > lastInitializedRevision)) {
        revert AlreadyInitialized();
      }
    } else {
      // by default, initialization of implementation is only allowed inside a constructor
      if (!(lastInitializedRevision == IMPL_REVISION && isConstructor())) {
        revert InitializerBlockedOff();
      }

      // enable normal use of initializers inside a constructor
      lastInitializedRevision = 0;
      // but make sure to block initializers afterwards
      topRevision = BLOCK_REVISION;

      initializing = lastInitializingRevision > 0;
    }

    if (initializing && lastInitializingRevision <= localRevision) {
      revert WrongOrderOfInitializers();
    }

    if (localRevision <= lastInitializedRevision) {
      // prevent calling of parent's initializer when it was called before
      if (initializing) {
        // Can't set zero yet, as it is not a top-level call, otherwise `initializing` will become false.
        // Further calls will fail with the `incorrect order` assertion above.
        lastInitializingRevision = 1;
      }
      skip = true;
    }
  }

  function isRevisionInitialized(uint256 localRevision) internal view returns (bool) {
    return lastInitializedRevision >= localRevision;
  }

  // solhint-disable-next-line func-name-mixedcase
  function REVISION() public pure override returns (uint256) {
    return getRevision();
  }

  /**
   * @dev returns the revision number (< type(uint256).max - 1) of the contract.
   * The number should be defined as a private constant.
   **/
  function getRevision() internal pure virtual returns (uint256);

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    uint256 cs;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      cs := extcodesize(address())
    }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  // slither-disable-next-line unused-state
  uint256[16] private ______gap;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

/// @dev Provides delegation of calls with proper forwarding of return values and bubbling of failures. Based on OpenZeppelin Proxy.
abstract contract Delegator {
  /**
   * @dev Delegates execution to an implementation contract.
   * This is a low level function that doesn't return to its internal call site.
   * It will return to the external caller whatever the implementation returns.
   * @param implementation Address to delegate.
   */
  function _delegate(address implementation) internal {
    require(implementation != address(0));
    // solhint-disable-next-line no-inline-assembly
    assembly {
      // Copy msg.data. We take full control of memory in this inline assembly
      // block because it will not return to Solidity code. We overwrite the
      // Solidity scratch pad at memory position 0.
      calldatacopy(0, 0, calldatasize())

      // Call the implementation.
      // out and outsize are 0 because we don't know the size yet.
      let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

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

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './IERC1363.sol';

abstract contract ERC1363ReceiverBase is IERC1363Receiver {
  function onTransferReceived(
    address operator,
    address from,
    uint256 value,
    bytes calldata data
  ) external override returns (bytes4) {
    internalReceiveTransfer(operator, from, value, data);
    return this.onTransferReceived.selector;
  }

  function internalReceiveTransfer(
    address operator,
    address from,
    uint256 value,
    bytes calldata data
  ) internal virtual;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface ICollateralStakeManager {
  function verifyBorrowUnderlying(address account, uint256 value) external returns (bool);

  function verifyRepayUnderlying(address account, uint256 value) external returns (bool);

  function syncStakeAsset(address asset) external;

  function syncByStakeAsset(uint256 assetSupply, uint256 collateralSupply) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './ICollateralized.sol';
import '../tools/tokens/IERC20.sol';

interface IYieldStakeAsset is ICollateralized {
  function collateralSupply() external view returns (uint256);

  function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './ICollateralized.sol';

interface IPremiumActuary is ICollateralized {
  function premiumDistributor() external view returns (address);

  function collectDrawdownPremium() external returns (uint256 availablePremiumValue);

  function burnPremium(
    address account,
    uint256 value,
    address drawdownRecepient
  ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../tools/tokens/IERC20.sol';
import './ICoverageDistributor.sol';
import '../insurer/Rounds.sol';

interface IInsurerPoolBase is ICollateralized, ICharterable {
  /// @dev returns ratio of $IC to $CC, this starts as 1 (RAY)
  function exchangeRate() external view returns (uint256);
}

interface IPerpetualInsurerPool is IInsurerPoolBase {
  /// @notice The interest of the account is their earned premium amount
  /// @param account The account to query
  /// @return rate The current interest rate of the account
  /// @return accumulated The current earned premium of the account
  function interestOf(address account) external view returns (uint256 rate, uint256 accumulated);

  /// @notice Withdrawable amount of this account
  /// @param account The account to query
  /// @return amount The amount withdrawable
  function withdrawable(address account) external view returns (uint256 amount);

  /// @notice Attempt to withdraw all of a user's coverage
  /// @return The amount withdrawn
  function withdrawAll() external returns (uint256);
}

interface IInsurerPool is IERC20, IInsurerPoolBase, ICoverageDistributor {
  function statusOf(address) external view returns (MemberStatus);

  /// @dev returns balances of a user
  /// @return value The value of the pool share tokens (and provided coverage)
  /// @return balance The number of the pool share tokens
  /// @return swappable The amount of user's value which can be swapped to tokens (e.g. premium earned)
  function balancesOf(address account)
    external
    view
    returns (
      uint256 value,
      uint256 balance,
      uint256 swappable
    );
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './ICharterable.sol';

interface IJoinableBase {
  /// @dev initiates evaluation of the insured pool by this insurer. May involve governance activities etc.
  /// IInsuredPool.joinProcessed will be called after the decision is made.
  function requestJoin(address insured) external;

  // function statusOf(address insured)
}

interface IJoinable is ICharterable, IJoinableBase {}

interface IJoinEvents {
  event JoinRequested(address indexed insured);
  event JoinCancelled(address indexed insured);
  event JoinProcessed(address indexed insured, bool accepted);
  event JoinFailed(address indexed insured, bool isPanic, bytes reason);
  event MemberLeft(address indexed insured);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../libraries/Balances.sol';
import './WeightedPoolStorage.sol';
import './WeightedPoolBase.sol';
import './InsurerJoinBase.sol';

// Handles Insured pool functions, adding/cancelling demand
abstract contract WeightedPoolExtension is IAddableCoverageDistributor, WeightedPoolStorage {
  using WadRayMath for uint256;
  using PercentageMath for uint256;
  using Balances for Balances.RateAcc;

  /// @notice Coverage Unit Size is the minimum amount of coverage that can be demanded/provided
  /// @return The coverage unit size
  function coverageUnitSize() external view override returns (uint256) {
    return internalUnitSize();
  }

  /// @inheritdoc IAddableCoverageDistributor
  function addCoverageDemand(
    uint256 unitCount,
    uint256 premiumRate,
    bool hasMore,
    uint256 loopLimit
  ) external override onlyActiveInsured returns (uint256 addedCount) {
    AddCoverageDemandParams memory params;
    params.insured = msg.sender;
    Arithmetic.require(premiumRate == (params.premiumRate = uint40(premiumRate)));
    params.loopLimit = defaultLoopLimit(LoopLimitType.AddCoverageDemand, loopLimit);
    params.hasMore = hasMore;
    Arithmetic.require(unitCount <= type(uint64).max);

    addedCount = unitCount - super.internalAddCoverageDemand(uint64(unitCount), params);
    //If there was excess coverage before adding this demand, immediately assign it
    if (_excessCoverage > 0 && internalCanAddCoverage()) {
      // avoid addCoverage code to be duplicated within WeightedPoolExtension to reduce contract size
      WeightedPoolBase(address(this)).pushCoverageExcess();
    }
    return addedCount;
  }

  function cancelCoverage(address insured, uint256 payoutRatio)
    external
    override
    onlyActiveInsuredOrOps(insured)
    onlyUnpaused
    returns (uint256 payoutValue)
  {
    bool enforcedCancel = msg.sender != insured;
    if (payoutRatio > 0) {
      payoutRatio = internalVerifyPayoutRatio(insured, payoutRatio, enforcedCancel);
    }
    (payoutValue, ) = internalCancelCoverage(insured, payoutRatio, enforcedCancel);
  }

  /// @dev Cancel all coverage for the insured and payout
  /// @param insured The address of the insured to cancel
  /// @param payoutRatio The RAY ratio of how much of provided coverage should be paid out
  /// @return payoutValue The effective amount of coverage paid out to the insured (includes all )
  function internalCancelCoverage(
    address insured,
    uint256 payoutRatio,
    bool enforcedCancel
  ) private returns (uint256 payoutValue, uint256 deductedValue) {
    (DemandedCoverage memory coverage, uint256 excessCoverage, uint256 providedCoverage, uint256 receivableCoverage, uint256 receivedPremium) = super
      .internalCancelCoverage(insured);
    // NB! receivableCoverage was not yet received by the insured, it was found during the cancallation
    // and caller relies on a coverage provided earlier

    // NB! when protocol is not fully covered, then there will be a discrepancy between the coverage provided ad-hoc
    // and the actual amount of protocol tokens made available during last sync
    // so this is a sanity check - insurance must be sync'ed before cancellation
    // otherwise there will be premium without actual supply of protocol tokens

    payoutValue = providedCoverage.rayMul(payoutRatio);

    require(
      enforcedCancel || ((receivableCoverage <= providedCoverage >> 16) && (receivableCoverage + payoutValue <= providedCoverage)),
      'must be reconciled'
    );

    uint256 premiumDebt = address(_premiumDistributor) == address(0)
      ? 0
      : _premiumDistributor.premiumAllocationFinished(insured, coverage.totalPremium, receivedPremium);

    internalSetStatus(insured, MemberStatus.Declined);

    if (premiumDebt > 0) {
      unchecked {
        if (premiumDebt >= payoutValue) {
          deductedValue = payoutValue;
          premiumDebt -= payoutValue;
          payoutValue = 0;
        } else {
          deductedValue = premiumDebt;
          payoutValue -= premiumDebt;
          premiumDebt = 0;
        }
      }
    }

    payoutValue = internalTransferCancelledCoverage(
      insured,
      payoutValue,
      providedCoverage - receivableCoverage,
      excessCoverage + receivableCoverage,
      premiumDebt
    );
  }

  function internalTransferCancelledCoverage(
    address insured,
    uint256 payoutValue,
    uint256 advanceValue,
    uint256 recoveredValue,
    uint256 premiumDebt
  ) internal virtual returns (uint256);

  /// @inheritdoc IAddableCoverageDistributor
  function receivableDemandedCoverage(address insured, uint256 loopLimit)
    external
    view
    override
    returns (uint256 receivableCoverage, DemandedCoverage memory coverage)
  {
    GetCoveredDemandParams memory params;
    params.insured = insured;
    params.loopLimit = defaultLoopLimit(LoopLimitType.ReceivableDemandedCoverage, loopLimit);

    (coverage, , ) = internalGetCoveredDemand(params);
    return (params.receivedCoverage, coverage);
  }

  /// @inheritdoc IAddableCoverageDistributor
  function receiveDemandedCoverage(address insured, uint256 loopLimit)
    external
    override
    onlyActiveInsured
    onlyUnpaused
    returns (
      uint256 receivedCoverage,
      uint256 receivedCollateral,
      DemandedCoverage memory coverage
    )
  {
    GetCoveredDemandParams memory params;
    params.insured = insured;
    params.loopLimit = defaultLoopLimit(LoopLimitType.ReceiveDemandedCoverage, loopLimit);

    coverage = internalUpdateCoveredDemand(params);
    receivedCollateral = internalTransferDemandedCoverage(insured, params.receivedCoverage, coverage);

    if (address(_premiumDistributor) != address(0)) {
      _premiumDistributor.premiumAllocationUpdated(insured, coverage.totalPremium, params.receivedPremium, coverage.premiumRate);
    }

    return (params.receivedCoverage, receivedCollateral, coverage);
  }

  function internalTransferDemandedCoverage(
    address insured,
    uint256 receivedCoverage,
    DemandedCoverage memory coverage
  ) internal virtual returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../tools/upgradeability/Delegator.sol';
import '../tools/tokens/ERC1363ReceiverBase.sol';
import '../interfaces/IPremiumActuary.sol';
import '../interfaces/IInsurerPool.sol';
import '../interfaces/IJoinable.sol';
import './WeightedPoolExtension.sol';
import './WeightedPoolStorage.sol';

contract JoinablePoolExtension is IJoinableBase, ICancellableCoverageDemand, WeightedPoolStorage {
  constructor(
    IAccessController acl,
    uint256 unitSize,
    address collateral_
  ) WeightedPoolConfig(acl, unitSize, collateral_) {}

  function accessController() external view returns (IAccessController) {
    return remoteAcl();
  }

  function requestJoin(address insured) external override {
    Access.require(msg.sender == insured);
    internalRequestJoin(insured);
  }

  function approveJoiner(address insured, bool accepted) external onlyGovernorOr(AccessFlags.INSURER_OPS) {
    internalProcessJoin(insured, accepted);
  }

  function cancelJoin() external returns (MemberStatus) {
    return internalCancelJoin(msg.sender);
  }

  function coverageUnitSize() external view override returns (uint256) {
    return internalUnitSize();
  }

  function cancelCoverageDemand(
    address insured,
    uint256 unitCount,
    uint256 loopLimit
  ) external override onlyActiveInsuredOrOps(insured) returns (uint256 cancelledUnits, uint256[] memory) {
    CancelCoverageDemandParams memory params;
    params.insured = insured;
    params.loopLimit = defaultLoopLimit(LoopLimitType.CancelCoverageDemand, loopLimit);

    if (unitCount > type(uint64).max) {
      unitCount = type(uint64).max;
    }
    cancelledUnits = internalCancelCoverageDemand(uint64(unitCount), params);
    return (cancelledUnits, params.rateBands);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../tools/math/PercentageMath.sol';
import '../interfaces/IPremiumDistributor.sol';
import './WeightedPoolConfig.sol';

// Contains all variables for both base and extension contract. Allows for upgrades without corruption

/// @dev
/// @dev WARNING! This contract MUST NOT be extended with new fields after deployment
/// @dev
abstract contract WeightedPoolStorage is WeightedPoolConfig {
  using PercentageMath for uint256;
  using WadRayMath for uint256;

  struct UserBalance {
    uint128 balance; // scaled
    uint128 extra; // NB! this field is used differenly for perpetual and imperpetual pools
  }
  mapping(address => UserBalance) internal _balances; // [investor]

  IPremiumDistributor internal _premiumDistributor;

  /// @dev Amount of coverage provided to the pool that is not satisfying demand
  uint192 internal _excessCoverage;
  bool internal _paused;

  event ExcessCoverageUpdated(uint256 coverageExcess);

  function internalSetExcess(uint256 excess) internal {
    Arithmetic.require((_excessCoverage = uint192(excess)) == excess);
    emit ExcessCoverageUpdated(excess);
  }

  modifier onlyUnpaused() {
    Access.require(!_paused);
    _;
  }

  ///@dev Return if an account has a balance or premium earned
  function internalIsInvestor(address account) internal view override returns (bool) {
    UserBalance memory b = _balances[account];
    return b.extra != 0 || b.balance != 0;
  }

  event PremiumDistributorUpdated(address);

  function internalSetPremiumDistributor(address premiumDistributor_) internal virtual {
    _premiumDistributor = IPremiumDistributor(premiumDistributor_);
    emit PremiumDistributorUpdated(premiumDistributor_);
  }

  function internalAfterJoinOrLeave(address insured, MemberStatus status) internal override {
    if (address(_premiumDistributor) != address(0)) {
      _premiumDistributor.registerPremiumSource(insured, status == MemberStatus.Accepted);
    }
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IVersioned {
  // solhint-disable-next-line func-name-mixedcase
  function REVISION() external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './IERC20Details.sol';

library ERC1363 {
  // 0x88a7ca5c === bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"))
  bytes4 internal constant RECEIVER = type(IERC1363Receiver).interfaceId;

  /* 0xb0202a11 ===
   *   bytes4(keccak256('transferAndCall(address,uint256)')) ^
   *   bytes4(keccak256('transferAndCall(address,uint256,bytes)')) ^
   *   bytes4(keccak256('transferFromAndCall(address,address,uint256)')) ^
   *   bytes4(keccak256('transferFromAndCall(address,address,uint256,bytes)')) ^
   *   bytes4(keccak256('approveAndCall(address,uint256)')) ^
   *   bytes4(keccak256('approveAndCall(address,uint256,bytes)'))
   */
  bytes4 internal constant TOKEN = type(IERC1363).interfaceId;

  function callReceiver(
    address receiver,
    address operator,
    address from,
    uint256 value,
    bytes memory data
  ) internal {
    require(IERC1363Receiver(receiver).onTransferReceived(operator, from, value, data) == IERC1363Receiver.onTransferReceived.selector);
  }
}

interface IERC1363 {
  /**
   * @notice Transfer tokens from `msg.sender` to another address and then call `onTransferReceived` on receiver
   * @param recipient address The address which you want to transfer to
   * @param amount uint256 The amount of tokens to be transferred
   * @return true unless throwing
   */
  function transferAndCall(address recipient, uint256 amount) external returns (bool);

  /**
   * @notice Transfer tokens from `msg.sender` to another address and then call `onTransferReceived` on receiver
   * @param recipient address The address which you want to transfer to
   * @param amount uint256 The amount of tokens to be transferred
   * @param data bytes Additional data with no specified format, sent in call to `recipient`
   * @return true unless throwing
   */
  function transferAndCall(
    address recipient,
    uint256 amount,
    bytes calldata data
  ) external returns (bool);

  /**
   * @notice Transfer tokens from one address to another and then call `onTransferReceived` on receiver
   * @param sender address The address which you want to send tokens from
   * @param recipient address The address which you want to transfer to
   * @param amount uint256 The amount of tokens to be transferred
   * @return true unless throwing
   */
  function transferFromAndCall(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  /**
   * @notice Transfer tokens from one address to another and then call `onTransferReceived` on receiver
   * @param sender address The address which you want to send tokens from
   * @param recipient address The address which you want to transfer to
   * @param amount uint256 The amount of tokens to be transferred
   * @param data bytes Additional data with no specified format, sent in call to `recipient`
   * @return true unless throwing
   */
  function transferFromAndCall(
    address sender,
    address recipient,
    uint256 amount,
    bytes calldata data
  ) external returns (bool);

  /**
   * @notice Approve the passed address to spend the specified amount of tokens on behalf of msg.sender
   * and then call `onApprovalReceived` on spender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param spender address The address which will spend the funds
   * @param amount uint256 The amount of tokens to be spent
   */
  function approveAndCall(address spender, uint256 amount) external returns (bool);

  /**
   * @notice Approve the passed address to spend the specified amount of tokens on behalf of msg.sender
   * and then call `onApprovalReceived` on spender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param spender address The address which will spend the funds
   * @param amount uint256 The amount of tokens to be spent
   * @param data bytes Additional data with no specified format, sent in call to `spender`
   */
  function approveAndCall(
    address spender,
    uint256 amount,
    bytes calldata data
  ) external returns (bool);
}

interface IERC1363Receiver {
  /**
   * @notice Handle the receipt of ERC1363 tokens
   * @dev Any ERC1363 smart contract calls this function on the recipient
   * after a `transfer` or a `transferFrom`. This function MAY throw to revert and reject the
   * transfer. Return of other than the magic value MUST result in the
   * transaction being reverted.
   * Note: the token contract address is always the message sender.
   * @param operator address The address which called `transferAndCall` or `transferFromAndCall` function
   * @param from address The address which are token transferred from
   * @param value uint256 The amount of tokens transferred
   * @param data bytes Additional data with no specified format
   * @return `bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"))`
   *  unless throwing
   */
  function onTransferReceived(
    address operator,
    address from,
    uint256 value,
    bytes memory data
  ) external returns (bytes4);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface ICollateralized {
  /// @dev address of the collateral fund and coverage token ($CC)
  function collateral() external view returns (address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './ICollateralized.sol';
import './ICharterable.sol';

interface ICancellableCoverageDemand {
  /// @dev size of collateral allocation chunk made by this pool
  function coverageUnitSize() external view returns (uint256);

  /// @notice Cancel coverage that has been demanded, but not filled yet
  /// @dev can only be called by an accepted insured pool
  /// @param unitCount The number of units that wishes to be cancelled
  /// @return cancelledUnits The amount of units that were cancelled
  /// @return rateBands Distribution of cancelled uints by rate-bands, each aeeay value has higher 40 bits as rate, and the rest as number of units
  function cancelCoverageDemand(
    address insured,
    uint256 unitCount,
    uint256 loopLimit
  ) external returns (uint256 cancelledUnits, uint256[] memory rateBands);
}

interface ICancellableCoverage {
  /// @dev size of collateral allocation chunk made by this pool
  function coverageUnitSize() external view returns (uint256);

  /// @notice Cancel coverage for the sender
  /// @dev Called by insureds
  /// @param payoutRatio The RAY ratio of how much of provided coverage should be paid out
  /// @dev e.g payoutRatio = 5e26 means 50% of coverage is paid
  /// @return payoutValue The amount of coverage paid out to the insured
  function cancelCoverage(address insured, uint256 payoutRatio) external returns (uint256 payoutValue);
}

interface IAddableCoverageDistributor is ICancellableCoverage {
  /// @notice Add demand for coverage
  /// @dev can only be called by an accepted insured pool
  /// @param unitCount Number of *units* of coverage demand to add
  /// @param premiumRate The rate paid on the coverage
  /// @param hasMore Whether the insured has more demand it would like to request after this
  /// @return addedCount Number of units of demand that were actually added
  function addCoverageDemand(
    uint256 unitCount,
    uint256 premiumRate,
    bool hasMore,
    uint256 loopLimit
  ) external returns (uint256 addedCount);

  ///@notice Get the amount of coverage demanded and filled, and the total premium rate and premium charged
  ///@param insured The insured pool
  ///@return availableCoverage The amount coverage in terms of $CC
  ///@return coverage All the details relating to the coverage, demand and premium
  function receivableDemandedCoverage(address insured, uint256 loopLimit)
    external
    view
    returns (uint256 availableCoverage, DemandedCoverage memory coverage);

  /// @notice Transfer the amount of coverage that been filled to the insured since last called
  /// @dev Only should be called when charteredDemand is true
  /// @dev No use in calling this after coverage demand is fully fulfilled
  /// @param insured The insured to be updated
  /// @return receivedCoverage amount of coverage the Insured received
  /// @return receivedCollateral amount of collateral sent to the Insured
  /// @return coverage Up to date information for this insured
  function receiveDemandedCoverage(address insured, uint256 loopLimit)
    external
    returns (
      uint256 receivedCoverage,
      uint256 receivedCollateral,
      DemandedCoverage memory
    );
}

interface ICoverageDistributor is ICancellableCoverageDemand, IAddableCoverageDistributor {
  function coverageUnitSize() external view override(ICancellableCoverage, ICancellableCoverageDemand) returns (uint256);
}

struct DemandedCoverage {
  uint256 totalDemand; // total demand added to insurer
  uint256 totalCovered; // total coverage allocated by insurer (can not exceed total demand)
  uint256 pendingCovered; // coverage that is allocated, but can not be given yet (should reach unit size)
  uint256 premiumRate; // total premium rate accumulated accross all units filled-in with coverage
  uint256 totalPremium; // time-cumulated of premiumRate
  uint32 premiumUpdatedAt;
  uint32 premiumRateUpdatedAt;
}

struct TotalCoverage {
  uint256 totalCoverable; // total demand that can be covered now (already balanced) - this value is not provided per-insured
  uint88 usableRounds;
  uint88 openRounds;
  uint64 batchCount;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.10;

/*

UnitPremiumRate per sec * 365 days <= 1 WAD (i.e. 1 WAD = 100% of coverage p.a.)
=>> UnitPremiumRate is uint40
=>> timestamp ~80y

=>> RoundPremiumRate = UnitPremiumRate (40) * unitPerRound (16) = 56

=>> InsuredPremiumRate = UnitPremiumRate (40) * avgUnits (24) = 64
=>> AccumulatedInsuredPremiumRate = InsuredPremiumRate (64) * timestamp (32) = 96

=>> PoolPremiumRate = UnitPremiumRate (40) * maxUnits (64) = 104
=>> PoolAccumulatedPremiumRate = PoolPremiumRate (104) * timestamp (32) = 140

*/

library Rounds {
  /// @dev must be equal to bit size of Demand.premiumRate
  uint8 internal constant DEMAND_RATE_BITS = 40;

  /// @dev demand log entry, related to a single insurd pool
  struct Demand {
    /// @dev first batch that includes this demand
    uint64 startBatchNo;
    /// @dev premiumRate for this demand. See DEMAND_RATE_BITS
    uint40 premiumRate;
    /// @dev number of rounds accross all batches where this demand was added
    uint24 rounds;
    /// @dev number of units added to each round by this demand
    uint16 unitPerRound;
  }

  struct InsuredParams {
    /// @dev a minimum number of units to be allocated for an insured in a single batch. Best effort, but may be ignored.
    uint24 minUnits;
    /// @dev a maximum % of units this insured can have per round. This is a hard limit.
    uint16 maxShare;
    /// @dev a minimum premium rate to accept new coverage demand
    uint40 minPremiumRate;
  }

  struct InsuredEntry {
    /// @dev batch number to add next demand (if it will be open) otherwise it will start with the earliest open batch
    uint64 nextBatchNo;
    /// @dev total number of units demanded by this insured pool
    uint64 demandedUnits;
    /// @dev see InsuredParams
    PackedInsuredParams params;
    /// @dev status of the insured pool
    MemberStatus status;
  }

  struct Coverage {
    /// @dev total number of units covered for this insured pool
    uint64 coveredUnits;
    /// @dev index of Demand entry that is covered partially or will be covered next
    uint64 lastUpdateIndex;
    /// @dev Batch that is a part of the partially covered Demand
    uint64 lastUpdateBatchNo;
    /// @dev number of rounds within the Demand (lastUpdateIndex) starting from Demand's startBatchNo till lastUpdateBatchNo
    uint24 lastUpdateRounds;
    /// @dev number of rounds of a partial batch included into coveredUnits
    uint24 lastPartialRoundNo;
  }

  struct CoveragePremium {
    /// @dev total premium collected till lastUpdatedAt
    uint96 coveragePremium;
    /// @dev premium collection rate at lastUpdatedAt
    uint64 coveragePremiumRate;
    // uint64
    /// @dev time of the last updated applied
    uint32 lastUpdatedAt;
  }

  /// @dev Draft round can NOT receive coverage, more units can be added, always unbalanced
  /// @dev ReadyMin is a Ready round where more units can be added, may be unbalanced
  /// @dev Ready round can receive coverage, more units can NOT be added, balanced
  /// @dev Full round can NOT receive coverage, more units can NOT be added - full rounds are summed up and ignored further
  enum State {
    Draft,
    ReadyMin,
    Ready,
    Full
  }

  struct Batch {
    /// @dev sum of premium rates provided by all units (from different insured pools), per round
    uint56 roundPremiumRateSum;
    /// @dev next batch number (one-way linked list)
    uint64 nextBatchNo;
    /// @dev total number of units befor this batch, this value may not be exact for non-ready batches
    uint80 totalUnitsBeforeBatch;
    /// @dev number of rounds within the batch, can only be zero for an empty (not initialized batch)
    uint24 rounds;
    /// @dev number of units for each round of this batch
    uint16 unitPerRound;
    /// @dev state of this batch
    State state;
  }

  function isFull(Batch memory b) internal pure returns (bool) {
    return isFull(b.state);
  }

  function isOpen(Batch memory b) internal pure returns (bool) {
    return isOpen(b.state);
  }

  function isReady(Batch memory b) internal pure returns (bool) {
    return isReady(b.state);
  }

  function isDraft(State state) internal pure returns (bool) {
    return state == State.Draft;
  }

  function isFull(State state) internal pure returns (bool) {
    return state == State.Full;
  }

  function isOpen(State state) internal pure returns (bool) {
    return state <= State.ReadyMin;
  }

  function isReady(State state) internal pure returns (bool) {
    return state >= State.ReadyMin && state <= State.Ready;
  }

  type PackedInsuredParams is uint80;

  function packInsuredParams(
    uint24 minUnits_,
    uint16 maxShare_,
    uint40 minPremiumRate_
  ) internal pure returns (PackedInsuredParams) {
    return PackedInsuredParams.wrap(uint80((uint256(minPremiumRate_) << 40) | (uint256(maxShare_) << 24) | minUnits_));
  }

  function unpackInsuredParams(PackedInsuredParams v) internal pure returns (InsuredParams memory p) {
    p.minUnits = minUnits(v);
    p.maxShare = maxShare(v);
    p.minPremiumRate = minPremiumRate(v);
  }

  function minUnits(PackedInsuredParams v) internal pure returns (uint24) {
    return uint24(PackedInsuredParams.unwrap(v));
  }

  function maxShare(PackedInsuredParams v) internal pure returns (uint16) {
    return uint16(PackedInsuredParams.unwrap(v) >> 24);
  }

  function minPremiumRate(PackedInsuredParams v) internal pure returns (uint40) {
    return uint40(PackedInsuredParams.unwrap(v) >> 40);
  }
}

enum MemberStatus {
  Unknown,
  JoinCancelled,
  JoinRejected,
  JoinFailed,
  Declined,
  Joining,
  Accepted,
  Banned,
  NotApplicable
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface ICharterable {
  /// @dev indicates how the demand from insured pools is handled:
  /// * Chartered demand will be allocated without calling IInsuredPool, coverage units can be partially filled in.
  /// * Non-chartered (potential) demand can only be allocated after calling IInsuredPool.tryAddCoverage first, units can only be allocated in full.
  function charteredDemand() external view returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/Address.sol';
import '../tools/Errors.sol';
import '../interfaces/IJoinable.sol';
import '../interfaces/IInsuredPool.sol';
import '../insurer/Rounds.sol';

import 'hardhat/console.sol';

/// @title InsurerJoinBase
/// @notice Handles Insured's requests on joining this Insurer
abstract contract InsurerJoinBase is IJoinEvents {
  function internalGetStatus(address) internal view virtual returns (MemberStatus);

  function internalSetStatus(address, MemberStatus) internal virtual;

  function internalIsInvestor(address) internal view virtual returns (bool);

  function internalRequestJoin(address insured) internal virtual returns (MemberStatus status) {
    Value.requireContract(insured);
    if ((status = internalGetStatus(insured)) >= MemberStatus.Joining) {
      return status;
    }
    if (status == MemberStatus.Unknown) {
      State.require(!internalIsInvestor(insured));
    }
    internalSetStatus(insured, MemberStatus.Joining);
    emit JoinRequested(insured);

    if ((status = internalInitiateJoin(insured)) != MemberStatus.Joining) {
      status = _updateInsuredStatus(insured, status);
    }
  }

  function internalCancelJoin(address insured) internal returns (MemberStatus status) {
    if ((status = internalGetStatus(insured)) == MemberStatus.Joining) {
      status = MemberStatus.JoinCancelled;
      internalSetStatus(insured, status);
      emit JoinCancelled(insured);
    }
  }

  function _updateInsuredStatus(address insured, MemberStatus status) private returns (MemberStatus) {
    State.require(status > MemberStatus.Unknown);

    MemberStatus currentStatus = internalGetStatus(insured);
    if (currentStatus == MemberStatus.Joining) {
      bool accepted;
      if (status == MemberStatus.Accepted) {
        if (internalPrepareJoin(insured)) {
          accepted = true;
        } else {
          status = MemberStatus.JoinRejected;
        }
      } else if (status != MemberStatus.Banned) {
        status = MemberStatus.JoinRejected;
      }
      internalSetStatus(insured, status);

      bool isPanic;
      bytes memory errReason;

      try IInsuredPool(insured).joinProcessed(accepted) {
        emit JoinProcessed(insured, accepted);

        status = internalGetStatus(insured);
        if (accepted && status == MemberStatus.Accepted) {
          internalAfterJoinOrLeave(insured, status);
        }
        return status;
      } catch Error(string memory reason) {
        errReason = bytes(reason);
      } catch (bytes memory reason) {
        isPanic = true;
        errReason = reason;
      }
      emit JoinFailed(insured, isPanic, errReason);
      status = MemberStatus.JoinFailed;
    } else {
      if (status == MemberStatus.Declined) {
        State.require(currentStatus != MemberStatus.Banned);
      }
      if (currentStatus == MemberStatus.Accepted && status != MemberStatus.Accepted) {
        internalAfterJoinOrLeave(insured, status);
        emit MemberLeft(insured);
      }
    }

    internalSetStatus(insured, status);
    return status;
  }

  function internalAfterJoinOrLeave(address insured, MemberStatus status) internal virtual;

  function internalProcessJoin(address insured, bool accepted) internal virtual {
    _updateInsuredStatus(insured, accepted ? MemberStatus.Accepted : MemberStatus.JoinRejected);
  }

  function internalPrepareJoin(address) internal virtual returns (bool);

  function internalInitiateJoin(address) internal virtual returns (MemberStatus);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../Errors.sol';

/// @dev Percentages are defined in basis points. The precision is indicated by ONE. Operations are rounded half up.
library PercentageMath {
  uint16 public constant BP = 1; // basis point
  uint16 public constant PCT = 100 * BP; // basis points per percentage point
  uint16 public constant ONE = 100 * PCT; // basis points per 1 (100%)
  uint16 public constant HALF_ONE = ONE / 2;

  /**
   * @dev Executes a percentage multiplication
   * @param value The value of which the percentage needs to be calculated
   * @param factor Basis points of the value to be calculated
   * @return The percentage of value
   **/
  function percentMul(uint256 value, uint256 factor) internal pure returns (uint256) {
    if (value == 0 || factor == 0) {
      return 0;
    }
    return (value * factor + HALF_ONE) / ONE;
  }

  /**
   * @dev Executes a percentage division
   * @param value The value of which the percentage needs to be calculated
   * @param factor Basis points of the value to be calculated
   * @return The value divided the percentage
   **/
  function percentDiv(uint256 value, uint256 factor) internal pure returns (uint256) {
    return (value * ONE + factor / 2) / factor;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './ICollateralized.sol';

interface IPremiumDistributor is ICollateralized {
  function premiumAllocationUpdated(
    address insured,
    uint256 accumulated,
    uint256 increment,
    uint256 rate
  ) external;

  function premiumAllocationFinished(
    address insured,
    uint256 accumulated,
    uint256 increment
  ) external returns (uint256 premiumDebt);

  function registerPremiumSource(address insured, bool register) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/introspection/ERC165Checker.sol';
import '../interfaces/IWeightedPool.sol';
import '../interfaces/IPremiumSource.sol';
import '../tools/math/PercentageMath.sol';
import './WeightedRoundsBase.sol';
import './WeightedPoolAccessControl.sol';

abstract contract WeightedPoolConfig is WeightedRoundsBase, WeightedPoolAccessControl {
  using PercentageMath for uint256;
  using WadRayMath for uint256;
  using Rounds for Rounds.PackedInsuredParams;

  WeightedPoolParams internal _params;

  // uint256 private _loopLimits;

  constructor(
    IAccessController acl,
    uint256 unitSize,
    address collateral_
  ) WeightedRoundsBase(unitSize) GovernedHelper(acl, collateral_) {}

  // function internalSetLoopLimits(uint16[] memory limits) internal virtual {
  //   uint256 v;
  //   for (uint256 i = limits.length; i > 0; ) {
  //     i--;
  //     v = (v << 16) | uint16(limits[i]);
  //   }
  //   _loopLimits = v;
  // }

  event WeightedPoolParamsUpdated(WeightedPoolParams params);

  function internalSetPoolParams(WeightedPoolParams memory params) internal virtual {
    Value.require(
      params.minUnitsPerRound > 0 && params.maxUnitsPerRound >= params.minUnitsPerRound && params.overUnitsPerRound >= params.maxUnitsPerRound
    );

    Value.require(params.maxAdvanceUnits >= params.minAdvanceUnits && params.minAdvanceUnits >= params.maxUnitsPerRound);

    Value.require(
      params.minInsuredSharePct > 0 && params.maxInsuredSharePct > params.minInsuredSharePct && params.maxInsuredSharePct <= PercentageMath.ONE
    );

    Value.require(params.riskWeightTarget > 0 && params.riskWeightTarget < PercentageMath.ONE);

    Value.require(
      params.coveragePrepayPct >= _params.coveragePrepayPct &&
        params.coveragePrepayPct >= PercentageMath.HALF_ONE &&
        params.maxUserDrawdownPct <= PercentageMath.ONE - params.coveragePrepayPct
    );

    _params = params;
    emit WeightedPoolParamsUpdated(params);
  }

  ///@return The number of rounds to initialize a new batch
  function internalBatchAppend(
    uint80,
    uint32 openRounds,
    uint64 unitCount
  ) internal view override returns (uint24) {
    uint256 max = _params.maxUnitsPerRound;
    uint256 min = _params.minAdvanceUnits / max;
    max = _params.maxAdvanceUnits / max;

    if (min > type(uint24).max) {
      if (openRounds + min > max) {
        return 0;
      }
      min = type(uint24).max;
    }

    if (openRounds + min > max) {
      if (min < (max >> 1) || openRounds > (max >> 1)) {
        return 0;
      }
    }

    if (unitCount > type(uint24).max) {
      unitCount = type(uint24).max;
    }

    if ((unitCount /= uint64(min)) <= 1) {
      return uint24(min);
    }

    if ((max = (max - openRounds) / min) < unitCount) {
      min *= max;
    } else {
      min *= unitCount;
    }
    Sanity.require(min > 0);

    return uint24(min);
  }

  function internalGetPassiveCoverageUnits() internal view returns (uint256) {}

  /// @dev Calculate the limits of the number of units that can be added to a round
  function internalRoundLimits(
    uint80 totalUnitsBeforeBatch,
    uint24 batchRounds,
    uint16 unitPerRound,
    uint64 demandedUnits,
    uint16 maxShare
  )
    internal
    view
    override
    returns (
      uint16, // maxShareUnitsPerRound,
      uint16, // minUnitsPerRound,
      uint16, // readyUnitsPerRound
      uint16 // maxUnitsPerRound
    )
  {
    (uint16 minUnitsPerRound, uint16 maxUnitsPerRound) = (_params.minUnitsPerRound, _params.maxUnitsPerRound);

    // total # of units could be allocated when this round if full
    uint256 x = uint256(unitPerRound < minUnitsPerRound ? minUnitsPerRound : unitPerRound + 1) *
      batchRounds +
      totalUnitsBeforeBatch +
      internalGetPassiveCoverageUnits();

    // max of units that can be added in total for the share not to be exceeded
    x = x.percentMul(maxShare);

    if (x < demandedUnits + batchRounds) {
      x = 0;
    } else {
      unchecked {
        x = (x - demandedUnits) / batchRounds;
      }
      if (unitPerRound + x >= maxUnitsPerRound) {
        if (unitPerRound < minUnitsPerRound) {
          // this prevents lockup of a batch when demand is added by small portions
          minUnitsPerRound = unitPerRound + 1;
        }
      }

      if (x > type(uint16).max) {
        x = type(uint16).max;
      }
    }

    return (uint16(x), minUnitsPerRound, maxUnitsPerRound, _params.overUnitsPerRound);
  }

  function _requiredForMinimumCoverage(
    uint64 demandedUnits,
    uint64 minUnits,
    uint256 remainingUnits
  ) private pure returns (bool) {
    return demandedUnits < minUnits && demandedUnits + remainingUnits >= minUnits;
  }

  function internalBatchSplit(
    uint64 demandedUnits,
    uint64 minUnits,
    uint24 batchRounds,
    uint24 remainingUnits
  ) internal pure override returns (uint24 splitRounds) {
    // console.log('internalBatchSplit-0', demandedUnits, minUnits);
    // console.log('internalBatchSplit-1', batchRounds, remainingUnits);
    return _requiredForMinimumCoverage(demandedUnits, minUnits, remainingUnits) || (remainingUnits > batchRounds >> 2) ? remainingUnits : 0;
  }

  function internalIsEnoughForMore(Rounds.InsuredEntry memory entry, uint256 unitCount) internal view override returns (bool) {
    return _requiredForMinimumCoverage(entry.demandedUnits, entry.params.minUnits(), unitCount) || unitCount >= _params.minAdvanceUnits;
  }

  function defaultLoopLimit(LoopLimitType t, uint256 limit) internal view returns (uint256) {
    if (limit == 0) {
      // limit = uint16(_loopLimits >> (uint8(t) << 1));
      // if (limit == 0) {
      limit = t > LoopLimitType.ReceivableDemandedCoverage ? 31 : 255;
      // }
    }
    this;
    return limit;
  }

  function internalGetUnderwrittenParams(address insured) internal virtual returns (bool ok, IApprovalCatalog.ApprovedPolicyForInsurer memory data) {
    IApprovalCatalog ac = approvalCatalog();
    if (address(ac) != address(0)) {
      (ok, data) = ac.getAppliedApplicationForInsurer(insured);
    } else {
      IInsurerGovernor g = governorContract();
      if (address(g) != address(0)) {
        (ok, data) = g.getApprovedPolicyForInsurer(insured);
      }
    }
  }

  /// @dev Prepare for an insured pool to join by setting the parameters
  function internalPrepareJoin(address insured) internal override returns (bool) {
    (bool ok, IApprovalCatalog.ApprovedPolicyForInsurer memory approvedParams) = internalGetUnderwrittenParams(insured);
    if (!ok) {
      return false;
    }

    uint256 maxShare = approvedParams.riskLevel == 0 ? PercentageMath.ONE : uint256(_params.riskWeightTarget).percentDiv(approvedParams.riskLevel);
    uint256 v;
    if (maxShare >= (v = _params.maxInsuredSharePct)) {
      maxShare = v;
    } else if (maxShare < (v = _params.minInsuredSharePct)) {
      maxShare = v;
    }

    if (maxShare == 0) {
      return false;
    }

    State.require(IPremiumSource(insured).premiumToken() == approvedParams.premiumToken);

    InsuredParams memory insuredSelfParams = IInsuredPool(insured).insuredParams();

    uint256 unitSize = internalUnitSize();
    uint256 minUnits = (insuredSelfParams.minPerInsurer + unitSize - 1) / unitSize;
    Arithmetic.require(minUnits <= type(uint24).max);

    uint256 baseRate = (approvedParams.basePremiumRate + unitSize - 1) / unitSize;
    Arithmetic.require(baseRate <= type(uint40).max);

    super.internalSetInsuredParams(
      insured,
      Rounds.InsuredParams({minUnits: uint24(minUnits), maxShare: uint16(maxShare), minPremiumRate: uint40(baseRate)})
    );

    return true;
  }

  function internalGetStatus(address account) internal view override returns (MemberStatus) {
    return internalGetInsuredStatus(account);
  }

  function internalSetStatus(address account, MemberStatus status) internal override {
    return super.internalSetInsuredStatus(account, status);
  }

  /// @return status The status of the account, NotApplicable if unknown about this address or account is an investor
  function internalStatusOf(address account) internal view returns (MemberStatus status) {
    if ((status = internalGetStatus(account)) == MemberStatus.Unknown && internalIsInvestor(account)) {
      status = MemberStatus.NotApplicable;
    }
    return status;
  }
}

enum LoopLimitType {
  // View ops (255 iterations by default)
  ReceivableDemandedCoverage,
  // Modify ops (31 iterations by default)
  AddCoverageDemand,
  AddCoverage,
  AddCoverageDemandByPull,
  CancelCoverageDemand,
  ReceiveDemandedCoverage
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IWeightedPoolInit {
  function initializeWeighted(
    address governor,
    string calldata tokenName,
    string calldata tokenSymbol,
    WeightedPoolParams calldata params
  ) external;
}

struct WeightedPoolParams {
  /// @dev a recommended maximum of uncovered units per pool
  uint32 maxAdvanceUnits;
  /// @dev a recommended minimum of units per batch
  uint32 minAdvanceUnits;
  /// @dev a target risk level, an insured with higher risk will get a lower share per batch (and vice versa)
  uint16 riskWeightTarget;
  /// @dev a minimum share per batch per insured, lower values will be replaced by this one
  uint16 minInsuredSharePct;
  /// @dev a maximum share per batch per insured, higher values will be replaced by this one
  uint16 maxInsuredSharePct;
  /// @dev an amount of units per round in a batch to consider the batch as ready to be covered
  uint16 minUnitsPerRound;
  /// @dev an amount of units per round in a batch to consider a batch as full (no more units can be added)
  uint16 maxUnitsPerRound;
  /// @dev an "overcharge" / a maximum allowed amount of units per round in a batch that can be applied to reduce batch fragmentation
  uint16 overUnitsPerRound;
  /// @dev an amount of coverage to be given out on reconciliation, where 100% disables drawdown permanently. A new value must be >= the prev one.
  uint16 coveragePrepayPct;
  /// @dev an amount of coverage usable as collateral drawdown, where 0% stops drawdown. MUST: maxUserDrawdownPct + coveragePrepayPct <= 100%
  uint16 maxUserDrawdownPct;
  /// @dev limits a number of auto-pull loops by amount of added coverage divided by this number, zero disables auto-pull
  uint16 unitsPerAutoPull;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './ICollateralized.sol';

interface IPremiumSource {
  function premiumToken() external view returns (address);

  function collectPremium(
    address actuary,
    address token,
    uint256 amount,
    uint256 value
  ) external;
}

interface IPremiumSourceDelegate {
  function collectPremium(
    address actuary,
    address token,
    uint256 amount,
    uint256 value,
    address recipient
  ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '../tools/math/WadRayMath.sol';
import '../tools/math/Math.sol';
import '../interfaces/IInsurerPool.sol';
import './Rounds.sol';

import 'hardhat/console.sol';

/// @title A calculator for allocating coverage
/// @notice Coverage is demanded and provided through rounds and batches.
// solhint-disable-next-line max-states-count
abstract contract WeightedRoundsBase {
  using Rounds for Rounds.Batch;
  using Rounds for Rounds.State;
  using Rounds for Rounds.PackedInsuredParams;
  using EnumerableSet for EnumerableSet.AddressSet;
  using WadRayMath for uint256;
  using Math for uint256;

  uint256 private immutable _unitSize;

  constructor(uint256 unitSize) {
    Value.require(unitSize > 0);
    _unitSize = unitSize;
  }

  /// @dev tracking info about insured pools
  mapping(address => Rounds.InsuredEntry) private _insureds;
  /// @dev demand log of each insured pool, updated by addition of coverage demand
  mapping(address => Rounds.Demand[]) private _demands;
  /// @dev coverage summary of each insured pool, updated by retrieving collected coverage
  mapping(address => Rounds.Coverage) private _covered;
  /// @dev premium summary of each insured pool, updated by retrieving collected coverage
  mapping(address => Rounds.CoveragePremium) private _premiums;

  /// @dev one way linked list of batches, appended by adding coverage demand, trimmed by adding coverage
  mapping(uint64 => Rounds.Batch) private _batches;

  /// @dev total number of batches
  uint64 private _batchCount;
  /// @dev the most recently added batch (head of the linked list)
  uint64 private _latestBatchNo;
  /// @dev points to an earliest round that is open, can not be zero
  uint64 private _firstOpenBatchNo;
  /// @dev number of open rounds starting from the partial one to _latestBatchNo
  /// @dev it is provided to the logic distribution control logic
  uint32 private _openRounds;
  /// @dev summary of total pool premium (covers all batches before the partial)
  Rounds.CoveragePremium private _poolPremium;

  struct PartialState {
    /// @dev amount of coverage in the partial round, must be zero when roundNo == batch size
    uint128 roundCoverage;
    /// @dev points either to a partial round or to the last full round when there is no other rounds
    /// @dev can ONLY be zero when there is no rounds (zero state)
    uint64 batchNo;
    /// @dev number of a partial round / also is the number of full rounds in the batch
    /// @dev when equals to batch size - then there is no partial round
    uint24 roundNo;
  }
  /// @dev the batch being filled (partially filled)
  PartialState private _partial;

  /// @dev segment of a coverage integral (time-weighted) for a partial or full batch
  struct TimeMark {
    /// @dev value of integral of coverage for a batch
    uint192 coverageTW;
    /// @dev last updated at
    uint32 timestamp;
    /// @dev time duration of this batch (length of the integral segment)
    uint32 duration;
  }
  /// @dev segments of coverage integral NB! Each segment is independent, it does NOT include / cosider previous segments
  mapping(uint64 => TimeMark) private _marks;

  uint80 private _pendingCancelledCoverageUnits;
  uint80 private _pendingCancelledDemandUnits;

  /// @dev a batch number to look for insureds with "hasMore" in _pullableDemands
  uint64 private _pullableBatchNo;
  /// @dev sets of insureds with "hasMore"
  mapping(uint64 => EnumerableSet.AddressSet) private _pullableDemands;

  function internalSetInsuredStatus(address account, MemberStatus status) internal {
    _insureds[account].status = status;
  }

  function internalGetInsuredStatus(address account) internal view returns (MemberStatus) {
    return _insureds[account].status;
  }

  ///@dev Sets the minimum amount of units this insured pool will assign and the max share % of the pool it can take up
  function internalSetInsuredParams(address account, Rounds.InsuredParams memory params) internal {
    _insureds[account].params = Rounds.packInsuredParams(params.minUnits, params.maxShare, params.minPremiumRate);
  }

  function internalGetInsuredParams(address account) internal view returns (MemberStatus, Rounds.InsuredParams memory) {
    Rounds.InsuredEntry storage entry = _insureds[account];
    return (entry.status, entry.params.unpackInsuredParams());
  }

  function internalUnitSize() internal view returns (uint256) {
    return _unitSize;
  }

  struct AddCoverageDemandParams {
    uint256 loopLimit;
    address insured;
    uint40 premiumRate;
    bool hasMore;
    // temporary variables
    uint64 prevPullBatch;
    bool takeNext;
  }

  /// @dev Adds coverage demand by performing the following:
  /// @dev Find which batch to first append to
  /// @dev Fill the batch, and create new batches if needed, looping under either all units added to batch or loopLimit
  /// @return The remaining demanded units
  function internalAddCoverageDemand(uint64 unitCount, AddCoverageDemandParams memory params)
    internal
    returns (
      uint64 // remainingCount
    )
  {
    // console.log('\ninternalAddCoverageDemand', unitCount);
    Rounds.InsuredEntry memory entry = _insureds[params.insured];
    Access.require(entry.status == MemberStatus.Accepted);
    Value.require(entry.params.minPremiumRate() <= params.premiumRate);

    if (unitCount == 0 || params.loopLimit == 0) {
      return unitCount;
    }

    Rounds.Demand[] storage demands = _demands[params.insured];
    params.prevPullBatch = entry.nextBatchNo;

    (Rounds.Batch memory b, uint64 thisBatch, bool isFirstOfOpen) = _findBatchToAppend(entry.nextBatchNo);

    Rounds.Demand memory demand;
    uint32 openRounds = _openRounds - _partial.roundNo;
    bool updateBatch;
    for (;;) {
      // console.log('addDemandLoop', thisBatch, isFirstOfOpen, b.totalUnitsBeforeBatch);
      params.loopLimit--;

      // Sanity.require(thisBatch != 0);
      if (b.rounds == 0) {
        // NB! empty batches can also be produced by cancellation

        b.rounds = internalBatchAppend(_adjustedTotalUnits(b.totalUnitsBeforeBatch), openRounds, unitCount);
        // console.log('addDemandToEmpty', b.rounds, openRounds - _partial.roundNo);

        if (b.rounds == 0) {
          break;
        }

        openRounds += b.rounds;
        _initTimeMark(_latestBatchNo = b.nextBatchNo = ++_batchCount);
        updateBatch = true;
      }

      uint16 addPerRound;
      if (b.isOpen()) {
        (addPerRound, params.takeNext) = _addToBatch(unitCount, b, entry, params, isFirstOfOpen);
        // console.log('addToBatchResult', addPerRound, takeNext);
        if (addPerRound > 0) {
          updateBatch = true;
        } else if (b.unitPerRound == 0) {
          updateBatch = false;
          break;
        }

        if (isFirstOfOpen && b.isOpen()) {
          _firstOpenBatchNo = thisBatch;
          isFirstOfOpen = false;
        }
      }

      if (b.rounds > 0 && _addToSlot(demand, demands, addPerRound, b.rounds, params.premiumRate)) {
        demand = Rounds.Demand({startBatchNo: thisBatch, premiumRate: params.premiumRate, rounds: b.rounds, unitPerRound: addPerRound});
      }

      if (addPerRound > 0) {
        // Sanity.require(takeNext);
        uint64 addedUnits = uint64(addPerRound) * b.rounds;
        unitCount -= addedUnits;
        entry.demandedUnits += addedUnits;
      }

      if (!params.takeNext) {
        break;
      }

      _batches[thisBatch] = b;
      updateBatch = false;

      entry.nextBatchNo = thisBatch = b.nextBatchNo;
      // Sanity.require(thisBatch != 0);

      uint80 totalUnitsBeforeBatch = b.totalUnitsBeforeBatch + uint80(b.unitPerRound) * b.rounds;
      b = _batches[thisBatch];

      if (b.totalUnitsBeforeBatch != totalUnitsBeforeBatch) {
        b.totalUnitsBeforeBatch = totalUnitsBeforeBatch;
        updateBatch = true;
      }

      if (unitCount == 0 || params.loopLimit == 0) {
        break;
      }
    }

    if (updateBatch) {
      _batches[thisBatch] = b;
    }
    _openRounds = openRounds + _partial.roundNo;

    _setPullBatch(params, params.hasMore || internalIsEnoughForMore(entry, unitCount) ? thisBatch : 0);
    _insureds[params.insured] = entry;

    if (demand.unitPerRound != 0) {
      demands.push(demand);
    }

    if (isFirstOfOpen) {
      _firstOpenBatchNo = thisBatch;
    }

    return unitCount;
  }

  function internalIsEnoughForMore(Rounds.InsuredEntry memory entry, uint256 unitCount) internal view virtual returns (bool);

  function _setPullBatch(AddCoverageDemandParams memory params, uint64 newPullBatch) private {
    if (params.prevPullBatch != newPullBatch) {
      if (params.prevPullBatch != 0) {
        _removeFromPullable(params.insured, params.prevPullBatch);
      }
      if (newPullBatch != 0) {
        _addToPullable(params.insured, newPullBatch);
      }
    }
  }

  /// @dev Finds which batch to add coverage demand to.
  /// @param nextBatchNo Attempts to use if it is accepting coverage demand
  /// @return b Returns the current batch, its number and whether batches were filled
  /// @return thisBatchNo
  /// @return isFirstOfOpen
  function _findBatchToAppend(uint64 nextBatchNo)
    private
    returns (
      Rounds.Batch memory b,
      uint64 thisBatchNo,
      bool isFirstOfOpen
    )
  {
    uint64 firstOpen = _firstOpenBatchNo;
    if (firstOpen == 0) {
      // there are no batches
      Sanity.require(_batchCount == 0);
      Sanity.require(nextBatchNo == 0);
      _initTimeMark(_latestBatchNo = _batchCount = _partial.batchNo = _firstOpenBatchNo = 1);
      return (b, 1, true);
    }

    if (nextBatchNo != 0 && (b = _batches[nextBatchNo]).isOpen()) {
      thisBatchNo = nextBatchNo;
    } else {
      b = _batches[thisBatchNo = firstOpen];
    }

    if (b.nextBatchNo == 0) {
      Sanity.require(b.rounds == 0);
    } else {
      PartialState memory part = _partial;
      if (part.batchNo == thisBatchNo) {
        uint24 remainingRounds = part.roundCoverage == 0 ? part.roundNo : part.roundNo + 1;
        if (remainingRounds > 0) {
          _splitBatch(remainingRounds, b);

          if (part.roundCoverage == 0) {
            b.state = Rounds.State.Full;

            Rounds.CoveragePremium memory premium = _poolPremium;
            _addPartialToTotalPremium(thisBatchNo, premium, b);
            _poolPremium = premium;

            _partial = PartialState({roundCoverage: 0, batchNo: b.nextBatchNo, roundNo: 0});
          }
          _batches[thisBatchNo] = b;
          if (firstOpen == thisBatchNo) {
            _firstOpenBatchNo = firstOpen = b.nextBatchNo;
          }
          b = _batches[thisBatchNo = b.nextBatchNo];
        }
      }
    }

    return (b, thisBatchNo, thisBatchNo == firstOpen);
  }

  function _adjustedTotalUnits(uint80 units) private view returns (uint80 n) {
    n = _pendingCancelledCoverageUnits;
    if (n >= units) {
      return 0;
    }
    unchecked {
      return units - n;
    }
  }

  /// @dev adds the demand to the list of demands
  function _addToSlot(
    Rounds.Demand memory demand,
    Rounds.Demand[] storage demands,
    uint16 addPerRound,
    uint24 batchRounds,
    uint40 premiumRate
  ) private returns (bool) {
    if (demand.unitPerRound == addPerRound && demand.premiumRate == premiumRate) {
      uint24 t;
      unchecked {
        t = batchRounds + demand.rounds;
      }
      if (t >= batchRounds) {
        demand.rounds = t;
        return false;
      }
      // overflow on amount of rounds per slot
    }

    if (demand.unitPerRound != 0) {
      demands.push(demand);
    }
    return true;
  }

  /// @dev Adds units to the batch. Can split the batch when the number of units is less than the number of rounds inside the batch.
  /// The unitCount units are evenly distributed across rounds by increase the # of units per round
  function _addToBatch(
    uint64 unitCount,
    Rounds.Batch memory b,
    Rounds.InsuredEntry memory entry,
    AddCoverageDemandParams memory params,
    bool canClose
  ) private returns (uint16 addPerRound, bool takeNext) {
    Sanity.require(b.isOpen() && b.rounds > 0);

    if (unitCount < b.rounds) {
      // split the batch or return the non-allocated units
      uint24 splitRounds = internalBatchSplit(entry.demandedUnits, entry.params.minUnits(), b.rounds, uint24(unitCount));
      // console.log('addToBatch-internalBatchSplit', splitRounds);
      if (splitRounds == 0) {
        return (0, false);
      }
      Sanity.require(unitCount >= splitRounds);
      // console.log('batchSplit-before', splitRounds, b.rounds, b.nextBatchNo);
      _splitBatch(splitRounds, b);
      // console.log('batchSplit-after', b.rounds, b.nextBatchNo);
    }

    (uint16 maxShareUnitsPerRound, uint16 minUnitsPerRound, uint16 readyUnitsPerRound, uint16 maxUnitsPerRound) = internalRoundLimits(
      _adjustedTotalUnits(b.totalUnitsBeforeBatch),
      b.rounds,
      b.unitPerRound,
      entry.demandedUnits,
      entry.params.maxShare()
    );

    // console.log('addToBatch-checkLimits', b.unitPerRound, b.rounds);
    // console.log('addToBatch-limits', maxShareUnitsPerRound, minUnitsPerRound, maxUnitsPerRound);

    if (maxShareUnitsPerRound > 0) {
      takeNext = true;
      if (b.unitPerRound < maxUnitsPerRound) {
        addPerRound = maxUnitsPerRound - b.unitPerRound;
        if (addPerRound > maxShareUnitsPerRound) {
          addPerRound = maxShareUnitsPerRound;
        }
        uint64 n = unitCount / b.rounds;
        if (addPerRound > n) {
          addPerRound = uint16(n);
        }
        Sanity.require(addPerRound > 0);

        b.unitPerRound += addPerRound;
        b.roundPremiumRateSum += uint56(params.premiumRate) * addPerRound;
      }
    }

    if (b.unitPerRound >= minUnitsPerRound) {
      b.state = canClose && b.unitPerRound >= readyUnitsPerRound ? Rounds.State.Ready : Rounds.State.ReadyMin;
    }
  }

  function internalRoundLimits(
    uint80 totalUnitsBeforeBatch,
    uint24 batchRounds,
    uint16 unitPerRound,
    uint64 demandedUnits,
    uint16 maxShare
  )
    internal
    virtual
    returns (
      uint16 maxAddUnitsPerRound,
      uint16 minUnitsPerRound,
      uint16 readyUnitsPerRound,
      uint16 maxUnitsPerRound
    );

  function internalBatchSplit(
    uint64 demandedUnits,
    uint64 minUnits,
    uint24 batchRounds,
    uint24 remainingUnits
  ) internal virtual returns (uint24 splitRounds);

  function internalBatchAppend(
    uint80 totalUnitsBeforeBatch,
    uint32 openRounds,
    uint64 unitCount
  ) internal virtual returns (uint24 rounds);

  /// @dev Reduces the current batch's rounds and adds the leftover rounds to a new batch.
  /// @dev Checks if this is the new latest batch
  /// @param remainingRounds Number of rounds to reduce the current batch to
  /// @param b The batch to add leftover rounds to
  function _splitBatch(uint24 remainingRounds, Rounds.Batch memory b) private {
    if (b.rounds == remainingRounds) return;
    Sanity.require(b.rounds > remainingRounds);

    uint64 newBatchNo = ++_batchCount;

    _batches[newBatchNo] = Rounds.Batch({
      nextBatchNo: b.nextBatchNo,
      totalUnitsBeforeBatch: b.totalUnitsBeforeBatch + uint80(remainingRounds) * b.unitPerRound,
      rounds: b.rounds - remainingRounds,
      unitPerRound: b.unitPerRound,
      state: b.state,
      roundPremiumRateSum: b.roundPremiumRateSum
    });
    _initTimeMark(newBatchNo);

    b.rounds = remainingRounds;
    if (b.nextBatchNo == 0) {
      _latestBatchNo = newBatchNo;
    }
    b.nextBatchNo = newBatchNo;
  }

  function _splitBatch(uint24 remainingRounds, uint64 batchNo) private returns (uint64) {
    Rounds.Batch memory b = _batches[batchNo];
    _splitBatch(remainingRounds, b);
    _batches[batchNo] = b;
    return b.nextBatchNo;
  }

  struct GetCoveredDemandParams {
    uint256 loopLimit;
    uint256 receivedCoverage;
    uint256 receivedPremium;
    address insured;
    bool done;
  }

  /// @dev Get the amount of demand that has been covered and the premium earned from it
  /// @param params Updates the received coverage
  /// @return coverage The values in this struct ONLY reflect the insured. IS FINALIZED
  /// @return covered Updated information based on newly collected coverage
  /// @return premium The premium paid and new premium rate
  function internalGetCoveredDemand(GetCoveredDemandParams memory params)
    internal
    view
    returns (
      DemandedCoverage memory coverage,
      Rounds.Coverage memory covered,
      Rounds.CoveragePremium memory premium
    )
  {
    Rounds.Demand[] storage demands = _demands[params.insured];
    premium = _premiums[params.insured];

    (coverage.totalPremium, coverage.premiumRate, coverage.premiumUpdatedAt) = (
      premium.coveragePremium,
      premium.coveragePremiumRate,
      premium.lastUpdatedAt
    );
    params.receivedPremium = uint256(_unitSize).wadMul(coverage.totalPremium);

    uint256 demandLength = demands.length;
    if (demandLength == 0) {
      params.done = true;
    } else {
      covered = _covered[params.insured];
      params.receivedCoverage = covered.coveredUnits;

      for (; params.loopLimit > 0; params.loopLimit--) {
        if (covered.lastUpdateIndex >= demandLength || !_collectCoveredDemandSlot(demands[covered.lastUpdateIndex], coverage, covered, premium)) {
          params.done = true;
          break;
        }
      }
    }

    _finalizePremium(coverage, true);
    coverage.totalDemand = uint256(_unitSize) * _insureds[params.insured].demandedUnits;
    coverage.totalCovered += uint256(_unitSize) * covered.coveredUnits;
    params.receivedCoverage = uint256(_unitSize) * (covered.coveredUnits - params.receivedCoverage);
    params.receivedPremium = coverage.totalPremium - params.receivedPremium;
  }

  function internalUpdateCoveredDemand(GetCoveredDemandParams memory params) internal returns (DemandedCoverage memory coverage) {
    (coverage, _covered[params.insured], _premiums[params.insured]) = internalGetCoveredDemand(params);
  }

  /// @dev Sets the function parameters to their correct values by calculating on new full batches
  /// @param d Update startBatchNo is set to the first open batch and rounds from last updated
  /// @param covered Update covered units and last known info based on the newly counted full batches
  /// @param premium Update total premium collected and the new premium rate for full batches
  /// @param coverage Update total premium collected and the new premium rate including the partial batch
  /// @return true if the demand has been completely filled
  function _collectCoveredDemandSlot(
    Rounds.Demand memory d,
    DemandedCoverage memory coverage,
    Rounds.Coverage memory covered,
    Rounds.CoveragePremium memory premium
  ) private view returns (bool) {
    // console.log('collect', d.rounds, covered.lastUpdateBatchNo, covered.lastUpdateRounds);

    uint24 fullRounds;
    if (covered.lastUpdateRounds > 0) {
      d.rounds -= covered.lastUpdateRounds; //Reduce by # of full rounds that was kept track of until lastUpdateBatchNo
      d.startBatchNo = covered.lastUpdateBatchNo;
    }
    if (covered.lastPartialRoundNo > 0) {
      covered.coveredUnits -= uint64(covered.lastPartialRoundNo) * d.unitPerRound;
      covered.lastPartialRoundNo = 0;
    }

    Rounds.Batch memory b;
    while (d.rounds > fullRounds) {
      Sanity.require(d.startBatchNo != 0);
      b = _batches[d.startBatchNo];
      // console.log('collectBatch', d.startBatchNo, b.nextBatchNo, b.rounds);

      if (!b.isFull()) break;
      // console.log('collectBatch1');

      // zero rounds may be present due to cancellations
      if (b.rounds > 0) {
        fullRounds += b.rounds;

        (premium.coveragePremium, premium.coveragePremiumRate, premium.lastUpdatedAt) = _calcPremium(
          d,
          premium,
          b.rounds,
          0,
          d.premiumRate,
          b.unitPerRound
        );
      }
      d.startBatchNo = b.nextBatchNo;
    }

    covered.coveredUnits += uint64(fullRounds) * d.unitPerRound;
    (coverage.totalPremium, coverage.premiumRate, coverage.premiumUpdatedAt) = (
      premium.coveragePremium,
      premium.coveragePremiumRate,
      premium.lastUpdatedAt
    );

    // if the covered.lastUpdateIndex demand has been fully covered
    if (d.rounds == fullRounds) {
      covered.lastUpdateRounds = 0;
      covered.lastUpdateBatchNo = 0;
      covered.lastUpdateIndex++;
      return true;
    }

    Sanity.require(d.rounds > fullRounds);
    Sanity.require(d.startBatchNo != 0);
    covered.lastUpdateRounds += fullRounds;
    covered.lastUpdateBatchNo = d.startBatchNo;

    PartialState memory part = _partial;
    // console.log('collectCheck', part.batchNo, covered.lastUpdateBatchNo);
    if (part.batchNo == d.startBatchNo) {
      // console.log('collectPartial', part.roundNo, part.roundCoverage);
      if (part.roundNo > 0 || part.roundCoverage > 0) {
        covered.coveredUnits += uint64(covered.lastPartialRoundNo = part.roundNo) * d.unitPerRound;
        coverage.pendingCovered = (uint256(part.roundCoverage) * d.unitPerRound) / _batches[d.startBatchNo].unitPerRound;

        (coverage.totalPremium, coverage.premiumRate, coverage.premiumUpdatedAt) = _calcPremium(
          d,
          premium,
          part.roundNo,
          coverage.pendingCovered,
          d.premiumRate,
          b.unitPerRound
        );
      }
    }

    return false;
  }

  /// @dev Calculate the actual premium values since variables keep track of number of coverage units instead of
  /// amount of coverage currency (coverage units * unit size).
  /// @dev NOTE: The effects from this should not be used in any calculations for modifying state
  function _finalizePremium(DemandedCoverage memory coverage, bool roundUp) private view {
    coverage.premiumRate = roundUp ? uint256(_unitSize).wadMulUp(coverage.premiumRate) : uint256(_unitSize).wadMul(coverage.premiumRate);
    coverage.totalPremium = uint256(_unitSize).wadMul(coverage.totalPremium);
    if (coverage.premiumUpdatedAt != 0) {
      coverage.totalPremium += coverage.premiumRate * (block.timestamp - coverage.premiumUpdatedAt);
      coverage.premiumRateUpdatedAt = coverage.premiumUpdatedAt;
      coverage.premiumUpdatedAt = uint32(block.timestamp);
    }
  }

  /// @dev Calculate the new premium values by including the rounds that have been filled for demand d and
  /// the partial rounds
  function _calcPremium(
    Rounds.Demand memory d,
    Rounds.CoveragePremium memory premium,
    uint24 rounds,
    uint256 pendingCovered,
    uint256 premiumRate,
    uint256 batchUnitPerRound
  )
    private
    view
    returns (
      uint96 coveragePremium,
      uint64 coveragePremiumRate,
      uint32 lastUpdatedAt
    )
  {
    TimeMark memory mark = _marks[d.startBatchNo];
    // console.log('premiumBefore', d.startBatchNo, d.unitPerRound, rounds);
    // console.log('premiumBefore', mark.timestamp, premium.lastUpdatedAt, mark.duration);
    // console.log('premiumBefore', premium.coveragePremium, premium.coveragePremiumRate, pendingCovered);
    // console.log('premiumBefore', mark.coverageTW, premiumRate, batchUnitPerRound);
    uint256 v = premium.coveragePremium;
    if (premium.lastUpdatedAt != 0) {
      v += uint256(premium.coveragePremiumRate) * (mark.timestamp - premium.lastUpdatedAt);
    }
    lastUpdatedAt = mark.timestamp;

    if (mark.coverageTW > 0) {
      // normalization by unitSize to reduce storage requirements
      v += _calcTimeMarkPortion(premiumRate * mark.coverageTW, d.unitPerRound, uint256(_unitSize) * batchUnitPerRound);
    }
    coveragePremium = v.asUint96();

    v = premium.coveragePremiumRate + premiumRate * uint256(rounds) * d.unitPerRound;
    if (pendingCovered > 0) {
      // normalization by unitSize to reduce storage requirements
      // roundup is aggresive here to ensure that this pools is guaranteed to pay not less that it pays out
      v += (pendingCovered * premiumRate + (_unitSize - 1)) / _unitSize;
    }
    Arithmetic.require((coveragePremiumRate = uint64(v)) == v);
    // console.log('premiumAfter', coveragePremium, coveragePremiumRate);
  }

  function _calcTimeMarkPortion(
    uint256 tw,
    uint16 unitPerRound,
    uint256 batchRoundUnits
  ) private pure returns (uint256) {
    return (tw * unitPerRound + (batchRoundUnits - 1)) / batchRoundUnits;
  }

  /// @dev Update the premium totals of coverage by including batch b
  function _collectPremiumTotalsFromPartial(
    PartialState memory part,
    Rounds.Batch memory b,
    Rounds.CoveragePremium memory premium,
    DemandedCoverage memory coverage
  ) private view {
    if (b.isFull() || (part.roundNo == 0 && part.roundCoverage == 0)) {
      (coverage.totalPremium, coverage.premiumRate, coverage.premiumUpdatedAt) = (
        premium.coveragePremium,
        premium.coveragePremiumRate,
        premium.lastUpdatedAt
      );
      return;
    }

    Rounds.Demand memory d;
    d.startBatchNo = part.batchNo;
    d.unitPerRound = 1;

    (coverage.totalPremium, coverage.premiumRate, coverage.premiumUpdatedAt) = _calcPremium(
      d,
      premium,
      part.roundNo,
      (part.roundCoverage + (b.unitPerRound - 1)) / b.unitPerRound,
      b.roundPremiumRateSum,
      b.unitPerRound
    );
  }

  function internalGetCoveredTotals() internal view returns (uint256 totalCovered, uint256 pendingCovered) {
    uint64 batchNo = _partial.batchNo;
    if (batchNo > 0) {
      Rounds.Batch storage b = _batches[batchNo];
      totalCovered = _unitSize * (_adjustedTotalUnits(b.totalUnitsBeforeBatch) + uint256(_partial.roundNo) * b.unitPerRound);
      pendingCovered = _partial.roundCoverage;
    }
  }

  function internalGetPremiumTotals() internal view returns (DemandedCoverage memory coverage) {
    return internalGetPremiumTotals(_partial, _poolPremium);
  }

  /// @return coverage All the coverage and premium values
  /// @dev IS FINALIZED
  function internalGetPremiumTotals(PartialState memory part, Rounds.CoveragePremium memory premium)
    internal
    view
    returns (DemandedCoverage memory coverage)
  {
    if (part.batchNo == 0) {
      return coverage;
    }

    Rounds.Batch memory b = _batches[part.batchNo];
    _collectPremiumTotalsFromPartial(part, b, premium, coverage);

    coverage.totalCovered = _adjustedTotalUnits(b.totalUnitsBeforeBatch) + uint256(part.roundNo) * b.unitPerRound;
    coverage.pendingCovered = part.roundCoverage;

    _finalizePremium(coverage, false);
    coverage.totalCovered *= _unitSize;
  }

  /// @dev Get the Pool's total amount of coverage that has been demanded, covered and allocated (partial round) and
  /// the corresponding premium based on these values
  /// @dev IS FINALIZED
  function internalGetTotals(uint256 loopLimit) internal view returns (DemandedCoverage memory coverage, TotalCoverage memory total) {
    PartialState memory part = _partial;
    if (part.batchNo == 0) return (coverage, total);

    uint64 thisBatch = part.batchNo;

    Rounds.Batch memory b = _batches[thisBatch];
    // console.log('batch0', thisBatch, b.nextBatchNo, b.rounds);
    // console.log('batch1', part.roundNo);
    _collectPremiumTotalsFromPartial(part, b, _poolPremium, coverage);

    uint80 adjustedTotal = _adjustedTotalUnits(b.totalUnitsBeforeBatch);
    coverage.totalCovered = adjustedTotal + uint256(part.roundNo) * b.unitPerRound;
    coverage.totalDemand = adjustedTotal + uint256(b.rounds) * b.unitPerRound;
    coverage.pendingCovered = part.roundCoverage;
    total.batchCount = 1;

    if (b.isReady()) {
      total.usableRounds = b.rounds - part.roundNo;
      total.totalCoverable = uint256(total.usableRounds) * b.unitPerRound;
    }
    if (b.isOpen()) {
      total.openRounds += b.rounds - part.roundNo;
    }

    for (; loopLimit > 0 && b.nextBatchNo != 0; loopLimit--) {
      thisBatch = b.nextBatchNo;
      b = _batches[b.nextBatchNo];
      // console.log('batch', thisBatch, b.nextBatchNo);

      total.batchCount++;
      coverage.totalDemand += uint256(b.rounds) * b.unitPerRound;

      if (b.isReady()) {
        total.usableRounds += b.rounds;
        total.totalCoverable += uint256(b.rounds) * b.unitPerRound;
      }

      if (b.isOpen()) {
        total.openRounds += b.rounds;
      }
    }

    _finalizePremium(coverage, false);
    coverage.totalCovered *= _unitSize;
    coverage.totalDemand *= _unitSize;
    total.totalCoverable = total.totalCoverable * _unitSize - coverage.pendingCovered;
  }

  struct AddCoverageParams {
    Rounds.CoveragePremium premium;
    /// @dev != 0 also indicates that at least one round was added
    uint64 openBatchNo;
    bool openBatchUpdated;
    bool batchUpdated;
    bool premiumUpdated;
    // uint256 unitsCovered;
  }

  /// @dev Satisfy coverage demand by adding coverage
  function internalAddCoverage(uint256 amount, uint256 loopLimit)
    internal
    returns (
      uint256 remainingAmount,
      uint256, /* remainingLoopLimit */
      AddCoverageParams memory params,
      PartialState memory part
    )
  {
    part = _partial;

    if (amount == 0 || loopLimit == 0 || part.batchNo == 0) {
      return (amount, loopLimit, params, part);
    }

    Rounds.Batch memory b;
    params.premium = _poolPremium;

    (remainingAmount, loopLimit, b) = _addCoverage(amount, loopLimit, part, params);
    if (params.batchUpdated) {
      _batches[part.batchNo] = b;
    }
    if (params.premiumUpdated) {
      _poolPremium = params.premium;
    }
    if (params.openBatchUpdated) {
      Sanity.require(params.openBatchNo != 0);
      _firstOpenBatchNo = params.openBatchNo;
    }
    _partial = part;
    // console.log('partial3', part.batchNo, part.roundNo, part.roundCoverage);

    return (remainingAmount, loopLimit, params, part);
  }

  /// @dev Adds coverage to the pool and stops if there are no batches left to add coverage to or
  /// if the current batch is not ready to accept coverage
  function _addCoverage(
    uint256 amount,
    uint256 loopLimit,
    PartialState memory part,
    AddCoverageParams memory params
  )
    internal
    returns (
      uint256, /* remainingAmount */
      uint256 remainingLoopLimit,
      Rounds.Batch memory b
    )
  {
    b = _batches[part.batchNo];

    if (part.roundCoverage > 0) {
      Sanity.require(b.isReady());

      _updateTimeMark(part, b.unitPerRound);

      uint256 maxRoundCoverage = uint256(_unitSize) * b.unitPerRound;
      uint256 vacant = maxRoundCoverage - part.roundCoverage;
      if (amount < vacant) {
        part.roundCoverage += uint128(amount);
        return (0, loopLimit - 1, b);
      }
      // params.unitsCovered = b.unitPerRound;
      part.roundCoverage = 0;
      part.roundNo++;
      amount -= vacant;
    } else if (!b.isReady()) {
      return (amount, loopLimit - 1, b);
    }

    /// @dev != 0 also indicates that at least one round was added
    params.openBatchNo = _firstOpenBatchNo;
    while (true) {
      loopLimit--;

      // if filled in the final round of a batch
      if (part.roundNo >= b.rounds) {
        Sanity.require(part.roundNo == b.rounds);
        Sanity.require(part.roundCoverage == 0);

        if (b.state != Rounds.State.Full) {
          b.state = Rounds.State.Full;
          params.batchUpdated = true;

          if (b.unitPerRound == 0) {
            // this is a special case when all units were removed by cancellations
            Sanity.require(b.rounds == 0);
            // total premium doesn't need to be updated as the rate remains the same
          } else {
            _addPartialToTotalPremium(part.batchNo, params.premium, b);
            params.premiumUpdated = true;
          }
        }

        if (params.batchUpdated) {
          _batches[part.batchNo] = b;
          params.batchUpdated = false;
        }

        if (part.batchNo == params.openBatchNo) {
          params.openBatchNo = b.nextBatchNo;
          params.openBatchUpdated = true;
        }

        if (b.nextBatchNo == 0) break;

        // do NOT do like this here:  part = PartialState({batchNo: b.nextBatchNo, roundNo: 0, roundCoverage: 0});
        (part.batchNo, part.roundNo, part.roundCoverage) = (b.nextBatchNo, 0, 0);
        // console.log('partial0', part.batchNo, part.roundNo, part.roundCoverage);

        uint80 totalUnitsBeforeBatch = b.totalUnitsBeforeBatch;
        if (b.rounds > 0) {
          _openRounds -= b.rounds;
          totalUnitsBeforeBatch += uint80(b.rounds) * b.unitPerRound;
        }

        b = _batches[part.batchNo];

        if (totalUnitsBeforeBatch != b.totalUnitsBeforeBatch) {
          b.totalUnitsBeforeBatch = totalUnitsBeforeBatch;
          params.batchUpdated = true;
        }

        if (amount == 0) break;
        if (!b.isReady()) {
          return (amount, loopLimit, b);
        }
      } else {
        _updateTimeMark(part, b.unitPerRound);

        uint256 maxRoundCoverage = uint256(_unitSize) * b.unitPerRound;
        uint256 n = amount / maxRoundCoverage;

        uint24 vacantRounds = b.rounds - part.roundNo;
        Sanity.require(vacantRounds > 0);

        if (n < vacantRounds) {
          // params.unitsCovered += n * b.unitPerRound;
          part.roundNo += uint24(n);
          part.roundCoverage = uint128(amount - maxRoundCoverage * n);
          amount = 0;
          break;
        }

        // params.unitsCovered += vacantRounds * b.unitPerRound;
        part.roundNo = b.rounds;
        amount -= maxRoundCoverage * vacantRounds;
        if (loopLimit > 0) continue; // make sure to move to the next batch
      }
      if (amount == 0 || loopLimit == 0) {
        break;
      }
    }

    return (amount, loopLimit, b);
  }

  /// @dev Sets the values of premium to include the partial batch b
  function _addPartialToTotalPremium(
    uint64 batchNo,
    Rounds.CoveragePremium memory premium,
    Rounds.Batch memory b
  ) internal view {
    (premium.coveragePremium, premium.coveragePremiumRate, premium.lastUpdatedAt) = _calcPremium(
      Rounds.Demand(batchNo, 0, 0, 1),
      premium,
      b.rounds,
      0,
      b.roundPremiumRateSum,
      b.unitPerRound
    );
  }

  function _initTimeMark(uint64 batchNo) private {
    // NB! this moves some of gas costs from addCoverage to addCoverageDemand
    _marks[batchNo].timestamp = 1;
  }

  /// @dev Updates the timeMark for the partial batch which calculates the "area under the curve"
  /// of the coverage curve over time
  function _updateTimeMark(PartialState memory part, uint256 batchUnitPerRound) private {
    // console.log('==updateTimeMark', part.batchNo);
    Sanity.require(part.batchNo != 0);
    TimeMark memory mark = _marks[part.batchNo];

    if (mark.timestamp <= 1) {
      mark.coverageTW = 0;
      mark.duration = 0;
    } else {
      uint32 duration = uint32(block.timestamp - mark.timestamp);
      if (duration == 0) return;

      uint256 coverageTW = mark.coverageTW + (uint256(_unitSize) * part.roundNo * batchUnitPerRound + part.roundCoverage) * duration;
      Value.require(coverageTW == (mark.coverageTW = uint192(coverageTW)));

      mark.duration += duration;
    }
    mark.timestamp = uint32(block.timestamp);

    _marks[part.batchNo] = mark;
  }

  struct Dump {
    uint64 batchCount;
    uint64 latestBatch;
    /// @dev points to an earliest round that is open, can be zero when all rounds are full
    uint64 firstOpenBatch;
    PartialState part;
    Rounds.Batch[] batches;
  }

  /// @dev Return coverage and premium information for an insured
  function _dumpInsured(address insured)
    internal
    view
    returns (
      Rounds.InsuredEntry memory,
      Rounds.Demand[] memory,
      Rounds.Coverage memory,
      Rounds.CoveragePremium memory
    )
  {
    return (_insureds[insured], _demands[insured], _covered[insured], _premiums[insured]);
  }

  /// @return dump The current state of the batches of the system
  function _dump() internal view returns (Dump memory dump) {
    dump.batchCount = _batchCount;
    dump.latestBatch = _latestBatchNo;
    dump.firstOpenBatch = _firstOpenBatchNo;
    dump.part = _partial;
    uint64 j = 0;
    for (uint64 i = dump.part.batchNo; i > 0; i = _batches[i].nextBatchNo) {
      j++;
    }
    dump.batches = new Rounds.Batch[](j);
    j = 0;
    for (uint64 i = dump.part.batchNo; i > 0; ) {
      Rounds.Batch memory b = _batches[i];
      i = b.nextBatchNo;
      dump.batches[j++] = b;
    }
  }

  /// @return If coverage can be added to the partial state
  function internalCanAddCoverage() internal view returns (bool) {
    uint64 batchNo = _partial.batchNo;
    return batchNo != 0 && (_partial.roundCoverage > 0 || _batches[batchNo].state.isReady());
  }

  struct CancelCoverageDemandParams {
    uint256 loopLimit;
    address insured;
    bool done;
    // temp var
    uint80 totalUnitsBeforeBatch;
    // result
    uint256[] rateBands;
  }

  /// @dev Try to cancel `unitCount` units of coverage demand
  /// @return The amount of units that were cancelled
  function internalCancelCoverageDemand(uint64 unitCount, CancelCoverageDemandParams memory params) internal returns (uint64) {
    Rounds.InsuredEntry storage entry = _insureds[params.insured];
    Access.require(entry.status == MemberStatus.Accepted);

    _removeFromPullable(params.insured, entry.nextBatchNo);

    if (unitCount == 0 || params.loopLimit == 0 || entry.demandedUnits == _covered[params.insured].coveredUnits) {
      return 0;
    }

    Rounds.Demand[] storage demands = _demands[params.insured];

    (uint256 index, uint64 batchNo, uint256 skippedRounds, Rounds.Demand memory demand, uint64 cancelledUnits) = _findAndAdjustUncovered(
      unitCount,
      demands,
      params
    );

    if (cancelledUnits == 0) {
      return 0;
    }

    entry.nextBatchNo = batchNo;
    entry.demandedUnits -= cancelledUnits;

    uint24 cancelFirstSlotRounds = uint24(demand.rounds - skippedRounds);
    Sanity.require(cancelFirstSlotRounds > 0);

    demand.rounds = uint24(skippedRounds);

    (batchNo, params.totalUnitsBeforeBatch) = _adjustUncoveredBatches(
      batchNo,
      cancelFirstSlotRounds,
      _batches[batchNo].totalUnitsBeforeBatch,
      demand
    );

    _adjustUncoveredSlots(batchNo, uint80(cancelFirstSlotRounds) * demand.unitPerRound, demands, index + 1, params);

    uint256 bandCount = 0;
    for (uint256 i = demands.length - 1; i > index; i--) {
      bandCount = _addToRateBand(params, bandCount, demands[i]);
      demands.pop();
    }

    if (demand.rounds == 0) {
      bandCount = _addToRateBand(params, bandCount, demands[index]);
      demands.pop();
    } else {
      bandCount = _addToRateBand(params, bandCount, demand.premiumRate, uint64(demands[index].rounds - demand.rounds) * demand.unitPerRound);
      demands[index] = demand;
    }
    Sanity.require(bandCount == params.rateBands.length);

    return cancelledUnits;
  }

  function _addToRateBand(
    CancelCoverageDemandParams memory params,
    uint256 bandCount,
    Rounds.Demand storage d
  ) private view returns (uint256) {
    return _addToRateBand(params, bandCount, d.premiumRate, uint64(d.unitPerRound) * d.rounds);
  }

  function _addToRateBand(
    CancelCoverageDemandParams memory params,
    uint256 bandCount,
    uint40 rate,
    uint64 units
  ) private pure returns (uint256) {
    if (bandCount > 0) {
      uint256 bandRate = params.rateBands[bandCount - 1] >> (256 - Rounds.DEMAND_RATE_BITS);
      if (bandRate == rate) {
        params.rateBands[bandCount - 1] += units;
        return bandCount;
      }
    }

    params.rateBands[bandCount] = (uint256(rate) << (256 - Rounds.DEMAND_RATE_BITS)) + units;
    return bandCount + 1;
  }

  /// @dev Remove coverage demand from batches
  function _findAndAdjustUncovered(
    uint64 unitCount,
    Rounds.Demand[] storage demands,
    CancelCoverageDemandParams memory params
  )
    private
    returns (
      uint256 index,
      uint64 batchNo,
      uint256 skippedRounds,
      Rounds.Demand memory demand,
      uint64 cancelledUnits
    )
  {
    PartialState memory part = _partial;
    uint256 rateBands;

    for (index = demands.length; index > 0 && params.loopLimit > 0; params.loopLimit--) {
      index--;

      Rounds.Demand memory prev = demand;
      demand = demands[index];
      if (prev.premiumRate != demand.premiumRate) {
        rateBands++;
      }

      uint64 cancelUnits;
      (params.done, batchNo, cancelUnits, skippedRounds) = _findUncoveredBatch(part, demand, unitCount - cancelledUnits);

      cancelledUnits += cancelUnits;
      if (params.done) {
        if (skippedRounds == demand.rounds) {
          // the whole demand slot was skipped, so use the previous one
          Sanity.require(cancelUnits == 0);
          index++;
          demand = prev;
          batchNo = prev.startBatchNo;
          skippedRounds = 0;
        }
        break;
      }

      Sanity.require(skippedRounds == 0);
    }

    params.rateBands = new uint256[](rateBands);
  }

  /// @dev Find the batch to remove coverage demand from
  function _findUncoveredBatch(
    PartialState memory part,
    Rounds.Demand memory demand,
    uint256 unitCount
  )
    private
    returns (
      bool done,
      uint64 batchNo,
      uint64 cancelUnits,
      uint256 skippedRounds
    )
  {
    batchNo = demand.startBatchNo;

    uint256 partialRounds;
    if (batchNo == part.batchNo) {
      done = true;
    } else if (_batches[batchNo].state.isFull()) {
      for (;;) {
        Rounds.Batch storage batch = _batches[batchNo];
        skippedRounds += batch.rounds;
        if (skippedRounds >= demand.rounds) {
          Sanity.require(skippedRounds == demand.rounds);
          return (true, batchNo, 0, skippedRounds);
        }
        batchNo = batch.nextBatchNo;
        if (batchNo == part.batchNo) {
          break;
        }
      }
      done = true;
    }
    if (done) {
      partialRounds = part.roundCoverage == 0 ? part.roundNo : part.roundNo + 1;
    }

    uint256 neededRounds = (uint256(unitCount) + demand.unitPerRound - 1) / demand.unitPerRound;

    if (demand.rounds <= skippedRounds + partialRounds + neededRounds) {
      // we should cancel all demands of this slot
      if (partialRounds > 0) {
        // the partial batch can alway be split
        batchNo = _splitBatch(uint24(partialRounds), batchNo);
        skippedRounds += partialRounds;
      }
      neededRounds = demand.rounds - skippedRounds;
    } else {
      // there is more demand in this slot than needs to be cancelled
      // so some batches may be skipped
      done = true;
      uint256 excessRounds = uint256(demand.rounds) - skippedRounds - neededRounds;

      for (; excessRounds > 0; ) {
        Rounds.Batch storage batch = _batches[batchNo];

        uint24 rounds = batch.rounds;
        if (rounds > excessRounds) {
          uint24 remainingRounds;
          unchecked {
            remainingRounds = rounds - uint24(excessRounds);
          }
          if (batchNo == part.batchNo || internalCanSplitBatchOnCancel(batchNo, remainingRounds)) {
            // partial batch can always be split, otherwise the policy decides
            batchNo = _splitBatch(remainingRounds, batchNo);
          } else {
            // cancel more than actually requested to avoid fragmentation of batches
            neededRounds += remainingRounds;
          }
          break;
        } else {
          skippedRounds += rounds;
          excessRounds -= rounds;
          batchNo = batch.nextBatchNo;
        }
      }
    }
    cancelUnits = uint64(neededRounds * demand.unitPerRound);
  }

  function internalCanSplitBatchOnCancel(uint64 batchNo, uint24 remainingRounds) internal view virtual returns (bool) {}

  function _adjustUncoveredSlots(
    uint64 batchNo,
    uint80 totalUnitsAdjustment,
    Rounds.Demand[] storage demands,
    uint256 startFrom,
    CancelCoverageDemandParams memory params
  ) private {
    uint256 maxIndex = demands.length;

    for (uint256 i = startFrom; i < maxIndex; i++) {
      Rounds.Demand memory d = demands[i];
      if (d.startBatchNo != batchNo) {
        params.totalUnitsBeforeBatch = _batches[d.startBatchNo].totalUnitsBeforeBatch;
        if (params.totalUnitsBeforeBatch > totalUnitsAdjustment) {
          params.totalUnitsBeforeBatch -= totalUnitsAdjustment;
        } else {
          params.totalUnitsBeforeBatch = 0;
        }
      }
      (batchNo, params.totalUnitsBeforeBatch) = _adjustUncoveredBatches(d.startBatchNo, d.rounds, params.totalUnitsBeforeBatch, d);
      totalUnitsAdjustment += uint80(d.rounds) * d.unitPerRound;
    }

    if (totalUnitsAdjustment > 0) {
      _pendingCancelledDemandUnits += totalUnitsAdjustment;
    }
  }

  function _adjustUncoveredBatches(
    uint64 batchNo,
    uint256 rounds,
    uint80 totalUnitsBeforeBatch,
    Rounds.Demand memory demand
  ) private returns (uint64, uint80) {
    for (; rounds > 0; ) {
      Rounds.Batch storage batch = _batches[batchNo];
      (uint24 br, uint16 bupr) = (batch.rounds, batch.unitPerRound);
      rounds -= br;
      if (bupr == demand.unitPerRound) {
        (batch.rounds, batch.roundPremiumRateSum, bupr) = (0, 0, 0);
        _openRounds -= br;
      } else {
        bupr -= demand.unitPerRound;
        batch.roundPremiumRateSum -= uint56(demand.unitPerRound) * demand.premiumRate;
      }

      batch.unitPerRound = bupr;
      batch.totalUnitsBeforeBatch = totalUnitsBeforeBatch;

      totalUnitsBeforeBatch += uint80(br) * bupr;

      if (batch.state == Rounds.State.Ready) {
        batch.state = Rounds.State.ReadyMin;
      }

      batchNo = batch.nextBatchNo;
    }
    return (batchNo, totalUnitsBeforeBatch);
  }

  function internalGetUnadjustedUnits()
    internal
    view
    returns (
      uint256 total,
      uint256 pendingCovered,
      uint256 pendingDemand
    )
  {
    Rounds.Batch storage b = _batches[_partial.batchNo];
    return (uint256(b.totalUnitsBeforeBatch) + _partial.roundNo * b.unitPerRound, _pendingCancelledCoverageUnits, _pendingCancelledDemandUnits);
  }

  function internalApplyAdjustmentsToTotals() internal {
    uint80 totals = _pendingCancelledCoverageUnits;
    if (totals == 0 && _pendingCancelledDemandUnits == 0) {
      return;
    }
    (_pendingCancelledCoverageUnits, _pendingCancelledDemandUnits) = (0, 0);

    uint64 batchNo = _partial.batchNo;
    totals = _batches[batchNo].totalUnitsBeforeBatch - totals;

    for (; batchNo > 0; ) {
      Rounds.Batch storage b = _batches[batchNo];
      b.totalUnitsBeforeBatch = totals;
      totals += uint80(b.rounds) * b.unitPerRound;
      batchNo = b.nextBatchNo;
    }
  }

  error DemandMustBeCancelled();

  /// @dev Cancel ALL coverage for the insured, including in the partial state
  /// @dev Deletes the coverage information and demands of the insured
  /// @return coverage The coverage info of the insured. IS FINALIZED
  /// @return excessCoverage The new amount of excess coverage
  /// @return providedCoverage Amount of coverage provided before cancellation
  /// @return receivedCoverage Amount of coverage received from the sync before cancelling
  function internalCancelCoverage(address insured)
    internal
    returns (
      DemandedCoverage memory coverage,
      uint256 excessCoverage,
      uint256 providedCoverage,
      uint256 receivedCoverage,
      uint256 receivedPremium
    )
  {
    Rounds.InsuredEntry storage entry = _insureds[insured];

    if (entry.demandedUnits == 0) {
      return (coverage, 0, 0, 0, 0);
    }
    _removeFromPullable(insured, entry.nextBatchNo);

    Rounds.Coverage memory covered;
    Rounds.CoveragePremium memory premium;
    (coverage, covered, premium, receivedCoverage, receivedPremium) = _syncBeforeCancelCoverage(insured);

    Rounds.Demand[] storage demands = _demands[insured];
    Rounds.Demand memory d;
    PartialState memory part = _partial;

    if (covered.lastUpdateIndex < demands.length) {
      if (covered.lastUpdateIndex == demands.length - 1 && covered.lastUpdateBatchNo == part.batchNo && covered.lastPartialRoundNo == part.roundNo) {
        d = demands[covered.lastUpdateIndex];
      } else {
        revert DemandMustBeCancelled();
      }
    } else {
      Sanity.require(entry.demandedUnits == covered.coveredUnits);
    }

    providedCoverage = covered.coveredUnits * _unitSize;
    _pendingCancelledCoverageUnits += covered.coveredUnits - uint64(covered.lastPartialRoundNo) * d.unitPerRound;

    if (part.batchNo > 0) {
      _premiums[insured] = _cancelPremium(premium, coverage.totalPremium);
      // ATTN! There MUST be a call to _updateTimeMark AFTER _cancelPremium - this call is inside _cancelPartialCoverage
      excessCoverage = _cancelPartialCoverage(part, d);
    }

    entry.demandedUnits = 0;
    entry.nextBatchNo = 0;
    delete (_covered[insured]);
    delete (_demands[insured]);
  }

  /// @dev Sync the insured's amount of coverage and premium paid
  /// @return coverage FINAZLIED coverage amounts ONLY for the insured
  /// @return covered Updated coverage info from sync
  /// @return premium Total premium collected and rate after sync
  /// @return receivedCoverage FINALIZED amount of covered units during this sync
  function _syncBeforeCancelCoverage(address insured)
    private
    view
    returns (
      DemandedCoverage memory coverage,
      Rounds.Coverage memory covered,
      Rounds.CoveragePremium memory premium,
      uint256 receivedCoverage,
      uint256 receivedPremium
    )
  {
    GetCoveredDemandParams memory params;
    params.insured = insured;
    params.loopLimit = ~uint256(0);

    (coverage, covered, premium) = internalGetCoveredDemand(params);
    Sanity.require(params.done);

    receivedCoverage = params.receivedCoverage;
    receivedPremium = params.receivedPremium;
  }

  /// @dev Cancel coverage in the partial state
  /// @return excessCoverage The new amount of excess coverage
  function _cancelPartialCoverage(PartialState memory part, Rounds.Demand memory d) private returns (uint128 excessCoverage) {
    Rounds.Batch storage partBatch = _batches[part.batchNo];
    Rounds.Batch memory b = partBatch;

    // Call to _updateTimeMark is MUST, because of _cancelPremium updating _poolPremium's timestamp
    _updateTimeMark(part, b.unitPerRound);

    if (d.unitPerRound == 0) {
      return 0;
    }
    Sanity.require(d.unitPerRound <= b.unitPerRound);

    {
      TimeMark storage mark = _marks[part.batchNo];
      uint192 coverageTW = mark.coverageTW;
      if (coverageTW > 0) {
        // reduce the integral summ proportionally - the relevant part was added to finalPremium already
        uint256 delta = _calcTimeMarkPortion(coverageTW, d.unitPerRound, b.unitPerRound);
        mark.coverageTW = uint192(coverageTW - delta);
      }
    }

    (partBatch.unitPerRound, partBatch.roundPremiumRateSum) = (
      b.unitPerRound -= d.unitPerRound,
      b.roundPremiumRateSum - uint56(d.premiumRate) * d.unitPerRound
    );

    if (b.unitPerRound == 0) {
      excessCoverage = part.roundCoverage;
      _partial.roundCoverage = part.roundCoverage = 0;
      _partial.roundNo = part.roundNo = 0;
    } else if (part.roundCoverage > 0) {
      excessCoverage = uint128(_unitSize) * b.unitPerRound;

      if (part.roundCoverage > excessCoverage) {
        (part.roundCoverage, excessCoverage) = (excessCoverage, part.roundCoverage - excessCoverage);
        _partial.roundCoverage = part.roundCoverage;
      }
    }
  }

  /// @dev Update the premium based on time elapsed and premium rate
  function _syncPremium(Rounds.CoveragePremium memory premium) private view returns (Rounds.CoveragePremium memory) {
    if (premium.lastUpdatedAt != 0) {
      premium.coveragePremium += uint96(premium.coveragePremiumRate) * (uint32(block.timestamp) - premium.lastUpdatedAt);
    }
    premium.lastUpdatedAt = uint32(block.timestamp);
    return premium;
  }

  /// @dev Cancel premium according to the parameters, and adjust the global pool's premium rate
  /// @param premium The premium info of the insured
  /// @param finalPremium The REAL amount of premium collected from the insured (multiplied by unitSize)
  /// @return A new CoveragePremium struct with the rate set to 0
  function _cancelPremium(Rounds.CoveragePremium memory premium, uint256 finalPremium) private returns (Rounds.CoveragePremium memory) {
    Rounds.CoveragePremium memory poolPremium = _syncPremium(_poolPremium);

    finalPremium = finalPremium.wadDiv(_unitSize).asUint96();

    poolPremium.coveragePremiumRate -= premium.coveragePremiumRate;
    poolPremium.coveragePremium += uint96(finalPremium - premium.coveragePremium);

    if (premium.lastUpdatedAt != poolPremium.lastUpdatedAt) {
      // avoid double-counting when premiuns are not synced
      poolPremium.coveragePremium -= uint96(premium.coveragePremiumRate) * (poolPremium.lastUpdatedAt - premium.lastUpdatedAt);
    }

    _poolPremium = poolPremium;

    return Rounds.CoveragePremium({coveragePremiumRate: 0, coveragePremium: uint96(finalPremium), lastUpdatedAt: poolPremium.lastUpdatedAt});
  }

  function _addToPullable(address insured, uint64 batchNo) private {
    _pullableDemands[batchNo].add(insured);
  }

  function _removeFromPullable(address insured, uint64 batchNo) private {
    _pullableDemands[batchNo].remove(insured);
  }

  function internalPullDemandCandidate(uint256 loopLimit, bool trimOnly) internal returns (address insured, uint256) {
    uint64 batchNo;
    uint64 pullableBatchNo = batchNo = _pullableBatchNo;
    if (batchNo == 0) {
      batchNo = 1;
    }

    for (; loopLimit > 0; ) {
      loopLimit--;

      Rounds.Batch storage batch = _batches[batchNo];
      if (!batch.state.isFull()) {
        break;
      }

      EnumerableSet.AddressSet storage demands = _pullableDemands[batchNo];
      for (uint256 n = demands.length(); n > 0; ) {
        n--;
        insured = demands.at(n);
        if (_insureds[insured].status == MemberStatus.Accepted) {
          if (!trimOnly) {
            demands.remove(insured);
          }
          break;
        }
        demands.remove(insured);
        insured = address(0);
        if (loopLimit == 0) {
          break;
        }
        loopLimit--;
      }
      if (insured != address(0)) {
        break;
      }

      uint64 nextBatchNo = batch.nextBatchNo;
      if (nextBatchNo == 0) {
        break;
      }
      batchNo = nextBatchNo;
    }

    if (pullableBatchNo != batchNo) {
      _pullableBatchNo = batchNo;
    }

    return (insured, loopLimit);
  }

  function internalOpenBatchRounds() internal view returns (uint256) {
    return _batches[_firstOpenBatchNo].rounds;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/introspection/ERC165Checker.sol';
import '../tools/math/PercentageMath.sol';
import '../tools/math/WadRayMath.sol';
import '../tools/math/Math.sol';
import '../governance/interfaces/IInsurerGovernor.sol';
import '../governance/GovernedHelper.sol';
import './InsurerJoinBase.sol';

abstract contract WeightedPoolAccessControl is GovernedHelper, InsurerJoinBase {
  using PercentageMath for uint256;

  address private _governor;
  bool private _governorIsContract;

  function _onlyActiveInsured(address insurer) internal view {
    Access.require(internalGetStatus(insurer) == MemberStatus.Accepted);
  }

  function _onlyInsured(address insurer) private view {
    Access.require(internalGetStatus(insurer) > MemberStatus.Unknown);
  }

  modifier onlyActiveInsured() {
    _onlyActiveInsured(msg.sender);
    _;
  }

  modifier onlyInsured() {
    _onlyInsured(msg.sender);
    _;
  }

  function _onlyActiveInsuredOrOps(address insured) private view {
    if (insured != msg.sender) {
      _onlyGovernorOr(AccessFlags.INSURER_OPS);
    }
    _onlyActiveInsured(insured);
  }

  modifier onlyActiveInsuredOrOps(address insured) {
    _onlyActiveInsuredOrOps(insured);
    _;
  }

  function internalSetTypedGovernor(IInsurerGovernor addr) internal {
    _governorIsContract = true;
    _setGovernor(address(addr));
  }

  function internalSetGovernor(address addr) internal virtual {
    // will also return false for EOA
    _governorIsContract = ERC165Checker.supportsInterface(addr, type(IInsurerGovernor).interfaceId);
    _setGovernor(addr);
  }

  function governorContract() internal view virtual returns (IInsurerGovernor) {
    return IInsurerGovernor(_governorIsContract ? governorAccount() : address(0));
  }

  function isAllowedByGovernor(address account, uint256 flags) internal view override returns (bool) {
    return _governorIsContract && IInsurerGovernor(governorAccount()).governerQueryAccessControlMask(account, flags) & flags != 0;
  }

  function internalInitiateJoin(address insured) internal override returns (MemberStatus) {
    IJoinHandler jh = governorContract();
    if (address(jh) == address(0)) {
      IApprovalCatalog c = approvalCatalog();
      Access.require(address(c) == address(0) || c.hasApprovedApplication(insured));
      return MemberStatus.Joining;
    } else {
      return jh.handleJoinRequest(insured);
    }
  }

  event GovernorUpdated(address);

  function _setGovernor(address addr) internal {
    emit GovernorUpdated(_governor = addr);
  }

  function governorAccount() internal view override returns (address) {
    return _governor;
  }

  function internalVerifyPayoutRatio(
    address insured,
    uint256 payoutRatio,
    bool enforcedCancel
  ) internal virtual returns (uint256 approvedPayoutRatio) {
    IInsurerGovernor jh = governorContract();
    if (address(jh) == address(0)) {
      IApprovalCatalog c = approvalCatalog();
      if (address(c) == address(0)) {
        return payoutRatio;
      }

      if (!enforcedCancel || c.hasApprovedClaim(insured)) {
        IApprovalCatalog.ApprovedClaim memory info = c.applyApprovedClaim(insured);

        Access.require(enforcedCancel || info.since <= block.timestamp);
        approvedPayoutRatio = WadRayMath.RAY.percentMul(info.payoutRatio);
      }
      // else approvedPayoutRatio = 0 (for enfoced calls without an approved claim)
    } else if (!enforcedCancel || payoutRatio > 0) {
      approvedPayoutRatio = jh.verifyPayoutRatio(insured, payoutRatio);
    }

    if (payoutRatio < approvedPayoutRatio) {
      approvedPayoutRatio = payoutRatio;
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

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
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
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

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../Errors.sol';

/// @dev Provides mul and div function for wads (decimal numbers with 18 digits precision) and rays (decimals with 27 digits)
library WadRayMath {
  uint256 internal constant WAD = 1e18;
  uint256 internal constant halfWAD = WAD / 2;

  uint256 internal constant RAY = 1e27;
  uint256 internal constant halfRAY = RAY / 2;

  uint256 internal constant WAD_RAY_RATIO = 1e9;
  uint256 private constant halfRatio = WAD_RAY_RATIO / 2;

  /// @return One ray, 1e27
  function ray() internal pure returns (uint256) {
    return RAY;
  }

  /// @return One wad, 1e18
  function wad() internal pure returns (uint256) {
    return WAD;
  }

  /// @return Half ray, 1e27/2
  function halfRay() internal pure returns (uint256) {
    return halfRAY;
  }

  /// @return Half ray, 1e18/2
  function halfWad() internal pure returns (uint256) {
    return halfWAD;
  }

  /// @dev Multiplies two wad, rounding half up to the nearest wad
  function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }
    return (a * b + halfWAD) / WAD;
  }

  /// @dev Multiplies two wad, rounding half up to the nearest wad
  function wadMulUp(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }
    return (a * b + WAD - 1) / WAD;
  }

  /// @dev Divides two wad, rounding half up to the nearest wad
  function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    return (a * WAD + b / 2) / b;
  }

  function divUp(uint256 a, uint256 b) internal pure returns (uint256) {
    return (a + b / 2) / b;
  }

  /// @dev Multiplies two ray, rounding half up to the nearest ray
  function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }
    return (a * b + halfRAY) / RAY;
  }

  /// @dev Divides two ray, rounding half up to the nearest ray
  function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    return (a * RAY + b / 2) / b;
  }

  /// @dev Casts ray down to wad
  function rayToWad(uint256 a) internal pure returns (uint256) {
    return (a + halfRatio) / WAD_RAY_RATIO;
  }

  /// @dev Converts wad up to ray
  function wadToRay(uint256 a) internal pure returns (uint256) {
    return a * WAD_RAY_RATIO;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.10;

import '../Errors.sol';

library Math {
  function boundedSub(uint256 x, uint256 y) internal pure returns (uint256) {
    unchecked {
      return x < y ? 0 : x - y;
    }
  }

  function boundedSub2(uint256 x, uint256 y) internal pure returns (uint256, uint256) {
    unchecked {
      return x < y ? (uint256(0), y - x) : (x - y, 0);
    }
  }

  function addAbsDelta(
    uint256 x,
    uint256 y,
    uint256 z
  ) internal pure returns (uint256) {
    return y > z ? x + y - z : x + z - y;
  }

  function checkAssign(uint256 v, uint256 ref) internal pure {
    if (v != ref) {
      Errors.overflow();
    }
  }

  function asUint224(uint256 x) internal pure returns (uint224 v) {
    checkAssign(v = uint224(x), x);
    return v;
  }

  function asUint216(uint256 x) internal pure returns (uint216 v) {
    checkAssign(v = uint216(x), x);
    return v;
  }

  function asUint128(uint256 x) internal pure returns (uint128 v) {
    checkAssign(v = uint128(x), x);
    return v;
  }

  function asUint112(uint256 x) internal pure returns (uint112 v) {
    checkAssign(v = uint112(x), x);
    return v;
  }

  function asUint96(uint256 x) internal pure returns (uint96 v) {
    checkAssign(v = uint96(x), x);
    return v;
  }

  function asUint88(uint256 x) internal pure returns (uint88 v) {
    checkAssign(v = uint88(x), x);
    return v;
  }

  function asUint64(uint256 x) internal pure returns (uint64 v) {
    checkAssign(v = uint64(x), x);
    return v;
  }

  function asUint32(uint256 x) internal pure returns (uint32 v) {
    checkAssign(v = uint32(x), x);
    return v;
  }

  function asInt128(uint256 x) internal pure returns (int128 v) {
    checkAssign(uint128(v = int128(uint128(x))), x);
    return v;
  }

  function checkAdd(uint256 result, uint256 added) internal pure {
    if (result < added) {
      Errors.overflow();
    }
  }

  function overflowBits(uint256 value, uint256 bits) internal pure {
    if (value >> bits != 0) {
      Errors.overflow();
    }
  }

  function sqrt(uint256 y) internal pure returns (uint256 z) {
    if (y > 3) {
      z = y;
      uint256 x = (y >> 1) + 1;
      while (x < z) {
        z = x;
        x = (y / x + x) >> 1;
      }
    } else if (y != 0) {
      z = 1;
    }
  }

  // @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
  /// @param a The multiplicand
  /// @param b The multiplier
  /// @param denominator The divisor
  /// @return result The 256-bit result
  /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
  function mulDiv(
    uint256 a,
    uint256 b,
    uint256 denominator
  ) internal pure returns (uint256 result) {
    // 512-bit multiply [prod1 prod0] = a * b
    // Compute the product mod 2**256 and mod 2**256 - 1
    // then use the Chinese Remainder Theorem to reconstruct
    // the 512 bit result. The result is stored in two 256
    // variables such that product = prod1 * 2**256 + prod0
    uint256 prod0; // Least significant 256 bits of the product
    uint256 prod1; // Most significant 256 bits of the product

    // solhint-disable no-inline-assembly
    assembly {
      let mm := mulmod(a, b, not(0))
      prod0 := mul(a, b)
      prod1 := sub(sub(mm, prod0), lt(mm, prod0))
    }

    // Handle non-overflow cases, 256 by 256 division
    if (prod1 == 0) {
      Arithmetic.require(denominator > 0);
      assembly {
        result := div(prod0, denominator)
      }
      return result;
    }

    // Make sure the result is less than 2**256.
    // Also prevents denominator == 0
    Arithmetic.require(denominator > prod1);

    ///////////////////////////////////////////////
    // 512 by 256 division.
    ///////////////////////////////////////////////

    // Make division exact by subtracting the remainder from [prod1 prod0]
    // Compute remainder using mulmod
    uint256 remainder;
    assembly {
      remainder := mulmod(a, b, denominator)
    }
    // Subtract 256 bit number from 512 bit number
    assembly {
      prod1 := sub(prod1, gt(remainder, prod0))
      prod0 := sub(prod0, remainder)
    }

    // Factor powers of two out of denominator
    // Compute largest power of two divisor of denominator.
    // Always >= 1.
    unchecked {
      uint256 twos = (type(uint256).max - denominator + 1) & denominator;
      // Divide denominator by power of two
      assembly {
        denominator := div(denominator, twos)
      }

      // Divide [prod1 prod0] by the factors of two
      assembly {
        prod0 := div(prod0, twos)
      }
      // Shift in bits from prod1 into prod0. For this we need
      // to flip `twos` such that it is 2**256 / twos.
      // If twos is zero, then it becomes one
      assembly {
        twos := add(div(sub(0, twos), twos), 1)
      }
      prod0 |= prod1 * twos;

      // Invert denominator mod 2**256
      // Now that denominator is an odd number, it has an inverse
      // modulo 2**256 such that denominator * inv = 1 mod 2**256.
      // Compute the inverse by starting with a seed that is correct
      // correct for four bits. That is, denominator * inv = 1 mod 2**4
      uint256 inv = (3 * denominator) ^ 2;
      // Now use Newton-Raphson iteration to improve the precision.
      // Thanks to Hensel's lifting lemma, this also works in modular
      // arithmetic, doubling the correct bits in each step.
      inv *= 2 - denominator * inv; // inverse mod 2**8
      inv *= 2 - denominator * inv; // inverse mod 2**16
      inv *= 2 - denominator * inv; // inverse mod 2**32
      inv *= 2 - denominator * inv; // inverse mod 2**64
      inv *= 2 - denominator * inv; // inverse mod 2**128
      inv *= 2 - denominator * inv; // inverse mod 2**256

      // Because the division is now exact we can divide by multiplying
      // with the modular inverse of denominator. This will give us the
      // correct result modulo 2**256. Since the precoditions guarantee
      // that the outcome is less than 2**256, this is the final result.
      // We don't need to compute the high bits of the result and prod1
      // is no longer required.
      result = prod0 * inv;
      return result;
    }
    // solhint-enable no-inline-assembly
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../../interfaces/IJoinHandler.sol';
import './IApprovalCatalog.sol';

interface IInsurerGovernor is IJoinHandler {
  function governerQueryAccessControlMask(address subject, uint256 filterMask) external view returns (uint256);

  function verifyPayoutRatio(address insured, uint256 payoutRatio) external returns (uint256);

  function getApprovedPolicyForInsurer(address insured) external returns (bool ok, IApprovalCatalog.ApprovedPolicyForInsurer memory data);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../tools/Errors.sol';
import '../interfaces/IProxyFactory.sol';
import '../funds/Collateralized.sol';
import '../access/AccessHelper.sol';
import './interfaces/IApprovalCatalog.sol';

abstract contract GovernedHelper is AccessHelper, Collateralized {
  constructor(IAccessController acl, address collateral_) AccessHelper(acl) Collateralized(collateral_) {}

  function _onlyGovernorOr(uint256 flags) internal view {
    Access.require(_isAllowed(flags) || hasAnyAcl(msg.sender, flags));
  }

  function _onlyGovernor() private view {
    Access.require(governorAccount() == msg.sender);
  }

  function _isAllowed(uint256 flags) private view returns (bool) {
    return governorAccount() == msg.sender || isAllowedByGovernor(msg.sender, flags);
  }

  function isAllowedByGovernor(address account, uint256 flags) internal view virtual returns (bool) {}

  modifier onlyGovernorOr(uint256 flags) {
    _onlyGovernorOr(flags);
    _;
  }

  modifier onlyGovernor() {
    _onlyGovernor();
    _;
  }

  function _onlySelf() private view {
    Access.require(msg.sender == address(this));
  }

  modifier onlySelf() {
    _onlySelf();
    _;
  }

  function governorAccount() internal view virtual returns (address);

  function approvalCatalog() internal view returns (IApprovalCatalog) {
    return IApprovalCatalog(getAclAddress(AccessFlags.APPROVAL_CATALOG));
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../insurer/Rounds.sol';

interface IJoinHandler {
  function handleJoinRequest(address) external returns (MemberStatus);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IApprovalCatalog {
  struct ApprovedPolicy {
    bytes32 requestCid;
    bytes32 approvalCid;
    address insured;
    uint16 riskLevel;
    uint80 basePremiumRate;
    string policyName;
    string policySymbol;
    address premiumToken;
    uint96 minPrepayValue;
    uint32 rollingAdvanceWindow;
    uint32 expiresAt;
    bool applied;
  }

  struct ApprovedPolicyForInsurer {
    uint16 riskLevel;
    uint80 basePremiumRate;
    address premiumToken;
  }

  function hasApprovedApplication(address insured) external view returns (bool);

  function getApprovedApplication(address insured) external view returns (ApprovedPolicy memory);

  function applyApprovedApplication() external returns (ApprovedPolicy memory);

  function getAppliedApplicationForInsurer(address insured) external view returns (bool valid, ApprovedPolicyForInsurer memory data);

  struct ApprovedClaim {
    bytes32 requestCid;
    bytes32 approvalCid;
    uint16 payoutRatio;
    uint32 since;
  }

  function hasApprovedClaim(address insured) external view returns (bool);

  function getApprovedClaim(address insured) external view returns (ApprovedClaim memory);

  function applyApprovedClaim(address insured) external returns (ApprovedClaim memory);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IProxyFactory {
  function isAuthenticProxy(address proxy) external view returns (bool);

  function createProxy(
    address adminAddress,
    bytes32 implName,
    address context,
    bytes calldata params
  ) external returns (address);

  function createProxyWithImpl(
    address adminAddress,
    bytes32 implName,
    address impl,
    bytes calldata params
  ) external returns (address);

  function upgradeProxy(address proxyAddress, bytes calldata params) external returns (bool);

  function upgradeProxyWithImpl(
    address proxyAddress,
    address newImpl,
    bool checkRevision,
    bytes calldata params
  ) external returns (bool);

  event ProxyCreated(address indexed proxy, address indexed impl, string typ, bytes params, address indexed admin);
  event ProxyUpdated(address indexed proxy, address indexed impl, string typ, bytes params);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../tools/Errors.sol';
import '../tools/tokens/IERC20.sol';
import '../interfaces/IManagedCollateralCurrency.sol';
import '../interfaces/ICollateralized.sol';

abstract contract Collateralized is ICollateralized {
  address private immutable _collateral;

  constructor(address collateral_) {
    _collateral = collateral_;
  }

  function collateral() public view virtual override returns (address) {
    return _collateral;
  }

  function _onlyCollateralCurrency() private view {
    Access.require(msg.sender == _collateral);
  }

  modifier onlyCollateralCurrency() {
    _onlyCollateralCurrency();
    _;
  }

  function _onlyLiquidityProvider() private view {
    Access.require(IManagedCollateralCurrency(_collateral).isLiquidityProvider(msg.sender));
  }

  modifier onlyLiquidityProvider() {
    _onlyLiquidityProvider();
    _;
  }

  function transferCollateral(address recipient, uint256 amount) internal {
    // collateral is a trusted token, hence we do not use safeTransfer here
    ensureTransfer(IERC20(collateral()).transfer(recipient, amount));
  }

  function balanceOfCollateral(address account) internal view returns (uint256) {
    return IERC20(collateral()).balanceOf(account);
  }

  function transferCollateralFrom(
    address from,
    address recipient,
    uint256 amount
  ) internal {
    // collateral is a trusted token, hence we do not use safeTransfer here
    ensureTransfer(IERC20(collateral()).transferFrom(from, recipient, amount));
  }

  function transferAvailableCollateralFrom(
    address from,
    address recipient,
    uint256 maxAmount
  ) internal returns (uint256 amount) {
    IERC20 token = IERC20(collateral());
    amount = maxAmount;
    if (amount > (maxAmount = token.allowance(from, address(this)))) {
      if (maxAmount == 0) {
        return 0;
      }
      amount = maxAmount;
    }
    if (amount > (maxAmount = token.balanceOf(from))) {
      if (maxAmount == 0) {
        return 0;
      }
      amount = maxAmount;
    }
    // ensureTransfer(token.transferFrom(from, recipient, amount));
    transferCollateralFrom(from, recipient, amount);
  }

  function ensureTransfer(bool ok) private pure {
    if (!ok) {
      revert Errors.CollateralTransferFailed();
    }
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../tools/Errors.sol';
import '../interfaces/IProxyFactory.sol';
import './interfaces/IAccessController.sol';
import './AccessLib.sol';
import './AccessFlags.sol';

abstract contract AccessHelper {
  using AccessLib for IAccessController;

  IAccessController private immutable _remoteAcl;

  constructor(IAccessController acl) {
    _remoteAcl = acl;
  }

  function remoteAcl() internal view virtual returns (IAccessController) {
    return _remoteAcl;
  }

  function hasRemoteAcl() internal view returns (bool) {
    return address(remoteAcl()) != address(0);
  }

  function isAdmin(address addr) internal view virtual returns (bool) {
    IAccessController acl = remoteAcl();
    return (address(acl) != address(0)) && acl.isAdmin(addr);
  }

  function owner() public view returns (address) {
    IAccessController acl = remoteAcl();
    return address(acl) != address(0) ? acl.owner() : address(0);
  }

  function _onlyAdmin() private view {
    Access.require(isAdmin(msg.sender));
  }

  modifier onlyAdmin() {
    _onlyAdmin();
    _;
  }

  function hasAnyAcl(address subject, uint256 flags) internal view virtual returns (bool) {
    return remoteAcl().hasAnyOf(subject, flags);
  }

  function hasAllAcl(address subject, uint256 flags) internal view virtual returns (bool) {
    return remoteAcl().hasAllOf(subject, flags);
  }

  function _requireAnyFor(address subject, uint256 flags) private view {
    Access.require(hasAnyAcl(subject, flags));
  }

  function _requireAllFor(address subject, uint256 flags) private view {
    Access.require(hasAllAcl(subject, flags));
  }

  modifier aclHas(uint256 flags) {
    _requireAnyFor(msg.sender, flags);
    _;
  }

  modifier aclHasAny(uint256 flags) {
    _requireAnyFor(msg.sender, flags);
    _;
  }

  modifier aclHasAll(uint256 flags) {
    _requireAllFor(msg.sender, flags);
    _;
  }

  modifier aclHasAnyFor(address subject, uint256 flags) {
    _requireAnyFor(subject, flags);
    _;
  }

  modifier aclHasAllFor(address subject, uint256 flags) {
    _requireAllFor(subject, flags);
    _;
  }

  function _onlyEmergencyAdmin() private view {
    if (!hasAnyAcl(msg.sender, AccessFlags.EMERGENCY_ADMIN)) {
      revert Errors.CallerNotEmergencyAdmin();
    }
  }

  modifier onlyEmergencyAdmin() {
    _onlyEmergencyAdmin();
    _;
  }

  function _onlySweepAdmin() private view {
    if (!hasAnyAcl(msg.sender, AccessFlags.SWEEP_ADMIN)) {
      revert Errors.CallerNotSweepAdmin();
    }
  }

  modifier onlySweepAdmin() {
    _onlySweepAdmin();
    _;
  }

  function getProxyFactory() internal view returns (IProxyFactory) {
    return IProxyFactory(getAclAddress(AccessFlags.PROXY_FACTORY));
  }

  function getAclAddress(uint256 t) internal view returns (address) {
    IAccessController acl = remoteAcl();
    return address(acl) == address(0) ? address(0) : acl.getAddress(t);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../tools/tokens/IERC20.sol';

interface IManagedCollateralCurrency is IERC20 {
  /// @dev regular mint
  function mint(address account, uint256 amount) external;

  /// @dev an optimized combo, equivalent of mint(onBehalf, mintAmount) and then transfers (mintAmount + balanceAmount) from onBehalf to recipient
  /// @dev balanceAmount can be uint256.max to take whole balance
  function mintAndTransfer(
    address onBehalf,
    address recepient,
    uint256 mintAmount,
    uint256 balanceAmount
  ) external;

  function transferOnBehalf(
    address onBehalf,
    address recipient,
    uint256 amount
  ) external;

  function burn(address account, uint256 amount) external;

  function isLiquidityProvider(address account) external view returns (bool);

  function isRegistered(address account) external view returns (bool);

  function borrowManager() external view returns (address); // ICollateralStakeManager
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './IRemoteAccessBitmask.sol';
import '../../tools/upgradeability/IProxy.sol';

/// @dev Main registry of permissions and addresses
interface IAccessController is IRemoteAccessBitmask {
  function getAddress(uint256 id) external view returns (address);

  function isAdmin(address) external view returns (bool);

  function owner() external view returns (address);

  function roleHolders(uint256 id) external view returns (address[] memory addrList);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './interfaces/IRemoteAccessBitmask.sol';

library AccessLib {
  function getAcl(IRemoteAccessBitmask remote, address subject) internal view returns (uint256) {
    return remote.queryAccessControlMask(subject, type(uint256).max);
  }

  function queryAcl(
    IRemoteAccessBitmask remote,
    address subject,
    uint256 filterMask
  ) internal view returns (uint256) {
    return address(remote) != address(0) ? remote.queryAccessControlMask(subject, filterMask) : 0;
  }

  function hasAnyOf(
    IRemoteAccessBitmask remote,
    address subject,
    uint256 flags
  ) internal view returns (bool) {
    return queryAcl(remote, subject, flags) & flags != 0;
  }

  function hasAllOf(
    IRemoteAccessBitmask remote,
    address subject,
    uint256 flags
  ) internal view returns (bool) {
    return flags != 0 && queryAcl(remote, subject, flags) & flags == flags;
  }

  function hasAny(IRemoteAccessBitmask remote, address subject) internal view returns (bool) {
    return address(remote) != address(0) && remote.queryAccessControlMask(subject, 0) != 0;
  }

  function hasNone(IRemoteAccessBitmask remote, address subject) internal view returns (bool) {
    return address(remote) != address(0) && remote.queryAccessControlMask(subject, 0) == 0;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

library AccessFlags {
  // roles that can be assigned to multiple addresses - use range [0..15]
  uint256 public constant EMERGENCY_ADMIN = 1 << 0;
  uint256 public constant TREASURY_ADMIN = 1 << 1;
  uint256 public constant COLLATERAL_FUND_ADMIN = 1 << 2;
  uint256 public constant INSURER_ADMIN = 1 << 3;
  uint256 public constant INSURER_OPS = 1 << 4;

  uint256 public constant PREMIUM_FUND_ADMIN = 1 << 5;

  uint256 public constant SWEEP_ADMIN = 1 << 6;
  uint256 public constant PRICE_ROUTER_ADMIN = 1 << 7;

  uint256 public constant UNDERWRITER_POLICY = 1 << 8;
  uint256 public constant UNDERWRITER_CLAIM = 1 << 9;

  uint256 public constant LP_DEPLOY = 1 << 10;
  uint256 public constant LP_ADMIN = 1 << 11;

  uint256 public constant INSURED_ADMIN = 1 << 12;
  uint256 public constant INSURED_OPS = 1 << 13;
  uint256 public constant BORROWER_ADMIN = 1 << 14;
  uint256 public constant LIQUIDITY_BORROWER = 1 << 15;

  uint256 public constant ROLES = (uint256(1) << 16) - 1;

  // singletons - use range [16..64] - can ONLY be assigned to a single address
  uint256 public constant SINGLETS = ((uint256(1) << 64) - 1) & ~ROLES;

  // protected singletons - use for proxies
  uint256 public constant APPROVAL_CATALOG = 1 << 16;
  uint256 public constant TREASURY = 1 << 17;
  // uint256 public constant COLLATERAL_CURRENCY = 1 << 18;
  uint256 public constant PRICE_ROUTER = 1 << 19;

  uint256 public constant PROTECTED_SINGLETS = ((uint256(1) << 26) - 1) & ~ROLES;

  // non-proxied singletons, numbered down from 31 (as JS has problems with bitmasks over 31 bits)
  uint256 public constant PROXY_FACTORY = 1 << 26;

  uint256 public constant DATA_HELPER = 1 << 28;

  // any other roles - use range [64..]
  // these roles can be assigned to multiple addresses
  uint256 public constant COLLATERAL_FUND_LISTING = 1 << 64; // an ephemeral role - just to keep a list of collateral funds
  uint256 public constant INSURER_POOL_LISTING = 1 << 65; // an ephemeral role - just to keep a list of insurer funds

  uint256 public constant ROLES_EXT = uint256(0x3) << 64;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IRemoteAccessBitmask {
  /**
   * @dev Returns access flags granted to the given address and limited by the filterMask. filterMask == 0 has a special meaning.
   * @param addr an to get access perfmissions for
   * @param filterMask limits a subset of flags to be checked.
   * NB! When filterMask == 0 then zero is returned no flags granted, or an unspecified non-zero value otherwise.
   * @return Access flags currently granted
   */
  function queryAccessControlMask(address addr, uint256 filterMask) external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IProxy {
  function upgradeToAndCall(address newImplementation, bytes calldata data) external payable;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './ICollateralized.sol';

interface IInsuredPool is ICollateralized {
  /// @notice Called by insurer during or after requestJoin() to inform this insured if it was accepted or not
  /// @param accepted true if accepted by the insurer
  function joinProcessed(bool accepted) external;

  /// @notice Invoked by chartered pools to request more coverage demand
  /// @param amount a hint on demand amount, 0 means default
  /// @param loopLimit a max number of iterations
  function pullCoverageDemand(uint256 amount, uint256 loopLimit) external returns (bool);

  /// @notice Get this insured params
  /// @return The insured params
  function insuredParams() external view returns (InsuredParams memory);

  /// @notice Directly offer coverage to the insured
  /// @param offeredAmount The amount of coverage being offered
  /// @return acceptedAmount The amount of coverage accepted by the insured
  /// @return rate The rate that the insured is paying for the coverage
  function offerCoverage(uint256 offeredAmount) external returns (uint256 acceptedAmount, uint256 rate);

  function rateBands() external view returns (InsuredRateBand[] memory bands, uint256 maxBands);

  function getInsurers() external view returns (address[] memory, address[] memory);
}

interface IReconcilableInsuredPool is IInsuredPool {
  function receivableByReconcileWithInsurer(address insurer) external view returns (ReceivableByReconcile memory);
}

struct ReceivableByReconcile {
  uint256 receivableCoverage;
  uint256 demandedCoverage;
  uint256 providedCoverage;
  uint256 rate;
  uint256 accumulated;
}

struct InsuredParams {
  uint128 minPerInsurer;
}

struct InsuredRateBand {
  uint64 premiumRate;
  uint96 coverageDemand;
}