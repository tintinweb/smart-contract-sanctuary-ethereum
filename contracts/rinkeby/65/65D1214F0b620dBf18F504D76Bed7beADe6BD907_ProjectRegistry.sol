/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

//SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.13;
pragma abicoder v2;

/**
 * @title ProjectRegistry
 *
 * Create and store new Project instances onchain.
 * Gives users the ability to then upvote or downvote projects.
 */
contract ProjectRegistry {
  // -- Data Types --

  enum VoteChoice { Null, Up, Down }

  struct Project {
    address owner;
    string name;
    string subtitle;
    string imageUrl;
    string description;
    uint256 upvotes;
    uint256 downvotes;
  }

  struct ProjectMetadata {
    string name;
    string subtitle;
    string imageUrl;
    string description;
  }

  // -- State --
  
  /// @notice mapping of Project id's to the stored Project instance
  mapping(uint256 => Project) public projects;
  /// @notice the owner of the Project
  /// @dev project id => contributor address
  mapping(uint256 => address) public projectOwners;
  /// @notice the sequential id for the project owner
  /// @dev owner => sequential id
  mapping(address => uint256) public projectOwnerSeqIds;
  /// @notice mapping of voters on a project
  /// @dev project id => voter address => vote choice
  /// this prevents a user from voting multiple times on a project
  mapping(uint256 => mapping(address => VoteChoice)) public projectVotes;

  // -- Events --

  /**
   * @notice this event is emitted anytime the Project is updated.
   * @dev updates occur when: the Project is submitted, a value on the Project is updated, the Project is voted on.
   * @param projectId ID of the Project in storage onchain.
   * @param owner Address of the owner; the user who submitted the Project.
   * @param name Name of the Project.
   * @param subtitle Subtitle of the Project.
   * @param description Description of the Project.
   * @param imageUrl URL of the Project image.
   * @param upvotes The total Up votes on the Project.
   * @param downvotes The total Down votes on the Project.
   * @param voteCount The total Up and Down vote count.
   */
  event ProjectUpdated(
    uint256 indexed projectId,
    address indexed owner,
    string indexed name,
    string subtitle,
    string description,
    string imageUrl,
    uint256 upvotes,
    uint256 downvotes,
    uint256 voteCount
  );

  /**
   * @notice this event is emitted when a user votes on a Project.
   * @param projectId ID of the Project in storage onchain.
   * @param voter Address of the user who voted on the Project.
   * @param vote The submitted vote on the Project.
   */
  event VoteSubmitted(uint256 indexed projectId, address indexed voter, VoteChoice indexed vote);

  // -- Modifiers --

  /**
   * @notice check that the Project is valid to store on chain.
   * @dev in order to be valid, the Project name and imageUrl cannot be empty.
   * @param _name the submitted Project name
   * @param _imageUrl the submitted Project imageUrl
   */
  modifier canSubmitProject(string memory _name, string memory _imageUrl) {
    require(_stringNotEmpty(_name), "Must provide a project name");
    require(_stringNotEmpty(_imageUrl), "Must provide a project image url");
    _;
  }

  /**
   * @notice check that the submitted update Project metadata is valid and that the user can update the project.
   * @dev in order to be able to update the Project metadata:
   *  - the Project must exist
   *  - only the Project owner can update the Project metadata
   *  - the name cannot be empty
   *  - the imageUrl cannot be empty
   * @param _projectId ID of the Project that is having its metadata updated
   * @param _name The potentially updated name of the Project.
   * @param _imageUrl The potentially updated imageUrl of the Project.
   */
  modifier canUpdateProject(uint256 _projectId, string memory _name, string memory _imageUrl) {
    require(_projectExists(_projectId), "Cannot update a Project that does not exist");
    require(getProjectOwner(_projectId) == msg.sender, "Only the Project owner can update the Project");
    require(_stringNotEmpty(_name), "Must provide a project name");
    require(_stringNotEmpty(_imageUrl), "Must provide a project image url");
    _;
  }

  /**
   * @notice check that the user can vote on the Project.
   * @notice to be able to vote:
   *  - the Project must exist
   *  - the user must vote either Up or Down
   *  - the voter cannot have voted on the Project previously
   * @param _projectId the id of the Project the user is voting on
   * @param _vote the vote choice
   */
  modifier canVote(uint256 _projectId, VoteChoice _vote) {
    require(_projectExists(_projectId), "Cannot vote on Project that does not exist");
    require(_vote == VoteChoice.Up || _vote == VoteChoice.Down, "Vote must be either Up or Down");
    require(getProjectVote(_projectId, msg.sender) == VoteChoice.Null, "Can only vote once on a Project");
    _;
  }

  // -- Actions --

  /**
   * @notice Allows a user to submit a new Project with the given Project metadata.
   * @dev Must pass the canSubmitProject modifier, which requires that the:
   *  - _name is not an empty string
   *  - _imageUrl is not an empty string
   * Generates a new id for the owner of the Project - identified by the msg.sender.
   * Stores the Project data on chain.
   *
   * @custom:emits ProjectUpdated
   * @param _metadata The Project metadata, containing the Project info
   */
  function submitProject(ProjectMetadata calldata _metadata) public canSubmitProject(_metadata.name, _metadata.imageUrl) {
    address owner = msg.sender;
    uint256 projectId = _nextProjectId(owner);

    Project memory project = getProject(projectId);
    project.owner = owner;
    project.name = _metadata.name;
    project.subtitle = _metadata.subtitle;
    project.description = _metadata.description;
    project.imageUrl = _metadata.imageUrl;
    project.upvotes = 0;
    project.downvotes = 0;

    _setProject(projectId, project);
    _setProjectOwner(projectId, owner);
  }

  /**
   * @notice Allows the owner of an existing Project to update the Project metadata onchain.
   * @dev must pass the canUpdateProject modifier, which validates that:
   *  - the Project exists
   *  - the msg.sender attempting to update the Project, is the Project owner.
   *  - the potentially updated _name is not empty
   *  - the potentially updated _imageUrl is not empty
   * If valid, the Project is grabbed out of memory, updated, and then restored onchain.
   *
   * @custom:emits ProjectUpdated
   * @param _projectId ID of the Project whose metadata is being updated
   * @param _metadata The Project metadata, containing the Project info
   */
  function updateProjectMetadata(
    uint256 _projectId,
    ProjectMetadata calldata _metadata
  ) public canUpdateProject(_projectId, _metadata.name, _metadata.imageUrl) {
    Project memory project = getProject(_projectId);
    project.name = _metadata.name;
    project.subtitle = _metadata.subtitle;
    project.description = _metadata.description;
    project.imageUrl = _metadata.imageUrl;

    _setProject(_projectId, project);
  }

  /**
   * @notice Allows the user to submit a upvote/downvote on the Project.
   * @dev must pass the canVote modifier, which requires that:
   *  - the Project exists
   *  - the submitted VoteChoice is either VoteChoice.Up or VoteChoice.Down
   *  - the user has not already voted on the Project
   * Updates the vote count on the Project.
   * Stores the submitted vote for the user onchain.
   *
   * @custom:emits ProjectUpdated
   * @custom:emits VoteSubmitted
   * @param _projectId ID of the Project being voted on.
   * @param _vote The submitted VoteChoice.
   */
  function vote(uint256 _projectId, VoteChoice _vote) public canVote(_projectId, _vote) {
    Project memory project = getProject(_projectId);
    if (_vote == VoteChoice.Up) {
      project.upvotes = project.upvotes + 1;
    } else {
      project.downvotes = project.downvotes + 1;
    }

    _setProject(_projectId, project);
    _setProjectVote(_projectId, msg.sender, _vote);
  }

  // -- Helpers --

  /**
   * @notice compare two strings for equality.
   * @param _s1 left-side of the comparison.
   * @param _s2 right-side of the comparison.
   */
  function _compare(string memory _s1, string memory _s2) internal pure returns (bool) {
    return keccak256(abi.encodePacked(_s1)) == keccak256(abi.encodePacked(_s2));
  }

  /**
   * @notice check if the given string is empty
   * @param _value the string to check if it is empty
   * @return true if the string has a value, is not ""; otherwise false
   */
  function _stringNotEmpty(string memory _value) internal pure returns (bool) {
    return !_compare(_value, "");
  }

  /**
   * @notice check the project owners mapping to see if we have a project at the given id.
   * @param _projectId the id of the project to check if exists.
   */
  function _projectExists(uint256 _projectId) internal view returns (bool) {
    return getProjectOwner(_projectId) != address(0);
  }

  /**
   * @notice build a sequential id for the given actor.
   * @dev concats together the actor address and the sequential id, hashes the value, converts to a uint256
   * @param _actor address of the actor building an id
   * @param _seqId incrementing, sequential id for the actor
   * @return id the concatenated, hashed, sequential id for the actor
   */
  function _buildId(address _actor, uint256 _seqId) internal pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(_actor, _seqId)));
  }

  /**
   * @dev Return a new consecutive sequence ID for a Project owner and update to the next value.
   * NOTE: This function updates the sequence ID for the Project owner
   * @param _owner The address of the owner of the Project
   * @return seqId ID for the owner
   */
  function _nextProjectOwnerSeqId(address _owner) internal returns (uint256 seqId) {
    seqId = projectOwnerSeqIds[_owner];
    
    // increment and set back in state
    projectOwnerSeqIds[_owner] = seqId + 1;
    return seqId;
  }

  /**
   * @dev Generate the next Project id.
   * The built id is the keccak256 hash of the Project owner address and their next sequential id.
   * @param _owner The Project owner.
   * @return projectId keccak256 hashed id of the Project owner address and their next sequential id.
   */
  function _nextProjectId(address _owner) internal returns (uint256) {
    return _buildId(_owner, _nextProjectOwnerSeqId(_owner));
  }

  // -- Getters --

  /**
   * @notice retrieve the Project out of memory from the mapping by its id.
   * @dev if there is no Project with the id, it will return an empty Project.
   * @param _projectId ID of the Project in storage.
   * @return project either the found Project with the ID, or an empty Project.
   */
  function getProject(uint256 _projectId) public view returns (Project memory) {
    return projects[_projectId];
  }

  /**
   * @notice retrieve the Project vote for the voter address out of memory from the mapping by the Project ID and voter address.
   * @dev if the user has not voted on the Project, this value will be VoteChoice.Null; which is uint256(0).
   * @param _projectId ID of the voted on Project.
   * @param _voter Address of the voter
   * @return vote The VoteChoice of the voter on the project; VoteChoice.Null if the voter has not voted on the Project.
   */
  function getProjectVote(uint256 _projectId, address _voter) public view returns (VoteChoice) {
    return projectVotes[_projectId][_voter];
  }

  /**
   * @notice retrieve the address of the owner of the Project out of memory from the mapping of project owners to ID.
   * @dev If the Project does not exist at the ID, then this will return an address(0), or empty address.
   * @param _projectId ID of the Project.
   * @return owner Address of the owner of the Project. If no Project at the ID, then address(0).
   */
  function getProjectOwner(uint256 _projectId) public view returns (address) {
    return projectOwners[_projectId];
  }

  // -- Setters --

  /**
   * @notice store the Project data onchain in the projectId => Project mapping.
   * @param _projectId ID of the Project.
   * @param _data The Project data to store/update in the mappping/onchain.
   * @custom:emits ProjectUpdated
   */
  function _setProject(uint256 _projectId, Project memory _data) internal {
    projects[_projectId] = _data;

    emit ProjectUpdated(
      _projectId,
      _data.owner,
      _data.name,
      _data.subtitle,
      _data.description,
      _data.imageUrl,
      _data.upvotes,
      _data.downvotes,
      _data.upvotes + _data.downvotes
    );
  }

  /**
   * @notice store the owner of a Project onchain in the projectId => address mapping.
   * @param _projectId ID of the Project.
   * @param _owner Address of the owner of the Project.
   */
  function _setProjectOwner(uint256 _projectId, address _owner) internal {
    projectOwners[_projectId] = _owner;
  }
  
  /**
   * @notice store the voters VoteChoice for the given Project onchain in the projectId => address => VoteChoice mapping.
   * @param _projectId ID of the Project that was voted on.
   * @param _voter Address of the voter on the Project.
   * @param _vote The voters VoteChoice on the project.
   * @custom:emits VoteSubmitted
   */
  function _setProjectVote(uint256 _projectId, address _voter, VoteChoice _vote) internal {
    projectVotes[_projectId][_voter] = _vote;

    emit VoteSubmitted(_projectId, _voter, _vote);
  }
}