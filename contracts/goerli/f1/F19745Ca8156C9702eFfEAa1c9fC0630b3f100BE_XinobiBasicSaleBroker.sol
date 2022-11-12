// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../../BuyVerifier/interfaces/IXinobiBuyVerifier.sol";
import "../../AvailableItems/interfaces/IXinobiAvailableItems.sol";
import "../../Transferer/interfaces/IXinobiTransferer.sol";
import "../../Wallet/interfaces/IXinobiWallet.sol";
import "../../Utils/TokenHandler.sol";
import "../../Utils/Charge.sol";
import "../../Utils/Accounts.sol";

contract XinobiBasicSaleBroker is TokenHandler {
    IXinobiBuyVerifier private _buyVerifier;
    IXinobiAvailableItems private _availableItems;
    IXinobiTransferer private _transferer;
    IXinobiWallet private _wallet;

    constructor(
        address buyVerifier,
        address avaiableItems,
        address transferer,
        address payable wallet
    ) {
        _buyVerifier = IXinobiBuyVerifier(buyVerifier);
        _availableItems = IXinobiAvailableItems(avaiableItems);
        _transferer = IXinobiTransferer(transferer);
        _wallet = IXinobiWallet(wallet);
    }

    modifier enoughEth(uint256 price) {
        require(price <= msg.value, "not enough eth.");
        _;
    }

    modifier isHandled(address collectionAddress) {
        require(
            _availableItems.isHandled(collectionAddress),
            "this collection is not handled."
        );
        _;
    }

    /**
     * if no affiliate, affiliater is address(0).
     */
    function buy(
        address collectionAddress,
        uint256 tokenId,
        uint256 price,
        Accounts calldata accounts,
        Charge.ChargePercentage calldata charge,
        uint256 sellerNonce,
        bytes calldata operatorSignature,
        bytes calldata sellerSignature
    ) external payable enoughEth(price) isHandled(collectionAddress) {
        // I can't implement it in a modifier because `CompilerError: Stack too deep.`
        require(
            _buyVerifier.verify(
                collectionAddress,
                tokenId,
                price,
                msg.sender,
                accounts,
                charge,
                operatorSignature
            ),
            "invalid access."
        );

        require(
            _buyVerifier.verify(
                collectionAddress,
                tokenId,
                price,
                accounts.seller,
                sellerNonce,
                sellerSignature
            ),
            "invalid access."
        );

        _buyVerifier.resetNonce(collectionAddress, tokenId);

        _transferer.transfer(
            collectionAddress,
            tokenId,
            accounts.seller,
            msg.sender,
            1
        );

        _wallet.accountFor{value: msg.value}(
            payable(accounts.seller),
            payable(accounts.royalityReceievr),
            payable(accounts.affiliater),
            charge
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

library Charge {
    // pacentage * 10^2. example 1% -> 100, 100% -> 10000
    struct ChargePercentage {
        uint16 royaltyPercentage;
        uint16 affiliatePercentage;
        uint16 operatingPercentage;
    }

    function isNotOverRoyalityUpper(
        ChargePercentage calldata charge,
        uint16 upper
    ) internal pure returns (bool) {
        return charge.royaltyPercentage <= upper;
    }

    function isNotOverAffiliateUpper(
        ChargePercentage calldata charge,
        uint16 upper
    ) internal pure returns (bool) {
        return charge.affiliatePercentage <= upper;
    }

    function isNotOverOperatingUpper(
        ChargePercentage calldata charge,
        uint16 upper
    ) internal pure returns (bool) {
        return charge.operatingPercentage <= upper;
    }

    function royality(ChargePercentage calldata charge, uint256 value)
        internal
        pure
        returns (uint256)
    {
        return
            ((value * charge.royaltyPercentage) / 10000) -
            affiliateRewards(charge, value);
    }

    function affiliateRewards(ChargePercentage calldata charge, uint256 value)
        internal
        pure
        returns (uint256)
    {
        return
            (((value * charge.royaltyPercentage) / 10000) *
                charge.affiliatePercentage) / 10000;
    }

    function operating(ChargePercentage calldata charge, uint256 value)
        internal
        pure
        returns (uint256)
    {
        return (value * charge.operatingPercentage) / 10000;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

abstract contract TokenHandler {
    modifier isSupportedInterface(address collectionAddress) {
        require(
            _isIERC721(collectionAddress) || _isIERC1155(collectionAddress),
            "this collection is not supported."
        );
        _;
    }

    function _isIERC721(address collectionAddress)
        internal
        view
        returns (bool)
    {
        return
            IERC165(collectionAddress).supportsInterface(
                type(IERC721).interfaceId
            );
    }

    function _isIERC1155(address collectionAddress)
        internal
        view
        returns (bool)
    {
        return
            IERC165(collectionAddress).supportsInterface(
                type(IERC1155).interfaceId
            );
    }

    modifier isOwner(
        address collectionAddress,
        uint256 tokenId,
        address from
    ) {
        if (_isIERC721(collectionAddress)) {
            require(
                IERC721(collectionAddress).ownerOf(tokenId) == from,
                "account is not owner."
            );
        } else if (_isIERC1155(collectionAddress)) {
            require(
                IERC1155(collectionAddress).balanceOf(from, tokenId) > 0,
                "account is not owner."
            );
        } else {
            require(false, "this collection is not supported.");
        }
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "../../Utils/Charge.sol";
import "../../Utils/Accounts.sol";

interface IXinobiBuyVerifier {
    struct List {
        address seller;
        uint256 nonce;
    }

    function getList(address collectionAddress, uint256 tokenId)
        external
        view
        returns (address, uint256);

    function list(address collectionAddress, uint256 tokenId, address seller) external;

    function resetNonce(address collectionAddress, uint256 tokenId) external;

    function verify(
        address collectionAddress,
        uint256 tokenId,
        uint256 price,
        address buyer,
        Accounts calldata accounts,
        Charge.ChargePercentage calldata charge,
        bytes calldata signature
    ) external view returns (bool);

    function verify(
        address collectionAddress,
        uint256 tokenId,
        uint256 price,
        address seller,
        uint256 sellerNonce,
        bytes calldata signature
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IXinobiAvailableItems {
    function addCollection(address collectionAddress) external;

    function removeCollection(address collectionAddress) external;

    function getCollections() external view returns (address[] memory);
    
    function isHandled(address collectionAddress) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IXinobiTransferer {
    function transfer(
        address collectionAddress,
        uint256 tokenId,
        address from,
        address to,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "../libs/Contributors.sol";
import "../../Utils/Charge.sol";

interface IXinobiWallet {
    function addContributor(Contributors.Contributor memory contributor)
        external;

    function updateContributor(Contributors.Contributor memory contributor)
        external;

    function removeContributor(address payable contributorAddress) external;

    function getContributors()
        external
        view
        returns (address[] memory, uint256[] memory);

    function withdrawAll() external;

    function accountFor(
        address payable seller,
        address payable royalityReceievr,
        address payable affiliater,
        Charge.ChargePercentage calldata charge
    ) external payable;

    receive() external payable;

    fallback() external payable;

    function getBalance() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

struct Accounts {
    address seller;
    address royalityReceievr;
    address affiliater;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
pragma solidity ^0.8.15;

library Contributors {
    struct Contributor {
        address payable payee;
        uint16 weight;
    }

    struct Set {
        Contributor[] _values;
        mapping(address => uint256) _indexes;
    }

    function add(Set storage set, Contributor memory contributor)
        internal
        returns (bool)
    {
        if (!contains(set, contributor.payee)) {
            set._values.push(contributor);
            set._indexes[contributor.payee] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function update(Set storage set, Contributor memory contributor)
        internal
        returns (bool)
    {
        if (contains(set, contributor.payee)) {
            uint256 idx = set._indexes[contributor.payee];
            set._values[idx - 1].weight = contributor.weight;
            return true;
        } else {
            return false;
        }
    }

    function remove(Set storage set, address contributorAddress)
        internal
        returns (bool)
    {
        uint256 valueIndex = set._indexes[contributorAddress];

        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                Contributor storage lastValue = set._values[lastIndex];
                set._values[toDeleteIndex] = lastValue;
                set._indexes[lastValue.payee] = valueIndex;
            }

            set._values.pop();
            delete set._indexes[contributorAddress];

            return true;
        } else {
            return false;
        }
    }

    function contains(Set storage set, address contributorAddress)
        internal
        view
        returns (bool)
    {
        return
            set._indexes[contributorAddress] != 0;
    }

    function length(Set storage set) internal view returns (uint256) {
        return set._values.length;
    }

    function at(Set storage set, uint256 index)
        internal
        view
        returns (Contributor memory)
    {
        return set._values[index];
    }

    function values(Set storage set)
        internal
        view
        returns (Contributor[] memory)
    {
        return set._values;
    }
}