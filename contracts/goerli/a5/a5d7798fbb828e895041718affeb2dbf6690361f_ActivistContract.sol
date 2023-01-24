// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <=0.9.0;

import "./UserContract.sol";
import "./ActivistTypes.sol";
import "./Callable.sol";

contract ActivistContract is Callable {
  mapping(address => Activist) internal activists;

  UserContract internal userContract;
  address[] internal activistsAddress;
  uint256 public activistsCount;

  constructor(address userContractAddress) {
    userContract = UserContract(userContractAddress);
  }

  /**
   * @dev Allow a new register of activist
   * @param name the name of the activist
   * @param country the country where the activist is
   * @param state the state of the activist
   * @param city the of the activist
   * @param cep the cep of the activist
   * @return a Activist
   */
  // TODO Add mustBeAllowedCaller
  function addActivist(
    string memory name,
    string memory proofPhoto,
    string memory country,
    string memory state,
    string memory city,
    string memory cep
  ) public uniqueActivist returns (Activist memory) {
    uint256 id = activistsCount + 1;
    UserType userType = UserType.ACTIVIST;

    ActivistAddress memory activistAddress = ActivistAddress(country, state, city, cep);

    Activist memory activist = Activist(
      id,
      msg.sender,
      userType,
      name,
      proofPhoto,
      0,
      0,
      activistAddress,
      0
    );

    activists[msg.sender] = activist;
    activistsAddress.push(msg.sender);
    activistsCount++;
    userContract.addUser(msg.sender, userType);

    return activist;
  }

  /**
   * @dev Returns all registered activists
   * @return Activist struct array
   */
  function getActivists() public view returns (Activist[] memory) {
    Activist[] memory activistList = new Activist[](activistsCount);

    for (uint256 i = 0; i < activistsCount; i++) {
      address acAddress = activistsAddress[i];
      activistList[i] = activists[acAddress];
    }

    return activistList;
  }

  /**
   * @dev Return a specific activist
   * @param addr the address of the activist.
   */
  function getActivist(address addr) public view returns (Activist memory) {
    return activists[addr];
  }

  /**
   * @dev Check if a specific activist exists
   * @return a bool that represent if a activist exists or not
   */
  function activistExists(address addr) public view returns (bool) {
    return bytes(activists[addr].name).length > 0;
  }

  function incrementRequests(address addr) public mustBeAllowedCaller {
    activists[addr].totalInspections++;
  }

  function incrementGiveUps(address addr) public mustBeAllowedCaller {
    activists[addr].giveUps++;
  }

  function decreaseGiveUps(address addr) public mustBeAllowedCaller {
    activists[addr].giveUps--;
  }

  function lastAcceptedAt(address addr, uint256 blocksNumber) public mustBeAllowedCaller {
    activists[addr].lastAcceptedAt = blocksNumber;
  }

  // MODIFIERS

  modifier uniqueActivist() {
    require(!activistExists(msg.sender), "This activist already exist");
    _;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <=0.9.0;

import "./Ownable.sol";

contract Callable is Ownable {
  mapping(address => bool) public allowedCallers;

  function newAllowedCaller(address allowed) public onlyOwner {
    allowedCallers[allowed] = true;
  }

  function isAllowedCaller(address caller) public view returns (bool) {
    return allowedCallers[caller];
  }

  modifier mustBeAllowedCaller() {
    require(allowedCallers[msg.sender], "Not allowed caller");
    _;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <=0.9.0;

import "./UserTypes.sol";

struct Activist {
  uint256 id;
  address activistWallet;
  UserType userType;
  string name;
  string proofPhoto;
  uint256 totalInspections;
  uint256 giveUps;
  ActivistAddress activistAddress;
  uint256 lastAcceptedAt;
}

struct ActivistAddress {
  string country;
  string state;
  string city;
  string cep;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <=0.9.0;

import "./Ownable.sol";
import "./UserTypes.sol";
import "./Callable.sol";

/**
 * @title UserContract
 * @dev This contract work as a centralized user's system, where all users has your userType here
 */
contract UserContract is Ownable, Callable {
  mapping(address => UserType) internal users;
  mapping(address => Delation[]) private delations;

  uint256 public delationsCount;
  uint256 public usersCount;

  // TODO: Add requires of modifiers mustNotExists and mustBeValidType inside function and remove modifier
  /**
   * @dev Add new user in the system
   * @param addr The address of the user
   * @param userType The type of the user - enum UserType
   */
  function addUser(address addr, UserType userType)
    public
    mustBeAllowedCaller
    mustNotExists(addr)
    mustBeValidType(userType)
  {
    users[addr] = userType;
    usersCount++;
  }

  /**
   * @dev Returns the user type if the user is registered
   * @param addr the user address that want check if exists
   */
  function getUser(address addr) public view returns (UserType) {
    return users[addr];
  }

  // TODO: have a better way to return types?
  /**
   * @dev Returns the enum UserType of the system
   */
  function userTypes()
    public
    pure
    returns (
      string memory,
      string memory,
      string memory,
      string memory,
      string memory,
      string memory,
      string memory,
      string memory
    )
  {
    return (
      "UNDEFINED",
      "PRODUCER",
      "ACTIVIST",
      "RESEARCHER",
      "DEVELOPER",
      "ADVISOR",
      "CONTRIBUTOR",
      "INVESTOR"
    );
  }

  // TODO: Add modifiers requires inside the function and remove modifiers
  /**
   * @dev Add new delation in the system
   * @param addr The address of the user
   * @param title Title the delation
   * @param testimony Content the delation
   * @param proofPhoto Photo proof the delation
   */
  function addDelation(
    address addr,
    string memory title,
    string memory testimony,
    string memory proofPhoto
  ) public callerMustExists reportedMustExists(addr) {
    uint256 id = delationsCount + 1;

    Delation memory delation = Delation(
      id,
      msg.sender,
      addr,
      title,
      testimony,
      proofPhoto
    );

    delations[addr].push(delation);
    delationsCount++;
  }

  /**
   * @dev Returns the user address delated
   */
  function getUserDelations(address addr) public view returns (Delation[] memory) {
    return delations[addr];
  }

  function exists(address addr) public view returns (bool) {
    return users[addr] != UserType.UNDEFINED;
  }

  // MODIFIER

  modifier mustNotExists(address addr) {
    require(users[addr] == UserType.UNDEFINED, "User already exists");
    _;
  }

  modifier callerMustExists() {
    require(users[msg.sender] != UserType.UNDEFINED, "Caller must be registered");
    _;
  }

  modifier reportedMustExists(address addr) {
    require(users[addr] != UserType.UNDEFINED, "User must be registered");
    _;
  }

  /**
   * @dev Modifier to check if user type is UNDEFINED when register
   */
  modifier mustBeValidType(UserType userType) {
    require(userType != UserType.UNDEFINED, "Invalid user type");
    _;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <=0.9.0;

enum UserType {
  UNDEFINED,
  PRODUCER,
  ACTIVIST,
  RESEARCHER,
  DEVELOPER,
  ADVISOR,
  CONTRIBUTOR,
  INVESTOR
}

struct Delation {
  uint256 id;
  address informer;
  address reported;
  string title;
  string testimony;
  string proofPhoto;
}

// SPDX-License-Identifier: GPL-3.0
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

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

// SPDX-License-Identifier: GPL-3.0
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