//SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

import "./Owner.sol";

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract Approve is Ownable {
    address vault;
    IERC20 public token;

    constructor(address _token) {
        token = IERC20(_token);
    }

    function approve(uint _amount) public onlyOwner returns (bool, uint256) {
        require(vault != address(0x0), "Vault address not assigned!");
        token.approve(vault, _amount);
        uint256 allowance = token.allowance(owner, vault);
        return(true, allowance);
    }

    function vaultAddress(address _vault) public onlyOwner {
        vault = _vault;
    } 

    function returnVault() public view onlyOwner returns (address) {
        return vault;
    }

    function returnAllowance() public view onlyOwner returns (uint256) {
        return token.allowance(owner, vault);
    }
}