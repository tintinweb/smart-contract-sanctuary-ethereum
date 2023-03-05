//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract PokerMRC {
    IERC721 private immutable MRC;

    event WalletPaid(address wallet, uint256 tokenId);

    uint256 public max_players;
    uint256 public current_players;
    uint256 public entrance_price;
    bool public closed;

    /// @notice Mapping of wallet to tokenIds that have been paid
    mapping(address => uint256[]) public wallet_paid;

    /// @notice Mapping of tokenId to wallet that has paid
    mapping(uint256 => address) public mrc_paid;

    mapping(address => bool) public is_admin;

    modifier onlyAdmin() {
        require(is_admin[msg.sender]);
        _;
    }

    constructor(uint256 _max_players, uint256 _entrance_price, address _mrc) {
        is_admin[msg.sender] = true;
        setMaxPlayers(_max_players);
        setEntrancePrice(_entrance_price);
        MRC = IERC721(_mrc);
    }

    function redeemMRC(uint256 tokenId) external payable {
        _isAllowedRequire();

        require(
            MRC.ownerOf(tokenId) == msg.sender,
            "PokerMRC: You do not own this MRC"
        );
        require(
            mrc_paid[tokenId] == address(0),
            "PokerMRC: This MRC has already been redeemed"
        );

        ++current_players;
        mrc_paid[tokenId] = msg.sender;
        wallet_paid[msg.sender].push(tokenId);

        emit WalletPaid(msg.sender, tokenId);
    }

    ///////////////////////
    /// Admin functions ///
    ///////////////////////

    /**
     * @param wallet Address of the wallet to be set as admin
     * @param value Boolean value to set the admin status
     */
    function setAdmin(address wallet, bool value) public onlyAdmin {
        is_admin[wallet] = value;
    }

    /**
     * @param new_max_players New max players for the tournament
     */
    function setMaxPlayers(uint256 new_max_players) public onlyAdmin {
        max_players = new_max_players;
    }

    /**
     * @param new_entrance_price New entrance price for the tournament
     */
    function setEntrancePrice(uint256 new_entrance_price) public onlyAdmin {
        entrance_price = new_entrance_price;
    }

    /**
     * @param _closed Boolean closed status of the tournament
     */
    function close(bool _closed) public onlyAdmin {
        closed = _closed;
    }

    /**
     * @notice Withdraws all MATIC from the contract to the msg.sender
     */
    function withdraw() public payable onlyAdmin {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "PokerMRC: Withdraw not successful");
    }

    ////////////////////////
    /// Helper functions ///
    ////////////////////////

    function _isAllowedRequire() private {
        require(msg.value >= entrance_price, "PokerMRC: Not enough MATIC");
        require(current_players < max_players, "PokerMRC: Pool is full");
        require(closed == false, "PokerMRC: Tournament is closed");
    }

    //////////////////////
    /// View functions ///
    //////////////////////

    function hasPaid(address wallet) public view returns (bool) {
        return wallet_paid[wallet].length > 0;
    }

    function isMrcPaid(uint256 tokenId) public view returns (bool) {
        return mrc_paid[tokenId] != address(0);
    }

    function getEntrancePrice() public view returns (uint256) {
        return entrance_price;
    }

    function getMaxPlayers() public view returns (uint256) {
        return max_players;
    }

    function getCurrentPlayers() public view returns (uint256) {
        return current_players;
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