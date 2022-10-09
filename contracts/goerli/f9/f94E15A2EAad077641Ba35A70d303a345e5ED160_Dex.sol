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

contract Dex {
  using Converters for bytes;
  using SafeMath for uint256;

  address private JMBOCoin;
  address private stableCoin;
  address private owner;
  address private vaultContract;
  uint256 private tokenPrice;
  mapping (address => bool) private operators;
  mapping (address => uint256) private bookingPrices;

  event BuyToken();
  event SellToken();

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

  constructor() {
    owner = msg.sender;
    operators[msg.sender] = true;
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

  // Установить цену за одну монету
  function setTokenPrice(uint256 price) public OnlyOperator {
    tokenPrice = price;
  }

  // Обмен stableCoin на JMBOCoin
  function deposit(uint256 maxAmountToSell, uint256 amountToBuy) public {
    uint256 maxPrice = maxAmountToSell.div(amountToBuy); // Цена в долларах

    require(maxPrice >= tokenPrice, 'Price has been increased');

    /** Проверка баланса пользователя  */
    (bool getStableCoinBalanceSuccess, bytes memory stableCoinBalanceData) =  stableCoin.call(
      abi.encodeWithSignature('balanceOf(address)', msg.sender)
    );

    require(getStableCoinBalanceSuccess, 'Failed to get available stable coin balance');
    require(stableCoinBalanceData.toUint256(0) >= maxAmountToSell, 'stableCoin amount is less than necessary');
    /** Проверка баланса пользователя  */

    /** Проверка баланса хранилища  */
    (bool getJMBOCoinSuccess, bytes memory JMBOCoinBalanceData) =  JMBOCoin.call(
      abi.encodeWithSignature('balanceOf(address)', vaultContract)
    );

    require(getJMBOCoinSuccess, 'Failed to get available JMBOCoin balance');
    require(JMBOCoinBalanceData.toUint256(0) >= amountToBuy, 'JMBOCoin amount in vault is less than necessary');
    /** Проверка баланса хранилища  */

    uint256 realAmountToSell = amountToBuy.mul(tokenPrice);

    /** Трансфер stableCoin от пользователя в хранилище  */
    (bool transferStableCoinSuccess, ) = stableCoin.call(
      abi.encodeWithSignature('transferFrom(address,address,uint256)', msg.sender, vaultContract, realAmountToSell)
    );

    require(transferStableCoinSuccess, 'Failed to transfer stable coin from, probably allowance is less than necessary');
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

    emit BuyToken();
  }

  // Обмен JMBOCoin на stableCoin с указанием адреса
  function withdrawTo(uint256 maxAmountToSell, uint256 amountToBuy, address _recepient, bool force) internal returns (bool) {
    uint256 minPrice = amountToBuy.div(maxAmountToSell); // Цена в долларах

    require(minPrice <= tokenPrice, 'Price has been decreased');

    /** Проверка баланса пользователя  */
    (bool getJMBOCoinSuccess, bytes memory JMBOCoinBalanceData) =  JMBOCoin.call(
      abi.encodeWithSignature('balanceOf(address)', _recepient)
    );

    require(getJMBOCoinSuccess, 'Failed to get available JMBOCoin balance');
    require(JMBOCoinBalanceData.toUint256(0) >= maxAmountToSell, 'JMBOCoin amount is less than necessary');
    /** Проверка баланса пользователя  */

    /** Проверка баланса хранилища  */
    (bool getStableCoinBalanceSuccess, bytes memory stableCoinBalanceData) =  vaultContract.call(
      abi.encodeWithSignature('getAvailableAmount()')
    );

    require(getStableCoinBalanceSuccess, 'Failed to get available stable coin balance');

    // Если в хранилище нет доступного баланса, делаем букинг
    // Делаем исключение (force = true), при выполнению обязательств по букингу
    if (!force && stableCoinBalanceData.toUint256(0) < amountToBuy) {
      (bool createBookingSuccess, ) = vaultContract.call(
        abi.encodeWithSignature('makeBooking(address,uint256)', _recepient, amountToBuy)
      );

      require(createBookingSuccess, 'Failed to create booking');
      bookingPrices[_recepient] = tokenPrice;

      return false;
    }
    /** Проверка баланса хранилища  */

    uint256 realAmountToSell = amountToBuy.div(tokenPrice);

    /** Трансфер JMBOCoin от пользователя в хранилище  */
    (bool transferStableCoinSuccess, ) = JMBOCoin.call(
      abi.encodeWithSignature('transferFrom(address,address,uint256)', _recepient, vaultContract, realAmountToSell)
    );

    require(transferStableCoinSuccess, 'Failed to transfer JMBOCoin from, probably allowance is less than necessary');
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

    emit SellToken();
    return true;
  }

  // Обмен JMBOCoin на stableCoin
  function withdraw(uint256 maxAmountToSell, uint256 amountToBuy) public returns (bool) {
    return withdrawTo(maxAmountToSell, amountToBuy, msg.sender, false);
  }

  // Завершение сделки по бронированию
  function emitBookingReady(address _recepient, uint256 amountToBuy) public OnlyVault {
    uint256 amountToSell = amountToBuy.div(bookingPrices[_recepient]);
    require(withdrawTo(amountToSell, amountToBuy, _recepient, true), 'Failed to withdraw');
  }

  // Отмена бронирования, если оно было
  function cancelBooking() public {
    (bool cancelBookingSuccess, ) = vaultContract.call(
      abi.encodeWithSignature('cancelBooking(address)', msg.sender)
    );

    require(cancelBookingSuccess, 'Failed to cancel booking');
  }
}