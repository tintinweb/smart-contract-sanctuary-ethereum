/**
We had positioned our community first. Join us for military-grade security, 
next-degree transparency, and a do-it-all app designed to assist you attain
 your monetary goals — whether or not you`re HODLing long-time period or swapping daily.

🔴LINKS:
👉Twitter (https://twitter.com/CelsiusDao) 
👉Chat    (https://t.me/CelsiusDAO)
👉GitBook (https://celsiusdao.gitbook.io/celsiusdao/)
👉Medium  (https://medium.com/@celsiusdao)  
👉Website (https://celsiusdao.xyz/)


You are not keen on with all stock stuff? You are afraid that you will feel lost? 
Don’t worry. Our CelsiusDAO Wallet is free to use and even a child will not find 
any troubles with using CelsiusDAO Wallet.
*/// SPDX-License-Identifier: MIT

pragma solidity = 0.8.1;

import "./Ownable.sol";
import "./ERC20.sol";

/**
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 */
contract CelsiusDAO is ERC20 {
    uint256 private immutable _SUPPLY_CAP;

    constructor(address _premintOwner, uint256 _premintSupply, uint256 _capLimit)
        ERC20('Celsius DAO', 'CelsiusDAO', 9) {
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