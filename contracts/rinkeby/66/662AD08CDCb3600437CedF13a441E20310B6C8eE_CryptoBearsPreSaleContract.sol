// SPDX-License-Identifier: MIT
// Developed by KG Technologies (https://kgtechnologies.io)

pragma solidity 0.8.11;

/**
   _____ _______     _______ _______ ____    ____  ______          _____   _____    _____         _      ______ 
  / ____|  __ \ \   / /  __ \__   __/ __ \  |  _ \|  ____|   /\   |  __ \ / ____|  / ____|  /\   | |    |  ____|
 | |    | |__) \ \_/ /| |__) | | | | |  | | | |_) | |__     /  \  | |__) | (___   | (___   /  \  | |    | |__   
 | |    |  _  / \   / |  ___/  | | | |  | | |  _ <|  __|   / /\ \ |  _  / \___ \   \___ \ / /\ \ | |    |  __|  
 | |____| | \ \  | |  | |      | | | |__| | | |_) | |____ / ____ \| | \ \ ____) |  ____) / ____ \| |____| |____ 
  \_____|_|  \_\ |_|  |_|      |_|  \____/  |____/|______/_/    \_\_|  \_\_____/  |_____/_/    \_\______|______|                                                                                                                                                                                                                                                                                                                                  
 */

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @notice Represents NFT Smart Contract
 */
contract ICryptoBearsERC721 {
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
 * @title CryptoBearsPreSaleContract.
 *
 * @author KG Technologies (https://kgtechnologies.io).
 *
 * @notice This Smart Contract can be used to sell any fixed amount of NFTs where only permissioned
 * wallets are allowed to buy. Buying is limited to a certain time period.
 *
 * @dev The primary mode of verifying permissioned actions is through Merkle Proofs
 * which are generated off-chain.
 */
contract CryptoBearsPreSaleContract is Ownable {

    /** 
     * @notice The Smart Contract of the NFT being sold 
     * @dev ERC-721 Smart Contract 
     */
    ICryptoBearsERC721 public immutable nft;

    /**
     * @notice Crypto Bull Society NFT address
     */
    address public immutable bulls;
    
    /** 
     * @dev MINT DATA 
     */
    uint256 public startTimeOpen = 1644606000;
    uint256 public startTimeWhitelist = startTimeOpen - 30 minutes;

    uint256 public price = 0.22 ether;
    uint256 public maxSupply = 1111 - 52;
    uint256 public minted = 0;
    mapping(address => uint256) public addressToMints;

     /** 
      * @dev MERKLE ROOTS 
      */
    bytes32 public merkleRoot = "";

    /**
     * @dev CLAIMING
     */
    uint256 public claimStart = 1644692400;
    mapping(uint256 => uint256) hasBullClaimed; // 0 = false | 1 = true

    /**
     * @dev DEVELOPER
     */
    address public immutable devAddress;
    uint256 public immutable devShare;
    
    /**
     * @dev Events
     */
    event ReceivedEther(address indexed sender, uint256 indexed amount);
    event Purchase(address indexed buyer, uint256 indexed amount);
    event Claim(address indexed claimer, uint256 indexed amount);
    event setStartTimeOpenEvent(uint256 indexed startTime);
    event setStartTimeWhitelistEvent(uint256 indexed startTime);
    event setPriceEvent(uint256 indexed price);
    event setMaxSupplyEvent(uint256 indexed maxSupply);
    event setClaimStartEvent(uint256 indexed time);
    event setMerkleRootEvent(bytes32 indexed merkleRoot);
    event WithdrawAllEvent(address indexed to, uint256 amount);

    constructor(
        address _nftaddress
    ) Ownable() {
        nft = ICryptoBearsERC721(_nftaddress);
        bulls = 0x469823c7B84264D1BAfBcD6010e9cdf1cac305a3;
        devAddress = 0x841d534CAa0993c677f21abd8D96F5d7A584ad81;
        devShare = 1;
    }
 
    /**
     * @dev SALE
     */

    /**
     * @notice Function to buy one or more NFTs.
     * @dev First the Merkle Proof is verified.
     * Then the mint is verified with the data embedded in the Merkle Proof.
     * Finally the NFTs are minted to the user's wallet.
     *
     * @param amount. The amount of NFTs to buy.
     * @param mintMaxAmount. The max amount the user can mint.
     * @param phase. The phase of the sale.
     * @param proof. The Merkle Proof of the user.
     */
    function buy(uint256 amount, uint256 mintMaxAmount, uint256 phase, bytes32[] calldata proof) 
        external 
        payable {

        /// @dev Verifies Merkle Proof submitted by user.
        /// @dev All mint data is embedded in the merkle proof.

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, mintMaxAmount, phase));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "INVALID PROOF");

        /// @dev Verifies that user can mint based on the provided parameters.   

        require(address(nft) != address(0), "NFT SMART CONTRACT NOT SET");
        require(merkleRoot != "", "PERMISSIONED SALE CLOSED");
        
        require(amount > 0, "HAVE TO BUY AT LEAST 1");

        require(amount <= nft.maxMintPerTransaction(), "CANNOT MINT MORE PER TX");
        require(addressToMints[msg.sender] + amount <= mintMaxAmount, "MINT AMOUNT EXCEEDS MAX FOR USER");
        require(minted + amount <= maxSupply, "MINT AMOUNT GOES OVER MAX SUPPLY");
        require(msg.value >= price * amount, "ETHER SENT NOT CORRECT");

        /// @dev allow minting at two different times
        if (phase == 1) {
            require(block.timestamp >= startTimeWhitelist, "SALE HASN'T STARTED YET");
        } else if (phase == 2) {
            require(block.timestamp >= startTimeOpen, "SALE HASN'T STARTED YET");
        } else {
            revert("INCORRECT PHASE");
        }

        /// @dev Updates contract variables and mints `amount` NFTs to users wallet

        minted += amount;
        addressToMints[msg.sender] += amount;
        nft.mintTo(amount, msg.sender);

        emit Purchase(msg.sender, amount);
    }

    /**
     * @dev CLAIMING
     */

    /**
     * @notice Claim bears by providing your crypto bull Ids
     * @dev Mints amount of bears to sender as valid crypto bulls 
     * provided. Validity depends on ownership and not having claimed yet.
     *
     * @param bullIds. The tokenIds of the bulls.
     */
    function claimBears(uint256[] calldata bullIds) external onlyOwner {
        require(address(nft) != address(0), "BEARS NFT NOT SET");
        require(bulls != address(0), "BULLS NFT NOT SET");
        require(bullIds.length > 0, "NO IDS SUPPLIED");
        require(block.timestamp >= claimStart, "CANNOT CLAIM YET");

        /// @dev Check if sender is owner of all bulls and that they haven't claimed yet
        /// @dev Update claim status of each bull
        for (uint256 i = 0; i < bullIds.length; i++) {
            uint256 bullId = bullIds[i];
            require(IERC721( bulls ).ownerOf(bullId) == msg.sender, "NOT OWNER OF BULL");
            require(hasBullClaimed[bullId] == 0, "BULL HAS ALREADY CLAIMED BEAR");
            hasBullClaimed[bullId] = 1;
        }

        nft.mintTo(bullIds.length, msg.sender);
        emit Claim(msg.sender, bullIds.length);
    }

    /**
     * @notice View which of your bulls can still claim bears
     * @dev Given an array of bull ids returns a subset of ids that
     * can still claim a bear. Used off chain to provide input of claimBears method.
     *
     * @param bullIds. The tokenIds of the bulls.
     */
    function getNotClaimedBullsOfOwner(uint256[] calldata bullIds) external view returns (uint256[] memory) {
        require(bullIds.length > 0, "NO IDS SUPPLIED");

        uint256[] memory notClaimedBulls;
        uint256 counter;

        /// @dev Check if sender is owner of all bulls and that they haven't claimed yet
        /// @dev Update claim status of each bull
        for (uint256 i = 0; i < bullIds.length; i++) {
            uint256 bullId = bullIds[i];
            require(IERC721( bulls ).ownerOf(bullId) == msg.sender, "NOT OWNER OF BULL");            
            if (hasBullClaimed[bullId] == 0) {
                notClaimedBulls[counter] = bullId;
                counter++;
            }
        }

        return notClaimedBulls;
    }

    /** 
     * @dev OWNER ONLY 
     */

    /**
     * @notice Change the start time of the raffle sale.
     *
     * @param newStartTime. The new start time.
     */
    function setStartTimeOpen(uint256 newStartTime) external onlyOwner {
        startTimeOpen = newStartTime;
        emit setStartTimeOpenEvent(newStartTime);
    }

    /**
     * @notice Change the start time of the whitelist sale.
     *
     * @param newStartTime. The new start time.
     */
    function setStartTimeWhiteList(uint256 newStartTime) external onlyOwner {
        startTimeWhitelist = newStartTime;
        emit setStartTimeWhitelistEvent(newStartTime);
    }

    /**
     * @notice Change the price of the sale.
     *
     * @param newPrice. The new price.
     */
    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
        emit setPriceEvent(newPrice);
    }

    /**
     * @notice Change the startime for bulls to claim their bears;
     *
     * @param newStart. The new start time.
     */
    function setClaimStart(uint256 newStart) external onlyOwner {
        claimStart = newStart;
        emit setClaimStartEvent(newStart);
    }

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

        uint256 developerCut = contractBalance * devShare / 100;
        uint remaining = contractBalance - developerCut;

        payable(devAddress).transfer(developerCut);
        payable(_to).transfer(remaining);

        emit WithdrawAllEvent(_to, remaining);
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