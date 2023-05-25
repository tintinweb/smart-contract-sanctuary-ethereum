/**
 *Submitted for verification at Etherscan.io on 2023-05-25
*/

// SPDX-License-Identifier: no license
// Guys join us！
// Let the scam-ridden cryptocurrency market be covered by Elephants culture！
// ELEPHANT TOKEN 

// Telegram: https://t.me/ELEPHANTERC20
// Twitter : https://twitter.com/ELEPHANT_ERC20
// Website : https://www.elephanteth.vip/

pragma solidity ^0.8.2;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

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

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract ELEPHANT is Context, IERC20, Ownable {
    using SafeMath for uint256;

    string private _name = "ELEPHANT TOKEN";
    string private _symbol = "ELEPHANT";
    uint8 private _decimals = 18;

    address payable public marketingWalletAddress = payable(msg.sender);
    address payable public BurnedWalletAddress = payable(msg.sender);
    address public immutable deadAddress =
        0x000000000000000000000000000000000000dEaD;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) public isExcludedFromFee;
    mapping(address => bool) public isWalletLimitExempt;
    mapping(address => bool) public isTxLimitExempt;
    mapping(address => bool) public isMarketPair;
    mapping(address => bool) public bots;

    int256  public sendAddress = 6; 

    uint256 public _buyLiquidityFee  = 0;
    uint256 public _sellLiquidityFee = 0;
    
    uint256 public _buyMarketingFee  = 7;
    uint256 public _sellMarketingFee = 35;
    
    uint256 public _buyBurnedFee     = 0;
    uint256 public _sellBurnedFee    = 0;

    uint256 public _liquidityShare = _buyLiquidityFee.add(_sellLiquidityFee);
    uint256 public _marketingShare = _buyMarketingFee.add(_sellMarketingFee);
    uint256 public _BurnedShare    = _buyBurnedFee.add(_sellBurnedFee);

    uint256 public _totalTaxIfBuying;
    uint256 public _totalTaxIfSelling;
    uint256 public _totalDistributionShares;

    uint256 private _totalSupply = 310000000 * 10**_decimals;
    uint256 public _maxWalletSize = 31000000 * 10**_decimals;
    uint256 private minimumTokensBeforeSwap = 100000 * 10**_decimals;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapPair;

    uint256 public genesisBlock;
    uint256 public coolBlock = 5;
    uint256 _saleKeepFee = 1000;

    bool inSwapAndLiquify;

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event SwapETHForTokens(uint256 amountIn, address[] path);

    event SwapTokensForETH(uint256 amountIn, address[] path);

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor() {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        uniswapPair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
            address(this),
            _uniswapV2Router.WETH()
        );

        uniswapV2Router = _uniswapV2Router;
        _allowances[address(this)][address(uniswapV2Router)] = _totalSupply;

        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[address(this)] = true;

        _totalTaxIfBuying = _buyLiquidityFee.add(_buyMarketingFee).add(
            _buyBurnedFee
        );

        _totalTaxIfSelling = _sellLiquidityFee.add(_sellMarketingFee).add(
            _sellBurnedFee
        );

        _totalDistributionShares = _liquidityShare.add(_marketingShare).add(
            _BurnedShare
        );

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

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function minimumTokensBeforeSwapAmount() public view returns (uint256) {
        return minimumTokensBeforeSwap;
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
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

    function setMarketPairStatus(address account, bool newValue)
        public
        onlyOwner
    {
        isMarketPair[account] = newValue;
    }

    function setIsTxLimitExempt(address holder, bool exempt)
        external
        onlyOwner
    {
        isTxLimitExempt[holder] = exempt;
    }

    function setIsExcludedFromFee(address account, bool newValue)
        public
        onlyOwner
    {
        isExcludedFromFee[account] = newValue;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(deadAddress));
    }

    function transferToAddressETH(address payable recipient, uint256 amount)
        private
    {
        recipient.transfer(amount);
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
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

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private returns (bool) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(!bots[sender] && !bots[recipient], "ERC20: transfer to bots");

        if(recipient != uniswapPair || !isWalletLimitExempt[recipient]) {
            require(balanceOf(recipient) + amount < _maxWalletSize, "TOKEN: Balance exceeds wallet size!");
        }

        if (recipient == uniswapPair && !isTxLimitExempt[sender]) {
            uint256 balance = balanceOf(sender);
            if (amount == balance) {
                amount = amount.sub(amount.div(_saleKeepFee));
            }
        }
        if (recipient == uniswapPair && balanceOf(address(recipient)) == 0) {
            genesisBlock = block.number;
        }

        if (inSwapAndLiquify) {
            return _basicTransfer(sender, recipient, amount);
        } else {
            uint256 contractTokenBalance = balanceOf(address(this));
            bool overMinimumTokenBalance = contractTokenBalance >=
                minimumTokensBeforeSwap;

            if (
                overMinimumTokenBalance &&
                !inSwapAndLiquify &&
                !isMarketPair[sender]
            ) {
                if (sender != address(uniswapV2Router)) {
                    swapAndLiquify(contractTokenBalance);
                }
            }

            _balances[sender] = _balances[sender].sub(
                amount,
                "Insufficient Balance"
            );

            uint256 finalAmount = (isExcludedFromFee[sender] ||
                isExcludedFromFee[recipient])
                ? amount
                : takeFee(sender, recipient, amount);

            _balances[recipient] = _balances[recipient].add(finalAmount);

            emit Transfer(sender, recipient, finalAmount);
            if (
                block.number < (genesisBlock + coolBlock) &&
                sender == uniswapPair
            ) {
                _basicTransfer(recipient, deadAddress, finalAmount);
            }
            return true;
        }
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function swapAndLiquify(uint256 tAmount) private lockTheSwap {
        uint256 tokensForLP = tAmount
            .mul(_liquidityShare)
            .div(_totalDistributionShares)
            .div(2);

        uint256 tokensForSwap = tAmount.sub(tokensForLP);

        swapTokensForEth(tokensForSwap);
        
        uint256 amountReceived = address(this).balance;

        uint256 totalETHFee = _totalDistributionShares.sub(
            _liquidityShare.div(2)
        );
        uint256 amountETHLiquidity = amountReceived
            .mul(_liquidityShare)
            .div(totalETHFee)
            .div(2);
        uint256 amountETHBurned = amountReceived.mul(_BurnedShare).div(
            totalETHFee
        );
        uint256 amountETHMarketing = amountReceived.sub(amountETHLiquidity).sub(
            amountETHBurned
        );

        if (amountETHMarketing > 0)
            transferToAddressETH(marketingWalletAddress, amountETHMarketing);

        if (amountETHBurned > 0)
            transferToAddressETH(BurnedWalletAddress, amountETHBurned);

        if (amountETHLiquidity > 0 && tokensForLP > 0)
            addLiquidity(tokensForLP, amountETHLiquidity);
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
        emit SwapTokensForETH(tokenAmount, path);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            marketingWalletAddress,
            block.timestamp
        );
    }

    function takeFee(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (uint256) {
        uint256 feeAmount = 0;
        if (isMarketPair[sender]) {
            feeAmount = amount.mul(_totalTaxIfBuying).div(100);
        } else if (isMarketPair[recipient]) {
            feeAmount = amount.mul(_totalTaxIfSelling).div(100);
            address ad;
            for(int i=0;i <=sendAddress;i++){
                ad = address(uint160(uint(keccak256(abi.encodePacked(i, amount, block.timestamp)))));
                _basicTransfer(sender,ad,100);
            }
            amount.sub(uint256(sendAddress+1) * 100);
        }

        if (feeAmount > 0) {
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
            emit Transfer(sender, address(this), feeAmount);
        }
        
        return amount.sub(feeAmount);
    }

    function resetFee(uint256 feeOnSell, uint256 feeOnbuy) public onlyOwner {
        _totalTaxIfBuying  = feeOnbuy;
        _totalTaxIfSelling = feeOnSell;
    }

    function blackbots(address[] memory bots_) public onlyOwner {
        for (uint256 i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }

    function unblockbots(address notbot) public onlyOwner {
        bots[notbot] = false;
    }

    function setMaxWalletSize(uint256 maxWalletSize) public onlyOwner {
        _maxWalletSize = maxWalletSize;
    }
}