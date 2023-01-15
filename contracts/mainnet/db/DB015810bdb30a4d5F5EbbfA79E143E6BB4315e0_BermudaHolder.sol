// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./UniswapV2Interfaces.sol";
import "./IBermuda.sol";
import "./IWETH.sol";
import "./Cycled.sol";

contract BermudaHolder is Cycled, ReentrancyGuard
{
    //Immutable
    IUniswapV2Router02 public immutable uniswapV2Router;

    //Public variables
    mapping(address => bool) public tokenApproved;

    //These two are never subtracted, only added. A different interface will keep track of subtracted amounts.
    //[tokenAddress][userAddress]
    mapping(address => mapping (address => uint256)) public balanceIn;
    //[userAddress]
    //mapping(address => uint256) public gasBalanceIn; //Prepaying gas not supported anymore.

    //[tokenAddress], should only be used for recoverLostTokens.
    mapping(address => uint256) public totalBalance;

    mapping(address => bool) public depositBlacklist;
    mapping(address => bool) public sendBlacklist;

    uint256 public requiredBMDAForDeposit;
    IWETH public WETH;
    IBermuda public BMDA;
    //No longer needed as we get this from the BMDA contract
    //address feeWallet;

    //Events
    event Deposit(address indexed sender, address indexed token, uint256 amount);

    //Constructor
    constructor(IBermuda bmda, uint256 initialRequiredForDeposit)
    {
        BMDA = bmda;
        uniswapV2Router = bmda.uniswapV2Router();
        WETH = IWETH(uniswapV2Router.WETH());
        requiredBMDAForDeposit = initialRequiredForDeposit; //For beta testers.
        //feeWallet = wallet;
    }

    //Internal Functions
    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'BermudaHolder: EXPIRED');
        _;
    }
    function buybackAndBurnBMDA(IERC20 token, uint256 amount) internal
    {
        if(amount == 0) return;
        //Generate path
        address[] memory path;
        uint256 length;
        if(address(token) == address(WETH))
        {
            length = 2;
            path = new address[](length);
            path[0] = address(token);
            path[1] = address(BMDA);
        }
        else
        {
            length = 3;
            path = new address[](length);
            path[0] = address(token);
            path[1] = address(WETH);
            path[2] = address(BMDA);
        }
        uint256 bmdaBefore = BMDA.balanceOf(address(this));
        token.approve(address(uniswapV2Router), amount);
        //Swap, covering even transfer fee tokens (just in case).
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            0, //Full slippage
            path,
            address(this),
            block.timestamp
        );

        //Burn whatever we've gotten.
        uint256 burnAmount = BMDA.balanceOf(address(this)) - bmdaBefore;
        if(burnAmount > 0) BMDA.burn(burnAmount);
    }

    function swapToETH(IERC20 token, address payable to, uint256 amount) internal
    {
        if(amount == 0) return;
        if(address(token) == address(0))
        {
            to.transfer(amount);
            return;
        }
        if(address(token) == address(WETH))
        {
            WETH.withdraw(amount);
            to.transfer(amount);
            return;
        }
        //Generate path
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = address(WETH);
        token.approve(address(uniswapV2Router), amount);
        //Swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            1, //Almost full slippage. Error out if unswappable (aka 0).
            path,
            to,
            block.timestamp
        );
    }

    //0 == ETH
    function swapTo(IERC20 token, address payable to, uint256 amount, IERC20 dest, uint256 amountMin, uint256 timestamp) internal ensure(timestamp)
    {
        if(amount == 0) return;
        if(address(token) == address(dest))
        {
            if(address(token) == address(0)) to.transfer(amount);
            else token.transfer(to, amount);
            return;
        }
        if(address(dest) == address(0) && address(token) == address(WETH))
        {
            WETH.withdraw(amount);
            to.transfer(amount);
            return;
        }
        else if(address(dest) == address(WETH) && address(token) == address(0))
        {
            WETH.deposit{value: amount}();
            WETH.transfer(to, amount);
            return;
        }
        //Generate path
        address[] memory path;
        uint256 length;
        if(address(token) == address(WETH) || address(dest) == address(WETH) || address(token) == address(0) || address(dest) == address(0))
        {
            length = 2;
            path = new address[](length);
            path[0] = address(token) == address(0) ? address(WETH) : address(token);
            path[1] = address(dest) == address(0) ? address(WETH) : address(dest);
        }
        else
        {
            length = 3;
            path = new address[](length);
            path[0] = address(token) == address(0) ? address(WETH) : address(token);
            path[1] = address(WETH);
            path[2] = address(dest) == address(0) ? address(WETH) : address(dest);
        }
        //Swap ETH
        if(address(dest) == address(0))
        {
            token.approve(address(uniswapV2Router), amount);
            uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                amount,
                amountMin,
                path,
                to,
                timestamp
            );
            return;
        }
        //Swap to ETH
        if(address(token) == address(0))
        {
            uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
                amountMin,
                path,
                to,
                timestamp
            );
            return;
        }
        //Swap two tokens
        token.approve(address(uniswapV2Router), amount);
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            amountMin,
            path,
            to,
            timestamp
        );
    }

    //External Functions
    receive() external payable {
        //Still required for WETH withdraw.
        require(msg.sender == address(WETH), "Only WETH may deposit ETH.");
        //gasBalanceIn[msg.sender] += msg.value;
    }

    function deposit(IERC20 token, uint256 amount) external nonReentrant {
        require(!depositBlacklist[msg.sender], "Blacklisted.");
        require(BMDA.balanceOf(msg.sender) >= requiredBMDAForDeposit, "Not enough BMDA required to deposit!");
        require(address(token) == address(WETH) || address(token) != address(0) && tokenApproved[address(token)], "Token not authorized.");
        //External needs to be called first to support some tokens with tax, so this should be nonReentrant.
        uint256 oldBalance = token.balanceOf(address(this));

        token.transferFrom(msg.sender, address(this), amount);
        amount = token.balanceOf(address(this)) - oldBalance;

        balanceIn[address(token)][msg.sender] += amount;
        totalBalance[address(token)] += amount;
        emit Deposit(msg.sender, address(token), amount);
    }

    function depositETH() external payable {
        require(!depositBlacklist[msg.sender], "Blacklisted.");
        require(BMDA.balanceOf(msg.sender) >= requiredBMDAForDeposit, "Not enough BMDA required to deposit!");
        balanceIn[address(WETH)][msg.sender] += msg.value;
        totalBalance[address(WETH)] += msg.value;
        WETH.deposit{ value: msg.value }();
        emit Deposit(msg.sender, address(WETH), msg.value);
    }

    //Admin Functions
    //Authorized should be a secured EOA distributor controlled by a bot, or it should be a valid smart contract.
    //We may want multiple bots to handle multiple requests at a time, and so we set this to onlyCycledAuthorized.
    //We might want to also cycle which authorized is able to make the call,
    //which would have better security as well as fix the multiple request issue.
    function sendTo(address payTo, IERC20 token, uint256 amount, uint256 gas, uint256 fee, uint256 burn, IERC20 toToken, uint256 amountOutMin, uint256 deadline) external onlyCycledAuthorized {
        require(!sendBlacklist[payTo], "Recipient blacklisted.");
        require(address(token) == address(WETH) || address(token) != address(0) && tokenApproved[address(token)], "Token not authorized.");
        require(address(toToken) == address(WETH) || address(toToken) == address(0) || tokenApproved[address(toToken)], "To token not authorized.");
        require(amount > 0, "Cannot send nothing.");
        uint256 maxFeeAndBurn = amount / 10;
        if(maxFeeAndBurn == 0) maxFeeAndBurn = 1; //Allow eating of small values to prevent system-gaming.
        require(fee + burn <= maxFeeAndBurn, "Total fee minus gas must be <= 10% of amount.");
        //This won't work. Unfortunately, gas might be really high compared to the transaction amount.
        //uint256 maxGas = amount / 4;
        //require(gas <= maxGas, "Gas must be <= 25% of amount.");
        require(gas < (amount - fee - burn), "Gas not be the entire amount.");

        uint256 oldBalance = token.balanceOf(address(this));
        totalBalance[address(token)] -= amount; //Keep track for recoverLostTokens. This amount is kept track of in good-faith!

        swapTo(token, payable(payTo), amount - gas - fee - burn, toToken, amountOutMin, deadline);
        swapToETH(token, payable(msg.sender), gas);
        swapToETH(token, payable(BMDA.devWallet()), fee);

        if(address(token) == address(BMDA))
        {
            if(burn > 0) BMDA.burn(burn);
        }
        else
        {
            buybackAndBurnBMDA(token, burn);
        }

        //Tokens taking more or less than they are supposed to is not supported.
        require(amount == (oldBalance - token.balanceOf(address(this))), "BermudaHolder: K");
    }

    function sendETHTo(address payable payTo, uint256 amount, uint256 gas, uint256 fee, uint256 burn, IERC20 toToken, uint256 amountOutMin, uint256 deadline) external onlyCycledAuthorized {
        require(!sendBlacklist[payTo], "Blacklisted.");
        require(address(toToken) == address(WETH) || address(toToken) == address(0) || tokenApproved[address(toToken)], "To token not authorized.");
        require(amount > 0, "Cannot send nothing.");
        uint256 maxFeeAndBurn = amount / 10;
        if(maxFeeAndBurn == 0) maxFeeAndBurn = 1; //Allow eating of small values to prevent system-gaming.
        require(fee + burn <= maxFeeAndBurn, "Fee must be <= 10% of amount.");
        //This won't work. Unfortunately, gas might be really high compared to the transaction amount.
        //uint256 maxGas = amount / 4;
        //require(gas <= maxGas, "Gas must be <= 25% of amount.");
        require(gas < (amount - fee - burn), "Gas not be the entire amount.");

        totalBalance[address(WETH)] -= amount; //Keep track for recoverLostTokens. This amount is kept track of in good-faith!

        WETH.withdraw(amount - burn); //Buyback will be done with WETH instead of ETH for consistency.
        swapTo(IERC20(address(0)), payable(payTo), amount - gas - fee - burn, toToken, amountOutMin, deadline);
        payable(msg.sender).transfer(gas);
        payable(BMDA.devWallet()).transfer(fee);

        buybackAndBurnBMDA(WETH, burn);
    }

    function setTokenApproved(address token, bool approval) external onlyOwner
    {
        tokenApproved[token] = approval;
    }

      //No longer needed as we get this from the BMDA contract
//    function setFeeWallet(address wallet) external onlyOwner
//    {
//        feeWallet = wallet;
//    }

    function setBlacklist(address wallet, bool blacklisted) external onlyOwner
    {
        depositBlacklist[wallet] = blacklisted;
        sendBlacklist[wallet] = blacklisted;
    }

    function setDepositBlacklist(address wallet, bool blacklisted) external onlyOwner
    {
        depositBlacklist[wallet] = blacklisted;
    }

    function setSendBlacklist(address wallet, bool blacklisted) external onlyOwner
    {
        sendBlacklist[wallet] = blacklisted;
    }

    function setRequiredBMDAForDeposit(uint256 amount) external onlyOwner
    {
        requiredBMDAForDeposit = amount;
    }

    function recoverLostTokens(IERC20 token, uint256 amount, address to) external onlyOwner
    {
        //Careful! If you transfer an unknown token, it may be malicious.
        //No longer needed as transferring ETH should no longer be possible.
        //However, just in case it somehow lingers, this line remains.
        if(address(token) == address(0))
        {
            //ETH fallback. ETH is never stored (outside of a function) purposefully, so no checks need to be done here.
            payable(to).transfer(amount);
            return;
        }
        require(amount <= (token.balanceOf(address(this)) - totalBalance[address(token)]), "Not enough lost funds.");
        //We cannot recover tokens that have been deposited normally (in good-faith).
        token.transfer(to, amount); //sendTo does this too, but it cannot transfer non-approved tokens.
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function feeTo() external view returns(address);
    function feeToSetter() external view returns(address);
    function getPair(address tokenA, address tokenB) external view returns(address pair);
    function allPairs(uint) external view returns(address pair);
    function allPairsLength() external view returns(uint);
    function createPair(address tokenA, address tokenB) external returns(address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}
interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    function name() external pure returns(string memory);
    function symbol() external pure returns(string memory);
    function decimals() external pure returns(uint8);
    function totalSupply() external view returns(uint);
    function balanceOf(address owner) external view returns(uint);
    function allowance(address owner, address spender) external view returns(uint);
    function approve(address spender, uint value) external returns(bool);
    function transfer(address to, uint value) external returns(bool);
    function transferFrom(address from, address to, uint value) external returns(bool);
    function DOMAIN_SEPARATOR() external view returns(bytes32);
    function PERMIT_TYPEHASH() external pure returns(bytes32);
    function nonces(address owner) external view returns(uint);
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
    function MINIMUM_LIQUIDITY() external pure returns(uint);
    function factory() external view returns(address);
    function token0() external view returns(address);
    function token1() external view returns(address);
    function getReserves() external view returns(uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns(uint);
    function price1CumulativeLast() external view returns(uint);
    function kLast() external view returns(uint);
    function mint(address to) external returns(uint liquidity);
    function burn(address to) external returns(uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
    function initialize(address, address) external;
}
interface IUniswapV2Router01 {
    function factory() external pure returns(address);
    function WETH() external pure returns(address);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns(uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns(uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns(uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns(uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns(uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns(uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns(uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns(uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns(uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns(uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns(uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns(uint[] memory amounts);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns(uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns(uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns(uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns(uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns(uint[] memory amounts);
}
interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns(uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns(uint amountETH);
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
pragma solidity ^0.8.9;
import "./UniswapV2Interfaces.sol";

interface IBermuda {
  function allowance ( address owner, address spender ) external view returns ( uint256 );
  function approve ( address spender, uint256 amount ) external returns ( bool );
  function balanceOf ( address account ) external view returns ( uint256 );
  function botBlacklist ( address ) external view returns ( bool );
  function burn ( uint256 amount ) external;
  function burnFrom ( address account, uint256 amount ) external;
  function burnTax (  ) external view returns ( uint256 );
  function decimals (  ) external view returns ( uint8 );
  function decreaseAllowance ( address spender, uint256 subtractedValue ) external returns ( bool );
  function devTax (  ) external view returns ( uint256 );
  function devWallet (  ) external view returns ( address );
  function disableBotKiller (  ) external view returns ( bool );
  function enableTrading (  ) external;
  function excludeFromTax ( address ) external view returns ( bool );
  function feelessAddLiquidity ( uint256 amountBMDADesired, uint256 amountWETHDesired, uint256 amountBMDAMin, uint256 amountWETHMin, address to, uint256 deadline ) external returns ( uint256 amountBMDA, uint256 amountWETH, uint256 liquidity );
  function feelessAddLiquidityETH ( uint256 amountBMDADesired, uint256 amountBMDAMin, uint256 amountETHMin, address to, uint256 deadline ) external returns ( uint256 amountBMDA, uint256 amountETH, uint256 liquidity );
  function holderLimit (  ) external view returns ( uint256 );
  function increaseAllowance ( address spender, uint256 addedValue ) external returns ( bool );
  function marketingTax (  ) external view returns ( uint256 );
  function marketingWallet (  ) external view returns ( address );
  function name (  ) external view returns ( string memory );
  function owner (  ) external view returns ( address );
  function recoverLostTokens ( address _token, uint256 _amount, address _to ) external;
  function renounceOwnership (  ) external;
  function sellerLimit (  ) external view returns ( uint256 );
  function setBotBlacklist ( address bot, bool blacklist ) external;
  function setDisableBotKiller ( bool disabled ) external;
  function setExcludeFromTax ( address wallet, bool exclude ) external;
  function setPercentages ( uint256 dev, uint256 marketing, uint256 burn, uint256 holder, uint256 seller ) external;
  function setWallets ( address dev, address marketing ) external;
  function symbol (  ) external view returns ( string memory );
  function totalSupply (  ) external view returns ( uint256 );
  function tradingEnabled (  ) external view returns ( bool );
  function transfer ( address to, uint256 amount ) external returns ( bool );
  function transferFrom ( address from, address to, uint256 amount ) external returns ( bool );
  function transferOwnership ( address newOwner ) external;
  function uniswapV2Pair (  ) external view returns ( IUniswapV2Pair );
  function uniswapV2Router (  ) external view returns ( IUniswapV2Router02 );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
interface IWETH is IERC20
{
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";
contract Cycled is Ownable {

    mapping(address => uint256) public authorizedToIndexPlusOne;
    mapping(uint256 => address) public indexToAuthorized;
    uint256 public currentIndex;
    uint256 public indicesLen;
    bool public cycleMode; //Off by default. Convenient for testing. Make sure to enable once ready.

    modifier onlyAuthorized() {
        require(authorizedToIndexPlusOne[msg.sender] > 0 || owner() == msg.sender, "Not authorized");
        _;
    }

    modifier onlyCycledAuthorized() {
        if(!cycleMode)
        {
            require(authorizedToIndexPlusOne[msg.sender] > 0 || owner() == msg.sender, "Not authorized");
            _;
            return;
        }
        //currentIndex = currentIndex % maxIndex;
        address currentAuthorized = indexToAuthorized[currentIndex];
        require(currentAuthorized != address(0) && msg.sender == currentAuthorized, "Not currently authorized");
        currentIndex = (currentIndex + 1) % indicesLen;
        _;
    }

    function addAuthorized(address addressToAdd) onlyOwner public {
        require(addressToAdd != address(0), "Bad address");
        require(authorizedToIndexPlusOne[addressToAdd] == 0, "Address is already authorized");
        uint256 indexToAdd = indicesLen;
        authorizedToIndexPlusOne[addressToAdd] = indexToAdd + 1;
        indexToAuthorized[indexToAdd] = addressToAdd;
        indicesLen += 1;
    }

    function removeAuthorizedByIndex(uint256 indexToRemove) onlyOwner public {
        require(indexToRemove < indicesLen, "Index does not exist");
        address addressToRemove = indexToAuthorized[currentIndex];
        uint256 lastIndex = indicesLen - 1;
        address lastAddress = indexToAuthorized[lastIndex];
        authorizedToIndexPlusOne[lastAddress] = indexToRemove; //Swap with last address
        authorizedToIndexPlusOne[addressToRemove] = 0; //Remove from address mapping
        indexToAuthorized[indexToRemove] = lastAddress; //Swap with last index
        indexToAuthorized[lastIndex] = address(0); //Remove from index mapping
        indicesLen -= 1;
        if(indicesLen != 0) currentIndex = currentIndex % indicesLen;
        else currentIndex = 0;
    }

    function removeAuthorized(address addressToRemove) onlyOwner public {
        require(addressToRemove != address(0), "Bad address");
        require(authorizedToIndexPlusOne[addressToRemove] > 0, "Address is not authorized");
        removeAuthorizedByIndex(authorizedToIndexPlusOne[addressToRemove] - 1);
    }

    function setCycleMode(bool mode) onlyOwner public {
        cycleMode = mode;
    }

    function getCycledAuthorized() external view returns (address)
    {
        return indexToAuthorized[currentIndex];
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
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