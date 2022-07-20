/**
 *Submitted for verification at Etherscan.io on 2022-07-20
*/

contract C {

    event Transfer(address indexed,address indexed,uint);

    function test() external {
        emit Transfer(address(0x0), msg.sender, 100);
    }
}