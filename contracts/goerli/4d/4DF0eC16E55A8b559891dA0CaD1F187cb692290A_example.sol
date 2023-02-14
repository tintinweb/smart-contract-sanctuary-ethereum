pragma solidity 0.8.0;

contract example{
    string memo;

    function updateMemo(string memory _memo) external {
        memo = _memo;
    }

    function getMemo() external view returns(string memory) {
        return memo;
    }
}