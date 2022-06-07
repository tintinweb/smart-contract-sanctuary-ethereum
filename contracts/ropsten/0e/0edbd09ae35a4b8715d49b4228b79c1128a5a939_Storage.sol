/**
 *Submitted for verification at Etherscan.io on 2022-06-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract Storage {

    uint256 number;
    mapping( address=> bool) whitelist;
    event valueupdated(uint indexed old, uint current,string message);

    
    modifier onlyWhitelisted ()
    {
        require(whitelist[msg.sender], "user not found in white List");
        _;
    }

    function addToWhiteList(address _address )external
    {
        whitelist[_address]=true;
    }

    function store(uint256 num) onlyWhitelisted public 
    {
        uint256 temp=number;
        number = num;
        emit valueupdated(number,num,"Value Updated");
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }
}