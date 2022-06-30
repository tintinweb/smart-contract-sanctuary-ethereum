/**
 *Submitted for verification at Etherscan.io on 2022-06-30
*/

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity ^0.8.0;

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

pragma solidity ^0.8.0;


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

pragma solidity ^0.8.0;


interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

pragma solidity ^0.8.0;


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


pragma solidity ^0.8.0;


interface IERC165 {
    
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

pragma solidity ^0.8.0;

abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

pragma solidity ^0.8.0;



abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

  
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

  
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

   
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

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

    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

pragma solidity ^0.8.0;

library EnumerableSet {
    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
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

    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

 
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }


    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

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

    
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

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

pragma solidity ^0.8.0;



abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

  
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

  
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

pragma solidity ^0.8.0;

abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

pragma solidity ^0.8.0;

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

   
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

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
   
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

   
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

   
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

   
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

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

  
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

   
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

   
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

pragma solidity ^0.8.0;

interface IERC20 {
   
    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed owner, address indexed spender, uint256 value);

  
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

   
    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: contracts\Marketplace.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract Marketplace is Pausable, Ownable, ReentrancyGuard {
    // Listing events
    event Sold(
        uint256 indexed _tradeID,
        address indexed _seller,
        address _buyer,
        uint256 indexed _tokenId,
        uint256 _price
    );

    event ListingCreated(
        uint256 indexed _tradeID,
        address indexed _seller,
        uint256 indexed _tokenId,
        uint256 _price,
        uint256 _start,
        uint256 _end
    );

    event ListingUpdated(
        uint256 indexed _tradeID,
        uint256 indexed _tokenId,
        uint256 _price,
        uint256 _start,
        uint256 _end
    );
    event ListingCancelled(uint256 indexed _tradeID, uint256 indexed _tokenId);

    // Bidding events
    event AuctionCreated(
        uint256 indexed _tradeID,
        address indexed _seller,
        uint256 indexed _tokenId,
        uint256 _price,
        uint256 _start,
        uint256 _end
    );

    event AuctionUpdated(
        uint256 indexed _tradeID,
        uint256 indexed _tokenId,
        uint256 _price,
        uint256 _start,
        uint256 _end
    );
    event AuctionCancelled(uint256 indexed _tradeID, uint256 indexed _tokenId);

    // Offer events
    event Offered(
        uint256 indexed _offerID,
        address indexed _seller,
        address _offerer,
        uint256 indexed _tokenId,
        uint256 _price,
        uint256 _end,
        bool isForAuction
    );

    event OfferUpdated(
        uint256 indexed _offerID,
        uint256 indexed _tokenId,
        address indexed _offerer,
        uint256 _price,
        uint256 _end,
        bool isForAuction
    );

    event OfferAccepted(
        uint256 indexed _offerID,
        address _seller,
        address indexed _offerer,
        uint256 indexed _tokenId,
        uint256 _price,
        bool isForAuction
    );

    event OfferCancelled(uint256 indexed _offerID, uint256 indexed _tokenId, address indexed _offerer, bool isForAuction);

    // Private listing events
    event SoldPrivate(
        uint256 indexed _tradeID,
        address indexed _seller,
        address _buyer,
        uint256 indexed _tokenId,
        uint256 _price
    );

    event PrivateListingCreated(
        uint256 indexed _tradeID,
        address _seller,
        address indexed _buyer,
        uint256 indexed _tokenId,
        uint256 _price,
        uint256 _start,
        uint256 _end
    );

    event PrivateListingUpdated(
        uint256 indexed _tradeID,
        uint256 indexed _tokenId,
        address indexed _buyer,
        uint256 _price,
        uint256 _start,
        uint256 _end
    );
    event PrivateListingCancelled(uint256 indexed _tradeID, uint256 indexed _tokenId, address indexed _buyer);

    // Counter offer events
    event CounterOfferAccepted(
        uint256 indexed _tradeID,
        address _seller,
        address indexed _offerer,
        uint256 indexed _tokenId,
        uint256 _price,
        bool isForAuction
    );

    event CounterOfferCreated(
        uint256 indexed _tradeID,
        address _seller,
        address indexed _offerer,
        uint256 indexed _tokenId,
        uint256 _price,
        uint256 _start,
        uint256 _end,
        bool isForAuction
    );

    event CounterOfferUpdated(
        uint256 indexed _tradeID,
        uint256 indexed _tokenId,
        address indexed _offerer,
        uint256 _price,
        uint256 _start,
        uint256 _end,
        bool isForAuction
    );
    event CounterOfferCancelled(uint256 indexed _tradeID, uint256 indexed _tokenId, address indexed _offerer, bool isForAuction);

    // Variables
    NFTInterface public masterContract;

    uint256 public listingFee;
    uint256 public biddingFee;

    uint256 public totalTrades = 0;
    uint256 public totalOffers = 0;

    address public feeCollector; 
    address public WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab;

    struct Trade {
        uint256 id;
        address seller;
        address buyer;
        uint256 tokenId;
        uint256 price;
        uint256 startTime;
        uint256 endTime;
        bool isAuction;
        bool isCounterOffer;
        bool exists;
    }

    struct Offer {
        uint256 id;
        address offerer;
        uint256 price;
        uint256 endTime;
        bool isForAuction;
        bool exists;
    }

    struct Asset {
        bool isListed;
        bool isAuctioned;
        mapping(address => bool) isPrivatelyListed;
        mapping(address => mapping(bool => bool)) isOffered;
        mapping(address => mapping(bool => bool)) isCounterOffered;
        mapping(uint256 => Trade) trades;
    }

    mapping(uint256 => Asset) public asset;
    mapping(uint256 => Offer) offers;

    constructor(
        address masterContractAddress,
        address collector,
        uint256 listFee,
        uint256 bidFee
    ) {
        masterContract = NFTInterface(masterContractAddress);
        feeCollector = collector;
        listingFee = listFee;
        biddingFee = bidFee;
        _pause();
    }

    modifier isTokenOwner(uint256 tokenId) {
        address caller = masterContract.ownerOf(tokenId);
        require(
            caller == _msgSender(),
            "Caller is not the owner of the token"
        );
        _;
    }

    /* USER FUNCTIONS */
    // Listing

    function createTrade(uint256 tokenId, uint256 price, address buyer, uint256 startTime, uint256 endTime, bool isAuction)
        external
        whenNotPaused
        isTokenOwner(tokenId)
    {
        require(
            masterContract.getApproved(tokenId) == address(this),
            "Market must be approved to transfer token"
        );
        require(endTime > startTime, "Must end after start");

        totalTrades++;

        if(buyer == address(0) && !isAuction){
            require(!asset[tokenId].isListed, "Already for sale");
            asset[tokenId].isListed = true;
            emit ListingCreated(totalTrades, _msgSender(), tokenId, price, startTime, endTime);
        }
        if(buyer == address(0) && isAuction){
            require(!asset[tokenId].isAuctioned, "Already on auction");
            asset[tokenId].isAuctioned = true;
            emit AuctionCreated(totalTrades, _msgSender(), tokenId, price, startTime, endTime);
        }
        if(buyer != address(0)){
            require(!asset[tokenId].isPrivatelyListed[buyer], "Already for sale");
            asset[tokenId].isPrivatelyListed[buyer] = true;
            emit PrivateListingCreated(totalTrades, _msgSender(), buyer, tokenId, price, startTime, endTime);
        }

        asset[tokenId].trades[totalTrades] = Trade(
            totalTrades,
            _msgSender(),
            buyer,
            tokenId,
            price,
            startTime,
            endTime,
            isAuction,
            false,
            true
        );
        return;
    }


    function updateTrade(uint256 tradeId, uint256 tokenId, uint256 price, uint256 startTime, uint256 endTime)
        external
        whenNotPaused
        isTokenOwner(tokenId)
    {
        require(
            masterContract.getApproved(tokenId) == address(this),
            "Market must be approved to transfer token"
        );
        require(endTime > startTime, "Must end after start");

        Trade memory trade = asset[tokenId].trades[tradeId];
        require(trade.exists, "Trade does not exist");
        
        asset[tokenId].trades[tradeId].price = price;
        asset[tokenId].trades[tradeId].startTime = startTime;
        asset[tokenId].trades[tradeId].endTime = endTime;

        if(trade.isAuction && trade.buyer == address(0) && !trade.isCounterOffer){
            emit AuctionUpdated(trade.id, tokenId, price, startTime, endTime);
        }
        if(!trade.isAuction && trade.buyer == address(0) && !trade.isCounterOffer){
            emit ListingUpdated(trade.id, tokenId, price, startTime, endTime);
        }
        if(trade.buyer != address(0) && !trade.isCounterOffer){
            emit PrivateListingUpdated(trade.id, tokenId, trade.buyer, price, startTime, endTime);
        }
        if(trade.isCounterOffer){
            emit CounterOfferUpdated(trade.id, tokenId, trade.buyer, price, startTime, endTime, trade.isAuction);
        }
        return;
    }

    function cancelTrade(uint256 tradeId, uint256 tokenId)
        external
        whenNotPaused
        isTokenOwner(tokenId)
    {
        Trade memory trade = asset[tokenId].trades[tradeId];
        require(trade.exists, "Trade does not exist");
        delete asset[tokenId].trades[tradeId];

        if(trade.isAuction && trade.buyer == address(0) && !trade.isCounterOffer){
            asset[tokenId].isListed = false;
            emit ListingCancelled(trade.id, tokenId);
        }
        if(!trade.isAuction && trade.buyer == address(0) && !trade.isCounterOffer){
            asset[tokenId].isAuctioned = false;
            emit AuctionCancelled(trade.id, tokenId);
        }
        if(trade.buyer != address(0) && !trade.isCounterOffer){
            asset[tokenId].isPrivatelyListed[trade.buyer] = false;
            emit PrivateListingCancelled(trade.id, tokenId, trade.buyer);
        }
        if(trade.isCounterOffer){
            asset[tokenId].isCounterOffered[trade.buyer][trade.isAuction] = false;
            emit CounterOfferCancelled(trade.id, tokenId, _msgSender(), trade.isAuction);
        }
        return;
    }

    function buy(uint256 tradeId, uint256 tokenId) external payable whenNotPaused nonReentrant {
        Trade memory trade = asset[tokenId].trades[tradeId];
        require(trade.exists, "Token not for sale");
        if(!trade.isCounterOffer){
            require(!trade.isAuction, "Trade must not be auction");
        }
        require(trade.startTime <= block.timestamp, "Sale time has not yet started");
        require(trade.endTime > block.timestamp, "Sale time has ended");
        require(
            masterContract.ownerOf(tokenId) == trade.seller,
            "Seller must equal current token owner"
        );
        if(trade.buyer != address(0)){
            require(_msgSender() == trade.buyer, "Not buyer");
        }
        require(msg.value == trade.price, "Not enough value");

        uint256 price = trade.price;
        uint256 fee = listingFee;
        if(trade.isAuction){
            fee = biddingFee;
        }
        uint256 feeAmount = price * fee / 10000;
        payable(feeCollector).transfer(feeAmount);
        payable(trade.seller).transfer(price - feeAmount);

        masterContract.transferFrom(trade.seller, _msgSender(), tokenId);

        if(trade.buyer == address(0) && !trade.isCounterOffer){
            emit Sold(trade.id, trade.seller, _msgSender(), tokenId, price);
        }
        if(trade.buyer != address(0) && !trade.isCounterOffer){
            emit SoldPrivate(trade.id, trade.seller, _msgSender(), tokenId, price);
        }
        if(trade.isCounterOffer){
            emit CounterOfferAccepted(trade.id, trade.seller, _msgSender(), tokenId, price, trade.isAuction);
        }

        delete asset[tokenId];
        return;
    }

    // Offer
    function makeOffer(uint256 tradeId, uint256 tokenId, uint256 price, uint256 endTime) external whenNotPaused nonReentrant {
        Trade memory trade = asset[tokenId].trades[tradeId];
        if(trade.isAuction){
            require(price >= trade.price, "Floor price not met");
            require(trade.startTime <= block.timestamp, "Token not for sale yet");
            require(trade.endTime > block.timestamp, "Token sale has ended");
        }
        require(trade.exists, "Token not for sale");
        require(trade.buyer == address(0) && !trade.isCounterOffer, "Must be auction or listing");
        require(
            masterContract.ownerOf(tokenId) == trade.seller,
            "Seller must equal current token owner"
        );
        require(!asset[tokenId].isOffered[_msgSender()][trade.isAuction], "Offer already existed");
        require(endTime > block.timestamp, "Must end in future");
        
        totalOffers++;
        offers[totalOffers] = Offer(totalOffers, _msgSender(), price, endTime, trade.isAuction, true);
        asset[tokenId].isOffered[_msgSender()][trade.isAuction] = true;
        IERC20(WETH).transferFrom(_msgSender(), address(this), price);

        emit Offered(totalOffers, trade.seller, _msgSender(), tokenId, price, endTime, trade.isAuction);
        return;
    }

    function updateOffer(uint256 offerId, uint256 tokenId, uint256 price, uint256 endTime) external whenNotPaused nonReentrant {
        Offer memory offer = offers[offerId];
        require(offer.exists, "Offer not existed");
        require(offer.offerer == _msgSender(), "Not offerer");
        require(endTime > block.timestamp, "Must end in future");

        uint256 lastPrice = offer.price;
        offers[offerId].price = price;
        offers[offerId].endTime = endTime;

        IERC20(WETH).transfer(_msgSender(), lastPrice);
        IERC20(WETH).transferFrom(_msgSender(), address(this), price);

        emit OfferUpdated(offer.id, tokenId, _msgSender(), price, endTime, offer.isForAuction);
    }

    function acceptOffer(uint256 offerId, uint256 tokenId) external whenNotPaused nonReentrant isTokenOwner(tokenId) {
        Offer memory offer = offers[offerId];
        require(offer.exists, "Offer not existed");
        require(offer.endTime > block.timestamp, "Offer has ended");

        uint256 price = offer.price;
        uint256 fee = listingFee;
        if(offer.isForAuction){
            fee = biddingFee;
        }
        uint256 feeAmount = price * fee / 10000;
        IERC20(WETH).transfer(feeCollector, feeAmount);
        IERC20(WETH).transfer(_msgSender(), price - feeAmount);

        masterContract.transferFrom(_msgSender(), offer.offerer, tokenId);
        emit OfferAccepted(offer.id, _msgSender(), offer.offerer, tokenId, price, offer.isForAuction);

        delete offers[offerId];
        delete asset[tokenId];
    }

    function cancelOffer(uint256 offerId, uint256 tokenId) external whenNotPaused nonReentrant {
        Offer memory offer = offers[offerId];
        require(offer.offerer == _msgSender(), "Not offerer");

        IERC20(WETH).transfer(_msgSender(), offer.price);

        if(offer.exists){
            asset[tokenId].isOffered[_msgSender()][offer.isForAuction] = false;
        }

        delete offers[offerId];

        emit OfferCancelled(offer.id, tokenId, _msgSender(), offer.isForAuction);
    }

    // Counter offers
    function createCounterOffer(
        uint256 offerId,
        uint256 tokenId,
        uint256 price,
        uint256 startTime,
        uint256 endTime
    ) external whenNotPaused isTokenOwner(tokenId) {
       Offer memory offer = offers[offerId];
        require(
            masterContract.getApproved(tokenId) == address(this),
            "Market must be approved to transfer token"
        );
        require(offer.exists, "Offer not existed");
        require(offer.endTime > block.timestamp, "Offer has ended");
        require(!asset[tokenId].isCounterOffered[offer.offerer][offer.isForAuction], "Already for sale");
        require(endTime > startTime, "Must end after start");

        totalTrades++;
        asset[tokenId].isCounterOffered[offer.offerer][offer.isForAuction] = true;
        asset[tokenId].trades[totalTrades] = Trade(
            totalTrades,
            _msgSender(),
            offer.offerer,
            tokenId,
            price,
            startTime,
            endTime,
            offer.isForAuction,
            true,
            true
        );

        emit CounterOfferCreated(totalTrades, _msgSender(), offer.offerer, tokenId, price, startTime, endTime, offer.isForAuction);
    }

    /* VIEW FUNCTIONS */
    function getTrade(uint256 tradeId, uint256 tokenId) external view returns(Trade memory) {
        return asset[tokenId].trades[tradeId];
    }

    /* OWNER FUNCTIONS */
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function updateListingFee(uint256 _fee, address _collector) external onlyOwner {
        require(_collector != address(0), "Non zero address");
        if(_fee != listingFee){
            listingFee = _fee;
        }
        if(_collector != feeCollector){
            feeCollector = _collector;
        }
    }

    function updateBiddingFee(uint256 _fee, address _collector) external onlyOwner {
        require(_collector != address(0), "Non zero address");
        if(_fee != biddingFee){
            biddingFee = _fee;
        }
        if(_collector != feeCollector){
            feeCollector = _collector;
        }
    }

    receive () external payable{}
}

abstract contract NFTInterface {
    function ownerOf(uint256 id) public virtual returns (address);

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual;

    function getApproved(uint256 tokenId) public view virtual returns (address);
}