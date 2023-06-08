// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract SquirtleCoinToken is ERC20 {

    address private mining = address(0x0B606A9D9C944ac9348724856FC6b5883Ef24B34);//mining address
    address private staking = address(0x7Ed6574f686E0Fc8d54994AeA81e1c573004FD79);//staking address
    address private marketing = address(0x46BF3459fF1d3424eD79CE3148D56475D4B078F3);//marketing address
    address private exchange_listings = address(0xB01523eb1aFD0D220bC1Dc9ec31F887bC9D0Ed70); //team address


    constructor() ERC20("SquirtleCoin Token", "SQRT1"){
        _mint(msg.sender, 302533999999 * 10**18);
        
        mint(staking,22183199999 * 10**18);
        mint(marketing,22183199999 * 10**18);
        mint(exchange_listings,22183199999 * 10**18);
    }

    function mint(address account, uint256 amount) internal virtual returns (bool) {
        address sender = _msgSender();
        require(sender == mining, "ERC20: mint to the zero address");
        _mint(account,amount);
        return true;
    }
}