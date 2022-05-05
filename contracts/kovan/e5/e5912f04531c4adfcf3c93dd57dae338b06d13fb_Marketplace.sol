/**
 *Submitted for verification at Etherscan.io on 2022-05-04
*/

// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;


// 
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
interface IMarketplaceEvents {
    event ConfigUpdated();

    event AddedToWhiteList(uint256 seasonId, address participant);

    event RemovedFromWhiteList(uint256 seasonId, address participant);

    event LootboxBought(uint256 seasonId, address buyer, address lootboxAddress, uint256 lootboxId);

    event ItemPriceSet(address addr, uint256 tokenId, uint256 price);

    event ItemPriceRemoved(address addr, uint256 tokenId);

    event ItemBought(address addr, uint256 tokenId, uint256 price);

    event SeasonAdded(
        uint256 startTimestamp,
        uint256 endTimestamp,
        uint256 lootboxesNumber,
        uint256 lootboxPrice,
        uint256 lootboxesPerAddress,
        bytes32 merkleRoot,
        string uri
    );

    event LootboxesSentInBatch(uint256 seasonId, address recipient, address lootboxAddress, uint256 number);
}

// 
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
struct NFTConfig {
    address lootboxAddress;
    address levelUpgradesAddress;
    address rarityCalculator;
}

struct RarityRates {
    uint8 common;
    uint8 rare;
    uint8 epic;
    uint8 legendary;
}

struct HashrateMultipliers {
    uint8[3] common;
    uint8[3] rare;
    uint8[3] epic;
    uint8[3] legendary;
}

struct VoteDiscounts {
    uint8[3] common;
    uint8[3] rare;
    uint8[3] epic;
    uint8[3] legendary;
}

enum Rarity {
    Common,
    Rare,
    Epic,
    Legendary
}

enum Level {
    Gen0,
    Gen1,
    Gen2
}

// 
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
contract OwnableStorage {
    address internal _owner;
}

// 
// Modified copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
// Original copyright OpenZeppelin Contracts v4.4.0 (token/ERC721/ERC721.sol)
contract ERC721Storage {
    // Token name
    string internal _name;

    // Token symbol
    string internal _symbol;

    // Base uri
    string internal _baseURI;

    // tokenId counter
    uint256 internal _tokenIdCounter;

    // Mapping from token ID to owner address
    mapping(uint256 => address) internal _owners;

    // Mapping owner address to token count
    mapping(address => uint256) internal _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) internal _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) internal _operatorApprovals;
}

// 
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
contract NFTStorage is ERC721Storage, OwnableStorage {
    NFTConfig internal _config;

    mapping(uint256 => uint256) internal _tokenCounterBySeason;
    mapping(uint256 => string) internal _seasonURI;

    mapping(uint256 => Rarity) internal _rarities;
    mapping(uint256 => uint256) internal _baseHashrates;

    mapping(uint256 => Level) internal _levels;
}

// 
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
interface INFTMayor {
    function batchMint(
        address owner,
        uint256 seasonId,
        string calldata seasonUri,
        uint256 nftStartIndex,
        uint256 numberToMint
    ) external returns (uint256[] memory tokenIds);

    function updateLevel(uint256 tokenId) external;

    function getLevel(uint256 tokenId) external view returns (Level);

    function getHashrate(uint256 tokenId) external view returns (uint256);

    function getVotePrice(uint256 tokenId, uint256 votePrice) external view returns (uint256);

    function getVoteDiscount(uint256 tokenId) external view returns (uint256);

    function getRarity(uint256 tokenId) external view returns (Rarity);
}

// 
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
interface INFTConfiguration {
    function updateConfig(NFTConfig calldata config) external;

    function getConfig() external view returns (NFTConfig memory);
}

// 
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
interface INFTEvents {
    event ConfigUpdated();

    event LevelUpdated(uint256 tokenId, Level level);
}

// 
// Modified copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
// Original copyright OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)
/**
 * @dev Required interface of an ERC721 compliant contract events.
 */
interface IERC721Events {
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
}

// 
// Modified copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
// Original copyright OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)
/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC721Events {
    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token
     * by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received},
     * which is called upon a safe transfer.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received},
     * which is called upon a safe transfer.
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

// 
// Modified copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
// Original copyright OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)
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
     * If any other value is returned or the interface is not implemented by the recipient,
     * the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// 
// Modified copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
// Original copyright OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Metadata.sol)
/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata {
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

// 
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
/**
 * @title ERC721 Mintable Token
 * @dev ERC721 Token that can be irreversibly minted.
 */
interface IERC721Mintable {
    /**
     * @dev Mints `tokenId`. See {ERC721-_mint}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function mint(address owner) external returns (uint256 tokenId);

    /**
     * @dev Mints `tokenId`. See {ERC721-_safeMint}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function safeMint(address owner) external returns (uint256 tokenId);

    /**
     * @dev Mints `tokenId`. See {ERC721-_safeMint}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function safeMint(address owner, bytes calldata data) external returns (uint256 tokenId);
}

// 
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// 
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
interface INFT is IERC165, IERC721, IERC721Metadata, INFTConfiguration, INFTMayor, INFTEvents {}

// 
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
library NFTErrors {
    error NoPermission();
    error SameAddress();
    error SameConfig();
    error SameRates();
    error NotEligible();
    error WrongRarity();
    error Overflow();
    error UnexistingToken();
    error SameValue();
    error WrongLevel();
    error MaxLevel();
}

// 
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
contract Ownable is OwnableStorage {
    error SameOwner();
    error NotOwner();

    event OwnershipTransferred(address to);

    modifier isOwner() {
        if (msg.sender != _owner) revert NotOwner();
        _;
    }

    //solhint-disable-next-line comprehensive-interface
    function transferOwnership(address to) external isOwner {
        if (_owner == to) revert SameOwner();
        _owner = to;
        emit OwnershipTransferred(to);
    }
}

// 
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
contract NFTConfiguration is INFTConfiguration, INFTEvents, Ownable, NFTStorage {
    function updateConfig(NFTConfig calldata config) external override isOwner {
        if (keccak256(abi.encode(_config)) == keccak256(abi.encode(config))) revert NFTErrors.SameConfig();
        _config = config;
        emit ConfigUpdated();
    }

    function getConfig() external view override returns (NFTConfig memory) {
        return _config;
    }
}

// 
// Modified copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
// Original copyright OpenZeppelin Contracts v4.4.0 (utils/Address.sol)
library AddressUtils {
    function isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }
}

// 
// Modified copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
// Original copyright OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)
library StringUtils {
    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function _toString(uint256 value) internal pure returns (string memory) {
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
}

// 
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
contract NFTERC721 is IERC165, IERC721, IERC721Metadata, Ownable, NFTStorage {
    using AddressUtils for address;
    using StringUtils for uint256;

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public override {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
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
    ) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI;
        string memory seasonURI = _seasonURI[tokenId];
        Level level = _levels[tokenId];

        return
            string(
                abi.encodePacked(
                    baseURI,
                    "/",
                    seasonURI,
                    "/",
                    _uintToASCIIBytes(tokenId),
                    "/",
                    _uintToASCIIBytes(tokenId),
                    "_",
                    _uintToASCIIBytes(uint8(level)),
                    ".json"
                )
            );
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
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
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received},
     * which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
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
    ) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
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
    ) internal {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @notice Original Copyright (c) 2015-2016 Oraclize SRL
     * @notice Original Copyright (c) 2016 Oraclize LTD
     * @notice Modified Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
     * @dev Converts an unsigned integer to its bytes representation
     * @notice https://github.com/provable-things/ethereum-api/blob/master/oraclizeAPI_0.5.sol#L1045
     * @param num The number to be converted
     * @return Bytes representation of the number
     */
    function _uintToASCIIBytes(uint256 num) internal pure returns (bytes memory) {
        uint256 _i = num;
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        while (_i != 0) {
            bstr[len - 1] = bytes1(uint8(48 + (_i % 10)));
            _i /= 10;
            len--;
        }
        return bstr;
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
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
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
}

// 
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
contract NFTModifiers is NFTStorage {
    modifier isLootboxOrOwner() {
        if (msg.sender != _config.lootboxAddress && msg.sender != _owner) {
            revert NFTErrors.NoPermission();
        }
        _;
    }

    modifier isExistingToken(uint256 tokenId) {
        if (_baseHashrates[tokenId] == 0) revert NFTErrors.UnexistingToken();
        _;
    }
}

// 
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
interface IRarityCalculator {
    function calculateRarityAndHashrate(
        uint256 blockNumber,
        uint256 id,
        address owner
    ) external view returns (Rarity, uint256);

    function getHashrate(
        Level level,
        Rarity rarity,
        uint256 baseHashrate
    ) external pure returns (uint256);

    function getVoteMultiplier(Level level, Rarity rarity) external pure returns (uint256);

    function getVoteDiscount(Level level, Rarity rarity) external pure returns (uint256);
}

// 
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
library NFTConstants {
    uint8 internal constant HASHRATE_MULTIPLIERS_COMMON_GEN0 = 10;
    uint8 internal constant HASHRATE_MULTIPLIERS_COMMON_GEN1 = 40;
    uint8 internal constant HASHRATE_MULTIPLIERS_COMMON_GEN2 = 120;

    uint8 internal constant HASHRATE_MULTIPLIERS_RARE_GEN0 = 10;
    uint8 internal constant HASHRATE_MULTIPLIERS_RARE_GEN1 = 30;
    uint8 internal constant HASHRATE_MULTIPLIERS_RARE_GEN2 = 75;

    uint8 internal constant HASHRATE_MULTIPLIERS_EPIC_GEN0 = 10;
    uint8 internal constant HASHRATE_MULTIPLIERS_EPIC_GEN1 = 25;
    uint8 internal constant HASHRATE_MULTIPLIERS_EPIC_GEN2 = 50;

    uint8 internal constant HASHRATE_MULTIPLIERS_LEGENDARY_GEN0 = 10;
    uint8 internal constant HASHRATE_MULTIPLIERS_LEGENDARY_GEN1 = 20;
    uint8 internal constant HASHRATE_MULTIPLIERS_LEGENDARY_GEN2 = 30;

    uint8 internal constant VOTE_MULTIPLIER_COMMON_GEN0 = 100;
    uint8 internal constant VOTE_MULTIPLIER_COMMON_GEN1 = 99;
    uint8 internal constant VOTE_MULTIPLIER_COMMON_GEN2 = 98;

    uint8 internal constant VOTE_MULTIPLIER_RARE_GEN0 = 100;
    uint8 internal constant VOTE_MULTIPLIER_RARE_GEN1 = 98;
    uint8 internal constant VOTE_MULTIPLIER_RARE_GEN2 = 96;

    uint8 internal constant VOTE_MULTIPLIER_EPIC_GEN0 = 100;
    uint8 internal constant VOTE_MULTIPLIER_EPIC_GEN1 = 96;
    uint8 internal constant VOTE_MULTIPLIER_EPIC_GEN2 = 94;

    uint8 internal constant VOTE_MULTIPLIER_LEGENDARY_GEN0 = 100;
    uint8 internal constant VOTE_MULTIPLIER_LEGENDARY_GEN1 = 94;
    uint8 internal constant VOTE_MULTIPLIER_LEGENDARY_GEN2 = 92;

    uint8 internal constant COMMON_RATE = 69;
    uint8 internal constant RARE_RATE = 94;
    uint8 internal constant EPIC_RATE = 99;
    uint8 internal constant LEGENDARY_RATE = 100;

    uint8 internal constant MAX_LEVEL = 2;

    uint256 internal constant COMMON_RANGE_MAX = 20;
    uint256 internal constant COMMON_RANGE_MIN = 10;

    uint256 internal constant RARE_RANGE_MAX = 55;
    uint256 internal constant RARE_RANGE_MIN = 27;

    uint256 internal constant EPIC_RANGE_MAX = 275;
    uint256 internal constant EPIC_RANGE_MIN = 125;

    uint256 internal constant LEGENDARY_RANGE_MAX = 1400;
    uint256 internal constant LEGENDARY_RANGE_MIN = 650;
}

// 
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
contract NFTMayor is INFTMayor, INFTEvents, NFTERC721, NFTModifiers {
    function batchMint(
        address owner,
        uint256 seasonId,
        string calldata seasonUri,
        uint256 nftStartIndex,
        uint256 numberToMint
    ) external override isLootboxOrOwner returns (uint256[] memory tokenIds) {
        tokenIds = new uint256[](numberToMint);
        for (uint256 i = 0; i < numberToMint; i++) {
            uint256 tokenId = _mintAndSetRarityAndHashrate(owner, seasonId, nftStartIndex);
            tokenIds[i] = tokenId;
            _seasonURI[tokenId] = seasonUri;
        }

        return tokenIds;
    }

    function updateLevel(uint256 tokenId) external override isExistingToken(tokenId) isOwner {
        if (_config.levelUpgradesAddress != msg.sender) revert NFTErrors.NotEligible();
        Level currentLevel = _levels[tokenId];
        if (uint8(currentLevel) == NFTConstants.MAX_LEVEL) revert NFTErrors.MaxLevel();
        _levels[tokenId] = Level(uint8(currentLevel) + 1);

        emit LevelUpdated(tokenId, Level(uint8(currentLevel) + 1));
    }

    function getLevel(uint256 tokenId) external view override isExistingToken(tokenId) returns (Level) {
        return _levels[tokenId];
    }

    function getRarity(uint256 tokenId) external view override isExistingToken(tokenId) returns (Rarity) {
        return _rarities[tokenId];
    }

    function getHashrate(uint256 tokenId) external view override isExistingToken(tokenId) returns (uint256) {
        Level level = _levels[tokenId];
        Rarity rarity = _rarities[tokenId];
        uint256 baseHashrate = _baseHashrates[tokenId];

        return IRarityCalculator(_config.rarityCalculator).getHashrate(level, rarity, baseHashrate);
    }

    function getVotePrice(uint256 tokenId, uint256 votePrice)
        external
        view
        override
        isExistingToken(tokenId)
        returns (uint256)
    {
        return (votePrice * _getVoteMultiplier(tokenId)) / 100;
    }

    function getVoteDiscount(uint256 tokenId) public view override isExistingToken(tokenId) returns (uint256) {
        Level level = _levels[tokenId];
        Rarity rarity = _rarities[tokenId];

        return IRarityCalculator(_config.rarityCalculator).getVoteDiscount(level, rarity);
    }

    function _mintAndSetRarityAndHashrate(
        address owner,
        uint256 seasonId,
        uint256 nftStartIndex
    ) internal returns (uint256) {
        uint256 id = _calculateTokenId(seasonId, nftStartIndex);
        _mint(owner, id);
        _setRarityAndHashrate(id, owner);
        return id;
    }

    function _calculateTokenId(uint256 seasonId, uint256 nftStartIndex) internal returns (uint256) {
        uint256 seasonTokenIndex = _tokenCounterBySeason[seasonId]++;
        return nftStartIndex + seasonTokenIndex;
    }

    function _setRarityAndHashrate(uint256 id, address owner) internal {
        (Rarity rarity, uint256 hashrate) = IRarityCalculator(_config.rarityCalculator).calculateRarityAndHashrate(
            block.number,
            id,
            owner
        );
        _rarities[id] = rarity;
        _baseHashrates[id] = hashrate;
    }

    function _getVoteMultiplier(uint256 tokenId) internal view isExistingToken(tokenId) returns (uint256) {
        Level level = _levels[tokenId];
        Rarity rarity = _rarities[tokenId];

        return IRarityCalculator(_config.rarityCalculator).getVoteMultiplier(level, rarity);
    }
}

// 
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
contract NFT is NFTMayor, NFTConfiguration {
    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        address owner
    ) {
        _name = name_;
        _symbol = symbol_;
        _baseURI = baseURI_;
        _owner = owner;
    }
}

// 
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
struct LootboxConfig {
    address marketplaceAddress;
    NFT nft;
}

struct SeasonInfo {
    uint256 lootboxesCounter;
    string uri;
    uint256 nftStartIndex;
    uint256 nftNumberInLootbox;
}

// 
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
contract LootboxStorage is ERC721Storage, OwnableStorage {
    LootboxConfig internal _config;

    mapping(uint256 => uint256) internal _unlockTimestamp;

    mapping(uint256 => uint256) internal _seasonIds;
    mapping(uint256 => SeasonInfo) internal _seasonInfo;
}

// 
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
interface ILootboxConfiguration {
    function updateConfig(LootboxConfig calldata config, string calldata uri) external;

    function getConfig() external view returns (LootboxConfig memory);
}

// 
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
interface ILootboxLifecycle {
    function mint(
        uint256 seasonId,
        string calldata seasonUri,
        uint256 nftStartIndex,
        uint256 nftNumberInLootbox,
        uint256 unlockTimestamp,
        address owner
    ) external returns (uint256 tokenId);

    function reveal(uint256 tokenId) external returns (uint256[] memory tokenIds);

    function batchMint(
        uint256 number,
        uint256 seasonId,
        string calldata seasonUri,
        uint256 nftStartIndex,
        uint256 nftNumberInLootbox,
        uint256 unlockTimestamp,
        address owner
    ) external;

    function getUnlockTimestamp(uint256 tokenId) external view returns (uint256);

    function getSeasonUriTimestamp(uint256 tokenId) external view returns (string memory);
}

// 
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
interface ILootboxEvents {
    event ConfigUpdated();
    event SeasonInfoAdded(
        uint256 seasonId,
        uint256 number,
        string uri,
        uint256 nftStartIndex,
        uint256 nftNumberInLootbox
    );
}

// 
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
interface ILootbox is IERC165, IERC721, IERC721Metadata, ILootboxConfiguration, ILootboxLifecycle, ILootboxEvents {}

// 
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
contract LootboxERC721 is IERC165, IERC721, IERC721Metadata, Ownable, LootboxStorage {
    using AddressUtils for address;
    using StringUtils for uint256;

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public override {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
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
    ) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(_baseURI).length > 0 ? _baseURI : "";
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
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
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received},
     * which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

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
    function _burn(uint256 tokenId) internal {
        address owner = ownerOf(tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
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
    ) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
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
    ) internal {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
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
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
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
}

// 
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
library LootboxErrors {
    error SameAddress();
    error SameValue();
    error NoPermission();
    error Overflow();
    error SameConfig();
    error NotUnlocked();
    error NoSeasonInfo();
}

// 
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
contract LootboxLifecycle is ILootboxLifecycle, ILootboxEvents, LootboxERC721 {
    modifier isMarketplaceOrOwner() {
        if (msg.sender != _config.marketplaceAddress && msg.sender != _owner) {
            revert LootboxErrors.NoPermission();
        }
        _;
    }

    function reveal(uint256 tokenId) external override returns (uint256[] memory tokenIds) {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) revert LootboxErrors.NoPermission();
        // solhint-disable-next-line not-rely-on-time
        if (_unlockTimestamp[tokenId] > block.timestamp) revert LootboxErrors.NotUnlocked();

        uint256 seasonId = _seasonIds[tokenId];
        SeasonInfo storage seasonInfo = _seasonInfo[seasonId];
        if (bytes(seasonInfo.uri).length == 0) revert LootboxErrors.NoSeasonInfo();

        tokenIds = _config.nft.batchMint(
            msg.sender,
            seasonId,
            seasonInfo.uri,
            seasonInfo.nftStartIndex,
            seasonInfo.nftNumberInLootbox
        );

        _burn(tokenId);
        delete _seasonIds[tokenId];
        if (seasonInfo.lootboxesCounter <= 1) {
            delete _seasonInfo[seasonId];
        } else {
            seasonInfo.lootboxesCounter--;
        }

        return tokenIds;
    }

    function mint(
        uint256 seasonId,
        string calldata seasonUri,
        uint256 nftStartIndex,
        uint256 nftNumberInLootbox,
        uint256 unlockTimestamp,
        address owner
    ) external override isMarketplaceOrOwner returns (uint256 tokenId) {
        uint256 id = _tokenIdCounter++;
        _mint(owner, id);
        _seasonIds[id] = seasonId;
        _unlockTimestamp[id] = unlockTimestamp;
        uint256 lootboxesCounter = 1;
        _addSeasonInfo(seasonId, lootboxesCounter, seasonUri, nftStartIndex, nftNumberInLootbox);
        return id;
    }

    function batchMint(
        uint256 number,
        uint256 seasonId,
        string calldata seasonUri,
        uint256 nftStartIndex,
        uint256 nftNumberInLootbox,
        uint256 unlockTimestamp,
        address owner
    ) external override isMarketplaceOrOwner {
        _balances[owner] += number;

        for (; number > 0; number--) {
            uint256 id = _tokenIdCounter++;
            _owners[id] = owner;
            _seasonIds[id] = seasonId;
            _unlockTimestamp[id] = unlockTimestamp;
            emit Transfer(address(0), owner, id);
        }
        _addSeasonInfo(seasonId, number, seasonUri, nftStartIndex, nftNumberInLootbox);
    }

    function getUnlockTimestamp(uint256 tokenId) external view override returns (uint256) {
        return _unlockTimestamp[tokenId];
    }

    function getSeasonUriTimestamp(uint256 tokenId) external view override returns (string memory) {
        return _seasonInfo[_seasonIds[tokenId]].uri;
    }

    function _addSeasonInfo(
        uint256 seasonId,
        uint256 lootboxesCounter,
        string calldata uri,
        uint256 nftStartIndex,
        uint256 nftNumberInLootbox
    ) internal {
        SeasonInfo memory seasonInfo = _seasonInfo[seasonId];
        if (bytes(seasonInfo.uri).length == 0) {
            _seasonInfo[seasonId] = SeasonInfo(lootboxesCounter, uri, nftStartIndex, nftNumberInLootbox);
            emit SeasonInfoAdded(seasonId, lootboxesCounter, uri, nftStartIndex, nftNumberInLootbox);
        }
    }
}

// 
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
contract LootboxConfiguration is ILootboxConfiguration, ILootboxEvents, Ownable, LootboxStorage {
    function updateConfig(LootboxConfig calldata config, string calldata uri) external override isOwner {
        if (keccak256(abi.encode(_config, _baseURI)) == keccak256(abi.encode(config, uri)))
            revert LootboxErrors.SameConfig();
        _config = config;
        _baseURI = uri;
        emit ConfigUpdated();
    }

    function getConfig() external view override returns (LootboxConfig memory) {
        return _config;
    }
}

// 
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
contract Lootbox is LootboxLifecycle, LootboxConfiguration {
    constructor(
        string memory name_,
        string memory symbol_,
        address owner
    ) {
        _name = name_;
        _symbol = symbol_;
        _owner = owner;
    }
}

// 
// Modified copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
// Original copyright OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);
}

// 
// Modified copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
// Original copyright OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)
/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// 
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
/**
 * @title ERC20 Mintable Token
 * @dev ERC20 Token that can be irreversibly minted.
 */
interface IERC20Mintable {
    /**
     * @dev Mints tokens. See {ERC20-_mint}.
     */
    function mint(address recipient, uint256 value) external;
}

// 
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
interface IToken is IERC165, IERC20, IERC20Metadata, IERC20Mintable {
    /**
     * @dev Mints tokens to several recipients.
     */
    function batchMint(address[] calldata recipients, uint256 value) external;
}

// 
// Modified copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
// Original copyright OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)
/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is IERC165, IERC20, IERC20Metadata, IERC20Mintable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Mints tokens. See {ERC20-_mint}.
     */
    function mint(address recipient, uint256 value) public virtual override {
        _mint(recipient, value);
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    //solhint-disable-next-line comprehensive-interface
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    //solhint-disable-next-line comprehensive-interface
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = msg.sender;
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC20).interfaceId ||
            interfaceId == type(IERC20Mintable).interfaceId ||
            interfaceId == type(IERC20Metadata).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// 
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
contract Token is IToken, ERC20, Ownable {
    constructor(
        string memory name_,
        string memory symbol_,
        address owner
    ) ERC20(name_, symbol_) {
        _owner = owner;
    }

    /**
     * @dev Mints tokens to several recipients.
     */
    function batchMint(address[] calldata recipients, uint256 value) external override isOwner {
        uint256 length = recipients.length;
        for (uint256 i = 0; i < length; i++) {
            super.mint(recipients[i], value);
        }
    }

    /**
     * @dev Mints tokens. See {ERC20-_mint}.
     */
    function mint(address recipient, uint256 value) public override(ERC20, IERC20Mintable) isOwner {
        super.mint(recipient, value);
    }
}

// 
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
struct Season {
    uint256 startTimestamp;
    uint256 endTimestamp;
    uint256 lootboxesNumber;
    uint256 lootboxPrice;
    uint256 lootboxesPerAddress;
    uint256 lootboxesUnlockTimestamp;
    uint256 nftNumberInLootbox;
    uint256 nftStartIndex;
    bytes32 merkleRoot;
    bool isPublic;
    string uri;
}

struct Item {
    address addr;
    uint256 tokenId;
}

struct MarketplaceConfig {
    Lootbox lootbox;
    NFT nft;
    Token paymentTokenPrimary;
    Token paymentTokenSecondary;
    address feeAggregator;
}

// 
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
interface IMarketplaceConfiguration {
    function updateConfig(MarketplaceConfig calldata config) external;

    function addNewSeasons(Season[] calldata seasons) external;

    function getConfig() external view returns (MarketplaceConfig memory);

    function getSeasonsTotal() external view returns (uint256);

    function getSeasons(uint256 start, uint256 number) external view returns (Season[] memory);
}

// 
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
interface IMarketplacePrimary {
    function buyLootboxMP(
        uint256 seasonId,
        uint256 index,
        bytes32[] calldata merkleProof
    ) external returns (uint256);

    function buyLootbox(uint256 seasonId) external returns (uint256);

    function sendLootboxes(
        uint256 seasonId,
        uint256 number,
        address recipient
    ) external;

    function addToWhiteList(uint256 seasonId, address[] calldata participants) external;

    function removeFromWhiteList(uint256 seasonId, address[] calldata participants) external;

    function isInWhiteList(uint256 seasonId, address participant) external view returns (bool);

    function verifyMerkleProof(
        uint256 seasonId,
        uint256 index,
        address account,
        bytes32[] calldata merkleProof
    ) external view returns (bool);

    function getSeason(uint256 seasonId) external view returns (Season memory);
}

// 
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
interface IMarketplaceSecondary {
    function setItemForSale(Item calldata item, uint256 price) external;

    function removeItemFromSale(Item calldata item) external;

    function buyItem(Item calldata item) external;

    function getItemPrice(Item calldata item) external view returns (uint256);
}

// 
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
interface IMarketplace is IMarketplaceEvents, IMarketplaceConfiguration, IMarketplacePrimary, IMarketplaceSecondary {}

// 
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
library MarketplaceErrors {
    error NotInMerkleTree();
    error NotInWhiteList();
    error TooManyLootboxesPerAddress();
    error NoSeasons();
    error EmptySeason();
    error SameValue();
    error NotTradable();
    error AlreadyOwner();
    error NotOnSale();
    error SameConfig();
    error NotValidPrice();
    error NotItemOwner();
    error UnexistingSeason();
    error ZeroPrice();
    error NoURI();
    error SeasonNotStarted();
    error SeasonFinished();
    error LootboxesEnded();
    error WrongTimestamps();
}

// 
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
contract MarketplaceStorage is OwnableStorage {
    MarketplaceConfig internal _config;

    Season[] internal _seasons;
    mapping(uint256 => mapping(address => bool)) internal _whiteList;
    mapping(uint256 => mapping(address => uint256)) internal _lootboxesBought;

    mapping(bytes32 => uint256) internal _itemPrice;
}

// 
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
contract MarketplaceConfiguration is IMarketplaceConfiguration, IMarketplaceEvents, Ownable, MarketplaceStorage {
    function updateConfig(MarketplaceConfig calldata config) external override isOwner {
        if (keccak256(abi.encode(_config)) == keccak256(abi.encode(config))) revert MarketplaceErrors.SameConfig();
        _config = config;
        emit ConfigUpdated();
    }

    function addNewSeasons(Season[] calldata seasons) external override isOwner {
        _addNewSeasons(seasons);
    }

    function getConfig() external view override returns (MarketplaceConfig memory) {
        return _config;
    }

    function getSeasonsTotal() external view override returns (uint256) {
        return _seasons.length;
    }

    function getSeasons(uint256 start, uint256 number) external view override returns (Season[] memory) {
        if (start + number > _seasons.length) revert MarketplaceErrors.UnexistingSeason();

        Season[] memory seasons = new Season[](number);
        for (uint256 i = 0; i < number; i++) {
            seasons[i] = _seasons[start + i];
        }
        return seasons;
    }

    function _addNewSeasons(Season[] memory seasons) internal {
        uint256 seasonsLength = seasons.length;
        if (seasonsLength == 0) revert MarketplaceErrors.NoSeasons();
        for (uint256 i = 0; i < seasonsLength; i++) {
            Season memory season = seasons[i];
            if (season.startTimestamp > season.endTimestamp) revert MarketplaceErrors.WrongTimestamps();
            if (season.lootboxesNumber == 0) revert MarketplaceErrors.EmptySeason();
            if (season.lootboxPrice == 0) revert MarketplaceErrors.ZeroPrice();
            if (bytes(season.uri).length == 0) revert MarketplaceErrors.NoURI();
            _seasons.push(season);

            emit SeasonAdded(
                season.startTimestamp,
                season.endTimestamp,
                season.lootboxesNumber,
                season.lootboxPrice,
                season.lootboxesPerAddress,
                season.merkleRoot,
                season.uri
            );
        }
    }
}

// 
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)
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

// 
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
contract MarketplacePrimary is IMarketplacePrimary, IMarketplaceEvents, Ownable, MarketplaceStorage {
    function buyLootboxMP(
        uint256 seasonId,
        uint256 index,
        bytes32[] calldata merkleProof
    ) external override returns (uint256) {
        Season storage season = _verifySeason(seasonId, 1);

        // Verify merkle proof
        if (!verifyMerkleProof(seasonId, index, msg.sender, merkleProof)) revert MarketplaceErrors.NotInMerkleTree();

        return _buyLootbox(seasonId, season);
    }

    function buyLootbox(uint256 seasonId) external override returns (uint256) {
        Season storage season = _verifySeason(seasonId, 1);

        if (!_whiteList[seasonId][msg.sender]) revert MarketplaceErrors.NotInWhiteList();

        return _buyLootbox(seasonId, season);
    }

    function sendLootboxes(
        uint256 seasonId,
        uint256 number,
        address recipient
    ) external override isOwner {
        Season storage season = _verifySeason(seasonId, number);

        _seasons[seasonId].lootboxesNumber -= number;
        _lootboxesBought[seasonId][msg.sender] += number;
        emit LootboxesSentInBatch(seasonId, recipient, address(_config.lootbox), number);

        _config.lootbox.batchMint(
            number,
            seasonId,
            season.uri,
            season.nftStartIndex,
            season.nftNumberInLootbox,
            season.lootboxesUnlockTimestamp,
            recipient
        );
    }

    function addToWhiteList(uint256 seasonId, address[] calldata participants) external override isOwner {
        uint256 length = participants.length;
        for (uint256 i = 0; i < length; i++) {
            bool whiteList = _whiteList[seasonId][participants[i]];
            if (!whiteList) {
                _whiteList[seasonId][participants[i]] = true;
                emit AddedToWhiteList(seasonId, participants[i]);
            }
        }
    }

    function removeFromWhiteList(uint256 seasonId, address[] calldata participants) external override isOwner {
        uint256 length = participants.length;
        for (uint256 i = 0; i < length; i++) {
            bool whiteList = _whiteList[seasonId][participants[i]];
            if (whiteList) {
                _whiteList[seasonId][participants[i]] = false;
                emit RemovedFromWhiteList(seasonId, participants[i]);
            }
        }
    }

    function isInWhiteList(uint256 seasonId, address participant) external view override returns (bool) {
        return _whiteList[seasonId][participant];
    }

    function verifyMerkleProof(
        uint256 seasonId,
        uint256 index,
        address account,
        bytes32[] memory merkleProof
    ) public view override returns (bool) {
        bytes32 node = _node(index, account);
        return MerkleProof.verify(merkleProof, _seasons[seasonId].merkleRoot, node);
    }

    function getSeason(uint256 seasonId) public view override returns (Season memory) {
        return _getSeason(seasonId);
    }

    function _buyLootbox(uint256 seasonId, Season storage season) internal returns (uint256) {
        _seasons[seasonId].lootboxesNumber--;
        _lootboxesBought[seasonId][msg.sender]++;

        uint256 id = _config.lootbox.mint(
            seasonId,
            season.uri,
            season.nftStartIndex,
            season.nftNumberInLootbox,
            season.lootboxesUnlockTimestamp,
            msg.sender
        );
        emit LootboxBought(seasonId, msg.sender, address(_config.lootbox), id);

        _config.paymentTokenPrimary.transferFrom(msg.sender, _config.feeAggregator, season.lootboxPrice);

        return id;
    }

    function _getSeason(uint256 seasonId) internal view returns (Season storage) {
        if (seasonId > _seasons.length - 1) revert MarketplaceErrors.UnexistingSeason();
        return _seasons[seasonId];
    }

    function _verifySeason(uint256 seasonId, uint256 lootboxes) internal view returns (Season storage) {
        Season storage season = _getSeason(seasonId);

        // solhint-disable not-rely-on-time
        if (season.startTimestamp > block.timestamp) revert MarketplaceErrors.SeasonNotStarted();
        if (season.endTimestamp > 0 && season.endTimestamp <= block.timestamp)
            revert MarketplaceErrors.SeasonFinished();
        // solhint-enable not-rely-on-time
        if (season.lootboxesNumber < lootboxes) revert MarketplaceErrors.LootboxesEnded();
        if (season.lootboxesPerAddress < _lootboxesBought[seasonId][msg.sender] + lootboxes)
            revert MarketplaceErrors.TooManyLootboxesPerAddress();

        return season;
    }

    function _node(uint256 index, address account) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(index, account));
    }
}

// 
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
library MarketplaceConstants {
    uint256 internal constant MIN_VALID_PRICE = 100 wei;
}

// 
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
contract MarketplaceSecondary is IMarketplaceSecondary, IMarketplaceEvents, MarketplaceStorage {
    function setItemForSale(Item calldata item, uint256 price) external override {
        if (price < MarketplaceConstants.MIN_VALID_PRICE) revert MarketplaceErrors.NotValidPrice();
        if (!_isTradableItem(item.addr)) revert MarketplaceErrors.NotTradable();
        if (IERC721(item.addr).ownerOf(item.tokenId) != msg.sender) revert MarketplaceErrors.NotItemOwner();

        bytes32 id = keccak256(abi.encode(item));
        if (_itemPrice[id] == price) revert MarketplaceErrors.SameValue();

        _itemPrice[id] = price;
        emit ItemPriceSet(item.addr, item.tokenId, price);
    }

    function removeItemFromSale(Item calldata item) external override {
        if (IERC721(item.addr).ownerOf(item.tokenId) != msg.sender) revert MarketplaceErrors.NotItemOwner();

        bytes32 id = keccak256(abi.encode(item));
        uint256 price = _itemPrice[id];
        if (price == 0) revert MarketplaceErrors.NotOnSale();

        _itemPrice[id] = 0;
        emit ItemPriceRemoved(item.addr, item.tokenId);
    }

    function buyItem(Item calldata item) external override {
        address owner = IERC721(item.addr).ownerOf(item.tokenId);
        if (owner == msg.sender) revert MarketplaceErrors.AlreadyOwner();

        bytes32 id = keccak256(abi.encode(item));
        uint256 price = _itemPrice[id];
        if (price == 0) revert MarketplaceErrors.NotOnSale();

        _itemPrice[id] = 0;
        emit ItemBought(item.addr, item.tokenId, price);

        _payForItem(price, owner);

        IERC721(item.addr).transferFrom(owner, msg.sender, item.tokenId);
    }

    function getItemPrice(Item calldata item) external view override returns (uint256) {
        uint256 price = _itemPrice[keccak256(abi.encode(item))];
        if (price == 0) revert MarketplaceErrors.NotOnSale();
        return price;
    }

    function _payForItem(uint256 price, address owner) internal {
        _config.paymentTokenSecondary.transferFrom(msg.sender, address(this), price);
        uint256 fee = price / 100;
        _config.paymentTokenSecondary.transfer(_config.feeAggregator, fee);
        _config.paymentTokenSecondary.transfer(owner, price - fee);
    }

    function _isTradableItem(address item) internal view returns (bool) {
        return item == address(_config.nft) || item == address(_config.lootbox);
    }
}

// 
// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
contract Marketplace is MarketplaceConfiguration, MarketplacePrimary, MarketplaceSecondary {
    constructor(MarketplaceConfig memory config, address owner) {
        _config = config;
        _owner = owner;
    }
}