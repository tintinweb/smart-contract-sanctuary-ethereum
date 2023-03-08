//SPDX-License-Identifier: UNLICENSED
// File: contracts/token/BEP20/ANON.sol
/**
 * @title ANON
 https://twitter.com/DexAnonymity
 
 TAX = 5% Going straight to Liquidity
 */
import "./ERC20.sol";
import "./Taxable.sol";
import "./ReentrancyGuard.sol";
import "./AccessControl.sol";

pragma solidity ^0.8.0;

contract ANON is ReentrancyGuard, ERC20, AccessControl, Taxable   {

        bytes32 private constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");
        bytes32 private constant PRESIDENT_ROLE = keccak256("PRESIDENT_ROLE");
        bytes32 private constant EXCLUDED_ROLE = keccak256("EXCLUDED_ROLE"); 
    constructor(
        string memory name_,
        string memory symbol_
    ) payable ERC20(name_, symbol_)  {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(GOVERNOR_ROLE, _msgSender());
        _grantRole(PRESIDENT_ROLE, _msgSender());
        _grantRole(EXCLUDED_ROLE, _msgSender());
        _mint(_msgSender(), 9000000e18);
        _mint(0xB1cfd4aEB87FFB54Aa8f8A40c30B24047358f3f9, 1000000e18);
        
    }
    function enableTax() public onlyRole(GOVERNOR_ROLE) { _taxon(); }
    function disableTax() public onlyRole(GOVERNOR_ROLE) { _taxoff(); }
    function updateTax(uint newtax) public onlyRole(GOVERNOR_ROLE) { _updatetax(newtax); }

    function updateTaxDestination(address newdestination) public onlyRole(PRESIDENT_ROLE) { _updatetaxdestination(newdestination); }
    function _transfer(address from, address to, uint256 amount) // Overrides the _transfer() function to use an optional transfer tax.
            internal
            virtual
            override(ERC20) // Specifies only the ERC20 contract for the override.
            nonReentrant // Prevents re-entrancy attacks.
            {
                if(hasRole(EXCLUDED_ROLE, from) || hasRole(EXCLUDED_ROLE, to) || !taxed()) { // If to/from a tax excluded address or if tax is off...
                    super._transfer(from, to, amount); // Transfers 100% of amount to recipient.
                } else { // If not to/from a tax excluded address & tax is on...
                    require(balanceOf(from) >= amount, "ERC20: transfer amount exceeds balance"); // Makes sure sender has the required token amount for the total.
                    // If the above requirement is not met, then it is possible that the sender could pay the tax but not the recipient, which is bad...
                    super._transfer(from, taxdestination(), amount*thetax()/10000); // Transfers tax to the tax destination address.
                    super._transfer(from, to, amount*(10000-thetax())/10000); // Transfers the remainder to the recipient.
                }
            }



}