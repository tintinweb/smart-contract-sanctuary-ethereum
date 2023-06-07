/**
 *Submitted for verification at Etherscan.io on 2023-06-06
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

 
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }


    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

 
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
interface IERC20 {
   
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount)external returns (bool);
    function allowance(address owner, address spender)external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner,address indexed spender,uint256 value);
}


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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


contract GenTokenCon is IERC20, Ownable {
    
    using SafeMath for uint256;

    string private _name = "GenToken";
    string private _symbol = "FGEN";
    uint8 private _decimals = 18;

    uint256 internal _totalSupply; 
    
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;
    
   IUniswapV2Router02 public  uniswapV2Router;
    address public  uniswapV2Pair;
    
    bool public isLiquidityAdded;
    uint256 public antiBotBlocks;
    uint256 public liquidityBotBlock;
    uint256 public taxPercentage;
    address public marketingWallet;

    uint256 public _buyFee; // 200 = 2.00%
    uint256 public _sellFee; // 100 = 1.00%
    uint256 public totalBuyingTax;
    uint256 public totalSellingTax;



    mapping(address => bool) public whiteListed;
    mapping(address => bool) isExcludedFromFee; 
    

    constructor(
         address[] memory wallets,
        uint256[] memory tokenAmounts,
        uint256 initialLiquidity,
        uint256 _buyTaxPercentage,
        uint256 _sellTaxPercentage,
        uint256 _antiBotBlocks,
        address _marketingWallet
    ) {

        require(wallets.length == tokenAmounts.length, "Invalid input");

        for (uint256 i = 0; i < wallets.length; i++) {
            _mint(wallets[i], tokenAmounts[i]);
        }

        _mint(address(this), initialLiquidity);

        _buyFee = _buyTaxPercentage * 100;
        _sellFee = _sellTaxPercentage * 100;
        antiBotBlocks = _antiBotBlocks;
        marketingWallet = _marketingWallet;
        isLiquidityAdded = false;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
  
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        
        uniswapV2Router = _uniswapV2Router;

        whiteListed[address(this)] = true;
        isExcludedFromFee[msg.sender] = true;
        isExcludedFromFee[address(this)] = true;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public override view returns (uint256) {
         return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override virtual returns (bool) {
       _transfer(msg.sender,recipient,amount);
        return true;
    }

    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override virtual returns (bool) {
        _transfer(sender,recipient,amount);
               
        _approve(sender,msg.sender,_allowances[sender][msg.sender].sub( amount,"ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _mint(address account, uint256 amount) public onlyOwner {
       
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
    }

    function _burn(address account, uint256 amount) public onlyOwner {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
            _balances[account] = accountBalance - amount;
            _totalSupply -= amount;
    }

    // function _transfer(
    //     address sender,
    //     address recipient,
    //     uint256 amount
    // ) internal virtual {
    //     require(sender != address(0), "ERC20: transfer from the zero address");
    //     require(recipient != address(0), "ERC20: transfer to the zero address");


    //     uint256 senderBalance = _balances[sender];
    //     require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
    //     unchecked {
    //         _balances[sender] = senderBalance - amount;
    //     }
    //     _balances[recipient] += amount;

    //     emit Transfer(sender, recipient, amount);

    // }

    function _transfer(address sender, address recipient, uint256 amount) private  {

        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        
        uint256 transferAmount = amount;
        
        if(isLiquidityAdded && block.number < liquidityBotBlock + antiBotBlocks){
            
            transferAmount = FullFee(sender,amount);
        }
        else if(whiteListed[sender] || whiteListed[recipient]){
            transferAmount = amount;     
        }
        else{

            if(isExcludedFromFee[sender] && isExcludedFromFee[recipient]){
                transferAmount = amount;
            }
            if(isExcludedFromFee[sender] && !isExcludedFromFee[recipient]){
                transferAmount = BuyFee(sender,amount);
            }
            if(!isExcludedFromFee[sender] && isExcludedFromFee[recipient]){
                transferAmount = SellFee(sender,amount);
            }
        }   
        
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        
        _balances[recipient] += transferAmount;

        emit Transfer(sender, recipient, transferAmount);
    }



    function addLiquidity( uint256 ethAmount) external payable {
        // approve token transfer to cover all possible scenarios

        uint256 tokenAmount = balanceOf(address(this));
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

        liquidityBotBlock = block.number;
        isLiquidityAdded = true;
    }

    function swapTokensForEth(uint256 tokenAmount) external onlyOwner {

        // add a require statement that balanceof(address(this) > zero

        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        
        // require that path.length == 2
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETH(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }


    function FullFee(address account, uint256 amount) public returns (uint256) {
        
        uint256 transferAmount = amount;

        uint256 _fullFee = 10000; // 100 %
        uint256 fullFee = amount * (_fullFee) / (10000);

        if (fullFee > 0){
            transferAmount = transferAmount - (fullFee);
            _balances[address(this)] = _balances[address(this)] + (fullFee);
            totalBuyingTax = totalBuyingTax + (fullFee);
            emit Transfer(account,address(this),fullFee);
        }
        return transferAmount;
     }


     function BuyFee(address account, uint256 amount) public returns (uint256) {
        
        uint256 transferAmount = amount;
        uint256 buyFee = amount * (_buyFee) / (10000);

        if (buyFee > 0){
            transferAmount = transferAmount - (buyFee);
            _balances[address(this)] = _balances[address(this)] + (buyFee);
            totalBuyingTax = totalBuyingTax + (buyFee);
            emit Transfer(account,address(this),buyFee);
        }
        return transferAmount;
     }

     function SellFee(address account, uint256 amount) public  returns (uint256) {
        
        uint256 transferAmount = amount;
        uint256 sellFee = amount * (_sellFee) / (10000);

        if (sellFee > 0){
            transferAmount = transferAmount - (sellFee);
            _balances[address(this)] = _balances[address(this)] + (sellFee);
            totalSellingTax = totalSellingTax + (sellFee);
            emit Transfer(account,address(this),sellFee);
        }
       
        return transferAmount;
    }


    function addInWhiteList(address account) public onlyOwner {
        whiteListed[account] = true;
    }

    function removeFromWhiteList(address account) public onlyOwner {
        whiteListed[account] = false;
    }

    function isWhiteListed(address _address) public view returns( bool _whitelisted){
        
        if(whiteListed[_address]){
            return true;
        }
        return false;
    }

    function ExcludedFromFee(address account) public onlyOwner {
        isExcludedFromFee[account] = true;
    }
    function IncludeInFee(address account) public onlyOwner {
        isExcludedFromFee[account] = false;
    }
    

    // function to allow admin to transfer ETH from this contract
    function TransferETH(address payable recipient, uint256 amount) public onlyOwner {
        recipient.transfer(amount);
    }

    modifier beforeliquidityNotAdded(address sender, address recipient) {
        
        if (sender != owner() && recipient != owner()){
            require(!isLiquidityAdded, "Liquidity already added");
        }
        _;
    }

    modifier liquidityAdded() {
        require(!isLiquidityAdded, "Liquidity already added.");
        _;
    }
    
    receive() external payable {}
}


// 0x1D375435c8EfA3e489ef002d2d0B1E7Eb3CC62Fe
// 0x210DB07c90e4979E481B917496a7e2A4e8770A07

// 0x1F811008eE5C9A3f9AD128571a0507Fe591A4043

// ["0x1D375435c8EfA3e489ef002d2d0B1E7Eb3CC62Fe","0x210DB07c90e4979E481B917496a7e2A4e8770A07"]

// [500000000000000000000,500000000000000000000]