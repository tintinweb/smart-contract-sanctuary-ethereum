// SPDX-License-Identifier: Unlicense
// Creator: 0xVeryBased

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract ERC721StorageLayer is Ownable {
    using Address for address;
    using Strings for uint256;

    //////////

    mapping(uint256 => address) private registeredContracts;
    mapping(address => uint256) private contractNumberings;
    mapping(address => bool) private isRegistered;
    uint256 numRegistered;

    modifier onlyRegistered() {
        _isRegistered();
        _;
    }
    function _isRegistered() internal view virtual {
        require(isRegistered[msg.sender], "r");
    }

    mapping(address => string) private _contractNames;
    mapping(address => string) private _contractSymbols;
    bool public canSetNameAndSymbol = true;

    mapping(address => string) private _contractDescriptions;
    mapping(address => string) private _contractImages;

    //////////

    address public mintingContract;

    modifier onlyMintingContract() {
        _isMintingContract();
        _;
    }
    function _isMintingContract() internal view virtual {
        require(msg.sender == mintingContract, "m");
    }

    //////////

    uint256 currentIndex;
    mapping(uint256 => address) _ownerships;
    mapping(address => uint256) _balances;

    address public immutable burnAddress = 0x000000000000000000000000000000000000dEaD;
    mapping(address => uint256) private _burnCounts;

    //////////

    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => mapping(address => bool))) private _operatorApprovals;

    ////////////////////

//    constructor() {
//    }

    ////////////////////

    function registerTopLevel(
        string memory name_,
        string memory symbol_,
        string memory description_,
        string memory image_
    ) public {
        require(numRegistered < 5, "mr");
//        require(Ownable(msg.sender).owner() == tx.origin, "o");
        require(tx.origin == owner(), "a");

        registeredContracts[numRegistered] = msg.sender;
        contractNumberings[msg.sender] = numRegistered;

        _contractNames[msg.sender] = name_;
        _contractSymbols[msg.sender] = symbol_;
        _contractDescriptions[msg.sender] = description_;
        _contractImages[msg.sender] = image_;

        isRegistered[msg.sender] = true;
        numRegistered++;
    }

    function registerMintingContract() public {
//        require(Ownable(msg.sender).owner() == tx.origin, "o");
        require(tx.origin == owner(), "a");
        mintingContract = msg.sender;
    }

    //////////

    function storage_totalSupply(address collection) public view returns (uint256) {
        require(isRegistered[collection], "r");
        return (currentIndex/5) - _burnCounts[collection];
    }

    function storage_tokenByIndex(
        address collection,
        uint256 index
    ) public view returns (uint256) {
        require(isRegistered[collection], "r");
        require(index < (currentIndex/5), "g");
        require(storage_ownerOf(collection, index) != burnAddress, "b");
        return index;
    }

    function storage_tokenOfOwnerByIndex(
        address collection,
        address owner,
        uint256 index
    ) public view returns (uint256) {
        require(isRegistered[collection], "r");
        require(index < storage_balanceOf(collection, owner), "b");
        uint256 numTokenIds = currentIndex;
        uint256 tokenIdsIdx = 0;
        address currOwnershipAddr = address(0);
        uint256 j;
        uint256 offset = contractNumberings[collection];
        for (uint256 i = 0; i < numTokenIds/5; i++) {
            j = i*5 + offset;
            address ownership = _ownerships[j];
            if (ownership != address(0)) {
                currOwnershipAddr = ownership;
            }
            if (currOwnershipAddr == owner) {
                if (tokenIdsIdx == index) {
                    return i;
                }
                tokenIdsIdx++;
            }
        }
        revert("u");
    }

    function storage_tokenOfOwnerByIndexStepped(
        address collection,
        address owner,
        uint256 index,
        uint256 lastToken,
        uint256 lastIndex
    ) public view returns (uint256) {
        require(isRegistered[collection], "r");
        require(index < storage_balanceOf(collection, owner), "b");
        uint256 numTokenIds = currentIndex;
        uint256 tokenIdsIdx = ((lastIndex == 0) ? 0 : (lastIndex + 1));
        address currOwnershipAddr = address(0);
        uint256 j;
        uint256 offset = contractNumberings[collection];
        for (uint256 i = ((lastToken == 0) ? 0 : (lastToken + 1)); i < numTokenIds/5; i++) {
            j = i*5 + offset;
            address ownership = _ownerships[j];
            if (ownership != address(0)) {
                currOwnershipAddr = ownership;
            }
            if (currOwnershipAddr == owner) {
                if (tokenIdsIdx == index) {
                    return i;
                }
                tokenIdsIdx++;
            }
        }
        revert("u");
    }

    function storage_balanceOf(
        address collection,
        address owner
    ) public view returns (uint256) {
        require(isRegistered[collection], "r");
        require(owner != address(0) || owner != burnAddress, "0/burn");
        return (_balances[owner] >> (14*contractNumberings[collection]))%(1<<14);
    }

    function storage_ownerOf(
        address collection,
        uint256 tokenId
    ) public view returns (address) {
        require(isRegistered[collection], "r");
        require(tokenId < currentIndex/5, "t");

//        uint256 curr;
        uint256 offset = contractNumberings[collection];
        for (uint256 i = tokenId*5 + offset; i >= 0; i--) {
//            curr = i*5 + offset;
//            address ownership = _ownerships[curr];
            address ownership = _ownerships[i];
            if (ownership != address(0)) {
                return ownership;
            }
        }

        revert("o");
    }

    function storage_name(address collection) public view returns (string memory) {
        require(isRegistered[collection], "r");
        return _contractNames[collection];
    }

    function storage_setName(address collection, string memory newName) public onlyOwner {
        require(isRegistered[collection] && canSetNameAndSymbol, "r/cs");
        _contractNames[collection] = newName;
    }

    function storage_symbol(address collection) public view returns (string memory) {
        require(isRegistered[collection] && canSetNameAndSymbol, "r/cs");
        return _contractSymbols[collection];
    }

    function storage_setSymbol(address collection, string memory newSymbol) public onlyOwner {
        require(isRegistered[collection], "r");
        _contractSymbols[collection] = newSymbol;
    }

    function flipCanSetNameAndSymbol() public onlyOwner {
        require(canSetNameAndSymbol, "cs");
        canSetNameAndSymbol = false;
    }

    function storage_setDescription(
        address collection,
        string memory newDescription
    ) public onlyOwner {
        require(isRegistered[collection], "r");
        _contractDescriptions[collection] = newDescription;
    }

    function storage_setImage(
        address collection,
        string memory newImage
    ) public onlyOwner {
        require(isRegistered[collection], "r");
        _contractImages[collection] = newImage;
    }

//    function storage_description(address collection) public view returns (string memory) {
//        return _contractDescriptions[collection];
//    }

    function storage_approve(address msgSender, address to, uint256 tokenId) public onlyRegistered {
        address owner = ERC721StorageLayer.storage_ownerOf(msg.sender, tokenId);
        require(to != owner, "o");

        require(
            msgSender == owner || storage_isApprovedForAll(msg.sender, owner, msgSender),
            "a"
        );

        _approve(to, tokenId*5 + contractNumberings[msg.sender], owner);
    }

    function storage_getApproved(
        address collection,
        uint256 tokenId
    ) public view returns (address) {
        require(isRegistered[collection], "r");

        uint256 mappedTokenId = tokenId*5 + contractNumberings[collection];
        require(_exists(mappedTokenId, tokenId), "a");

        return _tokenApprovals[mappedTokenId];
    }

    function storage_setApprovalForAll(
        address msgSender,
        address operator,
        bool approved
    ) public onlyRegistered {
        require(operator != msgSender, "a");

        _operatorApprovals[msg.sender][msgSender][operator] = approved;
        ERC721TopLevelProto(msg.sender).emitApprovalForAll(msgSender, operator, approved);
    }

    function storage_globalSetApprovalForAll(
        address operator,
        bool approved
    ) public {
        require(operator != msg.sender, "a");

        for (uint256 i = 0; i < 5; i++) {
            address topLevelContract = registeredContracts[i];
            require(!(ERC721TopLevelProto(topLevelContract).operatorRestrictions(operator)), "r");
            _operatorApprovals[topLevelContract][msg.sender][operator] = approved;
            ERC721TopLevelProto(topLevelContract).emitApprovalForAll(msg.sender, operator, approved);
        }
    }

    function storage_isApprovedForAll(
        address collection,
        address owner,
        address operator
    ) public view returns (bool) {
        require(isRegistered[collection], "r");
        return _operatorApprovals[collection][owner][operator];
    }

    function storage_transferFrom(
        address msgSender,
        address from,
        address to,
        uint256 tokenId
    ) public onlyRegistered {
        _transfer(msgSender, from, to, tokenId*5 + contractNumberings[msg.sender]);
        ERC721TopLevelProto(msg.sender).emitTransfer(from, to, tokenId);
    }

    function storage_safeTransferFrom(
        address msgSender,
        address from,
        address to,
        uint256 tokenId
    ) public onlyRegistered {
        storage_safeTransferFrom(msgSender, from, to, tokenId, "");
    }

    function storage_safeTransferFrom(
        address msgSender,
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public onlyRegistered {
        _transfer(msgSender, from, to, tokenId*5 + contractNumberings[msg.sender]);
        ERC721TopLevelProto(msg.sender).emitTransfer(from, to, tokenId);
        require(
            _checkOnERC721Received(msgSender, from, to, tokenId, _data),
            "z"
        );
    }

    function storage_burnToken(address msgSender, uint256 tokenId) public onlyRegistered {
        _transfer(
            msgSender,
            storage_ownerOf(msg.sender, tokenId),
            burnAddress,
            tokenId*5 + contractNumberings[msg.sender]
        );
        _burnCounts[msg.sender] += 1;
        ERC721TopLevelProto(msg.sender).emitTransfer(msgSender, burnAddress, tokenId);
    }

    function storage_exists(
        address collection,
        uint256 tokenId
    ) public view returns (bool) {
        require(isRegistered[collection], "r");
        return _exists(tokenId*5 + contractNumberings[collection], tokenId);
    }

    function _exists(uint256 mappedTokenId, uint256 tokenId) private view returns (bool) {
        return (mappedTokenId < currentIndex && _ownerships[tokenId] != burnAddress);
    }

    function storage_safeMint(
        address msgSender,
        address to,
        uint256 quantity
    ) public onlyMintingContract {
        storage_safeMint(msgSender, to, quantity, "");
    }

    function storage_safeMint(
        address msgSender,
        address to,
        uint256 quantity,
        bytes memory _data
    ) public onlyMintingContract {
        storage_mint(to, quantity);
        require(_checkOnERC721Received(msgSender, address(0), to, (currentIndex/5) - 1, _data), "z");
    }

    function storage_mint(address to, uint256 quantity) private {
        uint256 startTokenId = currentIndex/5;
        require(to != address(0), "0");
        // We know if the first token in the batch doesn't exist, the other ones don't as well, because of serial ordering.
        require(!_exists(startTokenId, currentIndex), "a");

        uint256 balanceQtyAdd = 0;
        for (uint256 i = 0; i < 5; i++) {
            balanceQtyAdd += (quantity << (i*14));
        }
        _balances[to] = _balances[to] + balanceQtyAdd;
        _ownerships[currentIndex] = to;

        uint256 updatedIndex = startTokenId;

        for (uint256 i = 0; i < quantity; i++) {
            for (uint256 j = 0; j < 5; j++) {
                ERC721TopLevelProto(registeredContracts[j]).emitTransfer(address(0), to, updatedIndex);
            }
            updatedIndex++;
        }

        currentIndex = updatedIndex*5;
    }

    function storage_contractURI(address collection) public view virtual returns (string memory) {
        require(isRegistered[collection], "r");
        return string(
            abi.encodePacked(
                "data:application/json;utf8,{\"name\":\"", storage_name(collection), "\",",
                "\"description\":\"", _contractDescriptions[collection], "\",",
                "\"image\":\"", _contractImages[collection], "\",",
                "\"external_link\":\"https://crudeborne.wtf\",",
                "\"seller_fee_basis_points\":500,\"fee_recipient\":\"",
                uint256(uint160(collection)).toHexString(), "\"}"
            )
        );
    }

    //////////

    function _transfer(
        address msgSender,
        address from,
        address to,
        uint256 tokenId
    ) private {
        uint256 collectionTokenId = tokenId/5;
        address prevOwnership = storage_ownerOf(msg.sender, collectionTokenId);

        bool isApprovedOrOwner = (msgSender == prevOwnership ||
        storage_getApproved(msg.sender, collectionTokenId) == msgSender ||
        storage_isApprovedForAll(msg.sender, prevOwnership, msgSender));

        require(isApprovedOrOwner && prevOwnership == from, "a");
        require(prevOwnership == from, "o");
        require(to != address(0), "0");

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, prevOwnership);

        _balances[from] -= (1 << (contractNumberings[msg.sender]*14));
        _balances[to] += (1 << (contractNumberings[msg.sender]*14));
        _ownerships[tokenId] = to;

        // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
        // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
        uint256 nextTokenId = tokenId + 1;
        if (_ownerships[nextTokenId] == address(0)) {
            if (_exists(nextTokenId, nextTokenId/5)) {
                _ownerships[nextTokenId] = prevOwnership;
            }
        }

        uint256 nextCollectionTokenId = tokenId + 5;
        if (_ownerships[nextCollectionTokenId] == address(0)) {
            if (_exists(nextCollectionTokenId, nextCollectionTokenId/5)) {
                _ownerships[nextCollectionTokenId] = prevOwnership;
            }
        }
    }

    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId] = to;
        ERC721TopLevelProto(msg.sender).emitApproval(owner, to, tokenId/5);
    }

    function _checkOnERC721Received(
        address msgSender,
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(msgSender, from, tokenId, _data) returns (bytes4 retVal) {
                return retVal == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("z");
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

////////////////////

abstract contract ERC721TopLevelProto {
    mapping(address => bool) public operatorRestrictions;
    function emitTransfer(address from, address to, uint256 tokenId) public virtual;
    function emitApproval(address owner, address approved, uint256 tokenId) public virtual;
    function emitApprovalForAll(address owner, address operator, bool approved) public virtual;
}

////////////////////////////////////////

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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