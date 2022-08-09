/**
 *Submitted for verification at Etherscan.io on 2022-08-09
*/

/*
ETH 4000 Official Community 📈
📍  https://eth4000.com
📍  https://twitter.com/ETH_4000
📍  https://medium.com/@eth4000.official
📍  https://t.me/eth4000
Let's Make Ethereum Great Again!!!🚀🌕
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.13;

interface IERC20 {
	
	function totalSupply() external view returns (uint256);
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
	function allowance(address owner, address spender) external view returns (uint256);
	function approve(address spender, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
	
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);

	event TransferDetails(address indexed from, address indexed to, uint256 total_Amount, uint256 reflected_amount, uint256 total_TransferAmount, uint256 reflected_TransferAmount);
}

abstract contract Context {
	function _msgSender() internal view virtual returns (address) {
		return msg.sender;
	}

	function _msgData() internal view virtual returns (bytes calldata) {
		this; 
		return msg.data;
	}
}

library Address {
	
	function isContract(address account) internal view returns (bool) {
		uint256 size;
		assembly { size := extcodesize(account) }
		return size > 0;
	}

	function sendValue(address payable recipient, uint256 amount) internal {
		require(address(this).balance >= amount, "Address: insufficient balance");
		(bool success, ) = recipient.call{ value: amount }("");
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
		(bool success, bytes memory returndata) = target.call{ value: value }(data);
		return _verifyCallResult(success, returndata, errorMessage);
	}
	
	function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
		return functionStaticCall(target, data, "Address: low-level static call failed");
	}
	
	function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
		require(isContract(target), "Address: static call to non-contract");
		(bool success, bytes memory returndata) = target.staticcall(data);
		return _verifyCallResult(success, returndata, errorMessage);
	}


	function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
		return functionDelegateCall(target, data, "Address: low-level delegate call failed");
	}
	
	function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
		require(isContract(target), "Address: delegate call to non-contract");
		(bool success, bytes memory returndata) = target.delegatecall(data);
		return _verifyCallResult(success, returndata, errorMessage);
	}

	function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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



abstract contract Ownable is Context {
	address private _owner;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
	constructor () {
		_owner = _msgSender();
		emit OwnershipTransferred(address(0), _owner);
	}
	
	function owner() public view virtual returns (address) {
		return _owner;
	}
	
	modifier onlyOwner() {
		require(owner() == _msgSender(), "Ownable: caller is not the owner");
		_;
	}

	function transferOwnership(address newOwner) public virtual onlyOwner {
		require(newOwner != address(0), "Ownable: new owner is the zero address");
		emit OwnershipTransferred(_owner, newOwner);
		_owner = newOwner;
	}

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

}

interface IUniswapV2Factory {
	function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router01 {
	function factory() external pure returns (address);
	function WETH() external pure returns (address);
	function addLiquidityETH(
		address token,
		uint amountTokenDesired,
		uint amountTokenMin,
		uint amountETHMin,
		address to,
		uint deadline
	) external payable returns (uint amountToken, uint amountETH, uint liquidity);
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


contract ETHFourThousand is Context, IERC20, Ownable {
	using Address for address;

	mapping (address => uint256) public _rewardedBalance;
	mapping (address => uint256) public _totalBalance;
	mapping (address => mapping (address => uint256)) private _allowances;
	
	mapping (address => bool) public _isExcluded;
	
	bool public blacklistMode = true;
	mapping (address => bool) public isBlacklisted;

	bool public tradingOpen = false;
	bool public TOBITNA = true;
	
	uint256 private constant MAX = ~uint256(0);

	uint8 public constant decimals = 9;
	uint256 public constant totalSupply = 1 * 10**8 * 10**decimals;

	uint256 private _reflectSupply   = (MAX - (MAX % totalSupply));
	
	string public constant name = "ETH4000";
	string public constant symbol = "ETH4000";
	
	uint256 public _swapToFeeThreshold_treasury = totalSupply / 5000;
	uint256 public _swapToFeeThreshold_marketing = totalSupply / 5000;
	 
	uint256 public _treasuryBalanceLimit = 0;
	uint256 public _marketingBalanceLimit = 0;
	 
	uint256 public _reflectionFee = 150; //1.5%
	uint256 private _old_reflectionFee = _reflectionFee;
	uint256 public _contractReflectionAmount = 0;
	 
	uint256 public _marketingFee = 75;//0.75%
	uint256 private _old_marketingFee = _marketingFee;
	address payable public _marketingWallet;
	 
	uint256 public _treasuryFee = 75;//0.75%
	uint256 private _old_treasuryFee = _treasuryFee;
	address payable public _treasuryWallet;
	 
	uint256 public _liquidityFee = 100; //1.5%
	uint256 private _old_liquidtyFee = _liquidityFee;
	
	uint256 public _burntFee = 100;//1%
	uint256 private _old_burntFee = _burntFee;
	address constant burntWallet = 0x000000000000000000000000000000000000dEaD;


	uint256 public _fee_denominator = 10000;

	IUniswapV2Router02 public immutable uniswapV2Router;
	address public immutable uniswapV2Pair;
	bool inSwapAndLiquify;
	bool public swapAndLiquifyEnabled = true;


 
	uint256 public _maxWallet = totalSupply / 50;
	uint256 public _maxTxnAmount =  totalSupply / 100;

	address[] public _excluded;
	mapping (address => bool) public isExcludedFromFee;
	mapping (address => bool) public isExcludedFromTxnLimit;
	mapping (address => bool) public isExcludedFromWalletLimit;
 
	uint256 public swapThreshold =  ( totalSupply * 2 ) / 1000;
 
	uint256 public sellMultiplier = 100;
	uint256 public buyMultiplier = 100;
	uint256 public transferMultiplier = 100;

	event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
	event SwapAndLiquify(
		uint256 tokensSwapped,
		uint256 ethReceived,
		uint256 tokensIntoLiqudity
	);

	
	modifier lockTheSwap {
		inSwapAndLiquify = true;
		_;
		inSwapAndLiquify = false;
	}
	
	constructor () {
		_rewardedBalance[owner()] = _reflectSupply;

		
		_marketingWallet = payable(0xdaDcbDFd7529f101E7f64F67cc331f3e90f27ca9);
		_treasuryWallet = payable(0x0b20a925355DCE12D19E2890697B1FE153b4ccE6);
		
		IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
		uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
		uniswapV2Router = _uniswapV2Router;

		isExcludedFromFee[msg.sender] = true;
		isExcludedFromFee[address(this)] = true;
		isExcludedFromFee[burntWallet] = true;

		isExcludedFromTxnLimit[msg.sender] = true;
		isExcludedFromTxnLimit[burntWallet] = true;
		isExcludedFromTxnLimit[_marketingWallet] = true;
		isExcludedFromTxnLimit[_treasuryWallet] = true;

		isExcludedFromWalletLimit[msg.sender] = true;
		isExcludedFromWalletLimit[address(this)] = true;
		isExcludedFromWalletLimit[burntWallet] = true;
		isExcludedFromWalletLimit[_marketingWallet] = true;
		isExcludedFromWalletLimit[_treasuryWallet] = true;
		
		emit Transfer(address(0), owner(), totalSupply);
	}

	function balanceOf(address account) public view override returns (uint256) {
		if (_isExcluded[account]) return _totalBalance[account];
		return tokenFromReflection(_rewardedBalance[account]);
	}

	function transfer(address recipient, uint256 amount) public override returns (bool) {
		_transfer(_msgSender(), recipient, amount);
		return true;
	}

	function allowance(address owner, address spender) public view override returns (uint256) {
		return _allowances[owner][spender];
	}

	function approve(address spender, uint256 amount) public override returns (bool) {
		_approve(_msgSender(), spender, amount);
		return true;
	}

	function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
		_transfer(sender, recipient, amount);
		require (_allowances[sender][_msgSender()] >= amount,"ERC20: transfer amount exceeds allowance");
		_approve(sender, _msgSender(), (_allowances[sender][_msgSender()]-amount));
		return true;
	}

	function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
		_approve(_msgSender(), spender, (_allowances[_msgSender()][spender] + addedValue));
		return true;
	}

	function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
		require (_allowances[_msgSender()][spender] >= subtractedValue,"ERC20: decreased allowance below zero");
		_approve(_msgSender(), spender, (_allowances[_msgSender()][spender] - subtractedValue));
		return true;
	}

	function ___tokenInfo () public view returns(
		uint256 MaxTxAmount,
		uint256 MaxWalletToken,
		uint256 TotalSupply,
		uint256 Reflected_Supply,
		uint256 Reflection_Rate,
		bool TradingOpen
		) {
		return (_maxTxnAmount, _maxWallet, totalSupply, _reflectSupply, _getRate(), tradingOpen );
	}

	function ___feesInfo () public view returns(
		uint256 SwapThreshold,
		uint256 contractTokenBalance,
		uint256 Reflection_tokens_stored
		) {
		return (swapThreshold, balanceOf(address(this)), _contractReflectionAmount);
	}

	function ___wallets () public view returns(
		uint256 Reflection_Fees,
		uint256 Liquidity_Fee,
		uint256 Treasury_Fee,
		uint256 Treasury_Fee_Convert_Limit,
		uint256 Treasury_Fee_Minimum_Balance,
		uint256 Marketing_Fee,
		uint256 Marketing_Fee_Convert_Limit,
		uint256 Marketing_Fee_Minimum_Balance
	) {
		return ( _reflectionFee, _liquidityFee,
			_treasuryFee,_swapToFeeThreshold_treasury,_treasuryBalanceLimit,
			_marketingFee,_swapToFeeThreshold_marketing, _marketingBalanceLimit);
	}

	function changeWallets(address _newMarketing, address _newTreasury) external onlyOwner {
		_marketingWallet = payable(_newMarketing);
		_treasuryWallet = payable(_newTreasury);
	}

	function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
		require(rAmount <= _reflectSupply, "Amount must be less than total reflections");
		uint256 currentRate =  _getRate();
		return (rAmount / currentRate);
	}

	function excludeFromReward(address account) external onlyOwner {
		require(!_isExcluded[account], "Account is already excluded");
		if(_rewardedBalance[account] > 0) {
			_totalBalance[account] = tokenFromReflection(_rewardedBalance[account]);
		}
		_isExcluded[account] = true;
		_excluded.push(account);
	}

	function removeExcludeFromReward(address account) external onlyOwner {
		require(_isExcluded[account], "Account is already included");
		for (uint256 i = 0; i < _excluded.length; i++) {
			if (_excluded[i] == account) {
				_excluded[i] = _excluded[_excluded.length - 1];
				_totalBalance[account] = 0;
				_isExcluded[account] = false;
				_excluded.pop();
				break;
			}
		}
	}

	function tradingStatus(bool _status, bool _ab) external onlyOwner {
		tradingOpen = _status;
		TOBITNA = _ab;
	}

	function setMaxTxPercent_base1000(uint256 maxTxPercentBase1000) external onlyOwner {
		_maxTxnAmount = (totalSupply * maxTxPercentBase1000 ) / 1000;
	}

	 function setMaxWalletPercent_base1000(uint256 maxWallPercentBase1000) external onlyOwner {
		_maxWallet = (totalSupply * maxWallPercentBase1000 ) / 1000;
	}
	
	function setSwapSettings(bool _status, uint256 _threshold) external onlyOwner {
		swapAndLiquifyEnabled = _status;
		swapThreshold = _threshold;
	}

	function enable_blacklist(bool _status) external onlyOwner {
		blacklistMode = _status;
	}

	function manage_blacklist(address[] calldata addresses, bool status) external onlyOwner {
		for (uint256 i; i < addresses.length; ++i) {
			isBlacklisted[addresses[i]] = status;
		}
	}

	function manage_excludeFromFee(address[] calldata addresses, bool status) external onlyOwner {
		for (uint256 i; i < addresses.length; ++i) {
			isExcludedFromFee[addresses[i]] = status;
		}
	}

	function manage_TxLimitExempt(address[] calldata addresses, bool status) external onlyOwner {
		require(addresses.length < 501,"GAS Error: max limit is 500 addresses");
		for (uint256 i=0; i < addresses.length; ++i) {
			isExcludedFromTxnLimit[addresses[i]] = status;
		}
	}

	function manage_WalletLimitExempt(address[] calldata addresses, bool status) external onlyOwner {
		require(addresses.length < 501,"GAS Error: max limit is 500 addresses");
		for (uint256 i=0; i < addresses.length; ++i) {
			isExcludedFromWalletLimit[addresses[i]] = status;
		}
	}
	

	function clearStuckBalance(uint256 amountPercentage) external onlyOwner {
		uint256 amountToClear = amountPercentage * address(this).balance / 100;
		payable(msg.sender).transfer(amountToClear);
	}

	function clearStuckToken(address tokenAddress, uint256 tokens) external onlyOwner returns (bool success) {

		if(tokens == 0){
			tokens = IERC20(tokenAddress).balanceOf(address(this));
		}
		return IERC20(tokenAddress).transfer(msg.sender, tokens);
	}

	
	function _getRate() private view returns(uint256) {
		(uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
		return rSupply / tSupply;
	}

	function _getCurrentSupply() private view returns(uint256, uint256) {
		uint256 rSupply = _reflectSupply;
		uint256 tSupply = totalSupply;
		for (uint256 i = 0; i < _excluded.length; i++) {
			if (_rewardedBalance[_excluded[i]] > rSupply || _totalBalance[_excluded[i]] > tSupply) return (_reflectSupply, totalSupply);
			rSupply = rSupply - _rewardedBalance[_excluded[i]];
			tSupply = tSupply - _totalBalance[_excluded[i]];
		}
		if (rSupply < (_reflectSupply/totalSupply)) return (_reflectSupply, totalSupply);
		return (rSupply, tSupply);
	}


	function _getValues(uint256 tAmount, address recipient, address sender) private view returns (
		uint256 rAmount, uint256 rTransferAmount, uint256 rReflection,
		uint256 tTransferAmount, uint256 tMarketing, uint256 tLiquidity, uint256 tTreasury, uint256 tReflection, uint256 tBurnt) {

		uint256 multiplier = transferMultiplier;

		if(recipient == uniswapV2Pair) {
			multiplier = sellMultiplier;
		} else if(sender == uniswapV2Pair) {
			multiplier = buyMultiplier;
		}

		tMarketing = ( tAmount * _marketingFee ) * multiplier / (_fee_denominator * 100);
		tLiquidity = ( tAmount * _liquidityFee ) * multiplier / (_fee_denominator * 100);
		tTreasury = ( tAmount * _treasuryFee  ) * multiplier / (_fee_denominator * 100);
		tReflection = ( tAmount * _reflectionFee ) * multiplier  / (_fee_denominator * 100);
		tBurnt = (tAmount * _burntFee) * multiplier  / (_fee_denominator * 100);


		tTransferAmount = tAmount - ( tMarketing + tLiquidity + tTreasury + tReflection + tBurnt);
		rReflection = tReflection * _getRate();
		rAmount = tAmount * _getRate();
		rTransferAmount = tTransferAmount * _getRate();
	}


	function _fees_to_eth_process( address payable wallet, uint256 tokensToConvert) private lockTheSwap {

		uint256 rTokensToConvert = tokensToConvert * _getRate();
		_rewardedBalance[wallet] = _rewardedBalance[wallet] - rTokensToConvert;
		
		if (_isExcluded[wallet]){
			_totalBalance[wallet] = _totalBalance[wallet] - tokensToConvert;
		}

		_rewardedBalance[address(this)] = _rewardedBalance[address(this)] + rTokensToConvert;

		emit Transfer(wallet, address(this), tokensToConvert);

		swapTokensForEthAndSend(tokensToConvert,wallet);

	}

	function _fees_to_eth(uint256 tokensToConvert, address payable feeWallet, uint256 minBalanceToKeep) private {

		if(tokensToConvert == 0){
			return;
		}

		if(tokensToConvert > _maxTxnAmount){
			tokensToConvert = _maxTxnAmount;
		}

		if((tokensToConvert+minBalanceToKeep)  <= balanceOf(feeWallet)){
			_fees_to_eth_process(feeWallet,tokensToConvert);
		}
	}

	function _takeFee(uint256 feeAmount, address receiverWallet) private {
		uint256 reflectedReeAmount = feeAmount * _getRate();
		_rewardedBalance[receiverWallet] = _rewardedBalance[receiverWallet] + reflectedReeAmount;

		if(_isExcluded[receiverWallet]){
			_totalBalance[receiverWallet] = _totalBalance[receiverWallet] + feeAmount;
		}
		if(feeAmount > 0){
			emit Transfer(msg.sender, receiverWallet, feeAmount);
		}
	}

	function _setAllFees(uint256 marketingFee, uint256 liquidityFee, uint256 treasuryFee, uint256 reflectionFee, uint256 burntFee) private {
		_marketingFee = marketingFee;
		_liquidityFee = liquidityFee;
		_treasuryFee = treasuryFee;
		_reflectionFee = reflectionFee;
		_burntFee = burntFee;
	}

	function setMultipliers(uint256 _buy, uint256 _sell, uint256 _trans) external onlyOwner {
		buyMultiplier = _buy;
		sellMultiplier = _sell;
		transferMultiplier = _trans;
	}

	function setFeesThreshold(uint256 swapToFeeThreshold_marketing, uint256 swapToFeeThreshold_treasury,uint256 treasuryBalanceLimit, uint256 marketingBalanceLimit) external onlyOwner {
		_swapToFeeThreshold_marketing = swapToFeeThreshold_marketing;
		_swapToFeeThreshold_treasury = swapToFeeThreshold_treasury;
		_treasuryBalanceLimit = treasuryBalanceLimit;
		_marketingBalanceLimit = marketingBalanceLimit;
	}


	function setFees(uint256 marketingFee, uint256 liquidityFee, uint256 treasuryFee, uint256 reflectionFee, uint256 bruntFee) external onlyOwner {
		uint256 totalFees =  marketingFee + liquidityFee +  treasuryFee + reflectionFee + bruntFee;
		
		require(totalFees/100 < 25);
		_setAllFees( marketingFee, liquidityFee, treasuryFee, reflectionFee, bruntFee);
	}

	function removeAllFee() private {
		_old_marketingFee = _marketingFee;
		_old_liquidtyFee = _liquidityFee;
		_old_treasuryFee = _treasuryFee;
		_old_reflectionFee = _reflectionFee;
		_old_burntFee = _burntFee;

		_setAllFees(0,0,0,0,0);
	}
	
	function restoreAllFee() private {
		_setAllFees(_old_marketingFee, _old_liquidtyFee, _old_treasuryFee, _old_reflectionFee, _old_burntFee);
	}


	function swapAndLiquify(uint256 tokensToSwap) private lockTheSwap {
		
		uint256 tokensHalf = tokensToSwap / 2;
		uint256 contractETHBalance = address(this).balance;

		swapTokensForEth(tokensHalf);
		uint256 ethSwapped = address(this).balance - contractETHBalance;
		addLiquidity(tokensHalf,ethSwapped);

		emit SwapAndLiquify(tokensToSwap, tokensHalf, ethSwapped);

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
	}

	function swapTokensForEthAndSend(uint256 tokenAmount, address payable receiverWallet) private {
		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = uniswapV2Router.WETH();
		_approve(address(this), address(uniswapV2Router), tokenAmount);
		uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
			tokenAmount,
			0,
			path,
			receiverWallet,
			block.timestamp
		);
	}

	function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
		_approve(address(this), address(uniswapV2Router), tokenAmount);
		uniswapV2Router.addLiquidityETH{value: ethAmount}(
			address(this),
			tokenAmount,
			0,
			0,
			owner(),
			block.timestamp
		);
	}


	function _approve(address owner, address spender, uint256 amount) private {
		require(owner != address(0), "ERC20: approve from the zero address");
		require(spender != address(0), "ERC20: approve to the zero address");

		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}

	function _transfer(address from, address to, uint256 amount) private {

		if(from != owner() && to != owner()){
			require(tradingOpen,"Trading not open yet");

			if(TOBITNA && from == uniswapV2Pair){
				isBlacklisted[to] = true;
			}
		}

		if(blacklistMode && !TOBITNA){
			require(!isBlacklisted[from],"Blacklisted");
		}
		
		require((amount <= _maxTxnAmount) || isExcludedFromTxnLimit[from] || isExcludedFromTxnLimit[to], "Max TX Limit Exceeded");

		if (!isExcludedFromWalletLimit[from] && !isExcludedFromWalletLimit[to] && to != uniswapV2Pair) {
		    require((balanceOf(to) + amount) <= _maxWallet,"max wallet limit reached");
		}


		{
		    uint256 contractTokenBalance = balanceOf(address(this));
		
		    if(contractTokenBalance >= _maxTxnAmount) {
		        contractTokenBalance = _maxTxnAmount - 1;
		    }
		
		    bool overMinTokenBalance = contractTokenBalance >= swapThreshold;
		    if (overMinTokenBalance &&
		        !inSwapAndLiquify &&
		        from != uniswapV2Pair &&
		        swapAndLiquifyEnabled
		    ) {
		        contractTokenBalance = swapThreshold;
		        swapAndLiquify(contractTokenBalance);
		    }

		    if(!inSwapAndLiquify && from != uniswapV2Pair && swapAndLiquifyEnabled){
		        _fees_to_eth(_swapToFeeThreshold_treasury,_treasuryWallet, _treasuryBalanceLimit);
		        _fees_to_eth(_swapToFeeThreshold_marketing,_marketingWallet, _marketingBalanceLimit);
		    }
		
		}
		
		bool takeFee = true;
		if(isExcludedFromFee[from] || isExcludedFromFee[to]){
		    takeFee = false;
		    removeAllFee();
		}
		
		(uint256 rAmount, uint256 rTransferAmount, uint256 rReflection, uint256 tTransferAmount, uint256 tMarketing, uint256 tLiquidity, uint256 tTreasury,  uint256 tReflection, uint256 tBurnt) = _getValues(amount, to, from);

		_transferStandard(from, to, amount, rAmount, tTransferAmount, rTransferAmount);

		_reflectSupply = _reflectSupply - rReflection;
		_contractReflectionAmount = _contractReflectionAmount + tReflection;

		if(!takeFee){
		    restoreAllFee();
		} else{
		    _takeFee(tMarketing,_marketingWallet);
		    _takeFee(tLiquidity,address(this));
		    _takeFee(tTreasury,_treasuryWallet);
			_takeFee(tBurnt, burntWallet);
		}

	}

	function _transferStandard(address from, address to, uint256 tAmount, uint256 rAmount, uint256 tTransferAmount, uint256 rTransferAmount) private {
		_rewardedBalance[from]    = _rewardedBalance[from]  - rAmount;

		if (_isExcluded[from]){
		    _totalBalance[from]    = _totalBalance[from]      - tAmount;
		}

		if (_isExcluded[to]){
		    _totalBalance[to]      = _totalBalance[to]        + tTransferAmount;
		}
		_rewardedBalance[to]      = _rewardedBalance[to]    + rTransferAmount;

		if(tTransferAmount > 0){
			emit Transfer(from, to, tTransferAmount);	
		}
	}

	receive() external payable {}
}