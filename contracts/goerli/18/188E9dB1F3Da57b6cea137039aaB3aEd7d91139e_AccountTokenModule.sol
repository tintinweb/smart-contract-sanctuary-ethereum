//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library AccessError {
    error Unauthorized(address addr);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library AddressError {
    error ZeroAddress();
    error NotAContract(address contr);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library InitError {
    error AlreadyInitialized();
    error NotInitialized();
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library ParameterError {
    /**
     * @notice Thrown when an invalid parameter is used in a function.
     */
    error InvalidParameter(string parameter, string reason);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../errors/InitError.sol";

abstract contract InitializableMixin {
    modifier onlyIfInitialized() {
        if (!_isInitialized()) {
            revert InitError.NotInitialized();
        }

        _;
    }

    modifier onlyIfNotInitialized() {
        if (_isInitialized()) {
            revert InitError.AlreadyInitialized();
        }

        _;
    }

    function _isInitialized() internal view virtual returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 {
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
    function setApprovalForAll(address operator, bool approved) external;

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC165.sol";

interface IERC721Metadata is IERC165 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) external returns (bytes4);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../errors/AccessError.sol";

library OwnableStorage {
    struct Data {
        bool initialized;
        address owner;
        address nominatedOwner;
    }

    function load() internal pure returns (Data storage store) {
        bytes32 s = keccak256(abi.encode("Ownable"));
        assembly {
            store.slot := s
        }
    }

    function onlyOwner() internal view {
        if (msg.sender != getOwner()) {
            revert AccessError.Unauthorized(msg.sender);
        }
    }

    function getOwner() internal view returns (address) {
        return OwnableStorage.load().owner;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IERC721.sol";
import "../interfaces/IERC721Metadata.sol";
import "../interfaces/IERC721Receiver.sol";
import "../errors/AddressError.sol";
import "../errors/AccessError.sol";
import "../errors/InitError.sol";
import "../errors/ParameterError.sol";
import "./ERC721Storage.sol";
import "../utils/AddressUtil.sol";
import "../utils/StringUtil.sol";

/*
    Reference implementations:
    * OpenZeppelin - https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol
*/

contract ERC721 is IERC721, IERC721Metadata {
    error CannotSelfApprove(address);
    error InvalidTransferRecipient(address);
    error TokenDoesNotExist(uint256);
    error TokenAlreadyMinted(uint256);

    function _initialize(
        string memory tokenName,
        string memory tokenSymbol,
        string memory baseTokenURI
    ) internal virtual {
        ERC721Storage.Data storage store = ERC721Storage.load();
        if (bytes(store.name).length > 0 || bytes(store.symbol).length > 0 || bytes(store.baseTokenURI).length > 0) {
            revert InitError.AlreadyInitialized();
        }

        if (bytes(tokenName).length == 0 || bytes(tokenSymbol).length == 0) {
            revert ParameterError.InvalidParameter("name/symbol", "must not be empty");
        }

        store.name = tokenName;
        store.symbol = tokenSymbol;
        store.baseTokenURI = baseTokenURI;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == this.supportsInterface.selector || // ERC165
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId;
    }

    function balanceOf(address holder) public view virtual override returns (uint) {
        if (holder == address(0)) {
            return 0;
        }

        return ERC721Storage.load().balanceOf[holder];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        if (!_exists(tokenId)) {
            return address(0);
        }

        return ERC721Storage.load().ownerOf[tokenId];
    }

    function name() external view virtual override returns (string memory) {
        return ERC721Storage.load().name;
    }

    function symbol() external view virtual override returns (string memory) {
        return ERC721Storage.load().symbol;
    }

    function tokenURI(uint256 tokenId) external view virtual override returns (string memory) {
        if (!_exists(tokenId)) {
            return "";
        }

        string memory baseURI = ERC721Storage.load().baseTokenURI;

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, StringUtil.uintToString(tokenId))) : "";
    }

    function approve(address to, uint256 tokenId) public virtual override {
        ERC721Storage.Data storage store = ERC721Storage.load();
        address holder = store.ownerOf[tokenId];

        if (to == holder) {
            revert CannotSelfApprove(to);
        }

        if (msg.sender != holder && !isApprovedForAll(holder, msg.sender)) {
            revert AccessError.Unauthorized(msg.sender);
        }

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        if (!_exists(tokenId)) {
            revert TokenDoesNotExist(tokenId);
        }

        return ERC721Storage.load().tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (msg.sender == operator) {
            revert CannotSelfApprove(operator);
        }

        ERC721Storage.load().operatorApprovals[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address holder, address operator) public view virtual override returns (bool) {
        return ERC721Storage.load().operatorApprovals[holder][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert AccessError.Unauthorized(msg.sender);
        }

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert AccessError.Unauthorized(msg.sender);
        }

        _transfer(from, to, tokenId);
        if (!_checkOnERC721Received(from, to, tokenId, data)) {
            revert InvalidTransferRecipient(to);
        }
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return ERC721Storage.load().ownerOf[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address holder = ownerOf(tokenId);

        // Not checking tokenId existence since it is checked in ownerOf() and getApproved()

        return (spender == holder || getApproved(tokenId) == spender || isApprovedForAll(holder, spender));
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        ERC721Storage.Data storage store = ERC721Storage.load();
        if (to == address(0)) {
            revert AddressError.ZeroAddress();
        }

        if (tokenId == 0) {
            revert ParameterError.InvalidParameter("tokenId", "cannot be zero");
        }

        if (_exists(tokenId)) {
            revert TokenAlreadyMinted(tokenId);
        }

        _beforeTransfer(address(0), to, tokenId);

        store.balanceOf[to] += 1;
        store.ownerOf[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        ERC721Storage.Data storage store = ERC721Storage.load();
        address holder = store.ownerOf[tokenId];

        _beforeTransfer(holder, address(0), tokenId);

        _approve(address(0), tokenId);

        store.balanceOf[holder] -= 1;
        delete store.ownerOf[tokenId];

        emit Transfer(holder, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        ERC721Storage.Data storage store = ERC721Storage.load();

        if (ownerOf(tokenId) != from) {
            revert AccessError.Unauthorized(from);
        }

        if (to == address(0)) {
            revert AddressError.ZeroAddress();
        }

        _beforeTransfer(from, to, tokenId);

        // Clear approvals from the previous holder
        _approve(address(0), tokenId);

        store.balanceOf[from] -= 1;
        store.balanceOf[to] += 1;
        store.ownerOf[tokenId] = to;

        _postTransfer(from, to, tokenId);

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        ERC721Storage.load().tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal returns (bool) {
        if (AddressUtil.isContract(to)) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch {
                return false;
            }
        } else {
            return true;
        }
    }

    function _beforeTransfer(
        address from,
        address to,
        uint256 tokenId // solhint-disable-next-line no-empty-blocks
    ) internal virtual {}

    function _postTransfer(
        address from,
        address to,
        uint256 tokenId // solhint-disable-next-line no-empty-blocks
    ) internal virtual {}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721EnumerableStorage.sol";
import "../interfaces/IERC721Enumerable.sol";

/*
    Reference implementations:
    * OpenZeppelin - https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/ERC721EnumerableStorage.sol
*/

abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    error IndexOutOfBounds();

    function _initialize(
        string memory tokenName,
        string memory tokenSymbol,
        string memory baseTokenURI
    ) internal virtual override {
        super._initialize(tokenName, tokenSymbol, baseTokenURI);
        if (ERC721EnumerableStorage.load().allTokens.length > 0) {
            revert InitError.AlreadyInitialized();
        }
    }

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        if (ERC721.balanceOf(owner) <= index) {
            return 0;
        }
        return ERC721EnumerableStorage.load().ownedTokens[owner][index];
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return ERC721EnumerableStorage.load().allTokens.length;
    }

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        if (index >= ERC721Enumerable.totalSupply()) {
            return 0;
        }
        return ERC721EnumerableStorage.load().allTokens[index];
    }

    function _beforeTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        ERC721EnumerableStorage.load().ownedTokens[to][length] = tokenId;
        ERC721EnumerableStorage.load().ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        ERC721EnumerableStorage.load().allTokensIndex[tokenId] = ERC721EnumerableStorage.load().allTokens.length;
        ERC721EnumerableStorage.load().allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = ERC721EnumerableStorage.load().ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = ERC721EnumerableStorage.load().ownedTokens[from][lastTokenIndex];

            ERC721EnumerableStorage.load().ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            ERC721EnumerableStorage.load().ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete ERC721EnumerableStorage.load().ownedTokensIndex[tokenId];
        delete ERC721EnumerableStorage.load().ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721EnumerableStorage.load().allTokens.length - 1;
        uint256 tokenIndex = ERC721EnumerableStorage.load().allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = ERC721EnumerableStorage.load().allTokens[lastTokenIndex];

        ERC721EnumerableStorage.load().allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        ERC721EnumerableStorage.load().allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete ERC721EnumerableStorage.load().allTokensIndex[tokenId];
        ERC721EnumerableStorage.load().allTokens.pop();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library ERC721EnumerableStorage {
    struct Data {
        mapping(uint256 => uint256) ownedTokensIndex;
        mapping(uint256 => uint256) allTokensIndex;
        mapping(address => mapping(uint256 => uint256)) ownedTokens;
        uint256[] allTokens;
    }

    function load() internal pure returns (Data storage store) {
        bytes32 s = keccak256(abi.encode("ERC721Enumerable"));
        assembly {
            store.slot := s
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library ERC721Storage {
    struct Data {
        string name;
        string symbol;
        string baseTokenURI;
        mapping(uint256 => address) ownerOf;
        mapping(address => uint256) balanceOf;
        mapping(uint256 => address) tokenApprovals;
        mapping(address => mapping(address => bool)) operatorApprovals;
    }

    function load() internal pure returns (Data storage store) {
        bytes32 s = keccak256(abi.encode("ERC721"));
        assembly {
            store.slot := s
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library AddressUtil {
    function isContract(address account) internal view returns (bool) {
        uint256 size;

        assembly {
            size := extcodesize(account)
        }

        return size > 0;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeCast/SafeCastI128.sol";
import "./SafeCast/SafeCastI256.sol";
import "./SafeCast/SafeCastU128.sol";
import "./SafeCast/SafeCastU256.sol";

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Utility that avoids silent overflow errors.
 *
 */
library SafeCastI128 {
    error OverflowInt128ToUint128();

    function toUint(int128 x) internal pure returns (uint128) {
        // ----------------<==============o==============>-----------------
        // ----------------xxxxxxxxxxxxxxxo===============>----------------
        if (x < 0) {
            revert OverflowInt128ToUint128();
        }

        return uint128(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Utility that avoids silent overflow errors.
 *
 */
library SafeCastI256 {
    error OverflowInt256ToUint256();
    error OverflowInt256ToInt128();

    function to128(int256 x) internal pure returns (int128) {
        // ----<==========================o===========================>----
        // ----xxxxxxxxxxxx<==============o==============>xxxxxxxxxxxxx----
        if (x < int256(type(int128).min) || x > int256(type(int128).max)) {
            revert OverflowInt256ToInt128();
        }

        return int128(x);
    }

    function toUint(int256 x) internal pure returns (uint256) {
        // ----<==========================o===========================>----
        // ----xxxxxxxxxxxxxxxxxxxxxxxxxxxo===============================>
        if (x < 0) {
            revert OverflowInt256ToUint256();
        }

        return uint256(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Utility that avoids silent overflow errors.
 *
 */
library SafeCastU128 {
    error OverflowUint128ToInt128();

    function toInt(uint128 x) internal pure returns (int128) {
        // -------------------------------o===============>----------------
        // ----------------<==============o==============>x----------------
        if (x > uint128(type(int128).max)) {
            revert OverflowUint128ToInt128();
        }

        return int128(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Utility that avoids silent overflow errors.
 *
 */
library SafeCastU256 {
    error OverflowUint256ToUint128();
    error OverflowUint256ToInt256();

    // Note: Overloading doesn't seem to work for similar types, i.e. int256 and int128, uint256 and uint128, etc, so explicitly naming the functions differently here.

    function to128(uint256 x) internal pure returns (uint128) {
        // -------------------------------o===============================>
        // -------------------------------o===============>xxxxxxxxxxxxxxxx
        if (x > type(uint128).max) {
            revert OverflowUint256ToUint128();
        }

        return uint128(x);
    }

    function toInt(uint256 x) internal pure returns (int256) {
        // -------------------------------o===============================>
        // ----<==========================o===========================>xxxx
        if (x > uint256(type(int256).max)) {
            revert OverflowUint256ToInt256();
        }

        return int256(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
    Reference implementations:
    * OpenZeppelin - https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol
*/

library StringUtil {
    function uintToString(uint value) internal pure returns (string memory) {
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@synthetixio/core-contracts/contracts/interfaces/IERC721Enumerable.sol";

/// @title NFT token identifying an Account
interface INftModule is IERC721Enumerable {
    /// @notice Returns if `initialize` has been called by the owner
    function isInitialized() external returns (bool);

    /// @notice Allows owner to initialize the token after attaching a proxy
    function initialize(
        string memory tokenName,
        string memory tokenSymbol,
        string memory uri
    ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@synthetixio/core-contracts/contracts/token/ERC721Enumerable.sol";
import "@synthetixio/core-contracts/contracts/utils/AddressUtil.sol";
import "@synthetixio/core-contracts/contracts/initializable/InitializableMixin.sol";
import "@synthetixio/core-contracts/contracts/ownership/OwnableStorage.sol";
import "@synthetixio/core-contracts/contracts/errors/AddressError.sol";

import "../storage/Initialized.sol";

import "../interfaces/INftModule.sol";

contract NftModule is INftModule, ERC721Enumerable, InitializableMixin {
    bytes32 internal constant _INITIALIZED_NAME = "NftModule";

    function _isInitialized() internal view override returns (bool) {
        return Initialized.load(_INITIALIZED_NAME).initialized;
    }

    function isInitialized() external view returns (bool) {
        return _isInitialized();
    }

    function initialize(
        string memory tokenName,
        string memory tokenSymbol,
        string memory uri
    ) public {
        OwnableStorage.onlyOwner();

        _initialize(tokenName, tokenSymbol, uri);
        Initialized.load(_INITIALIZED_NAME).initialized = true;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Initialized {
    struct Data {
        bool initialized;
    }

    function load(bytes32 id) internal pure returns (Data storage store) {
        bytes32 s = keccak256(abi.encode("Initialized", id));
        assembly {
            store.slot := s
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Module for managing accounts.
 * @notice Manages the system's account token NFT. Every user will need to register an account before being able to interact with the system.
 */
interface IAccountModule {
    /**
     * @notice Emitted when an account token with id `accountId` is minted to `sender`.
     */
    event AccountCreated(address indexed sender, uint128 indexed accountId);

    /**
     * @notice Emitted when `user` is granted `permission` by `sender` for account `accountId`.
     */
    event PermissionGranted(uint128 indexed accountId, bytes32 indexed permission, address indexed user, address sender);

    /**
     * @notice Emitted when `user` has `permission` renounced or revoked by `sender` for account `accountId`.
     */
    event PermissionRevoked(uint128 indexed accountId, bytes32 indexed permission, address indexed user, address sender);

    /**
     * @dev Data structure for tracking each user's permissions.
     */
    struct AccountPermissions {
        address user;
        bytes32[] permissions;
    }

    /**
     * @notice Returns an array of `AccountPermission` for the provided `accountId`.
     */
    function getAccountPermissions(uint128 accountId) external view returns (AccountPermissions[] memory);

    /**
     * @notice Mints an account token with id `requestedAccountId` to `msg.sender`.
     *
     * Requirements:
     *
     * - `requestedAccountId` must not already be minted.
     *
     * Emits a {AccountCreated} event.
     */
    function createAccount(uint128 requestedAccountId) external;

    /**
     * @notice Called by AccountTokenModule to notify the system when the account token is transferred.
     * @dev Resets user permissions and assigns ownership of the account token to the new holder.
     *
     * Requirements:
     *
     * - `msg.sender` must be the account token.
     */
    function notifyAccountTransfer(address to, uint128 accountId) external;

    /**
     * @notice Grants `permission` to `user` for account `accountId`.
     *
     * Requirements:
     *
     * - `msg.sender` must own the account token with ID `accountId` or have the "admin" permission.
     *
     * Emits a {PermissionGranted} event.
     */
    function grantPermission(
        uint128 accountId,
        bytes32 permission,
        address user
    ) external;

    /**
     * @notice Revokes `permission` from `user` for account `accountId`.
     *
     * Requirements:
     *
     * - `msg.sender` must own the account token with ID `accountId` or have the "admin" permission.
     *
     * Emits a {PermissionRevoked} event.
     */
    function revokePermission(
        uint128 accountId,
        bytes32 permission,
        address user
    ) external;

    /**
     * @notice Revokes `permission` from `msg.sender` for account `accountId`.
     *
     * Emits a {PermissionRevoked} event.
     */
    function renouncePermission(uint128 accountId, bytes32 permission) external;

    /**
     * @notice Returns `true` if `user` has been granted `permission` for account `accountId`.
     */
    function hasPermission(
        uint128 accountId,
        bytes32 permission,
        address user
    ) external view returns (bool);

    /**
     * @notice Returns `true` if `target` is authorized to `permission` for account `accountId`.
     */
    function isAuthorized(
        uint128 accountId,
        bytes32 permission,
        address target
    ) external view returns (bool);

    /**
     * @notice Returns the address for the account token used by the module.
     */
    function getAccountTokenAddress() external view returns (address);

    /**
     * @notice Returns the address that owns a given account, as recorded by the system.
     */
    function getAccountOwner(uint128 accountId) external view returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@synthetixio/core-modules/contracts/interfaces/INftModule.sol";

/**
 * @title Module with custom NFT logic for the account token.
 */
interface IAccountTokenModule is INftModule {
    /**
     * @notice Emitted when `tokenId` token is minted.
     */
    event Mint(address indexed owner, uint256 indexed tokenId);

    /**
     * @notice Mints a new token with the `requestedAccountId` as the ID, owned by `owner`
     *
     * This function is only used internally by the system. See `createAccount` in the Account Module.
     *
     * Requirements:
     *
     * - `msg.sender` must be the owner of the contract.
     * - `requestedAccountId` must not already be minted.
     *
     * Emits a {Mint} event.
     */
    function mint(address owner, uint requestedAccountId) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@synthetixio/core-modules/contracts/modules/NftModule.sol";
import "../../../contracts/interfaces/IAccountTokenModule.sol";
import "../../../contracts/interfaces/IAccountModule.sol";

import "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";

/**
 * @title Module with custom NFT logic for the account token.
 * @dev See IAccountTokenModule.
 */
contract AccountTokenModule is IAccountTokenModule, NftModule {
    using SafeCastU128 for uint128;
    using SafeCastU256 for uint256;
    using SafeCastI128 for int128;
    using SafeCastI256 for int256;

    /**
     * @inheritdoc IAccountTokenModule
     */
    function mint(address owner, uint256 nftId) external {
        OwnableStorage.onlyOwner();
        _mint(owner, nftId);

        emit Mint(owner, nftId);
    }

    /**
     * @dev Updates account RBAC storage to track the current owner of the token.
     */
    function _postTransfer(
        address, // from (unused)
        address to,
        uint256 tokenId
    ) internal virtual override {
        IAccountModule(OwnableStorage.getOwner()).notifyAccountTransfer(to, tokenId.to128());
    }
}