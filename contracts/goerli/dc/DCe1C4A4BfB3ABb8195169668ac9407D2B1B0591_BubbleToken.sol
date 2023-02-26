/**
 *Submitted for verification at Etherscan.io on 2023-02-25
*/

/**
 *Submitted for verification at Etherscan.io on 2022-12-10
*/

/**
▄▄███▄▄·██████╗ ██╗   ██╗██████╗ 
██╔════╝██╔══██╗██║   ██║██╔══██╗
███████╗██████╔╝██║   ██║██████╔╝
╚════██║██╔══██╗██║   ██║██╔══██╗
███████║██████╔╝╚██████╔╝██████╔╝
╚═▀▀▀══╝╚═════╝  ╚═════╝ ╚═════╝ 
 */

// SPDX-License-Identifier:MIT
pragma solidity ^0.8.10;

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
interface IDexFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

// Dex Router contract interface
interface IDexRouter {
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

contract BubbleToken is Context, IERC20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) public isExcludedFromFee;
    mapping(address => bool) public isExcludedFromMaxTxn;
    mapping(address => bool) public isExcludedFromMaxHolding;
    mapping(address => bool) public isBot;
    mapping(address => bool) public dexPair;

    string private _name = "Bubble";
    string private _symbol = "$BUB";
    uint8 private _decimals = 9;
    uint256 private _totalSupply = 100 * 1e6 * 1e9;

    address private constant DEAD = address(0xdead);
    address private constant ZERO = address(0);
    IDexRouter public dexRouter;
    address public lpWallet;
    address[] public dexPairs;

    uint256 public minTokenToSwap = _totalSupply.div(1e5); // this amount will trigger swap and distribute
    uint256 public maxHoldLimit = _totalSupply.mul(2).div(100); // this is the max wallet holding limit
    uint256 public maxTxnLimit = _totalSupply.mul(2).div(100); // this is the max transaction limit
    uint256 public percentDivider = 1000;
    uint256 public launchedAt;
    uint256 public snipingTime = 40 seconds;

    bool public distributeAndLiquifyStatus; // should be true to turn on to liquidate the pool
    bool public feesStatus; // enable by default
    bool public trading; // once enable can't be disable afterwards

    uint256 public devFeeOnBuying = 20; // 2% will be added to the development address
    uint256 public liquidityFeeOnBuying = 10; // 1% will be added to the liquidity

    uint256 public devFeeOnSelling = 20; // 2% will be added to the development address
    uint256 public liquidityFeeOnSelling = 10; // 1% will be added to the liquidity

    uint256 liquidityFeeCounter = 0;
    uint256 devFeeCounter = 0;

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    constructor() {
        _balances[owner()] = _totalSupply;
        lpWallet = address(0xAdd);

        IDexRouter _dexRouter = IDexRouter(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        // Create a dex pair for this new ERC20
        address _dexPair = IDexFactory(_dexRouter.factory()).createPair(
            address(this),
            _dexRouter.WETH()
        );
        dexPairs.push(_dexPair);
        dexPair[_dexPair] = true;

        // set the rest of the contract variables
        dexRouter = _dexRouter;

        //exclude owner and this contract from fee
        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[address(this)] = true;

        //exclude owner and this contract from max Txn
        isExcludedFromMaxTxn[owner()] = true;
        isExcludedFromMaxTxn[address(this)] = true;

        //exclude owner and this contract from max hold limit
        isExcludedFromMaxHolding[owner()] = true;
        isExcludedFromMaxHolding[address(this)] = true;
        isExcludedFromMaxHolding[_dexPair] = true;
        isExcludedFromMaxHolding[lpWallet] = true;

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
                "$BUB: transfer amount exceeds allowance"
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
                "$BUB: decreased allowance below zero"
            )
        );
        return true;
    }

    function includeOrExcludeFromFee(address account, bool value)
        external
        onlyOwner
    {
        isExcludedFromFee[account] = value;
    }

    function includeOrExcludeFromMaxTxn(address account, bool value)
        external
        onlyOwner
    {
        isExcludedFromMaxTxn[account] = value;
    }

    function includeOrExcludeFromMaxHolding(address account, bool value)
        external
        onlyOwner
    {
        isExcludedFromMaxHolding[account] = value;
    }

    function addOrRemoveBots(address[] memory accounts, bool value)
        external
        onlyOwner
    {
        for (uint256 i; i < accounts.length; i++) {
            require(
                accounts[i] != address(dexRouter) && !dexPair[accounts[i]],
                "$BUB: cannot blacklist Dex"
            );
            isBot[accounts[i]] = value;
        }
    }

    function setMinTokenToSwap(uint256 _amount) external onlyOwner {
        minTokenToSwap = _amount;
    }

    function setMaxHoldLimit(uint256 _amount) external onlyOwner {
        require(_amount >= 100e9, "$BUB: should be greater than 100 $BUB");
        maxHoldLimit = _amount;
    }

    function setMaxTxnLimit(uint256 _amount) external onlyOwner {
        require(_amount >= 100e9, "$BUB: should be greater than 100 $BUB");
        maxTxnLimit = _amount;
    }

    function setBuyFeePercent(uint256 _devFee, uint256 _lpFee)
        external
        onlyOwner
    {
        devFeeOnBuying = _devFee;
        liquidityFeeOnBuying = _lpFee;
        require(
            _devFee.add(_lpFee) <= percentDivider.mul(3).div(10),
            "$BUB: can't be more than 30%"
        );
    }

    function setSellFeePercent(uint256 _devFee, uint256 _lpFee)
        external
        onlyOwner
    {
        devFeeOnSelling = _devFee;
        liquidityFeeOnSelling = _lpFee;
        require(
            _devFee.add(_lpFee) <= percentDivider.mul(3).div(10),
            "$BUB: can't be more than 30%"
        );
    }

    function setDistributionStatus(bool _value) public onlyOwner {
        distributeAndLiquifyStatus = _value;
    }

    function enableOrDisableFees(bool _value) external onlyOwner {
        feesStatus = _value;
    }

    function updateAddress(address _lpWallet) external onlyOwner {
        lpWallet = _lpWallet;
    }

    function addDexPair(address _newPair) external onlyOwner {
        dexPair[_newPair] = true;
        dexPairs.push(_newPair);
    }

    function removeDexPair(address _oldPair, uint256 _pairIndex)
        external
        onlyOwner
    {
        dexPair[_oldPair] = false;
        delete dexPairs[_pairIndex];
    }

    function enableTrading() external onlyOwner {
        require(!trading, "$BUB: already enabled");
        trading = true;
        feesStatus = true;
        distributeAndLiquifyStatus = true;
        launchedAt = block.timestamp;
    }

    function totalBuyFeePerTx(uint256 amount) public view returns (uint256) {
        uint256 fee = amount.mul(devFeeOnBuying.add(liquidityFeeOnBuying)).div(
            percentDivider
        );
        return fee;
    }

    function totalSellFeePerTx(uint256 amount) public view returns (uint256) {
        uint256 fee = amount
            .mul(devFeeOnSelling.add(liquidityFeeOnSelling))
            .div(percentDivider);
        return fee;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "$BUB: approve from the zero address");
        require(spender != address(0), "$BUB: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "$BUB: transfer from the zero address");
        require(to != address(0), "$BUB: transfer to the zero address");
        require(amount > 0, "$BUB: Amount must be greater than zero");
        require(!isBot[from], "$BUB: Bot detected");

        if (!isExcludedFromMaxTxn[from] && !isExcludedFromMaxTxn[to]) {
            require(amount <= maxTxnLimit, "$BUB: max txn limit exceeds");

            // trading disable till launch
            if (!trading) {
                require(
                    !dexPair[from] && !dexPair[to],
                    "$BUB: trading is disable"
                );
            }
            // antibot
            if (
                block.timestamp < launchedAt + snipingTime &&
                from != address(dexRouter)
            ) {
                if (dexPair[from]) {
                    isBot[to] = true;
                } else if (dexPair[to]) {
                    isBot[from] = true;
                }
            }
        }

        if (!isExcludedFromMaxHolding[to]) {
            require(
                balanceOf(to).add(amount) <= maxHoldLimit,
                "$BUB: max hold limit exceeds"
            );
        }

        // swap and liquify
        distributeAndLiquify(from, to);

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to isExcludedFromFee account then remove the fee
        if (isExcludedFromFee[from] || isExcludedFromFee[to] || !feesStatus) {
            takeFee = false;
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (dexPair[sender] && takeFee) {
            uint256 allFee = totalBuyFeePerTx(amount);
            uint256 tTransferAmount = amount.sub(allFee);
            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(tTransferAmount);

            emit Transfer(sender, recipient, tTransferAmount);
            takeTokenFee(sender, allFee);
            setFeeCountersOnBuying(amount);
        } else if (dexPair[recipient] && takeFee) {
            uint256 allFee = totalSellFeePerTx(amount);
            uint256 tTransferAmount = amount.sub(allFee);
            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(tTransferAmount);

            emit Transfer(sender, recipient, tTransferAmount);
            takeTokenFee(sender, allFee);
            setFeeCountersOnSelling(amount);
        } else {
            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(amount);

            emit Transfer(sender, recipient, amount);
        }
    }

    function takeTokenFee(address sender, uint256 amount) private {
        _balances[address(this)] = _balances[address(this)].add(amount);

        emit Transfer(sender, address(this), amount);
    }

    function setFeeCountersOnBuying(uint256 amount) private {
        liquidityFeeCounter += amount.mul(liquidityFeeOnBuying).div(
            percentDivider
        );
        devFeeCounter += amount.mul(devFeeOnBuying).div(percentDivider);
    }

    function setFeeCountersOnSelling(uint256 amount) private {
        liquidityFeeCounter += amount.mul(liquidityFeeOnSelling).div(
            percentDivider
        );
        devFeeCounter += amount.mul(devFeeOnSelling).div(percentDivider);
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
            !dexPair[from] &&
            distributeAndLiquifyStatus &&
            !(from == address(this) && dexPair[to]) // swap 1 time
        ) {
            // approve contract
            _approve(address(this), address(dexRouter), contractTokenBalance);

            uint256 halfLiquidity = liquidityFeeCounter.div(2);
            uint256 otherHalfLiquidity = liquidityFeeCounter.sub(halfLiquidity);

            uint256 tokenAmountToBeSwapped = contractTokenBalance.sub(
                otherHalfLiquidity
            );

            uint256 balanceBefore = address(this).balance;

            // now is to lock into liquidty pool
            Utils.swapTokensForEth(address(dexRouter), tokenAmountToBeSwapped);

            uint256 deltaBalance = address(this).balance.sub(balanceBefore);

            uint256 ethToBeAddedToLiquidity = deltaBalance
                .mul(halfLiquidity)
                .div(tokenAmountToBeSwapped);

            // add liquidity to Dex
            if (ethToBeAddedToLiquidity > 0) {
                Utils.addLiquidity(
                    address(dexRouter),
                    DEAD,
                    otherHalfLiquidity,
                    ethToBeAddedToLiquidity
                );

                emit SwapAndLiquify(
                    halfLiquidity,
                    ethToBeAddedToLiquidity,
                    otherHalfLiquidity
                );
            }

            uint256 ethForLp = address(this).balance.sub(
                ethToBeAddedToLiquidity
            );

            // sending Eth to development wallet
            if (ethForLp > 0) payable(lpWallet).transfer(ethForLp);

            // Reset all fee counters
            liquidityFeeCounter = 0;
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
        IDexRouter dexRouter = IDexRouter(routerAddress);

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
        IDexRouter dexRouter = IDexRouter(routerAddress);

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