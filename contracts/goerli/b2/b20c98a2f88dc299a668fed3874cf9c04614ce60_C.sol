/**
 *Submitted for verification at Etherscan.io on 2022-12-11
*/

contract C {
    uint public num;
    address public sender;

    function setVars(uint _num) public payable {
        num = _num;
        sender = msg.sender;
    }
}