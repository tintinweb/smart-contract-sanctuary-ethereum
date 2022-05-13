// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ERC20.sol";
import "ERC20Burnable.sol";
import "Pausable.sol";
import "Ownable.sol";

contract Ater is ERC20, ERC20Burnable, Pausable, Ownable {
    constructor() ERC20("Aterium Stone", "ATER") {
         _mint(msg.sender, 40000000 * 10 ** decimals());
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function airdrop(address[] calldata buyers, uint256[] calldata amount) public payable onlyOwner{
       for(uint256 i = 0; i < buyers.length; i++ ){
       
        transfer(buyers[i], amount[i]*1000);


       }


    }

}