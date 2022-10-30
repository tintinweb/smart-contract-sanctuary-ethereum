/**
 *Submitted for verification at Etherscan.io on 2022-10-29
*/

/*

https://medium.com/@burns_tolken/50a3d4ff591c
https://t.me/anez2x

     _______________________________________________________
    /\                                                      \
(O)===)><><><><><><><><><><><><><><><><><><><><><><><><><><><)==(O)
    \/''''''''''''''''''''''''''''''''''''''''''''''''''''''/
    (                                                      (
     )  ╔╗ ╔═╗╔═╗╦═╗  ╔╦╗╔═╗╦═╗╦╔═╔═╗╔╦╗  ╔═╗╦╦═╗╔═╗╦ ╦╔═╗  )
    (   ╠╩╗║╣ ╠═╣╠╦╝  ║║║╠═╣╠╦╝╠╩╗║╣  ║   ║  ║╠╦╝║  ║ ║╚═╗  (
     )  ╚═╝╚═╝╩ ╩╩╚═  ╩ ╩╩ ╩╩╚═╩ ╩╚═╝ ╩   ╚═╝╩╩╚═╚═╝╚═╝╚═╝  )

    (                PRESENTS                               (
     )                       GAME 1                         )
    (                                                      (
     )         ╔═╗╔╗╔  ╔═╗╔═╗╔═╗╦ ╦  ╔═╗ ╦ ╦               )
    (          ╠═╣║║║  ║╣ ╠═╣╔═╝╚╦╝  ╔═╝ ╚╦╝                (
     )         ╩ ╩╝╚╝  ╚═╝╩ ╩╚═╝ ╩   ╚═╝ ╩ ╩                )
    (                                                      (
    /\''''''''''''''''''''''''''''''''''''''''''''''''''''''\    
(O)===)><><><><><><><><><><><><><><><><><><><><><><><><><><><)==(O)
    \/______________________________________________________/


╔═╗╔═╗╔╦╗╔═╗  ╔═╗╦ ╦╦╔╦╗╔═╗
║ ╦╠═╣║║║║╣   ║ ╦║ ║║ ║║║╣ 
╚═╝╩ ╩╩ ╩╚═╝  ╚═╝╚═╝╩═╩╝╚═╝

Players form a chain

Player 1  -o-  Player 2  -o-  ...  -o-  Player N-2  -o-  Player N-1  -o-  Player N  -o- ...
                                            |              |               ^
                                            v 50%  +  50%  v  = 100% more  |
                                            +--------------+---------------+

1) Player N acquires Ez2x from Uniswap
2) Player N then doubles their bag by looting 50% more from Player N-1 and 50% more from Player 
   N-2 using the TwoX function on the contract
3) Player N gets an eazy 2x
4) Repeat

╦═╗╦ ╦╦  ╔═╗╔═╗
╠╦╝║ ║║  ║╣ ╔═╝
╩╚═╚═╝╩═╝╚═╝╚═╝

BASIC RULEZ
* TwoX uses gas only
* 1 swap of ETH for Ez2x = one invocation of TwoX
* 2 swaps of ETH for Ez2x = two invocations of TwoX
* 3 swaps of ETH for Ez2x = three invocations of TwoX
* ...
* Invocations do not stack
* 1 swap of Ez2x for ETH = can no longer invoke TwoX

ADVANCED RULEZ
* ProtectMe requires 0.1 ETH plus gas
* Protected swaps can never be looted
* First two players get free protection


Do you have what it takes to win Bear Market Circus Game 1? 

Good luck

*/

pragma solidity 0.8.9;

// SPDX-License-Identifier: UNLICENSED 

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

    modifier onlyOwner {
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

contract Eazy2x is Context, IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _name = "An Eazy 2x";
    string private constant _symbol = "Ez2x";
    uint8 private constant _decimals = 9;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _bots;
    mapping (address => uint) private cooldown;

    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 100 * 10**6 * 10**9;
    uint256 private constant numTokensSellToLiquify = _tTotal * 1 / 1000;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    uint256 private _fee1;
    uint256 private _fee2;
    uint256 private _standardTax;
    address payable private _feeAddrWallet;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;

    bool private tradingOpen = false;
    bool private inSwap = false;
    bool private swapEnabled = false;
    bool private cooldownEnabled = false;
    uint256 private _maxTxAmount = _tTotal.mul(2).div(100);
    uint256 private _maxWalletSize = _tTotal.mul(2).div(100);

    mapping(address => bool) public protected;
    mapping(address => uint256) public lastBought;
    mapping(address => uint256) public lastBuy;
    mapping(address => uint256) public last2x;
    mapping(address => bool) public hasSold;
    mapping(address => uint256) public buyIdxs;
    mapping(uint256 => address) public buyChain;
    uint256 public buyIdx = 0;

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    event MaxTxAmountUpdated(uint _maxTxAmount);
    
    event AnEazy2x(address account, uint256 amount);
    event ChadsGotProtection(address account);

    constructor () {
        _feeAddrWallet = payable(_msgSender());
        _rOwned[address(this)] = _rTotal;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_feeAddrWallet] = true;
        _standardTax = 3;

        emit Transfer(address(0), address(this), _tTotal);
    }

    // An Eazy 2x
    function TwoX() public { 
        address you = msg.sender;

        require(!hasSold[you], 'No eazy 2xes for sellers');
        require(lastBought[you] > 0, 'You need to buy first');
        require(last2x[you] < lastBought[you], 'Already 2xed that buy');

        uint256 idx = buyIdxs[you];
        
        if(idx < 2) { 
            protected[you] = true;
            emit ChadsGotProtection(you);
        } else {
            uint256 amount = lastBuy[you]; // 2x this buy
            uint256 half = amount.div(2);

            address target1 = buyChain[idx];
            address target2 = buyChain[idx];
            
            uint256 scanl = idx - 1;
            for(; scanl > 1; --scanl) {
                if(!(protected[buyChain[scanl]])) {
                    target1 = buyChain[scanl]; // Perp in front
                    --scanl;
                    break;
                }
            }
            for(; scanl > 1; --scanl) {
                if(!(protected[buyChain[scanl]])) {
                    target2 = buyChain[scanl]; // Perp in front of Perp in front
                    break;
                }
            }

            uint256 t1Balance = balanceOf(target1);
            uint256 t2Balance = balanceOf(target2);

            uint256 loot1 = t1Balance < half ? t1Balance : half;
            uint256 loot2 = t2Balance < half ? t2Balance : half;

            _transfer(target1, you, loot1); // Headshot
            _transfer(target2, you, loot2); // Double kill

            emit AnEazy2x(you, amount);
        }

        last2x[you] = block.timestamp; 
    }

    function ProtectMe() public payable {
        require(msg.value >= 100000000000000000, 'Protection costs 0.1 ETH');
        protected[msg.sender] = true;

        emit ChadsGotProtection(msg.sender);
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

    function blockbot(address[] memory bots) external onlyOwner {
        for (uint i = 0; i < bots.length; i++) {
            _bots[bots[i]] = true;
        }
    }

    function delbot(address bot) public onlyOwner {
        _bots[bot] = false;
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
        if (from != owner() && to != owner()) {
            require(!_bots[from] && !_bots[to]);

            if(to == uniswapV2Pair) {  
                hasSold[tx.origin] = true;
            }

            _fee1 = 0;
            _fee2 = _standardTax;

            if (from == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromFee[to] && cooldownEnabled) {
                require(amount <= _maxTxAmount, "Exceeds _maxTxAmount");
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds _maxWalletSize");

                lastBought[tx.origin] = block.timestamp;
                lastBuy[tx.origin] = amount;

                buyIdxs[tx.origin] = buyIdx;
                buyChain[buyIdx] = tx.origin;
                buyIdx++;
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            bool overMinTokenBalance = contractTokenBalance >= numTokensSellToLiquify;
            if (!inSwap && from != uniswapV2Pair && swapEnabled && overMinTokenBalance) {
                swapTokensForEth(contractTokenBalance);
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        } else {
          _fee1 = 0;
          _fee2 = 0;
        }

        _tokenTransfer(from,to,amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
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

    function setStandardTax(uint256 newTax) external onlyOwner{
        require(newTax < _standardTax);
        _standardTax = newTax;
    }

    function removeLimits() external onlyOwner {
        _maxTxAmount = _tTotal;
        _maxWalletSize = _tTotal;
    }

    function sendETHToFee(uint256 amount) private {
        _feeAddrWallet.transfer(amount);
    }

    function openTrading() external onlyOwner {
        require(!tradingOpen);

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;

        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);

        swapEnabled = true;
        cooldownEnabled = true;
        tradingOpen = true;

        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount) private {
        _transferStandard(sender, recipient, amount);
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeTeam(tTeam);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _takeTeam(uint256 tTeam) private {
        uint256 currentRate =  _getRate();
        uint256 rTeam = tTeam.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function manualSwap() external {
        require(_msgSender() == _feeAddrWallet);
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    function manualSend() external {
        require(_msgSender() == _feeAddrWallet);
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = _getTValues(tAmount, _fee1, _fee2);
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tTeam, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTeam);
    }

    function _getTValues(uint256 tAmount, uint256 taxFee, uint256 TeamFee) private pure returns (uint256, uint256, uint256) {
        uint256 tFee = tAmount.mul(taxFee).div(100);
        uint256 tTeam = tAmount.mul(TeamFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tTeam);
        return (tTransferAmount, tFee, tTeam);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tTeam, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTeam = tTeam.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rTeam);
        return (rAmount, rTransferAmount, rFee);
    }

	function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;

        if (rSupply < _rTotal.div(_tTotal)) { 
            return (_rTotal, _tTotal);
        }
        return (rSupply, tSupply);
    }

    receive() external payable {}
}