/**
 *Submitted for verification at Etherscan.io on 2022-02-18
*/

contract StackAttack {

    function begin(int depth) public {
        begin(depth - 1);
        begin(depth - 1);
    }

}