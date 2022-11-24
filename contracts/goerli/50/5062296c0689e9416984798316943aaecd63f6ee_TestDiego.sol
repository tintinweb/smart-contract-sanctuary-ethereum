/**
 *Submitted for verification at Etherscan.io on 2022-11-24
*/

pragma solidity 0.8.9;

contract TestDiego {
    event NewIncentive();
    function addBeneficiaries(address[] memory addressArray) external {
        emit NewIncentive();
    }
}