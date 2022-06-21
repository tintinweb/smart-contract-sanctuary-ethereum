// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IQuantumArt.sol";
import "./interfaces/IQuantumMintPass.sol";
import "./interfaces/IQuantumUnlocked.sol";
import "./interfaces/IQuantumKeyRing.sol";
import "./ContinuousDutchAuctionUpgradeable.sol";
import "./solmate/AuthUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/BitMapsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./SalePlatformStorage.sol";

contract SalePlatformUpgradeable is
    SalePlatformAccessors,
    Initializable,
    ContinuousDutchAuctionUpgradeable,
    ReentrancyGuardUpgradeable,
    AuthUpgradeable,
    UUPSUpgradeable
{
    using SalePlatformStorage for SalePlatformStorage.Layout;
    using BitMapsUpgradeable for BitMapsUpgradeable.BitMap;
    using StringsUpgradeable for uint256;

    event Purchased(uint256 indexed dropId, uint256 tokenId, address to);
    event DropCreated(uint256 dropId);
    event DropUpdated(uint256 dropId);

    //mapping dropId => struct
    // mapping(uint256 => Sale) public sales;
    // mapping(uint256 => MPClaim) public mpClaims;
    // mapping(uint256 => Whitelist) public whitelists;
    // uint256 public defaultArtistCut; //10000 * percentage
    // IQuantumArt public quantum;
    // IQuantumMintPass public mintpass;
    // IQuantumUnlocked public keyUnlocks;
    // IQuantumKeyRing public keyRing;
    // address[] public privilegedContracts;

    uint256 private constant SEPARATOR = 10**4;

    // uint128 public nextUnlockDropId;
    // mapping(uint256 => UnlockSale) public keySales;

    /// >>>>>>>>>>>>>>>>>>>>>  INITIALIZER  <<<<<<<<<<<<<<<<<<<<<< ///

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        requiresAuth
    {}

    function initialize(
        address deployedQuantum,
        address deployedMP,
        address deployedKeyRing,
        address deployedUnlocks,
        address admin,
        address payable treasury,
        address authority,
        address authorizer
    ) public virtual initializer {
        __SalePlatform_init(
            deployedQuantum,
            deployedMP,
            deployedKeyRing,
            deployedUnlocks,
            admin,
            treasury,
            authority,
            authorizer
        );
    }

    function __SalePlatform_init(
        address deployedQuantum,
        address deployedMP,
        address deployedKeyRing,
        address deployedUnlocks,
        address admin,
        address payable treasury,
        address authority,
        address authorizer
    ) internal onlyInitializing {
        __AuthAuction_init(admin, AuthorityUpgradeable(authority));
        __SalePlatform_init_unchained(
            deployedQuantum,
            deployedMP,
            deployedKeyRing,
            deployedUnlocks,
            treasury,
            authorizer
        );
    }

    function __SalePlatform_init_unchained(
        address deployedQuantum,
        address deployedMP,
        address deployedKeyRing,
        address deployedUnlocks,
        address payable treasury,
        address authorizer
    ) internal onlyInitializing {
        SalePlatformStorage.Layout storage s = SalePlatformStorage.layout();
        s.quantum = IQuantumArt(deployedQuantum);
        s.mintpass = IQuantumMintPass(deployedMP);
        s.keyRing = IQuantumKeyRing(deployedKeyRing);
        s.keyUnlocks = IQuantumUnlocked(deployedUnlocks);
        s.quantumTreasury = treasury;
        s.authorizer = authorizer;
        s.defaultArtistCut = 8000; //default 80% for artist
    }

    modifier checkCaller() {
        require(msg.sender.code.length == 0, "Contract forbidden");
        _;
    }

    modifier isFirstTime(uint256 dropId) {
        SalePlatformStorage.Layout storage s = SalePlatformStorage.layout();
        if (!s.disablingLimiter.get(dropId)) {
            require(
                !s.alreadyBought[msg.sender].get(dropId),
                string(
                    abi.encodePacked("Already bought drop ", dropId.toString())
                )
            );
            s.alreadyBought[msg.sender].set(dropId);
        }
        _;
    }

    function setPrivilegedContracts(address[] calldata contracts)
        public
        requiresAuth
    {
        SalePlatformStorage.layout().privilegedContracts = contracts;
    }

    function setAuthorizer(address authorizer) public requiresAuth {
        SalePlatformStorage.layout().authorizer = authorizer;
    }

    function withdraw(address payable to) public requiresAuth {
        AddressUpgradeable.sendValue(to, address(this).balance);
    }

    function premint(uint256 dropId, address[] calldata recipients)
        public
        requiresAuth
    {
        SalePlatformStorage.Layout storage s = SalePlatformStorage.layout();
        for (uint256 i = 0; i < recipients.length; i++) {
            uint256 tokenId = s.quantum.mintTo(dropId, recipients[i]);
            emit Purchased(dropId, tokenId, recipients[i]);
        }
    }

    function setMintpass(address deployedMP) public requiresAuth {
        SalePlatformStorage.layout().mintpass = IQuantumMintPass(deployedMP);
    }

    function setQuantum(address deployedQuantum) public requiresAuth {
        SalePlatformStorage.layout().quantum = IQuantumArt(deployedQuantum);
    }

    function setKeyRing(address deployedKeyRing) public requiresAuth {
        SalePlatformStorage.layout().keyRing = IQuantumKeyRing(deployedKeyRing);
    }

    function setKeyUnlocks(address deployedUnlocks) public requiresAuth {
        SalePlatformStorage.layout().keyUnlocks = IQuantumUnlocked(
            deployedUnlocks
        );
    }

    function setDefaultArtistCut(uint256 cut) public requiresAuth {
        SalePlatformStorage.layout().defaultArtistCut = cut;
    }

    function createSale(
        uint256 dropId,
        uint128 price,
        uint64 start,
        uint64 limit
    ) public requiresAuth {
        SalePlatformStorage.layout().sales[dropId] = Sale(price, start, limit);
    }

    function createMPClaim(
        uint256 dropId,
        uint64 mpId,
        uint64 start,
        uint128 price
    ) public requiresAuth {
        SalePlatformStorage.layout().mpClaims[dropId] = MPClaim(
            mpId,
            start,
            price
        );
    }

    function createWLClaim(
        uint256 dropId,
        uint192 price,
        uint64 start,
        bytes32 root
    ) public requiresAuth {
        SalePlatformStorage.layout().whitelists[dropId] = Whitelist(
            price,
            start,
            root
        );
    }

    function flipUint64(uint64 x) internal pure returns (uint64) {
        return x > 0 ? 0 : type(uint64).max;
    }

    function flipSaleState(uint256 dropId) public requiresAuth {
        SalePlatformStorage.Layout storage s = SalePlatformStorage.layout();
        s.sales[dropId].start = flipUint64(s.sales[dropId].start);
    }

    function flipMPClaimState(uint256 dropId) public requiresAuth {
        SalePlatformStorage.Layout storage s = SalePlatformStorage.layout();
        s.mpClaims[dropId].start = flipUint64(s.mpClaims[dropId].start);
    }

    function flipWLState(uint256 dropId) public requiresAuth {
        SalePlatformStorage.Layout storage s = SalePlatformStorage.layout();
        s.whitelists[dropId].start = flipUint64(s.whitelists[dropId].start);
    }

    function flipLimiterForDrop(uint256 dropId) public requiresAuth {
        SalePlatformStorage.Layout storage s = SalePlatformStorage.layout();
        if (s.disablingLimiter.get(dropId)) {
            s.disablingLimiter.unset(dropId);
        } else {
            s.disablingLimiter.set(dropId);
        }
    }

    function overrideArtistcut(uint256 dropId, uint256 cut)
        public
        requiresAuth
    {
        SalePlatformStorage.layout().overridedArtistCut[dropId] = cut;
    }

    function overrideUnlockArtistCut(uint256 dropId, uint256 cut)
        public
        requiresAuth
    {
        SalePlatformStorage.layout().keySales[dropId].overrideArtistcut = cut;
    }

    function setAuction(
        uint256 auctionId,
        uint256 startingPrice,
        uint128 decreasingConstant,
        uint64 start,
        uint64 period
    ) public override requiresAuth {
        super.setAuction(
            auctionId,
            startingPrice,
            decreasingConstant,
            start,
            period
        );
    }

    function curatedPayout(
        address artist,
        uint256 dropId,
        uint256 amount
    ) internal {
        SalePlatformStorage.Layout storage s = SalePlatformStorage.layout();
        uint256 artistCut = s.overridedArtistCut[dropId] == 0
            ? s.defaultArtistCut
            : s.overridedArtistCut[dropId];
        uint256 payout_ = (amount * artistCut) / 10000;
        AddressUpgradeable.sendValue(payable(artist), payout_);
        AddressUpgradeable.sendValue(s.quantumTreasury, amount - payout_);
    }

    function genericPayout(
        address artist,
        uint256 amount,
        uint256 cut
    ) internal {
        SalePlatformStorage.Layout storage s = SalePlatformStorage.layout();
        uint256 artistCut = cut == 0 ? s.defaultArtistCut : cut;
        uint256 payout_ = (amount * artistCut) / 10000;
        AddressUpgradeable.sendValue(payable(artist), payout_);
        AddressUpgradeable.sendValue(s.quantumTreasury, amount - payout_);
    }

    function _isPrivileged(address user) internal view returns (bool) {
        SalePlatformStorage.Layout storage s = SalePlatformStorage.layout();
        uint256 length = s.privilegedContracts.length;
        unchecked {
            for (uint256 i; i < length; i++) {
                /// @dev using this interface because has balanceOf
                if (IQuantumArt(s.privilegedContracts[i]).balanceOf(user) > 0) {
                    return true;
                }
            }
        }
        return false;
    }

    function purchase(uint256 dropId, uint256 amount)
        public
        payable
        nonReentrant
        checkCaller
        isFirstTime(dropId)
    {
        SalePlatformStorage.Layout storage s = SalePlatformStorage.layout();
        Sale memory sale = s.sales[dropId];
        require(block.timestamp >= sale.start, "PURCHASE:SALE INACTIVE");
        require(amount <= sale.limit, "PURCHASE:OVER LIMIT");
        require(
            msg.value == amount * sale.price,
            "PURCHASE:INCORRECT MSG.VALUE"
        );
        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = s.quantum.mintTo(dropId, msg.sender);
            emit Purchased(dropId, tokenId, msg.sender);
        }
        curatedPayout(s.quantum.getArtist(dropId), dropId, msg.value);
    }

    //TODO: reinstate isFirstTime check but only before resting price
    function purchaseThroughAuction(uint256 dropId)
        public
        payable
        nonReentrant
        checkCaller
        isFirstTime(dropId)
    {
        SalePlatformStorage.Layout storage s = SalePlatformStorage.layout();
        Auction memory auction = s.auctions[dropId];
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
        uint256 tokenId = s.quantum.mintTo(dropId, msg.sender);
        emit Purchased(dropId, tokenId, msg.sender);
        curatedPayout(s.quantum.getArtist(dropId), dropId, userPaid);
    }

    function authorizedUnlockWithKey(
        UnlockedMintAuthorization calldata mintAuth,
        uint256 variant
    ) public payable {
        SalePlatformStorage.Layout storage s = SalePlatformStorage.layout();
        // require(msg.sender == owner || msg.sender == _minter, "NOT_AUTHORIZED");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encodePacked(
                        mintAuth.id,
                        mintAuth.keyId,
                        mintAuth.dropId,
                        mintAuth.validFrom,
                        mintAuth.validPeriod
                    )
                )
            )
        );
        address signer = ecrecover(digest, mintAuth.v, mintAuth.r, mintAuth.s);
        if (signer != s.authorizer) revert("PURCHASE:INVALID SIGNATURE");
        if (block.timestamp <= mintAuth.validFrom)
            revert("PURCHASE:NOT VALID YET");
        if (
            mintAuth.validPeriod > 0 &&
            block.timestamp > mintAuth.validFrom + mintAuth.validPeriod
        ) revert("PURCHASE:AUTHORIZATION EXPIRED");

        UnlockSale memory sale = s.keySales[mintAuth.dropId];
        address recipient = s.keyRing.ownerOf(mintAuth.keyId);
        _unlockWithKey(
            mintAuth.keyId,
            mintAuth.dropId,
            variant,
            recipient,
            sale
        );
    }

    function _unlockWithKey(
        uint256 keyId,
        uint128 dropId,
        uint256 variant,
        address recipient,
        UnlockSale memory sale
    ) private {
        SalePlatformStorage.Layout storage s = SalePlatformStorage.layout();
        require(!s.keyUnlockClaims[dropId][keyId], "PURCHASE:KEY ALREADY USED");

        require(
            s.keyUnlocks.dropSupply(dropId) < sale.maxDropSupply,
            "PURCHASE:NO MORE AVAILABLE"
        );
        require(
            sale.numOfVariants == 0 ||
                (variant > 0 && variant < sale.numOfVariants + 1),
            "PURCHASE:INVALID VARIANT"
        );
        //Check is a valid key range (to limit to particular keys)
        bool inRange = false;
        if (sale.enabledKeyRanges.length > 0) {
            for (uint256 i = 0; i < sale.enabledKeyRanges.length; i++) {
                if (
                    (keyId >= (sale.enabledKeyRanges[i] * SEPARATOR)) &&
                    (keyId < (((sale.enabledKeyRanges[i] + 1) * SEPARATOR) - 1))
                ) inRange = true;
            }
        } else inRange = true;
        require(inRange, "PURCHASE:SALE NOT AVAILABLE TO THIS KEY");
        require(msg.value == sale.price, "PURCHASE:INCORRECT MSG.VALUE");

        uint256 tokenId = s.keyUnlocks.mint(recipient, dropId, variant);
        s.keyUnlockClaims[dropId][keyId] = true;
        emit Purchased(dropId, tokenId, recipient);
        genericPayout(sale.artist, msg.value, sale.overrideArtistcut);
    }

    function unlockWithKey(
        uint256 keyId,
        uint128 dropId,
        uint256 variant
    ) public payable nonReentrant checkCaller {
        SalePlatformStorage.Layout storage s = SalePlatformStorage.layout();
        require(
            s.keyRing.ownerOf(keyId) == msg.sender,
            "PURCHASE:NOT KEY OWNER"
        );
        UnlockSale memory sale = s.keySales[dropId];
        require(block.timestamp >= sale.start, "PURCHASE:SALE NOT STARTED");
        require(
            block.timestamp <= (sale.start + sale.period),
            "PURCHASE:SALE EXPIRED"
        );
        _unlockWithKey(keyId, dropId, variant, msg.sender, sale);
    }

    function createUnlockSale(
        uint128 price,
        uint64 start,
        uint64 period,
        address artist,
        uint128 maxSupply,
        uint256 numOfVariants,
        uint256[] calldata enabledKeyRanges
    ) public requiresAuth {
        SalePlatformStorage.Layout storage s = SalePlatformStorage.layout();
        emit DropCreated(s.nextUnlockDropId);
        uint256[] memory blankRanges;
        s.keySales[s.nextUnlockDropId++] = UnlockSale(
            price,
            start,
            period,
            artist,
            0,
            blankRanges,
            numOfVariants,
            maxSupply
        );
        for (uint256 i = 0; i < enabledKeyRanges.length; i++)
            s.keySales[s.nextUnlockDropId - 1].enabledKeyRanges.push(
                enabledKeyRanges[i]
            );
    }

    function updateUnlockSale(
        uint128 dropId,
        uint128 price,
        uint64 start,
        uint64 period,
        address artist,
        uint128 maxSupply,
        uint256 numOfVariants,
        uint256[] calldata enabledKeyRanges
    ) public requiresAuth {
        SalePlatformStorage.Layout storage s = SalePlatformStorage.layout();
        emit DropUpdated(dropId);
        uint256[] memory blankRanges;
        s.keySales[dropId] = UnlockSale(
            price,
            start,
            period,
            artist,
            0,
            blankRanges,
            numOfVariants,
            maxSupply
        );
        for (uint256 i = 0; i < enabledKeyRanges.length; i++)
            s.keySales[s.nextUnlockDropId - 1].enabledKeyRanges.push(
                enabledKeyRanges[i]
            );
    }

    function setKeyUsedBatch(
        uint128 dropId,
        bool set,
        uint256[] calldata keys
    ) public requiresAuth {
        for (uint256 i = 0; i < keys.length; i++) {
            SalePlatformStorage.layout().keyUnlockClaims[dropId][keys[i]] = set;
        }
    }

    function isKeyUsed(uint256 dropId, uint256 keyId)
        public
        view
        returns (bool)
    {
        // TODO: Fix this after spaces deployment
        if (dropId == 0) return true;
        return SalePlatformStorage.layout().keyUnlockClaims[dropId][keyId];
    }

    function claimWithMintPass(uint256 dropId, uint256 amount)
        public
        payable
        nonReentrant
    {
        SalePlatformStorage.Layout storage s = SalePlatformStorage.layout();
        MPClaim memory mpClaim = s.mpClaims[dropId];
        require(block.timestamp >= mpClaim.start, "MP: CLAIMING INACTIVE");
        require(msg.value == amount * mpClaim.price, "MP:WRONG MSG.VALUE");
        s.mintpass.burnFromRedeem(msg.sender, mpClaim.mpId, amount); //burn mintpasses
        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = s.quantum.mintTo(dropId, msg.sender);
            emit Purchased(dropId, tokenId, msg.sender);
        }
        if (msg.value > 0)
            curatedPayout(s.quantum.getArtist(dropId), dropId, msg.value);
    }

    function purchaseThroughWhitelist(
        uint256 dropId,
        uint256 amount,
        uint256 index,
        bytes32[] calldata merkleProof
    ) external payable nonReentrant {
        SalePlatformStorage.Layout storage s = SalePlatformStorage.layout();
        Whitelist memory whitelist = s.whitelists[dropId];
        require(block.timestamp >= whitelist.start, "WL:INACTIVE");
        require(msg.value == whitelist.price * amount, "WL: INVALID MSG.VALUE");
        require(!s.claimedWL[dropId].get(index), "WL:ALREADY CLAIMED");
        bytes32 node = keccak256(abi.encodePacked(msg.sender, amount, index));
        require(
            MerkleProofUpgradeable.verify(
                merkleProof,
                whitelist.merkleRoot,
                node
            ),
            "WL:INVALID PROOF"
        );
        s.claimedWL[dropId].set(index);
        uint256 tokenId = s.quantum.mintTo(dropId, msg.sender);
        emit Purchased(dropId, tokenId, msg.sender);
        curatedPayout(s.quantum.getArtist(dropId), dropId, msg.value);
    }

    function isWLClaimed(uint256 dropId, uint256 index)
        public
        view
        returns (bool)
    {
        return SalePlatformStorage.layout().claimedWL[dropId].get(index);
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
    function dropSupply(uint128 dropId) external returns (uint128);

    function mint(
        address to,
        uint128 dropId,
        uint256 variant
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IQuantumKeyRing {
    function make(address to, uint256 id, uint256 amount) external;
    function ownerOf(uint256 tokenId) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "./SalePlatformStorage.sol";

abstract contract ContinuousDutchAuctionUpgradeable {
    function auctions(uint256 auctionId)
        public
        view
        returns (
            uint256 startingPrice,
            uint128 decreasingConstant,
            uint64 start,
            uint64 period,
            bool active
        )
    {
        Auction memory auction = SalePlatformStorage.layout().auctions[
            auctionId
        ];
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
    ) public virtual {
        unchecked {
            require(
                startingPrice - decreasingConstant * period <= startingPrice,
                "setAuction: floor price underflow"
            );
        }
        SalePlatformStorage.layout().auctions[auctionId] = Auction(
            startingPrice,
            decreasingConstant,
            start,
            period
        );
    }

    function getPrice(uint256 auctionId)
        public
        view
        virtual
        returns (uint256 price)
    {
        Auction memory auction = SalePlatformStorage.layout().auctions[
            auctionId
        ];
        //only compute correct price if necessary
        if (block.timestamp < auction.start) price = auction.startingPrice;
        else if (block.timestamp >= auction.start + auction.period)
            price =
                auction.startingPrice -
                auction.period *
                auction.decreasingConstant;
        else
            price =
                auction.startingPrice -
                (auction.decreasingConstant *
                    (block.timestamp - auction.start));
    }

    function verifyBid(uint256 auctionId) internal returns (uint256) {
        Auction memory auction = SalePlatformStorage.layout().auctions[
            auctionId
        ];
        require(auction.start > 0, "AUCTION:NOT CREATED");
        require(
            block.timestamp >= auction.start,
            "PURCHASE:AUCTION NOT STARTED"
        );
        uint256 pricePaid = getPrice(auctionId);
        require(msg.value >= pricePaid, "PURCHASE:INCORRECT MSG.VALUE");
        if (msg.value - pricePaid > 0)
            AddressUpgradeable.sendValue(
                payable(msg.sender),
                msg.value - pricePaid
            ); //refund difference
        return pricePaid;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/// @notice Provides a flexible and updatable auth pattern which is completely separate from application logic.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
/// @author Modified to be upgradeable by jcbdev @quantum
abstract contract AuthUpgradeable is Initializable {
    event OwnerUpdated(address indexed user, address indexed newOwner);

    event AuthorityUpdated(
        address indexed user,
        AuthorityUpgradeable indexed newAuthority
    );

    address public owner;

    AuthorityUpgradeable public authority;

    function __AuthAuction_init(address _owner, AuthorityUpgradeable _authority)
        internal
        onlyInitializing
    {
        __AuthAuction_init_unchained(_owner, _authority);
    }

    function __AuthAuction_init_unchained(
        address _owner,
        AuthorityUpgradeable _authority
    ) internal onlyInitializing {
        owner = _owner;
        authority = _authority;

        emit OwnerUpdated(msg.sender, _owner);
        emit AuthorityUpdated(msg.sender, _authority);
    }

    modifier requiresAuth() {
        require(isAuthorized(msg.sender, msg.sig), "UNAUTHORIZED");

        _;
    }

    function isAuthorized(address user, bytes4 functionSig)
        internal
        view
        virtual
        returns (bool)
    {
        AuthorityUpgradeable auth = authority; // Memoizing authority saves us a warm SLOAD, around 100 gas.

        // Checking if the caller is the owner only after calling the authority saves gas in most cases, but be
        // aware that this makes protected functions uncallable even to the owner if the authority is out of order.
        return
            (address(auth) != address(0) &&
                auth.canCall(user, address(this), functionSig)) ||
            user == owner;
    }

    function setAuthority(AuthorityUpgradeable newAuthority) public virtual {
        // We check if the caller is the owner first because we want to ensure they can
        // always swap out the authority even if it's reverting or using up a lot of gas.
        require(
            msg.sender == owner ||
                authority.canCall(msg.sender, address(this), msg.sig)
        );

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
interface AuthorityUpgradeable {
    function canCall(
        address user,
        address target,
        bytes4 functionSig
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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
library BitMapsUpgradeable {
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
library MerkleProofUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IQuantumArt.sol";
import "./interfaces/IQuantumMintPass.sol";
import "./interfaces/IQuantumUnlocked.sol";
import "./interfaces/IQuantumKeyRing.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/BitMapsUpgradeable.sol";

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

struct UnlockedMintAuthorization {
    uint256 id;
    uint256 keyId;
    uint128 dropId;
    uint256 validFrom;
    uint256 validPeriod;
    bytes32 r;
    bytes32 s;
    uint8 v;
}

//TODO: Better drop mechanism
struct UnlockSale {
    uint128 price;
    uint64 start;
    uint64 period;
    address artist;
    uint256 overrideArtistcut;
    uint256[] enabledKeyRanges;
    uint256 numOfVariants;
    uint128 maxDropSupply;
}

struct Auction {
    uint256 startingPrice;
    uint128 decreasingConstant;
    uint64 start;
    uint64 period; //period in seconds : MAX IS 18 HOURS
}

library SalePlatformStorage {
    using BitMapsUpgradeable for BitMapsUpgradeable.BitMap;

    struct Layout {
        mapping(uint256 => Auction) auctions;
        mapping(uint256 => Sale) sales;
        mapping(uint256 => MPClaim) mpClaims;
        mapping(uint256 => Whitelist) whitelists;
        uint256 defaultArtistCut; //10000 * percentage
        IQuantumArt quantum;
        IQuantumMintPass mintpass;
        IQuantumUnlocked keyUnlocks;
        IQuantumKeyRing keyRing;
        address[] privilegedContracts;
        BitMapsUpgradeable.BitMap disablingLimiter;
        mapping(uint256 => BitMapsUpgradeable.BitMap) claimedWL;
        mapping(address => BitMapsUpgradeable.BitMap) alreadyBought;
        mapping(uint256 => uint256) overridedArtistCut; // dropId -> cut
        address payable quantumTreasury;
        address authorizer;
        // TODO: Quantum Unlocked appended - needs rewrite
        uint128 nextUnlockDropId;
        mapping(uint256 => mapping(uint256 => bool)) keyUnlockClaims;
        mapping(uint256 => UnlockSale) keySales;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("quantum.contracts.storage.saleplatform.v1");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

abstract contract SalePlatformAccessors {
    using SalePlatformStorage for SalePlatformStorage.Layout;

    function sales(uint256 dropId) public view returns (Sale memory) {
        return SalePlatformStorage.layout().sales[dropId];
    }

    function mpClaims(uint256 dropId) public view returns (MPClaim memory) {
        return SalePlatformStorage.layout().mpClaims[dropId];
    }

    function whitelists(uint256 dropId) public view returns (Whitelist memory) {
        return SalePlatformStorage.layout().whitelists[dropId];
    }

    function defaultArtistCut() public view returns (uint256) {
        return SalePlatformStorage.layout().defaultArtistCut;
    }

    function privilegedContracts() public view returns (address[] memory) {
        return SalePlatformStorage.layout().privilegedContracts;
    }

    function nextUnlockDropId() public view returns (uint128) {
        return SalePlatformStorage.layout().nextUnlockDropId;
    }

    function keySales(uint256 dropId) public view returns (UnlockSale memory) {
        return SalePlatformStorage.layout().keySales[dropId];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}