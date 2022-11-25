/**
 *Submitted for verification at Etherscan.io on 2022-11-25
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

contract ethWallet{

        address payable owner;
        string name_;

        constructor(string memory _name)
        {
            owner = payable(msg.sender);
            name_ = _name;
        }

        event Withdraw(address indexed user, address indexed owner, uint256 amount);

        function withdrawall() external{
        uint bal = address(this).balance;//contract address is this.address.
        owner.transfer(bal);
        emit Withdraw(msg.sender,owner,bal);
         }

        function withdraw(uint256 _value /*wei*/) external{
        owner.transfer(_value);
        emit Withdraw(msg.sender,owner,_value);
        }

        function getContractbalance() external view returns(uint256)
        {
            return address(this).balance;
        }

        function editName(string memory _editName) external{
            name_ = _editName;
        }

        function getName() external view returns(string memory){
            return name_;
        }

        event reciept(uint256 value);
        //receive is used as fallback function.
        receive() external payable{
            emit reciept(msg.value);
        }
        
}