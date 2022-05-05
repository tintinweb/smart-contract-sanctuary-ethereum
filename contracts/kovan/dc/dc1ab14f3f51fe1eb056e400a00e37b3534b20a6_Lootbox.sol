/**
 *Submitted for verification at Etherscan.io on 2022-05-04
*/

// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;


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