// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IMSPToken.sol";

contract MSPToken is IMSPToken {
    constructor(

        string memory _name,
        string memory _symbol,
        uint256 _amount // 1year = 52,560,000
    ) ERC20(_name, _symbol) {
        _mint(_msgSender(), _amount * 10**decimals());
    }

    //Don't accept ETH or BNB
    receive() external payable {
        revert("Don't accept ETH or BNB");
    }
}