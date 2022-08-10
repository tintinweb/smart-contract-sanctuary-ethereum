// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IToken.sol";
import "./interfaces/IOwnable.sol";

contract Minter is Ownable {

    // sale details
    address public tokenAddress;
    uint256 public nextTokenId = 1999;
    uint256 public maxHolderAllocation = 5;
    uint256 public maxWhitelistAllocation = 20;

    /// @notice minter address => # already minted for MintPhase.HoldersOnly
    mapping(address => uint256) public hasMintedHolderAllocation;
    /// @notice minter address => # already minted for MintPhase.WhitelistOnly
    mapping(address => uint256) public hasMintedWhitelistAllocation;

    /// @notice merkle root of valid holder addresses and quantities allowed
    bytes32 public holderMerkleRoot;
    /// @dev this is a superset of holderMerkleRoot
    bytes32 public whitelistMerkleRoot;

    enum MintPhase { Paused, HoldersOnly, WhitelistOnly, Open }
    MintPhase public mintPhase;

    /// @notice mint on the main token contract
    /// @param merkleProof the merkle proof for the minter's address
    /// @param quantity number of mints desired
    function proxyMint(
        bytes32[] calldata merkleProof,
        uint256 quantity
    ) external payable {
        //===================== CHECKS =======================
        IToken tokenContract = IToken(tokenAddress);
        
        // PRIMARY CHECKS

        // check mint is not paused
        if (mintPhase == MintPhase.Paused) {
            revert("Minting paused");
        }

        // check we won't exceed max tokens allowed
        uint256 maxTokens = tokenContract.maxTokens();
        require(nextTokenId + quantity <= maxTokens, "Exceeds max supply");
        
        // check enough ether is sent
        uint256 price = tokenContract.price();
        require(msg.value >= price * quantity, "Not enough ether");
        
        // block contracts
        require(msg.sender == tx.origin, "No contract mints");

        // `HoldersOnly` PHASE CHECKS
        if (mintPhase == MintPhase.HoldersOnly) {
            // check merkle proof against holder root
            require(checkMerkleProof(merkleProof, msg.sender, holderMerkleRoot), "Invalid holder proof");

            // make sure user won't have already minted max HolderOnly amount
            require(hasMintedHolderAllocation[msg.sender] + quantity <= maxHolderAllocation, "Exceeds holder allocation");
            
            // EFFECT. log the amount this user has minted for holder allocation
            hasMintedHolderAllocation[msg.sender] = hasMintedHolderAllocation[msg.sender] + quantity;
        }

        // `WhitelistOnly` PHASE CHECKS
        if (mintPhase == MintPhase.WhitelistOnly) {
            // check merkle proof against whitelist root
            require(checkMerkleProof(merkleProof, msg.sender, whitelistMerkleRoot), "Invalid whitelist proof");

            // make sure user won't have already minted maxWhitelistAllocation amount
            require(hasMintedWhitelistAllocation[msg.sender] + quantity <= maxWhitelistAllocation, "Exceeds whitelist allocation");

            // EFFECT. log the amount this user has minted for whitelist allocation
            hasMintedWhitelistAllocation[msg.sender] = hasMintedWhitelistAllocation[msg.sender] + quantity;
        }

        // `Open` PHASE CHECKS
        if (mintPhase == MintPhase.Open) {
            // check maxMintsPerTx from token contract. note that in all other phases,
            // we have phase-specific limits and thus don't need to check this.
            uint256 maxMintsPerTx = tokenContract.maxMintsPerTx();
            require(quantity <= maxMintsPerTx, "Too many mints per txn");
        }

        //=================== EFFECTS =========================

        // forward funds to token contract
        (bool success, ) = tokenAddress.call{value: msg.value }("");
        require(success, "Payment forwarding failed");

        // increase our local tokenId. we only need to do this bc we made the 
        // tokenId on the main token contract private.
        nextTokenId += quantity;

        //=================== INTERACTIONS =======================
        tokenContract.mintAdmin(quantity, msg.sender);

    }

    /// @notice check whether the merkleProof is valid for a given address and root
    function checkMerkleProof(
        bytes32[] calldata merkleProof,
        address _address,
        bytes32 _root
    ) public pure returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        return MerkleProof.verify(merkleProof, _root, leaf);
    }

    /// @notice let owner set main token address
    function setTokenAddress(address _tokenAddress) external onlyOwner {
        tokenAddress = _tokenAddress;
    }

    /// @notice let owner set the holder merkle root
    function setHolderMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        holderMerkleRoot = _merkleRoot;
    }

    /// @notice let owner set the whitelist merkle root
    function setWhitelistMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        whitelistMerkleRoot = _merkleRoot;
    }

    /// @notice Sets mint phase, takes uint that refers to MintPhase enum (0 indexed).
    function setMintPhase(MintPhase phase) external onlyOwner {
        mintPhase = phase;
    }

    /// @notice set max holder allocation amount
    function setMaxHolderAllocation(uint256 amount) external onlyOwner {
        maxHolderAllocation = amount;
    }

    /// @notice set max whitelist allocation amount
    function setMaxWhitelistAllocation(uint256 amount) external onlyOwner {
        maxWhitelistAllocation = amount;
    }

    /// @notice change the next token id (to match token contract)
    function setNextTokenId(uint256 id) external onlyOwner {
        nextTokenId = id;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/cryptography/MerkleProof.sol)

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
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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

// SPDX-License-Identifier: GPL-3.0

/// @title IToken interface

pragma solidity ^0.8.6;

interface IToken {
    function saleActive() external returns (bool);
    function maxMintsPerTx() external returns (uint256);
    function maxTokens() external returns (uint256);
    function price() external returns (uint256);
    function mintAdmin(uint256 quantity, address to) external;
    function battleTransfer(address from, address to, uint256 tokenId) external;
}

// SPDX-License-Identifier: GPL-3.0

/// @title IOwnable interface

pragma solidity ^0.8.6;

interface IOwnable {
    function owner() external returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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