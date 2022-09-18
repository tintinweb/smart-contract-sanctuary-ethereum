/**
 *Submitted for verification at Etherscan.io on 2022-09-17
*/

pragma solidity 0.7.0;
//a fancy basicbank contract made by <3
//  www.goksu.in 17.9.22
contract BasicBank {

    mapping (address => uint) private userFunds;
    address private commissionCollector;
    
    uint private collectedComission = 0;

    constructor() {
        commissionCollector = msg.sender; 
    }
    
    modifier onlyCommissionCollector {
        require(msg.sender == commissionCollector);
        _;
    }

    function deposit() public payable {
        require(msg.value >= 1 ether); 
        userFunds[msg.sender] += msg.value; 
    }

    function withdraw(uint _amount) external payable {
        require(getBalance(msg.sender) >= _amount);
        payable (msg.sender).transfer(_amount*99/100);
        userFunds[msg.sender] -= _amount;
        userFunds[commissionCollector] += _amount/100; 
    }   

    function getBalance(address _user) public view returns(uint) {
        return userFunds[_user];
    }

    function getCommissionCollector() public view returns(address) {
        return commissionCollector;
    }

    function transfer(address _userToSend, uint _amount) external{
        require(getBalance(msg.sender) >= _amount);
        userFunds[_userToSend] += _amount;
        userFunds[msg.sender] -= _amount;
    }

    function setCommissionCollector(address _newCommissionCollector) external onlyCommissionCollector{
        commissionCollector = _newCommissionCollector;
    }

    function collectCommission() external onlyCommissionCollector{
        userFunds[msg.sender] += collectedComission;
        collectedComission = 0;
    }
}