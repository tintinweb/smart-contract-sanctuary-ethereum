/**
 *Submitted for verification at Etherscan.io on 2022-11-12
*/

contract Test {
    uint public x;

    function add1s() external {
        x++;
    }
}

contract Test2 {
    function add100s() external {
        Test t = Test(0xd9145CCE52D386f254917e481eB44e9943F39138);
        for (uint i = 0; i < 100; i++) {
            t.add1s();
        }
    }
}