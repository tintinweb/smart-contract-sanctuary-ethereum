// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
pragma solidity 0.8.18;

/*
* https://twitter.com/HackoorsNFT
*
*                                             ..?!~~~?..
*                                          :GPY^..   ^~#BP:
*                                        ^[email protected]@@P     .^#@@#&B^
*                                      .B&&&B~      :B&@@@@@&B.
*                                     !5?~!:  .    ::^^#@@#7^J5!
*                                   :&@@&PY!.:^.   ::::#@B!.~P&@&:
*                                  ^&G5P7:::^:.    ..::J7:..:^~7B&^
*                                  5G^::.:.                   :5&@5
*                                 [email protected]^..    :??????????????:     [email protected]
*                                 [email protected]!. ~B&&@@@@@@@@@@@@@@@@&&#?^^[email protected]?
*                                 [email protected]&&&@@@@@@@@@@@@@@@@@@@@@@@@@&&@?
*                                 [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@?
*                                 [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@?
*                                 [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@?
*                                 ^#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#^
*                            :.7::~5&@@@@@@@@@@@@@@@@@@@@@@@@@@@@&5~::7.:
*                          :??.     :Y&@@@@@@@@@@@@@@@@@@@@@@@@&Y:     .??:
*                        ^?^          :^^[email protected]@@@@@@@@@@@@@@@@@@#J:          ^?^
*                       ~?   ..   ...   .:[email protected]@@@@@@@@@@@@@@@#7:   ...  ..7.  ?~
*                      !5.  [email protected]&Y:   :::.75P#@@@&&&&&&&&@@@@#Y7.:::   :#&@7  ~#!
*                     !J:::[email protected]@@&5^..^:::[email protected]@@&~^^^^^^~&@@@B?:::^..^5&@@G~:...?!
*                    7!  .:[email protected]@@@&&&&5YYJYB&@&#JJJJJJ#&@&BYJYY5&&&&@@@@PY!^:  !7
*                   ~?.!YJG&==============================================&&&B!.?~
*                  :&[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@P~!~!B&:
*                  JGP&@@&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&@@&PGJ
*                 [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@57P5GB77?
*                ~J~^^:::[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@5.:.:!P~J~
*                JG&P~^:::[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B!::^[email protected]&GJ
*                [email protected]@@&&G57:[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Y:7B&@@@@@J
*                ~&@@@@@@@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@@@@&~
*                  ?BB#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#BB?
*                      ^:::[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@J:::^
*                           [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@~
*                              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
*/

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Puzzle1 {

    bytes32 constant ANSWERHASH = 0x5a179a9544e458d768dc16529d9d04e538d7aa4f3c8398c66aa09db48fe216e6;
    IERC721 constant HACKOORS = IERC721(0x72f7DBe108257e47370869cDb73D18680E4CFA83);
    IERC721 constant HMDT = IERC721(0xdf0F0A5508Aa4f506e5bDC8C45C8879E6E80d3e4);

    constructor() payable {}

    error NoEligibleNFTsOwned();
    error WrongAnswer();

    function claim(string calldata answer) external {

        _checkNFTHoldings();

        if (keccak256(abi.encode(answer)) != ANSWERHASH) revert WrongAnswer();
        payable(msg.sender).transfer(address(this).balance);
    }

    function _checkNFTHoldings() internal view {
        if (HACKOORS.balanceOf(msg.sender) == 0 && HMDT.balanceOf(msg.sender) == 0) revert NoEligibleNFTsOwned();
    }

    receive() external payable {}
}