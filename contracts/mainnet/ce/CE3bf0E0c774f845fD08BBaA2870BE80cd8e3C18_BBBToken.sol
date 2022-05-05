// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./ERC20.sol";

// 25000000000000000000000000000 = 25*10**9 * 10**18

contract BBBToken is ERC20 {
    constructor(
        uint256 initialSupply
    ) ERC20("BBBToken", "BBB"){
        _mint(msg.sender, initialSupply);
    }
    /**
    * @dev Returns the name of the token.
    */
    function  name() public view virtual override returns (string memory) {
        return "BerkshireBuffettBitcoin";
    }
    // external_link
    function external_link() public view virtual returns(string memory){
        return "https://BerkshireBuffettBitcoin.com";
    }
    // description
        function description() public view virtual returns(string memory){
        return "BerkshireBuffettBitcoin";
    } 
}