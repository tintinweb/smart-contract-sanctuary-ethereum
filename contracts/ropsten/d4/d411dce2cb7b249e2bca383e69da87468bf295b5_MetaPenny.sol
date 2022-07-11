// SPDX-License-Identifier: GPL-3.0
// MetaPenny Contracts (last updated v0.0.9) (MetaPenny.sol)

pragma solidity >=0.7.0 <0.9.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Pausable.sol";
import "./Ownable.sol";

contract MetaPenny is ERC20, ERC20Burnable, Pausable, Ownable {
    string constant private _name           = "MetaPenny";
    string constant private _symbol         = "MTP";
    uint constant private _initialSupply    = 200000000;

    constructor() ERC20(_name, _symbol) {
        _mint(msg.sender, _initialSupply * 10**uint(decimals()));
    }    

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }    
}