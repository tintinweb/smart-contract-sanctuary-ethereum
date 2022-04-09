// SPDX-License-Identifier: CC0-1.0
/// @title The Helms (for Loot) ERC-1155 token

//   _    _      _                  ____             _                 _ __
//  | |  | |    | |                / / _|           | |               | |\ \
//  | |__| | ___| |_ __ ___  ___  | | |_ ___  _ __  | |     ___   ___ | |_| |
//  |  __  |/ _ \ | '_ ` _ \/ __| | |  _/ _ \| '__| | |    / _ \ / _ \| __| |
//  | |  | |  __/ | | | | | \__ \ | | || (_) | |    | |___| (_) | (_) | |_| |
//  |_|  |_|\___|_|_| |_| |_|___/ | |_| \___/|_|    |______\___/ \___/ \__| |
//                                 \_\                                   /_/

/* Helms (for Loot) is a 3D visualisation of the Helms of Loot */

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "contracts/LootInterfaces.sol";
import "contracts/HelmsMetadata.sol";

pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
}

interface IERC2981 {
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

interface ProxyRegistry {
    function proxies(address) external view returns (address);
}

contract HelmsForLoot is ERC1155, IERC2981, Ownable {
    // Code inspired by Rings (for Loot):
    // https://github.com/w1nt3r-eth/rings-for-loot/blob/main/contracts/RingsForLoot.sol

    string public PROVENANCE = "";

    enum SaleState {
        Paused,
        Phase1, // Common helms available
        Phase2, // Epic and legendary helms available
        Phase3 // Mythic helms available
    }
    SaleState public state = SaleState.Paused;
    bool public lootOnly = true;

    // The Lootmart contract is used to calculate the token ID,
    // guaranteeing the correct supply for each helm
    ILoot private ogLootContract;
    ILmart private lmartContract;
    IRiftData private riftDataContract;
    IHelmsMetadata public metadataContract;

    // Loot-compatible contracts that we support. Users can claim a matching
    // helm if they own a token in this contract and `getHead` matches helm's name
    mapping(ILoot => bool) private lootContracts;

    // We only allow claiming one matching helm per bag. This data structure
    // holds the contract/bag ids that were already claimed
    mapping(ILoot => mapping(uint256 => bool)) public lootClaimed;
    // This data structure keeps track of the Loot bags that were minted to
    // ensure the correct max supply of each helm
    mapping(uint256 => bool) public lootMinted;

    string public name = "Helms for Loot";
    string public symbol = "H4L";

    // Flag to enable/disable Wyvern Proxy approval for gas-free Opensea listings
    bool private wyvernProxyWhitelist = true;

    // Common and Epic helms can be identified by calculating their greatness, but
    // to determine whether a helm is legendary or mythic, we use a list of ids
    // Legendary helm ids are stored as a tightly packed arrays of uint16
    bytes[5] private under19legendaryIds;
    bytes[5] private over19legendaryIds;

    // Pricing
    uint256 public lootOwnerPriceCommon = 0.02 ether;
    uint256 public publicPriceCommon = 0.05 ether;

    uint256 public lootOwnerPriceEpic = 0.04 ether;
    uint256 public publicPriceEpic = 0.07 ether;

    uint256 public lootOwnerPriceLegendary = 0.06 ether;
    uint256 public publicPriceLegendary = 0.09 ether;

    uint256 public lootOwnerPriceMythic = 0.08 ether;
    uint256 public publicPriceMythic = 0.11 ether;

    event Minted(uint256 lootId);
    event Claimed(uint256 lootId);

    constructor(
        ILoot[] memory lootsList,
        ILmart lmart,
        IRiftData riftData
    ) ERC1155("") {
        for (uint256 i = 0; i < lootsList.length; i++) {
            if (i == 0) {
                ogLootContract = lootsList[i];
            }
            lootContracts[lootsList[i]] = true;
        }
        lmartContract = lmart;
        riftDataContract = riftData;

        // List of legendary helm ids with less than 19 greatness
        // and over 19 greatness to help with rarity determination
        under19legendaryIds[1] = hex"01131028039119120f7b14d2";
        under19legendaryIds[2] = hex"0200109b0f441b04";
        under19legendaryIds[4] = hex"01400eea06fa1c29088616e60f7c12b5";
        over19legendaryIds[1] = hex"00fd148101ee0c02030a0809037013d91d501d88";
        over19legendaryIds[2] = hex"064d0a68094114340b611e45";
        over19legendaryIds[4] = hex"01a81d870b141087";
    }

    /**
     * @dev Accepts a Loot bag ID and returns the rarity level of the helm contained within that bag.
     * Rarity levels (based on the number of times each helm appears in the set of 8000 Loot bags):
     * 1 - Common Helm (>19)
     * 2 - Epic Helm (<19)
     * 3 - Legendary Helm (2)
     * 4 - Mythic Helm (1)
     */
    function helmRarity(uint256 lootId) public view returns (uint256) {
        // We use a combination of the greatness calculation from the loot contract
        // and precomputed lists of legendary and mythic helm IDs
        // to determine the helm rarity.
        uint256 rand = uint256(
            keccak256(abi.encodePacked("HEAD", Strings.toString(lootId)))
        );
        uint256 greatness = rand % 21;
        uint256 kind = rand % 15;

        // Other head armor not supported by this contract
        require(kind < 6, "HelmsForLoot: no helm in bag");

        if (greatness <= 14) {
            return (1); // Comon Helm
        } else if (greatness < 19) {
            // Check if it is in the legendary list
            if (findHelmIndex(under19legendaryIds[kind], lootId)) {
                return (3); // Legendary Helm
            }
            // Else two possible mythic helms with less than 19 greatness:
            else if (lootId == 2304 || lootId == 4557) {
                return (4); // Mythic Helm
            } else {
                return (2); // Epic Helm
            }
        } else {
            if (findHelmIndex(over19legendaryIds[kind], lootId)) {
                return (3); // Legendary helm
            } else {
                return (4); // Mythic Helm
            }
        }
    }

    /**
     * @dev Accepts an array of Loot bag IDs and mints the corresponding Helm tokens.
     */
    function purchasePublic(uint256[] memory lootIds) public payable {
        require(!lootOnly, "HelmsForLoot: Loot-only minting period is active");

        require(lootIds.length > 0, "HelmsForLoot: buy at least one");
        require(lootIds.length <= 26, "HelmsForLoot: too many at once");

        uint256[] memory tokenIds = new uint256[](lootIds.length);
        uint256 price = 0;

        for (uint256 i = 0; i < lootIds.length; i++) {
            require(!lootMinted[lootIds[i]], "HelmsForLoot: already claimed");
            // Reserve Loot IDs 7778 to 8000 for ownerClaim
            require(
                lootIds[i] > 0 && lootIds[i] < 7778,
                "HelmsForLoot: invalid Loot ID"
            );

            uint256 rarity = helmRarity(lootIds[i]);

            if (rarity == 1) {
                require(
                    state == SaleState.Phase1 ||
                        state == SaleState.Phase2 ||
                        state == SaleState.Phase3,
                    "HelmsForLoot: sale not active"
                );
                price += publicPriceCommon;
            } else if (rarity == 2) {
                require(
                    state == SaleState.Phase2 || state == SaleState.Phase3,
                    "HelmsForLoot: sale not active"
                );
                price += publicPriceEpic;
            } else if (rarity == 3) {
                require(
                    state == SaleState.Phase3,
                    "HelmsForLoot: sale not active"
                );
                price += publicPriceLegendary;
            } else {
                require(
                    state == SaleState.Phase3,
                    "HelmsForLoot: sale not active"
                );
                price += publicPriceMythic;
            }

            lootMinted[lootIds[i]] = true;
            tokenIds[i] = lmartContract.headId(lootIds[i]);
        }

        require(msg.value == price, "HelmsForLoot: wrong price");

        // We're using a loop with _mint rather than _mintBatch
        // as currently some centralised tools like Opensea
        // have issues understanding the `TransferBatch` event
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _mint(msg.sender, tokenIds[i], 1, "");
            emit Minted(lootIds[i]);
        }
    }

    /**
     * @dev Allows the owner of a Loot, More Loot, or Genesis Adventurer
     * NFT to claim the Helm from a Loot bag that matches the Helm in
     * their bag. The address of the contract (Loot, More Loot, or GA)
     * needs to be provided, together with claimIds array containing
     * the IDs of the bags to be used for the claim, together with a
     * corresponding lootIds array that contains the IDs of the Loot Bags
     * with matching helms to be claimed. If claimRiftXP is set to true,
     * each bag in the claimIds array will gain 200 XP on The Rift.
     */
    function purchaseMatching(
        ILoot claimLoot,
        uint256[] memory claimIds,
        uint256[] memory lootIds,
        bool claimRiftXP
    ) public payable {
        require(
            state == SaleState.Phase1 ||
                state == SaleState.Phase2 ||
                state == SaleState.Phase3,
            "HelmsForLoot: sale not active"
        );

        require(lootContracts[claimLoot], "HelmsForLoot: not compatible");

        if (lootOnly == true) {
            require(
                claimLoot == ogLootContract,
                "HelmsForLoot: loot-only minting period is active."
            );
        }

        require(lootIds.length > 0, "HelmsForLoot: buy at least one");
        require(lootIds.length <= 26, "HelmsForLoot: too many at once");

        uint256[] memory tokenIds = new uint256[](lootIds.length);
        uint256 price = 0;

        for (uint256 i = 0; i < lootIds.length; i++) {
            // Reserve Loot IDs 7778 to 8000 for ownerClaim
            require(
                (lootIds[i] > 0 && lootIds[i] < 7778),
                "HelmsForLoot: invalid Loot ID"
            );

            require(
                claimLoot.ownerOf(claimIds[i]) == msg.sender,
                "HelmsForLoot: not owner"
            );

            require(
                keccak256(abi.encodePacked(claimLoot.getHead(claimIds[i]))) ==
                    keccak256(
                        abi.encodePacked(ogLootContract.getHead(lootIds[i]))
                    ),
                "HelmsForLoot: wrong helm"
            );

            // Both the original loot bag and matching bag
            // (loot/mloot/genesis adventurer) to be unclaimed
            require(
                !lootClaimed[claimLoot][claimIds[i]],
                "HelmsForLoot: bag already used for claim"
            );
            require(
                !lootMinted[lootIds[i]],
                "HelmsForLoot: loot bag already minted"
            );

            uint256 rarity = helmRarity(lootIds[i]);

            if (rarity == 1) {
                require(
                    state == SaleState.Phase1 ||
                        state == SaleState.Phase2 ||
                        state == SaleState.Phase3,
                    "HelmsForLoot: sale not active"
                );
                price += lootOwnerPriceCommon;
            } else if (rarity == 2) {
                require(
                    state == SaleState.Phase2 || state == SaleState.Phase3,
                    "HelmsForLoot: sale not active"
                );
                price += lootOwnerPriceEpic;
            } else if (rarity == 3) {
                require(
                    state == SaleState.Phase3,
                    "HelmsForLoot: sale not active"
                );
                price += lootOwnerPriceLegendary;
            } else {
                require(
                    state == SaleState.Phase3,
                    "HelmsForLoot: sale not active"
                );
                price += lootOwnerPriceMythic;
            }
            lootMinted[lootIds[i]] = true;
            lootClaimed[claimLoot][claimIds[i]] = true;
            tokenIds[i] = lmartContract.headId(lootIds[i]);
        }
        require(msg.value == price, "HelmsForLoot: wrong price");

        // We're using a loop with _mint rather than _mintBatch
        // as currently some centralised tools like Opensea
        // have issues understanding the `TransferBatch` event
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 riftId;
            // Add XP via The Rift
            if (claimRiftXP == true) {
                // Adjust ID for gLoot:
                if (claimLoot != ogLootContract && claimIds[i] < 8001) {
                    riftId = claimIds[i] + 9997460;
                } else {
                    riftId = claimIds[i];
                }
                riftDataContract.addXP(200, riftId);
            }
            _mint(msg.sender, tokenIds[i], 1, "");
            emit Claimed(lootIds[i]);
        }
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        require(
            address(metadataContract) != address(0),
            "HelmsForLoot: no metadata address"
        );
        return metadataContract.uri(tokenId);
    }

    /**
     * @dev Run a batch query to check if a set of loot, mloot or gloot IDs have been used for a claim.
     */
    function lootClaimedBatched(ILoot loot, uint256[] calldata ids)
        public
        view
        returns (bool[] memory claimed)
    {
        claimed = new bool[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            claimed[i] = lootClaimed[loot][ids[i]];
        }
    }

    /**
     * @dev Run a batch query to check if a set of loot bags have already been claimed.
     */
    function lootMintedBatched(uint256[] calldata ids)
        public
        view
        returns (bool[] memory minted)
    {
        minted = new bool[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            minted[i] = lootMinted[ids[i]];
        }
    }

    /**
     * @dev Utlity function to check a tightly packed array of uint16 for a given id.
     */
    function findHelmIndex(bytes storage data, uint256 helmId)
        internal
        view
        returns (bool found)
    {
        for (uint256 i = 0; i < data.length / 2; i++) {
            if (
                uint8(data[i * 2]) == ((helmId >> 8) & 0xFF) &&
                uint8(data[i * 2 + 1]) == (helmId & 0xFF)
            ) {
                return true;
            }
        }
        return false;
    }

    // Interfaces

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = owner();
        royaltyAmount = (salePrice * 5) / 100;
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Allow easier listing for sale on OpenSea. Based on
        // https://github.com/ProjectOpenSea/opensea-creatures/blob/f7257a043e82fae8251eec2bdde37a44fee474c4/migrations/2_deploy_contracts.js#L29
        if (wyvernProxyWhitelist == true) {
            if (block.chainid == 4) {
                if (
                    ProxyRegistry(0xF57B2c51dED3A29e6891aba85459d600256Cf317)
                        .proxies(owner) == operator
                ) {
                    return true;
                }
            } else if (block.chainid == 1) {
                if (
                    ProxyRegistry(0xa5409ec958C83C3f309868babACA7c86DCB077c1)
                        .proxies(owner) == operator
                ) {
                    return true;
                }
            }
        }

        return ERC1155.isApprovedForAll(owner, operator);
    }

    // Admin
    function setProvenance(string calldata prov) public onlyOwner {
        PROVENANCE = prov;
    }

    function setState(SaleState newState, bool newlootOnly) public onlyOwner {
        state = newState;
        lootOnly = newlootOnly;
    }

    function setMetadataContract(IHelmsMetadata addr) public onlyOwner {
        metadataContract = addr;
    }

    function setWyvernProxyWhitelist(bool enabled) public onlyOwner {
        wyvernProxyWhitelist = enabled;
    }

    /**
     * @dev Allows the owner to mint a set of helms for promotional purposes and to reward contributors.
     * Loot IDs 7778->8000
     */
    function ownerClaim(uint256[] memory lootIds, address to)
        public
        payable
        onlyOwner
    {
        // We're using a loop with _mint rather than _mintBatch
        // as currently some centralised tools like Opensea
        // have issues understanding the `TransferBatch` event
        for (uint256 i = 0; i < lootIds.length; i++) {
            require(lootIds[i] > 7777 && lootIds[i] < 8001, "Token ID invalid");
            lootMinted[lootIds[i]] = true;
            uint256 tokenId = lmartContract.headId(lootIds[i]);
            _mint(to, tokenId, 1, "");
            emit Minted(lootIds[i]);
        }
    }

    /**
     * Given an erc721 bag, returns the erc1155 token ids of the helm in the bag
     * We use LootMart's bijective encoding function.
     */
    function id(uint256 lootId) public view returns (uint256 headId) {
        return lmartContract.headId(lootId);
    }

    function setPricesCommon(uint256 newlootOwnerPrice, uint256 newPublicPrice)
        public
        onlyOwner
    {
        lootOwnerPriceCommon = newlootOwnerPrice;
        publicPriceCommon = newPublicPrice;
    }

    function setPricesEpic(uint256 newlootOwnerPrice, uint256 newPublicPrice)
        public
        onlyOwner
    {
        lootOwnerPriceEpic = newlootOwnerPrice;
        publicPriceEpic = newPublicPrice;
    }

    function setPricesLegendary(
        uint256 newlootOwnerPrice,
        uint256 newPublicPrice
    ) public onlyOwner {
        lootOwnerPriceLegendary = newlootOwnerPrice;
        publicPriceLegendary = newPublicPrice;
    }

    function setPricesMythic(uint256 newlootOwnerPrice, uint256 newPublicPrice)
        public
        onlyOwner
    {
        lootOwnerPriceMythic = newlootOwnerPrice;
        publicPriceMythic = newPublicPrice;
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function withdrawAllERC20(IERC20 erc20Token) public onlyOwner {
        require(
            erc20Token.transfer(msg.sender, erc20Token.balanceOf(address(this)))
        );
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

interface ILoot {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function balanceOf(address owner) external view returns (uint256 balance);

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 tokenId);

    function tokenByIndex(uint256 index) external view returns (uint256);

    function getHead(uint256 tokenId) external view returns (string memory);
}

interface ILmart {
    function headId(uint256 tokenId) external pure returns (uint256);

    function tokenName(uint256 id) external view returns (string memory);
}

interface IRiftData {
    function addXP(uint256 xp, uint256 bagId) external;
}

// SPDX-License-Identifier: CC0-1.0
/// @title The Helms (for Loot) Metadata

import "@openzeppelin/contracts/access/Ownable.sol";
import "base64-sol/base64.sol";
import "contracts/LootInterfaces.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

pragma solidity ^0.8.0;

interface IHelmsMetadata {
    function uri(uint256 tokenId) external view returns (string memory);
}

contract HelmsMetadata is Ownable, IHelmsMetadata {
    string public description;
    string public baseUri;
    string private imageUriSuffix = ".gif";
    string private animationUriSuffix = ".glb";
    ILmart private lmartContract;

    constructor(ILmart lmart, string memory IpfsUri) Ownable() {
        description = "Helms (for Loot) is the first 3D interpretation of the helms of Loot. Adventurers, builders, and artists are encouraged to reference Helms (for Loot) to further expand on the imagination of Loot.";
        lmartContract = lmart;
        baseUri = IpfsUri;
    }

    function setDescription(string memory desc) public onlyOwner {
        description = desc;
    }

    function setbaseUri(string calldata newbaseUri) public onlyOwner {
        baseUri = newbaseUri;
    }

    function setUriSuffix(
        string calldata newImageUriSuffix,
        string calldata newAnimationUriSuffix
    ) public onlyOwner {
        imageUriSuffix = newImageUriSuffix;
        animationUriSuffix = newAnimationUriSuffix;
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        string memory name = lmartContract.tokenName(tokenId);
        bytes memory tokenUri = abi.encodePacked(
            baseUri,
            "/",
            Strings.toString(tokenId)
        );
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{ "name": "',
                        name,
                        '", ',
                        '"description": ',
                        '"Helms (for Loot) is the first 3D interpretation of the helms of Loot. Adventurers, builders, and artists are encouraged to reference Helms (for Loot) to further expand on the imagination of Loot.", ',
                        '"image": ',
                        '"',
                        tokenUri,
                        imageUriSuffix,
                        '", '
                        '"animation_url": ',
                        '"',
                        tokenUri,
                        animationUriSuffix,
                        '"'
                        "}"
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
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

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
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