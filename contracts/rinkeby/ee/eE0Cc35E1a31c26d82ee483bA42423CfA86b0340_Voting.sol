// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "Ownable.sol";

// интерфейс для взаимодействия с супер контрактом
interface SuperDAO {
    function fakeCatchersInfo(address _from)
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

    function changeRatingFakeCatcher(address _address, int256 delta) external;

    function changeRatingMedia(address _address, int256 delta) external;

    function getNewsOwner(uint256 _tokenId) external view returns (address);
}

contract Voting is Ownable {
    address addressSuperDAO;
    mapping(uint256 => bool) opportunityToVote; // словарь, для проверки, проводилось ли уже голосование
    mapping(uint256 => VotingBallot) public votingArchive; // архив голосований

    struct VotingBallot {
        uint256 newsId; // новость, которая вынесена на голосование.тоже самое,что токен Id
        address accusedMedia; // обвиняемый
        address accusingFakeCatcher; // обвинитель
        string exposingURI; // ссылка на статью/аргументы подтверждающие, что новость фейк
        uint256 voteFor; // голосов за
        uint256 voteAgainst; // голосов против
        uint256 startTime; // время старта голосования
        uint256 endTime; // время, после которого голосование закрывается
        mapping(address => bool) alreadyVoted; // список проголосовавших
        bool votingStatus; // статус голосования, true-открыто, false-закрыто
    }

    // устанавливаем адрес супер контракта
    function setAddressSuperDAO(address _addressSuperDAO) external onlyOwner {
        addressSuperDAO = _addressSuperDAO;
    }

    // открываем голосование
    function openVoting(uint256 _tokenId, string memory _uri) external {
        (bool _fakeCatcherAccreditation, , ) = SuperDAO(addressSuperDAO)
            .fakeCatchersInfo(msg.sender);
        require(
            _fakeCatcherAccreditation == true,
            "You are not an accredited fake catcher!"
        );
        require(
            opportunityToVote[_tokenId] == false,
            "Voting is in progress or already finished!"
        );
        opportunityToVote[_tokenId] = true;
        VotingBallot storage newVotingBallot = votingArchive[_tokenId];
        newVotingBallot.newsId = _tokenId; // нужен ли??
        newVotingBallot.accusedMedia = SuperDAO(addressSuperDAO).getNewsOwner(
            _tokenId
        );
        newVotingBallot.accusingFakeCatcher = msg.sender;
        newVotingBallot.exposingURI = _uri;
        newVotingBallot.voteFor = 1;
        newVotingBallot.voteAgainst = 0;
        newVotingBallot.startTime = block.timestamp;
        newVotingBallot.endTime = block.timestamp + 5 minutes; // 7 days
        newVotingBallot.alreadyVoted[msg.sender] = true;
        newVotingBallot.votingStatus = true;
    }

    // функция отдачи голоса
    function vote(uint256 _tokenId, bool _vote) external {
        (bool _fakeCatcherAccreditation, , ) = SuperDAO(addressSuperDAO)
            .fakeCatchersInfo(msg.sender);
        require(
            _fakeCatcherAccreditation == true,
            "You are not an accredited fake catcher!"
        );
        require(
            votingArchive[_tokenId].votingStatus == true,
            "Voting is closed!"
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
            } else {
                votingArchive[_tokenId].voteAgainst++;
            }
            votingArchive[_tokenId].alreadyVoted[msg.sender] = true;
        }
    }

    // функция окончания голосования и подсчета результатов
    function endOfVoting(uint256 _tokenId) private {
        votingArchive[_tokenId].votingStatus = false;
        address _fakeCatcher = votingArchive[_tokenId].accusingFakeCatcher;
        address _media = votingArchive[_tokenId].accusedMedia;
        if (
            votingArchive[_tokenId].voteFor >
            votingArchive[_tokenId].voteAgainst
        ) {
            SuperDAO(addressSuperDAO).changeRatingFakeCatcher(_fakeCatcher, 2);
            SuperDAO(addressSuperDAO).changeRatingMedia(_media, -2);
        } else if (
            votingArchive[_tokenId].voteFor <
            votingArchive[_tokenId].voteAgainst
        ) {
            SuperDAO(addressSuperDAO).changeRatingFakeCatcher(_fakeCatcher, -2);
            SuperDAO(addressSuperDAO).changeRatingMedia(_media, 2);
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