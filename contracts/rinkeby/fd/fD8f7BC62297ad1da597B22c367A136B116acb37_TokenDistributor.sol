// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../access/Ownable.sol";
import "../access/NFTSpaceXAccessControls.sol";
import "../token/INFTSpaceXToken.sol";
import "../utils/ReentrancyGuard.sol";
import "../utils/Pausable.sol";
import "../utils/libraries/SafeERC20.sol";
import "../utils/libraries/EnumerableSet.sol";
import "../interfaces/IShares.sol";
import "../interfaces/INFTSpaceXTicketCard.sol";

contract TokenDistributor is Ownable, Pausable, ReentrancyGuard {
  using SafeERC20 for INFTSpaceXToken;
  using EnumerableSet for EnumerableSet.AddressSet;

  struct PartyInfo {
    uint16 shares;
    uint256 tokensDistributedToParty;
  }

  INFTSpaceXToken public nftspacexToken;
  INFTSpaceXTicketCard public nftspacexTicketCard;
  NFTSpaceXAccessControls public nftspacexAccessControls;
  address public reserve;
  address public treasury;

  uint16 public totalShares;
  uint16 TOTAL_SHARES = 10000;

  uint256 public lastReleaseToken;
  uint256 public lastFullFillReserveAndTreasury;

  EnumerableSet.AddressSet private _parties;
  mapping(address => PartyInfo) private _partyInfo;

  event PartyUpdated(address indexed oldParty, address indexed newParty);
  event TokenDistributed(address indexed party, uint256 amount);
  event TokenReleased(uint256 amount, uint256 timestamp);
  event ReserveAndTreasuryFullFilled(uint256 amount, uint256 timestamp);

  modifier onlyAdmin() {
    require(nftspacexAccessControls.hasAdminRole(_msgSender()), "TD: only admin");
    _;
  }

  constructor(
    address _nftspacexToken,
    address _nftspacexTicketCard,
    address _nftspacexAccessControls,
    address _reserve,
    address _treasury,
    address[] memory parties_
  ) {
    require(parties_.length > 0, "TD: empty parties");

    for (uint256 i = 0; i < parties_.length; i++) {
      uint16 shares = IShares(parties_[i]).shares();
      require(shares > 0, "TD: zero share");
      _partyInfo[parties_[i]].shares = shares;
      _parties.add(parties_[i]);
      totalShares += shares;
    }

    uint16 reserveShares = IShares(_reserve).shares();
    uint16 treasuryShares = IShares(_treasury).shares();
    require((totalShares + reserveShares + treasuryShares) == TOTAL_SHARES, "TD: invalid shares");

    reserve = _reserve;
    treasury = _treasury;
    _partyInfo[_reserve].shares = IShares(_reserve).shares();
    _partyInfo[_treasury].shares = IShares(_treasury).shares();
    nftspacexToken = INFTSpaceXToken(_nftspacexToken);
    nftspacexTicketCard = INFTSpaceXTicketCard(_nftspacexTicketCard);
    nftspacexAccessControls = NFTSpaceXAccessControls(_nftspacexAccessControls);
    _pause();
  }

  function getParties() public view returns (address[] memory parties) {
    parties = new address[](_parties.length());
    for (uint256 i = 0; i < _parties.length(); i++) {
      parties[i] = _parties.at(i);
    }
  }

  function getPartyInfo(address party) public view returns (uint16 shares, uint256 tokensDistributedToParty) {
    shares = _partyInfo[party].shares;
    tokensDistributedToParty = _partyInfo[party].tokensDistributedToParty;
  }

  function releaseToken(uint256 ticketSupply, uint256 expiry) public onlyAdmin whenNotPaused {
    _updateTokenDistributor();
    _updateTicketCard(_parties.at(1), ticketSupply, expiry, "");

    uint256 totalTokens = nftspacexToken.balanceOf(address(this));
    for (uint256 i = 0; i < _parties.length(); i++) {
      uint256 amountDistributing = totalTokens * _partyInfo[_parties.at(i)].shares / totalShares;
      _distributeTokens(_parties.at(i), amountDistributing);
    }
    lastReleaseToken = block.timestamp;

    emit TokenReleased(totalTokens, block.timestamp);
  }

  function fullFillReserveAndTreasury() public onlyAdmin whenPaused {
    _updateTokenDistributor();

    uint256 missingInReserve = IShares(reserve).maxBalanceNST() - IShares(reserve).currentBalanceNST();
    if (missingInReserve > 0) {
      _distributeTokens(reserve, missingInReserve);
    }

    uint256 missingInTreasury = IShares(treasury).maxBalanceNST() - IShares(treasury).currentBalanceNST();
    if (missingInTreasury > 0) {
      _distributeTokens(treasury, missingInTreasury);
    }

    lastFullFillReserveAndTreasury = block.timestamp;
    emit ReserveAndTreasuryFullFilled((missingInReserve + missingInTreasury), block.timestamp);
  }

  function pauseDistribution() public onlyAdmin whenNotPaused {
    _pause();
  }

  function unpauseDistribution() public onlyAdmin whenPaused {
    _unpause();
  }

  function updateParty(address newParty, address currentParty) public onlyAdmin whenPaused {
    require(_partyInfo[currentParty].shares == IShares(newParty).shares(), "TD: invalid shares");

    _partyInfo[newParty].shares = IShares(newParty).shares();
    _partyInfo[newParty].tokensDistributedToParty = _partyInfo[currentParty].tokensDistributedToParty;
    _partyInfo[currentParty].shares = 0;
    _partyInfo[currentParty].tokensDistributedToParty = 0;
    _parties.add(newParty);
    _parties.remove(currentParty);

    emit PartyUpdated(currentParty, newParty);
  }

  function _updateTokenDistributor() private {
    uint256 nonCirculatingSupply = nftspacexToken.maxTotalSupply() - nftspacexToken.totalSupply();
    nftspacexToken.mint(address(this), nonCirculatingSupply);
  }

  function _updateTicketCard(
    address _initialOwner,
    uint256 _initialSupply,
    uint256 _expiry,
    bytes memory _data
  ) private {
    nftspacexTicketCard.create(_initialOwner, _initialSupply, _expiry, _data);
  }

  function _distributeTokens(address _party, uint256 _amount) internal nonReentrant {
    require(_amount > 0, "TD: zero amount");
    nftspacexToken.safeTransfer(_party, _amount);
    _partyInfo[_party].tokensDistributedToParty += _amount;

    emit TokenDistributed(_party, _amount);
  }
}

// SPDX-License-Identifier: MIT

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./NFTSpaceXAdminAccess.sol";

contract NFTSpaceXAccessControls is NFTSpaceXAdminAccess {
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant TOKEN_MINTER_ROLE = keccak256("TOKEN_MINTER_ROLE");
  bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

  event MinterRoleGranted(address indexed beneficiary, address indexed caller);
  event MinterRoleRemoved(address indexed beneficiary, address indexed caller);
  event OperatorRoleGranted(address indexed beneficiary, address indexed caller);
  event OperatorRoleRemoved(address indexed beneficiary, address indexed caller);
  event SmartContractRoleGranted(address indexed beneficiary, address indexed caller);
  event SmartContractRoleRemoved(address indexed beneficiary, address indexed caller);

  function hasMinterRole(address _address) public view returns (bool) {
    return hasRole(MINTER_ROLE, _address);
  }

  function hasTokenMinterRole(address _address) public view returns (bool) {
    return hasRole(TOKEN_MINTER_ROLE, _address);
  }

  function hasOperatorRole(address _address) public view returns (bool) {
    return hasRole(OPERATOR_ROLE, _address);
  }

  function addMinterRole(address _beneficiary) external {
    grantRole(MINTER_ROLE, _beneficiary);
    emit MinterRoleGranted(_beneficiary, _msgSender());
  }

  function removeMinterRole(address _beneficiary) external {
    revokeRole(MINTER_ROLE, _beneficiary);
    emit MinterRoleRemoved(_beneficiary, _msgSender());
  }

  function addTokenMinterRole(address _beneficiary) external {
    grantRole(TOKEN_MINTER_ROLE, _beneficiary);
    emit SmartContractRoleGranted(_beneficiary, _msgSender());
  }

  function addOperatorRole(address _beneficiary) external {
    grantRole(OPERATOR_ROLE, _beneficiary);
    emit OperatorRoleGranted(_beneficiary, _msgSender());
  }

  function removeOperatorRole(address _beneficiary) external {
    revokeRole(OPERATOR_ROLE, _beneficiary);
    emit OperatorRoleRemoved(_beneficiary, _msgSender());
  }
}

// SPDX-License-Identifier: MIT

import "./ERC20/IERC20.sol";

pragma solidity ^0.8.0;

interface INFTSpaceXToken is IERC20 {
  event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);
  event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);
  
  function maxTotalSupply() external view returns (uint256);
  function mint(address account, uint256 amount) external;
  function burn(uint256 amount) external;
  function burnFrom(address account, uint256 amount) external;
  function getVotes(address account) external view returns (uint256);
  function getPastVotes(address account, uint256 blockNumber) external view returns (uint256);
  function getPastTotalSupply(uint256 blockNumber) external view returns (uint256);
  function delegates(address account) external view returns (address);
  function delegate(address delegatee) external;
  function delegateBySig(
    address delegatee,
    uint256 nonce,
    uint256 expiry,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 */

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";

abstract contract Pausable is Context {
  bool private _paused;

  event Paused(address account);
  event Unpaused(address account);

  modifier whenNotPaused() {
    require(!paused(), "Pausable: paused");
    _;
  }

  modifier whenPaused() {
    require(paused(), "Pausable: not paused");
    _;
  }

  constructor() {
    _paused = false;
  }

  /**
   * @dev Return true if the contract is paused, and false otherwise
   */
  function paused() public virtual view returns (bool) {
    return _paused;
  }

  function _pause() internal virtual whenNotPaused {
    _paused = true;
    emit Paused(_msgSender());
  }

  /**
   * @dev Return to normal state
   */
  function _unpause() internal virtual whenPaused {
    _paused = false;
    emit Unpaused(_msgSender());
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../token/ERC20/IERC20.sol";
import "./Address.sol";

library SafeERC20 {
  using Address for address;

  function safeTransfer(IERC20 token, address to, uint256 value) internal {
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

  function safeApprove(IERC20 token, address spender, uint256 value) internal {
    require(
      (value == 0) || (token.allowance(address(this), spender) == 0),
      "SafeERC20: 0 allowance"
    );
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
  }

  function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
    uint256 newAllowance = token.allowance(address(this), spender) + value;
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
  }

  function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
    unchecked {
      uint256 oldAllowance = token.allowance(address(this), spender);
      require(oldAllowance >= value, "SafeERC20: value excceed");
      uint256 newAllowance = oldAllowance - value;
      _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
  }

  function _callOptionalReturn(IERC20 token, bytes memory data) private {
    bytes memory returndata = address(token).functionCall(data, "SafeERC20: low level call failed");
    if (returndata.length > 0) {
      require(abi.decode(returndata, (bool)), "SafeERC20: operation did not succeed");
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library EnumerableSet {
  struct Set {
    bytes32[] _values;
    mapping (bytes32 => uint256) _indexes;
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

    if (valueIndex != 0) { // Equivalent to contains(set, value)
      // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
      // the array, and then remove the last element (sometimes called as 'swap and pop').
      // This modifies the order of the array, as noted in {at}.

      uint256 toDeleteIndex = valueIndex - 1;
      uint256 lastIndex = set._values.length - 1;

      // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
      // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

      bytes32 lastvalue = set._values[lastIndex];

      // Move the last value to the index where the value to delete is
      set._values[toDeleteIndex] = lastvalue;
      // Update the index for the moved value
      set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

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
    require(set._values.length > index, "EnumerableSet: index out of bounds");
    return set._values[index];
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IShares {
  function shares() external view returns (uint16);
  function currentBalanceNST() external view returns (uint256);
  function maxBalanceNST() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155.sol";

interface INFTSpaceXTicketCard is IERC1155 {
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function factorySchemaName() external pure returns (string memory);
  function tokenURI(uint256 id) external view returns (string memory);
  function tokenSupply(uint256 id) external view returns (uint256);
  function currentIdSupported() external view returns (uint256);
  function isIdExpired(uint256 id) external view returns (bool);

  function setBaseTokenURI(string memory baseTokenURI) external;
  function create(address initialOwner, uint256 initialSupply, uint256 expiry, bytes calldata data) external;
  function mint(address to, uint256 quantity, bytes calldata data) external;
  function burn(address account, uint256 id, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "./AccessControl.sol";

contract NFTSpaceXAdminAccess is AccessControl {
  bool private initAccess;

  event AdminRoleGranted(address indexed beneficiary, address indexed caller);
  event AdminRoleRemoved(address indexed beneficiary, address indexed caller);

  function initAccessControls(address _admin) public {
    require(!initAccess, "NSA: Already initialised");
    require(_admin != address(0), "NSA: zero address");
    _setupRole(DEFAULT_ADMIN_ROLE, _admin);
    initAccess = true;
  }

  function hasAdminRole(address _address) public view returns (bool) {
    return hasRole(DEFAULT_ADMIN_ROLE, _address);
  }

  function addAdminRole(address _beneficiary) external {
    grantRole(DEFAULT_ADMIN_ROLE, _beneficiary);
    emit AdminRoleGranted(_beneficiary, _msgSender());
  }

  function removeAdminRole(address _beneficiary) external {
    revokeRole(DEFAULT_ADMIN_ROLE, _beneficiary);
    emit AdminRoleRemoved(_beneficiary, _msgSender());
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/libraries/EnumerableSet.sol";
import "../utils/introspection/ERC165.sol";
import "../interfaces/IAccessControl.sol";

abstract contract AccessControl is Context, IAccessControl, ERC165 {
  using EnumerableSet for EnumerableSet.AddressSet;

  struct RoleData {
    EnumerableSet.AddressSet members;
    bytes32 adminRole;
  }

  mapping(bytes32 => RoleData) private _roles;
  bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
  }

  function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
    return _roles[role].members.contains(account);
  }

  function getRoleMemberCount(bytes32 role) public view returns (uint256) {
    return _roles[role].members.length();
  }

  function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
    return _roles[role].members.at(index);
  }

  function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
    return _roles[role].adminRole;
  }

  function grantRole(bytes32 role, address account) public virtual override {
    require(hasRole(_roles[role].adminRole, _msgSender()), "AC: must be an admin");
    _grantRole(role, account);
  }

  function revokeRole(bytes32 role, address account) public virtual override {
    require(hasRole(_roles[role].adminRole, _msgSender()), "AC: must be an admin");
    _revokeRole(role, account);
  }

  function renounceRole(bytes32 role, address account) public virtual override {
    require(account == _msgSender(), "AC: must renounce yourself");
    _revokeRole(role, account);
  }

  function _setupRole(bytes32 role, address account) internal virtual {
    _grantRole(role, account);
  }

  function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
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
}

// SPDX-License-Identifier: MIT

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
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAccessControl {
  /**
    * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
    *
    * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
    * {RoleAdminChanged} not being emitted signaling this.
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

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    // event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}