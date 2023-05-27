// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/*
                                                 :::
                                             :: :::.
                       \/,                    .:::::
           \),          \`-._                 :::888
           /\            \   `-.             ::88888
          /  \            | .(                ::88
         /,.  \           ; ( `              .:8888
            ), \         / ;``               :::888
           /_   \     __/_(_                  :88
             `. ,`..-'      `-._    \  /      :8
               )__ `.           `._ .\/.
              /   `. `             `-._______m         _,
  ,-=====-.-;'                 ,  ___________/ _,-_,'"`/__,-.
 C   =--   ;                   `.`._    V V V       -=-'"#==-._
:,  \     ,|      UuUu _,......__   `-.__Ʌ_Ʌ_ -. ._ ,--._ ",`` `-
||  |`---' :    uUuUu,'          `'--...____/   `" `".   `
|`  :       \   UuUu:
:  /         \   UuUu`-._
 \(_          `._  uUuUu `-.
 (_3             `._  uUu   `._
                    ``-._      `.
                         `-._    `.
                             `.    \
                               )   ;
                              /   /
               `.        |\ ,'   /
                 ",_Ʌ_/\-| `   ,'
                   `--..,_|_,-'\
                          |     \
                          |      \__
                          |__

        wtf trogdor? https://www.youtube.com/watch?v=90X5NJleYJQ
        ascii sauce: https://github.com/asiansteev/trogdor
*/

contract Burninator {
    mapping(address => mapping(uint256 => uint256)) public offers;
    mapping(address => mapping(uint256 => mapping(address => uint256))) public donations;

    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    error AlreadyBurned();
    error DonationRequired();
    error InvalidOffer();
    error NoDonationToWithdraw();
    error NotTokenOwner();
    error TransferFailed();

    event Burninated(address indexed tokenAddress, uint256 indexed tokenId, address indexed acceptor);
    event Donation(address indexed tokenAddress, uint256 indexed tokenId, address indexed donor, uint256 amount);
    event Withdrawal(address indexed tokenAddress, uint256 indexed tokenId, address indexed donor, uint256 amount);

    /*
        Donate ether to encourage the burnination of a token
    */
    function donate(address tokenAddress, uint256 tokenId) external payable {
        if (msg.value == 0) revert DonationRequired();
        if (IERC721(tokenAddress).ownerOf(tokenId) == BURN_ADDRESS) revert AlreadyBurned();

        offers[tokenAddress][tokenId] += msg.value;
        donations[tokenAddress][tokenId][msg.sender] += msg.value;

        emit Donation(tokenAddress, tokenId, msg.sender, msg.value);
    }

    /*
        If you change your mind, withdraw before offer is accepted.
    */
    function withdraw(address tokenAddress, uint256 tokenId) external {
        if (donations[tokenAddress][tokenId][msg.sender] == 0) revert NoDonationToWithdraw();

        uint256 donation = donations[tokenAddress][tokenId][msg.sender];
        donations[tokenAddress][tokenId][msg.sender] = 0;
        offers[tokenAddress][tokenId] -= donation;

        (bool success, ) = payable(msg.sender).call{value: donation}("");
        if (!success) revert TransferFailed();

        emit Withdrawal(tokenAddress, tokenId, msg.sender, donation);
    }

    /*
        To accept the offer, first call approve or setApprovalForAll on your NFT's contract.

        Set minimumAmount to value of current offer to prevent frontrunning withdrawals.
    */
    function burninate(address tokenAddress, uint256 tokenId, uint256 minimumAmount) external {
        if (IERC721(tokenAddress).ownerOf(tokenId) != msg.sender) revert NotTokenOwner();
        if (offers[tokenAddress][tokenId] < minimumAmount) revert InvalidOffer();
        if (offers[tokenAddress][tokenId] == 0) revert InvalidOffer();

        uint256 amount = offers[tokenAddress][tokenId];
        offers[tokenAddress][tokenId] = 0;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) revert TransferFailed();

        IERC721(tokenAddress).transferFrom(msg.sender, BURN_ADDRESS, tokenId);

        emit Burninated(tokenAddress, tokenId, msg.sender);
    }
}

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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