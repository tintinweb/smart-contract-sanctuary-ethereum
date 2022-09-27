// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract TX {

    address public owner; // contract owner
    address payable public vault; // address which will get fees
    uint256 public etherFee; // fix number or percantage 
    uint256 public tokenFee; // fix number 
    bool public kindEtherFee;  // if this parametr is true - the fee is a percentage
                               //if this parametr is false - commision is a number

    constructor(
        address owner_,
        address payable vault_,
        uint256 etherFee_,
        uint256 tokenFee_,
        bool kindEtherFee_
    ) {
        owner = owner_;
        vault = vault_;
        etherFee = etherFee_;
        tokenFee = tokenFee_;
        kindEtherFee = kindEtherFee_;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function txTokens(IERC20[] calldata _tokenAdresses, address[] calldata _addresses, uint256[] calldata _amounts) external  {
        address _msgSender = msg.sender;
        uint256 _size = _addresses.length;
        require
        (
            _size == _amounts.length,
            "Not same lenght of _addresses and _amounts"
        );
        require
        (
            _size == _tokenAdresses.length,
            "Not same lenght of _addresses and _amounts"
        );
        IERC20 _tokenAddress;
        uint256 _userAmount;
        for (uint256 i = 0; i < _size;) {
            _tokenAddress = _tokenAdresses[i];
            _userAmount = _amounts[i];
            if 
            (
                _userAmount > tokenFee && 
                _tokenAddress.balanceOf(_msgSender) >= _userAmount
            ) {
                _tokenAddress.transferFrom(_msgSender, _addresses[i], _userAmount -= tokenFee);
        }
        unchecked { ++i; } // lower gas
        }
    }


    function txEther(address payable[] calldata _addresses, uint256[] calldata _amounts) payable external {
        uint256 _msgValue = msg.value;
        require(_msgValue > 0, "Zero ether");
        uint256 _size = _addresses.length;
        require
        (
            _size == _amounts.length,
            "Not same lenght of _addresses and _amounts"
        );
        
        uint256 _userAmount;
        uint256 _realUserAmount;
        address payable _userAddress;

        for (uint256 i = 0; i < _size;) {
            _userAmount = _amounts[i];
            _userAddress = _addresses[i];
            
            if (kindEtherFee) {
                transferPercantageEther(_msgValue, _userAmount, _userAddress);
            } else {
                transferFixEther(_msgValue, _realUserAmount, _userAmount, _userAddress);
            }
            unchecked { ++i; } // lower gas
        }
    }

    function transferPercantageEther(
        uint256 _msgValue,
        uint256 _userAmount,
        address payable _userAddress
        ) internal {
        _msgValue -= _userAmount;
        uint256 _comission = _userAmount * etherFee / 100;
        _userAddress.transfer(_userAmount - _comission);
    }

    function transferFixEther(
        uint256 _msgValue,
        uint256 _realUserAmount,
        uint256 _userAmount,
        address payable _userAddress
        ) internal {
        _msgValue -= _userAmount;
        _realUserAmount = _userAmount - etherFee;
        _userAddress.transfer(_realUserAmount);
    }

    function withdraw(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Withdrawable: Amount has to be greater than 0");
        require(
            _amount <= address(this).balance,
            "Withdrawable: Not enough funds"
        );
        vault.transfer(_amount);
    }

    function setEtherFee(uint256 _etherFee, bool _kindEtherFee) external onlyOwner {
        require(_etherFee > 0, "Zero fee");
        kindEtherFee = _kindEtherFee;
        etherFee = _etherFee;
    }

    function setTokenFee(uint256 _tokenFee) external onlyOwner {
        require(_tokenFee > 0, "Zero fee");
        tokenFee = _tokenFee;
    }

    function setOwner(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function setVault(address payable _newVault) external onlyOwner {
        vault = _newVault;
    }
}