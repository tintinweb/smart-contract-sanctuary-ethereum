/**
 *Submitted for verification at Etherscan.io on 2023-03-11
*/

// Version of Solidity compiler this program was written for
pragma solidity ^0.4.26;

contract Faucet{

//выдача эфира всем кто запросит
function withdraw (uint withdraw_amount) public {

//ограничиваем сумму снятия
require(withdraw_amount <= 100000000000000000);

//отправляем сумму по адресу, который запросил её
msg.sender.transfer(withdraw_amount);
}

//принимаем любые входящие средства
function () public payable {}

}