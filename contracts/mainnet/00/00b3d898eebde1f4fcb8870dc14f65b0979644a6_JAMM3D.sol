/**
 *Submitted for verification at Etherscan.io on 2022-08-08
*/

pragma solidity ^0.5.17;

interface Callable {
	function tokenCallback(address _from, uint256 _tokens, bytes calldata _data) external returns (bool);
}

interface JAM {
	function balanceOf(address) external view returns (uint256);
	function allowance(address, address) external view returns (uint256);
	function transfer(address, uint256) external returns (bool);
	function transferFrom(address, address, uint256) external returns (bool);
}

contract JAMM3D {

	uint256 constant private FLOAT_SCALAR = 2**64;

	uint256 constant private BUY_TAX = 4;
	uint256 constant private SELL_TAX = 4;
	uint256 constant private REINVEST_TAX = 2;

	uint256 constant private STARTING_PRICE = 1 * 10**9;
	uint256 constant private INCREMENT = 0.001 * 10**9;

	string constant public name = "JAMM3D";
	string constant public symbol = "JAMM3D";
	uint8 constant public decimals = 18;

	struct User {
		uint256 balance;
		mapping(address => uint256) allowance;
		int256 scaledPayout;
	}

	struct Info {
		uint256 totalSupply;
		mapping(address => User) users;
		uint256 scaledJAMPerToken;
		JAM jam;
	}

	Info private info;

	event Transfer(address indexed from, address indexed to, uint256 tokens);
	event Approval(address indexed owner, address indexed spender, uint256 tokens);
	event Buy(address indexed buyer, uint256 amountSpent, uint256 tokensReceived);
	event Sell(address indexed seller, uint256 tokensSpent, uint256 amountReceived);
	event Withdraw(address indexed user, uint256 amount);
	event Reinvest(address indexed user, uint256 amount);

	constructor(address _JAM_address) public {
		info.jam = JAM(_JAM_address);
	}

	function buy(uint256 _amount) external returns (uint256) {
		require(_amount > 0);
		require(info.jam.transferFrom(msg.sender, address(this), _amount));
		return _buy(_amount);
	}

	function sell(uint256 _tokens) external returns (uint256) {
		require(balanceOf(msg.sender) >= _tokens);
		return _sell(_tokens);
	}

	function withdraw() external returns (uint256) {
		uint256 _dividends = dividendsOf(msg.sender);
		require(_dividends > 0);
		info.users[msg.sender].scaledPayout += int256(_dividends * FLOAT_SCALAR);
		info.jam.transfer(msg.sender, _dividends);
		emit Withdraw(msg.sender, _dividends);
		return _dividends;
	}

	function reinvest() external returns (uint256) {
		uint256 _dividends = dividendsOf(msg.sender);
		require(_dividends > 0);
		info.users[msg.sender].scaledPayout += int256(_dividends * FLOAT_SCALAR);
		emit Reinvest(msg.sender, _dividends);
		return _reinvest(_dividends);
	}

	function transfer(address _to, uint256 _tokens) external returns (bool) {
		return _transfer(msg.sender, _to, _tokens);
	}

	function approve(address _spender, uint256 _tokens) external returns (bool) {
		info.users[msg.sender].allowance[_spender] = _tokens;
		emit Approval(msg.sender, _spender, _tokens);
		return true;
	}

	function transferFrom(address _from, address _to, uint256 _tokens) external returns (bool) {
		require(info.users[_from].allowance[msg.sender] >= _tokens);
		info.users[_from].allowance[msg.sender] -= _tokens;
		return _transfer(_from, _to, _tokens);
	}

	function transferAndCall(address _to, uint256 _tokens, bytes calldata _data) external returns (bool) {
		_transfer(msg.sender, _to, _tokens);
		uint32 _size;
		assembly {
			_size := extcodesize(_to)
		}
		if (_size > 0) {
			require(Callable(_to).tokenCallback(msg.sender, _tokens, _data));
		}
		return true;
	}

	function totalSupply() public view returns (uint256) {
		return info.totalSupply;
	}

	function currentPrices() public view returns (uint256 truePrice, uint256 buyPrice, uint256 sellPrice) {
		truePrice = STARTING_PRICE + INCREMENT * totalSupply() / 1e18;
		buyPrice = truePrice * 100 / (100 - BUY_TAX);
		sellPrice = truePrice * (100 - SELL_TAX) / 100;
	}

	function balanceOf(address _user) public view returns (uint256) {
		return info.users[_user].balance;
	}

	function dividendsOf(address _user) public view returns (uint256) {
		return uint256(int256(info.scaledJAMPerToken * balanceOf(_user)) - info.users[_user].scaledPayout) / FLOAT_SCALAR;
	}

	function allInfoFor(address _user) public view returns (uint256 contractBalance, uint256 totalTokenSupply, uint256 truePrice, uint256 buyPrice, uint256 sellPrice, uint256 userJAM, uint256 userAllowance, uint256 userBalance, uint256 userDividends, uint256 userLiquidValue) {
		contractBalance = info.jam.balanceOf(address(this));
		totalTokenSupply = totalSupply();
		(truePrice, buyPrice, sellPrice) = currentPrices();
		userJAM = info.jam.balanceOf(_user);
		userAllowance = info.jam.allowance(_user, address(this));
		userBalance = balanceOf(_user);
		userDividends = dividendsOf(_user);
		userLiquidValue = calculateResult(userBalance, false, false) + userDividends;
	}

	function allowance(address _user, address _spender) public view returns (uint256) {
		return info.users[_user].allowance[_spender];
	}

	function calculateResult(uint256 _amount, bool _buy, bool _inverse) public view returns (uint256) {
		uint256 _buyPrice;
		uint256 _sellPrice;
		( , _buyPrice, _sellPrice) = currentPrices();
		uint256 _rate = (_buy ? _buyPrice : _sellPrice);
		uint256 _increment = INCREMENT * (_buy ? 100 : (100 - SELL_TAX)) / (_buy ? (100 - BUY_TAX) : 100);
		if ((_buy && !_inverse) || (!_buy && _inverse)) {
			if (_inverse) {
				return (2 * _rate - _sqrt(4 * _rate * _rate + _increment * _increment - 4 * _rate * _increment - 8 * _amount * _increment) - _increment) * 1e18 / (2 * _increment);
			} else {
				return (_sqrt((_increment + 2 * _rate) * (_increment + 2 * _rate) + 8 * _amount * _increment) - _increment - 2 * _rate) * 1e18 / (2 * _increment);
			}
		} else {
			if (_inverse) {
				return (_rate * _amount + (_increment * (_amount + 1e18) / 2e18) * _amount) / 1e18;
			} else {
				return (_rate * _amount - (_increment * (_amount + 1e18) / 2e18) * _amount) / 1e18;
			}
		}
	}

	function _transfer(address _from, address _to, uint256 _tokens) internal returns (bool) {
		require(info.users[_from].balance >= _tokens);
		info.users[_from].balance -= _tokens;
		info.users[_from].scaledPayout -= int256(_tokens * info.scaledJAMPerToken);
		info.users[_to].balance += _tokens;
		info.users[_to].scaledPayout += int256(_tokens * info.scaledJAMPerToken);
		emit Transfer(_from, _to, _tokens);
		return true;
	}

	function _buy(uint256 _amount) internal returns (uint256 tokens) {
		uint256 _tax = _amount * BUY_TAX / 100;
		tokens = calculateResult(_amount, true, false);
		info.totalSupply += tokens;
		info.users[msg.sender].balance += tokens;
		info.users[msg.sender].scaledPayout += int256(tokens * info.scaledJAMPerToken);
		info.scaledJAMPerToken += _tax * FLOAT_SCALAR / info.totalSupply;
		emit Transfer(address(0x0), msg.sender, tokens);
		emit Buy(msg.sender, _amount, tokens);
	}

	function _reinvest(uint256 _amount) internal returns (uint256 tokens) {
		uint256 _tax = _amount * REINVEST_TAX / 100;
		tokens = calculateResult(_amount, true, false);
		info.totalSupply += tokens;
		info.users[msg.sender].balance += tokens;
		info.users[msg.sender].scaledPayout += int256(tokens * info.scaledJAMPerToken);
		info.scaledJAMPerToken += _tax * FLOAT_SCALAR / info.totalSupply;
		emit Transfer(address(0x0), msg.sender, tokens);
		emit Buy(msg.sender, _amount, tokens);
	}

	function _sell(uint256 _tokens) internal returns (uint256 amount) {
		require(info.users[msg.sender].balance >= _tokens);
		amount = calculateResult(_tokens, false, false);
		uint256 _tax = amount * SELL_TAX / (100 - SELL_TAX);
		info.totalSupply -= _tokens;
		info.users[msg.sender].balance -= _tokens;
		info.users[msg.sender].scaledPayout -= int256(_tokens * info.scaledJAMPerToken);
		info.scaledJAMPerToken += _tax * FLOAT_SCALAR / info.totalSupply;
		info.jam.transfer(msg.sender, amount);
		emit Transfer(msg.sender, address(0x0), _tokens);
		emit Sell(msg.sender, _tokens, amount);
	}

	function _sqrt(uint256 _n) internal pure returns (uint256 result) {
		uint256 _tmp = (_n + 1) / 2;
		result = _n;
		while (_tmp < result) {
			result = _tmp;
			_tmp = (_n / _tmp + _tmp) / 2;
		}
	}
}