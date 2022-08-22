/**
 *Submitted for verification at Etherscan.io on 2022-08-22
*/

// SPDX-License-Identifier:MIT

pragma solidity ^0.8.4;


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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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
       
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

   
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

   
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

   
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

   
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
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

   
    constructor() {
        _setOwner(_msgSender());
    }

  
    function owner() public view virtual  returns (address) {
        return _owner;
    }

    
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

   
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
interface IERC165 {
    
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    
    function balanceOf(address owner) external view returns (uint256 balance);

    
    function ownerOf(uint256 tokenId) external view returns (address owner);

    
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external ;

   
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    
    function approve(address to, uint256 tokenId) external;

   
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    
    function setApprovalForAll(address operator, bool _approved) external;

  
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
         
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
 
/*****
NOTE:- 
  (1) This NFT Marketplace Contract Will Only List FUL NFT, So Make Sure That NFT Which You Are Listing Or Auctioning That Is FUL NFT 
  (2) Now This Contract Is Not Well Optimized.
  (3) We Have Created View Function Rather Than Making Varibales Public For Increasing Contracts Security Readability.

*****/

contract FULNFTMarketplace is Ownable, ReentrancyGuard {

    using SafeERC20 for IERC20;

    struct Auction {
        address creator;
        uint256 NFTId;
        uint256 startTime;
        uint256 endTime;
        uint256 starterBid;
        uint256 expectedBid;
        uint256 curBid;
        address curBidder;
        address soldTo;
    }
 
    address adminWallet;  // Wallet address of admin.
    uint256 private totalAuctions; // Number of auction created.

    uint256 private auctionTrxFee = 5; // Platform fee of each auction, by default it is 5 percent. 


    mapping(uint256 => Auction) private auctions; // Auction Id mapping to details of auction of the AuctionId.
    mapping(address => uint256[]) private userAuctions; // it map user to number of auction he created.

    event FULNFTContractAddressChange(address indexed by, address indexed oldAddress, address indexed newAddress,uint256 at);
    event Auctioned(address indexed by, uint256 indexed NFTId, uint256 indexed auctionId, uint256 starterBid, uint256 startTime, uint256 endTime, uint256 at);
    event BidPlaced(uint256 indexed NFTId, address indexed oldBidder, address indexed newBidder, uint256 auctionId, uint256 oldBid, uint256 newBid, uint256 at);
    event SoldViaAuction(address indexed by,address indexed to, uint256 indexed NFTId, uint256 auctionId, uint256 soldPrice, uint256 at);


    
    IERC721 private FULNFTContract; 
    IERC20 public fulToken;

    /**
     *@dev To intract with NFT contract and Token contract we need to make instance  of contract. 
     *
     *@param FULNFTGeneratortAddress  FULMint contract address
     *@param fulTokenAddress native token address.
     * 
     **/
    constructor(address FULNFTGeneratortAddress,address fulTokenAddress) {
        FULNFTContract = IERC721(FULNFTGeneratortAddress);
        fulToken = IERC20(fulTokenAddress);
        emit FULNFTContractAddressChange(msg.sender, address(0), FULNFTGeneratortAddress,block.timestamp);
    }

    

    /********************| Auction Section |********************/
    // To validate auction is valid or not?
    modifier isValidAuctionId(uint256 auctionId) {
        require(auctionId > 0 && auctionId <= totalAuctions, "Invalid Listing Id");
        _;
    }

    
    /**
     * @dev This function is use to create auction.
     *
     * @param _NFTId it takes valid Nft id and NFT should be approved
     * @param _starterBid Initial bid amount.
     * @param _expectedBid Expected amount to sell Token
     * @param _endTime When will the auction end.
     *
     * @return auctionId Id of the newly created auction.
     *
     **/
    function createAuction(uint256 _NFTId, uint256 _starterBid,uint256 _expectedBid, uint256 _endTime) public returns (uint256) {
        require(block.timestamp < _endTime, "Start Time Should Lesser Than End Time");
        require(FULNFTContract.getApproved(_NFTId) == address(this),"You Has Not Approved Your NFT To This Contract");
        require(FULNFTContract.ownerOf(_NFTId) == msg.sender, "Only Owner of NFT  Can put NFT on Auction");
        FULNFTContract.transferFrom(msg.sender, address(this), _NFTId);
        totalAuctions++;
        uint256 auctionId = totalAuctions;

        auctions[auctionId] = Auction(msg.sender, _NFTId, block.timestamp, _endTime, _starterBid,_expectedBid, 0, address(0), address(0));
        userAuctions[msg.sender].push(auctionId);
        emit Auctioned(msg.sender, _NFTId, auctionId, _starterBid, block.timestamp, _endTime, block.timestamp);
        return auctionId;
    }

    /**
     * @dev This function will use to claim the NFT after auction end.
     *
     * @param auctionId auction winner user need to claim NFT with valid auctionId.
     *
     **/
    function claimNFT(uint256 auctionId) public isValidAuctionId(auctionId) {
        require((msg.sender == auctions[auctionId].creator) || ((msg.sender == auctions[auctionId].curBidder) && (block.timestamp >= auctions[auctionId].endTime)),"This Method Can Be Only Called By Auction Creator Or Curbidder. CurBidder Can Call This Method After End Time");
        require(auctions[auctionId].soldTo == address(0), "You Cannot End This Auction Because It Is Already Ended");

        if (auctions[auctionId].curBidder != address(0)) {
            auctions[auctionId].soldTo = auctions[auctionId].curBidder;
            address winner = auctions[auctionId].curBidder;
            FULNFTContract.transferFrom(address(this),winner, auctions[auctionId].NFTId);
            uint256 plateformFee = (auctions[auctionId].curBid * auctionTrxFee) / 100;
            uint256 amountToTransfer = auctions[auctionId].curBid - plateformFee;
            fulToken.transfer(auctions[auctionId].creator, amountToTransfer);
            fulToken.transfer(adminWallet,plateformFee);
            emit SoldViaAuction(auctions[auctionId].creator, auctions[auctionId].curBidder, auctions[auctionId].NFTId, auctionId, auctions[auctionId].curBid, block.timestamp);
        } else {
            auctions[auctionId].soldTo = msg.sender;
            FULNFTContract.transferFrom( address(this), msg.sender, auctions[auctionId].NFTId);
        }
    }

    
    /**
     * @dev To buy NFT from marketplace user need to bid or instantBuy NFT on Expected amount of auction.
     * 
     * @param auctionId On which perticular auction user is interested.
     * @param NewBidAmount Bidding amount or Expected amount of auction.
     *
     **/
    function placeBid(uint256 auctionId, uint256 NewBidAmount) public  nonReentrant isValidAuctionId(auctionId){
        uint256 curTime = block.timestamp;
        require(auctions[auctionId].soldTo == address(0), "Now You Cannot Bid In This Auction Because Auction Is Ended");
        require(auctions[auctionId].endTime > curTime, "You Cannot Bid For This Auction Because Auction Time Is Over" );
        require(auctions[auctionId].creator != msg.sender, "Auction Creator Cannot Bid In This Auction"
        );
        uint256 newBid = NewBidAmount;
        require(newBid >= auctions[auctionId].starterBid && newBid > auctions[auctionId].curBid,"Please bid correct Bid" );

        //from expected bid to instant buy
        if(newBid >= auctions[auctionId].expectedBid){
            instantBuy(auctionId, NewBidAmount);
        }else{
            fulToken.transferFrom(msg.sender,address(this), newBid);
            uint256 oldBid = auctions[auctionId].curBid;
            address oldBidder = auctions[auctionId].curBidder;
            auctions[auctionId].curBid = newBid;
            auctions[auctionId].curBidder = msg.sender;
            if(oldBidder != address(0)){
                fulToken.transfer(oldBidder, oldBid);
            }
            emit BidPlaced(auctions[auctionId].NFTId, oldBidder, msg.sender, auctionId, oldBid, newBid, curTime);
        }
        
    }

    /**
     * @dev To instantBuy NFT from marketplace user need to pay Expected amount of token.
     * 
     * @param auctionId On which perticular auction user is interested.
     * @param NewBidAmount Expected amount of token.
     *
     **/
    function instantBuy(uint256 auctionId, uint256 NewBidAmount) public isValidAuctionId(auctionId){
        if(NewBidAmount >= auctions[auctionId].expectedBid){
            auctions[auctionId].endTime = block.timestamp;
            
            if(auctions[auctionId].curBidder != address(0)){
                fulToken.transfer(auctions[auctionId].curBidder, auctions[auctionId].curBid);
            }
            auctions[auctionId].curBid = NewBidAmount;
            auctions[auctionId].curBidder = msg.sender; 
            fulToken.transferFrom(msg.sender,address(this), NewBidAmount);
            claimNFT(auctionId);
        }
    }

    // Before creating auction admin need to set admin wallet to collect platform fees.
    function setAdminWallet(address _adminWallet) public onlyOwner{
        adminWallet = _adminWallet;
    }

    // By default plateform fee is 5 percent, if admin want to change, it can be achive by this function.
    function setAuctionTrxFee(uint256 _auctionTrxFee) public onlyOwner {
        require(_auctionTrxFee < 50, "Dear Owner You Cannot Set Transaction Fee Price More Than 49%");
        auctionTrxFee = _auctionTrxFee;
    }

    function currentBidAmount(uint256 auctionID)public view returns(uint256){
        return auctions[auctionID].curBid;
    }

    function currentBidder(uint256 auctionID)public view returns(address){
        return auctions[auctionID].curBidder;
    }


    /***** View Functions *****/


    // To get admin wallet address
    function getAdminWallet()public view returns(address){
        return adminWallet;
    }

    // To find how many numbers of auction has been created?.
    function _totalAuctions() public view returns (uint256) {
        return totalAuctions;
    }

    // To find plateform fee on every auction.
    function _auctionTransactionFee() public view returns (uint256) {
        return auctionTrxFee;
    }

    // To find how many auctions has been created by which user.
    function _usersAuctions(address userAddress) public view returns (uint256[] memory){
        return userAuctions[userAddress];
    }

    // To get details of auction.
    function _auctionData(uint256 auctionId) public view isValidAuctionId(auctionId) returns (Auction memory){
        return auctions[auctionId];
    }



    function balanceOfContract()public view returns(uint256){
        return address(this).balance;
    }
    function withdrawEther() public onlyOwner  {
        address payable to = payable(msg.sender);
        to.transfer(address(this).balance);
    }
}