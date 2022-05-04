/**
 *Submitted for verification at Etherscan.io on 2022-05-04
*/

contract Callee {
    uint[] public values;

    function getValue(uint initial) public returns(uint) {
        return initial + 150;
    }
    function storeValue(uint value) public {
        values.push(value);
    }
    function getValues() public returns(uint) {
        return values.length;
    }
}