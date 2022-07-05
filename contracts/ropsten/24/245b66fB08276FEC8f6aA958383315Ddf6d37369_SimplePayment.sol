// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract SimplePayment {
    IERC20 public usdcToken;
    address public owner;

    constructor(){
        usdcToken = IERC20(0x07865c6E87B9F70255377e024ace6630C1Eaa37F);
        owner = msg.sender;
    }

    event PaymentSent(address employee, address employeeAddress, uint256 value, uint256 serviceFee, string currency);

    function pay(address employee, uint256 fee, string memory currency, uint256 value) public {//calculate fee in frontend
        uint256 moneyForEmployee = value - fee;
        if(keccak256(abi.encodePacked((currency))) == keccak256(abi.encodePacked(("ETH")))){
            payable(owner).transfer(fee);
            payable(employee).transfer(moneyForEmployee);
        }else if(keccak256(abi.encodePacked((currency))) == keccak256(abi.encodePacked(("USDC")))){
            usdcToken.transferFrom(msg.sender, owner, fee);
            usdcToken.transferFrom(msg.sender, employee, moneyForEmployee);
        }
        emit PaymentSent(msg.sender, employee, moneyForEmployee, fee, currency);
    }
    function approveTransaction(address spender, uint256 amount) public {
        usdcToken.approve(spender, amount);
    }
    function getBalance(address user) public view returns(uint256){
        return usdcToken.balanceOf(user);
    }
}