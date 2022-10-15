/**
 *Submitted for verification at Etherscan.io on 2022-10-15
*/

/**
 *Submitted for verification at Etherscan.io on 2022-10-15
*/

/**
 *Submitted for verification at Etherscan.io on 2022-10-14
*/

/**
 *Submitted for verification at Etherscan.io on 2022-10-14
*/

// SPDX-License-Identifier: MIT
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
interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);
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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
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
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
contract Auction is Ownable{
    struct AuctionStruct{
        uint auctionId;
        uint endTime;
        address lastBidder;
        uint bidCount;
        uint remainingBid;
        address token;
        uint tokenAmount;
        uint tokenType;
        uint totalBid;
        
    }
    
    event CreatedAuction(address _token, uint _tokenAmount, uint _tokenType, uint _endTime, uint256 time);
    event DeletedAuction(uint _auctionId, uint256 time);
    event Bid(address _bidder, uint _auctionId, uint256 time);
    event Claim(address _bidder, uint _auctionId, uint256 time);
    event UpdateEndTime(uint _getAuctionId, uint _newEndTime);
    event WithdrawTokens(address _token, uint _tokenAmount, uint _tokenType);
    
    uint auctionID = 0;
    uint bidPrice = 0.01 ether;
    mapping(uint => AuctionStruct) public auctionInfo;


    function bid(uint _auctionID) payable public {
        require(auctionInfo[_auctionID].endTime > block.timestamp, "The Auction is Ended");
        require(msg.value >= bidPrice, "Please send proper amount");
        uint bidCount = msg.value / bidPrice;
        
        if(auctionInfo[_auctionID].remainingBid >= bidCount){
            auctionInfo[_auctionID].remainingBid -= bidCount;
        }
        else{
            auctionInfo[_auctionID].remainingBid = ( (bidCount - auctionInfo[_auctionID].remainingBid) - 1 );
            auctionInfo[_auctionID].lastBidder = msg.sender;
        }
        auctionInfo[_auctionID].bidCount ++;
        uint _endTime = block.timestamp + 90;
        if(auctionInfo[_auctionID].endTime < _endTime){
            auctionInfo[_auctionID].endTime = _endTime;
        }
        emit Bid(msg.sender, _auctionID, block.timestamp);
    } 

    function createAuction(address _token, uint _tokenAmount, uint _tokenType, uint _endTime) onlyOwner payable public {
        require(_endTime > block.timestamp, "Auction ended" );
        AuctionStruct memory auctionDetail;
        auctionDetail = AuctionStruct({
            auctionId   :   auctionID,
            endTime     :   _endTime,
            lastBidder  :   address(0),
            bidCount    :   0,
            remainingBid:   0,
            token       :   _token,
            tokenAmount :   _tokenAmount,
            tokenType   :   _tokenType,
            totalBid    :   0
            

        });
        auctionInfo[auctionID] = auctionDetail;
        
        if(auctionInfo[auctionID].tokenType == 0){
            require(msg.value >= auctionInfo[auctionID].tokenAmount );
        }else if(auctionInfo[auctionID].tokenType == 1){
            IBEP20(auctionInfo[auctionID].token).transferFrom(msg.sender, address(this), auctionInfo[auctionID].tokenAmount);
        }else if(auctionInfo[auctionID].tokenType == 2){
            IERC721(auctionInfo[auctionID].token).safeTransferFrom(msg.sender, address(this), auctionInfo[auctionID].tokenAmount);
        }
        auctionID++;
        emit CreatedAuction(_token, _tokenAmount, _tokenType, _endTime, block.timestamp);
    }

    function claim(uint _auctionID) payable public {
        
        require(auctionInfo[_auctionID].endTime < block.timestamp, "Auction not ended yet");
        require(auctionInfo[_auctionID].lastBidder == msg.sender, "You are not winner");
        uint remainingValue = ( msg.value + ( auctionInfo[_auctionID].remainingBid * bidPrice ) - ( auctionInfo[_auctionID].bidCount * bidPrice ) );
        require( remainingValue >= 0, "Please send proper value");

        if(remainingValue > 0){
            payable(auctionInfo[_auctionID].lastBidder).transfer(remainingValue);
        }
        if(auctionInfo[_auctionID].tokenType == 0){
            payable(auctionInfo[_auctionID].lastBidder).transfer(auctionInfo[_auctionID].tokenAmount);
        }else if(auctionInfo[_auctionID].tokenType == 1){
            IBEP20(auctionInfo[_auctionID].token).transfer(auctionInfo[_auctionID].lastBidder, auctionInfo[_auctionID].tokenAmount);
        }else if(auctionInfo[_auctionID].tokenType == 2){
            IERC721(auctionInfo[_auctionID].token).safeTransferFrom(address(this),auctionInfo[_auctionID].lastBidder, auctionInfo[_auctionID].tokenAmount);
        }

        emit Claim(msg.sender, _auctionID, block.timestamp);
    }

    function updateEndTime(uint _getAuctionId, uint _newEndTime) onlyOwner public {
        auctionInfo[_getAuctionId].endTime = _newEndTime;
        emit UpdateEndTime(_getAuctionId, _newEndTime);
    }

    function deleteAuction(uint _auctionID) onlyOwner payable public {
        require(auctionInfo[_auctionID].lastBidder == address(0), "Auction have bids");
             
        if(auctionInfo[auctionID].tokenType == 0){
            payable (msg.sender).transfer(auctionInfo[auctionID].tokenAmount);
        }else if(auctionInfo[auctionID].tokenType == 1){
            IBEP20(auctionInfo[auctionID].token).transferFrom(address(this), msg.sender, auctionInfo[auctionID].tokenAmount);
        }else if(auctionInfo[auctionID].tokenType == 2){
            IERC721(auctionInfo[auctionID].token).safeTransferFrom(address(this), msg.sender, auctionInfo[auctionID].tokenAmount);
        }

        delete auctionInfo[auctionID];
        emit DeletedAuction(_auctionID, block.timestamp);
   
   }

    function withdrawAmount(uint _amount) onlyOwner public {
        payable(owner()).transfer(_amount);
    }

}