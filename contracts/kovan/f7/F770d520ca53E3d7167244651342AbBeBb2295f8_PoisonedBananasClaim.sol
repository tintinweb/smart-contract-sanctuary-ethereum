// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract IPoisonedBananas {
     function mintSingle(uint256 bananaType, address to) external {}
     function mintMultiple(uint256[] memory bananaTypes, uint256[] memory amounts, address to) external {}
}


contract PoisonedBananasClaim is Ownable {

    /**
     * @dev EXTERNAL ADDRESSES
     */
    IERC721 public primeApeNFT;
    IPoisonedBananas public bananas;
    
    /** 
     * @dev GENERAL DATA 
     */
    uint256 public maxSupply = 7979;
    uint256 public lvl1Supply = 5000;
    uint256 public lvl2Supply = 2965;
    uint256 public lvl3Supply = 14;

    uint256 public lvl2Odds = 3;
    uint256 public lvl3Odds = 570;

    /**
     * @dev CLAIM DATA
     */
    uint256 seed;
    mapping(uint256 => bool) public apeToClaimed;
    mapping(uint256 => uint256) public levelToClaimed;

    /**
     * @dev MINT DATA
     */
    uint256 public holderPrice = 0.07979 ether;
    uint256 public price = 0.15 ether;
    uint256 public minted;
    uint256 public mintMaxAmount = 1;
    bool public isHolderSale;
    bool public isSale;
    mapping(address => uint256) public addressToHolderMint;
    mapping(address => uint256) public addressToMints;
    
    /**
     * @dev Events
     */
    
    /**
     * @dev Setter events.
     */
    event setPriceEvent(uint256 indexed price);
    event setMaxSupplyEvent(uint256 indexed maxSupply);

    /**
     * @dev Sale events.
     */
    event Purchase(address indexed buyer, uint256 indexed amount);
    event ReceivedEther(address indexed sender, uint256 indexed amount);
    event WithdrawAllEvent(address indexed to, uint256 amount);

    constructor(
        address _ape,
        address _banana
    ) Ownable() {
        require(lvl1Supply + lvl2Supply + lvl3Supply == maxSupply, "Supply not correct");

        primeApeNFT = IERC721(_ape);
        bananas = IPoisonedBananas(_banana);
    }

    /**
     * @dev HELPERS
     */

    /**
     * @dev returns the bananas supply that is left.
     */
    function supplyLeft() public view returns (uint256) {
        return maxSupply - minted;
    }

    /**
     * @dev given an array of apeIds see which ones can still
     * claim their banana.
     *
     * @param apeIds. The ape ids.
     */
    function getNotClaimedApes(uint256[] calldata apeIds) external view returns(uint256[] memory) {
        require(apeIds.length > 0, "No IDS supplied");

        uint256 length = apeIds.length;
        uint256[] memory notClaimedApes = new uint256[](length);
        uint256 counter;

        /// @dev Check if sender is owner of all apes and that they haven't claimed yet
        /// @dev Update claim status of each ape
        for (uint256 i = 0; i < apeIds.length; i++) {
            uint256 apeId = apeIds[i];         
            if (!apeToClaimed[apeId]) {
                notClaimedApes[counter] = apeId;
                counter++;
            }
        }

        return notClaimedApes;
    }

    /**
     * @dev Psuedo-random number generator used to
     * determine which banana type an ape gets.
     */
    function getRandomNumber(address _addr, uint256 apeId) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(blockhash(block.number), block.timestamp, seed, _addr, apeId)));
    }

    function getBananaLevelForClaim(address claimer, uint256 claimingApeId) internal view returns (uint256) {
        uint256 rng = getRandomNumber(claimer, claimingApeId);

        bool isLvl3 = rng % lvl3Odds == 0;
        bool isLvl2 = rng % lvl2Odds == 0;
        bool isLvl1 = !isLvl3 && !isLvl2;

        bool isLvl3Full = levelToClaimed[2] >= lvl3Supply;
        bool isLvl2Full = levelToClaimed[1] >= lvl2Supply;
        bool isLvl1Full = levelToClaimed[0] >= lvl1Supply;

        if (isLvl3) {
            if (!isLvl3Full)
                return 2;
            else if (!isLvl2Full)
                return 1;
            else if (!isLvl1Full)
                return 0;
        }

        if (isLvl2) {
            if (!isLvl2Full)
                return 1;
            else if (!isLvl1Full)
                return 0;
            else if (!isLvl2Full)
                return 2;
        }

        if (isLvl1) {
            if (!isLvl1Full)
                return 0;
            else if (!isLvl2Full)
                return 1;
            else if (!isLvl3Full)
                return 2;
        }

        //should not get to this
        revert("Logic error");
    }

    /**
     * @dev CLAIMING
     */
    
    /**
     * @dev Claims bananas to sender for each valid ape Id.
     *
     * @param apeIds. The ape Ids.
     */
    function claimBananas(uint256[] calldata apeIds) external {
        require(address(bananas) != address(0), "Banana contract not set");
        require(address(primeApeNFT) != address(0), "Ape contract not set");
        require(apeIds.length > 0, "No Ids supplied");
        require(!isSale && !isHolderSale, "Claiming stopped");

        uint256[] memory bananaTypes = new uint256[](apeIds.length);
        uint256[] memory amounts = new uint256[](apeIds.length);

        /// @dev Check if sender is owner of all apes and that they haven't claimed yet
        /// @dev Update claim status of each ape
        for (uint256 i = 0; i < apeIds.length; i++) {
            uint256 apeId = apeIds[i];
            require(primeApeNFT.ownerOf(apeId) == msg.sender, "Sender does not own ape");
            require(!apeToClaimed[apeId], "Ape already claimed banana");
            apeToClaimed[apeId] = true;

            uint256 bananaType = getBananaLevelForClaim(msg.sender, apeId);
            levelToClaimed[bananaType]++;

            bananaTypes[i] = bananaType;
            amounts[i] = 1;
        }

        minted += apeIds.length;
        bananas.mintMultiple(bananaTypes, amounts, msg.sender);
    }
    
    /**
     * @dev Claims banana to sender for ape Id.
     *
     * @param apeId. The ape Id.
     */
    function claimBanana(uint256 apeId) external {
        require(address(bananas) != address(0), "Banana contract not set");
        require(address(primeApeNFT) != address(0), "Ape contract not set");
        require(!isSale && !isHolderSale, "Claiming stopped");

        require(primeApeNFT.ownerOf(apeId) == msg.sender, "Sender does not own ape");
        require(!apeToClaimed[apeId], "Ape already claimed banana");
        apeToClaimed[apeId] = true;

        uint256 bananaType = getBananaLevelForClaim(msg.sender, apeId);
        levelToClaimed[bananaType]++;

        minted++;
        bananas.mintSingle(bananaType, msg.sender);
    }

    /**
     * @dev SALE
     */

    /**
     * @dev Allows unclaimed bananas to be sold to holders
     */
    function buyBananasHolders() 
        external 
        payable {
        uint256 amount = 1;

        require(addressToHolderMint[msg.sender] == 0, "Can only buy one additional banana");
        require(minted + amount <= maxSupply, "Mint amount goes over max supply");
        require(msg.value >= holderPrice, "Ether sent not correct");
        require(isHolderSale, "Sale not started"); 

        addressToHolderMint[msg.sender] = 1;

        uint256 bananaType = getBananaLevelForClaim(msg.sender, minted);
        levelToClaimed[bananaType]++;

        minted++;
        bananas.mintSingle(bananaType, msg.sender);       

        emit Purchase(msg.sender, amount);
    }

    /**
     * @dev Allows unclaimed bananas to be sold to the public
     *
     * @param amount. The amount of bananas to be sold
     */
    function buyBananas(uint256 amount) 
        external 
        payable {
        
        require(amount > 0, "Have to buy more than 0");

        require(addressToMints[msg.sender] + amount <= mintMaxAmount, "Mint amount exceeds max for user");
        require(minted + amount <= maxSupply, "Mint amount goes over max supply");
        require(msg.value >= price * amount, "Ether sent not correct");
        require(isSale, "Sale not started"); 
        /// @dev Updates contract variables and mints `amount` NFTs to users wallet

        addressToMints[msg.sender] += amount;

        uint256[] memory bananaTypes = new uint256[](amount);
        uint256[] memory amounts = new uint256[](amount);

        for (uint256 i = 0; i < amount; i++) {
            uint256 bananaType = getBananaLevelForClaim(msg.sender, minted + i);
            levelToClaimed[bananaType]++;

            bananaTypes[i] = bananaType;
            amounts[i] = 1;
        }

        minted += amount;
        bananas.mintMultiple(bananaTypes, amounts, msg.sender);    

        emit Purchase(msg.sender, amount);
    }

    /** 
     * @dev OWNER ONLY 
     */

    function setIsSale(bool _isSale) external onlyOwner {
        isSale = _isSale;
    }

    function setIsHolderSale(bool _isSale) external onlyOwner {
        isHolderSale = _isSale;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
        emit setPriceEvent(newPrice);
    }

    function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
        maxSupply = newMaxSupply;
        emit setMaxSupplyEvent(newMaxSupply);
    }

    function setMaxMintAmount(uint256 newMaxMintAmount) external onlyOwner {
        mintMaxAmount = newMaxMintAmount;
    }

    function setLvl1Supply(uint256 newSupply) external onlyOwner {
        lvl1Supply = newSupply;
    }

    function setLvl2Supply(uint256 newSupply) external onlyOwner {
        lvl2Supply = newSupply;
    }

    function setLvl3Supply(uint256 newSupply) external onlyOwner {
        lvl3Supply = newSupply;
    }

    function setLvl2Odds(uint256 newOdds) external onlyOwner {
        lvl2Odds = newOdds;
    }

    function setLvl3Odds(uint256 newOdds) external onlyOwner {
        lvl3Odds = newOdds;
    }

    function setSeed(uint256 newSeed) external onlyOwner {
        seed = newSeed;
    }

    /**
     * @dev FINANCE
     */

    function withdrawAll(address _to) external onlyOwner {
        require(_to != address(0), "CANNOT WITHDRAW TO ZERO ADDRESS");
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "NO ETHER TO WITHDRAW");
        payable(_to).transfer(contractBalance);
        emit WithdrawAllEvent(_to, contractBalance);
    }

    /**
     * @dev Fallback function for receiving Ether
     */
    receive() external payable {
        emit ReceivedEther(msg.sender, msg.value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
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