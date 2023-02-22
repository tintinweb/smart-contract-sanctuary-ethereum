/**
 *Submitted for verification at Etherscan.io on 2023-02-22
*/

contract EndxReceiver {
    event ValueReceived(address user, uint amount);
    
    receive() external payable {
        emit ValueReceived(msg.sender, msg.value);
    }
}