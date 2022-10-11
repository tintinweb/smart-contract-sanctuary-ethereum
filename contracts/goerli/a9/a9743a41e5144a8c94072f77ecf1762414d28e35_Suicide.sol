/**
 *Submitted for verification at Etherscan.io on 2022-10-11
*/

contract Suicide {
    function kill() external {
        selfdestruct(payable(msg.sender));
    }
}