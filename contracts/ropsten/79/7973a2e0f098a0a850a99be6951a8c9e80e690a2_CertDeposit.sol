/**
 *Submitted for verification at Etherscan.io on 2022-04-28
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title CertDeposit
 * @dev poorly made contract that allows someone to abuse an integer overflow
 * ALL CREDIT DUE TO DR ADRIAN MANNING OF SIGMAPRIME FOR THIS CODE
 * https://blog.sigmaprime.io/solidity-security.html#ou-vuln
 */
contract CertDeposit {

    mapping(address => uint256) public balances;
    mapping(address => uint256) public lock;

/**
 * deposits eth into the contract for a certain amount of time
 *
 */
    function deposit() public payable {
        balances[msg.sender] += msg.value;
        lock[msg.sender] = block.timestamp + 5 hours;
    }

    // allows the user to make the contract locked for longer
    function increaseLockTime(uint256 _secondsToIncrease) public {
        lock[msg.sender] += _secondsToIncrease;
    }

    function withdraw() public {
        require(balances[msg.sender] > 0);
        require(block.timestamp > lock[msg.sender]);
        uint transferValue = balances[msg.sender];
        balances[msg.sender] = 0;
        payable(msg.sender).transfer(transferValue);
    }
}