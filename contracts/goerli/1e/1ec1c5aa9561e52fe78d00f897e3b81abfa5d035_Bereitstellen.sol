/**
 *Submitted for verification at Etherscan.io on 2023-02-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title Bereitstellen
 * @dev Bereitstellen dattabot test
 */
 
contract Bereitstellen {
    address deployer;
    address by;
    string public color;

    constructor() {
        deployer = msg.sender;
    }

    function getDeployer() public view returns(address){
        return deployer;
    }
    
    event ColorChanged(address by, string color);

    function setColor(address _by, string memory _yourNewColor) public {
        by = _by;
        require(by == deployer, "Can only called by deployer");
        color = _yourNewColor;
        emit ColorChanged(deployer, _yourNewColor);
    }
}