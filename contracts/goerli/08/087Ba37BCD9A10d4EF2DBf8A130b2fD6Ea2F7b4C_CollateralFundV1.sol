// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../tools/upgradeability/VersionedInitializable.sol';
import '../interfaces/ICollateralFundInit.sol';
import './CollateralFundBase.sol';

contract CollateralFundV1 is VersionedInitializable, ICollateralFundInit, CollateralFundBase {
  uint256 private constant CONTRACT_REVISION = 1;

  constructor(
    IAccessController acl,
    address collateral_,
    uint256 sourceFuses
  ) CollateralFundBase(acl, collateral_, sourceFuses) {}

  function initializeCollateralFund() public override initializer(CONTRACT_REVISION) {}

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

interface ICollateralFundInit {
  function initializeCollateralFund() external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '../tools/SafeERC20.sol';
import '../tools/math/WadRayMath.sol';
import '../tools/math/PercentageMath.sol';
import '../interfaces/IManagedCollateralCurrency.sol';
import '../interfaces/ICollateralStakeManager.sol';
import '../pricing/PricingHelper.sol';
import '../access/AccessHelper.sol';
import './interfaces/ICollateralFund.sol';
import './Collateralized.sol';

// TODO:TEST tests for zero return on price lockup

abstract contract CollateralFundBase is ICollateralFund, AccessHelper, PricingHelper {
  using SafeERC20 for IERC20;
  using WadRayMath for uint256;
  using PercentageMath for uint256;
  using EnumerableSet for EnumerableSet.AddressSet;

  IManagedCollateralCurrency private immutable _collateral;
  uint256 private immutable _sourceFuses;

  constructor(
    IAccessController acl,
    address collateral_,
    uint256 sourceFuses
  ) AccessHelper(acl) PricingHelper(_getPricerByAcl(acl)) {
    _collateral = IManagedCollateralCurrency(collateral_);
    _sourceFuses = sourceFuses;
  }

  struct CollateralAsset {
    uint8 assetFlags;
    address trustee;
  }

  struct BorrowBalance {
    uint128 amount;
    uint128 value;
  }

  uint8 private constant AF_ADDED = 1 << 7;

  EnumerableSet.AddressSet private _tokens;
  mapping(address => CollateralAsset) private _assets; // [token]
  mapping(address => mapping(address => BorrowBalance)) private _borrowedBalances; // [token][borrower]
  mapping(address => mapping(address => uint256)) private _approvals; // [owner][delegate]

  function _onlyApproved(
    address operator,
    address account,
    uint256 access
  ) private view {
    Access.require(operator == account || isApprovedFor(account, operator, access));
  }

  function _onlySpecial(address account, uint256 access) private view {
    Access.require(isApprovedFor(address(0), account, access));
  }

  modifier onlySpecial(address account, uint256 access) {
    _onlySpecial(account, access);
    _;
  }

  function remoteAcl() internal view override(AccessHelper, PricingHelper) returns (IAccessController pricer) {
    return AccessHelper.remoteAcl();
  }

  event ApprovalFor(address indexed owner, address indexed operator, uint256 approved);

  function setApprovalsFor(
    address operator,
    uint256 access,
    bool approved
  ) external override {
    uint256 flags;
    if (approved) {
      flags = (_approvals[msg.sender][operator] |= access);
    } else {
      flags = (_approvals[msg.sender][operator] &= ~access);
    }
    emit ApprovalFor(msg.sender, operator, flags);
  }

  function collateral() public view override returns (address) {
    return address(_collateral);
  }

  function setAllApprovalsFor(address operator, uint256 access) external override {
    _approvals[msg.sender][operator] = access;
    emit ApprovalFor(msg.sender, operator, access);
  }

  function getAllApprovalsFor(address account, address operator) public view override returns (uint256) {
    return _approvals[account][operator];
  }

  function isApprovedFor(
    address account,
    address operator,
    uint256 access
  ) public view override returns (bool) {
    return _approvals[account][operator] & access == access;
  }

  event SpecialApprovalFor(address indexed operator, uint256 approved);

  function internalSetSpecialApprovals(address operator, uint256 access) internal {
    _approvals[address(0)][operator] = access;
    emit SpecialApprovalFor(operator, access);
  }

  event TrusteeUpdated(address indexed token, address indexed trustedOperator);

  function internalSetTrustee(address token, address trustee) internal {
    CollateralAsset storage asset = _assets[token];
    State.require(asset.assetFlags & AF_ADDED != 0);
    asset.trustee = trustee;
    emit TrusteeUpdated(token, trustee);
  }

  function internalSetFlags(address token, uint8 flags) internal {
    CollateralAsset storage asset = _assets[token];
    State.require(asset.assetFlags & AF_ADDED != 0 && _tokens.contains(token));
    asset.assetFlags = AF_ADDED | flags;
  }

  event AssetAdded(address indexed token);
  event AssetRemoved(address indexed token);

  function internalAddAsset(address token, address trustee) internal virtual {
    Value.require(token != address(0));
    State.require(_tokens.add(token));

    _assets[token] = CollateralAsset({assetFlags: type(uint8).max, trustee: trustee});
    _attachSource(token, true);

    emit AssetAdded(token);
    if (trustee != address(0)) {
      emit TrusteeUpdated(token, trustee);
    }
  }

  function internalRemoveAsset(address token) internal {
    if (token != address(0) && _tokens.remove(token)) {
      CollateralAsset storage asset = _assets[token];
      asset.assetFlags = AF_ADDED;
      _attachSource(token, false);

      emit AssetRemoved(token);
    }
  }

  function _attachSource(address token, bool set) private {
    IManagedPriceRouter pricer = getPricer();
    if (address(pricer) != address(0)) {
      pricer.attachSource(token, set);
    }
  }

  function deposit(
    address account,
    address token,
    uint256 tokenAmount
  ) external override returns (uint256) {
    _ensureApproved(account, token, CollateralFundLib.APPROVED_DEPOSIT);
    return _depositAndMint(msg.sender, account, token, tokenAmount);
  }

  function invest(
    address account,
    address token,
    uint256 tokenAmount,
    address investTo
  ) external override returns (uint256) {
    _ensureApproved(account, token, CollateralFundLib.APPROVED_DEPOSIT | CollateralFundLib.APPROVED_INVEST);
    return _depositAndInvest(msg.sender, account, 0, token, tokenAmount, investTo);
  }

  function investIncludingDeposit(
    address account,
    uint256 depositValue,
    address token,
    uint256 tokenAmount,
    address investTo
  ) external override returns (uint256) {
    _ensureApproved(
      account,
      token,
      tokenAmount > 0 ? CollateralFundLib.APPROVED_DEPOSIT | CollateralFundLib.APPROVED_INVEST : CollateralFundLib.APPROVED_INVEST
    );
    return _depositAndInvest(msg.sender, account, depositValue, token, tokenAmount, investTo);
  }

  function internalPriceOf(address token) internal virtual returns (uint256) {
    return getPricer().pullAssetPrice(token, _sourceFuses);
  }

  function withdraw(
    address account,
    address to,
    address token,
    uint256 amount
  ) external override returns (uint256) {
    _ensureApproved(account, token, CollateralFundLib.APPROVED_WITHDRAW);
    return _withdraw(account, to, token, amount);
  }

  event AssetWithdrawn(address indexed token, address indexed account, uint256 amount, uint256 value);

  function _withdraw(
    address from,
    address to,
    address token,
    uint256 amount
  ) private returns (uint256) {
    if (amount > 0) {
      uint256 value;
      if (amount == type(uint256).max) {
        value = _collateral.balanceOf(from);
        if (value > 0) {
          uint256 price = internalPriceOf(token);
          if (price != 0) {
            amount = value.wadDiv(price);
          } else {
            value = 0;
          }
        }
      } else {
        value = amount.wadMul(internalPriceOf(token));
      }

      if (value > 0) {
        _collateral.burn(from, value);
        IERC20(token).safeTransfer(to, amount);

        emit AssetWithdrawn(token, from, amount, value);
        return amount;
      }
    }

    return 0;
  }

  function _ensureApproved(
    address account,
    address token,
    uint8 accessFlags
  ) private view returns (CollateralAsset storage asset) {
    return __ensureApproved(msg.sender, account, token, accessFlags);
  }

  function __ensureApproved(
    address operator,
    address account,
    address token,
    uint8 accessFlags
  ) private view returns (CollateralAsset storage asset) {
    _onlyApproved(operator, account, accessFlags);
    asset = _onlyActiveAsset(token, accessFlags);
  }

  function _onlyActiveAsset(address token, uint8 accessFlags) private view returns (CollateralAsset storage asset) {
    asset = _assets[token];
    uint8 flags = asset.assetFlags;
    State.require(flags & AF_ADDED != 0);
    if (flags & accessFlags != accessFlags) {
      if (_tokens.contains(token)) {
        revert Errors.OperationPaused();
      } else {
        revert Errors.IllegalState();
      }
    }
  }

  function internalIsTrusted(
    CollateralAsset storage asset,
    address operator,
    address token
  ) internal view virtual returns (bool) {
    token;
    return operator == asset.trustee;
  }

  function _ensureTrusted(
    address operator,
    address account,
    address token,
    uint8 accessFlags
  ) private view returns (CollateralAsset storage asset) {
    asset = __ensureApproved(operator, account, token, accessFlags);
    Access.require(internalIsTrusted(asset, msg.sender, token));
  }

  event AssetDeposited(address indexed token, address indexed account, uint256 amount, uint256 value);

  function __deposit(
    address from,
    address token,
    uint256 amount
  ) private returns (uint256 value, bool ok) {
    uint256 price = internalPriceOf(token);
    if (price != 0) {
      IERC20(token).safeTransferFrom(from, address(this), amount);
      value = amount.wadMul(price);
      ok = true;
    }
  }

  function _depositAndMint(
    address operator,
    address account,
    address token,
    uint256 tokenAmount
  ) private onlySpecial(account, CollateralFundLib.APPROVED_DEPOSIT) returns (uint256) {
    (uint256 value, bool ok) = __deposit(operator, token, tokenAmount);
    if (ok) {
      emit AssetDeposited(token, account, tokenAmount, value);
      _collateral.mint(account, value);
      return value;
    }
    return 0;
  }

  function _depositAndInvest(
    address operator,
    address account,
    uint256 depositValue,
    address token,
    uint256 tokenAmount,
    address investTo
  ) private returns (uint256) {
    (uint256 value, bool ok) = __deposit(operator, token, tokenAmount);
    if (ok) {
      emit AssetDeposited(token, account, tokenAmount, value);
      _collateral.mintAndTransfer(account, investTo, value, depositValue);
      return value + depositValue;
    }
    return 0;
  }

  function trustedDeposit(
    address operator,
    address account,
    address token,
    uint256 amount
  ) external returns (uint256) {
    _ensureTrusted(operator, account, token, CollateralFundLib.APPROVED_DEPOSIT);
    return _depositAndMint(operator, account, token, amount);
  }

  function trustedInvest(
    address operator,
    address account,
    uint256 depositValue,
    address token,
    uint256 tokenAmount,
    address investTo
  ) external returns (uint256) {
    _ensureTrusted(
      operator,
      account,
      token,
      tokenAmount > 0 ? CollateralFundLib.APPROVED_DEPOSIT | CollateralFundLib.APPROVED_INVEST : CollateralFundLib.APPROVED_INVEST
    );

    return _depositAndInvest(operator, account, depositValue, token, tokenAmount, investTo);
  }

  function trustedWithdraw(
    address operator,
    address account,
    address to,
    address token,
    uint256 amount
  ) external returns (uint256) {
    _ensureTrusted(operator, account, token, CollateralFundLib.APPROVED_WITHDRAW);
    return _withdraw(account, to, token, amount);
  }

  event AssetPaused(address indexed token, bool paused);

  function setPaused(address token, bool paused) external onlyEmergencyAdmin {
    internalSetFlags(token, paused ? 0 : type(uint8).max);
    emit AssetPaused(token, paused);
  }

  function isPaused(address token) public view returns (bool) {
    return _assets[token].assetFlags == type(uint8).max;
  }

  function setTrustedOperator(address token, address trustee) external aclHas(AccessFlags.LP_DEPLOY) {
    internalSetTrustee(token, trustee);
  }

  function setSpecialRoles(address operator, uint256 accessFlags) external aclHas(AccessFlags.LP_ADMIN) {
    internalSetSpecialApprovals(operator, accessFlags);
  }

  function _attachToken(address token, bool attach) private {
    IManagedPriceRouter pricer = getPricer();
    if (address(pricer) != address(0)) {
      pricer.attachSource(token, attach);
    }
  }

  function addAsset(address token, address trusted) external aclHas(AccessFlags.LP_DEPLOY) {
    internalAddAsset(token, trusted);
    _attachToken(token, true);
  }

  function removeAsset(address token) external aclHas(AccessFlags.LP_DEPLOY) {
    internalRemoveAsset(token);
    _attachToken(token, false);
  }

  function assets() external view override returns (address[] memory) {
    return _tokens.values();
  }

  event AssetBorrowed(address indexed token, uint256 amount, address to);
  event AssetReplenished(address indexed token, uint256 amount);

  function borrow(
    address token,
    uint256 amount,
    address to
  ) external {
    _onlyActiveAsset(token, CollateralFundLib.APPROVED_BORROW);
    Value.require(amount > 0);

    ICollateralStakeManager bm = ICollateralStakeManager(IManagedCollateralCurrency(collateral()).borrowManager());
    uint256 value = amount.wadMul(internalPriceOf(token));
    State.require(value > 0);
    State.require(bm.verifyBorrowUnderlying(msg.sender, value));

    BorrowBalance storage balance = _borrowedBalances[token][msg.sender];
    require((balance.amount += uint128(amount)) >= amount);
    require((balance.value += uint128(value)) >= value);

    SafeERC20.safeTransfer(IERC20(token), to, amount);

    emit AssetBorrowed(token, amount, to);
  }

  function repay(address token, uint256 amount) external {
    _onlyActiveAsset(token, CollateralFundLib.APPROVED_BORROW);
    Value.require(amount > 0);

    SafeERC20.safeTransferFrom(IERC20(token), msg.sender, address(this), amount);

    BorrowBalance storage balance = _borrowedBalances[token][msg.sender];
    uint256 prevAmount = balance.amount;
    balance.amount = uint128(prevAmount - amount);

    uint256 prevValue = balance.value;
    uint256 value = (prevValue * amount) / prevAmount;
    balance.value = uint128(prevValue - value);

    ICollateralStakeManager bm = ICollateralStakeManager(IManagedCollateralCurrency(collateral()).borrowManager());
    State.require(bm.verifyRepayUnderlying(msg.sender, value));

    emit AssetReplenished(token, amount);
  }

  function resetPriceGuard() external aclHasAny(AccessFlags.LP_ADMIN) {
    getPricer().resetSourceGroup();
  }
}

library CollateralFundLib {
  uint8 internal constant APPROVED_DEPOSIT = 1 << 0;
  uint8 internal constant APPROVED_INVEST = 1 << 1;
  uint8 internal constant APPROVED_WITHDRAW = 1 << 2;
  uint8 internal constant APPROVED_BORROW = 1 << 3;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IVersioned {
  // solhint-disable-next-line func-name-mixedcase
  function REVISION() external view returns (uint256);
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

interface ICollateralStakeManager {
  function verifyBorrowUnderlying(address account, uint256 value) external returns (bool);

  function verifyRepayUnderlying(address account, uint256 value) external returns (bool);

  function syncStakeAsset(address asset) external;

  function syncByStakeAsset(uint256 assetSupply, uint256 collateralSupply) external;
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

import '../../interfaces/ICollateralized.sol';

interface ICollateralFund is ICollateralized {
  function setApprovalsFor(
    address operator,
    uint256 access,
    bool approved
  ) external;

  function setAllApprovalsFor(address operator, uint256 access) external;

  function getAllApprovalsFor(address account, address operator) external view returns (uint256);

  function isApprovedFor(
    address account,
    address operator,
    uint256 access
  ) external view returns (bool);

  function deposit(
    address account,
    address token,
    uint256 tokenAmount
  ) external returns (uint256);

  function invest(
    address account,
    address token,
    uint256 tokenAmount,
    address investTo
  ) external returns (uint256);

  function investIncludingDeposit(
    address account,
    uint256 depositValue,
    address token,
    uint256 tokenAmount,
    address investTo
  ) external returns (uint256);

  function withdraw(
    address account,
    address to,
    address token,
    uint256 amount
  ) external returns (uint256);

  function assets() external view returns (address[] memory);
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

interface ICollateralized {
  /// @dev address of the collateral fund and coverage token ($CC)
  function collateral() external view returns (address);
}