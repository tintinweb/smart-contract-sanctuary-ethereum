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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IAllocationsStorage.sol";

contract AllocationsStorage is Ownable, IAllocationsStorage {
    mapping(bytes32 => Vote) private votesByUser;
    mapping(bytes32 => address) private votesByProposal;
    mapping(bytes32 => uint256) private votesCount;
    mapping(bytes32 => uint256) private voteIndex;

    // @notice Get user's vote in given epoch.
    function getUserVote(uint256 _epoch, address _user) external view returns (Vote memory) {
        return _getVoteByUser(_epoch, _user);
    }

    // @notice Add a vote. Requires that the vote does not exist.
    function addVote(
        uint256 _epoch,
        uint256 _proposalId,
        address _user,
        uint256 _alpha
    ) external onlyOwner {
        require(_getVoteIndex(_epoch, _proposalId, _user) == 0, "HN/vote-already-exists");
        uint256 count = _getVotesCount(_epoch, _proposalId);
        _setVoteByProposal(_epoch, _proposalId, count + 1, _user);
        _setVoteIndex(_epoch, _proposalId, _user, count + 1);
        _setVotesCount(_epoch, _proposalId, count + 1);
        _setVoteByUser(_epoch, _user, _proposalId, _alpha);
    }

    // @notice Remove a vote. Swaps the item with the last item in the set and truncates it; computationally cheap.
    // Requires that the vote exists.
    function removeVote(
        uint256 _epoch,
        uint256 _proposalId,
        address _user
    ) external onlyOwner {
        uint256 index = _getVoteIndex(_epoch, _proposalId, _user);
        require(index > 0, "HN/vote-does-not-exist");
        uint256 count = _getVotesCount(_epoch, _proposalId);
        if (index < count) {
            address lastVote = _getVoteByProposal(_epoch, _proposalId, count);
            _setVoteByProposal(_epoch, _proposalId, index, lastVote);
            _setVoteIndex(_epoch, _proposalId, lastVote, index);
        }
        _setVoteIndex(_epoch, _proposalId, _user, 0);
        _setVotesCount(_epoch, _proposalId, count - 1);
        _setVoteByUser(_epoch, _user, 0, 0);
    }

    // @notice Users for given proposal.
    function getUsersAlphas(uint256 _epoch, uint256 _proposalId)
        external
        view
        returns (address[] memory, uint256[] memory)
    {
        uint256 count = _getVotesCount(_epoch, _proposalId);
        address[] memory users = new address[](count);
        uint256[] memory alphas = new uint256[](count);
        for (uint256 i = 1; i <= count; i++) {
            address user = getUser(_epoch, _proposalId, i);
            users[i - 1] = user;
            alphas[i - 1] = _getVoteByUser(_epoch, user).alpha;
        }
        return (users, alphas);
    }

    // @notice The number of votes for proposal.
    function getVotesCount(uint256 _epoch, uint256 _proposalId) external view returns (uint256) {
        return _getVotesCount(_epoch, _proposalId);
    }

    // @notice The user address by index. Iteration starts from 1.
    function getUser(
        uint256 _epoch,
        uint256 _proposalId,
        uint256 _index
    ) public view returns (address) {
        return _getVoteByProposal(_epoch, _proposalId, _index);
    }

    // @notice Get vote by proposal.
    function _getVoteByProposal(
        uint256 _epoch,
        uint256 _proposalId,
        uint256 _index
    ) private view returns (address) {
        bytes32 key = keccak256(
            abi.encodePacked(_epoch, ".proposalId", _proposalId, ".index", _index)
        );
        return votesByProposal[key];
    }

    // @notice Set vote by proposal.
    function _setVoteByProposal(
        uint256 _epoch,
        uint256 _proposalId,
        uint256 _index,
        address _user
    ) private {
        bytes32 key = keccak256(
            abi.encodePacked(_epoch, ".proposalId", _proposalId, ".index", _index)
        );
        votesByProposal[key] = _user;
    }

    // @notice Get vote by proposal.
    function _getVoteByUser(uint256 _epoch, address _user) private view returns (Vote memory) {
        bytes32 key = keccak256(abi.encodePacked(_epoch, ".user", _user));
        return votesByUser[key];
    }

    // @notice Set vote by proposal.
    function _setVoteByUser(
        uint256 _epoch,
        address _user,
        uint256 _proposalId,
        uint256 _alpha
    ) private {
        bytes32 key = keccak256(abi.encodePacked(_epoch, ".user", _user));
        votesByUser[key] = Vote(_alpha, _proposalId);
    }

    // @notice Get votes count.
    function _getVotesCount(uint256 _epoch, uint256 _proposalId) private view returns (uint256) {
        bytes32 key = keccak256(abi.encodePacked(_epoch, ".proposalId", _proposalId));
        return votesCount[key];
    }

    // @notice Set votes count.
    function _setVotesCount(
        uint256 _epoch,
        uint256 _proposalId,
        uint256 _count
    ) private {
        bytes32 key = keccak256(abi.encodePacked(_epoch, ".proposalId", _proposalId));
        votesCount[key] = _count;
    }

    // @notice Get vote index.
    function _getVoteIndex(
        uint256 _epoch,
        uint256 _proposalId,
        address _user
    ) private view returns (uint256) {
        bytes32 key = keccak256(
            abi.encodePacked(_epoch, ".proposalId", _proposalId, ".user", _user)
        );
        return voteIndex[key];
    }

    // @notice Set vote index.
    function _setVoteIndex(
        uint256 _epoch,
        uint256 _proposalId,
        address _user,
        uint256 _index
    ) private {
        bytes32 key = keccak256(
            abi.encodePacked(_epoch, ".proposalId", _proposalId, ".user", _user)
        );
        voteIndex[key] = _index;
    }
}

pragma solidity ^0.8.9;

/* SPDX-License-Identifier: UNLICENSED */

interface IAllocationsStorage {
    struct Vote {
        uint256 alpha;
        uint256 proposalId;
    }

    function getUserVote(uint256 _epoch, address _user) external view returns (Vote memory);

    function addVote(
        uint256 _epoch,
        uint256 _proposalId,
        address _user,
        uint256 _alpha
    ) external;

    function removeVote(
        uint256 _epoch,
        uint256 _proposalId,
        address _user
    ) external;

    function getUsersAlphas(uint256 _epoch, uint256 _proposalId)
        external
        view
        returns (address[] memory, uint256[] memory);

    function getVotesCount(uint256 _epoch, uint256 _proposalId) external view returns (uint256);

    function getUser(
        uint256 _epoch,
        uint256 _proposalId,
        uint256 _index
    ) external view returns (address);
}