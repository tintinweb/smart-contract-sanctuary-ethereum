// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable diamond facet contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */

import {InitializableStorage} from "./InitializableStorage.sol";

abstract contract Initializable {
    using InitializableStorage for InitializableStorage.Layout;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(
            InitializableStorage.layout()._initializing ? isConstructor() : !InitializableStorage.layout()._initialized,
            "Initializable: contract is already initialized"
        );

        bool isTopLevelCall = !InitializableStorage.layout()._initializing;
        if (isTopLevelCall) {
            InitializableStorage.layout()._initializing = true;
            InitializableStorage.layout()._initialized = true;
        }

        _;

        if (isTopLevelCall) {
            InitializableStorage.layout()._initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(InitializableStorage.layout()._initializing, "Initializable: contract is not initializing");
        _;
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        assembly {
            cs := extcodesize(self)
        }
        return cs == 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base storage for the  initialization function for upgradeable diamond facet contracts
 **/

library InitializableStorage {
    struct Layout {
        /*
         * Indicates that the contract has been initialized.
         */
        bool _initialized;
        /*
         * Indicates that the contract is in the process of being initialized.
         */
        bool _initializing;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("openzepplin.contracts.storage.initializable.facet");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Modifiers} from "../shared/Modifiers.sol";

// abstract contract to include app-wide modifiers for ease of use
abstract contract AppModifiers is Modifiers {

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// This interface serves as a way to consolidate event definition conflicts (i.e. ApprovalForAll erc721/erc1155)
interface IConflictedEvents {
    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../../../../transpiled-oz/utils/StringsUpgradeable.sol";
import {ERC1155721Storage} from "./ERC1155721Storage.sol";

contract BaseMetadataURI {
    using StringsUpgradeable for uint256;

    event BaseMetadataURISet(string baseMetadataURI);

    function setBaseMetadataURI(string calldata baseMetadataURI_) external {
        ERC1155721Storage.getState().baseMetadataURI = baseMetadataURI_;
        emit BaseMetadataURISet(baseMetadataURI_);
    }

    function _uri(uint256 id) internal view virtual returns (string memory) {
        return string(abi.encodePacked(ERC1155721Storage.getState().baseMetadataURI, id.toString()));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC721, IERC721Metadata, IERC721BatchTransfer, IERC721Receiver} from "./interfaces/Interfaces.sol";
import {ERC1155InventoryBase} from "./ERC1155InventoryBase.sol";
import {AddressUpgradeable} from "../../../../../transpiled-oz/utils/AddressUpgradeable.sol";
import {ERC1155InventoryIdentifiersLib} from "./ERC1155InventoryIdentifiersLib.sol";
import {ERC1155721Storage} from "./ERC1155721Storage.sol";

abstract contract ERC1155721Inventory is IERC721, IERC721Metadata, IERC721BatchTransfer, ERC1155InventoryBase {
    using AddressUpgradeable for address;
    using ERC1155InventoryIdentifiersLib for uint256;

    bytes4 private constant _ERC165_INTERFACE_ID = 0x01ffc9a7;
    bytes4 private constant _ERC1155_TOKEN_RECEIVER_INTERFACE_ID = 0xd9b67a26;
    bytes4 private constant _ERC721_INTERFACE_ID = 0x80ac58cd;
    bytes4 private constant _ERC721_METADATA_INTERFACE_ID = 0x5b5e139f;
    bytes4 internal constant _ERC721_RECEIVED = 0x150b7a02;

    uint256 internal constant _APPROVAL_BIT_TOKEN_OWNER_ = 1 << 160;


    /// @dev See {IERC165-supportsInterface(bytes4)}.
    // function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    //     return super.supportsInterface(interfaceId) || interfaceId == _ERC721_INTERFACE_ID || interfaceId == _ERC721_METADATA_INTERFACE_ID;
    // }

    //===================================== ERC721 ==========================================/

    /// @dev See {IERC721-balanceOf(address)}.
    function balanceOf(address tokenOwner) external view virtual override returns (uint256) {
        require(tokenOwner != address(0), "Inventory: zero address");
        return ERC1155721Storage.getState()._nftBalances[tokenOwner];
    }

    /// @dev See {IERC721-ownerOf(uint256)} and {IERC1155Inventory-ownerOf(uint256)}.
    function ownerOf(uint256 nftId) public view virtual override(IERC721, ERC1155InventoryBase) returns (address) {
        return ERC1155InventoryBase.ownerOf(nftId);
    }

    /// @dev See {IERC721-approve(address,uint256)}.
    function approve(address to, uint256 nftId) external virtual override {
        address tokenOwner = ownerOf(nftId);
        require(to != tokenOwner, "Inventory: self-approval");
        require(_isOperatable(tokenOwner, msg.sender), "Inventory: non-approved sender");
        ERC1155721Storage.getState()._owners[nftId] = uint256(uint160(tokenOwner)) | _APPROVAL_BIT_TOKEN_OWNER_;
        ERC1155721Storage.getState()._nftApprovals[nftId] = to;
        emit Approval(tokenOwner, to, nftId);
    }

    /// @dev See {IERC721-getApproved(uint256)}.
    function getApproved(uint256 nftId) external view virtual override returns (address) {
        uint256 tokenOwner = ERC1155721Storage.getState()._owners[nftId];
        require(address(uint160(tokenOwner)) != address(0), "Inventory: non-existing NFT");
        if (tokenOwner & _APPROVAL_BIT_TOKEN_OWNER_ != 0) {
            return ERC1155721Storage.getState()._nftApprovals[nftId];
        } else {
            return address(0);
        }
    }

    /// @dev See {IERC721-isApprovedForAll(address,address)} and {IERC1155-isApprovedForAll(address,address)}
    function isApprovedForAll(address tokenOwner, address operator) public view virtual override(IERC721, ERC1155InventoryBase) returns (bool) {
        return ERC1155InventoryBase.isApprovedForAll(tokenOwner, operator);
    }

    /// @dev See {IERC721-isApprovedForAll(address,address)} and {IERC1155-isApprovedForAll(address,address)}
    function setApprovalForAll(address operator, bool approved) public virtual override(IERC721, ERC1155InventoryBase) {
        return ERC1155InventoryBase.setApprovalForAll(operator, approved);
    }

    /**
     * Unsafely transfers a Non-Fungible Token (ERC721-compatible).
     * @dev See {IERC1155721Inventory-transferFrom(address,address,uint256)}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 nftId
    ) public virtual override {
        _transferFrom(
            from,
            to,
            nftId,
            "",
            /* safe */
            false
        );
    }

    /**
     * Safely transfers a Non-Fungible Token (ERC721-compatible).
     * @dev See {IERC1155721Inventory-safeTransferFrom(address,address,uint256)}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 nftId
    ) public virtual override {
        _transferFrom(
            from,
            to,
            nftId,
            "",
            /* safe */
            true
        );
    }

    /**
     * Safely transfers a Non-Fungible Token (ERC721-compatible).
     * @dev See {IERC1155721Inventory-safeTransferFrom(address,address,uint256,bytes)}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 nftId,
        bytes memory data
    ) public virtual override {
        _transferFrom(
            from,
            to,
            nftId,
            data,
            /* safe */
            true
        );
    }

    /**
     * Unsafely transfers a batch of Non-Fungible Tokens (ERC721-compatible).
     * @dev See {IERC1155721BatchTransfer-batchTransferFrom(address,address,uint256[])}.
     */
    function batchTransferFrom(
        address from,
        address to,
        uint256[] memory nftIds
    ) public virtual override {
        require(to != address(0), "Inventory: transfer to zero");
        address sender = msg.sender;
        bool operatable = _isOperatable(from, sender);

        uint256 length = nftIds.length;
        uint256[] memory values = new uint256[](length);

        uint256 nfCollectionId;
        uint256 nfCollectionCount;
        for (uint256 i; i != length; ++i) {
            uint256 nftId = nftIds[i];
            values[i] = 1;
            _transferNFT(from, to, nftId, 1, operatable, true);
            emit Transfer(from, to, nftId);
            uint256 nextCollectionId = nftId.getNonFungibleCollection();
            if (nfCollectionId == 0) {
                nfCollectionId = nextCollectionId;
                nfCollectionCount = 1;
            } else {
                if (nextCollectionId != nfCollectionId) {
                    _transferNFTUpdateCollection(from, to, nfCollectionId, nfCollectionCount);
                    nfCollectionId = nextCollectionId;
                    nfCollectionCount = 1;
                } else {
                    ++nfCollectionCount;
                }
            }
        }

        if (nfCollectionId != 0) {
            _transferNFTUpdateCollection(from, to, nfCollectionId, nfCollectionCount);
            _transferNFTUpdateBalances(from, to, length);
        }

        emit TransferBatch(msg.sender, from, to, nftIds, values);
        if (to.isContract() && _isERC1155TokenReceiver(to)) {
            _callOnERC1155BatchReceived(from, to, nftIds, values, "");
        }
    }

    /// @dev See {IERC721Metadata-tokenURI(uint256)}.
    function tokenURI(uint256 nftId) external view virtual override returns (string memory) {
        require(address(uint160(ERC1155721Storage.getState()._owners[nftId])) != address(0), "Inventory: non-existing NFT");
        return uri(nftId);
    }

    //================================== ERC1155 =======================================/

    /**
     * Safely transfers some token (ERC1155-compatible).
     * @dev See {IERC1155721Inventory-safeTransferFrom(address,address,uint256,uint256,bytes)}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes memory data
    ) public virtual override {
        address sender = msg.sender;
        require(to != address(0), "Inventory: transfer to zero");
        bool operatable = _isOperatable(from, sender);

        if (id.isFungibleToken()) {
            _transferFungible(from, to, id, value, operatable);
        } else if (id.isNonFungibleToken()) {
            _transferNFT(from, to, id, value, operatable, false);
            emit Transfer(from, to, id);
        } else {
            revert("Inventory: not a token id");
        }
        // This must be emitted for the erc721 tokens to display in marketplaces as 1155s
        emit TransferSingle(sender, from, to, id, value);

        if (to.isContract()) {
            _callOnERC1155Received(from, to, id, value, data);
        }
    }

    /**
     * Safely transfers a batch of tokens (ERC1155-compatible).
     * @dev See {IERC1155721Inventory-safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) public virtual override {
        // internal function to avoid stack too deep error
        _safeBatchTransferFrom(from, to, ids, values, data);
    }

    //================================== ERC1155MetadataURI =======================================/

    /// @dev See {IERC1155MetadataURI-uri(uint256)}.
    function uri(uint256) public view virtual override returns (string memory);

    //================================== ABI-level Internal Functions =======================================/

    /**
     * Safely or unsafely transfers some token (ERC721-compatible).
     * @dev For `safe` transfer, see {IERC1155721Inventory-transferFrom(address,address,uint256)}.
     * @dev For un`safe` transfer, see {IERC1155721Inventory-safeTransferFrom(address,address,uint256,bytes)}.
     */
    function _transferFrom(
        address from,
        address to,
        uint256 nftId,
        bytes memory data,
        bool safe
    ) internal {
        require(to != address(0), "Inventory: transfer to zero");
        address sender = msg.sender;
        bool operatable = _isOperatable(from, sender);

        _transferNFT(from, to, nftId, 1, operatable, false);

        emit Transfer(from, to, nftId);
        emit TransferSingle(sender, from, to, nftId, 1);
        if (to.isContract()) {
            if (_isERC1155TokenReceiver(to)) {
                _callOnERC1155Received(from, to, nftId, 1, data);
            } else if (safe) {
                _callOnERC721Received(from, to, nftId, data);
            }
        }
    }

    /**
     * Safely transfers a batch of tokens (ERC1155-compatible).
     * @dev See {IERC1155721Inventory-safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)}.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) internal {
        require(to != address(0), "Inventory: transfer to zero");
        uint256 length = ids.length;
        require(length == values.length, "Inventory: inconsistent arrays");
        address sender = msg.sender;
        bool operatable = _isOperatable(from, sender);

        uint256 nfCollectionId;
        uint256 nfCollectionCount;
        uint256 nftsCount;
        for (uint256 i; i != length; ++i) {
            uint256 id = ids[i];
            if (id.isFungibleToken()) {
                _transferFungible(from, to, id, values[i], operatable);
            } else if (id.isNonFungibleToken()) {
                _transferNFT(from, to, id, values[i], operatable, true);
                emit Transfer(from, to, id);
                uint256 nextCollectionId = id.getNonFungibleCollection();
                if (nfCollectionId == 0) {
                    nfCollectionId = nextCollectionId;
                    nfCollectionCount = 1;
                } else {
                    if (nextCollectionId != nfCollectionId) {
                        _transferNFTUpdateCollection(from, to, nfCollectionId, nfCollectionCount);
                        nfCollectionId = nextCollectionId;
                        nftsCount += nfCollectionCount;
                        nfCollectionCount = 1;
                    } else {
                        ++nfCollectionCount;
                    }
                }
            } else {
                revert("Inventory: not a token id");
            }
        }

        if (nfCollectionId != 0) {
            _transferNFTUpdateCollection(from, to, nfCollectionId, nfCollectionCount);
            nftsCount += nfCollectionCount;
            _transferNFTUpdateBalances(from, to, nftsCount);
        }
        emit TransferBatch(msg.sender, from, to, ids, values);

        if (to.isContract()) {
            _callOnERC1155BatchReceived(from, to, ids, values, data);
        }
    }

    /**
     * Safely or unsafely mints some token (ERC721-compatible).
     * @dev For `safe` mint, see {IERC1155721InventoryMintable-mint(address,uint256)}.
     * @dev For un`safe` mint, see {IERC1155721InventoryMintable-safeMint(address,uint256,bytes)}.
     */
    function _mint(
        address to,
        uint256 nftId,
        bytes memory data,
        bool safe
    ) internal {
        require(to != address(0), "Inventory: transfer to zero");
        // require(nftId.isNonFungibleToken(), "Inventory: not an NFT");

        _mintNFT(to, nftId, 1, false);

        emit Transfer(address(0), to, nftId);
        // This must be emitted for the erc721 tokens to display in marketplaces as 1155s
        emit TransferSingle(msg.sender, address(0), to, nftId, 1);
        if (to.isContract()) {
            if (_isERC1155TokenReceiver(to)) {
                _callOnERC1155Received(address(0), to, nftId, 1, data);
            } else if (safe) {
                _callOnERC721Received(address(0), to, nftId, data);
            }
        }
    }

    /**
     * Unsafely mints a batch of Non-Fungible Tokens (ERC721-compatible).
     * @dev See {IERC1155721InventoryMintable-batchMint(address,uint256[])}.
     */
    function _batchMint(address to, uint256[] memory nftIds) internal {
        require(to != address(0), "Inventory: transfer to zero");

        uint256 length = nftIds.length;
        require(length > 0, "no ids given");

        uint256[] memory values = new uint256[](length);
        uint256 nfCollectionId;
        uint256 nfCollectionCount;
        for (uint256 i; i != length; ++i) {
            uint256 nftId = nftIds[i];
            require(nftId.isNonFungibleToken(), "Inventory: not an NFT");
            values[i] = 1;
            _mintNFT(to, nftId, 1, true);
            emit Transfer(address(0), to, nftId);
            uint256 nextCollectionId = nftId.getNonFungibleCollection();
            if (nfCollectionId == 0) {
                nfCollectionId = nextCollectionId;
                nfCollectionCount = 1;
            } else {
                if (nextCollectionId != nfCollectionId) {
                    ERC1155721Storage.getState()._balances[nfCollectionId][to] += nfCollectionCount;
                    ERC1155721Storage.getState()._supplies[nfCollectionId] += nfCollectionCount;
                    nfCollectionId = nextCollectionId;
                    nfCollectionCount = 1;
                } else {
                    ++nfCollectionCount;
                }
            }
        }
        require(nfCollectionId > 0, "No collection found");
        ERC1155721Storage.getState()._balances[nfCollectionId][to] += nfCollectionCount;
        ERC1155721Storage.getState()._supplies[nfCollectionId] += nfCollectionCount;
        ERC1155721Storage.getState()._nftBalances[to] += length;

        emit TransferBatch(msg.sender, address(0), to, nftIds, values);
        if (to.isContract() && _isERC1155TokenReceiver(to)) {
            _callOnERC1155BatchReceived(address(0), to, nftIds, values, "");
        }
    }

    /**
     * Safely mints some token (ERC1155-compatible).
     * @dev See {IERC1155721InventoryMintable-safeMint(address,uint256,uint256,bytes)}.
     */
    function _safeMint(
        address to,
        uint256 id,
        uint256 value,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "Inventory: transfer to zero");
        address sender = msg.sender;
        if (id.isFungibleToken()) {
            _mintFungible(to, id, value);
        } else if (id.isNonFungibleToken()) {
            _mintNFT(to, id, value, false);
            emit Transfer(address(0), to, id);
        } else {
            revert("Inventory: not a token id");
        }
        // This must be emitted for the erc721 tokens to display in marketplaces as 1155s
        emit TransferSingle(sender, address(0), to, id, value);

        if (to.isContract()) {
            _callOnERC1155Received(address(0), to, id, value, data);
        }
    }

    /**
     * Safely mints a batch of tokens (ERC1155-compatible).
     * @dev See {IERC1155721InventoryMintable-safeBatchMint(address,uint256[],uint256[],bytes)}.
     */
    function _safeBatchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "Inventory: transfer to zero");
        uint256 length = ids.length;
        require(length == values.length, "Inventory: inconsistent arrays");

        uint256 nfCollectionId;
        uint256 nfCollectionCount;
        uint256 nftsCount;
        uint256 supplyIncrease;
        // TODO: disallow batching erc721 + erc115 at the same time
        for (uint256 i; i != length; ++i) {
            uint256 id = ids[i];
            uint256 value = values[i];
            supplyIncrease += value;
            if (id.isFungibleToken()) {
                _mintFungible(to, id, value);
            } else if (id.isNonFungibleToken()) {
                _mintNFT(to, id, value, true);
                emit Transfer(address(0), to, id);
                uint256 nextCollectionId = id.getNonFungibleCollection();
                if (nfCollectionId == 0) {
                    nfCollectionId = nextCollectionId;
                    nfCollectionCount = 1;
                } else {
                    if (nextCollectionId != nfCollectionId) {
                        ERC1155721Storage.getState()._balances[nfCollectionId][to] += nfCollectionCount;
                        ERC1155721Storage.getState()._supplies[nfCollectionId] += nfCollectionCount;
                        nfCollectionId = nextCollectionId;
                        nftsCount += nfCollectionCount;
                        nfCollectionCount = 1;
                    } else {
                        ++nfCollectionCount;
                    }
                }
            } else {
                revert("Inventory: not a token id");
            }
        }

        if (nfCollectionId != 0) {
            ERC1155721Storage.getState()._balances[nfCollectionId][to] += nfCollectionCount;
            ERC1155721Storage.getState()._supplies[nfCollectionId] += nfCollectionCount;
            nftsCount += nfCollectionCount;
            ERC1155721Storage.getState()._nftBalances[to] += nftsCount;
        }
        emit TransferBatch(msg.sender, address(0), to, ids, values);

        ERC1155721Storage.getState()._totalSupply += supplyIncrease;

        if (to.isContract()) {
            _callOnERC1155BatchReceived(address(0), to, ids, values, data);
        }
    }

    //============================== Internal Helper Functions =======================================/

    function _mintFungible(
        address to,
        uint256 id,
        uint256 value
    ) internal {
        require(value != 0, "Inventory: zero value");
        uint256 supply = ERC1155721Storage.getState()._supplies[id];
        uint256 newSupply = supply + value;
        require(newSupply > supply, "Inventory: supply overflow");
        ERC1155721Storage.getState()._supplies[id] = newSupply;
        // cannot overflow as supply cannot overflow
        ERC1155721Storage.getState()._balances[id][to] += value;
    }

    function _mintNFT(
        address to,
        uint256 id,
        uint256 value,
        bool isBatch
    ) internal {
        require(value == 1, "Inventory: wrong NFT value");
        require(ERC1155721Storage.getState()._owners[id] == 0, "Inventory: existing/burnt NFT");

        ERC1155721Storage.getState()._owners[id] = uint256(uint160(to));

        if (!isBatch) {
            uint256 collectionId = id.getNonFungibleCollection();
            // it is virtually impossible that a non-fungible collection supply
            // overflows due to the cost of minting individual tokens
            ++ERC1155721Storage.getState()._supplies[collectionId];
            ++ERC1155721Storage.getState()._balances[collectionId][to];
            ++ERC1155721Storage.getState()._nftBalances[to];
        }
    }

    function _transferFungible(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bool operatable
    ) internal {
        require(operatable, "Inventory: non-approved sender");
        require(value != 0, "Inventory: zero value");
        uint256 balance = ERC1155721Storage.getState()._balances[id][from];
        require(balance >= value, "Inventory: not enough balance");
        if (from != to) {
            ERC1155721Storage.getState()._balances[id][from] = balance - value;
            // cannot overflow as supply cannot overflow
            ERC1155721Storage.getState()._balances[id][to] += value;
        }
    }

    function _transferNFT(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bool operatable,
        bool isBatch
    ) internal virtual {
        require(value == 1, "Inventory: wrong NFT value");
        uint256 owner = ERC1155721Storage.getState()._owners[id];
        require(from == address(uint160(owner)), "Inventory: non-owned NFT");
        if (!operatable) {
            require((owner & _APPROVAL_BIT_TOKEN_OWNER_ != 0) && msg.sender == ERC1155721Storage.getState()._nftApprovals[id], "Inventory: non-approved sender");
        }
        ERC1155721Storage.getState()._owners[id] = uint256(uint160(to));
        if (!isBatch) {
            _transferNFTUpdateBalances(from, to, 1);
            _transferNFTUpdateCollection(from, to, id.getNonFungibleCollection(), 1);
        }
    }

    function _transferNFTUpdateBalances(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        if (from != to) {
            // cannot underflow as balance is verified through ownership
            ERC1155721Storage.getState()._nftBalances[from] -= amount;
            //  cannot overflow as supply cannot overflow
            ERC1155721Storage.getState()._nftBalances[to] += amount;
        }
    }

    function _transferNFTUpdateCollection(
        address from,
        address to,
        uint256 collectionId,
        uint256 amount
    ) internal virtual {
        if (from != to) {
            // cannot underflow as balance is verified through ownership
            ERC1155721Storage.getState()._balances[collectionId][from] -= amount;
            // cannot overflow as supply cannot overflow
            ERC1155721Storage.getState()._balances[collectionId][to] += amount;
        }
    }

    ///////////////////////////////////// Receiver Calls Internal /////////////////////////////////////

    /**
     * Queries whether a contract implements ERC1155TokenReceiver.
     * @param _contract address of the contract.
     * @return wheter the given contract implements ERC1155TokenReceiver.
     */
    function _isERC1155TokenReceiver(address _contract) internal view returns (bool) {
        bool success;
        bool result;
        bytes memory staticCallData = abi.encodeWithSelector(_ERC165_INTERFACE_ID, _ERC1155_TOKEN_RECEIVER_INTERFACE_ID);
        assembly {
            let call_ptr := add(0x20, staticCallData)
            let call_size := mload(staticCallData)
            let output := mload(0x40) // Find empty storage location using "free memory pointer"
            mstore(output, 0x0)
            success := staticcall(10000, _contract, call_ptr, call_size, output, 0x20) // 32 bytes
            result := mload(output)
        }
        // (10000 / 63) "not enough for supportsInterface(...)" // consume all gas, so caller can potentially know that there was not enough gas
        assert(gasleft() > 158);
        return success && result;
    }

    /**
     * Calls {IERC721Receiver-onERC721Received} on a target contract.
     * @dev Reverts if `to` is not a contract.
     * @dev Reverts if the call to the target fails or is refused.
     * @param from Previous token owner.
     * @param to New token owner.
     * @param nftId Identifier of the token transferred.
     * @param data Optional data to send along with the receiver contract call.
     */
    function _callOnERC721Received(
        address from,
        address to,
        uint256 nftId,
        bytes memory data
    ) internal {
        require(IERC721Receiver(to).onERC721Received(msg.sender, from, nftId, data) == _ERC721_RECEIVED, "Inventory: transfer refused");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC1155721InventoryBurnable} from "./IERC1155721InventoryBurnable.sol";
import {ERC1155721Inventory} from "./ERC1155721Inventory.sol";
import {ERC1155InventoryIdentifiersLib} from "./ERC1155InventoryIdentifiersLib.sol";
import {ERC1155721Storage} from "./ERC1155721Storage.sol";

abstract contract ERC1155721InventoryBurnable is IERC1155721InventoryBurnable, ERC1155721Inventory {
    //============================== ERC1155721InventoryBurnable =======================================/
    using ERC1155InventoryIdentifiersLib for uint256;

    /**
     * Burns some token (ERC1155-compatible).
     * @dev See {IERC1155721InventoryBurnable-burnFrom(address,uint256,uint256)}.
     */
    function burnFrom(
        address from,
        uint256 id,
        uint256 value
    ) public virtual override {
        address sender = msg.sender;
        bool operatable = _isOperatable(from, sender);

        if (id.isFungibleToken()) {
            _burnFungible(from, id, value, operatable);
        } else if (id.isNonFungibleToken()) {
            _burnNFT(from, id, value, operatable, false);
            emit Transfer(from, address(0), id);
        } else {
            revert("Inventory: not a token id");
        }

        emit TransferSingle(sender, from, address(0), id, value);
    }

    /**
     * Burns a batch of token (ERC1155-compatible).
     * @dev See {IERC1155721InventoryBurnable-batchBurnFrom(address,uint256[],uint256[])}.
     */
    function batchBurnFrom(
        address from,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual override {
        uint256 length = ids.length;
        require(length == values.length, "Inventory: inconsistent arrays");

        address sender = msg.sender;
        bool operatable = _isOperatable(from, sender);

        uint256 nfCollectionId;
        uint256 nfCollectionCount;
        uint256 nftsCount;
        uint256 supplyDecrease;
        for (uint256 i; i != length; ++i) {
            uint256 id = ids[i];
            uint256 value = values[i];
            supplyDecrease += value;
            if (id.isFungibleToken()) {
                _burnFungible(from, id, value, operatable);
            } else if (id.isNonFungibleToken()) {
                _burnNFT(from, id, value, operatable, true);
                emit Transfer(from, address(0), id);
                uint256 nextCollectionId = id.getNonFungibleCollection();
                if (nfCollectionId == 0) {
                    nfCollectionId = nextCollectionId;
                    nfCollectionCount = 1;
                } else {
                    if (nextCollectionId != nfCollectionId) {
                        _burnNFTUpdateCollection(from, nfCollectionId, nfCollectionCount);
                        nfCollectionId = nextCollectionId;
                        nftsCount += nfCollectionCount;
                        nfCollectionCount = 1;
                    } else {
                        ++nfCollectionCount;
                    }
                }
            } else {
                revert("Inventory: not a token id");
            }
        }

        if (nfCollectionId != 0) {
            _burnNFTUpdateCollection(from, nfCollectionId, nfCollectionCount);
            nftsCount += nfCollectionCount;
            // cannot underflow as balance is verified through ownership
            ERC1155721Storage.getState()._nftBalances[from] -= nftsCount;
        }

        ERC1155721Storage.getState()._totalSupply -= supplyDecrease;

        emit TransferBatch(sender, from, address(0), ids, values);
    }

    /**
     * Burns a batch of token (ERC721-compatible).
     * @dev See {IERC1155721InventoryBurnable-batchBurnFrom(address,uint256[])}.
     */
    function batchBurnFrom(address from, uint256[] memory nftIds) public virtual override {
        address sender = msg.sender;
        bool operatable = _isOperatable(from, sender);

        uint256 length = nftIds.length;
        uint256[] memory values = new uint256[](length);

        uint256 nfCollectionId;
        uint256 nfCollectionCount;
        for (uint256 i; i != length; ++i) {
            uint256 nftId = nftIds[i];
            values[i] = 1;
            _burnNFT(from, nftId, values[i], operatable, true);
            emit Transfer(from, address(0), nftId);
            uint256 nextCollectionId = nftId.getNonFungibleCollection();
            if (nfCollectionId == 0) {
                nfCollectionId = nextCollectionId;
                nfCollectionCount = 1;
            } else {
                if (nextCollectionId != nfCollectionId) {
                    _burnNFTUpdateCollection(from, nfCollectionId, nfCollectionCount);
                    nfCollectionId = nextCollectionId;
                    nfCollectionCount = 1;
                } else {
                    ++nfCollectionCount;
                }
            }
        }

        if (nfCollectionId != 0) {
            _burnNFTUpdateCollection(from, nfCollectionId, nfCollectionCount);
            ERC1155721Storage.getState()._nftBalances[from] -= length;
        }

        emit TransferBatch(sender, from, address(0), nftIds, values);
    }

    //============================== Internal Helper Functions =======================================/

    function _burnFungible(
        address from,
        uint256 id,
        uint256 value,
        bool operatable
    ) internal {
        require(value != 0, "Inventory: zero value");
        require(operatable, "Inventory: non-approved sender");
        uint256 balance = ERC1155721Storage.getState()._balances[id][from];
        require(balance >= value, "Inventory: not enough balance");
        ERC1155721Storage.getState()._balances[id][from] = balance - value;
        // Cannot underflow
        ERC1155721Storage.getState()._supplies[id] -= value;
    }

    function _burnNFT(
        address from,
        uint256 id,
        uint256 value,
        bool operatable,
        bool isBatch
    ) internal virtual {
        require(value == 1, "Inventory: wrong NFT value");
        uint256 owner = ERC1155721Storage.getState()._owners[id];
        require(from == address(uint160(owner)), "Inventory: non-owned NFT");
        if (!operatable) {
            require((owner & _APPROVAL_BIT_TOKEN_OWNER_ != 0) && msg.sender == ERC1155721Storage.getState()._nftApprovals[id], "Inventory: non-approved sender");
        }
        ERC1155721Storage.getState()._owners[id] = _BURNT_NFT_OWNER;

        if (!isBatch) {
            _burnNFTUpdateCollection(from, id.getNonFungibleCollection(), 1);

            // cannot underflow as balance is verified through NFT ownership
            --ERC1155721Storage.getState()._nftBalances[from];
        }
    }

    function _burnNFTUpdateCollection(
        address from,
        uint256 collectionId,
        uint256 amount
    ) internal virtual {
        // cannot underflow as balance is verified through NFT ownership
        ERC1155721Storage.getState()._balances[collectionId][from] -= amount;
        ERC1155721Storage.getState()._supplies[collectionId] -= amount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library ERC1155721Storage {
	struct State {
    	string baseMetadataURI;

		/* owner => operator => approved */
		mapping(address => mapping(address => bool)) _operators;

		/* collection ID => owner => balance */
		mapping(uint256 => mapping(address => uint256)) _balances;

		/* collection ID => supply */
		mapping(uint256 => uint256) _supplies;

		/* NFT ID => owner */
		mapping(uint256 => uint256) _owners;

		/* collection ID => creator */
		mapping(uint256 => address) _creators;

    	/* owner => NFT balance */
		mapping(address => uint256) _nftBalances;

		/* NFT ID => operator */
		mapping(uint256 => address) _nftApprovals;

		/* Supply of all tokens in existence (fungible and otherwise) */
		uint256 _totalSupply;
	}

	bytes32 internal constant FACET_STORAGE_POSITION = keccak256("diamond.dapp.facet.erc1155721storage");

	function getState() internal pure returns (State storage s) {
		bytes32 position = FACET_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC1155, IERC1155MetadataURI, IERC1155Inventory, IERC1155TokenReceiver} from "./interfaces/Interfaces.sol";
import {IConflictedEvents} from "../IConflictedEvents.sol";
import {ERC1155InventoryIdentifiersLib} from "./ERC1155InventoryIdentifiersLib.sol";
import {ERC1155721Storage} from "./ERC1155721Storage.sol";

abstract contract ERC1155InventoryBase is IERC1155, IERC1155MetadataURI, IERC1155Inventory {
    using ERC1155InventoryIdentifiersLib for uint256;

    bytes4 private constant _ERC165_INTERFACE_ID = 0x01ffc9a7;
    bytes4 private constant _ERC1155_INTERFACE_ID = 0xd9b67a26;
    bytes4 private constant _ERC1155_METADATA_URI_INTERFACE_ID = 0x0e89341c;
    bytes4 private constant _ERC1155_INVENTORY_INTERFACE_ID = 0x469bd23f;

    // bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
    bytes4 internal constant _ERC1155_RECEIVED = 0xf23a6e61;

    // bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))
    bytes4 internal constant _ERC1155_BATCH_RECEIVED = 0xbc197c81;

    // Burnt non-fungible token owner's magic value
    uint256 internal constant _BURNT_NFT_OWNER = 0x000000000000000000000000000000000000000000000000000000000000dead;

    /// @dev See {IERC165-supportsInterface}.
    // function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    //     return
    //         interfaceId == _ERC165_INTERFACE_ID ||
    //         interfaceId == _ERC1155_INTERFACE_ID ||
    //         interfaceId == _ERC1155_METADATA_URI_INTERFACE_ID ||
    //         interfaceId == _ERC1155_INVENTORY_INTERFACE_ID;
    // }

    //================================== ERC1155 =======================================/

    /// @dev See {IERC1155-balanceOf(address,uint256)}.
    function balanceOf(address owner, uint256 id) public view virtual override returns (uint256) {
        require(owner != address(0), "Inventory: zero address");

        if (id.isNonFungibleToken()) {
            return address(uint160(ERC1155721Storage.getState()._owners[id])) == owner ? 1 : 0;
        }

        return ERC1155721Storage.getState()._balances[id][owner];
    }

    /// @dev See {IERC1155-balanceOfBatch(address[],uint256[])}.
    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids) external view virtual override returns (uint256[] memory) {
        require(owners.length == ids.length, "Inventory: inconsistent arrays");

        uint256[] memory balances = new uint256[](owners.length);

        for (uint256 i = 0; i != owners.length; ++i) {
            balances[i] = balanceOf(owners[i], ids[i]);
        }

        return balances;
    }

    /// @dev See {IERC1155-setApprovalForAll(address,bool)}.
    function setApprovalForAll(address operator, bool approved) public virtual override {
        address sender = msg.sender;
        require(operator != sender, "Inventory: self-approval");
        ERC1155721Storage.getState()._operators[sender][operator] = approved;
        emit ApprovalForAll(sender, operator, approved);
    }

    /// @dev See {IERC1155-isApprovedForAll(address,address)}.
    function isApprovedForAll(address tokenOwner, address operator) public view virtual override returns (bool) {
        return ERC1155721Storage.getState()._operators[tokenOwner][operator];
    }

    //================================== ERC1155Inventory =======================================/

    /// @dev See {IERC1155Inventory-isFungible(uint256)}.
    function isFungible(uint256 id) external pure virtual override returns (bool) {
        return id.isFungibleToken();
    }

    /// @dev See {IERC1155Inventory-collectionOf(uint256)}.
    function collectionOf(uint256 nftId) external pure virtual override returns (uint256) {
        require(nftId.isNonFungibleToken(), "Inventory: not an NFT");
        return nftId.getNonFungibleCollection();
    }

    /// @dev See {IERC1155Inventory-ownerOf(uint256)}.
    function ownerOf(uint256 nftId) public view virtual override returns (address) {
        address owner = address(uint160(ERC1155721Storage.getState()._owners[nftId]));
        require(owner != address(0), "Inventory: non-existing NFT");
        return owner;
    }

    /// @dev See {IERC1155Inventory-totalSupply(uint256)}.
    function totalSupply(uint256 id) external view virtual override returns (uint256) {
        if (id.isNonFungibleToken()) {
            return address(uint160(ERC1155721Storage.getState()._owners[id])) == address(0) ? 0 : 1;
        } else {
            return ERC1155721Storage.getState()._supplies[id];
        }
    }

    //================================== ABI-level Internal Functions =======================================/

    /**
     * Creates a collection (optional).
     * @dev Reverts if `collectionId` does not represent a collection.
     * @dev Reverts if `collectionId` has already been created.
     * @dev Emits a {IERC1155Inventory-CollectionCreated} event.
     * @param collectionId Identifier of the collection.
     */
    function _createCollection(uint256 collectionId) internal virtual {
        require(!collectionId.isNonFungibleToken(), "Inventory: not a collection");
        require(ERC1155721Storage.getState()._creators[collectionId] == address(0), "Inventory: existing collection");
        ERC1155721Storage.getState()._creators[collectionId] = msg.sender;
        emit CollectionCreated(collectionId, collectionId.isFungibleToken());
    }

    /// @dev See {IERC1155InventoryCreator-creator(uint256)}.
    function _creator(uint256 collectionId) internal view virtual returns (address) {
        require(!collectionId.isNonFungibleToken(), "Inventory: not a collection");
        return ERC1155721Storage.getState()._creators[collectionId];
    }

    //================================== Internal Helper Functions =======================================/

    /**
     * Returns whether `sender` is authorised to make a transfer on behalf of `from`.
     * @param from The address to check operatibility upon.
     * @param sender The sender address.
     * @return True if sender is `from` or an operator for `from`, false otherwise.
     */
    function _isOperatable(address from, address sender) internal view virtual returns (bool) {
        return (from == sender) || ERC1155721Storage.getState()._operators[from][sender];
    }

    /**
     * Calls {IERC1155TokenReceiver-onERC1155Received} on a target contract.
     * @dev Reverts if `to` is not a contract.
     * @dev Reverts if the call to the target fails or is refused.
     * @param from Previous token owner.
     * @param to New token owner.
     * @param id Identifier of the token transferred.
     * @param value Amount of token transferred.
     * @param data Optional data to send along with the receiver contract call.
     */
    function _callOnERC1155Received(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes memory data
    ) internal {
        require(IERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, value, data) == _ERC1155_RECEIVED, "Inventory: transfer refused");
    }

    /**
     * Calls {IERC1155TokenReceiver-onERC1155batchReceived} on a target contract.
     * @dev Reverts if `to` is not a contract.
     * @dev Reverts if the call to the target fails or is refused.
     * @param from Previous tokens owner.
     * @param to New tokens owner.
     * @param ids Identifiers of the tokens to transfer.
     * @param values Amounts of tokens to transfer.
     * @param data Optional data to send along with the receiver contract call.
     */
    function _callOnERC1155BatchReceived(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) internal {
        require(
            IERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, values, data) == _ERC1155_BATCH_RECEIVED,
            "Inventory: transfer refused"
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ERC1155InventoryIdentifiersLib, a library to introspect inventory identifiers.
 * @dev With N=32, representing the Non-Fungible Collection mask length, identifiers are represented as follow:
 * (a) a Fungible Token:
 *     - most significant bit == 0
 * (b) a Non-Fungible Collection:
 *     - most significant bit == 1
 *     - (256-N) least significant bits == 0
 * (c) a Non-Fungible Token:
 *     - most significant bit == 1
 *     - (256-N) least significant bits != 0
 */
library ERC1155InventoryIdentifiersLib {
    // Non-fungible bit. If an id has this bit set, it is a non-fungible (either collection or token)
    uint256 internal constant _NF_BIT = 1 << 255;

    // Mask for non-fungible collection (including the nf bit)
    uint256 internal constant _NF_COLLECTION_MASK = uint256(type(uint32).max) << 224;
    uint256 internal constant _NF_TOKEN_MASK = ~_NF_COLLECTION_MASK;

    function isFungibleToken(uint256 id) internal pure returns (bool) {
        return id & _NF_BIT == 0;
    }

    function isNonFungibleToken(uint256 id) internal pure returns (bool) {
        return id & _NF_BIT != 0 && id & _NF_TOKEN_MASK != 0;
    }

    function getNonFungibleCollection(uint256 nftId) internal pure returns (uint256) {
        return nftId & _NF_COLLECTION_MASK;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC1155721InventoryBurnable {
    /**
     * Burns some token (ERC1155-compatible).
     * @dev Reverts if the sender is not approved.
     * @dev Reverts if `id` does not represent a token.
     * @dev Reverts if `id` represents a fungible token and `value` is 0.
     * @dev Reverts if `id` represents a fungible token and `value` is higher than `from`'s balance.
     * @dev Reverts if `id` represents a non-fungible token and `value` is not 1.
     * @dev Reverts if `id` represents a non-fungible token which is not owned by `from`.
     * @dev Emits an {IERC721-Transfer} event to the zero address if `id` represents a non-fungible token.
     * @dev Emits an {IERC1155-TransferSingle} event to the zero address.
     * @param from Address of the current token owner.
     * @param id Identifier of the token to burn.
     * @param value Amount of token to burn.
     */
    function burnFrom(
        address from,
        uint256 id,
        uint256 value
    ) external;

    /**
     * Burns multiple tokens (ERC1155-compatible).
     * @dev Reverts if `ids` and `values` have different lengths.
     * @dev Reverts if the sender is not approved.
     * @dev Reverts if one of `ids` does not represent a token.
     * @dev Reverts if one of `ids` represents a fungible token and `value` is 0.
     * @dev Reverts if one of `ids` represents a fungible token and `value` is higher than `from`'s balance.
     * @dev Reverts if one of `ids` represents a non-fungible token and `value` is not 1.
     * @dev Reverts if one of `ids` represents a non-fungible token which is not owned by `from`.
     * @dev Emits an {IERC721-Transfer} event to the zero address for each burnt non-fungible token.
     * @dev Emits an {IERC1155-TransferBatch} event to the zero address.
     * @param from Address of the current tokens owner.
     * @param ids Identifiers of the tokens to burn.
     * @param values Amounts of tokens to burn.
     */
    function batchBurnFrom(
        address from,
        uint256[] calldata ids,
        uint256[] calldata values
    ) external;

    /**
     * Burns a batch of Non-Fungible Tokens (ERC721-compatible).
     * @dev Reverts if the sender is not approved.
     * @dev Reverts if one of `nftIds` does not represent a non-fungible token.
     * @dev Reverts if one of `nftIds` is not owned by `from`.
     * @dev Emits an {IERC721-Transfer} event to the zero address for each of `nftIds`.
     * @dev Emits an {IERC1155-TransferBatch} event to the zero address.
     * @param from Current token owner.
     * @param nftIds Identifiers of the tokens to transfer.
     */
    function batchBurnFrom(address from, uint256[] calldata nftIds) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC1155721InventoryBurnable} from "./ERC1155721InventoryBurnable.sol";
import {IERC1155721InventoryMintable, IERC1155InventoryCreator} from "./interfaces/Interfaces.sol";
import {BaseMetadataURI} from "./BaseMetadataURI.sol";
import {AppModifiers} from "../../../../AppModifiers.sol";
import {ERC1155721Storage} from "./ERC1155721Storage.sol";

contract InventoryImpl is
    ERC1155721InventoryBurnable,
    IERC1155721InventoryMintable,
    IERC1155InventoryCreator,
    BaseMetadataURI,
    AppModifiers
{
    // solhint-disable-next-line const-name-snakecase
    string public constant override name = "PEWTER";
    // solhint-disable-next-line const-name-snakecase
    string public constant override symbol = "PIE";

    //================================== ERC1155MetadataURI =======================================/

    /// @dev See {IERC1155MetadataURI-uri(uint256)}.
    function uri(uint256 id) public view virtual override returns (string memory) {
        return _uri(id);
    }

    function totalSupply() external view returns (uint256) {
        return ERC1155721Storage.getState()._totalSupply;
    }

    //================================== ERC1155InventoryCreator =======================================/

    /// @dev See {IERC1155InventoryCreator-creator(uint256)}.
    function creator(uint256 collectionId) external view override returns (address) {
        return _creator(collectionId);
    }

    //================================== ERC1155Inventory =======================================/

    /**
     * Creates a collection.
     * @dev Reverts if `collectionId` does not represent a collection.
     * @dev Reverts if `collectionId` has already been created.
     * @dev Emits a {IERC1155Inventory-CollectionCreated} event.
     * @param collectionId Identifier of the collection.
     */
    function createCollection(uint256 collectionId) external {
        _createCollection(collectionId);
    }

    //================================== ERC1155721InventoryMintable =======================================/

    /**
     * Unsafely mints a Non-Fungible Token (ERC721-compatible).
     * @dev See {IERC1155721InventoryMintable-batchMint(address,uint256)}.
     */
    function mint(address to, uint256 nftId) public virtual override {
        // require(isMinter(msg.sender), "Inventory: not a minter");
        _mint(to, nftId, "", false);
        ERC1155721Storage.getState()._totalSupply += 1;
    }

    /**
     * Unsafely mints a batch of Non-Fungible Tokens (ERC721-compatible).
     * @dev See {IERC1155721InventoryMintable-batchMint(address,uint256[])}.
     */
    function batchMint(address to, uint256[] memory nftIds) public virtual override {
        // require(isMinter(msg.sender), "Inventory: not a minter");
        _batchMint(to, nftIds);
        ERC1155721Storage.getState()._totalSupply += nftIds.length;
    }

    /**
     * Safely mints a Non-Fungible Token (ERC721-compatible).
     * @dev See {IERC1155721InventoryMintable-safeMint(address,uint256,bytes)}.
     */
    function safeMint(
        address to,
        uint256 nftId,
        bytes memory data
    ) public virtual override {
        // require(isMinter(msg.sender), "Inventory: not a minter");
        _mint(to, nftId, data, true);
        ERC1155721Storage.getState()._totalSupply += 1;
    }

    /**
     * Safely mints some token (ERC1155-compatible).
     * @dev See {IERC1155721InventoryMintable-safeMint(address,uint256,uint256,bytes)}.
     */
    function safeMint(
        address to,
        uint256 id,
        uint256 value,
        bytes memory data
    ) public virtual override {
        // require(isMinter(msg.sender), "Inventory: not a minter");
        _safeMint(to, id, value, data);
        ERC1155721Storage.getState()._totalSupply += value;
    }

    /**
     * Safely mints a batch of tokens (ERC1155-compatible).
     * @dev See {IERC1155721InventoryMintable-safeBatchMint(address,uint256[],uint256[],bytes)}.
     */
    function safeBatchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) public virtual override {
        // require(isMinter(msg.sender), "Inventory: not a minter");
        _safeBatchMint(to, ids, values, data);
        // totalSupply handled in _safeBatchMint
    }

    //================================== ERC721 =======================================/

    function transferFrom(
        address from,
        address to,
        uint256 nftId
    ) public virtual override {
        require(!_paused(), "Inventory: _paused");
        super.transferFrom(from, to, nftId);
    }

    function batchTransferFrom(
        address from,
        address to,
        uint256[] memory nftIds
    ) public virtual override {
        require(!_paused(), "Inventory: _paused");
        super.batchTransferFrom(from, to, nftIds);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 nftId
    ) public virtual override {
        require(!_paused(), "Inventory: _paused");
        super.safeTransferFrom(from, to, nftId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 nftId,
        bytes memory data
    ) public virtual override {
        require(!_paused(), "Inventory: _paused");
        super.safeTransferFrom(from, to, nftId, data);
    }

    function batchBurnFrom(address from, uint256[] memory nftIds) public virtual override {
        require(!_paused(), "Inventory: _paused");
        super.batchBurnFrom(from, nftIds);
        ERC1155721Storage.getState()._totalSupply -= nftIds.length;
    }

    //================================== ERC1155 =======================================/

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes memory data
    ) public virtual override {
        require(!_paused(), "Inventory: _paused");
        super.safeTransferFrom(from, to, id, value, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) public virtual override {
        require(!_paused(), "Inventory: _paused");
        super.safeBatchTransferFrom(from, to, ids, values, data);
    }

    function burnFrom(
        address from,
        uint256 id,
        uint256 value
    ) public virtual override {
        require(!_paused(), "Inventory: _paused");
        super.burnFrom(from, id, value);
        ERC1155721Storage.getState()._totalSupply -= value;
    }

    function batchBurnFrom(
        address from,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual override {
        require(!_paused(), "Inventory: _paused");
        super.batchBurnFrom(from, ids, values);
        // totalSupply handled in backBurnFrom
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IConflictedEvents} from "../../IConflictedEvents.sol";

interface IERC721 is IConflictedEvents {
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
    // event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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


// File @animoca/ethereum-contracts-assets_inventory/contracts/token/ERC721/[email protected]



/**
 * @title ERC721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 * Note: The ERC-165 identifier for this interface is 0x5b5e139f.
 */
interface IERC721Metadata {
    /**
     * @dev Gets the token name
     * @return string representing the token name
     */
    function name() external view returns (string memory);

    /**
     * @dev Gets the token symbol
     * @return string representing the token symbol
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns an URI for a given token ID
     * Throws if the token ID does not exist. May return an empty string.
     * @param tokenId uint256 ID of the token to query
     * @return string URI of given token ID
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}


// File @animoca/ethereum-contracts-assets_inventory/contracts/token/ERC721/[email protected]



/**
 * @title ERC721 Non-Fungible Token Standard, optional unsafe batchTransfer interface
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 * Note: The ERC-165 identifier for this interface is.
 */
interface IERC721BatchTransfer {
    /**
     * Unsafely transfers a batch of tokens.
     * @dev Usage of this method is discouraged, use `safeTransferFrom` whenever possible
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if the sender is not approved.
     * @dev Reverts if one of `tokenIds` is not owned by `from`.
     * @dev Resets the token approval for each of `tokenIds`.
     * @dev Emits an {IERC721-Transfer} event for each of `tokenIds`.
     * @param from Current tokens owner.
     * @param to Address of the new token owner.
     * @param tokenIds Identifiers of the tokens to transfer.
     */
    function batchTransferFrom(
        address from,
        address to,
        uint256[] calldata tokenIds
    ) external;
}


// File @animoca/ethereum-contracts-assets_inventory/contracts/token/ERC721/[email protected]



/**
    @title ERC721 Non-Fungible Token Standard, token receiver
    @dev See https://eips.ethereum.org/EIPS/eip-721
    Interface for any contract that wants to support safeTransfers from ERC721 asset contracts.
    Note: The ERC-165 identifier for this interface is 0x150b7a02.
 */
interface IERC721Receiver {
    /**
        @notice Handle the receipt of an NFT
        @dev The ERC721 smart contract calls this function on the recipient
        after a {IERC721-safeTransferFrom}. This function MUST return the function selector,
        otherwise the caller will revert the transaction. The selector to be
        returned can be obtained as `this.onERC721Received.selector`. This
        function MAY throw to revert and reject the transfer.
        Note: the ERC721 contract address is always the message sender.
        @param operator The address which called `safeTransferFrom` function
        @param from The address which previously owned the token
        @param tokenId The NFT identifier which is being transferred
        @param data Additional data with no specified format
        @return bytes4 `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC1155 is IConflictedEvents {
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);

    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);

    // event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    event URI(string _value, uint256 indexed _id);

    /**
     * Safely transfers some token.
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if the sender is not approved.
     * @dev Reverts if `from` has an insufficient balance.
     * @dev Reverts if `to` is a contract and the call to {IERC1155TokenReceiver-onERC1155received} fails or is refused.
     * @dev Emits a `TransferSingle` event.
     * @param from Current token owner.
     * @param to Address of the new token owner.
     * @param id Identifier of the token to transfer.
     * @param value Amount of token to transfer.
     * @param data Optional data to send along to a receiver contract.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external;

    /**
     * Safely transfers a batch of tokens.
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if `ids` and `values` have different lengths.
     * @dev Reverts if the sender is not approved.
     * @dev Reverts if `from` has an insufficient balance for any of `ids`.
     * @dev Reverts if `to` is a contract and the call to {IERC1155TokenReceiver-onERC1155batchReceived} fails or is refused.
     * @dev Emits a `TransferBatch` event.
     * @param from Current token owner.
     * @param to Address of the new token owner.
     * @param ids Identifiers of the tokens to transfer.
     * @param values Amounts of tokens to transfer.
     * @param data Optional data to send along to a receiver contract.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external;

    /**
     * Retrieves the balance of `id` owned by account `owner`.
     * @param owner The account to retrieve the balance of.
     * @param id The identifier to retrieve the balance of.
     * @return The balance of `id` owned by account `owner`.
     */
    function balanceOf(address owner, uint256 id) external view returns (uint256);

    /**
     * Retrieves the balances of `ids` owned by accounts `owners`. For each pair:
     * @dev Reverts if `owners` and `ids` have different lengths.
     * @param owners The addresses of the token holders
     * @param ids The identifiers to retrieve the balance of.
     * @return The balances of `ids` owned by accounts `owners`.
     */
    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * Enables or disables an operator's approval.
     * @dev Emits an `ApprovalForAll` event.
     * @param operator Address of the operator.
     * @param approved True to approve the operator, false to revoke an approval.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * Retrieves the approval status of an operator for a given owner.
     * @param owner Address of the authorisation giver.
     * @param operator Address of the operator.
     * @return True if the operator is approved, false if not.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}


// File @animoca/ethereum-contracts-assets_inventory/contracts/token/ERC1155/[email protected]



/**
 * @title ERC-1155 Multi Token Standard, optional metadata URI extension
 * @dev See https://eips.ethereum.org/EIPS/eip-1155
 * Note: The ERC-165 identifier for this interface is 0x0e89341c.
 */
interface IERC1155MetadataURI {
    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a given token.
     * @dev URIs are defined in RFC 3986.
     * @dev The URI MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
     * @dev The uri function SHOULD be used to retrieve values if no event was emitted.
     * @dev The uri function MUST return the same value as the latest event for an _id if it was emitted.
     * @dev The uri function MUST NOT be used to check for the existence of a token as it is possible for
     *  an implementation to return a valid string even if the token does not exist.
     * @return URI string
     */
    function uri(uint256 id) external view returns (string memory);
}


// File @animoca/ethereum-contracts-assets_inventory/contracts/token/ERC1155/[email protected]



/**
 * @title ERC-1155 Multi Token Standard, optional Inventory extension
 * @dev See https://eips.ethereum.org/EIPS/eip-xxxx
 * Interface for fungible/non-fungible tokens management on a 1155-compliant contract.
 *
 * This interface rationalizes the co-existence of fungible and non-fungible tokens
 * within the same contract. As several kinds of fungible tokens can be managed under
 * the Multi-Token standard, we consider that non-fungible tokens can be classified
 * under their own specific type. We introduce the concept of non-fungible collection
 * and consider the usage of 3 types of identifiers:
 * (a) Fungible Token identifiers, each representing a set of Fungible Tokens,
 * (b) Non-Fungible Collection identifiers, each representing a set of Non-Fungible Tokens (this is not a token),
 * (c) Non-Fungible Token identifiers. 

 * Identifiers nature
 * |       Type                | isFungible  | isCollection | isToken |
 * |  Fungible Token           |   true      |     true     |  true   |
 * |  Non-Fungible Collection  |   false     |     true     |  false  |
 * |  Non-Fungible Token       |   false     |     false    |  true   |
 *
 * Identifiers compatibilities
 * |       Type                |  transfer  |   balance    |   supply    |  owner  |
 * |  Fungible Token           |    OK      |     OK       |     OK      |   NOK   |
 * |  Non-Fungible Collection  |    NOK     |     OK       |     OK      |   NOK   |
 * |  Non-Fungible Token       |    OK      |   0 or 1     |   0 or 1    |   OK    |
 *
 * Note: The ERC-165 identifier for this interface is 0x469bd23f.
 */
interface IERC1155Inventory {
    /**
     * Optional event emitted when a collection (Fungible Token or Non-Fungible Collection) is created.
     *  This event can be used by a client application to determine which identifiers are meaningful
     *  to track through the functions `balanceOf`, `balanceOfBatch` and `totalSupply`.
     * @dev This event MUST NOT be emitted twice for the same `collectionId`.
     */
    event CollectionCreated(uint256 indexed collectionId, bool indexed fungible);

    /**
     * Retrieves the owner of a non-fungible token (ERC721-compatible).
     * @dev Reverts if `nftId` is owned by the zero address.
     * @param nftId Identifier of the token to query.
     * @return Address of the current owner of the token.
     */
    function ownerOf(uint256 nftId) external view returns (address);

    /**
     * Introspects whether or not `id` represents a fungible token.
     *  This function MUST return true even for a fungible token which is not-yet created.
     * @param id The identifier to query.
     * @return bool True if `id` represents afungible token, false otherwise.
     */
    function isFungible(uint256 id) external pure returns (bool);

    /**
     * Introspects the non-fungible collection to which `nftId` belongs.
     * @dev This function MUST return a value representing a non-fungible collection.
     * @dev This function MUST return a value for a non-existing token, and SHOULD NOT be used to check the existence of a non-fungible token.
     * @dev Reverts if `nftId` does not represent a non-fungible token.
     * @param nftId The token identifier to query the collection of.
     * @return The non-fungible collection identifier to which `nftId` belongs.
     */
    function collectionOf(uint256 nftId) external pure returns (uint256);

    /**
     * Retrieves the total supply of `id`.
     * @param id The identifier for which to retrieve the supply of.
     * @return
     *  If `id` represents a collection (fungible token or non-fungible collection), the total supply for this collection.
     *  If `id` represents a non-fungible token, 1 if the token exists, else 0.
     */
    function totalSupply(uint256 id) external view returns (uint256);

    /**
     * @notice this documentation overrides {IERC1155-balanceOf(address,uint256)}.
     * Retrieves the balance of `id` owned by account `owner`.
     * @param owner The account to retrieve the balance of.
     * @param id The identifier to retrieve the balance of.
     * @return
     *  If `id` represents a collection (fungible token or non-fungible collection), the balance for this collection.
     *  If `id` represents a non-fungible token, 1 if the token is owned by `owner`, else 0.
     */
    // function balanceOf(address owner, uint256 id) external view returns (uint256);

    /**
     * @notice this documentation overrides {IERC1155-balanceOfBatch(address[],uint256[])}.
     * Retrieves the balances of `ids` owned by accounts `owners`.
     * @dev Reverts if `owners` and `ids` have different lengths.
     * @param owners The accounts to retrieve the balances of.
     * @param ids The identifiers to retrieve the balances of.
     * @return An array of elements such as for each pair `id`/`owner`:
     *  If `id` represents a collection (fungible token or non-fungible collection), the balance for this collection.
     *  If `id` represents a non-fungible token, 1 if the token is owned by `owner`, else 0.
     */
    // function balanceOfBatch(address[] calldata owners, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @notice this documentation overrides its {IERC1155-safeTransferFrom(address,address,uint256,uint256,bytes)}.
     * Safely transfers some token.
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if the sender is not approved.
     * @dev Reverts if `id` does not represent a token.
     * @dev Reverts if `id` represents a non-fungible token and `value` is not 1.
     * @dev Reverts if `id` represents a non-fungible token and is not owned by `from`.
     * @dev Reverts if `id` represents a fungible token and `value` is 0.
     * @dev Reverts if `id` represents a fungible token and `from` has an insufficient balance.
     * @dev Reverts if `to` is a contract and the call to {IERC1155TokenReceiver-onERC1155received} fails or is refused.
     * @dev Emits an {IERC1155-TransferSingle} event.
     * @param from Current token owner.
     * @param to Address of the new token owner.
     * @param id Identifier of the token to transfer.
     * @param value Amount of token to transfer.
     * @param data Optional data to pass to the receiver contract.
     */
    // function safeTransferFrom(
    //     address from,
    //     address to,
    //     uint256 id,
    //     uint256 value,
    //     bytes calldata data
    // ) external;

    /**
     * @notice this documentation overrides its {IERC1155-safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)}.
     * Safely transfers a batch of tokens.
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if the sender is not approved.
     * @dev Reverts if one of `ids` does not represent a token.
     * @dev Reverts if one of `ids` represents a non-fungible token and `value` is not 1.
     * @dev Reverts if one of `ids` represents a non-fungible token and is not owned by `from`.
     * @dev Reverts if one of `ids` represents a fungible token and `value` is 0.
     * @dev Reverts if one of `ids` represents a fungible token and `from` has an insufficient balance.
     * @dev Reverts if one of `to` is a contract and the call to {IERC1155TokenReceiver-onERC1155batchReceived} fails or is refused.
     * @dev Emits an {IERC1155-TransferBatch} event.
     * @param from Current tokens owner.
     * @param to Address of the new tokens owner.
     * @param ids Identifiers of the tokens to transfer.
     * @param values Amounts of tokens to transfer.
     * @param data Optional data to pass to the receiver contract.
     */
    // function safeBatchTransferFrom(
    //     address from,
    //     address to,
    //     uint256[] calldata ids,
    //     uint256[] calldata values,
    //     bytes calldata data
    // ) external;
}


// File @animoca/ethereum-contracts-assets_inventory/contracts/token/ERC1155/[email protected]



/**
 * @title ERC-1155 Multi Token Standard, token receiver
 * @dev See https://eips.ethereum.org/EIPS/eip-1155
 * Interface for any contract that wants to support transfers from ERC1155 asset contracts.
 * Note: The ERC-165 identifier for this interface is 0x4e2312e0.
 */
interface IERC1155TokenReceiver {
    /**
     * @notice Handle the receipt of a single ERC1155 token type.
     * An ERC1155 contract MUST call this function on a recipient contract, at the end of a `safeTransferFrom` after the balance update.
     * This function MUST return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     *  (i.e. 0xf23a6e61) to accept the transfer.
     * Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
     * @param operator  The address which initiated the transfer (i.e. msg.sender)
     * @param from      The address which previously owned the token
     * @param id        The ID of the token being transferred
     * @param value     The amount of tokens being transferred
     * @param data      Additional data with no specified format
     * @return bytes4   `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @notice Handle the receipt of multiple ERC1155 token types.
     * An ERC1155 contract MUST call this function on a recipient contract, at the end of a `safeBatchTransferFrom` after the balance updates.
     * This function MUST return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     *  (i.e. 0xbc197c81) if to accept the transfer(s).
     * Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
     * @param operator  The address which initiated the batch transfer (i.e. msg.sender)
     * @param from      The address which previously owned the token
     * @param ids       An array containing ids of each token being transferred (order and length must match _values array)
     * @param values    An array containing amounts of each token being transferred (order and length must match _ids array)
     * @param data      Additional data with no specified format
     * @return          `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC1155721InventoryMintable {
    /**
     * Safely mints some token (ERC1155-compatible).
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if `id` is not a token.
     * @dev Reverts if `id` represents a non-fungible token and `value` is not 1.
     * @dev Reverts if `id` represents a non-fungible token which has already been minted.
     * @dev Reverts if `id` represents a fungible token and `value` is 0.
     * @dev Reverts if `id` represents a fungible token and there is an overflow of supply.
     * @dev Reverts if `to` is a contract and the call to {IERC1155TokenReceiver-onERC1155Received} fails or is refused.
     * @dev Emits an {IERC721-Transfer} event from the zero address if `id` represents a non-fungible token.
     * @dev Emits an {IERC1155-TransferSingle} event from the zero address.
     * @param to Address of the new token owner.
     * @param id Identifier of the token to mint.
     * @param value Amount of token to mint.
     * @param data Optional data to send along to a receiver contract.
     */
    function safeMint(
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external;

    /**
     * Safely mints a batch of tokens (ERC1155-compatible).
     * @dev Reverts if `ids` and `values` have different lengths.
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if one of `ids` is not a token.
     * @dev Reverts if one of `ids` represents a non-fungible token and its paired value is not 1.
     * @dev Reverts if one of `ids` represents a non-fungible token which has already been minted.
     * @dev Reverts if one of `ids` represents a fungible token and its paired value is 0.
     * @dev Reverts if one of `ids` represents a fungible token and there is an overflow of supply.
     * @dev Reverts if `to` is a contract and the call to {IERC1155TokenReceiver-onERC1155batchReceived} fails or is refused.
     * @dev Emits an {IERC721-Transfer} event from the zero address for each non-fungible token minted.
     * @dev Emits an {IERC1155-TransferBatch} event from the zero address.
     * @param to Address of the new tokens owner.
     * @param ids Identifiers of the tokens to mint.
     * @param values Amounts of tokens to mint.
     * @param data Optional data to send along to a receiver contract.
     */
    function safeBatchMint(
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external;

    /**
     * Unsafely mints a Non-Fungible Token (ERC721-compatible).
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if `nftId` does not represent a non-fungible token.
     * @dev Reverts if `nftId` has already been minted.
     * @dev Emits an {IERC721-Transfer} event from the zero address.
     * @dev Emits an {IERC1155-TransferSingle} event from the zero address.
     * @dev If `to` is a contract and supports ERC1155TokenReceiver, calls {IERC1155TokenReceiver-onERC1155Received} with empty data.
     * @param to Address of the new token owner.
     * @param nftId Identifier of the token to mint.
     */
    function mint(address to, uint256 nftId) external;

    /**
     * Unsafely mints a batch of Non-Fungible Tokens (ERC721-compatible).
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if one of `nftIds` does not represent a non-fungible token.
     * @dev Reverts if one of `nftIds` has already been minted.
     * @dev Emits an {IERC721-Transfer} event from the zero address for each of `nftIds`.
     * @dev Emits an {IERC1155-TransferBatch} event from the zero address.
     * @dev If `to` is a contract and supports ERC1155TokenReceiver, calls {IERC1155TokenReceiver-onERC1155BatchReceived} with empty data.
     * @param to Address of the new token owner.
     * @param nftIds Identifiers of the tokens to mint.
     */
    function batchMint(address to, uint256[] calldata nftIds) external;

    /**
     * Safely mints a token (ERC721-compatible).
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if `tokenId` has already ben minted.
     * @dev Reverts if `to` is a contract which does not implement IERC721Receiver or IERC1155TokenReceiver.
     * @dev Reverts if `to` is an IERC1155TokenReceiver or IERC721TokenReceiver contract which refuses the transfer.
     * @dev Emits an {IERC721-Transfer} event from the zero address.
     * @dev Emits an {IERC1155-TransferSingle} event from the zero address.
     * @param to Address of the new token owner.
     * @param nftId Identifier of the token to mint.
     * @param data Optional data to pass along to the receiver call.
     */
    function safeMint(
        address to,
        uint256 nftId,
        bytes calldata data
    ) external;
}

interface IERC1155InventoryCreator {
    /**
     * Returns the creator of a collection, or the zero address if the collection has not been created.
     * @dev Reverts if `collectionId` does not represent a collection.
     * @param collectionId Identifier of the collection.
     * @return The creator of a collection, or the zero address if the collection has not been created.
     */
    function creator(uint256 collectionId) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "./libraries/LibDiamond.sol";
import {AccessControlStorage} from "../transpiled-oz/access/AccessControlStorage.sol";
import {PausableStorage} from "../transpiled-oz/security/PausableStorage.sol";
import {LibUtilities} from "./libraries/LibUtilities.sol";

// abstract contract to include shared utility modifiers for ease of use
// also includes modifiers imported from PausableUpgradeable
abstract contract Modifiers {

    // Safe to have constants, since constants are stored in bytecode, not storage
    // This will have no affect on using the AppStorage pattern in the future
    //  if desired (storing a struct at storage slot 0)
    bytes32 internal constant ADMIN_ROLE = keccak256("ADMIN");
    bytes32 internal constant UPGRADER_ROLE = keccak256("UPGRADER");
    bytes32 internal constant ROLE_GRANTER_ROLE = keccak256("ROLE_GRANTER");

    // =============================================================
    //                         Modifiers
    // =============================================================

    modifier requireRole(bytes32 _role) {
        if (!_hasRole(_role, msg.sender)) {
            revert LibUtilities.MissingRole(msg.sender, _role);
        }
        _;
    }

    modifier requireEitherRole(bytes32 _roleOption1, bytes32 _roleOption2) {
        if (!_hasRole(_roleOption1, msg.sender) && !_hasRole(_roleOption2, msg.sender)) {
            revert LibUtilities.MissingEitherRole(msg.sender, _roleOption1, _roleOption2);
        }
        _;
    }

    // Hook into diamond storage for ownership info because ownership
    //  is automatically handled by hardhat-deploy plugin
    modifier requireOwnerOrRole(bytes32 _role) {
        if (!_hasRole(_role, msg.sender) && LibDiamond.contractOwner() != msg.sender) {
            revert LibUtilities.MissingRoleAndNotOwner(msg.sender, _role);
        }
        _;
    }

    modifier whenNotPaused() {
        if(_paused()) revert LibUtilities.IsPaused();
        _;
    }

    modifier whenPaused() {
        if(!_paused()) revert LibUtilities.NotPaused();
        _;
    }

    // =============================================================
    //                      Utility functions
    // =============================================================

    // Taken from AccessControlUpgradeable, and renamed to avoid conflicts with any contract importing AccessControlUpgradeable
    // Purposefully not importing the entire contract to avoid bloating this base contract.
    // If this changes in AccessControlUpgradeable, it would be a breaking change and contracts using this wouldn't be able to update anyway.
    function _hasRole(bytes32 _role, address _account) internal view returns (bool) {
        return AccessControlStorage.layout()._roles[_role].members[_account];
    }

    // Needs to be internal so that only a single facet exposes it externally to avoid failing a diamond upgrade due to
    //  multiple functions across multiple facets
    function _paused() internal view returns (bool) {
        return PausableStorage.layout()._paused;
    }

    function _pause() internal whenNotPaused {
        PausableStorage.layout()._paused = true;
        emit LibUtilities.Paused(msg.sender);
    }

    function _unpause() internal whenPaused {
        PausableStorage.layout()._paused = false;
        emit LibUtilities.Unpaused(msg.sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

/* solhint-disable reason-string, avoid-low-level-calls */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";

library LibDiamond {
    bytes32 internal constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }

    function addFunction(
        DiamondStorage storage ds,
        bytes4 _selector,
        uint96 _selectorPosition,
        address _facetAddress
    ) internal {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(
        DiamondStorage storage ds,
        address _facetAddress,
        bytes4 _selector
    ) internal {
        require(_facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    assembly {
                        revert(add(32, error), mload(error))
                    }
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }

    function callDelegateFuncNoArgs(bytes4 _functionSelector) internal {
        DiamondStorage storage ds = diamondStorage();
        // get facet address of function
        address facet = ds.selectorToFacetAndPosition[_functionSelector].facetAddress;
        bytes memory myFunctionCall = abi.encodeWithSelector(_functionSelector);
        (bool success, bytes memory error) = facet.delegatecall(myFunctionCall);
        if(!success) {
            if (error.length > 0) {
                // bubble up the error as it was given.
                // will return reason strings as well as custom errors
                assembly {
                    revert(add(32, error), mload(error))
                }
            } else {
                revert("external function call reverted");
            }
        }
    }

    function callDelegateFunc(bytes4 _functionSelector, bytes memory _funcCall) internal {
        DiamondStorage storage ds = diamondStorage();
        // get facet address of function 
        address facet = ds.selectorToFacetAndPosition[_functionSelector].facetAddress; 
        (bool success, bytes memory error) = facet.delegatecall(_funcCall);
        if(!success) {
            if (error.length > 0) {
                // bubble up the error
                revert(string(error));
            } else {
                revert("external function call reverted");
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FacetInitializableStorage} from "../utils/FacetInitializableStorage.sol";

library LibUtilities {
    event Paused(address _account);
    event Unpaused(address _account);

    error MissingEitherRole(address _account, bytes32 _roleOption1, bytes32 _roleOption2);
    error MissingRoleAndNotOwner(address _account, bytes32 _role);
    error MissingRole(address _account, bytes32 _role);

    error IsPaused();
    error NotPaused();

    function asSingletonArray(uint256 _item) internal pure returns (uint256[] memory array_) {
        array_ = new uint256[](1);
        array_[0] = _item;
    }

    function asSingletonArray(string memory _item) internal pure returns (string[] memory array_) {
        array_ = new string[](1);
        array_[0] = _item;
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() internal view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        assembly {
            cs := extcodesize(self)
        }
        return cs == 0;
    }

    /// @dev Returns true if the given facet has had its initializer ran
    function isFacetInitialized(bytes32 _facetId) internal view returns (bool) {
        return FacetInitializableStorage.getState()._initialized[_facetId];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Storage to track facets in a diamond that have been initialized.
 * Needed to prevent accidental re-initializations
 * Name changed to prevent collision with OZ contracts
 * OZ's Initializable storage handles all of the _initializing state, which isn't facet-specific
 */
library FacetInitializableStorage {
    error AlreadyInitialized(bytes32 facetId);
    
    struct State {
        /*
         * @dev Indicates that the contract/facet has been initialized.
         * bytes32 is the contract/facetId (keccak of the contract name)
         * bool is whether or not the contract/facet has been initialized
         */
        mapping(bytes32 => bool) _initialized;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("diamond.dapp.utils.Initializable");

    function getState() internal pure returns (State storage s) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            s.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {AccessControlUpgradeable} from "./AccessControlUpgradeable.sol";

library AccessControlStorage {
    struct Layout {
        mapping(bytes32 => AccessControlUpgradeable.RoleData) _roles;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("omnificient.contracts.storage.AccessControl");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import {AccessControlStorage} from "./AccessControlStorage.sol";
import "../../Initializable.sol";

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
abstract contract AccessControlUpgradeable is
    Initializable,
    ContextUpgradeable,
    IAccessControlUpgradeable,
    ERC165Upgradeable
{
    using AccessControlStorage for AccessControlStorage.Layout;

    function __AccessControl_init() internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal onlyInitializing {}

    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

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
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return AccessControlStorage.layout()._roles[role].members[account];
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
                        StringsUpgradeable.toHexString(account),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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
        return AccessControlStorage.layout()._roles[role].adminRole;
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     * May emit a {RoleGranted} event.
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
        AccessControlStorage.layout()._roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            AccessControlStorage.layout()._roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            AccessControlStorage.layout()._roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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

pragma solidity ^0.8.0;

import {PausableUpgradeable} from "./PausableUpgradeable.sol";

library PausableStorage {
    struct Layout {
        bool _paused;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("omnificient.contracts.storage.Pausable");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import {PausableStorage} from "./PausableStorage.sol";
import "../../Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    using PausableStorage for PausableStorage.Layout;
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        PausableStorage.layout()._paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return PausableStorage.layout()._paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        PausableStorage.layout()._paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        PausableStorage.layout()._paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.0;

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../../Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {}

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../../Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal onlyInitializing {}
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
    // function supportsInterface(bytes4 interfaceId) external view returns (bool);
}