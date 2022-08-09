/**
 *Submitted for verification at Etherscan.io on 2022-08-08
*/

// File: contracts/1_Storage.sol



pragma solidity =0.8.15;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract Storage {

    uint256 number;
    address owner;


    constructor(){
        owner = msg.sender;
    }

    function GetMoney() public {
        address payable Powner = payable(owner);
         Powner.transfer(address(this).balance);
    }
    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public {
        number += num;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }
    
    function PIDORASI() public view returns (uint256){
        return 1;
    }
}