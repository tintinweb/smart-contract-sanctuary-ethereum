// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <=0.9.0;

import "./PoolPassiveInterface.sol";
import "./CategoryTypes.sol";
import "./ResearcherContract.sol";
import "./UserContract.sol";

/**
 * @author Sintrop
 * @title CategoryContract
 * @dev Category resource that is a part of Sintrop business
 */
contract CategoryContract {
  uint256 public constant LIMIT_VOTING = 100000000000000000000000;

  mapping(uint256 => Category) public categories;
  mapping(uint256 => uint256) public votes;
  mapping(address => mapping(uint256 => uint256)) public voted;

  ResearcherContract public researcherContract;
  UserContract public userContract;

  // TODO: Remove state category (unused)
  Category public category;
  uint256 public categoryCounts;
  PoolPassiveInterface internal isaPool;

  // TODO: Remove researcherContract and use only userContract to check if exists or if is a researcher
  constructor(
    address _isaPoolAddress,
    address researcherContractAddress,
    address userContractAddress
  ) {
    isaPool = PoolPassiveInterface(_isaPoolAddress);
    researcherContract = ResearcherContract(researcherContractAddress);
    userContract = UserContract(userContractAddress);
  }

  // TODO: remove modifier and use require direct in the function (modifier is not reutilized)
  /**
   * @dev add a new category
   * @param name the name of category
   * @param description the description of category
   * @param tutorial how activists should evaluate it.
   * @param totallySustainable the description text to this metric
   * @param partiallySustainable the description text to this metric
   * @param neutro the description text to this metric
   * @param partiallyNotSustainable the description text to this metric
   * @param totallyNotSustainable the description text to this metric
   * @return bool
   */
  function addCategory(
    string memory name,
    string memory description,
    string memory tutorial,
    string memory totallySustainable,
    string memory partiallySustainable,
    string memory neutro,
    string memory partiallyNotSustainable,
    string memory totallyNotSustainable
  ) public requireResearcher returns (bool) {
    category = Category(
      categoryCounts + 1,
      msg.sender,
      name,
      description,
      tutorial,
      totallySustainable,
      partiallySustainable,
      neutro,
      partiallyNotSustainable,
      totallyNotSustainable,
      0
    );

    categories[category.id] = category;
    categoryCounts++;

    return true;
  }

  /**
   * @dev Returns all added categories
   * @return category struc array
   */
  function getCategories() public view returns (Category[] memory) {
    Category[] memory categoriesList = new Category[](categoryCounts);

    // TODO: Add categoryCounts in a memory variable before the loop
    for (uint256 i = 0; i < categoryCounts; i++) {
      categoriesList[i] = categories[i + 1];
    }

    return categoriesList;
  }

  // TODO: Remove not reutilized modifiers and use require direct in the function
  /**
   * @dev Allow a user vote in a category sending tokens amount to this
   * @param id the id of a category that receives a vote.
   * @param tokens the tokens amount that the use want use to vote.
   * @return boolean
   */
  function vote(uint256 id, uint256 tokens)
    public
    requireUserExists
    categoryMustExists(id)
    mustHaveSacToken(tokens)
    mustSendSomeSacToken(tokens)
    mustNotExceedLimitVoting(id, tokens)
    returns (bool)
  {
    isaPool.transferWith(msg.sender, address(isaPool), tokens);

    votes[id] += tokens;
    voted[msg.sender][id] += tokens;

    categories[id].votesCount++;
    return true;
  }

  // TODO: Remove not reutilized modifiers and use require direct in the function
  /**
   * @dev Allow a user unvote in a category and get your tokens again
   * @param id the id of a category that receives a vote.
   * @return uint256
   */
  function unvote(uint256 id)
    public
    categoryMustExists(id)
    mustHaveVoted(id)
    returns (uint256)
  {
    uint256 tokens = voted[msg.sender][id];

    isaPool.transferWith(address(isaPool), msg.sender, tokens);

    votes[id] -= tokens;
    voted[msg.sender][id] = 0;
    categories[id].votesCount--;

    return tokens;
  }

  // MODIFIERS

  modifier mustNotExceedLimitVoting(uint256 id, uint256 tokens) {
    require(
      voted[msg.sender][id] + tokens <= LIMIT_VOTING,
      "can't vote more than 100k tokens"
    );
    _;
  }

  modifier categoryMustExists(uint256 id) {
    require(categories[id].id > 0, "This category don't exists");
    _;
  }

  modifier mustHaveSacToken(uint256 tokens) {
    require(isaPool.balanceOf(msg.sender) > tokens, "You don't have tokens to vote");
    _;
  }

  modifier mustSendSomeSacToken(uint256 tokens) {
    require(tokens > 0, "Send at least 1 SAC Token");
    _;
  }

  modifier mustHaveVoted(uint256 id) {
    require(voted[msg.sender][id] > 0, "You don't voted to this category");
    _;
  }

  modifier requireResearcher() {
    require(
      researcherContract.researcherExists(msg.sender),
      "Only allowed to researchers"
    );
    _;
  }

  modifier requireUserExists() {
    require(userContract.exists(msg.sender), "Only registered users");
    _;
  }
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

import "./UserContract.sol";
import "./ResearcherTypes.sol";
import "./Registrable.sol";

contract ResearcherContract is Registrable {
  mapping(address => Researcher) internal researchers;
  mapping(uint256 => Work) internal works;

  UserContract internal userContract;
  address[] internal researchersAddress;
  uint256 public researchersCount;
  uint256 public worksCount;

  constructor(address userContractAddress) {
    userContract = UserContract(userContractAddress);
  }

  /**
   * @dev Allow a new register of researcher
   * @param name the name of the researcher
   * @return a Researcher
   */
  function addResearcher(string memory name, string memory proofPhoto)
    public
    uniqueResearcher
    mustBeAllowedUser
    returns (Researcher memory)
  {
    uint256 id = researchersCount + 1;
    UserType userType = UserType.RESEARCHER;

    Researcher memory researcher = Researcher(
      id,
      msg.sender,
      userType,
      name,
      proofPhoto,
      0
    );

    researchers[msg.sender] = researcher;
    researchersAddress.push(msg.sender);
    researchersCount++;
    userContract.addUser(msg.sender, userType);

    return researcher;
  }

  /**
   * @dev Returns all registered researchers
   * @return Researcher struct array
   */
  function getResearchers() public view returns (Researcher[] memory) {
    Researcher[] memory researcherList = new Researcher[](researchersCount);

    for (uint256 i = 0; i < researchersCount; i++) {
      address acAddress = researchersAddress[i];
      researcherList[i] = researchers[acAddress];
    }

    return researcherList;
  }

  /**
   * @dev Return a specific researcher
   * @param addr the address of the researcher.
   */
  function getResearcher(address addr) public view returns (Researcher memory) {
    return researchers[addr];
  }

  /**
   * @dev Check if a specific researcher exists
   * @return a bool that represent if a researcher exists or not
   */
  function researcherExists(address addr) public view returns (bool) {
    return bytes(researchers[addr].name).length > 0;
  }

  function addWork(
    string memory title,
    string memory thesis,
    string memory file
  ) public {
    require(researcherExists(msg.sender), "Only allowed to researchers");

    uint256 id = worksCount + 1;

    Work memory work = Work(id, msg.sender, title, thesis, file, block.timestamp); // solhint-disable-line

    works[id] = work;
    worksCount++;
    researchers[msg.sender].publishedWorks++;
  }

  function getWorks() public view returns (Work[] memory) {
    Work[] memory worksList = new Work[](worksCount);
    uint256 count = worksCount;

    for (uint256 i = 0; i < count; i++) {
      worksList[i] = works[i + 1];
    }

    return worksList;
  }

  // MODIFIERS

  modifier uniqueResearcher() {
    require(!researcherExists(msg.sender), "This researcher already exist");
    _;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <=0.9.0;

enum Isas {
  TOTALLY_SUSTAINABLE,
  PARTIAL_SUSTAINABLE,
  NEUTRO,
  PARTIAL_NOT_SUSTAINABLE,
  TOTALLY_NOT_SUSTAINABLE
}

struct Category {
  uint256 id;
  address createdBy;
  string name;
  string description;
  string tutorial;
  string totallySustainable;
  string partiallySustainable;
  string neutro;
  string partiallyNotSustainable;
  string totallyNotSustainable;
  uint256 votesCount;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <=0.9.0;

interface PoolPassiveInterface {
  /*
   * @dev Allow a user approve tokens from pool to your account
   */
  function approveWith(address delegate, uint256 _numTokens) external returns (bool);

  /*
   * @dev Allow a user transfer tokens to pool
   */
  function transferWith(
    address tokenOwner,
    address receiver,
    uint256 tokens
  ) external returns (bool);

  /*
   * @dev Allow a user withdraw (transfer) your tokens approved to your account
   */
  function withDraw() external returns (bool);

  /*
   * @dev Allow a user know how much tokens his has approved from pool
   */
  function allowance() external view returns (uint256);

  /*
   * @dev Allow a user know how much tokens this pool has available
   */
  function balance() external view returns (uint256);

  /*
   * @dev Allow a user know how much tokens this pool has available
   */
  function balanceOf(address tokenOwner) external view returns (uint256);
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
pragma solidity >=0.7.0 <=0.9.0;

import "./Ownable.sol";

contract Registrable is Ownable {
  mapping(address => bool) public allowedUsers;

  function newAllowedUser(address allowed) public onlyOwner {
    allowedUsers[allowed] = true;
  }

  modifier mustBeAllowedUser() {
    require(allowedUsers[msg.sender], "Not allowed user");
    _;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <=0.9.0;

import "./UserTypes.sol";

struct Researcher {
  uint256 id;
  address researcherWallet;
  UserType userType;
  string name;
  string proofPhoto;
  uint256 publishedWorks;
}

struct Work {
  uint256 id;
  address createdBy;
  string title;
  string thesis;
  string file;
  uint256 createdAtTimeStamp;
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