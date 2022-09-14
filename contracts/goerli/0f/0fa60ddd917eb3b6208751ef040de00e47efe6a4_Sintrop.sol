/**
 *Submitted for verification at Etherscan.io on 2022-09-13
*/

// File: v2-goerli/InspectionTypes.sol
// SPDX-License-Identifier: GPL-3.0


pragma solidity >=0.7.0 <=0.9.0;

enum InspectionStatus {
  OPEN,
  ACCEPTED,
  INSPECTED,
  EXPIRED
}

struct IsaInspection {
  uint256 categoryId;
  uint256 isaIndex;
  string report;
  string proofPhoto;
}

struct Inspection {
  uint256 id;
  InspectionStatus status;
  address createdBy;
  address acceptedBy;
  int256 isaScore;
  uint256 createdAt;
  uint256 updatedAt;
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

// File: v2-goerli/ActivistTypes.sol


pragma solidity >=0.7.0 <=0.9.0;


struct Activist {
  uint256 id;
  address activistWallet;
  UserType userType;
  string name;
  string document;
  string documentType;
  bool recentInspection;
  uint256 totalInspections;
  ActivistAddress activistAddress;
}

struct ActivistAddress {
  string country;
  string state;
  string city;
  string cep;
}

// File: v2-goerli/ProducerTypes.sol


pragma solidity >=0.7.0 <=0.9.0;


struct Producer {
  uint256 id;
  address producerWallet;
  UserType userType;
  string name;
  string document;
  string documentType;
  bool recentInspection;
  uint256 totalRequests;
  uint256 lastRequestAt;
  Isa isa;
  TokenApprove tokenApprove;
  PropertyAddress propertyAddress;
}

struct Isa {
  int256 isaScore;
  int256 isaAverage;
}

struct TokenApprove {
  uint256 allowed;
  bool withdrewToken;
}

struct PropertyAddress {
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

// File: v2-goerli/ActivistContract.sol


pragma solidity >=0.7.0 <=0.9.0;




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
   * @param document the document of activist
   * @param documentType the document type type of activist. CPF/CNPJ
   * @param country the country where the activist is
   * @param state the state of the activist
   * @param city the of the activist
   * @param cep the cep of the activist
   * @return a Activist
   */
  // TODO Add mustBeAllowedCaller
  function addActivist(
    string memory name,
    string memory document,
    string memory documentType,
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
      document,
      documentType,
      false,
      0,
      activistAddress
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

  function recentInspection(address addr, bool state) public mustBeAllowedCaller {
    activists[addr].recentInspection = state;
  }

  function incrementRequests(address addr) public mustBeAllowedCaller {
    activists[addr].totalInspections++;
  }

  // MODIFIERS

  modifier uniqueActivist() {
    require(!activistExists(msg.sender), "This activist already exist");
    _;
  }
}

// File: v2-goerli/ProducerContract.sol


pragma solidity >=0.7.0 <=0.9.0;




/**
 * @title ProducerContract
 * @dev Producer resource that represent a user that can request a inspection
 */
contract ProducerContract is Callable {
  mapping(address => Producer) public producers;

  UserContract internal userContract;
  address[] internal producersAddress;
  uint256 public producersCount;

  constructor(address userContractAddress) {
    userContract = UserContract(userContractAddress);
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
    string memory document,
    string memory documentType,
    string memory country,
    string memory state,
    string memory city,
    string memory cep
  ) public uniqueProducer {
    UserType userType = UserType.PRODUCER;

    Producer memory producer = Producer(
      producersCount + 1,
      msg.sender,
      userType,
      name,
      document,
      documentType,
      false,
      0,
      0,
      Isa(0, 0),
      TokenApprove(0, false),
      PropertyAddress(country, state, city, cep)
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

  function updateIsaScore(address addr, int256 isaScore) public mustBeAllowedCaller {
    producers[addr].isa.isaScore = isaScore;
  }

  function incrementRequests(address addr) public mustBeAllowedCaller {
    producers[addr].totalRequests++;
  }

  function approveProducerNewTokens(address addr, uint256 numTokens) public mustBeAllowedCaller {
    uint256 tokens = producers[addr].tokenApprove.allowed;
    producers[addr].tokenApprove = TokenApprove(tokens += numTokens, false);
  }

  function lastRequestAt(address addr, uint256 blocksNumber) public mustBeAllowedCaller {
    producers[addr].lastRequestAt = blocksNumber;
  }

  function getProducerApprove(address address_) public view returns (uint256) {
    return producers[address_].tokenApprove.allowed;
  }

  function undoProducerApprove() internal returns (bool) {
    producers[msg.sender].tokenApprove = TokenApprove(0, false);
    return true;
  }

  // MODIFIERS

  modifier uniqueProducer() {
    require(!producerExists(msg.sender), "This producer already exist");
    _;
  }
}

// File: v2-goerli/Sintrop.sol


pragma solidity >=0.7.0 <=0.9.0;





/**
 * @title SintropContract
 * @dev Sintrop application to certificated a rural producer
 */
contract Sintrop {
  mapping(address => mapping(address => bool)) internal activistInspected;
  mapping(address => Inspection[]) internal userInspections;
  mapping(uint256 => Inspection) internal inspections;
  mapping(uint256 => IsaInspection[]) public isas;

  ActivistContract public activistContract;
  ProducerContract public producerContract;

  uint256 public inspectionsCount;
  uint256 internal timeBetweenInspections;

  constructor(
    address activistContractAddress,
    address producerContractAddress,
    uint256 timeBetweenInspections_
  ) {
    activistContract = ActivistContract(activistContractAddress);
    producerContract = ProducerContract(producerContractAddress);
    timeBetweenInspections = timeBetweenInspections_;
  }

  /**
   * @dev Allows the current user producer/activist get all yours inspections with status INSPECTED
   */
  function getInspectionsHistory() public view returns (Inspection[] memory) {
    return userInspections[msg.sender];
  }

  /**
   * @dev List IsaInspection from inspection
   * @param inspectionId The id of the inspection to get IsaInspection
   */
  function getIsa(uint256 inspectionId) public view returns (IsaInspection[] memory) {
    return isas[inspectionId];
  }

  /**
   * @dev Allows the current user (producer) request a inspection.
   */
  function requestInspection()
    public
    requireProducer
    requireNoInspectionsOpen
    requireNoRecentInspection
  {
    newRequest();

    producerContract.recentInspection(msg.sender, true);
    producerContract.lastRequestAt(msg.sender, block.number);
  }

  function newRequest() internal {
    Inspection memory inspection = Inspection(
      inspectionsCount + 1,
      InspectionStatus.OPEN,
      msg.sender,
      msg.sender,
      0,
      block.number,
      0
    );
    inspections[inspection.id] = inspection;
    inspectionsCount++;
  }

  /**
   * @dev Allows the current user (activist) accept a inspection.
   * @param inspectionId The id of the inspection that the activist want accept.
   */
  function acceptInspection(uint256 inspectionId)
    public
    requireActivist
    requireInspectionExists(inspectionId)
    requireNotInspectedProducer(inspectionId)
    returns (bool)
  {
    Inspection memory inspection = inspections[inspectionId];

    require(inspection.status == InspectionStatus.OPEN, "This inspection is not OPEN");

    inspection.status = InspectionStatus.ACCEPTED;
    inspection.updatedAt = block.timestamp; // solhint-disable-line
    inspection.acceptedBy = msg.sender;
    inspections[inspectionId] = inspection;

    activistContract.recentInspection(msg.sender, true);

    return true;
  }

  /**
   * @dev Allow a activist realize a inspection and mark as INSPECTED
   * @param inspectionId The id of the inspection to be realized
   * @param _isas The IsaIsaInspection[] of the inspection to be realized
   */
  function realizeInspection(uint256 inspectionId, IsaInspection[] memory _isas)
    public
    requireActivist
    requireInspectionExists(inspectionId)
    requireInspectionAccepted(inspectionId)
    requireInspectionOwner(inspectionId)
    returns (bool)
  {
    Inspection memory inspection = inspections[inspectionId];

    markAsRealized(inspection, _isas);

    afterRealizeInspection(inspection);

    producerContract.updateIsaScore(inspection.createdBy, inspection.isaScore);

    producerContract.approveProducerNewTokens(inspection.createdBy, 2000);

    activistInspected[msg.sender][inspection.createdBy] = true;

    return true;
  }

  function markAsRealized(Inspection memory inspection, IsaInspection[] memory _isas) internal {
    inspection.status = InspectionStatus.INSPECTED;
    inspection.updatedAt = block.timestamp; // solhint-disable-line
    inspection.isaScore = calculateIsa(inspection, _isas);
    inspections[inspection.id] = inspection;
  }

  function calculateIsa(Inspection memory inspection, IsaInspection[] memory _isas)
    internal
    returns (int256)
  {
    int256[5] memory points = [int256(10), 5, 0, -5, -10];
    int256 isaScore;

    for (uint8 i = 0; i < _isas.length; i++) {
      isas[inspection.id].push(_isas[i]);
      uint256 isaIndex = _isas[i].isaIndex;
      isaScore += points[isaIndex];
    }

    return isaScore;
  }

  /**
   * @dev Inscrement producer and activist request action and mark both as no recent open requests and inspection
   * @param inspection the inspected inspection
   */
  function afterRealizeInspection(Inspection memory inspection) internal {
    address createdBy = inspection.createdBy;
    address acceptedBy = inspection.acceptedBy;

    // Increment actvist inspections and release to carry out new inspections
    activistContract.recentInspection(acceptedBy, false);
    activistContract.incrementRequests(acceptedBy);

    // Increment producer requests and release to carry out new requests
    producerContract.recentInspection(createdBy, false);
    producerContract.incrementRequests(createdBy);

    userInspections[createdBy].push(inspection);
    userInspections[acceptedBy].push(inspection);
  }

  /**
   * @dev Returns a inspection by id if that exists.
   * @param id The id of the inspection to return.
   */
  function getInspection(uint256 id) public view returns (Inspection memory) {
    return inspections[id];
  }

  /**
   * @dev Returns all requested inspections.
   */
  function getInspections() public view returns (Inspection[] memory) {
    Inspection[] memory inspectionsList = new Inspection[](inspectionsCount);

    for (uint256 i = 0; i < inspectionsCount; i++) {
      inspectionsList[i] = inspections[i + 1];
    }

    return inspectionsList;
  }

  /**
   * @dev Returns all inpections status string.
   */
  function getInspectionsStatus()
    public
    pure
    returns (
      string memory,
      string memory,
      string memory,
      string memory
    )
  {
    return ("OPEN", "ACCEPTED", "INSPECTED", "EXPIRED");
  }

  /**
   * @dev Check if an inspections exists in mapping.
   * @param id The id of the inspection that the activist want accept.
   */
  function inspectionExists(uint256 id) public view returns (bool) {
    return inspections[id].id >= 1;
  }

  function isActivistOwner(uint256 inspectionId) internal view returns (bool) {
    return inspections[inspectionId].acceptedBy == msg.sender;
  }

  function isAccepted(uint256 inspectionId) internal view returns (bool) {
    return inspections[inspectionId].status == InspectionStatus.ACCEPTED;
  }

  function canRequestInspection() public view returns (bool) {
    Producer memory producer = producerContract.getProducer(msg.sender);

    uint256 lastRequestAt = producer.lastRequestAt;
    bool canRequest = block.number > lastRequestAt + timeBetweenInspections;

    return canRequest || lastRequestAt == 0;
  }

  // MODIFIERS
  modifier requireNotInspectedProducer(uint256 inspectionId) {
    Inspection memory inspection = inspections[inspectionId];

    require(
      !activistInspected[msg.sender][inspection.createdBy],
      "Already inspected this producer"
    );
    _;
  }

  modifier requireActivist() {
    require(activistContract.activistExists(msg.sender), "Please register as activist");
    _;
  }

  modifier requireInspectionExists(uint256 inspectionId) {
    require(inspectionExists(inspectionId), "This inspection don't exists");
    _;
  }

  modifier requireProducer() {
    require(producerContract.producerExists(msg.sender), "Please register as producer");
    _;
  }

  modifier requireNoInspectionsOpen() {
    require(!producerContract.getProducer(msg.sender).recentInspection, "Request OPEN or ACCEPTED");
    _;
  }

  modifier requireNoRecentInspection() {
    require(canRequestInspection(), "Recent inspection");
    _;
  }

  modifier requireInspectionAccepted(uint256 inspectionId) {
    require(isAccepted(inspectionId), "Accept this inspection before");
    _;
  }

  modifier requireInspectionOwner(uint256 inspectionId) {
    require(isActivistOwner(inspectionId), "You not accepted this inspection");
    _;
  }
}