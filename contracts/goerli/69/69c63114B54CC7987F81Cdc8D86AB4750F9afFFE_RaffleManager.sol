// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// contract Raffle is IERC721Receiver, ReentrancyGuard{
//   using Counters for Counters.Counter;
// 	Counters.Counter private _itemIds;
// 	Counters.Counter private _itemsSold;
	
// 	address payable owner;
// 	uint256 public listingFee = 0.001 ether;

//   struct SimpleRaffleItem {
//     uint itemId;
//     uint256 tokenId;
//     address payable seller;
//     address payable owner;
//     uint256 price;
//   //   bool ended;
//     uint expiredAt;
//     uint ticketCap;
//   //   mapping(address => uint) gamblerTickets;
//   }

//   struct RaffleItem {
//     uint itemId;
//     uint256 tokenId;
//     address payable seller;
//     address payable owner;
//     uint256 price;
//     bool ended; // 티켓 다 팔리면 true 

//     uint expiredAt;
//     uint ticketCap;
//     mapping(address => uint) gamblerTickets;
//     address[] gamblerAddrs;
//   }

//   mapping(uint256 => RaffleItem) public vaultItems;

//   event NFTRaffleCreated (
//     uint indexed itemId,
//     uint256 indexed tokenId,
//     address seller,
//     address owner,
//     uint256 price,
//     bool ended,
//     uint expiredAt
//   );

//   function getListingFee() public view returns(uint256) {
//     return listingFee;
//   }

//   ERC721Enumerable nft;

//   // constructor(ERC721Enumerable _nft) {
//   //   owner = payable(msg.sender);
//   //   nft = _nft;
//   // }

//   function addRaffle(uint256 tokenId, uint256 price, uint expiredAt, uint ticketCap) public payable nonReentrant {
//     require(nft.ownerOf(tokenId) == msg.sender, "This NFT is not owned by this wallet.");
//     require(vaultItems[tokenId].tokenId == 0, "Already listed.");
//     require(price > 0, "Listing price must be higher than 0.");
//     require(msg.value == listingFee, "Not enough fee.");

//     // 래플 등록 때마다 itemId 번호 증가, 1번부터 시작
//     _itemIds.increment();
//     uint itemId = _itemIds.current();
//     // vaultItems[itemId] = RaffleItem(itemId, tokenId, payable(msg.sender), payable(address(this)), price, false, expiredAt, ticketCap);
//     RaffleItem storage raffleItem = vaultItems[itemId];
//     raffleItem.itemId = itemId;
//     raffleItem.tokenId = tokenId;
//     raffleItem.seller = payable(msg.sender);
//     raffleItem.owner = payable(address(this));
//     raffleItem.price = price;
//     raffleItem.ended = false;
//     raffleItem.expiredAt = expiredAt;
//     raffleItem.ticketCap = ticketCap;
    
//     // 컨트랙트에 해당 NFT 전송
//     nft.transferFrom(msg.sender, address(this), tokenId);
    
//     // Listing이 되면 event emit
//     emit NFTRaffleCreated(itemId, tokenId, msg.sender, address(this), price, false, expiredAt);
//   }

//   function buyNFT(uint256 itemId) public payable nonReentrant {
//     uint256 price = vaultItems[itemId].price;
//     uint256 tokenId = vaultItems[itemId].tokenId;

//     require(msg.value == price, "Exact amount of price is required.");
    
//     vaultItems[itemId].seller.transfer(msg.value);
//     payable(msg.sender).transfer(listingFee);
//     nft.transferFrom(address(this), msg.sender, tokenId);
//     vaultItems[itemId].ended = true;
//     _itemsSold.increment();

//     delete vaultItems[tokenId];
//     delete vaultItems[itemId];
//   }

//   function nftListings() public view returns (SimpleRaffleItem[] memory) {
//     uint itemCount = _itemIds.current();
//     uint unsoldItemCount = _itemIds.current() - _itemsSold.current();
//     uint currentIndex = 0;

//     SimpleRaffleItem[] memory items = new SimpleRaffleItem[](unsoldItemCount);

//     for (uint i = 0; i < itemCount; i++) {
//       if (vaultItems[i+1].owner == address(this)) {
//         // uint currentId = i + 1;
//         // RaffleItem storage currentItem = vaultItems[currentId];
//         // items[currentIndex] = currentItem;
//         items[currentIndex] = SimpleRaffleItem(
//           vaultItems[i + 1].itemId, 
//           vaultItems[i + 1].tokenId, 
//           vaultItems[i + 1].seller, 
//           vaultItems[i + 1].owner, 
//           vaultItems[i + 1].price, 
//           vaultItems[i + 1].expiredAt, 
//           vaultItems[i + 1].ticketCap);
//         currentIndex += 1;
//       }
//     }
//     return items;
//   }

//   function onERC721Received(
//     address,
//     address from,
//     uint256,
//     bytes calldata
//   ) external pure override returns (bytes4) {
//     require(from == address(0x0), "Cannot send nfts to Vault directly");
//     return IERC721Receiver.onERC721Received.selector;
//   }

//   // 이더 전송 처리 부분 필요
//   function joinRaffle(uint256 tokenId, uint ticketNum) public {
//     uint ticketCap = vaultItems[tokenId].ticketCap;
//     uint currentTicketCap = 0;
//     for(uint i=0; i<vaultItems[tokenId].gamblerAddrs.length; i++) {
//       address addr = vaultItems[tokenId].gamblerAddrs[i];
//       currentTicketCap += vaultItems[tokenId].gamblerTickets[addr];
//     }

//     require(currentTicketCap + ticketNum <= ticketCap, "Gambler's tickets are too many to join");

//     // 최초 참가자라면 티켓 갯수가 0
//     if(vaultItems[tokenId].gamblerTickets[msg.sender] == 0) {
//       // msg.sender is Gambler?
//       vaultItems[tokenId].gamblerAddrs.push(msg.sender);
//     }
//     vaultItems[tokenId].gamblerTickets[msg.sender] += ticketNum;

//     // 티켓 캡이 다 차면 마감 처리
//     if(currentTicketCap + ticketNum == ticketCap) {
//       closeRaffle();
//     }
//   }

//   // 써드파티에서 이 함수를 주기적으로 호출
//   function checkExpiredRaffles() public {
//     require(owner == msg.sender, "Only owner can execute this.");
//     uint itemCount = _itemIds.current();

//     for (uint i = 1; i < itemCount - 1; i++) {
//       if(vaultItems[i].expiredAt <= block.timestamp) {
//         // 만료된 래플 처리
//         closeRaffle();
//       }
//     }

//   }

//   // case1. winner가 정해졌을 때 -> 우리가 직접 winner에게 전송
//   // case2. winner가 없을 때 -> 각각의 참여자들에게 claim할 수 있게
//   function closeRaffle() public {

//   }

// }

contract Raffle is IERC721Receiver, ReentrancyGuard{

  address private raffleOwner;
  address private nftContract;
  uint256 private nftTokenId;
  uint256 private nftTokenType;
  uint256 private expiredAt;
  uint16 private ticketCap;
  uint32 private ticketPrice;
  uint8 private ticketPricePointer;

  // address payable private seller;
  // address payable private owner;
  // uint256 price;
//   bool ended;

  struct Purchase {
    address purchaser;
    uint timestamp;
    uint tickets;
  }

  Purchase[] private purchases;

// payable nonReentrant
  constructor (
    address _raffleOwner,
    address _nftContract,
    uint256 _nftTokenId,
    uint256 _nftTokenType,    
    uint256 _expiredAt, 
    uint16 _ticketCap, 
    uint32 _ticketPrice,
    uint8 _ticketPricePointer
  ) {
    raffleOwner = _raffleOwner;
    nftContract = _nftContract;
    nftTokenId = _nftTokenId;
    nftTokenType = _nftTokenType;
    expiredAt = _expiredAt;
    ticketCap = _ticketCap;
    ticketPrice = _ticketPrice;
    ticketPricePointer = _ticketPricePointer;

    // // 컨트랙트에 해당 NFT 전송
    // nft.transferFrom(msg.sender, address(this), tokenId);
  }

  function getExpiredAt() external view returns(uint) {
    return expiredAt;
  }

  function getRaffle() public view returns(uint, uint, uint) {
    return(expiredAt, ticketCap, ticketPrice);
  }

  function getPurchases() public view returns(Purchase[] memory) {
    return purchases;
  }

  // event NFTRaffleCreated (
  //   uint indexed itemId,
  //   uint256 indexed tokenId,
  //   address seller,
  //   address owner,
  //   uint256 price,
  //   bool ended,
  //   uint expiredAt
  // );

  // function getListingFee() public view returns(uint256) {
  //   return listingFee;
  // }

  // constructor(ERC721Enumerable _nft) {
  //   owner = payable(msg.sender);
  //   nft = _nft;
  // }

  // function buyNFT(uint256 itemId) public payable nonReentrant {
  //   uint256 price = vaultItems[itemId].price;
  //   uint256 tokenId = vaultItems[itemId].tokenId;

  //   require(msg.value == price, "Exact amount of price is required.");
    
  //   vaultItems[itemId].seller.transfer(msg.value);
  //   payable(msg.sender).transfer(listingFee);
  //   nft.transferFrom(address(this), msg.sender, tokenId);
  //   vaultItems[itemId].ended = true;
  //   _itemsSold.increment();

  //   delete vaultItems[tokenId];
  //   delete vaultItems[itemId];
  // }

  // function nftListings() public view returns (SimpleRaffleItem[] memory) {
  //   uint itemCount = _itemIds.current();
  //   uint unsoldItemCount = _itemIds.current() - _itemsSold.current();
  //   uint currentIndex = 0;

  //   SimpleRaffleItem[] memory items = new SimpleRaffleItem[](unsoldItemCount);

  //   for (uint i = 0; i < itemCount; i++) {
  //     if (vaultItems[i+1].owner == address(this)) {
  //       // uint currentId = i + 1;
  //       // RaffleItem storage currentItem = vaultItems[currentId];
  //       // items[currentIndex] = currentItem;
  //       items[currentIndex] = SimpleRaffleItem(
  //         vaultItems[i + 1].itemId, 
  //         vaultItems[i + 1].tokenId, 
  //         vaultItems[i + 1].seller, 
  //         vaultItems[i + 1].owner, 
  //         vaultItems[i + 1].price, 
  //         vaultItems[i + 1].expiredAt, 
  //         vaultItems[i + 1].ticketCap);
  //       currentIndex += 1;
  //     }
  //   }
  //   return items;
  // }

  function onERC721Received(
    address,
    address from,
    uint256,
    bytes calldata
  ) external pure override returns (bytes4) {
    require(from == address(0x0), "Cannot send nfts to Vault directly");
    return IERC721Receiver.onERC721Received.selector;
  }

  // 이더 전송 처리 부분 필요
  function purchaseTickets(address purchaser, uint timestamp, uint tickets) public {
    uint currentTicketCap = 0;
    for(uint i=0; i<purchases.length; i++) {
      currentTicketCap += purchases[i].tickets;
    }

    require(currentTicketCap + tickets <= ticketCap, "Purchaser's tickets are too many to join");

    purchases.push(Purchase(purchaser, timestamp, tickets));

    // 티켓 캡이 다 차면 마감 처리
    if(currentTicketCap + tickets == ticketCap) {
      // closeRaffle();
    }
  }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "contracts/Raffle.sol";

contract RaffleManager {

  address private owner;
  Raffle[] private raffles;

  constructor() {
    owner = msg.sender;
  }

  event NFTRaffleCreated (
    address raffleOwner,
    address nftContract,
    uint256 nftTokenId,
    uint256 nftTokenType,
    uint256 expiredAt, 
    uint16 ticketCap, 
    uint32 ticketPrice,
    uint8 ticketPricePointer,
    address raffleAddress
  );

  function createRaffle(
    address raffleOwner,
    address nftContract,
    uint256 nftTokenId,
    uint256 nftTokenType,
    uint256 expiredAt,
    uint16 ticketCap,
    uint32 ticketPrice,
    uint8 ticketPricePointer
  ) public {
    // require(nft.ownerOf(tokenId) == msg.sender, "This NFT is not owned by this wallet.");
    // require(vaultItems[tokenId].tokenId == 0, "Already listed.");
    // require(price > 0, "Listing price must be higher than 0.");
    // require(msg.value == listingFee, "Not enough fee.");

    Raffle raffle = new Raffle(
      raffleOwner, 
      nftContract, 
      nftTokenId, 
      nftTokenType, 
      expiredAt, 
      ticketCap, 
      ticketPrice, 
      ticketPricePointer
    );
    raffles.push(raffle);

    emit NFTRaffleCreated(
      raffleOwner, 
      nftContract, 
      nftTokenId, 
      nftTokenType, 
      expiredAt, 
      ticketCap, 
      ticketPrice, 
      ticketPricePointer,
      address(raffle)
    );
  }

  function getRaffles() public view returns(Raffle[] memory) {
    return raffles;
  }

  function deleteRaffle() public {

  }

  function checkExpiredRaffles() public {
    require(owner == msg.sender, "Only owner can execute this.");

    for (uint i = 0; i < raffles.length; i++) {
      if(raffles[i].getExpiredAt() <= block.timestamp) {
        // 만료된 래플 처리
        closeRaffle();
      }
    }

  }

  // case1. winner가 정해졌을 때 -> 우리가 직접 winner에게 전송
  // case2. winner가 없을 때 -> 각각의 참여자들에게 claim할 수 있게
  function closeRaffle() public {

  }

  // mapping(uint256 => Raffle) raffleMap;

}