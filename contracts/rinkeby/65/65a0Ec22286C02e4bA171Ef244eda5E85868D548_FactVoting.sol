// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "Ownable.sol";
import "IFactManager.sol";

contract FactVoting is Ownable {
    IFactManager FactManager;
    mapping(uint256 => bool) opportunityToVote; // Mapping to check if a vote was taken.
    mapping(uint256 => VotingBallot) public votingArchive;

    struct VotingBallot {
        address accusedMedia;
        address accusingFakeHunter;
        string exposingURI; // link to the article/arguments confirming that the news is fake
        uint256 voteFor;
        uint256 voteAgainst;
        uint256 startTime;
        uint256 endTime;
        mapping(address => bool) alreadyVoted;
        bool votingStatus; // voting status, true-open, false-close
        address[] votedFor;
        address[] votedAgainst;
    }

    /**
     * @dev This function is for assigning the address of a deployed maanger contract on the network.
     * @param _addressFactManager Address of the maanger contract deployed in the network.
     */
    function setAddressFactManagerContract(address _addressFactManager)
        external
        onlyOwner
    {
        FactManager = IFactManager(_addressFactManager);
    }

    /**
     * @dev Voting opening function.
     * Voting can only be opened once.
     * The person who opens the vote automatically votes yes.
     * Voting closes after the function is called at the end of time.
     * @param _tokenId token id of the accused news.
     * @param _uri link to the article/arguments confirming that the news is fake.
     */
    function openVoting(uint256 _tokenId, string memory _uri) external {
        (bool _fakeHunterAccreditation, , ) = FactManager.fakeHuntersInfo(
            msg.sender
        );
        require(
            _fakeHunterAccreditation == true,
            "You are not an accredited fake hunter!"
        );
        require(
            opportunityToVote[_tokenId] == false,
            "FactVoting is in progress or already finished!"
        );
        opportunityToVote[_tokenId] = true;
        VotingBallot storage newVotingBallot = votingArchive[_tokenId];
        newVotingBallot.accusedMedia = FactManager.getNewsOwner(_tokenId);
        newVotingBallot.accusingFakeHunter = msg.sender;
        newVotingBallot.exposingURI = _uri;
        newVotingBallot.voteFor = 1;
        newVotingBallot.voteAgainst = 0;
        newVotingBallot.startTime = block.timestamp;
        newVotingBallot.endTime = block.timestamp + 2 minutes; // 7 days
        newVotingBallot.alreadyVoted[msg.sender] = true;
        newVotingBallot.votingStatus = true;
        newVotingBallot.votedFor.push(msg.sender);
    }

    /**
     * @dev Voting function.
     * If the voting time has expired, the vote is not accepted and the voting ends.
     * @param _tokenId token id of the accused news.
     * @param _vote true-news is fake, false-news is not fake
     */
    function vote(uint256 _tokenId, bool _vote) external {
        (bool _fakeHunterAccreditation, , ) = FactManager.fakeHuntersInfo(
            msg.sender
        );
        require(
            _fakeHunterAccreditation == true,
            "You are not an accredited fake hunter!"
        );
        require(
            votingArchive[_tokenId].votingStatus == true,
            "FactVoting is closed!"
        );
        require(
            votingArchive[_tokenId].alreadyVoted[msg.sender] == false,
            "You have already voted!"
        );
        if (votingArchive[_tokenId].endTime < block.timestamp) {
            endOfVoting(_tokenId);
        } else {
            if (_vote == true) {
                votingArchive[_tokenId].voteFor++;
                votingArchive[_tokenId].votedFor.push(msg.sender);
            } else {
                votingArchive[_tokenId].voteAgainst++;
                votingArchive[_tokenId].votedAgainst.push(msg.sender);
            }
            votingArchive[_tokenId].alreadyVoted[msg.sender] = true;
        }
    }

    /**
     * @dev The function of the end of voting and counting of votes.
     * A function can only be called by the contract itself.
     */
    function endOfVoting(uint256 _tokenId) private {
        votingArchive[_tokenId].votingStatus = false;
        address _fakeHunter = votingArchive[_tokenId].accusingFakeHunter;
        address _media = votingArchive[_tokenId].accusedMedia;
        if (
            votingArchive[_tokenId].voteFor >
            votingArchive[_tokenId].voteAgainst
        ) {
            FactManager.changeRatingFakeHunter(_fakeHunter, 2);
            FactManager.changeRatingMedia(_media, -2);
            FactManager.distributionOfAwards(
                _media,
                _fakeHunter,
                true,
                _tokenId
            );
        } else if (
            votingArchive[_tokenId].voteFor <
            votingArchive[_tokenId].voteAgainst
        ) {
            FactManager.changeRatingFakeHunter(_fakeHunter, -2);
            FactManager.changeRatingMedia(_media, 2);
            FactManager.distributionOfAwards(
                _media,
                _fakeHunter,
                false,
                _tokenId
            );
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IFactManager {
    function fakeHuntersInfo(address _from)
        external
        view
        returns (
            bool,
            int256,
            uint256
        );

    function getMediaInfo(address _from)
        external
        view
        returns (
            bool,
            int256,
            uint256
        );

    function changeRatingFakeHunter(address _address, int256 delta) external;

    function changeRatingMedia(address _address, int256 delta) external;

    function distributionOfAwards(
        address _media,
        address _fakeCatcher,
        bool _resultOfVoting,
        uint256 _tokenId
    ) external;

    function getNewsOwner(uint256 _tokenId) external view returns (address);

    function addNewsToArchive(address _mediaAddress, uint256 _tokenId) external;
}