// SPDX-License-Identifier: MIT
// Nomos Marketplace
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// import "hardhat/console.sol";

contract NomosSaleMarket is ERC1155Holder {

    struct NomosSale {
        string saleId;
        uint256 tokenId;
        uint256 amount;
        uint256 priceInWei;
        address collectionContract;
        address paymentTokenContract;
        address seller;
        bool sold;
    }
    struct SaleBeneficiary {
        uint256 percentage;
        address wallet;
    }
    event SaleCreated(string saleId);
    event BuyPerformed(string saleId, address buyer);

    mapping(string => NomosSale) sales;
    mapping(string => SaleBeneficiary[]) beneficiariesMap;
    address admin;

    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin {
        require(admin == msg.sender, "Only admin");
        _;
    }

    function getSalesDetails(string memory saleId) public view returns (NomosSale memory) {
        return sales[saleId];
    }

    function getBeneficiaries(string memory saleId) public view returns (SaleBeneficiary[] memory) {
        return beneficiariesMap[saleId];
    }

    function sellNft(
        string memory saleId,
        uint256 tokenId,
        uint256 priceInWei,
        address collectionContract,
        SaleBeneficiary[] memory beneficiaries
    ) public {
        sellNft(saleId, tokenId, priceInWei, collectionContract, beneficiaries, 1);
    }

    function sellNft(
        string memory saleId,
        uint256 tokenId,
        uint256 priceInWei,
        address collectionContract,
        SaleBeneficiary[] memory beneficiaries,
        uint256 amount
    ) public {
        require(sales[saleId].tokenId == 0, "Existing sale ID");
        IERC1155 minter = IERC1155(collectionContract);
        require(minter.balanceOf(msg.sender, tokenId) >= amount, "Not enough balance");

        NomosSale memory sale = NomosSale(
            saleId,
            tokenId,
            amount,
            priceInWei,
            collectionContract,
            address(0),
            msg.sender,
            false
        );

        if (beneficiaries.length == 0) {
            beneficiariesMap[saleId].push(SaleBeneficiary(10000, msg.sender));
        }

        for (uint i = 0; i < beneficiaries.length; i++) {
            beneficiariesMap[saleId].push(beneficiaries[i]);
        }

        minter.safeTransferFrom(msg.sender, address(this), tokenId, amount, "");
        sales[saleId] = sale;
        emit SaleCreated(saleId);
    } 

    function buyNft (string memory saleId) public payable {
        buyNft(saleId, 1);
    }

    function buyNft(string memory saleId, uint256 amount) public payable {
        require(!sales[saleId].sold, "Already sold");
        require(sales[saleId].amount >= amount, "Not enough supply");
        require(sales[saleId].seller != msg.sender, "Cannot buy own item");
        require(msg.value >= sales[saleId].priceInWei * amount, "Payment not enough");

        IERC1155 minter = IERC1155(sales[saleId].collectionContract);

        for (uint i = 0; i < beneficiariesMap[saleId].length; i++) {
            address payable beneficiary = payable(beneficiariesMap[saleId][i].wallet);
            uint256 benefitAmount = (sales[saleId].priceInWei * amount * beneficiariesMap[saleId][i].percentage) / 10000;

            (bool success, ) = beneficiary.call{value: benefitAmount}("");
            require(success, "buyNft: Transfer failed");
        }

        minter.safeTransferFrom(address(this), msg.sender, sales[saleId].tokenId, amount, "");

        // subtract the transferred amount
        sales[saleId].amount -= amount;
        
        if (sales[saleId].amount == 0) {
            sales[saleId].sold = true;
        }
        emit BuyPerformed(saleId, msg.sender);
    }

    function buyAdmin(string memory saleId, uint256 amount, address destination) public onlyAdmin {
        require(!sales[saleId].sold, "Already sold");
        require(sales[saleId].amount >= amount, "Not enough supply");
        IERC1155 minter = IERC1155(sales[saleId].collectionContract);
        minter.safeTransferFrom(address(this), destination, sales[saleId].tokenId, amount, "");

        // subtract the transferred amount
        sales[saleId].amount -= amount;

        if (sales[saleId].amount == 0) {
            sales[saleId].sold = true;
        }
        emit BuyPerformed(saleId, destination);
    }

    function cancelSaleNft(string memory saleId) public {
        require(!sales[saleId].sold, "Already sold");
        require(sales[saleId].seller == msg.sender, "Not own sale");

        IERC1155 minter = IERC1155(sales[saleId].collectionContract);
        minter.safeTransferFrom(address(this), msg.sender, sales[saleId].tokenId, 1, "");

        sales[saleId] = NomosSale(
            saleId,
            0,
            0,
            0,
            address(0),
            address(0),
            address(0),
            false
        );
    }

    function sellNftWithToken(
        string memory saleId,
        uint256 tokenId,
        uint256 priceInWei,
        address collectionContract,
        address paymentContract,
        SaleBeneficiary[] memory beneficiaries
    ) public {
        require(sales[saleId].tokenId == 0, "Existing sale ID");
        IERC1155 minter = IERC1155(collectionContract);

        require(minter.balanceOf(msg.sender, tokenId) > 0, "Not enough balance");
        NomosSale memory sale = NomosSale(
            saleId,
            tokenId,
            1,
            priceInWei,
            collectionContract,
            paymentContract,
            msg.sender,
            false
        );

        if (beneficiaries.length == 0) {
            beneficiariesMap[saleId].push(SaleBeneficiary(10000, msg.sender));
        }
        for (uint i = 0; i < beneficiaries.length; i++) {
            beneficiariesMap[saleId].push(beneficiaries[i]);
        }

        sales[saleId] = sale;
        minter.safeTransferFrom(msg.sender, address(this), tokenId, 1, "");
        emit SaleCreated(saleId);
    }


    function buyNftWithToken (string memory saleId) public {
        require(!sales[saleId].sold, "Already sold");
        require(sales[saleId].seller != msg.sender, "Cannot buy own item");

        IERC20 erc20 = IERC20(sales[saleId].paymentTokenContract);
        require(erc20.balanceOf(msg.sender) >= sales[saleId].priceInWei, "Payment token not enough");

        IERC1155 minter = IERC1155(sales[saleId].collectionContract);

        for (uint i = 0; i < beneficiariesMap[saleId].length; i++) {
            address payable beneficiary = payable(beneficiariesMap[saleId][i].wallet);
            uint256 benefitAmount = (sales[saleId].priceInWei * 1 * beneficiariesMap[saleId][i].percentage) / 10000;

            erc20.transferFrom(msg.sender, beneficiary, benefitAmount);
        }

        minter.safeTransferFrom(address(this), msg.sender, sales[saleId].tokenId, 1, "");
        sales[saleId].sold = true;
        emit BuyPerformed(saleId, msg.sender);
    }
}

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
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