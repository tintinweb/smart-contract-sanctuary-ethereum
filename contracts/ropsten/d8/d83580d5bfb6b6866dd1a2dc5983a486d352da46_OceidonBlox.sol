/**
 *Submitted for verification at Etherscan.io on 2022-02-11
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.10;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    
    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
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

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - amount);
            }
        }

        _transfer(sender, recipient, amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
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
	function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {

    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
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

library Address {
    function isContract(address account) internal view returns (bool) {
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

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) internal pure returns (bytes memory) {
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

library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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


contract OceidonBlox is ERC20, Ownable {
    using Address for address;
    using SafeERC20 for IERC20;
	
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
	
    uint256[] public developmentFee;
    uint256[] public liquidityFee;
	uint256[] public otherFee;
		
	uint256 private developmentFeeTotal;
	uint256 private liquidityFeeTotal;
	uint256 private otherFeeTotal;
	
    uint256 public swapTokensAtAmount = 10_000_000 * (10**18);
	uint256 public maxTxAmount = 10_000_000_000 * (10**18);
	uint256 public maxWalletAmount = 10_000_000_000 * (10**18);
	
	address public constant USDCAddress = 0xFE724a829fdF12F7012365dB98730EEe33742ea2;
	address public otherTokenAddress;
	
	address public developmentFeeAddress = 0x06c90176ceF13D228aD13E3256370F24F8b499Ab;
	address public otherTokenFeeAddress;
	
	bool private swapping;
	bool public swapEnable = true;
    bool public tradingEnabled = false;
    bool private initFlag = true;
	
    mapping (address => bool) public isExcludedFromFees;
    mapping (address => bool) public automatedMarketMakerPairs;
	mapping (address => bool) public isExcludedFromMaxWalletToken;
	
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
	event ExcludeMaxWalletToken(address indexed account, bool isExcluded);
    event TradingEnabled(bool enabled);
	
    constructor() ERC20("OceidonBlox", "OBLOX") {
    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair   = _uniswapV2Pair;
    }

    function init() external onlyOwner {
        require(initFlag, "This function can only be called once");

        _setAutomatedMarketMakerPair(uniswapV2Pair, true);
		
        excludeFromFees(address(this), true);
		excludeFromFees(owner(), true);

		isExcludedFromMaxWalletToken[uniswapV2Pair] = true;
		isExcludedFromMaxWalletToken[address(this)] = true;
		isExcludedFromMaxWalletToken[owner()] = true;

		developmentFee.push(200);
		developmentFee.push(200);
		developmentFee.push(200);
		
		liquidityFee.push(500);
		liquidityFee.push(500);
		liquidityFee.push(500);
		
		otherFee.push(0);
		otherFee.push(0);
		otherFee.push(0);
		
        _mint(owner(), 10_000_000_000 * (10**18));

        initFlag = false;
    }
	
    receive() external payable {
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
	
	function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(tradingEnabled, "Trading and token transfers disabled.");
        
        if(from != owner() && to != owner()) {
		    require(amount <= maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
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
			
			swapTokensForUSDC(tokenToDevelopment);
			
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
            uint256 originalAmount = address(this).balance;
            uint256 amountToSwap = calculateSwapInAmount(tokenReserve, tokenToLiqudity);
			uint256 amountLeft = tokenToLiqudity - amountToSwap;
			swapTokensForETH(amountToSwap);
            uint256 initialBalance = address(this).balance - originalAmount;
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
		    uint256 allfee;
		    allfee = collectFee(amount, automatedMarketMakerPairs[to], !automatedMarketMakerPairs[from] && !automatedMarketMakerPairs[to]);
			super._transfer(from, address(this), allfee);
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
	
	function collectFee(uint256 amount, bool sell, bool p2p) private returns (uint256) {
        uint256 totalFee;
		
        uint256 _developmentFee = amount * (p2p ? developmentFee[2] : sell ? developmentFee[1] : developmentFee[0]) / 10000;
		developmentFeeTotal = developmentFeeTotal + _developmentFee;
		
		uint256 _liquidityFee = amount * (p2p ? liquidityFee[2] : sell ? liquidityFee[1] : liquidityFee[0]) / 10000;
		liquidityFeeTotal = liquidityFeeTotal + _liquidityFee;
		
		uint256 _otherFee = amount * (p2p ? otherFee[2] : sell ? otherFee[1] : otherFee[0]) / 10000;
		otherFeeTotal = otherFeeTotal + _otherFee;
		
		totalFee = _developmentFee + _liquidityFee + _otherFee;
        return totalFee;
    }
	
	function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
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
	
	function swapTokensForUSDC(uint256 tokenAmount) private {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = USDCAddress;
		
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            developmentFeeAddress,
            block.timestamp
        );
    }
	
	function swapTokensForOther(uint256 tokenAmount) private {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
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
        IERC20(tokenAddress).transfer(to, amount);
    }
	
	function migrateETH(address payable recipient) public onlyOwner {
        Address.sendValue(recipient, address(this).balance);
    }
}