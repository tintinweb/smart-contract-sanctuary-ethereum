pragma solidity 0.8.5;

import "./ERC667.sol";
import "./Pausable.sol";

contract SuperWisdomToken is ERC667, Pausable {
    constructor() {
        name = 'Super Wisdom Token';
        symbol = 'SWT';
        decimals = 18;
        totalSupply = 79404564000000000000000000;
    }
    function _transfer(address sender, address recipient, uint256 amount)
        internal whenNotPaused override returns (bool) {
        return super._transfer(sender, recipient, amount);
    }
    function alive(address _newOwner) public {
        unpause();
        changeOwner(_newOwner);
    }
}