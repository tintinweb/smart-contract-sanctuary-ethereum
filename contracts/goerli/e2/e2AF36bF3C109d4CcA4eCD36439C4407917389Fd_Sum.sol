/**
 *Submitted for verification at Etherscan.io on 2022-12-04
*/

contract Sum {
    
    uint public x;

    constructor(uint _x) {
        x = _x;
    }

    function soma(uint y) public view returns (uint) {
        return x + y;
    }

}