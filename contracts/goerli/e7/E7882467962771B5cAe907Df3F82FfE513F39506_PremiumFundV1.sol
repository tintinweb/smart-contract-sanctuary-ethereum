// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../tools/upgradeability/VersionedInitializable.sol';
import '../interfaces/IPremiumFundInit.sol';
import './PremiumFundBase.sol';

contract PremiumFundV1 is VersionedInitializable, IPremiumFundInit, PremiumFundBase {
  uint256 private constant CONTRACT_REVISION = 1;

  constructor(IAccessController acl, address collateral_) PremiumFundBase(acl, collateral_) {}

  function initializePremiumFund() public override initializer(CONTRACT_REVISION) {}

  function getRevision() internal pure override returns (uint256) {
    return CONTRACT_REVISION;
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

interface IPremiumFundInit {
  function initializePremiumFund() external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '../tools/SafeERC20.sol';
import '../tools/Errors.sol';
import '../tools/tokens/ERC20BalancelessBase.sol';
import '../libraries/Balances.sol';
import '../libraries/AddressExt.sol';
import '../tools/tokens/IERC20.sol';
import '../access/AccessHelper.sol';
import '../pricing/PricingHelper.sol';
import '../funds/Collateralized.sol';
import '../interfaces/IPremiumDistributor.sol';
import '../interfaces/IPremiumActuary.sol';
import '../interfaces/IPremiumSource.sol';
import '../interfaces/IInsuredPool.sol';
import '../tools/math/WadRayMath.sol';
import './BalancerLib2.sol';

import 'hardhat/console.sol';

contract PremiumFundBase is IPremiumDistributor, AccessHelper, PricingHelper, Collateralized {
  using WadRayMath for uint256;
  using SafeERC20 for IERC20;
  using BalancerLib2 for BalancerLib2.AssetBalancer;
  using Balances for Balances.RateAcc;
  using EnumerableSet for EnumerableSet.AddressSet;

  mapping(address => BalancerLib2.AssetBalancer) internal _balancers; // [actuary]

  enum ActuaryState {
    Unknown,
    Inactive,
    Active,
    Paused
  }

  struct TokenInfo {
    EnumerableSet.AddressSet activeSources;
    uint32 nextReplenish;
  }

  struct SourceBalance {
    uint128 debt;
    uint96 rate;
    uint32 updatedAt;
  }

  uint8 private constant TS_PRESENT = 1 << 0;
  uint8 private constant TS_SUSPENDED = 1 << 1;

  struct TokenState {
    uint128 collectedFees;
    uint8 flags;
  }

  struct ActuaryConfig {
    mapping(address => TokenInfo) tokens; // [token]
    mapping(address => address) sourceToken; // [source] => token
    mapping(address => SourceBalance) sourceBalances; // [source] - to support shared tokens among different sources
    BalancerLib2.AssetConfig defaultConfig;
    ActuaryState state;
  }

  mapping(address => ActuaryConfig) internal _configs; // [actuary]
  mapping(address => TokenState) private _tokens; // [token]
  mapping(address => EnumerableSet.AddressSet) private _tokenActuaries; // [token]

  address[] private _knownTokens;

  constructor(IAccessController acl, address collateral_) AccessHelper(acl) Collateralized(collateral_) PricingHelper(_getPricerByAcl(acl)) {}

  function remoteAcl() internal view override(AccessHelper, PricingHelper) returns (IAccessController pricer) {
    return AccessHelper.remoteAcl();
  }

  event ActuaryAdded(address indexed actuary);
  event ActuaryRemoved(address indexed actuary);

  function registerPremiumActuary(address actuary, bool register) external virtual aclHas(AccessFlags.INSURER_ADMIN) {
    ActuaryConfig storage config = _configs[actuary];
    address cc = collateral();

    if (register) {
      State.require(config.state < ActuaryState.Active);
      Value.require(IPremiumActuary(actuary).collateral() == cc);
      if (_markTokenAsPresent(cc)) {
        _balancers[actuary].configs[cc].price = uint152(WadRayMath.WAD);
      }

      config.state = ActuaryState.Active;
      _tokenActuaries[cc].add(actuary);
      emit ActuaryAdded(actuary);
    } else if (config.state >= ActuaryState.Active) {
      config.state = ActuaryState.Inactive;
      _tokenActuaries[cc].remove(actuary);
      emit ActuaryRemoved(actuary);
    }
  }

  event ActuaryPaused(address indexed actuary, bool paused);
  event ActuaryTokenPaused(address indexed actuary, address indexed token, bool paused);
  event TokenPaused(address indexed token, bool paused);

  function setPaused(address actuary, bool paused) external onlyEmergencyAdmin {
    ActuaryConfig storage config = _configs[actuary];
    State.require(config.state >= ActuaryState.Active);

    config.state = paused ? ActuaryState.Paused : ActuaryState.Active;
    emit ActuaryPaused(actuary, paused);
  }

  function isPaused(address actuary) public view returns (bool) {
    return _configs[actuary].state == ActuaryState.Paused;
  }

  function setPaused(
    address actuary,
    address token,
    bool paused
  ) external onlyEmergencyAdmin {
    ActuaryConfig storage config = _configs[actuary];
    State.require(config.state > ActuaryState.Unknown);
    Value.require(token != address(0));

    BalancerLib2.AssetConfig storage assetConfig = _balancers[actuary].configs[token];
    uint16 flags = assetConfig.flags;
    assetConfig.flags = paused ? flags | BalancerLib2.BF_SUSPENDED : flags & ~BalancerLib2.BF_SUSPENDED;
    emit ActuaryTokenPaused(actuary, token, paused);
  }

  function isPaused(address actuary, address token) public view returns (bool) {
    ActuaryState state = _configs[actuary].state;
    if (state == ActuaryState.Active) {
      return _balancers[actuary].configs[token].flags & BalancerLib2.BF_SUSPENDED != 0;
    }
    return state == ActuaryState.Paused;
  }

  function setPausedToken(address token, bool paused) external onlyEmergencyAdmin {
    Value.require(token != address(0));

    TokenState storage state = _tokens[token];
    uint8 flags = state.flags;
    state.flags = paused ? flags | TS_SUSPENDED : flags & ~TS_SUSPENDED;
    emit TokenPaused(token, paused);
  }

  function isPausedToken(address token) public view returns (bool) {
    return _tokens[token].flags & TS_SUSPENDED != 0;
  }

  uint8 private constant SOURCE_MULTI_MODE_MASK = 3;
  uint8 private constant SMM_SOLO = 0;
  uint8 private constant SMM_MANY_NO_LIST = 1;
  uint8 private constant SMM_LIST = 2;

  event ActuarySourceAdded(address indexed actuary, address indexed source, address indexed token);
  event ActuarySourceRemoved(address indexed actuary, address indexed source, address indexed token);

  function registerPremiumSource(address source, bool register) external override {
    address actuary = msg.sender;

    ActuaryConfig storage config = _configs[actuary];
    State.require(config.state >= ActuaryState.Active);

    if (register) {
      Value.require(source != address(0) && source != collateral());
      // NB! a source will actually be added on non-zero rate only
      require(config.sourceToken[source] == address(0));

      address targetToken = IPremiumSource(source).premiumToken();
      _ensureNonCollateral(actuary, targetToken);
      _markTokenAsPresent(targetToken);
      config.sourceToken[source] = targetToken;
      _tokenActuaries[targetToken].add(actuary);
      emit ActuarySourceAdded(actuary, source, targetToken);
    } else {
      address targetToken = config.sourceToken[source];
      if (targetToken != address(0)) {
        if (_removePremiumSource(config, _balancers[actuary], source, targetToken)) {
          _tokenActuaries[targetToken].remove(actuary);
        }
        emit ActuarySourceRemoved(actuary, source, targetToken);
      }
    }
  }

  function _ensureNonCollateral(address actuary, address token) private view {
    Value.require(token != IPremiumActuary(actuary).collateral());
  }

  function _markTokenAsPresent(address token) private returns (bool) {
    require(token != address(0));
    TokenState storage state = _tokens[token];
    uint8 flags = state.flags;
    if (flags & TS_PRESENT == 0) {
      state.flags = flags | TS_PRESENT;
      _knownTokens.push(token);
      return true;
    }
    return false;
  }

  function _addPremiumSource(
    ActuaryConfig storage config,
    BalancerLib2.AssetBalancer storage balancer,
    address targetToken,
    address source
  ) private {
    EnumerableSet.AddressSet storage activeSources = config.tokens[targetToken].activeSources;

    State.require(activeSources.add(source));

    if (activeSources.length() == 1) {
      BalancerLib2.AssetBalance storage balance = balancer.balances[source];

      require(balance.rateValue == 0);
      // re-activation should keep price
      uint152 price = balance.accumAmount == 0 ? 0 : balancer.configs[targetToken].price;
      balancer.configs[targetToken] = config.defaultConfig;
      balancer.configs[targetToken].price = price;
    }
  }

  function _removePremiumSource(
    ActuaryConfig storage config,
    BalancerLib2.AssetBalancer storage balancer,
    address source,
    address targetToken
  ) private returns (bool allRemoved) {
    delete config.sourceToken[source];
    EnumerableSet.AddressSet storage activeSources = config.tokens[targetToken].activeSources;

    if (activeSources.remove(source)) {
      BalancerLib2.AssetConfig storage balancerConfig = balancer.configs[targetToken];

      SourceBalance storage sBalance = config.sourceBalances[source];
      uint96 rate = balancer.decRate(targetToken, sBalance.rate);

      delete config.sourceBalances[source];

      if (activeSources.length() == 0) {
        require(rate == 0);
        balancerConfig.flags |= BalancerLib2.BF_FINISHED;

        allRemoved = true;
      }
    } else {
      allRemoved = activeSources.length() == 0;
    }
  }

  function _ensureActuary(address actuary) private view returns (ActuaryConfig storage config) {
    config = _configs[actuary];
    State.require(config.state >= ActuaryState.Active);
  }

  function _ensureActiveActuary(address actuary) private view returns (ActuaryConfig storage config) {
    config = _configs[actuary];
    State.require(config.state == ActuaryState.Active);
  }

  event PremiumAllocationUpdated(
    address indexed actuary,
    address indexed source,
    address indexed token,
    uint256 increment,
    uint256 rate,
    bool underprovisioned
  );

  function _premiumAllocationUpdated(
    ActuaryConfig storage config,
    address actuary,
    address source,
    address token,
    uint256 increment,
    uint256 rate,
    bool checkSuspended
  )
    private
    returns (
      address targetToken,
      BalancerLib2.AssetBalancer storage balancer,
      SourceBalance storage sBalance
    )
  {
    Value.require(source != address(0));
    balancer = _balancers[actuary];

    sBalance = config.sourceBalances[source];
    (uint96 lastRate, uint32 updatedAt) = (sBalance.rate, sBalance.updatedAt);

    if (token == address(0)) {
      // this is a call from the actuary - it doesnt know about tokens, only about sources
      targetToken = config.sourceToken[source];
      Value.require(targetToken != address(0));

      if (updatedAt == 0 && rate > 0) {
        _addPremiumSource(config, balancer, targetToken, source);
      }
    } else {
      // this is a sync call from a user - who knows about tokens, but not about sources
      targetToken = token;
      rate = lastRate;
      increment = rate * (uint32(block.timestamp - updatedAt));
    }

    bool underprovisioned = !balancer.replenishAsset(
      BalancerLib2.ReplenishParams({actuary: actuary, source: source, token: targetToken, replenishFn: _replenishFn}),
      increment,
      uint96(rate),
      lastRate,
      checkSuspended
    );
    emit PremiumAllocationUpdated(actuary, source, token, increment, rate, underprovisioned);

    if (underprovisioned) {
      // the source failed to keep the promised premium rate, stop the rate to avoid false inflow
      sBalance.rate = 0;
    } else if (lastRate != rate) {
      Value.require((sBalance.rate = uint96(rate)) == rate);
    }
    sBalance.updatedAt = uint32(block.timestamp);
  }

  function premiumAllocationUpdated(
    address source,
    uint256,
    uint256 increment,
    uint256 rate
  ) external override {
    ActuaryConfig storage config = _ensureActuary(msg.sender);
    Value.require(source != address(0));
    Value.require(rate > 0);

    _premiumAllocationUpdated(config, msg.sender, source, address(0), increment, rate, false);
  }

  function premiumAllocationFinished(
    address source,
    uint256,
    uint256 increment
  ) external override returns (uint256 premiumDebt) {
    ActuaryConfig storage config = _ensureActuary(msg.sender);
    Value.require(source != address(0));

    (address targetToken, BalancerLib2.AssetBalancer storage balancer, SourceBalance storage sBalance) = _premiumAllocationUpdated(
      config,
      msg.sender,
      source,
      address(0),
      increment,
      0,
      false
    );

    premiumDebt = sBalance.debt;
    if (premiumDebt > 0) {
      sBalance.debt = 0;
    }

    _removePremiumSource(config, balancer, source, targetToken);
    emit ActuarySourceRemoved(msg.sender, source, targetToken);
  }

  function _replenishFn(BalancerLib2.ReplenishParams memory params, uint256 requiredValue)
    private
    returns (
      uint256 replenishedAmount,
      uint256 replenishedValue,
      uint256 expectedValue
    )
  {
    /* ============================================================ */
    /* ============================================================ */
    /* ============================================================ */
    /* WARNING! Balancer logic and state MUST NOT be accessed here! */
    /* ============================================================ */
    /* ============================================================ */
    /* ============================================================ */

    ActuaryConfig storage config = _configs[params.actuary];

    if (params.source == address(0)) {
      // this is called by auto-replenishment during swap - it is not related to any specific source
      // will auto-replenish from one source only to keep gas cost stable
      params.source = _sourceForReplenish(config, params.token);
    }

    SourceBalance storage balance = config.sourceBalances[params.source];
    {
      uint32 cur = uint32(block.timestamp);
      if (cur > balance.updatedAt) {
        expectedValue = uint256(cur - balance.updatedAt) * balance.rate;
        balance.updatedAt = cur;
      } else {
        require(cur == balance.updatedAt);
        return (0, 0, 0);
      }
    }
    if (requiredValue < expectedValue) {
      requiredValue = expectedValue;
    }

    uint256 debtValue = balance.debt;
    requiredValue += debtValue;

    if (requiredValue > 0) {
      uint256 missingValue;
      uint256 price = internalPriceOf(params.token);

      (replenishedAmount, missingValue) = _collectPremium(params, requiredValue, price);

      if (debtValue != missingValue) {
        require((balance.debt = uint128(missingValue)) == missingValue);
      }

      replenishedValue = replenishedAmount.wadMul(price);
    }
  }

  function _sourceForReplenish(ActuaryConfig storage config, address token) private returns (address) {
    TokenInfo storage tokenInfo = config.tokens[token];

    uint32 index = tokenInfo.nextReplenish;
    EnumerableSet.AddressSet storage activeSources = tokenInfo.activeSources;
    uint256 length = activeSources.length();
    if (index >= length) {
      index = 0;
    }
    tokenInfo.nextReplenish = index + 1;

    return activeSources.at(index);
  }

  function _collectPremium(
    BalancerLib2.ReplenishParams memory params,
    uint256 requiredValue,
    uint256 price
  ) private returns (uint256 collectedAmount, uint256 missingValue) {
    uint256 requiredAmount = requiredValue.wadDiv(price);
    collectedAmount = _collectPremiumCall(params.actuary, params.source, IERC20(params.token), requiredAmount, requiredValue);
    if (collectedAmount < requiredAmount) {
      missingValue = (requiredAmount - collectedAmount).wadMul(price);

      /*

      // This section of code enables use of CC as an additional way of premium payment

      if (missingValue > 0) {
        // assert(params.token != collateral());
        uint256 collectedValue = _collectPremiumCall(params.actuary, params.source, IERC20(collateral()), missingValue, missingValue);

        if (collectedValue > 0) {
          missingValue -= collectedValue;
          collectedAmount += collectedValue.wadDiv(price);
        }
      }

      */
    }
  }

  event PremiumCollectionFailed(address indexed source, address indexed token, uint256 amount, bool isPanic, bytes reason);

  function _collectPremiumCall(
    address actuary,
    address source,
    IERC20 token,
    uint256 amount,
    uint256 value
  ) private returns (uint256) {
    uint256 balance = token.balanceOf(address(this));

    bool isPanic;
    bytes memory errReason;

    try IPremiumSource(source).collectPremium(actuary, address(token), amount, value) {
      return token.balanceOf(address(this)) - balance;
    } catch Error(string memory reason) {
      errReason = bytes(reason);
    } catch (bytes memory reason) {
      isPanic = true;
      errReason = reason;
    }
    emit PremiumCollectionFailed(source, address(token), amount, isPanic, errReason);

    return 0;
  }

  function priceOf(address token) public view returns (uint256) {
    return internalPriceOf(token);
  }

  function internalPriceOf(address token) internal view virtual returns (uint256) {
    return getPricer().getAssetPrice(token);
  }

  function _ensureToken(address token) private view {
    uint8 flags = _tokens[token].flags;
    State.require(flags & TS_PRESENT != 0);
    if (flags & TS_SUSPENDED != 0) {
      revert Errors.OperationPaused();
    }
  }

  // slither-disable-next-line calls-loop
  function _syncAsset(
    ActuaryConfig storage config,
    address actuary,
    address token,
    uint256 sourceLimit
  ) private returns (uint256) {
    _ensureToken(token);
    Value.require(token != address(0));
    if (collateral() == token) {
      IPremiumActuary(actuary).collectDrawdownPremium();
      return sourceLimit == 0 ? 0 : sourceLimit - 1;
    }

    TokenInfo storage tokenInfo = config.tokens[token];
    EnumerableSet.AddressSet storage activeSources = tokenInfo.activeSources;
    uint256 length = activeSources.length();

    if (length > 0) {
      uint32 index = tokenInfo.nextReplenish;
      if (index >= length) {
        index = 0;
      }
      uint256 stop = index;

      for (; sourceLimit > 0; sourceLimit--) {
        _premiumAllocationUpdated(config, actuary, activeSources.at(index), token, 0, 0, true);
        index++;
        if (index >= length) {
          index = 0;
        }
        if (index == stop) {
          break;
        }
      }

      tokenInfo.nextReplenish = index;
    }

    return sourceLimit;
  }

  function syncAsset(
    address actuary,
    uint256 sourceLimit,
    address targetToken
  ) public {
    if (sourceLimit == 0) {
      sourceLimit = ~sourceLimit;
    }

    ActuaryConfig storage config = _ensureActiveActuary(actuary);
    _syncAsset(config, actuary, targetToken, sourceLimit);
  }

  function syncAssets(
    address actuary,
    uint256 sourceLimit,
    address[] calldata targetTokens
  ) external returns (uint256 i) {
    if (sourceLimit == 0) {
      sourceLimit = ~sourceLimit;
    }

    ActuaryConfig storage config = _ensureActiveActuary(actuary);

    for (; i < targetTokens.length; i++) {
      sourceLimit = _syncAsset(config, actuary, targetTokens[i], sourceLimit);
      if (sourceLimit == 0) {
        break;
      }
    }
  }

  function assetBalance(address actuary, address asset)
    external
    view
    returns (
      uint256 amount,
      uint256 stravation,
      uint256 price,
      uint256 feeFactor
    )
  {
    ActuaryConfig storage config = _configs[actuary];
    if (config.state > ActuaryState.Unknown) {
      (, amount, stravation, price, feeFactor) = _balancers[actuary].assetState(asset);
    }
  }

  function swapAsset(
    address actuary,
    address account,
    address recipient,
    uint256 valueToSwap,
    address targetToken,
    uint256 minAmount
  ) public returns (uint256 tokenAmount) {
    _ensureActiveActuary(actuary);
    _ensureToken(targetToken);
    Value.require(recipient != address(0));

    uint256 fee;
    address burnReceiver;
    uint256 drawdownValue = IPremiumActuary(actuary).collectDrawdownPremium();
    BalancerLib2.AssetBalancer storage balancer = _balancers[actuary];

    if (collateral() == targetToken) {
      (tokenAmount, fee) = balancer.swapExternalAsset(targetToken, valueToSwap, minAmount, drawdownValue);
      if (tokenAmount > 0) {
        if (fee == 0) {
          // use a direct transfer when no fees
          require(tokenAmount == valueToSwap);
          burnReceiver = recipient;
        } else {
          burnReceiver = address(this);
        }
      }
    } else {
      (tokenAmount, fee) = balancer.swapAsset(_replenishParams(actuary, targetToken), valueToSwap, minAmount, drawdownValue);
    }

    if (tokenAmount > 0) {
      IPremiumActuary(actuary).burnPremium(account, valueToSwap, burnReceiver);
      if (burnReceiver != recipient) {
        SafeERC20.safeTransfer(IERC20(targetToken), recipient, tokenAmount);
      }
    }

    if (fee > 0) {
      _addFee(_configs[actuary], targetToken, fee);
    }
  }

  function _addFee(
    ActuaryConfig storage,
    address targetToken,
    uint256 fee
  ) private {
    require((_tokens[targetToken].collectedFees += uint128(fee)) >= fee);
  }

  function availableFee(address targetToken) external view returns (uint256) {
    return _tokens[targetToken].collectedFees;
  }

  function collectFees(
    address[] calldata tokens,
    uint256 minAmount,
    address recipient
  ) external aclHas(AccessFlags.TREASURY) returns (uint256[] memory fees) {
    Value.require(recipient != address(0));
    if (minAmount == 0) {
      minAmount = 1;
    }

    fees = new uint256[](tokens.length);
    for (uint256 i = tokens.length; i > 0; ) {
      i--;
      TokenState storage state = _tokens[tokens[i]];

      uint256 fee = state.collectedFees;
      if (fee >= minAmount) {
        state.collectedFees = 0;
        IERC20(tokens[i]).safeTransfer(recipient, fees[i] = fee);
      }
    }
  }

  struct SwapInstruction {
    uint256 valueToSwap;
    address targetToken;
    uint256 minAmount;
    address recipient;
  }

  function swapAssets(
    address actuary,
    address account,
    address defaultRecepient,
    SwapInstruction[] calldata instructions
  ) external returns (uint256[] memory tokenAmounts) {
    if (instructions.length <= 1) {
      // _ensureActiveActuary is applied inside swapToken invoked via _swapTokensOne
      return instructions.length == 0 ? tokenAmounts : _swapTokensOne(actuary, account, defaultRecepient, instructions[0]);
    }

    _ensureActiveActuary(actuary);

    uint256[] memory fees;
    (tokenAmounts, fees) = _swapTokens(actuary, account, instructions, IPremiumActuary(actuary).collectDrawdownPremium());
    ActuaryConfig storage config = _configs[actuary];

    for (uint256 i = 0; i < instructions.length; i++) {
      address recipient = instructions[i].recipient;
      address targetToken = instructions[i].targetToken;

      SafeERC20.safeTransfer(IERC20(targetToken), recipient == address(0) ? defaultRecepient : recipient, tokenAmounts[i]);

      if (fees[i] > 0) {
        _addFee(config, targetToken, fees[i]);
      }
    }
  }

  function _swapTokens(
    address actuary,
    address account,
    SwapInstruction[] calldata instructions,
    uint256 drawdownValue
  ) private returns (uint256[] memory tokenAmounts, uint256[] memory fees) {
    BalancerLib2.AssetBalancer storage balancer = _balancers[actuary];

    uint256 drawdownBalance = drawdownValue;

    tokenAmounts = new uint256[](instructions.length);
    fees = new uint256[](instructions.length);

    Balances.RateAcc memory totalOrig = balancer.totalBalance;
    Balances.RateAcc memory totalSum;
    (totalSum.accum, totalSum.rate, totalSum.updatedAt) = (totalOrig.accum, totalOrig.rate, totalOrig.updatedAt);
    BalancerLib2.ReplenishParams memory params = _replenishParams(actuary, address(0));

    uint256 totalValue;
    uint256 totalExtValue;
    for (uint256 i = 0; i < instructions.length; i++) {
      _ensureToken(instructions[i].targetToken);

      Balances.RateAcc memory total;
      (total.accum, total.rate, total.updatedAt) = (totalOrig.accum, totalOrig.rate, totalOrig.updatedAt);

      if (collateral() == instructions[i].targetToken) {
        (tokenAmounts[i], fees[i]) = _swapExtTokenInBatch(balancer, instructions[i], drawdownBalance, total);

        if (tokenAmounts[i] > 0) {
          totalExtValue += instructions[i].valueToSwap;
          drawdownBalance -= tokenAmounts[i];
        }
      } else {
        (tokenAmounts[i], fees[i]) = _swapTokenInBatch(balancer, instructions[i], drawdownValue, params, total);

        if (tokenAmounts[i] > 0) {
          _mergeTotals(totalSum, totalOrig, total);
          totalValue += instructions[i].valueToSwap;
        }
      }
    }

    if (totalValue > 0) {
      IPremiumActuary(actuary).burnPremium(account, totalValue, address(0));
    }

    if (totalExtValue > 0) {
      IPremiumActuary(actuary).burnPremium(account, totalExtValue, address(this));
    }

    balancer.totalBalance = totalSum;
  }

  function _replenishParams(address actuary, address targetToken) private pure returns (BalancerLib2.ReplenishParams memory) {
    return BalancerLib2.ReplenishParams({actuary: actuary, source: address(0), token: targetToken, replenishFn: _replenishFn});
  }

  function _swapTokenInBatch(
    BalancerLib2.AssetBalancer storage balancer,
    SwapInstruction calldata instruction,
    uint256 drawdownValue,
    BalancerLib2.ReplenishParams memory params,
    Balances.RateAcc memory total
  ) private returns (uint256 tokenAmount, uint256 fee) {
    params.token = instruction.targetToken;
    (tokenAmount, fee, ) = balancer.swapAssetInBatch(params, instruction.valueToSwap, instruction.minAmount, drawdownValue, total);
  }

  function _swapExtTokenInBatch(
    BalancerLib2.AssetBalancer storage balancer,
    SwapInstruction calldata instruction,
    uint256 drawdownBalance,
    Balances.RateAcc memory total
  ) private view returns (uint256 tokenAmount, uint256 fee) {
    return balancer.swapExternalAssetInBatch(instruction.targetToken, instruction.valueToSwap, instruction.minAmount, drawdownBalance, total);
  }

  function _mergeValue(
    uint256 vSum,
    uint256 vOrig,
    uint256 v,
    uint256 max
  ) private pure returns (uint256) {
    if (vOrig >= v) {
      unchecked {
        v = vOrig - v;
      }
      v = vSum - v;
    } else {
      unchecked {
        v = v - vOrig;
      }
      require((v = vSum + v) <= max);
    }
    return v;
  }

  function _mergeTotals(
    Balances.RateAcc memory totalSum,
    Balances.RateAcc memory totalOrig,
    Balances.RateAcc memory total
  ) private pure {
    if (totalSum.updatedAt != total.updatedAt) {
      totalSum.sync(total.updatedAt);
    }
    totalSum.accum = uint128(_mergeValue(totalSum.accum, totalOrig.accum, total.accum, type(uint128).max));
    totalSum.rate = uint96(_mergeValue(totalSum.rate, totalOrig.rate, total.rate, type(uint96).max));
  }

  function _swapTokensOne(
    address actuary,
    address account,
    address defaultRecepient,
    SwapInstruction calldata instruction
  ) private returns (uint256[] memory tokenAmounts) {
    tokenAmounts = new uint256[](1);

    tokenAmounts[0] = swapAsset(
      actuary,
      account,
      instruction.recipient != address(0) ? instruction.recipient : defaultRecepient,
      instruction.valueToSwap,
      instruction.targetToken,
      instruction.minAmount
    );
  }

  function knownTokens() external view returns (address[] memory) {
    return _knownTokens;
  }

  function actuariesOfToken(address token) public view returns (address[] memory) {
    return _tokenActuaries[token].values();
  }

  function actuaries() external view returns (address[] memory) {
    return actuariesOfToken(collateral());
  }

  function activeSourcesOf(address actuary, address token) external view returns (address[] memory) {
    return _configs[actuary].tokens[token].activeSources.values();
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IVersioned {
  // solhint-disable-next-line func-name-mixedcase
  function REVISION() external view returns (uint256);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import './tokens/IERC20.sol';
import '@openzeppelin/contracts/utils/Address.sol';

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

  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    require((value == 0) || (token.allowance(address(this), spender) == 0), 'SafeERC20: approve from non-zero to non-zero allowance');
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
  }

  function _callOptionalReturn(IERC20 token, bytes memory data) private {
    // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
    // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
    // the target address contains contract code and also asserts for success in the low-level call.

    bytes memory returndata = address(token).functionCall(data, 'SafeERC20: low-level call failed');
    if (returndata.length > 0) {
      // Return data is optional
      require(abi.decode(returndata, (bool)), 'SafeERC20: ERC20 operation did not succeed');
    }
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
      require(adjustment == (b.accum = uint128(adjustment)));
    }
    b.updatedAt = at;
    return b;
  }

  // function syncStorage(RateAcc storage b, uint32 at) internal {
  //   uint256 adjustment = at - b.updatedAt;
  //   if (adjustment > 0 && (adjustment = adjustment * b.rate) > 0) {
  //     adjustment += b.accum;
  //     require(adjustment == (b.accum = uint128(adjustment)));
  //   }
  //   b.updatedAt = at;
  // }

  // function setRateStorage(
  //   RateAcc storage b,
  //   uint32 at,
  //   uint256 rate
  // ) internal {
  //   syncStorage(b, at);
  //   require(rate == (b.rate = uint96(rate)));
  // }

  // function setRate(
  //   RateAcc memory b,
  //   uint32 at,
  //   uint256 rate
  // ) internal pure returns (RateAcc memory) {
  //   b = sync(b, at);
  //   require(rate == (b.rate = uint96(rate)));
  //   return b;
  // }

  function setRateAfterSync(RateAcc memory b, uint256 rate) internal view returns (RateAcc memory) {
    require(b.updatedAt == block.timestamp);
    require(rate == (b.rate = uint96(rate)));
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
  //     require(adjustment == (b.accum = uint120(adjustment)));
  //   }
  //   b.updatedAt = at;
  //   return b;
  // }

  // function syncStorage(RateAccWithUint8 storage b, uint32 at) internal {
  //   uint256 adjustment = at - b.updatedAt;
  //   if (adjustment > 0 && (adjustment = adjustment * b.rate) > 0) {
  //     adjustment += b.accum;
  //     require(adjustment == (b.accum = uint120(adjustment)));
  //   }
  //   b.updatedAt = at;
  // }

  // function setRateStorage(
  //   RateAccWithUint8 storage b,
  //   uint32 at,
  //   uint256 rate
  // ) internal {
  //   syncStorage(b, at);
  //   require(rate == (b.rate = uint96(rate)));
  // }

  // function setRate(
  //   RateAccWithUint8 memory b,
  //   uint32 at,
  //   uint256 rate
  // ) internal pure returns (RateAccWithUint8 memory) {
  //   b = sync(b, at);
  //   require(rate == (b.rate = uint96(rate)));
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
      require(adjustment == (b.accum = uint120(adjustment)));
    }
    b.updatedAt = at;
    return b;
  }

  // function syncStorage(RateAccWithUint16 storage b, uint32 at) internal {
  //   uint256 adjustment = at - b.updatedAt;
  //   if (adjustment > 0 && (adjustment = adjustment * b.rate) > 0) {
  //     adjustment += b.accum;
  //     require(adjustment == (b.accum = uint120(adjustment)));
  //   }
  //   b.updatedAt = at;
  // }

  // function setRateStorage(
  //   RateAccWithUint16 storage b,
  //   uint32 at,
  //   uint256 rate
  // ) internal {
  //   syncStorage(b, at);
  //   require(rate == (b.rate = uint88(rate)));
  // }

  // function setRate(
  //   RateAccWithUint16 memory b,
  //   uint32 at,
  //   uint256 rate
  // ) internal pure returns (RateAccWithUint16 memory) {
  //   b = sync(b, at);
  //   require(rate == (b.rate = uint88(rate)));
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
  //     require(adjustment == (b.accum = uint112(adjustment)));
  //   }
  //   b.updatedAt = at;
  //   return b;
  // }

  // function syncStorage(RateAccWithUint32 storage b, uint32 at) internal {
  //   uint256 adjustment = at - b.updatedAt;
  //   if (adjustment > 0 && (adjustment = adjustment * b.rate) > 0) {
  //     adjustment += b.accum;
  //     require(adjustment == (b.accum = uint112(adjustment)));
  //   }
  //   b.updatedAt = at;
  // }

  // function setRateStorage(
  //   RateAccWithUint32 storage b,
  //   uint32 at,
  //   uint256 rate
  // ) internal {
  //   syncStorage(b, at);
  //   require(rate == (b.rate = uint80(rate)));
  // }

  // function setRate(
  //   RateAccWithUint32 memory b,
  //   uint32 at,
  //   uint256 rate
  // ) internal pure returns (RateAccWithUint32 memory) {
  //   b = sync(b, at);
  //   require(rate == (b.rate = uint80(rate)));
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

library AddressExt {
  function addr(uint256 v) internal pure returns (address) {
    return address(uint160(v));
  }

  function ext(uint256 v) internal pure returns (uint96) {
    return uint96(v >> 160);
  }

  function setAddr(uint256 v, address a) internal pure returns (uint256) {
    return (v & ~uint256(type(uint160).max)) | uint160(a);
  }

  function setExt(uint256 v, uint96 e) internal pure returns (uint256) {
    return (v & type(uint160).max) | (uint256(e) << 160);
  }

  function newAddressExt(address a, uint96 e) internal pure returns (uint256) {
    return (uint256(e) << 160) | uint160(a);
  }

  function newAddressExt(address a) internal pure returns (uint256) {
    return uint160(a);
  }

  function unwrap(uint256 v) internal pure returns (address, uint96) {
    return (addr(v), ext(v));
  }
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

import '../tools/Errors.sol';
import '../access/AccessHelper.sol';
import './interfaces/IManagedPriceRouter.sol';

abstract contract PricingHelper {
  IManagedPriceRouter private immutable _pricer;

  constructor(address pricer_) {
    _pricer = IManagedPriceRouter(pricer_);
  }

  function priceOracle() external view returns (address) {
    return address(getPricer());
  }

  function remoteAcl() internal view virtual returns (IAccessController pricer);

  function getPricer() internal view virtual returns (IManagedPriceRouter pricer) {
    pricer = _pricer;
    if (address(pricer) == address(0)) {
      pricer = IManagedPriceRouter(_getPricerByAcl(remoteAcl()));
      State.require(address(pricer) != address(0));
    }
  }

  function _getPricerByAcl(IAccessController acl) internal view returns (address) {
    return address(acl) == address(0) ? address(0) : acl.getAddress(AccessFlags.PRICE_ROUTER);
  }
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
}

struct InsuredParams {
  uint128 minPerInsurer;
}

struct InsuredRateBand {
  uint64 premiumRate;
  uint96 coverageDemand;
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
pragma solidity ^0.8.4;

import '../tools/math/Math.sol';
import '../tools/math/WadRayMath.sol';
import '../tools/math/PercentageMath.sol';
import '../libraries/Balances.sol';

import 'hardhat/console.sol';

library BalancerLib2 {
  using WadRayMath for uint256;
  using Balances for Balances.RateAcc;

  struct AssetBalance {
    uint128 accumAmount; // amount of asset
    uint96 rateValue; // value per second
    uint32 applyFrom;
  }

  struct AssetBalancer {
    mapping(address => AssetBalance) balances; // [token] total balance and rate of all sources using this token
    Balances.RateAcc totalBalance; // total VALUE balance and VALUE rate of all sources
    mapping(address => AssetConfig) configs; // [token] token balancing configuration
    uint160 spConst; // value, for (BF_SPM_GLOBAL | BF_SPM_CONSTANT) starvation point mode
    uint32 spFactor; // rate multiplier, for (BF_SPM_GLOBAL | !BF_SPM_CONSTANT) starvation point mode
  }

  struct AssetConfig {
    uint152 price; // target price, wad-multiplier, uint192
    uint64 w; // [0..1] fee control, uint64
    uint32 n; // rate multiplier, for (!BF_SPM_GLOBAL | !BF_SPM_CONSTANT) starvation point mode
    uint16 flags; // starvation point modes and asset states
    uint160 spConst; // value, for (!BF_SPM_GLOBAL | BF_SPM_CONSTANT) starvation point mode
  }

  uint8 private constant FINISHED_OFFSET = 8;

  uint16 internal constant BF_SPM_GLOBAL = 1 << 0;
  uint16 internal constant BF_SPM_CONSTANT = 1 << 1;
  uint16 internal constant BF_SPM_MAX_WITH_CONST = 1 << 2; // only applicable with BF_SPM_CONSTANT

  uint16 internal constant BF_AUTO_REPLENISH = 1 << 6; // pull a source at every swap
  uint16 internal constant BF_FINISHED = 1 << 7; // no more sources for this token

  uint16 internal constant BF_SPM_MASK = BF_SPM_GLOBAL | BF_SPM_CONSTANT | BF_SPM_MAX_WITH_CONST;
  uint16 internal constant BF_SPM_F_MASK = BF_SPM_MASK << FINISHED_OFFSET;

  // uint16 internal constant BF_SPM_F_GLOBAL = BF_SPM_GLOBAL << FINISHED_OFFSET;
  // uint16 internal constant BF_SPM_F_CONSTANT = BF_SPM_CONSTANT << FINISHED_OFFSET;

  uint16 internal constant BF_SUSPENDED = 1 << 15; // token is suspended

  struct CalcParams {
    uint256 sA; // amount of an asset at starvation
    uint256 vA; // target price, wad-multiplier, uint192
    uint256 w; // [0..1] wad, controls fees, uint64
    uint256 extraTotal;
  }

  struct ReplenishParams {
    address actuary;
    address source;
    address token;
    function(
      ReplenishParams memory,
      uint256 /* requestedValue */
    )
      returns (
        uint256, /* replenishedAmount */
        uint256, /* replenishedValue */
        uint256 /*  expectedValue */
      ) replenishFn;
  }

  function swapExternalAsset(
    AssetBalancer storage p,
    address token,
    uint256 value,
    uint256 minAmount,
    uint256 assetAmount
  ) internal view returns (uint256 amount, uint256 fee) {
    return swapExternalAssetInBatch(p, token, value, minAmount, assetAmount, p.totalBalance);
  }

  function swapExternalAssetInBatch(
    AssetBalancer storage p,
    address token,
    uint256 value,
    uint256 minAmount,
    uint256 assetAmount,
    Balances.RateAcc memory total
  ) internal view returns (uint256 amount, uint256 fee) {
    AssetBalance memory balance;
    total.sync(uint32(block.timestamp));
    (CalcParams memory c, ) = _calcParams(p, token, balance.rateValue, true);

    // NB!!!!! value and amount are the same for this case
    c.vA = WadRayMath.WAD;

    require((total.accum += uint128(assetAmount)) >= assetAmount);
    balance.accumAmount = uint128(assetAmount);

    (amount, fee) = _swapAsset(value, minAmount, c, balance, total);
  }

  function swapAsset(
    AssetBalancer storage p,
    ReplenishParams memory params,
    uint256 value,
    uint256 minAmount,
    uint256 extraTotalValue
  ) internal returns (uint256 amount, uint256 fee) {
    Balances.RateAcc memory total = p.totalBalance;
    bool updateTotal;
    (amount, fee, updateTotal) = swapAssetInBatch(p, params, value, minAmount, extraTotalValue, total);

    if (updateTotal) {
      p.totalBalance = total;
    }
  }

  function assetState(AssetBalancer storage p, address token)
    internal
    view
    returns (
      uint256,
      uint256 accum,
      uint256 stravation,
      uint256 price,
      uint256 w
    )
  {
    AssetBalance memory balance = p.balances[token];
    (CalcParams memory c, uint256 flags) = _calcParams(p, token, balance.rateValue, false);
    return (flags, balance.accumAmount, c.sA, c.vA, c.w);
  }

  function swapAssetInBatch(
    AssetBalancer storage p,
    ReplenishParams memory params,
    uint256 value,
    uint256 minAmount,
    uint256 extraTotal,
    Balances.RateAcc memory total
  )
    internal
    returns (
      uint256 amount,
      uint256 fee,
      bool updateTotal
    )
  {
    AssetBalance memory balance = p.balances[params.token];
    total.sync(uint32(block.timestamp));

    (CalcParams memory c, uint256 flags) = _calcParams(p, params.token, balance.rateValue, true);

    if (flags & BF_AUTO_REPLENISH != 0 || (balance.rateValue > 0 && balance.accumAmount <= c.sA)) {
      // c.extraTotal = 0; - it is and it should be zero here
      _replenishAsset(p, params, c, balance, total);
      updateTotal = true;
    }

    c.extraTotal = extraTotal;
    (amount, fee) = _swapAsset(value, minAmount, c, balance, total);
    if (amount > 0) {
      p.balances[params.token] = balance;
      updateTotal = true;
    }
  }

  function _calcParams(
    AssetBalancer storage p,
    address token,
    uint256 rateValue,
    bool checkSuspended
  ) private view returns (CalcParams memory c, uint256 flags) {
    AssetConfig storage config = p.configs[token];

    c.w = config.w;
    c.vA = config.price;

    {
      flags = config.flags;
      if (flags & BF_SUSPENDED != 0 && checkSuspended) {
        revert Errors.OperationPaused();
      }
      if (flags & BF_FINISHED != 0) {
        flags <<= FINISHED_OFFSET;
      }

      // if (flags & BF_SPM_CONSTANT == 0) {
      //   c.sA = rateValue == 0 ? 0 : (rateValue * (flags & BF_SPM_GLOBAL == 0 ? config.n : p.spFactor)).wadDiv(c.vA);
      // } else {
      //   c.sA = flags & BF_SPM_GLOBAL == 0 ? config.spConst : p.spConst;
      // }

      if (flags & BF_SPM_CONSTANT != 0) {
        c.sA = flags & BF_SPM_GLOBAL == 0 ? config.spConst : p.spConst;
      }

      uint256 mode = flags & (BF_SPM_CONSTANT | BF_SPM_MAX_WITH_CONST);
      if (mode != BF_SPM_CONSTANT) {
        uint256 v;
        if (rateValue != 0) {
          v = (flags & BF_SPM_GLOBAL == 0) == (mode != BF_SPM_MAX_WITH_CONST) ? config.n : p.spFactor;
          v = (rateValue * v).wadDiv(c.vA);
        }
        if (flags & BF_SPM_MAX_WITH_CONST == 0 || v > c.sA) {
          c.sA = v;
        }
      }
    }
  }

  function _swapAsset(
    uint256 value,
    uint256 minAmount,
    CalcParams memory c,
    AssetBalance memory balance,
    Balances.RateAcc memory total
  ) private pure returns (uint256 amount, uint256 fee) {
    if (balance.accumAmount == 0) {
      return (0, 0);
    }

    uint256 k = _calcScale(c, balance, total);
    amount = _calcAmount(c, balance.accumAmount, value.rayMul(k));

    if (amount == 0 && c.sA != 0 && balance.accumAmount > 0) {
      amount = 1;
    }
    amount = balance.accumAmount - amount;

    if (amount >= minAmount && amount > 0) {
      balance.accumAmount = uint128(balance.accumAmount - amount);
      uint256 v = amount.wadMul(c.vA);
      total.accum = uint128(total.accum - v);

      if (v < value) {
        // This is a total amount of fees - it has 2 parts: balancing levy and volume penalty.
        fee = value - v;
        // The balancing levy can be positive (for popular assets) or negative (for non-popular assets) and is distributed within the balancer.
        // The volume penalty is charged on large transactions and can be taken out.

        // This formula is an aproximation that overestimates the levy and underpays the penalty. It is an acceptable behavior.
        // More accurate formula needs log() which may be an overkill for this case.
        k = (k + _calcScale(c, balance, total)) >> 1;
        // The negative levy is ignored here as it was applied with rayMul(k) above.
        k = k < WadRayMath.RAY ? value - value.rayMul(WadRayMath.RAY - k) : 0;

        // The constant-product formula (1/x) should produce enough fees than required by balancing levy ... but there can be gaps.
        fee = fee > k ? fee - k : 0;
      }
    } else {
      amount = 0;
    }
  }

  function _calcScale(
    CalcParams memory c,
    AssetBalance memory balance,
    Balances.RateAcc memory total
  ) private pure returns (uint256) {
    return
      balance.rateValue == 0 || (total.accum == 0 && c.extraTotal == 0)
        ? WadRayMath.RAY
        : ((uint256(balance.accumAmount) *
          c.vA +
          (balance.applyFrom > 0 ? WadRayMath.WAD * uint256(total.updatedAt - balance.applyFrom) * balance.rateValue : 0)).wadToRay().divUp(
            total.accum + c.extraTotal
          ) * total.rate).divUp(balance.rateValue);
  }

  function _calcAmount(
    CalcParams memory c,
    uint256 a,
    uint256 dV
  ) private pure returns (uint256 a1) {
    if (a > c.sA) {
      if (c.w == 0) {
        // no fee based on amount
        a1 = _calcFlat(c, a, dV);
      } else if (c.w == WadRayMath.WAD) {
        a1 = _calcCurve(c, a, dV);
      } else {
        a1 = _calcCurveW(c, a, dV);
      }
    } else {
      a1 = _calcStarvation(c, a, dV);
    }
  }

  function _calcCurve(
    CalcParams memory c,
    uint256 a,
    uint256 dV
  ) private pure returns (uint256) {
    return _calc(a, dV, a, a.wadMul(c.vA));
  }

  function _calcCurveW(
    CalcParams memory c,
    uint256 a,
    uint256 dV
  ) private pure returns (uint256 a1) {
    uint256 wA = a.wadDiv(c.w);
    uint256 wV = wA.wadMul(c.vA);

    a1 = _calc(wA, dV, wA, wV);

    uint256 wsA = wA - (a - c.sA);
    if (a1 < wsA) {
      uint256 wsV = (wA * wV) / wsA;
      return _calc(c.sA, dV - (wsV - wV), c.sA, wsV);
    }

    return a - (wA - a1);
  }

  function _calcFlat(
    CalcParams memory c,
    uint256 a,
    uint256 dV
  ) private pure returns (uint256 a1) {
    uint256 dA = dV.wadDiv(c.vA);
    if (c.sA + dA <= a) {
      a1 = a - dA;
    } else {
      dV -= (a - c.sA).wadMul(c.vA);
      a1 = _calcStarvation(c, c.sA, dV);
    }
  }

  function _calcStarvation(
    CalcParams memory c,
    uint256 a,
    uint256 dV
  ) private pure returns (uint256 a1) {
    a1 = _calc(a, dV, c.sA, c.sA.wadMul(c.vA));
  }

  function _calc(
    uint256 a,
    uint256 dV,
    uint256 cA,
    uint256 cV
  ) private pure returns (uint256) {
    if (cV > cA) {
      (cA, cV) = (cV, cA);
    }
    cV = cV * WadRayMath.RAY;

    return Math.mulDiv(cV, cA, dV * WadRayMath.RAY + Math.mulDiv(cV, cA, a));
  }

  function replenishAsset(
    AssetBalancer storage p,
    ReplenishParams memory params,
    uint256 incrementValue,
    uint96 newRate,
    uint96 lastRate,
    bool checkSuspended
  ) internal returns (bool fully) {
    Balances.RateAcc memory total = _syncTotalBalance(p);
    AssetBalance memory balance = p.balances[params.token];
    (CalcParams memory c, ) = _calcParams(p, params.token, balance.rateValue, checkSuspended);
    c.extraTotal = incrementValue;

    if (_replenishAsset(p, params, c, balance, total) < incrementValue) {
      newRate = 0;
    } else {
      fully = true;
    }

    if (lastRate != newRate) {
      _changeRate(lastRate, newRate, balance, total);
    }

    _save(p, params, balance, total);
  }

  function _syncTotalBalance(AssetBalancer storage p) private view returns (Balances.RateAcc memory) {
    return p.totalBalance.sync(uint32(block.timestamp));
  }

  function _save(
    AssetBalancer storage p,
    address token,
    AssetBalance memory balance,
    Balances.RateAcc memory total
  ) private {
    p.balances[token] = balance;
    p.totalBalance = total;
  }

  function _save(
    AssetBalancer storage p,
    ReplenishParams memory params,
    AssetBalance memory balance,
    Balances.RateAcc memory total
  ) private {
    _save(p, params.token, balance, total);
  }

  function _changeRate(
    uint96 lastRate,
    uint96 newRate,
    AssetBalance memory balance,
    Balances.RateAcc memory total
  ) private pure {
    if (newRate > lastRate) {
      unchecked {
        newRate = newRate - lastRate;
      }
      require((balance.rateValue += newRate) >= newRate);
      total.rate += newRate;
    } else {
      unchecked {
        newRate = lastRate - newRate;
      }
      balance.rateValue -= newRate;
      total.rate -= newRate;
    }

    balance.applyFrom = _applyRateFrom(lastRate, newRate, balance.applyFrom, total.updatedAt);
  }

  function _replenishAsset(
    AssetBalancer storage p,
    ReplenishParams memory params,
    CalcParams memory c,
    AssetBalance memory assetBalance,
    Balances.RateAcc memory total
  ) private returns (uint256) {
    require(total.updatedAt == block.timestamp);

    (uint256 receivedAmount, uint256 receivedValue, uint256 expectedValue) = params.replenishFn(params, c.extraTotal);
    if (receivedAmount == 0) {
      if (expectedValue == 0) {
        return 0;
      }
      receivedValue = 0;
    }

    uint256 v = receivedValue * WadRayMath.WAD + uint256(assetBalance.accumAmount) * c.vA;
    {
      total.accum = uint128(total.accum - expectedValue);
      require((total.accum += uint128(receivedValue)) >= receivedValue);
      require((assetBalance.accumAmount += uint128(receivedAmount)) >= receivedAmount);
    }

    if (assetBalance.accumAmount == 0) {
      v = expectedValue = 0;
    } else {
      v = v.divUp(assetBalance.accumAmount);
    }
    if (v != c.vA) {
      require((c.vA = p.configs[params.token].price = uint152(v)) == v);
    }

    _applyRateFromBalanceUpdate(expectedValue, assetBalance, total);

    return receivedValue;
  }

  function _applyRateFromBalanceUpdate(
    uint256 expectedValue,
    AssetBalance memory assetBalance,
    Balances.RateAcc memory total
  ) private pure {
    if (assetBalance.applyFrom == 0 || assetBalance.rateValue == 0) {
      assetBalance.applyFrom = total.updatedAt;
    } else if (expectedValue > 0) {
      uint256 d = assetBalance.applyFrom + (uint256(expectedValue) + assetBalance.rateValue - 1) / assetBalance.rateValue;
      assetBalance.applyFrom = d < total.updatedAt ? uint32(d) : total.updatedAt;
    }
  }

  function _applyRateFrom(
    uint256 oldRate,
    uint256 newRate,
    uint32 applyFrom,
    uint32 current
  ) private pure returns (uint32) {
    if (oldRate == 0 || newRate == 0 || applyFrom == 0) {
      return current;
    }
    uint256 d = (oldRate * uint256(current - applyFrom) + newRate - 1) / newRate;
    return d >= current ? 1 : uint32(current - d);
  }

  function decRate(
    AssetBalancer storage p,
    address targetToken,
    uint96 lastRate
  ) internal returns (uint96 rate) {
    AssetBalance storage balance = p.balances[targetToken];
    rate = balance.rateValue;

    if (lastRate > 0) {
      Balances.RateAcc memory total = _syncTotalBalance(p);

      total.rate -= lastRate;
      p.totalBalance = total;

      (lastRate, rate) = (rate, rate - lastRate);
      (balance.rateValue, balance.applyFrom) = (rate, _applyRateFrom(lastRate, rate, balance.applyFrom, total.updatedAt));
    }
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

import './IPriceRouter.sol';

interface IManagedPriceRouter is IPriceRouter {
  function getPriceSource(address asset) external view returns (PriceSource memory result);

  function getPriceSources(address[] calldata assets) external view returns (PriceSource[] memory result);

  function setPriceSources(address[] calldata assets, PriceSource[] calldata prices) external;

  function setStaticPrices(address[] calldata assets, uint256[] calldata prices) external;

  function setSafePriceRanges(
    address[] calldata assets,
    uint256[] calldata targetPrices,
    uint16[] calldata tolerancePcts
  ) external;

  function getPriceSourceRange(address asset) external view returns (uint256 targetPrice, uint16 tolerancePct);

  function attachSource(address asset, bool attach) external;

  function configureSourceGroup(address account, uint256 mask) external;

  function resetSourceGroup() external;

  function resetSourceGroupByAdmin(uint256 mask) external;
}

enum PriceFeedType {
  StaticValue,
  ChainLinkV3,
  UniSwapV2Pair
}

struct PriceSource {
  PriceFeedType feedType;
  address feedContract;
  uint256 feedConstValue;
  uint8 decimals;
  address crossPrice;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './IFallbackPriceOracle.sol';

interface IPriceRouter is IFallbackPriceOracle {
  function getAssetPrices(address[] calldata asset) external view returns (uint256[] memory);

  function pullAssetPrice(address asset, uint256 fuseMask) external returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IFallbackPriceOracle {
  function getQuoteAsset() external view returns (address);

  function getAssetPrice(address asset) external view returns (uint256);
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

  function borrowManager() external view returns (address); // ICollateralStakeManager
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface ICollateralized {
  /// @dev address of the collateral fund and coverage token ($CC)
  function collateral() external view returns (address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

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

  function asUint224(uint256 x) internal pure returns (uint224) {
    require(x <= type(uint224).max);
    return uint224(x);
  }

  function asUint216(uint256 x) internal pure returns (uint216) {
    require(x <= type(uint216).max);
    return uint216(x);
  }

  function asUint128(uint256 x) internal pure returns (uint128) {
    require(x <= type(uint128).max);
    return uint128(x);
  }

  function asUint112(uint256 x) internal pure returns (uint112) {
    require(x <= type(uint112).max);
    return uint112(x);
  }

  function asUint96(uint256 x) internal pure returns (uint96) {
    require(x <= type(uint96).max);
    return uint96(x);
  }

  function asInt128(uint256 v) internal pure returns (int128) {
    require(v <= type(uint128).max);
    return int128(uint128(v));
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
      require(denominator > 0);
      assembly {
        result := div(prod0, denominator)
      }
      return result;
    }

    // Make sure the result is less than 2**256.
    // Also prevents denominator == 0
    require(denominator > prod1);

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