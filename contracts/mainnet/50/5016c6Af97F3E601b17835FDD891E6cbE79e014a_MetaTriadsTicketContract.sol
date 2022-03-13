// SPDX-License-Identifier: MIT
// Developed by KG Technologies (https://kgtechnologies.io)

pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @notice Represents MetaTriad Smart Contract
 */
contract IMetaTriads {
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
 * @title MetaTriadsTicketContract.
 *
 * @author KG Technologies (https://kgtechnologies.io).
 *
 * @notice This Smart Contract can be used to sell a fixed amount of tickets where some of them are 
 * sold to permissioned wallets and the others are sold to the general public. 
 * The tickets can then be used to mint a corresponding amount of NFTs.
 *
 * @dev The primary mode of verifying permissioned actions is through Merkle Proofs
 * which are generated off-chain.
 */
contract MetaTriadsTicketContract is Ownable {

    /** 
     * @notice The Smart Contract of MetaTriad 
     * @dev ERC-721 Smart Contract 
     */
    IMetaTriads public immutable nft;
    
    /** 
     * @dev MINT DATA 
     */    
    uint256 public phaseOneMaxSupply = 300;
    uint256 public phaseTwoMaxSupply = 2000;    
    uint256 public pricePermissioned = 0.09 ether;
    mapping(uint256 => uint256) public boughtPermissioned;

    uint256 public marginOfSafety = 2 minutes;
    uint256 public phaseOneStartTime = 1; //1647246600 - marginOfSafety
    uint256 public phaseOneDuration = 100 * 365 days; // 30 minutes
    uint256 public phaseTwoStartTime = 1; //1647248400 - marginOfSafety
    uint256 public phaseTwoDuration = 100 * 365 days; // 30 minutes

    uint256 public maxSupplyOpen = 7200;
    uint256 public boughtOpen = 0;
    uint256 public limitOpen = 10;
    uint256 public priceOpen = 0.18 ether;
    uint256 public startTimeOpen = 1; // 1647250200 - marginOfSafety

    uint256 public redeemStart = startTimeOpen + 1 hours - marginOfSafety;
    uint256 public redeemDuration = 1 days * 30;
    
    mapping(address => uint256) public addressToTicketsOpen;
    mapping(address => mapping(uint256 => uint256)) public addressToTicketsPermissioned;
    mapping(address => uint256) public addressToMints;    

    /// @dev Initial value is randomly generated from https://www.random.org/
    bytes32 public merkleRoot = 0xd1146eea03185df9ba3ea50f2b88a665bbc97f3f96c4846b6481c18f8e299cfb;

    /**
     * @dev GIVEAWAY 
     */
    uint256 public maxSupplyGiveaway = 500;
    uint256 public giveAwayRedeemed = 0;
    mapping(address => uint256) public addressToGiveawayRedeemed;
    bytes32 public giveAwayMerkleRoot = "";

    /**
     * @dev Events
     */
    event ReceivedEther(address indexed sender, uint256 indexed amount);
    event WithdrawAllEvent(address indexed to, uint256 amount);
    event Purchase(address indexed buyer, uint256 indexed amount, bool indexed permissioned);
    event RedeemTickets(address indexed redeemer, uint256 amount);
    event RedeemGiveAway(address indexed redeemer, uint256 amount);
 
    /// @dev Setters
    event setMaxSupplyPhaseOneEvent(uint256 indexed maxSupply);
    event setMaxSupplyPhaseTwoEvent(uint256 indexed maxSupply);
    event setMaxSupplyOpenEvent(uint256 indexed maxSupply);
    event setLimitOpenEvent(uint256 indexed limit);
    event setPriceOpenEvent(uint256 indexed price);
    event setRedeemStartEvent(uint256 indexed start);
    event setRedeemDurationEvent(uint256 indexed duration);
    event setMerkleRootEvent(bytes32 indexed merkleRoot);
    event setGiveAwayMerkleRootEvent(bytes32 indexed merkleRoot);
    event setGiveAwayMaxSupplyEvent(uint256 indexed newSupply);
    event setPricePermissionedEvent(uint256 indexed price);
    event setPhaseOneStartTimeEvent(uint256 indexed time);
    event setPhaseOneDurationEvent(uint256 indexed time);
    event setPhaseTwoStartTimeEvent(uint256 indexed time);
    event setPhaseTwoDurationEvent(uint256 indexed time);
    event setStartTimeOpenEvent(uint256 indexed time);    

    constructor(
        address _metaTriadsAddress
    ) Ownable() {
        nft = IMetaTriads(_metaTriadsAddress);
    }
 
    /**
     * @dev SALE
     */

    function phaseOneLeft() public view returns(uint256) {
        if (phaseOneMaxSupply >= boughtPermissioned[1]) {
            return phaseOneMaxSupply - boughtPermissioned[1];
        } else {
            return 0;
        }
    }

    function phaseTwoLeft() public view returns(uint256) {
        if (phaseTwoMaxSupply >= boughtPermissioned[2]) {
            return phaseTwoMaxSupply - boughtPermissioned[2];
        } else {
            return 0;
        }    
    }

    function realSupplyOpen() public view returns(uint256) {
        return maxSupplyOpen + phaseOneLeft() + phaseTwoLeft();
    }

    function openLeft() public view returns(uint256) {
        if (realSupplyOpen() >= boughtOpen) {
            return realSupplyOpen() - boughtOpen;
        } else {
            return 0;
        }
        
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
            require(block.timestamp < phaseOneStartTime + phaseOneDuration, "PHASE ONE SALE IS CLOSED");    
            require(msg.value >= priceOpen * amount, "ETHER SENT NOT CORRECT");
            require(boughtPermissioned[phase] + amount <= phaseOneMaxSupply, "BUY AMOUNT GOES OVER MAX SUPPLY");
            require(block.timestamp >= phaseOneStartTime, "PHASE ONE SALE HASN'T STARTED YET");

        } else if (phase == 2) {            
            require(block.timestamp < phaseTwoStartTime + phaseTwoDuration, "PHASE TWO SALE IS CLOSED");    
            require(msg.value >= pricePermissioned * amount, "ETHER SENT NOT CORRECT");
            require(boughtPermissioned[phase] + amount <= phaseTwoMaxSupply, "BUY AMOUNT GOES OVER MAX SUPPLY");
            require(block.timestamp >= phaseTwoStartTime, "PHASE TWO SALE HASN'T STARTED YET");

        } else {
            revert("INCORRECT PHASE");
        }
    }

    /**
     * @notice Function to buy one or more tickets.
     * @dev First the Merkle Proof is verified.
     * Then the buy is verified with the data embedded in the Merkle Proof.
     * Finally the tickets are bought to the user's wallet.
     *
     * @param amount. The amount of tickets to buy.     
     * @param buyMaxAmount. The max amount the user can buy.
     * @param phase. The permissioned sale phase.
     * @param proof. The Merkle Proof of the user.
     */
    function buyPermissioned(uint256 amount, uint256 buyMaxAmount, uint256 phase, bytes32[] calldata proof) 
        external 
        payable {

        /// @dev Verifies Merkle Proof submitted by user.
        /// @dev All mint data is embedded in the merkle proof.

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, buyMaxAmount, phase));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "INVALID PROOF");

        /// @dev Verify that user can perform permissioned sale based on the provided parameters.

        require(address(nft) != address(0), "METATRIAD NFT SMART CONTRACT NOT SET");     
        
        require(amount > 0, "HAVE TO BUY AT LEAST 1");
        require(addressToTicketsPermissioned[msg.sender][phase] + amount <= buyMaxAmount, "BUY AMOUNT EXCEEDS MAX FOR USER");            

        /// @dev verify that user can perform permissioned sale based on phase of user
        validatePhaseSpecificPurchase(amount, phase);

        boughtPermissioned[phase] += amount;           
        addressToTicketsPermissioned[msg.sender][phase] += amount;
        emit Purchase(msg.sender, amount, true);
    }

    /**
     * @notice Function to buy one or more tickets.
     *
     * @param amount. The amount of tickets to buy.
     */
    function buyOpen(uint256 amount) 
        external 
        payable {
        
        /// @dev Verifies that user can perform open sale based on the provided parameters.

        require(address(nft) != address(0), "METATRIADS NFT SMART CONTRACT NOT SET");
        require(block.timestamp >= startTimeOpen, "OPEN SALE CLOSED");

        require(amount > 0, "HAVE TO BUY AT LEAST 1");

        require(addressToTicketsOpen[msg.sender] + amount <= limitOpen, "BUY AMOUNT EXCEEDS MAX FOR USER");
        require(boughtOpen + amount <= realSupplyOpen(), "BUY AMOUNT GOES OVER MAX SUPPLY");
        require(msg.value >= priceOpen * amount, "ETHER SENT NOT CORRECT");

        /// @dev Updates contract variables and buys `amount` tickets to users wallet

        boughtOpen += amount;
        addressToTicketsOpen[msg.sender] += amount;

        emit Purchase(msg.sender, amount, false);
    }

    /**
     * @dev MINTING 
     */

    /**
     * @notice Allows users to redeem their tickets for NFTs.
     * 
     * @dev Users from Phase 1 can bypass the time block.
     */
    function redeemTickets() external {
        require(block.timestamp >= redeemStart || addressToTicketsPermissioned[msg.sender][1] > 0, "REDEEM CLOSED");
        require(block.timestamp < redeemStart + redeemDuration, "REDEEM CLOSED");

        uint256 ticketsOfSender = 
            addressToTicketsPermissioned[msg.sender][1] + 
            addressToTicketsPermissioned[msg.sender][2] + 
            addressToTicketsOpen[msg.sender];
        uint256 mintsOfSender = addressToMints[msg.sender];
        uint256 mintable = ticketsOfSender - mintsOfSender;

        require(mintable > 0, "NO MINTABLE TICKETS");

        uint256 maxMintPerTx = 100;
        uint256 toMint = mintable > maxMintPerTx ? maxMintPerTx : mintable;
        
        addressToMints[msg.sender] = addressToMints[msg.sender] + toMint;

        nft.mintTo(toMint, msg.sender);
        emit RedeemTickets(msg.sender, toMint);
    }

    /**
     * @notice Function to redeem giveaway.
     * @dev First the Merkle Proof is verified.
     * Then the redeem is verified with the data embedded in the Merkle Proof.
     * Finally the metatriads are minted to the user's wallet.
     *
     * @param redeemAmount. The amount to redeem.
     * @param proof. The Merkle Proof of the user.
     */
    function redeemGiveAway(uint256 redeemAmount, bytes32[] calldata proof) external {
        /// @dev Verifies Merkle Proof submitted by user.
        /// @dev All giveaway data is embedded in the merkle proof.

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, redeemAmount));
        require(MerkleProof.verify(proof, giveAwayMerkleRoot, leaf), "INVALID PROOF");

        /// @dev Verifies that user can perform giveaway based on the provided parameters.

        require(address(nft) != address(0), "METATRIAD NFT SMART CONTRACT NOT SET");
        require(giveAwayMerkleRoot != "", "GIVEAWAY CLOSED");

        require(redeemAmount > 0, "HAVE TO REDEEM AT LEAST 1");

        require(addressToGiveawayRedeemed[msg.sender] == 0, "GIVEAWAY ALREADY REDEEMED");
        require(giveAwayRedeemed + redeemAmount <= maxSupplyGiveaway, "GIVEAWAY AMOUNT GOES OVER MAX SUPPLY");

        /// @dev Updates contract variables and mints `redeemAmount` metatriads to users wallet

        giveAwayRedeemed += redeemAmount;
        addressToGiveawayRedeemed[msg.sender] = 1;

        nft.mintTo(redeemAmount, msg.sender);
        emit RedeemGiveAway(msg.sender, redeemAmount);
    }

    /** 
     * @dev OWNER ONLY 
     */

    /**
     * @notice Change the maximum supply of tickets that are for sale in phase one permissioned sale.
     *
     * @param newMaxSupply. The new max supply.
     */
    function setMaxSupplyPhaseOne(uint256 newMaxSupply) external onlyOwner {
        phaseOneMaxSupply = newMaxSupply;
        emit setMaxSupplyPhaseOneEvent(newMaxSupply);
    }

    /**
     * @notice Change the maximum supply of tickets that are for sale in phase two permissioned sale.
     *
     * @param newMaxSupply. The new max supply.
     */
    function setMaxSupplyPhaseTwo(uint256 newMaxSupply) external onlyOwner {
        phaseTwoMaxSupply = newMaxSupply;
        emit setMaxSupplyPhaseTwoEvent(newMaxSupply);
    }

    /**
     * @notice Change the maximum supply of tickets that are for sale in open sale.
     *
     * @param newMaxSupply. The new max supply.
     */
    function setMaxSupplyOpen(uint256 newMaxSupply) external onlyOwner {
        maxSupplyOpen = newMaxSupply;
        emit setMaxSupplyOpenEvent(newMaxSupply);
    }

    /**
     * @notice Change the limit of tickets per wallet in open sale.
     *
     * @param newLimitOpen. The new max supply.
     */
    function setLimitOpen(uint256 newLimitOpen) external onlyOwner {
        limitOpen = newLimitOpen;
        emit setLimitOpenEvent(newLimitOpen);
    }

    /**
     * @notice Change the price of tickets that are for sale in open sale.
     *
     * @param newPriceOpen. The new price.
     */
    function setPriceOpen(uint256 newPriceOpen) external onlyOwner {
        priceOpen = newPriceOpen;
        emit setPriceOpenEvent(newPriceOpen);
    }

    /**
     * @notice Change the price of tickets that are for sale in permissioned sale.
     *
     * @param newPricePermissioned. The new price.
     */
    function setPricePermissioned(uint256 newPricePermissioned) external onlyOwner {
        pricePermissioned = newPricePermissioned;
        emit setPricePermissionedEvent(newPricePermissioned);
    }

    /**
     * @notice Allows owner to change the start time of the redeem period
     *
     * @param newStart. The new start time of the redeem period
     */
    function setRedeemStart(uint256 newStart) external onlyOwner {
        redeemStart = newStart;
        emit setRedeemStartEvent(newStart);
    }

    /**
     * @notice Allows owner to change the duration of the redeem period
     *
     * @param newDuration. The new duration of the redeem period
     */
    function setRedeemDuration(uint256 newDuration) external onlyOwner {
        redeemDuration = newDuration;
        emit setRedeemDurationEvent(newDuration);
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
     * @notice Delete the merkleRoot of the sale.
     */
    function deleteMerkleRoot() external onlyOwner {
        merkleRoot = "";
        emit setMerkleRootEvent(merkleRoot);
    }

    /**
     * @notice Change the merkleRoot of the giveaway.
     *
     * @param newRoot. The new merkleRoot.
     */
    function setGiveAwayMerkleRoot(bytes32 newRoot) external onlyOwner {
        giveAwayMerkleRoot = newRoot;
        emit setGiveAwayMerkleRootEvent(newRoot);
    }

    /**
     * @notice Change the max supply for the giveaway.
     *
     * @param newSupply. The new giveaway max supply.
     */
    function setGiveAwayMaxSupply(uint256 newSupply) external onlyOwner {
        maxSupplyGiveaway = newSupply;
        emit setGiveAwayMaxSupplyEvent(newSupply);
    }    

    /**
     * @notice Change start time of the Phase One permissioned sale.
     *
     * @param newTime. The new time.
     */
    function setPhaseOneStartTime(uint256 newTime) external onlyOwner {
        phaseOneStartTime = newTime;
        emit setPhaseOneStartTimeEvent(newTime);
    }

    /**
     * @notice Change duration of the Phase One permissioned sale.
     *
     * @param newDuration. The new duration.
     */
    function setPhaseOneDuration(uint256 newDuration) external onlyOwner {
        phaseOneDuration = newDuration;
        emit setPhaseOneDurationEvent(newDuration);
    }

    /**
     * @notice Change start time of the Phase Two permissioned sale.
     *
     * @param newTime. The new time.
     */
    function setPhaseTwoStartTime(uint256 newTime) external onlyOwner {
        phaseTwoStartTime = newTime;
        emit setPhaseTwoStartTimeEvent(newTime);
    }

    /**
     * @notice Change duration of the Phase One permissioned sale.
     *
     * @param newDuration. The new duration.
     */
    function setPhaseTwoDuration(uint256 newDuration) external onlyOwner {
        phaseTwoDuration = newDuration;
        emit setPhaseTwoDurationEvent(newDuration);
    }

    /**
     * @notice Change start time of the open sale.
     *
     * @param newTime. The new time.
     */
    function setStartTimeOpen(uint256 newTime) external onlyOwner {
        startTimeOpen = newTime;
        emit setStartTimeOpenEvent(newTime);
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