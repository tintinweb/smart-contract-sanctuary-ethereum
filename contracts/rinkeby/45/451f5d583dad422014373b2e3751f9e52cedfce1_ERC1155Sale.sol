/**
 *Submitted for verification at Etherscan.io on 2022-05-26
*/

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

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

// File: openzeppelin-solidity/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: openzeppelin-solidity/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/2_Owner.sol


pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;





contract ERC1155Sale is Ownable{
    using Address for address;

    IERC1155 public nft;
    IERC20 public ERA;

    uint256 public FEE = 25; // fee in percentage * 10
    address public FeeRecipient;
    mapping(uint256 => BidData[]) public bids;
    struct BidData{
        address bidder;
        uint256 amount;
    }

    struct Auction {
        uint256 startPrice;
        uint256 endPrice;
        uint256 startTime;
        uint256 endTime;
    }

    struct Sale {
        uint256 tokenId;
        uint256 price;
        address payable seller;
        bool isActive;
        bool isAuction; //false sell with amount // true auction
        Auction auction;
    }

    Sale[] public sales;

    event New(uint256 indexed saleId, address indexed seller, uint256 indexed tokenId);
    event Cancel(uint256 indexed saleId, address indexed seller);
    event Buy(uint256 indexed saleId, address indexed seller, address indexed buyer, uint256 price);
    event Bid(uint256 indexed saleId, address indexed bidder, uint256 bidAmount);
    event CancelBid(uint256 indexed saleId, address indexed bidder);
    event AuctionFinished(uint256 indexed saleId, uint256 indexed state);
    // state 0 = expired with winner, 1 = expired without winner,  2 = winner bid the end price, 3 = auction cancelled
    constructor(IERC1155 _nft, IERC20 _ERA, address _FeeRecipient) public {
        nft = _nft;
        ERA = _ERA;
        FeeRecipient = _FeeRecipient;
    }

    modifier onlySeller(uint256 _saleId) {
        require(sales[_saleId].seller == msg.sender, "caller not seller");
        _;
    }

    modifier isActive(uint256 _saleId) {
        require(sales[_saleId].isActive, "sale already cancelled or bought");
        _;
    }


    modifier saleExists(uint256 _saleId) {
        require(sales.length >= _saleId, "sale doesn't exist");
        _;
    }

    function createSale(
        uint256 _tokenId,
        uint256 _price
    ) external {
        nft.safeTransferFrom(msg.sender, address(this), _tokenId, 1, "");
        Sale memory sale = Sale({
        tokenId: _tokenId,
        price: _price,
        seller: payable(msg.sender),
        isActive: true,
        isAuction: false,
        auction: Auction(0,0,0,0)
        });
        uint256 saleId = sales.length;
        sales.push(sale);
        emit New(saleId, msg.sender, _tokenId);
    }

    function createAuction(
        uint256 _tokenId,
        uint256 _startPrice,
        uint256 _endPrice,
        uint256 _startTime,
        uint256 _length
    ) external {
        nft.safeTransferFrom(msg.sender, address(this), _tokenId, 1, "");
        Sale memory sale = Sale({
        tokenId: _tokenId,
        price: 0,
        seller: payable(msg.sender),
        isActive: true,
        isAuction: true,
        auction: Auction({
        startPrice: _startPrice,
        endPrice: _endPrice,
        startTime: _startTime,
        endTime: _startTime + _length
        })
        });
        uint256 saleId = sales.length;
        sales.push(sale);
        emit New(saleId, msg.sender, _tokenId);
    }

    function cancelSale(uint256 _saleId) external saleExists(_saleId) onlySeller(_saleId) isActive(_saleId) {
        Sale memory sale = sales[_saleId];
        sales[_saleId].isActive = false;
        nft.safeTransferFrom(address(this), sale.seller, sale.tokenId, 1, "");
        if(sale.isAuction) {
            refundBids(_saleId);
            emit AuctionFinished(_saleId, 3);
        }
        emit Cancel(_saleId, msg.sender);
    }

    function buy(uint256 _saleId) external saleExists(_saleId) isActive(_saleId)  {
        Sale memory sale = sales[_saleId];
        require(!sale.isAuction, "cannot buy an auction");
        sales[_saleId].isActive = false;
        ERA.transferFrom(msg.sender, FeeRecipient, sale.price * FEE / 1000);
        ERA.transferFrom(msg.sender, sale.seller, sale.price * (1000 - FEE) / 1000);
        nft.safeTransferFrom(address(this), msg.sender, sale.tokenId, 1, "");
        emit Buy(_saleId, sale.seller, msg.sender, sale.price);
    }

    function bidAuction(uint256 _saleId, uint256 bidAmount) external saleExists(_saleId) isActive(_saleId){
        Sale memory sale = sales[_saleId];
        require(sale.isAuction, "Should bid on an auction");
        require(notAlreadyBid(_saleId, msg.sender), "you already bid on this auction");
        require(sale.auction.startTime <= block.timestamp && sale.auction.endTime >= block.timestamp, "auction is finished");
        require(bidAmount >= sale.auction.startPrice, "bid too low");
        if(sale.auction.endPrice > 0 && bidAmount >= sale.auction.endPrice) {
            sales[_saleId].isActive = false;
            ERA.transferFrom(msg.sender, FeeRecipient, sale.auction.endPrice * FEE / 1000);
            ERA.transferFrom(msg.sender, sale.seller, sale.auction.endPrice * (1000 - FEE) / 1000);
            nft.safeTransferFrom(address(this), msg.sender, sale.tokenId, 1, "");
            emit Buy(_saleId, sale.seller, msg.sender, sale.auction.endPrice);
            emit Bid(_saleId, msg.sender, sale.auction.endPrice);
            emit AuctionFinished(_saleId, 2);
            return;
        }
        BidData memory bid = BidData({
        bidder: msg.sender,
        amount: bidAmount
        });
        bids[_saleId].push(bid);
        ERA.transferFrom(msg.sender, address(this), bidAmount);
        emit Bid(_saleId, msg.sender, bidAmount);
    }

    function cancelBid(uint256 _saleId) external saleExists(_saleId) isActive(_saleId) {
        Sale memory sale = sales[_saleId];
        require(sale.isAuction, "sale is not an auction");
        require(!notAlreadyBid(_saleId, msg.sender), "you haven't bid on this auction");
        uint256 bidIndex = getBidIndex(_saleId, msg.sender);
        BidData memory bid = bids[_saleId][bidIndex];
        require(bid.amount > 0, "bid is already withdrawn");
        bid.amount = 0;
        ERA.transferFrom(address(this), msg.sender, bid.amount);
        emit CancelBid(_saleId, msg.sender);
    }

    function increaseBid(uint256 _saleId, uint256 amount) external saleExists(_saleId) isActive(_saleId){
        Sale memory sale = sales[_saleId];
        require(sale.isAuction, "sale is not an auction");
        require(!notAlreadyBid(_saleId, msg.sender), "you haven't bid on this auction");
        uint256 bidIndex = getBidIndex(_saleId, msg.sender);
        BidData memory bid = bids[_saleId][bidIndex];
        bid.amount += amount;
        require(bid.amount >= sale.auction.startPrice, "bid too low");
        ERA.transferFrom(msg.sender, address(this), amount);
        if(sale.auction.endPrice > 0 && bid.amount >= sale.auction.endPrice) {
            sales[_saleId].isActive = false;
            ERA.transfer(FeeRecipient, sale.auction.endPrice * FEE / 1000);
            ERA.transfer(sale.seller, sale.auction.endPrice * (1000 - FEE) / 1000);
            nft.safeTransferFrom(address(this), msg.sender, sale.tokenId, 1, "");
            emit Buy(_saleId, sale.seller, msg.sender, sale.auction.endPrice);
            emit Bid(_saleId, msg.sender, sale.auction.endPrice);
            emit AuctionFinished(_saleId, 2);
            return;
        }
        emit Bid(_saleId, msg.sender, bid.amount);
    }

    function finishAuction(uint256 _saleId) external saleExists(_saleId) isActive(_saleId){
        Sale memory sale = sales[_saleId];
        require(sale.isAuction, "sale is not an auction");
        require(sale.auction.endTime < block.timestamp, "auction is not finished yet");

        // find the highest bid amount
        uint256 highestBid = 0;
        uint256 highestBidIndex = 0;
        for(uint256 i = 0; i < bids[_saleId].length; i++) {
            BidData memory bid = bids[_saleId][i];
            if(bid.amount > highestBid) {
                highestBid = bid.amount;
                highestBidIndex = i;
            }
        }
        if(highestBid > 0) {
            BidData memory bid = bids[_saleId][highestBidIndex];
            bid.amount = 0;
            ERA.transfer(FeeRecipient, bid.amount * FEE / 1000);
            ERA.transfer(sale.seller, bid.amount * (1000 - FEE) / 1000);
            nft.safeTransferFrom(address(this), bid.bidder, sale.tokenId, 1, "");
            refundBids(_saleId);    // refund all other bids
            emit Buy(_saleId, sale.seller, bid.bidder, highestBid);
            emit AuctionFinished(_saleId, 0);
        }
        else {
            // no bids, so transfer the token to the seller
            nft.safeTransferFrom(address(this), sale.seller, sale.tokenId, 1, "");
            emit AuctionFinished(_saleId, 1);
        }
        sale.isActive = false;
    }

    function getBidIndex(uint256 _saleId, address _bidder) public view returns (uint256) {
        uint256 bidIndex = 0;
        for(; bidIndex < bids[_saleId].length; bidIndex++) {
            if(bids[_saleId][bidIndex].bidder == _bidder) {
                break;
            }
        }
        return bidIndex;
    }

    function notAlreadyBid(uint256 _saleId, address bidder) internal returns(bool) {
        for(uint256 i = 0; i < bids[_saleId].length; i++) {
            if(bids[_saleId][i].bidder == bidder) {
                return false;
            }
        }
        return true;
    }

    function refundBids(uint256 _saleId) internal saleExists(_saleId) {
        for (uint256 i = 0; i < bids[_saleId].length; i++) {
            BidData storage bid = bids[_saleId][i];
            if(bid.amount > 0) {
                ERA.transfer(bid.bidder, bid.amount);
            }
        }
    }

    // IMPLEMENT ERC1155 RECEIVER
    //
    /* solhint-disable no-unused-vars */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
    /* solhint-disable no-unused-vars */
}