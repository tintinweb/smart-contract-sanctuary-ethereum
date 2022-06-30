// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./Authorization.sol"; 
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IUniswapV2Router01.sol";
import "./IERC20Burnable.sol";
import "./IERC20Mintable.sol";
import "./IERC20Decimable.sol";

contract ACDMPlatform is Authorization {

//requer mint and burn for ACDMToken
//requer burn for XXXToken

    enum PlatformState { NOT_STARTED, SALE, TRADE }

    struct TradeSell {
        uint256 amount;
        uint256 price;
    }

    PlatformState public state;
    uint64 public endTimeState;
    address public ACDMTokenAddress;
    address public XXXTokenAddress;
    address public daoAddress;
    address public ownerAddress;

    uint256 public ACDMTokenPrice;
    uint256 public ACDMPlatformFeeAmount; // in ether
    uint16 public numberPlatformCircle = 0;
    uint16 public percentageFirstReferrerSale = 500; // 5%
    uint16 public percentageSecondReferrerSale = 300; // 3%
    uint16 public percentageReferrerTrading = 250; // 2.5%

    uint256 public saleTokenAmount = 100000000000; //100 000 ACDMToken

    uint256 public lastTradingVolume = 0;

    uint64 public constant roundTimeSize = 3 days;
    uint8 public immutable ACDMTokenDecimal;
    uint256 public constant minimumPurchaseSaleRound = 10000; // 0.01 ACDMToken
    uint16 public constant hundredPercent = 10000;

    address internal constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router01 uniswapRouter;

    mapping (address => TradeSell) _tradeSell;

    event PurchasedOnSale(address buyer, uint256 amount, uint256 price, uint16 numberPlatformCircle);
    event InitTradeSell(address seller, uint256 amount, uint256 price);
    event PurchasedTradeSell(address seller, address purchaser, uint256 amount, uint256 price);
    event StopTradeSell(address seller, uint256 amount, uint256 price);

    constructor(address XXXTokenAddress_, address ACDMTokenAddress_, address daoAddress_) {
        uniswapRouter = IUniswapV2Router01(UNISWAP_ROUTER_ADDRESS);
        XXXTokenAddress = XXXTokenAddress_;
        ACDMTokenAddress = ACDMTokenAddress_;
        daoAddress = daoAddress_;
        ownerAddress = msg.sender;

        ACDMTokenDecimal = IERC20Decimable(ACDMTokenAddress).decimals();

        ACDMTokenPrice = (1 ether) / saleTokenAmount;
    }

    modifier onlyDAO() {
        require(daoAddress == msg.sender, "ACDMPlatform: need dao role");
        _;
    }

    modifier onlySaleState() {
        require(
            state == PlatformState.SALE &&
            (block.timestamp < endTimeState || saleTokenAmount > 0),
            "ACDMPlatform: sale is over"
        ); 
        _;
    }

    modifier onlyTradeState() {
        require(state == PlatformState.TRADE && (block.timestamp < endTimeState), "ACDMPlatform: trade is over" ); 
        _;
    }

    function getTradeSale(address account) 
        external 
        view 
        returns (
            uint256 amount,
            uint256 price
        ) 
    {
        return (_tradeSell[account].amount, _tradeSell[account].price);
    }

    function sendFeeToOwner() external onlyDAO {
        uint256 feeAmount = ACDMPlatformFeeAmount;
        ACDMPlatformFeeAmount = 0;

        (bool sent, bytes memory data) = payable(ownerAddress).call{value: feeAmount}("");
        //require(sent, "Failed to send Ether");
    }

    function swapFeeAndBurn() external onlyDAO {
        uint deadline = block.timestamp + 15; 
        uint256 feeAmount = ACDMPlatformFeeAmount;
        ACDMPlatformFeeAmount = 0;

        address[] memory pathWETHXXX = new address[](2);
        pathWETHXXX[0] = uniswapRouter.WETH();
        pathWETHXXX[1] = XXXTokenAddress;

        uint256 amountsOut = uniswapRouter.getAmountsOut(feeAmount, pathWETHXXX)[1];

        uniswapRouter.swapETHForExactTokens{ value: feeAmount }
        (
            amountsOut,
            pathWETHXXX,
            address(this),
            deadline
        );
        
        uint256 balanceOfXXXToken = IERC20(pathWETHXXX[1]).balanceOf(address(this));

        IERC20Burnable(pathWETHXXX[1]).burn(balanceOfXXXToken);

    }

    function setPercentFeeForFirstLevelSale(uint16 newPercent) external onlyDAO {
        require(newPercent + percentageSecondReferrerSale <= hundredPercent, "ACDMPlatform:too high percentage");

        percentageFirstReferrerSale = newPercent;
    }

    function setPercentFeeForSecondLevelSale(uint16 newPercent) external onlyDAO {
        require(newPercent + percentageFirstReferrerSale <= hundredPercent, "ACDMPlatform:too high percentage");

        percentageSecondReferrerSale = newPercent;
    }

    function setPercentFeeForTrading(uint16 newPercent) external onlyDAO {
        require(newPercent * 2 <= hundredPercent, "ACDMPlatform:too high percentage");

        percentageReferrerTrading = newPercent;
    }

    receive() payable external {}

    //if you send more eth than necessary, they will remain on the platform
    function buyTokensOnSale() payable external onlyRegistered onlySaleState {
        address sender = msg.sender;

        uint256 value = msg.value;

        uint256 resoultACDMToken = min(value / ACDMTokenPrice, saleTokenAmount);

        require(resoultACDMToken >= minimumPurchaseSaleRound, "ACDMPlatform: small purchase");

        saleTokenAmount = saleTokenAmount - resoultACDMToken;

        IERC20(ACDMTokenAddress).transfer(sender, resoultACDMToken);

        sendFeeToReferrers(value, sender, percentageFirstReferrerSale, percentageSecondReferrerSale);

        emit PurchasedOnSale(sender, resoultACDMToken, ACDMTokenPrice, numberPlatformCircle);
    }

    function buyTradeSell(address seller) payable external onlyRegistered onlyTradeState {
        address sender = msg.sender;

        uint256 tradeSaleAmount = _tradeSell[seller].amount;
        uint256 tradeSalePrice = _tradeSell[seller].price;

        require(tradeSaleAmount > 0, "ACDMPlatform:no active sale");

        uint256 value = msg.value;

        uint256 resoultACDMToken = min(value / tradeSalePrice, tradeSaleAmount);

        _tradeSell[seller].amount -= resoultACDMToken;

        IERC20(ACDMTokenAddress).transfer(sender, resoultACDMToken);

        sendFeeToReferrers(value, sender, percentageReferrerTrading, percentageReferrerTrading);

        uint256 valueForSaller = value * (hundredPercent - percentageReferrerTrading - percentageReferrerTrading) / hundredPercent;

        (bool sent, bytes memory data) = payable(seller).call{value: valueForSaller }("");
        //require(sent, "Failed to send Ether");


        lastTradingVolume += value;
        emit PurchasedTradeSell(seller, sender, resoultACDMToken, tradeSalePrice);
    }

    //before this user must approve tokens for transfer 
    function initSell(uint256 tokenAmount, uint256 price) external onlyRegistered onlyTradeState {
        address sender = msg.sender;

        require(_tradeSell[sender].amount == 0, "ACDMPlatform: already have sale");
        require(tokenAmount >= minimumPurchaseSaleRound, "ACDMPlatform: less than minimum");

        IERC20(ACDMTokenAddress).transferFrom(sender, address(this), tokenAmount);

        _tradeSell[sender].amount = tokenAmount;
        _tradeSell[sender].price = price;

        emit InitTradeSell(sender, tokenAmount, price);
    }

    function stopSell() external onlyRegistered {
        address sender = msg.sender;
        require(_tradeSell[sender].amount > 0, "ACDMPlatform: not have sale");

        uint256 tokenAmount = _tradeSell[sender].amount;
        uint256 lastPrice = _tradeSell[sender].price;
        _tradeSell[sender].amount = 0;
        _tradeSell[sender].price = 0;

        IERC20(ACDMTokenAddress).transfer(sender, tokenAmount);

        emit StopTradeSell(sender, tokenAmount, lastPrice);
    }

    function changeState() external {
        if(state == PlatformState.SALE) {
            require(block.timestamp >= endTimeState || saleTokenAmount == 0, "ACDMPlatform: sale is not over"); 

            uint256 ADCMTokenBalance = IERC20(ACDMTokenAddress).balanceOf(address(this));
            if(ADCMTokenBalance > 0) {
                IERC20Burnable(ACDMTokenAddress).burn(ADCMTokenBalance);
            }

            lastTradingVolume = 0;
            state = PlatformState.TRADE;
            endTimeState = uint64(block.timestamp + roundTimeSize);
        } else if(state == PlatformState.TRADE) {
            require(block.timestamp >= endTimeState, "ACDMPlatform:trading is not over");

            increasePrice();
            initSaleRound();
            if(saleTokenAmount >= minimumPurchaseSaleRound) {
                state = PlatformState.SALE;
            } 
            numberPlatformCircle++;
            endTimeState = uint64(block.timestamp + roundTimeSize);
        } else {
            numberPlatformCircle++;

            IERC20Mintable(ACDMTokenAddress).mint(address(this), saleTokenAmount);

            endTimeState = uint64(block.timestamp + roundTimeSize);
            state = PlatformState.SALE;
        }
    }

    function increasePrice() internal {
        ACDMTokenPrice = ACDMTokenPrice * 103 / 100  + (0.000004 ether);
    }

    function initSaleRound() internal {
        saleTokenAmount = uint128(uint256(lastTradingVolume) / ACDMTokenPrice);
        IERC20Mintable(ACDMTokenAddress).mint(address(this), saleTokenAmount);
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a <= b ? a : b;
    }

    function sendFeeToReferrers
    (
        uint256 value,
        address sender,
        uint16 firstPercentReferrer,
        uint16 secondPercentReferrer
    ) internal {
        address contractAddress = address(this);

        address firstReferrer = _referral[sender];
        if(firstReferrer == contractAddress) {
            ACDMPlatformFeeAmount = 
            ACDMPlatformFeeAmount +
            (value*(firstPercentReferrer + secondPercentReferrer) / hundredPercent);
            return;
        }

        (bool sent, bytes memory data) = payable(firstReferrer).call{value: (value * firstPercentReferrer / hundredPercent) }("");
        //require(sent, "Failed to send Ether");
        address secondReferrer = _referral[firstReferrer];

        if(secondReferrer == contractAddress) {
            ACDMPlatformFeeAmount = 
            ACDMPlatformFeeAmount +
            (value* secondPercentReferrer / hundredPercent);
            return;
        }

        (bool secondSent, bytes memory secondData) = payable(secondReferrer).call{value: (value * secondPercentReferrer / hundredPercent) }("");
        //require(secondSent, "Failed to send Ether"); 
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Authorization {

    //referral => referrer
    mapping (address => address) _referral;

    modifier onlyRegistered() {
        require(_referral[msg.sender] != address(0), "Authorization: need registration");
        _;
    }

    modifier onlyRegisteredReferrer(address accountAddress) {
        require(isRegistered(accountAddress), "Authorization:referrer not known");
        _;
    }

    function isRegistered(address accountAddress) public view returns(bool) {
        return _referral[accountAddress] != address(0);
    }

    function getReferrer(address referralAddress) external view returns(address referrer){
        return _referral[referralAddress];
    }

    function signUpWithoutReferrer() external {
        address sender = msg.sender;
        _register(sender, address(0));
    }

    function signUp(address referrer) external onlyRegisteredReferrer(referrer) {
        address sender = msg.sender;
        _register(sender, referrer);
    }

    function setReferrer(address newReferrer) external onlyRegistered onlyRegisteredReferrer(newReferrer) {
        address sender = msg.sender;
        address referre = _referral[sender];
        require(referre == address(this), "Authorization: has referrer");

        _referral[sender] = newReferrer;
    }

    function _register(address sender, address referrer) internal {
        require(_referral[sender] == address(0), "Authorization:already authorized");

        if(referrer == address(0)) {
            _referral[sender] = address(this);
        } else {
            _referral[sender] = referrer;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

pragma solidity >=0.6.2;

//SPDX-License-Identifier: Unlicense

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
pragma solidity >=0.7.0 <0.9.0;

interface IERC20Burnable {
    function burn(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IERC20Mintable {
    function mint(address to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IERC20Decimable {
    function decimals() external view returns (uint8);
}