// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.13;

import "./IERC1155.sol";
import "./Multivaria.sol";

contract MultivariaOpenMint{
    uint256 public _price = 0.08 ether;
    uint256 public _maxSupply = 200;
    uint256 public _supply;

    address public _multivariaAddress;
    address public _recipient;

    bool public _mintOpened;

    mapping(address => bool) public _isAdmin;

    constructor(){
        _isAdmin[msg.sender]=true;
    }

    modifier adminOnly(){
        require(_isAdmin[msg.sender], "Admins only");
        _;
    }

    function setAdmin (address admin) external adminOnly{
        _isAdmin[admin]= !_isAdmin[admin];
    }

    function setRecipient (address recipient) external adminOnly{
        _recipient = recipient;
    }

    function setPrice (uint256 price) external adminOnly{
        _price = price;
    }

    function setMultivariaAddress(address multivariaAddress) external adminOnly{
        _multivariaAddress = multivariaAddress;
    }

    function toggleMintOpened() external adminOnly{
        _mintOpened = !_mintOpened;
    }

    function updateSupply(uint256 supply) external adminOnly{
        _supply = supply;
    }

    function publicMint(uint256 quantity)external payable{
        require(_mintOpened, "Public mint is currently closed");    
        require(_supply + quantity <= _maxSupply,"Max supply reached");
        require(msg.value >= _price * quantity, "Not enough funds");
        payable(_recipient).transfer(_price * quantity);
        Multivaria(_multivariaAddress).mint(msg.sender, 12, quantity);
        Multivaria(_multivariaAddress).mint(msg.sender, 13, quantity);
        _supply += quantity;
    }
}