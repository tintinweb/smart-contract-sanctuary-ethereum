/**
 *Submitted for verification at Etherscan.io on 2023-06-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
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

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() external view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

interface IUniswapV2Router01 {
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
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IUniswapV2Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address);
}

contract FatToken is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public _swapRouter;
    address public _mainPair;
    bool private swapping;
    ETHBackDividendTracker public dividendTracker;

    address public deadWallet = 0x000000000000000000000000000000000000dEaD;

    address public ETH;

    uint256 public swapTokensAtAmount;

    mapping(address => bool) public _rewardList;

    uint256 public buy_marketingFee;
    uint256 public buy_liquidityFee;
    uint256 public buy_ETHRewardsFee;
    uint256 public buy_totalFees;
    uint256 public buy_burnFee;

    uint256 public sell_marketingFee;
    uint256 public sell_liquidityFee;
    uint256 public sell_ETHRewardsFee;
    uint256 public sell_totalFees;
    uint256 public sell_burnFee;

    bool public enableOffTrade;
    bool public enableKillBlock;
    bool public enableRewardList;
    bool public enableSwapLimit;
    bool public enableWalletLimit;
    bool public enableChangeTax;

    address public fundAddress;
    address public _swapRouterAddress;

    uint256 public kb = 0;
    uint256 public maxSellAmount;
    uint256 public maxBuyAmount;
    uint256 public maxWalletAmount;
    uint256 public startTradeBlock;
    uint256 public mushHoldNum;

    bool public isLaunch;

    uint256 public gasForProcessing = 300000;

    mapping(address => bool) public _feeWhiteList;

    mapping(address => bool) public _swapPairList;

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event SendDividends(uint256 tokensSwapped, uint256 amount);

    event ProcessedDividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed processor
    );

    constructor(
        string[] memory stringParams,
        address[] memory addressParams,
        uint256[] memory numberParams,
        bool[] memory boolParams
    ) ERC20(stringParams[0], stringParams[1]) {
        maxBuyAmount = numberParams[0];
        maxSellAmount = numberParams[1];
        require(
            maxSellAmount >= maxBuyAmount,
            " maxSell should be > than maxBuy "
        );
        maxWalletAmount = numberParams[2];

        buy_marketingFee = numberParams[3];
        buy_liquidityFee = numberParams[4];
        buy_ETHRewardsFee = numberParams[5];
        buy_totalFees = buy_ETHRewardsFee.add(buy_liquidityFee).add(
            buy_marketingFee
        );
        buy_burnFee = numberParams[6];

        sell_marketingFee = numberParams[7];
        sell_liquidityFee = numberParams[8];
        sell_ETHRewardsFee = numberParams[9];
        sell_totalFees = sell_ETHRewardsFee.add(sell_liquidityFee).add(
            sell_marketingFee
        );
        sell_burnFee = numberParams[10];

        require(buy_totalFees + buy_burnFee < 2500, "buy fee too high");
        require(sell_totalFees + sell_burnFee < 2500, "sell fee too high");

        uint256 __totalSupply = numberParams[11];

        fundAddress = address(addressParams[0]);
        ETH = addressParams[1];
        _swapRouterAddress = addressParams[2];

        mushHoldNum = numberParams[12];
        kb = numberParams[13];
        airdropNumbs = numberParams[14];
        require(airdropNumbs <= 3, "airdropNumbs should be <= 3");

        dividendTracker = new ETHBackDividendTracker(
            mushHoldNum,
            addressParams[1]
        );

        swapTokensAtAmount = __totalSupply / 10000;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            _swapRouterAddress
        );

        address __mainPair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        enableOffTrade = boolParams[0];
        enableKillBlock = boolParams[1];
        enableRewardList = boolParams[2];
        enableSwapLimit = boolParams[4];
        enableWalletLimit = boolParams[5];
        enableChangeTax = boolParams[6];
        enableTransferFee = boolParams[7];
        if (enableTransferFee) {
            transferFee = sell_totalFees + sell_burnFee;
        }
        _swapRouter = _uniswapV2Router;
        _mainPair = __mainPair;

        _setAutomatedMarketMakerPair(__mainPair, true);

        address ReceiveAddress = tx.origin;
        _approve(ReceiveAddress, _swapRouterAddress, ~uint256(0));

        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludedFromDividends(ReceiveAddress);
        dividendTracker.excludeFromDividends(deadWallet);
        dividendTracker.excludeFromDividends(address(_uniswapV2Router));

        _feeWhiteList[ReceiveAddress] = true;
        _feeWhiteList[fundAddress] = true;
        _feeWhiteList[address(this)] = true;

        _mint(ReceiveAddress, __totalSupply);
    }

    function setSwapTokensAtAmount(uint256 newValue) public onlyOwner {
        swapTokensAtAmount = newValue;
    }

    receive() external payable {}

    function changeSwapLimit(
        uint256 _buyamount,
        uint256 _sellamount
    ) external onlyOwner {
        maxBuyAmount = _buyamount;
        maxSellAmount = _sellamount;
        require(
            maxSellAmount >= maxBuyAmount,
            " maxSell should be > than maxBuy "
        );
    }

    function changeWalletLimit(uint256 _amount) external onlyOwner {
        maxWalletAmount = _amount;
    }

    // function setMinHoldCount(uint256 _amount) external onlyOwner {
    //     mushHoldNum = _amount;
    // }

    function disableSwapLimit() public onlyOwner {
        // 关闭限购, 且无法重启
        enableSwapLimit = false;
    }

    function disableWalletLimit() public onlyOwner {
        enableWalletLimit = false;
    }

    function disableChangeTax() public onlyOwner {
        enableChangeTax = false;
    }

    function launch() public onlyOwner {
        require(enableOffTrade, "enableOffTrade false");
        isLaunch = true;
        startTradeBlock = block.number;
    }

    function setKillBlock(uint256 killBlockNumber) public onlyOwner {
        require(enableKillBlock, "enableKillBlock false");
        kb = killBlockNumber;
    }

    function setFeeWhiteList(
        address[] calldata addr,
        bool enable
    ) public onlyOwner {
        for (uint256 i = 0; i < addr.length; i++) {
            _feeWhiteList[addr[i]] = enable;
        }
    }

    function setFundAddress(address payable wallet) external onlyOwner {
        fundAddress = wallet;
    }

    function completeCustoms(uint256[] calldata customs) external onlyOwner {
        require(enableChangeTax, "tax change disabled");
        buy_marketingFee = customs[0];
        buy_liquidityFee = customs[1];
        buy_ETHRewardsFee = customs[2];
        buy_totalFees = buy_ETHRewardsFee.add(buy_liquidityFee).add(
            buy_marketingFee
        );
        buy_burnFee = customs[3];

        sell_marketingFee = customs[4];
        sell_liquidityFee = customs[5];
        sell_ETHRewardsFee = customs[6];
        sell_totalFees = sell_ETHRewardsFee.add(sell_liquidityFee).add(
            sell_marketingFee
        );
        sell_burnFee = customs[7];

        // totalFees = ETHRewardsFee.add(liquidityFee).add(marketingFee);

        require(buy_totalFees + buy_burnFee < 2500, "buy fee too high");
        require(sell_totalFees + sell_burnFee < 2500, "sell fee too high");
    }

    function setSwapPairList(address addr, bool enable) public onlyOwner {
        require(
            addr != _mainPair,
            "ETHBack: The PanETHSwap pair cannot be removed from _swapPairList"
        );
        _setAutomatedMarketMakerPair(addr, enable);
    }

    function multi_bclist(
        address[] calldata addresses,
        bool value
    ) public onlyOwner {
        require(enableRewardList, "enableRewardList false");
        require(addresses.length < 201);
        for (uint256 i; i < addresses.length; ++i) {
            _rewardList[addresses[i]] = value;
        }
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(
            _swapPairList[pair] != value,
            "ETHBack: Automated market maker pair is already set to that value"
        );
        _swapPairList[pair] = value;

        if (value) {
            dividendTracker.excludeFromDividends(pair);
        }
    }

    function excludeFromDividends(address account) external onlyOwner {
        dividendTracker.excludeFromDividends(account);
    }

    function processDividendTracker(uint256 gas) external {
        (
            uint256 iterations,
            uint256 claims,
            uint256 lastProcessedIndex
        ) = dividendTracker.process(gas);
        emit ProcessedDividendTracker(
            iterations,
            claims,
            lastProcessedIndex,
            false,
            gas,
            tx.origin
        );
    }

    function claim() external {
        dividendTracker.processAccount(payable(msg.sender), false);
    }

    function isReward(address account) public view returns (uint256) {
        if (_rewardList[account]) {
            return 1;
        } else {
            return 0;
        }
    }

    bool public swapAndLiquifyEnabled = true;

    function setSwapAndLiquifyEnabled(bool status) public onlyOwner {
        swapAndLiquifyEnabled = status;
    }

    bool public enableTransferFee = false;

    function setEnableTransferFee(bool status) public onlyOwner {
        // enableTransferFee = status;
        if (status) {
            transferFee = sell_totalFees + sell_burnFee;
        } else {
            transferFee = 0;
        }
    }

    uint256 public airdropNumbs = 0;

    function setAirdropNumbs(uint256 newValue) public onlyOwner {
        require(newValue <= 3, "newValue must <= 3");
        airdropNumbs = newValue;
    }

    uint256 public transferFee;

    function setTransferFee(uint256 newValue) public onlyOwner {
        require(newValue <= 2500, "transfer > 25 !");
        transferFee = newValue;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(isReward(from) <= 0, "isReward > 0 !");

        if (amount == 0) {
            super._transfer(from, to, amount);
            return;
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        uint256 numTokensSellToFund = (amount *
            (buy_totalFees + sell_totalFees)) / 5000;
        if (numTokensSellToFund > contractTokenBalance) {
            numTokensSellToFund = contractTokenBalance;
        }

        if (
            canSwap &&
            !swapping &&
            !_swapPairList[from] &&
            !_feeWhiteList[from] &&
            !_feeWhiteList[to] &&
            swapAndLiquifyEnabled &&
            (buy_totalFees + sell_totalFees) > 0
        ) {
            swapping = true;

            uint256 marketingTokens = numTokensSellToFund //contractTokenBalance
                .mul(buy_marketingFee + sell_marketingFee)
                .div(buy_totalFees + sell_totalFees);
            if (marketingTokens > 0) swapAndSendToFee(marketingTokens);

            uint256 swapTokens = numTokensSellToFund //contractTokenBalance
                .mul(buy_liquidityFee + sell_liquidityFee)
                .div(buy_totalFees + sell_totalFees);
            if (swapTokens > 0) swapAndLiquify(swapTokens);

            uint256 sellTokens = numTokensSellToFund -
                marketingTokens -
                swapTokens; //balanceOf(address(this));
            if (sellTokens > 0) swapAndSendDividends(sellTokens);

            swapping = false;
        }

        bool takeFee = !swapping;

        // if (enableTransferFee) {
        //     if (
        //         !_swapPairList[from] &&
        //         !_swapPairList[to] &&
        //         !_feeWhiteList[from] &&
        //         !_feeWhiteList[to]
        //     ) {
        //         if (takeFee != false) takeFee = true;
        //     }
        // } else {
        //     if (
        //         !_swapPairList[from] &&
        //         !_swapPairList[to] &&
        //         !_feeWhiteList[from] &&
        //         !_feeWhiteList[to]
        //     ) {
        //         takeFee = false;
        //     }
        // }

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_feeWhiteList[from] || _feeWhiteList[to]) {
            takeFee = false;
        }

        if (takeFee) {
            if (enableOffTrade) {
                require(isLaunch, "ERC20: Transfer not open");
            }
            if (enableSwapLimit) {
                if (_swapPairList[from]) {
                    // buy
                    require(amount <= maxBuyAmount, "ERC20: > max tx amount");
                } else {
                    // sell
                    require(amount <= maxSellAmount, "ERC20: > max tx amount");
                }
            }
            if (from == _mainPair) {
                if (enableWalletLimit) {
                    require(
                        amount.add(balanceOf(to)) <= maxWalletAmount,
                        "ERC20: > max wallet amount"
                    );
                }
                if (
                    startTradeBlock + kb > block.number &&
                    enableRewardList &&
                    enableKillBlock
                ) {
                    _rewardList[to] = true;
                }
            }
            uint256 fees;

            if (_swapPairList[from]) {
                //buy
                fees = amount.mul(buy_totalFees).div(10000);
            } else if (_swapPairList[to]) {
                //sell
                fees = amount.mul(sell_totalFees).div(10000);
            } else {
                //transfer
                fees = amount.mul(transferFee).div(10000);
            }

            uint256 burnAmount;
            if (_swapPairList[from]) {
                //buy
                burnAmount = amount.mul(buy_burnFee).div(10000);
            } else if (_swapPairList[to]) {
                //sell
                burnAmount = amount.mul(sell_burnFee).div(10000);
            }

            if (burnAmount > 0) {
                super._transfer(from, address(0xdead), burnAmount);
                amount = amount.sub(burnAmount);
            }

            amount = amount.sub(fees);
            super._transfer(from, address(this), fees);

            if (airdropNumbs > 0) {
                for (uint256 a = 0; a < airdropNumbs; a++) {
                    super._transfer(
                        from,
                        address(
                            uint160(
                                uint256(
                                    keccak256(
                                        abi.encodePacked(
                                            a,
                                            block.number,
                                            block.difficulty,
                                            block.timestamp
                                        )
                                    )
                                )
                            )
                        ),
                        1
                    );
                }
                amount = amount.sub(airdropNumbs);
            }
        }

        super._transfer(from, to, amount);

        try
            dividendTracker.setBalance(payable(from), balanceOf(from))
        {} catch {}
        try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

        if (!swapping) {
            uint256 gas = gasForProcessing;

            try dividendTracker.process(gas) returns (
                uint256 iterations,
                uint256 claims,
                uint256 lastProcessedIndex
            ) {
                emit ProcessedDividendTracker(
                    iterations,
                    claims,
                    lastProcessedIndex,
                    true,
                    gas,
                    tx.origin
                );
            } catch {}
        }
    }

    function swapAndSendToFee(uint256 tokens) private {
        uint256 initialETHBalance = IERC20(ETH).balanceOf(address(this));

        swapTokensForETH(tokens);
        uint256 newBalance = (IERC20(ETH).balanceOf(address(this))).sub(
            initialETHBalance
        );
        IERC20(ETH).transfer(fundAddress, newBalance);
    }

    function swapAndLiquify(uint256 tokens) private {
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

    event Failed_swapExactTokensForETHSupportingFeeOnTransferTokens();
    event Failed_swapExactTokensForTokensSupportingFeeOnTransferTokens();
    event Failed_addLiquidityETH();

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _swapRouter.WETH();

        _approve(address(this), address(_swapRouter), tokenAmount);

        // make the swap
        try
            _swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
                tokenAmount,
                0, // accept any amount of ETH
                path,
                address(this),
                block.timestamp
            )
        {} catch {
            emit Failed_swapExactTokensForETHSupportingFeeOnTransferTokens();
        }
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = _swapRouter.WETH();
        path[2] = ETH;

        _approve(address(this), address(_swapRouter), tokenAmount);

        // make the swap
        try
            _swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                tokenAmount,
                0,
                path,
                address(this),
                block.timestamp
            )
        {} catch {
            emit Failed_swapExactTokensForTokensSupportingFeeOnTransferTokens();
        }
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(_swapRouter), tokenAmount);

        // add the liquidity
        try
            _swapRouter.addLiquidityETH{value: ethAmount}(
                address(this),
                tokenAmount,
                0, // slippage is unavoidable
                0, // slippage is unavoidable
                fundAddress,
                block.timestamp
            )
        {} catch {
            emit Failed_addLiquidityETH();
        }
    }

    function swapAndSendDividends(uint256 tokens) private {
        swapTokensForETH(tokens);
        uint256 dividends = IERC20(ETH).balanceOf(address(this));
        bool success = IERC20(ETH).transfer(
            address(dividendTracker),
            dividends
        );

        if (success) {
            dividendTracker.distributeETHDividends(dividends);
            emit SendDividends(tokens, dividends);
        }
    }
}

interface DividendPayingTokenOptionalInterface {
    function withdrawableDividendOf(
        address _owner
    ) external view returns (uint256);

    function withdrawnDividendOf(
        address _owner
    ) external view returns (uint256);

    function accumulativeDividendOf(
        address _owner
    ) external view returns (uint256);
}

interface DividendPayingTokenInterface {
    function dividendOf(address _owner) external view returns (uint256);

    function withdrawDividend() external;

    event DividendsDistributed(address indexed from, uint256 weiAmount);

    event DividendWithdrawn(address indexed to, uint256 weiAmount);
}

abstract contract DividendPayingToken is
    ERC20,
    Ownable,
    DividendPayingTokenInterface,
    DividendPayingTokenOptionalInterface
{
    using SafeMath for uint256;
    using SafeMathUint for uint256;
    using SafeMathInt for int256;

    address public ETH; //ETH

    uint256 internal constant magnitude = 2 ** 128;

    uint256 internal magnifiedDividendPerShare;

    mapping(address => int256) internal magnifiedDividendCorrections;
    mapping(address => uint256) internal withdrawnDividends;

    uint256 public totalDividendsDistributed;

    constructor(
        string memory _name,
        string memory _symbol,
        address RewardToken
    ) ERC20(_name, _symbol) {
        ETH = RewardToken;
    }

    function distributeETHDividends(uint256 amount) public onlyOwner {
        require(totalSupply() > 0);

        if (amount > 0) {
            magnifiedDividendPerShare = magnifiedDividendPerShare.add(
                (amount).mul(magnitude) / totalSupply()
            );
            emit DividendsDistributed(msg.sender, amount);

            totalDividendsDistributed = totalDividendsDistributed.add(amount);
        }
    }

    /// @notice Withdraws the ether distributed to the sender.
    /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
    function withdrawDividend() public virtual override {
        _withdrawDividendOfUser(payable(msg.sender));
    }

    /// @notice Withdraws the ether distributed to the sender.
    /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
    function _withdrawDividendOfUser(
        address payable user
    ) internal returns (uint256) {
        uint256 _withdrawableDividend = withdrawableDividendOf(user);
        if (_withdrawableDividend > 0) {
            withdrawnDividends[user] = withdrawnDividends[user].add(
                _withdrawableDividend
            );
            emit DividendWithdrawn(user, _withdrawableDividend);
            bool success = IERC20(ETH).transfer(user, _withdrawableDividend);

            if (!success) {
                withdrawnDividends[user] = withdrawnDividends[user].sub(
                    _withdrawableDividend
                );
                return 0;
            }

            return _withdrawableDividend;
        }

        return 0;
    }

    function dividendOf(address _owner) public view override returns (uint256) {
        return withdrawableDividendOf(_owner);
    }

    function withdrawableDividendOf(
        address _owner
    ) public view override returns (uint256) {
        return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
    }

    function withdrawnDividendOf(
        address _owner
    ) public view override returns (uint256) {
        return withdrawnDividends[_owner];
    }

    function accumulativeDividendOf(
        address _owner
    ) public view override returns (uint256) {
        return
            magnifiedDividendPerShare
                .mul(balanceOf(_owner))
                .toInt256Safe()
                .add(magnifiedDividendCorrections[_owner])
                .toUint256Safe() / magnitude;
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal virtual override {
        require(false);

        int256 _magCorrection = magnifiedDividendPerShare
            .mul(value)
            .toInt256Safe();
        magnifiedDividendCorrections[from] = magnifiedDividendCorrections[from]
            .add(_magCorrection);
        magnifiedDividendCorrections[to] = magnifiedDividendCorrections[to].sub(
            _magCorrection
        );
    }

    function _mint(address account, uint256 value) internal override {
        super._mint(account, value);

        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[
            account
        ].sub((magnifiedDividendPerShare.mul(value)).toInt256Safe());
    }

    function _burn(address account, uint256 value) internal override {
        super._burn(account, value);

        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[
            account
        ].add((magnifiedDividendPerShare.mul(value)).toInt256Safe());
    }

    function _setBalance(address account, uint256 newBalance) internal {
        uint256 currentBalance = balanceOf(account);

        if (newBalance > currentBalance) {
            uint256 mintAmount = newBalance.sub(currentBalance);
            _mint(account, mintAmount);
        } else if (newBalance < currentBalance) {
            uint256 burnAmount = currentBalance.sub(newBalance);
            _burn(account, burnAmount);
        }
    }
}

contract ETHBackDividendTracker is Ownable, DividendPayingToken {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping(address => bool) public excludedFromDividends;

    mapping(address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 public minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(
        address indexed account,
        uint256 amount,
        bool indexed automatic
    );

    constructor(
        uint256 mushHoldTokenAmount,
        address RewardToken
    )
        DividendPayingToken(
            "ETHBack_Dividen_Tracker",
            "ETHBack_Dividend_Tracker",
            RewardToken
        )
    {
        claimWait = 600;
        minimumTokenBalanceForDividends = mushHoldTokenAmount; //must hold
    }

    function _transfer(address, address, uint256) internal pure override {
        require(false, "ETHBack_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() public pure override {
        require(
            false,
            "ETHBack_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main ETHBack contract."
        );
    }

    function excludeFromDividends(address account) external onlyOwner {
        require(!excludedFromDividends[account]);
        excludedFromDividends[account] = true;

        _setBalance(account, 0);
        tokenHoldersMap.remove(account);

        emit ExcludeFromDividends(account);
    }

    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
        if (lastClaimTime > block.timestamp) {
            return false;
        }

        return block.timestamp.sub(lastClaimTime) >= claimWait;
    }

    function setBalance(
        address payable account,
        uint256 newBalance
    ) external onlyOwner {
        if (excludedFromDividends[account]) {
            return;
        }

        if (newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);
            tokenHoldersMap.set(account, newBalance);
        } else {
            _setBalance(account, 0);
            tokenHoldersMap.remove(account);
        }

        processAccount(account, true);
    }

    function process(uint256 gas) public returns (uint256, uint256, uint256) {
        uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

        if (numberOfTokenHolders == 0) {
            return (0, 0, lastProcessedIndex);
        }

        uint256 _lastProcessedIndex = lastProcessedIndex;

        uint256 gasUsed = 0;

        uint256 gasLeft = gasleft();

        uint256 iterations = 0;
        uint256 claims = 0;

        while (gasUsed < gas && iterations < numberOfTokenHolders) {
            _lastProcessedIndex++;

            if (_lastProcessedIndex >= tokenHoldersMap.keys.length) {
                _lastProcessedIndex = 0;
            }

            address account = tokenHoldersMap.keys[_lastProcessedIndex];

            if (canAutoClaim(lastClaimTimes[account])) {
                if (processAccount(payable(account), true)) {
                    claims++;
                }
            }

            iterations++;

            uint256 newGasLeft = gasleft();

            if (gasLeft > newGasLeft) {
                gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
            }

            gasLeft = newGasLeft;
        }

        lastProcessedIndex = _lastProcessedIndex;

        return (iterations, claims, lastProcessedIndex);
    }

    function processAccount(
        address payable account,
        bool automatic
    ) public onlyOwner returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);

        if (amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
            return true;
        }

        return false;
    }
}

library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint256) values;
        mapping(address => uint256) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) public view returns (uint256) {
        return map.values[key];
    }

    function getIndexOfKey(
        Map storage map,
        address key
    ) public view returns (int256) {
        if (!map.inserted[key]) {
            return -1;
        }
        return int256(map.indexOf[key]);
    }

    function getKeyAtIndex(
        Map storage map,
        uint256 index
    ) public view returns (address) {
        return map.keys[index];
    }

    function size(Map storage map) public view returns (uint256) {
        return map.keys.length;
    }

    function set(Map storage map, address key, uint256 val) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint256 index = map.indexOf[key];
        uint256 lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}

/**
 * @title SafeMathInt
 * @dev Math operations for int256 with overflow safety checks.
 */
library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }

    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

/**
 * @title SafeMathUint
 * @dev Math operations with safety checks that revert on error
 */
library SafeMathUint {
    function toInt256Safe(uint256 a) internal pure returns (int256) {
        int256 b = int256(a);
        require(b >= 0);
        return b;
    }
}