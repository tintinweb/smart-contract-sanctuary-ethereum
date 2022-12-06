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



// import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IAnimeMetaverseReward} from "./interfaces/IAnimeMetaverseReward.sol";
import {IAnimeMetaverseNFT} from "./interfaces/IAnimeMetaverseNFT.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error InvalidTokenAmounts();

contract Burner is Ownable, ReentrancyGuard {
    
    IAnimeMetaverseReward public animeMetaverseReward;
    IAnimeMetaverseNFT public animeMetaverseNft;

    uint256 public minboosterTokenTypeCount = 2; // TODO: Should this be updateable ?
    uint256 public requiredcomponentTokenTypeCount = 3; // TODO: Should this be updateable ?

    constructor(
        IAnimeMetaverseReward _animeMetaverseReward,
        IAnimeMetaverseNFT _animeMetaverseNft
    ) Ownable() {
        animeMetaverseReward = _animeMetaverseReward;
        animeMetaverseNft = _animeMetaverseNft;
    }

    event NftMinted(uint256 nftId, uint256[] rewardIDsBurned, address user);
    
    // @dev the contract burns and mints the tokens
    function burnAndMint(uint256[] calldata ids) external nonReentrant {
        
        uint256 boosterTokenTypeCount;
        uint256 componentTokenTypeCount;

        for(uint256 i = 0; i < ids.length; i++) {
            
            uint256 id = ids[i];

            if(id == animeMetaverseReward.BOOSTER_TOKEN_TYPE()) {
                boosterTokenTypeCount++;
            }
            if(id == animeMetaverseReward.COMPONENT_TOKEN_TYPE()) {
                componentTokenTypeCount++;
            }
        }

        if (componentTokenTypeCount != requiredcomponentTokenTypeCount || boosterTokenTypeCount > minboosterTokenTypeCount) {
            revert InvalidTokenAmounts();
        }

        animeMetaverseReward.forceBurn(_msgSender(), animeMetaverseReward.COMPONENT_TOKEN_TYPE(), componentTokenTypeCount);
        if (boosterTokenTypeCount > 0) {
            // save a call!
            animeMetaverseReward.forceBurn(_msgSender(), animeMetaverseReward.BOOSTER_TOKEN_TYPE(), boosterTokenTypeCount);
        }

        uint256 nftId = animeMetaverseNft.totalMinted() + 1;
        animeMetaverseNft.mint(_msgSender());

        emit NftMinted(nftId, ids, _msgSender());

    }

}

/*

// This function is called by contract owner on the reward contract
function setBurnerAddress(
    uint256 tokenType,
    address burner,
    bool _flag
) external onlyOwner validAddress(burner) validTokenType(tokenType) {
    burnerList[tokenType][burner] = _flag;
}


uint256 public constant COMPONENT_TOKEN_TYPE = 4;
uint256 public constant BOOSTER_TOKEN_TYPE = 5;

function forceBurn(address account, uint256 id)
    external
    validAddress(account)
    onlyBurner(id)
{
    _burn(account, id, SUPPLY_PER_TOKENID);
    emit ForceBurn(msg.sender, account, id, SUPPLY_PER_TOKENID);
}


*/

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.16;

interface IAnimeMetaverseNFT {
    function totalMinted() external view returns(uint256);
    function mint(address to) external payable;
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.16;

interface IAnimeMetaverseReward {
    
    function forceBurn(
        address _account,
        uint256 _id,
        uint256 _amount
    ) external;

    function COMPONENT_TOKEN_TYPE() external view returns(uint256);
    function BOOSTER_TOKEN_TYPE() external view returns(uint256);

}