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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.16;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IAnimeMetaverseReward} from "./interfaces/IAnimeMetaverseReward.sol";
import {IAnimeMetaverseGuardians} from "./interfaces/IAnimeMetaverseGuardians.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @notice Error thrown if the tokens being burnt don't have a correct count
error InvalidComponentCount();
/// @notice Error thrown if user is trying to burn a tokenType other than the componentTokenType and boosterTokenType
error InvalidToken();
/// @notice Error thrown if trying to set a zero address
error InvalidAddress();
/// @notice Error thrown if the timestamp being set is invalid
error InvalidTimestamp();

contract Burner is Ownable, ReentrancyGuard {
    address public animeMetaverseRewardAddress;
    // IAnimeMetaverseReward
    address public animeMetaverseGuardiansAddress;
    // IAnimeMetaverseGuardians

    /// @dev max allowed boosterTokenType to burn for minting an NFT
    uint256 public constant MAX_BOOSTER_TOKEN_TYPE_COUNT = 2;
    /// @dev exact required componentTokenType to burn for minting an NFT
    uint256 public constant REQUIRED_COMPONENT_TOKEN_TYPE_COUNT = 3;

    /// @dev component token type lowest id
    uint256 public constant COMPONENT_TOKEN_TYPE_LOWEST_ID = 8;
    /// @dev component token type highest id
    uint256 public constant COMPONENT_TOKEN_TYPE_HIGHEST_ID = 12;

    /// @dev booster token type lowest id
    uint256 public constant BOOSTER_TOKEN_TYPE_LOWEST_ID = 13;
    /// @dev booster token type highest id
    uint256 public constant BOOSTER_TOKEN_TYPE_HIGHEST_ID = 15;

    /// @dev start time for burning rewards and minting NFT
    uint256 public startTime;
    /// @dev end time for burning rewards and minting NFT
    uint256 public endTime;

    /// @dev event emitted when reward tokens successfully burnt and NFT is minted
    event NftMinted(
        uint256 nftIdMinted,
        uint256[] rewardIDsBurned,
        address user
    );

    /// @dev modifier to check valid timestamp
    modifier validTimestamp() {
        uint256 _now = block.timestamp;
        if (_now < startTime || _now > endTime) {
            revert InvalidTimestamp();
        }
        _;
    }

    /// @param _animeMetaverseReward address of animeMetaverseReward contract
    /// @param _animeMetaverseGuardians address of animeMetaverseGuardians contract
    /// @param _startTime start time of this burning contract
    /// @param _endTime end time of this burning contract
    constructor(
        address _animeMetaverseReward,
        address _animeMetaverseGuardians,
        uint256 _startTime,
        uint256 _endTime
    ) Ownable() {
        animeMetaverseRewardAddress = _animeMetaverseReward;
        animeMetaverseGuardiansAddress = _animeMetaverseGuardians;
        startTime = _startTime;
        endTime = _endTime;
    }

    /// @dev burn rewards and mint an NFT
    /// @param rewardTokenIDs list of tokenIDs to burn and hence mint a single NFT
    function burnAndMint(
        uint256[] calldata rewardTokenIDs
    ) external validTimestamp nonReentrant {
        uint256 boosterTokenTypeCount;
        uint256 componentTokenTypeCount;

        for (
            uint256 index = 0;
            index < rewardTokenIDs.length;
            index = _uncheckedInc(index)
        ) {
            uint256 _id = rewardTokenIDs[index];

            if (isBoosterTokenType(_id)) {
                boosterTokenTypeCount++;
            }
            if (isComponentTokenType(_id)) {
                componentTokenTypeCount++;
            }
        }

        if (
            componentTokenTypeCount != REQUIRED_COMPONENT_TOKEN_TYPE_COUNT ||
            boosterTokenTypeCount > MAX_BOOSTER_TOKEN_TYPE_COUNT
        ) {
            revert InvalidComponentCount();
        }

        if (
            componentTokenTypeCount + boosterTokenTypeCount !=
            rewardTokenIDs.length
        ) {
            // some other invalidtoken present
            revert InvalidToken();
        }

        for (
            uint256 index = 0;
            index < rewardTokenIDs.length;
            index = _uncheckedInc(index)
        ) {
            IAnimeMetaverseReward(animeMetaverseRewardAddress).forceBurn(
                _msgSender(),
                rewardTokenIDs[index],
                1
            );
        }

        uint256 nftId = IAnimeMetaverseGuardians(animeMetaverseGuardiansAddress)
            .totalMinted() + 1;
        IAnimeMetaverseGuardians(animeMetaverseGuardiansAddress).mint(
            _msgSender()
        );
        emit NftMinted(nftId, rewardTokenIDs, _msgSender());
    }

    /// @dev this function is used to set AnimeMetaverseRewards contract address
    /// @param contractAddress is the contract address this function takes as input
    function setAnimeMetaverseRewardAddress(
        address contractAddress
    ) external onlyOwner {
        if (contractAddress == address(0)) {
            revert InvalidAddress();
        }
        animeMetaverseRewardAddress = contractAddress;
    }

    /// @dev this function is used to set AnimeMetaverseGuardians contract address
    /// @param contractAddress is the contract address this function takes as input
    function setAnimeMetaverseGuardians(
        address contractAddress
    ) external onlyOwner {
        if (contractAddress == address(0)) {
            revert InvalidAddress();
        }
        animeMetaverseGuardiansAddress = contractAddress;
    }

    /// @dev used to set start and end time
    /// @notice can only be called by the owner
    /// @param _startTime the start time
    /// @param _endTime the end time
    function setStartEndTime(
        uint256 _startTime,
        uint256 _endTime
    ) external onlyOwner {
        uint256 _now = block.timestamp;
        if (_now > _endTime) {
            revert InvalidTimestamp();
        }
        if (_startTime >= _endTime) {
            revert InvalidTimestamp();
        }
        startTime = _startTime;
        endTime = _endTime;
    }

    /// @dev this method is used to check if the given tokenID is of component type
    /// @param tokenID the tokenID to check if it is componentType or not
    function isComponentTokenType(uint256 tokenID) private pure returns (bool) {
        return
            tokenID >= COMPONENT_TOKEN_TYPE_LOWEST_ID &&
            tokenID <= COMPONENT_TOKEN_TYPE_HIGHEST_ID;
    }

    /// @dev this method is used to check if the given tokenID is of booster type
    /// @param tokenID the tokenID to check if it is boosterType or not
    function isBoosterTokenType(uint256 tokenID) private pure returns (bool) {
        return
            tokenID >= BOOSTER_TOKEN_TYPE_LOWEST_ID &&
            tokenID <= BOOSTER_TOKEN_TYPE_HIGHEST_ID;
    }

    /// @dev Unchecked increment function, just to reduce gas usage
    /// @return incremented value
    function _uncheckedInc(uint256 val) private pure returns (uint256) {
        unchecked {
            return val + 1;
        }
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.16;

interface IAnimeMetaverseGuardians {
    function totalMinted() external view returns (uint256);

    function mint(address to) external payable;
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.15;

interface IAnimeMetaverseReward {
    function forceBurn(
        address _account,
        uint256 _id,
        uint256 _amount
    ) external;
}