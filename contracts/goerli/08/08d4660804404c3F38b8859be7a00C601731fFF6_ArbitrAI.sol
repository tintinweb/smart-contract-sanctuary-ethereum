/**
 *Submitted for verification at Etherscan.io on 2023-03-16
*/

/**
 *Submitted for verification at Etherscan.io on 2023-03-16
*/

// SPDX-License-Identifier: MIT
// File: ArbiTree/Libraries.sol



pragma solidity ^0.8.4;

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: ArbiTree/token.sol



pragma solidity ^0.8.4;




contract ArbitrAI is IERC20, Ownable
{

    mapping(address => uint) private _balances;
    mapping(address => mapping(address => uint)) private _allowances;
    mapping(address => bool) public excludedFromFees;
    mapping(address => bool) public isAMM;
    //Token Info
    string public constant name = 'ArbitrAI';
    string public constant symbol = 'AAI0';
    uint8 public constant decimals = 18;
    uint public constant InitialSupply = 10 ** 9 * 10 ** decimals;//equals 1.000.000.000 Token
    //    address operationWallet = 0xf82618B0a8E62153B1173647bF8FBb7840905EEf;

    uint private constant DefaultLiquidityLockTime = 7 days;
    //TODO: mainnet
    //goerli testnet
    address private constant UniswapV2Router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    //variables that track balanceLimit and sellLimit,
    //can be updated based on circulating supply and Sell- and BalanceLimitDividers
    uint private _circulatingSupply = InitialSupply;

    //Tracks the current Taxes, different Taxes can be applied for buy/sell/transfer
    uint public buyTax = 150;
    uint public sellTax = 150;
    uint public transferTax = 0;
    uint public burnTax = 0;
    uint public minerTax = 250;
    uint public marketingTax = 750;
    uint constant TAX_DENOMINATOR = 1000;
    uint constant MAXTAXDENOMINATOR = 10;


    address private _uniswapV2PairAddress;
    IUniswapV2Router02 private _uniswapV2Router;


    //TODO: marketingWallet
    address public marketingWallet;
    //Only marketingWallet can change marketingWallet
    function ChangeMarketingWallet(address newWallet) public {
        require(msg.sender == marketingWallet);
        marketingWallet = newWallet;
    }

    address public minerWallet = 0xFF6CdCD9A2B13E54b250420739EAA96Db01a165E;

    function ChangeMinerWallet(address newWallet) public onlyTeam {
        minerWallet = newWallet;
    }
    //modifier for functions only the team can call
    modifier onlyTeam() {
        require(_isTeam(msg.sender), "Caller not Team or Owner");
        _;
    }
    //Checks if address is in Team, is needed to give Team access even if contract is renounced
    //Team doesn't have access to critical Functions that could turn this into a Rugpull(Exept liquidity unlocks)
    function _isTeam(address addr) private view returns (bool){
        return addr == owner() || addr == marketingWallet;
    }
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Constructor///////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    constructor () {
        uint deployerBalance = _circulatingSupply;
        _balances[msg.sender] = deployerBalance;
        emit Transfer(address(0), msg.sender, deployerBalance);

        // UniswapV2 Router
        _uniswapV2Router = IUniswapV2Router02(UniswapV2Router);
        //Creates a UniswapV2 Pair
        _uniswapV2PairAddress = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        isAMM[_uniswapV2PairAddress] = true;

        //contract creator is by default marketing wallet
        marketingWallet = msg.sender;
        //owner uniswapV2 router and contract is excluded from Taxes
        excludedFromFees[msg.sender] = true;
        excludedFromFees[UniswapV2Router] = true;
        excludedFromFees[address(this)] = true;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Transfer functionality////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    //transfer function, every transfer runs through this function
    function _transfer(address sender, address recipient, uint amount) private {
        require(sender != address(0), "Transfer from zero");
        require(recipient != address(0), "Transfer to zero");


        //Pick transfer
        if (excludedFromFees[sender] || excludedFromFees[recipient])
            _feelessTransfer(sender, recipient, amount);
        else {
            //once trading is enabled, it can't be turned off again
            require(LaunchTimestamp > 0, "trading not yet enabled");
            _taxedTransfer(sender, recipient, amount);
        }
    }
    //applies taxes, checks for limits, locks generates autoLP and stakingETH, and autostakes
    function _taxedTransfer(address sender, address recipient, uint amount) private {
        uint senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer exceeds balance");

        bool isBuy = isAMM[sender];
        bool isSell = isAMM[recipient];

        uint tax;
        if (isSell) {
            uint SellTaxDuration = 60 seconds;
            if (block.timestamp < LaunchTimestamp + SellTaxDuration) {
                tax = TAX_DENOMINATOR;
            } else tax = sellTax;
        }
        else if (isBuy) {
            uint BuyTaxDuration = 60 seconds;
            if (block.timestamp < LaunchTimestamp + BuyTaxDuration) {
                tax = TAX_DENOMINATOR;
            } else tax = buyTax;
        } else tax = transferTax;

        //Calculates the exact token amount for each tax
        uint tokensToBeBurnt = _calculateFee(amount, tax, burnTax);
        //staking and liquidity Tax get treated the same, only during conversion they get split
        uint contractToken = _calculateFee(amount, tax, marketingTax + minerTax);
        //Subtract the Taxed Tokens from the amount
        uint taxedAmount = amount - (tokensToBeBurnt + contractToken);

        _balances[sender] -= amount;
        //Adds the taxed tokens to the operation & miner wallet
        _balances[address(this)] += contractToken;
        //Burns tokens
        _circulatingSupply -= tokensToBeBurnt;
        _balances[recipient] += taxedAmount;

        if ((sender != _uniswapV2PairAddress) && (!manualSwap) && (!_isSwappingContractModifier))
            _swapContractToken(contractToken);

        emit Transfer(sender, recipient, taxedAmount);
    }

    //Calculates the token that should be taxed
    function _calculateFee(uint amount, uint tax, uint taxPercent) private pure returns (uint) {
        return (amount * tax * taxPercent) / (TAX_DENOMINATOR * TAX_DENOMINATOR);
    }


    //Feeless transfer only transfers and autostakes
    function _feelessTransfer(address sender, address recipient, uint amount) private {
        uint senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer exceeds balance");
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Swap Contract Tokens//////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    //Locks the swap if already swapping
    bool private _isSwappingContractModifier;
    modifier lockTheSwap {
        _isSwappingContractModifier = true;
        _;
        _isSwappingContractModifier = false;
    }

    //Sets the permille of uniswapV2 pair to trigger liquifying taxed token
    uint public swapTreshold = 2;

    function setSwapTreshold(uint newSwapTresholdPermille) public onlyTeam {
        require(newSwapTresholdPermille <= 10);
        //MaxTreshold= 1%
        swapTreshold = newSwapTresholdPermille;
    }
    //Sets the max Liquidity where swaps for Liquidity still happen
    uint public overLiquifyTreshold = 150;

    function SetOverLiquifiedTreshold(uint newOverLiquifyTresholdPermille) public onlyTeam {
        require(newOverLiquifyTresholdPermille <= 1000);
        overLiquifyTreshold = newOverLiquifyTresholdPermille;
    }
    //Sets the taxes Burn+marketing+liquidity tax needs to equal the TAX_DENOMINATOR (1000)
    //buy, sell and transfer tax are limited by the MAXTAXDENOMINATOR
    event OnSetTaxes(uint buy, uint sell, uint transfer_, uint burn, uint marketing, uint miner);

    function SetTaxes(uint buy, uint sell, uint transfer_, uint burn, uint marketing, uint miner) public onlyTeam {
        uint maxTax = TAX_DENOMINATOR / MAXTAXDENOMINATOR;
        require(buy <= maxTax && sell <= maxTax && transfer_ <= maxTax, "Tax exceeds maxTax");
        require(burn + marketing + miner == TAX_DENOMINATOR, "Taxes don't add up to denominator");

        buyTax = buy;
        sellTax = sell;
        transferTax = transfer_;
        marketingTax = marketing;
        minerTax = miner;
        burnTax = burn;
        emit OnSetTaxes(buy, sell, transfer_, burn, marketing, miner);
    }

    //If liquidity is over the treshold, convert 100% of Token to Marketing ETH to avoid overliquifying
    function isOverLiquified() public view returns (bool){
        return _balances[_uniswapV2PairAddress] > _circulatingSupply * overLiquifyTreshold / 1000;
    }


    //swaps the token on the contract for Marketing ETH and LP Token.
    //always swaps a percentage of the LP pair balance to avoid price impact
    function _swapContractToken(uint tokenToSwap) private lockTheSwap {
        uint totalTax = minerTax + marketingTax;
        uint initialETHBalance = address(this).balance;
        _swapTokenForETH(tokenToSwap);
        uint newETH = (address(this).balance - initialETHBalance);

        uint marketingETH = (newETH * marketingTax) / totalTax;

        //Sends all the marketing ETH to the marketingWallet
        (bool sent1,) = marketingWallet.call{value : marketingETH}("");
        (bool sent2,) = minerWallet.call{value : newETH - marketingETH}("");
        sent1 = true;
        sent2 = true;
    }
    //swaps tokens on the contract for ETH
    function _swapTokenForETH(uint amount) private {
        _approve(address(this), address(_uniswapV2Router), amount);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();

        try _uniswapV2Router.swapExactTokensForETH(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        ){}
        catch{}
    }
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //public functions /////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    function getLiquidityReleaseTimeInSeconds() public view returns (uint){
        if (block.timestamp < _liquidityUnlockTime)
            return _liquidityUnlockTime - block.timestamp;
        return 0;
    }

    function getBurnedTokens() public view returns (uint){
        return (InitialSupply - _circulatingSupply) + _balances[address(0xdead)];
    }
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Settings//////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //For AMM addresses buy and sell taxes apply
    function SetAMM(address AMM, bool Add) public onlyTeam {
        require(AMM != _uniswapV2PairAddress, "can't change uniswap");
        isAMM[AMM] = Add;
    }

    bool public manualSwap;
    //switches autoLiquidity and marketing ETH generation during transfers
    function SwitchManualSwap(bool manual) public onlyTeam {
        manualSwap = manual;
    }
    //manually converts contract token to LP and staking ETH
    function SwapContractToken() public onlyTeam {
        uint tokenToSwap = _balances[address(this)];
        _swapContractToken(tokenToSwap);
    }

    event ExcludeAccount(address account, bool exclude);
    //Exclude/Include account from fees (eg. CEX)
    function ExcludeAccountFromFees(address account, bool exclude) public onlyTeam {
        require(account != address(this), "can't Include the contract");
        excludedFromFees[account] = exclude;
        emit ExcludeAccount(account, exclude);
    }
    //Enables trading. Sets the launch timestamp to the given Value
    event OnEnableTrading();

    uint public LaunchTimestamp;

    function SetupEnableTrading() public onlyTeam {
        require(LaunchTimestamp == 0, "AlreadyLaunched");
        LaunchTimestamp = block.timestamp;
        emit OnEnableTrading();
    }
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Liquidity Lock////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //the timestamp when Liquidity unlocks
    uint _liquidityUnlockTime;
    bool public LPReleaseLimitedTo20Percent;
    //Sets Liquidity Release to 20% at a time and prolongs liquidity Lock for a Week after Release.
    //That way autoLiquidity can be slowly released
    function limitLiquidityReleaseTo20Percent() public onlyTeam {
        LPReleaseLimitedTo20Percent = true;
    }
    //Locks Liquidity for seconds. can only be prolonged
    function LockLiquidityForSeconds(uint secondsUntilUnlock) public onlyTeam {
        _prolongLiquidityLock(secondsUntilUnlock + block.timestamp);
    }

    event OnProlongLPLock(uint UnlockTimestamp);

    function _prolongLiquidityLock(uint newUnlockTime) private {
        // require new unlock time to be longer than old one
        require(newUnlockTime > _liquidityUnlockTime);
        _liquidityUnlockTime = newUnlockTime;
        emit OnProlongLPLock(_liquidityUnlockTime);
    }

    event OnReleaseLP();
    //Release Liquidity Tokens once unlock time is over
    function LiquidityRelease() public onlyTeam {
        //Only callable if liquidity Unlock time is over
        require(block.timestamp >= _liquidityUnlockTime, "Not yet unlocked");

        IERC20 liquidityToken = IERC20(_uniswapV2PairAddress);
        uint amount = liquidityToken.balanceOf(address(this));
        if (LPReleaseLimitedTo20Percent)
        {
            _liquidityUnlockTime = block.timestamp + DefaultLiquidityLockTime;
            //regular liquidity release, only releases 20% at a time and locks liquidity for another week
            amount = amount * 2 / 10;
        }
        liquidityToken.transfer(msg.sender, amount);
        emit OnReleaseLP();
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //external//////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    receive() external payable {}

    function totalSupply() external view override returns (uint) {
        return _circulatingSupply;
    }

    function balanceOf(address account) external view override returns (uint) {
        return _balances[account];
    }

    function transfer(address recipient, uint amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address _owner, address spender) external view override returns (uint) {
        return _allowances[_owner][spender];
    }

    function approve(address spender, uint amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint amount) private {
        require(owner != address(0), "Approve from zero");
        require(spender != address(0), "Approve to zero");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transferFrom(address sender, address recipient, uint amount) external override returns (bool) {
        _transfer(sender, recipient, amount);

        uint currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "Transfer > allowance");

        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }

    // IERC20 - Helpers

    function increaseAllowance(address spender, uint addedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint subtractedValue) external returns (bool) {
        uint currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "<0 allowance");

        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }

}