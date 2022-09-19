// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.8;
import "./Accept.sol";
import "./IERC721.sol";
import "./utils/SafeMath.sol";

contract AuctionNFT is Accept {
  using SafeMath for uint256;
  struct Bid {
    address payable user;
    uint256 amount;
  }
  struct Order {
    uint256 tokenId;
    uint256 price;
    uint256 startTime;
    uint256 deadline;
    uint256 bidCount;
    uint256[] bidList;
    mapping(uint256 => Bid) bids;
    mapping(address => uint256) bidNo;
    uint256 fee;
    uint256 royalityPercent;
    uint256 highestBid;
    uint256[] bundleIds;
    bool isSingle;
    bool isOpenForBids;
    address buyer;
    address payable seller;
    mapping(uint256 => NftStat) tokenDet; //nftDet;
  }
  struct NftStat {
    address nftAddress;
    address tokenAddress;
    mapping(address => bool) bidder;
    mapping(address => uint8) sameCreator;
    address payable[] creators;
  }
  mapping(uint256 => Order) public pendingOrders;
  mapping(uint256 => Order) public completedOrders;
  mapping(uint256 => Order) public cancelledOrders;
  mapping(uint256 => bool) public isTokenListed;
  mapping(uint256 => bool) public isOrderExist;

  uint256[] private orderList;
  event AddAuction(uint256 _orderNumber,uint256 _tokenId, address _nftAddress, address _seller, uint256 _price, uint256 _startTime,uint256 _deadline,uint256 _royalityPercent,bool _isOpenForBids,string _token);
  event CancelAuction(uint256 _orderNumber, address _seller);
  event AddBid(uint256 _orderNumber, uint256 _bidAmount, address _bidder, uint256 _bidCount, address _nftAddress, uint256 _tokenId);
  event FinalizeAuction(uint256 _orderNumber, address _seller, address _nftAddress);
  event AddBundleAuction(uint256 _orderNumber,address _nftAddress,address _seller,uint256 _price,uint256 _startTime,uint256 _deadline, uint256 _royalityPercent, bool _isOpenForBids,uint256[] bundleIds, string _nftType);
  event CancelBid(uint256 _orderNumber, uint256 _bidNo, address _bidder, uint256 _amount);
  event DiscountOffer(address _owner, uint256 _discount, uint256 _tokenId);
  event UpdatePrice(address owner, uint256 price, uint256 orderNumber);  
  modifier isSellerOrAdmin(uint256 orderNumber) {
    require(msg.sender == owner() || msg.sender == pendingOrders[orderNumber].seller, "IS_SELLER_ADMIN");
    _;
  }

  constructor(uint256 fee) public {
    require(fee <= 10000, "IVALID_FEE");
    orderFee = fee;
  }
  function addAuction(
    address nftAddress,
    uint256 tokenId,
    uint256 price,
    uint256 orderNumber,
    uint256 startTime,
    uint256 deadline,
    uint256 royalityPercent,
    bool isOpenForBids,
    string memory tokenType
  ) public { 
    require(royalityPercent <6000,"ROYALITY_EXCEEDS");
    require(tokens[tokenType] != address(0), "INVALID_TOKEN_TYPE");
    require(IERC721(nftAddress).isApprovedForAll(msg.sender, address(this)) == true || IERC721(nftAddress).getApproved(tokenId) == address(this), "NOT_APPROVED");
    require((startTime >= now) && deadline > startTime, "SET_VALID_TIME");
    require(!isOrderExist[orderNumber] ,"ORDER_NUM_EXIST");
    require(IERC721(nftAddress).ownerOf(tokenId) == msg.sender,"SHOULD_BE_OWNER");
    require(!isTokenListed[tokenId] ,"ALREADY_LISTED");
    pendingOrders[orderNumber].tokenId = tokenId;
    pendingOrders[orderNumber].tokenDet[orderNumber].nftAddress = nftAddress;
    pendingOrders[orderNumber].buyer = address(this);
    pendingOrders[orderNumber].seller = msg.sender;
    pendingOrders[orderNumber].price = price;
    pendingOrders[orderNumber].startTime = startTime;
    pendingOrders[orderNumber].isSingle = true;
    pendingOrders[orderNumber].deadline = deadline;
    pendingOrders[orderNumber].royalityPercent = royalityPercent;
    pendingOrders[orderNumber].isOpenForBids = isOpenForBids;
    isTokenListed[tokenId] = true;
    isOrderExist[orderNumber] = true;

    pendingOrders[orderNumber].tokenDet[orderNumber].tokenAddress = tokens[tokenType];
    orderList.push(orderNumber);
    emit AddAuction(orderNumber, tokenId, nftAddress, msg.sender, price, startTime, deadline, royalityPercent, isOpenForBids, tokenType);

  }

  function addMultiAuction(
    address nftAddress,
    uint256[] memory tokenId,
    uint256 price,
    uint256[] memory orderNumber,
    uint256 startTime,
    uint256 deadline,
    uint256 royalityPercent,
    bool isOpenForBids,
    string memory tokenType
  ) public {
    require(royalityPercent <6000,"ROYALITY_EXCEEDS");
    for (uint256 i = 0; i < tokenId.length; i++) {
      require(IERC721(nftAddress).isApprovedForAll(msg.sender, address(this)) == true || IERC721(nftAddress).getApproved(tokenId[i]) == address(this), "NOT_APPROVED");
      require(!isOrderExist[orderNumber[i]] ,"ORDER_NUM_EXIST");
      require(IERC721(nftAddress).ownerOf(tokenId[i]) == msg.sender, "SHOULD_BE_OWNER");
      require(!isTokenListed[tokenId[i]] ,"ALREADY_EXIST");
      pendingOrders[orderNumber[i]].tokenId = tokenId[i];
      pendingOrders[orderNumber[i]].tokenDet[orderNumber[i]].nftAddress = nftAddress;
      pendingOrders[orderNumber[i]].buyer = address(this);
      pendingOrders[orderNumber[i]].seller = msg.sender;
      pendingOrders[orderNumber[i]].price = price;
      pendingOrders[orderNumber[i]].startTime = startTime;
      pendingOrders[orderNumber[i]].deadline = deadline;
      pendingOrders[orderNumber[i]].royalityPercent = royalityPercent;
      pendingOrders[orderNumber[i]].isOpenForBids = isOpenForBids;
      pendingOrders[i].tokenDet[orderNumber[i]].tokenAddress = tokens[tokenType];
      isTokenListed[tokenId[i]] = true;
      pendingOrders[orderNumber[i]].isSingle = true;
      isOrderExist[orderNumber[i]] = true;
      orderList.push(orderNumber[i]);
      emit AddAuction(orderNumber[i],tokenId[i], nftAddress, msg.sender, price, startTime, deadline, royalityPercent, isOpenForBids, tokenType);
    }
  }

  function bid(uint256 orderNumber, uint256 _amount) public payable {
    Order storage order = pendingOrders[orderNumber];
    require(order.seller != msg.sender, "ITSELF_SELLER");
    if (keccak256(bytes(tokenOf[order.tokenDet[orderNumber].tokenAddress])) == keccak256(bytes("eth"))) {
      require(msg.value >= order.price, "NOT_ENOUGH_PAYMENT");
    } else {
      require(IBEP20(order.tokenDet[orderNumber].tokenAddress).allowance(msg.sender, address(this)) >= _amount, "NOT_ENOUGH_ALLOWNACE");
      require(IBEP20(order.tokenDet[orderNumber].tokenAddress).balanceOf(msg.sender) >= _amount, "NOT_ENOUGH_PAYMENT");
    }
    if (!order.isOpenForBids) {
      require(now <= order.deadline && now >= order.startTime, "AUCTION_ENDED");
    }
    require(IERC721(order.tokenDet[orderNumber].nftAddress).isApprovedForAll(order.seller, address(this)) == true, "NEED_TO_APPROVE");
    if (keccak256(bytes(tokenOf[order.tokenDet[orderNumber].tokenAddress])) != keccak256(bytes("eth"))) {
      IBEP20(order.tokenDet[orderNumber].tokenAddress).transferFrom(msg.sender, address(this), _amount);
    }
    if (order.tokenDet[orderNumber].bidder[msg.sender]) {
      for (uint256 i = 1; i <= order.bidCount; i++) {
        if (order.bids[i].user == msg.sender) {
          if (keccak256(bytes(tokenOf[order.tokenDet[orderNumber].tokenAddress])) == keccak256(bytes("eth"))) {
            require(msg.value > order.bids[i].amount, "BID_SHOULD_GREATER");
            order.bids[i].user.transfer(order.bids[i].amount);
          } else {
            require(_amount > order.bids[i].amount, "BID_SHOULD_GREATER");
            IBEP20(order.tokenDet[orderNumber].tokenAddress).transfer(msg.sender, _amount);
          }
          delete order.bids[i];
        }
      }
    }
    order.bidCount = order.bidCount + 1;
    order.bidList.push(order.bidCount);
    order.bids[order.bidCount].user = msg.sender;
    if (keccak256(bytes(tokenOf[order.tokenDet[orderNumber].tokenAddress])) == keccak256(bytes("eth"))) {
      if (order.highestBid < msg.value) {
        order.highestBid = msg.value;
      }
      order.bids[order.bidCount].amount = msg.value;
    } else {
      if (order.highestBid < _amount) {
        order.highestBid = _amount;
      }
      order.bids[order.bidCount].amount = _amount;
    }
    order.tokenDet[orderNumber].bidder[msg.sender] = true;
    order.bidNo[msg.sender] = order.bidCount;
    emit AddBid(orderNumber, msg.value, msg.sender, order.bidCount, order.tokenDet[orderNumber].nftAddress, order.tokenId);
  }

  function finalizeAuction(uint256 orderNumber) external isSellerOrAdmin(orderNumber) {
    Order storage order = pendingOrders[orderNumber];
    require(order.bidList.length != 0, "NO_BID_FOUND");
    if (!order.isOpenForBids) {
      require(now >= order.deadline, "AUCTION_NOT_ENDED");
    }
    (address buyer, uint256 amount) = getMaximumBid(orderNumber);
    if (order.isSingle) {
      IERC721(order.tokenDet[orderNumber].nftAddress).safeTransferFrom(order.seller, buyer, order.tokenId);
      isTokenListed[order.tokenId] = false;
    } else {
      for (uint256 i = 0; i < order.bundleIds.length; i++) {
        IERC721(order.tokenDet[orderNumber].nftAddress).safeTransferFrom(order.seller, buyer, order.bundleIds[i]);
        isTokenListed[order.bundleIds[i]] = false;
      }
    }
    uint256 _fee = _computeFee(amount);
    uint256 _royality = computeRoyality(amount, order.royalityPercent);
    if (keccak256(bytes(tokenOf[order.tokenDet[orderNumber].tokenAddress])) == keccak256(bytes("eth"))) {
      order.seller.transfer(amount.sub(_fee.add(_royality)));
      benefactor.transfer(_fee);
      if (!order.isSingle) {
        for (uint256 i = 0; i < order.tokenDet[orderNumber].creators.length; i++) {
          address creatorAdd = order.tokenDet[orderNumber].creators[i];
          uint256 creatorAmount = order.tokenDet[orderNumber].sameCreator[creatorAdd];
          uint256 calAmount = (creatorAmount.mul(_royality)).div(order.bundleIds.length);
          payable(creatorAdd).transfer(calAmount);
        }
      } else {
        payable(IERC721(order.tokenDet[orderNumber].nftAddress).creator(order.tokenId)).transfer(_royality);
      }
    } else {
      IBEP20(order.tokenDet[orderNumber].tokenAddress).transfer(order.seller, amount.sub(_fee.add(_royality)));
      IBEP20(order.tokenDet[orderNumber].tokenAddress).transfer(benefactor, _fee);
      if (order.isSingle) {
        IBEP20(order.tokenDet[orderNumber].tokenAddress).transfer(IERC721(order.tokenDet[orderNumber].nftAddress).creator(order.tokenId),_royality);
      } else {
        for (uint256 i = 0; i < order.tokenDet[orderNumber].creators.length; i++) {
          address creatorAdd = order.tokenDet[orderNumber].creators[i];
          uint256 creatorAmount = order.tokenDet[orderNumber].sameCreator[creatorAdd];
          uint256 calAmount = (creatorAmount.mul(_royality)).div(order.bundleIds.length);
          IBEP20(order.tokenDet[orderNumber].tokenAddress).transfer(creatorAdd, calAmount);
        }
      }
    }
    order.fee = _fee;
    for (uint256 i = 1; i <= order.bidCount; i++) {
      if (order.bids[i].user != buyer) {
        if (keccak256(bytes(tokenOf[order.tokenDet[orderNumber].tokenAddress])) == keccak256(bytes("eth"))) {
          order.bids[i].user.transfer(order.bids[i].amount);
        } else {
          IBEP20(order.tokenDet[orderNumber].tokenAddress).transfer(order.bids[i].user, order.bids[i].amount);
        }
      }
    }
    completedOrders[orderNumber] = order;
    isOrderExist[orderNumber] = false;
    delete pendingOrders[orderNumber];
    emit FinalizeAuction(orderNumber, msg.sender, order.tokenDet[orderNumber].nftAddress);
  }

  function getBidsCount(uint256 orderNumber) public view returns (uint256) {
    Order storage order = pendingOrders[orderNumber];
    return order.bidCount;
  }

  function getMaximumBid(uint256 orderNumber) public view returns (address, uint256) {
    Order storage order = pendingOrders[orderNumber];
    uint256 highestBid = 0;
    address biddingUser;
    for (uint256 i = 1; i <= order.bidCount; i++) {
      if (order.bids[i].amount > highestBid) {
        highestBid = order.bids[i].amount;
        biddingUser = order.bids[i].user;
      }
    }
    return (biddingUser, highestBid);
  }

  function getBidByIndex(uint256 orderNumber, uint256 index) public view returns (address user, uint256 amount) {
    Order storage order = pendingOrders[orderNumber];
    return (order.bids[index].user, order.bids[index].amount);
  }

  function cancelAuction(uint256 orderNumber) external isSellerOrAdmin(orderNumber) {
    Order storage order = pendingOrders[orderNumber];
    if (keccak256(bytes(tokenOf[order.tokenDet[orderNumber].tokenAddress])) == keccak256(bytes("eth"))) {
      for (uint256 i = 1; i <= order.bidCount; i++) {
        order.bids[i].user.transfer(order.bids[i].amount);
      }
    } else {
      for (uint256 i = 1; i <= order.bidCount; i++) {
        IBEP20(order.tokenDet[orderNumber].tokenAddress).transfer(order.bids[i].user, order.bids[i].amount);
      }
    }
    if (order.isSingle) {
      isTokenListed[order.tokenId] = false;
    } else {
      for (uint256 i = 0; i < order.bundleIds.length; i++) {
        isTokenListed[order.bundleIds[i]] = false;
      }
    }
    cancelledOrders[orderNumber] = order;
    isOrderExist[orderNumber] = false;
    delete pendingOrders[orderNumber];
    emit CancelAuction(orderNumber, msg.sender);
  }

  function cancelBid(uint256 orderNumber) external {
    Order storage order = pendingOrders[orderNumber];
    require(order.tokenDet[orderNumber].bidder[msg.sender], "NOT_VALID_BIDDER");
    require(order.isOpenForBids, "AUCTION_ENDED");
    uint256 bidNo = order.bidNo[msg.sender];
    (address buyer, uint256 amount) = getMaximumBid(orderNumber);
    uint256 highBidT;
    if (amount == order.highestBid && order.bidCount > 1) {
      if (order.highestBid != order.bids[1].amount) {
        highBidT = order.bids[1].amount;
      } else {
        highBidT = order.bids[2].amount;
      }
      for (uint256 i = 1; i <= order.bidCount; i++) {
        if (msg.sender == order.bids[i].user && highBidT < order.bids[i].amount) {
          order.highestBid = order.bids[i].amount;
          if (keccak256(bytes(tokenOf[order.tokenDet[orderNumber].tokenAddress])) == keccak256(bytes("eth"))) {
            order.bids[bidNo].user.transfer(order.bids[bidNo].amount);
          } else {
            IBEP20(order.tokenDet[orderNumber].tokenAddress).transfer(order.bids[i].user, order.bids[i].amount);
          }
        }
        if (i >= bidNo) {
          order.bids[i].user = order.bids[i + 1].user;
          order.bids[i].amount = order.bids[i + 1].amount;
        }
      }
    }
    order.bidCount--;
    emit CancelBid(orderNumber, bidNo, msg.sender, amount);
  }

  function addNftBundle(
    address nftAddress,
    uint256[] calldata tokenId,
    uint256 price,
    uint256 orderNumber,
    uint256 startTime,
    uint256 deadline,
    uint256 royalityPercent,
    bool isOpenForBids,
    string calldata tokenType
  ) external {
    require(royalityPercent <6000,"ROYALITY_EXCEEDS");
    require(!isOrderExist[orderNumber] ,"ORDER_NUM_EXIST");
    for (uint256 i = 0; i < tokenId.length; i++) {
      require(IERC721(nftAddress).isApprovedForAll(msg.sender, address(this)) == true || IERC721(nftAddress).getApproved(tokenId[i]) == address(this), "NOT_APPROVED");
      require(IERC721(nftAddress).ownerOf(tokenId[i]) == msg.sender, "SHOULD_BE_OWNER");
      require(!isTokenListed[tokenId[i]], "ALREADY_LISTED");
      pendingOrders[orderNumber].bundleIds.push(tokenId[i]); 
    }
    pendingOrders[orderNumber].tokenDet[orderNumber].nftAddress = nftAddress;
    pendingOrders[orderNumber].buyer = address(this);
    pendingOrders[orderNumber].seller = msg.sender;
    pendingOrders[orderNumber].price = price;
    pendingOrders[orderNumber].startTime = startTime;
    pendingOrders[orderNumber].deadline = deadline;
    pendingOrders[orderNumber].isSingle = false;
    pendingOrders[orderNumber].royalityPercent = royalityPercent;
    pendingOrders[orderNumber].isOpenForBids = isOpenForBids;
    pendingOrders[orderNumber].tokenDet[orderNumber].tokenAddress = tokens[tokenType];
    isOrderExist[orderNumber] = true;
    orderList.push(orderNumber);
    for (uint256 i = 0; i < pendingOrders[orderNumber].bundleIds.length; i++) {
      if (
        pendingOrders[orderNumber].tokenDet[orderNumber].sameCreator[IERC721(nftAddress).creator(pendingOrders[orderNumber].bundleIds[i])] >0
      ) {
        pendingOrders[orderNumber].tokenDet[orderNumber].sameCreator[IERC721(nftAddress).creator(pendingOrders[orderNumber].bundleIds[i])] += 1;
      } else {
        pendingOrders[orderNumber].tokenDet[orderNumber].sameCreator[IERC721(nftAddress).creator(pendingOrders[orderNumber].bundleIds[i])] = 1;
        pendingOrders[orderNumber].tokenDet[orderNumber].creators.push(
          payable(IERC721(nftAddress).creator(pendingOrders[orderNumber].bundleIds[i]))
        );
      }
    }
    uint256[] memory nftBundleIds = tokenId;
    emit AddBundleAuction(orderNumber, nftAddress, msg.sender, price, startTime, deadline, royalityPercent, isOpenForBids, nftBundleIds, "bundle");
  }
  function discountOffer(uint256[] calldata _orderNumbers, uint256 _percentage) external {
    require(_percentage > 0 && _percentage < 10000, "INVALID_PERCENTAGE");
    for (uint256 i = 0; i < _orderNumbers.length; i++) {
      Order storage pendOrd = pendingOrders[_orderNumbers[i]];
      require(pendOrd.seller == msg.sender, "ONLY_OWNER_CAN_UPDATE");
      require(isTokenListed[pendOrd.tokenId], "NOT_LISTED");
      require(pendOrd.seller == msg.sender, "ONLY_OWNER_CAN_UPDATE");
      pendOrd.price = (pendOrd.price).sub(((pendOrd.price).mul(_percentage)).div(10000));
      emit DiscountOffer(msg.sender, _percentage, _orderNumbers[i]);
    }
  }

  function orderDetail(uint256 orderNumber) public view returns (uint256[] memory orderIds, uint256[] memory bidLists) {
    Order memory order = pendingOrders[orderNumber];
    return (order.bundleIds, order.bidList);
  }
  function updatePrice(uint256 _orderNumber, uint256 _price )public  {
    require(_price > 0, "INVALID_PRICE");
    Order storage pendOrd = pendingOrders[_orderNumber];
    require(isTokenListed[pendOrd.tokenId], "NOT_EXIST");
    require(msg.sender == pendOrd.seller,"NOT_SELLER");
    pendOrd.price = _price;
    emit UpdatePrice(msg.sender, _price, _orderNumber);
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.8;
import "./IBEP20.sol";
import "./utils/Ownable.sol";

contract Accept is Ownable {
  IBEP20 BEP20;

  mapping(address => bool) public tokenStatus;
  mapping(string => address) public tokens;
  mapping(address => string) public tokenOf;
  address[] listOfTokens;
  uint256 public orderFee;
  address payable benefactor;

  constructor() public {
    benefactor = msg.sender;
  }

  function addTokens(address _tokenAddress, string memory _tokenName) public onlyOwner {
    require(!tokenStatus[_tokenAddress], "ALREADY_ADDED");
    tokens[_tokenName] = _tokenAddress;
    tokenOf[_tokenAddress] = _tokenName;
    listOfTokens.push(_tokenAddress);
    tokenStatus[_tokenAddress] = true;
  }

  function removeToken(string memory tokenName) public onlyOwner {
    require(tokenStatus[tokens[tokenName]], "NOT_EXIST");
    if (tokens[tokenName] == listOfTokens[listOfTokens.length - 1]) {
      delete listOfTokens[listOfTokens.length - 1];
    } else
      for (uint256 i = 0; i < listOfTokens.length - 1; i++) {
        if (listOfTokens[i] == tokens[tokenName]) {
          listOfTokens[i] = listOfTokens[i + 1];
        }
      }
    tokenStatus[tokens[tokenName]] = false;
    delete tokens[tokenName];
  }

  function _computeFee(uint256 _price) public view returns (uint256) {
    return (_price * orderFee) / 10000;
  }

  function computeRoyality(uint256 _price, uint256 _royality) public pure returns (uint256) {
    return (_price * _royality) / 10000;
  }

  function changeFee(uint256 fee) public onlyOwner {
    require(fee <= 10000, "PROVIDE_VALID_FEE");
    orderFee = fee;
  }

  function changeBenefactor(address payable newBenefactor) public onlyOwner {
    benefactor = newBenefactor;
  }

  function getBenefactor() public view returns (address _address) {
    return benefactor;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.8;

interface IERC721 {
  function burn(uint256 tokenId) external;

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  function mint(
    address _to,
    uint256 _tokenId,
    string calldata _uri,
    string calldata _payload
  ) external;

  function isApprovedForAll(address _owner, address _operator) external view returns (bool);

  function ownerOf(uint256 _tokenId) external returns (address _owner);

  function getApproved(uint256 _tokenId) external returns (address);

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  ) external;

  function creator(uint256 _id) external returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.8;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
  /**
   * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
   * - Addition cannot overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "ADD_OVERFLOW");

    return c;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SUB_OWERFLOW");
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `*` operator.
   *
   * Requirements:
   * - Multiplication cannot overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "OVERFLOW");

    return c;
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "DIVISION_BY_ZERO");
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "ZERO_MODULE");
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts with custom message when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.8;

// BEP20 Hardhat token = 0x5FbDB2315678afecb367f032d93F642f64180aa3
interface IBEP20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
   * @dev Returns the token name.
   */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

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
  function allowance(address _owner, address spender) external view returns (uint256);

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.8;

import "./Context.sol";
// import "hardhat/console.sol";
contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  constructor() public {

    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }
  function owner() public view returns (address) {
    return _owner;
  }
  modifier onlyOwner() {
    require(_owner == _msgSender(), "NOT_OWNER");
    _;
  }
  
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "ZERO_ADDRESS");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.8;
// import "hardhat/console.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  constructor() public {
    // console.log("Context Contract Constructor Call");
  }

  function _msgSender() internal view returns (address) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}