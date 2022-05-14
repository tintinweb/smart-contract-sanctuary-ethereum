/**
 *Submitted for verification at Etherscan.io on 2022-05-14
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

// File: nft_marketplace.sol

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;









//contract-name = NFTMarket

contract NFTMarket is ReentrancyGuard {



  //n = no of items

  uint256 public n;

  //commision

  uint256 public commission_for_marketplace;

  //owner of nft marketplace

  address payable public owner;



// constructor

  constructor() {

    owner = payable(msg.sender);

    n=0;

    commission_for_marketplace = 0;



 }

// to transfer ownership of nft marketplace

  function transferOwner(address beneficiary) public{

    require(msg.sender==owner);

    owner = payable(beneficiary);

  }



  //to set commision by owner of nft marketplace

  function setCommission(uint256 fee)public{

    require(msg.sender==owner);

    commission_for_marketplace = fee;

 }

// increment function

  function increment() private {

          n = n+1;

      }



  // MarketToken data structure

  struct MarketToken {

     uint256 itemId;  //item id

     uint256 tokenId; //tokenid

     address nftContract; //nft contractAddress of token

     address payable owner; //owner of nft

     address payable creater; //creator of nft

     address payable prev_owner; // previous owner of nft

     uint256 price; // price of nft

     uint royalities; // royality for nfts

     uint256 time;//this says the time for auction

     address payable bidder; //latest bidder of nft

     bool sell; // this is bool statement to keep it for sale or not

     bool is_fixed;//this says that item is for fixed price or not



}



  mapping(uint256 => MarketToken) private markettokens;



  event create_market_items_for_erc721(uint256 indexed itemId,address,uint );

  event create_market_sale(uint indexed, uint256 , address indexed,address indexed);

  event keep_for_sale(uint256 indexed itemId,uint256);

  event keep_for_timed_auction(uint256 indexed itemId,uint256,uint256);

  event bid(uint256 indexed itemId,uint256 ,address indexed);

  event burn_token(uint256 indexed);

  event cancel_sale(uint256 indexed);









  function create_market_item_for_erc721(uint256 tokenId , address nftContract,uint royalities) public  {

    require(IERC721(nftContract).ownerOf(tokenId) == msg.sender);

    increment();

    markettokens[n] = MarketToken(n,tokenId,nftContract,payable(msg.sender),payable(msg.sender),payable(0x00),0,royalities,0,payable(0x00),false,false);



    emit create_market_items_for_erc721(n , nftContract,royalities);

}



  function createMarketSale_erc721(uint256 itemId) public payable nonReentrant{

    uint256 price = markettokens[itemId].price;

    uint royality = markettokens[itemId].royalities ;

    uint commission = commission_for_marketplace ;

    require(msg.value >= price, 'Please submit the asking price in order to continuee the transcation');

    require(markettokens[itemId].sell = true,'this is not for sale');







    if(markettokens[itemId].is_fixed==true ){

      markettokens[itemId].prev_owner = markettokens[itemId].owner;

      markettokens[itemId].owner.transfer((price/10000)*(10000-commission-royality));

      markettokens[itemId].creater.transfer((price/10000)*royality);

      owner.transfer((price/10000)*(commission));

      markettokens[itemId].owner = payable(msg.sender);

      markettokens[itemId].sell = false;

      markettokens[itemId].price = 0;



      IERC721(markettokens[itemId].nftContract).safeTransferFrom(markettokens[itemId].prev_owner,msg.sender,markettokens[itemId].tokenId);

}

    else {

      require(msg.sender == markettokens[itemId].bidder,'your not a auction winner');

      markettokens[itemId].prev_owner = markettokens[itemId].owner;

      markettokens[itemId].owner.transfer((price/10000)*(10000-commission-royality));

      markettokens[itemId].creater.transfer((price/10000)*royality);

      owner.transfer((price/10000)*(commission));

      markettokens[itemId].owner = payable(msg.sender);

      markettokens[itemId].sell = false;

      markettokens[itemId].bidder = payable(0x00);

      markettokens[itemId].price = 0;



      IERC721(markettokens[itemId].nftContract).safeTransferFrom(markettokens[itemId].prev_owner,msg.sender,markettokens[itemId].tokenId);

}



    emit create_market_sale(itemId,price,msg.sender,markettokens[itemId].prev_owner);

}



  function keepForSale(uint256 itemId,uint256 price) public {

    require(check_for_ownership(itemId) == true);

    require(msg.sender == markettokens[itemId].owner,'your are not owner of nfts');

    require(markettokens[itemId].sell ==false,'it is already in sale');

    markettokens[itemId].price = price;

    markettokens[itemId].sell = true;

    markettokens[itemId].is_fixed=true;

    emit keep_for_sale(itemId,price);

}













  function fetchallnfts() public view returns(MarketToken[] memory) {

    uint totalItemCount =n;

    uint itemCount = 0;

    uint currentIndex = 0;

    for(uint i = 0; i < totalItemCount; i++) {

      if(markettokens[i + 1].owner != address(0x00)) {

          itemCount += 1;

        }

      }

    MarketToken[] memory items = new MarketToken[](itemCount);

    for(uint i = 0; i < totalItemCount; i++) {

        if(markettokens[i +1].owner != address(0x00)) {

            uint currentId = i+1;

            MarketToken memory currentItem = markettokens[currentId];

            items[currentIndex]= currentItem;

            currentIndex += 1;

        }

      }

      return items;

    }



    function fetchallnftsbyOwner() public view returns(MarketToken[] memory){

    uint totalItemCount =n;

    uint itemCount = 0;

    uint currentIndex = 0;



    for(uint i = 0; i < totalItemCount; i++) {

      if(markettokens[i + 1].owner == msg.sender) {

          itemCount += 1;

        }

      }

    MarketToken[] memory items = new MarketToken[](itemCount);

    for(uint i = 0; i < totalItemCount; i++) {

        if(markettokens[i +1].owner == msg.sender) {

            uint currentId = i+1;

            MarketToken memory currentItem = markettokens[currentId];

            items[currentIndex]= currentItem;

            currentIndex += 1;

        }

      }

      return items;

    }





    function fetchallnftsbyCreater() public returns(MarketToken[] memory) {

      uint totalItemCount =n;

      uint itemCount = 0;

      uint currentIndex = 0;



      for(uint i = 0; i < totalItemCount; i++) {

        if(check_for_ownership(i+1) == true ||markettokens[i + 1].creater == msg.sender) {

            itemCount += 1;

          }

        }

      MarketToken[] memory items = new MarketToken[](itemCount);

      for(uint i = 0; i < totalItemCount; i++) {

          if(markettokens[i +1].creater == msg.sender) {

              uint currentId = i+1;

              MarketToken memory currentItem = markettokens[currentId];

              items[currentIndex]= currentItem;

              currentIndex += 1;

          }

        }

        return items;

      }





      function fetchallnftsbyBidder() public view returns(MarketToken[] memory) {

        uint totalItemCount =n;

        uint itemCount = 0;

        uint currentIndex = 0;



        for(uint i = 0; i < totalItemCount; i++) {

          if(markettokens[i + 1].bidder == msg.sender) {

              itemCount += 1;

            }

          }

        MarketToken[] memory items = new MarketToken[](itemCount);

        for(uint i = 0; i < totalItemCount; i++) {

            if(markettokens[i +1].bidder == msg.sender) {

                uint currentId = i+1;

                MarketToken memory currentItem = markettokens[currentId];

                items[currentIndex]= currentItem;

                currentIndex += 1;

            }

          }

          return items;

        }





      function fetchnftsbyfixed_price() public view returns(MarketToken[] memory) {

        uint totalItemCount =n;

        uint itemCount = 0;

        uint currentIndex = 0;



        for(uint i = 0; i < totalItemCount; i++) {

          if(markettokens[i + 1].sell == true && markettokens[i + 1].is_fixed == true) {

              itemCount += 1;

            }

          }

        MarketToken[] memory items = new MarketToken[](itemCount);

        for(uint i = 0; i < totalItemCount; i++) {

            if(markettokens[i + 1].sell == true && markettokens[i + 1].is_fixed == true) {

                uint currentId = i+1;

                MarketToken memory currentItem = markettokens[currentId];

                items[currentIndex]= currentItem;

                currentIndex += 1;

            }

          }

          return items;

        }

      function fetchnftsbytimedauction() public view returns(MarketToken[] memory) {

        uint totalItemCount =n;

        uint itemCount = 0;

        uint currentIndex = 0;



        for(uint i = 0; i < totalItemCount; i++) {

          if(markettokens[i + 1].sell == true && markettokens[i + 1].is_fixed == false) {

              itemCount += 1;

            }

          }

        MarketToken[] memory items = new MarketToken[](itemCount);

        for(uint i = 0; i < totalItemCount; i++) {

            if(markettokens[i + 1].sell == true && markettokens[i + 1].is_fixed == false ) {

                uint currentId = i+1;

                MarketToken memory currentItem = markettokens[currentId];

                items[currentIndex]= currentItem;

                currentIndex += 1;

            }

          }

        return items;

     }



    function fetchNftbyItemid(uint256 itemId)view public returns(MarketToken memory){

      return markettokens[itemId];

    }







    function timed_bid(uint256 itemId,uint256 price)public {

      require(msg.sender!=markettokens[itemId].owner || markettokens[itemId].owner != payable(0x00));

      require(markettokens[itemId].sell ==true);

      require(check_auction_completed(itemId)==false);

      require(markettokens[itemId].is_fixed == false,'not for timed auction');

      require(markettokens[itemId].price < price,'bid for higher price');

      markettokens[itemId].price = price;

      markettokens[itemId].bidder = payable(msg.sender);

      emit bid(itemId,price,msg.sender);

    }











    function check_auction_completed(uint256 itemId)view public returns(bool){

      require(markettokens[itemId].sell ==true);

      require(markettokens[itemId].is_fixed == false);



      if(markettokens[itemId].time <= block.timestamp){

        return true;

      }

      else{

        return false;

      }

    }



      function keep_for_timedauction(uint256 itemId,uint256 time,uint price) public{

      require(check_for_ownership(itemId) == true);

      require(markettokens[itemId].owner ==msg.sender ,"you can't annonce for auction");

      markettokens[itemId].bidder=payable(0x00);

      markettokens[itemId].sell =true;

      markettokens[itemId].time = time;

      markettokens[itemId].is_fixed = false;

      markettokens[itemId].price = price;

      emit keep_for_timed_auction(itemId,price,time);



    }





    function burn(uint256 itemId) public{

      require(msg.sender == markettokens[itemId].owner || msg.sender == address(this),'your are not owner of token');

      markettokens[itemId].owner = payable(0x00);

      markettokens[itemId].bidder = payable(0x00);

      markettokens[itemId].price = 0;

      markettokens[itemId].sell =false;

      emit burn_token(itemId);

    }



    function cancelsale(uint256 itemId) public{

        require(check_for_ownership(itemId) == true);

        require(msg.sender == markettokens[itemId].owner,'your are not owner of token');

        require(markettokens[itemId].sell==true,'it is already not in sale');

        markettokens[itemId].sell=false;

        markettokens[itemId].bidder = payable(0x00);

        markettokens[itemId].price = 0;

        emit cancel_sale(itemId);

      }







  function check_for_ownership(uint256 itemId) public returns(bool boolean){

    if(markettokens[itemId].owner != payable(0x00)){

       if(IERC721(markettokens[itemId].nftContract).ownerOf(markettokens[itemId].tokenId) == markettokens[itemId].owner){

          boolean = true;

          return boolean;

       }

       else{

         burn(itemId);

         boolean = false;

         return boolean;

       }

    }







  }



  function fetchnftsinsale() public view returns(MarketToken[] memory) {

      uint totalItemCount =n;

      uint itemCount = 0;

      uint currentIndex = 0;



      for(uint i = 0; i < totalItemCount; i++) {

        if(markettokens[i + 1].sell == true) {

            itemCount += 1;

          }

        }

      MarketToken[] memory items = new MarketToken[](itemCount);

      for(uint i = 0; i < totalItemCount; i++) {

          if(markettokens[i + 1].sell == true) {

              uint currentId = i+1;

              MarketToken memory currentItem = markettokens[currentId];

              items[currentIndex]= currentItem;

              currentIndex += 1;

          }

        }

        return items;

      }







}