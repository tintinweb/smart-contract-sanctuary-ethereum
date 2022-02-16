// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from '../Ownable.sol';
import {ERC20} from '../ERC20.sol';

contract ILOMarker is ERC20, Ownable {

    constructor(
        address _premintReceiver,
        uint256 _premintAmount
    ) ERC20('ILOMarker', 'ILOM') {
        // Transfer the sum of the premint to address
        _mint(_premintReceiver, _premintAmount);
    }

    function transfer(address recipient, uint256 amount) public onlyOwner override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public onlyOwner override returns (bool) {
        _transfer(sender, recipient, amount);
        return true;
    }

    function multiTransfer(address[] calldata recipients, uint256 amount) public onlyOwner returns (bool) {
        for (uint256 i = 0; i < recipients.length; i++) {
            address recipient = recipients[i];
            _transfer(_msgSender(), recipient, amount);
        }
        return true;
    }
}