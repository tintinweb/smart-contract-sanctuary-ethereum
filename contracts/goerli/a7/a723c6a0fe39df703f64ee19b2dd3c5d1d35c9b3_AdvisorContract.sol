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

// File: v2-goerli/AdvisorTypes.sol


pragma solidity >=0.7.0 <=0.9.0;


struct Advisor {
  uint256 id;
  address advisorWallet;
  UserType userType;
  string name;
  string document;
  string documentType;
  AdvisorAddress advisorAddress;
}

struct AdvisorAddress {
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

// File: v2-goerli/AdvisorContract.sol


pragma solidity >=0.7.0 <=0.9.0;




contract AdvisorContract is Registrable {
  mapping(address => Advisor) internal advisors;

  UserContract internal userContract;
  address[] internal advisorsAddress;
  uint256 public advisorsCount;

  constructor(address userContractAddress) {
    userContract = UserContract(userContractAddress);
  }

  /**
   * @dev Allow a new register of advisor
   * @param name the name of the advisor
   * @param document the document of advisor
   * @param documentType the document type type of advisor. CPF/CNPJ
   * @param country the country where the advisor is
   * @param state the state of the advisor
   * @param city the of the advisor
   * @param cep the cep of the advisor
   * @return a Advisor
   */
  function addAdvisor(
    string memory name,
    string memory document,
    string memory documentType,
    string memory country,
    string memory state,
    string memory city,
    string memory cep
  ) public mustBeAllowedUser uniqueAdvisor returns (Advisor memory) {
    uint256 id = advisorsCount + 1;
    UserType userType = UserType.ADVISOR;

    AdvisorAddress memory advisorAddress = AdvisorAddress(country, state, city, cep);

    Advisor memory advisor = Advisor(
      id,
      msg.sender,
      userType,
      name,
      document,
      documentType,
      advisorAddress
    );

    advisors[msg.sender] = advisor;
    advisorsAddress.push(msg.sender);
    advisorsCount++;
    userContract.addUser(msg.sender, userType);

    return advisor;
  }

  /**
   * @dev Returns all registered advisors
   * @return Advisor struct array
   */
  function getAdvisors() public view returns (Advisor[] memory) {
    Advisor[] memory advisorList = new Advisor[](advisorsCount);

    for (uint256 i = 0; i < advisorsCount; i++) {
      address acAddress = advisorsAddress[i];
      advisorList[i] = advisors[acAddress];
    }

    return advisorList;
  }

  /**
   * @dev Return a specific advisor
   * @param addr the address of the advisor.
   */
  function getAdvisor(address addr) public view returns (Advisor memory) {
    return advisors[addr];
  }

  /**
   * @dev Check if a specific advisor exists
   * @return a bool that represent if a advisor exists or not
   */
  function advisorExists(address addr) public view returns (bool) {
    return bytes(advisors[addr].name).length > 0;
  }

  // MODIFIERS

  modifier uniqueAdvisor() {
    require(!advisorExists(msg.sender), "This advisor already exist");
    _;
  }
}