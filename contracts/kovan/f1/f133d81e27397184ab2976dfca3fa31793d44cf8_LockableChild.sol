// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.12;

import "./Lockable.sol";


contract LockableChild is Lockable {

    address public childChainManagerProxy;
    address deployer;

    constructor() {        
        childChainManagerProxy = 0xA6FA4fB5f76172d178d61B04b0ecd319C5d1C0aa;
        deployer = msg.sender;
        _burn(msg.sender, totalSupply(), "", "");
    }

    // being proxified smart contract, most probably childChainManagerProxy contract's address
    // is not going to change ever, but still, lets keep it 
    function updateChildChainManager(address newChildChainManagerProxy) external {
        require(newChildChainManagerProxy != address(0), "Bad ChildChainManagerProxy address");
        require(msg.sender == deployer, "You're not allowed");

        childChainManagerProxy = newChildChainManagerProxy;
    }

    function deposit(address user, bytes memory depositData) external {
        require(msg.sender == childChainManagerProxy, "You're not allowed to deposit");

        uint256 amount = abi.decode(depositData, (uint256));

        // `amount` token getting minted here & equal amount got locked in RootChainManager
         _mint(user, amount, "", "");
    }

    function withdraw(uint256 amount) external {
        _burn(_msgSender(), amount, "", "");
    }
}