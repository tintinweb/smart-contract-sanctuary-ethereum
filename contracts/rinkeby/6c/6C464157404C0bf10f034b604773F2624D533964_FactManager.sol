// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "Ownable.sol";
import "IERC721Receiver.sol";

contract FactManager is Ownable, IERC721Receiver {
    // Variables for storing contract addresses
    address public addressFactVotingContract;
    address public addressFactMediaContract;

    // Below are media related variables
    enum Status {
        Unconfirmed,
        Confirmed,
        Fake
    }

    struct mediaProfile {
        bool mediaAccreditation;
        int256 mediaRating;
        uint256 mediaBalance;
    }

    struct newsProfile {
        address newsOwner;
        Status newsStatus;
    }

    mapping(address => mediaProfile) public mediaArchive;

    mapping(uint256 => newsProfile) public newsArchive;

    uint256 public mediaDeposit = 0.5 ether;

    // Below are fake hunters related variables
    struct fakeHunterProfile {
        bool fakeHunterAccreditation;
        int256 fakeHunterRating;
        uint256 fakeHunterBalance;
    }

    mapping(address => fakeHunterProfile) public fakeHuntersArchive;

    uint256 public fakeHuntersDeposit = 0.5 ether;

    // FUNCTIONS FOR WORKING WITH MEDIA
    /**
     * @dev This is a payable function for registering media on the site.
     * It does not take any parameters, but for the transaction to be successful, the value must be greater than the deposit threshold.
     */
    function mediaRegistration() public payable {
        require(msg.value >= mediaDeposit, "You need more money!");
        require(
            mediaArchive[msg.sender].mediaRating == 0,
            "You are already registred!"
        );
        require(
            fakeHuntersArchive[msg.sender].fakeHunterRating == 0,
            "You are already fake hunter!"
        );
        mediaProfile storage newMediaProfile = mediaArchive[msg.sender];
        newMediaProfile.mediaAccreditation = true;
        newMediaProfile.mediaRating = 100;
        newMediaProfile.mediaBalance = msg.value;
    }

    /**
     * @dev This is a function for an external contract so that it can receive media information.
     * @param _from The address of the media of interest.
     */
    function getMediaInfo(address _from)
        external
        view
        returns (
            bool,
            int256,
            uint256
        )
    {
        return (
            mediaArchive[_from].mediaAccreditation,
            mediaArchive[_from].mediaRating,
            mediaArchive[_from].mediaBalance
        );
    }

    /**
     * @dev Function to change media rating up or down.
     * @param _address The address of the media of interest.
     * @param delta The value by which the rating will change. May be positive or negative.
     */
    function changeRatingMedia(address _address, int256 delta) external {
        require(msg.sender == addressFactVotingContract);
        mediaArchive[_address].mediaRating += delta;
    }

    /**
     * @dev Function to block media in case of violation of the rules.
     */
    function blockMedia(address _media) public onlyOwner {
        mediaArchive[_media].mediaAccreditation = false;
    }

    /**
     * @dev An external function that can only be called by the media contract.
     * Adds new news to the general archive.
     * @param _mediaAddress The address of the media that released the news.
     * @param _tokenId Token id of the released news
     */
    function addNewsToArchive(address _mediaAddress, uint256 _tokenId)
        external
    {
        require(msg.sender == addressFactMediaContract);
        newsProfile storage newNewsProfile = newsArchive[_tokenId];
        newNewsProfile.newsOwner = _mediaAddress;
        newNewsProfile.newsStatus = Status.Unconfirmed;
    }

    /**
     * @dev Function for external contracts to find out the owner of the news.
     */
    function getNewsOwner(uint256 _tokenId) external view returns (address) {
        return newsArchive[_tokenId].newsOwner;
    }

    /**
     * @dev This function is for assigning the address of a deployed media contract on the network.
     * @param _addressMediaContract Address of the media contract deployed in the network.
     */
    function setAddressFactMediaContract(address _addressMediaContract)
        external
        onlyOwner
    {
        addressFactMediaContract = _addressMediaContract;
    }

    // FUNCTIONS FOR WORKING WITH FAKE HUNTERS
    /**
     * @dev This is a payable function for registering fake hunter on the site.
     * It does not take any parameters, but for the transaction to be successful, the value must be greater than the deposit threshold.
     */
    function fakeHuntersRegistration() public payable {
        require(msg.value >= fakeHuntersDeposit);
        require(
            fakeHuntersArchive[msg.sender].fakeHunterRating == 0,
            "You are already registred!"
        );
        require(
            mediaArchive[msg.sender].mediaRating == 0,
            "You are already media!"
        );
        fakeHunterProfile storage newFakeHunter = fakeHuntersArchive[
            msg.sender
        ];
        newFakeHunter.fakeHunterAccreditation = true;
        newFakeHunter.fakeHunterRating = 100;
        newFakeHunter.fakeHunterBalance = msg.value;
    }

    /**
     * @dev This is a function for an external contract so that it can receive fake hunter information.
     * @param _from The address of the fake hunter of interest.
     */
    function fakeHuntersInfo(address _from)
        external
        view
        returns (
            bool,
            int256,
            uint256
        )
    {
        return (
            fakeHuntersArchive[_from].fakeHunterAccreditation,
            fakeHuntersArchive[_from].fakeHunterRating,
            fakeHuntersArchive[_from].fakeHunterBalance
        );
    }

    /**
     * @dev Function to change fake hunter rating up or down.
     * @param _address The address of the fake hunter of interest.
     * @param delta The value by which the rating will change. May be positive or negative.
     */
    function changeRatingFakeHunter(address _address, int256 delta) external {
        require(msg.sender == addressFactVotingContract);
        fakeHuntersArchive[_address].fakeHunterRating += delta;
    }

    /**
     * @dev Function to block fake hunter in case of violation of the rules.
     */
    function blockFakeHunter(address _fakeHunter) public onlyOwner {
        fakeHuntersArchive[_fakeHunter].fakeHunterAccreditation = false;
    }

    // COMMON FUNCTIONS
    /**
     * @dev This function is for assigning the address of a deployed voting contract on the network.
     * @param _addressFactVotingContract Address of the voting contract deployed in the network.
     */
    function setAddressFactVotingContract(address _addressFactVotingContract)
        external
        onlyOwner
    {
        addressFactVotingContract = _addressFactVotingContract;
    }

    /**
     * @dev A function by which the contract can receive / store news (nft)
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev This is the function that processes the voting results.
     * Changes the rating of the winner and the loser, also distributes the reward among the winners.
     * @param _media Address of the accused media.
     * @param _fakeHunter Address of the initiator of the vote.
     * @param _resultOfVoting Voting result. Truе- Fake News, False - news confirmed.
     * @param _tokenId Token id of the released news.
     */
    function distributionOfAwards(
        address _media,
        address _fakeHunter,
        bool _resultOfVoting,
        uint256 _tokenId
    ) external {
        require(msg.sender == addressFactVotingContract);
        if (_resultOfVoting == true) {
            payable(_fakeHunter).transfer(100000000000000000 * 0.75);
            payable(owner()).transfer(100000000000000000 * 0.15);
            mediaArchive[_media].mediaBalance -= 0.1 ether;
            newsArchive[_tokenId].newsStatus = Status.Fake;
        } else {
            payable(_media).transfer(100000000000000000 * 0.75);
            payable(owner()).transfer(100000000000000000 * 0.15);
            fakeHuntersArchive[_fakeHunter].fakeHunterBalance -= 0.1 ether;
            newsArchive[_tokenId].newsStatus = Status.Confirmed;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}