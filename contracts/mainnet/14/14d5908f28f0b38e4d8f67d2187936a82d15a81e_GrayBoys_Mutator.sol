//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IGrayBoys_Mutants.sol";
import "./IGrayBoys_Science_Lab.sol";

contract GrayBoys_Mutator {
    /* Lab items */
    uint16 constant RED_SERUM_ID = 1;
    uint16 constant ANCIENT_CRYSTAL_ID = 4;
    uint16 constant GREEN_SERUM_ID = 5;

    /* Mutations */
    uint16 constant L1_MUTATION_ID = 0;
    uint16 constant L2_MUTATION_ID = 1;
    uint16 constant CRYSTAL_MUTATION_ID = 2;

    IGrayBoys_Mutants public mutantsContract;
    IGrayBoys_Science_Lab public scienceLabContract;

    constructor(address _mutantsContractAddress, address _scienceLabContractAddress) {
        mutantsContract = IGrayBoys_Mutants(_mutantsContractAddress);
        scienceLabContract = IGrayBoys_Science_Lab(_scienceLabContractAddress);
    }

    /* Basic mutations */
    function mutateL1(uint256[] calldata _fromTokenIds) external {
        uint256 count = _fromTokenIds.length;
        scienceLabContract.burnMaterialForOwnerAddress(RED_SERUM_ID, count, msg.sender);
        scienceLabContract.burnMaterialForOwnerAddress(GREEN_SERUM_ID, count, msg.sender);
        mutantsContract.mutate(msg.sender, L1_MUTATION_ID, _fromTokenIds);
    }

    function mutateL2(uint256[] calldata _fromTokenIds) external {
        uint256 count = _fromTokenIds.length;
        scienceLabContract.burnMaterialForOwnerAddress(RED_SERUM_ID, 2 * count, msg.sender);
        scienceLabContract.burnMaterialForOwnerAddress(GREEN_SERUM_ID, 2 * count, msg.sender);
        mutantsContract.mutate(msg.sender, L2_MUTATION_ID, _fromTokenIds);
    }

    /* Special mutations */
    function mutateCrystal(uint256 _count) external {
        scienceLabContract.burnMaterialForOwnerAddress(ANCIENT_CRYSTAL_ID, _count, msg.sender);
        mutantsContract.specialMutate(msg.sender, CRYSTAL_MUTATION_ID, _count);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IGrayBoys_Mutants {
    //Create mutations from GBs
    function mutate(address _ownerAddress, uint256 _typeId, uint256[] calldata _fromTokenIds) external;

    //Create special mutations (do not require GBs)
    function specialMutate(address _ownerAddress, uint256 _typeId, uint256 _count) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IGrayBoys_Science_Lab is IERC1155 {
  function burnMaterialForOwnerAddress(uint256 _typeId, uint256 _quantity, address _materialOwnerAddress) external;
  function mintMaterialToAddress(uint256 _typeId, uint256 _quantity, address _toAddress) external;
  function bulkSafeTransfer(uint256 _typeId, uint256 _quantityPerRecipient, address[] calldata recipients) external;
}

// SPDX-License-Identifier: MIT

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