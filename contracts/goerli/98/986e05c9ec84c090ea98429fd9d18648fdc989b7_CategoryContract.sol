/**
 *Submitted for verification at Etherscan.io on 2022-09-13
*/

// File: v2-goerli/UserTypes.sol
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

// File: v2-goerli/ResearcherTypes.sol


pragma solidity >=0.7.0 <=0.9.0;


struct Researcher {
  uint256 id;
  address researcherWallet;
  UserType userType;
  string name;
  string document;
  string documentType;
  ResearcherAddress researcherAddress;
}

struct ResearcherAddress {
  string country;
  string state;
  string city;
  string cep;
}

// File: v2-goerli/Context.sol


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

// File: v2-goerli/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: v2-goerli/Registrable.sol


pragma solidity >=0.7.0 <=0.9.0;


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

// File: v2-goerli/Callable.sol


pragma solidity >=0.7.0 <=0.9.0;


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

// File: v2-goerli/UserContract.sol


pragma solidity >=0.7.0 <=0.9.0;




/**
 * @title UserContract
 * @dev This contract work as a centralized user's system, where all users has your userType here
 */
contract UserContract is Ownable, Callable {
  mapping(address => UserType) internal users;

  uint256 public usersCount;

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

  // MODIFIER

  modifier mustNotExists(address addr) {
    require(users[addr] == UserType.UNDEFINED, "User already exists");
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

// File: v2-goerli/ResearcherContract.sol


pragma solidity >=0.7.0 <=0.9.0;




contract ResearcherContract is Registrable {
  mapping(address => Researcher) internal researchers;

  UserContract internal userContract;
  address[] internal researchersAddress;
  uint256 public researchersCount;

  constructor(address userContractAddress) {
    userContract = UserContract(userContractAddress);
  }

  /**
   * @dev Allow a new register of researcher
   * @param name the name of the researcher
   * @param document the document of researcher
   * @param documentType the document type type of researcher. CPF/CNPJ
   * @param country the country where the researcher is
   * @param state the state of the researcher
   * @param city the of the researcher
   * @param cep the cep of the researcher
   * @return a Researcher
   */
  function addResearcher(
    string memory name,
    string memory document,
    string memory documentType,
    string memory country,
    string memory state,
    string memory city,
    string memory cep
  ) public uniqueResearcher mustBeAllowedUser returns (Researcher memory) {
    uint256 id = researchersCount + 1;
    UserType userType = UserType.RESEARCHER;

    Researcher memory researcher = Researcher(
      id,
      msg.sender,
      userType,
      name,
      document,
      documentType,
      ResearcherAddress(country, state, city, cep)
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

  // MODIFIERS

  modifier uniqueResearcher() {
    require(!researcherExists(msg.sender), "This researcher already exist");
    _;
  }
}

// File: v2-goerli/CategoryTypes.sol


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

// File: v2-goerli/PoolPassiveInterface.sol


pragma solidity >=0.7.0 <=0.9.0;

interface PoolPassiveInterface {
  /*
   * @dev Allow a user approve tokens from pool to your account
   */
  function approveWith(address delegate, uint256 _numTokens) external returns (bool);

  /*
   * @dev Allow a user transfer tokens to pool
   */
  function transferWith(address tokenOwner, uint256 tokens) external returns (bool);

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

// File: v2-goerli/CategoryContract.sol


pragma solidity >=0.7.0 <=0.9.0;




/**
 * @author Sintrop
 * @title CategoryContract
 * @dev Category resource that is a part of Sintrop business
 */
contract CategoryContract {
  mapping(uint256 => Category) public categories;
  mapping(uint256 => uint256) public votes;
  mapping(address => mapping(uint256 => uint256)) public voted;

  ResearcherContract public researcherContract;

  Category public category;
  uint256 public categoryCounts;
  PoolPassiveInterface internal isaPool;

  constructor(address _isaPoolAddress, address researcherContractAddress) {
    isaPool = PoolPassiveInterface(_isaPoolAddress);
    researcherContract = ResearcherContract(researcherContractAddress);
  }

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

    for (uint256 i = 0; i < categoryCounts; i++) {
      categoriesList[i] = categories[i + 1];
    }

    return categoriesList;
  }

  /**
   * @dev Allow a user vote in a category sending tokens amount to this
   * @param id the id of a category that receives a vote.
   * @param tokens the tokens amount that the use want use to vote.
   * @return boolean
   */
  function vote(uint256 id, uint256 tokens)
    public
    categoryMustExists(id)
    mustHaveSacToken(tokens)
    mustSendSomeSacToken(tokens)
    returns (bool)
  {
    isaPool.transferWith(msg.sender, tokens);

    votes[id] += tokens;
    voted[msg.sender][id] += tokens;

    categories[id].votesCount++;
    return true;
  }

  /**
   * @dev Allow a user unvote in a category and get your tokens again
   * @param id the id of a category that receives a vote.
   * @return uint256
   */
  function unvote(uint256 id) public categoryMustExists(id) mustHaveVoted(id) returns (uint256) {
    uint256 tokens = voted[msg.sender][id];

    isaPool.approveWith(msg.sender, tokens);

    votes[id] -= tokens;
    voted[msg.sender][id] = 0;
    categories[id].votesCount--;

    return tokens;
  }

  // MODIFIERS

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
    require(researcherContract.researcherExists(msg.sender), "Only allowed to researchers");
    _;
  }
}