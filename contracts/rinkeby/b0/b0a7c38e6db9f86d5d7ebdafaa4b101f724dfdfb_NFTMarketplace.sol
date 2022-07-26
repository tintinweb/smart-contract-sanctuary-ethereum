/**
 *Submitted for verification at Etherscan.io on 2022-07-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
// {
//     require(_tokenAddress.isContract(),"The NFT Address should be a contract");
//     require(IERC721(_tokenAddress).supportsInterface(_INTERFACE_ID_ERC721),"The NFT contract has an invalid ERC721 implementation");
//     return IERC721(_tokenAddress);
// }

// import "hardhat/console.sol";
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
library Address {

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}
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
// contract Pausable is Ownable {
//   event Pause();
//   event Unpause();

//   bool public paused = false;


//   /**
//    * @dev Modifier to make a function callable only when the contract is not paused.
//    */
//   modifier whenNotPaused() {
//     require(!paused);
//     _;
//   }

//   /**
//    * @dev Modifier to make a function callable only when the contract is paused.
//    */
//   modifier whenPaused() {
//     require(paused);
//     _;
//   }
//   /**
//    * @dev called by the owner to pause, triggers stopped state
//    */
//   function pause() onlyOwner whenNotPaused public {
//     paused = true;
//     emit Pause();
//   }

//   /**
//    * @dev called by the owner to unpause, returns to normal state
//    */
//   function unpause() onlyOwner whenPaused public {
//     paused = false;
//     emit Unpause();
//   }
// }
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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
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

contract NFTMarketplace is Ownable,  ERC721Holder  {

    uint256 public marketplaceFEE;
    address public marketOwner;
    using Address for address;
    bytes4 public constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

   
    // IERC20 public auraToken;
    // IERC20 public Token;

    // IERC20 public WETHToken;

    uint [] public auctionnID;
    uint [] public orderrID;

   
    constructor()  Ownable() {
        // auraToken=IERC20(_auraAddress);
        // WETHToken=IERC20(_WETHToken);
        }
    
    // function setPaused(bool _setPaused) public onlyOwner {
    //     return (_setPaused) ? pause() : unpause();}
    
 //...........................................................................................................................................................................    
    struct Order {
        bytes32 orderId;
        address  payable seller; //seller address
        uint256 ethPrice;
        uint256 tokenPrice;
        address coinAddress;
        }

    // struct AuctionDataEth {
    //     bytes32 auctionId;
    //     address payable seller;
    //     uint256 minBid;         // Selling Price
    //     uint expiryTime;
    //     // string paymentType;
    //     // address coinAddress;
    //     } 

    struct AuctionData {
        bytes32 auctionId;
        address payable seller;
        uint256 minBid;         // Selling Price
        uint expiryTime;
        // string paymentType;
        address coinAddress;
        }     

    struct BidData{
       bytes32  bidId;
       uint     bidCounter;
       uint     newBid;
       uint     auctionEndTime;
       address  highestBidder;
       uint256  highestBid;
       }

     //offer  
    struct Offer{
        uint256 amount;
        uint256 expiry; 
        address buyerAddress;
        address contractaddress;
        uint256 tokenid;
        bytes32 offerid;
        // string paymentType;
        address coinAddress;
        }


    Offer  [] public OfferArray;


    struct royalty{
       address contractADDress;
       address owner;
       uint256 amount;}
 

   

     
    // ORDER EVENTS
    event OrderCreated(bytes32 orderId,address indexed seller,uint256 indexed tokenId,uint256 ethPrice,uint256 toeknPrice,address indexed coinadress);
    event AuctionCreated(bytes32 orderId,address indexed seller,uint256 indexed tokenId,uint256 minBid,uint256 expiryTime);
    event OrderUpdated(bytes32 orderId,address indexed tokenAddress,uint256 indexed tokenId, uint256 ethPrice,uint256 tokenPrice,address indexed coinAddress);
    event OrderSuccessfullByToken(bytes32 orderId,address indexed tokenAddress,uint256 indexed tokenId,address indexed coinAddress,uint256 tokenPrice );
    event OrderSuccessfullByEth(bytes32 orderId,address indexed tokenAddress,uint256 indexed tokenId,uint256 Price );
    event OrderCancelled(bytes32 orderId,address indexed tokenAddress,uint256 indexed tokenId, address indexed seller);
        
    //Auction events
    event AuctionCreatedByToken(bytes32 auctionId,address indexed tokenAddress,address indexed seller,uint256 tokenId,uint256 minBid,uint expiryTime, address indexed coinAddress);
    event AuctionCreatedByEth(bytes32 auctionId,address indexed tokenAddress,address indexed seller,uint256 tokenId,uint256 minBid,uint expiryTime);
    event AuctionCancelled(bytes32 id,address indexed tokenAddress,uint256 tokenId);
    //BID Events
    event BidByEth(address tokenAddress,uint256 tokenId,address bidder, uint highestBid, address highestBidder);
    event BidByToken(address tokenAddress,uint256 tokenId,address coinAddress,address bidder, uint highestBid, address highestBidder);
    event BidAccepted(address tokenAddress,uint256 _tokenId,address highestBidder,uint256 highestBid,address coinAddress);

    // Offer Events
    
    event OfferMade(address tokenAddress,uint256 tokenId,address buyer,uint256 _time,uint256 _amount,address _coinAddress);
    event offerAccepted(address _tokenAddress,uint256 tokenId,uint256 amount, address buyer,address coinAddress);



  // Mappings
    mapping(address => mapping(uint256 => Order)) public orderByTokenId;  
    // mapping(address => mapping(uint256 => AuctionDataEth)) public auctionByETH; 
    mapping(address => mapping(uint256 => AuctionData)) public auctionById; 

    mapping(address => mapping(uint256 => BidData)) public bidByTokenId;
    // mapping(bytes32 => Offer) public offerByBuyer;  //offer
    mapping (address => mapping(uint256 =>Offer )) public offerByBuyer;
    // mapping(address => mapping(uint256=> address)) public orderToken;

    mapping(address => royalty)public Royalties;





//...............................ROYALTIES SECTION............................................................................................................................................    

// for royalties

    mapping(address => uint256) public fundsByBidder;// check this mapping later

    
    function setRoyaltie(address _tokenAddress,uint _royaltyAmount) public {
        require (_royaltyAmount<= 10000000000000000000,"please enter value beteen 0-10 ");

           Ownable tokenRegistry = Ownable(_tokenAddress);
           require(tokenRegistry.owner()==msg.sender,"only owner");

                Royalties[_tokenAddress].contractADDress=_tokenAddress;
                Royalties[_tokenAddress].owner=msg.sender;
                Royalties[_tokenAddress].amount=_royaltyAmount;}
    
    function setmarketplaceFEE(uint256 _newPrice)public onlyOwner {
        marketplaceFEE=_newPrice;}

    function setmarketOwner(address _marketOwner) public onlyOwner{
        marketOwner=_marketOwner;
    }

    

    

 //...............................ORDER SECTION............................................................................................................................................    
    
    //create order
    
    function createOrder(address _tokenAddress,uint256 _tokenId, uint256 _ethPrice, uint _tokenPrice,address _coinAddress) public 
    {
        _createOrder(_tokenAddress, _tokenId,  _ethPrice, _tokenPrice,_coinAddress);
    }

    function _createOrder(address _tokenAddress, uint256 _tokenId, uint256 _ethPrice,uint _tokenPrice,address _coinAddress) internal
    {
       // Check nft registry
         IERC721 tokenRegistry = IERC721(_tokenAddress);
         
        // Check order creator is the asset owner
        address tokenOwner = tokenRegistry.ownerOf(_tokenId);

        require(tokenOwner == msg.sender,"Marketplace: Only the asset owner can create orders");
        require(_ethPrice > 0, "not enough funds send");

        tokenRegistry.safeTransferFrom(tokenOwner,address(this), _tokenId);
        
        // create the orderId
        bytes32 _orderId = keccak256(abi.encodePacked(_tokenId, _ethPrice, _tokenPrice));
        orderByTokenId[_tokenAddress][_tokenId] = Order({
            orderId: _orderId,
            seller:payable(msg.sender),
            ethPrice: _ethPrice,
            tokenPrice: _tokenPrice,
            coinAddress:_coinAddress
        });
        orderrID.push(_tokenId);
        emit OrderCreated(_orderId,msg.sender,_tokenId,_ethPrice,_tokenPrice,_coinAddress);
    }


     
    //Update Order
    function updateOrder( address _tokenAddress,uint256 _tokenId, uint256 _ethPrice, uint256 _tokenPrice,address _coinAddress) public 
    
    {   
        Order memory order = orderByTokenId[_tokenAddress][_tokenId];
        require(order.orderId != 0, "Markeplace: Order not yet published");
        require(order.seller == msg.sender, "Markeplace: sender is not allowed");
        require(order.ethPrice > 0, "Marketplace: Price should be bigger than 0");
        require(order.tokenPrice > 0, "Marketplace: Price should be bigger than 0");                   
        bytes32 updatedId=orderByTokenId[_tokenAddress][_tokenId].orderId;

        orderByTokenId[_tokenAddress][_tokenId] = Order({
            orderId: updatedId,
            seller:payable(msg.sender),
            ethPrice: _ethPrice,
            tokenPrice: _tokenPrice,
            coinAddress:_coinAddress

        });
         emit OrderUpdated(order.orderId,_tokenAddress,_tokenId, _ethPrice,_tokenPrice,_coinAddress);

    }



    //Cancel order
    function cancelOrder(address _tokenAddress,uint256 _tokenId) public 
    {
        
        Order memory order = orderByTokenId[_tokenAddress][_tokenId];
        require(order.seller == msg.sender || msg.sender == owner(), "Marketplace: unauthorized sender");
        _cancelOrder(_tokenAddress,order.orderId,_tokenId,  msg.sender);
    }

    function _cancelOrder(address _tokenAddress,bytes32 _orderId,uint256 _tokenId, address _seller) internal
    {
         // Check nft registry
        IERC721 tokenRegistry = IERC721(_tokenAddress);
         
        delete orderByTokenId[_tokenAddress][_tokenId];
        tokenRegistry.safeTransferFrom(address(this), _seller, _tokenId);   
        emit OrderCancelled(_orderId,_tokenAddress,_tokenId,_seller);
    }


      //Buy with ETH

    function safeExecuteOrderByEth( address _tokenAddress,uint256 _tokenId) public  payable
    {
        Order memory order = _getValidOrder( _tokenAddress,_tokenId);
        require(order.ethPrice == msg.value, "Marketplace: invalid price");

        require(order.seller != msg.sender,  "Marketplace: unauthorized sender");
        
        
        _executeOrder(_tokenAddress, msg.sender,_tokenId);


                // getting values for royalties
        uint256 royaltyAmount=Royalties[_tokenAddress].amount;
        address owner=Royalties[_tokenAddress].owner;

        //royalty calculation 
        uint value= msg.value;// we can also use oder.amount 
        uint256 royaltyCut = value *royaltyAmount/100000000000000000000;
        uint256 MP_FEE     = value *marketplaceFEE/100000000000000000000;
        uint256 sellerCut  =  value-(royaltyCut+MP_FEE);
  
        if (royaltyAmount==0){payable(order.seller).transfer(sellerCut);}
        else{
        payable(order.seller).transfer(sellerCut);
    
        payable(owner).transfer(royaltyCut);

        }


         for(uint i = _tokenId; i < orderrID.length-1; i++)
         {
               orderrID[i] = orderrID[i+1];      
         }
        orderrID.pop();
         emit OrderSuccessfullByEth(order.orderId,_tokenAddress,_tokenId,order.ethPrice );

    }

    //Buy with $AURA

    function safeExecuteOrderByToken( address _tokenAddress,uint256 _tokenId,address _coinAddress) public 
    { 

        IERC20  Token;
        Token=IERC20(_coinAddress);
        Order memory order = _getValidOrder( _tokenAddress,_tokenId);
        address CoinAddress=order.coinAddress;
        require (CoinAddress==_coinAddress,"use same token");
        require(order.tokenPrice <= Token.balanceOf(msg.sender), "Marketplace: invalid price");
        require(order.seller != msg.sender, "Marketplace: unauthorized sender");
        _executeOrder(_tokenAddress, msg.sender, _tokenId);

        // getting values for royalties
        uint256 royaltyAmount=Royalties[_tokenAddress].amount;
        address owner=Royalties[_tokenAddress].owner;

        //royalty calculation 
        uint256 royaltyCut =  (order.tokenPrice*royaltyAmount)/100000000000000000000;
        uint256 MP_FEE     =  (order.tokenPrice*marketplaceFEE)/100000000000000000000;
        uint256 sellerCut  =  order.tokenPrice-(royaltyCut+MP_FEE);

        if (royaltyAmount==0){Token.transferFrom(msg.sender,order.seller,sellerCut);
         Token.transferFrom(msg.sender,marketOwner,MP_FEE);}
        else{
        Token.transferFrom(msg.sender,order.seller,sellerCut);
        Token.transferFrom(msg.sender,owner,royaltyCut);
        Token.transferFrom(msg.sender,marketOwner,MP_FEE);}

        for(uint i = _tokenId; i < orderrID.length-1; i++)
        {
              orderrID[i] = orderrID[i+1];      
        }
        orderrID.pop();
         emit OrderSuccessfullByToken(order.orderId,_tokenAddress,_tokenId,_coinAddress,order.tokenPrice );
         
    


    }
    
    function _executeOrder(address _tokenAddress, address _buyer, uint256 _tokenId) internal
    {   
         IERC721 tokenRegistry = IERC721(_tokenAddress);
         delete orderByTokenId[_tokenAddress][_tokenId];   
         tokenRegistry.safeTransferFrom(address(this), _buyer, _tokenId);  
        //  emit OrderSuccessfull(_orderId, _buyer);
    }


        
    function _getValidOrder( address _tokenAddress,uint256 _tokenId) internal view returns (Order memory order)
    {
        order = orderByTokenId[_tokenAddress][_tokenId];
        require(order.orderId != 0, "Marketplace: asset not published");
    }


    //Return total number of id being listed for sale on a market place.
    function getOrderTokenIds(address _owner,address _contract)public view returns(uint orderId)
    {
        uint countt=0;
        Order memory order ;
        for (uint256 index = 0; index < orderrID.length; index++)
        {
        uint aa=orderrID[index];
        order = orderByTokenId[_contract][aa];
        if(order.seller==_owner)
        {   countt+=1;   }

        }
        return countt;
    }



    //.....................................AUCTION SECTION......................................................................................................................................    


    function _createAuctionByEth(address _tokenAddress,uint256 _tokenId, uint256 _minBid, uint _expiryTime ) public
    {
        
        // require(keccak256(abi.encodePacked(_paymentType))==keccak256(abi.encodePacked("AURA"))||keccak256(abi.encodePacked(_paymentType))==keccak256(abi.encodePacked("WETH")));
         // Check nft registry
         IERC721 tokenRegistry = IERC721(_tokenAddress);
         
         
        // Check order creator is the asset owner
        address tokenOwner = tokenRegistry.ownerOf(_tokenId);
        require(tokenOwner == msg.sender,"Marketplace: Only the asset owner can create orders");
        require(_minBid > 0, "not enough funds send");
        tokenRegistry.safeTransferFrom(tokenOwner,address(this), _tokenId);
        
        // create the orderId
        bytes32 _auctionId = keccak256(abi.encodePacked(_tokenId,_minBid,_expiryTime));
       auctionById[_tokenAddress][_tokenId] = AuctionData({
            auctionId:      _auctionId,
            seller:         payable(msg.sender),
            minBid:         _minBid,
            expiryTime:     _expiryTime,
            coinAddress:0x0000000000000000000000000000000000000000
            // paymentType:_paymentType
    

        });

            bidByTokenId[_tokenAddress][_tokenId] = BidData({
            bidId:_auctionId,
            bidCounter:0,
            newBid:0,
            auctionEndTime:block.timestamp +_expiryTime,
            highestBidder:0x0000000000000000000000000000000000000000,
            highestBid:0
        });
        auctionnID.push(_tokenId);
        emit AuctionCreatedByEth(_auctionId,_tokenAddress, msg.sender, _tokenId, _minBid, _expiryTime);
        
    }


        function _createAuctionByToken(address _tokenAddress,uint256 _tokenId, uint256 _minBid, uint _expiryTime ,address _coinAddress) public
    {
        
        // require(keccak256(abi.encodePacked(_paymentType))==keccak256(abi.encodePacked("AURA"))||keccak256(abi.encodePacked(_paymentType))==keccak256(abi.encodePacked("WETH")));
         // Check nft registry
         IERC721 tokenRegistry = IERC721(_tokenAddress);
         
         
        // Check order creator is the asset owner
        address tokenOwner = tokenRegistry.ownerOf(_tokenId);
        require(tokenOwner == msg.sender,"Marketplace: Only the asset owner can create orders");
        require(_minBid > 0, "not enough funds send");
        tokenRegistry.safeTransferFrom(tokenOwner,address(this), _tokenId);
        
        // create the orderId
        bytes32 _auctionId = keccak256(abi.encodePacked(_tokenId,_minBid,_expiryTime));
        auctionById[_tokenAddress][_tokenId] = AuctionData({
            auctionId: _auctionId,
            seller: payable(msg.sender),
            minBid: _minBid,
            expiryTime: _expiryTime,
            coinAddress:_coinAddress
            // paymentType:_paymentType
    

        });

            bidByTokenId[_tokenAddress][_tokenId] = BidData({
            bidId:_auctionId,
            bidCounter:0,
            newBid:0,
            auctionEndTime:block.timestamp +_expiryTime,
            highestBidder:0x0000000000000000000000000000000000000000,
            highestBid:0
        });
        auctionnID.push(_tokenId);
        emit AuctionCreatedByToken(_auctionId,_tokenAddress, msg.sender, _tokenId, _minBid, _expiryTime,_coinAddress);
   

    }


  // CANCEL AUCTION 
    function cancelAuction(address _nftAddress,uint256 _tokenId) public {
        AuctionData memory auctionData = auctionById[_nftAddress][_tokenId];
        IERC20 token = IERC20(auctionData.coinAddress);

        BidData memory bidData = _getValidBid( _nftAddress,_tokenId);
        IERC721 tokenRegistry = IERC721(_nftAddress);
        require(auctionData.seller == msg.sender || msg.sender == owner(), "Marketplace: unauthorized sender");

        delete auctionById[_nftAddress][_tokenId];
        if (bidData.highestBid!=0){
           if(auctionData.coinAddress==0x0000000000000000000000000000000000000000)
        {
        // sending eth
        payable(bidData.highestBidder).transfer(bidData.highestBid);
       
        }

            
       else
       {
        
         // sending aura
       
        token.transfer(bidData.highestBidder,bidData.highestBid);

      
         
    } tokenRegistry.safeTransferFrom(address(this), msg.sender,_tokenId); 
     }
    else{
        tokenRegistry.safeTransferFrom(address(this), msg.sender,_tokenId);  
        
    }
        emit AuctionCancelled(auctionData.auctionId,_nftAddress,_tokenId);

    }



  function _getValidAuctionToken( address _tokenAddress,uint256 _tokenId) internal view returns (AuctionData memory auctionData)
    {
        auctionData = auctionById[_tokenAddress][_tokenId];
        require(auctionData.auctionId != 0, "Marketplace: asset not published");
    }


    //Return total number of id being listed for Auction on a market place.

    function getAuctionTokenIds(address _contract,address _owner)public view returns(uint auctionId)
    {
        uint countt=0;
        AuctionData memory auctionData;
        for (uint256 index = 0; index < auctionnID.length; index++)
        {
        uint indexA=auctionnID[index];
        auctionData = auctionById[_contract][indexA];
        if(auctionData.seller==_owner)
        {   countt+=1;   }
        
        }
        return countt;
    }

//...............................................BIDDING SECTION............................................................................................................................        
         
    function placeBidToken(address _tokenAddress,uint _tokenId,uint _bid,address _coinAddress) public
    {
        IERC20  Token;
        Token=IERC20(_coinAddress);
        AuctionData memory auctionData = _getValidAuctionToken( _tokenAddress,_tokenId);
        address CoinAddress=auctionData.coinAddress;

        // Order memory order = _getValidOrder( _tokenAddress,_tokenId);
        // address CoinAddress=order.coinAddress;
        require (CoinAddress==_coinAddress,"use same token");
        BidData memory bidData = _getValidBid( _tokenAddress,_tokenId);
        // require(keccak256(abi.encodePacked(auctionData.paymentType)) == keccak256(abi.encodePacked("AURA")),"auction is for eth please bid by aura");
        require(Token.balanceOf(msg.sender) >= auctionData.minBid, "error");
        require(auctionData.minBid <= _bid ,"new bid should be greater min bid");
        require(bidData.highestBid < _bid ,"new bid should be greater highest bid");
        require(block.timestamp <= bidData.auctionEndTime, "auction canceled");
        require(Token.balanceOf(msg.sender) > fundsByBidder[bidData.highestBidder], "error");
        if (bidData.bidCounter != 0)
        {
            
            Token.transfer(bidData.highestBidder,bidData.highestBid);
        }
        fundsByBidder[msg.sender] = _bid;

        bidByTokenId[_tokenAddress][_tokenId] = BidData({
            bidId:auctionData.auctionId,
            bidCounter:bidData.bidCounter+1,
            newBid:_bid,
            auctionEndTime:bidData.auctionEndTime,
            highestBidder:msg.sender,
            highestBid:_bid
        });
        Token.transferFrom(msg.sender,address(this),_bid);
        emit BidByToken(_tokenAddress,_tokenId,_coinAddress,msg.sender, bidData.highestBid, bidData.highestBidder);


        // return true;
    }


// only check fundsByBidder map whether we made it nested mapping or not .
    function placeBidEth(address _tokenAddress,uint _tokenId) public payable
    {
        AuctionData memory auctionData = _getValidAuctionToken( _tokenAddress,_tokenId);
        
       
        BidData memory bidData = _getValidBid(_tokenAddress, _tokenId);
        
        require(auctionData.coinAddress==0x0000000000000000000000000000000000000000,"please bis by relevent token");
        require(msg.value >= auctionData.minBid, "new bid should be greater min bid");
        require(block.timestamp <= bidData.auctionEndTime, "auction canceled");
        require(msg.value > fundsByBidder[bidData.highestBidder], "new bid should be greater highest bid");
        if (bidData.bidCounter != 0)
        {
            (bool success, ) = bidData.highestBidder.call{value: bidData.highestBid}("");
            require(success, "Failed to send Ether");
        }
        fundsByBidder[msg.sender] = msg.value;

        bidByTokenId[_tokenAddress][_tokenId] = BidData({
            bidId:auctionData.auctionId,
            bidCounter:bidData.bidCounter+1,
            newBid:msg.value,
            auctionEndTime:bidData.auctionEndTime,
            highestBidder:msg.sender,
            highestBid:msg.value
        });
       
        emit BidByEth(_tokenAddress,_tokenId,msg.sender, bidData.highestBid, bidData.highestBidder);

        
        // return true;
    }

    function acceptBid(address _tokenAddress, uint256 _tokenId) public 
    {
        IERC721 tokenRegistry = IERC721(_tokenAddress);
        AuctionData memory auctionData = _getValidAuctionToken( _tokenAddress,_tokenId);
        // AuctionDataEth memory auctionDataEth = _getValidAuctionEth( _tokenAddress,_tokenId);
        
        IERC20 Token=IERC20(auctionData.coinAddress);

        require(auctionData.seller==msg.sender,"user is not owner");
        BidData memory bidData = _getValidBid( _tokenAddress,_tokenId);
        require(block.timestamp > bidData.auctionEndTime,"Auction is not ended");
        tokenRegistry.safeTransferFrom(address(this), bidData.highestBidder, _tokenId);
       //getting values for royalties 
        uint256 royaltyAmount=Royalties[_tokenAddress].amount;
        address owner=Royalties[_tokenAddress].owner;

        if (royaltyAmount==0){

            //royalty calculation 
        uint256 MP_FEE      =  bidData.highestBid*marketplaceFEE/100000000000000000000;
        uint256 sellerCut   =  bidData.highestBid-MP_FEE;
       

        if(auctionData.coinAddress==0x0000000000000000000000000000000000000000)
        {
        // sending eth
        payable(auctionData.seller).transfer(sellerCut);
       
        }

            
       else  
       {
        
         // sending aura
       
        Token.transfer(msg.sender,sellerCut);
    } 

        }else {

            //royalty calculation 
        uint256 royaltyCut  =  bidData.highestBid*royaltyAmount/100000000000000000000;
        uint256 MP_FEE      =  bidData.highestBid*marketplaceFEE/100000000000000000000;
        uint256 sellerCut   =  bidData.highestBid-(royaltyCut+MP_FEE);
       

        if(auctionData.coinAddress==0x0000000000000000000000000000000000000000)
        {
       
        // sending eth
        payable(auctionData.seller).transfer(sellerCut);
        payable(owner).transfer(royaltyCut);
        
        
        }
            
       else 
       {
        
        // sending aura
       
        Token.transfer(msg.sender,sellerCut);
        Token.transfer(owner,royaltyCut);
        Token.transfer(marketOwner,MP_FEE);         
    } 
        }

         delete auctionById[_tokenAddress][_tokenId];

        //  delete auctionByTokenId[_tokenAddress][_tokenId];

        for(uint i = _tokenId; i < auctionnID.length-1; i++)
        {
        auctionnID[i] = auctionnID[i+1];      
        }
        auctionnID.pop();
        emit BidAccepted(_tokenAddress,_tokenId,bidData.highestBidder,bidData.highestBid,auctionData.coinAddress);
    }


    function _getValidBid( address _tokenAddress, uint256 _tokenId) internal view returns (BidData memory bidData)
    {
        bidData = bidByTokenId[_tokenAddress][_tokenId];
        require(bidData.bidId != 0, "Marketplace: asset not published");
    }  

  //  Get the Highest Bid on the Token ID

    function getHighestBid(address _tokenAddress,uint _tokenId) public view returns(uint)
    {
        BidData memory bidData = _getValidBid( _tokenAddress,_tokenId);
        return fundsByBidder[bidData.highestBidder];
    }

    //...........................................................................................................................................................................        

    //Returns       1)Auction ID           2)Order ID     3)Total NFT owned by the address
    function tokensOfOwner(address _tokenAddress,address _owner)public view returns (uint[]memory OrderId, uint[]memory AuctionId, uint[]memory TokensOfOwner)
    {

        address newTokenAdrres=_tokenAddress;
        address owner1=_owner;
        IERC721 tokenRegistry = IERC721(newTokenAdrres);
        uint256 count = tokenRegistry.balanceOf(owner1);
        AuctionData memory auctionData;
        Order memory order ;
        uint256[] memory resultTokensOfOwner = new uint256[](count);
        uint256[] memory resultOrder=new uint256[](getOrderTokenIds(owner1,newTokenAdrres));
        uint256[] memory resultAuction=new uint256[](getAuctionTokenIds(newTokenAdrres,owner1));
        uint orderIndex=0;  
        uint auctionIndex=0;
        
        for (uint256 index = 0; index < auctionnID.length; index++) {
            uint aa=auctionnID[index];
           auctionData=auctionById[newTokenAdrres][aa];
            if(auctionData.seller==owner1)
            {
               
                resultAuction[auctionIndex]=auctionnID[index];
                auctionIndex++;
                
            }
        }

        for (uint256 index = 0; index < orderrID.length; index++) {
            uint aa=orderrID[index];
            order = orderByTokenId[newTokenAdrres][aa];
            if(order.seller==owner1)
            {
               
                resultOrder[orderIndex]=orderrID[index];
               orderIndex++;
            }
        }

        for (uint256 index = 0; index < count; index++) {
            resultTokensOfOwner[index] = tokenRegistry.tokenOfOwnerByIndex(owner1, index);
        }
        return (resultOrder,resultAuction,resultTokensOfOwner);
    }





//.............................................OFFER SECTION..............................................................................................................................        

    //Make Offer by $AURA & $WETH

    function makeOffer(address _tokenAddress,uint256 _amount,uint256 _tokenId,uint256 _time,address _coinAddress) public 
    {
        
        IERC20  Token;
        Token=IERC20(_coinAddress);
        IERC721 tokenRegistry = IERC721(_tokenAddress);
        address tokenOwner=tokenRegistry.ownerOf(_tokenId);
        require(tokenOwner != msg.sender," owner can not make offer");
        uint allowed= Token.allowance(msg.sender,address(this));
        require(allowed>=_amount,"low allowance");
        
        bytes32 offerId = keccak256(abi.encodePacked(_tokenAddress,_amount,_tokenId,msg.sender));
   
        offerByBuyer[_tokenAddress][_tokenId]=Offer({
           
            amount:_amount,
            expiry:block.timestamp+_time,
            buyerAddress:msg.sender,
            contractaddress:_tokenAddress,
            tokenid:_tokenId,
            offerid: offerId,
            coinAddress:_coinAddress
        });


        Offer memory  object;
        object.amount=_amount;
        object.expiry=block.timestamp+_time;
        object.buyerAddress=msg.sender;
        object.contractaddress=_tokenAddress;
        object.tokenid=_tokenId;
        object.coinAddress=_coinAddress;
        OfferArray.push(object);
        
        emit OfferMade(_tokenAddress,_tokenId,msg.sender, _time, _amount,_coinAddress);

    }

 


  
    function acceptOffer(address _tokenAddress,uint256 tokenId,uint _amount,address _buyer,address _coinAddress) public {

      
        bytes32 offerId = keccak256(abi.encodePacked(_tokenAddress,_amount,tokenId,_buyer));
        IERC20  Token;
        Token=IERC20(_coinAddress);
        
        IERC721 tokenRegistry = IERC721(_tokenAddress);
        address tokenOwner=tokenRegistry.ownerOf(tokenId);

        Offer memory  offer = offerByBuyer[_tokenAddress][tokenId];
        // address buyerAddress=offer.buyerAddress;
        // uint amount=offer.amount;

    

        // address CoinAddress=offer.coinAddress;
        require (offer.coinAddress==_coinAddress,"use same token");
        
        require (offer.offerid==offerId,"invalid offer");

        require(offer.expiry> block.timestamp,"offer expires");

        require(tokenOwner==msg.sender,"user is not owner");
        

        //Id trnsfer
        tokenRegistry.transferFrom(msg.sender,_buyer,tokenId);
  

        // getting values for royalties
        uint256 royaltyAmount=Royalties[_tokenAddress].amount;
        address owner=Royalties[_tokenAddress].owner;

        //royalty calculation 
        uint256 royaltyCut =  _amount*royaltyAmount/100000000000000000000;
        uint256 MP_FEE     =  _amount*marketplaceFEE/100000000000000000000;
        uint256 sellerCut  =  _amount-(royaltyCut+MP_FEE);


        
        // sending money
 
        if (royaltyAmount==0){Token.transferFrom(_buyer, msg.sender,sellerCut);
         Token.transferFrom(_buyer,marketOwner,MP_FEE);}
        else{
        // sending token
        Token.transferFrom(_buyer, msg.sender,sellerCut);
        Token.transferFrom(_buyer, owner,royaltyCut);
        Token.transferFrom(_buyer,marketOwner,MP_FEE);}

    
        delete offer;
        emit offerAccepted(_tokenAddress,tokenId,_amount, _buyer,_coinAddress);

    }

    // // returns the number of offers on id

        function getcount(uint  _tokenid,address _tokenAddress)
        internal
        view
        returns (uint256 total)
    {
        uint256 countt = 0;
        for (uint256 index = 0; index < OfferArray.length; index++) {
            if (OfferArray[index].tokenid == _tokenid && OfferArray[index].contractaddress == _tokenAddress ) {
                countt += 1;
            }
        }
        return countt;
        
    }


    //returns the total  offers data of the owner

    function getoffers(address _contractaddress,uint256 _tokenid)
        public
        view
        returns ( uint256 [] memory   amount,
                //   uint256 [] memory   time,
                  uint256 [] memory   tokenid,
                  address [] memory   buyeraddress,
                  address [] memory   contractaddress,
                  address [] memory   coinaddress
        )        
                      
    {    uint256 dyanamicIndex = 0;

        uint256 [] memory _amount         = new uint256   [](getcount(_tokenid,_contractaddress));
    // uint256 [] memory _time           = new uint256   [](getcount(_tokenid,_contractaddress));
        uint256 [] memory tokenId         = new uint256   [](getcount(_tokenid,_contractaddress));
        address [] memory _buyeraddress   = new address   [](getcount(_tokenid,_contractaddress));
        address [] memory contractAddress = new address   [](getcount(_tokenid,_contractaddress));
        address [] memory  coinAddress   = new address    [](getcount(_tokenid,_contractaddress));
       
        for (uint256 index = 0; index < OfferArray.length; index++) {
         if (OfferArray[index].tokenid == _tokenid && OfferArray[index].contractaddress == _contractaddress) {
                _amount         [dyanamicIndex]         = OfferArray [index].amount;
                // _time           [dyanamicIndex]         = OfferArray [index].expiry;
                tokenId         [dyanamicIndex]         = OfferArray [index].tokenid;
                _buyeraddress   [dyanamicIndex]         = OfferArray [index].buyerAddress;
                contractAddress [dyanamicIndex]         = OfferArray [index].contractaddress;
                coinAddress     [dyanamicIndex]         = OfferArray [index].coinAddress;
                

                dyanamicIndex++;
            }
        }
        // return (_amount, _time,tokenId, _buyeraddress,contractAddress,coinAddress);
         return (_amount,tokenId, _buyeraddress,contractAddress,coinAddress);

        

    }


//this function is used to get the full array of structures i
// function getoffers(address _contractaddress,uint256 _tokenid) public view returns (Offer[] memory){
//       Offer[]    memory id = new Offer[] (getcount(_tokenid,_contractaddress));
//       for (uint i = 0; i < getcount(_tokenid,_contractaddress); i++) {
//           Offer storage offer = offerByBuyer[_contractaddress][_tokenid];
//           id[i] = offer;
//       }
//       return id;
//   }

    
// withdraw eth ,aura $ weth from contract

    function withdraw() public onlyOwner {
        uint256 totalbalance=address(this).balance;
        (bool hq,) = payable(owner()).call{value:totalbalance }("");
        require(hq);
       

    }


}