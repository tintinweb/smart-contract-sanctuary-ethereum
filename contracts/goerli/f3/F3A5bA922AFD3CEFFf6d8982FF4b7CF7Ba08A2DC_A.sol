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
    function getABC() public view returns(uint){
        return abc;
    }
}