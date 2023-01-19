/**
 *Submitted for verification at Etherscan.io on 2023-01-19
*/

pragma solidity ^0.8.17;
contract FeeSmartContract {
uint256 public FEE;
function set(uint256 _fee) external {
        require(_fee <= 500000, "Key Pair:  Fee can't be more than 50% on one side.");
        FEE = _fee;
}
function get() public returns (uint256) {
    return FEE;
}

}