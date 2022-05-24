// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "contracts/libraries/UniLib.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "contracts/interfaces/IMarketPlace.sol";
contract Marketplace is IMarketPlace{
  using SafeMath for uint256;
  //Buy array of NFTs only for normal buy
  address private constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  address private constant _WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
  address private factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
  uint256 private _royalty_fee = 5;

  mapping(address=>mapping(uint256=>ItemForSale)) public itemsForSale;
  mapping(address=>mapping(uint256=>ItemForSaleAuction)) public itemsForSaleAuction;
  mapping(address=>mapping(uint256 => bool)) public firstTimeSell;
  mapping(address=>mapping(uint256 => bool)) public activeItems; 
  event itemAddedForSale(uint256 tokenId, uint256 price, address owner, address nftContract);
  event itemSold( uint256 tokenId, uint256 price, address buyer, address nftContract);
  event itemSoldArray( uint256[] tokenId, uint256[] price, address buyer, address nftContract);
  event itemAddedForAuction(uint256 tokenId, uint256 price, uint256 time, address owner, address nftContract);
  event newBid(uint256 tokenId, uint256 bid, address bidder, address nftContract);

  modifier OnlyItemOwner(uint256 tokenId, address nftContract){
    require(IERC721(nftContract).ownerOf(tokenId) == msg.sender, "MarketPlace: Sender does not own the item");
    _;
  }

  modifier HasTransferApproval(uint256 tokenId, address nftContract){
    require(IERC721(nftContract).isApprovedForAll(IERC721(nftContract).ownerOf(tokenId), address(this))
    , "MarketPlace: Market is not approved");
    _;
  }

  modifier ItemExists(uint256 tokenId, address nftContract){
    require(activeItems[nftContract][tokenId], "MarketPlace:Item is not active");
    _;
  }
  modifier IsForSale(uint256 tokenId, address nftContract){
    require(!itemsForSale[nftContract][tokenId].isSold, "MarketPlace:Item is already sold");
    _;
  }
  modifier IsAvailable(uint256 tokenId, address nftContract){
    require(itemsForSaleAuction[nftContract][tokenId].time >= block.timestamp, 
            "MarketPlace:Item bidding has ended");
    _;
  }
  modifier notAuctionable(uint256 tokenId, address nftContract){
    require(itemsForSaleAuction[nftContract][tokenId].tokenId == 0 
            && itemsForSale[nftContract][tokenId].tokenId != 0 
            ,"MarketPlace:Not Auctionable as item has not been transferred");
    _;
  }
  modifier HasTransferApprovalArray(uint256[] memory tokenId, address nftContract){
    for(uint i = 0;i<tokenId.length;i++){
    require(IERC721(nftContract).isApprovedForAll(IERC721(nftContract).ownerOf(tokenId[i]), address(this))
    , "MarketPlace: Market is not approved");
    }
    _;
  }

  modifier ItemExistsArray(uint256[] memory tokenId, address nftContract){
    for(uint i = 0;i<tokenId.length;i++){
      require(activeItems[nftContract][tokenId[i]], "MarketPlace:Item is not active");
    }
    _;
  }
  modifier IsForSaleArray(uint256[] memory tokenId, address nftContract){
    for(uint i = 0;i<tokenId.length;i++){
    require(!itemsForSale[nftContract][tokenId[i]].isSold, "MarketPlace:Item is already sold");
    }
    _;
  }
  function putItemForSale(uint256 tokenId, uint256 price, address nftContract) 
    OnlyItemOwner(tokenId, nftContract) 
    HasTransferApproval(tokenId, nftContract) 
    external 
    returns (uint256){
      require(!activeItems[nftContract][tokenId], "MarketPlace:Item is already up for sale");
      if(firstTimeSell[nftContract][tokenId] == false){
        itemsForSale[nftContract][tokenId]=ItemForSale({
          nftContract:nftContract,
          tokenId: tokenId,
          seller: payable(msg.sender),
          price: price,
          isSold: false
      });}
      else{
        price = price + price.mul(_royalty_fee).div(100);
        itemsForSale[nftContract][tokenId]=ItemForSale({
          nftContract:nftContract,
          tokenId: tokenId,
          seller: payable(msg.sender),
          price: price,
          isSold: false
      });
      }
      activeItems[nftContract][tokenId] = true;

      emit itemAddedForSale(tokenId, price, msg.sender, nftContract);
      return tokenId;
  }

  function buyItem(uint256 tokenId, address nftContract) 
    ItemExists(tokenId, nftContract)
    IsForSale(tokenId, nftContract)
    HasTransferApproval(tokenId, nftContract)
    payable 
    external {
      require(msg.value >= itemsForSale[nftContract][tokenId].price, "MarketPlace:Not enough funds sent");
      require(msg.sender != itemsForSale[nftContract][tokenId].seller, "MarketPlace:Seller can't be equal to buyer");
      itemsForSale[nftContract][tokenId].isSold = true;
      activeItems[nftContract][tokenId] = false;
      IERC721(nftContract).safeTransferFrom(itemsForSale[nftContract][tokenId].seller, msg.sender, tokenId);
      itemsForSale[nftContract][tokenId].seller.transfer(msg.value);
      firstTimeSell[nftContract][tokenId] = true;
      emit itemSold(tokenId, itemsForSale[nftContract][tokenId].price, msg.sender, nftContract);
    }
  function buyItemArray(uint256[] memory tokenIds, address nftContract) 
    ItemExistsArray(tokenIds, nftContract)
    IsForSaleArray(tokenIds, nftContract)
    HasTransferApprovalArray(tokenIds, nftContract)
    payable 
    external {
      uint256 tempPrice = msg.value;
      uint256[] memory priceArray = new uint256[](tokenIds.length); 
      for(uint256 i = 0; i<tokenIds.length; i++){
        require(tempPrice >= itemsForSale[nftContract][tokenIds[i]].price, "MarketPlace:Not enough funds sent");
        require(msg.sender != itemsForSale[nftContract][tokenIds[i]].seller, "MarketPlace:Seller can't be equal to buyer");
        itemsForSale[nftContract][tokenIds[i]].isSold = true;
        activeItems[nftContract][tokenIds[i]] = false;
        IERC721(nftContract).safeTransferFrom(itemsForSale[nftContract][tokenIds[i]].seller, msg.sender, tokenIds[i]);
        itemsForSale[nftContract][tokenIds[i]].seller.transfer(itemsForSale[nftContract][tokenIds[i]].price);
        firstTimeSell[nftContract][tokenIds[i]] = true;
        tempPrice -= itemsForSale[nftContract][tokenIds[i]].price;
        priceArray[i] = itemsForSale[nftContract][tokenIds[i]].price;
      }
      emit itemSoldArray(tokenIds, priceArray, msg.sender, nftContract);

    }
  function buyItemERC20(uint256 tokenId, uint256 price, address tokenAddress, address nftContract) 
    ItemExists(tokenId, nftContract)
    IsForSale(tokenId, nftContract)
    HasTransferApproval(tokenId, nftContract)
    payable 
    external {
      require(msg.sender != itemsForSale[nftContract][tokenId].seller);
      address[] memory path = new address[](2);
      path[0] = tokenAddress;
      path[1] = _WETH;
      uint[] memory amount = UniswapV2Library.getAmountsOut(factory, price, path);
      require(amount[1] >= itemsForSale[nftContract][tokenId].price, "MarketPlace:Amount entered is lower than the price");
      IERC20(tokenAddress).transferFrom(msg.sender, address(this), price);
      IERC20(tokenAddress).approve(UNISWAP_ROUTER_ADDRESS,price);
      IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS).swapExactTokensForETH(
            itemsForSale[nftContract][tokenId].price,
            amount[1],
            path,
            msg.sender,
            block.timestamp + 1 hours
      );
      itemsForSale[nftContract][tokenId].isSold = true;
      activeItems[nftContract][tokenId] = false;
      firstTimeSell[nftContract][tokenId] = true;
      IERC721(nftContract).safeTransferFrom(itemsForSale[nftContract][tokenId].seller, msg.sender, tokenId);
      IERC20(tokenAddress).transfer(itemsForSale[nftContract][tokenId].seller, price);

      emit itemSold(tokenId, price, msg.sender, nftContract);
    }
  function putItemForSaleAuction(uint256 tokenId, uint256 price, uint256 time, address nftContract) 
    OnlyItemOwner(tokenId, nftContract) 
    HasTransferApproval(tokenId, nftContract) 
    external 
    returns(uint256){
      if(activeItems[nftContract][tokenId] == true){
        require(itemsForSaleAuction[nftContract][tokenId].time <= block.timestamp && 
            (IERC721(nftContract).ownerOf(tokenId)== itemsForSaleAuction[nftContract][tokenId].bidder ||
             itemsForSaleAuction[nftContract][tokenId].bidder == address(0)),
            "MarketPlace:Not Auctionable as item has not been transferred or its deadline has not ended");
      }
      if(firstTimeSell[nftContract][tokenId] == false){
        itemsForSaleAuction[nftContract][tokenId]=ItemForSaleAuction({
        nftContract:nftContract,
        tokenId: tokenId,
        seller: payable(msg.sender),
        bidder:payable(address(0)),
        currentBid: price,
        time:time+block.timestamp,
        inAuction:true
      });
      }
      else{
        price = price + price.mul(_royalty_fee).div(100);
        itemsForSaleAuction[nftContract][tokenId]=ItemForSaleAuction({
        nftContract:nftContract,
        tokenId: tokenId,
        seller: payable(msg.sender),
        bidder:payable(address(0)),
        currentBid: price,
        time:time+block.timestamp,
        inAuction:true
      });
      }
      activeItems[nftContract][tokenId] = true;
      emit itemAddedForAuction(tokenId, price, time, msg.sender, nftContract);
      return tokenId;
  }
  function bid(uint256 tokenId, address nftContract) 
    ItemExists(tokenId, nftContract)
    HasTransferApproval(tokenId, nftContract)
    IsAvailable(tokenId, nftContract)
    external 
    payable
    {
        require(msg.value >= itemsForSaleAuction[nftContract][tokenId].currentBid, "MarketPlace:Not enough funds sent");
        require(msg.sender != itemsForSaleAuction[nftContract][tokenId].seller, "MarketPlace: Owner can't bid");
        itemsForSaleAuction[nftContract][tokenId].bidder = payable(msg.sender);
        itemsForSaleAuction[nftContract][tokenId].currentBid = msg.value;
        emit newBid(tokenId, itemsForSaleAuction[nftContract][tokenId].currentBid,msg.sender,  nftContract);
    }
  function bidERC20(uint256 tokenId, uint256 price, address tokenAddress, address nftContract) 
    ItemExists(tokenId, nftContract)
    IsAvailable(tokenId, nftContract)
    HasTransferApproval(tokenId, nftContract)
    external 
    payable
    {
      require(msg.sender != itemsForSaleAuction[nftContract][tokenId].seller);
      address[] memory path = new address[](2);
      path[0] = tokenAddress;
      path[1] = _WETH;
      uint[] memory amount = UniswapV2Library.getAmountsOut(factory, price, path);
      require(itemsForSaleAuction[nftContract][tokenId].currentBid < amount[1], "MarketPlace:Amount entered is lower than the price");
      IERC20(tokenAddress).transferFrom(msg.sender, address(this), price);
      IERC20(tokenAddress).approve(UNISWAP_ROUTER_ADDRESS,price);
      IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS).swapExactTokensForETH(
            itemsForSale[nftContract][tokenId].price,
            amount[1],
            path,
            msg.sender,
            block.timestamp + 1 hours
      );      
        require(msg.value >= itemsForSaleAuction[nftContract][tokenId].currentBid, "MarketPlace: Not enough funds sent");
        itemsForSaleAuction[nftContract][tokenId].bidder = payable(msg.sender);
        itemsForSaleAuction[nftContract][tokenId].currentBid = price;
        emit newBid(tokenId, itemsForSaleAuction[nftContract][tokenId].currentBid, msg.sender, nftContract);
  }
  function NFTWithdrawal(uint256 tokenId, address nftContract) ItemExists(tokenId, nftContract) external  {
    require(itemsForSaleAuction[nftContract][tokenId].time <= block.timestamp, "MarketPlace: Item is already sold");
    if (itemsForSaleAuction[nftContract][tokenId].bidder != address(0) && itemsForSaleAuction[nftContract][tokenId].inAuction == true){
    IERC721(nftContract).safeTransferFrom(itemsForSaleAuction[nftContract][tokenId].seller, itemsForSaleAuction[nftContract][tokenId].bidder, tokenId);
    itemsForSale[nftContract][tokenId].seller.transfer(itemsForSaleAuction[nftContract][tokenId].currentBid);
    firstTimeSell[nftContract][tokenId] = true;
    activeItems[nftContract][tokenId] = false;
    itemsForSaleAuction[nftContract][tokenId].inAuction = false;
    emit itemSold(tokenId, itemsForSaleAuction[nftContract][tokenId].currentBid
                  , itemsForSaleAuction[nftContract][tokenId].bidder, nftContract);
    }
    else if(itemsForSaleAuction[nftContract][tokenId].tokenId!=0 
            && itemsForSaleAuction[nftContract][tokenId].inAuction == true){
        activeItems[nftContract][tokenId] = false;
        itemsForSaleAuction[nftContract][tokenId].inAuction = false;
  }  
}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
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

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';

import "./SafeMath.sol";

library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            )))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     event RevokeApproval(address indexed owner, address indexed operator, uint256 tokenId);
     
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
    function revokeApproval(uint256 tokenId) external;
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

pragma solidity >=0.8.0;
interface IMarketPlace{
    struct ItemForSale {
    address nftContract;
    uint256 tokenId;
    address payable seller;
    uint256 price;
    bool isSold;
  }

  struct ItemForSaleAuction {
    address nftContract;
    uint256 tokenId;
    address payable seller;
    address payable bidder;
    uint256 currentBid;
    uint256 time;
    bool inAuction;
  }
 // tokenId => ativo?
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.4;

// A library for performing overflow-safe math, courtesy of DappHub: https://github.com/dapphub/ds-math/blob/d0ef6d6a5f/src/math.sol
// Modified to include only the essentials
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
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