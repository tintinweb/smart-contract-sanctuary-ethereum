pragma solidity ^0.8.11;

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {PermitControl} from "../../access/PermitControl.sol";
import {Signature} from "../../libraries/Signature.sol";

error PlatformFeeRecipientCannotBeZero();
error ProtocolFeeRecipientCannotBeZero();
error ValidatorAddressCannotBeZero();
error SignatureExpired();
error NothingToClaim();
error BadSignature();

/**
    @title The logic domain of Gigamart, which handles fees.
    @author Rostislav Khlebnikov.
 */
contract FeeManager is PermitControl {
    using SafeERC20 for IERC20;

    /**  The public identifier for the right to set new items. */
    bytes32 public constant FEE_CONFIG = keccak256("FEE_CONFIG");
    /** The public identifier for the right to change validator address. */
    bytes32 public constant VALIDATOR_SETTER = keccak256("VALIDATOR_SETTER");

    /** The address of the validator. */
    address validator;

    /** Plaftorm fee configuration - recipient address take left 160 bit and fee percentage takes right 96 bits */
    uint256 platformFee;
    /** Protocol fee configuration - recipient address take left 160 bit and fee percentage takes right 96 bits */
    uint256 protocolFee;

    /** collection address => royalty */
    mapping(address => uint256[]) public royalties;

    /**
        Emmited when royalty for collection is changed.
        @param setter address which changed royalties.
        @param collection address of the collection, for which new royalties are set.
        @param newRoyalties array of new royalties, address and uint96 packed in 256 bits.
    */
    event RoyaltyChanged(
        address indexed setter,
        address indexed collection,
        uint256[] newRoyalties
    );

    /**
        Emmited when new royalties added to collection.
        @param setter address which added royalties.
        @param collection address of the collection, for which new royalties are added.
        @param newRoyalties array of new royalties, address and uint96 packed in 256 bits.
    */
    event RoyatyAdded(
        address indexed setter,
        address indexed collection,
        uint256[] newRoyalties
    );

    /**
        Emmited when platform fee amount is changed.
        @param oldPlatformFeeRecipient previous recipient address of platform fees.
        @param newPlatformFeeRecipient new recipient address of platform fees.
        @param oldPlatformFeePercent previous amount of platform fees..
        @param newPlatformFeePercent new amount of platform fees. 
     */
    event PlatformFeeChanged(
        address oldPlatformFeeRecipient,
        address newPlatformFeeRecipient,
        uint256 oldPlatformFeePercent,
        uint256 newPlatformFeePercent
    );

    /**
        Emmited when protocol  fee config is changed.
        @param oldProtocolFeeRecipient previous recipient address of protocol fees.
        @param newProtocolFeeRecipient new recipient address of protocol fees.
        @param oldProtocolFeePercent previous amount of protocol fees..
        @param newProtocolFeePercent new amount of protocol fees. 
     */
    event ProtocolFeeChanged(
        address oldProtocolFeeRecipient,
        address newProtocolFeeRecipient,
        uint256 oldProtocolFeePercent,
        uint256 newProtocolFeePercent
    );

    /**
        @param platformFeeRecipient platform fee recipient address.
        @param platformFeePercent platform fee percent.
        @param protocolFeeRecipient protocol fee recipient address.
        @param protocolFeePercent protocol fee percent.
     */
    constructor(
        address platformFeeRecipient,
        uint96 platformFeePercent,
        address protocolFeeRecipient,
        uint96 protocolFeePercent
    ) {
        if (platformFeeRecipient == address(0))
            revert PlatformFeeRecipientCannotBeZero();
        platformFee =
            (uint256(uint160(platformFeeRecipient)) << 96) +
            uint256(platformFeePercent);
        protocolFee =
            (uint256(uint160(protocolFeeRecipient)) << 96) +
            uint256(protocolFeePercent);
    }

    /**
        Takes hash from parameters, before validating royalties change.
        @param setter msg.sender for royalty change.
        @param collection address of the collection for which royalties will be changed/added.
        @param deadline time until setter has rights to change royalties.
        @param newRoyalties royalties to be set/added.
     */
    function hash(
        address setter,
        address collection,
        uint256 deadline,
        uint256[] memory newRoyalties
    ) internal pure returns (bytes32) {
        return
            keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(setter, collection, deadline, newRoyalties))));
    }

    /**
        @dev Changes validator address.
        @param _validator new validator address.
     */
    function changeValidator(address _validator)
        external
        hasValidPermit(UNIVERSAL, VALIDATOR_SETTER)
    {
        if (_validator == address(0)) revert ValidatorAddressCannotBeZero();
        validator = _validator;
    }

    /**
        @dev Changes amount of fees for the platform
        @param newPlatformFeeRecipient new platform fee recipient.
        @param newPlatformFeePercent new amount of fees in percent, e.g. 2% = 200.
     */
    function changePlatformFees(
        address newPlatformFeeRecipient,
        uint256 newPlatformFeePercent
    ) external hasValidPermit(UNIVERSAL, FEE_CONFIG) {
        if (newPlatformFeeRecipient == address(0))
            revert PlatformFeeRecipientCannotBeZero();

        uint256 oldPlatformFee = platformFee;
        platformFee =
            (uint256(uint160(newPlatformFeeRecipient)) << 96) +
            uint256(newPlatformFeePercent);

        emit PlatformFeeChanged(
            address(uint160(oldPlatformFee >> 96)),
            newPlatformFeeRecipient,
            uint256(uint96(oldPlatformFee)),
            newPlatformFeePercent
        );
    }

    /**
        @dev Changes amount of fees for the platform
        @param newProtocolFeeRecipient new protocol fee recipient.
        @param newProtocolFeePercent new amount of fees in percent, e.g. 2% = 200.
     */
    function changeProtocolFees(
        address newProtocolFeeRecipient,
        uint256 newProtocolFeePercent
    ) external hasValidPermit(UNIVERSAL, FEE_CONFIG) {
        if (newProtocolFeeRecipient == address(0))
            revert ProtocolFeeRecipientCannotBeZero();

        uint256 oldProtocolFee = platformFee;
        protocolFee =
            (uint256(uint160(newProtocolFeeRecipient)) << 96) +
            uint256(newProtocolFeePercent);

        emit ProtocolFeeChanged(
            address(uint160(oldProtocolFee >> 96)),
            newProtocolFeeRecipient,
            uint256(uint96(oldProtocolFee)),
            newProtocolFeePercent
        );
    }

    /**
        @dev Rewrites mapping with new royalties.
        @param collection address of the collection, for which `newRoyalties` are set.
        @param deadline time until which `signature` is valid.
        @param newRoyalties royalties to be set.
        @param signature validator signature.
     */
    function setRoyalties(
        address collection,
        uint256 deadline,
        uint256[] memory newRoyalties,
        bytes calldata signature
    ) external {
        if (Signature.recover(hash(msg.sender, collection, deadline, newRoyalties), signature) != validator) revert BadSignature();
        if (deadline < block.timestamp) revert SignatureExpired();
        royalties[collection] = newRoyalties;
        emit RoyaltyChanged(msg.sender, collection, newRoyalties);
    }

    /**
        @dev Appends new royalties.
        @param collection address of the collection, for which `newRoyalties` are added.
        @param deadline time until which `signature` is valid.
        @param newRoyalties royalties to be added.
        @param signature validator signature.
     */
    function addRoyalties(
        address collection,
        uint256 deadline,
        uint256[] memory newRoyalties,
        bytes calldata signature
    ) external {
        if (Signature.recover(hash(msg.sender, collection, deadline, newRoyalties), signature) != validator) revert BadSignature();
        if (deadline < block.timestamp) revert SignatureExpired();
        for (uint256 i; i < newRoyalties.length; ++i){
            royalties[collection].push(newRoyalties[i]);
        }
        emit RoyatyAdded(msg.sender, collection, newRoyalties);
    }

    /**
        Returns royalty, platform and protocol fee configs.
        @param collection address to return fees for.
     */
    function getFees(address collection)
        public
        view
        returns (uint256[] memory)
    {
        uint256 platformFee_ = platformFee;
        uint256 protocolFee_ = protocolFee;
        uint256[] memory royalties_ = royalties[collection];
        uint256 size = royalties_.length + 2;
        uint256[] memory fees = new uint256[](size);
        fees[0] = platformFee_;
        fees[1] = protocolFee_;
        for (uint256 i = 2; i < size; ++i){
            fees[i] = royalties_[i - 2];
        }
        return fees;
    }

    /**
        Returns current platform fee config.
     */
    function currentPlatformFee() external view returns (address, uint256) {
        uint256 fee = platformFee;
        return (address(uint160(fee >> 96)), uint256(uint96(fee)));
    }

    /**
        Returns current protocol fee config.
     */
    function currentProtocolFee() external view returns (address, uint256) {
        uint256 fee = protocolFee;
        return (address(uint160(fee >> 96)), uint256(uint96(fee)));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
  @title An advanced permission-management contract.
  @author Tim Clancy

  This contract allows for a contract owner to delegate specific rights to
  external addresses. Additionally, these rights can be gated behind certain
  sets of circumstances and granted expiration times. This is useful for some
  more finely-grained access control in contracts.

  The owner of this contract is always a fully-permissioned super-administrator.

  August 23rd, 2021.
*/
abstract contract PermitControl is Ownable {
  using Address for address;

  /// A special reserved constant for representing no rights.
  bytes32 public constant ZERO_RIGHT = hex"00000000000000000000000000000000";

  /// A special constant specifying the unique, universal-rights circumstance.
  bytes32 public constant UNIVERSAL = hex"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF";

  /*
    A special constant specifying the unique manager right. This right allows an
    address to freely-manipulate the `managedRight` mapping.
  **/
  bytes32 public constant MANAGER = hex"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF";

  /**
    A mapping of per-address permissions to the circumstances, represented as
    an additional layer of generic bytes32 data, under which the addresses have
    various permits. A permit in this sense is represented by a per-circumstance
    mapping which couples some right, represented as a generic bytes32, to an
    expiration time wherein the right may no longer be exercised. An expiration
    time of 0 indicates that there is in fact no permit for the specified
    address to exercise the specified right under the specified circumstance.

    @dev Universal rights MUST be stored under the 0xFFFFFFFFFFFFFFFFFFFFFFFF...
    max-integer circumstance. Perpetual rights may be given an expiry time of
    max-integer.
  */
  mapping( address => mapping( bytes32 => mapping( bytes32 => uint256 )))
    public permissions;

  /**
    An additional mapping of managed rights to manager rights. This mapping
    represents the administrator relationship that various rights have with one
    another. An address with a manager right may freely set permits for that
    manager right's managed rights. Each right may be managed by only one other
    right.
  */
  mapping( bytes32 => bytes32 ) public managerRight;

  /**
    An event emitted when an address has a permit updated. This event captures,
    through its various parameter combinations, the cases of granting a permit,
    updating the expiration time of a permit, or revoking a permit.

    @param updator The address which has updated the permit.
    @param updatee The address whose permit was updated.
    @param circumstance The circumstance wherein the permit was updated.
    @param role The role which was updated.
    @param expirationTime The time when the permit expires.
  */
  event PermitUpdated(
    address indexed updator,
    address indexed updatee,
    bytes32 circumstance,
    bytes32 indexed role,
    uint256 expirationTime
  );

//   /**
//     A version of PermitUpdated for work with setPermits() function.
    
//     @param updator The address which has updated the permit.
//     @param updatees The addresses whose permit were updated.
//     @param circumstances The circumstances wherein the permits were updated.
//     @param roles The roles which were updated.
//     @param expirationTimes The times when the permits expire.
//   */
//   event PermitsUpdated(
//     address indexed updator,
//     address[] indexed updatees,
//     bytes32[] circumstances,
//     bytes32[] indexed roles,
//     uint256[] expirationTimes
//   );

  /**
    An event emitted when a management relationship in `managerRight` is
    updated. This event captures adding and revoking management permissions via
    observing the update history of the `managerRight` value.

    @param manager The address of the manager performing this update.
    @param managedRight The right which had its manager updated.
    @param managerRight The new manager right which was updated to.
  */
  event ManagementUpdated(
    address indexed manager,
    bytes32 indexed managedRight,
    bytes32 indexed managerRight
  );

  /**
    A modifier which allows only the super-administrative owner or addresses
    with a specified valid right to perform a call.

    @param _circumstance The circumstance under which to check for the validity
      of the specified `right`.
    @param _right The right to validate for the calling address. It must be
      non-expired and exist within the specified `_circumstance`.
  */
  modifier hasValidPermit(
    bytes32 _circumstance,
    bytes32 _right
  ) {
    require(_msgSender() == owner()
      || hasRight(_msgSender(), _circumstance, _right),
      "P1");
    _;
  }

  /**
    Return a version number for this contract's interface.
  */
  function version() external virtual pure returns (uint256) {
    return 1;
  }

  /**
    Determine whether or not an address has some rights under the given
    circumstance, and if they do have the right, until when.

    @param _address The address to check for the specified `_right`.
    @param _circumstance The circumstance to check the specified `_right` for.
    @param _right The right to check for validity.
    @return The timestamp in seconds when the `_right` expires. If the timestamp
      is zero, we can assume that the user never had the right.
  */
  function hasRightUntil(
    address _address,
    bytes32 _circumstance,
    bytes32 _right
  ) public view returns (uint256) {
    return permissions[_address][_circumstance][_right];
  }

   /**
    Determine whether or not an address has some rights under the given
    circumstance,

    @param _address The address to check for the specified `_right`.
    @param _circumstance The circumstance to check the specified `_right` for.
    @param _right The right to check for validity.
    @return true or false, whether user has rights and time is valid.
  */
  function hasRight(
    address _address,
    bytes32 _circumstance,
    bytes32 _right
  ) public view returns (bool) {
    return permissions[_address][_circumstance][_right] > block.timestamp;
  }

  /**
    Set the permit to a specific address under some circumstances. A permit may
    only be set by the super-administrative contract owner or an address holding
    some delegated management permit.

    @param _address The address to assign the specified `_right` to.
    @param _circumstance The circumstance in which the `_right` is valid.
    @param _right The specific right to assign.
    @param _expirationTime The time when the `_right` expires for the provided
      `_circumstance`.
  */
  function setPermit(
    address _address,
    bytes32 _circumstance,
    bytes32 _right,
    uint256 _expirationTime
  ) public virtual hasValidPermit(UNIVERSAL, managerRight[_right]) {
    require(_right != ZERO_RIGHT,
      "P2");
    permissions[_address][_circumstance][_right] = _expirationTime;
    emit PermitUpdated(_msgSender(), _address, _circumstance, _right,
      _expirationTime);
  }

//   /**
//     Version of setPermit() that works with multiple addresses in one transaction.

//     @param _addresses The array of addresses to assign the specified `_right` to.
//     @param _circumstances The array of circumstances in which the `_right` is 
//                           valid.
//     @param _rights The array of specific rights to assign.
//     @param _expirationTimes The array of times when the `_rights` expires for 
//                             the provided _circumstance`.
//   */
//   function setPermits(
//     address[] memory _addresses,
//     bytes32[] memory _circumstances, 
//     bytes32[] memory _rights, 
//     uint256[] memory _expirationTimes
//   ) public virtual {
//     require((_addresses.length == _circumstances.length)
//              && (_circumstances.length == _rights.length)
//              && (_rights.length == _expirationTimes.length),
//              "leghts of input arrays are not equal"
//     );
//     bytes32 lastRight;
//     for(uint i = 0; i < _rights.length; i++) {
//       if (lastRight != _rights[i] || (i == 0)) { 
//         require(_msgSender() == owner() || hasRight(_msgSender(), _circumstances[i], _rights[i]), "P1");
//         require(_rights[i] != ZERO_RIGHT, "P2");
//         lastRight = _rights[i];
//       }
//       permissions[_addresses[i]][_circumstances[i]][_rights[i]] = _expirationTimes[i];
//     }
//     emit PermitsUpdated(
//       _msgSender(), 
//       _addresses,
//       _circumstances,
//       _rights,
//       _expirationTimes
//     );
//   }

  /**
    Set the `_managerRight` whose `UNIVERSAL` holders may freely manage the
    specified `_managedRight`.

    @param _managedRight The right which is to have its manager set to
      `_managerRight`.
    @param _managerRight The right whose `UNIVERSAL` holders may manage
      `_managedRight`.
  */
  function setManagerRight(
    bytes32 _managedRight,
    bytes32 _managerRight
  ) external virtual hasValidPermit(UNIVERSAL, MANAGER) {
    require(_managedRight != ZERO_RIGHT,
      "P3");
    managerRight[_managedRight] = _managerRight;
    emit ManagementUpdated(_msgSender(), _managedRight, _managerRight);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

error InvalidSignatureLength();

library Signature {
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

    function unchecked_recover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return ecrecover(hash, v, r, s);
    }

    function recover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        // Check the signature length
        if (signature.length != 65) {
            revert InvalidSignatureLength();
        }
        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return ecrecover(hash, v, r, s);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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