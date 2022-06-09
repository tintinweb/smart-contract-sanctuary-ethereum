/**
 *Submitted for verification at Etherscan.io on 2022-06-09
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

contract CryptoTips {
    string name = "Crypto Tips";
    uint256 m_Bank = 0;
    uint256 m_BankWithdraws = 0;
    mapping(uint256 => uint256) m_BankHistory;
    mapping(uint256 => uint256) m_Jars;
    mapping(uint256 => uint256) m_Royalties;
    mapping(uint256 => uint256) m_RoyaltyReceiver;
    mapping(address => bool) m_Admins;

    constructor(){
        m_Admins[msg.sender] = true;
    }
    function tipJar(uint256 _tipJar, uint16 _royalty) external payable {
        require(msg.value > 0, "Must tip more than 0");
        require(_tipJar > 0, "Invalid Tip Jar");
        require(_royalty >= 0);
        uint256 _fee =  msg.value / 100;
        uint256 _amount = msg.value;
        m_Bank += _fee;
        if(_royalty > 0){
            require(m_RoyaltyReceiver[_tipJar] != 0, "Invalid Royalty Address");
            m_Royalties[m_RoyaltyReceiver[_tipJar]] += _amount / _royalty;
            _amount -= _amount / _royalty;
        }
        m_Jars[_tipJar] += _amount - _fee;
    }
    function tipWallet(address payable _address) external payable {
        require(msg.value > 0,"Must tip more than 0");
        uint256 _fee =  msg.value / 100;        
        m_Bank += _fee;
        _address.transfer(msg.value-_fee);
    }
    function assignRoyalty(uint256 _tipJar, uint256 _receiver) external {
        require(m_Admins[msg.sender]);
        m_RoyaltyReceiver[_tipJar] = _receiver;
    }
    function getRoyaltyAwardee(uint256 _tipJar) external view returns(uint256) {
        return m_RoyaltyReceiver[_tipJar];
    }
    function viewBalance(uint256 _tipJar) external view returns(uint256) {
        return m_Jars[_tipJar];
    }    
    function tipWithdraw(uint256[] memory _tipJars, address payable _address, uint256 _txFee) external {
        require(m_Admins[msg.sender]);
        uint256 _bal = 0;
        for(uint64 i=0;i< _tipJars.length; i++){
            if(m_Jars[_tipJars[i]] != 0){                
                _bal += m_Jars[_tipJars[i]];
                m_Jars[_tipJars[i]] = 0;
            }
        }
        require(_bal > 0, "Nothing to withdraw");
        require(_bal > _txFee, "Transaction cost greater than balance");
        _bal -= _txFee;
        m_Bank += _txFee;
        _address.transfer(_bal);
    }
    function viewRoyalties(uint256 _royalty) external view returns(uint256) {
        return m_Royalties[_royalty];
    }
    function royaltyWithdraw(uint256[] memory _tipJars, address payable _address) external {
        require(m_Admins[msg.sender]);
        uint256 _bal;        
        for(uint64 i=0;i< _tipJars.length; i++){
            _bal += m_Royalties[_tipJars[i]];
            if(m_Royalties[_tipJars[i]] != 0)       
                m_Royalties[_tipJars[i]] = 0;
        }
        require(_bal > 0, "Nothing to withdraw");
        _address.transfer(_bal);
    }
    function viewBank() external view returns(uint256) {
        require(m_Admins[msg.sender]);
        return m_Bank;
    }
    function viewBankHistory(uint256 _index) external view returns(uint256) {
        require(m_Admins[msg.sender]);
        return m_BankHistory[_index];
    }
    function bankWithdraw() external {
        require(m_Admins[msg.sender]);
        uint256 _bal = m_Bank;
        m_Bank -= _bal;
        m_BankHistory[m_BankWithdraws] = _bal;
        m_BankWithdraws += 1;
        payable(msg.sender).transfer(_bal);
    }
    function emergencyWithdraw() external {
        require(m_Admins[msg.sender]);        
        payable(msg.sender).transfer(address(this).balance);
    }
    function assignAdmin(address _address) external {
        require(m_Admins[msg.sender]);
        m_Admins[_address] = true;
    }
    function removeAdmin(address _address) external {
        require(m_Admins[msg.sender]);
        m_Admins[_address] = false;        
    }
}