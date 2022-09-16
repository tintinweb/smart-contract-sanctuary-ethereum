// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.13;

import "./IERC721.sol";
import "./Clock.sol";

contract ClockMint{

    // Congratulations! You found the final contract. 
    // This contract will allow you to mint one Block Clock for free (I mean, you still have to pay gas).
    // I hope you'll enjoy it!
    // The rest of the scavenger hunt was on Rinkeby to save your hard earn ETH. 
    // But this is the real deal. Don't forget to switch back your wallet to Mainnet.
    // If you got here and all the clocks are gone, you can still mint one here: https://block-clock.xyz

    address public _clockAddress;

    bool public _publicMintOpened;

    uint256 public _supply;

    mapping(address => bool) public _isAdmin;
    mapping(address => bool) public _hasAlreadyMinted;

    constructor(){
        _isAdmin[msg.sender]=true;
    }
    

    function setClockAddress(address clockAddress) external{
        require(_isAdmin[msg.sender], "Only Admins can set ClockAddress");
        _clockAddress = clockAddress;
    }

    function togglePublicMintOpened() external{
        require(_isAdmin[msg.sender], "Only Admins can toggle mint");
        _publicMintOpened = !_publicMintOpened;
    }


    function mint(
    ) external {
        require(_publicMintOpened, "Mint closed");
        require(_supply <=5, "No more free Block-Clocks available..." );
        require(!_hasAlreadyMinted[msg.sender],"Leave some for the others...");
        Clock(_clockAddress).adminMint(msg.sender);
        _supply += 1;
        _hasAlreadyMinted[msg.sender] = true;
    }


}