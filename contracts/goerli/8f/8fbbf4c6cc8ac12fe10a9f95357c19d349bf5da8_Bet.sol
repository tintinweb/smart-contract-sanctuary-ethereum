// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";


contract Bet is  Ownable {

    uint256 public taxRate;
    address payable public USDTTokenAddress;
    address public taxAccount;
    address public baseAccount;

    event Deposit(address indexed user, uint256 amount);

    constructor(address payable _USDTtoken){
        taxRate = 0;
        taxAccount = msg.sender;
        baseAccount = msg.sender;
        USDTTokenAddress = _USDTtoken;
    }

    function Trxdesposit(uint256 _amount) payable external returns (bool){
        if(IERC20(USDTTokenAddress).allowance(msg.sender, address(this)) < _amount){
            revert("Isufficient token deposit amount");
        }

        uint256 taxfees = _amount * taxRate / 100;
        uint256 remain = _amount - taxfees;

        IERC20(USDTTokenAddress).transferFrom(msg.sender, address(this), _amount);
        IERC20(USDTTokenAddress).transfer(taxAccount, taxfees);
        IERC20(USDTTokenAddress).transfer(baseAccount, remain);

        emit Deposit(msg.sender, _amount);

        return true;
    }

    function setTaxrate(uint256 rate) external onlyOwner returns (bool){
        taxRate = rate;
        return true;
    }

    function setTaxAccount(address payable _address) external onlyOwner returns (bool){
        taxAccount = _address;
        return true;
    }

    function setBaseAccount(address payable _address) external onlyOwner returns (bool){
        baseAccount = _address;
        return true;
    }

    function setUSDT(address payable _address) external onlyOwner returns (bool){
        USDTTokenAddress = _address;
        return true;
    }
}