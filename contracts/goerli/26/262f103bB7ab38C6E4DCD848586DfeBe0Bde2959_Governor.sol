//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Governor is Ownable {
  struct Member {
    string name;
    string email;
    address wallet;
  }

  struct Project {
    string name;
    string description;
    uint256 date;
    uint256 votes;
    bool approved;
  }

  uint256 public quorum = 80;
  uint256 public memberCount;
  uint256 public projectCount;

  uint256 public constant VOTING_PERIOD = 1 weeks;

  mapping(uint256 => Member) private members;
  mapping(uint256 => Project) private projects;
  mapping(uint256 => address[]) private votes;

  modifier onlyMembers(address _wallet) {
    for (uint256 i = 0; i < memberCount; ++i) {
      if (members[i].wallet == _wallet) {
        _;
        return;
      }
    }

    revert("Not a member");
  }

  event NewProjectProposed(
    address indexed _from,
    string _name,
    string _description
  );

  event ProjectApproved(uint256 indexed _projectId);

  function propose(string calldata _name, string calldata _description)
    external
    onlyMembers(msg.sender)
  {
    projects[projectCount] = Project(
      _name,
      _description,
      block.timestamp,
      0,
      false
    );
    projectCount++;

    emit NewProjectProposed(msg.sender, _name, _description);
  }

  function vote(uint256 _projectId) external onlyMembers(msg.sender) {
    require(
      keccak256(abi.encodePacked(projects[_projectId].name)) !=
        keccak256(abi.encodePacked("")),
      "Project does not exist"
    );
    require(projects[_projectId].approved == false, "Project already approved");
    require(
      projects[_projectId].date + VOTING_PERIOD > block.timestamp,
      "Vote period has ended"
    );

    for (uint256 i = 0; i < projects[_projectId].votes; ++i) {
      if (votes[_projectId][i] == msg.sender) {
        revert("Already voted");
      }
    }

    projects[_projectId].votes += 1;
    votes[_projectId].push(msg.sender);

    if ((projects[_projectId].votes / memberCount) * 100 >= quorum) {
      projects[_projectId].approved = true;

      emit ProjectApproved(_projectId);
    }
  }

  function getProjects() external view returns (Project[] memory) {
    Project[] memory result = new Project[](projectCount);

    for (uint256 i = 0; i < projectCount; ++i) {
      Project storage project = projects[i];
      result[i] = project;
    }

    return result;
  }

  function getMembers() external view returns (Member[] memory) {
    Member[] memory result = new Member[](memberCount);

    for (uint256 i = 0; i < memberCount; ++i) {
      Member storage member = members[i];
      result[i] = member;
    }

    return result;
  }

  function getProject(uint256 _projectId) public view returns (Project memory) {
    return projects[_projectId];
  }

  function getMember(address _wallet) public view returns (Member memory) {
    for (uint256 i = 0; i < memberCount; ++i) {
      if (members[i].wallet == _wallet) {
        return members[i];
      }
    }

    revert("Not a member");
  }

  function register(
    string calldata _name,
    string calldata _email,
    address _wallet
  ) external onlyOwner {
    members[memberCount] = Member(_name, _email, _wallet);
    memberCount++;
  }

  function remove(address _wallet) external onlyOwner onlyMembers(_wallet) {
    for (uint256 i = 0; i < memberCount; ++i) {
      if (members[i].wallet == _wallet) {
        members[i] = members[memberCount - 1];
        delete members[memberCount - 1];
        memberCount--;
      }
    }
  }

  function setQuorum(uint256 _quorum) external onlyOwner {
    quorum = _quorum;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
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