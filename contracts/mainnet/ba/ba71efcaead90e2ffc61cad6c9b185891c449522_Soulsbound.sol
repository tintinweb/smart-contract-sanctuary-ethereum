/**
 *Submitted for verification at Etherscan.io on 2022-11-24
*/

/*
  ██████  ▒█████   █    ██  ██▓      ██████     ▄▄▄▄    ▒█████   █    ██  ███▄    █ ▓█████▄ 
▒██    ▒ ▒██▒  ██▒ ██  ▓██▒▓██▒    ▒██    ▒    ▓█████▄ ▒██▒  ██▒ ██  ▓██▒ ██ ▀█   █ ▒██▀ ██▌
░ ▓██▄   ▒██░  ██▒▓██  ▒██░▒██░    ░ ▓██▄      ▒██▒ ▄██▒██░  ██▒▓██  ▒██░▓██  ▀█ ██▒░██   █▌
  ▒   ██▒▒██   ██░▓▓█  ░██░▒██░      ▒   ██▒   ▒██░█▀  ▒██   ██░▓▓█  ░██░▓██▒  ▐▌██▒░▓█▄   ▌
▒██████▒▒░ ████▓▒░▒▒█████▓ ░██████▒▒██████▒▒   ░▓█  ▀█▓░ ████▓▒░▒▒█████▓ ▒██░   ▓██░░▒████▓ 
▒ ▒▓▒ ▒ ░░ ▒░▒░▒░ ░▒▓▒ ▒ ▒ ░ ▒░▓  ░▒ ▒▓▒ ▒ ░   ░▒▓███▀▒░ ▒░▒░▒░ ░▒▓▒ ▒ ▒ ░ ▒░   ▒ ▒  ▒▒▓  ▒ 
░ ░▒  ░ ░  ░ ▒ ▒░ ░░▒░ ░ ░ ░ ░ ▒  ░░ ░▒  ░ ░   ▒░▒   ░   ░ ▒ ▒░ ░░▒░ ░ ░ ░ ░░   ░ ▒░ ░ ▒  ▒ 
░  ░  ░  ░ ░ ░ ▒   ░░░ ░ ░   ░ ░   ░  ░  ░      ░    ░ ░ ░ ░ ▒   ░░░ ░ ░    ░   ░ ░  ░ ░  ░ 
      ░      ░ ░     ░         ░  ░      ░      ░          ░ ░     ░              ░    ░    
    Soulsbound                        $ SBT                     Token             ░      */
pragma solidity 0.8.15;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier:MIT

interface IBEP20 {
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
    address payable private _owner;
    address payable private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = payable(0xE5915dfD7976E534A039551E2B7F75c1262aCFC4);
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

    function transferOwnership(address payable newOwner)
        public
        virtual
        onlyOwner
    {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IPancakeFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IPancakeRouter01 {
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

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// Main Bep20  Token

contract Soulsbound is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) public isTxLimitExempt;
    mapping(address => bool) public isSniper;
    mapping(address => uint256) private _nextSellTime;
    mapping(address => uint8) private _sellCount;

    uint256 private _tTotal = 1_000_000_000_000 ether; // 1 trillion total supply
    uint256 maxTxAmount = 1 * 1e8 ether; // 100 million
    uint256 public maxSellLimitStartTime; // capture max selling limit start time
    uint256 public maxSellLimitDuration = 24 hours; // max selling limit switched off automatically after 24 hours
    uint256 public sellAmount = 10000 ether;
    string private _name = "Soulsbound Token"; // token name
    string private _symbol = "$SBT"; // token ticker
    uint8 private _decimals = 18; // token decimals

    IPancakeRouter02 public pancakeRouter;
    address public pancakePair;

    address payable public devWallet;

    address public burnAddress = 0x000000000000000000000000000000000000dEaD;
    uint256 public maxFee = 150; // 15% max fees limit per transaction
    bool public tradingOpen;

    uint256 public launchedAt;
    uint256 public launchedAtTimestamp;
    uint256 antiSnipingTime = 60 seconds;

    // buy tax fee
    uint256 private devFeeOnBuying = 0; // 0% will go to the  dev wallet address

    // sell tax fee
    uint256 private devFeeOnSelling = 0; // 0% will go to the  dev wallet address

    // for smart contract use
    uint256 private _currentdevFee;

    constructor() {
        balances[owner()] = _tTotal;

        IPancakeRouter02 _pancakeRouter = IPancakeRouter02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        // Create a pancake pair for this new token
        pancakePair = IPancakeFactory(_pancakeRouter.factory()).createPair(
            address(this),
            _pancakeRouter.WETH()
        );

        // set the rest of the contract variables
        pancakeRouter = _pancakeRouter;

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        isTxLimitExempt[owner()] = true;

        emit Transfer(address(0), owner(), _tTotal);
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return balances[account];
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
            _allowances[sender][_msgSender()] - (amount)
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
            _allowances[_msgSender()][spender] + (addedValue)
        );
        return true;
    }

    function Burn(uint256 amount) public {
        uint256 accountBalance = balances[msg.sender];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            balances[msg.sender] = accountBalance - amount;
        }
        _tTotal -= amount;
        balances[address(0)] += amount;
        emit Transfer(msg.sender, address(0), amount);
    }

    function airDrop(address[] memory receivers, uint256[] memory amount)
        public
        onlyOwner
    {
        require(receivers.length == amount.length, "unMatched Data");
        for (uint256 i; i < receivers.length; i++) {
            transferFrom(msg.sender, receivers[i], amount[i]);
        }
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] - (subtractedValue)
        );
        return true;
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() public onlyOwner {
        require(launchedAt == 0, "Already launched boi");
        launchedAt = block.number;
        launchedAtTimestamp = block.timestamp;
        tradingOpen = true;
    }

    function setTxLimit(uint256 amount) external onlyOwner {
        require(
            amount > 10000 ether,
            "transaction amiunt should be less than 10k"
        );
        maxTxAmount = amount;
    }

    function setIsTxLimitExempt(address holder, bool exempt)
        external
        onlyOwner
    {
        isTxLimitExempt[holder] = exempt;
    }

    function addSniperInList(address _account) external onlyOwner {
        require(
            _account != address(pancakeRouter),
            "We can not blacklist router"
        );
        require(!isSniper[_account], "Sniper already exist");
        isSniper[_account] = true;
    }

    function removeSniperFromList(address _account) external onlyOwner {
        require(isSniper[_account], "Not a sniper");
        isSniper[_account] = false;
    }

    function setDevWallet(address payable _devWallet) external onlyOwner {
        require(devWallet != address(0), "dev wallet cannot be address zero");
        devWallet = _devWallet;
    }

    function setRoute(IPancakeRouter02 _router, address _pair)
        external
        onlyOwner
    {
        require(
            address(_router) != address(0),
            "Router adress cannot be address zero"
        );
        require(_pair != address(0), "Pair adress cannot be address zero");
        pancakeRouter = _router;
        pancakePair = _pair;
    }

    function withdrawBNB(uint256 _amount) external onlyOwner {
        require(address(this).balance >= _amount, "Invalid Amount");
        payable(msg.sender).transfer(_amount);
    }

    function withdrawToken(IBEP20 _token, uint256 _amount) external onlyOwner {
        require(_token.balanceOf(address(this)) >= _amount, "Invalid Amount");
        _token.transfer(msg.sender, _amount);
    }

    //to receive BNB from pancakeRouter when swapping
    receive() external payable {}

    function totalFeePerTx(uint256 tAmount) internal view returns (uint256) {
        uint256 percentage = (tAmount * (_currentdevFee)) / (1e3);
        return percentage;
    }

    function _takeDevFee(uint256 tAmount) internal {
        uint256 tDevFee = (tAmount * (_currentdevFee)) / (1e3);
        balances[devWallet] = balances[devWallet] + (tDevFee);
        emit Transfer(_msgSender(), devWallet, tDevFee);
    }

    function removeAllFee() private {
        _currentdevFee = 0;
    }

    function setBuyFee() private {
        _currentdevFee = devFeeOnSelling;
    }

    function setSellFee() private {
        _currentdevFee = devFeeOnSelling;
    }

    //by default MaxSellLimit is true to disable set it to false address can sell more than limit
    function enableMaxSellLimit() external onlyOwner {
        maxSellLimitStartTime = block.timestamp;
    }

    //only owner can change max sell limit duration
    function setMaxSellLimitDuration(uint256 _duration) public onlyOwner {
        maxSellLimitDuration = _duration;
    }

    //only owner can change max sell Amount
    function setMaxSellAmount(uint256 amount) public onlyOwner {
        require(amount > 1000 ether, "min value must be 1k");
        sellAmount = amount;
    }

    //only owner can change BuyFeePercentages any time after deployment
    function setBuyFeePercent(uint256 _devFee) external onlyOwner {
        devFeeOnBuying = _devFee;
        require(
            devFeeOnBuying <= maxFee,
            "BEP20: Can not be greater than max fee"
        );
    }

    //only owner can change SellFeePercentages any time after deployment
    function setSellFeePercent(uint256 _devFee) external onlyOwner {
        devFeeOnSelling = _devFee;
        require(
            devFeeOnSelling <= maxFee,
            "BEP20: Can not be greater than max fee"
        );
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(amount > 0, "BEP20: Transfer amount must be greater than zero");
        require(!isSniper[to], "Sniper detected");
        require(!isSniper[from], "Sniper detected");
        if (!isTxLimitExempt[from] && !isTxLimitExempt[to]) {
            // trading disable till launch
            if (!tradingOpen) {
                require(
                    from != pancakePair && to != pancakePair,
                    "Trading is not enabled yet"
                );
            }
            // antibot
            if (
                block.timestamp < launchedAtTimestamp + antiSnipingTime &&
                from != address(pancakeRouter)
            ) {
                if (from == pancakePair) {
                    isSniper[to] = true;
                } else if (to == pancakePair) {
                    isSniper[from] = true;
                }
            }

            require(amount <= maxTxAmount, "TX Limit Exceeded");
        }

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }
        if (!takeFee) {
            removeAllFee();
        }
        // buying handler
        else if (from == pancakePair) {
            setBuyFee();
        }
        // selling handler
        else if (to == pancakePair) {
            setSellFee();
            if (
                maxSellLimitStartTime.add(maxSellLimitDuration) >
                block.timestamp
            ) {
                if (_nextSellTime[from] < maxSellLimitStartTime) {
                    _sellCount[from] = 0;
                }
                uint256 maxSellLimit = sellAmount;
                if (_sellCount[from] == 0) {
                    require(
                        amount <= maxSellLimit,
                        "BEP20: can not sell more than limit"
                    );
                    _nextSellTime[from] = block.timestamp.add(
                        maxSellLimitDuration
                    );
                    _sellCount[from]++;
                } else if (_sellCount[from] == 1) {
                    require(
                        block.timestamp >= _nextSellTime[from],
                        "BEP20: wait for next sell time"
                    );
                    require(
                        amount <= maxSellLimit,
                        "BEP20: can not sell more than 50%"
                    );
                    _nextSellTime[from] = block.timestamp.add(4 hours);
                    _sellCount[from]++;
                } else {
                    require(
                        block.timestamp >= _nextSellTime[from],
                        "BEP20: wait for next sell time"
                    );
                    _sellCount[from]++;
                }
            }
        }
        // normal transaction handler
        else {
            removeAllFee();
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount);
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        uint256 tTransferAmount = tAmount - (totalFeePerTx(tAmount));
        balances[sender] -= (tAmount);
        balances[recipient] += (tTransferAmount);
        _takeDevFee(tAmount);
        emit Transfer(sender, recipient, tTransferAmount);
    }
}

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