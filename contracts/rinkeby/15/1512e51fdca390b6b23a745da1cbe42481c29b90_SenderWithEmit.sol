/**
 *Submitted for verification at Etherscan.io on 2022-04-28
*/

contract SenderWithEmit {
    event Debug(bool success);
    function send(address payable receiver) public payable {
        (bool success,) = receiver.call.gas(10000000).value(msg.value)("");
        emit Debug(success);
    }
}