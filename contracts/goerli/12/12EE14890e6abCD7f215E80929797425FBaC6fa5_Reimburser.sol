/**
 *Submitted for verification at Etherscan.io on 2022-12-08
*/

pragma solidity ^0.8.17;

contract Reimburser {
    // Define the maximum allowance and reimbursement percentage
    uint256 private maximumAllowance;
    uint256 private reimbursementPercentage;

    // Define the contract owner (admin)
    address private owner;

    // Define the mapping to store the balances of each user
    mapping(address => uint256) private balances;

    // Constructor to set the maximum allowance and reimbursement percentage and define the contract owner
    constructor(uint256 _maximumAllowance, uint256 _reimbursementPercentage) public {
        maximumAllowance = _maximumAllowance;
        reimbursementPercentage = _reimbursementPercentage;
        owner = msg.sender;
    }

    // Function to reimburse a user
    function reimburse(address payable _user, uint256 amount) public {
        // Check if the caller is the contract owner (admin)
        require(msg.sender == owner, "Only the contract owner can call this function.");

        // Check if user has reached the max allowance
        require(balances[_user] < maximumAllowance, "Employee has exceeded maximum allowance");

        // Calculate the reimbursement amount based on the defined reimbursement percentage and maximum allowance
        uint256 reimbursementAmount = amount * reimbursementPercentage / 100;

        // If this reimbursement will go over the max allowance, only reimburse enough to reach the max
        if (reimbursementAmount + balances[_user] > maximumAllowance) {
            reimbursementAmount = maximumAllowance - balances[_user];
        }

        // Reimburse the user and update their balance
        balances[_user] += reimbursementAmount;
        _user.transfer(reimbursementAmount);
    }
}