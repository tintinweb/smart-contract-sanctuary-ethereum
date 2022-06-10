/**
 *Submitted for verification at Etherscan.io on 2022-06-10
*/

// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;


// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
contract OwnableStorage {
    address internal _owner;
}

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

// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
contract NFTStorage is ERC721Storage, OwnableStorage {
    NFTConfig internal _config;

    mapping(uint256 => uint256) internal _tokenCounterBySeason;
    mapping(uint256 => string) internal _seasonURI;

    mapping(uint256 => Rarity) internal _rarities;
    mapping(uint256 => uint256) internal _baseHashrates;

    mapping(uint256 => Level) internal _levels;
}

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

// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
interface INFTConfiguration {
    function updateConfig(NFTConfig calldata config) external;

    function getConfig() external view returns (NFTConfig memory);
}

// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
interface INFTEvents {
    event ConfigUpdated();

    event LevelUpdated(uint256 tokenId, Level level);
}

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

// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
interface INFT is IERC165, IERC721, IERC721Metadata, INFTConfiguration, INFTMayor, INFTEvents {}

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

// Copyright © 2022 Artem Belozerov. All rights reserved.
struct VoteConfig {
    address votingAddress;
}

// Copyright © 2022 Artem Belozerov. All rights reserved.
contract VoteStorage is OwnableStorage {
    VoteConfig internal _config;
}

// Copyright © 2022 Artem Belozerov. All rights reserved.
library VoteErrors {
    error SameConfig();
    error NoPermission();
}

// Copyright © 2022 Artem Belozerov. All rights reserved.
contract VoteModifiers is VoteStorage {
    modifier isVotingOrOwner() {
        if (msg.sender != _config.votingAddress && msg.sender != _owner) {
            revert VoteErrors.NoPermission();
        }
        _;
    }
}

// Copyright © 2022 Artem Belozerov. All rights reserved.
library VoteConstants {
    uint8 internal constant DECIMAL = 4;
    uint256 internal constant TOTAL_SUPPLY = 10000000000000;
}

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

// Copyright © 2022 Artem Belozerov. All rights reserved.
/**
 * @title ERC20 Burnable Token
 * @dev ERC20 Token that can be irreversibly burned (destroyed).
 */
interface IERC20Burnable {
    /**
     * @dev Burns tokens. See {ERC20-_burn}.
     */
    function burn(address recipient, uint256 value) external;
}

// Copyright © 2022 Artem Belozerov. All rights reserved.
interface IVoteERC20 is IERC165, IERC20, IERC20Metadata, IERC20Burnable {}

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
contract ERC20 is IERC165, IERC20, IERC20Metadata {
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

// Copyright © 2022 Artem Belozerov. All rights reserved.
contract VoteERC20 is IVoteERC20, ERC20, Ownable, VoteModifiers {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {}

    /**
     * @dev Burns tokens. See {ERC20-_burn}.
     */
    function burn(address recipient, uint256 value) public override isVotingOrOwner {
        _burn(recipient, value);
    }

    function decimals() public pure override(ERC20, IERC20Metadata) returns (uint8) {
        return VoteConstants.DECIMAL;
    }
}

// Copyright © 2022 Artem Belozerov. All rights reserved.
interface IVoteConfiguration {
    function updateConfig(VoteConfig calldata config) external;

    function getConfig() external view returns (VoteConfig memory);
}

// Copyright © 2022 Artem Belozerov. All rights reserved.
interface IVoteEvents {
    event ConfigUpdated();
}

// Copyright © 2022 Artem Belozerov. All rights reserved.
contract VoteConfiguration is IVoteConfiguration, IVoteEvents, Ownable, VoteStorage {
    function updateConfig(VoteConfig calldata config) external override isOwner {
        if (keccak256(abi.encode(_config)) == keccak256(abi.encode(config))) revert VoteErrors.SameConfig();
        _config = config;
        emit ConfigUpdated();
    }

    function getConfig() external view override returns (VoteConfig memory) {
        return _config;
    }
}

// Copyright © 2022 Artem Belozerov. All rights reserved.
contract Vote is VoteERC20, VoteConfiguration {
    constructor(
        string memory name_,
        string memory symbol_,
        address owner
    ) VoteERC20(name_, symbol_) {
        _owner = owner;
        _mint(owner, VoteConstants.TOTAL_SUPPLY);
    }
}

// Copyright © 2022 Artem Belozerov. All rights reserved.
library VoucherErrors {
    error SameConfig();
    error NoPermission();
}

// Copyright © 2022 Artem Belozerov. All rights reserved.
struct VoucherConfig {
    address stakingAddress;
}

// Copyright © 2022 Artem Belozerov. All rights reserved.
contract VoucherStorage is OwnableStorage {
    VoucherConfig internal _config;
}

// Copyright © 2022 Artem Belozerov. All rights reserved.
interface IVoucherConfiguration {
    function updateConfig(VoucherConfig calldata config) external;

    function getConfig() external view returns (VoucherConfig memory);
}

// Copyright © 2022 Artem Belozerov. All rights reserved.
interface IVoucherEvents {
    event ConfigUpdated();
}

// Copyright © 2022 Artem Belozerov. All rights reserved.
contract VoucherConfiguration is IVoucherConfiguration, IVoucherEvents, Ownable, VoucherStorage {
    function updateConfig(VoucherConfig calldata config) external override isOwner {
        if (keccak256(abi.encode(_config)) == keccak256(abi.encode(config))) revert VoucherErrors.SameConfig();
        _config = config;
        emit ConfigUpdated();
    }

    function getConfig() external view override returns (VoucherConfig memory) {
        return _config;
    }
}

// Copyright © 2022 Artem Belozerov. All rights reserved.
contract VoucherModifiers is VoucherStorage {
    modifier isStakingOrOwner() {
        if (msg.sender != _config.stakingAddress && msg.sender != _owner) {
            revert VoucherErrors.NoPermission();
        }
        _;
    }
}

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

// Copyright © 2022 Artem Belozerov. All rights reserved.
interface IVoucherERC20 is IERC165, IERC20, IERC20Metadata, IERC20Mintable {}

// Copyright © 2022 Artem Belozerov. All rights reserved.
contract VoucherERC20 is IVoucherERC20, ERC20, Ownable, VoucherStorage, VoucherModifiers {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {}

    /**
     * @dev Mints tokens. See {ERC20-_mint}.
     */
    function mint(address recipient, uint256 value) public override isStakingOrOwner {
        _mint(recipient, value);
    }

    function decimals() public pure override(ERC20, IERC20Metadata) returns (uint8) {
        return 2;
    }
}

// Copyright © 2022 Artem Belozerov. All rights reserved.
interface IVoucher is IVoucherConfiguration, IVoucherERC20, IVoucherEvents {}

// Copyright © 2022 Artem Belozerov. All rights reserved.
contract Voucher is VoucherERC20, VoucherConfiguration {
    constructor(
        string memory name_,
        string memory symbol_,
        VoucherConfig memory config,
        address owner
    ) VoucherERC20(name_, symbol_) {
        _config = config;
        _owner = owner;
    }
}

// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
enum Building {
    Empty,
    University,
    Hospital,
    Bank,
    Factory,
    Stadium,
    Monument
}

struct Region {
    bool active;
    uint256 startVotingTimestamp;
}

struct City {
    uint256 regionId;
    string name;
    uint256 population;
    uint256 votePrice;
    bool active;
}

struct NewCity {
    string name;
    uint256 population;
    uint256 votePrice;
}

struct Nominee {
    uint256 mayorId;
    uint256 votes;
}

// season number starts from 1
struct BuildingInfo {
    Building building;
    uint256 season;
}

struct ClaimInfo {
    uint256 cityId;
    uint256[] seasonIds;
}

// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
interface IVoting {
    event CitiesAdded(uint256 indexed regionId, uint256[] newCities);
    event VotePriceUpdated(uint256 indexed cityId, uint256 oldPrice, uint256 newPrice);
    event VotingStarted(uint256 indexed regionId, uint256 endVotingTimestamp);
    event BuildingAdded(address indexed owner, uint256 indexed cityId, uint256 indexed season, Building newBuilding);
    event CandidateAdded(uint256 indexed mayorId, uint256 indexed cityId, uint256 votes);
    event CityUpdated(uint256 indexed cityId, bool isOpen);
    event PrizeClaimed(address indexed account, uint256 indexed cityId, uint256 amount, uint256 toBurn);
    event VotesPerCitizenUpdated(uint256 oldAmount, uint256 amount);

    function transferTokens() external;

    function changeVotesPerCitizen(uint256 amount) external;

    function addCities(uint256 regionId, NewCity[] calldata newCities) external;

    function changeCityVotePrice(uint256 cityId, uint256 newPrice) external;

    function addBuilding(
        uint256 cityId,
        Building newBuilding
    ) external;

    function nominate(
        uint256 mayorId,
        uint256 cityId,
        uint256 votes
    ) external;

    function updateCities(uint256[] calldata citiesIds, bool isOpen) external;

    function claimPrizes(ClaimInfo[] calldata claimInfos) external;

    function getCurrentSeason(uint256 cityId) external view returns (uint256);
    function getWinner(uint256 cityId, uint256 season) external view returns(uint256);

    function getUnclaimedSeasons(
        address account,
        uint256 cityId,
        uint256 startSeason,
        uint256 endSeason,
        uint256 currentSeason
    ) external view returns (bool[] memory);

    function getUnclaimedBuildings(
        address account,
        uint256 cityId,
        uint256 currentSeason
    ) external view returns (bool[] memory);

    function calculatePrizes(
        address account,
        uint256 cityId,
        uint256[] calldata seasonIds,
        uint256 currentSeason
    ) external view returns (uint256);

    function calculateVotesPrice(
        uint256 mayorId,
        uint256 cityId,
        uint256 votes
    ) external view returns(uint256);
}

// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
library VotingConstants {
    uint8 internal constant BUILDING_DISCOUNT_UNIVERSITY = 7;
    uint8 internal constant BUILDING_DISCOUNT_HOSPITAL = 5;

    uint8 internal constant BUILDING_ACTIVATION_DELAY = 4;

    uint8 internal constant GOVERNANCE_RATE_BANK = 7;
    uint8 internal constant GOVERNANCE_RATE_FACTORY = 5;
    uint8 internal constant GOVERNANCE_RATE_STADIUM = 2;
    uint8 internal constant GOVERNANCE_RATE_MONUMENT = 1;

    uint256 internal constant UNIVERSITY_PRICE = 40000;
    uint256 internal constant HOSPITAL_PRICE = 30000;
    uint256 internal constant BANK_PRICE = 30000;
    uint256 internal constant FACTORY_PRICE = 20000;
    uint256 internal constant STADIUM_PRICE = 8000;
    uint256 internal constant MONUMENT_PRICE = 30000;
}

// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
library VotingErrors {
    error Overflow();
    error EmptyArray();
    error WrongMayor();
    error InsufficientBalance();
    error BuildingDuplicate();
    error InactiveObject();
    error VotesBankExceeded();
    error IncorrectPeriod();
    error IncorrectValue();
    error NotWinner();
    error UnknownCity();
    error NothingToClaim();
}

// Copyright © 2021 Anton "BaldyAsh" Grigorev. All rights reserved.
contract Voting is IVoting, Ownable {
    uint256 internal constant VOTING_DURATION = 1 minutes;
    uint256 internal constant GOVERNANCE_DURATION = 6 minutes;

    uint256 internal constant PRIZE_RATE = 87;
    uint256 internal constant REWARD_BURN_RATE = 3;

    uint8 internal constant CLAIMABLE_BUILDING_LENGTH = 4;

    NFT internal _mayor;
    Vote internal _voteToken;
    Voucher internal _voucherToken;

    // amount of votes for 1 citizen, 4 digits
    uint8 internal _voteDigits;
    uint256 internal _votesPerCitizen;

    // city id => City
    mapping(uint256 => City) internal _cities;
    // region id => Region
    mapping(uint256 => Region) internal _regions;
    // regionId => [city id]
    mapping(uint256 => uint256[]) internal _regionToCities;

    // owner address => city id => BuildingInfo
    mapping(address => mapping(uint256 => BuildingInfo[])) internal _ownerToBuildings;

    // owner address => city id => building => prize is claimed
    mapping(address => mapping(uint256 => mapping(Building => bool))) internal _ownerBuildingClaimed;
    // owner address => city id => season => prize is claimed
    mapping(address => mapping(uint256 => mapping(uint256 => bool))) internal _ownerElectionClaimed;

    // city id => season id => Nominee[]
    mapping(uint256 => mapping(uint256 => Nominee[])) internal _cityToNominees;

    uint256 internal _cityIdCounter = 0;

    constructor(
        NFT mayorNFT,
        Vote voteToken_,
        Voucher voucherToken_,
        uint256 votesPerCitizen_,
        address owner
    ) {
        _mayor = mayorNFT;
        _voteToken = voteToken_;
        _voucherToken = voucherToken_;
        _votesPerCitizen = votesPerCitizen_;
        _owner = owner;
        _voteDigits = _voteToken.decimals();
    }

    /// @notice Transfer BVoucher and 30% of Votes tokens from the contract to the owner
    function transferTokens() external override isOwner {
        uint256 voteBalance = _voteToken.balanceOf(address(this)) * 30 / 100;
        uint256 voucherBalance = _voucherToken.balanceOf(address(this));
        _voteToken.transfer(msg.sender, voteBalance);
        _voucherToken.transfer(msg.sender, voucherBalance);
    }

    function changeVotesPerCitizen(uint256 amount) external override isOwner {
        if (amount == 0) revert VotingErrors.IncorrectValue();
        uint256 oldAmount = _votesPerCitizen;
        _votesPerCitizen = amount;

        emit VotesPerCitizenUpdated(oldAmount, amount);
    }

    function addCities(uint256 regionId, NewCity[] calldata newCities) external override isOwner {
        if(newCities.length <= 0) revert VotingErrors.EmptyArray();
        uint256[] memory cityIds = new uint256[](newCities.length);

        for (uint256 i = 0; i < newCities.length; i++) {
            NewCity memory newCity = newCities[i];
            if (newCity.population == 0) revert VotingErrors.IncorrectValue();
            City memory city = City({
                regionId: regionId,
                name: newCity.name,
                population: newCity.population,
                votePrice: newCity.votePrice,
                active: true
            });
            _cities[_cityIdCounter] = city;
            _regionToCities[regionId].push(_cityIdCounter);
            cityIds[i] = _cityIdCounter;
            _cityIdCounter++;
        }
        emit CitiesAdded(regionId, cityIds);
        _startVoting(regionId);
    }

    function changeCityVotePrice(uint256 cityId, uint256 newPrice) external override isOwner {
        City storage city = _cities[cityId];
        if (!_verifyCityExists(city)) revert VotingErrors.UnknownCity();
        if (_isVotingPeriod(city.regionId)) revert VotingErrors.IncorrectPeriod();
        if (newPrice == 0) revert VotingErrors.IncorrectValue();

        uint256 oldPrice = city.votePrice;
        city.votePrice = newPrice;
        emit VotePriceUpdated(cityId, oldPrice, newPrice);
    }

    function addBuilding(
        uint256 cityId,
        Building newBuilding
    ) external override {
        City storage city = _cities[cityId];
        if (!_verifyCityExists(city)) revert VotingErrors.UnknownCity();
        if (!_isGoverningPeriod(city.regionId)) revert VotingErrors.IncorrectPeriod();
        if (newBuilding == Building.Empty) revert  VotingErrors.IncorrectValue();

        uint256 season = _seasonNumber(city.regionId);
        if (!_isWinner(msg.sender, cityId, season)) revert VotingErrors.NotWinner();

        uint256 buildingPrice = _getBuildingPrice(newBuilding);
        if (_getBuildingSeason(msg.sender, cityId, newBuilding) > 0) revert VotingErrors.BuildingDuplicate();
        _ownerToBuildings[msg.sender][cityId].push(BuildingInfo({building: newBuilding, season: season}));

        emit BuildingAdded(msg.sender, cityId, season, newBuilding);
        _voucherToken.transferFrom(msg.sender, address(this), buildingPrice);
    }

    function nominate(
        uint256 mayorId,
        uint256 cityId,
        uint256 votes
    ) external override {
        City storage city = _cities[cityId];
        if (!_verifyCityExists(city)) revert VotingErrors.UnknownCity();
        if (!city.active) revert VotingErrors.InactiveObject();
        if (!_isVotingPeriod(city.regionId)) revert VotingErrors.IncorrectPeriod();
        if (_mayor.ownerOf(mayorId) != msg.sender) revert VotingErrors.WrongMayor();

        uint256 seasonNumber = _seasonNumber(city.regionId);
        uint256 citizenVotes = city.population * _votesPerCitizen / 10 ** _voteDigits;
        if (votes > (citizenVotes - _getBank(cityId, seasonNumber))) revert VotingErrors.VotesBankExceeded();

        // get the price of those votes
        uint256 priceInVotes = _calculateVotesPrice(mayorId, cityId, votes);

        // save user vote info
        _cityToNominees[cityId][seasonNumber].push(Nominee({ mayorId: mayorId, votes: votes }));
        emit CandidateAdded(mayorId, cityId, votes);

        // transfer the "votes" amount from user to reward pool
        _voteToken.transferFrom(msg.sender, address(this), priceInVotes);
    }

    function updateCities(uint256[] calldata citiesIds, bool isOpen) external override isOwner {
        for(uint256 i = 0; i < citiesIds.length; i++) {
            uint256 cityId = citiesIds[i];
            if (_isVotingPeriod(_cities[cityId].regionId)) revert VotingErrors.IncorrectPeriod();
            _cities[cityId].active = isOpen;
            emit CityUpdated(cityId, isOpen);
        }
    }

    function claimPrizes(ClaimInfo[] calldata claimInfos) external override {
        uint256 totalPrize = 0;
        uint256 totalBurn = 0;

        uint256 claimInfosLength = claimInfos.length;
        for (uint256 i = 0; i < claimInfosLength; i++) {
            ClaimInfo memory claimInfo = claimInfos[i];

            if (!_verifyCityExists(_cities[claimInfo.cityId])) revert VotingErrors.UnknownCity();
            uint256 currentSeason = _seasonNumber(_cities[claimInfo.cityId].regionId);

            (uint256 prize, uint256 burnPrize) = _claimElectionPrizes(
                msg.sender, claimInfo.cityId, claimInfo.seasonIds, currentSeason);
            prize += _claimBuildingPrizes(
                msg.sender, claimInfo.cityId, currentSeason);

            totalPrize += prize;
            totalBurn += burnPrize;
            emit PrizeClaimed(msg.sender, claimInfo.cityId, prize, burnPrize);
        }

        if (totalPrize == 0) revert VotingErrors.NothingToClaim();

        // send tokens to the winner
        _voteToken.transfer(msg.sender, totalPrize);

        // 3% needs to be burned
        _voteToken.burn(address(this), totalBurn);
    }

    function getCurrentSeason(uint256 cityId) external view override returns (uint256) {
        return _seasonNumber(_cities[cityId].regionId);
    }

    function getWinner(uint256 cityId, uint256 season) external view override returns(uint256) {
        uint256 bank = _getBank(cityId, season);
        if (bank == 0) revert VotingErrors.IncorrectValue();
        return _calculateWinner(season, cityId, bank);
    }

    function getUnclaimedSeasons(
        address account,
        uint256 cityId,
        uint256 startSeason,
        uint256 endSeason,
        uint256 currentSeason
    ) external view override returns (bool[] memory) {
        if (startSeason == 0 || startSeason > endSeason) revert VotingErrors.IncorrectValue();

        bool[] memory unclaimedSeasons = new bool[](endSeason - (startSeason-1));
        for (uint256 i = (startSeason-1); i < endSeason; i++) {
            uint256 season = i+1;
            if (!_verifySeasonClaim(account, cityId, season, currentSeason)) continue;
            unclaimedSeasons[i] = !_ownerElectionClaimed[account][cityId][season];
        }
        return unclaimedSeasons;
    }

    function getUnclaimedBuildings(
        address account,
        uint256 cityId,
        uint256 currentSeason
    ) external view override returns (bool[] memory) {
        bool[] memory unclaimedBuildings = new bool[](CLAIMABLE_BUILDING_LENGTH);
        for (uint8 i = 0; i < CLAIMABLE_BUILDING_LENGTH; i++) {
            Building building = _getClaimableBuilding(i);
            uint256 season = _getBuildingSeason(account, cityId, building);
            if (!_isBuildingRewardPeriod(season, currentSeason, building)) continue;
            if (!_verifyBuildingClaim(account, cityId, season, currentSeason, building)) continue;
            unclaimedBuildings[i] = !_ownerBuildingClaimed[account][cityId][building];
        }
        return unclaimedBuildings;
    }

    function calculatePrizes(
        address account,
        uint256 cityId,
        uint256[] calldata seasonIds,
        uint256 currentSeason
    ) external view override returns(uint256) {
        return (
            _calculateElectionPrizes(account, cityId, seasonIds, currentSeason) +
            _calculateBuildingPrizes(account, cityId, currentSeason)
        );
    }

    function calculateVotesPrice(
        uint256 mayorId,
        uint256 cityId,
        uint256 votes
    ) external view override returns(uint256) {
        City storage city = _cities[cityId];
        if (!_verifyCityExists(city)) revert VotingErrors.UnknownCity();
        return _calculateVotesPrice(mayorId, cityId, votes);
    }

    function _claimElectionPrizes(
        address account,
        uint256 cityId,
        uint256[] memory seasonIds,
        uint256 currentSeason
    ) internal returns (uint256, uint256){
        uint256 totalPrize = 0;
        uint256 totalBurn = 0;

        uint256 seasonsLength = seasonIds.length;
        for (uint256 i = 0; i < seasonsLength; i++) {
            uint256 season = seasonIds[i];

            // verification
            if (!_verifySeasonClaim(account, cityId, season, currentSeason))
                revert VotingErrors.IncorrectValue();

            // claim
            _ownerElectionClaimed[account][cityId][season] = true;

            // calculate prizes
            uint256 bank = _getBank(cityId, seasonIds[i]);
            totalPrize += _calculateElectionPrize(bank);
            totalBurn += _calculatePrizeToBurn(bank);
        }

        return (totalPrize, totalBurn);
    }

    function _claimBuildingPrizes(
        address account,
        uint256 cityId,
        uint256 currentSeason
    ) internal returns (uint256){
        uint256 totalPrize = 0;
        for (uint8 i = 0; i < CLAIMABLE_BUILDING_LENGTH; i++) {
            Building building = _getClaimableBuilding(i);
            uint256 season = _getBuildingSeason(account, cityId, building);
            if (!_isBuildingRewardPeriod(season, currentSeason, building)) continue;

            // verification
            if (!_verifyBuildingClaim(account, cityId, season, currentSeason, building))
                revert VotingErrors.IncorrectValue();

            // claim
            _ownerBuildingClaimed[account][cityId][building] = true;

            // calculate prizes
            uint256 bank = _getBuildingBank(cityId, season, currentSeason, building);
            totalPrize += _calculateBuildingPrize(bank, building);
        }

        return totalPrize;
    }

    function _startVoting(uint256 regionId) internal {
        // solhint-disable-next-line not-rely-on-time
        uint256 currentTimestamp = block.timestamp;
        if (_regions[regionId].startVotingTimestamp == 0) {
            _regions[regionId] = Region({active: true, startVotingTimestamp: currentTimestamp});
            emit VotingStarted(regionId, currentTimestamp);
        }
    }

    function _verifyCityExists(City storage city) internal view returns (bool) {
        return city.population != 0;
    }

    function _verifySeasonClaim(
        address account,
        uint256 cityId,
        uint256 season,
        uint256 currentSeason
    ) internal view returns(bool) {
        return (
            _isRewardPeriod(season, currentSeason) &&
            _isWinner(account, cityId, season) &&
            !_ownerElectionClaimed[account][cityId][season]
        );
    }

    function _verifyBuildingClaim(
        address account,
        uint256 cityId,
        uint256 season,
        uint256 currentSeason,
        Building building
    ) internal view returns(bool) {
        return (
            _isRewardPeriod(season, currentSeason) &&
            _isWinner(account, cityId, season) &&
            !_ownerBuildingClaimed[account][cityId][building]
        );
    }

    function _seasonNumber(uint256 regionId) internal view returns(uint256) {
        // solhint-disable-next-line not-rely-on-time
        return ((block.timestamp - _regions[
            regionId].startVotingTimestamp) /
            (VOTING_DURATION + GOVERNANCE_DURATION)) + 1;
    }

    function _isVotingPeriod(uint256 regionId) internal view returns(bool) {
        // solhint-disable-next-line not-rely-on-time
        return ((block.timestamp - _regions[regionId].startVotingTimestamp) %
            (VOTING_DURATION + GOVERNANCE_DURATION)) < VOTING_DURATION;
    }

    function _isGoverningPeriod(uint256 regionId) internal view returns(bool) {
        // solhint-disable-next-line not-rely-on-time
        return ((block.timestamp - _regions[regionId].startVotingTimestamp) %
            (VOTING_DURATION + GOVERNANCE_DURATION)) > VOTING_DURATION;
    }

    function _calculateVotesPrice(
        uint256 mayorId,
        uint256 cityId,
        uint256 votes
    ) internal view returns(uint256) {
        return (votes * _cities[cityId].votePrice * _getVoteMultiplier(mayorId, cityId, msg.sender)) / 100;
    }

    function _getBuildingsDiscount(uint256 cityId, address account) internal view returns(uint256) {
        if (_getBuildingSeason(account, cityId, Building.University) > 0) {
            return VotingConstants.BUILDING_DISCOUNT_UNIVERSITY;
        } else if (_getBuildingSeason(account, cityId, Building.Hospital) > 0) {
            return VotingConstants.BUILDING_DISCOUNT_HOSPITAL;
        } else {
            return 0;
        }
    }

    function _getBuildingSeason(
        address account,
        uint256 cityId,
        Building building
    ) internal view returns(uint256) {
        BuildingInfo[] storage infos = _ownerToBuildings[account][cityId];
        uint256 infosLength = infos.length;
        for (uint256 i = 0; i < infosLength; i++) {
            if (infos[i].building == building) {
                return infos[i].season;
            }
        }
        return 0;
    }

    function _getVoteMultiplier(
        uint256 nftId,
        uint256 cityId,
        address account
    ) internal view returns(uint256) {
        return 100 - _mayor.getVoteDiscount(nftId) - _getBuildingsDiscount(cityId, account);
    }

    function _isWinner(
        address account,
        uint256 cityId,
        uint256 season
    ) internal view  returns (bool) {
        uint256 bank = _getBank(cityId, season);
        return (
            bank != 0 &&
            _mayor.ownerOf(_calculateWinner(season, cityId, bank)) == account
        );
    }

    function _calculateWinner(
        uint256 season,
        uint256 cityId,
        uint256 bank
    ) internal view returns(uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(season, cityId)));
        uint256 winnerRate = random % bank;
        uint256 votesCounter = 0;

        Nominee[] storage nominees = _cityToNominees[cityId][season];
        uint256 nomineesLength = nominees.length;
        uint256 randomIndex = random % nomineesLength;
        for (uint256 i = randomIndex; i < nomineesLength; i++) {
            votesCounter += nominees[i].votes;
            if (winnerRate < votesCounter) return nominees[i].mayorId;
        }
        for (uint256 i = 0; i < randomIndex; i++) {
            votesCounter += nominees[i].votes;
            if (winnerRate < votesCounter) return nominees[i].mayorId;
        }

        // it will never be reached
        return nominees[nomineesLength - 1].mayorId;
    }

    function _calculateElectionPrizes(
        address account,
        uint256 cityId,
        uint256[] calldata seasonIds,
        uint256 currentSeason
    ) internal view returns(uint256) {
        uint256 totalPrize = 0;
        uint256 seasonsLength = seasonIds.length;
        for (uint256 i = 0; i < seasonsLength; i++) {
            if (!_verifySeasonClaim(account, cityId, seasonIds[i], currentSeason)) continue;
            uint256 bank = _getBank(cityId, seasonIds[i]);
            totalPrize += _calculateElectionPrize(bank);
        }
        return totalPrize;
    }

    function _calculateBuildingPrizes(
        address account,
        uint256 cityId,
        uint256 currentSeason
    ) internal view returns(uint256) {
        uint256 totalPrize = 0;
        for (uint8 i = 0; i < CLAIMABLE_BUILDING_LENGTH; i++) {
            Building building = _getClaimableBuilding(i);
            uint256 season = _getBuildingSeason(account, cityId, building);
            if (!_isBuildingRewardPeriod(season, currentSeason, building)) continue;
            if (!_verifyBuildingClaim(account, cityId, season, currentSeason, building)) continue;
            uint256 bank = _getBuildingBank(cityId, season, currentSeason, building);
            totalPrize += _calculateBuildingPrize(bank, building);
        }
        return totalPrize;
    }

    function _getBank(
        uint256 cityId,
        uint256 season
    ) internal view returns (uint256) {
        uint256 bank = 0;

        Nominee[] storage nominees = _cityToNominees[cityId][season];
        uint256 nomineesLength = nominees.length;
        for (uint256 i = 0; i < nomineesLength; i++) {
            bank += nominees[i].votes;
        }
        return bank;
    }

    function _getBuildingBank(
        uint256 cityId,
        uint256 season,
        uint256 currentSeason,
        Building building
    ) internal view returns (uint256) {
        if (building != Building.Monument) {
            return _getBank(cityId, season);
        }
        if (season + VotingConstants.BUILDING_ACTIVATION_DELAY <= currentSeason) {
            return (
                _getBank(cityId, season) +
                _getBank(cityId, season + 1) +
                _getBank(cityId, season + 2) +
                _getBank(cityId, season + 3)
            );
        }
        return 0;
    }

    function _calculateElectionPrize(uint256 bank) internal pure returns (uint256) {
        return bank * PRIZE_RATE / 100;
    }

    function _calculatePrizeToBurn(uint256 bank) internal pure returns (uint256) {
        return bank * REWARD_BURN_RATE / 100;
    }

    function _calculateBuildingPrize(
        uint256 bank,
        Building building
    ) internal pure returns (uint256) {
        return bank * _getBuildingRate(building) / 100;
    }

    function _getClaimableBuilding(uint8 index) internal pure returns(Building) {
        if (index == 0) return Building.Bank;
        if (index == 1) return Building.Factory;
        if (index == 2) return Building.Stadium;
        if (index == 3) return Building.Monument;
        return Building.Empty;
    }

    function _getBuildingRate(Building building) internal pure returns(uint8) {
        if (building == Building.Bank) {
            return VotingConstants.GOVERNANCE_RATE_BANK;
        } else if (building == Building.Factory) {
            return VotingConstants.GOVERNANCE_RATE_FACTORY;
        } else if (building == Building.Stadium) {
            return VotingConstants.GOVERNANCE_RATE_STADIUM;
        } else if (building == Building.Monument) {
            return VotingConstants.GOVERNANCE_RATE_MONUMENT;
        } else {
            return 0;
        }
    }

    function _getBuildingPrice(Building building) internal pure returns(uint256) {
        if (building == Building.University) {
            return VotingConstants.UNIVERSITY_PRICE;
        } else if (building == Building.Hospital) {
            return VotingConstants.HOSPITAL_PRICE;
        } else if (building == Building.Bank) {
            return VotingConstants.BANK_PRICE;
        } else if (building == Building.Factory) {
            return VotingConstants.FACTORY_PRICE;
        } else if (building == Building.Stadium) {
            return VotingConstants.STADIUM_PRICE;
        } else {
            return VotingConstants.MONUMENT_PRICE;
        }
    }

    function _isRewardPeriod(uint256 season, uint256 currentSeason) internal pure returns(bool) {
        return season != 0 && season < currentSeason;
    }

    function _isBuildingRewardPeriod(
        uint256 season,
        uint256 currentSeason,
        Building building
    ) internal pure returns(bool) {
        return season != 0  && (
            building != Building.Monument ||
            season + VotingConstants.BUILDING_ACTIVATION_DELAY <= currentSeason
        );
    }

}