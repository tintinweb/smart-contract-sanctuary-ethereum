// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {LockRegistry} from "./abstract/LockRegistry.sol";
import {IBrawlerBearz} from "./interfaces/IBrawlerBearz.sol";
import {IBrawlerBearzRenderer} from "./interfaces/IBrawlerBearzRenderer.sol";
import {IBrawlerBearzDynamicItems} from "./interfaces/IBrawlerBearzDynamicItems.sol";
import {ERC721Psi, ERC721PsiRandomSeedReveal, ERC721PsiRandomSeedRevealBurnable} from "./ERC721PsiRandomSeedRevealBurnable.sol";

/*******************************************************************************
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@|(@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@|,|@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&@@@@@@@@@@@|,*|&@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%,**%@@@@@@@@%|******%&@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&##*****|||**,(%%%%%**|%@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@***,#%%%%**#&@@@@@#**,|@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@*,(@@@@@@@@@@**,(&@@@@#**%@@@@@@||(%@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@%|,****&@((@&***&@@@@@@%||||||||#%&@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@&%#*****||||||**#%&@%%||||||||#@&%#(@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@&**,(&@@@@@%|||||*##&&&&##|||||(%@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@**,%@@@@@@@(|*|#%@@@@@@@@#||#%%@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@#||||#@@@@||*|%@@@@@@@@&|||%%&@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@#,,,,,,*|**||%|||||||###&@@@@@@@#|||#%@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@&#||*|||||%%%@%%%#|||%@@@@@@@@&(|(%&@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@&&%%(||||@@@@@@&|||||(%&((||(#%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@%%(||||||||||#%#(|||||%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@&%#######%%@@**||(#%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%##%%&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
********************************************************************************/

/**************************************************
 * @title BrawlerBearz
 * @author @ScottMitchell18
 **************************************************/

contract BrawlerBearz is
    IBrawlerBearz,
    ERC721PsiRandomSeedRevealBurnable,
    LockRegistry,
    ReentrancyGuard,
    AccessControl
{
    address public constant DEAD_ADDRESS =
        0x000000000000000000000000000000000000dEaD;

    // Roles
    bytes32 constant XP_MUTATOR_ROLE = keccak256("XP_MUTATOR_ROLE");
    bytes32 constant OWNER_ROLE = keccak256("OWNER_ROLE");

    // Equip types
    bytes32 constant WEAPON_ITEM_TYPE = keccak256(abi.encodePacked("WEAPON"));
    bytes32 constant BACKGROUND_ITEM_TYPE =
        keccak256(abi.encodePacked("BACKGROUND"));
    bytes32 constant ARMOR_ITEM_TYPE = keccak256(abi.encodePacked("ARMOR"));
    bytes32 constant FACE_ARMOR_ITEM_TYPE =
        keccak256(abi.encodePacked("FACE_ARMOR"));
    bytes32 constant EYEWEAR_ITEM_TYPE = keccak256(abi.encodePacked("EYEWEAR"));
    bytes32 constant MISC_ITEM_TYPE = keccak256(abi.encodePacked("MISC"));

    /// @notice bytes32 of chainlink keyhash
    bytes32 public immutable keyHash;

    /// @notice value of chainlink subscription id
    uint64 public immutable subscriptionId;

    /// @notice address of treasury (e.g, gnosis safe)
    address public treasury =
        payable(0x39bfA2b4319581bc885A2d4b9F0C90C2e1c24B87);

    /*
     * @notice Whitelist Live ~ September 16th, 2022, 10AM EST
     * @dev timestamp for whitelist liveness
     */
    uint256 public whitelistLiveAt = 1663336800;

    /*
     * @notice Public / Free Claim Live ~ September 16th, 2022, 5PM EST
     * @dev timestamp for public and free claim liveness
     */
    uint256 public liveAt = 1663362000;

    /// @notice amount of the total supply of the collection (n - 1)
    uint256 public maxSupply = 3335; // Excludes 2666 access passes

    /// @notice price in ether
    uint256 public price = 0.06 ether;

    /// @notice amount of transactions allowed per wallet (n - 1)
    uint256 public maxPerWallet = 4;

    /// @notice boolean for if the shop drop is enabled
    bool private isShopDropEnabled = true;

    /// @notice bytes32 hash of the merkle root
    bytes32 public merkleRoot;

    /// @notice map from token id to custom metadata
    mapping(uint256 => CustomMetadata) internal metadata;

    // @dev An address mapping for max mint per wallet
    mapping(address => uint256) public addressToMinted;

    /// @notice Vendor contract
    IBrawlerBearzDynamicItems public vendorContract;

    /// @notice Access pass contract
    IERC721 public accessPassContract;

    /// @notice The rendering library contract
    IBrawlerBearzRenderer public renderer;

    // ========================================
    // Modifiers
    // ========================================

    modifier isTokenOwner(uint256 tokenId) {
        if (ownerOf(tokenId) != _msgSender()) {
            revert InvalidOwner();
        }
        _;
    }

    modifier isItemTokenOwner(uint256 itemTokenId) {
        if (vendorContract.balanceOf(_msgSender(), itemTokenId) == 0) {
            revert InvalidOwner();
        }
        _;
    }

    modifier isItemValidType(uint256 itemTokenId, string memory validTypeOf) {
        if (
            keccak256(abi.encodePacked(validTypeOf)) !=
            keccak256(abi.encodePacked(vendorContract.getItemType(itemTokenId)))
        ) {
            revert InvalidItemType();
        }
        _;
    }

    modifier isItemXPMet(uint256 itemTokenId, uint256 tokenId) {
        if (metadata[tokenId].xp < vendorContract.getItemXPReq(itemTokenId)) {
            revert ItemRequiresMoreXP();
        }
        _;
    }

    // " and \ are not valid
    modifier isValidString(string calldata value) {
        bytes memory str = bytes(value);
        for (uint256 i; i < str.length; i++) {
            bytes1 char = str[i];
            if ((char == 0x22) || (char == 0x5c)) revert InvalidString();
        }
        _;
    }

    constructor(
        address _vrfV2Coordinator,
        bytes32 keyHash_,
        uint64 subscriptionId_,
        address _accessPassContract,
        address _renderingContract,
        address _vendorContract
    )
        ERC721Psi("Brawler Bearz", "BB")
        ERC721PsiRandomSeedReveal(_vrfV2Coordinator, 400000, 3)
    {
        // Chainlink VRF initialization
        keyHash = keyHash_;
        subscriptionId = subscriptionId_;
        // Setup access control
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(OWNER_ROLE, _msgSender());
        // Display contracts
        setAccessPassContractAddress(_accessPassContract);
        setRenderingContractAddress(_renderingContract);
        setVendorContractAddress(_vendorContract);
    }

    // ========================================
    // Dynamic metadata
    // ========================================

    /**
     * @notice Sets the name of a particular token id
     * @dev only token owner call this function
     * @param tokenId The token id
     * @param name The name to set
     */
    function setName(uint256 tokenId, string calldata name)
        public
        override
        isTokenOwner(tokenId)
        isValidString(name)
    {
        bytes memory n = bytes(name);
        if (n.length > 25) revert InvalidLength();
        if (keccak256(n) == keccak256(bytes(metadata[tokenId].name)))
            revert InvalidValue();
        metadata[tokenId].name = name;
        emit NameChanged(tokenId, name);
    }

    /**
     * @notice Sets the lore/backstory of a particular token id
     * @dev only token owner call this function
     * @param tokenId The token id
     * @param lore The name to set
     */
    function setLore(uint256 tokenId, string calldata lore)
        public
        override
        isTokenOwner(tokenId)
        isValidString(lore)
    {
        bytes memory n = bytes(lore);
        if (keccak256(n) == keccak256(bytes(metadata[tokenId].lore)))
            revert InvalidValue();
        metadata[tokenId].lore = lore;
        emit LoreChanged(tokenId, lore);
    }

    /**
     * @notice Sets the equipped items of a particular token id and item type
     * @dev only token owner call this function
     * @param tokenId The token id of the bear
     * @param typeOf The type of item to equip
     * @param itemTokenId The token id of the item
     */
    function equip(
        uint256 tokenId,
        string calldata typeOf,
        uint256 itemTokenId
    )
        public
        override
        isTokenOwner(tokenId)
        isItemTokenOwner(itemTokenId)
        isItemValidType(itemTokenId, typeOf)
        isItemXPMet(itemTokenId, tokenId)
        nonReentrant
    {
        bytes32 itemType = keccak256(abi.encodePacked(typeOf));
        CustomMetadata storage instance = metadata[tokenId];

        if (WEAPON_ITEM_TYPE == itemType) {
            require(instance.weapon == 0, "96");
            instance.weapon = itemTokenId;
        } else if (ARMOR_ITEM_TYPE == itemType) {
            require(instance.armor == 0, "96");
            instance.armor = itemTokenId;
        } else if (BACKGROUND_ITEM_TYPE == itemType) {
            require(instance.background == 0, "96");
            instance.background = itemTokenId;
        } else if (FACE_ARMOR_ITEM_TYPE == itemType) {
            require(instance.faceArmor == 0, "96");
            instance.faceArmor = itemTokenId;
        } else if (EYEWEAR_ITEM_TYPE == itemType) {
            require(instance.eyewear == 0, "96");
            instance.eyewear = itemTokenId;
        } else if (MISC_ITEM_TYPE == itemType) {
            require(instance.misc == 0, "96");
            instance.misc = itemTokenId;
        } else {
            revert InvalidItemType();
        }
        // Burn item
        vendorContract.burnItemForOwnerAddress(itemTokenId, 1, _msgSender());
        emit Equipped(tokenId, typeOf, itemTokenId);
    }

    /**
     * @notice Unsets the equipped items of a particular token id
     * @dev only token owner call this function
     * @param typeOf The type of item to equip
     * @param tokenId The token id
     */
    function unequip(uint256 tokenId, string calldata typeOf)
        public
        override
        isTokenOwner(tokenId)
        nonReentrant
    {
        uint256 itemTokenId;
        bytes32 itemType = keccak256(abi.encodePacked(typeOf));
        CustomMetadata storage instance = metadata[tokenId];

        if (WEAPON_ITEM_TYPE == itemType) {
            itemTokenId = instance.weapon;
            instance.weapon = 0;
        } else if (ARMOR_ITEM_TYPE == itemType) {
            itemTokenId = instance.armor;
            instance.armor = 0;
        } else if (BACKGROUND_ITEM_TYPE == itemType) {
            itemTokenId = instance.background;
            instance.background = 0;
        } else if (FACE_ARMOR_ITEM_TYPE == itemType) {
            itemTokenId = instance.faceArmor;
            instance.faceArmor = 0;
        } else if (EYEWEAR_ITEM_TYPE == itemType) {
            itemTokenId = instance.eyewear;
            instance.eyewear = 0;
        } else if (MISC_ITEM_TYPE == itemType) {
            itemTokenId = instance.misc;
            instance.misc = 0;
        } else {
            revert InvalidItemType();
        }

        require(itemTokenId > 0, "6969");
        // Mint item
        vendorContract.mintItemToAddress(itemTokenId, 1, _msgSender());
        emit Unequipped(tokenId, typeOf, itemTokenId);
    }

    // ========================================
    // NFT display helpers
    // ========================================

    /// @notice Reveal called by the governanace to reveal the seed of the NFT
    function reveal() external onlyRole(OWNER_ROLE) {
        _reveal();
    }

    /// @notice The custom metadata associated to a given tokenId
    function getMetadata(uint256 tokenId)
        external
        view
        override
        returns (CustomMetadata memory)
    {
        return metadata[tokenId];
    }

    /// @notice The token uri for a given tokenId
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "0");
        CustomMetadata memory md = metadata[tokenId];
        md.isUnlocked = isUnlocked(tokenId);
        return renderer.tokenURI(tokenId, seed(tokenId), md);
    }

    // ========================================
    // Mint Helpers
    // ========================================

    /**
     * @notice Free claim mint, requires access pass ownership
     * @param _tokenIds of the access pass
     */
    function claim(uint256[] calldata _tokenIds) external nonReentrant {
        require(isPublicLive(), "0");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            accessPassContract.transferFrom(
                _msgSender(),
                DEAD_ADDRESS,
                _tokenIds[i]
            );
        }
        _safeMint(_msgSender(), _tokenIds.length, "");
    }

    /**
     * @notice Whitelisted mint, requires a merkle proof
     * @param _amount of mints
     * @param _proof hashed array proof
     */
    function whitelistMint(uint256 _amount, bytes32[] calldata _proof)
        external
        payable
        nonReentrant
    {
        require(isWhitelistLive(), "0");
        require(totalSupply() + _amount < maxSupply, "9");
        require(msg.value >= _amount * price, "1");
        require(addressToMinted[_msgSender()] + _amount < maxPerWallet, "2");
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_proof, merkleRoot, leaf), "4");
        addressToMinted[_msgSender()] += _amount;
        _safeMint(_msgSender(), _amount, "");
        // Shop drop chance game
        if (isShopDropEnabled) {
            vendorContract.shopDrop(_msgSender(), _amount);
        }
    }

    /**
     * @notice Public mint
     * @param _amount of mints
     */
    function mint(uint256 _amount) external payable {
        require(isPublicLive(), "0");
        require(totalSupply() + _amount < maxSupply, "9");
        require(msg.value >= _amount * price, "1");
        require(addressToMinted[_msgSender()] + _amount < maxPerWallet, "2");
        addressToMinted[_msgSender()] += _amount;
        _safeMint(_msgSender(), _amount, "");
    }

    /**
     * @notice Sets public price in wei
     * @dev only owner call this function
     * @param _price The new public price in wei
     */
    function setPrice(uint256 _price) public onlyRole(OWNER_ROLE) {
        price = _price;
    }

    /**
     * @notice Sets the treasury recipient
     * @dev only owner call this function
     * @param _treasury The new price in wei
     */
    function setTreasury(address _treasury) public onlyRole(OWNER_ROLE) {
        treasury = payable(_treasury);
    }

    /**
     * @notice Sets max supply for the collection
     * @dev only owner call this function
     * @param _maxSupply The new max supply value
     */
    function setMaxSupply(uint256 _maxSupply) external onlyRole(OWNER_ROLE) {
        maxSupply = _maxSupply;
    }

    /**
     * @notice Sets the max mints per wallet
     * @param _maxPerWallet The max per wallet (Keep mind its +1 n)
     */
    function setMaxPerWallet(uint256 _maxPerWallet)
        external
        onlyRole(OWNER_ROLE)
    {
        maxPerWallet = _maxPerWallet;
    }

    /**
     * @notice Sets the go live timestamp for whitelist
     * @param _whitelistLiveAt A base uri
     */
    function setWhitelistLiveAt(uint256 _whitelistLiveAt)
        external
        onlyRole(OWNER_ROLE)
    {
        whitelistLiveAt = _whitelistLiveAt;
    }

    /**
     * @notice Sets the go live timestamp
     * @param _liveAt A base uri
     */
    function setLiveAt(uint256 _liveAt) external onlyRole(OWNER_ROLE) {
        liveAt = _liveAt;
    }

    /**
     * @notice Sets the merkle root for the mint
     * @param _merkleRoot The merkle root to set
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyRole(OWNER_ROLE) {
        merkleRoot = _merkleRoot;
    }

    /// @notice Withdraw from contract
    function withdraw() public onlyRole(OWNER_ROLE) {
        (bool success, ) = treasury.call{value: address(this).balance}("");
        require(success, "999");
    }

    /**
     * @notice Sets whether shop drop is enabled
     * @param _isShopDropEnabled the bool value
     */
    function setShopDropEnabled(bool _isShopDropEnabled)
        external
        onlyRole(OWNER_ROLE)
    {
        isShopDropEnabled = _isShopDropEnabled;
    }

    // ========================================
    // Lock registry
    // ========================================

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        require(isUnlocked(tokenId), "1337");
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        require(isUnlocked(tokenId), "1337");
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    function lockId(uint256 tokenId) external {
        require(_exists(tokenId), "0");
        _lockId(tokenId);
    }

    function unlockId(uint256 tokenId) external {
        require(_exists(tokenId), "0");
        _unlockId(tokenId);
    }

    function freeId(uint256 tokenId, address contractAddress) external {
        require(_exists(tokenId), "0");
        _freeId(tokenId, contractAddress);
    }

    // ========================================
    // External contract helpers
    // ========================================

    /**
     * @notice Adds XP to tokenId
     * @param tokenId the token
     * @param amount of xp to add
     */
    function addXP(uint256 tokenId, uint256 amount)
        external
        onlyRole(XP_MUTATOR_ROLE)
    {
        metadata[tokenId].xp += amount;
    }

    /**
     * @notice Subtracts XP from tokenId
     * @param tokenId the token
     * @param amount of xp to subtract
     */
    function subtractXP(uint256 tokenId, uint256 amount)
        external
        onlyRole(XP_MUTATOR_ROLE)
    {
        metadata[tokenId].xp -= amount;
    }

    /**
     * @notice Sets the bearz rendering library contract
     * @dev only owner call this function
     * @param _renderingContractAddress The new contract address
     */
    function setRenderingContractAddress(address _renderingContractAddress)
        public
        onlyRole(OWNER_ROLE)
    {
        renderer = IBrawlerBearzRenderer(_renderingContractAddress);
    }

    /**
     * @notice Sets the bearz vendor item contract
     * @dev only owner call this function
     * @param _vendorContractAddress The new contract address
     */
    function setVendorContractAddress(address _vendorContractAddress)
        public
        onlyRole(OWNER_ROLE)
    {
        vendorContract = IBrawlerBearzDynamicItems(_vendorContractAddress);
    }

    /**
     * @notice Sets the bearz access pass contract
     * @dev only owner call this function
     * @param _accessPassContractAddress The new contract address
     */
    function setAccessPassContractAddress(address _accessPassContractAddress)
        public
        onlyRole(OWNER_ROLE)
    {
        accessPassContract = IERC721(_accessPassContractAddress);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Psi, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // ========================================
    // Read operations
    // ========================================

    // @dev Check if mint is public live
    function isWhitelistLive() public view returns (bool) {
        return block.timestamp > whitelistLiveAt;
    }

    // @dev Check if mint is public live
    function isPublicLive() public view returns (bool) {
        return block.timestamp > liveAt;
    }

    // @dev Check the owner of a particular set of tokenIds
    function isOwnerOf(address account, uint256[] calldata _tokenIds)
        external
        view
        returns (bool)
    {
        for (uint256 i; i < _tokenIds.length; ++i) {
            if (ownerOf(_tokenIds[i]) != account) return false;
        }

        return true;
    }

    // ========================================
    // Chainlink integrations
    // ========================================

    function _keyHash() internal view override returns (bytes32) {
        return keyHash;
    }

    function _subscriptionId() internal view override returns (uint64) {
        return subscriptionId;
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
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/*
 * Origin author
 *     ,_,
 *    (',')
 *    {/"\}
 *    -"-"-
 * Utilized by @ScottMitchell18
 */

abstract contract LockRegistry is Ownable {
    mapping(address => bool) public approvedContract;
    mapping(uint256 => uint256) public lockCount;
    mapping(uint256 => mapping(uint256 => address)) public lockMap;
    mapping(uint256 => mapping(address => uint256)) public lockMapIndex;

    event TokenLocked(
        uint256 indexed tokenId,
        address indexed approvedContract
    );

    event TokenUnlocked(
        uint256 indexed tokenId,
        address indexed approvedContract
    );

    function isUnlocked(uint256 _id) public view returns (bool) {
        return lockCount[_id] == 0;
    }

    function updateApprovedContracts(
        address[] calldata _contracts,
        bool[] calldata _values
    ) external onlyOwner {
        require(_contracts.length == _values.length, "!length");
        for (uint256 i = 0; i < _contracts.length; i++)
            approvedContract[_contracts[i]] = _values[i];
    }

    function _lockId(uint256 _id) internal {
        require(approvedContract[msg.sender], "Cannot update map");
        require(
            lockMapIndex[_id][msg.sender] == 0,
            "ID already locked by caller"
        );

        uint256 count = lockCount[_id] + 1;
        lockMap[_id][count] = msg.sender;
        lockMapIndex[_id][msg.sender] = count;
        lockCount[_id]++;
        emit TokenLocked(_id, msg.sender);
    }

    function _unlockId(uint256 _id) internal {
        require(approvedContract[msg.sender], "Cannot update map");
        uint256 index = lockMapIndex[_id][msg.sender];
        require(index != 0, "ID not locked by caller");

        uint256 last = lockCount[_id];
        if (index != last) {
            address lastContract = lockMap[_id][last];
            lockMap[_id][index] = lastContract;
            lockMap[_id][last] = address(0);
            lockMapIndex[_id][lastContract] = index;
        } else lockMap[_id][index] = address(0);
        lockMapIndex[_id][msg.sender] = 0;
        lockCount[_id]--;
        emit TokenUnlocked(_id, msg.sender);
    }

    function _freeId(uint256 _id, address _contract) internal {
        require(!approvedContract[_contract], "Cannot update map");
        uint256 index = lockMapIndex[_id][_contract];
        require(index != 0, "ID not locked");

        uint256 last = lockCount[_id];
        if (index != last) {
            address lastContract = lockMap[_id][last];
            lockMap[_id][index] = lastContract;
            lockMap[_id][last] = address(0);
            lockMapIndex[_id][lastContract] = index;
        } else lockMap[_id][index] = address(0);
        lockMapIndex[_id][_contract] = 0;
        lockCount[_id]--;
        emit TokenUnlocked(_id, _contract);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IBrawlerBearzCommon} from "./IBrawlerBearzCommon.sol";
import {IBrawlerBearzEvents} from "./IBrawlerBearzEvents.sol";
import {IBrawlerBearzErrors} from "./IBrawlerBearzErrors.sol";

interface IBrawlerBearz is
    IBrawlerBearzCommon,
    IBrawlerBearzEvents,
    IBrawlerBearzErrors
{
    function getMetadata(uint256 tokenId)
        external
        view
        returns (CustomMetadata memory);

    function setName(uint256 tokenId, string calldata newName) external;

    function setLore(uint256 tokenId, string calldata newLore) external;

    function equip(
        uint256 tokenId,
        string calldata typeOf,
        uint256 itemTokenId
    ) external;

    function unequip(uint256 tokenId, string calldata typeOf) external;

    function whitelistMint(uint256 amount, bytes32[] calldata proof)
        external
        payable;

    function mint(uint256 amount) external payable;

    function freeId(uint256 tokenId, address contractAddress) external;

    function lockId(uint256 tokenId) external;

    function unlockId(uint256 tokenId) external;

    function addXP(uint256 tokenId, uint256 amount) external;

    function subtractXP(uint256 tokenId, uint256 amount) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IBrawlerBearzCommon} from "./IBrawlerBearzCommon.sol";

interface IBrawlerBearzRenderer is IBrawlerBearzCommon {
    function tokenURI(
        uint256 _tokenId,
        uint256 _seed,
        CustomMetadata memory _md
    ) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

interface IBrawlerBearzDynamicItems is IERC1155Upgradeable {
    struct CustomMetadata {
        string typeOf;
        string name;
        uint256 xp;
    }

    function getMetadata(uint256 tokenId)
        external
        view
        returns (CustomMetadata memory);

    function getItemType(uint256 tokenId) external view returns (string memory);

    function getItemName(uint256 tokenId) external view returns (string memory);

    function getItemXPReq(uint256 tokenId) external view returns (uint256);

    function setItemMetadata(
        uint256 tokenId,
        string calldata typeOf,
        string calldata name,
        uint256 xp
    ) external;

    function shopDrop(address _toAddress, uint256 _amount) external;

    function burnItemForOwnerAddress(
        uint256 _typeId,
        uint256 _quantity,
        address _materialOwnerAddress
    ) external;

    function mintItemToAddress(
        uint256 _typeId,
        uint256 _quantity,
        address _toAddress
    ) external;

    function mintBatchItemsToAddress(
        uint256[] memory _typeIds,
        uint256[] memory _quantities,
        address _toAddress
    ) external;

    function bulkSafeTransfer(
        uint256 _typeId,
        uint256 _quantityPerRecipient,
        address[] calldata recipients
    ) external;
}

// SPDX-License-Identifier: MIT
/**
  ______ _____   _____ ______ ___  __ _  _  _ 
 |  ____|  __ \ / ____|____  |__ \/_ | || || |
 | |__  | |__) | |        / /   ) || | \| |/ |
 |  __| |  _  /| |       / /   / / | |\_   _/ 
 | |____| | \ \| |____  / /   / /_ | |  | |   
 |______|_|  \_\\_____|/_/   |____||_|  |_|   
                                              
                                            
 */
pragma solidity ^0.8.0;

import "./BitMaps.sol";
import "./ERC721PsiRandomSeedReveal.sol";

abstract contract ERC721PsiRandomSeedRevealBurnable is
    ERC721PsiRandomSeedReveal
{
    using BitMaps for BitMaps.BitMap;
    BitMaps.BitMap private _burnedToken;

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address from = ownerOf(tokenId);
        _beforeTokenTransfers(from, address(0), tokenId, 1);
        _burnedToken.set(tokenId);
        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId)
        internal
        view
        virtual
        override
        returns (bool)
    {
        if (_burnedToken.get(tokenId)) {
            return false;
        }
        return super._exists(tokenId);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _minted - _burned() - 1;
    }

    /**
     * @dev Returns number of token burned.
     */
    function _burned() internal view returns (uint256 burned) {
        uint256 totalBucket = (_minted >> 8) + 1;
        for (uint256 i = 0; i < totalBucket; i++) {
            uint256 bucket = _burnedToken.getBucket(i);
            burned += _popcount(bucket);
        }
    }

    /**
     * @dev Returns number of set bits.
     */
    function _popcount(uint256 x) private pure returns (uint256 count) {
        unchecked {
            for (count = 0; x != 0; count++) x &= x - 1;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBrawlerBearzCommon {
    struct CustomMetadata {
        string name;
        string lore;
        uint256 background;
        uint256 weapon;
        uint256 armor;
        uint256 faceArmor;
        uint256 eyewear;
        uint256 misc;
        uint256 xp;
        bool isUnlocked;
    }

    struct Traits {
        uint256 strength;
        uint256 endurance;
        uint256 intelligence;
        uint256 luck;
        uint256 xp;
        uint256 level;
        string skin;
        string head;
        string eyes;
        string clothes;
        string mouth;
        string background;
        string weapon;
        string armor;
        string eyewear;
        string faceArmor;
        string misc;
        string locked;
    }

    struct Bear {
        string name;
        string description;
        string dna;
        Traits traits;
        CustomMetadata dynamic;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBrawlerBearzEvents {
    event NameChanged(uint256 indexed id, string name);
    event LoreChanged(uint256 indexed id, string lore);
    event Equipped(uint256 indexed id, string typeOf, uint256 itemTokenId);
    event Unequipped(uint256 indexed id, string typeOf, uint256 itemTokenId);
    event Staked(uint256 indexed id);
    event Unstaked(uint256 indexed id, uint256 amount);
    event ClaimedTokens(uint256 indexed id, uint256 amount);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBrawlerBearzErrors {
    error InvalidRecipient();
    error InvalidTokenIds();
    error InvalidOwner();
    error InvalidItemType();
    error InvalidString();
    error InvalidLength();
    error InvalidValue();
    error ItemRequiresMoreXP();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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
interface IERC165Upgradeable {
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
/**
  ______ _____   _____ ______ ___  __ _  _  _ 
 |  ____|  __ \ / ____|____  |__ \/_ | || || |
 | |__  | |__) | |        / /   ) || | \| |/ |
 |  __| |  _  /| |       / /   / / | |\_   _/ 
 | |____| | \ \| |____  / /   / /_ | |  | |   
 |______|_|  \_\\_____|/_/   |____||_|  |_|   
                                              
                                            
 */
pragma solidity ^0.8.0;

import "./BitScan.sol";

/**
 * @dev This Library is a modified version of Openzeppelin's BitMaps library.
 * Functions of finding the index of the closest set bit from a given index are added.
 * The indexing of each bucket is modifed to count from the MSB to the LSB instead of from the LSB to the MSB.
 * The modification of indexing makes finding the closest previous set bit more efficient in gas usage.
 */

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largelly inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */

library BitMaps {
    using BitScan for uint256;
    uint256 private constant MASK_INDEX_ZERO = (1 << 255);
    struct BitMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(BitMap storage bitmap, uint256 index)
        internal
        view
        returns (bool)
    {
        uint256 bucket = index >> 8;
        uint256 mask = MASK_INDEX_ZERO >> (index & 0xff);
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
        uint256 mask = MASK_INDEX_ZERO >> (index & 0xff);
        bitmap._data[bucket] |= mask;
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = MASK_INDEX_ZERO >> (index & 0xff);
        bitmap._data[bucket] &= ~mask;
    }

    /**
     * @dev Find the closest index of the set bit before `index`.
     */
    function scanForward(BitMap storage bitmap, uint256 index)
        internal
        view
        returns (uint256)
    {
        uint256 bucket = index >> 8;
        uint256 bucketIndex = (index & 0xff);
        uint256 offset = 0xff ^ bucketIndex;
        uint256 bb = bitmap._data[bucket];
        bb = bb >> offset;
        if (bb > 0) {
            unchecked {
                return (bucket << 8) | (bucketIndex - bb.bitScanForward256());
            }
        } else {
            require(bucket > 0, "!exists");
            unchecked {
                bucket--;
                bucketIndex = 255;
                offset = 0;
            }
            while (true) {
                bb = bitmap._data[bucket];
                if (bb > 0) {
                    unchecked {
                        return
                            (bucket << 8) |
                            (bucketIndex - bb.bitScanForward256());
                    }
                } else {
                    require(bucket > 0, "!existS");
                    unchecked {
                        bucket--;
                    }
                }
            }
        }
    }

    function getBucket(BitMap storage bitmap, uint256 bucket)
        internal
        view
        returns (uint256)
    {
        return bitmap._data[bucket];
    }
}

// SPDX-License-Identifier: MIT
/**
  ______ _____   _____ ______ ___  __ _  _  _ 
 |  ____|  __ \ / ____|____  |__ \/_ | || || |
 | |__  | |__) | |        / /   ) || | \| |/ |
 |  __| |  _  /| |       / /   / / | |\_   _/ 
 | |____| | \ \| |____  / /   / /_ | |  | |   
 |______|_|  \_\\_____|/_/   |____||_|  |_|
 */
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "./interfaces/IERC721RandomSeed.sol";
import "./BitMaps.sol";
import "./ERC721PsiBatchMetaData.sol";

abstract contract ERC721PsiRandomSeedReveal is
    IERC721RandomSeed,
    ERC721PsiBatchMetaData,
    VRFConsumerBaseV2
{
    // Chainklink VRF V2
    VRFCoordinatorV2Interface immutable COORDINATOR;
    uint32 immutable callbackGasLimit;
    uint16 immutable requestConfirmations;
    uint16 constant numWords = 1;

    // requestId => genId
    mapping(uint256 => uint256) private requestIdToGenId;

    // genId => seed
    mapping(uint256 => uint256) private genSeed;

    // batchHeadTokenId => genId
    mapping(uint256 => uint256) private _batchHeadtokenGen;

    // current genId for minting
    uint256 private currentGen = 1;

    event RandomnessRequest(uint256 requestId);

    constructor(
        address coordinator,
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations
    ) VRFConsumerBaseV2(coordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(coordinator);
        callbackGasLimit = _callbackGasLimit;
        requestConfirmations = _requestConfirmations;
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        uint256 randomness = randomWords[0];
        uint256 genId = requestIdToGenId[requestId];
        delete requestIdToGenId[genId];
        genSeed[genId] = randomness;
        _processRandomnessFulfillment(requestId, genId, randomness);
    }

    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal virtual override {
        uint256 tokenIdHead = _minted;
        _batchHeadtokenGen[tokenIdHead] = currentGen;
        super._safeMint(to, quantity, _data);
    }

    /**
        @dev Query the generation of `tokenId`.
     */
    function _tokenGen(uint256 tokenId) internal view returns (uint256) {
        require(_exists(tokenId), "!exists");
        return _batchHeadtokenGen[_getMetaDataBatchHead(tokenId)];
    }

    /**
        @dev Request the randomess for the tokens of the current generation.
     */
    function _reveal() internal virtual {
        uint256 requestId = COORDINATOR.requestRandomWords(
            _keyHash(),
            _subscriptionId(),
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        emit RandomnessRequest(requestId);
        requestIdToGenId[requestId] = currentGen;
        _processRandomnessRequest(requestId, currentGen);
        currentGen++;
    }

    /**
        @dev Return the random seed of `tokenId`.
        Revert when the randomness hasn't been fulfilled.
     */
    function seed(uint256 tokenId)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(_exists(tokenId), "!exists");

        unchecked {
            uint256 _genSeed = genSeed[_tokenGen(tokenId)];
            require(_genSeed != 0, "!fullfilled");
            return uint256(keccak256(abi.encode(_genSeed, tokenId)));
        }
    }

    /** 
        @dev Override the function to provide the corrosponding keyHash for the Chainlink VRF V2.

        see also: https://docs.chain.link/docs/vrf-contracts/
     */
    function _keyHash() internal virtual returns (bytes32);

    /** 
        @dev Override the function to provide the corrosponding subscription id for the Chainlink VRF V2.

        see also: https://docs.chain.link/docs/get-a-random-number/#create-and-fund-a-subscription
     */
    function _subscriptionId() internal virtual returns (uint64);

    function _processRandomnessRequest(uint256 requestId, uint256 genId)
        internal
    {}

    function _processRandomnessFulfillment(
        uint256 requestId,
        uint256 genId,
        uint256 randomness
    ) internal {}
}

// SPDX-License-Identifier: MIT
/**
  ______ _____   _____ ______ ___  __ _  _  _ 
 |  ____|  __ \ / ____|____  |__ \/_ | || || |
 | |__  | |__) | |        / /   ) || | \| |/ |
 |  __| |  _  /| |       / /   / / | |\_   _/ 
 | |____| | \ \| |____  / /   / /_ | |  | |   
 |______|_|  \_\\_____|/_/   |____||_|  |_|   
                                              
                                            
 */

pragma solidity ^0.8.0;

library BitScan {
    uint256 private constant DEBRUIJN_256 =
        0x818283848586878898a8b8c8d8e8f929395969799a9b9d9e9faaeb6bedeeff;
    bytes private constant LOOKUP_TABLE_256 =
        hex"0001020903110a19042112290b311a3905412245134d2a550c5d32651b6d3a7506264262237d468514804e8d2b95569d0d495ea533a966b11c886eb93bc176c9071727374353637324837e9b47af86c7155181ad4fd18ed32c9096db57d59ee30e2e4a6a5f92a6be3498aae067ddb2eb1d5989b56fd7baf33ca0c2ee77e5caf7ff0810182028303840444c545c646c7425617c847f8c949c48a4a8b087b8c0c816365272829aaec650acd0d28fdad4e22d6991bd97dfdcea58b4d6f29fede4f6fe0f1f2f3f4b5b6b607b8b93a3a7b7bf357199c5abcfd9e168bcdee9b3f1ecf5fd1e3e5a7a8aa2b670c4ced8bbe8f0f4fc3d79a1c3cde7effb78cce6facbf9f8";

    function isolateLSB256(uint256 bb) internal pure returns (uint256) {
        require(bb > 0);
        unchecked {
            return bb & (0 - bb);
        }
    }

    function isolateMSB256(uint256 bb) internal pure returns (uint256) {
        require(bb > 0);
        unchecked {
            bb |= bb >> 256;
            bb |= bb >> 128;
            bb |= bb >> 64;
            bb |= bb >> 32;
            bb |= bb >> 16;
            bb |= bb >> 8;
            bb |= bb >> 4;
            bb |= bb >> 2;
            bb |= bb >> 1;

            return (bb >> 1) + 1;
        }
    }

    function bitScanForward256(uint256 bb) internal pure returns (uint8) {
        unchecked {
            return
                uint8(
                    LOOKUP_TABLE_256[(isolateLSB256(bb) * DEBRUIJN_256) >> 248]
                );
        }
    }

    function bitScanReverse256(uint256 bb) internal pure returns (uint8) {
        unchecked {
            return
                255 -
                uint8(
                    LOOKUP_TABLE_256[
                        ((isolateMSB256(bb) * DEBRUIJN_256) >> 248)
                    ]
                );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC721RandomSeed {
    function seed(uint256 tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
/**
  ______ _____   _____ ______ ___  __ _  _  _ 
 |  ____|  __ \ / ____|____  |__ \/_ | || || |
 | |__  | |__) | |        / /   ) || | \| |/ |
 |  __| |  _  /| |       / /   / / | |\_   _/ 
 | |____| | \ \| |____  / /   / /_ | |  | |   
 |______|_|  \_\\_____|/_/   |____||_|  |_|   
                                              
                                            
 */

pragma solidity ^0.8.0;

import "./ERC721Psi.sol";
import "./BitMaps.sol";

abstract contract ERC721PsiBatchMetaData is ERC721Psi {
    using BitMaps for BitMaps.BitMap;
    BitMaps.BitMap private _metaDataBatchHead;

    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal virtual override {
        uint256 tokenIdBatchHead = _minted;
        _metaDataBatchHead.set(tokenIdBatchHead);
        super._safeMint(to, quantity, _data);
    }

    /**
     *  @dev Return the batch head tokenId where the on-chain metadata is stored during minting.
     *
     *  The returned tokenId will remain the same after the token transfer.
     */
    function _getMetaDataBatchHead(uint256 tokenId)
        internal
        view
        returns (uint256 tokenIdMetaDataBatchHead)
    {
        tokenIdMetaDataBatchHead = _metaDataBatchHead.scanForward(tokenId);
    }
}

// SPDX-License-Identifier: MIT
/**
  ______ _____   _____ ______ ___  __ _  _  _
 |  ____|  __ \ / ____|____  |__ \/_ | || || |
 | |__  | |__) | |        / /   ) || | \| |/ |
 |  __| |  _  /| |       / /   / / | |\_   _/
 | |____| | \ \| |____  / /   / /_ | |  | |
 |______|_|  \_\\_____|/_/   |____||_|  |_|


 */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./BitMaps.sol";
import "./Address.sol";

contract ERC721Psi is
    Context,
    ERC165,
    IERC721,
    IERC721Metadata,
    IERC721Enumerable
{
    using Address for address;
    using Strings for uint256;
    using BitMaps for BitMaps.BitMap;

    BitMaps.BitMap private _batchHead;

    string private _name;
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) internal _owners;
    uint256 internal _minted = 1; // Start token Ids at 1

    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(owner != address(0), "zero address");

        uint256 count;
        for (uint256 i; i < _minted; ++i) {
            if (_exists(i)) {
                if (owner == ownerOf(i)) {
                    ++count;
                }
            }
        }
        return count;
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        (address owner, uint256 tokenIdBatchHead) = _ownerAndBatchHeadOf(
            tokenId
        );
        return owner;
    }

    function _ownerAndBatchHeadOf(uint256 tokenId)
        internal
        view
        returns (address owner, uint256 tokenIdBatchHead)
    {
        require(_exists(tokenId), "!exists");
        tokenIdBatchHead = _getBatchHead(tokenId);
        owner = _owners[tokenIdBatchHead];
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "!exists");

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "!approval");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "!approved"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(_exists(tokenId), "!exists");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        require(operator != _msgSender(), "!approve");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "!approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "!approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "!ERC721Receiver"
        );
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return tokenId < _minted;
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(_exists(tokenId), "!exist");
        address owner = ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 quantity) internal virtual {
        _safeMint(to, quantity, "");
    }

    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal virtual {
        uint256 tokenIdBatchHead = _minted;

        require(quantity > 0, "zero");
        require(to != address(0), "!zeroaddress");

        _beforeTokenTransfers(address(0), to, tokenIdBatchHead, quantity);
        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = tokenIdBatchHead + i;
            emit Transfer(address(0), to, tokenId);
            require(
                _checkOnERC721Received(address(0), to, tokenId, _data),
                "!ERC721Receiver"
            );
        }

        _owners[tokenIdBatchHead] = to;
        _batchHead.set(tokenIdBatchHead);
        _minted += quantity;

        _afterTokenTransfers(address(0), to, tokenIdBatchHead, quantity);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        (address owner, uint256 tokenIdBatchHead) = _ownerAndBatchHeadOf(
            tokenId
        );

        require(owner == from, "notown");
        require(to != address(0), "zeroaddress");

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        uint256 nextTokenId = tokenId + 1;

        if (!_batchHead.get(nextTokenId) && nextTokenId < _minted) {
            _owners[nextTokenId] = from;
            _batchHead.set(nextTokenId);
        }

        _owners[tokenId] = to;
        if (tokenId != tokenIdBatchHead) {
            _batchHead.set(tokenId);
        }

        emit Transfer(from, to, tokenId);

        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("!ERC721Receiver");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _getBatchHead(uint256 tokenId)
        internal
        view
        returns (uint256 tokenIdBatchHead)
    {
        tokenIdBatchHead = _batchHead.scanForward(tokenId);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _minted;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(index < totalSupply(), "oob");

        uint256 count;
        for (uint256 i; i < _minted; i++) {
            if (_exists(i)) {
                if (count == index) return i;
                else count++;
            }
        }
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        virtual
        override
        returns (uint256 tokenId)
    {
        uint256 count;
        for (uint256 i; i < _minted; i++) {
            if (_exists(i) && owner == ownerOf(i)) {
                if (count == index) return i;
                else count++;
            }
        }

        revert("oob");
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library Address {
    function isContract(address account) internal view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}