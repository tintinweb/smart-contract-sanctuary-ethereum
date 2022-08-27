// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./lib/ISarugami.sol";
import "./lib/ISarugamiGamaSummon.sol";

contract SaleGama is Ownable, ReentrancyGuard {
    bool public isMintActive = false;
    uint256 public lockedAmountHolders = 2510;
    uint256 public minted = 0;
    uint256 public serviceFee = 6000000000000000;

    bytes32 public merkleRootRegularWhitelist = "0x";
    bytes32 public merkleRootAlphaWhitelist = "0x";

    uint256 public startMint = 1661626800;
    uint256 public alphaSeconds = 7200;//2 hours
    uint256 public whitelistSeconds = 86400;//24 hours

    mapping(uint256 => bool) public nftsClaimed;
    mapping(address => bool) public walletsClaimed;
    ISarugami public sarugami;
    ISarugamiGamaSummon public summon;

    constructor(
        address sarugamiAddress,
        address summonAddress
    ) {
        sarugami = ISarugami(sarugamiAddress);
        summon = ISarugamiGamaSummon(summonAddress);
    }

    function mintHolder(uint256[] memory ids) public payable nonReentrant {
        require(isMintActive == true, "Holder free mint not open");
        require(msg.value == serviceFee, "ETH sent does not match the Service Fee");
        require(block.timestamp > startMint, "Sale not open");

        for (uint i = 0; i < ids.length; i++) {
            require(sarugami.ownerOf(ids[i]) == _msgSender(), "You are not the owner");
            require(nftsClaimed[ids[i]] == false, "Already claimed");
            nftsClaimed[ids[i]] = true;
        }

        summon.mint(msg.sender, ids.length);
    }

    function mintWhitelist(bytes32[] calldata merkleProof) public payable nonReentrant {
        require(isMintActive == true, "Mint is not active");
        require(walletsClaimed[msg.sender] == false, "Max 1 per wallet");
        require(msg.value == serviceFee, "ETH sent does not match the Service Fee");
        require(block.timestamp > startMint, "Sale not open");
        require(minted+1 < lockedAmountHolders, "Limit reached, Holders have 24 hours to mint, then the remaining supply will be unlocked");

        if(block.timestamp < startMint + alphaSeconds){
            require(isWalletOnAlphaWhitelist(merkleProof, msg.sender) == true, "Invalid proof, Alpha whitelist is minting now");
        } else {
            if (block.timestamp > startMint + alphaSeconds && block.timestamp < startMint + whitelistSeconds) {
                require(isWalletOnAlphaWhitelist(merkleProof, msg.sender) == true || isWalletOnRegularWhitelist(merkleProof, msg.sender) == true, "Invalid proof, your wallet isn't listed in any whitelist");
            }
        }

        minted += 1;
        walletsClaimed[msg.sender] = true;
        summon.mint(msg.sender, 1);
    }

    function isWalletOnAlphaWhitelist(
        bytes32[] calldata merkleProof,
        address wallet
    ) private view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(wallet));
        return MerkleProof.verify(merkleProof, merkleRootAlphaWhitelist, leaf);
    }

    function isWalletOnRegularWhitelist(
        bytes32[] calldata merkleProof,
        address wallet
    ) private view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(wallet));
        return MerkleProof.verify(merkleProof, merkleRootRegularWhitelist, leaf);
    }

    function changePriceServiceFee(uint256 newPrice) external onlyOwner {
        serviceFee = newPrice;
    }

    function changeAlphaSeconds(uint256 newTimestamp) external onlyOwner {
        alphaSeconds = newTimestamp;
    }

    function changeWhitelistSeconds(uint256 newTimestamp) external onlyOwner {
        whitelistSeconds = newTimestamp;
    }

    function changeStartMint(uint256 newTimestamp) external onlyOwner {
        startMint = newTimestamp;
    }

    function changeLockedAmountHolders(uint256 newLock) external onlyOwner {
        lockedAmountHolders = newLock;
    }

    function setMerkleTreeRegularWhitelist(bytes32 newMerkleRoot) external onlyOwner {
        merkleRootRegularWhitelist = newMerkleRoot;
    }

    function setMerkleTreeAlphaWhitelist(bytes32 newMerkleRoot) external onlyOwner {
        merkleRootAlphaWhitelist = newMerkleRoot;
    }

    function mintGiveAwayWithAddresses(address[] calldata supporters) external onlyOwner {
        // Reserved for people who helped this project and giveaways
        for (uint256 index; index < supporters.length; index++) {
            minted += 1;
            summon.mint(supporters[index], 1);
        }
    }

    function changeMintStatus() external onlyOwner {
        isMintActive = !isMintActive;
    }

    function removeDustFunds(address treasury) external onlyOwner {
        (bool success,) = treasury.call{value : address(this).balance}("");
        require(success, "funds were not sent properly to treasury");
    }

    function removeFunds() external onlyOwner {
        uint256 funds = address(this).balance;

        (bool devShare,) = 0xDEcB0fB8d7BB68F0CE611460BE8Ca0665A72d47E.call{
        value : funds * 10 / 100
        }("");

        (bool operationalShare,) = 0x7F1a6c8DFF62e1595A699e9f0C93B654CcfC5Fe1.call{
        value : funds * 15 / 100
        }("");

        (bool modsShare,) = 0x4f45a514EeB7D4a6614eC1F76eec5aB75922A86D.call{
        value : funds * 5 / 100
        }("");

        (bool artistShare,) = 0x289660e62ff872536330938eb843607FC53E0a34.call{
        value : funds * 30 / 100
        }("");

        (bool costShare,) = 0xc27aa218950d40c2cCC74241a3d0d779b52666f3.call{
        value : funds * 10 / 100
        }("");

        (bool artistAndOperationalShare,) = 0xDEEf09D53355E838db08E1DBA9F86a5A7DfF2124.call{
        value : address(this).balance
        }("");

        require(
            devShare &&
            modsShare &&
            artistShare &&
            operationalShare &&
            costShare &&
            artistAndOperationalShare,
            "funds were not sent properly"
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ISarugamiGamaSummon {
    function mint(address, uint256) external returns (uint256);
    function ownerOf(uint256) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ISarugami {
    function mint(address, uint256) external returns (uint256);
    function ownerOf(uint256) external returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
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
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
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