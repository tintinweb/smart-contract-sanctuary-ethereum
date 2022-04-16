// SPDX-License-Identifier: MIT
// Developed by itxToledo

pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @notice Represents MetaGodsERC721 Smart Contract
 */
contract IMetaGodsERC721 {
    /**
     * @dev ERC-721 INTERFACE
     */
    function ownerOf(uint256 tokenId) public view virtual returns (address) {}

    /**
     * @dev CUSTOM INTERFACE
     */
    function mintTo(uint256 amount, address _to) external {}

    function maxMintPerTransaction() public returns (uint256) {}
}

/**
 * @title NFTPreSaleContract.
 *
 * @author itxToledo
 *
 * @notice This Smart Contract can be used to sell any fixed amount of NFTs where only permissioned
 * wallets are allowed to buy. Buying is limited to a certain time period.
 *
 * @dev The primary mode of verifying permissioned actions is through Merkle Proofs
 * which are generated off-chain.
 */
contract NFTPreSale is Ownable {
    /**
     * @notice The Smart Contract of the NFT being sold
     * @dev ERC-721 Smart Contract
     */
    IMetaGodsERC721 public immutable nft;

    /**
     * @dev MINT DATA
     */
    uint256 public publicMintPrice = 0.0888 * 1e16;
    uint256 public publicMaxMintPerWallet = 2;
    bool public isPublicSale = false;

    uint256 public maxSupply = 888;
    uint256 public minted = 0;

    mapping(address => uint256) public addressToMints;

    /**
     * @dev MERKLE ROOTS
     */
    bytes32 public merkleRoot = "";

    /**
     * @dev Events
     */
    event ReceivedEther(address indexed sender, uint256 indexed amount);
    event Purchase(address indexed buyer, uint256 indexed amount);
    event setMaxSupplyEvent(uint256 indexed maxSupply);
    event setMerkleRootEvent(bytes32 indexed merkleRoot);
    event WithdrawAllEvent(address indexed to, uint256 amount);
    event setPublicMintPriceEvent(uint256 indexed publicMintPrice);
    event setPublicMaxMintPerWalletEvent(
        uint256 indexed publicMaxMintPerWallet
    );
    event setIsPublicSaleEvent(bool indexed isPublicSale);

    constructor(address _nftaddress) Ownable() {
        nft = IMetaGodsERC721(_nftaddress);
    }

    /**
     * @dev SALE
     */

    modifier canMint(uint256 amount) {
        require(address(nft) != address(0), "NFT SMART CONTRACT NOT SET");
        require(amount > 0, "HAVE TO BUY AT LEAST 1");
        require(
            amount <= nft.maxMintPerTransaction(),
            "CANNOT MINT MORE PER TX"
        );
        require(
            minted + amount <= maxSupply,
            "MINT AMOUNT GOES OVER MAX SUPPLY"
        );
        _;
    }

    /// @dev Updates contract variables and mints `amount` NFTs to users wallet
    function computeNewPurchase(uint256 amount) internal {
        minted += amount;
        addressToMints[msg.sender] += amount;
        nft.mintTo(amount, msg.sender);

        emit Purchase(msg.sender, amount);
    }

    /**
     * @notice Function to buy one or more NFTs.
     * @dev First the Merkle Proof is verified.
     * Then the mint is verified with the data embedded in the Merkle Proof.
     * Finally the NFTs are minted to the user's wallet.
     *
     * @param amount. The amount of NFTs to buy.
     * @param mintStart. The start date of the mint.
     * @param mintEnd. The end date of the mint.
     * @param mintPrice. The mint price for the user.
     * @param mintMaxAmount. The max amount the user can mint.
     * @param proof. The Merkle Proof of the user.
     */
    function buy(
        uint256 amount,
        uint256 mintStart,
        uint256 mintEnd,
        uint256 mintPrice,
        uint256 mintMaxAmount,
        bytes32[] calldata proof
    ) external payable canMint(amount) {
        /// @dev Verifies Merkle Proof submitted by user.
        /// @dev All mint data is embedded in the merkle proof.

        bytes32 leaf = keccak256(
            abi.encodePacked(
                msg.sender,
                mintStart,
                mintEnd,
                mintPrice,
                mintMaxAmount
            )
        );
        require(MerkleProof.verify(proof, merkleRoot, leaf), "INVALID PROOF");

        /// @dev Verifies that user can mint based on the provided parameters.

        require(merkleRoot != "", "PERMISSIONED SALE CLOSED");

        require(block.timestamp >= mintStart, "SALE HASN'T STARTED YET");
        require(block.timestamp < mintEnd, "SALE IS CLOSED");

        require(
            addressToMints[_msgSender()] + amount <= mintMaxAmount,
            "MINT AMOUNT EXCEEDS MAX FOR USER"
        );

        require(msg.value == mintPrice * amount, "ETHER SENT NOT CORRECT");

        computeNewPurchase(amount);
    }

    /**
     * @notice Function to buy one or more NFTs in public sale.
     * @param amount. The amount of NFTs to buy.
     */
    function publicBuy(uint256 amount) external payable canMint(amount) {
        require(isPublicSale == true, "PUBLIC SALE IS DISABLED");
        require(
            msg.value == publicMintPrice * amount,
            "ETHER SENT NOT CORRECT"
        );

        require(
            addressToMints[_msgSender()] + amount <= publicMaxMintPerWallet,
            "MINT AMOUNT EXCEEDS MAX FOR USER"
        );

        computeNewPurchase(amount);
    }

    /**
     * @dev OWNER ONLY
     */

    /**
     * @notice Change the maximum supply of NFTs that are for sale.
     *
     * @param newMaxSupply. The new max supply.
     */
    function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
        maxSupply = newMaxSupply;
        emit setMaxSupplyEvent(newMaxSupply);
    }

    /**
     * @notice Change the merkleRoot of the sale.
     *
     * @param newRoot. The new merkleRoot.
     */
    function setMerkleRoot(bytes32 newRoot) external onlyOwner {
        merkleRoot = newRoot;
        emit setMerkleRootEvent(newRoot);
    }

    /**
     * @notice Change the public mint price per NFT.
     *
     * @param newPublicMintPrice. The new public mint price per NFT.
     */
    function setPublicMintPrice(uint256 newPublicMintPrice) external onlyOwner {
        publicMintPrice = newPublicMintPrice;
        emit setPublicMintPriceEvent(publicMintPrice);
    }

    /**
     * @notice Change the public max mint amount per user.
     *
     * @param newPublicMaxMintPerWallet. The new public max mint amount per user.
     */
    function setPublicMaxMintPerWallet(uint256 newPublicMaxMintPerWallet)
        external
        onlyOwner
    {
        publicMaxMintPerWallet = newPublicMaxMintPerWallet;
        emit setPublicMaxMintPerWalletEvent(newPublicMaxMintPerWallet);
    }

    /**
     * @notice Change the public sale state.
     *
     * @param newIsPublicSale. The new public sale state.
     */
    function setIsPublicSale(bool newIsPublicSale) external onlyOwner {
        isPublicSale = newIsPublicSale;
        emit setIsPublicSaleEvent(newIsPublicSale);
    }

    /**
     * @dev FINANCE
     */

    /**
     * @notice Allows owner to withdraw funds generated from sale.
     *
     * @param _to. The address to send the funds to.
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