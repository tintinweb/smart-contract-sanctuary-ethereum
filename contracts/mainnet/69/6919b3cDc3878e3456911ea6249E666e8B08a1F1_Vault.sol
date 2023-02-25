// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import { IDex } from './IDex.sol';
import { IVault } from './IVault.sol';
import { IWETHToken } from './IToken.sol';
import { IERC20 } from '../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol';

import { ArrayUint256Util } from '../lib/ArrayUint256Util.sol';
import { ArrayAddressUtil } from '../lib/ArrayAddressUtil.sol';

contract Vault {
  struct Booking {
    uint256 amount;
    uint timestamp;
  }

  struct Session {
    uint256 id;
    uint256 amount;
  }

  using ArrayUint256Util for uint256[];
  using ArrayAddressUtil for address[];

  IERC20 public stableCoin;
  IERC20 public ownCoin;
  IWETHToken public wETHCoin;
  IDex public ownDexContract;
  uint public maxBookingTime;

  address private owner;
  Session[] private activeSessions;
  Session[] private finalSessions;
  address[] private usersBookings;
  address[] private bookingsToCancel;
  
  mapping (uint256 => Session) activeSessionsMap;
  mapping (uint256 => Session) finalSessionsMap;
  mapping (address => Booking) private bookings;
  mapping (address => bool) private operators;

  event SwapError(string text);
  event CreateBooking(address user, uint256 amount);
  event CancelBooking(address user);
  event ExchangeError(address user, string message);

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
  function _setStableCoin(address tokenAddress) public OnlyOwner {
    stableCoin = IERC20(tokenAddress);
  }

  // Установить свой коин
  function _setOwnCoin(address tokenAddress) public OnlyOwner {
    ownCoin = IERC20(tokenAddress);
  }

  // Установить wETH-коин
  function _setWETHCoin(address tokenAddress) public OnlyOwner {
    wETHCoin = IWETHToken(tokenAddress);
  }

  // Установить контракт обменника
  function _setOwnDexContract(address dexContract) public OnlyOwner {
    ownDexContract = IDex(dexContract);
  }

  // Сменить владельца
  function _changeOwner(address newOwner) public OnlyOwner {
    owner = newOwner;
  }

  // Добавить оператора
  function _addOperator(address operator) public OnlyOwner {
    operators[operator] = true;
  }

  // Удалить оператора
  function _removeOperator(address operator) public OnlyOwner {
    delete operators[operator];
  }

  // Отправить Ethereum по адресу
  function _sendEth(address payable target, uint amount) public OnlyDexOrOperator {
    (bool success, ) = target.call{ value: amount }('');
    require(success, 'Failed to send ETH');
  }

  // Отправить Token по адресу
  function _sendToken(address target, uint amount, IERC20 token) public OnlyDexOrOperator {
    token.transfer(target, amount);
  }

  // Возвращает allowance
  function _getAllowance(IERC20 token, address spender) internal view returns (uint256) {
    return token.allowance(address(this), spender);
  }

  // Устанавливает allowance на токене
  function _setAllowance(IERC20 token, address spender, uint amount) public OnlyDexOrOperator {
    uint256 allowance = _getAllowance(token, spender);

    if (amount > allowance) {
      token.approve(spender, amount);
    }
  }

  function _setMaxBookingTime(uint time) public OnlyOperator {
    maxBookingTime = time;
  }

  // Возвращает баланс монеты
  function _getTokenBalance(IERC20 token) internal view returns (uint256) {
    return token.balanceOf(address(this));
  }

  // Совершает обмен wETH на ETH
  function _exchangeWETHOnETH(uint256 amount) internal {
    wETHCoin.withdraw(amount);
  }

  // Своп токена через прокси 0x.org
  function _proxySwap(
    address proxyAddress,
    bytes calldata proxyData,
    address tokenToBuy,
    address payable target
  ) public OnlyOperator {
    uint256 tokenToBuyBalanceBefore = _getTokenBalance(IERC20(tokenToBuy));

    (bool success, bytes memory err) = proxyAddress.call(proxyData);

    if (!success) {
      emit SwapError(string(err));
      revert('Failed to call proxy');
    }

    uint256 boughtAmount = _getTokenBalance(IERC20(tokenToBuy)) - tokenToBuyBalanceBefore;

    if (target != address(this)) {
      if (tokenToBuy == address(wETHCoin)) {
        _exchangeWETHOnETH(boughtAmount);  
        _sendEth(target, boughtAmount);
      } else {
        _sendToken(target, boughtAmount, IERC20(tokenToBuy));
      }
    }
  }

  function _startSession(
    uint256 sessionId,
    address proxyAddress,
    bytes calldata proxyData,
    address tokenToBuy,
    address payable target
  ) public OnlyOperator {
    uint256 stableCoinBalanceBefore = _getTokenBalance(stableCoin);

    _proxySwap(proxyAddress, proxyData, tokenToBuy, target);

    uint256 transferedAmount = stableCoinBalanceBefore - _getTokenBalance(stableCoin);

    _createSession(sessionId, transferedAmount);
  }

  // Этот метод вынесен больше для тестов нежели для использования
  function _createSession(
    uint256 sessionId,
    uint256 transferedAmount
  ) public OnlyOperator {
    require(activeSessionsMap[sessionId].amount == 0, 'session id busy');

    Session memory newSession = Session(sessionId, transferedAmount);
    // Храним сессии в обработке
    activeSessions.push(newSession);
    activeSessionsMap[sessionId] = newSession;
  }

  /**
   * Метод для обновления цены перед завершенем сессий
   */
  function _moveSessionsToFinal(Session[] calldata sessions) public OnlyOperator {
    uint256 afterIncomeBalance = _getTokenBalance(stableCoin);

    // Перекладываем сессии в стейт
    for (uint i = 0; i < sessions.length; i += 1) {
      // Если сессии нет, пропускаем
      if (activeSessionsMap[sessions[i].id].amount > 0) {
        finalSessions.push(sessions[i]);
        finalSessionsMap[sessions[i].id] = sessions[i];
      }
    }

    for (uint i = 0; i < activeSessions.length; i += 1) {
      /**
       * Если в списке активных сессий есть финальная
       * То учитываем "финальный" баланс сессии
       */
      if (finalSessionsMap[activeSessions[i].id].amount > 0) {
        afterIncomeBalance += finalSessionsMap[activeSessions[i].id].amount;
        continue;
      }

      // Иначе - учитываем "начальный" баланс сессии
      afterIncomeBalance += activeSessions[i].amount;
    }

    // Объем монет в обращении
    uint256 ownCoinAmount = ownCoin.totalSupply() - _getTokenBalance(ownCoin);
    ownDexContract._setPriceRate(afterIncomeBalance, ownCoinAmount);
  }

  /**
   * Метод для обновления цены токена после завершения пачки сессий
   */
  function _completeSessions(Session[] calldata sessions) public OnlyOperator {
    uint256 income = 0;

    for (uint i = 0; i < sessions.length; i += 1) {
      // Если сессии нет, пропускаем
      if (activeSessionsMap[sessions[i].id].amount == 0) {
        continue;
      }

      income += sessions[i].amount;

      // Удаляем сессии из стейта финальных сессий
      for (uint j = 0; j < finalSessions.length; j += 1) {
        if (finalSessions[i].id == sessions[i].id) {
          finalSessions[i] = finalSessions[finalSessions.length - 1];
          delete finalSessions[finalSessions.length - 1];
          delete finalSessionsMap[sessions[i].id];
          break;
        }
      }

      // Удаляем сессии из стейта активных сессий
      for (uint j = 0; j < activeSessions.length; j += 1) {
        if (activeSessions[i].id == sessions[i].id) {
          activeSessions[i] = activeSessions[activeSessions.length - 1];
          delete activeSessions[activeSessions.length - 1];
          delete activeSessionsMap[sessions[i].id];
          break;
        }
      }
    }

    // Забираем income, который пришел на баланс оператора
    stableCoin.transferFrom(msg.sender, address(this), income);

    uint256 afterIncomeBalance = _getTokenBalance(stableCoin);

    for (uint i = 0; i < activeSessions.length; i += 1) {
      /**
       * Если в списке активных сессий есть финальная
       * То учитываем "финальный" баланс сессии
       */
      if (finalSessionsMap[activeSessions[i].id].amount > 0) {
        afterIncomeBalance += finalSessionsMap[activeSessions[i].id].amount;
        continue;
      }

      // Иначе - учитываем "начальный" баланс сессии
      afterIncomeBalance += activeSessions[i].amount;
    }

    // Объем монет в обращении
    uint256 ownCoinAmount = ownCoin.totalSupply() - _getTokenBalance(ownCoin);

    ownDexContract._setPriceRate(afterIncomeBalance, ownCoinAmount);
  }

  function _checkBookingNotExpired(Booking memory booking) internal view returns (bool) {
    return block.timestamp - booking.timestamp < maxBookingTime;
  }

  function getBookedBalance() public view returns (uint256) {
    uint256 bookedBalance = 0;

    for (uint i = 0; i < usersBookings.length; i += 1) {
      if (_checkBookingNotExpired(bookings[usersBookings[i]])) {
        bookedBalance += bookings[usersBookings[i]].amount;
      }
    }

    return bookedBalance;
  }

  // Дает допустимый остаток по счету, не считая брони
  function getAvailableAmount() public view returns (uint256) {
    uint256 balance = _getTokenBalance(stableCoin);
    uint256 bookedBalance = getBookedBalance();

    if (bookedBalance < balance) {
      return balance - bookedBalance;
    }

    return 0;
  }

  function getBookingAmount(address user) public view returns (uint256) {
    if (_checkBookingNotExpired(bookings[user])) {
      return bookings[user].amount;
    }

    return 0;
  }

  // Забронировать баланс
  function _makeBooking(address user, uint256 amount) public OnlyDex {
    require(amount > 0, 'Booking amount is too low');

    if (bookings[user].amount > 0) {
      if (_checkBookingNotExpired(bookings[user])) {
        revert('Booking is already exists');
      }

      _cancelBooking(user);
    }

    usersBookings.push(user);
    bookings[user] = Booking(amount, block.timestamp);

    emit CreateBooking(user, amount);
  }

  // Снять бронь баланса
  function _cancelBooking(address user) public OnlyDexOrOperator {
    delete bookings[user];
    usersBookings.removeByValue(user);

    emit CancelBooking(user);
  }

  // Отправить завершенные бронирования
  function _completeBookings() public OnlyOperator {
    uint256 balance = _getTokenBalance(stableCoin);
    address user;
    uint256 amount;

    for (uint i = 0; i < usersBookings.length; i += 1) {
      user = usersBookings[i];
      amount = bookings[user].amount;

      if (!_checkBookingNotExpired(bookings[user])) {
        bookingsToCancel.push(user);
        continue;
      }

      if (amount > balance) {
        continue;
      }

      try ownDexContract._completeBooking(msg.sender, amount) {
        balance -= amount;
      } catch Error(string memory err) {
        emit ExchangeError(user, err);
      }

      bookingsToCancel.push(user);
    }

    if (bookingsToCancel.length > 0) {
      for (uint i = bookingsToCancel.length - 1; i > 0; i -= 1) {
        _cancelBooking(bookingsToCancel[i]);
        delete bookingsToCancel[i];
      }
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

library ArrayUint256Util {
  function indexOf(uint256[] storage values, uint256 value) internal view returns(bool, uint) {
    for (uint i = 0; i < values.length; i += 1) {
      if (values[i] == value) {
        return (true, i);
      }
    }

    return (false, 0);
  }

  function removeByValue(uint256[] storage values, uint256 value) internal {
    (bool success, uint index) = indexOf(values, value);

    if (success) {
      removeByIndex(values, index);
    }
  }

  function removeByIndex(uint256[] storage values, uint index) internal {
    for (uint i = index; i < values.length - 1; i += 1) {
      values[i] = values[i+1];
    }

    delete values[values.length - 1];
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

library ArrayAddressUtil {
  function indexOf(address[] storage values, address value) internal view returns(bool, uint) {
    for (uint i = 0; i < values.length; i += 1) {
      if (values[i] == value) {
        return (true, i);
      }
    }

    return (false, 0);
  }

  function removeByValue(address[] storage values, address value) internal {
    (bool success, uint index) = indexOf(values, value);

    if (success) {
      removeByIndex(values, index);
    }
  }

  function removeByIndex(address[] storage values, uint index) internal {
    for (uint i = index; i < values.length - 1; i += 1) {
      values[i] = values[i+1];
    }

    delete values[values.length - 1];
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import { IDex } from './IDex.sol';
import { IWETHToken } from './IToken.sol';
import { Vault } from './Vault.sol';
import { IERC20 } from '../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IVault {
  function stableCoin() external view returns (IERC20);
  function ownCoin() external view returns (IERC20);
  function wETHCoin() external view returns (IWETHToken);
  function ownDexContract() external view returns (IDex);
  function maxBookingTime() external view returns (uint);

  function getBookedBalance() external view returns (uint256);
  function getAvailableAmount() external view returns (uint256);
  function getBookingAmount(address user) external view returns (uint256);

  function _setStableCoin(address tokenAddress) external;
  function _setOwnCoin(address tokenAddress) external;
  function _setWETHCoin(address tokenAddress) external;
  function _setOwnDexContract(address dexContract) external;
  function _changeOwner(address newOwner) external;
  function _addOperator(address operator) external;
  function _removeOperator(address operator) external;
  function _sendEth(address payable target, uint amount) external;
  function _sendToken(address target, uint amount, IERC20 token) external;
  function _setAllowance(IERC20 token, address spender, uint amount) external;
  function _moveSessionsToFinal(Vault.Session[] calldata sessions) external;
  function _completeSessions(Vault.Session[] calldata sessions) external;
  function _makeBooking(address user, uint256 amount) external;
  function _completeBookings() external;
  function _cancelBooking(address user) external;
  function _setMaxBookingTime(uint time) external;
  function _proxySwap(
    address proxyAddress,
    bytes calldata proxyData,
    address tokenToBuy,
    address payable target
  ) external;
  function _createSession(
    uint256 sessionId,
    uint256 transferedAmount
  ) external;
  function _startSession(
    uint256 sessionId,
    address proxyAddress,
    bytes calldata proxyData,
    address tokenToBuy,
    address payable target
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import { IERC20 } from '../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IWETHToken is IERC20 {
  function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import { IVault } from './IVault.sol';
import { IERC20 } from '../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IDex {
  function isPaused() external view returns (bool);
  function rateValues() external view returns (uint256, uint256);
  function ownCoin() external view returns (IERC20);
  function stableCoin() external view returns (IERC20);
  function vaultContract() external view returns (IVault);

  function deposit(uint256 maxAmountToSell, uint256 amountToBuy) external;
  function withdraw(uint256 maxAmountToSell, uint256 amountToBuy) external returns (bool);
  function cancelBooking() external;

  function _setPause(bool pause) external;
  function _changeOwner(address newOwner) external;
  function _setStableCoin(address tokenAddress) external;
  function _setOwnCoin(address tokenAddress) external;
  function _setVaultContract(address vaultAddress) external;
  function _removeOperator(address operator) external;
  function _setPriceRate(uint256 stable, uint256 own) external;
  function _completeBooking(address recepient, uint256 amountToBuy) external;
}