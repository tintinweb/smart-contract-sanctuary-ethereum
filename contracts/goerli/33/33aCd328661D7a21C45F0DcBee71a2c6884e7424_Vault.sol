/**
 *Submitted for verification at Etherscan.io on 2022-10-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^ 0.8.0;

library Converters {
  function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
    require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
    uint256 tempUint;

    assembly {
      tempUint := mload(add(add(_bytes, 0x20), _start))
    }

    return tempUint;
  }
}
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
        return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);
    uint256 c = a / b;
    
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

contract Vault {
  using Converters for bytes;
  using SafeMath for uint256;

  uint256 public bookedBalance;

  address private stableCoin;
  address private JMBOCoin;
  address private wETHCoin;
  address private owner;
  address private ownDexContract;
  address[] private usersBookings;
  mapping (address => uint256) private bookings;
  mapping (address => bool) private operators;

  event CreateBooking(address user, uint256 amount);
  event CancelBooking(address user);
  event ExchangeError(address user);

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
    require(ownDexContract == msg.sender, 'Permission denied: Dex');
    _;
  }

  // Модификатор доступа собственного обменника или оператора
  modifier OnlyDexOrOperator() {
    require((
      ownDexContract == msg.sender || operators[msg.sender]
    ), 'Permission denied: Dex');
    _;
  }

  // Модификатор доступа собственного обменника или собственника
  modifier OnlyDexOrOwner() {
    require((
      ownDexContract == msg.sender || owner == msg.sender
    ), 'Permission denied: Dex');
    _;
  }

  constructor() {
    owner = msg.sender;
    operators[msg.sender] = true;
  }

  receive() external payable {}

  // Установить стейбл-коин
  function setStableCoin(address token) public OnlyOwner {
    stableCoin = token;
  }

  // Установить свой коин
  function setJMBOCoin(address token) public OnlyOwner {
    JMBOCoin = token;
  }

  // Установить wETH-коин
  function setWETHCoin(address token) public OnlyOwner {
    wETHCoin = token;
  }

  // Установить контракт обменника
  function setOwnDexContract(address dexContract) public OnlyOwner {
    ownDexContract = dexContract;
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
  function sendEth(address payable target, uint amount) public OnlyDexOrOwner {
    (bool success, ) = target.call{ value: amount }('');
    require(success, 'Failed to send ETH');
  }

  // Отправить Ethereum по адресу
  function sendToken(address target, uint amount, address token) public OnlyDexOrOwner {
    (bool success, ) = token.call(abi.encodeWithSignature('transfer(address,uint256)', target, amount));
    require(success, 'Failed to send token');
  }

  // Возвращает allowance
  function getAllowance(address token, address spender) internal returns (uint256) {
    (bool success, bytes memory data ) = token.call(
      abi.encodeWithSignature('allowance(address,address)', address(this), spender)
    );

    require(success, 'Failed to get token allowance');

    return data.toUint256(0);
  }

  // Устанавливает allowance на токене
  function setAllowance(address token, address spender, uint amount) public OnlyDexOrOperator {
    uint256 allowance = getAllowance(token, spender);

    if (amount > allowance) {
      (bool success, ) = token.call(
        abi.encodeWithSignature('approve(address,uint256)', spender, amount)
      );

      require(success, 'Failed to set token allowance');
    }
  }

  // Возвращает баланс монеты
  function getTokenBalance(address token) internal returns (uint256) {
    (bool success, bytes memory data) = token.call(
      abi.encodeWithSignature('balanceOf(address)', address(this))
    );

    require(success, 'Failed to get token balance');
    
    return data.toUint256(0);
  }

  // Совершает обмен wETH на ETH
  function exchangeWETHonETH(uint256 amount) internal {
    (bool success, ) = wETHCoin.call(
      abi.encodeWithSignature('withdraw(uint256)', amount)
    );

    require(success, 'Failed to exchange wETH on ETH');
  }

  // Своп токена через прокси 0x.org
  function proxySwap(address proxy, bytes memory proxyData, address tokenToBuy, address payable target) public OnlyOperator {
    (bool success, ) = proxy.call(proxyData);

    require(success, 'Failed to call proxy');

    uint boughtAmount = getTokenBalance(tokenToBuy);

    if (tokenToBuy == wETHCoin) {
      exchangeWETHonETH(boughtAmount);
    }

    if (target != address(this)) {
      if (tokenToBuy == wETHCoin) {
        sendEth(target, boughtAmount);
      } else {
        sendToken(target, boughtAmount, tokenToBuy);
      }
    }
  }

  // Дает допустимый остаток по счету, не считая брони
  function getAvailableAmount() public returns (uint256) {
    uint256 balance = getTokenBalance(stableCoin);
    return balance.sub(bookedBalance);
  }

  // Забронировать баланс
  function makeBooking(address user, uint256 amount) public OnlyDex {
    require(bookings[user] == 0, 'Booking is already exists');

    usersBookings.push(user);
    bookedBalance = bookedBalance.add(amount);
    bookings[user] = amount;

    emit CreateBooking(user, amount);
  }

  // Снять бронь баланса
  function cancelBooking(address user) public OnlyDexOrOperator {
    require(bookings[user] > 0, 'There is no booking');

    bookedBalance -= bookings[user];
    delete bookings[user];

    for (uint256 i = 0; i < usersBookings.length; i += 1) {
      if (usersBookings[i] == user) {
        usersBookings[i] = usersBookings[usersBookings.length - 1];
        delete usersBookings[usersBookings.length - 1];
        break;
      }
    }

    emit CancelBooking(user);
  }

  // Отправить завершенные бронирования
  function emitBookingsReady() public OnlyOperator {
    uint256 balance = getTokenBalance(stableCoin);

    for (uint256 i = 0; i < usersBookings.length ; i += 1) {
      address user = usersBookings[i];
      uint256 amount = bookings[user];

      if (amount >= balance) {
        break;
      }

      (bool success, ) = ownDexContract.call(
        abi.encodeWithSignature('emitBookingReady(address, uint256)', msg.sender, amount)
      );

      if (!success) {
        emit ExchangeError(user);
      } else {
        balance -= amount;
      }

      cancelBooking(user);
    }
  }
}