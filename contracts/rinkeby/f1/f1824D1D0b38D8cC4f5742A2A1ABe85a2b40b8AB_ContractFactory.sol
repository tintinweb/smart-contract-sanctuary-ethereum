// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


contract DeployWithCreate2 {

    address public owner;
	
    constructor(address _owner) {
        owner = _owner;
    }
}

contract ContractFactory {

    event Deploy(address addr);

    function deploy() external {
        DeployWithCreate2 _contract = new DeployWithCreate2(msg.sender);
        emit Deploy(address(_contract));
    }
}