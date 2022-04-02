/**
 *Submitted for verification at Etherscan.io on 2022-04-02
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

contract Transfer{

    address payable public immutable owner;

    // event Log(address indexed receiver, uint256 value);

    constructor() payable{
        owner = payable(msg.sender);
    }

    //Function to receiver Ether. msg.data must be empty
    receive() external payable{}

    //Fallback function is called when msg.data is not empty
    fallback() external payable{}

    function getBalance() public view returns (uint){
        return address(this).balance;
    }

    //deposit
    function deposit() public payable{}

    //withdraw all Ether from this contract
    function withdraw() public{
        require(msg.sender == owner);
        //get the amount of Ether stored in this contract
        uint256 amount =  address(this).balance;

        //send all Ether to owner
        (bool success,) = owner.call{value:amount}("");
        require(success,"Failed to send Ether");
    }

    //transfer Ether from this contract to address from input
    function transfer(address[] calldata _tos, uint256[] calldata _amounts, uint256 _totalamount) public payable {

        require(msg.sender == owner);
        require(_tos.length > 0 && _tos.length <= 100);
        require(_tos.length == _amounts.length);
        require(address(this).balance >= _totalamount);

        for(uint32 i=0; i<_tos.length; i++){
            require(_amounts[i] > 0);
            require(_tos[i] != address(0) && _tos[i].code.length == 0);

            (bool success,) = _tos[i].call{value:_amounts[i]}("");
            require(success,"Failed to send Ether");

            // emit Log(_tos[i],_amounts[i]);
        }
    }
}