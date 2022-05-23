// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface IFlowerFam {
    function ownerOf(uint256 tokenId) external view returns (address);
     function mint(
        address sender,
        uint256 amount
    ) external;
    function getLastMintedId() external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

interface IFlowerFamMintPass {
    function balanceOf(address owner) external view returns (uint256);
    function userPassesLeft(address owner) external view returns (uint256);
    function redeemPasses(address owner, uint256 amount) external;
}

interface IFlowerFamEcoSystem {
    function mintAndStakeFlowerFamFlower(address staker, uint256 flowerFamId) external;
    function mintAndBatchStakeFlowerFamFlowers(address staker, uint256[] calldata flowerFamIds) external; 
}

contract FlowerFamMinter is Ownable {

    IFlowerFam public immutable flowerFam;
    IFlowerFamMintPass public immutable flowerFamMintPass;
    IFlowerFamEcoSystem public immutable flowerFamEcoSystem;

    uint256 public whitelistRound = 0;
    uint256 public giveawaysRound = 1;
    uint256 public raffleRound = 2;
    uint256 public publicRound = 3;

    uint256 public maxSupply = 6969;
    uint256 public price = 0.069 ether;

    uint256 public mintDuration = 69 minutes; /// @dev unix timestamp duration of each mint round.
    uint256 public startTimeWL = 1653148800 - 1 minutes; /// @dev unix timestamp of start time of whitelist mint (first round).
    uint256 public startTimeGiveaway = startTimeWL + mintDuration;
    uint256 public startTimeRaffle = startTimeGiveaway + mintDuration;
    uint256 public startTimePublic = startTimeRaffle + mintDuration;

    mapping(uint256 => uint256) public roundToMintLimits; /// @dev mint per wallet limit per round
    mapping(address => mapping(uint256 => uint256)) public roundToMinted; /// @dev number of flowers minted per wallet per round
    mapping(uint256 => bytes32) public roundToMerkleRoot; /// @dev maps each round to the merkle root containing wallets allowed to mint during that round

    constructor(
        address _flowerFamNFT,
        address _flowerFamMintPass,
        address _flowerFamEcoSystem
    ) Ownable() {
        flowerFam = IFlowerFam(_flowerFamNFT);
        flowerFamMintPass = IFlowerFamMintPass(_flowerFamMintPass);
        flowerFamEcoSystem = IFlowerFamEcoSystem(_flowerFamEcoSystem);

        roundToMintLimits[whitelistRound] = 2;
        roundToMintLimits[giveawaysRound] = 1;
        roundToMintLimits[raffleRound] = 2;
        roundToMintLimits[publicRound] = 6969;
    }

    receive() external payable {}

    function whitelistMint(uint256 amount, bytes32[] calldata proof, bool stake) external payable {
        require(block.timestamp >= startTimeWL, "Whitelist mint not started");
        require(block.timestamp < startTimeWL + mintDuration, "Whitelist mint closed");
        require(msg.value >= amount * price, "Not enough eth sent");

        uint256 mintAmount = amount;
        uint256 passesLeft = flowerFamMintPass.userPassesLeft(msg.sender); /// @dev passes left = mints left from passes ( each pass = 2 mints )

        if (passesLeft > 0) {
            uint256 amountFromPasses = passesLeft < mintAmount ? passesLeft : mintAmount;

            mintAmount -= amountFromPasses;
            flowerFamMintPass.redeemPasses(msg.sender, amountFromPasses);
            _mintFromMintPass(msg.sender, amountFromPasses);
        }
        
        if (mintAmount > 0)
            _merkleProofMint(msg.sender, mintAmount, proof, whitelistRound);
        
        if (stake)
            _stakeMintedFlowers(amount);
    }

    function giveawayMint(uint256 amount, bytes32[] calldata proof, bool stake) external payable {
        require(block.timestamp >= startTimeGiveaway, "Giveaway mint not started");
        require(block.timestamp < startTimeGiveaway + mintDuration, "Giveaway mint closed");
        require(msg.value >= amount * price, "Not enough eth sent");

        _merkleProofMint(msg.sender, amount, proof, giveawaysRound);

        if (stake)
            _stakeMintedFlowers(amount);
    }

    function raffleMint(uint256 amount, bytes32[] calldata proof, bool stake) external payable {
        require(block.timestamp >= startTimeRaffle, "Raffle mint not started");
        require(block.timestamp < startTimeRaffle + mintDuration, "Raffle mint closed");
        require(msg.value >= amount * price, "Not enough eth sent");
       
        _merkleProofMint(msg.sender, amount, proof, raffleRound);

        if (stake)
            _stakeMintedFlowers(amount);
    }

    function publicMint(uint256 amount, bool stake) external payable {
        require(block.timestamp >= startTimePublic, "Public mint not started");        
        require(flowerFam.totalSupply() + amount <= maxSupply, "Flower Fam NFT is sold out");
        require(msg.value >= amount * price, "Not enough eth sent");

        flowerFam.mint(msg.sender, amount);  

        if (stake)
            _stakeMintedFlowers(amount);      
    }

    function totalMintsOfUser(address user) external view returns (uint256) {
        return  roundToMinted[user][whitelistRound] + 
                roundToMinted[user][giveawaysRound] + 
                roundToMinted[user][raffleRound] + 
                roundToMinted[user][publicRound];
    }

    function getActiveRound() external view returns (uint256) {
        uint256 activeRound = 0;
        bool hasActiveRound = false;

        if(block.timestamp >= startTimeWL && block.timestamp < startTimeWL + mintDuration) {
            activeRound = 0;
            hasActiveRound = true;
        }

        if(block.timestamp >= startTimeGiveaway && block.timestamp < startTimeGiveaway + mintDuration) {
            activeRound = 1;
            hasActiveRound = true;
        }

        if(block.timestamp >= startTimeRaffle && block.timestamp < startTimeRaffle + mintDuration) {
            activeRound = 2;
            hasActiveRound = true;
        }

        if(block.timestamp >= startTimePublic && block.timestamp < startTimePublic + mintDuration) {
            activeRound = 3;
            hasActiveRound = true;
        }

        if(hasActiveRound) {
            return activeRound;
        }
        else {
            revert("No active round running");
        }
    }

    function getSupplyLeft() external view returns (uint256) {
        uint256 totalSupply = flowerFam.totalSupply();
        if (totalSupply > maxSupply)
            return 0;
        return maxSupply - totalSupply;
    }

    function getUserMintedAtRound(address sender, uint256 round) external view returns (uint256) {
        return roundToMintLimits[round] - roundToMinted[sender][round];
    }

    function setMintDuration(uint256 newduration) external onlyOwner {
        mintDuration = newduration;
    }

    function setStartTimeWL(uint256 newStartTimeWL) external onlyOwner {
        startTimeWL = newStartTimeWL;
    }

    function setStartTimeGiveaway(uint256 newStartTimeGiveaway) external onlyOwner {
        startTimeGiveaway = newStartTimeGiveaway;
    }

    function setStartTimeRaffle(uint256 newStartTimeRaffle) external onlyOwner {
        startTimeRaffle = newStartTimeRaffle;
    }

    function setStartTimeWaitlist(uint256 newStartTimeWaitlist) external onlyOwner {
        startTimePublic = newStartTimeWaitlist;
    }

    function setMintLimitOfRound(uint256 round, uint256 limit) external onlyOwner {
        roundToMintLimits[round] = limit;
    }

    function setMerkleRootOfRound(uint256 round, bytes32 root) external onlyOwner {
        roundToMerkleRoot[round] = root;
    }

    function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
        maxSupply = newMaxSupply;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function withdraw(address _to) external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Balance zero");
        require(_to != address(0), "Cannot transfer to null address");
        payable(_to).transfer(balance);
    }

    
    function _stakeMintedFlowers(uint256 amount) internal {
        uint256 lastMinted = flowerFam.getLastMintedId(); /// @dev the id of the flower last minted, if we use this in the same tx as minting then it gives us the last minted id we minted
        uint256 firstMinted = lastMinted + 1 - amount;  
        if (amount == 1)
            flowerFamEcoSystem.mintAndStakeFlowerFamFlower(msg.sender, lastMinted);
        else {
            uint256[] memory ids = new uint256[](amount);
            for (uint i = 0; i < amount; i++) {
                ids[i] = firstMinted + i;
            }
            flowerFamEcoSystem.mintAndBatchStakeFlowerFamFlowers(msg.sender, ids);
        }
    }

    function _merkleProofMint(address sender, uint256 amount, bytes32[] calldata proof, uint256 round) internal {
        require(amount > 0, "Invalid mint amount");
        
        bytes32 root = roundToMerkleRoot[round];
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, root, leaf), "Sender not allowed to mint in this round");

        require(roundToMinted[sender][round] + amount <= roundToMintLimits[round], "Sender exceeds max mint limit of this round");
        require(flowerFam.totalSupply() + amount <= maxSupply, "Flower Fam NFT is sold out");

        roundToMinted[sender][round] += amount;

        flowerFam.mint(msg.sender, amount);
    }

    function _mintFromMintPass(address sender, uint256 amount) internal {
        require(amount > 0, "Invalid mint amount");
        require(flowerFam.totalSupply() + amount <= maxSupply, "Flower Fam NFT is sold out");
        
        flowerFam.mint(sender, amount);
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