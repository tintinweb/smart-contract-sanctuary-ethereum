// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./ERC20.sol";

contract TanimoToken is ERC20 { 
    using SafeMath for uint256;

    /**
     * @dev Value send to contract should be equal with `amount`.
     */
    modifier validateFee(uint256 _amount) {
        require(msg.value == _amount, "Invalid network fee");
        _;
    }

    /**
     * @dev Action only called from owner.
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, "You do not have right");
        _;
    }

    /**
     * @dev Owner of token.
     */
    address payable public _owner;

    /**
     * @dev The Tanimoto Token constructor.
     */
    constructor(address payable _ownerOfToken) ERC20("Tanimo Token", "TTJP") {
        _owner = _ownerOfToken;
    }

    /**
     * @dev Mint token to an address.
     * @param _receiver : receivers address
     * @param _amountToken : amount token to mint
     */
    function mintToken(address _receiver, uint _amountToken) onlyOwner public {
        _mint(_receiver, _amountToken);
    }

    /**
     * @dev Burn token of an address.
     * @param _from : from address
     * @param _amountToken : amount token to burn
     */
    function burnToken(address _from, uint _amountToken) onlyOwner public {
        _burn(_from, _amountToken);
    }
}