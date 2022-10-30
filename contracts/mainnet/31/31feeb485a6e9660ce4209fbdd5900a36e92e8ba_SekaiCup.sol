/**

SekaiCup launching soon!! telegram group will open at  20k Marketcap 0% tax

Channel : https://t.me/SekaiCupETH

Website : https://sekaicup.com/

*/// SPDX-License-Identifier: MIT

pragma solidity = 0.8.1;

import "./Ownable.sol";
import "./ERC20.sol";

/**
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 */
contract SekaiCup is ERC20 {
    uint256 private immutable _SUPPLY_CAP;

    constructor(address _premintOwner, uint256 _premintSupply, uint256 _capLimit)
        ERC20('SekaiCup', 'SEKAI', 9) {
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