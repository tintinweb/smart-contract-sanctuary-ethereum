/*
                                          _____          
                                         /\    \         
                                        /::\____\        
                                       /:::/    /        
                                      /:::/    /         
                                     /:::/    /          
                                    /:::/____/           
                                   /::::\    \           
                                  /::::::\    \   _____  
                                 /:::/\:::\    \ /\    \ 
                                /:::/  \:::\    /::\____\
                                \::/    \:::\  /:::/    /
                                 \/____/ \:::\/:::/    / 
                                          \::::::/    /  
                                           \::::/    /   
                                           /:::/    /    
                                          /:::/    /     
                                         /:::/    /      
                                        /:::/    /       
                                        \::/    /        
                                         \/____/                        
                                      _____          
                                     |\    \         
                                     |:\____\        
                                     |::|   |        
                                     |::|   |        
                                     |::|   |        
                                     |::|   |        
                                     |::|   |        
                                     |::|___|______  
                                     /::::::::\    \ 
                                    /::::::::::\____\
                                   /:::/~~~~/~~      
                                  /:::/    /         
                                 /:::/    /          
                                /:::/    /           
                                \::/    /            
                                 \/____/             
                                                               
                                  _____          
        ______                   /\    \         
       |::|   |                 /::\    \        
       |::|   |                /::::\    \       
       |::|   |               /::::::\    \      
       |::|   |              /:::/\:::\    \     
       |::|   |             /:::/__\:::\    \    
       |::|   |            /::::\   \:::\    \   
       |::|   |           /::::::\   \:::\    \  
 ______|::|___|___ ____  /:::/\:::\   \:::\____\ 
|:::::::::::::::::|    |/:::/  \:::\   \:::|    |
|:::::::::::::::::|____|\::/    \:::\  /:::|____|
 ~~~~~~|::|~~~|~~~       \/_____/\:::\/:::/    / 
       |::|   |                   \::::::/    /  
       |::|   |                    \::::/    /   
       |::|   |                     \::/____/    
       |::|   |                      ~~          
       |::|   |                   _____                 
       |::|   |                  /\    \                 
       |::|___|                 /::\    \                    
        ~~                     /::::\    \              
                              /::::::\    \      
                             /:::/\:::\    \     
                            /:::/__\:::\    \    
                           /::::\   \:::\    \   
                          /::::::\   \:::\    \  
                         /:::/\:::\   \:::\    \ 
                        /:::/__\:::\   \:::\____\
                        \:::\   \:::\   \::/    /
                         \:::\   \:::\   \/____/ 
                          \:::\   \:::\    \     
                           \:::\   \:::\____\    
                            \:::\   \::/    /    
                             \:::\   \/____/     
                              \:::\    \         
                               \:::\____\        
                                \::/    /        
                                 \/____/         
                                  _____          
                                 /\    \         
                                /::\    \        
                               /::::\    \       
                              /::::::\    \      
                             /:::/\:::\    \     
                            /:::/__\:::\    \    
                           /::::\   \:::\    \   
                          /::::::\   \:::\    \  
                         /:::/\:::\   \:::\____\ 
                        /:::/  \:::\   \:::|    |
                        \::/   |::::\  /:::|____|
                         \/____|:::::\/:::/    / 
                               |:::::::::/    /  
                               |::|\::::/    /   
                               |::| \::/____/    
                               |::|  ~|          
                               |::|   |          
                               \::|   |          
                                \:|   |          
                                 \|___|                                          
*/
//SPDX-License-Identifier: CC0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

//notloot collection: 0x841e03065558AeE39D6Cb2F751DB964f80E95EE3
contract HyperXP is Ownable, ReentrancyGuard {
    // address: collection address
    mapping(address => bool) public hyperAddresses;

    // address: collection address
    // uint256: id of token in collection
    // returns xp of given token from collection
    mapping(address => mapping(uint256 => uint256)) public xp;

    // maximum xp a token can have
    // can be increased by contract
    uint256 public maxXP; 

    // address: collection address
    // uint256: id of token in collection
    // returns the block of the last Action Point used by given token from collection
    mapping(address => mapping(uint256 => ActionInfo)) public apBlock;
    struct ActionInfo {
        uint128 lastUse; // last time an AP was used
        uint32 apPE;  // AP per epoch
    }
    // address: contract address
    // returns the XP allocated to a given contract
    mapping(address => uint256) public xpAlloc;

    constructor() {
        maxXP = 3000; // level 10
    }

    // 1 ap every 5 minutes. does not stack.
    function availableAP(address collection, uint256 tokenId)
    isHyper(collection)
    public view returns(uint256) {
        return (!hyperAddresses[collection] || (block.timestamp - apBlock[collection][tokenId].lastUse < 5 minutes)) 
        ? 0 
        : 1;
    }

    function useAP(address collection, uint256 tokenId, uint256 amount, address to)
    isHyper(collection)
    isAssetOwner(collection, tokenId)
    external {
        require(amount <= availableAP(collection, tokenId), "not enough AP");
        apBlock[collection][tokenId].lastUse = uint128(block.timestamp);
        xpAlloc[to] += amount * 200; // 200 XP per AP
    }

    function awardXP(address collection, uint256 tokenId, uint256 amount) 
    isHyper(collection)
    external {
        require(amount <= xpAlloc[msg.sender], "not enough XP");
        xpAlloc[msg.sender] -= amount;
        // xp can't go over maxXP
        if (xp[collection][tokenId] + amount > maxXP) {
            xp[collection][tokenId] = maxXP;
        } else {
            xp[collection][tokenId] += amount;
        }
    }

     /// @notice Calculates the level of the specified tokenId from a given collection, defaults to 1
    function getLevel(address collection, uint256 tokenId) 
    public
    view
    returns(uint256) {
        uint256 _xp = xp[collection][tokenId];
        if (_xp < 65) return 1;
        else if (_xp < 70) return 2;
        else {
            return 1 + (sqrt(625+75*_xp)-25)/50; // roughly 15% increase xp per level
        }
    }

    modifier isHyper(address collection) {
        require(hyperAddresses[collection], "not yet in hyper xp");
        _;
    }

    modifier isAssetOwner(address collection, uint256 tokenId) {
        require(IERC721(collection).ownerOf(tokenId) == tx.origin, "you can't perform this action");
        _;
    }

    function _addCollection(address collection) 
    external
    onlyOwner {
        hyperAddresses[collection] = true;
    }

    function _addCollections(address[] calldata collections) 
    external
    onlyOwner {
        for (uint i=0; i < collections.length; i++) {
            hyperAddresses[collections[i]] = true;
        }
    }

    function _removeCollection(address collection) 
    external
    onlyOwner {
        hyperAddresses[collection] = false;
    }

    function _setMaxXP(uint256 amount)
    external
    onlyOwner {
        maxXP = amount;
    }
}

/// @notice Calculates the square root of x, rounding down.
/// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
/// @param x The uint256 number for which to calculate the square root.
/// @return result The result as an uint256.
function sqrt(uint256 x) pure returns (uint256 result) {
    if (x == 0) {
        return 0;
    }

    // Calculate the square root of the perfect square of a power of two that is the closest to x.
    uint256 xAux = uint256(x);
    result = 1;
    if (xAux >= 0x100000000000000000000000000000000) {
        xAux >>= 128;
        result <<= 64;
    }
    if (xAux >= 0x10000000000000000) {
        xAux >>= 64;
        result <<= 32;
    }
    if (xAux >= 0x100000000) {
        xAux >>= 32;
        result <<= 16;
    }
    if (xAux >= 0x10000) {
        xAux >>= 16;
        result <<= 8;
    }
    if (xAux >= 0x100) {
        xAux >>= 8;
        result <<= 4;
    }
    if (xAux >= 0x10) {
        xAux >>= 4;
        result <<= 2;
    }
    if (xAux >= 0x8) {
        result <<= 1;
    }

    // The operations can never overflow because the result is max 2^127 when it enters this block.
    unchecked {
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1; // Seven iterations should be enough
        uint256 roundedDownResult = x / result;
        return result >= roundedDownResult ? roundedDownResult : result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}