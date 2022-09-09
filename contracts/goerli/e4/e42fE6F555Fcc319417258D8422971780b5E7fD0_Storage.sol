// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.16;

import "./ISBT.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Storage is Ownable {
    enum TransferType {
        UPVOTE,
        DOWNVOTE
    }

    struct Relationship {
        int256 karmaAmount; // if bigger than 0 - user mostly upvoted him
        int16 relationshipRating; // more upvotes - more bounds
    }

    struct User {
        bool isInitialized;
        uint256 userId;
        int256 karma; // should be between +10 and -10
        mapping(address => Relationship) outgoing;
        mapping(address => Relationship) ingoing;
    }

    // storages
    mapping(address => bool) public hasSBT;
    mapping(address => User) public users;
    // allows to add multiple SBT tokens from different KYC providers
    mapping(ISBT => bool) public supportedContracts;

    modifier isSoulbounded() {
        require(hasSBT[msg.sender], "Storage: User is not soulbounded");
        _;
    }

    function addSBT(ISBT sbt) external onlyOwner {
        supportedContracts[sbt] = true;
    }

    function createUser(ISBT sbt) external {
        require(supportedContracts[sbt], "Storage: Contract not supported");
        require(
            sbt.tokenOf(msg.sender) != 0,
            "Storage: User does not have a KYC"
        );
        hasSBT[msg.sender] = true;
        User storage user = users[msg.sender];
        require(!user.isInitialized, "Storage: User has been initialized");
        user.isInitialized = true;
        user.karma = 100; // + 100
    }

    function sendKarma(
        address to,
        int16 amount,
        TransferType transfer
    ) external isSoulbounded {
        User storage user = users[msg.sender];
        require(
            amount < 1000 && amount > -1000,
            "Storage: Invalid karma value"
        );
        require(user.karma >= amount, "Storage: Insufficient karma");

        if (transfer == TransferType.UPVOTE) {
            _upvote(user, to, amount);
        } else {
            _downvote(user, to, amount);
        }
    }

    function getUserKarma(address user) external view returns (int256) {
        require(user != address(0), "Storage: Invalid address");
        return users[user].karma; 
    }

    function _upvote(
        User storage user,
        address to,
        int16 amount
    ) internal {
        User storage receiver = users[to];
        (int256 transferKarma, int16 transferRating) = _calculateTransfer(
            user.karma,
            receiver.karma,
            user.outgoing[to].relationshipRating,
            amount
        );
        user.karma -= amount;
        unchecked {
            receiver.karma += transferKarma;        
        }
        int16 relationshipRating = user.outgoing[to].relationshipRating + transferRating;
        user.outgoing[to].relationshipRating = relationshipRating; 
        receiver.ingoing[msg.sender].relationshipRating = relationshipRating;
    }

    function _downvote(
        User storage user,
        address to,
        int16 amount
    ) internal {
        User storage receiver = users[to];
          (int256 transferKarma, int16 transferRating) = _calculateTransfer(
            user.karma,
            receiver.karma,
            user.outgoing[to].relationshipRating,
            amount
        );

        receiver.karma -= transferKarma;        
        int16 relationshipRating = user.outgoing[to].relationshipRating + transferRating;
        user.outgoing[to].relationshipRating = relationshipRating; 
        receiver.ingoing[msg.sender].relationshipRating = relationshipRating;
    }

    function _calculateTransfer(
        int256 senderKarma,
        int256 receiverKarma,
        int256 bonding,
        int16 amount
    ) internal pure returns (int256 karma, int16 rating) {
        (int256 biggestKarma, int256 smallestKarma) = (senderKarma >
            receiverKarma)
            ? (senderKarma, receiverKarma)
            : (receiverKarma, senderKarma);
        int256 difference = biggestKarma - smallestKarma;
        int256 weightedKarma = (bonding * amount) / difference;

        if (weightedKarma > 5) {
            weightedKarma = 5;
        } else if (weightedKarma < 5) {
            weightedKarma = -5; 
        }
        
        if (senderKarma == biggestKarma) {
            karma = amount - weightedKarma;
        } else {
            karma = amount + weightedKarma;
        }

        rating = amount / 10;
    }
}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.8.16;

interface ISBT {
    function tokenOf(address owner) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

    function tokenURI(uint256 tokenId) external view returns (string memory);
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