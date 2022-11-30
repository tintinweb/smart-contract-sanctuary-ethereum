/**
 *Submitted for verification at Etherscan.io on 2022-11-30
*/

//SPDX-License-Identifier: UNLICENSED

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity >=0.7.0 <0.9.0;

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

library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}


interface IMarketplace {
    event CreateAsk(
        address indexed nft,
        uint256 indexed tokenID,
        uint256 price,
        address indexed to
    );
    event CancelAsk(address indexed nft, uint256 indexed tokenID);
    event AcceptAsk(
        address indexed nft,
        uint256 indexed tokenID,
        uint256 price,
        address indexed to
    );

    event CreateBid(
        address indexed nft,
        uint256 indexed tokenID,
        uint256 price
    );
    event CancelBid(address indexed nft, uint256 indexed tokenID);
    event AcceptBid(
        address indexed nft,
        uint256 indexed tokenID,
        uint256 price
    );

    struct Ask {
        bool exists;
        address seller;
        uint256 price;
        address to;
    }

    struct Bid {
        bool exists;
        address buyer;
        uint256 price;
    }

    function createAsk(
        IERC721 nft,
        uint256 tokenID,
        uint256 price,
        address to
    ) external;

    function createBid(
        IERC721 nft,
        uint256 tokenID,
        uint256 price
    ) external payable;

    function cancelAsk(IERC721 nft, uint256 tokenID) external;

    function cancelBid(IERC721 nft, uint256 tokenID) external;

    function acceptAsk(IERC721 nft, uint256 tokenID) external payable;

    function acceptBid(IERC721 nft, uint256 tokenID) external;

    function withdraw() external;
}

contract Marketplace is IMarketplace {
    using Address for address payable;

    mapping(address => mapping(uint256 => Ask)) public asks;
    mapping(address => mapping(uint256 => Bid)) public bids;
    mapping(address => uint256) public escrow;

    // =====================================================================

    address payable beneficiary;
    address admin;

    // =====================================================================

    // =====================================================================

    string public constant REVERT_NOT_OWNER_OF_TOKEN_ID =
        "Marketplace::not an owner of token ID";
    string public constant REVERT_OWNER_OF_TOKEN_ID =
        "Marketplace::owner of token ID";
    string public constant REVERT_BID_TOO_LOW = "Marketplace::bid too low";
    string public constant REVERT_NOT_A_CREATOR_OF_BID =
        "Marketplace::not a creator of the bid";
    string public constant REVERT_NOT_A_CREATOR_OF_ASK =
        "Marketplace::not a creator of the ask";
    string public constant REVERT_ASK_DOES_NOT_EXIST =
        "Marketplace::ask does not exist";
    string public constant REVERT_CANT_ACCEPT_OWN_ASK =
        "Marketplace::cant accept own ask";
    string public constant REVERT_ASK_IS_RESERVED =
        "Marketplace::ask is reserved";
    string public constant REVERT_ASK_INSUFFICIENT_VALUE =
        "Marketplace::ask price higher than sent value";
    string public constant REVERT_ASK_SELLER_NOT_OWNER =
        "Marketplace::ask creator not owner";
    string public constant REVERT_NFT_NOT_SENT = "Marketplace::NFT not sent";
    string public constant REVERT_INSUFFICIENT_ETHER =
        "Marketplace::insufficient ether sent";

    // =====================================================================

    constructor(address payable newBeneficiary) {
        beneficiary = newBeneficiary;
        admin = msg.sender;
    }

    // ======= CREATE ASK ============================================

    /// @notice Creates an ask for (`nft`, `tokenID`) tuple for `price`, which can be reserved for `to`, if `to` is not a zero address.
    /// @dev Creating an ask requires msg.sender to have at least one qty of (`nft`, `tokenID`).
    /// @param nft     An array of ERC-721 addresses.
    /// @param tokenID Token Ids of the NFTs msg.sender wishes to sell.
    /// @param price   Prices at which the seller is willing to sell the NFTs.
    /// @param to      Addresses for which the sale is reserved. If zero address, then anyone can accept.
    function createAsk(
        IERC721 nft,
        uint256 tokenID,
        uint256 price,
        address to
    ) external override {
        require(
            nft.ownerOf(tokenID) == msg.sender,
            REVERT_NOT_OWNER_OF_TOKEN_ID
        );
        // if feecollector extension applied, this ensures math is correct
        require(price > 10_000, "price too low");

        // overwristes or creates a new one
        asks[address(nft)][tokenID] = Ask({
            exists: true,
            seller: msg.sender,
            price: price,
            to: to
        });

        emit CreateAsk({
            nft: address(nft),
            tokenID: tokenID,
            price: price,
            to: to
        });
    }

    // ======= Cancel ASK ============================================

    /// @notice Cancels ask(s) that the seller previously created.
    /// @param nft     An array of ERC-721 and / or ERC-1155 addresses.
    /// @param tokenID Token Ids of the NFTs msg.sender wishes to cancel the asks on.
    function cancelAsk(IERC721 nft, uint256 tokenID) external override {
        address nftAddress = address(nft);
        require(
            asks[nftAddress][tokenID].seller == msg.sender,
            REVERT_NOT_A_CREATOR_OF_ASK
        );

        delete asks[nftAddress][tokenID];

        emit CancelAsk({nft: nftAddress, tokenID: tokenID});
    }

    // ======= ACCEPT ASK ===========================================

    /// @notice Seller placed ask(s), you (buyer) are fine with the terms. You accept their ask by sending the required msg.value and indicating the id of the token(s) you are purchasing.
    /// @param nft     An array of ERC-721 and / or ERC-1155 addresses.
    /// @param tokenID Token Ids of the NFTs msg.sender wishes to accept the asks on.
    function acceptAsk(IERC721 nft, uint256 tokenID) external payable override {
        uint256 totalPrice = 0;
        address nftAddress = address(nft);

        require(asks[nftAddress][tokenID].exists, REVERT_ASK_DOES_NOT_EXIST);
        require(
            asks[nftAddress][tokenID].seller != msg.sender,
            REVERT_CANT_ACCEPT_OWN_ASK
        );
        if (asks[nftAddress][tokenID].to != address(0)) {
            require(
                asks[nftAddress][tokenID].to == msg.sender,
                REVERT_ASK_IS_RESERVED
            );
        }
        require(
            nft.ownerOf(tokenID) == asks[nftAddress][tokenID].seller,
            REVERT_ASK_SELLER_NOT_OWNER
        );

        totalPrice += asks[nftAddress][tokenID].price;

        escrow[asks[nftAddress][tokenID].seller] += _takeFee(
            asks[nftAddress][tokenID].price
        );

        require(totalPrice == msg.value, REVERT_ASK_INSUFFICIENT_VALUE);

        // if there is a bid for this tokenID from msg.sender, cancel and refund
        if (bids[nftAddress][tokenID].buyer == msg.sender) {
            escrow[bids[nftAddress][tokenID].buyer] += bids[nftAddress][tokenID]
                .price;
            delete bids[nftAddress][tokenID];
        }

        emit AcceptAsk({
            nft: nftAddress,
            tokenID: tokenID,
            price: asks[nftAddress][tokenID].price,
            to: asks[nftAddress][tokenID].to
        });

        nft.safeTransferFrom(
            asks[nftAddress][tokenID].seller,
            msg.sender,
            tokenID,
            new bytes(0)
        );

        delete asks[nftAddress][tokenID];
    }

    // ======= Create Bid ===========================================

    /// @notice Creates a bid on (`nft`, `tokenID`) tuple for `price`.
    /// @param nft     An ERC-721 addresses.
    /// @param tokenID Token Ids of the NFTs msg.sender wishes to buy.
    /// @param price   Prices at which the buyer is willing to buy the NFTs.
    function createBid(
        IERC721 nft,
        uint256 tokenID,
        uint256 price
    ) external payable override {
        address nftAddress = address(nft);
        // bidding on own NFTs is possible. But then again, even if we wanted to disallow it,
        // it would not be an effective mechanism, since the agent can bid from his other
        // wallets
        require(
            msg.value > bids[nftAddress][tokenID].price,
            REVERT_BID_TOO_LOW
        );

        // if bid existed, let the prev. creator withdraw their bid. new overwrites
        if (bids[nftAddress][tokenID].exists) {
            escrow[bids[nftAddress][tokenID].buyer] += bids[nftAddress][tokenID]
                .price;
        }

        // overwrites or creates a new one
        bids[nftAddress][tokenID] = Bid({
            exists: true,
            buyer: msg.sender,
            price: price
        });

        emit CreateBid({nft: nftAddress, tokenID: tokenID, price: price});
    }

    // ======= Cancel Bid ===========================================

    /// @notice Cancels bid(s) that the msg.sender previously created.
    /// @param nft     ERC-721 addresse.
    /// @param tokenID Token Ids of the NFTs msg.sender wishes to cancel the bids on.
    function cancelBid(IERC721 nft, uint256 tokenID) external override {
        address nftAddress = address(nft);
        require(
            bids[nftAddress][tokenID].buyer == msg.sender,
            REVERT_NOT_A_CREATOR_OF_BID
        );

        escrow[msg.sender] += bids[nftAddress][tokenID].price;

        delete bids[nftAddress][tokenID];

        emit CancelBid({nft: nftAddress, tokenID: tokenID});
    }

    /// @notice You are the owner of the NFTs, someone submitted the bids on them. You accept one or more of these bids.
    /// @param nft     An ERC-721 addresses.
    /// @param tokenID Token Ids of the NFTs msg.sender wishes to accept the bids on.
    function acceptBid(IERC721 nft, uint256 tokenID) external override {
        uint256 escrowDelta = 0;

        require(
            nft.ownerOf(tokenID) == msg.sender,
            REVERT_NOT_OWNER_OF_TOKEN_ID
        );

        address nftAddress = address(nft);

        escrowDelta += bids[nftAddress][tokenID].price;

        emit AcceptBid({
            nft: nftAddress,
            tokenID: tokenID,
            price: bids[nftAddress][tokenID].price
        });

        nft.safeTransferFrom(
            msg.sender,
            bids[nftAddress][tokenID].buyer,
            tokenID,
            new bytes(0)
        );

        delete asks[nftAddress][tokenID];
        delete bids[nftAddress][tokenID];

        uint256 remaining = _takeFee(escrowDelta);
        escrow[msg.sender] = remaining;
    }

    /// @notice Sellers can receive their payment by calling this function.
    function withdraw() external override {
        uint256 amount = escrow[msg.sender];
        escrow[msg.sender] = 0;
        payable(address(msg.sender)).sendValue(amount);
    }

    // ============ ADMIN ==================================================

    /// @dev Used to change the address of the trade fee receiver.
    function changeBeneficiary(address payable newBeneficiary) external {
        require(msg.sender == admin, "");
        require(newBeneficiary != payable(address(0)), "");
        beneficiary = newBeneficiary;
    }

    /// @dev sets the admin to the zero address. This implies that beneficiary address and other admin only functions are disabled.
    function revokeAdmin() external {
        require(msg.sender == admin, "");
        admin = address(0);
    }

    // ============ EXTENSIONS =============================================

    /// @dev Hook that is called to collect the fees in FeeCollector extension. Plain implementation of marketplace (without the FeeCollector extension) has no fees.
    /// @param totalPrice Total price payable for the trade(s).
    function _takeFee(uint256 totalPrice) internal virtual returns (uint256) {
        return totalPrice;
    }
}