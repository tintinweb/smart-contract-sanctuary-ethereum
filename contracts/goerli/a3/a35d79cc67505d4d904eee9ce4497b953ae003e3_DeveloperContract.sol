/**
 *Submitted for verification at Etherscan.io on 2022-09-13
*/

// File: v2-goerli/DeveloperPoolTypes.sol
// SPDX-License-Identifier: GPL-3.0


pragma solidity >=0.7.0 <=0.9.0;

struct Era {
  uint256 tokens;
  uint256 developers;
  uint256 levels;
  DeveloperToken[] developerTokens;
}

struct DeveloperToken {
  address wallet;
  uint256 tokens;
}

// File: v2-goerli/SafeMath.sol


// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: v2-goerli/Blockable.sol


pragma solidity >=0.7.0 <=0.9.0;


/**
 * @author Sintrop
 * @title Blockable
 * @dev Blockable is a contract to manage blocks eras
 */
contract Blockable {
  using SafeMath for uint256;

  uint256 public constant BLOCKS_PRECISION = 5;

  uint256 public blocksPerEra;
  uint256 public deployedAt;
  uint256 public eraMax;

  constructor(uint256 _blocksPerEra, uint256 _eraMax) {
    blocksPerEra = _blocksPerEra;
    eraMax = _eraMax;
    deployedAt = currentBlockNumber();
  }

  function canApprove(uint256 currentUserEra) public view returns (bool) {
    return currentUserEra < currentContractEra() && validEra(currentUserEra);
  }

  function currentContractEra() public view returns (uint256) {
    return currentBlockNumber().sub(deployedAt).div(blocksPerEra).add(1);
  }

  function nextApproveIn(uint256 currentUserEra) public view returns (int256) {
    return
      int256(deployedAt) +
      (int256(blocksPerEra) * int256(currentUserEra)) -
      int256(currentBlockNumber());
  }

  function canApproveTimes(uint256 currentUserEra) public view returns (uint256) {
    int256 approvesTimes = nextApproveIn(currentUserEra);

    if (approvesTimes > 0) return 0;

    return uint256(-approvesTimes).mul(10**BLOCKS_PRECISION).div(blocksPerEra);
  }

  // PRIVATE FUNCTIONS

  function validEra(uint256 currentEra) internal view returns (bool) {
    return currentEra <= eraMax;
  }

  function currentUserBlockNumber(uint256 currentUserEra) internal view returns (uint256) {
    return deployedAt.add(blocksPerEra.mul(currentUserEra));
  }

  function currentBlockNumber() internal view returns (uint256) {
    return block.number;
  }
}

// File: v2-goerli/SacTokenInterface.sol


pragma solidity >=0.7.0 <=0.9.0;

interface SacTokenInterface {
  function balanceOf(address tokenOwner) external view returns (uint256);

  function allowance(address owner, address delegate) external view returns (uint256);

  function approveWith(address delegate, uint256 numTokens) external returns (uint256);

  function transferWith(address tokenOwner, uint256 numTokens) external returns (bool);

  function transferFrom(
    address owner,
    address to,
    uint256 numTokens
  ) external returns (bool);
}

// File: v2-goerli/PoolInterface.sol


pragma solidity >=0.7.0 <=0.9.0;

interface PoolInterface {
  /*
   * @dev Allow a user approve tokens from pool to your account
   */
  function approve(
    address delegate,
    uint256 level,
    uint256 currentEra
  ) external;

  /*
   * @dev Allow a user withdraw (transfer) your tokens approved to your account
   */
  function withDraw() external returns (bool);

  /*
   * @dev Allow a user know how much tokens his has approved from pool
   */
  function allowance() external view returns (uint256);
}

// File: v2-goerli/UserTypes.sol


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

// File: v2-goerli/DeveloperTypes.sol


pragma solidity >=0.7.0 <=0.9.0;


struct Developer {
  uint256 id;
  address developerWallet;
  UserType userType;
  string name;
  string document;
  string documentType;
  Level level;
  UserAddress userAddress;
  uint256 createdAt;
}

struct UserAddress {
  string country;
  string state;
  string city;
  string cep;
}

struct Level {
  uint256 level;
  uint256 currentEra;
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

// File: v2-goerli/DeveloperPool.sol


pragma solidity >=0.7.0 <=0.9.0;








/**
 * @author Sintrop
 * @title DeveloperContract
 * @dev DeveloperPool is a contract to reward developers
 */
contract DeveloperPool is Ownable, Blockable, Callable, PoolInterface {
  using SafeMath for uint256;

  uint256 public constant FIXED_POINT = 10**18;
  uint256 public constant TOKENS_PER_ERA = 833333000000000000000000;
  uint256 public constant ERAS = 18;

  SacTokenInterface internal sacToken;

  mapping(uint256 => Era) public eras;

  constructor(
    address sacTokenAddress,
    uint256 blocksPerEra,
    uint256 eraMax
  ) Blockable(blocksPerEra, eraMax) {
    sacToken = SacTokenInterface(sacTokenAddress);
  }

  /**
   * @dev Returns a era
   * @param era The number of the era
   */
  function getEra(uint256 era) public view returns (Era memory) {
    return eras[era];
  }

  /**
   * @dev Allow developers to claim their tokens
   * @param delegate The address of the delegate developer
   * @param level The level the developer is at
   * @param currentEra The currentEra of the developer
   */
  function approve(
    address delegate,
    uint256 level,
    uint256 currentEra
  ) public override mustBeAllowedCaller {
    require(canApprove(currentEra), "You can't approve yet");

    uint256 devTokens = tokens(level, currentEra);

    sacToken.approveWith(delegate, devTokens);
  }

  //TODO: Implement withdraw method (pool and sacToken)
  function withDraw() public pure override returns (bool) {
    return true;
  }

  /**
   * @dev Returns the amount of tokens a developer can claim
   */
  function allowance() public view override returns (uint256) {
    return sacToken.allowance(address(this), msg.sender);
  }

  /**
   * @dev Returns how much tokens the developer has
   * @param tokenOwner The address of the developer
   */
  function balanceOf(address tokenOwner) public view returns (uint256) {
    return sacToken.balanceOf(tokenOwner);
  }

  /**
   * @dev Returns how much tokens the contract has
   */
  function balance() public view returns (uint256) {
    return balanceOf(address(this));
  }

  /**
   * @dev Allow add new level to eras
   * @param fromEra The era to start adding levels
   */
  function addLevel(uint256 fromEra) public mustBeAllowedCaller {
    upLevels(fromEra);
  }

  /**
   * @dev Allow remove levels from eras
   * @param fromEra The era to start removing levels
   * @param levels The amount of levels to remove
   */
  function removeLevel(uint256 fromEra, uint256 levels) public mustBeAllowedCaller {
    downLevels(fromEra, levels);
  }

  /**
   * @dev Calc the amount of tokens a developer can claim
   * @param level The level of the developer
   * @param currentEra The current era of the developer
   */
  function tokens(uint256 level, uint256 currentEra) internal view returns (uint256) {
    uint256 levels = eras[currentEra].levels;
    if (levels == 0) return 0;

    return level.mul((TOKENS_PER_ERA.div(levels)));
  }

  /**
   * @dev Increase the amount of levels in eras
   * @param fromEra The era to start adding levels
   */
  function upLevels(uint256 fromEra) internal {
    for (uint256 i = fromEra; i <= ERAS; i++) {
      eras[i].levels++;
    }
  }

  /**
   * @dev Decrease the amount of levels in eras
   * @param fromEra The era to start removing levels
   */
  function downLevels(uint256 fromEra, uint256 levels) internal {
    require(eras[fromEra].levels >= levels, "Not enough levels to remove");

    for (uint256 i = fromEra; i <= ERAS; i++) {
      eras[i].levels -= levels;
    }
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

// File: v2-goerli/DeveloperContract.sol


pragma solidity >=0.7.0 <=0.9.0;






/**
 * @title DeveloperContract
 * @dev Developer resource that represent dev
 */
contract DeveloperContract is Ownable, Registrable {
  mapping(address => Developer) public developers;

  UserContract internal userContract;
  DeveloperPool internal developerPool;

  address[] internal developersAddress;
  uint256 public developersCount;

  constructor(address userContractAddress, address developerPoolAddress) {
    userContract = UserContract(userContractAddress);
    developerPool = DeveloperPool(developerPoolAddress);
  }

  /**
   * @dev Allow a new register of developer
   * @param name the name of the developer
   * @param document the document of developer
   * @param documentType the document type of developer. CPF/CNPJ
   * @param country the country where the developer is
   * @param state the state of the developer
   * @param city the of the developer
   * @param cep the cep of the developer
   */
  function addDeveloper(
    string memory name,
    string memory document,
    string memory documentType,
    string memory country,
    string memory state,
    string memory city,
    string memory cep
  ) public mustBeAllowedUser uniqueDeveloper {
    UserType userType = UserType.DEVELOPER;
    uint256 poolEra = developerPoolEra();
    uint256 level = 1;

    Developer memory developer = Developer(
      developersCount + 1,
      msg.sender,
      userType,
      name,
      document,
      documentType,
      Level(level, poolEra),
      UserAddress(country, state, city, cep),
      block.number
    );

    userContract.addUser(msg.sender, userType);
    developers[msg.sender] = developer;
    developersAddress.push(msg.sender);
    developersCount++;

    incrementEraLevel(poolEra);
  }

  /**
   * @dev Returns all developers
   */
  function getDevelopers() public view returns (Developer[] memory) {
    Developer[] memory developerList = new Developer[](developersCount);

    for (uint256 i = 0; i < developersCount; i++) {
      address devAddress = developersAddress[i];
      developerList[i] = developers[devAddress];
    }

    return developerList;
  }

  /**
   * @dev Returns a developer
   * @param addr The address of the developer
   */
  function getDeveloper(address addr) public view returns (Developer memory developer) {
    return developers[addr];
  }

  /**
   * @dev Check if developer exists
   * @param addr The address of the developer
   */
  function developerExists(address addr) public view returns (bool) {
    return developers[addr].id > 0;
  }

  /**
   * @dev Call approve function from developerPool to try to claim tokens
   */
  function approve() public requireDeveloper returns (bool) {
    Developer memory developer = developers[msg.sender];

    developerPool.approve(msg.sender, developer.level.level, developer.level.currentEra);

    developers[msg.sender].level.currentEra++;

    return true;
  }

  /**
   * @dev Allow the owner to add a new level to the developer
   * @param addr The address of the developer
   */
  function addLevel(address addr) public onlyOwner {
    Developer memory developer = developers[addr];
    developer.level.level++;
    developers[addr] = developer;

    incrementEraLevel(developer.level.currentEra);
  }

  /**
   * @dev Allow the owner to remove levels from the developer
   * @param addr The address of the developer
   * @param levels The number of levels to remove
   */
  function removeLevel(address addr, uint256 levels) public onlyOwner {
    Developer memory developer = developers[addr];

    require(developer.level.level >= levels, "Invalid level to remove");

    developer.level.level -= levels;
    developers[addr] = developer;

    decrementEraLevel(developer.level.currentEra, levels);
  }

  /**
   * @dev Increment the eras level
   * @param fromEra The era to start incrementing
   */
  function incrementEraLevel(uint256 fromEra) internal {
    developerPool.addLevel(fromEra);
  }

  /**
   * @dev Decrement the eras level
   * @param fromEra The era to start decrementing
   * @param levels The number of levels to decrement
   */
  function decrementEraLevel(uint256 fromEra, uint256 levels) internal {
    developerPool.removeLevel(fromEra, levels);
  }

  /**
   * @dev Returns the current era of pool
   */
  function developerPoolEra() internal view returns (uint256) {
    return developerPool.currentContractEra();
  }

  /**
   * @dev Returns max era of pool
   */
  function eraMax() internal view returns (uint256) {
    return developerPool.eraMax();
  }

  // MODIFIERS

  modifier requireDeveloper() {
    require(developerExists(msg.sender), "Pool only to developer");
    _;
  }

  modifier uniqueDeveloper() {
    require(!developerExists(msg.sender), "This developer already exist");
    _;
  }
}