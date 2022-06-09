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
    mapping(address => bool) whitelist;
    event valueUpdated(uint old, uint current, string message);

    modifier OnlyOwner{
        require(msg.sender == owner, "NOT OWNER");
        _;
    }

    constructor(){
        owner = msg.sender;
    }

    modifier onlyWhiteListed(){
        require (whitelist[msg.sender], "User not in Whitelist");
        _;
    }

    function addtoWhitelist(address _address) OnlyOwner external{
        whitelist[_address] = true;
    }

    function removefromWhitelist(address _address) OnlyOwner external{
        whitelist[_address] = false;
    }

    function store(uint256 _num) onlyWhiteListed public{
        uint256 temp = number;
        number = _num;
        emit valueUpdated(temp, _num, "Value Updated");
    }


    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }
}