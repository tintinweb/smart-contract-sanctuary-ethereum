// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

/**
  __  __ ______ _______       ____   ____ _______    _____  ____   _____ _____ ______ _________     __
 |  \/  |  ____|__   __|/\   |  _ \ / __ \__   __|  / ____|/ __ \ / ____|_   _|  ____|__   __\ \   / /
 | \  / | |__     | |  /  \  | |_) | |  | | | |    | (___ | |  | | |      | | | |__     | |   \ \_/ / 
 | |\/| |  __|    | | / /\ \ |  _ <| |  | | | |     \___ \| |  | | |      | | |  __|    | |    \   /  
 | |  | | |____   | |/ ____ \| |_) | |__| | | |     ____) | |__| | |____ _| |_| |____   | |     | |   
 |_|  |_|______|  |_/_/    \_\____/ \____/  |_|    |_____/ \____/ \_____|_____|______|  |_|     |_|                                                                                                                                                                                                                                   
                             
 */

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @notice Represents NFT Smart Contract
 */
contract IMetaBotSocietyERC721 {
    /** 
     * @dev ERC-721 INTERFACE 
     */
    function ownerOf(uint256 tokenId) public view virtual returns (address) {}

    /** 
     * @dev CUSTOM INTERFACE 
     */
    function mintTo(uint256 amount, address _to) external {}
}

/**
 * @title MetaBotSocietyPreSaleLimitedContract.
 *
 * @notice This Smart Contract can be used to sell any fixed amount of NFTs where only permissioned
 * wallets are allowed to buy. Buying is limited to a certain time period.
 *
 * @dev The primary mode of verifying permissioned actions is through Merkle Proofs
 * which are generated off-chain.
 */
contract MetaBotSocietyPreSaleLimitedContract is Ownable {

    /** 
     * @notice The Smart Contract of the MetaBotSocietyNFT
     * @dev MetaBotSocietyNFT Smart Contract 
     */
    IMetaBotSocietyERC721 public immutable nft;
    
    /** 
     * @dev MINT DATA 
     */
    uint256 internal safetyMargin = 2 minutes;
    uint256 public startTimePhaseOne = 1646074800 - safetyMargin; // 28 Feb 2022 19:00 UTC
    uint256 public startTimePhaseTwo = 1646334000 - safetyMargin; // 3 Mar 2022 19:00 UTC
    uint256 public startTimeOpen = 1646679600 - safetyMargin; // 7 Mar 2022 19:00 UTC

    uint256 public pricePhaseOne = 0.075 ether;
    uint256 public pricePhaseTwo = 0.08 ether;
    uint256 public priceOpen = 0.1 ether;
    
    uint256 public maxSupplyPhaseOne = 100;
    uint256 public maxSupplyPhaseTwo = 1500;
    uint256 public totalSupply = 9999;
    uint256 public limitOpen = 20;

    mapping(uint256 => uint256) public mintedPhases;
    uint256 public mintedOpen;
    mapping(address => mapping(uint256 => uint256)) public addressToMints;

     /** 
      * @dev MERKLE ROOTS 
      */
    bytes32 public merkleRoot = 0x17b84e7900ba3240c9a01ac84a0c750b4e0dabb93e651f3cdd00f56db8b136ef;

    /**
     * @dev PAYMENT
     */
    address[] public recipients;
    uint256[] public shares;
    
    /**
     * @dev Events
     */
    
    /**
     * @dev Setter Events.
     */
    event setStartTimePhaseOneEvent(uint256 indexed startTime);
    event setStartTimePhaseTwoEvent(uint256 indexed startTime);

    event setPricePhaseOneEvent(uint256 indexed price);
    event setPricePhaseTwoEvent(uint256 indexed price);

    event setMaxSupplyPhaseOneEvent(uint256 indexed maxSupply);
    event setMaxSupplyPhaseTwoEvent(uint256 indexed maxSupply);

    event setMerkleRootEvent(bytes32 indexed merkleRoot);

    event setStartTimeOpenEvent(uint256 indexed time);
    event setTotalSupplyEvent(uint256 indexed supply);
    event setPriceOpenEvent(uint256 indexed price);
    event setLimitOpenEvent(uint256 indexed limit);

    event setRecipientsEvent(address[] indexed addresses, uint256[] indexed shares);

    /**
     * @dev Sale Events.
     */
    event Purchase(address indexed buyer, uint256 indexed amount, uint256 indexed phase);
    event ReceivedEther(address indexed sender, uint256 indexed amount);
    event WithdrawAllEvent(address indexed to, uint256 amount);

    constructor(
        address _nftaddress
    ) Ownable() {
        nft = IMetaBotSocietyERC721(_nftaddress);      
    }
 
    /**
     * @dev SALE
     */

    /**
     * @notice Returns the max supply for the public sale.
     * @dev Is calculated by substracting the sales made in the
     * first and second phases from the total supply
     */
    function maxSupplyOpen() public view returns(uint256) {
        return totalSupply - mintedPhases[1] - mintedPhases[2];
    }

    /**
     * @notice Validates the sale data for each phase per user
     *
     * @dev For each phase validates that the time is correct,
     * that the ether supplied is correct and that the purchase 
     * amount doesn't exceed the max amount
     *
     * @param amount. The amount the user want's to purchase
     * @param phase. The sale phase of the user
     */
    function validatePhaseSpecificPurchase(uint256 amount, uint256 phase) internal {
        if (phase == 1) {                          
            require(msg.value >= pricePhaseOne * amount, "ETHER SENT NOT CORRECT");
            require(mintedPhases[1] + amount <= maxSupplyPhaseOne, "BUY AMOUNT GOES OVER MAX SUPPLY");
            require(block.timestamp >= startTimePhaseOne, "PHASE ONE SALE HASN'T STARTED YET");

        } else if (phase == 2) {                     
            require(msg.value >= pricePhaseTwo * amount, "ETHER SENT NOT CORRECT");
            require(mintedPhases[2] + amount <= maxSupplyPhaseTwo, "BUY AMOUNT GOES OVER MAX SUPPLY");
            require(block.timestamp >= startTimePhaseTwo, "PHASE TWO SALE HASN'T STARTED YET");

        } else {
            revert("INCORRECT PHASE");
        }
    }

    /**
     * @notice Function to buy one or more NFTs.
     * @dev First the Merkle Proof is verified.
     * Then the buy is verified with the data embedded in the Merkle Proof.
     * Finally the NFTs are bought to the user's wallet.
     *
     * @param amount. The amount of NFTs to buy.     
     * @param buyMaxAmount. The max amount the user can buy.
     * @param phase. The permissioned sale phase.
     * @param proof. The Merkle Proof of the user.
     */
    function buyPhases(uint256 amount, uint256 buyMaxAmount, uint256 phase, bytes32[] calldata proof) 
        external 
        payable {

        /// @dev Verifies Merkle Proof submitted by user.
        /// @dev All mint data is embedded in the merkle proof.

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, buyMaxAmount, phase));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "INVALID PROOF");

        /// @dev Verify that user can perform permissioned sale based on the provided parameters.

        require(address(nft) != address(0), "NFT SMART CONTRACT NOT SET");
        require(merkleRoot != "", "PERMISSIONED SALE CLOSED");
        
        require(amount > 0, "HAVE TO BUY AT LEAST 1");
        require(addressToMints[msg.sender][phase] + amount <= buyMaxAmount, "BUY AMOUNT EXCEEDS MAX FOR USER");            

        /// @dev Verify that user can perform permissioned sale based on phase of user

        validatePhaseSpecificPurchase(amount, phase);

        /// @dev Permissioned sale closes as soon as public sale starts
        require(block.timestamp < startTimeOpen, "PERMISSIONED SALE CLOSED");

        /// @dev Update mint values

        mintedPhases[phase] += amount;
        addressToMints[msg.sender][phase] += amount;
        nft.mintTo(amount, msg.sender);

        emit Purchase(msg.sender, amount, phase);
    }

    /**
     * @notice Function to buy one or more NFTs.
     *
     * @param amount. The amount of NFTs to buy.
     */
    function buyOpen(uint256 amount) 
        external 
        payable {
        
        /// @dev Verifies that user can perform open mint based on the provided parameters.

        require(address(nft) != address(0), "NFT SMART CONTRACT NOT SET");
        require(block.timestamp >= startTimeOpen, "OPEN SALE CLOSED");

        require(amount > 0, "HAVE TO BUY AT LEAST 1");

        require(addressToMints[msg.sender][3] + amount <= limitOpen, "MINT AMOUNT EXCEEDS MAX FOR USER");
        require(mintedOpen + amount <= maxSupplyOpen(), "MINT AMOUNT GOES OVER MAX SUPPLY");
        require(msg.value >= priceOpen * amount, "ETHER SENT NOT CORRECT");

        /// @dev Updates contract variables and mints `amount` NFTs to users wallet
        
        mintedOpen += amount;
        addressToMints[msg.sender][3] += amount;
        nft.mintTo(amount, msg.sender);

        emit Purchase(msg.sender, amount, 3);
    }

    /**
     * @dev VIEW
     */

    /**
     * @dev Returns the total amount of NFTs minted 
     * accross all phases.
     */
    function totalMinted() external view returns(uint256) {
        return mintedPhases[1] + mintedPhases[2] + mintedOpen;
    }

    /**
     * @dev Returns the total amount of NFTs minted 
     * accross all phases by a specific wallet.
     */
    function totalMintedByAddress(address user) external view returns(uint256) {
        return addressToMints[user][1] + addressToMints[user][2] + addressToMints[user][3];
    }

    /**
     * @dev Returns the total amount of NFTs left
     * accross all phases.
     */
    function nftsLeft() external view returns(uint256) {
        return totalSupply - mintedPhases[1] - mintedPhases[2] - mintedOpen;
    }

    /** 
     * @dev OWNER ONLY 
     */

    /**
     * @notice Change the start time of phase one.
     *
     * @param newStartTime. The new start time.
     */
    function setStartTimePhaseOne(uint256 newStartTime) external onlyOwner {
        startTimePhaseOne = newStartTime;
        emit setStartTimePhaseOneEvent(newStartTime);
    }

    /**
     * @notice Change the start time of phase two.
     *
     * @param newStartTime. The new start time.
     */
    function setStartTimePhaseTwo(uint256 newStartTime) external onlyOwner {
        startTimePhaseTwo = newStartTime;
        emit setStartTimePhaseTwoEvent(newStartTime);
    }

    /**
     * @notice Change the price of phase one.
     *
     * @param newPrice. The new price.
     */
    function setPricePhaseOne(uint256 newPrice) external onlyOwner {
        pricePhaseOne = newPrice;
        emit setPricePhaseOneEvent(newPrice);
    }

    /**
     * @notice Change the price of phase two.
     *
     * @param newPrice. The new price.
     */
    function setPricePhaseTwo(uint256 newPrice) external onlyOwner {
        pricePhaseTwo = newPrice;
        emit setPricePhaseTwoEvent(newPrice);
    }

    /**
     * @notice Change the maximum supply of phase one.
     *
     * @param newMaxSupply. The new max supply.
     */
    function setMaxSupplyPhaseOne(uint256 newMaxSupply) external onlyOwner {
        maxSupplyPhaseOne = newMaxSupply;
        emit setMaxSupplyPhaseOneEvent(newMaxSupply);
    }

    /**
     * @notice Change the maximum supply of phase two.
     *
     * @param newMaxSupply. The new max supply.
     */
    function setMaxSupplyPhaseTwo(uint256 newMaxSupply) external onlyOwner {
        maxSupplyPhaseTwo = newMaxSupply;
        emit setMaxSupplyPhaseTwoEvent(newMaxSupply);
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
     * @notice Change the start time of the public sale.
     *
     * @param time. The new start time.
     */
    function setStartTimeOpen(uint256 time) external onlyOwner {
        startTimeOpen = time;
        emit setStartTimeOpenEvent(time);
    }

    /**
     * @notice Change the total supply.
     *
     * @param supply. The new max supply.
     */
    function setTotalSupply(uint256 supply) external onlyOwner {
        totalSupply = supply;
        emit setTotalSupplyEvent(supply);
    }

    /**
     * @notice Change the price of public sale.
     *
     * @param price. The new price.
     */
    function setPriceOpen(uint256 price) external onlyOwner {
        priceOpen = price;
        emit setPriceOpenEvent(price);
    }

    /**
     * @notice Change the maximum purchasable NFTs per wallet during public sale.
     *
     * @param limit. The new limit.
     */
    function setLimitOpen(uint256 limit) external onlyOwner {
        limitOpen = limit;
        emit setLimitOpenEvent(limit);
    }    

    /**
     * @notice Set recipients for funds collected in smart contract.
     *
     * @dev Overrides old recipients and shares
     *
     * @param _addresses. The addresses of the new recipients.
     * @param _shares. The shares corresponding to the recipients.
     */
    function setRecipients(address[] calldata _addresses, uint256[] calldata _shares) external onlyOwner {
        require(_addresses.length > 0, "HAVE TO PROVIDE AT LEAST ONE RECIPIENT");
        require(_addresses.length == _shares.length, "PAYMENT SPLIT NOT CONFIGURED CORRECTLY");

        delete recipients;
        delete shares;

        for (uint i = 0; i < _addresses.length; i++) {
            recipients[i] = _addresses[i];
            shares[i] = _shares[i];
        }

        emit setRecipientsEvent(_addresses, _shares);
    }

    /**
     * @dev FINANCE
     */

    /**
     * @notice Allows owner to withdraw funds generated from sale to the specified recipients.
     *
     */
    function withdrawAll() external {
        bool senderIsRecipient = false;
        for (uint i = 0; i < recipients.length; i++) {
            senderIsRecipient = senderIsRecipient || (msg.sender == recipients[i]);
        }
        require(senderIsRecipient, "CAN ONLY BE CALLED BY RECIPIENT");
        require(recipients.length > 0, "CANNOT WITHDRAW TO ZERO ADDRESS");
        require(recipients.length == shares.length, "PAYMENT SPLIT NOT CONFIGURED CORRECTLY");

        uint256 contractBalance = address(this).balance;

        require(contractBalance > 0, "NO ETHER TO WITHDRAW");

        for (uint i = 0; i < recipients.length; i++) {
            address _to = recipients[i];
            uint256 _amount = contractBalance * shares[i] / 1000;
            payable(_to).transfer(_amount);
            emit WithdrawAllEvent(_to, _amount);
        }        
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
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/MerkleProof.sol)

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