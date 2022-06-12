/**
 *Submitted for verification at Etherscan.io on 2022-06-12
*/

/**
 *Submitted for verification at BscScan.com on 2022-04-02
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

abstract contract Context {

    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }


}

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor ()  {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
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

interface IUniswapV2Factory {


    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);

    function createPair(address tokenA, address tokenB) external returns (address pair);

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

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);


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

contract MetashToken is Context, IERC20, Ownable {

    using SafeMath for uint256;
    using Address for address;

    string private _name = "META SKINNY&HOPE";
    string private _symbol = "METASH";
    uint8 private _decimals = 18;

    //市场钱包地址
    address payable public marketingWalletAddress = payable(0x2E81994A67132e5A5AB0796aC778E5b2b2399131);
    //销毁钱包地址
    address payable public BurnedWalletAddress = payable(0x2E81994A67132e5A5AB0796aC778E5b2b2399131);
    //销毁地址
    address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) public isExcludedFromFee;
    mapping (address => bool) public isWalletLimitExempt;
    mapping (address => bool) public isTxLimitExempt;
    mapping (address => bool) public isMarketPair;

    //购买流动性费率
    uint256 public _buyLiquidityFee = 0;
    //购买市场费率
    uint256 public _buyMarketingFee = 2;
    //购买销毁费率
    uint256 public _buyBurnedFee = 0;
    //卖出流动性费率
    uint256 public _sellLiquidityFee = 0;
    //卖出市场费率
    uint256 public _sellMarketingFee = 2;
    //卖出销毁费率
    uint256 public _sellBurnedFee = 0;

    //流动性分享 = 购买流动性费率 + 卖出流动性费率
    uint256 public _liquidityShare = _buyLiquidityFee.add(_sellLiquidityFee);
    uint256 public _marketingShare =  _buyMarketingFee.add(_sellMarketingFee);
    uint256 public _BurnedShare = _buyBurnedFee.add(_sellBurnedFee);

    uint256 public _totalTaxIfBuying;
    uint256 public _totalTaxIfSelling;
    //总的分配股份
    uint256 public _totalDistributionShares;

    uint256 private _totalSupply = 10 * 10**8 * 10**_decimals;
    uint256 private minimumTokensBeforeSwap = 4880 * 10**_decimals;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapPair;

    //交易对初始化区块高度
    uint256 public genesisBlock;
    uint256 public coolBlock = 20;
    uint256 _saleKeepFee = 1000;

    bool inSwapAndLiquify;

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event SwapETHForTokens(
        uint256 amountIn,
        address[] path
    );

    event SwapTokensForETH(
        uint256 amountIn,
        address[] path
    );

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor () {

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        uniswapPair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        _allowances[address(this)][address(uniswapV2Router)] = _totalSupply;

        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[address(this)] = true;

        _totalTaxIfBuying = _buyLiquidityFee.add(_buyMarketingFee).add(_buyBurnedFee);
        _totalTaxIfSelling = _sellLiquidityFee.add(_sellMarketingFee).add(_sellBurnedFee);
        //总分配股份 = 流动性分享费率 + 市场分享费率 + 销毁分享费率
        _totalDistributionShares = _liquidityShare.add(_marketingShare).add(_BurnedShare);

        isWalletLimitExempt[owner()] = true;
        isWalletLimitExempt[address(uniswapPair)] = true;
        isWalletLimitExempt[address(this)] = true;

        isTxLimitExempt[owner()] = true;
        isTxLimitExempt[address(this)] = true;

        isMarketPair[address(uniswapPair)] = true;

        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
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

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function minimumTokensBeforeSwapAmount() public view returns (uint256) {
        return minimumTokensBeforeSwap;
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

    function setMarketPairStatus(address account, bool newValue) public onlyOwner {
        isMarketPair[account] = newValue;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }

    function setIsExcludedFromFee(address account, bool newValue) public onlyOwner {
        isExcludedFromFee[account] = newValue;
    }

    function setBuyMarketingFee(uint feeNum) public onlyOwner {
        _buyMarketingFee = feeNum;
    }

    function setSellMarketingFee(uint feeNum) public onlyOwner {
        _sellMarketingFee = feeNum;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(deadAddress));
    }

    function transferToAddressETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }


    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) private returns (bool) {

        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        //判断是否是交易对地址或者不是豁免地址
        if(recipient == uniswapPair && !isTxLimitExempt[sender])
        {
            //获取发送人余额
            uint256 balance = balanceOf(sender);
            //如果发送数量等于发送人余额
            if (amount == balance) {
                //卖出数量等于 卖出数量 - （卖出数量 / 卖出保留费率（_saleKeepFee默认1000））
                amount = amount.sub(amount.div(_saleKeepFee));
            }

        }

        //如果地址等于当前合约（token->eth）交易对地址，并且交易对地址余额为0
        if(recipient == uniswapPair && balanceOf(address(recipient)) == 0){
            //记录交易对初始化区块高度
            genesisBlock = block.number;
        }

        //锁
        if(inSwapAndLiquify)
        {
            //基础转账
            return _basicTransfer(sender, recipient, amount);
        }
        else
        {
            //获取合约余额
            uint256 contractTokenBalance = balanceOf(address(this));
            //合约余额大于最小允许代币数量
            bool overMinimumTokenBalance = contractTokenBalance >= minimumTokensBeforeSwap;

            //不是交易对地址并且没被锁并且合约余额大于分配余额，添加流动性
            if (overMinimumTokenBalance && !inSwapAndLiquify && !isMarketPair[sender])
            {
                //如果发起转账人不等于路由地址
                if(sender !=  address(uniswapV2Router))
                {
                    //交换添加流动性
                    swapAndLiquify(contractTokenBalance);
                }

            }

            //扣减发送人余额
            _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

            //（给合约添加余额）判断是否是排除手续费地址
            uint256 finalAmount = (isExcludedFromFee[sender] || isExcludedFromFee[recipient]) ?
            amount : takeFee(sender, recipient, amount);

            //接收人接收扣减后的余额
            _balances[recipient] = _balances[recipient].add(finalAmount);


            emit Transfer(sender, recipient, finalAmount);

            //当前区块高度小于创世区块高度+20 并且发送地址是交易对地址
            if (block.number < ( genesisBlock + coolBlock) && sender == uniswapPair )
            {
                //就会销毁转账的代币
                _basicTransfer(recipient,deadAddress, finalAmount);
            }
            return true;
        }
    }

    //基础转账
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    //交换添加流动性
    function swapAndLiquify(uint256 tAmount) private lockTheSwap {

        //拿出一半的流动性分享数量
        uint256 tokensForLP = tAmount.mul(_liquidityShare).div(_totalDistributionShares).div(2);
        //剩余另一半数量
        uint256 tokensForSwap = tAmount.sub(tokensForLP);
        //兑换ETH给合约
        swapTokensForEth(tokensForSwap);
        //获取当前合约eth数量
        uint256 amountReceived = address(this).balance;
        //
        uint256 totalBNBFee = _totalDistributionShares.sub(_liquidityShare.div(2));

        uint256 amountBNBLiquidity = amountReceived.mul(_liquidityShare).div(totalBNBFee).div(2);
        uint256 amountBNBBurned = amountReceived.mul(_BurnedShare).div(totalBNBFee);
        uint256 amountBNBMarketing = amountReceived.sub(amountBNBLiquidity).sub(amountBNBBurned);

        if(amountBNBMarketing > 0)
            transferToAddressETH(marketingWalletAddress, amountBNBMarketing);

        if(amountBNBBurned > 0)
            transferToAddressETH(BurnedWalletAddress, amountBNBBurned);

        if(amountBNBLiquidity > 0 && tokensForLP > 0)
            addLiquidity(tokensForLP, amountBNBLiquidity);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, //能接受的最小兑换数量
            path, //兑换路径
            address(this), // 兑换给谁
            block.timestamp //时间
        );
        emit SwapTokensForETH(tokenAmount, path);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // 限制交易恢复前代币上涨的数量
            0, // 限制代币恢复前eth上涨数量
            owner(),//接收流动性token人
            block.timestamp //时间搓再次时间之后会被恢复
        );
    }

    //手续费计算
    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = 0;
        //判断是否是交易对
        if(isMarketPair[sender]) {
            feeAmount = amount.mul(_totalTaxIfBuying).div(100);
        }
        else if(isMarketPair[recipient]) {
            feeAmount = amount.mul(_totalTaxIfSelling).div(100);
        }

        if(feeAmount > 0) {
            //手续费转给合约
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
            emit Transfer(sender, address(this), feeAmount);
        }

        return amount.sub(feeAmount);
    }

}