/**
 *Submitted for verification at Etherscan.io on 2022-04-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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

contract CrowBot is ReentrancyGuard {

    struct Escrow {
        uint256 id;
        address maker;
        address token;
        address pair;
        uint256 protocol;
        string data;
        uint256 amount;
        uint256 timestamp;
        uint256 ends;
        uint256 mode;
        uint256 winners;
        uint256 gas;
        uint256 fee;
        bool closed;
        uint256 closedTimestamp;
    }

    uint256 public id = 0;
    address public OPERATOR;
    address public NFT = 0xc041b413ce4afC86FfBC9DbDCc0180742b44eC78;
    IERC721 public nft = IERC721(NFT);

    uint256 public gasPremium = 10 ** 16;
    uint256 public fee = 10 ** 16;

    uint256 public deposits = 0;
    uint256 public depositsTotal = 0;
    uint256 public fees = 0;
    uint256 public withdrawals = 0;

    mapping(uint256 => Escrow) private escrows;

    event OpenEscrow(uint256 indexed id);
    event CloseEscrow(uint256 indexed id);

    constructor() {
        OPERATOR = msg.sender;
    }

    function newEscrow(
        address _token,
        address _pair,
        uint256 _protocol,
        string memory _data,
        uint256 _amount,
        uint256 _ends,
        uint256 _mode,
        uint256 _winners
    ) nonReentrant external payable {
        require(nft.balanceOf(msg.sender) > 0);
        require(_ends > block.timestamp);
        require(msg.value == _amount + gasPremium + fee);
        deposits += msg.value;
        depositsTotal += msg.value + gasPremium + fee;
        fees += fee;
        payable(OPERATOR).transfer(gasPremium + fee);
        id++;
        escrows[id] = Escrow(id, msg.sender, _token, _pair, _protocol, _data, block.timestamp, _amount, _ends, _mode, _winners, gasPremium, fee, false, 0);
        emit OpenEscrow(id);
    }

    function releaseFunds(
        uint256 _id,
        address[] memory _winners,
        uint256 _amount
    ) nonReentrant external {
        require(msg.sender == OPERATOR);
        Escrow memory _escrow = escrows[_id];
        require(!_escrow.closed);
        uint256 winnersLength = _winners.length;
        require(_escrow.amount == _amount * winnersLength);
        require(_escrow.ends >= block.timestamp);
        for (uint256 i = 0; i < winnersLength; i++) {
            payable(_winners[i]).transfer(_amount);
        }
        withdrawals += _amount;
        escrows[_id].closed = true;
        escrows[_id].closedTimestamp = block.timestamp;
        emit CloseEscrow(id);
    }

    function changeOperator(
        address _operator
    ) nonReentrant external {
        require(msg.sender == OPERATOR);
        OPERATOR = _operator;
    }

    function changeNft(
        address _nft
    ) nonReentrant external {
        require(msg.sender == OPERATOR);
        NFT = _nft;
        nft = IERC721(_nft);
    }

    function changeGasPremium(
        uint256 _gasPremium
    ) nonReentrant external {
        require(msg.sender == OPERATOR);
        gasPremium = _gasPremium;
    }

    function changeFee(
        uint256 _fee
    ) nonReentrant external {
        require(msg.sender == OPERATOR);
        fee = _fee;
    }

    function retrieveEscrow(
        uint256 _id
    ) external view returns (Escrow memory) {
        return escrows[_id];
    }

    function retrieveEscrows() external view returns (Escrow[] memory) {
        Escrow[] memory res = new Escrow[](id);

        for (uint256 i = id; i > 0; i--) {
            Escrow storage e = escrows[i - 1];
            res[i] = e;
        }

        return res;
    }

    function retrieveEscrowsOpen() external view returns (Escrow[] memory) {
        uint256 hits = 0;

        for (uint256 i = id; i > 0; i--) {
            if (escrows[i - 1].closed == false) {
                hits += 1;
            }
        }

        Escrow[] memory res = new Escrow[](hits);

        for (uint256 i = id; i > 0; i--) {
            if (escrows[i - 1].closed == false) {
                Escrow storage e = escrows[i - 1];
                res[i] = e;
            }
        }

        return res;
    }

    function balance() external view returns (uint256) {
        return address(this).balance;
    }

    receive() external payable {}

}