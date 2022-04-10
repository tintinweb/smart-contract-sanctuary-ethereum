// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./IOmniyaLandSaleToken.sol";

interface MintPassContract {
    function burnFromRedeem(address account, uint256 id, uint256 amount) external;
    function balanceOf(address account, uint256 id) external view returns (uint256);
}

contract OmniyaLandSaleMinter is Ownable, ReentrancyGuard {

    // ======== Sale Status =========
    bool public saleIsActive = false;
    uint256 public immutable publicSaleStart; 

    // ======== Claim Tracking =========
    mapping(address => uint256) private addressToMintCount;

    // ======== External Storage Contract =========
    IOmniyaLandSaleToken public immutable token;

    // ======== Fund Management =========
    address public withdrawalAddress = 0xcaFe1fC8Fe3a9Ea448a91Ac458A38Dbb331B08e6; // NFH

    // ======== Mint Pass =========
    MintPassContract public mintPassContract;
    address public immutable mintPassTokenAddress;

    event Redeemed(address indexed account, uint256 amount);

    // ======== Tiers =========
    uint256 constant BRONZE = 1; 
    uint256 constant SILVER = 2; 
    uint256 constant GOLD = 3; 
    uint256 constant PLATINUM = 4;
    
    // ======== Tier Price ========= 
    uint256 public constant BRONZE_COST = 0.1 ether; 
    uint256 public constant SILVER_COST = 0.5 ether; 
    uint256 public constant GOLD_COST = 1 ether; 
    uint256 public constant PLATINUM_COST = 5 ether;

    // ======== Tier Supply ========= 
    uint256 public constant BRONZE_SUPPLY_MAX = 500; 
    uint256 public constant SILVER_SUPPLY_MAX = 250; 
    uint256 public constant GOLD_SUPPLY_MAX = 150; 
    uint256 public constant PLATINUM_SUPPLY_MAX = 100;
       
    mapping(uint256 => uint256) private tierToSupplyMax;
    mapping(uint256 => uint256) private tierToMintedCount;
    mapping(uint256 => uint256) private tokenIdToTier;
    mapping(uint256 => uint256) private tierToPrice;

    // ======== Constructor =========
    constructor(address contractAddress,
                uint256 publicSaleStartTimestamp,
                address _mintPassTokenAddress) {

        token = IOmniyaLandSaleToken(contractAddress);
        publicSaleStart = publicSaleStartTimestamp;
        mintPassTokenAddress = _mintPassTokenAddress;
        mintPassContract = MintPassContract(mintPassTokenAddress);

        tierToPrice[BRONZE] = BRONZE_COST;
        tierToPrice[SILVER] = SILVER_COST;
        tierToPrice[GOLD] = GOLD_COST;
        tierToPrice[PLATINUM] = PLATINUM_COST;

        tierToSupplyMax[BRONZE] = BRONZE_SUPPLY_MAX;
        tierToSupplyMax[SILVER] = SILVER_SUPPLY_MAX;
        tierToSupplyMax[GOLD] = GOLD_SUPPLY_MAX;
        tierToSupplyMax[PLATINUM] = PLATINUM_SUPPLY_MAX;
    }

    // ======== Modifier Checks =========    
    modifier isPaymentCorrect(uint256 qty, uint256 tier) {
        require(msg.value >= tierToPrice[tier] * qty, "Invalid ETH value sent!");
        _;
    }

    modifier isSaleActive() {
        require(saleIsActive, "Sale is not active!");
        _;
    }

    modifier isSaleStarted(uint256 saleStartTime) {
        require(block.timestamp >= saleStartTime, "Sale not started!");
        _;
    }

    modifier isTierSupported(uint256 tier) {
        require(tier == BRONZE || tier == SILVER || tier == GOLD || tier == PLATINUM, "Tier not supported!");
        _;
    }

    modifier isSupplyAvailable(uint256 qty, uint256 tier) {
        require(tierToMintedCount[tier] + qty <= tierToSupplyMax[tier], "Exceeds max token supply!");
        _;
    }

    // ======== Mint Functions =========
    /// @notice Transfers funds to withdrawal address
    /// @param qty Quantity of tokens to purchase
    /// @param price Price of each token
    function transferFunds(uint256 qty, uint256 price) private {
        if(msg.value == qty * price) { 
            (bool success, ) = payable(withdrawalAddress).call{value: qty * price}("");
            require(success, "Transfer failed!");
        } else {
          revert("Invalid payment!");
        }
    }

    /// @notice Transfers funds to withdrawal address
    /// @param qty Quantity of tokens to purchase
    /// @param qty Tier to purchase
    function redeem(uint qty, uint256 tier) public payable 
        isSaleActive()
        isSaleStarted(publicSaleStart)
        isTierSupported(tier)
        isPaymentCorrect(qty, tier)
        isSupplyAvailable(qty, tier)
        nonReentrant  {
        require(msg.sender == tx.origin, "Redeem: not allowed from contract");
        require(mintPassContract.balanceOf(msg.sender, 0) >= qty, "Redeem: insufficient amount of MintPasses");
        
        transferFunds(qty, tierToPrice[tier]);

        mintPassContract.burnFromRedeem(msg.sender, 0, qty);

        token.mint(qty, msg.sender);
        
        for (uint256 i = 0; i < qty; i++) {
            tokenIdToTier[tierToMintedCount[tier]] = tier;
            tierToMintedCount[tier] += 1;
        }

        addressToMintCount[msg.sender] += qty;

        emit Redeemed(msg.sender, qty);
    }

    // ======== Utilities =========
    function mintCount(address _address) external view returns (uint) {
        return addressToMintCount[_address];
    }

    function isPublicSaleActive() external view returns (bool) {
        return block.timestamp >= publicSaleStart && saleIsActive;
    }

    function getTierByTokenId(uint256 tokenId) external view returns (uint256) {
        return tokenIdToTier[tokenId];
    }

    // ======== State Management =========
    function flipSaleStatus() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    // ======== Withdraw =========
    function setWithdrawalAddress(address _newWithdrawalAddress) public onlyOwner {
        withdrawalAddress = _newWithdrawalAddress;
    }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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
     * by making the `nonReentrant` function external, and make it call a
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
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

// Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
/// @title Interface for Token
pragma solidity 0.8.13;

abstract contract IOmniyaLandSaleToken {

    function setProvenanceHash(string memory _provenanceHash) virtual external;

    function mint(uint256 _count, address _recipient) virtual external;

    function setBaseURI(string memory baseURI) virtual external;

    function updateMinter(address _minter) virtual external;

    function lockMinter() virtual external;

    function tokenCount() virtual external returns (uint256);
}

// SPDX-License-Identifier: MIT

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