// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.13;

import "./IERC721.sol";
import "./Clock.sol";

contract ClockMint{
    uint256 public _publicMintPrice = 0.02*10**18;

    address public _clockAddress;
    address public _recipient;

    bool public _publicMintOpened;

    mapping(address => bool) public _isAdmin;

    constructor(){
        _isAdmin[msg.sender]=true;
        _recipient = msg.sender;
    }
    

    function setClockAddress(address clockAddress) external{
        require(_isAdmin[msg.sender], "Only Admins can set LuxAddress");
        _clockAddress = clockAddress;
    }

    function setRecipient(address recipient) external{
        require(_isAdmin[msg.sender], "Only Admins can set the recipient");
        _recipient = recipient;
    }

    function togglePublicMintOpened() external{
        require(_isAdmin[msg.sender], "Only Admins can toggle AL Mint");
        _publicMintOpened = !_publicMintOpened;
    }


    function publicMint(
    ) external payable{
        require(_publicMintOpened, "Mint closed");
        require(msg.value >= _publicMintPrice, "Not enough funds");
        payable(_recipient).transfer(_publicMintPrice);
        Clock(_clockAddress).adminMint(msg.sender);
    }


}