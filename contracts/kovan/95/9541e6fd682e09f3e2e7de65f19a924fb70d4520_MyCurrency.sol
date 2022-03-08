/**
 *Submitted for verification at Etherscan.io on 2022-03-08
*/

pragma solidity >=0.7.0 <0.8.0; // compiler version used
contract MyCurrency { // contract def . close to a class
mapping ( address => uint ) public currencyBalance ; // field
function getBalance () external view returns ( uint ) { // method
return address ( this ) . balance ;
}
function buy ( uint nbCoins ) external payable { // method
require ( msg . value == nbCoins * (1 ether ) ) ;
currencyBalance [ msg . sender ]+= nbCoins ;
}
function sell ( uint nbCoins ) external { // method
require ( nbCoins <= currencyBalance [ msg . sender ]) ;
currencyBalance [ msg . sender ] -= nbCoins ;
msg . sender . transfer ( nbCoins *(1 ether ) ) ;
}
receive () external payable {} // ether reception method
}