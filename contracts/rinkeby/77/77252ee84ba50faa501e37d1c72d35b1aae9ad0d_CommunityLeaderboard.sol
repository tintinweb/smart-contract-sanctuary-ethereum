/**
 *Submitted for verification at Etherscan.io on 2022-05-05
*/

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
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol

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

// File: contracts/lib/BasicMetaTransaction.sol

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

contract BasicMetaTransaction {
  using SafeMath for uint256;

  event MetaTransactionExecuted(
    address userAddress,
    address payable relayerAddress,
    bytes functionSignature
  );
  mapping(address => uint256) nonces;

  function getChainID() public view returns (uint256) {
    uint256 id;
    assembly {
      id := chainid()
    }
    return id;
  }

  /**
   * Main function to be called when user wants to execute meta transaction.
   * The actual function to be called should be passed as param with name functionSignature
   * Here the basic signature recovery is being used. Signature is expected to be generated using
   * personal_sign method.
   * @param userAddress Address of user trying to do meta transaction
   * @param functionSignature Signature of the actual function to be called via meta transaction
   * @param sigR R part of the signature
   * @param sigS S part of the signature
   * @param sigV V part of the signature
   */
  function executeMetaTransaction(
    address userAddress,
    bytes memory functionSignature,
    bytes32 sigR,
    bytes32 sigS,
    uint8 sigV
  ) public payable returns (bytes memory) {
    require(
      verify(
        userAddress,
        nonces[userAddress],
        getChainID(),
        functionSignature,
        sigR,
        sigS,
        sigV
      ),
      "Signer and signature do not match"
    );
    nonces[userAddress] = nonces[userAddress].add(1);

    // Append userAddress at the end to extract it from calling context
    (bool success, bytes memory returnData) = address(this).call(
      abi.encodePacked(functionSignature, userAddress)
    );

    require(success, "Function call not successfull");
    emit MetaTransactionExecuted(
      userAddress,
      payable(msg.sender),
      functionSignature
    );
    return returnData;
  }

  function getNonce(address user) public view returns (uint256 nonce) {
    nonce = nonces[user];
  }

  // Builds a prefixed hash to mimic the behavior of eth_sign.
  function prefixed(bytes32 hash) internal pure returns (bytes32) {
    return
      keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
  }

  function verify(
    address owner,
    uint256 nonce,
    uint256 chainID,
    bytes memory functionSignature,
    bytes32 sigR,
    bytes32 sigS,
    uint8 sigV
  ) public view returns (bool) {
    bytes32 hash = prefixed(
      keccak256(abi.encodePacked(nonce, this, chainID, functionSignature))
    );
    address signer = ecrecover(hash, sigV, sigR, sigS);
    require(signer != address(0), "Invalid signature");
    return (owner == signer);
  }

  function msgSender() internal view returns (address sender) {
    if (msg.sender == address(this)) {
      bytes memory array = msg.data;
      uint256 index = msg.data.length;
      assembly {
        // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
        sender := and(
          mload(add(array, index)),
          0xffffffffffffffffffffffffffffffffffffffff
        )
      }
    } else {
      return msg.sender;
    }
  }
}

// File: contracts/CommunityLeaderboard.sol

pragma solidity ^0.8.0;




interface IERC721 {
  function owner() external returns (address owner);

  function ownerOf(uint256 tokenId) external returns (address owner);
}

contract CommunityLeaderboard is Ownable, Pausable, BasicMetaTransaction {
  using SafeMath for uint256;

  uint256 public maxLeaderboardsPerProject = 50;

  event ProjectRegistered(
    bytes32 projectHashId,
    uint256 projectId,
    address indexed from,
    address indexed nftContract,
    string name,
    uint256 numberOfLeaderboards
  );

  event NewProjectOwnerAdded(uint256 _projectId, address indexed _newOwner);

  event LeaderboardCreated(
    bytes32 leaderboardHashId,
    address indexed creator,
    string leaderboardName,
    uint256 projectId,
    uint256 leaderBoardId,
    uint256 epochCount,
    uint256 epoch
  );

  event VoteCast(
    bytes32 voteHashId,
    uint256 projectId,
    uint256 leaderboardId,
    address indexed member,
    uint256 nftTokenId,
    address indexed voter
  );

  event VoteChanged(
    bytes32 changeVoteHashId,
    uint256 projectId,
    uint256 leaderboardId,
    address indexed member,
    address indexed newMember
  );

  struct Project {
    mapping(address => bool) addressToIsOwner;
    address[] owners;
    address nftContract;
    string name;
    uint256 projectId;
    uint256 numberOfLeaderboards;
  }

  struct MemberRow {
    uint256 numberOfVotes;
    address[] voters;
    mapping(address => uint256) addressToIndex;
  }

  struct LeaderboardSettings {
    string name;
    uint256 projectId;
    uint256 leaderBoardId;
    uint256 epochCount; // How many leaderboard epochs have passed
    uint256 epoch; // Days per epoch
  }

  struct LeaderboardInstance {
    uint256 leaderBoardId;
    uint256 blockStart;
    uint256 blockEnd;
    address[] members; // Addresses that have received votes (used to iterate)
    address[] voters;
    mapping(address => MemberRow) rows;
    mapping(address => bool) voterToHasVoted;
  }

  uint256 public projectCount = 0;
  uint256[] public projectIds;
  mapping(uint256 => Project) public projectIdToProject;
  mapping(uint256 => mapping(uint256 => LeaderboardSettings))
    public leaderboardIndex;
  mapping(uint256 => mapping(uint256 => mapping(uint256 => LeaderboardInstance)))
    public epochToLeaderboard;

  function getLeaderboard(uint256 _projectId, uint256 _leaderboardId)
    external
    view
    returns (
      string memory,
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    LeaderboardSettings storage leaderboard = leaderboardIndex[_projectId][
      _leaderboardId
    ];
    return (
      leaderboard.name,
      leaderboard.projectId,
      leaderboard.leaderBoardId,
      leaderboard.epochCount,
      leaderboard.epoch
    );
  }

  function getProjectName(uint256 _projectId)
    external
    view
    returns (string memory)
  {
    return projectIdToProject[_projectId].name;
  }

  // change name to getProjectNumberOfLeaderboards
  function getProjectepochCount(uint256 _projectId)
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
      epochToLeaderboard[_projectId][_leaderboardId][
        leaderboardIndex[_projectId][_leaderboardId].epochCount
      ].members.length;
  }

  function getLeaderboardMemberAddress(
    uint256 _projectId,
    uint256 _leaderboardId,
    uint256 _memberId
  ) external view returns (address) {
    return
      epochToLeaderboard[_projectId][_leaderboardId][
        leaderboardIndex[_projectId][_leaderboardId].epochCount
      ].members[_memberId];
  }

  function getLeaderboardMemberVoteCount(
    uint256 _projectId,
    uint256 _leaderboardId,
    uint256 _memberId
  ) external view returns (uint256) {
    return
      epochToLeaderboard[_projectId][_leaderboardId][
        leaderboardIndex[_projectId][_leaderboardId].epochCount
      ]
        .rows[
          epochToLeaderboard[_projectId][_leaderboardId][
            leaderboardIndex[_projectId][_leaderboardId].epochCount
          ].members[_memberId]
        ]
        .numberOfVotes;
  }

  function getLeaderboardMemberVoteCountByAddress(
    uint256 _projectId,
    uint256 _leaderboardId,
    address _member
  ) external view returns (uint256) {
    return
      epochToLeaderboard[_projectId][_leaderboardId][
        leaderboardIndex[_projectId][_leaderboardId].epochCount
      ].rows[_member].numberOfVotes;
  }

  function getLeaderboardArchivedMemberVoteCount(
    uint256 _projectId,
    uint256 _leaderboardId,
    address _member,
    uint256 _leaderboardArchiveId
  ) external view returns (uint256) {
    return
      epochToLeaderboard[_projectId][_leaderboardId][_leaderboardArchiveId]
        .rows[_member]
        .numberOfVotes;
  }

  function registerProject(address _nftContract, string memory _name)
    public
    whenNotPaused
    returns (uint256)
  {
    // Verify that the person calling function is owner of NFT contract
    // address nftContractOwner = IERC721(_nftContract).owner(); // REMOVE FOR TESTING
    // require(nftContractOwner == msgSender(), "You do not own this NFT contract."); // REMOVE FOR TESTING

    Project storage newProject = projectIdToProject[projectCount];
    newProject.addressToIsOwner[msgSender()] = true;
    newProject.owners.push(msgSender());
    newProject.nftContract = _nftContract;
    newProject.name = _name;
    newProject.projectId = projectCount;
    newProject.numberOfLeaderboards = 0;

    projectCount = projectCount.add(1);

    bytes32 projectHashId = keccak256(
      abi.encodePacked(_nftContract, ":", newProject.projectId)
    );

    emit ProjectRegistered(
      projectHashId,
      newProject.projectId,
      msgSender(),
      _nftContract,
      _name,
      newProject.numberOfLeaderboards
    );

    return newProject.projectId;
  }

  function addOwnerToProject(uint256 _projectId, address _newOwner)
    public
    whenNotPaused
  {
    require(
      projectIdToProject[_projectId].addressToIsOwner[msgSender()] == true,
      "You are not an owner of this project."
    );
    projectIdToProject[_projectId].addressToIsOwner[_newOwner] = true;
    projectIdToProject[_projectId].owners.push(_newOwner);

    emit NewProjectOwnerAdded(_projectId, _newOwner);
  }

  function deleteProject(uint256 _projectId) external onlyOwner {
    delete projectIdToProject[_projectId];
  }

  function deleteLeaderboard(uint256 _projectId, uint256 _leaderboardId)
    external
    onlyOwner
  {
    delete leaderboardIndex[_projectId][_leaderboardId];
  }

  function userDeleteProject(uint256 _projectId) external {
    require(
      projectIdToProject[_projectId].addressToIsOwner[msgSender()] == true,
      "You are not an owner of this project."
    );
    delete projectIdToProject[_projectId];
  }

  function userDeleteLeaderboard(uint256 _projectId, uint256 _leaderboardId)
    external
    onlyOwner
  {
    require(
      projectIdToProject[_projectId].addressToIsOwner[msgSender()] == true,
      "You are not an owner of this project."
    );
    delete leaderboardIndex[_projectId][_leaderboardId];
  }

  function createLeaderboard(
    uint256 _projectId,
    string memory _leaderboardName,
    uint256 _time
  ) public whenNotPaused returns (uint256) {
    require(
      projectIdToProject[_projectId].addressToIsOwner[msgSender()] == true,
      "You are not an owner of this project."
    );
    require(
      projectIdToProject[_projectId].numberOfLeaderboards <
        maxLeaderboardsPerProject,
      "Have reached max amount of leaderboards allowed in this project."
    );

    LeaderboardSettings storage newLeaderboard = leaderboardIndex[_projectId][
      projectIdToProject[_projectId].numberOfLeaderboards
    ];
    newLeaderboard.name = _leaderboardName;
    newLeaderboard.projectId = _projectId;
    newLeaderboard.leaderBoardId = projectIdToProject[_projectId]
      .numberOfLeaderboards;
    newLeaderboard.epochCount = 1;
    newLeaderboard.epoch = _time;

    LeaderboardInstance storage leaderboardInstance = epochToLeaderboard[
      _projectId
    ][projectIdToProject[_projectId].numberOfLeaderboards][1];
    leaderboardInstance.blockStart = block.number;
    leaderboardInstance.blockEnd = block.number + _time;

    projectIdToProject[_projectId].numberOfLeaderboards = projectIdToProject[
      _projectId
    ].numberOfLeaderboards.add(1);

    bytes32 leaderboardHashId = keccak256(
      abi.encodePacked(
        newLeaderboard.projectId,
        ":",
        newLeaderboard.leaderBoardId
      )
    );

    emit LeaderboardCreated(
      leaderboardHashId,
      msgSender(),
      _leaderboardName,
      _projectId,
      newLeaderboard.leaderBoardId,
      newLeaderboard.epochCount,
      newLeaderboard.epoch
    );

    return newLeaderboard.leaderBoardId;
  }

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
    require(_member != msgSender(), "Cannot vote for self");

    // address nftOwner = IERC721(projectIdToProject[_projectId].nftContract).ownerOf(_nftTokenId); // REMOVE FOR TESTING
    // require(nftOwner == msgSender(), "You do not own the NFT based on the token ID provided."); // REMOVE FOR TESTING

    LeaderboardInstance storage leaderboardInstance = epochToLeaderboard[
      _projectId
    ][_leaderboardId][leaderboardIndex[_projectId][_leaderboardId].epochCount];

    if (leaderboardInstance.blockEnd <= block.number) {
      leaderboardIndex[_projectId][_leaderboardId]
        .epochCount = leaderboardIndex[_projectId][_leaderboardId]
        .epochCount
        .add(1);
      leaderboardInstance = epochToLeaderboard[_projectId][_leaderboardId][
        leaderboardIndex[_projectId][_leaderboardId].epochCount
      ];
    }

    require(
      leaderboardInstance.voterToHasVoted[msgSender()] == false,
      "You have already voted on this leaderboard."
    );

    leaderboardInstance.voterToHasVoted[msgSender()] = true;
    leaderboardInstance.voters.push(msgSender());

    MemberRow storage member = leaderboardInstance.rows[_member];

    if (member.numberOfVotes == 0) {
      leaderboardInstance.members.push(_member);
    }

    member.addressToIndex[msgSender()] = member.voters.length;
    member.voters.push(msgSender());
    member.numberOfVotes = member.numberOfVotes.add(1);

    bytes32 voteHashId = keccak256(
      abi.encodePacked(
        _projectId,
        _leaderboardId,
        leaderboardIndex[_projectId][_leaderboardId].epochCount,
        msgSender()
      )
    );

    emit VoteCast(
      voteHashId,
      _projectId,
      _leaderboardId,
      _member,
      _nftTokenId,
      msgSender()
    );
  }

  function changeVote(
    uint256 _projectId,
    uint256 _leaderboardId,
    address _member,
    address _newMember
  ) public whenNotPaused {
    LeaderboardInstance storage leaderboardInstance = epochToLeaderboard[
      _projectId
    ][_leaderboardId][leaderboardIndex[_projectId][_leaderboardId].epochCount];

    if (leaderboardInstance.blockEnd <= block.number) {
      leaderboardIndex[_projectId][_leaderboardId]
        .epochCount = leaderboardIndex[_projectId][_leaderboardId]
        .epochCount
        .add(1);
      leaderboardInstance = epochToLeaderboard[_projectId][_leaderboardId][
        leaderboardIndex[_projectId][_leaderboardId].epochCount
      ];
    }

    require(
      leaderboardInstance.voterToHasVoted[msgSender()] == true,
      "You have not voted on this leaderboard."
    );
    require(_member != _newMember, "Cannot change vote to the same member.");

    MemberRow storage member = leaderboardInstance.rows[_member];
    delete member.voters[member.addressToIndex[msgSender()]];
    delete member.addressToIndex[msgSender()];
    member.numberOfVotes = member.numberOfVotes.sub(1);

    MemberRow storage newMember = leaderboardInstance.rows[_newMember];
    newMember.voters.push(msgSender());
    newMember.numberOfVotes = member.numberOfVotes.add(1);

    if (newMember.numberOfVotes == 0) {
      leaderboardInstance.members.push(_newMember);
    }

    bytes32 changeVoteHashId = keccak256(
      abi.encodePacked(
        _projectId,
        _leaderboardId,
        leaderboardIndex[_projectId][_leaderboardId].epochCount,
        msgSender()
      )
    );

    emit VoteChanged(
      changeVoteHashId,
      _projectId,
      _leaderboardId,
      _member,
      _newMember
    );
  }
}