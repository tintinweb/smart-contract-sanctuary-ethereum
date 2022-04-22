/**
 *Submitted for verification at Etherscan.io on 2022-04-22
*/

contract Calculator {
    uint256 result = 0;
    event Result(uint256 result);

    function Add(uint256 param1, uint256 param2) public {
        result = param1 + param2;
        emit Result(result);
    }

    function Subtract(uint256 param1, uint256 param2) public returns (uint256) {
        return result = param1 - param2;
    }

    function Multiply(uint256 param1, uint256 param2) public returns (uint256) {
        return result = param1 * param2;
    }

    function Divide(uint256 param1, uint256 param2) public returns (uint256) {
        return result = param1 / param2;
    }

    function Mod(uint256 param1, uint256 param2) public returns (uint256) {
        return result = param1 % param2;
    }
}