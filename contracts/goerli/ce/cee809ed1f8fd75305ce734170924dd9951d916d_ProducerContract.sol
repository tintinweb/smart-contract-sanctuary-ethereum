// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <=0.9.0;

import "./UserContract.sol";
import "./ProducerTypes.sol";
import "./Callable.sol";
import "./ProducerPool.sol";

/**
 * @title ProducerContract
 * @dev Producer resource that represent a user that can request a inspection
 */
contract ProducerContract is Callable {
  uint256 internal constant MINIMUM_INSPECTION_TO_POOL = 3;
  int256 internal constant LIMIT_ISA_SCORE_TO_POOL = 1000;

  mapping(address => Producer) public producers;

  UserContract internal userContract;
  ProducerPool internal producerPool;

  address[] internal producersAddress;
  uint256 public producersCount;
  uint256 public producersSustainable;
  int256 public producersTotalScore;

  constructor(address userContractAddress, address producerPoolAddress) {
    userContract = UserContract(userContractAddress);
    producerPool = ProducerPool(producerPoolAddress);
  }

  /**
   * @dev Allow a new register of producer
   * @param name the name of the producer
   * @param document the document of producer
   * @param documentType the document type of producer. CPF/CNPJ
   * @param country the country where the producer is
   * @param state the state of the producer
   * @param city the of the producer
   * @param cep the cep of the producer
   */
  function addProducer(
    string memory name,
    string memory proofPhoto,
    string memory document,
    string memory documentType,
    string memory country,
    string memory state,
    string memory city,
    string memory street,
    string memory complement,
    string memory cep
  ) public {
    require(!producerExists(msg.sender), "This producer already exist");

    UserType userType = UserType.PRODUCER;

    // TODO: Create issue to create producer instance before, so add just the required fields
    Producer memory producer = Producer(
      producersCount + 1,
      msg.sender,
      userType,
      name,
      proofPhoto,
      UserDocument(document, documentType),
      false,
      0,
      0,
      Isa(0, 0, false),
      PropertyAddress(country, state, city, street, complement, cep),
      Pool(producerPool.currentContractEra())
    );

    producers[msg.sender] = producer;
    producersAddress.push(msg.sender);
    producersCount++;
    userContract.addUser(msg.sender, userType);
  }

  /**
   * @dev Returns all registered producers
   * @return Producer struct array
   */
  function getProducers() public view returns (Producer[] memory) {
    Producer[] memory producerList = new Producer[](producersCount);

    // TODO: Add producersCount in a memory variable before call in the for loop
    for (uint256 i = 0; i < producersCount; i++) {
      address acAddress = producersAddress[i];
      producerList[i] = producers[acAddress];
    }

    return producerList;
  }

  /**
   * @dev Return a specific producer
   * @param addr the address of the producer.
   */
  function getProducer(address addr) public view returns (Producer memory producer) {
    return producers[addr];
  }

  function withdraw() public {
    Producer memory producer = producers[msg.sender];

    require(producerExists(msg.sender), "Only producers pool");
    require(minimumInspections(producer.totalInspections), "Minimum inspections");
    require(!limitIsaScore(producer.isa.isaScore), "Limit ISA Score");
    // TODO: Create issue to add validation by last 12 eras

    producerPool.withdraw(
      msg.sender,
      producersTotalScore,
      producer.isa.isaScore,
      producer.pool.currentEra
    );

    incrementCurrentEra(msg.sender);
  }

  function minimumInspections(uint256 totalInspections) internal pure returns (bool) {
    return totalInspections >= MINIMUM_INSPECTION_TO_POOL;
  }

  function limitIsaScore(int256 isaScore) internal pure returns (bool) {
    return isaScore >= LIMIT_ISA_SCORE_TO_POOL;
  }

  /**
   * @dev Check if a specific producer exists
   * @return a bool that represent if a producer exists or not
   */
  function producerExists(address addr) public view returns (bool) {
    return producers[addr].id > 0;
  }

  function recentInspection(address addr, bool state) public mustBeAllowedCaller {
    producers[addr].recentInspection = state;
  }

  function setIsaScore(address addr, int256 isaScore)
    public
    mustBeAllowedCaller
    returns (bool)
  {
    Producer memory producer = producers[addr];

    producer.isa.isaScore += isaScore;
    producers[addr] = producer;
    int256 newProducerScore = producer.isa.isaScore;

    if (producer.isa.sustainable) return true;
    if (newProducerScore < 0) isaScore = isaScore - (newProducerScore);

    producersTotalScore += isaScore;

    if (limitIsaScore(producer.isa.isaScore)) changeProducerToSustainable(producer);

    return true;
  }

  function changeProducerToSustainable(Producer memory producer) internal {
    producersSustainable++;
    producers[producer.producerWallet].isa.sustainable = true;
    producersTotalScore -= producer.isa.isaScore;
  }

  function incrementCurrentEra(address addr) internal {
    producers[addr].pool.currentEra++;
  }

  function incrementInspections(address addr) public mustBeAllowedCaller {
    producers[addr].totalInspections++;
  }

  function lastRequestAt(address addr, uint256 blocksNumber) public mustBeAllowedCaller {
    producers[addr].lastRequestAt = blocksNumber;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <=0.9.0;

import "./PoolInterface.sol";
import "./SacTokenInterface.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Blockable.sol";
import "./Callable.sol";

/**
 * @author Sintrop
 * @title ProducerPool
 * @dev ProducerPool is a contract to reward producers
 */
contract ProducerPool is Ownable, Blockable, Callable {
  using SafeMath for uint256;

  uint256 internal immutable halving;
  uint256 internal immutable totalEras;

  SacTokenInterface internal sacToken;

  uint256[8] internal tokensPerEpochs = [
    360000000000000000000000000,
    180000000000000000000000000,
    90000000000000000000000000,
    45000000000000000000000000,
    22500000000000000000000000,
    11250000000000000000000000,
    5625000000000000000000000,
    2812500000000000000000000
  ];

  constructor(
    address sacTokenAddress,
    uint256 _halving,
    uint256 _totalEras,
    uint256 _blocksPerEra
  ) Blockable(_blocksPerEra, _totalEras) {
    sacToken = SacTokenInterface(sacTokenAddress);
    halving = _halving;
    totalEras = _totalEras;
  }

  /**
   * @dev Returns how much tokens the contract has
   */
  function balance() public view returns (uint256) {
    return balanceOf(address(this));
  }

  /**
   * @dev Returns how much tokensa user has
   * @param addr The address of the developer
   */
  function balanceOf(address addr) public view returns (uint256) {
    return sacToken.balanceOf(addr);
  }

  function withdraw(
    address receiver,
    int256 totalScores,
    int256 producerScore,
    uint256 currentEra
  ) public mustBeAllowedCaller {
    require(canApprove(currentEra), "You can't approve yet");
    uint256 numTokens = tokens(totalScores, producerScore);
    require(numTokens > 0, "Don't have tokens to withdraw");

    sacToken.transferWith(address(this), receiver, numTokens);
  }

  function tokensPerEra() public view returns (uint256) {
    return tokensPerEpoch().div(totalEras);
  }

  function tokensPerEpoch() public view returns (uint256) {
    return tokensPerEpochs[currentEpoch() - 1];
  }

  function currentEpoch() public view returns (uint256) {
    return currentContractEra().div(halving) + 1;
  }

  function tokens(int256 totalScores, int256 producerScore)
    internal
    view
    returns (uint256)
  {
    if (!scoresToApprove(totalScores, producerScore)) return 0;
    return uint256(producerScore).mul((tokensPerEra().div(uint256(totalScores))));
  }

  function scoresToApprove(int256 totalScores, int256 producerScore)
    internal
    pure
    returns (bool)
  {
    return totalScores > 0 && producerScore > 0;
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

struct Producer {
  uint256 id;
  address producerWallet;
  UserType userType;
  string name;
  string proofPhoto;
  UserDocument userDocument;
  bool recentInspection;
  uint256 totalInspections;
  uint256 lastRequestAt;
  Isa isa;
  PropertyAddress propertyAddress;
  Pool pool;
}

struct Pool {
  uint256 currentEra;
}

struct Isa {
  int256 isaScore;
  int256 isaAverage;
  bool sustainable;
}

struct PropertyAddress {
  string country;
  string state;
  string city;
  string street;
  string complement;
  string cep;
}

struct UserDocument {
  string document;
  string documentType;
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
pragma solidity >=0.7.0 <=0.9.0;

import "./SafeMath.sol";

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

  function currentUserBlockNumber(uint256 currentUserEra)
    internal
    view
    returns (uint256)
  {
    return deployedAt.add(blocksPerEra.mul(currentUserEra));
  }

  function currentBlockNumber() internal view returns (uint256) {
    return block.number;
  }
}

// SPDX-License-Identifier: GPL-3.0
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <=0.9.0;

interface SacTokenInterface {
  function balanceOf(address tokenOwner) external view returns (uint256);

  function allowance(address owner, address delegate) external view returns (uint256);

  function approveWith(address delegate, uint256 numTokens) external returns (uint256);

  function transferWith(
    address tokenOwner,
    address receiver,
    uint256 numTokens
  ) external returns (bool);

  function transferFrom(
    address owner,
    address to,
    uint256 numTokens
  ) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
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