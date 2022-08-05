// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

/**

 * @title AREVEA-Token
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `ERC20` functions.
 */

contract AREVEAToken is ERC20,Ownable {

    using SafeMath for uint256;

    uint8 public constant DECIMALS = 18;

    uint256 public constant INITIAL_SUPPLY = 1000000 * (10 ** uint256(DECIMALS));

    uint256 public constant Maximum_SUPPLY = 1000000000000 * (10 ** uint256(DECIMALS));

    /**

     * @dev Constructor that gives msg.sender all of existing tokens.

     */

    constructor () ERC20 ("AREVEA", "AVA") {

        mint(msg.sender, INITIAL_SUPPLY);

    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
 	* the total supply.
 	*
 	* Emits a {Transfer} event with `from` set to the zero address.
 	*
 	* Requirements:
 	*
 	* - `account` cannot be the zero address.
 	*/

    function mint(address account, uint256 amount) public  onlyOwner  {

       require(totalSupply().add(amount) <= Maximum_SUPPLY,"Maximum supply reached") ;

      _mint(account,amount);

    }  
   /**
 	* @dev Destroys `amount` tokens from the caller.
 	*
 	* See {ERC20-_burn}.
 	*/
   
    function burn(uint256 amount) public {

      _burn(msg.sender, amount);

    }
    /**
 	* @dev Destroys `amount` tokens from `account`, deducting from the caller's
 	* allowance.
 	*
 	* See {ERC20-_burn} and {ERC20-allowance}.
 	*
 	* Requirements:
 	*
 	* - the caller must have allowance for ``accounts``'s tokens of at least
 	* `amount`.
 	*/
    function burnFrom(address account, uint256 amount) public virtual {

        _spendAllowance(account, _msgSender(), amount);

        _burn(account, amount);

    }

   

}