/**
 *Submitted for verification at Etherscan.io on 2022-10-01
*/

// File: contracts/markt.sol

//SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

interface INFTContract {
    // --------------- ERC1155 -----------------------------------------------------

    /// @notice Get the balance of an account's tokens.
    /// @param _owner  The address of the token holder
    /// @param _id     ID of the token
    /// @return        The _owner's balance of the token type requested
    function balanceOf(address _owner, uint256 _id)
        external
        view
        returns (uint256);

    /// @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
    /// @dev MUST emit the ApprovalForAll event on success.
    /// @param _operator  Address to add to the set of authorized operators
    /// @param _approved  True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
    /// @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
    /// MUST revert if `_to` is the zero address.
    /// MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
    /// MUST revert on any other error.
    /// MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
    /// After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
    /// @param _from    Source address
    /// @param _to      Target address
    /// @param _id      ID of the token type
    /// @param _value   Transfer amount
    /// @param _data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external;

    /// @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `_to` address specified (with safety call).
    /// @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
    /// MUST revert if `_to` is the zero address.
    /// MUST revert if length of `_ids` is not the same as length of `_values`.
    /// MUST revert if any of the balance(s) of the holder(s) for token(s) in `_ids` is lower than the respective amount(s) in `_values` sent to the recipient.
    /// MUST revert on any other error.        
    /// MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
    /// Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
    /// After the above conditions for the transfer(s) in the batch are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).                      
    /// @param _from    Source address
    /// @param _to      Target address
    /// @param _ids     IDs of each token type (order and length must match _values array)
    /// @param _values  Transfer amounts per token type (order and length must match _ids array)
    /// @param _data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external;

    // ---------------------- ERC721 ------------------------------------------------

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param tokenId The identifier for an NFT
    /// @return owner  The address of the owner of the NFT
    function ownerOf(uint256 tokenId) external view returns (address owner);

    // function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external payable;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes calldata data
    ) external payable;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external payable;
}

pragma solidity =0.8.11;


// helps with sending the NFTs, will be particularly useful for batch operations
library NFTCommon {
    /**
     @notice Transfers the NFT tokenID from to.
     @dev safuTransferFrom name to avoid collision with the interface signature definitions. The reason it is implemented the way it is,
      is because some NFT contracts implement both the 721 and 1155 standard at the same time. Sometimes, 721 or 1155 function does not work.
      So instead of relying on the user's input, or listinging the contract what interface it implements, it is best to just make a good assumption
      about what NFT type it is (here we guess it is 721 first), and if that fails, we use the 1155 function to tranfer the NFT.
     @param nft     NFT address
     @param from    Source address
     @param to      Target address
     @param tokenID ID of the token type
     @param data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
    */
    function safeTransferFrom_(
        INFTContract nft,
        address from,
        address to,
        uint256 tokenID,
        bytes memory data
    ) internal returns (bool) {
        // most are 721s, so we assume that that is what the NFT type is
        try nft.safeTransferFrom(from, to, tokenID, data) {
            return true;
            // on fail, use 1155s format
        } catch (bytes memory) {
            try nft.safeTransferFrom(from, to, tokenID, 1, data) {
                return true;
            } catch (bytes memory) {
                return false;
            }
        }
    }

    /**
     @notice Determines if potentialOwner is in fact an owner of at least 1 qty of NFT token ID.
     @param nft NFT address
     @param potentialOwner suspected owner of the NFT token ID
     @param tokenID id of the token
     @return quantity of held token, possibly zero
    */
    function quantityOf(
        INFTContract nft,
        address potentialOwner,
        uint256 tokenID
    ) internal view returns (uint256) {
        try nft.ownerOf(tokenID) returns (address owner) {
            if (owner == potentialOwner) {
                return 1;
            } else {
                return 0;
            }
        } catch (bytes memory) {
            try nft.balanceOf(potentialOwner, tokenID) returns (
                uint256 amount
            ) {
                return amount;
            } catch (bytes memory) {
                return 0;
            }
        }
    }
}

pragma solidity =0.8.11;


interface IMarketplace {

    event CreateListing(
        address indexed nft,
        uint256 indexed tokenID,
        uint256 price
    );
    event CancelListing(address indexed nft, uint256 indexed tokenID);
    event AcceptListing(
        address indexed nft,
        uint256 indexed tokenID,
        uint256 price
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

    struct Listing {
        bool exists;
        address seller;
        uint256 price;
    }

    struct Bid {
        bool exists;
        address buyer;
        uint256 price;
    }

    function createListing(
        INFTContract nft,
        uint256 tokenID,
        uint256 price
    ) external;

    function createBid(
        INFTContract nft,
        uint256 tokenID,
        uint256 price
    ) external payable;

    function cancelListing(INFTContract nft, uint256 tokenID)
        external;

    function cancelBid(INFTContract nft, uint256 tokenID)
        external;

    function acceptListing(INFTContract nft, uint256 tokenID)
        external
        payable;

    function acceptBid(INFTContract nft, uint256 tokenID)
        external;

    function withdraw() external;
}

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: market/Marketplace.sol

 
pragma solidity =0.8.11;





// todo: think about how on transfer we can delete the listing of prev owner
// might not be necessary if we bake in checks, and if checks fail: delete
// todo: check out 0.8.9 custom types
contract IzzyNfts is IMarketplace {
    using Address for address payable;
    using NFTCommon for INFTContract;

    uint256 private currentFee = 1_000;
    uint256 private constant HUNDRED_PERCENT = 10_000;

    mapping(address => mapping(uint256 => Listing)) private listings;
    mapping(address => mapping(uint256 => Bid)) private bids;
    mapping(address => uint256) private escrow;

    function getListing(address nft, uint256 tokenId) public view returns (Listing memory) {
        return listings[nft][tokenId];
    }

    function getBid(address nft, uint256 tokenId) public view returns (Bid memory) {
        return bids[nft][tokenId];
    }

    function getEscrow(address sender) public view returns (uint256) {
        return escrow[sender];
    }

    function getCurrentFee() public view returns (uint256) {
        return currentFee/100;
    }

    // =====================================================================

    address payable public beneficiary;
    address admin;

    // =====================================================================

    string private constant REVERT_NOT_OWNER_OF_TOKEN_ID =
        "Marketplace::not an owner of token ID";
    string private constant REVERT_OWNER_OF_TOKEN_ID =
        "Marketplace::owner of token ID";
    string private constant REVERT_BID_TOO_LOW = "Marketplace::bid too low";
    string private constant REVERT_NOT_A_CREATOR_OF_BID =
        "Marketplace::not a creator of the bid";
    string private constant REVERT_NOT_A_CREATOR_OF_ASK =
        "Marketplace::not a creator of the listing";
    string private constant REVERT_ASK_DOES_NOT_EXIST =
        "Marketplace::listing does not exist";
    string private constant REVERT_CANT_ACCEPT_OWN_ASK =
        "Marketplace::cant accept own listing";
    string private constant REVERT_ASK_IS_RESERVED =
        "Marketplace::listing is reserved";
    string private constant REVERT_ASK_INSUFFICIENT_VALUE =
        "Marketplace::listing price higher than sent value";
    string private constant REVERT_ASK_SELLER_NOT_OWNER =
        "Marketplace::listing creator not owner";
    string private constant REVERT_NFT_NOT_SENT = "Marketplace::NFT not sent";
    string private constant REVERT_INSUFFICIENT_ETHER =
        "Marketplace::insufficient ether sent";

    // =====================================================================

    constructor(address payable newBeneficiary) {
        beneficiary = newBeneficiary;
        admin = msg.sender;
    }

    /// @dev Hook that is called before any token transfer.
    function _takeFee(uint256 totalPrice)
        internal
        virtual
        returns (uint256)
    {
        uint256 cut = (totalPrice * currentFee) / HUNDRED_PERCENT;
        require(cut < totalPrice, "");
        escrow[beneficiary] += cut;
        uint256 left = totalPrice - cut;
        return left;
    }

    function changeFee(uint256 newFee) external {
        require(msg.sender == admin, "");
        require(newFee < HUNDRED_PERCENT, "");
        currentFee = newFee;
    }

    // ======= CREATE ASK / BID ============================================

    /// @notice Creates an listing for (`nft`, `tokenID`) tuple for `price`, which can
    /// be reserved for `to`, if `to` is not a zero address.
    /// @dev Creating an listing requires msg.sender to have at least one qty of
    /// (`nft`, `tokenID`).
    /// @param nft     An array of ERC-721 and / or ERC-1155 addresses.
    /// @param tokenID Token Ids of the NFTs msg.sender wishes to sell.
    /// @param price   Prices at which the seller is willing to sell the NFTs.
    /// then anyone can accept.
    function createListing(
        INFTContract  nft,
        uint256  tokenID,
        uint256  price
    ) external override {
            require(
                nft.quantityOf(msg.sender, tokenID) > 0,
                REVERT_NOT_OWNER_OF_TOKEN_ID
            );
            // if feecollector extension applied, this ensures math is correct
            require(price > 10_000, "price too low");

            // overwrites or creates a new one
            listings[address(nft)][tokenID] = Listing({
                exists: true,
                seller: msg.sender,
                price: price
            });

            emit CreateListing({
                nft: address(nft),
                tokenID: tokenID,
                price: price
            });
    }

     /// @notice Creates a bid on (`nft`, `tokenID`) tuple for `price`.
     /// @param nft     An array of ERC-721 and / or ERC-1155 addresses.
     /// @param tokenID Token Ids of the NFTs msg.sender wishes to buy.
     /// @param price   Prices at which the buyer is willing to buy the NFTs.
    function createBid(
        INFTContract  nft,
        uint256  tokenID,
        uint256  price
    ) external payable override {
        uint256 totalPrice = 0;

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
                escrow[bids[nftAddress][tokenID].buyer] += bids[nftAddress][
                    tokenID
                ].price;
            }

            // overwrites or creates a new one
            bids[nftAddress][tokenID] = Bid({
                exists: true,
                buyer: msg.sender,
                price: price
            });

            emit CreateBid({
                nft: nftAddress,
                tokenID: tokenID,
                price: price
            });

            totalPrice += price;

        require(totalPrice == msg.value, REVERT_INSUFFICIENT_ETHER);
    }

    // ======= CANCEL ASK / BID ============================================

    /// @notice Cancels listing(s) that the seller previously created.
    /// @param nft     An array of ERC-721 and / or ERC-1155 addresses.
    /// @param tokenID Token Ids of the NFTs msg.sender wishes to cancel the
    /// listings on.
    function cancelListing(INFTContract  nft, uint256  tokenID)
        external
        override
    {
            address nftAddress = address(nft);
            require(
                listings[nftAddress][tokenID].seller == msg.sender,
                REVERT_NOT_A_CREATOR_OF_ASK
            );

            delete listings[nftAddress][tokenID];

            emit CancelListing({nft: nftAddress, tokenID: tokenID});
    }

    /// @notice Cancels bid(s) that the msg.sender previously created.
    /// @param nft     An array of ERC-721 and / or ERC-1155 addresses.
    /// @param tokenID Token Ids of the NFTs msg.sender wishes to cancel the
    /// bids on.
    function cancelBid(INFTContract  nft, uint256  tokenID)
        external
        override
    {
            address nftAddress = address(nft);
            require(
                bids[nftAddress][tokenID].buyer == msg.sender,
                REVERT_NOT_A_CREATOR_OF_BID
            );

            escrow[msg.sender] += bids[nftAddress][tokenID].price;

            delete bids[nftAddress][tokenID];

            emit CancelBid({nft: nftAddress, tokenID: tokenID});
    }

    // ======= ACCEPT ASK / BID ===========================================

    /// @notice Seller placed listing(s), you (buyer) are fine with the terms. You accept
    /// their listing by sending the required msg.value and indicating the id of the
    /// token(s) you are purchasing.
    /// @param nft     An array of ERC-721 and / or ERC-1155 addresses.
    /// @param tokenID Token Ids of the NFTs msg.sender wishes to accept the
    /// listings on.
    function acceptListing(INFTContract  nft, uint256  tokenID)
        external
        payable
        override
    {
        uint256 totalPrice = 0;
            address nftAddress = address(nft);

            require(
                listings[nftAddress][tokenID].exists,
                REVERT_ASK_DOES_NOT_EXIST
            );
            require(
                listings[nftAddress][tokenID].seller != msg.sender,
                REVERT_CANT_ACCEPT_OWN_ASK
            );
            
            require(
                nft.quantityOf(
                    listings[nftAddress][tokenID].seller,
                    tokenID
                ) > 0,
                REVERT_ASK_SELLER_NOT_OWNER
            );

            totalPrice += listings[nftAddress][tokenID].price;

            escrow[listings[nftAddress][tokenID].seller] += _takeFee(
                listings[nftAddress][tokenID].price
            );

            // if there is a bid for this tokenID from msg.sender, cancel and refund
            if (bids[nftAddress][tokenID].buyer == msg.sender) {
                escrow[bids[nftAddress][tokenID].buyer] += bids[nftAddress][
                    tokenID
                ].price;
                delete bids[nftAddress][tokenID];
            }

            emit AcceptListing({
                nft: nftAddress,
                tokenID: tokenID,
                price: listings[nftAddress][tokenID].price
            });

            bool success = nft.safeTransferFrom_(
                listings[nftAddress][tokenID].seller,
                msg.sender,
                tokenID,
                new bytes(0)
            );
            require(success, REVERT_NFT_NOT_SENT);

            delete listings[nftAddress][tokenID];

        require(totalPrice == msg.value, REVERT_ASK_INSUFFICIENT_VALUE);
    }

    /// @notice You are the owner of the NFTs, someone submitted the bids on them.
    /// You accept one or more of these bids.
    /// @param nft     An array of ERC-721 and / or ERC-1155 addresses.
    /// @param tokenID Token Ids of the NFTs msg.sender wishes to accept the
    /// bids on.
    function acceptBid(INFTContract  nft, uint256  tokenID)
        external
        override
    {
        uint256 escrowDelta = 0;
            require(
                nft.quantityOf(msg.sender, tokenID) > 0,
                REVERT_NOT_OWNER_OF_TOKEN_ID
            );

            address nftAddress = address(nft);

            escrowDelta += bids[nftAddress][tokenID].price;
            // escrow[msg.sender] += bids[nftAddress][tokenID].price;

            emit AcceptBid({
                nft: nftAddress,
                tokenID: tokenID,
                price: bids[nftAddress][tokenID].price
            });

            bool success = nft.safeTransferFrom_(
                msg.sender,
                bids[nftAddress][tokenID].buyer,
                tokenID,
                new bytes(0)
            );
            require(success, REVERT_NFT_NOT_SENT);

            delete listings[nftAddress][tokenID];
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

    /// @dev Used to change the address of the trade currentFee receiver.
    function changeBeneficiary(address payable newBeneficiary) external {
        require(msg.sender == admin, "");
        require(newBeneficiary != payable(address(0)), "");
        beneficiary = newBeneficiary;
    }

    /// @dev sets the admin to the zero address. This implies that beneficiary
    /// address and other admin only functions are disabled.
    function revokeAdmin() external {
        require(msg.sender == admin, "");
        admin = address(0);
    }

    // ============ EXTENSIONS =============================================

    /// @dev Hook that is called to collect the fees in FeeCollector extension.
    /// Plain implementation of marketplace (without the FeeCollector extension)
    /// has no fees.
    /// @param totalPrice Total price payable for the trade(s).
    
}