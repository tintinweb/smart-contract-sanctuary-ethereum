/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

contract childContract {
    uint256 private value;

    constructor(uint256 initialValue) {
        value = initialValue;
    }

    function incrementValue(uint256 amount) public {
        value += amount;
    }

    function getValue() public view returns (uint256) {
        return value;
    }
}