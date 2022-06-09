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
    event valueUpdated(uint indexed old,uint current,string message);
    mapping (address => bool) whitelist;
    
    modifier onlywhitelisted(){
        require(whitelist[msg.sender],"User not in whitelist");
        _;
    }
    constructor (){
        owner=msg.sender;
    }
    function addTowhitelist(address _address) external{
        whitelist[_address]=true;
    }
    function store(uint256 num) onlywhitelisted public {
        number = num;
         emit valueUpdated(number,num,"Value Updated");
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }
}