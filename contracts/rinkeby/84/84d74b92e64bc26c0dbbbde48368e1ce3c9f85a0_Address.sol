/**
 *Submitted for verification at Etherscan.io on 2022-06-28
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;
// function _requireERC721(address _tokenAddress) internal view returns (IERC721)
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
    using Address for address;
    bytes4 public constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

   
    IERC20 public auraToken;
    IERC20 public WETHToken;

    uint [] public auctionnID;
    uint [] public orderrID;

   
    constructor(address _auraAddress, address _WETHToken)  Ownable() {
        auraToken=IERC20(_auraAddress);
        WETHToken=IERC20(_WETHToken);
        }
    
    // function setPaused(bool _setPaused) public onlyOwner {
    //     return (_setPaused) ? pause() : unpause();}
    
 //...........................................................................................................................................................................    
    struct Order {
        bytes32 orderId;
        address  payable seller; //seller address
        uint256 ethPrice;
        uint256 auraPrice;}

    struct AuctionData {
        bytes32 auctionId;
        address payable seller;
        uint256 minBid;         // Selling Price
        uint expiryTime;
        string paymentType;} 

    struct BidData{
       bytes32 bidId;
       uint bidCounter;
       uint newBid;
       uint auctionEndTime;
       address highestBidder;
       uint256 highestBid;}

     //offer  
    struct Offer{
        uint256 amount;
        uint256 expiry; 
        address buyerAddress;
        address contractaddress;
        uint256 tokenid;
        bytes32 offerid;
        string paymentType;
        }


    struct royalty{
       address contractADDress;
       address owner;
       uint256 amount;}
       mapping(address => royalty)public Royalties;
 
 Offer  [] public OfferArray;

    // struct OfferWETH{
    //     uint256[] amount;
    //     uint256[] expiry;
    //     address[] buyerAddress;
    // }

     
    // ORDER EVENTS
    event OrderCreated(bytes32 orderId,address indexed seller,uint256 indexed tokenId,uint256 ethPrice,uint256 auraPrice);
    event AuctionCreated(bytes32 orderId,address indexed seller,uint256 indexed tokenId,uint256 minBid,uint256 expiryTime);
    event OrderUpdated(bytes32 orderId,uint256 ethPrice,uint256 auraPricw);
    event OrderSuccessfull(bytes32 orderId,address indexed buyer);
    event OrderCancelled(bytes32 id);
    event LogBid(address bidder, uint highestBid, address highestBidder);
    event OfferMade(address Buyer,uint256 Time,uint256 Amount);
    event AuctionCancelled(bytes32 id);

  
    mapping(address => mapping(uint256 => Order)) public orderByTokenId;  
    mapping(address => mapping(uint256 => AuctionData)) public auctionByTokenId; 
    mapping(address => mapping(uint256 => BidData)) public bidByTokenId;
    mapping(bytes32 => Offer) public offerByBuyer;  //offer
    



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

    

    

 //...........................................................................................................................................................................    
    
    //create order
    function createOrder(address _tokenAddress,uint256 _tokenId, uint256 _ethPrice, uint _auraPrice) public 
    {
        _createOrder(_tokenAddress, _tokenId,  _ethPrice, _auraPrice);
    }

    function _createOrder(address _tokenAddress, uint256 _tokenId, uint256 _ethPrice,uint _auraPrice) internal
    {
       // Check nft registry
         IERC721 tokenRegistry = IERC721(_tokenAddress);
         
        // Check order creator is the asset owner
        address tokenOwner = tokenRegistry.ownerOf(_tokenId);

        require(tokenOwner == msg.sender,"Marketplace: Only the asset owner can create orders");
        require(_ethPrice > 0, "not enough funds send");

        tokenRegistry.safeTransferFrom(tokenOwner,address(this), _tokenId);
        
        // create the orderId
        bytes32 _orderId = keccak256(abi.encodePacked(_tokenId, _ethPrice, _auraPrice));
        orderByTokenId[_tokenAddress][_tokenId] = Order({
            orderId: _orderId,
            seller:payable(msg.sender),
            ethPrice: _ethPrice,
            auraPrice: _auraPrice
        });
        orderrID.push(_tokenId);
        emit OrderCreated(_orderId,msg.sender,_tokenId,_ethPrice,_auraPrice);
    }
    
    function createAuctionByEth(address _tokenAddress,uint256 _tokenId, uint256 _minBid,uint _expiryTime ,string memory _paymentType) public 
    {
        _createAuction(_tokenAddress,_tokenId,  _minBid, _expiryTime,_paymentType);
    }

    function createAuctionByAura(address _tokenAddress,uint256 _tokenId, uint256 _minBid,uint _expiryTime,string memory _paymentType) public 
    {
        _createAuction(_tokenAddress,_tokenId,  _minBid, _expiryTime,_paymentType);
    }

    function _createAuction(address _tokenAddress,uint256 _tokenId, uint256 _minBid, uint _expiryTime ,string memory _paymentType) internal
    {
        
         // Check nft registry
         IERC721 tokenRegistry = IERC721(_tokenAddress);
         
        // Check order creator is the asset owner
        address tokenOwner = tokenRegistry.ownerOf(_tokenId);
        require(tokenOwner == msg.sender,"Marketplace: Only the asset owner can create orders");
        require(_minBid > 0, "not enough funds send");
        tokenRegistry.safeTransferFrom(tokenOwner,address(this), _tokenId);
        
        // create the orderId
        bytes32 _auctionId = keccak256(abi.encodePacked(_tokenId,_minBid,_expiryTime));
        auctionByTokenId[_tokenAddress][_tokenId] = AuctionData({
            auctionId: _auctionId,
            seller: payable(msg.sender),
            minBid: _minBid,
            expiryTime: _expiryTime,
            paymentType:_paymentType

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
        emit AuctionCreated(_auctionId, msg.sender, _tokenId, _minBid, _expiryTime);
    }

  //...........................................................................................................................................................................    
   // CANCEL AUCTION 
  

function cancelAuction(address _nftAddress,uint256 _tokenId) public {
        AuctionData memory auctionData = auctionByTokenId[_nftAddress][_tokenId];
        BidData memory bidData = _getValidBid( _nftAddress,_tokenId);
        IERC721 tokenRegistry = IERC721(_nftAddress);
        require(auctionData.seller == msg.sender || msg.sender == owner(), "Marketplace: unauthorized sender");

        delete auctionByTokenId[_nftAddress][_tokenId];
        if (bidData.highestBid!=0){
           if(keccak256(abi.encodePacked(auctionData.paymentType)) == keccak256(abi.encodePacked("ETH")))
        {
        // sending eth
        payable(bidData.highestBidder).transfer(bidData.highestBid);
       
        }

            
       else if (keccak256(abi.encodePacked(auctionData.paymentType)) == keccak256(abi.encodePacked("AURA")))
       {
        
         // sending aura
       
        auraToken.transfer(bidData.highestBidder,bidData.highestBid);

      
         
    } tokenRegistry.safeTransferFrom(address(this), msg.sender,_tokenId); 
     }
    else{
        tokenRegistry.safeTransferFrom(address(this), msg.sender,_tokenId);  
        
    }
        emit AuctionCancelled(auctionData.auctionId);

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
        emit OrderCancelled(_orderId);
    }

//  //...........................................................................................................................................................................    

    //Update Order
    function updateOrder( address _tokenAddress,uint256 _tokenId, uint256 _ethPrice, uint256 _auraPrice) public 
    
    {   
        Order memory order = orderByTokenId[_tokenAddress][_tokenId];
        require(order.orderId != 0, "Markeplace: Order not yet published");
        require(order.seller == msg.sender, "Markeplace: sender is not allowed");
        require(order.ethPrice > 0, "Marketplace: Price should be bigger than 0");
        require(order.auraPrice > 0, "Marketplace: Price should be bigger than 0");                   
        bytes32 b=orderByTokenId[_tokenAddress][_tokenId].orderId;

        orderByTokenId[_tokenAddress][_tokenId] = Order({
            orderId: b,
            seller:payable(msg.sender),
            ethPrice: _ethPrice,
            auraPrice: _auraPrice
        });
         emit OrderUpdated(order.orderId, _ethPrice,_auraPrice);

    }

//  //...........................................................................................................................................................................    

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



    

    //Return total number of id being listed for Auction on a market place.
    function getAuctionTokenIds(address _contract,address _owner)public view returns(uint auctionId)
    {
        uint countt=0;
        AuctionData memory auctionData;
        for (uint256 index = 0; index < auctionnID.length; index++)
        {
        uint aa=auctionnID[index];
        auctionData = auctionByTokenId[_contract][aa];
        if(auctionData.seller==_owner)
        {   countt+=1;   }
        
        }
        return countt;
    }

//  //...........................................................................................................................................................................    


//     //Buy with ETH
    function safeExecuteOrderByEth( address _tokenAddress,uint256 _tokenId) public  payable
    {
        Order memory order = _getValidOrder( _tokenAddress,_tokenId);
        require(order.ethPrice == msg.value, "Marketplace: invalid price");
        require(order.seller != msg.sender,  "Marketplace: unauthorized sender");

        _executeOrder(_tokenAddress,order.orderId, msg.sender,   _tokenId);


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
    }

//     //Buy with $AURA
    function safeExecuteOrderByAura( address _tokenAddress,uint256 _tokenId) public 
    { 
        Order memory order = _getValidOrder( _tokenAddress,_tokenId);
        require(order.auraPrice <= auraToken.balanceOf(msg.sender), "Marketplace: invalid price");
        require(order.seller != msg.sender, "Marketplace: unauthorized sender");
        _executeOrder(_tokenAddress,order.orderId, msg.sender, _tokenId);

            // getting values for royalties
        uint256 royaltyAmount=Royalties[_tokenAddress].amount;
        address owner=Royalties[_tokenAddress].owner;

        //royalty calculation 
        uint256 royaltyCut =  (order.auraPrice*royaltyAmount)/100000000000000000000;
        uint256 MP_FEE     =  (order.auraPrice*marketplaceFEE)/100000000000000000000;
        uint256 sellerCut  =  order.auraPrice-(royaltyCut+MP_FEE);

        if (royaltyAmount==0){auraToken.transferFrom(msg.sender,order.seller,sellerCut);
         auraToken.transferFrom(msg.sender,address(this),MP_FEE);}
        else{
        auraToken.transferFrom(msg.sender,order.seller,sellerCut);
        auraToken.transferFrom(msg.sender,owner,royaltyCut);
         auraToken.transferFrom(msg.sender,address(this),MP_FEE);}

        for(uint i = _tokenId; i < orderrID.length-1; i++)
        {
              orderrID[i] = orderrID[i+1];      
        }
        orderrID.pop();
    }
    
    function _executeOrder(address _tokenAddress,bytes32 _orderId, address _buyer, uint256 _tokenId) internal
    {   
  // Check nft registry
         IERC721 tokenRegistry = IERC721(_tokenAddress);
         delete orderByTokenId[_tokenAddress][_tokenId];   
         tokenRegistry.safeTransferFrom(address(this), _buyer, _tokenId);  
         emit OrderSuccessfull(_orderId, _buyer);
    }
        
    function _getValidOrder( address _tokenAddress,uint256 _tokenId) internal view returns (Order memory order)
    {
        order = orderByTokenId[_tokenAddress][_tokenId];
        require(order.orderId != 0, "Marketplace: asset not published");
    }


//  //...........................................................................................................................................................................        

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
           auctionData=auctionByTokenId[newTokenAdrres][aa];
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

//  //...........................................................................................................................................................................        

   // Get the Highest Bid on the Token ID

    function getHighestBid(address _tokenAddress,uint _tokenId) public view returns(uint)
    {
        BidData memory bidData = _getValidBid( _tokenAddress,_tokenId);
        return fundsByBidder[bidData.highestBidder];
    }

//  //...........................................................................................................................................................................    


    function _getValidAuction( address _tokenAddress,uint256 _tokenId) internal view returns (AuctionData memory auctionData)
    {
        auctionData = auctionByTokenId[_tokenAddress][_tokenId];
        require(auctionData.auctionId != 0, "Marketplace: asset not published");
    }

    function _getValidBid( address _tokenAddress, uint256 _tokenId) internal view returns (BidData memory bidData)
    {
        bidData = bidByTokenId[_tokenAddress][_tokenId];
        require(bidData.bidId != 0, "Marketplace: asset not published");
    }       
    
    function placeBidAura(address _tokenAddress,uint _tokenId,uint _bid) public
    {
        AuctionData memory auctionData = _getValidAuction( _tokenAddress,_tokenId);
        BidData memory bidData = _getValidBid( _tokenAddress,_tokenId);
        require(keccak256(abi.encodePacked(auctionData.paymentType)) == keccak256(abi.encodePacked("AURA")),"auction is for eth please bid by aura");
        require(auraToken.balanceOf(msg.sender) >= auctionData.minBid, "error");
        require(auctionData.minBid <= _bid ,"new bid should be greater min bid");
        require(bidData.highestBid < _bid ,"new bid should be greater highest bid");
        require(block.timestamp <= bidData.auctionEndTime, "auction canceled");
        require(auraToken.balanceOf(msg.sender) > fundsByBidder[bidData.highestBidder], "error");
        if (bidData.bidCounter != 0)
        {

            auraToken.transfer(bidData.highestBidder,bidData.highestBid);
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
        auraToken.transferFrom(msg.sender,address(this),_bid);
        emit LogBid(msg.sender, bidData.highestBid, bidData.highestBidder);
        // return true;
    }


// only check fundsByBidder map whether we made it nested mapping or not .
    function placeBidEth(address _tokenAddress,uint _tokenId) public payable
    {
        AuctionData memory auctionData = _getValidAuction( _tokenAddress,_tokenId);
        BidData memory bidData = _getValidBid(_tokenAddress, _tokenId);
        require(keccak256(abi.encodePacked(auctionData.paymentType)) == keccak256(abi.encodePacked("ETH")),"auction is for eth please bid using eth");
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
        emit LogBid(msg.sender, bidData.highestBid, bidData.highestBidder);
        // return true;
    }

    function acceptBid(address _tokenAddress, uint256 _tokenId) public 
    {
        IERC721 tokenRegistry = IERC721(_tokenAddress);
        AuctionData memory auctionData = _getValidAuction( _tokenAddress,_tokenId);
        require(auctionData.seller==msg.sender,"user is not owner");
        BidData memory bidData = _getValidBid( _tokenAddress,_tokenId);
        require(block.timestamp > bidData.auctionEndTime,"Auction is not ended");
        tokenRegistry.safeTransferFrom(address(this), bidData.highestBidder, _tokenId);
       //getting values for royalties 
        uint256 royaltyAmount=Royalties[_tokenAddress].amount;
        address owner=Royalties[_tokenAddress].owner;

        if (royaltyAmount==0){

            //royalty calculation 
        // uint256 royaltyCut  =  bidData.highestBid*royaltyAmount/100000000000000000000;
        uint256 MP_FEE      =  bidData.highestBid*marketplaceFEE/100000000000000000000;
        uint256 sellerCut   =  bidData.highestBid-MP_FEE;
       

        if(keccak256(abi.encodePacked(auctionData.paymentType)) == keccak256(abi.encodePacked("ETH")))
        {
        // sending eth
        payable(auctionData.seller).transfer(sellerCut);
       
        }

            
       else if (keccak256(abi.encodePacked(auctionData.paymentType)) == keccak256(abi.encodePacked("AURA")))
       {
        
         // sending aura
       
        auraToken.transfer(msg.sender,sellerCut);

      
    } 

        }else {

            //royalty calculation 
        uint256 royaltyCut  =  bidData.highestBid*royaltyAmount/100000000000000000000;
        uint256 MP_FEE      =  bidData.highestBid*marketplaceFEE/100000000000000000000;
        uint256 sellerCut   =  bidData.highestBid-(royaltyCut+MP_FEE);
       

        if(keccak256(abi.encodePacked(auctionData.paymentType)) == keccak256(abi.encodePacked("ETH")))
        {
       
        // sending eth
        payable(auctionData.seller).transfer(sellerCut);
        payable(owner).transfer(royaltyCut);
        
        }
            
       else if (keccak256(abi.encodePacked(auctionData.paymentType)) == keccak256(abi.encodePacked("AURA")))
       {
        
        // sending aura
       
        auraToken.transfer(msg.sender,sellerCut);
        auraToken.transfer(owner,royaltyCut);

    
    } 
        }

         delete auctionByTokenId[_tokenAddress][_tokenId];
        for(uint i = _tokenId; i < auctionnID.length-1; i++)
        {
        auctionnID[i] = auctionnID[i+1];      
        }
        auctionnID.pop();
        
}






//Make Offer by $AURA & $WETH

function makeOffer(address _tokenAddress,uint256 _amount,uint256 _tokenId,uint256 _time,string memory _paymentType) public 
    {
        require( keccak256(abi.encodePacked(_paymentType))==keccak256(abi.encodePacked("AURA"))||keccak256(abi.encodePacked(_paymentType))==keccak256(abi.encodePacked("WETH")),"type must be AURA or WETH");
        IERC721 tokenRegistry = IERC721(_tokenAddress);
        address tokenOwner=tokenRegistry.ownerOf(_tokenId);
        require(tokenOwner != msg.sender," owner can not make offer");
         uint allowed= auraToken.allowance(msg.sender,address(this));
         require(allowed>=_amount,"low allowance");
        if(keccak256(abi.encodePacked(_paymentType))==keccak256(abi.encodePacked("AURA"))){
            require(auraToken.balanceOf(msg.sender)>=_amount,"Low aura balance");
        }else if (keccak256(abi.encodePacked(_paymentType))==keccak256(abi.encodePacked("WETH")))
        {require(WETHToken.balanceOf(msg.sender)>=_amount,"low weth balance");}

        
        bytes32 offerId = keccak256(abi.encodePacked(_tokenAddress,_amount,_tokenId,msg.sender));
   
        offerByBuyer[offerId]=Offer({
           
            amount:_amount,
            expiry:block.timestamp+_time,
            buyerAddress:msg.sender,
            contractaddress:_tokenAddress,
            tokenid:_tokenId,
            offerid: offerId,
            paymentType:_paymentType
        });


        Offer memory  object;
        object.amount=_amount;
        object.expiry=block.timestamp+_time;
        object.buyerAddress=msg.sender;
        object.contractaddress=_tokenAddress;
        object.tokenid=_tokenId;
        object.paymentType=_paymentType;
        OfferArray.push(object);
        
        emit OfferMade(msg.sender, _time, _amount);

    }


    function acceptOffer(address _tokenAddress,uint256 tokenId,uint256 _amount,address _buyer) public {

        bytes32 offerId = keccak256(abi.encodePacked(_tokenAddress,_amount,tokenId,_buyer));
        require(offerByBuyer[offerId].offerid==offerId,"invalid offer");
        require(offerByBuyer[offerId].expiry> block.timestamp,"offer expires");

        IERC721 tokenRegistry = IERC721(_tokenAddress);
        address tokenOwner=tokenRegistry.ownerOf(tokenId);
        require(tokenOwner==msg.sender,"user is not owner");
        address buyerAddress=offerByBuyer[offerId].buyerAddress;
    if(keccak256(abi.encodePacked(offerByBuyer[offerId].paymentType)) == keccak256(abi.encodePacked("AURA"))){

        // getting values for royalties
        uint256 royaltyAmount=Royalties[_tokenAddress].amount;
        address owner=Royalties[_tokenAddress].owner;

        //royalty calculation 
        uint256 royaltyCut =  _amount*royaltyAmount/100000000000000000000;
        uint256 MP_FEE     =  _amount*marketplaceFEE/100000000000000000000;
        uint256 sellerCut  =  _amount-(royaltyCut+MP_FEE);

        // sending money
 
        if (royaltyAmount==0){auraToken.transferFrom(buyerAddress, msg.sender,sellerCut);
         auraToken.transferFrom(buyerAddress,address(this),MP_FEE);}
        else{
        auraToken.transferFrom(buyerAddress, msg.sender,sellerCut);
        auraToken.transferFrom(buyerAddress, owner,royaltyCut);
        auraToken.transferFrom(buyerAddress,address(this),MP_FEE);}
        // sending token

    }
    else if (keccak256(abi.encodePacked(offerByBuyer[offerId].paymentType)) == keccak256(abi.encodePacked("WETH"))){
 // getting values for royalties
        uint256 royaltyAmount=Royalties[_tokenAddress].amount;
        address owner=Royalties[_tokenAddress].owner;

        //royalty calculation 
        uint256 royaltyCut =  _amount*royaltyAmount/100000000000000000000;
        uint256 MP_FEE     =  _amount*marketplaceFEE/100000000000000000000;
        uint256 sellerCut  =  _amount-(royaltyCut+MP_FEE);

        // sending money
 
        if (royaltyAmount==0){WETHToken.transferFrom(buyerAddress, msg.sender,sellerCut);
         WETHToken.transferFrom(buyerAddress,address(this),MP_FEE);}
        else{
        WETHToken.transferFrom(buyerAddress, msg.sender,sellerCut);
        WETHToken.transferFrom(buyerAddress, owner,royaltyCut);
        WETHToken.transferFrom(buyerAddress,address(this),MP_FEE);}
    }

        tokenRegistry.transferFrom(msg.sender,buyerAddress,tokenId);
        delete offerByBuyer[offerId];


    }


        function getcount(uint  _tokenid,address _ct)
        internal
        view
        returns (uint256 total)
    {


        uint256 countt = 0;
        

        for (uint256 index = 0; index < OfferArray.length; index++) {
            if (OfferArray[index].tokenid == _tokenid && OfferArray[index].contractaddress == _ct ) {
                countt += 1;
            }
        }
        return countt;
        
    }




// // returns the total  offers data of the owner

    function getoffers(address _contractaddress,uint256 _tokenid)
        public
        view
        returns ( uint256 [] memory   amount,
                  uint256 [] memory   time,
                  address [] memory   buyeraddress,
                  address [] memory   contractaddress,
                  uint256 [] memory   tokenid 
        )
            
                      
    {
       
        uint256 dyanamicIndex = 0;

        uint256 [] memory _amount         = new uint256   [](getcount(_tokenid,_contractaddress));
        uint256 [] memory _time           = new uint256   [](getcount(_tokenid,_contractaddress));
        address [] memory _buyeraddress   = new address   [](getcount(_tokenid,_contractaddress));
        address [] memory contractAddress = new address   [](getcount(_tokenid,_contractaddress));
        uint256 [] memory tokenId         = new uint256   [](getcount(_tokenid,_contractaddress));

        for (uint256 index = 0; index < OfferArray.length; index++) {
         if (OfferArray[index].tokenid == _tokenid && OfferArray[index].contractaddress == _contractaddress) {

            
                _amount         [dyanamicIndex]         = OfferArray [index].amount;
                _time           [dyanamicIndex]         = OfferArray [index].expiry;
                _buyeraddress   [dyanamicIndex]         = OfferArray [index].buyerAddress;
                contractAddress [dyanamicIndex]         = OfferArray [index].contractaddress;
                tokenId         [dyanamicIndex]         = OfferArray [index].tokenid;
                

                dyanamicIndex++;
            }
        }
        return (_amount, _time, _buyeraddress,contractAddress,tokenId);
    }


    

function withdraw() public onlyOwner {
        uint256 totalbalance=address(this).balance;
        (bool hq,) = payable(owner()).call{value:totalbalance }("");
        require(hq);
        auraToken.transfer(msg.sender,auraToken.balanceOf(address(this)));
        WETHToken.transfer(msg.sender,WETHToken.balanceOf(address(this)));

    }


}