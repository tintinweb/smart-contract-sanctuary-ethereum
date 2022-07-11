/**
 *Submitted for verification at Etherscan.io on 2022-07-11
*/

pragma solidity =0.8.0;
pragma abicoder v2; 

contract Test {

    struct La {
        string a1;
        
        bytes a2;
    }

    event Test1(uint indexed a, La indexed b);

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