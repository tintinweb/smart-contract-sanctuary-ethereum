// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";

contract LOVE is ERC20, Ownable{

    mapping(address => bool) public isApprovedAddress;

    constructor (
        string memory _name,
        string memory _symbol
    )ERC20(_name,_symbol){ }
    
    modifier onlyApprovedAddresses{
        require(isApprovedAddress[msg.sender], "You are not authorized!");
        _;
    }

    function mint(address _to, uint256 _amount) external onlyApprovedAddresses{
        _mint(_to, _amount);
    }

    function burn(address _to, uint256 _amount) external onlyApprovedAddresses{
        _burn(_to, _amount);
    }
    
    function setApprovedAddresses(address _approvedAddress, bool _set) external onlyOwner(){
        isApprovedAddress[_approvedAddress] = _set;
    }
    
}