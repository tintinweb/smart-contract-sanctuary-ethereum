// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// This contract is used to store ERC20 addresses
contract ERC20FacetStorage {
    address[] internal erc20s;

    function getERC20s() public view returns (address[] memory) {
        return erc20s;
    }

    function addERC20s(address[] memory erc20s_) public returns (address[] memory) {
        for (uint256 i; i < erc20s_.length; i++) {
            erc20s.push(erc20s_[i]);
        }

        return erc20s_;
    }

}