/**
 *Submitted for verification at Etherscan.io on 2022-04-21
*/

contract Calculator {
    uint256 result = 0;

    function Add(uint256 param1, uint256 param2) public returns (uint256) {
        return result = param1 + param2;
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

    function getResult() public view returns (uint256) {
        return result;
    }
}