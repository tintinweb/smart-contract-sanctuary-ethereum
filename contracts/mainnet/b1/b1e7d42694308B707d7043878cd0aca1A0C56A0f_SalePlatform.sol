// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./interfaces/IQuantumArt.sol";
import "./interfaces/IQuantumMintPass.sol";
import "./interfaces/IQuantumUnlocked.sol";
import "./interfaces/IQuantumKeyRing.sol";
import "./ContinuousDutchAuction.sol";
import "@rari-capital/solmate/src/auth/Auth.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract SalePlatform is ContinuousDutchAuction, ReentrancyGuard, Auth {
    using BitMaps for BitMaps.BitMap;
    using Strings for uint256;

    struct Sale {
        uint128 price;
        uint64 start;
        uint64 limit;
    }

    struct MPClaim {
        uint64 mpId;
        uint64 start;
        uint128 price;
    }

    struct Whitelist {
        uint192 price;
        uint64 start;
        bytes32 merkleRoot;
    }

    event Purchased(uint256 indexed dropId, uint256 tokenId, address to);
    event DropCreated(uint256 dropId);

    //mapping dropId => struct
    mapping (uint256 => Sale) public sales;
    mapping (uint256 => MPClaim) public mpClaims;
    mapping (uint256 => Whitelist) public whitelists;
    uint256 public defaultArtistCut; //10000 * percentage
    IQuantumArt public quantum;
    IQuantumMintPass public mintpass;
    IQuantumUnlocked public keyUnlocks;
    IQuantumKeyRing public keyRing;
    address[] public privilegedContracts;

    BitMaps.BitMap private _disablingLimiter;
    mapping (uint256 => BitMaps.BitMap) private _claimedWL;
    mapping (address => BitMaps.BitMap) private _alreadyBought;
    mapping (uint256 => uint256) private _overridedArtistCut; // dropId -> cut
    address payable private _quantumTreasury;

    //TODO: Better drop mechanism
    struct UnlockSale {
        uint128 price;
        uint64 start;
        uint64 period;
        address artist;
        uint256 overrideArtistcut;
        uint256[] enabledKeyRanges;
    }

    uint private constant SEPARATOR = 10**4;
    uint128 private _nextUnlockDropId;
    //TODO: CLEAN UP
    mapping(uint256 => mapping(uint256 => bool)) keyUnlockClaims;
    //TODO: Seperate sales mechanisms for target sales is not right.
    mapping (uint256 => UnlockSale) public keySales;

    constructor(
        address deployedQuantum,
        address deployedMP,
        address deployedKeyRing,
        address deployedUnlocks,
        address admin,
        address payable treasury,
        address authority) Auth(admin, Authority(authority)) {
        quantum = IQuantumArt(deployedQuantum);
        mintpass = IQuantumMintPass(deployedMP);
        keyRing = IQuantumKeyRing(deployedKeyRing);
        keyUnlocks = IQuantumUnlocked(deployedUnlocks);
        _quantumTreasury = treasury;
        defaultArtistCut = 8000; //default 80% for artist
    }

    modifier checkCaller {
        require(msg.sender.code.length == 0, "Contract forbidden");
        _;
    }

    modifier isFirstTime(uint256 dropId) {
        if (!_disablingLimiter.get(dropId)) {
            require(!_alreadyBought[msg.sender].get(dropId), string(abi.encodePacked("Already bought drop ", dropId.toString())));
            _alreadyBought[msg.sender].set(dropId);
        }
        _;
    }

    function setPrivilegedContracts(address[] calldata contracts) requiresAuth public {
        privilegedContracts = contracts;
    }

    function withdraw(address payable to) requiresAuth public {
        Address.sendValue(to, address(this).balance);
    }

    function premint(uint256 dropId, address[] calldata recipients) requiresAuth public {
        for(uint256 i = 0; i < recipients.length; i++) {
            uint256 tokenId = quantum.mintTo(dropId, recipients[i]);
            emit Purchased(dropId, tokenId, recipients[i]);
        }
    }

    function setMintpass(address deployedMP) requiresAuth public {
        mintpass = IQuantumMintPass(deployedMP);
    }

    function setQuantum(address deployedQuantum) requiresAuth public {
        quantum = IQuantumArt(deployedQuantum);
    }

    function setKeyRing(address deployedKeyRing) requiresAuth public {
        keyRing = IQuantumKeyRing(deployedKeyRing);
    }

    function setKeyUnlocks(address deployedUnlocks) requiresAuth public {
        keyUnlocks = IQuantumUnlocked(deployedUnlocks);
    }

    function setDefaultArtistCut(uint256 cut) requiresAuth public {
        defaultArtistCut = cut;
    }
    
    function createSale(uint256 dropId, uint128 price, uint64 start, uint64 limit) requiresAuth public {
        sales[dropId] = Sale(price, start, limit);
    }

    function createMPClaim(uint256 dropId, uint64 mpId, uint64 start, uint128 price) requiresAuth public {
        mpClaims[dropId] = MPClaim(mpId, start, price);
    }

    function createWLClaim(uint256 dropId, uint192 price, uint64 start, bytes32 root) requiresAuth public {
        whitelists[dropId] = Whitelist(price, start, root);
    }

    function flipUint64(uint64 x) internal pure returns (uint64) {
        return x > 0 ? 0 : type(uint64).max;
    }

    function flipSaleState(uint256 dropId) requiresAuth public {
        sales[dropId].start = flipUint64(sales[dropId].start);
    }

    function flipMPClaimState(uint256 dropId) requiresAuth public {
        mpClaims[dropId].start = flipUint64(mpClaims[dropId].start);
    }

    function flipWLState(uint256 dropId) requiresAuth public {
        whitelists[dropId].start = flipUint64(whitelists[dropId].start);
    }

    function flipLimiterForDrop(uint256 dropId) requiresAuth public {
        if (_disablingLimiter.get(dropId)) {
            _disablingLimiter.unset(dropId);
        } else {
            _disablingLimiter.set(dropId);
        }
    }

    function overrideArtistcut(uint256 dropId, uint256 cut) requiresAuth public {
        _overridedArtistCut[dropId] = cut;
    }

    function overrideUnlockArtistCut(uint256 dropId, uint256 cut) requiresAuth public {
        keySales[dropId].overrideArtistcut = cut;
    }

    function setAuction(
        uint256 auctionId,
        uint256 startingPrice,
        uint128 decreasingConstant,
        uint64 start,
        uint64 period
    ) public override requiresAuth {
        super.setAuction(auctionId, startingPrice, decreasingConstant, start, period);
    }

    function curatedPayout(address artist, uint256 dropId, uint256 amount) internal {
        uint256 artistCut = _overridedArtistCut[dropId] == 0 ? defaultArtistCut : _overridedArtistCut[dropId];
        uint256 payout_ = (amount*artistCut)/10000;
        Address.sendValue(payable(artist), payout_);
        Address.sendValue(_quantumTreasury, amount - payout_);
    }

    function genericPayout(address artist, uint256 amount, uint256 cut) internal {
        uint256 artistCut = cut == 0 ? defaultArtistCut : cut;
        uint256 payout_ = (amount*artistCut)/10000;
        Address.sendValue(payable(artist), payout_);
        Address.sendValue(_quantumTreasury, amount - payout_);
    }

    function _isPrivileged(address user) internal view returns (bool) {
        uint256 length = privilegedContracts.length;
        unchecked {
            for(uint i; i < length; i++) {
                /// @dev using this interface because has balanceOf
                if (IQuantumArt(privilegedContracts[i]).balanceOf(user) > 0) {
                    return true;
                }
            }
        }
        return false;
    }

    function purchase(uint256 dropId, uint256 amount) nonReentrant checkCaller isFirstTime(dropId) payable public {
        Sale memory sale = sales[dropId];
        require(block.timestamp >= sale.start, "PURCHASE:SALE INACTIVE");
        require(amount <= sale.limit, "PURCHASE:OVER LIMIT");
        require(msg.value == amount * sale.price, "PURCHASE:INCORRECT MSG.VALUE");
        for(uint256 i = 0; i < amount; i++) {
            uint256 tokenId = quantum.mintTo(dropId, msg.sender);
            emit Purchased(dropId, tokenId, msg.sender);
        }
        curatedPayout(quantum.getArtist(dropId), dropId, msg.value);
    }


    function purchaseThroughAuction(uint256 dropId) nonReentrant checkCaller isFirstTime(dropId) payable public {
        Auction memory auction = _auctions[dropId];
        // if 5 minutes before public auction
        // if holder -> special treatment
        uint256 userPaid = auction.startingPrice;
        if (
            block.timestamp <= auction.start && 
            block.timestamp >= auction.start - 300 &&
            _isPrivileged(msg.sender)
        ) {
            require(msg.value == userPaid, "PURCHASE:INCORRECT MSG.VALUE");

        } else {
            userPaid = verifyBid(dropId);
        }
        uint256 tokenId = quantum.mintTo(dropId, msg.sender);
        emit Purchased(dropId, tokenId, msg.sender);
        curatedPayout(quantum.getArtist(dropId), dropId, userPaid);
    }

    
    function unlockWithKey(uint256 keyId, uint128 dropId, uint256 variant) nonReentrant checkCaller payable public {
        require(keyRing.ownerOf(keyId) == msg.sender, "PURCHASE:NOT KEY OWNER");
        require(!keyUnlockClaims[dropId][keyId], "PURCHASE:KEY ALREADY USED");
        require(variant>0 && variant<13, "PURCHASE:INVALID VARIANT");

        UnlockSale memory sale = keySales[dropId];
        //Check is a valid key range (to limit to particular keys)
        bool inRange = false;
        if (sale.enabledKeyRanges.length > 0) {
            for (uint256 i=0; i<sale.enabledKeyRanges.length; i++) {
                if ((keyId >= (sale.enabledKeyRanges[i] * SEPARATOR)) && (keyId < (((sale.enabledKeyRanges[i]+1) * SEPARATOR)-1))) inRange = true;
            }
        } 
        else inRange = true;
        require(inRange, "PURCHASE:SALE NOT AVAILABLE TO THIS KEY");
        require(block.timestamp >= sale.start, "PURCHASE:SALE NOT STARTED");
        require(block.timestamp <= (sale.start + sale.period), "PURCHASE:SALE EXPIRED");
        require(msg.value == sale.price, "PURCHASE:INCORRECT MSG.VALUE");

        uint256 tokenId = keyUnlocks.mint(msg.sender, dropId, variant);
        keyUnlockClaims[dropId][keyId] = true;
        emit Purchased(dropId, tokenId, msg.sender);
        genericPayout(sale.artist, msg.value, sale.overrideArtistcut);
    }

    function createUnlockSale(uint128 price, uint64 start, uint64 period, address artist, uint256[] calldata enabledKeyRanges) requiresAuth public {
        emit DropCreated(_nextUnlockDropId);
        uint256[] memory blankRanges;
        keySales[_nextUnlockDropId++] = UnlockSale(price, start, period, artist, 0, blankRanges);
        for (uint i=0; i<enabledKeyRanges.length; i++) keySales[_nextUnlockDropId-1].enabledKeyRanges.push(enabledKeyRanges[i]);
    }

    function isKeyUsed(uint256 dropId, uint256 keyId) public view returns (bool) {
        return keyUnlockClaims[dropId][keyId];
    }

    function claimWithMintPass(uint256 dropId, uint256 amount) nonReentrant payable public {
        MPClaim memory mpClaim = mpClaims[dropId];
        require(block.timestamp >= mpClaim.start, "MP: CLAIMING INACTIVE");
        require(msg.value == amount * mpClaim.price, "MP:WRONG MSG.VALUE");
        mintpass.burnFromRedeem(msg.sender, mpClaim.mpId, amount); //burn mintpasses
        for(uint256 i = 0; i < amount; i++) {
            uint256 tokenId = quantum.mintTo(dropId, msg.sender);
            emit Purchased(dropId, tokenId, msg.sender);
        }
        if (msg.value > 0) curatedPayout(quantum.getArtist(dropId), dropId, msg.value);
    }

    function purchaseThroughWhitelist(uint256 dropId, uint256 amount, uint256 index, bytes32[] calldata merkleProof) nonReentrant external payable {
        Whitelist memory whitelist = whitelists[dropId];
        require(block.timestamp >= whitelist.start, "WL:INACTIVE");
        require(msg.value == whitelist.price * amount, "WL: INVALID MSG.VALUE");
        require(!_claimedWL[dropId].get(index), "WL:ALREADY CLAIMED");
        bytes32 node = keccak256(abi.encodePacked(msg.sender, amount, index));
        require(MerkleProof.verify(merkleProof, whitelist.merkleRoot, node),"WL:INVALID PROOF");
        _claimedWL[dropId].set(index);
        uint256 tokenId = quantum.mintTo(dropId, msg.sender);
        emit Purchased(dropId, tokenId, msg.sender);
        curatedPayout(quantum.getArtist(dropId), dropId, msg.value);
    }

    function isWLClaimed(uint256 dropId, uint256 index) public view returns (bool) {
        return _claimedWL[dropId].get(index);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IQuantumArt {
    function mintTo(uint256 dropId, address artist) external returns (uint256);
    function burn(uint256 tokenId) external;
    function getArtist(uint256 dropId) external view returns (address);
    function balanceOf(address user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IQuantumMintPass {
    function burnFromRedeem(address user, uint256 mpId, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IQuantumUnlocked {
    function mint(address to, uint128 dropId, uint256 variant) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IQuantumKeyRing {
    function make(address to, uint256 id, uint256 amount) external;
    function ownerOf(uint256 tokenId) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/utils/Address.sol";

abstract contract ContinuousDutchAuction {

    struct Auction {
        uint256 startingPrice;
        uint128 decreasingConstant;
        uint64 start;
        uint64 period; //period in seconds : MAX IS 18 HOURS
    }

    mapping (uint => Auction) internal _auctions;

    function auctions(uint256 auctionId) public view returns (
        uint256 startingPrice,
        uint128 decreasingConstant,
        uint64 start,
        uint64 period,
        bool active
    ) {
        Auction memory auction = _auctions[auctionId];
        startingPrice = auction.startingPrice;
        decreasingConstant = auction.decreasingConstant;
        start = auction.start;
        period = auction.period;
        active = start > 0 && block.timestamp >= start;
    }

    function setAuction(
        uint256 auctionId,
        uint256 startingPrice,
        uint128 decreasingConstant,
        uint64 start,
        uint64 period
    ) virtual public {
        unchecked {
            require(startingPrice - decreasingConstant * period <= startingPrice, "setAuction: floor price underflow");
        }
        _auctions[auctionId] = Auction(startingPrice, decreasingConstant, start, period);
    }

    function getPrice(uint256 auctionId) virtual public view returns (uint256 price) {
        Auction memory auction = _auctions[auctionId];
        //only compute correct price if necessary
        if (block.timestamp < auction.start) price = auction.startingPrice;
        else if (block.timestamp >= auction.start + auction.period) price = auction.startingPrice - auction.period * auction.decreasingConstant;
        else price = auction.startingPrice - (auction.decreasingConstant * (block.timestamp - auction.start));
    }

    function verifyBid(uint256 auctionId) internal returns (uint256) {
        Auction memory auction = _auctions[auctionId];
        require(auction.start > 0, "AUCTION:NOT CREATED");
        require(block.timestamp >= auction.start, "PURCHASE:AUCTION NOT STARTED");
        uint256 pricePaid = getPrice(auctionId);
        require(msg.value >= pricePaid, "PURCHASE:INCORRECT MSG.VALUE");
        if (msg.value - pricePaid > 0) Address.sendValue(payable(msg.sender), msg.value-pricePaid); //refund difference
        return pricePaid;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Provides a flexible and updatable auth pattern which is completely separate from application logic.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
abstract contract Auth {
    event OwnerUpdated(address indexed user, address indexed newOwner);

    event AuthorityUpdated(address indexed user, Authority indexed newAuthority);

    address public owner;

    Authority public authority;

    constructor(address _owner, Authority _authority) {
        owner = _owner;
        authority = _authority;

        emit OwnerUpdated(msg.sender, _owner);
        emit AuthorityUpdated(msg.sender, _authority);
    }

    modifier requiresAuth() {
        require(isAuthorized(msg.sender, msg.sig), "UNAUTHORIZED");

        _;
    }

    function isAuthorized(address user, bytes4 functionSig) internal view virtual returns (bool) {
        Authority auth = authority; // Memoizing authority saves us a warm SLOAD, around 100 gas.

        // Checking if the caller is the owner only after calling the authority saves gas in most cases, but be
        // aware that this makes protected functions uncallable even to the owner if the authority is out of order.
        return (address(auth) != address(0) && auth.canCall(user, address(this), functionSig)) || user == owner;
    }

    function setAuthority(Authority newAuthority) public virtual {
        // We check if the caller is the owner first because we want to ensure they can
        // always swap out the authority even if it's reverting or using up a lot of gas.
        require(msg.sender == owner || authority.canCall(msg.sender, address(this), msg.sig));

        authority = newAuthority;

        emit AuthorityUpdated(msg.sender, newAuthority);
    }

    function setOwner(address newOwner) public virtual requiresAuth {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

/// @notice A generic interface for a contract which provides authorization data to an Auth instance.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
interface Authority {
    function canCall(
        address user,
        address target,
        bytes4 functionSig
    ) external view returns (bool);
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/BitMaps.sol)
pragma solidity ^0.8.0;

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largelly inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */
library BitMaps {
    struct BitMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(BitMap storage bitmap, uint256 index) internal view returns (bool) {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        return bitmap._data[bucket] & mask != 0;
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(
        BitMap storage bitmap,
        uint256 index,
        bool value
    ) internal {
        if (value) {
            set(bitmap, index);
        } else {
            unset(bitmap, index);
        }
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] |= mask;
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] &= ~mask;
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}