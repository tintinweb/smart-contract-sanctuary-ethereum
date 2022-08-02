// SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-0.8/token/ERC1155/IERC1155.sol";
import "./MarketPlaceERC1155.sol";

/**
 * @title OCTK1MarketPlace is the marketplace for OCTK1 Token deployed by Octofan.
 * @dev OCTK1.
 */
contract OCTK1MarketPlace is MarketPlaceERC1155 {
    constructor(
        IERC1155 ierc1155,
        uint256[] memory tokenIds,
        uint256[] memory unitPriceInETH,
        address payable marketPlaceAddress
    ) MarketPlaceERC1155(ierc1155, tokenIds, unitPriceInETH, marketPlaceAddress) {}
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
// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-0.8/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts-0.8/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts-0.8/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts-0.8/access/Ownable.sol";
import "@openzeppelin/contracts-0.8/utils/Strings.sol";

contract MarketPlaceERC1155 is IERC1155Receiver, Ownable, ReentrancyGuard {
    IERC1155 private immutable _ierc1155;
    mapping(uint256 => uint256) private _unitPrice;
    address payable private _recipient;
    bool private _redirect;
    bool private _allowSell;

    constructor(
        IERC1155 ierc1155,
        uint256[] memory tokenIds,
        uint256[] memory unitPriceInETH,
        address payable recipient
    ) {
        _ierc1155 = ierc1155;
        _setUnitPrice(tokenIds, unitPriceInETH);
        _recipient = recipient;
        _redirect = true;
        _allowSell = false;
    }

    function _setUnitPrice(uint256[] memory tokenIds, uint256[] memory unitPriceInETH) internal {
        require(tokenIds.length == unitPriceInETH.length, "TokenIds and unitPriceInETH should have same length.");
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            _unitPrice[tokenIds[i]] = unitPriceInETH[i];
        }
    }

    event MarketPlaceERC1155Recipient(address payable _recipient);
    event MarketPlaceERC1155UnitPrice(uint256[] _unitPrice);
    event MarketPlaceERC1155Retrieved(address _receiver, uint256[] _amountsRetrived);
    event MarketPlaceERC1155Buy(address _receiver, uint256[] _tokenIds, uint256[] _amounts, uint256[] _unitPrice, uint256 _priceInETH);

    /// @notice Buy IERC1155 tokens with ether.
    /// @param tokenIds The ids of the IERC1155 token
    /// @param amounts The amounts of the IERC1155 token to buy
    function buy(uint256[] calldata tokenIds, uint256[] calldata amounts) external nonReentrant payable {
        uint256 amountPayed = msg.value;
        require(amountPayed > 0, "You must send some ether.");

        uint256[] memory unitPrices = _getUnitPrice(tokenIds);
        uint256[] memory _tokenBalances = _balances(address(this),tokenIds);
        uint256 sellAmount = 0;
        for (uint256 i = 0; i < unitPrices.length; ++i) {
            require(_tokenBalances[i] >= amounts[i], string(abi.encodePacked("There are not enough tokens ", Strings.toString(tokenIds[i]), " for sale: ", Strings.toString(_tokenBalances[i]))));
            sellAmount = sellAmount + unitPrices[i] * amounts[i];
        } 
        require(amountPayed == sellAmount, string(abi.encodePacked("sell amount: ", Strings.toString(sellAmount), " does not match payment: ", Strings.toString(amountPayed))));
        if(_redirect){
            (bool success, ) = payable(_recipient).call{value: amountPayed}("");
            require(success, string(abi.encodePacked("Tranfer to ", _recipient, " Failed. ")));
        }

        _ierc1155.safeBatchTransferFrom(
            address(this),
            _msgSender(),
            tokenIds,
            amounts,
            ""
        );

        emit MarketPlaceERC1155Buy(_msgSender(), tokenIds, amounts, unitPrices, sellAmount);
    }

    /// @notice retrieve all IERC1155 tokens from contract to an address.
    /// @param recipient The address that will receive all IERC1155 tokens.
    /// @param tokenIds The token ids to receive.
    function retrieveAt(address recipient, uint256[] calldata tokenIds) external nonReentrant onlyOwner {
        uint256[] memory marketPlaceBalance = _balances(address(this), tokenIds);
        _ierc1155.safeBatchTransferFrom(
            address(this),
            recipient,
            tokenIds,
            marketPlaceBalance,
            ""
        );
        emit MarketPlaceERC1155Retrieved(recipient, marketPlaceBalance);
    }

    /// @notice retrieve all IERC1155 tokens from contract to msg.sender address.
    /// @param tokenIds The token ids to receive.
    function retrieve(uint256[] calldata tokenIds) external nonReentrant onlyOwner {
        uint256[] memory marketPlaceBalance = _balances(address(this), tokenIds);
        _ierc1155.safeBatchTransferFrom(
            address(this),
            _msgSender(),
            tokenIds,
            marketPlaceBalance,
            ""
        );
        emit MarketPlaceERC1155Retrieved(_msgSender(), marketPlaceBalance);
    }

    /// @notice return the IERC1155 amount price in wei.
    function getPrice(uint256[] calldata tokenIds, uint256[] calldata amounts) external view returns (uint256[] memory) {
        uint256[] memory prices = new uint256[](tokenIds.length);
        require(tokenIds.length == amounts.length, "TokenIds and amounts should have same length.");
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            require(_unitPrice[tokenIds[i]] != 0, string(abi.encodePacked("Tokens are not sold on this market place: ", Strings.toString(tokenIds[i]))));
            prices[i] = amounts[i] * _unitPrice[tokenIds[i]];
        }
        return prices;
    }

    /// @notice return the IERC1155 token address.
    function getERC1155Address() external view returns (address) {
        return address(_ierc1155);
    }

    /// @notice set the market place address
    /// @param recipient address of the market place
    function setRecipient(address payable recipient) external nonReentrant onlyOwner {
        require(recipient != address(0), "receiving market place address cannot be zero address");
        _recipient = recipient;
        emit MarketPlaceERC1155Recipient(recipient);
    }

    /// @notice return the market place address.
    function getRecipient() public view returns (address) {
        return _recipient;
    }

    /// @notice set the IERC1155 unit prices in wei.
    function setUnitPrice(uint256[] calldata tokenIds, uint256[] calldata unitPriceInETH) external nonReentrant onlyOwner {
        _setUnitPrice(tokenIds, unitPriceInETH);
    }

    /// @notice return true if automatic eth flow redirection is set.
    function getRedirect() external view returns (bool) {
        return _redirect;
    }

    /// @notice set automatic eth flow redirection.
    /// @param redirect automatic eth flow redirection
    function setRedirect(bool redirect) external nonReentrant onlyOwner {
        _redirect = redirect;
    }

    /// @notice return true if sell is allowed.
    function getAllowSell() external view returns (bool) {
        return _allowSell;
    }

    /// @notice set sell authorization.
    /// @param allowSell allow sell
    function setAllowSell(bool allowSell) external nonReentrant onlyOwner {
        _allowSell = allowSell;
    }

    /// @notice get eth amount on contract.
    function getBalance() external view returns (uint256){
        return address(this).balance;
    }

    /// @notice Transfer all funds to one address.
    function transfer() external nonReentrant onlyOwner {
        uint256 ethBalance = address(this).balance;
        (bool success, ) = payable(_recipient).call{value: ethBalance}("");
        require(success, string(abi.encodePacked("Tranfer to ", _recipient, " Failed. ")));
    }

    /// @notice Transfer funds to one address.
    /// @param recipient The address to which the funds are transferred
    /// @param amount The amount of funds to be transferred
    function transferAt(address payable recipient, uint256 amount) external nonReentrant onlyOwner {
        require(recipient != address(0), "recipient address cannot be zero address");
        require(address(this).balance >= amount, string(abi.encodePacked("There are not enough ethers on contract, required: ", Strings.toString(amount), " available: ", Strings.toString(address(this).balance))));
        (bool success, ) = payable(recipient).call{value: amount}("");
        require(success, string(abi.encodePacked("Tranfer to ", recipient, " Failed. ")));
    }

    /// @notice return the IERC1155 unit prices in wei.
    /// @param tokenIds The ids of the IERC1155 token
    function _getUnitPrice(uint256[] calldata tokenIds) internal view returns (uint256[] memory) {
        uint[] memory unitPrices = new uint[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            require(_unitPrice[tokenIds[i]] != 0, string(abi.encodePacked("Tokens are not sold on this market place: ", Strings.toString(tokenIds[i]))));
            unitPrices[i] = _unitPrice[tokenIds[i]];
        }
        return unitPrices;
    }

    /// @notice return the IERC1155 unit prices in wei.
    /// @param tokenIds The ids of the IERC1155 token
    function getUnitPrice(uint256[] calldata tokenIds) external view returns (uint256[] memory) {
        return _getUnitPrice(tokenIds);
    }

    /// @notice return the current IERC1155 id token balance for the contract.
    /// @param tokenId The id of the IERC1155 token
    function balanceOf(uint256 tokenId) external view returns (uint256) {
        return _ierc1155.balanceOf(address(this), tokenId);
    }

    /// @notice Returns the current balance of IERC1155 token for the contract.
    /// @param account The address of the account
    /// @param tokenIds The ids of the IERC1155 token
    function _balances(address account, uint256[] calldata tokenIds) internal view returns (uint256[] memory) {
        uint256[] memory _tokenBalances = new uint256[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            _tokenBalances[i] = _ierc1155.balanceOf(account, tokenIds[i]);
        }
        return _tokenBalances;
    }

    /// @notice Returns the current balance of IERC1155 token for the contract.
    /// @param tokenIds The ids of the IERC1155 token
    function balances(uint256[] calldata tokenIds) external view returns (uint256[] memory) {
        return _balances(address(this),tokenIds);
    }

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override returns (bytes4){
        require(_msgSender() == address(_ierc1155),"Bad sender");
        return IERC1155Receiver.onERC1155Received.selector;
    }

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override returns (bytes4){
        require(_msgSender() == address(_ierc1155),"Bad sender");
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC1155Receiver).interfaceId ||
            interfaceId == type(Ownable).interfaceId;
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