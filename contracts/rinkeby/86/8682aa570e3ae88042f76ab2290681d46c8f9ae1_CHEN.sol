/**
 *Submitted for verification at Etherscan.io on 2022-08-29
*/

// SPDX-License-Identifier: MIT

// CHEN
pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

}  

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract CHEN is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isExcludedFromFee;
    mapping (address => bool) public isExcludedFromLimit;
    mapping (address => bool) private bots;
    mapping (address => uint) private cooldown;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1_000_000_000_000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    uint256 public swapThreshold = 100_000_000 * 10**9;
    
    uint256 public buyReflectionFee = 0;
    uint256 public buyLiquidityFee = 0;
    uint256 public buyTeamFee = 5;
    uint256 public sellReflectionFee = 0;
    uint256 public sellLiquidityFee = 0;
    uint256 public sellTeamFee = 5;

    uint256 public liqPending;

    address payable private _feeAddrWallet1;
    address payable private _feeAddrWallet2;
    
    string private constant _name = "CHEN Inu";
    string private constant _symbol = "CHEN";
    uint8 private constant _decimals = 9;

    struct ValuesFromAmount {
        // Amount of tokens for to transfer.
        uint256 amount;
        // Amount tokens charged for burning.
        uint256 tTeam;
        // Amount tokens charged to reward.
        uint256 tReflect;
        // Amount tokens charged to add to liquidity.
        uint256 tLiquidity;
        // Amount tokens after fees.
        uint256 tTransferAmount;
        // Reflection of amount.
        uint256 rAmount;
        // Reflection of burn fee.
        uint256 rTeam;
        // Reflection of reward fee.
        uint256 rReflect;
        // Reflection of liquify fee.
        uint256 rLiquidity;
        // Reflection of transfer amount.
        uint256 rTransferAmount;
    }
    
    IUniswapV2Router02 private uniswapV2Router;
    address public uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap;
    bool private swapEnabled;
    bool private cooldownEnabled;

    uint256 private _maxTxAmount = 20_000_000_000 * 10**9;
    uint256 private _maxWalletAmount = 30_000_000_000 * 10**9;

    event SendDividends(uint256 tokensSwapped, uint256 amount);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor (address wallet1, address wallet2) {
        _feeAddrWallet1 = payable(wallet1);
        _feeAddrWallet2 = payable(wallet2);
        _rOwned[_msgSender()] = _rTotal;

        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[_feeAddrWallet1] = true;
        isExcludedFromFee[_feeAddrWallet2] = true;

        isExcludedFromLimit[owner()] = true;
        isExcludedFromLimit[address(this)] = true;
        isExcludedFromLimit[address(0xdead)] = true;
        isExcludedFromLimit[_feeAddrWallet1] = true;
        isExcludedFromLimit[_feeAddrWallet2] = true;

        emit Transfer(address(this), _msgSender(), _tTotal);
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
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function setCooldownEnabled(bool onoff) external onlyOwner {
        cooldownEnabled = onoff;
    }

    function tokenFromReflection(uint256 rAmount) private view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        require(balanceOf(from) >= amount, "ERC20: transfer amount exceeds balance");

        if (from != owner() && to != owner()) {

            require(!bots[from] && !bots[to]);

            if (!isExcludedFromLimit[from] || (from == uniswapV2Pair && !isExcludedFromLimit[to])) {
                require(amount <= _maxTxAmount, "Anti-whale: Transfer amount exceeds max limit");
            }
            if (!isExcludedFromLimit[to]) {
                require(balanceOf(to) + amount <= _maxWalletAmount, "Anti-whale: Wallet amount exceeds max limit");
            }

            if (from == uniswapV2Pair && to != address(uniswapV2Router) && !isExcludedFromFee[to] && cooldownEnabled) {
                // Cooldown
                require(cooldown[to] < block.timestamp);
                cooldown[to] = block.timestamp + (60 seconds);
            }

            uint256 contractTokenBalance = balanceOf(address(this));

            if (!inSwap && from != uniswapV2Pair && swapEnabled && contractTokenBalance >= swapThreshold) {
                if (liqPending > 0) {
                    swapAndLiquify(liqPending);

                    liqPending = 0;
                }
                if (balanceOf(address(this)) > 0) {
                    swapAndSendETHToFee(balanceOf(address(this)));
                }
            }
        }
		
        _tokenTransfer(from,to,amount);
    }

    function swapAndLiquify(uint256 tokens) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
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
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function swapAndSendETHToFee(uint256 tokens) private lockTheSwap {
        uint256 initialBalance = address(this).balance;

        swapTokensForEth(tokens);
        
        uint256 dividends = address(this).balance.sub(initialBalance);

        (bool success,) = _feeAddrWallet1.call{value: dividends.div(2)}("");
        (success,) = _feeAddrWallet2.call{value: dividends.div(2)}("");

        if(success) {
            emit SendDividends(tokens, dividends);
        }
    }

    function openTrading() external onlyOwner() {
        require(!tradingOpen, "trading is already open");

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        isExcludedFromLimit[address(uniswapV2Router)] = true;
        isExcludedFromLimit[uniswapV2Pair] = true;

        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );

        swapEnabled = true;
        cooldownEnabled = true;
        tradingOpen = true;

        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
    }

    function changeMaxTxAmount(uint256 amount) public onlyOwner {
        _maxTxAmount = amount;
    }

    function changeMaxWalletAmount(uint256 amount) public onlyOwner {
        _maxWalletAmount = amount;
    }

    function changeSwapThreshold(uint256 amount) public onlyOwner {
        swapThreshold = amount;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        isExcludedFromFee[account] = excluded;
    }

    function excludeFromLimits(address account, bool excluded) public onlyOwner {
        isExcludedFromLimit[account] = excluded;
    }
    
    function setBots(address[] memory bots_) public onlyOwner {
        for (uint i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }
    
    function delBot(address notbot) public onlyOwner {
        bots[notbot] = false;
    }

    function changeBuyFees(uint256 _buyReflectionFee, uint256 _buyLiquidityFee, uint256 _buyTeamFee) public onlyOwner {
        buyReflectionFee = _buyReflectionFee;
        buyLiquidityFee = _buyLiquidityFee;
        buyTeamFee = _buyTeamFee;
    }

    function changeSellFees(uint256 _sellReflectionFee, uint256 _sellLiquidityFee, uint256 _sellTeamFee) public onlyOwner {
        sellReflectionFee = _sellReflectionFee;
        sellLiquidityFee = _sellLiquidityFee;
        sellTeamFee = _sellTeamFee;
    }
        
    function _tokenTransfer(address sender, address recipient, uint256 amount) private {
        _transferStandard(sender, recipient, amount);
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        bool buying = false;

        if (sender == uniswapV2Pair) {
            buying = true;
        }

        bool selling = false;

        if (recipient == uniswapV2Pair) {
            selling = true;
        }

        ValuesFromAmount memory values = _getValues(tAmount, buying, selling);
        
        _rOwned[sender] = _rOwned[sender].sub(values.rAmount);

        if (isExcludedFromFee[sender] || isExcludedFromFee[recipient]) {
            _rOwned[recipient] = _rOwned[recipient].add(values.rAmount); 

            emit Transfer(sender, recipient, tAmount);
        } else {
            _rOwned[recipient] = _rOwned[recipient].add(values.rTransferAmount);
            emit Transfer(sender, recipient, values.tTransferAmount);

            _takeETH(values.tTeam, values.tLiquidity);
            emit Transfer(sender, address(this), values.tTeam.add(values.tLiquidity));

            _reflectFee(values.rReflect, values.tReflect);
        }
    }

    function _takeETH(uint256 tTeam, uint256 tLiquidity) private {
        uint256 currentRate = _getRate();
        uint256 rAmount = tTeam.add(tLiquidity).mul(currentRate);

        _rOwned[address(this)] = _rOwned[address(this)].add(rAmount);

        liqPending = liqPending.add(tLiquidity);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    receive() external payable {}

    function _getValues(uint256 tAmount, bool buying, bool selling) private view returns (ValuesFromAmount memory) {
        ValuesFromAmount memory values;
        values.amount = tAmount;

        if (buying) {
            values.tReflect = tAmount.mul(buyReflectionFee).div(100);
            values.tTeam = tAmount.mul(buyTeamFee).div(100);
            values.tLiquidity = tAmount.mul(buyLiquidityFee).div(100);
        } else if (selling) {
            values.tReflect = tAmount.mul(sellReflectionFee).div(100);
            values.tTeam = tAmount.mul(sellTeamFee).div(100);
            values.tLiquidity = tAmount.mul(sellLiquidityFee).div(100);
        }
        
        values.tTransferAmount = tAmount.sub(values.tReflect).sub(values.tTeam).sub(values.tLiquidity);

        uint256 currentRate = _getRate();

        values.rAmount = tAmount.mul(currentRate);
        values.rReflect = values.tReflect.mul(currentRate);
        values.rTeam = values.tTeam.mul(currentRate);
        values.rLiquidity = values.tLiquidity.mul(currentRate);
        values.rTransferAmount = values.rAmount.sub(values.rReflect).sub(values.rTeam).sub(values.rLiquidity);

        return values;
    }

	function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
}