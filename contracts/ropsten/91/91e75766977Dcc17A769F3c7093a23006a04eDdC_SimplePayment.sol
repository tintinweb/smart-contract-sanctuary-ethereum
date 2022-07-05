// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface DaiToken {
    function transfer(address dst, uint wad) external returns (bool);
    function transferFrom(address src, address dst, uint wad) external returns (bool);
    function balanceOf(address guy) external view returns (uint);
}

contract SimplePayment {
    DaiToken public usdcToken;
    address public owner;

    constructor(){
        usdcToken = DaiToken(0x07865c6E87B9F70255377e024ace6630C1Eaa37F);
        owner = msg.sender;
    }

    event PaymentSent(address employee, address employeeAddress, uint256 value, uint256 serviceFee, string currency);

    function pay(address employee, uint256 fee, string memory currency, uint256 value) public {//calculate fee in frontend
        uint256 moneyForEmployee = value - fee;
        if(keccak256(abi.encodePacked((currency))) == keccak256(abi.encodePacked(("ETH")))){
            payable(owner).transfer(fee);
            payable(employee).transfer(moneyForEmployee);
        }else if(keccak256(abi.encodePacked((currency))) == keccak256(abi.encodePacked(("USDC")))){
            usdcToken.transfer(owner, fee);
            usdcToken.transferFrom(msg.sender, employee, moneyForEmployee);
        }
        emit PaymentSent(msg.sender, employee, moneyForEmployee, fee, currency);
    }
    function getBalance(address user) public view returns(uint256){
        return usdcToken.balanceOf(user);
    }
}