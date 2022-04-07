/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

// contract CryptosToken{
//     address immutable owner;
//     string public name = "Cryptos";
//     uint supply;

//     constructor(){
//         owner=msg.sender;
//     }

//     function setsupply(uint _supply)public{
//         supply = _supply;
//     }
//     function getsupply()public view returns(uint){
//         return supply;
//     }
// }

// contract MyTokens{
//     string[] public tokens = ['BTC', 'ETH'];
    
//     function changeTokens() public {
//         string[] storage t = tokens;
//         t[0] = 'VET';
//     }
// }

// contract Deposit{

//     address immutable admin;

//     constructor(){
//         admin=msg.sender;
//     }

//     receive()external payable{

//     }
//     fallback()external payable{

//     }

//     function getbalance()public view returns(uint){
//         return address(this).balance;
//     }

//     function transferr(address payable to)public{
//         require(msg.sender==admin,"you are not admin!!");
//         uint amount=getbalance();
//         to.transfer(amount);
//     }
// }

contract Game{
    address[] public players;
    function start()public{
        players.push(msg.sender);
    }
}