/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

contract Simple {
    uint public x;
    uint public y;
    uint public sum;

    function sumTheNumbers(uint _x, uint _y) external {
        x = _x;
        y = _y;
        sum = _x + _y;
    }
}