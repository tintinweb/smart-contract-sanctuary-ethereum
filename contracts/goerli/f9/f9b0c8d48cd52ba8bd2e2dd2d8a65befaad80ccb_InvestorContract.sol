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

// File: v2-goerli/InvestorTypes.sol


pragma solidity >=0.7.0 <=0.9.0;


struct Investor {
  uint256 id;
  address investorWallet;
  UserType userType;
  string name;
  string document;
  string documentType;
  InvestorAddress investorAddress;
}

struct InvestorAddress {
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

// File: v2-goerli/InvestorContract.sol


pragma solidity >=0.7.0 <=0.9.0;



contract InvestorContract {
  mapping(address => Investor) internal investors;

  UserContract internal userContract;
  address[] internal investorsAddress;
  uint256 public investorsCount;

  constructor(address userContractAddress) {
    userContract = UserContract(userContractAddress);
  }

  /**
   * @dev Allow a new register of investor
   * @param name the name of the investor
   * @param document the document of investor
   * @param documentType the document type type of investor. CPF/CNPJ
   * @param country the country where the investor is
   * @param state the state of the investor
   * @param city the of the investor
   * @param cep the cep of the investor
   * @return a investor
   */
  function addInvestor(
    string memory name,
    string memory document,
    string memory documentType,
    string memory country,
    string memory state,
    string memory city,
    string memory cep
  ) public uniqueInvestor returns (Investor memory) {
    uint256 id = investorsCount + 1;
    UserType userType = UserType.INVESTOR;

    InvestorAddress memory investorAddress = InvestorAddress(country, state, city, cep);

    Investor memory investor = Investor(
      id,
      msg.sender,
      userType,
      name,
      document,
      documentType,
      investorAddress
    );

    investors[msg.sender] = investor;
    investorsAddress.push(msg.sender);
    investorsCount++;
    userContract.addUser(msg.sender, userType);

    return investor;
  }

  /**
   * @dev Returns all registered investors
   * @return Investor struct array
   */
  function getInvestors() public view returns (Investor[] memory) {
    Investor[] memory investorList = new Investor[](investorsCount);

    for (uint256 i = 0; i < investorsCount; i++) {
      address acAddress = investorsAddress[i];
      investorList[i] = investors[acAddress];
    }

    return investorList;
  }

  /**
   * @dev Return a specific investor
   * @param addr the address of the investor.
   */
  function getInvestor(address addr) public view returns (Investor memory) {
    return investors[addr];
  }

  /**
   * @dev Check if a specific investor exists
   * @return a bool that represent if a investor exists or not
   */
  function investorExists(address addr) public view returns (bool) {
    return bytes(investors[addr].name).length > 0;
  }

  //MODIFIERS

  modifier uniqueInvestor() {
    require(!investorExists(msg.sender), "This investor already exist");
    _;
  }
}