// SPDX-License-Identifier: MIT

// Version
pragma solidity ^0.8.4;

import "./ERC_20_Full.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./Context.sol";

contract customERC_20 is Ownable, ERC20, Pausable{
    // constructor(string memory _name, string memory _symbol, uint256 _totalSupply, uint256 _cap, address _newOwner) ERC20(_name, _symbol){
    //     _capped(_cap*(uint256(10) ** 18));
    //     _mint(_msgSender(), _totalSupply * (uint256(10) ** 18));
    //     _transferOwnership(_newOwner);
    //     _transfer(_msgSender(), _newOwner, _totalSupply * (uint256(10) ** 18));
    // }

    constructor() ERC20("Rubies", "RBS"){
        address _newOwner = 0x68905da737e5a11E3A93AB6CeC2eA8b145fce961;
        uint256 _cap = 1000000000 *(uint256(10) ** 18);
        uint256 _totalSupply = 1000000000;
        _capped(_cap);
        _mint(_msgSender(), _totalSupply * (uint256(10) ** 18));
        _transferOwnership(_newOwner);
        _transfer(_msgSender(), _newOwner, _totalSupply * (uint256(10) ** 18));
    }

    function mint(uint256 _amount) public onlyOwner{
        _mint(_msgSender(), _amount);
    }

    function burn(uint256 _amount) public onlyOwner{
        _burn(_msgSender(), _amount);
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function blacklistAddress(address account) public onlyOwner {
        _blacklistAddress(account);
    }

    function unBlacklistAddress(address account) public onlyOwner {
        _unBlacklistAddress(account);
    }

    

    function transferOwnership(address _newOwner) public override onlyOwner{
        _transferOwnership(_newOwner);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal whenNotPaused override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}