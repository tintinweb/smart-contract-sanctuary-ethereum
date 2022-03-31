// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.9;

interface IERC20 {
    function mint(address account, uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
}

contract BridgeAssist {
    address public owner;
    IERC20 public tokenInterface;  

    modifier restricted {
        require(msg.sender == owner, "This function is restricted to owner");
        _;
    }
    
    event Collect(address indexed sender, uint256 amount);
    event Dispense(address indexed sender, uint256 amount);
    event TransferOwnership(address indexed previousOwner, address indexed newOwner);

    function collect(address _sender, uint256 _amount) public restricted returns (bool success) {
        tokenInterface.burnFrom(_sender, _amount);
        emit Collect(_sender, _amount);
        return true;
    }

    function dispense(address _sender, uint256 _amount) public restricted returns (bool success) {
        tokenInterface.mint(_sender, _amount);
        emit Dispense(_sender, _amount);
        return true;
    }

    function transferOwnership(address _newOwner) public restricted {
        require(_newOwner != address(0), "Invalid address: should not be 0x0");
        emit TransferOwnership(owner, _newOwner);
        owner = _newOwner;
    }

    constructor(IERC20 _tokenInterface) {
        tokenInterface = _tokenInterface;
        owner = msg.sender;
    }
}