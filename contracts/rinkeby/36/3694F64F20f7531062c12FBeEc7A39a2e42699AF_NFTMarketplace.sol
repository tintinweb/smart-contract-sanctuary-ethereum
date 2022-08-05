// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "IERC721.sol";
import "Ownable.sol";
import "IERC20.sol";


contract NFTMarketplace is Ownable{
   
    uint256 private platformFee;
    address contract_owner;

    enum order_status{
        open,
        cancel,
        expire,
        completed
    }

    struct ListNFT {
        address nft_address;
        uint256 nft_tokenid;
        address sender;
        address receiver;
        uint256 price;
        uint256 expire_time;
        address token_address;
        order_status status;
    }
    
    mapping(uint256 =>ListNFT) public list;
    uint256 public numoflist; 

    struct OfferNFT {
        address nft_address;
        uint256 nft_tokenid;
        address sender;
        address receiver;
        uint256 Price;
        uint256 expire_time;
        address token_address;
        order_status status; 
    }
    mapping(uint256 => OfferNFT) public offerNfts;
    uint256 public numofoffer;
    // struct auctionNft{
    //     address nft;
    //     uint256 tokenid;
    //     address payable owner;
    //     uint256 startprice;
    //     uint256 starttime;
    //     uint256 endtime;
    //     address last_bider;
    //     uint256 bidingvalue;
    //     address wineer;
    //     bool success;
    // }
    // mapping(address => mapping(uint256 => auctionNft)) private auctionNfts;
    
    event ListedNFT(address indexed nft,uint256 indexed tokenid,uint256 price,address sender);
    event OFFERNFT(address indexed nft,uint256 indexed tokenid,uint256 price,address token,address sender);
    event cancelOffer(address indexed nft,uint256 indexed tokenid,uint256 price,address token,address sender,address receiver);
    event offerAccept(address indexed nft,uint indexed tokenid,uint256 price,address token,address sender,address receiver);
    event BoughtNFT(address indexed nft,uint256 indexed tokenid,uint256 price,address token,address sender,address receiver);

    constructor(uint _platformFee) public {
        platformFee = _platformFee;
        contract_owner=msg.sender;
    }
    function listnft(address _nft,uint256 _tokenid,uint256 _price,address _token) external {
        IERC721 nft = IERC721(_nft);
        require(nft.ownerOf(_tokenid) == msg.sender, "this nft owner can list only");
        require(nft.getApproved(_tokenid)==address(this),'this nft not approv');
        list[numoflist].nft_address=_nft;
        list[numoflist].nft_tokenid=_tokenid;
        list[numoflist].sender=msg.sender;
        list[numoflist].price=_price;
        list[numoflist].expire_time=block.timestamp+360000;
        list[numoflist].token_address=_token;
        list[numoflist].status=order_status.open;
        numoflist++;
        emit ListedNFT(_nft, _tokenid,_price, msg.sender);
    }

    function cancelListedNFT(uint256 _numoflist) external {
        ListNFT memory listedNFT = list[_numoflist];
        require(listedNFT.sender == msg.sender, "not listed owner");
        require(listedNFT.status == order_status.open,'your nft not listed');
        listedNFT.status=order_status.cancel;
    }

    function makeoffer(uint256 _offerprice,uint256 _numoflist,address _token) external {
        IERC20 token=IERC20(_token);
        ListNFT memory nft = list[_numoflist];
        require(_offerprice > 0, "price can not 0");
        require(token.allowance(msg.sender,address(this)) >= _offerprice,'you have a not allowanance');
        require(nft.status == order_status.open,'you cannot offer this nft');
        require(nft.expire_time > block.timestamp,'this token list time expire');
        offerNfts[numofoffer].nft_address=nft.nft_address;
        offerNfts[numofoffer].nft_tokenid=nft.nft_tokenid;
        offerNfts[numofoffer].sender=msg.sender;
        offerNfts[numofoffer].Price=_offerprice;
        offerNfts[numofoffer].expire_time=block.timestamp + 360000;
        offerNfts[numofoffer].token_address=_token;
        offerNfts[numofoffer].status=order_status.open;
        numofoffer++;
        emit OFFERNFT(offerNfts[numofoffer].nft_address,
                      offerNfts[numofoffer].nft_tokenid, 
                      offerNfts[numofoffer].Price, _token, msg.sender);
    }

    function cancelOfferNFT(uint256 _numofoffer)external {
        OfferNFT memory offer = offerNfts[_numofoffer];
        IERC721 nft = IERC721(offer.nft_address);
        require(offer.sender == msg.sender || nft.ownerOf(offer.nft_tokenid) == msg.sender, "you cannot cancel offer");
        require(offer.status==order_status.open,"you cannot cancel this offer");
        offerNfts[_numofoffer].status =order_status.cancel;

        emit cancelOffer(offer.nft_address,
                         offer.nft_tokenid,
                         offer.Price, 
                         offer.token_address,
                         offer.sender,
                         nft.ownerOf(offer.nft_tokenid));
    }

    function acceptofferNFT(uint256 _numofoffer,uint256 _numoflist)external{
        IERC721 nft = IERC721(offerNfts[_numofoffer].nft_address);
        IERC20 token=IERC20(offerNfts[_numofoffer].token_address);
        address nft_owner=nft.ownerOf(offerNfts[_numofoffer].nft_tokenid);

        require(token.allowance(msg.sender,address(this)) == list[_numoflist].price,'you have a not allowanance');
        require(token.balanceOf(offerNfts[_numofoffer].sender) >= offerNfts[_numofoffer].Price,'buyer have not enough fund');
        require(nft.getApproved(offerNfts[_numofoffer].nft_tokenid)==address(this),'this nft not approv');
        require(nft_owner == msg.sender,"this nft is not your");
        require(list[_numoflist].sender == msg.sender,'this nft is not your');
        require(list[_numoflist].nft_address == offerNfts[_numofoffer].nft_address,'this offer not for this nft');
        require(list[_numoflist].nft_tokenid == offerNfts[_numofoffer].nft_tokenid,'this offer not for this nft');
        require(list[_numoflist].status == order_status.open,'this nft is not listed');
        require(offerNfts[_numofoffer].status == order_status.open,'you cannot accept this offer');
        require(list[_numoflist].expire_time > block.timestamp,'this nft list time expiry');
        require(offerNfts[_numofoffer].expire_time > block.timestamp,'your offer expire');

        uint256 offerPrice = offerNfts[_numofoffer].Price;
        uint256 _platformFee= offerPrice * platformFee/100 ;
        uint256 ownerprice=(offerPrice) - (_platformFee);
       
        token.transferFrom(offerNfts[_numofoffer].sender,address(this),_platformFee);
        token.transferFrom(offerNfts[_numofoffer].sender,nft_owner,ownerprice);
        nft.transferFrom(nft_owner,offerNfts[_numofoffer].sender,offerNfts[_numofoffer].nft_tokenid); 

        offerNfts[_numofoffer].status=order_status.completed;
        list[_numoflist].status=order_status.completed;
        list[_numoflist].receiver=offerNfts[_numofoffer].sender;
        offerNfts[_numofoffer].receiver=nft_owner;

        emit offerAccept(offerNfts[_numofoffer].nft_address, 
                         offerNfts[_numofoffer].nft_tokenid,
                         offerNfts[_numofoffer].Price,
                         offerNfts[_numofoffer].token_address,
                         offerNfts[_numofoffer].sender,
                         offerNfts[_numofoffer].receiver);   
    }

    function buyNFT(uint256 _numoflist) external{
        IERC721 nft = IERC721(list[_numoflist].nft_address);
        IERC20 token=IERC20(list[_numoflist].token_address);

        require(token.allowance(msg.sender,address(this)) == list[_numoflist].price,'you have a not allowanance');
        require(token.balanceOf(msg.sender) >= list[_numoflist].price,'buyer have not enough fund');
        require(nft.getApproved(list[_numoflist].nft_tokenid)==address(this),'this nft not approv');
        require(list[_numoflist].status == order_status.open, "this nft for not sold");
        require(list[_numoflist].expire_time > block.timestamp,'nft status in expire');

        uint256 _platefromfee=list[_numoflist].price*platformFee/100;
        uint256 nft_owner_price=(list[_numoflist].price)-(_platefromfee);

        token.transferFrom(msg.sender,list[_numoflist].sender,nft_owner_price);
        token.transferFrom(msg.sender,address(this),_platefromfee);
        nft.transferFrom(list[_numoflist].sender,msg.sender,list[_numoflist].nft_tokenid);

        list[_numoflist].receiver=msg.sender;
        list[_numoflist].status=order_status.completed;

        emit BoughtNFT(list[_numoflist].nft_address,
                       list[_numoflist].nft_tokenid,
                       list[_numoflist].price,
                       list[_numoflist].token_address,
                       list[_numoflist].sender,msg.sender);

    }
    
    function expire_list(uint256 _numoflist) external {
        require(list[_numoflist].expire_time < block.timestamp,'your nft not expire');
        list[_numoflist].status=order_status.expire;
    }

    function expire_offer(uint256 _numofoffer) external {
        require(offerNfts[_numofoffer].expire_time < block.timestamp,'your nft not expire');
        offerNfts[_numofoffer].status=order_status.expire;
    }


    modifier onlyowner(){
        require(msg.sender == contract_owner);
        _;
    }
    function change_platfrom_fee(uint256 fee) external onlyowner {
        require(msg.sender == contract_owner,'this function call only contract owner');
        platformFee=fee;
    }

    function total_fund(address _tokenaddress) external onlyowner view returns(uint256){
        require(msg.sender == contract_owner);
        IERC20 token=IERC20(_tokenaddress);
        return token.balanceOf(address(this));
    }

    function withdraw(address _receiver,address _token,uint256 _amount) external onlyowner{
        IERC20 token=IERC20(_token);
        require(token.balanceOf(address(this)) >= _amount,'not enough token');
        token.transfer(_receiver,_amount);
    }


    // function create_auction(address _nft,uint256 _tokenid,uint256 _price,uint256 _starttime)public {
    //     IERC721 nft = IERC721(_nft);
    //     require(nft.ownerOf(_tokenid) == msg.sender, "this nft owner can list only");
    //     auctionNfts[_nft][_tokenid] = auctionNft({
    //         nft: _nft,
    //         tokenid: _tokenid,
    //         owner: payable(msg.sender),
    //         startprice:_price,
    //         starttime:_starttime,
    //         endtime:_starttime + 3600,
    //         last_bider:msg.sender,
    //         bidingvalue:_price,
    //         wineer:msg.sender,
    //         success: false
    //     });
    // }

    // function cancel_auction(address _nft,uint256 _tokenid) public{
    //     auctionNft memory auction=auctionNfts[_nft][_tokenid];
    //     require(auction.owner == msg.sender,'you not owner off this nft');
    //     require(auction.starttime > block.timestamp,'auction alreday start');
    //     delete auctionNfts[_nft][_tokenid];
    // }

    // function bid_auction(address _nft,uint256 _tokenid,uint256 _price) public{
    //     auctionNft memory auction=auctionNfts[_nft][_tokenid];
    //     require(auction.starttime <= block.timestamp,'auction not start');
    //     require(auction.endtime > block.timestamp,'auction is over');
    //     require(auction.last_bider != msg.sender,'alreday last bider you');
    //     require(auction.bidingvalue < _price,'please enter valid amount');
    //     auction.last_bider =msg.sender;
    //     auction.bidingvalue=_price;
    //     auction.wineer=msg.sender;
    // }

    // function result_auction(address _nft, uint256 _tokenid) public{
    //     require(!auctionNfts[_nft][_tokenid].success, "already resulted");
    //     auctionNft memory auction=auctionNfts[_nft][_tokenid];
    //     require(msg.sender == auction.owner || msg.sender == auction.last_bider,'only owner or winner call this function' );
    //     require(auction.endtime < block.timestamp,'auction not finish');
    //     auction.success = true;
    //     uint256 price=auction.bidingvalue;
    //     uint256 ownerprice= (price) - (price*platformFee/100);
    //     IERC20(WETH).transferFrom(auction.wineer,address(this),price);
    //     IERC721(auction.nft).transferFrom(auction.owner,auction.wineer,auction.tokenid); 
    //     auction.owner.transfer(ownerprice);
    // }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC165.sol";

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Context.sol";

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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