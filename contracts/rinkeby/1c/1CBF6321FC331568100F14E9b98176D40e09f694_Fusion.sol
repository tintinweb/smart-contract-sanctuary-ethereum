/**
 *Submitted for verification at Etherscan.io on 2022-06-26
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/IERC165.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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

// File: contracts/fusionNFTInterface.sol



pragma solidity ^0.8.0;



interface fusionNFTInterface is IERC721 {
    function mint(address nftid, uint256 tokenId, uint256 fusionLevel, uint256 tier) external returns(uint256);
}
// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: contracts/fusion.sol

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;






contract Fusion is Ownable, ReentrancyGuard {

    IERC20 public token;
    address public nft;
    address public fusionNFT;

    struct TierLevels {
        uint256 tier;
        uint256 level1; //nfts for fusion
        uint256 level2;
        uint256 level3;
        uint256 level4;
        uint256 level5;
        uint256 lvl1MaxMints; // max possible amount of mints for this level of tier
        uint256 lvl2MaxMints;
        uint256 lvl3MaxMints;
        uint256 lvl4MaxMints;
        uint256 lvl5MaxMints;
    }
    

    // if nft address is external then fusion level = 0
    // if nft address is fusionNFT.sol the fusion level >= 1 && <=5
    mapping(uint256 => uint256) private fusionNFTidToLevel;
    mapping(uint256 => TierLevels) private tierToLevels;
    mapping(string => mapping(uint256 => mapping(uint256 => uint256))) public nameToTierToLevelToMintCounter; // tierToLevelToMintCounter["pepe"][1][2] = 0, pepe, tier 1 level 2 counter is 0

    address private dead = 0x000000000000000000000000000000000000dEaD;

    mapping (string => tierArray) nameToTiers;
    mapping (uint256 => uint256) tierToTokens;

    struct tierArray {
        uint256[5000] tier1;  //common
        uint256[2500] tier2;  //special
        uint256[500] tier3;   //epic
        uint256[50] tier4;    //legendary
        uint256 tier5;        //unique
        bool initialized;     //if struct for player has been created already
    }

    event Fused(address indexed owner, uint256[] indexed ids);

    constructor (IERC20 erc20, address _nft) {
        token = erc20;
        nft = _nft;

        tierTokensInit();
        initTierLevels();
    }

    function compareTiers(uint256[] memory _tiers) private pure returns(bool) {
        uint256 baseTier = _tiers[0];
        for(uint256 i = 0; i < _tiers.length; i++) {
            if(baseTier != _tiers[i])
                return false;
        }
        return true;
    }

    function compareNames(string[] memory names) private pure returns(bool) {
        string memory baseName = names[0];
        for(uint256 i = 0; i < names.length; i++) {
            if(keccak256(abi.encodePacked(baseName)) != keccak256(abi.encodePacked(names[i])))
                return false;
        }
        return true;
    }

    // fuse your nfts
    function fuse(address nftAddress, uint256[] memory tokenIds, string[] memory names, uint256 amt) external nonReentrant() {
        require(nftAddress == nft || nftAddress == fusionNFT, "Address not accepted");
        require(tokenIds.length == names.length, "Lengths do not match");
        require(tokenIds.length >= 2 && tokenIds.length <= 5, "Cant fuse only 1 ERC721 or more than 5");        
        for(uint256 i = 0; i < tokenIds.length; i++) {
            require(tokenIds[i] > 0, "NFT does not exist");
            require(IERC721(nftAddress).ownerOf(tokenIds[i]) == msg.sender, "Not owner of NFTs");
            //require(getTier(tokenIds[i], names[i]) != 666, "Tier from nfts not found");
            IERC721(nftAddress).safeTransferFrom(msg.sender, dead, tokenIds[i]);
        }
        /*uint256[] memory _tiers = new uint256[](tokenIds.length);
        for(uint256 i = 0; i < tokenIds.length; i++) {
            _tiers[i] = getTier(tokenIds[i], names[i]);
        }
        require(compareTiers(_tiers) && compareNames(names), "Tiers or names do not match");
*/
        uint256 indexToStore; // index from deleted tier position of burned nfts, to store the new fused nft

        uint256 tmpTier = getTier(tokenIds[0], names[0]);
        if(tmpTier == 1) {
            require(tokenIds.length == tierToLevels[tmpTier].level1, "Wrong amount of nfts for fusion");
            for(uint256 i = 0; i < tokenIds.length; i++) {
                if(i == 0) {
                    indexToStore = getTier1Index(tokenIds[i], names[0]);
                }
                delete nameToTiers[names[0]].tier1[getTier1Index(tokenIds[i], names[0])];
            }
        }
        else if(tmpTier == 2) {
            require(tokenIds.length == tierToLevels[tmpTier].level2, "Wrong amount of nfts for fusion");
            for(uint256 i = 0; i < tokenIds.length; i++) {
                if(i == 0) {
                    indexToStore = getTier2Index(tokenIds[i], names[0]);
                }
                delete nameToTiers[names[0]].tier2[getTier2Index(tokenIds[i], names[0])];
            }
        }
        else if(tmpTier == 3) {
            require(tokenIds.length == tierToLevels[tmpTier].level3, "Wrong amount of nfts for fusion");
            for(uint256 i = 0; i < tokenIds.length; i++) {
                if(i == 0) {
                    indexToStore = getTier3Index(tokenIds[i], names[0]);
                }
                delete nameToTiers[names[0]].tier3[getTier3Index(tokenIds[i], names[0])];
            }
        }
        else if(tmpTier == 4) {
            require(tokenIds.length == tierToLevels[tmpTier].level4, "Wrong amount of nfts for fusion");
            for(uint256 i = 0; i < tokenIds.length; i++) {
                if(i == 0) {
                    indexToStore = getTier4Index(tokenIds[i], names[0]);
                }
                delete nameToTiers[names[0]].tier4[getTier4Index(tokenIds[i], names[0])];
            }
        }
        else if(tmpTier == 5) {
            require(tokenIds.length == tierToLevels[tmpTier].level5, "Wrong amount of nfts for fusion");
            for(uint256 i = 0; i < tokenIds.length; i++) {
                if(i == 0) {
                    indexToStore = 0;
                }
                delete nameToTiers[names[0]].tier5;
            }
        }

        require(indexToStore != 5001, "5001 error");


        //make sure all tokens have the same fusion level

        uint256 fusionLevel;
        if(nftAddress == nft) { // if nfts to fuse are from the base nft contract and not fusionNFT, it means all nfts are level 0(default)
            fusionLevel = 0;
        }
        else {
            fusionLevel = getFusionLevel(tokenIds[0]);
            for(uint i = 1; i < tokenIds.length; i++) {
                require(fusionLevel == getFusionLevel(tokenIds[i]), "Fusion levels of ERC721 tokens must be the same");
            }
        }
        require(fusionLevel + 1 <= 5, "Can not fuse more than 5 levels");

        require(amt >= tierToTokens[1], "Token amount less than fuse amount");
        require(token.allowance(msg.sender, address(this)) >= amt, "Tokens not allowed to spend, allow first");
        require(token.transferFrom(msg.sender, address(this), amt), "Transfer failed");


        if(fusionLevel + 1 == 1) {
            require(nameToTierToLevelToMintCounter[names[0]][1][fusionLevel + 1] + 1 <  tierToLevels[1].lvl1MaxMints, "Fuse mints level 1 reached cap");   
        } 
        else if(fusionLevel + 1 == 2) {
            require(nameToTierToLevelToMintCounter[names[0]][1][fusionLevel + 1] + 1 <  tierToLevels[1].lvl2MaxMints, "Fuse mints level 2 reached cap");   
        } 
        else if(fusionLevel + 1 == 3) {
            require(nameToTierToLevelToMintCounter[names[0]][1][fusionLevel + 1] + 1 <  tierToLevels[1].lvl3MaxMints, "Fuse mints level 3  reached cap");   
        } 
        else if(fusionLevel + 1 == 4) {
            require(nameToTierToLevelToMintCounter[names[0]][1][fusionLevel + 1] + 1 <  tierToLevels[1].lvl4MaxMints, "Fuse mints level 4 reached cap");   
        } 
        else if(fusionLevel + 1 == 5) {
            require(nameToTierToLevelToMintCounter[names[0]][1][fusionLevel + 1] + 1 <  tierToLevels[1].lvl5MaxMints, "Fuse mints level 5 reached cap");   
        }

        address _nftid;
        if(nftAddress == nft) 
            _nftid = nft;
        else 
            _nftid = address(0);

        nameToTierToLevelToMintCounter[names[0]][1][fusionLevel + 1]++;
        uint256 newFusionId = fusionNFTInterface(fusionNFT).mint(_nftid, tokenIds[0], fusionLevel + 1, 1);
        //update tier for new minted token
        if(tmpTier == 1) {
            nameToTiers[names[0]].tier1[indexToStore] = newFusionId;
        }
        else if(tmpTier == 2) {
            nameToTiers[names[0]].tier2[indexToStore] = newFusionId;
        }
        else if(tmpTier == 3) {
            nameToTiers[names[0]].tier3[indexToStore] = newFusionId;
        }
        else if(tmpTier == 4) {
            nameToTiers[names[0]].tier4[indexToStore] = newFusionId;
        }
        else {
            nameToTiers[names[0]].tier5 = newFusionId;
        }
        setFusionLevel(newFusionId, fusionLevel + 1);
        emit Fused(msg.sender, tokenIds);
    }

    function initTierLevels() private {
        tierToLevels[1] = TierLevels(1, 5, 5, 4, 4, 3, 1000, 200, 50, 12, 4);
        tierToLevels[2] = TierLevels(2, 4, 4, 4, 3, 3, 625, 156, 39, 13, 4);
        tierToLevels[3] = TierLevels(3, 3, 3, 3, 2, 2, 166, 55, 18, 9, 4);
        tierToLevels[4] = TierLevels(4, 2, 2, 2, 2, 2, 25, 12, 6, 3, 1);
    }

    function getTier(uint256 tokenId, string memory name) public view returns(uint256) {
        if(checkTier5(tokenId, name)) {
            return 5;
        } else if(checkTier4(tokenId, name)) {
            return 4;
        } else if(checkTier3(tokenId, name)) {
            return 3;
        } else if(checkTier2(tokenId, name)) {
            return 2;
        } else if(checkTier1(tokenId, name)) {
            return 1;
        }
        else {
            return 666;
        }
    }

    // these 2 functions are for already fused nfts, minted from fusionNFT.sol contract
    function setFusionLevel(uint256 fusedNFTtokenId, uint256 level) private {
        fusionNFTidToLevel[fusedNFTtokenId] = level;
    }

    function getFusionLevel(uint256 fusedNFTtokenId) public view returns(uint256) {
        return fusionNFTidToLevel[fusedNFTtokenId];
    }

    function checkTier1(uint256 tokenId, string memory name) public view returns(bool) {
        for(uint256 i = 0; i < 5000; i++) {
            if(nameToTiers[name].tier1[i] == tokenId){
                return true;
            }

        }
        return false;
    }

    function getTier1Index(uint256 tokenId, string memory name) public view returns(uint256) {
        for(uint256 i = 0; i < 5000; i++) {
            if(nameToTiers[name].tier1[i] == tokenId){
                return i;
            }
        }
        return 5001;
    }
        

    function checkTier2(uint256 tokenId, string memory name) public view returns(bool) {
        for(uint256 i = 0; i < 2500; i++) {
            if(nameToTiers[name].tier2[i] == tokenId){
                return true;
            }

        }
        return false;
    }

    function getTier2Index(uint256 tokenId, string memory name) public view returns(uint256) {
        for(uint256 i = 0; i < 5000; i++) {
            if(nameToTiers[name].tier2[i] == tokenId){
                return i;
            }
        }
        return 5001;
    }

    function checkTier3(uint256 tokenId, string memory name) public view returns(bool) {
        for(uint256 i = 0; i < 500; i++) {
            if(nameToTiers[name].tier3[i] == tokenId){
                return true;
            }

        }
        return false;
    }

    function getTier3Index(uint256 tokenId, string memory name) public view returns(uint256) {
        for(uint256 i = 0; i < 5000; i++) {
            if(nameToTiers[name].tier3[i] == tokenId){
                return i;
            }
        }
        return 5001;
    }

    function checkTier4(uint256 tokenId, string memory name) public view returns(bool) {
        for(uint256 i = 0; i < 50; i++) {
            if(nameToTiers[name].tier4[i] == tokenId){
                return true;
            }
        }
        return false;
    }

    function getTier4Index(uint256 tokenId, string memory name) public view returns(uint256) {
        for(uint256 i = 0; i < 5000; i++) {
            if(nameToTiers[name].tier4[i] == tokenId){
                return i;
            }
        }
        return 5001;
    }

    function checkTier5(uint256 tokenId, string memory name) public view returns(bool) {
        return(nameToTiers[name].tier5 == tokenId);
    }

    function withdraw() external onlyOwner() {
        require(token.balanceOf(address(this)) > 0, "Zero value");
        token.transfer(owner(), token.balanceOf(address(this)));
    }
    
    function tierTokensInit() internal {
        tierToTokens[1] = 100 * (10**18); 
        tierToTokens[2] = 1000 * (10**18); 
        tierToTokens[3] = 10000 * (10**18); 
        tierToTokens[4] = 100000 * (10**18);
        tierToTokens[5] = 1000000 * (10**18); 
    }

    function editTierTokens(uint256 t1, uint256 t2, uint256 t3, uint256 t4, uint256 t5) external onlyOwner() {
        tierToTokens[1] = t1 * (10**18);    // tier1
        tierToTokens[2] = t2 * (10**18);    // tier2
        tierToTokens[3] = t3 * (10**18);    // tier3
        tierToTokens[4] = t4 * (10**18);    // tier4
        tierToTokens[5] = t5 * (10**18);    // tier5
    }

    // k is in control of what part of the tier array will be returned
    // the array is "split" in 5 parts of 1000 ids because of gas limit per tx
    // and k controls wich part of the 5000 array elements will be returned
    // so if k = 0, function will return the first 0 - 500, if k = 1 it will return the second 500 elements (500 - 999)
    // k should be >= 0 and < 5
    function showNameTierOneWithK(string memory name, uint256 k) public view returns(uint256[500] memory) {
        uint256[500] memory _tier1;
        require(k >= 0 && k < 10, "Wrong k values");
        uint256 i = 500;
        uint256 limit = 0;
        uint256 j = 0;
        // i = 500, so if k = 0 then i * k = 500 * 0 = 0 will start checking the first 500 elements from array[0]
        i = i * k;
        limit = i + 500;


        for(; i < limit; i++) {
            _tier1[j] = nameToTiers[name].tier1[i];
            j++;
        }

        return _tier1;
    }

    // tier 2 has 2500 array elements for each player
    // function call is split in 500 elements per call
    function showNameTierTwoWithK(string memory name, uint256 k) public view returns(uint256[500] memory) {
        uint256[500] memory _tier2;
        require(k >= 0 && k < 5, "Wrong k values");
        uint256 i = 500;
        uint256 limit = 0;
        uint256 j = 0;
        i = i * k;
        limit = i + 500;


        for(; i < limit; i++) {
            _tier2[j] = nameToTiers[name].tier2[i];
            j++;
        }

        return _tier2;
    }

    // tier 3 has 500 array elements for each player
    function showNameTierThreeWithK(string memory name) public view returns(uint256[500] memory) {
        uint256[500] memory _tier3;
        uint256 i = 500;
        uint256 j = 0;

        for(; i < 500; i++) {
            _tier3[j] = nameToTiers[name].tier3[i];
            j++;
        }

        return _tier3;
    }

    function showNameTierFour(string memory name) public view returns(uint256[50] memory) {
        uint256[50] memory _tier4;
        uint256 j = 0;

        for(uint i = 0; i < 50; i++) {
            _tier4[j] = nameToTiers[name].tier4[i];
            j++;
        }

        return _tier4;
    }

    function showNameTierFive(string memory name) public view returns (uint256) {
        return nameToTiers[name].tier5;
    }

    // i indicates from which point the array should start filling
    function fillTierOneWithi(string memory name, uint256[] memory _tier1, uint256 i) external onlyOwner() {
        if(nameToTiers[name].initialized == false) {
            uint256[5000] memory tier1;
            uint256[2500] memory tier2;
            uint256[500] memory tier3;
            uint256[50] memory tier4;
                                
            tierArray memory Tierarray = tierArray(tier1, tier2, tier3, tier4, 0, true);
            nameToTiers[name] = Tierarray;
        }

        uint256 initial_i = i;
        uint256 j = 0;

        require(i + _tier1.length <= 5000, "Wrong values");

        for(; i < initial_i + _tier1.length; i++) {
            nameToTiers[name].tier1[i] = _tier1[j]; 
            j++;
        }
    }
    
    function fillTierTwoWithi(string memory name, uint256[] memory _tier2, uint256 i) external onlyOwner() {
        if(nameToTiers[name].initialized == false) {
            uint256[5000] memory tier1;
            uint256[2500] memory tier2;
            uint256[500] memory tier3;
            uint256[50] memory tier4;
                                
            tierArray memory Tierarray = tierArray(tier1, tier2, tier3, tier4, 0, true);
            nameToTiers[name] = Tierarray;
        }

        uint256 initial_i = i;
        uint256 j = 0;

        require(i + _tier2.length <= 2500, "Wrong values");

        for(; i < initial_i + _tier2.length; i++) {
            nameToTiers[name].tier2[i] = _tier2[j];
            j++; 
        }
    }

    function fillTierThreeWithi(string memory name, uint256[] memory _tier3, uint256 i) external onlyOwner() {
        if(nameToTiers[name].initialized == false) {
            uint256[5000] memory tier1;
            uint256[2500] memory tier2;
            uint256[500] memory tier3;
            uint256[50] memory tier4;
                                
            tierArray memory Tierarray = tierArray(tier1, tier2, tier3, tier4, 0, true);
            nameToTiers[name] = Tierarray;
        }

        uint256 initial_i = i;
        uint256 j = 0;

        require(i + _tier3.length <= 500, "Wrong values");

        for(; i < initial_i + _tier3.length; i++) {
            nameToTiers[name].tier3[i] = _tier3[j]; 
            j++;
        }
    }

    function fillTierFourWithi(string memory name, uint256[] memory _tier4, uint256 i) external onlyOwner() {
        if(nameToTiers[name].initialized == false) {
            uint256[5000] memory tier1;
            uint256[2500] memory tier2;
            uint256[500] memory tier3;
            uint256[50] memory tier4;
                                
            tierArray memory Tierarray = tierArray(tier1, tier2, tier3, tier4, 0, true);
            nameToTiers[name] = Tierarray;
        }

        uint256 initial_i = i;
        uint256 j = 0;

        require(i + _tier4.length <= 50, "Wrong values");

        for(; i < initial_i + _tier4.length; i++) {
            nameToTiers[name].tier4[i] = _tier4[j]; 
            j++;
        }
    }

    function fillTierFive(string memory name, uint256 _tier5) external onlyOwner() {
        if(nameToTiers[name].initialized == false) {
            uint256[5000] memory tier1;
            uint256[2500] memory tier2;
            uint256[500] memory tier3;
            uint256[50] memory tier4;
                                
            tierArray memory Tierarray = tierArray(tier1, tier2, tier3, tier4, _tier5, true);
            nameToTiers[name] = Tierarray;
        }

        nameToTiers[name].tier5 = _tier5;
    }

    function setFusionNFT(address adr) external onlyOwner() {
        fusionNFT = adr;
    }

    function setToken(address adr) external onlyOwner() {
        token = IERC20(adr);
    }

    function setNFT(address adr) external onlyOwner() {
        nft = adr;
    }
/*
    function getTierToLevels(uint256 tier) external view returns(
    uint256, uint256, uint256, uint256, uint256, uint256,
    uint256, uint256, uint256, uint256, uint256) {
        return (tierToLevels[tier].tier , tierToLevels[tier].level1 , tierToLevels[tier].level2 , tierToLevels[tier].level3 ,
        tierToLevels[tier].level4 , tierToLevels[tier].level5 , tierToLevels[tier].lvl1MaxMints , tierToLevels[tier].lvl2MaxMints,
        tierToLevels[tier].lvl3MaxMints , tierToLevels[tier].lvl4MaxMints , tierToLevels[tier].lvl5MaxMints);
    }*/

    function findTheFuckingError(address nftAddress, uint256[] memory tokenIds, string[] memory names) external {
        for(uint256 i = 0; i < tokenIds.length; i++) {
            require(tokenIds[i] > 0, "NFT does not exist");
            require(IERC721(nftAddress).ownerOf(tokenIds[i]) == msg.sender, "Not owner of NFTs");
            require(getTier(tokenIds[i], names[i]) != 666, "Tier from nfts not found");
            IERC721(nftAddress).safeTransferFrom(msg.sender, dead, tokenIds[i]);
        }
    }
}