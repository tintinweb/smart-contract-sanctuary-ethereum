/**
 *Submitted for verification at Etherscan.io on 2022-07-13
*/

pragma solidity =0.8.0;
pragma abicoder v2; 

contract Test {

    struct La {
        string a1;
        
        bytes a2;
    }

    event Test1(uint indexed a, La indexed b);
    event Test2(uint indexed a, uint[2] b);
    event Test3(bool c, string indexed a, uint[2] b) anonymous;

    function eventTest() public {
        emit Test1(1212, La("zhangla", "zhangla"));
        uint[2] memory b = [uint(1), uint(2)];
        emit Test2(12, b);
        emit Test3(true, "1212", b);
    }

    function test() public pure returns (string memory r1){
        r1 = "Hello World!";
    }

    function test2() public pure returns (string memory r1){
        r1 = "Hello World!";
    }

    function test3(uint[][] memory a1) public pure returns (uint[][] memory r1) {
        r1 = a1;
    }

    function test4(bytes memory a1) public pure returns (bytes memory r1){
        r1 = a1;
    }

    function test5(string[2] memory a1) public pure returns (string[2] memory r1){
        r1 = a1;
    }
}