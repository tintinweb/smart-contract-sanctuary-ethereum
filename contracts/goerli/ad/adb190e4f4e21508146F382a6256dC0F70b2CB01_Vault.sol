// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import { IToken } from './Token.sol';
import { IDex } from './Dex.sol';

import { ArrayUint256Util } from '../lib/ArrayUint256Util.sol';
import { ArrayAddressUtil } from '../lib/ArrayAddressUtil.sol';

interface IWETHToken is IToken {
  function withdraw(uint256 amount) external;
}

interface IVault {
  function stableCoin() external view returns (IToken);
  function ownCoin() external view returns (IToken);
  function wETHCoin() external view returns (IWETHToken);
  function ownDexContract() external view returns (IDex);
  function maxBookingTime() external view returns (uint);

  function getBookedBalance() external view returns (uint256);
  function setStableCoin(address tokenAddress) external;
  function setOwnCoin(address tokenAddress) external;
  function setWETHCoin(address tokenAddress) external;
  function setOwnDexContract(address dexContract) external;
  function changeOwner(address newOwner) external;
  function addOperator(address operator) external;
  function removeOperator(address operator) external;
  function sendEth(address payable target, uint amount) external;
  function sendToken(address target, uint amount, IToken token) external;
  function setAllowance(IToken token, address spender, uint amount) external;
  function proxySwap(address proxy, bytes calldata proxyData, address tokenToBuy, address payable target, uint256 sessionId) external;
  function completeSessions(uint256[] calldata ids, uint256 income) external;
  function getAvailableAmount() external view returns (uint256);
  function getBookingAmount(address user) external view returns (uint256);
  function makeBooking(address user, uint256 amount) external;
  function completeBookings() external;
  function cancelBooking(address user) external;
  function setMaxBookingTime(uint time) external;
}

contract Vault {
  struct Booking {
    uint256 amount;
    uint timestamp;
  }

  using ArrayUint256Util for uint256[];
  using ArrayAddressUtil for address[];

  IToken public stableCoin;
  IToken public ownCoin;
  IWETHToken public wETHCoin;
  IDex public ownDexContract;
  uint public maxBookingTime;

  address private owner;
  uint256[] private activeSessions;
  address[] private usersBookings;
  address[] private bookingsToCancel;
  mapping (uint256 => uint256) private sessionsList;
  mapping (address => Booking) private bookings;
  mapping (address => bool) private operators;

  event CreateBooking(address user, uint256 amount);
  event CancelBooking(address user);
  event ExchangeError(address user, string message);
  event Log(string text);

  // Модификатор доступа владельца
  modifier OnlyOwner() {
    require(owner == msg.sender, 'Permission denied: Owner');
    _;
  }

  // Модификатор доступа оператора
  modifier OnlyOperator() {
    require(operators[msg.sender], 'Permission denied: Operator');
    _;
  }

  // Модификатор доступа собственного обменника
  modifier OnlyDex() {
    require(address(ownDexContract) == msg.sender, 'Permission denied: Dex');
    _;
  }

  // Модификатор доступа собственного обменника или оператора
  modifier OnlyDexOrOperator() {
    require((
      address(ownDexContract) == msg.sender || operators[msg.sender]
    ), 'Permission denied: Dex or Operator');
    _;
  }

  constructor() {
    owner = msg.sender;
    operators[msg.sender] = true;
  }

  receive() external payable {}

  // Установить стейбл-коин
  function setStableCoin(address tokenAddress) public OnlyOwner {
    stableCoin = IToken(tokenAddress);
  }

  // Установить свой коин
  function setOwnCoin(address tokenAddress) public OnlyOwner {
    ownCoin = IToken(tokenAddress);
  }

  // Установить wETH-коин
  function setWETHCoin(address tokenAddress) public OnlyOwner {
    wETHCoin = IWETHToken(tokenAddress);
  }

  // Установить контракт обменника
  function setOwnDexContract(address dexContract) public OnlyOwner {
    ownDexContract = IDex(dexContract);
  }

  // Сменить владельца
  function changeOwner(address newOwner) public OnlyOwner {
    owner = newOwner;
  }

  // Добавить оператора
  function addOperator(address operator) public OnlyOwner {
    operators[operator] = true;
  }

  // Удалить оператора
  function removeOperator(address operator) public OnlyOwner {
    delete operators[operator];
  }

  // Отправить Ethereum по адресу
  function sendEth(address payable target, uint amount) public OnlyDexOrOperator {
    (bool success, ) = target.call{ value: amount }('');
    require(success, 'Failed to send ETH');
  }

  // Отправить Token по адресу
  function sendToken(address target, uint amount, IToken token) public OnlyDexOrOperator {
    token.transfer(target, amount);
  }

  // Возвращает allowance
  function getAllowance(IToken token, address spender) internal view returns (uint256) {
    return token.allowance(address(this), spender);
  }

  // Устанавливает allowance на токене
  function setAllowance(IToken token, address spender, uint amount) public OnlyDexOrOperator {
    uint256 allowance = getAllowance(token, spender);

    if (amount > allowance) {
      token.approve(spender, amount);
    }
  }

  function setMaxBookingTime(uint time) public OnlyOperator {
    maxBookingTime = time;
  }

  // Возвращает баланс монеты
  function getTokenBalance(IToken token) internal view returns (uint256) {
    return token.balanceOf(address(this));
  }

  // Совершает обмен wETH на ETH
  function exchangeWETHOnETH(uint256 amount) internal {
    wETHCoin.withdraw(amount);
  }

  // Своп токена через прокси 0x.org
  function proxySwap(
    address proxy,
    bytes calldata proxyData,
    address tokenToBuy,
    address payable target,
    uint256 sessionId
  ) public OnlyOperator {
    uint256 balanceBefore = getTokenBalance(stableCoin);

    (bool success, ) = proxy.call(proxyData);

    require(success, 'Failed to call proxy');

    uint256 transferedAmount = balanceBefore - getTokenBalance(stableCoin);

    uint boughtAmount = getTokenBalance(IToken(tokenToBuy));

    if (tokenToBuy == address(wETHCoin)) {
      exchangeWETHOnETH(boughtAmount);
    }

    if (target != address(this)) {
      if (tokenToBuy == address(wETHCoin)) {
        sendEth(target, boughtAmount);
      } else {
        sendToken(target, boughtAmount, IToken(tokenToBuy));
      }
    }

    // Храним транзакции в обработке
    sessionsList[sessionId] = transferedAmount;
    activeSessions.push(sessionId);
  }

  // Метод для обновления цены токена после завершения пачки транзакций
  function completeSessions(uint256[] calldata ids, uint256 income) public OnlyOperator {
    uint256 stableCoinBalance = getTokenBalance(stableCoin) + income;

    for (uint256 i = 0; i < ids.length; i += 1) {
      stableCoinBalance -= sessionsList[ids[i]];
      delete sessionsList[ids[i]];
      activeSessions.removeByValue(ids[i]);
    }

    for (uint256 i = 0; i < activeSessions.length; i += 1) {
      stableCoinBalance += sessionsList[activeSessions[i]];
    }

    uint256 ownCoinAmount = ownCoin.totalSupply() - getTokenBalance(ownCoin);

    ownDexContract.setPriceRate(stableCoinBalance, ownCoinAmount);
  }

  function checkBookingNotExpired(Booking memory booking) internal view returns (bool) {
    return block.timestamp - booking.timestamp < maxBookingTime;
  }

  function getBookedBalance() public view returns (uint256) {
    uint256 bookedBalance = 0;

    for (uint256 i = 0; i < usersBookings.length; i += 1) {
      if (checkBookingNotExpired(bookings[usersBookings[i]])) {
        bookedBalance += bookings[usersBookings[i]].amount;
      }
    }

    return bookedBalance;
  }

  // Дает допустимый остаток по счету, не считая брони
  function getAvailableAmount() public view returns (uint256) {
    uint256 balance = getTokenBalance(stableCoin);
    uint256 bookedBalance = getBookedBalance();

    if (bookedBalance < balance) {
      return balance - bookedBalance;
    }

    return 0;
  }

  function getBookingAmount(address user) public view returns (uint256) {
    if (checkBookingNotExpired(bookings[user])) {
      return bookings[user].amount;
    }

    return 0;
  }

  // Забронировать баланс
  function makeBooking(address user, uint256 amount) public OnlyDex {
    require(amount > 0, 'Booking amount is too low');

    if (bookings[user].amount > 0) {
      if (checkBookingNotExpired(bookings[user])) {
        revert('Booking is already exists');
      }

      cancelBooking(user);
    }

    usersBookings.push(user);
    bookings[user] = Booking(amount, block.timestamp);

    emit CreateBooking(user, amount);
  }

  // Снять бронь баланса
  function cancelBooking(address user) public OnlyDexOrOperator {
    delete bookings[user];
    usersBookings.removeByValue(user);

    emit CancelBooking(user);
  }

  // Отправить завершенные бронирования
  function completeBookings() public OnlyOperator {
    uint256 balance = getTokenBalance(stableCoin);
    address user;
    uint256 amount;

    emit Log('fetch balance');

    for (uint256 i = 0; i < usersBookings.length; i += 1) {
      emit Log('start cycle for user');

      user = usersBookings[i];
      amount = bookings[user].amount;

      if (!checkBookingNotExpired(bookings[user])) {
        emit Log('booking is expired');
        bookingsToCancel.push(user);
        continue;
      }

      if (amount > balance) {
        continue;
      }

      emit Log('try to complete booking');

      try ownDexContract.completeBooking(msg.sender, amount) {
        emit Log('success for user');
        balance -= amount;
      } catch Error(string memory err) {
        emit ExchangeError(user, err);
      }

      emit Log('add booking to cancel');
      bookingsToCancel.push(user);
    }

    if (bookingsToCancel.length > 0) {
      emit Log('booking to cancel > 0');
      for (uint256 i = bookingsToCancel.length - 1; i > 0; i -= 1) {
        emit Log('cancel booking');
        cancelBooking(bookingsToCancel[i]);
        delete bookingsToCancel[i];
      }
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

library ArrayUint256Util {
  function indexOf(uint256[] memory values, uint256 value) internal pure returns(bool, uint256) {
    for (uint256 i = 0; i < values.length; i += 1) {
      if (values[i] == value) {
        return (true, i);
      }
    }

    return (false, 0);
  }

  function removeByValue(uint256[] memory values, uint256 value) internal pure {
    (bool success, uint256 index) = indexOf(values, value);

    if (success) {
      removeByIndex(values, index);
    }
  }

  function removeByIndex(uint256[] memory values, uint256 index) internal pure {
    for (uint256 i = index; i < values.length - 1; i += 1) {
      values[i] = values[i+1];
    }

    delete values[values.length - 1];
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

library ArrayAddressUtil {
  function indexOf(address[] memory values, address value) internal pure returns(bool, uint256) {
    for (uint256 i = 0; i < values.length; i += 1) {
      if (values[i] == value) {
        return (true, i);
      }
    }

    revert("element doesn't exist");
  }

  function removeByValue(address[] memory values, address value) internal pure {
    (bool success, uint256 index) = indexOf(values, value);

    if (success) {
      removeByIndex(values, index);
    }
  }

  function removeByIndex(address[] memory values, uint256 index) internal pure {
    for (uint256 i = index; i < values.length - 1; i += 1) {
      values[i] = values[i+1];
    }

    delete values[values.length - 1];
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IToken {
	function totalSupply() external view returns (uint256);
	function name() external view returns (string memory);
	function decimals() external view returns (uint8);
	function symbol() external view returns (string memory);
	function version() external view returns (string memory);

	function balanceOf(address _owner) external view returns (uint256 balance);
	function transfer(address _recipient, uint256 _value) external;
	function transferFrom(address _from, address _to, uint256 _value) external;
	function approve(address _spender, uint256 _value) external;
	function allowance(address _spender, address _owner) external view returns (uint256 balance);
}

contract Token is IToken {
	uint256 public totalSupply;
	string public name;
	uint8 public decimals;
	string public symbol;
	string public version;

  address private owner;

	mapping (address => uint256) balances;
	mapping (address => mapping (address => uint)) allowed;

	//Event which is triggered to log all transfers to this contract's event log
	event Transfer(
		address indexed _from,
		address indexed _to,
		uint256 _value
	);
		
	//Event which is triggered whenever an owner approves a new allowance for a spender.
	event Approval(
		address indexed _owner,
		address indexed _spender,
		uint256 _value
	);

  // Модификатор доступа владельца
  modifier OnlyOwner() {
    require(owner == msg.sender, 'Permission denied: Owner');
    _;
  }

	// Fix for short address attack against ERC20
	modifier onlyPayloadSize(uint256 size) {
		assert(msg.data.length == size + 4);
		_;
	} 

  constructor() {
    name = 'Jeembo Finance Token';
    decimals = 6;
    symbol = 'JMBO';
		version = '1.0';

    owner = msg.sender;
  }

  // Сменить владельца
  function changeOwner(address newOwner) public OnlyOwner {
    owner = newOwner;
  }

  function mint(uint256 amount, address _recipient) public OnlyOwner {
    balances[_recipient] += amount;
    totalSupply += amount;

		emit Transfer(address(this), _recipient, amount);
  }

	function balanceOf(address _owner) public view returns (uint256 balance) {
		return balances[_owner];
	}

  function transfer(address _recipient, uint256 _value) public onlyPayloadSize(2*32) {
		require(balances[msg.sender] >= _value, 'Insufficient balance');

    balances[msg.sender] -= _value;
    balances[_recipient] += _value;

    emit Transfer(msg.sender, _recipient, _value);        
  }

  function transferFrom(address _from, address _to, uint256 _value) public {
		require(balances[_from] >= _value, 'Insufficient balance');
    require(allowed[_from][msg.sender] >= _value, 'Insufficient allowance');

    balances[_from] -= _value;
    balances[_to] += _value;
    allowed[_from][msg.sender] -= _value;
	
    emit Transfer(_from, _to, _value);
  }

	function  approve(address _spender, uint256 _value) public {
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
	}

	function allowance(address _spender, address _owner) public view returns (uint256 balance) {
		return allowed[_owner][_spender];
	}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import { IVault } from './Vault.sol';
import { IToken } from './Token.sol';

interface IDex {
  function isPaused() external view returns (bool);
  function rateValues() external view returns (uint256, uint256);
  function ownCoin() external view returns (IToken);
  function stableCoin() external view returns (IToken);
  function vaultContract() external view returns (IVault);

  function setPause(bool pause) external;
  function changeOwner(address newOwner) external;
  function setStableCoin(address tokenAddress) external;
  function setOwnCoin(address tokenAddress) external;
  function setVaultContract(address vaultAddress) external;
  function removeOperator(address operator) external;
  function setPriceRate(uint256 stable, uint256 own) external;
  function deposit(uint256 maxAmountToSell, uint256 amountToBuy) external;
  function withdraw(uint256 maxAmountToSell, uint256 amountToBuy) external returns (bool);
  function completeBooking(address _recepient, uint256 amountToBuy) external;
  function cancelBooking() external;
}

contract Dex is IDex {
  struct RateValues {
    uint256 stable;
    uint256 own;
  }

  bool public isPaused;
  // Переменные используемые для вычисления цены
  RateValues public rateValues;
  IToken public ownCoin;
  IToken public stableCoin;
  IVault public vaultContract;

  address private owner;
  mapping (address => bool) private operators;
  mapping (address => RateValues) private bookingPrices;

  event BuyToken(address user);
  event SellToken(address user);

  // Модификатор доступа владельца
  modifier OnlyOwner() {
    require(owner == msg.sender, 'Permission denied: Owner');
    _;
  }

  // Модификатор доступа оператора
  modifier OnlyOperator() {
    require(operators[msg.sender], 'Permission denied: Operator');
    _;
  }

  // Модификатор доступа оператора или хранилища
  modifier OnlyOperatorOrVault() {
    require((
      operators[msg.sender] || address(vaultContract) == msg.sender
    ), 'Permission denied: Operator or Vault');
    _;
  }

  // Модификатор доступа хранилища
  modifier OnlyVault() {
    require(address(vaultContract) == msg.sender, 'Permission denied: Vault');
    _;
  }

  // Модификатор доступа хранилища
  modifier NotPaused() {
    require(!isPaused, 'Permission denied: Vault');
    _;
  }

  constructor() {
    owner = msg.sender;
    operators[msg.sender] = true;
  }

  function setPause(bool pause) public {
    isPaused = pause;
  }

  // Сменить владельца
  function changeOwner(address newOwner) public OnlyOwner {
    owner = newOwner;
  }

  // Установить стейбл-коин
  function setStableCoin(address tokenAddress) public OnlyOwner {
    stableCoin = IToken(tokenAddress);
  }

  // Установить свой коин
  function setOwnCoin(address tokenAddress) public OnlyOwner {
    ownCoin = IToken(tokenAddress);
  }

  // Установить контракт хранилища
  function setVaultContract(address vaultAddress) public OnlyOwner {
    vaultContract = IVault(vaultAddress);
  }

  // Добавить оператора
  function addOperator(address operator) public OnlyOwner {
    operators[operator] = true;
  }

  // Удалить оператора
  function removeOperator(address operator) public OnlyOwner {
    delete operators[operator];
  }

  // Установить rateValues
  function setPriceRate(uint256 stable, uint256 own) public OnlyOperatorOrVault {
    rateValues = RateValues({
      stable: stable,
      own: own
    });
  }

  // Обмен stableCoin на ownCoin
  function deposit(uint256 maxAmountToSell, uint256 amountToBuy) public NotPaused {
    require((
      maxAmountToSell * rateValues.own >= rateValues.stable * amountToBuy
    ), 'Price has been increased');

    uint256 realAmountToSell = amountToBuy * rateValues.stable / rateValues.own;

    require(realAmountToSell > 0, 'Too little amout to sell');
    require(amountToBuy > 0, 'Too little amout to buy');

    stableCoin.transferFrom(msg.sender, address(vaultContract), realAmountToSell);

    vaultContract.setAllowance(ownCoin, address(this), amountToBuy);

    ownCoin.transferFrom(address(vaultContract), msg.sender, amountToBuy);

    emit BuyToken(msg.sender);
  }

  // Обмен ownCoin на stableCoin
  function withdraw(uint256 maxAmountToSell, uint256 amountToBuy) public NotPaused returns (bool) {
    require((
      amountToBuy * rateValues.own <= rateValues.stable * maxAmountToSell
    ), 'Price has been increased');

    uint256 availableAmount = vaultContract.getAvailableAmount();

    // Если в хранилище нет доступного баланса, делаем букинг
    if (availableAmount < amountToBuy) {
      vaultContract.makeBooking(msg.sender, amountToBuy);

      bookingPrices[msg.sender] = RateValues({
        stable: rateValues.stable,
        own: rateValues.own
      });

      return false;
    }

    uint256 realAmountToSell = amountToBuy * rateValues.own / rateValues.stable;

    require(realAmountToSell > 0, 'Too little amout to sell');
    require(amountToBuy > 0, 'Too little amout to buy');

    vaultContract.setAllowance(stableCoin, address(this), amountToBuy);

    ownCoin.transferFrom(msg.sender, address(vaultContract), realAmountToSell);
    stableCoin.transferFrom(address(vaultContract), msg.sender, amountToBuy);

    emit SellToken(msg.sender);
    return true;
  }

  // Завершение сделки по бронированию
  function completeBooking(address _recepient, uint256 amountToBuy) public OnlyVault NotPaused {
    RateValues memory bookedRateValues = bookingPrices[_recepient];
    uint256 amountToSell = amountToBuy * bookedRateValues.own / bookedRateValues.stable;

    require(amountToSell > 0, 'Too little amout to sell');
    require(amountToBuy > 0, 'Too little amout to buy');

    vaultContract.setAllowance(stableCoin, address(this), amountToBuy);

    ownCoin.transferFrom(_recepient, address(vaultContract), amountToSell);
    stableCoin.transferFrom(address(vaultContract), _recepient, amountToBuy);

    emit SellToken(_recepient);
    delete bookingPrices[_recepient];
  }

  // Отмена бронирования, если оно было
  function cancelBooking() public {
    vaultContract.cancelBooking(msg.sender);
  }
}