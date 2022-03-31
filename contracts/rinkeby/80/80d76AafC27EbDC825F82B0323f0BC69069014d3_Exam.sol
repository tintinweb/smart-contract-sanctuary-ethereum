// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Exam is Ownable {

    uint256 ENTRY_FEE = 10000000000000000;
    uint256 public votingPeriodInSeconds = 3 * 24 * 60 * 60; //seconds
    uint256 public ownerFee;

    struct Voting {
        address[] applicants;
        uint256[] votes;
        address winner;
        uint256 endTimestamp;
        uint256 sumEther;
        bool archived;
    }
    mapping(address => mapping(uint256 => bool)) voted;

    mapping(uint256 => Voting) votings;
    uint256 votingCounter;

    function getVoting(uint index) external view returns(address[] memory, uint256[] memory, address, uint256) {
        return (votings[index].applicants, votings[index].votes, votings[index].winner, votings[index].endTimestamp);
    }

    function addVoting(address[] memory applicants) external onlyOwner {
        Voting storage newVoting = votings[votingCounter++];

        newVoting.endTimestamp = block.timestamp + votingPeriodInSeconds;

        for(uint256 i = 0; i < applicants.length; i++){
            newVoting.applicants.push(applicants[i]);
            newVoting.votes.push(0);
        }
    }

    function finish(uint256 votingIndex) external {
        require(!votings[votingIndex].archived, "ALREADY ARCHIVED");
        require(votingIndex < votingCounter, "INDEX OUT OF BOUNDS");
        require(votings[votingIndex].endTimestamp < block.timestamp, "NOT ENOUGH TIME");

        uint256 max = 0;
        address payable winner;
        for (uint i = 0; i < votings[votingIndex].votes.length; i++) {
            if (votings[votingIndex].votes[i] > max) {
                max = votings[votingIndex].votes[i];
                winner = payable(votings[votingIndex].applicants[i]);
            }
        }
        votings[votingIndex].winner = winner;
        winner.transfer(votings[votingIndex].sumEther * 90 / 100);

        ownerFee += votings[votingIndex].sumEther * 10 / 100;

        votings[votingIndex].archived = true;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(ownerFee);
        ownerFee = 0;
    }

    function vote(uint256 indexVoting, uint256 indexPerson) external payable {
        require(voted[msg.sender][indexVoting] == false, "YOU ALREADY VOTED");
        require(msg.value == ENTRY_FEE, "BAD AMOUNT INPUT");
        require(indexVoting < votingCounter, "INDEX OUT OF BOUNDS");

        voted[msg.sender][indexVoting] = true;
        votings[indexVoting].votes[indexPerson]++;
        votings[indexVoting].sumEther += msg.value;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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