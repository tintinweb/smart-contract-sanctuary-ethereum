/**
 *Submitted for verification at Etherscan.io on 2022-09-05
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface ERC20 {
  function allowance(address _owner, address spender) external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract MultiBridge {
    address public owner;
    ERC20 public immutable token;
    uint public immutable initBlock;

    event BridgeAssistUpload(address indexed sender, uint256 amount, string target);
    event Dispense(address indexed sender, uint256 amount);
    event TransferOwnership(address indexed previousOwner, address indexed newOwner);

    modifier restricted() {
        require(msg.sender == owner, "Function restricted to owner");
        _;
    }

    constructor(ERC20 _token) {
        require(address(_token) != address(0), "Invalid token address");
        token = _token;
        owner = msg.sender;
        initBlock = block.number;
    }

    function upload(uint256 amount, string memory target) external returns (bool success) {
        require(amount > 0, "Wrong amount");
        require(bytes(target).length != 0, "Incorrect target");
        require(token.transferFrom(msg.sender, address(this), amount), "Failed to transferFrom");
        emit BridgeAssistUpload(msg.sender, amount, target);
        return true;
    }

    function dispense(address recipient, uint256 _amount) external restricted returns (bool success) {
        require(_amount > 0, "Wrong amount");
        require(recipient != address(0), "Incorrect recipient");
        require(token.transfer(recipient, _amount), "Failed to transfer");
        emit Dispense(recipient, _amount);
        return true;
    }

    function transferOwnership(address _newOwner) external restricted {
        require(_newOwner != address(0), "Invalid _newOwner address");
        emit TransferOwnership(owner, _newOwner);
        owner = _newOwner;
    }

    function infoBundle(address user) external view returns (ERC20 tok, uint256 all, uint256 bal) {
        return (token, token.allowance(user, address(this)), token.balanceOf(user));
    }
}