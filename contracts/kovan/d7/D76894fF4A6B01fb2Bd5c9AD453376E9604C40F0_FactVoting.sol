// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IFactManager.sol";
import "../interfaces/IFactMedia.sol";

contract FactVoting is Ownable {
    IFactManager FactManager;
    IFactMedia FactMedia;

    uint256 public ballotID;

    mapping(string => bool) opportunityToVote; // Mapping to check if a vote was taken.
    mapping(uint256 => VotingBallot) public votingArchive;

    struct VotingBallot {
        address accusingFakeHunter;
        string newsURI;
        string exposingURI; // link to the article/arguments confirming that the news is fake
        uint256 voteFor;
        uint256 voteAgainst;
        uint256 startTime;
        uint256 endTime;
        mapping(address => bool) alreadyVoted;
        bool votingStatus; // voting status, true-open, false-close
    }

    function setFactManagerContract(address _addressFactManager)
        external
        onlyOwner
    {
        FactManager = IFactManager(_addressFactManager);
    }

    function setFactMediaContract(address _addressFactMedia)
        external
        onlyOwner
    {
        FactMedia = IFactMedia(_addressFactMedia);
    }

    function openVoting(string memory _newsURI, string memory _exposingURI)
        external
    {
        (bool _fakeHunterAccreditation, ) = FactManager.fakeHuntersInfo(
            msg.sender
        );
        uint256 _fakeHunterBalance = FactManager.depositInfo(msg.sender);
        require(
            _fakeHunterAccreditation == true,
            "You are not an accredited fake hunter!"
        );
        require(
            _fakeHunterBalance >= 20 * 10**18,
            "You don't have enough funds to open voting!"
        );
        require(
            opportunityToVote[_newsURI] == false,
            "FactVoting is in progress or already finished!"
        );
        opportunityToVote[_newsURI] = true;
        VotingBallot storage newVotingBallot = votingArchive[ballotID];
        newVotingBallot.accusingFakeHunter = msg.sender;
        newVotingBallot.newsURI = _newsURI;
        newVotingBallot.exposingURI = _exposingURI;
        newVotingBallot.voteFor = 20;
        newVotingBallot.voteAgainst = 0;
        newVotingBallot.startTime = block.timestamp;
        newVotingBallot.endTime = block.timestamp + 1 minutes; // 7 days
        newVotingBallot.alreadyVoted[msg.sender] = true;
        newVotingBallot.votingStatus = true;
        uint256 _amount = 20 * 10**18;
        uint256 _reward = _amount + 10 * 10**18;
        FactManager.dataOfVote(msg.sender, ballotID, _amount, _reward, true);
        FactMedia.safeMint(_newsURI);
        ballotID++;
    }

    function vote(
        uint256 _ballotID,
        uint256 _amount,
        bool _vote
    ) external {
        uint256 _voterBalance = FactManager.depositInfo(msg.sender);
        require(_amount <= 10**18, "The minimum amount to block is 10 tokens!");
        require(
            _amount <= _voterBalance,
            "You don't have enough money to vote!"
        );
        require(
            votingArchive[_ballotID].votingStatus == true,
            "FactVoting is closed!"
        );
        require(
            votingArchive[_ballotID].alreadyVoted[msg.sender] == false,
            "You have already voted!"
        );
        require(
            votingArchive[_ballotID].endTime > block.timestamp,
            "Time to vote is up!"
        );
        uint256 _voteWeight = _amount / 10**18;
        if (_vote == true) {
            votingArchive[_ballotID].voteFor += _voteWeight;
        } else {
            votingArchive[_ballotID].voteAgainst += _voteWeight;
        }
        votingArchive[_ballotID].alreadyVoted[msg.sender] = true;
        uint256 _reward = _amount + 10**18;
        FactManager.dataOfVote(msg.sender, _ballotID, _amount, _reward, _vote);
    }

    function endOfVoting(uint256 _ballotID) public onlyOwner {
        require(
            votingArchive[_ballotID].endTime <= block.timestamp,
            "Voting time is not over yet!"
        );
        votingArchive[_ballotID].votingStatus = false;
        address _fakeHunter = votingArchive[_ballotID].accusingFakeHunter;
        if (
            votingArchive[_ballotID].voteFor >
            votingArchive[_ballotID].voteAgainst
        ) {
            FactManager.changeRatingFakeHunter(_fakeHunter, 2);
        } else if (
            votingArchive[_ballotID].voteFor <
            votingArchive[_ballotID].voteAgainst
        ) {
            FactManager.changeRatingFakeHunter(_fakeHunter, -2);
        }
    }

    function votingArchiveInfo(uint256 _ballotID)
        public
        view
        returns (
            address,
            string memory,
            string memory,
            uint256,
            uint256,
            uint256,
            bool
        )
    {
        return (
            votingArchive[_ballotID].accusingFakeHunter,
            votingArchive[_ballotID].newsURI,
            votingArchive[_ballotID].exposingURI,
            votingArchive[_ballotID].voteFor,
            votingArchive[_ballotID].voteAgainst,
            votingArchive[_ballotID].endTime,
            votingArchive[_ballotID].votingStatus
        );
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
pragma solidity ^0.8;

interface IFactManager {
    function fakeHuntersInfo(address _from)
        external
        view
        returns (bool, int256);

    function depositInfo(address _user) external view returns (uint256);

    function participationInVotingInfo(address _voter, uint256 _ballotID)
        external
        view
        returns (
            uint256,
            uint256,
            bool
        );

    function changeRatingFakeHunter(address _address, int256 delta) external;

    function dataOfVote(
        address _voter,
        uint256 _ballotID,
        uint256 _lockedAmount,
        uint256 _lockedAmountWithReward,
        bool _vote
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

interface IFactMedia {
    function safeMint(string memory uri) external;
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