/**
 *Submitted for verification at Etherscan.io on 2022-04-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;
/**
 * @title LeoFiEtherFund
 * @dev Faucet Ethereum Testnet for ethereum developers
 * @author Leo Nguyen <leofi.me>
 */
contract LeoFiEtherFund{

    address payable public owner; 

    address[] public operators;

    event ChangeOwnerShip(address indexed _from, address indexed _to);
    event EmergencyWithdraw(address indexed _requestor, address indexed _to, uint256 _amount);

    constructor (){
        owner = payable(msg.sender);
        operators.push(msg.sender);
    }

    modifier onlyOwner(){
         require(msg.sender == owner, "Caller is not owner");
        _;
    }

    modifier onlyOperators(){
        require(_isOperator(msg.sender), "Caller is not operator");
        _;
    }

    function changeOwner(address payable _address) public onlyOwner{
        owner = _address;
        emit ChangeOwnerShip(msg.sender, _address);
    }

    function _isOperator(address _address) internal returns(bool){
        if(operators.length == 0)
            return false;

       for (uint i = 0; i < operators.length-1; i++){
            if(operators[i] == _address)
                return true;
        }
        return false;
    }

    function addOperators(address _op) public onlyOwner{
        require(_op != address(0));
        require(!_isOperator(_op), "This operator is exists");
        operators.push(_op);
    }

     function removeOperators(address _op) public onlyOwner{
        require(_isOperator(_op), "This operator is not exists");
        _removeOperator(_op);
    }

    function _removeOperator(address _address) internal {
        for (uint i = 0; i < operators.length-1; i++){
            if(operators[i] == _address)
            {
                operators[i] = operators[operators.length-1];
                operators.pop();
            }
        }
    }
    
    function getBalanceOfFund() public view returns(uint256){
        return address(this).balance;
    }

    function withdrawFund(address payable _to, uint256 _amount) public payable onlyOperators returns(bool){
       return _sendFund(_to, _amount);
    }

    function multiWithdrawFund(address payable[] memory _tos, uint256 _amount) public payable onlyOperators{
        for (uint i = 0; i < _tos.length-1; i++){
           _sendFund(_tos[i], _amount);
        }
    }

    function _sendFund(address payable _to, uint256 _amount) internal  returns(bool){
       (bool sent,) = _to.call{value: _amount}("");
       return sent;
    }

    function emergencyWithdraw() public onlyOwner{
        uint256  balanceOf = address(this).balance;
        owner.transfer(balanceOf);
        emit EmergencyWithdraw(msg.sender,msg.sender,balanceOf );
    }

    function moveFundTo(address payable _to) public onlyOwner{
        uint256  balanceOf = address(this).balance;
        _to.transfer(balanceOf);
        emit EmergencyWithdraw(msg.sender, _to,balanceOf );
    }

    fallback() external payable { }
    
    receive() external payable { }
}