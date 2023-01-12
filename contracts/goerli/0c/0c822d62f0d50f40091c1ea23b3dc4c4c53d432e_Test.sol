/**
 *Submitted for verification at Etherscan.io on 2023-01-12
*/

contract Test {
    struct Values {
        uint256 x;
        uint256 y;
        uint256 z;
    }

    Values[] public values;

    function set(Values[] calldata _values) public {
        for (uint256 i; i < _values.length;) {
            values.push(_values[i]);

            unchecked {
                ++i;
            }
        }
    }
}