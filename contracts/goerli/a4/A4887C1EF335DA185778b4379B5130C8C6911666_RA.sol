/**
 *Submitted for verification at Etherscan.io on 2022-10-27
*/

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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


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

// File: ray_auction.sol



pragma solidity ^0.8.7;



// 0x8b5Cb3d931aC1cA7944f627544F97BA53694749b
contract RA is ERC165, IERC1155Receiver {
    // mapping(address => mapping(address => bool)) approvalMapping;
    // mapping(address => mapping(address => mapping(uint => mapping)))
    // struct SwapInfo {
    //     address tokenAddress;
    //     uint id;
    //     uint amount;
    // }
    // mapping(address => mapping(address => SwapInfo)) mappingSwapInfo;

    event eventIntrust(bool success, bytes response);
    event eventReturn(string response);

    function intrust(address tokenAddress, address from, uint id, uint amount, address swapAddress, uint swapId, uint swapAmount) public {
        (bool success, bytes memory response) = tokenAddress.call(abi.encodeWithSignature("safeTransferFrom(address,address,uint256,uint256)", from, address(this), id, amount));
        emit eventIntrust(success, response);
        if (success == true) {
            emit eventReturn("GOOD intrust");
        } else {
            emit eventReturn("BAD intrust");
        }
        // SwapInfo memory swapInfo;
        // swapInfo.tokenAddress = swapAddress;
        // swapInfo.id = swapId;
        // swapInfo.amount = swapAmount;
        // mappingSwapInfo[msg.sender][tokenAddress] = swapInfo;
    }

    // function getTime1() public view returns(uint) {
    //     return block.timestamp;
    // }

    // uint nowId = keccak256("abc");
    // uint nowId = uint256(keccak256(abi.encodePacked(block.timestamp)));
    // function newRandomId() public {
    //     nowId = uint256(keccak256(abi.encodePacked(nowId)));
    // }
    // function getRandomId() public view returns(uint256) {
    //     return uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp)));
    // }

    // function setApprovalForAll(address tokenAddress) public returns(bool) {
    //     (bool success, bytes memory response) = tokenAddress.call(abi.encodeWithSignature("setApprovalForAll(address,address)", address(this), msg.sender));

    //     emit eventIntrust(success, response);
        // if (abi.decode(response, (bool)) == true) {
        //     emit eventReturn("Good ApprovalForAll");
        // } else {
        //     emit eventReturn("No ApprovalForAll");
        // }
    //     return success;
    // }

    // function isApprovalForAll(address token) public returns(bool) {
    //     (bool success, bytes memory response) = token.call(abi.encodeWithSignature("isApprovedForAll(address,address)", 0xFBfFA9f10a9fEEA871C47530507B676f92164bc4, address(this)));

    //     bool res = abi.decode(response, (bool));
        // bool res = true;
        // return res;
        // emit eventIntrust(success, response);
        // if (res == false) {
        //     emit eventReturn("NO ApprovalForAll");
        // }
        // if (res == true) {
        //     emit eventReturn("GOOD ApprovalForAll");
        // }
    // }
    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data) external override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address operator, address from, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}