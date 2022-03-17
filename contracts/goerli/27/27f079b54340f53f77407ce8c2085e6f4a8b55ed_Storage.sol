/**
 *Submitted for verification at Etherscan.io on 2022-03-17
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */

contract Storage 
{

    bool _state;
    uint256 _minted;

    /**
     * @dev Store value in variable
     * @param state value to store
     */
    function setState(bool state) external {
        _state = state;
    }

    function getMinted() external view returns (uint256){
        return _minted;
    }

    /**
     * @dev Return value 
     * @return value of 'state'
     */
    function retrieveState() external view returns (bool){
        return _state;
    }

    modifier isSalesActive()
    {
        require(_state == true, "Sale not active yet.");
        _;
    }

    function mint() external payable isSalesActive {
        _minted++;
    }
}