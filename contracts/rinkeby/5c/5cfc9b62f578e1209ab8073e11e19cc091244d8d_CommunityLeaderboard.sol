/**
 *Submitted for verification at Etherscan.io on 2022-05-04
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


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

// File: contracts/LeaderboardContract_flat.sol



pragma solidity ^0.8.0;




// Interface for checking the address that owns an ERC721
interface IERC721 {
  function owner() external returns (address owner);

  function ownerOf(uint256 tokenId) external returns (address owner);
}

contract CommunityLeaderboard is Ownable, Pausable {
  using SafeMath for uint256;

  uint256 public maxLeaderboardsPerProject = 50;

  event projectRegistser(
    bytes32 projectHashId,
    uint256 projectId,
    address indexed from,
    address indexed nftContract,
    string name,
    uint256 numberOfLeaderboards
  );

  event projectOwnerAdd(uint256 _projectId, address indexed _newOwner);

  event createNftRequiredLeaderboard(
    bytes32 leaderboardHashId,
    address indexed creator,
    string leaderboardName,
    uint256 projectId,
    uint256 leaderBoardId,
    uint256 leaderboardCount,
    uint256 epoch,
    bool nftRequired,
    uint256 nftsRequired
  );

  event voteCast(
    bytes32 voteHashId,
    uint256 projectId,
    uint256 leaderboardId,
    address indexed member,
    uint256 nftTokenId,
    address indexed voter
  );

  event voteChange(
    bytes32 changeVoteHashId,
    uint256 projectId,
    uint256 leaderboardId,
    address indexed member,
    address indexed newMember
  );

  struct Project {
    mapping(address => bool) owners;
    address nftContract;
    string name;
    uint256 projectId;
    uint256 numberOfLeaderboards;
  }

  struct MemberRow {
    uint256 numberOfVotes;
    address[] voters; // may have 0x addresses, which indicates a changed/deleted vote
    mapping(address => uint256) addressToIndex;
    // mapping(address => bool) voterToHasVoted;
  }

  struct Leaderboard {
    string name;
    uint256 projectId;
    uint256 leaderBoardId;
    uint256 leaderboardCount; // How many leaderboard epochs have passed
    uint256 epoch; // Days?
    bool nftRequired;
    uint256 numberOfNftsRequired;
  }

  struct LeaderboardInstance {
    uint256 leaderBoardId;
    uint256 leaderboardIndex;
    uint256 blockStart;
    uint256 blockEnd;
    address[] members; // Addresses that have received votes (used to iterate), make sure to not have duplicates
    address[] voters;
    mapping(address => MemberRow) rows;
    mapping(address => bool) voterToHasVoted;
  }

  uint256 public projectCount = 0;
  uint256[] public projectIds;
  mapping(uint256 => Project) public projectIdToProject;
  // mapping(uint256 => Leaderboard[]) public projectIdToLeaderboards;
  mapping(uint256 => mapping(uint256 => Leaderboard)) public leaderboardIndex;
  mapping(uint256 => mapping(uint256 => mapping(uint256 => LeaderboardInstance)))
    public leaderboardInstances;

  // mapping(uint256 => mapping(uint256 => mapping(uint256 => Leaderboard)))
  //   public leaderboardArchive;

  function getLeaderboard(uint256 _projectId, uint256 _leaderboardId)
    external
    view
    returns (
      string memory,
      uint256,
      uint256,
      uint256,
      uint256,
      bool,
      uint256
    )
  {
    Leaderboard storage leaderboard = leaderboardIndex[_projectId][
      _leaderboardId
    ];
    return (
      leaderboard.name,
      leaderboard.projectId,
      leaderboard.leaderBoardId,
      leaderboard.leaderboardCount,
      leaderboard.epoch,
      leaderboard.nftRequired,
      leaderboard.numberOfNftsRequired
    );
  }

  function getProjectName(uint256 _projectId)
    external
    view
    returns (string memory)
  {
    return projectIdToProject[_projectId].name;
  }

  function getProjectLeaderboardCount(uint256 _projectId)
    external
    view
    returns (uint256)
  {
    return projectIdToProject[_projectId].numberOfLeaderboards;
  }

  function getLeaderboardName(uint256 _projectId, uint256 _leaderboardId)
    external
    view
    returns (string memory)
  {
    return leaderboardIndex[_projectId][_leaderboardId].name;
  }

  function getLeaderboardMemberLength(
    uint256 _projectId,
    uint256 _leaderboardId
  ) external view returns (uint256) {
    return
      leaderboardInstances[_projectId][_leaderboardId][
        leaderboardIndex[_projectId][_leaderboardId].leaderboardCount
      ].members.length;
  }

  function getLeaderboardMemberAddress(
    uint256 _projectId,
    uint256 _leaderboardId,
    uint256 _memberId
  ) external view returns (address) {
    return
      leaderboardInstances[_projectId][_leaderboardId][
        leaderboardIndex[_projectId][_leaderboardId].leaderboardCount
      ].members[_memberId];
  }

  function getLeaderboardMemberVoteCount(
    uint256 _projectId,
    uint256 _leaderboardId,
    uint256 _memberId
  ) external view returns (uint256) {
    return
      leaderboardInstances[_projectId][_leaderboardId][
        leaderboardIndex[_projectId][_leaderboardId].leaderboardCount
      ]
        .rows[
          leaderboardInstances[_projectId][_leaderboardId][
            leaderboardIndex[_projectId][_leaderboardId].leaderboardCount
          ].members[_memberId]
        ]
        .numberOfVotes;
  }

  function getLeaderboardArchivedMemberVoteCount(
    uint256 _projectId,
    uint256 _leaderboardId,
    address _member,
    uint256 _leaderboardArchiveId
  ) external view returns (uint256) {
    return
      leaderboardInstances[_projectId][_leaderboardId][_leaderboardArchiveId]
        .rows[_member]
        .numberOfVotes;
  }

  function getLeaderboardMemberVoteCount2(
    uint256 _projectId,
    uint256 _leaderboardId,
    address _member
  ) external view returns (uint256) {
    return
      leaderboardInstances[_projectId][_leaderboardId][
        leaderboardIndex[_projectId][_leaderboardId].leaderboardCount
      ].rows[_member].numberOfVotes;
  }

  // function getArchiveLeaderboardMemberVoteCount(
  //   uint256 _projectId,
  //   uint256 _leaderboardId,
  //   uint256 _archiveId,
  //   address _member
  // ) external view returns (uint256) {
  //   return
  //     leaderboardArchive[_projectId][_leaderboardId][_archiveId]
  //       .rows[_member]
  //       .numberOfVotes;
  // }

  function registerProject(address _nftContract, string memory _name)
    public
    whenNotPaused
  {
    // Verify that the person calling function is owner of NFT contract
    address nftContractOwner = IERC721(_nftContract).owner(); // REMOVE FOR TESTING
    require(nftContractOwner == msg.sender, "You do not own this NFT contract."); // REMOVE FOR TESTING

    // Create new project and add it to mapping
    Project storage newProject = projectIdToProject[projectCount];
    newProject.owners[msg.sender] = true;
    newProject.nftContract = _nftContract;
    newProject.name = _name;
    newProject.projectId = projectCount;
    newProject.numberOfLeaderboards = 0;

    projectCount = projectCount.add(1);

    bytes32 projectHashId = keccak256(
      abi.encodePacked(_nftContract, newProject.projectId)
    );

    emit projectRegistser(
      projectHashId,
      newProject.projectId,
      msg.sender,
      _nftContract,
      _name,
      newProject.numberOfLeaderboards
    );
  }

  function addOwnerToProject(uint256 _projectId, address _newOwner)
    public
    whenNotPaused
  {
    require(
      projectIdToProject[_projectId].owners[msg.sender] == true,
      "You are not an owner of this project."
    );
    projectIdToProject[_projectId].owners[_newOwner] = true;

    emit projectOwnerAdd(_projectId, _newOwner);
  }

  function createLeaderboardNftRequired(
    uint256 _projectId,
    string memory _leaderboardName,
    uint256 _time,
    uint256 _nftsRequired
  ) public whenNotPaused {
    require(
      projectIdToProject[_projectId].owners[msg.sender] == true,
      "You are not an owner of this project."
    );
    require(
      projectIdToProject[_projectId].numberOfLeaderboards <
        maxLeaderboardsPerProject,
      "Have reached max amount of leaderboards allowed in this project."
    );

    Leaderboard storage newLeaderboard = leaderboardIndex[_projectId][
      projectIdToProject[_projectId].numberOfLeaderboards
    ];
    newLeaderboard.name = _leaderboardName;
    newLeaderboard.projectId = _projectId;
    newLeaderboard.leaderBoardId = projectIdToProject[_projectId]
      .numberOfLeaderboards;
    newLeaderboard.leaderboardCount = 1;
    newLeaderboard.epoch = _time;
    newLeaderboard.nftRequired = true;
    newLeaderboard.numberOfNftsRequired = _nftsRequired;

    LeaderboardInstance storage leaderboardInstance = leaderboardInstances[
      _projectId
    ][projectIdToProject[_projectId].numberOfLeaderboards][1];
    leaderboardInstance.leaderboardIndex = 1;
    leaderboardInstance.blockStart = block.number;
    leaderboardInstance.blockEnd = block.number + _time;

    projectIdToProject[_projectId].numberOfLeaderboards = projectIdToProject[
      _projectId
    ].numberOfLeaderboards.add(1);

    bytes32 leaderboardHashId = keccak256(
      abi.encodePacked(newLeaderboard.projectId, newLeaderboard.leaderBoardId)
    );

    emit createNftRequiredLeaderboard(
      leaderboardHashId,
      msg.sender,
      _leaderboardName,
      _projectId,
      newLeaderboard.leaderBoardId,
      newLeaderboard.leaderboardCount,
      newLeaderboard.epoch,
      newLeaderboard.nftRequired,
      _nftsRequired
    );
  }

  // function createLeaderboardOpen(
  //   uint256 _projectId,
  //   string memory _leaderboardName,
  //   uint256 _time
  // ) public {
  //   require(
  //     projectIdToProject[_projectId].owners[msg.sender] == true,
  //     "You are not an owner of this project."
  //   );

  //   Leaderboard storage newLeaderboard = leaderboardIndex[_projectId][
  //     projectIdToProject[_projectId].numberOfLeaderboards
  //   ];
  //   newLeaderboard.name = _leaderboardName;
  //   newLeaderboard.projectId = _projectId;
  //   newLeaderboard.leaderBoardId = projectIdToProject[_projectId]
  //     .numberOfLeaderboards;
  //   newLeaderboard.leaderboardCount = 0;
  //   newLeaderboard.epoch = _time;
  //   newLeaderboard.blockStart = block.number;
  //   newLeaderboard.blockEnd = block.number + _time;
  //   newLeaderboard.nftRequired = false;

  //   projectIdToProject[_projectId].numberOfLeaderboards = projectIdToProject[
  //     _projectId
  //   ].numberOfLeaderboards.add(1);
  // }

  // function archiveAndResetLeaderboard(
  //   uint256 _projectId,
  //   uint256 _leaderboardId
  // ) internal {
  //   // Leaderboard memory leaderboardCopy = leaderboardIndex[_projectId][
  //   //   _leaderboardId
  //   // ];
  //   Leaderboard storage leaderboardArchived = leaderboardArchive[_projectId][
  //     _leaderboardId
  //   ][leaderboardIndex[_projectId][_leaderboardId].leaderboardCount];
  //   leaderboardArchived = leaderboardIndex[_projectId][_leaderboardId];
  //   // leaderboardArchive[_projectId][_leaderboardId][leaderboardIndex[_projectId][_leaderboardId].leaderboardCount] = leaderboardIndex[_projectId][_leaderboardId];

  //   Leaderboard storage leaderboardNew = leaderboardIndex[_projectId][
  //     _leaderboardId
  //   ];
  //   leaderboardNew.leaderboardCount = leaderboardNew.leaderboardCount.add(1);
  //   leaderboardNew.blockStart = block.number;
  //   leaderboardNew.blockEnd = block.number + leaderboardNew.epoch;
  //   delete leaderboardNew.members;

  //   // Need to iterate through both mappings and reset each entry
  //   address[] memory members = leaderboardIndex[_projectId][_leaderboardId]
  //     .members;
  //   for (uint256 i = 0; i < members.length; i++) {
  //     // delete leaderboardIndex[_projectId][_leaderboardId].rows[members[i]];
  //     // If delete does not properly erase addressToIndex mapping, will need to use loop below, need to test
  //     address[] memory rowVoters = leaderboardIndex[_projectId][_leaderboardId]
  //       .rows[members[i]]
  //       .voters;
  //     for (uint256 j = 0; j < rowVoters.length; j++) {
  //       leaderboardIndex[_projectId][_leaderboardId]
  //         .rows[members[i]]
  //         .addressToIndex[rowVoters[j]] = 0;
  //     }
  //   }
  //   address[] memory voters = leaderboardIndex[_projectId][_leaderboardId]
  //     .voters;
  //   for (uint256 i = 0; i < voters.length; i++) {
  //     leaderboardIndex[_projectId][_leaderboardId].voterToHasVoted[
  //       voters[i]
  //     ] = false;
  //   }
  // }

  function castVote(
    uint256 _projectId,
    uint256 _leaderboardId,
    address _member,
    uint256 _nftTokenId
  ) public whenNotPaused {
    require(
      leaderboardIndex[_projectId][_leaderboardId].epoch != 0,
      "This leaderboard does not exist."
    );
    require(_member != msg.sender, "Cannot vote for self");

    address nftOwner = IERC721(projectIdToProject[_projectId].nftContract).ownerOf(_nftTokenId); // REMOVE FOR TESTING
    require(nftOwner == msg.sender, "You do not own the NFT based on the token ID provided."); // REMOVE FOR TESTING

    LeaderboardInstance storage leaderboardInstance = leaderboardInstances[
      _projectId
    ][_leaderboardId][
      leaderboardIndex[_projectId][_leaderboardId].leaderboardCount
    ];

    if (leaderboardInstance.blockEnd <= block.number) {
      // start new leaderboard instance here
      leaderboardIndex[_projectId][_leaderboardId]
        .leaderboardCount = leaderboardIndex[_projectId][_leaderboardId]
        .leaderboardCount
        .add(1);
    //   LeaderboardInstance storage leaderboardInstance = leaderboardInstances[
    //     _projectId
    //   ][_leaderboardId][
    //     leaderboardIndex[_projectId][_leaderboardId].leaderboardCount
    //   ];
    }

    require(
      leaderboardInstance.voterToHasVoted[msg.sender] == false,
      "You have already voted on this leaderboard."
    );

    leaderboardInstance.voterToHasVoted[msg.sender] = true;
    leaderboardInstance.voters.push(msg.sender);

    MemberRow storage member = leaderboardInstance.rows[_member];

    if (member.numberOfVotes == 0) {
      leaderboardInstance.members.push(_member);
    }

    member.addressToIndex[msg.sender] = member.voters.length; // is there better way than using voters.length?
    member.voters.push(msg.sender);
    member.numberOfVotes = member.numberOfVotes.add(1);

    bytes32 voteHashId = keccak256(
      abi.encodePacked(
        _projectId,
        _leaderboardId,
        leaderboardIndex[_projectId][_leaderboardId].leaderboardCount,
        msg.sender
      )
    );

    emit voteCast(
      voteHashId,
      _projectId,
      _leaderboardId,
      _member,
      _nftTokenId,
      msg.sender
    );
  }

  function changeVote(
    uint256 _projectId,
    uint256 _leaderboardId,
    address _member,
    address _newMember
  ) public whenNotPaused {
    LeaderboardInstance storage leaderboardInstance = leaderboardInstances[
      _projectId
    ][_leaderboardId][
      leaderboardIndex[_projectId][_leaderboardId].leaderboardCount
    ];
    require(
      leaderboardInstance.voterToHasVoted[msg.sender] == true,
      "You have not voted on this leaderboard."
    );
    require(_member != _newMember, "Cannot change vote to the same member.");

    MemberRow storage member = leaderboardInstance.rows[_member];
    /*
        for (uint256 i = 0; i < member.voters.length; i++) {
            if (member.voters[i] == msg.sender) {
                delete member.voters[i];
                break;
            }
        }
    */
    delete member.voters[member.addressToIndex[msg.sender]];
    delete member.addressToIndex[msg.sender];
    member.numberOfVotes = member.numberOfVotes.sub(1);

    MemberRow storage newMember = leaderboardInstance.rows[_newMember];
    newMember.voters.push(msg.sender);
    newMember.numberOfVotes = member.numberOfVotes.add(1);

    if (newMember.numberOfVotes == 0) {
      leaderboardInstance.members.push(_newMember);
    }

    bytes32 changeVoteHashId = keccak256(
      abi.encodePacked(
        _projectId,
        _leaderboardId,
        leaderboardIndex[_projectId][_leaderboardId].leaderboardCount,
        msg.sender
      )
    );

    emit voteChange(
      changeVoteHashId,
      _projectId,
      _leaderboardId,
      _member,
      _newMember
    );
  }
}