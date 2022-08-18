// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../tools/upgradeability/VersionedInitializable.sol';
import './PriceGuardOracleBase.sol';

contract OracleRouterV1 is VersionedInitializable, PriceGuardOracleBase {
  uint256 private constant CONTRACT_REVISION = 1;

  constructor(IAccessController acl, address quote) PriceGuardOracleBase(acl, quote) {}

  function initializePriceOracle() public initializer(CONTRACT_REVISION) {}

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

import '../tools/Errors.sol';
import '../tools/math/PercentageMath.sol';
import '../tools/math/WadRayMath.sol';
import '../access/AccessHelper.sol';
import './interfaces/IManagedPriceRouter.sol';
import './interfaces/IPriceFeedChainlinkV3.sol';
import './interfaces/IPriceFeedUniswapV2.sol';
import './OracleRouterBase.sol';
import './FuseBox.sol';

contract PriceGuardOracleBase is OracleRouterBase, FuseBox {
  using WadRayMath for uint256;
  using PercentageMath for uint256;

  uint8 private constant EF_LIMIT_BREACHED_STICKY = 1 << 0;

  constructor(IAccessController acl, address quote) AccessHelper(acl) OracleRouterBase(quote) {}

  event SourceTripped(address indexed asset, uint256 price);

  function pullAssetPrice(address asset, uint256 fuseMask) external override returns (uint256) {
    if (asset == getQuoteAsset()) {
      return WadRayMath.WAD;
    }

    (uint256 v, uint8 flags) = internalReadSource(asset);

    if (v == 0) {
      revert Errors.UnknownPriceAsset(asset);
    }

    if (internalHasAnyBlownFuse(fuseMask)) {
      revert Errors.ExcessiveVolatilityLock(fuseMask);
    }

    if (flags & EF_LIMIT_BREACHED != 0) {
      if (flags & EF_LIMIT_BREACHED_STICKY == 0) {
        emit SourceTripped(asset, v);
        internalSetCustomFlags(asset, 0, EF_LIMIT_BREACHED_STICKY);
      }
      internalBlowFuses(asset);
      v = 0;
    } else if (flags & EF_LIMIT_BREACHED_STICKY != 0) {
      if (internalHasAnyBlownFuse(asset)) {
        v = 0;
      } else {
        internalSetCustomFlags(asset, EF_LIMIT_BREACHED_STICKY, 0);
      }
    }

    return v;
  }

  event SourceToGroupsAdded(address indexed asset, uint256 mask);
  event SourceFromGroupsRemoved(address indexed asset, uint256 mask);

  function attachSource(address asset, bool attach) external override {
    Value.require(asset != address(0));

    uint256 maskSet = internalGetOwnedFuses(msg.sender);
    uint256 maskUnset;
    if (maskSet != 0) {
      if (attach) {
        emit SourceToGroupsAdded(asset, maskSet);
      } else {
        (maskSet, maskUnset) = (0, maskSet);
        emit SourceFromGroupsRemoved(asset, maskUnset);
      }
      internalSetFuses(asset, maskUnset, maskSet);
    }
  }

  function resetSourceGroup() external override {
    uint256 mask = internalGetOwnedFuses(msg.sender);
    if (mask != 0) {
      internalResetFuses(mask);
      emit SourceGroupResetted(msg.sender, mask);
    }
  }

  function internalResetGroup(uint256 mask) internal override {
    internalResetFuses(mask);
  }

  function internalRegisterGroup(address account, uint256 mask) internal override {
    internalSetOwnedFuses(account, mask);
  }

  function groupsOf(address account) external view override returns (uint256 memberOf, uint256 ownerOf) {
    return (internalGetFuses(account), internalGetOwnedFuses(account));
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

interface IPriceFeedChainlinkV3 {
  // aka AggregatorV3Interface
  // function decimals() external view returns (uint8);

  // function description() external view returns (string memory);

  // function version() external view returns (uint256);

  // // getRoundData and latestRoundData should both raise "No data present"
  // // if they do not have data to report, instead of returning unset values
  // // which could be misinterpreted as actual reported values.
  // function getRoundData(uint80 _roundId)
  //   external
  //   view
  //   returns (
  //     uint80 roundId,
  //     int256 answer,
  //     uint256 startedAt,
  //     uint256 updatedAt,
  //     uint80 answeredInRound
  //   );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IPriceFeedUniswapV2 {
  function token0() external view returns (address);

  function token1() external view returns (address);

  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );
  // function price0CumulativeLast() external view returns (uint);
  // function price1CumulativeLast() external view returns (uint);
  // function kLast() external view returns (uint);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../tools/Errors.sol';
import '../tools/math/PercentageMath.sol';
import '../tools/math/WadRayMath.sol';
import '../access/AccessHelper.sol';
import './interfaces/IManagedPriceRouter.sol';
import './interfaces/IPriceFeedChainlinkV3.sol';
import './interfaces/IPriceFeedUniswapV2.sol';
import './PriceSourceBase.sol';

// @dev All prices given out have 18 decimals
abstract contract OracleRouterBase is IManagedPriceRouter, AccessHelper, PriceSourceBase {
  using WadRayMath for uint256;
  using PercentageMath for uint256;

  address private immutable _quote;

  constructor(address quote) {
    _quote = quote;
  }

  function _onlyOracleAdmin() private view {
    if (!hasAnyAcl(msg.sender, AccessFlags.PRICE_ROUTER_ADMIN)) {
      revert Errors.CallerNotOracleAdmin();
    }
  }

  modifier onlyOracleAdmin() {
    _onlyOracleAdmin();
    _;
  }

  uint8 private constant CF_UNISWAP_V2_RESERVE = 1 << 0;

  function getQuoteAsset() public view returns (address) {
    return _quote;
  }

  function getAssetPrice(address asset) public view override returns (uint256) {
    if (asset == _quote) {
      return WadRayMath.WAD;
    }

    (uint256 v, ) = internalReadSource(asset);

    if (v == 0) {
      revert Errors.UnknownPriceAsset(asset);
    }

    return v;
  }

  function getAssetPrices(address[] calldata assets) external view override returns (uint256[] memory result) {
    result = new uint256[](assets.length);
    for (uint256 i = assets.length; i > 0; ) {
      i--;
      result[i] = getAssetPrice(assets[i]);
    }
    return result;
  }

  error UnknownPriceFeedType(uint8);

  function internalGetHandler(uint8 callType)
    internal
    pure
    override
    returns (function(uint8, address, address) internal view returns (uint256, uint32))
  {
    if (callType == uint8(PriceFeedType.ChainLinkV3)) {
      return _readChainlink;
    } else if (callType == uint8(PriceFeedType.UniSwapV2Pair)) {
      return _readUniswapV2;
    }
    revert UnknownPriceFeedType(callType);
  }

  function _readChainlink(
    uint8,
    address feed,
    address
  ) private view returns (uint256, uint32) {
    (, int256 v, , uint256 at, ) = IPriceFeedChainlinkV3(feed).latestRoundData();
    return (uint256(v), uint32(at));
  }

  function _readUniswapV2(
    uint8 callFlags,
    address feed,
    address
  ) private view returns (uint256 v0, uint32 at) {
    uint256 v1;
    (v0, v1, at) = IPriceFeedUniswapV2(feed).getReserves();
    if (v0 != 0) {
      if (callFlags & CF_UNISWAP_V2_RESERVE != 0) {
        (v0, v1) = (v1, v0);
      }
      v0 = v1.wadDiv(v0);
    }
  }

  // slither-disable-next-line calls-loop
  function _setupUniswapV2(address feed, address token) private view returns (uint8 callFlags) {
    if (token == IPriceFeedUniswapV2(feed).token1()) {
      return CF_UNISWAP_V2_RESERVE;
    }
    Value.require(token == IPriceFeedUniswapV2(feed).token0());
  }

  function _getPriceSource(address asset, PriceSource memory result)
    private
    view
    returns (
      bool ok,
      uint8 decimals,
      address crossPrice,
      uint32 maxValidity,
      uint8 flags
    )
  {
    bool staticPrice;
    (ok, decimals, crossPrice, maxValidity, flags, staticPrice) = internalGetConfig(asset);

    if (ok) {
      result.decimals = decimals;
      result.crossPrice = crossPrice;
      // result.maxValidity = maxValidity;

      if (staticPrice) {
        result.feedType = PriceFeedType.StaticValue;
        (result.feedConstValue, ) = internalGetStatic(asset);
      } else {
        uint8 callType;
        (callType, result.feedContract, , , ) = internalGetSource(asset);
        result.feedType = PriceFeedType(callType);
      }
    }
  }

  function getPriceSource(address asset) external view returns (PriceSource memory result) {
    _getPriceSource(asset, result);
  }

  function getPriceSources(address[] calldata assets) external view returns (PriceSource[] memory result) {
    result = new PriceSource[](assets.length);
    for (uint256 i = assets.length; i > 0; ) {
      i--;
      _getPriceSource(assets[i], result[i]);
    }
  }

  /// @param sources  If using a Uniswap price, the decimals field must compensate for tokens that
  ///                 do not have the same as the quote asset decimals.
  ///                 If the quote asset has 18 decimals:
  ///                   If a token has 9 decimals, it must set the decimals value to (9 + 18) = 27
  ///                   If a token has 27 decimals, it must set the decimals value to (27 - 18) = 9
  function setPriceSources(address[] calldata assets, PriceSource[] calldata sources) external onlyOracleAdmin {
    for (uint256 i = assets.length; i > 0; ) {
      i--;
      _setPriceSource(assets[i], sources[i]);
    }
  }

  /// @dev When an asset was configured before, then this call assumes the price to have same decimals, otherwise 18
  function setStaticPrices(address[] calldata assets, uint256[] calldata prices) external onlyOracleAdmin {
    for (uint256 i = assets.length; i > 0; ) {
      i--;
      _setStaticValue(assets[i], prices[i]);
    }
  }

  event SourceStaticUpdated(address indexed asset, uint256 value);
  event SourceStaticConfigured(address indexed asset, uint256 value, uint8 decimals, address xPrice);
  event SourceFeedConfigured(address indexed asset, address source, uint8 decimals, address xPrice, uint8 feedType, uint8 callFlags);

  function _setStaticValue(address asset, uint256 value) private {
    Value.require(asset != _quote);

    internalSetStatic(asset, value, 0);
    emit SourceStaticUpdated(asset, value);
  }

  function _setPriceSource(address asset, PriceSource calldata source) private {
    Value.require(asset != _quote);

    if (source.feedType == PriceFeedType.StaticValue) {
      internalSetStatic(asset, source.feedConstValue, 0);

      emit SourceStaticConfigured(asset, source.feedConstValue, source.decimals, source.crossPrice);
    } else {
      uint8 callFlags;
      if (source.feedType == PriceFeedType.UniSwapV2Pair) {
        callFlags = _setupUniswapV2(source.feedContract, asset);
      }
      internalSetSource(asset, uint8(source.feedType), source.feedContract, callFlags);

      emit SourceFeedConfigured(asset, source.feedContract, source.decimals, source.crossPrice, uint8(source.feedType), callFlags);
    }
    internalSetConfig(asset, source.decimals, source.crossPrice, 0);
  }

  event PriceRangeUpdated(address indexed asset, uint256 targetPrice, uint16 tolerancePct);

  function setSafePriceRanges(
    address[] calldata assets,
    uint256[] calldata targetPrices,
    uint16[] calldata tolerancePcts
  ) external override onlyOracleAdmin {
    Value.require(assets.length == targetPrices.length);
    Value.require(assets.length == tolerancePcts.length);
    for (uint256 i = assets.length; i > 0; ) {
      i--;
      address asset = assets[i];
      Value.require(asset != address(0) && asset != _quote);

      uint256 targetPrice = targetPrices[i];
      uint16 tolerancePct = tolerancePcts[i];

      internalSetPriceTolerance(asset, targetPrice, tolerancePct);
      emit PriceRangeUpdated(asset, targetPrice, tolerancePct);
    }
  }

  function getPriceSourceRange(address asset) external view override returns (uint256 targetPrice, uint16 tolerancePct) {
    (, , , targetPrice, tolerancePct) = internalGetSource(asset);
  }

  event SourceGroupResetted(address indexed account, uint256 mask);

  function resetSourceGroupByAdmin(uint256 mask) external override onlyOracleAdmin {
    internalResetGroup(mask);
    emit SourceGroupResetted(address(0), mask);
  }

  function internalResetGroup(uint256 mask) internal virtual;

  function internalRegisterGroup(address account, uint256 mask) internal virtual;

  event SourceGroupConfigured(address indexed account, uint256 mask);

  function configureSourceGroup(address account, uint256 mask) external override onlyOracleAdmin {
    Value.require(account != address(0));
    internalRegisterGroup(account, mask);
    emit SourceGroupConfigured(account, mask);
  }

  function groupsOf(address) external view virtual returns (uint256 memberOf, uint256 ownerOf);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../tools/Errors.sol';
import '../tools/math/PercentageMath.sol';
import '../tools/math/WadRayMath.sol';
import './interfaces/IManagedPriceRouter.sol';

abstract contract FuseBox {
  using WadRayMath for uint256;
  using PercentageMath for uint256;

  mapping(address => uint256) private _fuseOwners;
  mapping(address => uint256) private _fuseMasks;
  uint256 private _fuseBox;

  function internalBlowFuses(address addr) internal returns (bool blown) {
    uint256 mask = _fuseMasks[addr];
    if (mask != 0) {
      uint256 fuseBox = _fuseBox;
      if ((mask &= ~fuseBox) != 0) {
        _fuseBox = fuseBox | mask;
        internalFuseBlown(addr, fuseBox, mask);
        blown = true;
      }
    }
  }

  function internalFuseBlown(
    address addr,
    uint256 fuseBoxBefore,
    uint256 blownFuses
  ) internal virtual {}

  function internalSetFuses(
    address addr,
    uint256 unsetMask,
    uint256 setMask
  ) internal {
    if ((unsetMask = ~unsetMask) != 0) {
      setMask |= _fuseMasks[addr] & unsetMask;
    }
    _fuseMasks[addr] = setMask;
  }

  function internalGetFuses(address addr) internal view returns (uint256) {
    return _fuseMasks[addr];
  }

  function internalHasAnyBlownFuse(uint256 mask) internal view returns (bool) {
    return mask != 0 && (mask & _fuseBox != 0);
  }

  function internalHasAnyBlownFuse(address addr) internal view returns (bool) {
    return internalHasAnyBlownFuse(_fuseMasks[addr]);
  }

  function internalHasAnyBlownFuse(address addr, uint256 mask) internal view returns (bool) {
    return mask != 0 && internalHasAnyBlownFuse(mask & _fuseMasks[addr]);
  }

  function internalGetOwnedFuses(address owner) internal view returns (uint256) {
    return _fuseOwners[owner];
  }

  function internalResetFuses(uint256 mask) internal {
    _fuseBox &= ~mask;
  }

  function internalIsOwnerOfAllFuses(address owner, uint256 mask) internal view returns (bool) {
    return mask & ~_fuseOwners[owner] == 0;
  }

  function internalSetOwnedFuses(address owner, uint256 mask) internal {
    _fuseOwners[owner] = mask;
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

import '../tools/Errors.sol';
import '../tools/math/PercentageMath.sol';
import '../tools/math/WadRayMath.sol';

abstract contract PriceSourceBase {
  using WadRayMath for uint256;
  using PercentageMath for uint256;

  // struct Source {
  //   uint4 sourceType;
  //   uint6 decimals;
  //   uint6 internalFlags;
  //   uint8 maxValidity; // minutes

  //   address source;
  //   uint8 callFlags;

  //   uint8 tolerance;
  //   uint56 target;
  // }

  uint8 private constant SOURCE_TYPE_OFS = 0;
  uint8 private constant SOURCE_TYPE_BIT = 4;
  uint256 private constant SOURCE_TYPE_MASK = (2**SOURCE_TYPE_BIT) - 1;

  uint8 private constant DECIMALS_OFS = SOURCE_TYPE_OFS + SOURCE_TYPE_BIT;
  uint8 private constant DECIMALS_BIT = 6;
  uint256 private constant DECIMALS_MASK = (2**DECIMALS_BIT) - 1;

  uint8 private constant FLAGS_OFS = DECIMALS_OFS + DECIMALS_BIT;
  uint8 private constant FLAGS_BIT = 6;
  uint256 private constant FLAGS_MASK = (2**FLAGS_BIT) - 1;

  uint256 private constant FLAG_CROSS_PRICED = 1 << (FLAGS_OFS + FLAGS_BIT - 1);
  uint8 internal constant EF_LIMIT_BREACHED = uint8(FLAG_CROSS_PRICED >> FLAGS_OFS);
  uint8 private constant CUSTOM_FLAG_MASK = EF_LIMIT_BREACHED - 1;

  uint8 private constant VALIDITY_OFS = FLAGS_OFS + FLAGS_BIT;
  uint8 private constant VALIDITY_BIT = 8;
  uint256 private constant VALIDITY_MASK = (2**VALIDITY_BIT) - 1;

  uint8 private constant PAYLOAD_OFS = VALIDITY_OFS + VALIDITY_BIT;

  uint8 private constant FEED_POST_PAYLOAD_OFS = PAYLOAD_OFS + 160 + 8;
  uint256 private constant FEED_PAYLOAD_CONFIG_AND_SOURCE_TYPE_MASK = (uint256(1) << FEED_POST_PAYLOAD_OFS) - 1;

  uint256 private constant MAX_STATIC_VALUE = (type(uint256).max << (PAYLOAD_OFS + 32)) >> (PAYLOAD_OFS + 32);

  uint256 private constant CONFIG_AND_SOURCE_TYPE_MASK = (uint256(1) << PAYLOAD_OFS) - 1;
  uint256 private constant CONFIG_MASK = CONFIG_AND_SOURCE_TYPE_MASK & ~SOURCE_TYPE_MASK;
  uint256 private constant INVERSE_CONFIG_MASK = ~CONFIG_MASK;

  // struct StaticSource {
  //   uint8 sourceType == 0;
  //   uint6 decimals;
  //   uint6 internalFlags;
  //   uint8 maxValidity; // minutes

  //   uint32 updatedAt;
  //   uint200 staticValue;
  // }

  struct CallHandler {
    function(uint8, address, address) internal view returns (uint256, uint32) handler;
  }

  mapping(address => uint256) private _encodedSources;
  mapping(address => address) private _crossTokens;
  mapping(address => uint256) private _fuseMasks;

  function internalReadSource(address token) internal view returns (uint256, uint8) {
    return _readSource(token, true);
  }

  function _readSource(address token, bool notNested) private view returns (uint256, uint8 resultFlags) {
    uint256 encoded = _encodedSources[token];
    if (encoded == 0) {
      return (0, 0);
    }

    uint8 callType = uint8(encoded & SOURCE_TYPE_MASK);

    (uint256 v, uint32 t) = callType != 0 ? _callSource(callType, encoded, token) : _callStatic(encoded);

    uint8 maxValidity = uint8(encoded >> VALIDITY_OFS);
    require(maxValidity == 0 || t == 0 || t + maxValidity * 1 minutes >= block.timestamp);

    resultFlags = uint8((encoded >> FLAGS_OFS) & FLAGS_MASK);
    uint8 decimals = uint8(((encoded >> DECIMALS_OFS) + 18) & DECIMALS_MASK);

    if (encoded & FLAG_CROSS_PRICED != 0) {
      State.require(notNested);
      uint256 vc;
      (vc, ) = _readSource(_crossTokens[token], false);
      v *= vc;
      decimals += 18;
    }

    if (decimals > 18) {
      v = v.divUp(10**uint8(decimals - 18));
    } else {
      v *= 10**uint8(18 - decimals);
    }

    if (callType != 0 && _checkLimits(v, encoded)) {
      resultFlags |= EF_LIMIT_BREACHED;
    }

    return (v, resultFlags);
  }

  uint256 private constant TARGET_UNIT = 10**9;
  uint256 private constant TOLERANCE_ONE = 800;

  function _callSource(
    uint8 callType,
    uint256 encoded,
    address token
  ) private view returns (uint256 v, uint32 t) {
    return internalGetHandler(callType)(uint8(encoded >> (PAYLOAD_OFS + 160)), address(uint160(encoded >> PAYLOAD_OFS)), token);
  }

  function _checkLimits(uint256 v, uint256 encoded) private pure returns (bool) {
    encoded >>= FEED_POST_PAYLOAD_OFS;
    uint8 tolerance = uint8(encoded);
    uint256 target = encoded >> 8;
    target *= TARGET_UNIT;

    v = v > target ? v - target : target - v;
    return (v * TOLERANCE_ONE > target * tolerance);
  }

  function _callStatic(uint256 encoded) private pure returns (uint256 v, uint32 t) {
    encoded >>= PAYLOAD_OFS;
    return (encoded >> 32, uint32(encoded));
  }

  function internalGetHandler(uint8 callType)
    internal
    view
    virtual
    returns (function(uint8, address, address) internal view returns (uint256, uint32));

  function internalSetStatic(
    address token,
    uint256 value,
    uint32 since
  ) internal {
    uint256 encoded = _encodedSources[token];
    require(value <= MAX_STATIC_VALUE);

    if (value == 0) {
      since = 0;
    } else if (since == 0) {
      since = uint32(block.timestamp);
    }

    value = (value << 32) | since;
    _encodedSources[token] = (value << PAYLOAD_OFS) | (encoded & CONFIG_MASK);
  }

  function internalUnsetSource(address token) internal {
    delete _encodedSources[token];
  }

  function internalSetCustomFlags(
    address token,
    uint8 unsetFlags,
    uint8 setFlags
  ) internal {
    Value.require((unsetFlags | setFlags) <= CUSTOM_FLAG_MASK);

    uint256 encoded = _encodedSources[token];

    if (unsetFlags != 0) {
      encoded &= ~(uint256(unsetFlags) << FLAGS_OFS);
    }
    encoded |= uint256(setFlags) << FLAGS_OFS;

    _encodedSources[token] = encoded;
  }

  function internalSetSource(
    address token,
    uint8 callType,
    address feed,
    uint8 callFlags
  ) internal {
    Value.require(feed != address(0));
    Value.require(callType > 0 && callType <= SOURCE_TYPE_MASK);

    internalGetHandler(callType);

    uint256 encoded = _encodedSources[token] & CONFIG_MASK;
    encoded |= callType | (((uint256(callFlags) << 160) | uint160(feed)) << PAYLOAD_OFS);

    _encodedSources[token] = encoded;
  }

  function internalSetPriceTolerance(
    address token,
    uint256 targetPrice,
    uint16 tolerancePct
  ) internal {
    uint256 encoded = _encodedSources[token];
    State.require(encoded & SOURCE_TYPE_MASK != 0);

    uint256 v;
    if (targetPrice != 0) {
      v = uint256(tolerancePct).percentMul(TOLERANCE_ONE);
      Value.require(v <= type(uint8).max);

      targetPrice = targetPrice.divUp(TARGET_UNIT);
      Value.require(targetPrice > 0);
      v |= targetPrice << 8;

      v <<= FEED_POST_PAYLOAD_OFS;
    }

    _encodedSources[token] = v | (encoded & FEED_PAYLOAD_CONFIG_AND_SOURCE_TYPE_MASK);
  }

  function _ensureCrossPriceToken(address crossPrice) private view {
    uint256 encoded = _encodedSources[crossPrice];

    Value.require(encoded != 0);
    State.require(encoded & FLAG_CROSS_PRICED == 0);
    State.require(_crossTokens[crossPrice] == crossPrice);
  }

  function internalSetConfig(
    address token,
    uint8 decimals,
    address crossPrice,
    uint32 maxValidity
  ) internal {
    uint256 encoded = _encodedSources[token];
    State.require(encoded != 0);

    Value.require(decimals <= DECIMALS_MASK);
    decimals = uint8(((DECIMALS_MASK - 17) + decimals) & DECIMALS_MASK);

    maxValidity = maxValidity == type(uint32).max ? 0 : (maxValidity + 1 minutes - 1) / 1 minutes;
    Value.require(maxValidity <= type(uint8).max);

    if (crossPrice != address(0) && crossPrice != token) {
      _ensureCrossPriceToken(crossPrice);
      encoded |= FLAG_CROSS_PRICED;
    } else {
      encoded &= ~FLAG_CROSS_PRICED;
    }

    encoded &= ~(VALIDITY_MASK << VALIDITY_OFS) | (DECIMALS_MASK << DECIMALS_OFS);
    _encodedSources[token] = encoded | (uint256(maxValidity) << VALIDITY_OFS) | (uint256(decimals) << DECIMALS_OFS);
    _crossTokens[token] = crossPrice;
  }

  function internalGetConfig(address token)
    internal
    view
    returns (
      bool ok,
      uint8 decimals,
      address crossPrice,
      uint32 maxValidity,
      uint8 flags,
      bool staticPrice
    )
  {
    uint256 encoded = _encodedSources[token];
    if (encoded != 0) {
      ok = true;
      staticPrice = encoded & SOURCE_TYPE_MASK == 0;

      decimals = uint8(((encoded >> DECIMALS_OFS) + 18) & DECIMALS_MASK);
      maxValidity = uint8(encoded >> VALIDITY_OFS);

      if (encoded & FLAG_CROSS_PRICED != 0) {
        crossPrice = _crossTokens[token];
      }

      flags = uint8((encoded >> FLAGS_OFS) & CUSTOM_FLAG_MASK);
    }
  }

  function internalGetSource(address token)
    internal
    view
    returns (
      uint8 callType,
      address feed,
      uint8 callFlags,
      uint256 target,
      uint16 tolerance
    )
  {
    uint256 encoded = _encodedSources[token];
    if (encoded != 0) {
      State.require((callType = uint8(encoded & SOURCE_TYPE_MASK)) != 0);
      encoded >>= PAYLOAD_OFS;

      feed = address(uint160(encoded));
      encoded >>= 160;
      callFlags = uint8(encoded);
      encoded >>= 8;

      tolerance = uint16(uint256(uint8(encoded)).percentDiv(TOLERANCE_ONE));
      target = (encoded >> 8) * TARGET_UNIT;
    }
  }

  function internalGetStatic(address token) internal view returns (uint256, uint32) {
    uint256 encoded = _encodedSources[token];
    State.require(encoded & SOURCE_TYPE_MASK == 0);
    encoded >>= PAYLOAD_OFS;

    return (encoded >> 32, uint32(encoded));
  }
}