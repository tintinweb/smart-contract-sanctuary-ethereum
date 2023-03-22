/**
 *Submitted for verification at Etherscan.io on 2023-03-22
*/

// SPDX-License-Identifier: MIT

/**
 *  @authors: [@shotaronowhere]
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity ^0.8.0;

/**
 * @title LightBulb
 * @dev A lightbulb on ethereum controlled by a switch on Arbitrum with the Vea bridge.
 **/
 
contract LightBulb{
    
    address public immutable bridge; // vea bridge on L1
    address public immutable lightBulbSwitch; // The switch on arbitrum that controls this lightbulb.
    bool public globalLighbulb;
    mapping (address=>bool) public lightBulbIsOn;
    
    constructor(address _bridge, address _lightBulbSwitch) {
        bridge = _bridge;
        lightBulbSwitch = _lightBulbSwitch;
    }

    modifier onlyAuthenticatedFromVea(address _msgSender) {
        require(msg.sender == bridge, "L1 Auth: Only Vea Bridge.");
        require(_msgSender == lightBulbSwitch, "L2 Auth: Only the switch can turn on the lightbulb.");
        _;
    }

    /**
    * @dev Toggles the lightbulb on or off.
    * @param _msgSender The address of the sender on the L2 side.
    * @param lightBulbOwner The address of the owner of the lightbulb on the L2 side.
    */
    function toggleMyLightBulb(address _msgSender, address lightBulbOwner) external onlyAuthenticatedFromVea(_msgSender) {
        // lightBulbOwner authentication is done on the L2 switch side.
        lightBulbIsOn[lightBulbOwner] = !lightBulbIsOn[lightBulbOwner];
    }

    /**
    * @dev Toggles the global lightbulb on or off.
    * @param _msgSender The address of the sender on the L2 side.
    */
    function toggleGlobalLightBulb(address _msgSender) external onlyAuthenticatedFromVea(_msgSender){
        // lightbulb is global, no owner authentication is needed.
        globalLighbulb = !globalLighbulb;
    }
}