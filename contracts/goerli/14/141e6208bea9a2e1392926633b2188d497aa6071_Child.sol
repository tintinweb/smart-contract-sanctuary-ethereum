// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.18;

contract Parent {
    uint childNumber = 0;

    event ChildGeneration(address _parentAddress, address _childAddress, uint childNumber);

    function childGeneration  () external {
        Child child = new Child();
        bool isDeployed = child.validateTheCreation();
        require(isDeployed,"Undeployed");
        childNumber+=1;
        emit ChildGeneration(address(this), address(child), childNumber);
    }    
}

contract Child {    
    bool isDeployed = false;

    event InitializeChild(address _parentAddress, address childAddress);
    event Deposit(address user, uint value);
    event Withdraw(address user, uint value);


    constructor() {
        isDeployed = true;
        emit InitializeChild(msg.sender, address(this));
    }
    function validateTheCreation() external view returns(bool){
        return isDeployed;
    }

    function deposit() external {
        emit Deposit(msg.sender, 1 ether);
    }

    function withdraw() external {
        emit Withdraw(msg.sender, 1 ether);
    }
 
}