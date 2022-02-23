/**
 *Submitted for verification at Etherscan.io on 2022-02-22
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.7;

abstract contract Initializable {
    bool private _initialized;

    bool private _initializing;

    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    uint256[50] private __gap;
}


abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    uint256[49] private __gap;
}

interface IERC20Upgradeable {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

library AddressUpgradeable {
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
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
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
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

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        // emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    uint256[45] private __gap;
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Pair {
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function token0() external view returns (address);

    function token1() external view returns (address);
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB, uint liquidity);
	function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {

    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
}

interface IOceidonNFT {
    function balanceOf(address account, uint256 id) external view returns (uint256);
}

library Babylonian {
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0
    }
}

library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract OceidonBlox is ERC20Upgradeable, OwnableUpgradeable {
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;
	
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
	
    uint256[] public developmentFee;
    uint256[] public liquidityFee;
	uint256[] public otherFee;
		
	uint256 private developmentFeeTotal;
	uint256 private liquidityFeeTotal;
	uint256 private otherFeeTotal;
	
    uint256 public swapTokensAtAmount;
	uint256 public maxTxAmount;
	uint256 public maxWalletAmount;
	
	address public USDCAddress;
	address public otherTokenAddress;
	
	address public developmentFeeAddress;
	address public otherTokenFeeAddress;
	
	bool private swapping;
	bool public swapEnable;
    bool public tradingEnabled;
    bool private initFlag;
	
    mapping (address => bool) public isExcludedFromFees;
    mapping (address => bool) public automatedMarketMakerPairs;
	mapping (address => bool) public isExcludedFromMaxWalletToken;
    address public constant uniswapV2_OBLOXUSDCPair = 0xB1636Da7243bED31B988d68026C3289Df258d252;
    mapping (address => bool) public blacklist;
    address public OBLOXNFT;
    bool public tokenDiscountEnable;
    uint256 public token2Discount;
    uint256 public token3Discount;
	
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
	event ExcludeMaxWalletToken(address indexed account, bool isExcluded);
    event TradingEnabled(bool enabled);
    event SetBlacklist(address indexed account, bool indexed isBanned);
    event SwapToUSDC(address indexed token0, address indexed token1);

    function initialize() external initializer {
        __Ownable_init();
        __ERC20_init("Oceidon Blox", "OBLOX");
        
        USDCAddress = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F;
    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), USDCAddress);

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair   = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(uniswapV2Pair, true);
		
        excludeFromFees(address(this), true);
		excludeFromFees(owner(), true);

		isExcludedFromMaxWalletToken[uniswapV2Pair] = true;
		isExcludedFromMaxWalletToken[address(this)] = true;
		isExcludedFromMaxWalletToken[owner()] = true;

        swapTokensAtAmount = 10_000_000 * (10**18);
        maxTxAmount = 10_000_000_000 * (10**18);
        maxWalletAmount = 10_000_000_000 * (10**18);

        developmentFeeAddress = 0xeC82E2d1184a38c192A0cBD8Fa84b6A3d6A127DB;

		developmentFee.push(200);
		developmentFee.push(200);
		developmentFee.push(200);
		
		liquidityFee.push(500);
		liquidityFee.push(500);
		liquidityFee.push(500);
		
		otherFee.push(0);
		otherFee.push(0);
		otherFee.push(0);

        tradingEnabled = true;
        swapEnable = false;
        initFlag = true;
        tokenDiscountEnable = true;
        token2Discount = 5000;
        token3Discount = 7500;
        OBLOXNFT = 0x1C3668D33d8BA5b848Ce78684E72f5069f57789B;
		
        _mint(0x203C4186280c6fEed11200b8453A2584feEBC306, 10_000_000_000 * (10**18));
    }
	
    receive() external payable {
  	}

    function setUsdcAddr(address _usdc) external onlyOwner {
        USDCAddress = _usdc;
    }

    function setObloxAddr(address _oblox) external onlyOwner {
        OBLOXNFT = _oblox;
    }

    function enableTrading(bool _enabled) external onlyOwner {
        tradingEnabled = _enabled;
        emit TradingEnabled(_enabled);
    }
	
	function setSwapTokensAtAmount(uint256 amount) external onlyOwner {
  	     require(amount <= totalSupply(), "Amount cannot be over the total supply.");
		 swapTokensAtAmount = amount;
  	}
	
	function setMaxTxAmount(uint256 amount) external onlyOwner {
	     require(amount <= totalSupply(), "Amount cannot be over the total supply.");
         maxTxAmount = amount;
    }
	
	function setMaxWalletAmount(uint256 amount) public onlyOwner {
		require(amount <= totalSupply(), "Amount cannot be over the total supply.");
		maxWalletAmount = amount;
	}
	
	function setSwapEnable(bool _enabled) public onlyOwner {
        swapEnable = _enabled;
    }
	
	function setDevelopmentFee(uint256 buy, uint256 sell, uint256 p2p) external onlyOwner {
        require(buy <= 10000, "Exceeds maximum fee");
        require(sell <= 10000, "Exceeds maximum fee");
        require(p2p <= 10000, "Exceeds maximum fee");

		developmentFee[0] = buy;
		developmentFee[1] = sell;
		developmentFee[2] = p2p;
	}
	
	function setLiquidityFee(uint256 buy, uint256 sell, uint256 p2p) external onlyOwner {
        require(buy <= 10000, "Exceeds maximum fee");
        require(sell <= 10000, "Exceeds maximum fee");
        require(p2p <= 10000, "Exceeds maximum fee");

		liquidityFee[0] = buy;
		liquidityFee[1] = sell;
		liquidityFee[2] = p2p;
	}
	
	function setOtherFee(uint256 buy, uint256 sell, uint256 p2p) external onlyOwner {
        require(buy <= 10000, "Exceeds maximum fee");
        require(sell <= 10000, "Exceeds maximum fee");
        require(p2p <= 10000, "Exceeds maximum fee");
        
		otherFee[0] = buy;
		otherFee[1] = sell;
		otherFee[2] = p2p;
	}
	
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(isExcludedFromFees[account] != excluded, "Account is already the value of 'excluded'");
        isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }
	
	function excludeFromMaxWalletToken(address account, bool excluded) public onlyOwner {
        require(isExcludedFromMaxWalletToken[account] != excluded, "Account is already the value of 'excluded'");
        isExcludedFromMaxWalletToken[account] = excluded;
        emit ExcludeMaxWalletToken(account, excluded);
    }
	
    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "The Uniswap pair cannot be removed from automatedMarketMakerPairs");
        _setAutomatedMarketMakerPair(pair, value);
    }
	
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }
	
	function setDevelopmentFeeAddress(address payable newAddress) external onlyOwner {
       require(newAddress != address(0), "zero-address not allowed");
	   developmentFeeAddress = newAddress;
    }
	
	function setOtherTokenFeeAddress(address payable newAddress) external onlyOwner {
       require(newAddress != address(0), "zero-address not allowed");
	   otherTokenFeeAddress = newAddress;
    }
	
	function setOtherTokenAddress(address newAddress) external onlyOwner {
       require(newAddress != address(0), "zero-address not allowed");
	   otherTokenAddress = newAddress;
    }

    function setBlacklist(address account, bool isBanned) public onlyOwner {
        require(blacklist[account] != isBanned, "This account is already set to that value");
        blacklist[account] = isBanned;
        emit SetBlacklist(account, isBanned);
    }

    function setBlacklistBatch(address[] memory accounts, bool isBanned) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            blacklist[accounts[i]] = isBanned;
        }
    }

    function setTokenDiscountEnable(bool _enabled) public onlyOwner {
        tokenDiscountEnable = _enabled;
    }

    function setTokensDiscount(uint256 _token2Discount, uint256 _token3Discount) public onlyOwner {
        require(_token2Discount <= 10000, "Exceeds maximum fee");
        require(_token3Discount <= 10000, "Exceeds maximum fee");

        token2Discount = _token2Discount;
        token3Discount = _token3Discount;
    }
	
	function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(blacklist[from] == false && blacklist[to] == false, "Sender or receiver are not allowed to trade");
        
        if(from != owner() && to != owner()) {
		    require(amount <= maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            require(tradingEnabled, "Trading and token transfers disabled.");
		}
		
		if(!isExcludedFromMaxWalletToken[to] && !automatedMarketMakerPairs[to]) {
            uint256 balanceRecepient = balanceOf(to);
            require(balanceRecepient + amount <= maxWalletAmount, "Exceeds maximum wallet token amount");
        }
		
		uint256 contractTokenBalance = balanceOf(address(this));
		bool canSwap = contractTokenBalance >= swapTokensAtAmount;
		
		if (!swapping && canSwap && swapEnable) {
			swapping = true;
			
			uint256 tokenToDevelopment = developmentFeeTotal;
			uint256 tokenToLiqudity = liquidityFeeTotal;
			uint256 tokenToOther = otherFeeTotal;
			
			swapTokensForUSDC(tokenToDevelopment, developmentFeeAddress);
			
			if(tokenToOther > 0 && otherTokenAddress != address(0)){
			   swapTokensForOther(tokenToOther);
			}
			
            IUniswapV2Pair pair = IUniswapV2Pair(uniswapV2Pair);
            (uint256 res0, uint256 res1, ) = pair.getReserves();

            uint256 tokenReserve;
            if(address(this) == pair.token0()) {
                tokenReserve = res0;
            } else {
                tokenReserve = res1;
            }
            uint256 originalAmount = IERC20Upgradeable(USDCAddress).balanceOf(address(this));
            uint256 amountToSwap = calculateSwapInAmount(tokenReserve, tokenToLiqudity);
			uint256 amountLeft = tokenToLiqudity - amountToSwap;
			swapTokensForUSDC(amountToSwap, address(this));
            uint256 initialBalance = IERC20Upgradeable(USDCAddress).balanceOf(address(this)) - originalAmount;
			addLiquidity(amountLeft, initialBalance);
			
			developmentFeeTotal = developmentFeeTotal - tokenToDevelopment;
			liquidityFeeTotal = liquidityFeeTotal - tokenToLiqudity;
			otherFeeTotal = otherFeeTotal - tokenToOther;
			swapping = false;
		}
		
        bool takeFee = !swapping;
		if(isExcludedFromFees[from] || isExcludedFromFees[to]) {
            takeFee = false;
        }
		
		if(takeFee) 
		{
            uint256 discountForNftHolders = 10000;
            if(tokenDiscountEnable) {
                if(IOceidonNFT(OBLOXNFT).balanceOf(from, 3) >= 1 || IOceidonNFT(OBLOXNFT).balanceOf(to, 3) >= 1) {
                    discountForNftHolders = token3Discount;
                }
                if(IOceidonNFT(OBLOXNFT).balanceOf(from, 2) >= 1 || IOceidonNFT(OBLOXNFT).balanceOf(to, 2) >= 1) {
                    discountForNftHolders = token2Discount;
                }
            }

		    uint256 allfee;
		    allfee = collectFee(amount, automatedMarketMakerPairs[to], !automatedMarketMakerPairs[from] && !automatedMarketMakerPairs[to], discountForNftHolders);
            if(allfee > 0) {
			    super._transfer(from, address(this), allfee);
            }
			amount = amount - allfee;
		}
        super._transfer(from, to, amount);
    }

    function calculateSwapInAmount(uint256 reserveIn, uint256 userIn)
        internal
        pure
        returns (uint256)
    {
        return
            (Babylonian.sqrt(
                reserveIn * ((userIn * 3988000) + (reserveIn * 3988009))
            ) - (reserveIn * 1997)) / 1994;
    }
	
	function collectFee(uint256 amount, bool sell, bool p2p, uint256 discountForNftHolders) private returns (uint256) {
        uint256 totalFee;
		
        uint256 _developmentFee = amount * (p2p ? developmentFee[2] : sell ? developmentFee[1] : developmentFee[0]) / 10000 * discountForNftHolders / 10000;
		developmentFeeTotal = developmentFeeTotal + _developmentFee;
		
		uint256 _liquidityFee = amount * (p2p ? liquidityFee[2] : sell ? liquidityFee[1] : liquidityFee[0]) / 10000 * discountForNftHolders / 10000;
		liquidityFeeTotal = liquidityFeeTotal + _liquidityFee;
		
		uint256 _otherFee = amount * (p2p ? otherFee[2] : sell ? otherFee[1] : otherFee[0]) / 10000 * discountForNftHolders / 10000;
		otherFeeTotal = otherFeeTotal + _otherFee;
		
		totalFee = _developmentFee + _liquidityFee + _otherFee;
        return totalFee;
    }
	
	function addLiquidity(uint256 tokenAmount, uint256 usdcAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        IERC20Upgradeable(USDCAddress).approve(address(uniswapV2Router), usdcAmount);
        uniswapV2Router.addLiquidity(
            address(this),
            USDCAddress,
            tokenAmount,
            usdcAmount, 
            0,
            0,
            address(this),
            block.timestamp
        );
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

	function swapTokensForUSDC(uint256 tokenAmount, address receiver) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = USDCAddress;
		emit SwapToUSDC(path[0], path[1]);
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            receiver,
            block.timestamp
        );
    }
	
	function swapTokensForOther(uint256 tokenAmount) private {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = USDCAddress;
        path[2] = otherTokenAddress;

        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            otherTokenFeeAddress,
            block.timestamp
        );
    }
	
	function transferTokens(address tokenAddress, address to, uint256 amount) public onlyOwner {
        IERC20Upgradeable(tokenAddress).transfer(to, amount);
    }
	
	function migrateETH(address payable recipient) public onlyOwner {
        AddressUpgradeable.sendValue(recipient, address(this).balance);
    }
}