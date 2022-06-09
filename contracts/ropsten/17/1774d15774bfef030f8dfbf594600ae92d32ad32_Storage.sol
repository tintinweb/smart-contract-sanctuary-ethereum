/**
 *Submitted for verification at Etherscan.io on 2022-06-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract Storage {

    address public owner;
    uint256 number;
    event valueUpdate(uint old,uint current,string message);
    mapping(address=>bool)whitelist;

    modifier onlyWhitelisted(){
        require(whitelist[msg.sender],"User Not Found");
        _;
    }
    modifier OnlyOwner(){
        require(msg.sender==owner,"Not Owner");
        _;
    }
   
   constructor() {
       owner = msg.sender;
   }

    

    function addToWhitelisted(address _address) OnlyOwner external{
        whitelist[_address]=true;
    }
    function removeWhiteList(address _address) OnlyOwner external{
        whitelist[_address]=false;
    }




    function store(uint256 num) onlyWhitelisted public {
        emit valueUpdate(number,num,"Value Update");
        number = num;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }
}