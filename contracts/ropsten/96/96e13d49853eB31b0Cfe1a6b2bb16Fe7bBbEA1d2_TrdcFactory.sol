// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


contract TrdcFactory{
uint256 index = 0;
 address _admin;
 address[] public poolad;

 event newpool(address Pooladresss); 
constructor(){

_admin = msg.sender;


}    function NewPool(address _pool) external onlyOwner{
    poolad.push(_pool);
    index++;
    emit newpool(_pool);

    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_admin ==  msg.sender, "Ownable: caller is not the owner");
        _;
    }



}