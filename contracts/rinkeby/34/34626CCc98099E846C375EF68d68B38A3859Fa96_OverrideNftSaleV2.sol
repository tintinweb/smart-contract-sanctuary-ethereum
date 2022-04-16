/**
 *Submitted for verification at Etherscan.io on 2022-04-16
*/

// Sources flattened with hardhat v2.8.4 https://hardhat.org

// File @openzeppelin/contracts/utils/introspection/[email protected]

// 
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


// File @openzeppelin/contracts/token/ERC721/[email protected]

// 
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]

// 
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}


// File @openzeppelin/contracts/utils/[email protected]

// 
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


// File @openzeppelin/contracts/access/[email protected]

// 
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


// File @openzeppelin/contracts/security/[email protected]

// 
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


// File @openzeppelin/contracts/security/[email protected]

// 
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


// File @openzeppelin/contracts/utils/cryptography/[email protected]

// 
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


// File contracts/OverrideNftSaleV2.sol

// 
pragma solidity ^0.8.9;





interface IOverrideNftSaleV2 { 
  function mintBatch(address to, uint256[] memory tokenIds) external;
}

contract OverrideNftSaleV2 is Ownable, Pausable, ReentrancyGuard {

    uint256 public constant MAX_MINT_PER_TX = 10;
    uint256 public constant MAX_SUPPLY = 9000;
    uint256 public constant MAX_TREASURY_SUPPLY = 100;
    uint256 public treasuryTotalSupply = MAX_TREASURY_SUPPLY;
    
    address public nftContract;

    uint256 public whitelistStartTime;
    uint256 public whitelistEndTime;
    uint256 public saleStartTime;

    uint256 public constant PRICE = 0.08 ether;
    uint256 public constant DISCOUNT_PRICE = 0.07 ether;
    uint256 public constant PREMIUM_DISCOUNT_PRICE = 0.06 ether;

    uint256 constant FREE_INDEX = 0;
    uint256 constant PREMIUM_DISCOUNT_INDEX = 1;
    uint256 constant DISCOUNT_INDEX = 2;

    mapping(address => uint64) freeMints;
    mapping(address => uint64) premiumDiscountMints;
    mapping(address => uint64) discountMints;

    uint64 public freeMinted;
    uint64 public premiumDiscountMinted;
    uint64 public discountMinted;

    bytes32 public freeRoot;
    bytes32 public premiumDiscountRoot;
    bytes32 public discountRoot;

    event Minted(address sender, uint256 count);
    event Reserved(address sender, uint256 count);

    constructor(address _nftContract, 
        address _owner,
        uint256 _whitelistStartTime,
        uint256 _whitelistEndTime, 
        uint256 _saleStartTime) Ownable() ReentrancyGuard() {
        nftContract = _nftContract;
        whitelistStartTime = _whitelistStartTime;
        whitelistEndTime = _whitelistEndTime;
        saleStartTime = _saleStartTime;

        // Transfer to owner of NFT instead of deployer (multisig set up)
        transferOwnership(_owner);
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function withdrawETH() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    // TODO:0xcompbow different approach? should consider
    // function withdrawMoney() external onlyOwner nonReentrant {
    //     (bool success, ) = msg.sender.call{value: address(this).balance}("");
    //     require(success, "Transfer failed.");
    // }

    function setNftContract(address _nftContract) public onlyOwner {
        nftContract = _nftContract;
    }

    function setTimes(uint256 _whitelistStartTime, uint256 _whitelistEndTime, uint256 _saleStartTime) external onlyOwner {
        whitelistStartTime = _whitelistStartTime;
        whitelistEndTime = _whitelistEndTime;
        saleStartTime = _saleStartTime;
    }

    function setWhitelistRoots(bytes32 _freeRoot, bytes32 _premiumDiscountRoot, bytes32 _discountRoot) external onlyOwner {
        freeRoot = _freeRoot;
        premiumDiscountRoot = _premiumDiscountRoot;
        discountRoot = _discountRoot;
    }

    function treasuryMint() public onlyOwner {
        require(treasuryTotalSupply == 0, "treasury already minted");

        uint256 targetMintIndex = currentMintIndex();

        require(
        targetMintIndex + MAX_TREASURY_SUPPLY <= MAX_SUPPLY,
        "not enough remaining reserved for auction to support desired mint amount"
        );

        uint256[] memory ids = new uint256[](MAX_TREASURY_SUPPLY);
        for (uint256 i; i < MAX_TREASURY_SUPPLY; ++i) {
            ids[i] = targetMintIndex + i;
        }

        IOverrideNftSaleV2(nftContract).mintBatch(msg.sender, ids);

        treasuryTotalSupply = treasuryTotalSupply - MAX_TREASURY_SUPPLY;

        emit Minted(msg.sender, MAX_TREASURY_SUPPLY);
    }

    function whitelistMint(uint256[3] calldata amountsToBuy, 
        uint256[3] calldata amounts, 
        uint256[3] calldata indexes, 
        bytes32[][3] calldata merkleProof) external payable nonReentrant callerIsUser {

        require(
        whitelistStartTime != 0 && block.timestamp >= whitelistStartTime,
        "whitelist mint has not started yet"
        );

        require(block.timestamp >= whitelistEndTime, "whitelist mint has ended");

        require(amountsToBuy.length == 3, "Not right length");
        require(amountsToBuy.length == amounts.length, "Not equal amounts");
        require(amounts.length == indexes.length, "Not equal indexes");
        require(indexes.length == merkleProof.length, "Not equal proof");

        uint256 expectedPayment;
        if (merkleProof[PREMIUM_DISCOUNT_INDEX].length != 0) {
            expectedPayment += amountsToBuy[PREMIUM_DISCOUNT_INDEX]*PREMIUM_DISCOUNT_PRICE;
        }
        if (merkleProof[DISCOUNT_INDEX].length != 0) {
            expectedPayment += amountsToBuy[DISCOUNT_INDEX]*DISCOUNT_PRICE;
        } 
        require(msg.value == expectedPayment, "Not right ETH sent");

        uint256 quantity;
        // if (merkleProof[FREE_INDEX].length != 0 && freeMints[msg.sender] <= amounts[FREE_INDEX]) {
        if (merkleProof[FREE_INDEX].length != 0) {
            require(freeRoot.length != 0, "free root not assigned");
            bytes32 node = keccak256(abi.encodePacked(indexes[FREE_INDEX], msg.sender, amounts[FREE_INDEX]));
            require(MerkleProof.verify(merkleProof[FREE_INDEX], freeRoot, node), 'MerkleProof: Invalid team proof.');
            require(amountsToBuy[FREE_INDEX] <= amounts[FREE_INDEX], "Cant buy this many");
            quantity += amountsToBuy[FREE_INDEX];
            uint64 temp = uint64(amountsToBuy[FREE_INDEX]);
            freeMinted += temp;
            // freeMints[msg.sender] += temp;
        }
        if (merkleProof[PREMIUM_DISCOUNT_INDEX].length != 0) {
            require(premiumDiscountRoot.length != 0, "Premium Discount root not assigned");
            bytes32 node = keccak256(abi.encodePacked(indexes[PREMIUM_DISCOUNT_INDEX], msg.sender, amounts[PREMIUM_DISCOUNT_INDEX]));
            require(MerkleProof.verify(merkleProof[PREMIUM_DISCOUNT_INDEX], premiumDiscountRoot, node), 'MerkleProof: Invalid uwu proof.');
            require(amountsToBuy[PREMIUM_DISCOUNT_INDEX] <= amounts[PREMIUM_DISCOUNT_INDEX], "Cant buy this many");
            quantity += amountsToBuy[PREMIUM_DISCOUNT_INDEX];
            premiumDiscountMinted += uint64(amountsToBuy[PREMIUM_DISCOUNT_INDEX]);
        }
        if (merkleProof[DISCOUNT_INDEX].length != 0) {
            require(discountRoot.length != 0, "Discount root not assigned");
            bytes32 node = keccak256(abi.encodePacked(indexes[DISCOUNT_INDEX], msg.sender, amounts[DISCOUNT_INDEX]));
            require(MerkleProof.verify(merkleProof[DISCOUNT_INDEX], discountRoot, node), 'MerkleProof: Invalid wl proof.');
            require(amountsToBuy[DISCOUNT_INDEX] <= amounts[DISCOUNT_INDEX], "Cant buy this many");
            quantity += amountsToBuy[DISCOUNT_INDEX];
            discountMinted += uint64(amountsToBuy[DISCOUNT_INDEX]);
        }  

        uint256 targetMintIndex = currentMintIndex();

        require(
        targetMintIndex + quantity <= MAX_SUPPLY,
        "not enough remaining reserved for auction to support desired mint amount"
        );

        uint256[] memory ids = new uint256[](quantity);
        for (uint256 i; i < quantity; ++i) {
            ids[i] = targetMintIndex + i;
        }

        IOverrideNftSaleV2(nftContract).mintBatch(msg.sender, ids);

        emit Reserved(msg.sender, quantity);
    }

    function saleMint(uint256 quantity) external payable nonReentrant callerIsUser {

        require(quantity > 0, "Cannot mint 0");
        require(quantity <= MAX_MINT_PER_TX, "per tx limit: can not mint this many in a tx");
        require(
        saleStartTime != 0 && block.timestamp >= saleStartTime,
        "sale mint has not started yet"
        );

        require(msg.value == quantity * PRICE, "Not right ETH sent");

        uint256 targetMintIndex = currentMintIndex();

        require(targetMintIndex + quantity <= MAX_SUPPLY, "Sold out! Sorry!");

        uint256[] memory ids = new uint256[](quantity);
        for (uint256 i; i < quantity; ++i) {
            ids[i] = targetMintIndex + i;
        }

        IOverrideNftSaleV2(nftContract).mintBatch(msg.sender, ids);

        emit Minted(msg.sender, quantity);
    }

    function currentMintIndex() public view returns (uint256) {
        return totalSupply() + 1;
    }

    function totalSupply() public view returns (uint256) {
        // remaining supply
        return IERC721Enumerable(nftContract).totalSupply();
    }
}