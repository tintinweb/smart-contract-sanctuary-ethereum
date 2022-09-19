// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.8;
import "./Accept.sol";
import "./IERC721.sol";
import "./utils/SafeMath.sol";

contract SwapNFT is Accept {
  using SafeMath for uint256;

  struct Order {
    uint256 tokenId;
    address nftAddress;
    address buyer;
    address payable seller;
    uint256 price;
    uint256 fee;
    uint256 royalityPercent;
    uint256[] bundleIds;
    address tokenAddress;
    bool isOffer;
    bool isSingle;
    mapping(address => uint256) sameCreator;
    address[] creators;
  }

  // IBEP20 Bep20;
  mapping(uint256 => Order) public pendingOrders;
  mapping(uint256 => Order) public completedOrders;
  mapping(uint256 => Order) public cancelledOrders;
  mapping(uint256 => bool) public isTokenListed;
  mapping(uint256 => bool) public isOrderExist;
  // Events
  event AddOrder(
    uint256 _orderNumber,
    uint256 _tokenId,
    address _nftAddress,
    address _seller,
    uint256 _price,
    uint256 _fee,
    address _royalityAddress,
    uint256 _royalityPercent
  );
  event CancelOrder(uint256 _orderNumber, address _seller);
  event PurchaseOrder(
    uint256 _orderNumber,
    uint256 _tokenId,
    address _nftAddress,
    address _seller,
    address _buyer,
    uint256 _price,
    uint256 _fee,
    address _royalityAddress,
    uint256 _royalityAmount,
    string _token
  );
  event AddBundle(uint256 _orderNumber, address _nftAddress, address _seller, uint256 _price, uint256 _royalityPercent,uint256[] bundleIds, string _nftType);
  event DiscountOffer(address _owner, uint256 _discount, uint256 _tokenId);
  event MakeOffer(
    address nftAddress,
    uint256 tokenId,
    uint256 price,
    uint256 orderNumber,
    uint256 royalityPercent,
    string tokenType,
    address offer_sender
  );
  event AcceptOffer(
    uint256 _orderNumber,
    uint256 _tokenId,
    address _nftAddress,
    address _seller,
    address _buyer,
    uint256 _price,
    uint256 _fee,
    address _royalityAddress,
    uint256 _royalityAmount,
    string _token
  );
  event CancelOffer(uint256 _orderNumber, address _seller);
  event UpdatePrice(address owner, uint256 price, uint256 orderNumber);  
  constructor(uint256 fee) public {
    require(fee <= 10000, "INVALID_FEE");
    orderFee = fee;
    benefactor = msg.sender;
  }

  function purchaseOrder(uint256 orderNumber) external payable {
    Order storage order = pendingOrders[orderNumber];
    address tokenAddress = order.tokenAddress;
    IERC721 ierc721 = IERC721(order.nftAddress);
    IBEP20 Bep20 =IBEP20(order.tokenAddress);
    string memory tokenName = tokenOf[tokenAddress];
    require(tokenStatus[tokenAddress], "INVALID_TOKEN_NAME");
    if (keccak256(bytes(tokenName)) == keccak256(bytes("eth"))) {
      require(msg.value == order.price, "NOT_ENOUGH_PAYMENT");
    } else {
      require(Bep20.allowance(msg.sender, address(this)) >= order.price, "NOT_ENOUGH_ALLOWANCE");
      require(Bep20.balanceOf(msg.sender) >= order.price, "NOT_ENOUGH_PAYMENT");
    }
   
    if (!order.isSingle) {
      for (uint256 i = 0; i < order.bundleIds.length; i++) {
        ierc721.safeTransferFrom(order.seller, msg.sender, order.bundleIds[i]);
        isTokenListed[order.bundleIds[i]] = false;
      }
    } else {
      ierc721.safeTransferFrom(order.seller, msg.sender, order.tokenId);
      isTokenListed[order.tokenId] = false;
    }
    uint256 _fee = _computeFee(order.price);
    uint256 _royality = computeRoyality(order.price, order.royalityPercent);
    address creatorAdd = ierc721.creator(order.tokenId);
    if (keccak256(bytes(tokenName)) == keccak256(bytes("eth"))) {
      order.seller.transfer(order.price.sub(_fee.add(_royality)));
      benefactor.transfer(_fee);
      if (!order.isSingle) {
        for (uint256 i = 0; i < order.creators.length; i++) {
          address creatorAdd = order.creators[i];
          uint256 creatorAmount = order.sameCreator[creatorAdd];
          uint256 calAmount = (creatorAmount.mul(_royality)).div(order.bundleIds.length);
          payable(creatorAdd).transfer(calAmount);
        }
      } else {
        payable(ierc721.creator(order.tokenId)).transfer(_royality);
      }
    } else {
      Bep20.transferFrom(msg.sender, order.seller, order.price - (_fee + _royality));
      Bep20.transferFrom(msg.sender, benefactor, _fee);

      if (!order.isSingle) {
        for (uint256 i = 0; i < order.creators.length; i++) {
          uint256 calAmount = ((order.sameCreator[order.creators[i]]).mul(_royality)).div(order.bundleIds.length);
          Bep20.transferFrom(msg.sender, order.creators[i], calAmount);
        }
      } else {
        Bep20.transferFrom(msg.sender, creatorAdd, _royality);
      }
    }
    order.buyer = msg.sender;
    order.fee = _fee;
    completedOrders[orderNumber] = order;
    isOrderExist[orderNumber] = false;
    delete pendingOrders[orderNumber];

    emit PurchaseOrder(
      orderNumber,
      order.tokenId,
      order.nftAddress,
      order.seller,
      order.buyer,
      order.price,
      order.fee,
      creatorAdd,
      _royality,
      tokenName
    );
  }

  function cancelOrder(uint256 orderNumber) external {
    Order memory order = pendingOrders[orderNumber];
    require(order.seller == msg.sender, "ONLY_SELLER_CANCEL");
    cancelledOrders[orderNumber] = order;
    if(order.isSingle){
    isTokenListed[order.tokenId] = false;
    }else{
      for(uint256 i =0; i< order.bundleIds.length; i++){
        isTokenListed[order.bundleIds[i]] = false;
      }
    }
    isOrderExist[orderNumber] = false;
    delete pendingOrders[orderNumber];
    emit CancelOrder(orderNumber, msg.sender);
  }
  function addOrder(
    address nftAddress,
    uint256 tokenId,
    uint256 price,
    uint256 orderNumber,
    uint256 royalityPercent,
    string calldata tokenType
  ) external {
    IERC721 ierc721 = IERC721(nftAddress);
    require(royalityPercent <6000,"ROYALITY_EXCEEDS");
    require(IERC721(nftAddress).isApprovedForAll(msg.sender, address(this)) == true || IERC721(nftAddress).getApproved(tokenId) == address(this), "NOT_APPROVED");
    require(tokens[tokenType] != address(0), "INVALID_TOKEN");
    require(!isOrderExist[orderNumber] ,"ORDER_NUM_EXIST");
    require(IERC721(nftAddress).ownerOf(tokenId) == msg.sender, "SHOULD_BE_OWNER");
    require(!isTokenListed[tokenId] ,"ALREADY_LISTED");
    pendingOrders[orderNumber].tokenId = tokenId;
    pendingOrders[orderNumber].nftAddress = nftAddress;
    pendingOrders[orderNumber].buyer = address(this);
    pendingOrders[orderNumber].seller = msg.sender;
    pendingOrders[orderNumber].price = price;
    pendingOrders[orderNumber].royalityPercent = royalityPercent;
    isTokenListed[tokenId] = true;
    pendingOrders[orderNumber].tokenAddress = tokens[tokenType];
    pendingOrders[orderNumber].isSingle = true;
    isOrderExist[orderNumber] = true;
    emit AddOrder(orderNumber, tokenId, nftAddress, msg.sender, price, 0, IERC721(nftAddress).creator(tokenId), royalityPercent);
  }

  function addMultiOrder(
    address nftAddress,
    uint256[] memory tokenId,
    uint256 price,
    uint256[] memory orderNumber,
    uint256 royalityPercent,
    string memory tokenType
  ) public {
    require(royalityPercent <6000,"ROYALITY_EXCEEDS");
    IERC721 ierc721 = IERC721(nftAddress);
    require(tokens[tokenType] != address(0), "INVALID_TOKEN");
    require(tokenId.length == orderNumber.length,"LENGTH_MISMATCH");
    for (uint256 i = 0; i < tokenId.length; i++) {
      require(ierc721.ownerOf(tokenId[i])== msg.sender, "SHOULD_BE_OWNER");
      require(!isOrderExist[orderNumber[i]] ,"ORDER_EXIST");
      require(ierc721.isApprovedForAll(msg.sender, address(this)) == true || ierc721.getApproved(tokenId[i]) == address(this), "NOT_APPROVED");
      require(ierc721.ownerOf(tokenId[i]) == msg.sender, "BE_OWNER");
      require(!isTokenListed[tokenId[i]] ,"TOKEN_EXIST");
      pendingOrders[orderNumber[i]].tokenId = tokenId[i];
      pendingOrders[orderNumber[i]].nftAddress = nftAddress;
      pendingOrders[orderNumber[i]].buyer = address(this);
      pendingOrders[orderNumber[i]].seller = msg.sender;
      pendingOrders[orderNumber[i]].price = price;
      pendingOrders[orderNumber[i]].royalityPercent = royalityPercent;
      isTokenListed[tokenId[i]] = true;
      pendingOrders[orderNumber[i]].tokenAddress = tokens[tokenType];
      pendingOrders[orderNumber[i]].isSingle = true;
      isOrderExist[orderNumber[i]] = true;
      emit AddOrder(orderNumber[i], tokenId[i], nftAddress, msg.sender, price, 0, ierc721.creator(tokenId[i]), royalityPercent);
    }
  }

  function addNftBundle(
    address nftAddress,
    uint256[] calldata tokenId,
    uint256 price,
    uint256 orderNumber,
    uint256 royalityPercent,
    string calldata tokenType
  ) external {
    require(royalityPercent <6000,"ROYALITY_EXCEEDS");
    require(tokens[tokenType] != address(0), "INVALID_TOKEN");
    require(!isOrderExist[orderNumber] ,"ORDER_EXIST");
    IERC721 ierc721 = IERC721(nftAddress);
    for (uint256 i = 0; i < tokenId.length; i++) {
      require(ierc721.isApprovedForAll(msg.sender, address(this)) == true || ierc721.getApproved(tokenId[i]) == address(this), "NOT_APPROVED");
      require(!isTokenListed[tokenId[i]], "ALREADY_LISTED");
      require(ierc721.ownerOf(tokenId[i]) == msg.sender, "BE_OWNER");
      pendingOrders[orderNumber].bundleIds.push(tokenId[i]); 
      isTokenListed[tokenId[i]] = true;
    }
    pendingOrders[orderNumber].nftAddress = nftAddress;
    pendingOrders[orderNumber].buyer = address(this);
    pendingOrders[orderNumber].seller = msg.sender;
    pendingOrders[orderNumber].price = price;
    pendingOrders[orderNumber].royalityPercent = royalityPercent;
    pendingOrders[orderNumber].tokenAddress = tokens[tokenType];
    pendingOrders[orderNumber].isSingle = false;
    isOrderExist[orderNumber] = true;
    for (uint256 i = 0; i < pendingOrders[orderNumber].bundleIds.length; i++) {
      if (pendingOrders[orderNumber].sameCreator[ierc721.creator(pendingOrders[orderNumber].bundleIds[i])] > 0) {
        pendingOrders[orderNumber].sameCreator[ierc721.creator(pendingOrders[orderNumber].bundleIds[i])] += 1;
      } else {
        pendingOrders[orderNumber].sameCreator[ierc721.creator(pendingOrders[orderNumber].bundleIds[i])] = 1;
        pendingOrders[orderNumber].creators.push(ierc721.creator(pendingOrders[orderNumber].bundleIds[i]));
      }
    }
    emit AddBundle(orderNumber, nftAddress, msg.sender, price, royalityPercent,tokenId, "bundle");
  }
  function discountOffer(uint256[] calldata _orderNumbers, uint256 _percentage) external {
    require(_percentage > 0 && _percentage < 10000, "INVALID_PERCENTAGE");
    for (uint256 i = 0; i < _orderNumbers.length; i++) {
      Order storage pendOrd = pendingOrders[_orderNumbers[i]];
      require(msg.sender == pendOrd.seller,"NOT_SELLER");
      require(isTokenListed[pendOrd.tokenId], "NOT_EXIST");
      pendOrd.price = pendOrd.price - ((pendOrd.price.mul(_percentage)).div(10000) );
      emit DiscountOffer(msg.sender, _percentage, _orderNumbers[i]);
    }
  }

  function makeOffer(
    address nftAddress,
    uint256 tokenId,
    uint256 price,
    uint256 orderNumber,
    uint256 royalityPercent,
    string calldata tokenType
  ) external payable {
    require(!isTokenListed[tokenId], "ALREADY_LISTED");
    require(tokens[tokenType] != address(0), "INVALID_PAYMENT");
    require(IERC721(nftAddress).ownerOf(tokenId) != address(0), "NOT_MINTED");
    require(!isOrderExist[orderNumber] ,"ORDER_EXIST");
    if (keccak256(bytes(tokenType)) == keccak256(bytes("eth"))) {
      require(msg.value > 0, "IVALID_OFFER");
      pendingOrders[orderNumber].price = msg.value;
    } else {
      require(price > 0, "IVALID_OFFER");
      IBEP20(tokens[tokenType]).transferFrom(msg.sender, address(this), price);
      pendingOrders[orderNumber].price = price;
    }
    pendingOrders[orderNumber].tokenId = tokenId;
    pendingOrders[orderNumber].nftAddress = nftAddress;
    pendingOrders[orderNumber].buyer = msg.sender;
    pendingOrders[orderNumber].seller = payable(IERC721(nftAddress).ownerOf(tokenId));
    pendingOrders[orderNumber].royalityPercent = royalityPercent;
    isTokenListed[tokenId] = false;
    pendingOrders[orderNumber].tokenAddress = tokens[tokenType];
    pendingOrders[orderNumber].isSingle = true;
    pendingOrders[orderNumber].isOffer = true;
    isOrderExist[orderNumber] = true;
    emit MakeOffer(nftAddress, tokenId, price, orderNumber, royalityPercent, tokenType, msg.sender);
  }

  function acceptOffer(uint256 orderNumber) external {
    Order storage order = pendingOrders[orderNumber];
    IERC721 ierc721 = IERC721(order.nftAddress);
    require(ierc721.ownerOf(order.tokenId) == msg.sender, "NOT_OWNER");
    require((ierc721.getApproved(order.tokenId) == address(this)) || (ierc721.isApprovedForAll(order.seller, address(this))), "NOT_APPROVED");
    ierc721.safeTransferFrom(msg.sender, order.buyer, order.tokenId);
    isTokenListed[order.tokenId] = false;
    address tokenAddress = order.tokenAddress;
    uint256 _fee = _computeFee(order.price);
    uint256 _royality = computeRoyality(order.price, order.royalityPercent);
    address creatorAdd = ierc721.creator(order.tokenId);
    if (keccak256(bytes(tokenOf[tokenAddress])) == keccak256(bytes("eth"))) {
      msg.sender.transfer(order.price.sub(_fee.add(_royality)));
      benefactor.transfer(_fee);
      payable(ierc721.creator(order.tokenId)).transfer(_royality);
    } else {
      IBEP20(order.tokenAddress).transfer(order.buyer, order.price.sub(_fee.add(_royality)));
      IBEP20(order.tokenAddress).transfer(benefactor, _fee);
      IBEP20(order.tokenAddress).transfer(creatorAdd, _royality);
    }
    order.fee = _fee;
    completedOrders[orderNumber] = order;
    isOrderExist[orderNumber] = false;
    delete pendingOrders[orderNumber];
    emit AcceptOffer(
      orderNumber,
      order.tokenId,
      order.nftAddress,
      msg.sender,
      order.buyer,
      order.price,
      order.fee,
      creatorAdd,
      _royality,
      tokenOf[tokenAddress]
    );
  }

  function orderDetail(uint256 orderNumber) public view returns (uint256[] memory allbundlenfts, address[] memory creatorsNfts) {
    Order memory order = pendingOrders[orderNumber];
    return (order.bundleIds, order.creators);
  }

  function cancelOffer(uint256 orderNumber) external {
    Order memory order = pendingOrders[orderNumber];
    require(order.buyer == msg.sender, "NOT_BUYER");
    cancelledOrders[orderNumber] = order;
    order.isOffer = false;
    isOrderExist[orderNumber] = false;
    delete pendingOrders[orderNumber];
    emit CancelOffer(orderNumber, msg.sender);
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