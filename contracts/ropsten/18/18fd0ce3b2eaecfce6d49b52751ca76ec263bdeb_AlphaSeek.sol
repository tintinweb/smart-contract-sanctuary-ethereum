// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Capped.sol";
import "./Ownable.sol";

contract AlphaSeek is ERC20, ERC20Burnable, Ownable {
    uint256 private immutable _cap;

    /**
     * @dev Initializes `ERC20` token.
     *
     * @param _name string - name of token
     * @param _symbol string - symbol of token
     * @param _totalSupply uint256 - total supply of token
     * @param _beneficiary address - address of beneficiary to receive totalsupply of tokens
     * @dev Sets the value of the `cap`. This value is immutable, it can only be
     * set once during construction.
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply,
        address _beneficiary,
        uint256 cap_
    ) ERC20(_name, _symbol) {
        require(cap_ > 0, "ERC20Capped: cap is 0");
        _cap = cap_;
        _mint(_beneficiary, _totalSupply);
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view virtual returns (uint256) {
        return _cap;
    }

    /**
     * @dev Mints `_amount` ERC20 tokens to `_account`.
     * @param _account address - address of beneficiary to receive tokens
     * @param _amount uint256 - amount of tokens to receive
     */
    function mint(address _account, uint256 _amount) public onlyOwner {
        require(
            ERC20.totalSupply() + _amount <= cap(),
            "ERC20Capped: cap exceeded"
        );
        _mint(_account, _amount);
    }
}