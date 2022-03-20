/**
 *Submitted for verification at Etherscan.io on 2022-03-20
*/

pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

contract Ponzi{
    address public owner;
    uint public totalFundValue;

    mapping (address => uint) public invested;
    mapping (address => uint) public balances;
    address[] investors;

    event LogInvestment(address investor, uint amount);
    event LogWithdrawal(address investor, uint amount);

    modifier nonZeroBalance() { 
        require(!(balances[msg.sender] == 0));
        _;
    }
    
    bool internal locked;

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    uint fee_percent;
    
    constructor() {
        owner = msg.sender;
        fee_percent = 20;
        totalFundValue = 0;
    }

    function invest() public payable {
        uint investment = msg.value;
        balances[owner] += investment * fee_percent/100;
        
        distributeInvestment(investment - (investment * fee_percent/100));

        if (invested[msg.sender] == 0){
            investors.push(msg.sender);
        }

        invested[msg.sender] += investment;
        totalFundValue += investment;

        emit LogInvestment(msg.sender, msg.value);
    }

    function distributeInvestment(uint _investment) private {
        for (uint i = 0; i < investors.length; i++){
            balances[investors[i]] += (_investment) * (invested[investors[i]] / totalFundValue);
        }
    }

    function withdraw() noReentrant() nonZeroBalance() public {
        uint withdrawable = balances[msg.sender];
        balances[msg.sender] = 0;
        (bool sent, bytes memory data) = msg.sender.call{
            value: withdrawable
        }("");
        // data = data;
        if(sent){
            emit LogWithdrawal(msg.sender, withdrawable);
        } else {
            balances[msg.sender] = withdrawable;
        }
    }

    function reinvest() noReentrant() nonZeroBalance() public {
        uint investment = balances[msg.sender];
        balances[msg.sender] = 0;
        distributeInvestment(investment);
        invested[msg.sender] += investment;
        emit LogInvestment(msg.sender, investment);
    }
    // fallback() external payable {}
}