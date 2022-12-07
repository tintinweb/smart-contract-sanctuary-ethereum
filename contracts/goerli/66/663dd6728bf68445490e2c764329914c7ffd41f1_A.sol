/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

contract A {

    uint public abc;

    function setABC() public {
        abc = 10;
    }


    function setABC2(uint _abc) public {
        abc = _abc;
    }


    function getABC() public view returns(uint) {
        return abc;
    }
}

contract B {
   


}


contract C {

A public a; // contract A의 스마트컨트랙트주소 조회가능
    constructor(address _a) {
        a = A(_a);
    }


    function setABC2_C(uint _new_abc2) public {
        a.setABC2(_new_abc2);
    }
}