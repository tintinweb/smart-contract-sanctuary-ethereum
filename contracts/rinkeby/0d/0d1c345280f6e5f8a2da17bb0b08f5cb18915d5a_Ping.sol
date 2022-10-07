/**
 *Submitted for verification at Etherscan.io on 2022-10-04
*/

pragma solidity >=0.7.0 <0.9.0;

contract Ping {

    // quando ricevi degli ether, mandali indietro al mittente
    receive() external payable {
        // rimandali al mittente
         payable(msg.sender).send(msg.value);
    }


}