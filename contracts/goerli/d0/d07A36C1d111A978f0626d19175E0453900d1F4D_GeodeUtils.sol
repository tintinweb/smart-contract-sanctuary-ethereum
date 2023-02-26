// SPDX-License-Identifier: MIT

pragma solidity =0.8.7;

/**
 * @author Icebear & Crash Bandicoot
 * @title Isolated Storage Layout
 * A Storage Management Library for Dynamic Structs
 *
 * * DataStoreUtils is a storage management tool designed to create a safe and scalable
 * * storage layout with the help of data types, IDs and keys.
 *
 * * Focusing on upgradable contracts with multiple user types to create a
 * * sustainable development environment.
 * * In summary, extra gas cost that would be saved with Storage packing are
 * * ignored to create upgradable structs.
 *
 * @dev Distinct id and key pairs SHOULD return different storage slots
 * @dev TYPEs are defined in globals.sol
 *
 * @dev IDs are the representation of an entity with any given key as properties.
 * @dev While it is good practice to keep record,
 * * TYPE for ID is NOT mandatory, an ID might not have an explicit type.
 * * Thus there is no checks of types or keys.
 */

library DataStoreUtils {
  /**
   * @notice Main Struct for reading and writing operations for given (id, key) pairs
   * @param allIdsByType type => id[], optional categorization for IDs, requires direct access
   * @param uintData keccak(id, key) =>  returns uint256
   * @param bytesData keccak(id, key) => returns bytes
   * @param addressData keccak(id, key) =>  returns address
   * @param __gap keep the struct size at 16
   * @dev any other storage type can be expressed as uint or bytes
   */
  struct IsolatedStorage {
    mapping(uint256 => uint256[]) allIdsByType;
    mapping(bytes32 => uint256) uintData;
    mapping(bytes32 => bytes) bytesData;
    mapping(bytes32 => address) addressData;
    uint256[12] __gap;
  }

  /**
   *                              ** HELPERS **
   **/

  /**
   * @notice generaliazed method of generating an ID
   * @dev Some TYPEs may require permissionless creation. Allowing anyone to claim any ID,
   * meaning malicious actors can claim names to mislead people. To prevent this
   * TYPEs will be considered during ID generation.
   */
  function generateId(
    bytes memory _name,
    uint256 _type
  ) internal pure returns (uint256 id) {
    id = uint256(keccak256(abi.encodePacked(_name, _type)));
  }

  /**
   * @notice hashes given id and a parameter to be used as key in getters and setters
   * @return key bytes32 hash of id and parameter to be stored
   **/
  function getKey(
    uint256 id,
    bytes32 param
  ) internal pure returns (bytes32 key) {
    key = keccak256(abi.encodePacked(id, param));
  }

  /**
   *                              ** DATA GETTERS **
   **/

  function readUintForId(
    IsolatedStorage storage self,
    uint256 _id,
    bytes32 _key
  ) internal view returns (uint256 data) {
    data = self.uintData[getKey(_id, _key)];
  }

  function readBytesForId(
    IsolatedStorage storage self,
    uint256 _id,
    bytes32 _key
  ) internal view returns (bytes memory data) {
    data = self.bytesData[getKey(_id, _key)];
  }

  function readAddressForId(
    IsolatedStorage storage self,
    uint256 _id,
    bytes32 _key
  ) internal view returns (address data) {
    data = self.addressData[getKey(_id, _key)];
  }

  /**
   *                              ** ARRAY GETTERS **
   **/

  function readUintArrayForId(
    IsolatedStorage storage self,
    uint256 _id,
    bytes32 _key,
    uint256 _index
  ) internal view returns (uint256 data) {
    data = self.uintData[getKey(_index, getKey(_id, _key))];
  }

  function readBytesArrayForId(
    IsolatedStorage storage self,
    uint256 _id,
    bytes32 _key,
    uint256 _index
  ) internal view returns (bytes memory data) {
    data = self.bytesData[getKey(_index, getKey(_id, _key))];
  }

  function readAddressArrayForId(
    IsolatedStorage storage self,
    uint256 _id,
    bytes32 _key,
    uint256 _index
  ) internal view returns (address data) {
    data = self.addressData[getKey(_index, getKey(_id, _key))];
  }

  /**
   *                              ** DATA SETTERS **
   **/

  function writeUintForId(
    IsolatedStorage storage self,
    uint256 _id,
    bytes32 _key,
    uint256 _data
  ) internal {
    self.uintData[getKey(_id, _key)] = _data;
  }

  function addUintForId(
    IsolatedStorage storage self,
    uint256 _id,
    bytes32 _key,
    uint256 _addend
  ) internal {
    self.uintData[getKey(_id, _key)] += _addend;
  }

  function subUintForId(
    IsolatedStorage storage self,
    uint256 _id,
    bytes32 _key,
    uint256 _minuend
  ) internal {
    self.uintData[getKey(_id, _key)] -= _minuend;
  }

  function writeBytesForId(
    IsolatedStorage storage self,
    uint256 _id,
    bytes32 _key,
    bytes memory _data
  ) internal {
    self.bytesData[getKey(_id, _key)] = _data;
  }

  function writeAddressForId(
    IsolatedStorage storage self,
    uint256 _id,
    bytes32 _key,
    address _data
  ) internal {
    self.addressData[getKey(_id, _key)] = _data;
  }

  /**
   *                              ** ARRAY SETTERS **
   **/

  function appendUintArrayForId(
    IsolatedStorage storage self,
    uint256 _id,
    bytes32 _key,
    uint256 _data
  ) internal {
    bytes32 arrayKey = getKey(_id, _key);
    self.uintData[getKey(self.uintData[arrayKey]++, arrayKey)] = _data;
  }

  function appendBytesArrayForId(
    IsolatedStorage storage self,
    uint256 _id,
    bytes32 _key,
    bytes memory _data
  ) internal {
    bytes32 arrayKey = getKey(_id, _key);
    self.bytesData[getKey(self.uintData[arrayKey]++, arrayKey)] = _data;
  }

  function appendAddressArrayForId(
    IsolatedStorage storage self,
    uint256 _id,
    bytes32 _key,
    address _data
  ) internal {
    bytes32 arrayKey = getKey(_id, _key);
    self.addressData[getKey(self.uintData[arrayKey]++, arrayKey)] = _data;
  }

  /**
   *                              ** BATCH ARRAY SETTERS **
   **/

  function appendUintArrayForIdBatch(
    IsolatedStorage storage self,
    uint256 _id,
    bytes32 _key,
    uint256[] memory _data
  ) internal {
    bytes32 arrayKey = getKey(_id, _key);
    uint256 arrayLen = self.uintData[arrayKey];
    for (uint256 i; i < _data.length; ) {
      self.uintData[getKey(arrayLen++, arrayKey)] = _data[i];
      unchecked {
        i += 1;
      }
    }
    self.uintData[arrayKey] = arrayLen;
  }

  function appendBytesArrayForIdBatch(
    IsolatedStorage storage self,
    uint256 _id,
    bytes32 _key,
    bytes[] memory _data
  ) internal {
    bytes32 arrayKey = getKey(_id, _key);
    uint256 arrayLen = self.uintData[arrayKey];
    for (uint256 i; i < _data.length; ) {
      self.bytesData[getKey(arrayLen++, arrayKey)] = _data[i];
      unchecked {
        i += 1;
      }
    }
    self.uintData[arrayKey] = arrayLen;
  }

  function appendAddressArrayForIdBatch(
    IsolatedStorage storage self,
    uint256 _id,
    bytes32 _key,
    address[] memory _data
  ) internal {
    bytes32 arrayKey = getKey(_id, _key);
    uint256 arrayLen = self.uintData[arrayKey];
    for (uint256 i; i < _data.length; ) {
      self.addressData[getKey(arrayLen++, arrayKey)] = _data[i];
      unchecked {
        i += 1;
      }
    }
    self.uintData[arrayKey] = arrayLen;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

import {ID_TYPE, PERCENTAGE_DENOMINATOR} from "./globals.sol";
import {DataStoreUtils as DSU} from "./DataStoreUtilsLib.sol";

/**
 * @author Icebear & Crash Bandicoot
 * @title Geode Dual Governance
 * @notice Exclusively contains functions for the administration of the Isolated Storage,
 * and Limited Upgradability with Dual Governance of Governance and Senate
 * Note This library contains both functions called by users(ID) (approveSenate) and admins(GOVERNANCE, SENATE)
 *
 * @dev Reserved ID_TYPEs:
 *
 * * Type 0 : NULL
 *
 * * Type 1 : SENATE ELECTIONS
 * * * Every SENATE has an expiration date, a new one should be elected before it ends.
 * * * Only the controllers of IDs with TYPEs that are set true on _electorTypes can vote.
 * * * 2/3 is the expected concensus, however this logic seems to be improved in the future.
 *
 * * Type 2 : CONTRACT UPGRADES
 * * * Provides Limited Upgradability on Portal and Withdrawal Contract
 * * * Contract can be upgradable once Senate approves it.
 *
 * * Type 3 : __GAP__
 * * * ormally represented the admin contract, but we use UUPS. Reserved to be never used.
 *
 * @dev Contracts relying on this library must initialize GeodeUtils.DualGovernance
 * @dev Functions are already protected accordingly
 *
 * @dev review DataStoreUtils
 */
library GeodeUtils {
  /// @notice Using DataStoreUtils for IsolatedStorage struct
  using DSU for DSU.IsolatedStorage;

  /// @notice EVENTS
  event GovernanceFeeUpdated(uint256 newFee);
  event ControllerChanged(uint256 indexed id, address newCONTROLLER);
  event Proposed(
    uint256 id,
    address CONTROLLER,
    uint256 indexed TYPE,
    uint256 deadline
  );
  event ProposalApproved(uint256 id);
  event ElectorTypeSet(uint256 TYPE, bool isElector);
  event Vote(uint256 indexed proposalId, uint256 indexed voterId);
  event NewSenate(address senate, uint256 senateExpiry);

  /**
   * @notice Proposals give the control of a specific ID to a CONTROLLER
   *
   * @notice A Proposal has 4 specs:
   * @param TYPE: refer to globals.sol
   * @param CONTROLLER: the address that refers to the change that is proposed by given proposal.
   * * This slot can refer to the controller of an id, a new implementation contract, a new Senate etc.
   * @param NAME: DataStore generates ID by keccak(name, type)
   * @param deadline: refers to last timestamp until a proposal expires, limited by MAX_PROPOSAL_DURATION
   * * Expired proposals can not be approved by Senate
   * * Expired proposals can not be overriden by new proposals
   **/
  struct Proposal {
    address CONTROLLER;
    uint256 TYPE;
    bytes NAME;
    uint256 deadline;
  }

  /**
   * @notice DualGovernance allows 2 parties to manage a contract with proposals and approvals
   * @param GOVERNANCE a community that works to improve the core product and ensures its adoption in the DeFi ecosystem
   * Suggests updates, such as new operators, contract upgrades, a new Senate -without any permission to force them-
   * @param SENATE An address that protects the users by controlling the state of governance, contract updates and other crucial changes
   * Note SENATE is proposed by Governance and voted by all elector TYPEs, approved if ⌊2/3⌋ votes.
   * @param SENATE_EXPIRY refers to the last timestamp that SENATE can continue operating. Enforces a new election, limited by MAX_SENATE_PERIOD
   * @param GOVERNANCE_FEE operation fee on the given contract, acquired by GOVERNANCE. Limited by MAX_GOVERNANCE_FEE
   * @param approvedVersion only 1 implementation contract SHOULD be "approved" at any given time.
   * * @dev safe to set to address(0) after every upgrade as isUpgradeAllowed returns false for address(0)
   * @param _electorCount increased when a new id is added with _electorTypes[id] == true
   * @param _electorTypes only given TYPEs can vote
   * @param _proposals till approved, proposals are kept separated from the Isolated Storage
   * @param __gap keep the struct size at 16
   **/
  struct DualGovernance {
    address GOVERNANCE;
    address SENATE;
    uint256 SENATE_EXPIRY;
    uint256 GOVERNANCE_FEE;
    address approvedVersion;
    uint256 _electorCount;
    mapping(uint256 => bool) _electorTypes;
    mapping(uint256 => Proposal) _proposals;
    uint256[8] __gap;
  }

  /**
   * @notice limiting the GOVERNANCE_FEE, 5%
   */
  uint256 public constant MAX_GOVERNANCE_FEE =
    (PERCENTAGE_DENOMINATOR * 5) / 100;

  /**
   * @notice prevents Governance from collecting any fees till given timestamp:
   * @notice April 2025
   * @dev fee switch will be automatically switched on after given timestamp
   * @dev fee switch can be switched on with the approval of Senate (a contract upgrade)
   */
  uint256 public constant FEE_COOLDOWN = 1743454800;

  uint32 public constant MIN_PROPOSAL_DURATION = 1 days;
  uint32 public constant MAX_PROPOSAL_DURATION = 4 weeks;
  uint32 public constant MAX_SENATE_PERIOD = 365 days;

  modifier onlySenate(DualGovernance storage self) {
    require(msg.sender == self.SENATE, "GU: SENATE role needed");
    require(block.timestamp < self.SENATE_EXPIRY, "GU: SENATE expired");
    _;
  }

  modifier onlyGovernance(DualGovernance storage self) {
    require(msg.sender == self.GOVERNANCE, "GU: GOVERNANCE role needed");
    _;
  }

  modifier onlyController(DSU.IsolatedStorage storage DATASTORE, uint256 id) {
    require(
      msg.sender == DATASTORE.readAddressForId(id, "CONTROLLER"),
      "GU: CONTROLLER role needed"
    );
    _;
  }

  /**
   * @notice                                     ** DualGovernance **
   **/

  /**
   * @dev  ->  view
   */

  /**
   * @return address of SENATE
   **/
  function getSenate(
    DualGovernance storage self
  ) external view returns (address) {
    return self.SENATE;
  }

  /**
   * @return address of GOVERNANCE
   **/
  function getGovernance(
    DualGovernance storage self
  ) external view returns (address) {
    return self.GOVERNANCE;
  }

  /**
   * @return the expiration date of current SENATE as a timestamp
   */
  function getSenateExpiry(
    DualGovernance storage self
  ) external view returns (uint256) {
    return self.SENATE_EXPIRY;
  }

  /**
   * @notice active GOVERNANCE_FEE limited by FEE_COOLDOWN and MAX_GOVERNANCE_FEE
   * @dev MAX_GOVERNANCE_FEE MUST limit GOVERNANCE_FEE even if MAX is changed later
   * @dev MUST return 0 until cooldown period is active
   */
  function getGovernanceFee(
    DualGovernance storage self
  ) external view returns (uint256) {
    return
      block.timestamp < FEE_COOLDOWN
        ? 0
        : MAX_GOVERNANCE_FEE > self.GOVERNANCE_FEE
        ? self.GOVERNANCE_FEE
        : MAX_GOVERNANCE_FEE;
  }

  /**
   * @dev  ->  external
   */

  /**
   * @notice onlyGovernance, sets the governance fee
   * @dev Can not set the fee more than MAX_GOVERNANCE_FEE
   */
  function setGovernanceFee(
    DualGovernance storage self,
    uint256 newFee
  ) external onlyGovernance(self) {
    require(newFee <= MAX_GOVERNANCE_FEE, "GU: > MAX_GOVERNANCE_FEE");

    self.GOVERNANCE_FEE = newFee;

    emit GovernanceFeeUpdated(newFee);
  }

  /**
   * @notice                                     ** ID **
   */

  /**
   * @dev  ->  external
   */

  /**
   * @notice onlyController, change the CONTROLLER of an ID
   * @dev this operation can not be reverted by the old CONTROLLER !
   * @dev can not provide address(0), try 0x000000000000000000000000000000000000dEaD
   */
  function changeIdCONTROLLER(
    DSU.IsolatedStorage storage DATASTORE,
    uint256 id,
    address newCONTROLLER
  ) external onlyController(DATASTORE, id) {
    require(newCONTROLLER != address(0), "GU: CONTROLLER can not be zero");

    DATASTORE.writeAddressForId(id, "CONTROLLER", newCONTROLLER);

    emit ControllerChanged(id, newCONTROLLER);
  }

  /**
   * @notice                                     ** PROPOSALS **
   */

  /**
   * @dev  ->  view
   */

  /**
   * @dev refer to Proposal struct
   */
  function getProposal(
    DualGovernance storage self,
    uint256 id
  ) external view returns (Proposal memory) {
    return self._proposals[id];
  }

  /**
   * @dev  ->  external
   */

  /**
   * @notice onlyGovernance, creates a new Proposal
   * @dev DATASTORE[id] will not be updated until the proposal is approved
   * @dev Proposals can NEVER be overriden
   * @dev refer to Proposal struct
   */
  function newProposal(
    DualGovernance storage self,
    DSU.IsolatedStorage storage DATASTORE,
    address _CONTROLLER,
    uint256 _TYPE,
    bytes calldata _NAME,
    uint256 duration
  ) external onlyGovernance(self) returns (uint256 id) {
    id = DSU.generateId(_NAME, _TYPE);

    require(self._proposals[id].deadline == 0, "GU: NAME already proposed");

    require(
      (DATASTORE.readBytesForId(id, "NAME")).length == 0,
      "GU: ID already exist"
    );

    require(_CONTROLLER != address(0), "GU: CONTROLLER can NOT be ZERO");
    require(
      _TYPE != ID_TYPE.NONE && _TYPE != ID_TYPE.__GAP__,
      "GU: TYPE is NONE or GAP"
    );
    require(
      duration >= MIN_PROPOSAL_DURATION && duration <= MAX_PROPOSAL_DURATION,
      "GU: invalid proposal duration"
    );

    uint256 _deadline = block.timestamp + duration;

    self._proposals[id] = Proposal({
      CONTROLLER: _CONTROLLER,
      TYPE: _TYPE,
      NAME: _NAME,
      deadline: _deadline
    });

    emit Proposed(id, _CONTROLLER, _TYPE, _deadline);
  }

  /**
   * @notice onlySenate, approves a proposal and records given data to
   *  @notice specific changes for the reserved types (1,2,3) are implemented here,
   *  any other addition should take place in Portal, as not related
   *  @param id given ID proposal that has been approved by Senate
   *  @dev Senate is not able to approve approved proposals
   *  @dev Senate is not able to approve expired proposals
   *  @dev Senate is not able to approve SENATE proposals
   */
  function approveProposal(
    DualGovernance storage self,
    DSU.IsolatedStorage storage DATASTORE,
    uint256 id
  ) external onlySenate(self) returns (uint256 _type, address _controller) {
    require(
      self._proposals[id].deadline > block.timestamp,
      "GU: NOT an active proposal"
    );

    _type = self._proposals[id].TYPE;
    _controller = self._proposals[id].CONTROLLER;

    require(_type != ID_TYPE.SENATE, "GU: can NOT approve SENATE election");

    DATASTORE.writeUintForId(id, "TYPE", _type);
    DATASTORE.writeAddressForId(id, "CONTROLLER", _controller);
    DATASTORE.writeBytesForId(id, "NAME", self._proposals[id].NAME);
    DATASTORE.allIdsByType[_type].push(id);

    if (_type == ID_TYPE.CONTRACT_UPGRADE) {
      self.approvedVersion = _controller;
    }

    if (isElector(self, _type)) {
      self._electorCount += 1;
    }

    // important
    self._proposals[id].deadline = block.timestamp;

    emit ProposalApproved(id);
  }

  /**
   * @notice                                       ** SENATE ELECTIONS **
   */

  /**
   * @dev  ->  view
   */

  function isElector(
    DualGovernance storage self,
    uint256 _TYPE
  ) public view returns (bool) {
    return self._electorTypes[_TYPE];
  }

  /**
   * @dev  ->  internal
   */

  /**
   * @notice internal function to set a new senate with a given period
   */
  function _setSenate(
    DualGovernance storage self,
    address _newSenate,
    uint256 _expiry
  ) internal {
    self.SENATE = _newSenate;
    self.SENATE_EXPIRY = _expiry;

    emit NewSenate(self.SENATE, self.SENATE_EXPIRY);
  }

  /**
   * @dev  ->  external
   */

  /**
   * @notice onlySenate, Sometimes it is useful to be able to change the Senate's address.
   * @dev does not change the expiry
   */
  function changeSenate(
    DualGovernance storage self,
    address _newSenate
  ) external onlySenate(self) {
    _setSenate(self, _newSenate, self.SENATE_EXPIRY);
  }

  /**
   * @notice onlyGovernance, only elector types can vote for senate
   * @param _TYPE selected type
   * @param _isElector true if selected _type can vote for senate from now on
   * @dev can not set with the same value again, preventing double increment/decrements
   */
  function setElectorType(
    DualGovernance storage self,
    DSU.IsolatedStorage storage DATASTORE,
    uint256 _TYPE,
    bool _isElector
  ) external onlyGovernance(self) {
    require(_isElector != isElector(self, _TYPE), "GU: type already elector");
    require(
      _TYPE > ID_TYPE.__GAP__,
      "GU: 0, Senate, Upgrade, GAP cannot be elector"
    );

    self._electorTypes[_TYPE] = _isElector;

    if (_isElector) {
      self._electorCount += DATASTORE.allIdsByType[_TYPE].length;
    } else {
      self._electorCount -= DATASTORE.allIdsByType[_TYPE].length;
    }

    emit ElectorTypeSet(_TYPE, _isElector);
  }

  /**
   * @notice onlyController, Proposed CONTROLLER is the new Senate after 2/3 of the electors approved
   * NOTE mathematically, min 3 elector is needed for (c+1)*2/3 to work properly
   * @notice id can not vote if:
   * - approved already
   * - proposal is expired
   * - not its type is elector
   * - not senate proposal
   * @param voterId should have the voting rights, msg.sender should be the CONTROLLER of given ID
   * @dev pins id as "voted" when approved
   * @dev increases "approvalCount" of proposalId by 1 when approved
   */
  function approveSenate(
    DualGovernance storage self,
    DSU.IsolatedStorage storage DATASTORE,
    uint256 proposalId,
    uint256 voterId
  ) external onlyController(DATASTORE, voterId) {
    uint256 _type = self._proposals[proposalId].TYPE;
    require(_type == ID_TYPE.SENATE, "GU: NOT Senate Proposal");
    require(
      self._proposals[proposalId].deadline >= block.timestamp,
      "GU: proposal expired"
    );
    require(
      isElector(self, DATASTORE.readUintForId(voterId, "TYPE")),
      "GU: NOT an elector"
    );
    require(
      DATASTORE.readUintForId(proposalId, DSU.getKey(voterId, "voted")) == 0,
      " GU: already approved"
    );

    DATASTORE.writeUintForId(proposalId, DSU.getKey(voterId, "voted"), 1);
    DATASTORE.addUintForId(proposalId, "approvalCount", 1);

    if (
      DATASTORE.readUintForId(proposalId, "approvalCount") >=
      ((self._electorCount + 1) * 2) / 3
    ) {
      self._proposals[proposalId].deadline = block.timestamp;
      _setSenate(
        self,
        self._proposals[proposalId].CONTROLLER,
        block.timestamp + MAX_SENATE_PERIOD
      );
    }

    emit Vote(proposalId, voterId);
  }

  /**
   * @notice                                       ** LIMITED UPGRADABILITY **
   */

  /**
   * @dev  ->  view
   */

  /**
   * @notice Get if it is allowed to change a specific contract with the current version.
   * @return True if it is allowed by senate and false if not.
   * @dev address(0) should return false
   * @dev DO NOT TOUCH, EVER! WHATEVER YOU DEVELOP IN FUCKING 3022
   **/
  function isUpgradeAllowed(
    DualGovernance storage self,
    address proposedImplementation
  ) external view returns (bool) {
    return
      self.approvedVersion != address(0) &&
      self.approvedVersion == proposedImplementation;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

// PERCENTAGE_DENOMINATOR represents 100%
uint256 constant PERCENTAGE_DENOMINATOR = 10 ** 10;

/**
 * @notice ID_TYPE is like an ENUM, widely used within Portal and Modules like Withdrawal Contract
 * @dev Why not use enums, they basically do the same thing?
 * * We like using a explicit defined uints than linearly increasing ones.
 */
library ID_TYPE {
  /// @notice TYPE 0: *invalid*
  uint256 internal constant NONE = 0;

  /// @notice TYPE 1: Senate and Senate Election Proposals
  uint256 internal constant SENATE = 1;

  /// @notice TYPE 2: Contract Upgrade
  uint256 internal constant CONTRACT_UPGRADE = 2;

  /// @notice TYPE 3: *gap*: formally represented the admin contract, now reserved to be never used
  uint256 internal constant __GAP__ = 3;

  /// @notice TYPE 4: Node Operators
  uint256 internal constant OPERATOR = 4;

  /// @notice TYPE 5: Staking Pools
  uint256 internal constant POOL = 5;

  /// @notice TYPE 21: Module: Withdrawal Contract
  uint256 internal constant MODULE_WITHDRAWAL_CONTRACT = 21;

  /// @notice TYPE 31: Module: A new gETH interface
  uint256 internal constant MODULE_GETH_INTERFACE = 31;

  /// @notice TYPE 41: Module: A new Liquidity Pool
  uint256 internal constant MODULE_LIQUDITY_POOL = 41;

  /// @notice TYPE 42: Module: A new Liquidity Pool token
  uint256 internal constant MODULE_LIQUDITY_POOL_TOKEN = 42;
}

/**
 * @notice VALIDATOR_STATE keeping track of validators within The Staking Library
 */
library VALIDATOR_STATE {
  /// @notice STATE 0: *invalid*
  uint8 internal constant NONE = 0;

  /// @notice STATE 1: validator is proposed, 1 ETH is sent from Operator to Deposit Contract
  uint8 internal constant PROPOSED = 1;

  /// @notice STATE 2: proposal was approved, operator used pooled funds, 1 ETH is released back to Operator
  uint8 internal constant ACTIVE = 2;

  /// @notice STATE 3: validator is exited, not currently used much
  uint8 internal constant EXITED = 3;

  /// @notice STATE 69: proposal was malicious(alien), maybe faulty signatures or probably: (https://bit.ly/3Tkc6UC)
  uint8 internal constant ALIENATED = 69;
}