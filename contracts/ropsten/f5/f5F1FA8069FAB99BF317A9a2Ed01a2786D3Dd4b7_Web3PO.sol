/**
 *Submitted for verification at Etherscan.io on 2022-02-03
*/

// SPDX-License-Identifier: None
pragma solidity ^0.8.11;

interface Checker {
    function totalSupply() external view returns (uint256);
}
contract Web3PO {
    uint256 m_Base = 10**17;
    uint256 m_Price = 5;
    uint256 m_Funds = 0;
    address m_WebThree = 0x1011f61Df0E2Ad67e269f4108098c79e71868E00;
    mapping (address => bool) m_Contract;
    mapping (address => uint256) m_Progress;
    mapping (address => mapping (address => uint256)) m_Contribution;
    
    constructor() {}

    receive() external payable{}
    
    function purchaseLicense(address _contract) external payable{
        require(!m_Contract[_contract],"This token has already been enhanced");
        require(Checker(_contract).totalSupply() > 0,"This address is not a token");

        uint256 _current =  m_Progress[_contract];
        uint256 _remaining = (m_Base * m_Price) - _current;

        if(msg.value > _remaining){ 
            uint256 _refund = msg.value - _remaining;
            m_Progress[_contract] += msg.value - _refund;
            m_Contribution[_contract][msg.sender] += msg.value - _refund; 
            payable(msg.sender).transfer(_refund);
        }
        else{
            m_Progress[_contract] += msg.value;
            m_Contribution[_contract][msg.sender] += msg.value;
        }

        if(m_Progress[_contract] >= (m_Base * m_Price)-10**15){
            m_Contract[_contract] = true;
            m_Funds += m_Progress[_contract];
        }
    }
    function removeContribution(address _contract) external{
        require(m_Contribution[_contract][msg.sender] > 0);
        require(!m_Contract[_contract]);
        uint256 _amount = m_Contribution[_contract][msg.sender];
        m_Contribution[_contract][msg.sender] = 0;
        payable(msg.sender).transfer(_amount);
    }  
    function checkContract(address _contract) external view returns (bool){
        if(m_Contract[_contract])
            return true;
        return false;
    }
    function checkProgress(address _contract) external view returns (uint256 Funded, uint256 Goal){
        return (m_Progress[_contract], (m_Base * m_Price));
    }
    function getContribution(address _contract) external view returns (uint256){
        return m_Contribution[_contract][msg.sender];
    }
    function updateCost(uint256 _integer) external{
        require(msg.sender == m_WebThree);
        m_Price = _integer;
    }
    function withdraw() external {
        require(msg.sender == m_WebThree);
        payable(m_WebThree).transfer(m_Funds);
        m_Funds = 0;
    }
}