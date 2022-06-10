/**
 *Submitted for verification at Etherscan.io on 2022-06-10
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


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

// File: contracts/PaymentSplitter.sol



pragma solidity ^0.8.0;


contract PaymentSplitter {
    // Structs
    struct Payment {
        uint128 timestamp;
        uint128 value;
    }

    
    // Storage
    Payment[] public paymentsReceived;
       
    mapping(uint => mapping(uint => bool)) internal _claimStatus;
    mapping(uint => bool) internal _isNftRare;

    IERC1155 nft = IERC1155(address(0x35886Bc0740f019319E3aeccd6736AF88ac5ac69));

    address immutable deployer;

    // Constructor

    constructor() {
        deployer = msg.sender;
       // uint[] public arr = [604, 605, 606];

    }

    // View Functions
    // id is rare token id
    //index is the index in the array of payment
    function isNftRare(uint id) public view returns(bool) {
        return _isNftRare[id];
    }


    function getClaimStatus(uint id, uint index) public view returns(bool) {
        return _claimStatus[id][index];
    }

    // Claiming
    function claim(uint[] calldata ids, uint[] calldata indexes) external {
        uint claimAmount = _verifyDataAndGetClaimAmount(ids, indexes);
        (bool success,) = msg.sender.call{ value: claimAmount }("");
        require(success, "Failed to send eth");
    }


    // Internal Checks

    function _verifyDataAndGetClaimAmount(uint[] calldata ids, uint[] calldata indexes) internal returns(uint claimAmount) {
        unchecked {
            uint firstInvalidIndex = paymentsReceived.length;
            for(uint x = 0; x < indexes.length; x++) {

                // Add to claim amount after verifying the index is valid
                require(indexes[x] < firstInvalidIndex, "Invalid indexes");
                claimAmount += paymentsReceived[indexes[x]].value;
                // add another require check here for the timelock
                //divide by the total amount of tokens and multiply by the amount of tokens the user has
                //or do it at the end of the function before the return 

                for(uint i = 0; i < ids.length; i++) {
                    // Verify ownership and rarity status
                    require(nft.balanceOf(msg.sender, ids[i]) == 1, "Not owner");
                    require(_isNftRare[ids[i]] == true, "Not rare");

                    // Set NFT as claimed after verifying it's not already claimed
                    require(_claimStatus[ids[i]][indexes[x]] == false, "Already claimed");
                    _claimStatus[ids[i]][indexes[x]] = true;
                }
            }
        }
    }

    receive() external payable {
        require(msg.sender == deployer);    
        require(msg.value <= type(uint128).max);
        // require(msg.value <= type(uint128).max) security practice

                 
        paymentsReceived.push(Payment({
            timestamp: uint128(block.timestamp),
            value: uint128(msg.value)
        }));
    }
    
}



/*
 * This contract is used to receive the payments and then pass them onto the splitter
 * to avoid reverts in the `receive` function of the splitter due to the storage write
 */
contract PaymentReceiver {
    PaymentSplitter public immutable splitter;

    constructor() {
    splitter = new PaymentSplitter();
    }

    //transfer the funds
    function sendToSplitter() external payable {
        (bool success, bytes memory returnVal) = address(splitter).call{ value: address(this).balance }("");
        require(success, string(returnVal));
    }

    receive() external payable {}
}

/*
TODO:
require checks for balance > 0
use bitmaps and bitmap mappings with merkle trees to keep track of who holds NFT or not 
*/