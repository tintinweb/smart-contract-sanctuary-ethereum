//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./ERC20.sol";
import "./Authorizable.sol";

contract QQQQQ is ERC20, Authorizable {
    string private TOKEN_NAME = "QQQQQ";
    string private TOKEN_SYMBOL = "QQ";

    event Minted(address owner, uint256 TestingAmt);
    event Burned(address owner, uint256 TestingAmt);

    mapping(address => bool) public authorizedToMint;

    modifier onlyAuthorizedToMint() {
        require(authorizedToMint[msg.sender] ||  owner() == msg.sender, "Not authorized to mint");
        _;
    }

     function addAuthorizedToMint(address _toAdd) onlyOwner public {
        require(_toAdd != address(0));
        authorizedToMint[_toAdd] = true;
    }

    function removeAuthorizedToMint(address _toRemove) onlyOwner public {
        require(_toRemove != address(0));
        require(_toRemove != msg.sender);
        authorizedToMint[_toRemove] = false;
    }

    // Constructor
    constructor() ERC20(TOKEN_NAME, TOKEN_SYMBOL) {
    }

    function mint(address to, uint256 amount) external onlyAuthorizedToMint {
        _mint(to, amount);
        emit Minted(to, amount);
    }

    function burn(address sender, uint256 amount) external onlyAuthorized {
        require(balanceOf(sender) >= amount, "NOT ENOUGH ACT");
        _burn(sender, amount);
        emit Burned(sender, amount);
    }
}