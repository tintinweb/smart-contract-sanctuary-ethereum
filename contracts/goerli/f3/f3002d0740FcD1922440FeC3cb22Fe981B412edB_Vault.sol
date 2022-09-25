/**
 *Submitted for verification at Etherscan.io on 2022-09-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^ 0.8.0;

contract Vault {
  address public stableCoin;

  address private owner;

  mapping (address => bool) private operators;

  // Модификатор владельца
  modifier OnlyOwner() {
    require(owner == msg.sender, 'Permission denied');
    _;
  }

  // Модификатор оператора
  modifier OnlyOperator() {
    require(!operators[msg.sender], 'Permission denied');
    _;
  }

  constructor() public {
    owner = msg.sender;
  }

  receive() external payable {}

  function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
    require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
    uint256 tempUint;

    assembly {
        tempUint := mload(add(add(_bytes, 0x20), _start))
    }

    return tempUint;
  }

  // Установить стейбл-коин
  function setStableCoin(address token) public OnlyOwner {
    stableCoin = token;
  }

  // Сменить владельца
  function changeOwner(address newOwner) public OnlyOwner {
    require(!operators[msg.sender], 'New owner must be operator first');
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

  // Своп токена через прокси 0x.org
  function proxySwapTo(address proxy, bytes memory data, address targetCoin, address transferTo) public OnlyOperator {
    (bool proxyCallSuccess, ) = proxy.call(data);

    require(proxyCallSuccess, 'Failed to call proxy');

    (bool getBalanceSuccess, bytes memory getBalancedata) = targetCoin.call(
      abi.encodeWithSignature('balanceOf(address)', address(this))
    );

    uint amount = toUint256(getBalancedata, 0);

    require(getBalanceSuccess, 'Failed to transfer token to `transferTo`');

    if (transferTo != address(this)) {
      targetCoin.call(abi.encodeWithSignature('transfer(address,uint256)', transferTo, amount));
    }
  }
}