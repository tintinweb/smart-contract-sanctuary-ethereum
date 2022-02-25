/**
 *Submitted for verification at Etherscan.io on 2022-02-25
*/

// SPDX-License-Identifier: MIT

// Scroll down to the bottom to find the contract of interest. 

// File: @openzeppelin/contracts/utils/cryptography/MerkleProof.sol

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


// File: @openzeppelin/contracts/utils/Context.sol

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


// File: @openzeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/Context.sol";

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


// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}


// File: @openzeppelin/contracts/utils/introspection/IERC165.sol

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


// File: @openzeppelin/contracts/token/ERC721/IERC721.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

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


// File: @rari-capital/solmate/src/tokens/ERC20.sol

pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                              EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}


// File: eth/contracts/Dreams.sol

pragma solidity ^0.8.0;
pragma abicoder v2;

// import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol"; 
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// import "@rari-capital/solmate/src/tokens/ERC20.sol";

error InvalidProof();
error Unauthorized();
error NotActive();
error IndexOutOfBounds();
error NoMoreAvailableToMint();

abstract contract ERC20MintCapped is ERC20, Ownable {

    uint256 public immutable mintCap;

    uint256 public immutable harvestMintCap;

    uint128 public totalMinted;

    uint128 public totalHarvestMinted;

    mapping(address => bool) public minters;

    constructor(uint128 mintCap_, uint128 harvestMintCap_) { 
        mintCap = mintCap_;
        harvestMintCap = harvestMintCap_;
        if (harvestMintCap_ > mintCap_) revert();
        minters[msg.sender] = true;
    }

    function _cappedMint(address to, uint256 amount) internal returns (uint256) {
        if (amount == 0) return 0;
        uint256 diff;
        unchecked {
            uint256 curr = totalMinted;
            uint256 next = curr + amount;
            if (amount > type(uint128).max) revert();
            if (next > mintCap) { // If the next total amount exceeds the mintCap,
                next = mintCap; // set the total amount to the mintCap.
            }
            diff = next - curr; // The amount needed to be minted.
            if (diff == 0) revert NoMoreAvailableToMint();
            if (next > type(uint128).max) revert();
            totalMinted = uint128(next);    
        }
        _mint(to, diff);
        return diff;
    }

    function _harvestCappedMint(address to, uint256 amount) internal returns (uint256) {
        if (amount == 0) return 0;
        uint256 diff;
        unchecked {
            uint256 curr = totalHarvestMinted;
            uint256 next = curr + amount;
            if (amount > type(uint128).max) revert();
            if (next > harvestMintCap) { // If the next total amount exceeds the harvestMintCap,
                next = harvestMintCap; // set the total amount to the harvestMintCap.
            }
            diff = next - curr; // The amount needed to be minted.
            if (diff == 0) revert NoMoreAvailableToMint();
            if (next > type(uint128).max) revert();
            totalHarvestMinted = uint128(next);    
        }
        return _cappedMint(to, diff);
    }

    function authorizeMinter(address minter) external onlyOwner {
        minters[minter] = true;
    }

    function revokeMinter(address minter) external onlyOwner {
        minters[minter] = false;
    }
    
    function mint(address to, uint256 amount) external {
        if (!minters[msg.sender]) revert Unauthorized();
        _cappedMint(to, amount);
    }

    function selfMint(uint256 amount) external {
        if (!minters[msg.sender]) revert Unauthorized();
        _cappedMint(msg.sender, amount);
    }
}


abstract contract ERC20Claimable is ERC20MintCapped {
    
    bytes32 internal _claimMerkleRoot;

    mapping(uint256 => uint256) internal _claimed;

    constructor(bytes32 claimMerkleRoot) {
        _claimMerkleRoot = claimMerkleRoot;
    }

    function setClaimMerkleRoot(bytes32 root) public onlyOwner {
        _claimMerkleRoot = root;
    }

    function isClaimed(uint256 slot) external view returns (bool) {
        uint256 q = slot >> 8;
        uint256 r = slot & 255;
        uint256 b = 1 << r;
        return _claimed[q] & b != 0;
    }

    function claim(address to, uint256 amount, uint256 slot, bytes32[] calldata proof) external {
        uint256 q = slot >> 8;
        uint256 r = slot & 255;
        uint256 b = 1 << r;
        require(_claimed[q] & b == 0, "Already claimed.");
        bytes32 leaf = keccak256(abi.encodePacked(to, amount, slot));
        bool isValidLeaf = MerkleProof.verify(proof, _claimMerkleRoot, leaf);
        if (!isValidLeaf) revert InvalidProof();
        _claimed[q] |= b;

        _cappedMint(to, amount);
    }
}


abstract contract ERC20Burnable is ERC20 {

    function _checkedBurn(address account, uint256 amount) internal {
        require(balanceOf[account] >= amount, "Insufficient balance.");
        _burn(account, amount);
    }

    function burn(uint256 amount) public {
        _checkedBurn(msg.sender, amount);
    }

    function burnFrom(address account, uint256 amount) public {
        uint256 currentAllowance = allowance[account][msg.sender];
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            allowance[account][msg.sender] -= amount;
        }
        _checkedBurn(account, amount);
    }
}


abstract contract Coin is ERC20, ERC20Burnable, ERC20MintCapped, ERC20Claimable {

    constructor(
        string memory name_, 
        string memory symbol_, 
        uint128 mintCap_, 
        uint128 harvestMintCap_
    )
    ERC20(name_, symbol_, 18) 
    ERC20MintCapped(mintCap_, harvestMintCap_) {}
}


abstract contract Shop is Coin {

    struct PriceListing {
        uint248 price;
        bool active;
    }

    uint256 internal constant BITWIDTH_TOKEN_UID = 16;
    uint256 internal constant BITWIDTH_TOKEN_ID = BITWIDTH_TOKEN_UID - 1;
    uint256 internal constant BITMASK_TOKEN_ID = (1 << BITWIDTH_TOKEN_ID) - 1;

    address public immutable gen0;
    address public immutable gen1;

    constructor(address _gen0, address _gen1) {
        gen0 = _gen0;
        gen1 = _gen1;
    }

    function _gen(uint256 gen) internal view returns (IERC721) {
        return IERC721(gen == 0 ? gen0 : gen1);
    }
}


abstract contract NFTStaker is Shop {

    uint256 internal constant BITSHIFT_OWNER = 96;
    uint256 internal constant BITWIDTH_BLOCK_NUM = 31;
    uint256 internal constant BITMASK_BLOCK_NUM = (1 << BITWIDTH_BLOCK_NUM) - 1;
    uint256 internal constant BITWIDTH_STAKE = (BITWIDTH_TOKEN_UID + BITWIDTH_BLOCK_NUM);
    uint256 internal constant BITMASK_STAKE = (1 << BITWIDTH_STAKE) - 1;
    uint256 internal constant BITMOD_STAKE = (256 / BITWIDTH_STAKE);
    uint256 internal constant BITPOS_NUM_STAKED = BITMOD_STAKE * BITWIDTH_STAKE;
    uint256 internal constant BITMASK_STAKES = (1 << BITPOS_NUM_STAKED) - 1;
    
    uint256 internal constant BITWIDTH_RATE = 4;
    uint256 internal constant BITMOD_RATE = (256 / BITWIDTH_RATE);
    uint256 internal constant BITMASK_RATE = (1 << BITWIDTH_RATE) - 1;
    uint256 internal constant DEFAULT_RATE = 5;

    mapping(uint256 => uint256) internal _vault;

    bytes32 internal _ratesMerkleRoot;

    uint128 public harvestBaseRate;

    uint32 public minStakeBlocks;

    bool private _reentrancyGuard;

    constructor(
        uint128 harvestBaseRate_, 
        uint32 minStakeBlocks_, 
        bytes32 ratesMerkleRoot_
    ) {
        harvestBaseRate = harvestBaseRate_;
        minStakeBlocks = minStakeBlocks_;
        _ratesMerkleRoot = ratesMerkleRoot_;
    }

    modifier nonReentrant() {
        if (_reentrancyGuard) revert();
        _reentrancyGuard = true;
        _;
        _reentrancyGuard = false;
    }

    function setRatesMerkleRoot(bytes32 value) external onlyOwner {
        _ratesMerkleRoot = value;
    }

    function setMinStakeBlocks(uint32 value) external onlyOwner {
        minStakeBlocks = value;
    }

    function setHarvestBaseRate(uint128 value) external onlyOwner {
        harvestBaseRate = value;
    }

    function _blockNumber() internal view virtual returns (uint256) {
        return block.number;
    }

    function stakeNFTs(uint256[] memory tokenUids) 
    external nonReentrant {
        unchecked {
            uint256 n = tokenUids.length;
            require(n > 0, "Please submit at least 1 token.");
            uint256 o = uint256(uint160(msg.sender)) << BITSHIFT_OWNER;
            uint256 f = _vault[o];
            uint256 m = f >> BITPOS_NUM_STAKED;

            uint256 j = m;

            _vault[o] = f ^ ((m ^ (m + n)) << BITPOS_NUM_STAKED);

            uint256 blockNumCurr = _blockNumber();
            for (uint256 i; i < n; ++i) {
                uint256 e = tokenUids[i];
                
                // Transfer NFT from owner to contract.
                uint256 gen = e >> BITWIDTH_TOKEN_ID;
                uint256 tokenId = e & BITMASK_TOKEN_ID;
                _gen(gen).transferFrom(msg.sender, address(this), tokenId);

                uint256 q = (j / BITMOD_STAKE) | o;
                uint256 r = (j % BITMOD_STAKE) * BITWIDTH_STAKE;
                uint256 s = (e << BITWIDTH_BLOCK_NUM) | blockNumCurr;
                _vault[q] |= (s << r);
                ++j;
            }
        }
    }

    function stakedNFTs(address owner) 
    external view returns (uint256[] memory) {
        unchecked {
            uint256 o = uint256(uint160(owner)) << BITSHIFT_OWNER;
            uint256 f = _vault[o];
            uint256 m = f >> BITPOS_NUM_STAKED;

            uint256[] memory a = new uint256[](m);
            for (uint256 j; j < m; ++j) {
                uint256 q = (j / BITMOD_STAKE) | o;
                uint256 r = (j % BITMOD_STAKE) * BITWIDTH_STAKE;
                uint256 s = (_vault[q] >> r) & BITMASK_STAKE;
                a[j] = s >> BITWIDTH_BLOCK_NUM;
            }
            return a;
        }
    }

    function stakedNFTByIndex(address owner, uint256 index) public view returns (uint256) {
        unchecked {
            uint256 j = index;
            uint256 o = uint256(uint160(owner)) << BITSHIFT_OWNER;
            uint256 f = _vault[o];
            uint256 m = f >> BITPOS_NUM_STAKED;
            if (j >= m) revert IndexOutOfBounds();
            uint256 q = (j / BITMOD_STAKE) | o;
            uint256 r = (j % BITMOD_STAKE) * BITWIDTH_STAKE;
            uint256 s = (_vault[q] >> r) & BITMASK_STAKE;
            return s >> BITWIDTH_BLOCK_NUM;
        }        
    }

    function unstakeNFTs(uint256[] calldata indices, uint256 numStaked) 
    external nonReentrant {
        unchecked {
            uint256 o = uint256(uint160(msg.sender)) << BITSHIFT_OWNER;
            uint256 f = _vault[o];
            uint256 m = f >> BITPOS_NUM_STAKED;      
            if (m != numStaked) revert IndexOutOfBounds();
            uint256 n = indices.length;
            require(n > 0, "Please submit at least 1 token.");
            if (m < n) revert IndexOutOfBounds();

            _vault[o] = f ^ ((m ^ (m - n)) << BITPOS_NUM_STAKED);
            uint256 p = type(uint256).max;
            for (uint256 i; i < n; ++i) {
                uint256 j = indices[i];
                if (j >= m || j >= p) revert IndexOutOfBounds();
                uint256 q = (j / BITMOD_STAKE) | o;
                uint256 r = (j % BITMOD_STAKE) * BITWIDTH_STAKE;
                uint256 s = (_vault[q] >> r) & BITMASK_STAKE;
                
                uint256 tokenUid = s >> BITWIDTH_BLOCK_NUM;
                
                // Transfer NFT from contract to owner.
                uint256 gen = tokenUid >> BITWIDTH_TOKEN_ID;
                uint256 tokenId = tokenUid & BITMASK_TOKEN_ID;
                _gen(gen).transferFrom(address(this), msg.sender, tokenId);

                --m;
                uint256 u = (m / BITMOD_STAKE) | o;
                uint256 v = (m % BITMOD_STAKE) * BITWIDTH_STAKE;
                uint256 w = (_vault[u] >> v) & BITMASK_STAKE;
                _vault[q] ^= ((s ^ w) << r);
                _vault[u] ^= (w << v);
                p = j;
            }
        }
    }

    function harvest(uint256[] calldata rates, bytes32[][] calldata proofs) 
    external nonReentrant returns (uint256) {
        unchecked {
            uint256 o = uint256(uint160(msg.sender)) << BITSHIFT_OWNER;
            uint256 m = _vault[o] >> BITPOS_NUM_STAKED;
            uint256 amount;
            if (m != rates.length || m != proofs.length)
                revert InvalidProof();
            
            uint256 blockNumCurr = _blockNumber();
            uint256 thres = minStakeBlocks;
            bytes32 root = _ratesMerkleRoot;
            
            for (uint256 j; j < m; ++j) {
                bytes32[] memory proof = proofs[j];
                uint256 rate = rates[j];
                uint256 q = (j / BITMOD_STAKE) | o;
                uint256 r = (j % BITMOD_STAKE) * BITWIDTH_STAKE;
                uint256 s = (_vault[q] >> r) & BITMASK_STAKE;
                
                uint256 blockNum = s & BITMASK_BLOCK_NUM;
                uint256 tokenUid = s >> BITWIDTH_BLOCK_NUM;
                
                if (blockNum + thres > blockNumCurr) continue;

                if (!MerkleProof.verify(proof, root, 
                    keccak256(abi.encodePacked(tokenUid, rate)))) 
                    revert InvalidProof();

                amount += rate * (blockNumCurr - blockNum);

                uint256 w = (tokenUid << BITWIDTH_BLOCK_NUM) | blockNumCurr;
                _vault[q] ^= ((s ^ w) << r);                    
            }
            amount *= harvestBaseRate;

            return _harvestCappedMint(msg.sender, amount);
        }
    }
}


abstract contract NFTDataChanger is NFTStaker {

    mapping(uint256 => PriceListing) public nftDataPrices;

    // nftData[tokenUid][dataTypeId]
    mapping(uint256 => mapping(uint256 => bytes32)) public nftData;

    event NFTDataChanged(uint256 tokenUid, uint256 dataTypeId, bytes32 value);

    function setNFTDataPrice(uint256 dataTypeId, uint248 price, bool active) external onlyOwner {
        nftDataPrices[dataTypeId].price = price;
        nftDataPrices[dataTypeId].active = active;
    }

    function _setNFTData(uint256 tokenUid, uint256 dataTypeId, bytes32 value) internal {
        if (!nftDataPrices[dataTypeId].active) revert NotActive();
        burn(nftDataPrices[dataTypeId].price);

        nftData[tokenUid][dataTypeId] = value;
        emit NFTDataChanged(tokenUid, dataTypeId, value);
    }

    function setNFTData(uint256 tokenUid, uint256 dataTypeId, bytes32 value) external {
        uint256 gen = tokenUid >> BITWIDTH_TOKEN_ID;
        uint256 tokenId = tokenUid & BITMASK_TOKEN_ID;
        if (msg.sender != _gen(gen).ownerOf(tokenId)) revert Unauthorized();
        _setNFTData(tokenUid, dataTypeId, value);
    }

    function setStakedNFTData(uint256 tokenUid, uint256 index, uint256 dataTypeId, bytes32 value) external {
        if (stakedNFTByIndex(msg.sender, index) != tokenUid) revert Unauthorized();
        _setNFTData(tokenUid, dataTypeId, value);
    }

    function getNFTData(uint256[] calldata tokenUids, uint256[] calldata dataTypeIds) 
    external view returns (bytes32[] memory) {
        unchecked {
            uint256 m = tokenUids.length;
            uint256 n = dataTypeIds.length;
            bytes32[] memory a = new bytes32[](m * n);
            for (uint256 j; j < m; ++j) {
                for (uint256 i; i < n; ++i) {
                    a[j * n + i] = nftData[tokenUids[j]][dataTypeIds[i]];
                }
            }
            return a;    
        }
    }
}


abstract contract TicketShop is Shop {

    mapping(uint256 => PriceListing) public ticketPrices;

    mapping(uint256 => address[]) public ticketPurchases;

    mapping(uint256 => mapping(address => bool)) public hasPurchasedTicket;

    function setTicketPrice(uint256 ticketTypeId, uint248 price, bool active) external onlyOwner {
        ticketPrices[ticketTypeId].price = price;
        ticketPrices[ticketTypeId].active = active;
    }

    function purchaseTicket(uint256 ticketTypeId) public {
        if (!ticketPrices[ticketTypeId].active) revert NotActive();
        burn(ticketPrices[ticketTypeId].price);

        ticketPurchases[ticketTypeId].push(msg.sender);
        hasPurchasedTicket[ticketTypeId][msg.sender] = true;
    }
}


interface IGen1 is IERC721 {
    
    function forceMint(address[] memory _addresses) external;
}


abstract contract Gen1Minter is Shop {

    PriceListing public gen1MintPrice;

    function setGen1MintPrice(uint128 price, bool active) external onlyOwner {
        gen1MintPrice.price = price;
        gen1MintPrice.active = active;
    }

    function passBackGen1Ownership() external onlyOwner {
        Ownable(gen1).transferOwnership(owner());
    }

    function mintGen1(uint256 numTokens) external {
        if (!gen1MintPrice.active) revert NotActive();
        burn(gen1MintPrice.price * numTokens);

        address[] memory a = new address[](numTokens);
        unchecked {
            for (uint i; i < numTokens; ++i) {
                a[i] = msg.sender;
            }
        }
        IGen1(gen1).forceMint(a);
    }
}


abstract contract NFTCoinShop is NFTDataChanger, TicketShop, Gen1Minter {

    constructor(
        string memory name_, 
        string memory symbol_, 
        uint128 mintCap_, 
        uint128 harvestMintCap_, 
        address gen0_, 
        address gen1_,
        bytes32 claimMerkleRoot_,
        uint128 harvestBaseRate_, 
        uint32 minStakeBlocks_, 
        bytes32 ratesMerkleRoot_) 
    Coin(name_, symbol_, mintCap_, harvestMintCap_)
    Shop(gen0_, gen1_)
    ERC20Claimable(claimMerkleRoot_)
    NFTStaker(harvestBaseRate_, minStakeBlocks_, ratesMerkleRoot_) {}
}


// Replace class name with actual value in prod.
contract Dreams is NFTCoinShop {

    constructor() 
    NFTCoinShop(
        // Name
        "Dreams", 
        // Symbol
        "DREAMS", 
        // Mint cap
        10000000 * 1000000000000000000, 
        // Harvest mint cap
        7000000 * 1000000000000000000, 
        // Gen 0 
        0x4e2781e3aD94b2DfcF34c51De0D8e9358c69F296, 
        // Gen 1
        0xAB9F99e6460f6B7940aB7920F44D97b725e0FA4c, 
        // Claim Merkle Root
        0xef35dac8c7728a6c30dc702829819d9d3349f1435480726d0a865665ef8ace69,
        // Harvest base Rate
        100000000000000,
        // Harvest min stake blocks
        66000, 
        // Harvest rates merkle root
        0x8b032d7c4c594507e68c268cbee1026fb7321f4eee5d333862bac183598d338d
    ) {}

}