/**
 *Submitted for verification at Etherscan.io on 2022-11-11
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

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

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IRouter {
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

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

interface DividendPayingTokenInterface {
    function dividendOf(address _owner) external view returns (uint256);

    function distributeDividends() external payable;

    function withdrawDividend() external;

    event DividendsDistributed(address indexed from, uint256 weiAmount);
    event DividendWithdrawn(address indexed to, uint256 weiAmount);
}

interface DividendPayingTokenOptionalInterface {
    function withdrawableDividendOf(address _owner) external view returns (uint256);

    function withdrawnDividendOf(address _owner) external view returns (uint256);

    function accumulativeDividendOf(address _owner) external view returns (uint256);
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

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }

    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

library SafeMathUint {
    function toInt256Safe(uint256 a) internal pure returns (int256) {
        int256 b = int256(a);
        require(b >= 0);
        return b;
    }
}

library Address {
	function isContract(address account) internal view returns (bool) {
		uint256 size;
		assembly {
			size := extcodesize(account)
		}
		return size > 0;
	}

	function sendValue(address payable recipient, uint256 amount) internal {
		require(
			address(this).balance >= amount,
			"Address: insufficient balance"
		);

		(bool success, ) = recipient.call{value: amount}("");
		require(
			success,
			"Address: unable to send value, recipient may have reverted"
		);
	}

	function functionCall(address target, bytes memory data)
	internal
	returns (bytes memory)
	{
		return functionCall(target, data, "Address: low-level call failed");
	}

	function functionCall(
		address target,
		bytes memory data,
		string memory errorMessage
	) internal returns (bytes memory) {
		return functionCallWithValue(target, data, 0, errorMessage);
	}

	function functionCallWithValue(
		address target,
		bytes memory data,
		uint256 value
	) internal returns (bytes memory) {
		return
		functionCallWithValue(
			target,
			data,
			value,
			"Address: low-level call with value failed"
		);
	}

	function functionCallWithValue(
		address target,
		bytes memory data,
		uint256 value,
		string memory errorMessage
	) internal returns (bytes memory) {
		require(
			address(this).balance >= value,
			"Address: insufficient balance for call"
		);
		require(isContract(target), "Address: call to non-contract");

		(bool success, bytes memory returndata) = target.call{value: value}(
		data
		);
		return _verifyCallResult(success, returndata, errorMessage);
	}

	function functionStaticCall(address target, bytes memory data)
	internal
	view
	returns (bytes memory)
	{
		return
		functionStaticCall(
			target,
			data,
			"Address: low-level static call failed"
		);
	}

	function functionStaticCall(
		address target,
		bytes memory data,
		string memory errorMessage
	) internal view returns (bytes memory) {
		require(isContract(target), "Address: static call to non-contract");

		(bool success, bytes memory returndata) = target.staticcall(data);
		return _verifyCallResult(success, returndata, errorMessage);
	}

	function functionDelegateCall(address target, bytes memory data)
	internal
	returns (bytes memory)
	{
		return
		functionDelegateCall(
			target,
			data,
			"Address: low-level delegate call failed"
		);
	}

	function functionDelegateCall(
		address target,
		bytes memory data,
		string memory errorMessage
	) internal returns (bytes memory) {
		require(isContract(target), "Address: delegate call to non-contract");

		(bool success, bytes memory returndata) = target.delegatecall(data);
		return _verifyCallResult(success, returndata, errorMessage);
	}

	function _verifyCallResult(
		bool success,
		bytes memory returndata,
		string memory errorMessage
	) private pure returns (bytes memory) {
		if (success) {
			return returndata;
		} else {
			if (returndata.length > 0) {
				assembly {
					let returndata_size := mload(returndata)
					revert(add(32, returndata), returndata_size)
				}
			} else {
				revert(errorMessage);
			}
		}
	}
}

library IterableMapping {
    struct Map {
        address[] keys;
        mapping(address => uint256) values;
        mapping(address => uint256) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) public view returns (uint256) {
        return map.values[key];
    }

    function getIndexOfKey(Map storage map, address key) public view returns (int256) {
        if (!map.inserted[key]) {
            return -1;
        }
        return int256(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint256 index) public view returns (address) {
        return map.keys[index];
    }

    function size(Map storage map) public view returns (uint256) {
        return map.keys.length;
    }

    function set(
        Map storage map,
        address key,
        uint256 val
    ) public {
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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
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
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
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
        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
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

contract DividendPayingToken is
    ERC20,
    Ownable,
    DividendPayingTokenInterface,
    DividendPayingTokenOptionalInterface
{
    using SafeMath for uint256;
    using SafeMathUint for uint256;
    using SafeMathInt for int256;

    uint256 internal constant magnitude = 2**128;
    uint256 internal magnifiedDividendPerShare;
    uint256 public totalDividendsDistributed;
    address public rewardToken;
    IRouter public uniswapV2Router;

    mapping(address => int256) internal magnifiedDividendCorrections;
    mapping(address => uint256) internal withdrawnDividends;

    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}

    receive() external payable {
        distributeDividends();
    }

    function distributeDividends() public payable override onlyOwner {
        require(totalSupply() > 0);
        if (msg.value > 0) {
            magnifiedDividendPerShare = magnifiedDividendPerShare.add(
                (msg.value).mul(magnitude) / totalSupply()
            );
            emit DividendsDistributed(msg.sender, msg.value);
            totalDividendsDistributed = totalDividendsDistributed.add(msg.value);
        }
    }

    function withdrawDividend() public virtual override onlyOwner {
        _withdrawDividendOfUser(payable(msg.sender));
    }

    function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
        uint256 _withdrawableDividend = withdrawableDividendOf(user);
        if (_withdrawableDividend > 0) {
            withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
            emit DividendWithdrawn(user, _withdrawableDividend);
            return swapETHForTokensAndWithdrawDividend(user, _withdrawableDividend);
        }
        return 0;
    }

    function swapETHForTokensAndWithdrawDividend(address holder, uint256 ethAmount)
        private
        returns (uint256)
    {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(rewardToken);

        try
            uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: ethAmount }(
                0, // accept any amount of tokens
                path,
                address(holder),
                block.timestamp
            )
        {
            return ethAmount;
        } catch {
            withdrawnDividends[holder] = withdrawnDividends[holder].sub(ethAmount);
            return 0;
        }
    }

    function dividendOf(address _owner) public view override returns (uint256) {
        return withdrawableDividendOf(_owner);
    }

    function withdrawableDividendOf(address _owner) public view override returns (uint256) {
        return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
    }

    function withdrawnDividendOf(address _owner) public view override returns (uint256) {
        return withdrawnDividends[_owner];
    }

    function accumulativeDividendOf(address _owner) public view override returns (uint256) {
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
        int256 _magCorrection = magnifiedDividendPerShare.mul(value).toInt256Safe();
        magnifiedDividendCorrections[from] = magnifiedDividendCorrections[from].add(_magCorrection);
        magnifiedDividendCorrections[to] = magnifiedDividendCorrections[to].sub(_magCorrection);
    }

    function _mint(address account, uint256 value) internal override {
        super._mint(account, value);
        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account].sub(
            (magnifiedDividendPerShare.mul(value)).toInt256Safe()
        );
    }

    function _burn(address account, uint256 value) internal override {
        super._burn(account, value);
        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account].add(
            (magnifiedDividendPerShare.mul(value)).toInt256Safe()
        );
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

    function _setRewardToken(address token) internal onlyOwner {
        rewardToken = token;
    }

    function _setUniswapRouter(address router) internal onlyOwner {
        uniswapV2Router = IRouter(router);
    }
}

contract Brewlabs is Ownable, ERC20 {
    using Address for address;

    IRouter public uniswapV2Router;
    address public immutable uniswapV2Pair;

    string private constant _name = "Brewlabs";
    string private constant _symbol = "BREWLABS";
    uint8 private constant _decimals = 9;

    BrewlabsDividendTracker public dividendTracker;

    bool public isTradingEnabled;

    // max wallet is 1.5% of Brewlabs(BEP20)'s initialSupply
    uint256 public maxWalletAmount = (1000000000 * (10**9) * 150) / 10000;

    // max buy and sell tx is 0.2% of Brewlabs(BEP20)'s initialSupply
    uint256 public maxTxAmount = (1000000000 * (10**9) * 20) / 10000;

    bool private _swapping;
    uint256 public minimumTokensBeforeSwap = 250000000 * (10**9);

    address public dividendToken = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; //USDC

    address public liquidityWallet;
    address public devWallet;
    address public buyBackWallet;
    address public bridge;
    address public stakingAddress;

    struct CustomTaxPeriod {
        bytes23 periodName;
        uint8 blocksInPeriod;
        uint256 timeInPeriod;
        uint8 liquidityFeeOnBuy;
        uint8 liquidityFeeOnSell;
        uint8 devFeeOnBuy;
        uint8 devFeeOnSell;
        uint8 buyBackFeeOnBuy;
        uint8 buyBackFeeOnSell;
        uint8 stakingFeeOnBuy;
        uint8 stakingFeeOnSell;
        uint8 holdersFeeOnBuy;
        uint8 holdersFeeOnSell;
    }

    // Base taxes
    CustomTaxPeriod private _base = CustomTaxPeriod("base", 0, 0, 1, 1, 1, 1, 8, 8, 1, 1, 4, 4);

    mapping(address => bool) private _isAllowedToTradeWhenDisabled;
    mapping(address => bool) private _feeOnSelectedWalletTransfers;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcludedFromMaxTransactionLimit;
    mapping(address => bool) private _isExcludedFromMaxWalletLimit;
    mapping(address => bool) public automatedMarketMakerPairs;

    uint8 private _liquidityFee;
    uint8 private _devFee;
    uint8 private _buyBackFee;
    uint8 private _stakingFee;
    uint8 private _holdersFee;
    uint8 private _totalFee;

    event AutomatedMarketMakerPairChange(address indexed pair, bool indexed value);
    event UniswapV2RouterChange(address indexed newAddress, address indexed oldAddress);
    event WalletChange(
        string indexed indentifier,
        address indexed newWallet,
        address indexed oldWallet
    );
    event FeeChange(
        string indexed identifier,
        uint8 liquidityFee,
        uint8 devFee,
        uint8 buyBackFee,
        uint8 stakingFee,
        uint8 holdersFee
    );
    event CustomTaxPeriodChange(
        uint256 indexed newValue,
        uint256 indexed oldValue,
        string indexed taxType,
        bytes23 period
    );
    event MaxTransactionAmountChange(uint256 indexed newValue, uint256 indexed oldValue);
    event MaxWalletAmountChange(uint256 indexed newValue, uint256 indexed oldValue);
    event ExcludeFromFeesChange(address indexed account, bool isExcluded);
    event ExcludeFromMaxTransferChange(address indexed account, bool isExcluded);
    event ExcludeFromMaxWalletChange(address indexed account, bool isExcluded);
    event ExcludeFromDividendsChange(address indexed account, bool isExcluded);
    event AllowedWhenTradingDisabledChange(address indexed account, bool isExcluded);
    event MinTokenAmountBeforeSwapChange(uint256 indexed newValue, uint256 indexed oldValue);
    event MinTokenAmountForDividendsChange(uint256 indexed newValue, uint256 indexed oldValue);
    event DividendsSent(uint256 tokensSwapped);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    event FeeOnSelectedWalletTransfersChange(address indexed account, bool newValue);
    event ClaimETHOverflow(uint256 amount);
    event FeesApplied(
        uint8 liquidityFee,
        uint8 devFee,
        uint8 buyBackFee,
        uint8 stakingFee,
        uint8 holdersFee,
        uint8 totalFee
    );
    event SetBridgeContract(address indexed bridgeContract);
    event SetStakingAddress(address indexed stakingAddress);

    modifier hasMintPermission() {
        require(msg.sender == bridge, "Only bridge contract can mint");
        _;
    }

    constructor() ERC20(_name, _symbol) {
        dividendTracker = new BrewlabsDividendTracker();
        dividendTracker.setUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        dividendTracker.setRewardToken(dividendToken);

        liquidityWallet = owner();
        devWallet = owner();
        buyBackWallet = owner();

        IRouter _uniswapV2Router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _uniswapV2Pair = IFactory(_uniswapV2Router.factory()).createPair(
            address(this),
            _uniswapV2Router.WETH()
        );
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[address(dividendTracker)] = true;

        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(address(0x000000000000000000000000000000000000dEaD));
        dividendTracker.excludeFromDividends(owner());
        dividendTracker.excludeFromDividends(address(_uniswapV2Router));

        _isAllowedToTradeWhenDisabled[owner()] = true;
        _isAllowedToTradeWhenDisabled[address(this)] = true;

        _isExcludedFromMaxTransactionLimit[address(dividendTracker)] = true;
        _isExcludedFromMaxTransactionLimit[address(this)] = true;

        _isExcludedFromMaxWalletLimit[_uniswapV2Pair] = true;
        _isExcludedFromMaxWalletLimit[address(dividendTracker)] = true;
        _isExcludedFromMaxWalletLimit[address(uniswapV2Router)] = true;
        _isExcludedFromMaxWalletLimit[address(this)] = true;
        _isExcludedFromMaxWalletLimit[owner()] = true;
    }

    receive() external payable {}

    // Setters
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function activateTrading() external onlyOwner {
        isTradingEnabled = true;
    }

    function deactivateTrading() external onlyOwner {
        isTradingEnabled = false;
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(
            automatedMarketMakerPairs[pair] != value,
            "Brewlabs: Automated market maker pair is already set to that value"
        );
        automatedMarketMakerPairs[pair] = value;
        if (value) {
            dividendTracker.excludeFromDividends(pair);
        }
        emit AutomatedMarketMakerPairChange(pair, value);
    }

    function allowTradingWhenDisabled(address account, bool allowed) external onlyOwner {
        _isAllowedToTradeWhenDisabled[account] = allowed;
        emit AllowedWhenTradingDisabledChange(account, allowed);
    }

    function setFeeOnSelectedWalletTransfers(address account, bool value) external onlyOwner {
        require(
            _feeOnSelectedWalletTransfers[account] != value,
            "Brewlabs: The selected wallet is already set to the value "
        );
        _feeOnSelectedWalletTransfers[account] = value;
        emit FeeOnSelectedWalletTransfersChange(account, value);
    }

    function excludeFromFees(address account, bool excluded) external onlyOwner {
        require(
            _isExcludedFromFee[account] != excluded,
            "Brewlabs: Account is already the value of 'excluded'"
        );
        _isExcludedFromFee[account] = excluded;
        emit ExcludeFromFeesChange(account, excluded);
    }

    function excludeFromDividends(address account) external onlyOwner {
        dividendTracker.excludeFromDividends(account);
    }

    function excludeFromMaxTransactionLimit(address account, bool excluded) external onlyOwner {
        require(
            _isExcludedFromMaxTransactionLimit[account] != excluded,
            "Brewlabs: Account is already the value of 'excluded'"
        );
        _isExcludedFromMaxTransactionLimit[account] = excluded;
        emit ExcludeFromMaxTransferChange(account, excluded);
    }

    function excludeFromMaxWalletLimit(address account, bool excluded) external onlyOwner {
        require(
            _isExcludedFromMaxWalletLimit[account] != excluded,
            "Brewlabs: Account is already the value of 'excluded'"
        );
        _isExcludedFromMaxWalletLimit[account] = excluded;
        emit ExcludeFromMaxWalletChange(account, excluded);
    }

    function setStakingAddress(
        address newStakingAddress
    ) external onlyOwner {
        require(newStakingAddress != address(0), "Brewlabs: The stakingAddress cannot be 0");
        require(newStakingAddress != stakingAddress, "Brewlabs: The stakingAddress is already the value of newStakingAddress");
        stakingAddress = newStakingAddress;
        emit SetStakingAddress(stakingAddress);
    }

    function setWallets(
        address newLiquidityWallet,
        address newDevWallet,
        address newBuyBackWallet
    ) external onlyOwner {
        if (liquidityWallet != newLiquidityWallet) {
            require(newLiquidityWallet != address(0), "Brewlabs: The liquidityWallet cannot be 0");
            emit WalletChange("liquidityWallet", newLiquidityWallet, liquidityWallet);
            liquidityWallet = newLiquidityWallet;
        }
        if (devWallet != newDevWallet) {
            require(newDevWallet != address(0), "Brewlabs: The devWallet cannot be 0");
            emit WalletChange("devWallet", newDevWallet, devWallet);
            devWallet = newDevWallet;
        }
        if (buyBackWallet != newBuyBackWallet) {
            require(newBuyBackWallet != address(0), "Brewlabs: The buyBackWallet cannot be 0");
            emit WalletChange("buyBackWallet", newBuyBackWallet, buyBackWallet);
            buyBackWallet = newBuyBackWallet;
        }
    }

    // Base fees
    function setBaseFeesOnBuy(
        uint8 _liquidityFeeOnBuy,
        uint8 _devFeeOnBuy,
        uint8 _buyBackFeeOnBuy,
        uint8 _stakingFeeOnBuy,
        uint8 _holdersFeeOnBuy
    ) external onlyOwner {
        _setCustomBuyTaxPeriod(
            _base,
            _liquidityFeeOnBuy,
            _devFeeOnBuy,
            _buyBackFeeOnBuy,
            _stakingFeeOnBuy,
            _holdersFeeOnBuy
        );
        emit FeeChange(
            "baseFees-Buy",
            _liquidityFeeOnBuy,
            _devFeeOnBuy,
            _buyBackFeeOnBuy,
            _stakingFeeOnBuy,
            _holdersFeeOnBuy
        );
    }

    function setBaseFeesOnSell(
        uint8 _liquidityFeeOnSell,
        uint8 _devFeeOnSell,
        uint8 _buyBackFeeOnSell,
        uint8 _stakingFeeOnSell,
        uint8 _holdersFeeOnSell
    ) external onlyOwner {
        _setCustomSellTaxPeriod(
            _base,
            _liquidityFeeOnSell,
            _devFeeOnSell,
            _buyBackFeeOnSell,
            _stakingFeeOnSell,
            _holdersFeeOnSell
        );
        emit FeeChange(
            "baseFees-Sell",
            _liquidityFeeOnSell,
            _devFeeOnSell,
            _buyBackFeeOnSell,
            _stakingFeeOnSell,
            _holdersFeeOnSell
        );
    }

    function setUniswapRouter(address newAddress) external onlyOwner {
        require(
            newAddress != address(uniswapV2Router),
            "Brewlabs: The router already has that address"
        );
        emit UniswapV2RouterChange(newAddress, address(uniswapV2Router));
        uniswapV2Router = IRouter(newAddress);
        dividendTracker.setUniswapRouter(newAddress);
    }

    function setMaxTransactionAmount(uint256 newValue) external onlyOwner {
        require(newValue != maxTxAmount, "Brewlabs: Cannot update maxTxAmount to same value");
        emit MaxTransactionAmountChange(newValue, maxTxAmount);
        maxTxAmount = newValue;
    }

    function setMaxWalletAmount(uint256 newValue) external onlyOwner {
        require(
            newValue != maxWalletAmount,
            "Brewlabs: Cannot update maxWalletAmount to same value"
        );
        emit MaxWalletAmountChange(newValue, maxWalletAmount);
        maxWalletAmount = newValue;
    }

    function setMinimumTokensBeforeSwap(uint256 newValue) external onlyOwner {
        require(
            newValue != minimumTokensBeforeSwap,
            "Brewlabs: Cannot update minimumTokensBeforeSwap to same value"
        );
        emit MinTokenAmountBeforeSwapChange(newValue, minimumTokensBeforeSwap);
        minimumTokensBeforeSwap = newValue;
    }

    function setMinimumTokenBalanceForDividends(uint256 newValue) external onlyOwner {
        dividendTracker.setTokenBalanceForDividends(newValue);
    }

    function claim() external {
        dividendTracker.processAccount(payable(msg.sender), false);
    }

    function claimETHOverflow(uint256 amount) external onlyOwner {
        require(amount < address(this).balance, "Brewlabs: Cannot send more than contract balance");
        (bool success, ) = address(owner()).call{ value: amount }("");
        if (success) {
            emit ClaimETHOverflow(amount);
        }
    }

    function mint(address account, uint256 value) external hasMintPermission returns (bool) {
        _mint(account, value);
        try dividendTracker.setBalance(payable(account), balanceOf(account)) {} catch {}
        return true;
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
        try dividendTracker.setBalance(payable(msg.sender), balanceOf(msg.sender)) {} catch {}
    }

    function setBridgeContract(address _bridgeContract) external onlyOwner {
        require(_bridgeContract != address(0x0) && _bridgeContract != bridge, "Brewlabs: Invalid bridge");
        bridge = _bridgeContract;
        emit SetBridgeContract(_bridgeContract);
    }

    // Getters
    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function withdrawableDividendOf(address account) external view returns (uint256) {
        return dividendTracker.withdrawableDividendOf(account);
    }

    function dividendTokenBalanceOf(address account) external view returns (uint256) {
        return dividendTracker.balanceOf(account);
    }

    function getNumberOfDividendTokenHolders() external view returns (uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }

    function getBaseBuyFees()
        external
        view
        returns (
            uint8,
            uint8,
            uint8,
            uint8,
            uint8
        )
    {
        return (
            _base.liquidityFeeOnBuy,
            _base.devFeeOnBuy,
            _base.buyBackFeeOnBuy,
            _base.stakingFeeOnBuy,
            _base.holdersFeeOnBuy
        );
    }

    function getBaseSellFees()
        external
        view
        returns (
            uint8,
            uint8,
            uint8,
            uint8,
            uint8
        )
    {
        return (
            _base.liquidityFeeOnSell,
            _base.devFeeOnSell,
            _base.buyBackFeeOnSell,
            _base.stakingFeeOnSell,
            _base.holdersFeeOnSell
        );
    }

    // Main
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (!_isAllowedToTradeWhenDisabled[from] && !_isAllowedToTradeWhenDisabled[to]) {
            require(isTradingEnabled, "Brewlabs: Trading is currently disabled.");
            if (!_isExcludedFromMaxTransactionLimit[to] && !_isExcludedFromMaxTransactionLimit[from]) {
                require(amount <= maxTxAmount, "Brewlabs: Buy amount exceeds the maxTxBuyAmount.");
            }
            if (!_isExcludedFromMaxWalletLimit[to]) {
                require((balanceOf(to) + amount) <= maxWalletAmount, "Brewlabs: Expected wallet amount exceeds the maxWalletAmount.");
            }
        }

        _adjustTaxes(automatedMarketMakerPairs[from], automatedMarketMakerPairs[to], from, to);
        bool canSwap = balanceOf(address(this)) >= minimumTokensBeforeSwap;

        if (
            isTradingEnabled &&
            canSwap &&
            !_swapping &&
            _totalFee > 0 &&
            automatedMarketMakerPairs[to]
        ) {
            _swapping = true;
            _swapAndLiquify();
            _swapping = false;
        }

        bool takeFee = !_swapping && isTradingEnabled;

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }
        if (takeFee && _totalFee > 0) {
            uint256 fee = (amount * _totalFee) / 100;
            amount = amount - fee;
            super._transfer(from, address(this), fee);
        }
        super._transfer(from, to, amount);

        try dividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}
    }

    function _adjustTaxes(
        bool isBuyFromLp,
        bool isSelltoLp,
        address from,
        address to
    ) private {
        _liquidityFee = 0;
        _devFee = 0;
        _buyBackFee = 0;
        _stakingFee = 0;
        _holdersFee = 0;

        if (isBuyFromLp) {
            _liquidityFee = _base.liquidityFeeOnBuy;
            _devFee = _base.devFeeOnBuy;
            _buyBackFee = _base.buyBackFeeOnBuy;
            _stakingFee = _base.stakingFeeOnBuy;
            _holdersFee = _base.holdersFeeOnBuy;
        }
        if (isSelltoLp) {
            _liquidityFee = _base.liquidityFeeOnSell;
            _devFee = _base.devFeeOnSell;
            _buyBackFee = _base.buyBackFeeOnSell;
            _stakingFee = _base.stakingFeeOnSell;
            _holdersFee = _base.holdersFeeOnSell;
        }
        if (
            !isSelltoLp &&
            !isBuyFromLp &&
            (_feeOnSelectedWalletTransfers[from] || _feeOnSelectedWalletTransfers[to])
        ) {
            _liquidityFee = _base.liquidityFeeOnBuy;
            _devFee = _base.devFeeOnBuy;
            _buyBackFee = _base.buyBackFeeOnBuy;
            _stakingFee = _base.stakingFeeOnBuy;
            _holdersFee = _base.holdersFeeOnBuy;
        }
        _totalFee = _liquidityFee + _devFee + _buyBackFee + _stakingFee + _holdersFee;
        emit FeesApplied(_liquidityFee, _devFee, _buyBackFee, _stakingFee, _holdersFee, _totalFee);
    }

    function _setCustomSellTaxPeriod(
        CustomTaxPeriod storage map,
        uint8 _liquidityFeeOnSell,
        uint8 _devFeeOnSell,
        uint8 _buyBackFeeOnSell,
        uint8 _stakingFeeOnSell,
        uint8 _holdersFeeOnSell
    ) private {
        if (map.liquidityFeeOnSell != _liquidityFeeOnSell) {
            emit CustomTaxPeriodChange(
                _liquidityFeeOnSell,
                map.liquidityFeeOnSell,
                "liquidityFeeOnSell",
                map.periodName
            );
            map.liquidityFeeOnSell = _liquidityFeeOnSell;
        }
        if (map.devFeeOnSell != _devFeeOnSell) {
            emit CustomTaxPeriodChange(
                _devFeeOnSell,
                map.devFeeOnSell,
                "devFeeOnSell",
                map.periodName
            );
            map.devFeeOnSell = _devFeeOnSell;
        }
        if (map.buyBackFeeOnSell != _buyBackFeeOnSell) {
            emit CustomTaxPeriodChange(
                _buyBackFeeOnSell,
                map.buyBackFeeOnSell,
                "buyBackFeeOnSell",
                map.periodName
            );
            map.buyBackFeeOnSell = _buyBackFeeOnSell;
        }
        if (map.stakingFeeOnSell != _stakingFeeOnSell) {
            emit CustomTaxPeriodChange(
                _stakingFeeOnSell,
                map.stakingFeeOnSell,
                "stakingFeeOnSell",
                map.periodName
            );
            map.stakingFeeOnSell = _stakingFeeOnSell;
        }
        if (map.holdersFeeOnSell != _holdersFeeOnSell) {
            emit CustomTaxPeriodChange(
                _holdersFeeOnSell,
                map.holdersFeeOnSell,
                "holdersFeeOnSell",
                map.periodName
            );
            map.holdersFeeOnSell = _holdersFeeOnSell;
        }
    }

    function _setCustomBuyTaxPeriod(
        CustomTaxPeriod storage map,
        uint8 _liquidityFeeOnBuy,
        uint8 _devFeeOnBuy,
        uint8 _buyBackFeeOnBuy,
        uint8 _stakingFeeOnBuy,
        uint8 _holdersFeeOnBuy
    ) private {
        if (map.liquidityFeeOnBuy != _liquidityFeeOnBuy) {
            emit CustomTaxPeriodChange(
                _liquidityFeeOnBuy,
                map.liquidityFeeOnBuy,
                "liquidityFeeOnBuy",
                map.periodName
            );
            map.liquidityFeeOnBuy = _liquidityFeeOnBuy;
        }
        if (map.devFeeOnBuy != _devFeeOnBuy) {
            emit CustomTaxPeriodChange(
                _devFeeOnBuy,
                map.devFeeOnBuy,
                "devFeeOnBuy",
                map.periodName
            );
            map.devFeeOnBuy = _devFeeOnBuy;
        }
        if (map.buyBackFeeOnBuy != _buyBackFeeOnBuy) {
            emit CustomTaxPeriodChange(
                _buyBackFeeOnBuy,
                map.buyBackFeeOnBuy,
                "buyBackFeeOnBuy",
                map.periodName
            );
            map.buyBackFeeOnBuy = _buyBackFeeOnBuy;
        }
        if (map.stakingFeeOnBuy != _stakingFeeOnBuy) {
            emit CustomTaxPeriodChange(
                _stakingFeeOnBuy,
                map.stakingFeeOnBuy,
                "stakingFeeOnBuy",
                map.periodName
            );
            map.stakingFeeOnBuy = _stakingFeeOnBuy;
        }
        if (map.holdersFeeOnBuy != _holdersFeeOnBuy) {
            emit CustomTaxPeriodChange(
                _holdersFeeOnBuy,
                map.holdersFeeOnBuy,
                "holdersFeeOnBuy",
                map.periodName
            );
            map.holdersFeeOnBuy = _holdersFeeOnBuy;
        }
    }

    function _swapAndLiquify() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 initialETHBalance = address(this).balance;

        uint256 amountToLiquify = (contractBalance * _liquidityFee) / _totalFee / 2;
        uint256 amountForStaking = (contractBalance * _stakingFee) / _totalFee;
        uint256 amountToSwap = contractBalance - (amountToLiquify + amountForStaking);

        _swapTokensForETH(amountToSwap);

        uint256 ETHBalanceAfterSwap = address(this).balance - initialETHBalance;
        uint256 totalETHFee = _totalFee - (_liquidityFee / 2) - _stakingFee;
        uint256 amountETHLiquidity = (ETHBalanceAfterSwap * _liquidityFee) / totalETHFee / 2;
        uint256 amountETHBuyBack = (ETHBalanceAfterSwap * _buyBackFee) / totalETHFee;
        uint256 amountETHDev = (ETHBalanceAfterSwap * _devFee) / totalETHFee;
        uint256 amountETHHolders = ETHBalanceAfterSwap - (amountETHLiquidity + amountETHBuyBack + amountETHDev);

        Address.sendValue(payable(buyBackWallet),amountETHBuyBack);
        Address.sendValue(payable(devWallet),amountETHDev);

        if (amountToLiquify > 0) {
            _addLiquidity(amountToLiquify, amountETHLiquidity);
            emit SwapAndLiquify(amountToSwap, amountETHLiquidity, amountToLiquify);
        }

        bool success = IERC20(address(this)).transfer(address(stakingAddress), amountForStaking);

        (success, ) = address(dividendTracker).call{ value: amountETHHolders }("");
        if (success) {
            emit DividendsSent(amountETHHolders);
        }
    }

    function _swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            1, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{ value: ethAmount }(
            address(this),
            tokenAmount,
            1, // slippage is unavoidable
            1, // slippage is unavoidable
            liquidityWallet,
            block.timestamp
        );
    }
}

contract BrewlabsDividendTracker is DividendPayingToken {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;

    mapping(address => bool) public excludedFromDividends;
    mapping(address => uint256) public lastClaimTimes;
    uint256 public claimWait;
    uint256 public minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor() DividendPayingToken("Brewlabs_Dividend_Tracker", "Brewlabs_Dividend_Tracker") {
        claimWait = 3600;
        minimumTokenBalanceForDividends = 0 * (10**18);
    }

    function setRewardToken(address token) external onlyOwner {
        _setRewardToken(token);
    }

    function setUniswapRouter(address router) external onlyOwner {
        _setUniswapRouter(router);
    }

    function _transfer(
        address,
        address,
        uint256
    ) internal pure override {
        require(false, "Brewlabs_Dividend_Tracker: No transfers allowed");
    }

    function excludeFromDividends(address account) external onlyOwner {
        require(!excludedFromDividends[account]);
        excludedFromDividends[account] = true;
        _setBalance(account, 0);
        tokenHoldersMap.remove(account);
        emit ExcludeFromDividends(account);
    }

    function setTokenBalanceForDividends(uint256 newValue) external onlyOwner {
        require(
            minimumTokenBalanceForDividends != newValue,
            "Brewlabs_Dividend_Tracker: minimumTokenBalanceForDividends already the value of 'newValue'."
        );
        minimumTokenBalanceForDividends = newValue;
    }

    function getNumberOfTokenHolders() external view returns (uint256) {
        return tokenHoldersMap.keys.length;
    }

    function setBalance(address payable account, uint256 newBalance) external onlyOwner {
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

    function processAccount(address payable account, bool automatic)
        public
        onlyOwner
        returns (bool)
    {
        uint256 amount = _withdrawDividendOfUser(account);
        if (amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
            return true;
        }
        return false;
    }
}