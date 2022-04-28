/**
 *Submitted for verification at Etherscan.io on 2022-04-28
*/

contract Sender {
    function send(address payable receiver) public payable {
        receiver.call.gas(10000000).value(msg.value)("");
    }
}