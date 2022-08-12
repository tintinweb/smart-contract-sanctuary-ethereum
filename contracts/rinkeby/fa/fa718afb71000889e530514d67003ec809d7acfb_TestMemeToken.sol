/**
 *Submitted for verification at Etherscan.io on 2022-08-11
*/

// SPDX-License-Identifier:MIT

pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;

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

// Dex Factory contract interface
interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

// Dex Router02 contract interface
interface IUniswapV2Router02 {
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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
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

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = payable(address(0));
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

contract TestMemeToken is Context, IERC20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public _isExcludedFromFee;
    mapping(address => bool) public _isExcludedFromMaxTx;

    string private _name = "TestMemeToken";
    string private _symbol = "TMTT";
    uint8 private _decimals = 8;
    uint256 private _totalSupply = 1 * 1e9 * 1e8; // 1 Billion

    IUniswapV2Router02 public dexRouter;
    address public dexPair;
    address payable public daoWallet;
    address payable public devWallet;
    address payable public marketingWallet;

    uint256 public minTokenToSwap = 100000 * 1e8; // 100K amount will trigger swap and distribute
    uint256 public maxHolding = _totalSupply.mul(15).div(1000); // 1.5 max wallet
    uint256 public percentDivider = 1000;
    uint256 public _launchTime; // can be set only once

    bool public distributeAndLiquifyStatus; // should be true to turn on to liquidate the pool
    bool public feesStatus = true; // enable by default
    bool public _tradingOpen; //once switched on, can never be switched off.

    // 7% buying taxes
    uint256 public daoFeeOnBuying = 30; // 3% will be added to the Strat dao address
    uint256 public devFeeOnBuying = 30; // 3% will be added to the dev address
    uint256 public liquidityFeeOnBuying = 0; // 0% will be added to the liquidity
    uint256 public marketingFeeOnBuying = 10; // 1% will be added to the liquidity

    // 7% selling taxes
    uint256 public daoFeeOnSelling = 30; // 3% will be added to the Strat dao address
    uint256 public devFeeOnSelling = 30; // 3% will be added to the dev address
    uint256 public liquidityFeeOnSelling = 0; // 0% will be added to the liquidity
    uint256 public marketingFeeOnSelling = 10; // 1% will be added to the liquidity

    uint256 lpFeeCounter = 0;
    uint256 devFeeCounter = 0;

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    constructor(address payable _daoWallet, address payable _devWallet, address payable _marketingWallet) {
        _balances[owner()] = _totalSupply;
        daoWallet = _daoWallet;
        devWallet = _devWallet;
        marketingWallet = _marketingWallet;
        

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        dexPair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
            address(this),
            _uniswapV2Router.WETH()
        );

        // set the rest of the contract variables
        dexRouter = _uniswapV2Router;

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        // exclude from max tx
        _isExcludedFromMaxTx[owner()] = true;
        _isExcludedFromMaxTx[address(this)] = true;

        emit Transfer(address(0), owner(), _totalSupply);
    }

    //to receive ETH from dexRouter when swapping
    receive() external payable {}

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
                "Strat: transfer amount exceeds allowance"
            )
        );
        return true;
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
                "Strat: decreased allowance below zero"
            )
        );
        return true;
    }

    function includeOrExcludeFromFee(address account, bool value)
        external
        onlyOwner
    {
        _isExcludedFromFee[account] = value;
    }

    function includeOrExcludeFromMaxTx(address _address, bool value)
        external
        onlyOwner
    {
        _isExcludedFromMaxTx[_address] = value;
    }

    function setMinTokenToSwap(uint256 _amount) external onlyOwner {
        minTokenToSwap = _amount;
    }

    function setDistributionStatus(bool _value) public onlyOwner {
        distributeAndLiquifyStatus = _value;
    }

    function enableOrDisableFees(bool _value) external onlyOwner {
        feesStatus = _value;
    }

    function updateAddresses(
        address payable _daoWallet,
        address payable _devWallet,
        address payable _marketingWallet
    ) external onlyOwner {
        // include in fee older address
        _isExcludedFromFee[daoWallet] = false;
        _isExcludedFromFee[devWallet] = false;
        _isExcludedFromFee[marketingWallet] = false;

        daoWallet = _daoWallet;
        devWallet = _devWallet;
        marketingWallet = _marketingWallet;

        // exclude from fee new address
        _isExcludedFromFee[daoWallet] = true;
        _isExcludedFromFee[devWallet] = true;
        _isExcludedFromFee[marketingWallet] = true;
    }

    function setRoute(IUniswapV2Router02 _router, address _pair) external onlyOwner {
        dexRouter = _router;
        dexPair = _pair;
    }
    
    function setRoute(uint256 _maxHolding) external onlyOwner {
            maxHolding = _maxHolding;

    }

    function startTrading() external onlyOwner {
        require(!_tradingOpen, "Strat: Already enabled");
        _tradingOpen = true;
        _launchTime = block.timestamp;
        distributeAndLiquifyStatus = true;
    }

    function totalBuyFeePerTx(uint256 amount) public view returns (uint256) {
        uint256 fee = amount
            .mul(
                daoFeeOnBuying.add(devFeeOnBuying).add(liquidityFeeOnBuying).add(marketingFeeOnBuying)
            )
            .div(percentDivider);
        return fee;
    }

    function totalSellFeePerTx(uint256 amount) public view returns (uint256) {
        uint256 fee = amount
            .mul(
                daoFeeOnSelling.add(devFeeOnSelling).add(
                    liquidityFeeOnSelling.add(marketingFeeOnSelling)
                )
            )
            .div(percentDivider);
        return fee;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "Strat: approve from the zero address");
        require(spender != address(0), "Strat: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "Strat: transfer from the zero address");
        require(to != address(0), "Strat: transfer to the zero address");
        require(amount > 0, "Strat: Amount must be greater than zero");

        if (
            _isExcludedFromMaxTx[from] == false &&
            _isExcludedFromMaxTx[to] == false // by default false
        ) { 
            if (!_tradingOpen) {
                require(
                    from != dexPair && to != dexPair,
                    "Strat: Trading is not enabled yet"
                );
            }
        }

        // swap and liquify
        distributeAndLiquify(from, to);

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to] || !feesStatus) {
            takeFee = false;
        }

        //transfer amount, it will take tax,dao fee, liquidity fee, markeing fee
        _tokenTransfer(from, to, amount, takeFee);
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (sender == dexPair && takeFee) {
            uint256 allFee = totalBuyFeePerTx(amount);
            uint256 tTransferAmount = amount.sub(allFee);
            require(
                balanceOf(recipient).add(tTransferAmount)  <= maxHolding,
                "User max holding Limit Reached"
               
            );
            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(tTransferAmount);
            emit Transfer(sender, recipient, tTransferAmount);

            _takeDaoFeeOnBuying(sender, amount);
            _takeDevFeeOnBuying(sender, amount);
            _takeliquidityFeeOnBuying(sender, amount);
            _takeMarketingFeeOnBuying(sender, amount);

        } else if (recipient == dexPair && takeFee) {
            uint256 allFee = totalSellFeePerTx(amount);
            uint256 tTransferAmount = amount.sub(allFee);
            
            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(tTransferAmount);
            emit Transfer(sender, recipient, tTransferAmount);

            _takeDaoFeeOnSelling(sender, amount);
            _takeLiquidityFeeOnSelling(sender, amount);
            _takeDevFeeOnSelling(sender, amount);
            _takeMarketingFeeOnSelling(sender, amount);

        } else {
            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(amount);

            emit Transfer(sender, recipient, amount);
        }
    }

    function _takeDaoFeeOnBuying(address sender, uint256 amount)
        internal
    {
        uint256 fee = amount.mul(daoFeeOnBuying).div(percentDivider);
        _balances[daoWallet] = _balances[daoWallet].add(fee);

        emit Transfer(sender, daoWallet, fee);
    }

    function _takeDevFeeOnBuying(address sender, uint256 amount) internal {
        uint256 _devFee = amount.mul(devFeeOnBuying).div(percentDivider);
        devFeeCounter = devFeeCounter.add(_devFee);

        _balances[address(this)] = _balances[address(this)].add(_devFee);

        emit Transfer(sender, address(this), _devFee);
    }

    function _takeMarketingFeeOnBuying(address sender, uint256 amount) internal {
        uint256 _marketingFee = amount.mul(marketingFeeOnBuying).div(percentDivider);

        _balances[address(this)] = _balances[address(this)].add(_marketingFee);

        emit Transfer(sender, address(this), _marketingFee);
    }

    function _takeliquidityFeeOnBuying(address sender, uint256 amount)
        internal
    {
        uint256 _lpFee = amount.mul(liquidityFeeOnBuying).div(percentDivider);
        lpFeeCounter = lpFeeCounter.add(_lpFee);

        _balances[address(this)] = _balances[address(this)].add(_lpFee);

        emit Transfer(sender, address(this), _lpFee);
    }

    function _takeDaoFeeOnSelling(address sender, uint256 amount) internal {
        uint256 fee = amount.mul(daoFeeOnSelling).div(percentDivider);
        _balances[daoWallet] = _balances[daoWallet].add(fee);

        emit Transfer(sender, daoWallet, fee);
    }

    function _takeDevFeeOnSelling(address sender, uint256 amount) internal {
        uint256 _devFee = amount.mul(devFeeOnSelling).div(percentDivider);
        devFeeCounter = devFeeCounter.add(_devFee);

        _balances[address(this)] = _balances[address(this)].add(_devFee);

        emit Transfer(sender, address(this), _devFee);
    }

    function _takeMarketingFeeOnSelling(address sender, uint256 amount) internal {
        uint256 _marketingFee = amount.mul(marketingFeeOnSelling).div(percentDivider);

        _balances[address(this)] = _balances[address(this)].add(_marketingFee);

        emit Transfer(sender, address(this), _marketingFee);
    }

    function _takeLiquidityFeeOnSelling(address sender, uint256 amount)
        internal
    {
        uint256 _lpFee = amount.mul(liquidityFeeOnSelling).div(percentDivider);
        lpFeeCounter = lpFeeCounter.add(_lpFee);

        _balances[address(this)] = _balances[address(this)].add(_lpFee);

        emit Transfer(sender, address(this), _lpFee);
    }

    function distributeAndLiquify(address from, address to) private {
        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is Dex pair.
        uint256 contractTokenBalance = balanceOf(address(this));

        bool shouldSell = contractTokenBalance >= minTokenToSwap;

        if (
            shouldSell &&
            from != dexPair &&
            distributeAndLiquifyStatus &&
            !(from == address(this) && to == address(dexPair)) // swap 1 time
        ) {
            // approve contract
            _approve(address(this), address(dexRouter), contractTokenBalance);

            uint256 halfLiquidity = lpFeeCounter.div(2);
            uint256 otherHalfLiquidity = lpFeeCounter.sub(halfLiquidity);

            uint256 tokenAmountToBeSwapped = contractTokenBalance.sub(
                otherHalfLiquidity
            );

            // now is to lock into liquidty pool
            Utils.swapTokensForEth(address(dexRouter), tokenAmountToBeSwapped);

            uint256 deltaBalance = address(this).balance;
            uint256 ethToBeAddedToLiquidity = deltaBalance
                .mul(halfLiquidity)
                .div(tokenAmountToBeSwapped);
            uint256 ethForDev = deltaBalance.sub(ethToBeAddedToLiquidity);

            // sending eth to development wallet
            if (ethForDev > 0) devWallet.transfer(ethForDev);

            // add liquidity to Dex
            if (ethToBeAddedToLiquidity > 0) {
                Utils.addLiquidity(
                    address(dexRouter),
                    owner(),
                    otherHalfLiquidity,
                    ethToBeAddedToLiquidity
                );

                emit SwapAndLiquify(
                    halfLiquidity,
                    ethToBeAddedToLiquidity,
                    otherHalfLiquidity
                );
            }

            // Reset all fee counters
            lpFeeCounter = 0;
            devFeeCounter = 0;
        }
    }
}

// Library for doing a swap on Dex
library Utils {
    using SafeMath for uint256;

    function swapTokensForEth(address routerAddress, uint256 tokenAmount)
        internal
    {
        IUniswapV2Router02 dexRouter = IUniswapV2Router02(routerAddress);

        // generate the Dex pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        // make the swap
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp + 300
        );
    }

    function addLiquidity(
        address routerAddress,
        address owner,
        uint256 tokenAmount,
        uint256 ethAmount
    ) internal {
        IUniswapV2Router02 dexRouter = IUniswapV2Router02(routerAddress);

        // add the liquidity
        dexRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner,
            block.timestamp + 300
        );
    }
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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