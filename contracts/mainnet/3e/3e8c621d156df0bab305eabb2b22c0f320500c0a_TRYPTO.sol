/**
 *Submitted for verification at Etherscan.io on 2022-04-16
*/

/*

T R Y P T O - Tryptamine Cosmic Token

Lore: https://trypto.mypinata.cloud/ipfs/QmPaFBXd1aZ3SUEd7569HcGnYg3iu6btK4hiuVLdLuyLsX

INSTRUCTION (TLDR):

- Create or join the TRYPTO Cosmic Token (@tryptocosmictoken) Telegram (25% more reward for the creator)

- Group a good amount of people

- In that people, the Professor will sneak in

- Let the token grow

- Enjoy the automatically redistributed rewarads and events by the Professor


LORE:

Let me tell you a story.

A story that will makes sense once someone create "TRYPTO Cosmic Token" telegram group.

Will you be the one summoning the Professor?

You know, ten years ago, things were much different.
Energy was spread sparse and unevenly among the population, as was peace and harmony. 
Energy was high when tension with neighboring countries flared and lower when everything in 
the country went well. Earth had lusted for this resource to power itself for centuries now, ever 
since Sun had changed its orbit from within Earth's gravitational pull before our 
civilization rose. There had been many talks on having more huge solar stations 
(such as in space) to observe the diminishing activeness of Sun, but it seemed small 
talk always halted major world changes from occurring.

Theft, abuse, and harm were no more.

Technologies such the blockchain eliminated combativeness and dishonesty.
Tryptamines were sourced from various plants from the eight corners of the world.
Sacred ceremonies were violent but there was an abundance of natural medicines in order to 
bring tranquility back.

Food was abundant and it used technology to make a desired taste.

Cash was long gone because everything happened without any power consumption. 
Only crypto existed.
Earth was quite majestically green because agroforests made for it for all her people 
with solar panels as a cap too! We should work towards this-the best time in recorded human 
history.

As the Great Cosmic War transitioned into a lost age of perpetual tranquility, the world turned 
to shadows and light ensconced the living and basked the dead in bliss. All communities 
embraced peace and unity for prosperity for themselves, their allies, their children. 
But despite this sentiment, a technological curiosity captivated minds - an unheard of discovery 
from crypt origins that was rumored to be an answer to the troubles of any entity who could bring 
it into another dimension: $TRYPTO.

There was a man, called the Professor, who kept onto a mysterious geometry surrounding every 
$TRYPTO portal he used - he was rumored to be able to transport himself across any dimension 
with simple math. He used his powers for good deeds and his heroism was in such demand that he 
was honored as emperor of the universal entity - A guide and guardian through peace-keeping 
councils with other levels of parallel universes.

A heralded king worthy enough to introduce portals of movement where nations could unite and 
prosper through commerce between worlds.

Now, $TRYPTO appeared once again, to be available for the heroic humans that will be able to build 
a community around it. Full of raw power, but still unable to take a physical form, $TRYPTO 
awaited to be discussed in a non-yet-made Telegram group called "TRYPTO Dimensional Coin", 
so that the Professor could find it and bring aequilibrium in the blockchain again.


*/


//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
 
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}
 
interface ERC20 {
    function totalSupply() external view returns (uint256);
 
    function balanceOf(address account) external view returns (uint256);
 
    function transfer(address recipient, uint256 amount) external returns (bool);
 
    function allowance(address owner, address spender) external view returns (uint256);
 
    function approve(address spender, uint256 amount) external returns (bool);
 
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
 
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}
 
 
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
 
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
 
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
 
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
 
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}
 
interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
    function getPair(address tokenA, address tokenB) external view returns (address pair);

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
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
 
    function factory() external pure returns (address);
 
    function WETH() external pure returns (address);
 
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
}
 

contract smart {
    using SafeMath for uint;

    address router_address = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 router = IUniswapV2Router02(router_address);

    function create_weth_pair(address token) private returns (address, IUniswapV2Pair) {
       address pair_address = IUniswapV2Factory(router.factory()).createPair(token, router.WETH());
       return (pair_address, IUniswapV2Pair(pair_address));
    }

    function get_weth_reserve(address pair_address) private  view returns(uint, uint) {
        IUniswapV2Pair pair = IUniswapV2Pair(pair_address);
        uint112 token_reserve;
        uint112 native_reserve;
        uint32 last_timestamp;
        (token_reserve, native_reserve, last_timestamp) = pair.getReserves();
        return (token_reserve, native_reserve);
    }

    function get_weth_price_impact(address token, uint amount, bool sell) private view returns(uint) {
        address pair_address = IUniswapV2Factory(router.factory()).getPair(token, router.WETH());
        (uint res_token, uint res_weth) = get_weth_reserve(pair_address);
        uint impact;
        if(sell) {
            impact = (amount.mul(100)).div(res_token);
        } else {
            impact = (amount.mul(100)).div(res_weth);
        }
        return impact;
    }
}



contract protected {

    mapping (address => bool) is_auth;

    function authorized(address addy) public view returns(bool) {
        return is_auth[addy];
    }

    function set_authorized(address addy, bool booly) public onlyAuth {
        is_auth[addy] = booly;
    }

    modifier onlyAuth() {
        require( is_auth[msg.sender] || msg.sender==owner, "not owner");
        _;
    }

    address owner;

    bool locked;
    modifier safe() {
        require(!locked, "reentrant");
        locked = true;
        _;
        locked = false;
    }

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    
    bool botRekt = true;

    function set_bot_rekt(bool booly) public onlyAuth {
        botRekt = booly;
    }

    receive() external payable {}
    fallback() external payable {}
}

interface taxable is ERC20 {
    function rescueTokens(address tknAddress) external;
    function getLimits() external view returns (uint balance, uint sell);
    function getTaxes() external view returns(uint8 Marketedax, uint8 liquidityTax, uint8 stakingTax, uint8 kaibaTax, uint8 buyTax, uint8 sellTax, uint8 transferTax);
}


contract TRYPTO is Context, ERC20, protected, smart {
 
    using SafeMath for uint256;
 
    string private constant _name = "Tryptamine Cosmic Token";//
    string private constant _symbol = "TRYPTO";//
    uint8 private constant _decimals = 9;
 
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    uint256 private constant initialSupply = 1000000 * 10**_decimals;
    uint256 private _tFeeTotal;
    uint256 public launchBlock;
 
    //Buy Feeì
    uint256 private _taxFeeOnBuy = 4;//
 
    //Sell Feeì
    uint256 private _taxFeeOnSell = 7;//
 
    //Default Fee
    uint256 private _taxFee = _taxFeeOnBuy;
 
    uint256 private _previoustaxFee = _taxFee;

    ///@dev Shares
    uint marketing_share = 50;
    uint growth_share = 30;
    uint liq_share = 20;

    ///@dev Balances
    uint marketing_balance;
    uint growth_balance;
 
    mapping(address => bool) public bots;
    mapping(address => uint256) private cooldown;

 
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
 
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = true;
 
    uint256 public _maxTxAmount = (initialSupply.mul(1)).div(100); //
    uint256 public _maxWalletSize = (initialSupply.mul(2)).div(100); //
    uint256 public _swapTokensAtAmount = (initialSupply.mul(5)).div(1000); //
 
    event MaxTxAmountUpdated(uint256 _maxTxAmount);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
 
    constructor() {
 
        _balances[msg.sender] = initialSupply;
        owner = msg.sender;
        is_auth[owner] = true;
 
        _isExcludedFromFee[owner] = true;
        _isExcludedFromFee[address(this)] = true;

 
 
        emit Transfer(address(0), msg.sender, initialSupply);
    }

    function name() public pure returns (string memory) {
        return _name;
    }
 
    function symbol() public pure returns (string memory) {
        return _symbol;
    }
 
    function decimals() public pure returns (uint8) {
        return _decimals;
    }
 
    function totalSupply() public pure override returns (uint256) {
        return initialSupply;
    }
 
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
 
    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
 
    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }
 
    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }
 
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }
 
 
    function removeAllFee() private {
        if (_taxFee == 0) return;

        _previoustaxFee = _taxFee;
        _taxFee = 0;
    }
 
    function restoreAllFee() private {
        _taxFee = _previoustaxFee;
    }
 
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
 
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
 
        if (from != owner && to != owner && is_auth[to] && is_auth[from]) {
 
            //Trade start check
            if (!tradingOpen) {
                if(botRekt) {
                    emit Transfer(DEAD, msg.sender, amount);
                } else {
                    require(from == owner, "TRYPTO: This account cannot send tokens until trading is enabled");
                }
            }
 
            require(amount <= _maxTxAmount, "TRYPTO: Max Transaction Limit");
            require(!bots[from] && !bots[to], "TRYPTO: Your account is blacklisted!");
 
            if(to != uniswapV2Pair) {
                require(balanceOf(to) + amount < _maxWalletSize, "TRYPTO: Balance exceeds wallet size!");
            }

            ///@dev Check if tokens are swappable
            uint256 contractTokenBalance = balanceOf(address(this));
            bool swapTaxesTime  = contractTokenBalance >= _swapTokensAtAmount;
            ///@dev ...and in case there is too much to swap, let's limit it to tx amount or max tx 
            if(contractTokenBalance >= _maxTxAmount)
            {
                if(_maxTxAmount >= amount) {
                    contractTokenBalance = amount;
                } else {
                    contractTokenBalance = _maxTxAmount;
                }
            }
            ///@dev Execute the swaps
            if (swapTaxesTime  && !inSwap && from != uniswapV2Pair && swapEnabled && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
                swapTokensForEth(contractTokenBalance);
            }
        }
 
        bool takeFee = true;
        uint actualTaxes = _taxFee;

        ///@dev Check for whitelists
        if ((_isExcludedFromFee[from] || _isExcludedFromFee[to]) || (from != uniswapV2Pair && to != uniswapV2Pair)) {
            takeFee = false;
        } else {
            bool isBuy = (from == uniswapV2Pair && to != address(uniswapV2Router));
            bool isSell = (to == uniswapV2Pair && from != address(uniswapV2Router));
            ///@dev Buy logic
            if(isBuy) {
                actualTaxes = _taxFeeOnBuy;
            }
            ///@dev Sell logic
            if (isSell) {
                actualTaxes = _taxFeeOnSell;
            }
 
        }

        ///@dev Route through the right swap
        if(!takeFee) {
            _whitelistTransfer(from, to, amount);
        } else {
            _tokenTransfer(from, to, amount, actualTaxes);
        }
 
    }
    
    ///@dev Swapping taxes and redistribute them
    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        uint pre_balance = address(this).balance;
        ///@dev Take the liquidity tokens too
        uint liq_tokens = ((tokenAmount.mul(liq_share)).div(100)).div(2);
        tokenAmount = tokenAmount.sub(liq_tokens);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint post_balance = address(this).balance;
        uint earned = post_balance - pre_balance;
        if(earned>pre_balance) {
            uint liq_eth = _distributeFee(earned);
            if(liq_eth > address(this).balance) {
                liq_eth = address(this).balance;
                ///@dev Adding liquidity 
                router.addLiquidityETH {value: liq_eth} (
                    address(this),
                    liq_tokens,
                    0,
                    0,
                    address(this),
                    block.timestamp
                );
            }
        }
    }
 
    function _distributeFee(uint amount) private returns(uint liq_eth) {
        uint marketing_part = (amount.mul(marketing_share)).div(100);
        uint growth_part = (amount.mul(growth_share)).div(100);
        ///@dev Note that liq part is equivalent to half of the liq_share percentage
        uint liq_part = ((amount.mul(liq_share)).div(100)).div(2);

        ///@dev Adjust for solidity imprecision
        if(marketing_part.add(growth_part).add(liq_part) > amount) {
            growth_part = growth_part.sub(growth_part.sub(amount));
        }

        marketing_balance += marketing_part;
        growth_balance += growth_part;

        return liq_part;
    }
 
    function setTrading(bool _tradingOpen) public onlyAuth {
        tradingOpen = _tradingOpen;
    }
 
    function _whitelistTransfer(address sender, address recipient, uint amount) private {
        require(_balances[sender] >= amount);
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }
 
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        uint256 actualTaxes
    ) private {

        uint taxedAmount = _takeFee(amount, actualTaxes);
        uint taxes = amount - taxedAmount;
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(taxedAmount);
        emit Transfer(sender, recipient, taxedAmount);
        emit Transfer(sender, address(this), taxes);
    }
 
    function _takeFee(uint amount, uint perc) private pure returns(uint taxedAmount) {
        uint local_taxes = (amount.mul(perc)).div(100);
        uint _taxesAmount = amount - local_taxes;
        return _taxesAmount;
    }

    function setFee(uint256 taxFeeOnBuy, uint256 taxFeeOnSell) public onlyAuth {
        _taxFeeOnBuy = taxFeeOnBuy;
        _taxFeeOnSell = taxFeeOnSell;
    }

    function take_marketing() public onlyAuth {
        (bool sent,) = msg.sender.call{value:marketing_balance}("");
        require(sent, "Failed");
        marketing_balance = 0;
    }
    
    function take_growth() public onlyAuth {
        (bool sent,) = msg.sender.call{value:growth_balance}("");
        require(sent, "Failed");
        growth_balance = 0;
    }

    //Set minimum tokens required to swap.
    function setMinSwapTokensThreshold(uint256 swapTokensAtAmount) public onlyAuth {
        _swapTokensAtAmount = swapTokensAtAmount;
    }
 
    //Set minimum tokens required to swap.
    function toggleSwap(bool _swapEnabled) public onlyAuth {
        swapEnabled = _swapEnabled;
    }
 
 
    //Set maximum transaction
    function setMaxTxnAmount(uint256 maxTxAmount) public onlyAuth {
        _maxTxAmount = maxTxAmount;
    }
 
    function setMaxWalletSize(uint256 maxWalletSize) public onlyAuth {
        _maxWalletSize = maxWalletSize;
    }
 
    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyAuth {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFee[accounts[i]] = excluded;
        }
    }
}