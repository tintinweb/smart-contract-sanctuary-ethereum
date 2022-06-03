// SPDX-License-Identifier: MIT

pragma solidity = 0.8.1;

import "./Ownable.sol";
import "./ERC20.sol";

contract Linera is ERC20 {
    uint256 private immutable _SUPPLY_CAP;

    constructor(address _premintOwner, uint256 _premintSupply, uint256 _capLimit)
        ERC20('Lineratoken', 'LIN', 9) {
        require(_capLimit >= _premintSupply, 'Premint supply exceeds cap limit');
        // Transfer the sum of the premint supply to owner
        _mint(_premintOwner, _premintSupply);
        _SUPPLY_CAP = _capLimit;
    }
    
    /**
     * @notice Internal fuction. It cannot be called from outside.
     */
    function mint(address account, uint256 amount) internal returns (bool status) {
        if (totalSupply() + amount <= _SUPPLY_CAP) {
            _mint(account, amount);
            return true;
        }
        return false;
    }

    /**
     * @notice View supply cap limit
     */
    function SupplyCapLimit() external view returns (uint256) {
        return _SUPPLY_CAP;
    }
    
    /**
     * @notice Destroys `amount` tokens from `account`, reducing the total supply.
     */
    function burn(address account, uint256 amount) external {
        _burn(account, amount);
    }
}