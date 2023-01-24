// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <=0.9.0;

import "./ProducerContract.sol";
import "./ActivistContract.sol";
import "./CategoryContract.sol";
import "./InspectionTypes.sol";

/**
 * @title SintropContract
 * @dev Sintrop application to certificate a rural producer
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
  uint256 internal blocksToExpireAcceptedInspection;

  constructor(
    address activistContractAddress,
    address producerContractAddress,
    uint256 timeBetweenInspections_,
    uint256 blocksToExpireAcceptedInspection_
  ) {
    activistContract = ActivistContract(activistContractAddress);
    producerContract = ProducerContract(producerContractAddress);
    timeBetweenInspections = timeBetweenInspections_;
    blocksToExpireAcceptedInspection = blocksToExpireAcceptedInspection_;
  }

  // TODO: Refact this mapping to not duplicate inspections
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

  // TODO: Remove not reutilized modifiers and use require direct in the function
  /**
   * @dev Allows the current user (producer) request a inspection.
   */
  function requestInspection() public requireProducer requireNoInspectionsOpen {
    require(canRequestInspection(), "Recent inspection");

    newRequest();

    // TODO: create a function to realize actions above in a single transaction?
    producerContract.recentInspection(msg.sender, true);
    producerContract.lastRequestAt(msg.sender, block.number);
  }

  // TODO: use default address as the acceptedBy address
  function newRequest() internal {
    // TODO: create instance before, so add just the required fields
    Inspection memory inspection = Inspection(
      inspectionsCount + 1,
      InspectionStatus.OPEN,
      msg.sender,
      msg.sender,
      0,
      block.number,
      block.timestamp,
      0,
      0,
      0
    );
    inspections[inspection.id] = inspection;
    inspectionsCount++;
  }

  // TODO: Remove not reutilized modifiers and use require direct in the function
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

    require(canAcceptInspection(), "Can't accept yet");
    require(inspection.status == InspectionStatus.OPEN, "This inspection is not OPEN");

    inspection.status = InspectionStatus.ACCEPTED;
    inspection.acceptedAt = block.number;
    inspection.acceptedAtTimestamp = block.timestamp; // solhint-disable-line
    inspection.acceptedBy = msg.sender;
    inspections[inspectionId] = inspection;

    producerContract.recentInspection(inspection.createdBy, false); // Talvez não precise, pois estamos usando a expiração da inspeção pra checar se o produtor pode solicitar uma nova inspeção
    activistContract.incrementGiveUps(msg.sender);

    activistContract.lastAcceptedAt(msg.sender, block.number);

    // TODO: Remove return?
    return true;
  }

  // TODO: Remove not reutilized modifiers and use require direct in the function
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
  {
    Inspection memory inspection = inspections[inspectionId];

    require(!expiredInspection(inspectionId), "Inspection Expired");

    markAsRealized(inspection, _isas);

    afterRealizeInspection(inspection);

    producerContract.setIsaScore(inspection.createdBy, inspection.isaScore);

    activistInspected[msg.sender][inspection.createdBy] = true;
  }

  function markAsRealized(Inspection memory inspection, IsaInspection[] memory _isas)
    internal
  {
    inspection.status = InspectionStatus.INSPECTED;
    inspection.inspectedAtTimestamp = block.timestamp; // solhint-disable-line
    inspection.isaScore = calculateIsa(inspection, _isas);
    inspections[inspection.id] = inspection;
  }

  function calculateIsa(Inspection memory inspection, IsaInspection[] memory _isas)
    internal
    returns (int256)
  {
    // TODO: Add isaScore points in state
    int256[5] memory points = [int256(10), 5, 0, -5, -10];
    int256 isaScore;

    for (uint8 i = 0; i < _isas.length; i++) {
      isas[inspection.id].push(_isas[i]);
      uint256 isaIndex = _isas[i].isaIndex;
      isaScore += points[isaIndex];
    }

    return isaScore;
  }

  // TODO: Refact this function
  /**
   * @dev Inscrement producer and activist request actions
   * @param inspection the inspected inspection
   */
  function afterRealizeInspection(Inspection memory inspection) internal {
    address createdBy = inspection.createdBy;
    address acceptedBy = inspection.acceptedBy;

    // Increment actvist inspections and release to carry out new inspections
    activistContract.incrementRequests(acceptedBy);
    activistContract.decreaseGiveUps(acceptedBy);

    // Increment producer requests
    producerContract.incrementInspections(createdBy);

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

  // TODO: Have a better way to return this?
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
   * @dev Check if an inspection exists in mapping.
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

  // TODO: Refact this action
  function canRequestInspection() public view returns (bool) {
    Producer memory producer = producerContract.getProducer(msg.sender);

    uint256 lastRequestAt = producer.lastRequestAt;
    bool canRequest = block.number > lastRequestAt + timeBetweenInspections;

    return canRequest || lastRequestAt == 0;
  }

  function expiredInspection(uint256 inspectionId) internal view returns (bool) {
    Inspection memory inspection = inspections[inspectionId];
    uint256 expireInspectionAt = inspection.acceptedAt + blocksToExpireAcceptedInspection;

    return block.number > expireInspectionAt;
  }

  function calculateBlocksToExpire(uint256 inspectionId) public view returns (uint256) {
    Inspection memory inspection = inspections[inspectionId];

    return inspection.acceptedAt + blocksToExpireAcceptedInspection - block.number;
  }

  function canAcceptInspection() internal view returns (bool) {
    Activist memory activist = activistContract.getActivist(msg.sender);
    uint256 lastAcceptedAt = activist.lastAcceptedAt;

    bool canAccept = block.number > lastAcceptedAt + blocksToExpireAcceptedInspection;

    return canAccept || lastAcceptedAt == 0;
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
    require(
      !producerContract.getProducer(msg.sender).recentInspection,
      "Request OPEN or ACCEPTED"
    );
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
  uint256 createdAtTimestamp;
  uint256 acceptedAt;
  uint256 acceptedAtTimestamp;
  uint256 inspectedAtTimestamp;
}

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