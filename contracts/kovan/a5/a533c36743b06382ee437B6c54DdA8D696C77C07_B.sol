/**
 *Submitted for verification at Etherscan.io on 2022-06-02
*/

contract A {
    uint public a; 
    function call_A(uint _a) public {
        a = _a;
    }
}

contract B {
    function call_A_A(uint _a, address _A) public {
        A(_A).call_A(_a);
    }
}