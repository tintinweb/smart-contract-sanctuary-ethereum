/**
 *Submitted for verification at Etherscan.io on 2023-02-25
*/

contract bal {
function getUserBalance(address _owner) external view returns (uint) {
    return address(_owner).balance;
}
}