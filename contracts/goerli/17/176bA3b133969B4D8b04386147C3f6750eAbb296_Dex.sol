// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import { Converters } from '../lib/Converters.sol';
import { SafeMath } from '../lib/Math.sol';

contract Dex {
  struct RateValues {
    uint256 stable;
    uint256 own;
  }

  using Converters for bytes;
  using SafeMath for uint256;

  // Переменные используемые для вычисления цены
  RateValues public rateValues;

  bool public isPaused;
  address public JMBOCoin;
  address public stableCoin;

  address private owner;
  address private vaultContract;
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

  // Модификатор доступа хранилища
  modifier OnlyVault() {
    require(vaultContract == msg.sender, 'Permission denied: Vault');
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
  function setStableCoin(address token) public OnlyOwner {
    stableCoin = token;
  }

  // Установить свой коин
  function setJMBOCoin(address token) public OnlyOwner {
    JMBOCoin = token;
  }

  // Установить контракт хранилища
  function setVaultContract(address vault) public OnlyOwner {
    vaultContract = vault;
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
  function setPriceRate(uint256 stable, uint256 own) public OnlyOperator {
    rateValues = RateValues({
      stable: stable,
      own: own
    });
  }

  // Обмен stableCoin на JMBOCoin
  function deposit(uint256 maxAmountToSell, uint256 amountToBuy) public NotPaused {
    require((
      maxAmountToSell.mul(rateValues.own) > rateValues.stable.mul(amountToBuy)
    ), 'Price has been increased');

    uint256 realAmountToSell = amountToBuy.mul(rateValues.stable).div(rateValues.own);

    /** Трансфер stableCoin от пользователя в хранилище  */
    (bool transferStableCoinSuccess, ) = stableCoin.call(
      abi.encodeWithSignature('transferFrom(address,address,uint256)', msg.sender, vaultContract, realAmountToSell)
    );

    require(transferStableCoinSuccess, 'Failed to transfer stable coin from, probably allowance or balance is less than necessary');
    /** Трансфер stableCoin от пользователя в хранилище  */

    /** Установка allowance для JMBOCoin */
    (bool setAllowanceOwnTokenSuccess, ) = vaultContract.call(
      abi.encodeWithSignature('setAllowance(address,address,uint256)', JMBOCoin, address(this), amountToBuy)
    );

    require(setAllowanceOwnTokenSuccess, 'Failed to set JMBOCoin allowance');
    /** Установка allowance для JMBOCoin */

    /** Трансфер JMBOCoin от хранилища к пользователю  */
    (bool transferOwnTokenSuccess, ) = JMBOCoin.call(
      abi.encodeWithSignature('transferFrom(address,address,uint256)', vaultContract, msg.sender, amountToBuy)
    );

    require(transferOwnTokenSuccess, 'Failed to transfer token');
    /** Трансфер JMBOCoin от хранилища к пользователю  */

    emit BuyToken(msg.sender);
  }

  // Обмен JMBOCoin на stableCoin
  function withdraw(uint256 maxAmountToSell, uint256 amountToBuy) public NotPaused returns (bool) {
    require((
      amountToBuy.mul(rateValues.own) < rateValues.stable.mul(maxAmountToSell)
    ), 'Price has been increased');

    /** Проверка баланса хранилища  */
    (bool getStableCoinBalanceSuccess, bytes memory stableCoinBalanceData) =  vaultContract.call(
      abi.encodeWithSignature('getAvailableAmount()')
    );

    require(getStableCoinBalanceSuccess, 'Failed to get available stable coin balance');

    // Если в хранилище нет доступного баланса, делаем букинг
    // Делаем исключение (force = true), при выполнению обязательств по букингу
    if (stableCoinBalanceData.toUint256(0) < amountToBuy) {
      (bool createBookingSuccess, ) = vaultContract.call(
        abi.encodeWithSignature('makeBooking(address,uint256)', msg.sender, amountToBuy)
      );

      require(createBookingSuccess, 'Failed to create booking');
      bookingPrices[msg.sender] = RateValues({
        stable: rateValues.stable,
        own: rateValues.own
      });

      return false;
    }
    /** Проверка баланса хранилища  */

    uint256 realAmountToSell = amountToBuy.mul(rateValues.own).div(rateValues.stable);

    /** Трансфер JMBOCoin от пользователя в хранилище  */
    (bool transferStableCoinSuccess, ) = JMBOCoin.call(
      abi.encodeWithSignature('transferFrom(address,address,uint256)', msg.sender, vaultContract, realAmountToSell)
    );

    require(transferStableCoinSuccess, 'Failed to transfer JMBOCoin from, probably allowance or balance is less than necessary');
    /** Трансфер JMBOCoin от пользователя в хранилище  */

    /** Установка allowance для stableCoin */
    (bool setAllowanceOwnTokenSuccess, ) = vaultContract.call(
      abi.encodeWithSignature('setAllowance(address,address,uint256)', stableCoin, address(this), amountToBuy)
    );

    require(setAllowanceOwnTokenSuccess, 'Failed to set stableCoin allowance');
    /** Установка allowance для stableCoin */

    /** Трансфер stableCoin от хранилища к пользователю  */
    (bool transferOwnTokenSuccess, ) = stableCoin.call(
      abi.encodeWithSignature('transferFrom(address,address,uint256)', vaultContract, msg.sender, amountToBuy)
    );

    require(transferOwnTokenSuccess, 'Failed to transfer token');
    /** Трансфер stableCoin от хранилища к пользователю  */

    emit SellToken(msg.sender);
    return true;
  }

  // Завершение сделки по бронированию
  function emitBookingReady(address _recepient, uint256 amountToBuy) public OnlyVault NotPaused {
    RateValues memory bookedRateValues = bookingPrices[_recepient];
    uint256 amountToSell = amountToBuy.mul(bookedRateValues.own).div(bookedRateValues.stable);

    /** Трансфер JMBOCoin от пользователя в хранилище  */
    (bool transferStableCoinSuccess, ) = JMBOCoin.call(
      abi.encodeWithSignature('transferFrom(address,address,uint256)', _recepient, vaultContract, amountToSell)
    );

    require(transferStableCoinSuccess, 'Failed to transfer JMBOCoin from, probably allowance or balance is less than necessary');
    /** Трансфер JMBOCoin от пользователя в хранилище  */

    /** Установка allowance для stableCoin */
    (bool setAllowanceOwnTokenSuccess, ) = vaultContract.call(
      abi.encodeWithSignature('setAllowance(address,address,uint256)', stableCoin, address(this), amountToBuy)
    );

    require(setAllowanceOwnTokenSuccess, 'Failed to set stableCoin allowance');
    /** Установка allowance для stableCoin */

    /** Трансфер stableCoin от хранилища к пользователю  */
    (bool transferOwnTokenSuccess, ) = stableCoin.call(
      abi.encodeWithSignature('transferFrom(address,address,uint256)', vaultContract, _recepient, amountToBuy)
    );

    require(transferOwnTokenSuccess, 'Failed to transfer token');
    /** Трансфер stableCoin от хранилища к пользователю  */

    emit SellToken(_recepient);
  }

  // Отмена бронирования, если оно было
  function cancelBooking() public {
    (bool cancelBookingSuccess, ) = vaultContract.call(
      abi.encodeWithSignature('cancelBooking(address)', msg.sender)
    );

    require(cancelBookingSuccess, 'Failed to cancel booking');
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

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