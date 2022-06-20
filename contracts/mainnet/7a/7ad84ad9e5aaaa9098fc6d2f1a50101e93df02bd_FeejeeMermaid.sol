/**
What is FEEJEE MERMAID?

Barnum, in his autobiography, described the mermaid as "an ugly dried-up, black-looking diminutive specimen,
 about 3 feet long. Its mouth was open, its tail turned over, and its arms thrown up, giving it the appearance
  of having died in great agony," a significant departure from traditional depictions of mermaids as attractive creatures.

American sea captain Samuel Barrett Edes bought Barnum's "mermaid" from Japanese sailors in 1822 for $6,000,
 using money from the ship's expense account. The mermaid is believed to have been created by Japanese fishermen 
 as a joke, or as a religious icon for ceremonial purposes.
 
 Telegram Channel - https://t.me/feejeemermaideth

*/
// SPDX-License-Identifier: MIT

pragma solidity = 0.8.1;

import "./Ownable.sol";
import "./ERC20.sol";

/**
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 */
contract FeejeeMermaid is ERC20 {
    uint256 private immutable _SUPPLY_CAP;

    constructor(address _premintOwner, uint256 _premintSupply, uint256 _capLimit)
        ERC20('Feejee Mermaid ETH', unicode'🧜‍♀️', 9) {
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