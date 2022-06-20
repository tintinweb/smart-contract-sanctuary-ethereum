/**
 *Submitted for verification at Etherscan.io on 2022-06-20
*/

// SPDX-License-Identifier: MIT 
pragma solidity 0.8.15;
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
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
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
library AddressUpgradeable {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
contract Initializable {
  bool private initialized;
  bool private initializing;
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");
    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }
    _;
    if (isTopLevelCall) {
      initializing = false;
    }
  }
  // Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }
  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }
    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable {
  function __AccessControl_init() internal  initializer(){
    __Context_init_unchained();
    __AccessControl_init_unchained();
  }
  function __AccessControl_init_unchained() internal initializer() {}
  using EnumerableSet for EnumerableSet.AddressSet;
  using AddressUpgradeable for address;
  struct RoleData {
    EnumerableSet.AddressSet members;
    bytes32 adminRole;
  }
  mapping(bytes32 => RoleData) private _roles;
  bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;
  event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
  event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
  event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
  function hasRole(bytes32 role, address account) internal view returns (bool) {
    return _roles[role].members.contains(account);
  }
  function getRoleMemberCount(bytes32 role) internal view returns (uint256) {
    return _roles[role].members.length();
  }
  function getRoleMember(bytes32 role, uint256 index) internal view returns (address) {
    return _roles[role].members.at(index);
  }
  function getRoleAdmin(bytes32 role) internal view returns (bytes32) {
    return _roles[role].adminRole;
  }
  function grantRole(bytes32 role, address account) internal virtual {
    require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");
    _grantRole(role, account);
  }
  function revokeRole(bytes32 role, address account) internal virtual {
    require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

    _revokeRole(role, account);
  }
  function renounceRole(bytes32 role, address account) internal virtual {
    require(account == _msgSender(), "AccessControl: can only renounce roles for self");
    _revokeRole(role, account);
  }
  function _setupRole(bytes32 role, address account) internal {
    _grantRole(role, account);
  }
  function _setRoleAdmin(bytes32 role, bytes32 adminRole) private {
    emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
    _roles[role].adminRole = adminRole;
  }

  function _grantRole(bytes32 role, address account) private {
    if (_roles[role].members.add(account)) {
      emit RoleGranted(role, account, _msgSender());
    }
  }

  function _revokeRole(bytes32 role, address account) private {
    if (_roles[role].members.remove(account)) {
      emit RoleRevoked(role, account, _msgSender());
    }
  }
  uint256[49] private __gap;
}
abstract contract AdminRole is Initializable, AccessControlUpgradeable {
  function _initializeAdminRole(address admin) internal initializer() {
    AccessControlUpgradeable.__AccessControl_init();
    // Grant the role to a specified account
    _setupRole(DEFAULT_ADMIN_ROLE, admin);
  }
  modifier onlyAdmin() {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "AdminRole: caller does not have the Admin role");
    _;
  }
  function grantAdmin(address account) external {
    grantRole(DEFAULT_ADMIN_ROLE, account);
  }
  function revokeAdmin(address account) external {
    revokeRole(DEFAULT_ADMIN_ROLE, account);
  }
  function getAdminMember(uint256 index) external view returns (address account) {
    return getRoleMember(DEFAULT_ADMIN_ROLE, index);
  }
  function getAdminMemberCount() external view returns (uint256 count) {
    return getRoleMemberCount(DEFAULT_ADMIN_ROLE);
  }
  function isAdmin(address account) external view returns (bool approved) {
    return hasRole(DEFAULT_ADMIN_ROLE, account);
  }
  uint256[1000] private __gap;
}
abstract contract CollateralManagement is AdminRole {
  using AddressUpgradeable for address payable;
  event FundsWithdrawn(address indexed to, uint256 amount);
  receive() external payable {}
  function withdrawFunds(address payable to, uint256 amount) external onlyAdmin {
    if (amount == 0) {
      amount = address(this).balance;
    }
    to.sendValue(amount);
    emit FundsWithdrawn(to, amount);
  }
  uint256[1000] private __gap;
}
abstract contract OperatorRole is Initializable, AccessControlUpgradeable {
  bytes32 private constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
  function grantOperator(address account) external {
    grantRole(OPERATOR_ROLE, account);
  }
  function revokeOperator(address account) external {
    revokeRole(OPERATOR_ROLE, account);
  }
  function getOperatorMember(uint256 index) external view returns (address account) {
    return getRoleMember(OPERATOR_ROLE, index);
  }
  function getOperatorMemberCount() external view returns (uint256 count) {
    return getRoleMemberCount(OPERATOR_ROLE);
  }
  function isOperator(address account) external view returns (bool approved) {
    return hasRole(OPERATOR_ROLE, account);
  }
}
interface ISendValueWithFallbackWithdraw {
  function withdraw() external;
}
abstract contract WithdrawFromEscrow is AdminRole {
  function withdrawFromEscrow(ISendValueWithFallbackWithdraw market) external onlyAdmin {
    market.withdraw();
  }
}
contract SSSTreasury is AdminRole, OperatorRole, CollateralManagement, WithdrawFromEscrow {
  function initialize(address admin) external initializer {
    AdminRole._initializeAdminRole(admin);
  }
}