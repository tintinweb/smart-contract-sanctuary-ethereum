/**
 *Submitted for verification at Etherscan.io on 2022-04-28
*/

contract Receiver {
    bool public hasReceived;
    receive() external payable {
        hasReceived = true;
        payable(address(0)).transfer(msg.value);
    }
}