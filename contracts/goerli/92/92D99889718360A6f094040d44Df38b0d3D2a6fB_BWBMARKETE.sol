// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";


contract BWBMARKETE is IERC721Receiver,  Ownable {

    using Address for address payable;
    using Counters for Counters.Counter;

    address payable private feeAddr;
    Counters.Counter private auctionIds;

    enum iType { ERCNon , ERC721Type , ERC1155Type }
    
    constructor() {
        feeAddr = payable(msg.sender);
        
    }

    struct auction {
        address  payable _Seller;
        address  payable _HighestBidder;
        uint256 _HighestBid;
        uint256 _auctionId;
        uint256 _endTime;
        bool    _Started;
        bool    _Ended;
    }

    mapping(address => mapping(uint256 => auction)) _auctionInfo;
    mapping(address => uint256) _bidsAmount;

     uint256 private auctionEndTime;

    event Start(address , uint256 , auction);
    event Bid (address , uint256 , auction);
    event End (address , uint256 , address ,address , uint256);
    event Cancel (address, uint256 , address , uint256);

    modifier isStart(address _NFTAddress , uint256 _TokenID , uint256 _startPrice) {
        require(_auctionInfo[_NFTAddress][_TokenID]._Started == false , "Auction already started.");
        require(msg.sender == IERC721(_NFTAddress).ownerOf(_TokenID) , "MSG.SENDER is not the owner");
        require(_startPrice > 0 , "StartPrice must be greater than 0");
        _;
    }

    modifier isBid(address _NFTAddress , uint256 _TokenID , uint256 _BidPrice) {
        require(_auctionInfo[_NFTAddress][_TokenID]._Started == true , "NFT not started");
        require(_auctionInfo[_NFTAddress][_TokenID]._HighestBid < _BidPrice , "msg.value must be greater than highestbid");
        require(msg.value == fee(_BidPrice) , "msg.value is not (price + fee)");
        require(_auctionInfo[_NFTAddress][_TokenID]._endTime > block.timestamp , "auction ended" );
        _;
    }

    modifier idEnd(address _NFTAddress , uint256 _TokenID) {
        require(_auctionInfo[_NFTAddress][_TokenID]._Started == true && 
                _auctionInfo[_NFTAddress][_TokenID]._Ended == false, "Action not started or Auction already ended");
        
        require(_auctionInfo[_NFTAddress][_TokenID]._endTime <= block.timestamp , "Auction is still ongoing");
        _;
    }

    modifier onlyAuctionSeller(address _NFTAddress , uint256 _TokenID) {
        require (_auctionInfo[_NFTAddress][_TokenID]._Seller  == msg.sender || msg.sender == owner() , "MSG.SENDER is not NFT Seller.");
        require (_auctionInfo[_NFTAddress][_TokenID]._HighestBidder == address(0) , "Aleady biding");
        _;
    }
    

    function onERC721Received(address , address , uint256 , bytes calldata ) public virtual override returns (bytes4) {
	
        return this.onERC721Received.selector;
    }

    function auctionStart(address _NFTAddress , uint256 _TokenID , uint256 _startPrice) public 
        isStart(_NFTAddress , _TokenID , _startPrice)
    {

        uint256 auctionId = auctionIds.current();
        auctionIds.increment();

        auction memory _auction = auction({
            _Seller         : payable(msg.sender),
            _HighestBidder  : payable(address(0)),
            _HighestBid     : _startPrice,
            _auctionId      : auctionId,
            _endTime        : block.timestamp + 5 minutes, // 1667030400 (2022-10-29 17:00:00)
            _Started        : true,
            _Ended          : false
        });

        _auctionInfo[_NFTAddress][_TokenID] = _auction;

        IERC721(_NFTAddress).safeTransferFrom(msg.sender, address(this), _TokenID);

        emit Start(_NFTAddress , _TokenID , _auctionInfo[_NFTAddress][_TokenID]);
    }
    
    function setAuctionEndTime (uint256 _auctionEndTime) public onlyOwner{
        require (_auctionEndTime <= block.timestamp , "endtime greater than block.timestamp");
        auctionEndTime =  _auctionEndTime;
    }

    function getAuctionEndTime () public view returns (uint256) {
        return auctionEndTime;
    }

    function autionNFTOf(address _NFTAddress , uint256 _TokenID) public view returns(auction memory _auction) {
        auction memory a = _auctionInfo[_NFTAddress][_TokenID];
        return a;
    }

    function auctionCancel (address _NFTAddress , uint256 _TokenID ) public 
        onlyAuctionSeller(_NFTAddress , _TokenID)
    {
        auction storage c = _auctionInfo[_NFTAddress][_TokenID];

        uint256 auctionId = c._auctionId;

        IERC721(_NFTAddress).safeTransferFrom(address(this) , msg.sender , _TokenID);

        c._Seller = payable(address(0));
        c._Started = false;
        c._endTime = 0;
        c._HighestBid = 0;
        c._auctionId = 0;

        emit Cancel(_NFTAddress , _TokenID , msg.sender , auctionId);
    }

    function bid( address _NFTAddress , uint256 _TokenID , uint256 _BidPrice) public payable 
        isBid(_NFTAddress , _TokenID , _BidPrice)
    {
        
        auction storage c = _auctionInfo[_NFTAddress][_TokenID];

        if (c._HighestBidder != address(0)){
            
            uint256 amount = _bidsAmount[c._HighestBidder];
            _bidsAmount[c._HighestBidder] = 0;
            c._HighestBidder.sendValue(amount);   
        }

        c._HighestBidder = payable(msg.sender);
        c._HighestBid = _BidPrice;

        _bidsAmount[msg.sender] = msg.value;

        emit Bid(_NFTAddress , _TokenID , c);
    }

    function end ( address _NFTAddress , uint256 _TokenID ) public
        onlyOwner 
        idEnd(_NFTAddress , _TokenID)
    {
        auction storage c = _auctionInfo[_NFTAddress][_TokenID];

        if (c._HighestBidder == address(0)){ 

            IERC721(_NFTAddress).safeTransferFrom(address(this), c._Seller , _TokenID);

        } else {
            
            IERC721(_NFTAddress).safeTransferFrom(address(this), c._HighestBidder , _TokenID);

            uint256 amount = _bidsAmount[c._HighestBidder];
            _bidsAmount[c._HighestBidder] = 0;
            c._Seller.sendValue(c._HighestBid);
            feeAddr.sendValue(amount - c._HighestBid);
        }

        c._Started = false;
        c._Ended = true;

        emit End(_NFTAddress , _TokenID , c._Seller, c._HighestBidder , c._HighestBid);
    }
    
    
    /**************  sale  ************/

    mapping ( address => uint256 ) _DepositAmount;
    mapping ( address => uint256 ) _FeeAmount;

    mapping ( address => mapping ( uint256 => NFTSellInfo )) _DepositNFT;
    
    struct NFTSellInfo {
        address payable _Seller;
        address payable _Buyer;
        uint256 _Price;
        uint256 _Saledate;
        bool    _Deposited;
        bool    _Selled;
    }
    
    event DepositNFT(address _nft , uint256 _TokenID , NFTSellInfo _NFTSelling);
    event buyNFTs(address _NFTAddress , uint256 _tokenId , address seller ,address buyer , uint256 buyprice);
    event CancelDeposit (address _nft , uint256 _tokenId , address canceller);

    modifier onlyNFTSeller (address _NFTAddress , uint256 _TokenId ) {
        require (_DepositNFT[_NFTAddress][_TokenId]._Seller  == msg.sender || msg.sender == owner() , "MSG.SENDER is not NFT Seller.");
        require (_DepositNFT[_NFTAddress][_TokenId]._Deposited == true , "NFT not Deposited");
        _;
    } 

    modifier onlyTokenOwner () {
        require ( _DepositAmount[msg.sender] > 0 , "MSG.SENDER is not NFT Buyer.. ");
        _;
    }

    modifier isNFTSale (address _NFTAddress , uint256 _TokenId , uint256 _Price ) {
        require (_DepositNFT[_NFTAddress][_TokenId]._Deposited == false , "NFT Aleady Deposit");
        require (_Price > 0 , "Price must be greater than 0 ");
        _;
    }

    modifier isOwnerOf(address _NFTAddress , uint256 _TokenId , address account) {
        require (account == IERC721(_NFTAddress).ownerOf(_TokenId) , "...");
        _;
    }

    modifier isNFTBuy (address _NFTAddress , uint256 _TokenID , uint256 _Amount) {
        require (_Amount == fee(_DepositNFT[_NFTAddress][_TokenID]._Price) , "msg.value is not (price + fee)");
        _;
    }
    


    function depositNFT (address _NFTAddress , uint256 _TokenID , uint256 _Price) public 
        isOwnerOf(_NFTAddress , _TokenID , msg.sender)
        isNFTSale(_NFTAddress , _TokenID , _Price)
    {

        NFTSellInfo memory _info = NFTSellInfo({
            _Seller     : payable(msg.sender),
            _Buyer      : payable(address(0)),
            _Price      : _Price,
            _Saledate   : 0,
            _Deposited  : true,
            _Selled     : false
        });

        _DepositNFT[_NFTAddress][_TokenID] = _info;

        IERC721(_NFTAddress).safeTransferFrom( msg.sender , address(this), _TokenID);
        
        emit DepositNFT(_NFTAddress, _TokenID, _DepositNFT[_NFTAddress][_TokenID]);
    }
    
    function depositNFTOf (address _NFTAddress , uint256 _TokenID) public view returns(NFTSellInfo memory _info) {

        NFTSellInfo memory c = _DepositNFT[_NFTAddress][_TokenID];

        return c;
    }

    function cancelAtNFT (address _NFTAddress , uint256 _TokenID) public
        onlyNFTSeller(_NFTAddress , _TokenID ) 
    {

        NFTSellInfo storage c = _DepositNFT[_NFTAddress][_TokenID];

        c._Price = 0;
        c._Deposited = false;
        c._Seller = payable(address(0));
        
        IERC721(_NFTAddress).safeTransferFrom(address(this) , msg.sender , _TokenID);

        emit CancelDeposit(_NFTAddress, _TokenID , msg.sender);
    }

    function buyNFT ( address _NFTAddress , uint256 _TokenID ) public payable 
        isNFTBuy( _NFTAddress , _TokenID , msg.value)
    {   

        NFTSellInfo storage c = _DepositNFT[_NFTAddress][_TokenID];

        c._Buyer = payable(msg.sender);
        c._Saledate = block.timestamp;
        c._Selled = true;
        c._Deposited = false;

       
        IERC721(_NFTAddress).safeTransferFrom(address(this) , msg.sender , _TokenID);

        /* fee 분배. */
        feeAddr.sendValue(msg.value - c._Price);
        
        c._Seller.sendValue(c._Price);

        emit buyNFTs(_NFTAddress , _TokenID , c._Seller ,c._Buyer , c._Price);
    }

    function fee(uint256 _Price) internal pure returns(uint256 _fee) {
        _fee = _Price + (_Price * 4 / 100);
    }

    function changeFeeAddr(address payable _to) public onlyOwner {
        feeAddr = _to;
    }

    function getFeeAddr() public view returns (address) {
        return feeAddr;
    }

    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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