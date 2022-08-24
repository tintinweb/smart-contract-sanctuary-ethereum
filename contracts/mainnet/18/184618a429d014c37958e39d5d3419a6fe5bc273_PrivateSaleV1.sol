/**
 *Submitted for verification at Etherscan.io on 2022-08-24
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function getOwner() external view returns (address);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Ownable {
    address internal owner;
    constructor(address _owner) { owner = _owner; }
    modifier onlyOwner() { require(isOwner(msg.sender), "!OWNER"); _; }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

contract PrivateSaleV1 is Ownable {
  using SafeMath for uint256;

  address private tokenpayment;
  address private tokenreceive;
  uint256 private swapratio;

  event ChangeState(address tokenpayment, address tokenreceive,uint256 swapratio);
  event Bought(address indexed buyer,address tokenpayment,uint256 paidamount,address tokenreceive,uint256 receiveamount,uint256 txwhen);

  constructor(address _tokenpayment,address _tokenreceive,uint256 _swapratio) Ownable(msg.sender) {
    tokenpayment = _tokenpayment;
    tokenreceive = _tokenreceive;
    swapratio = _swapratio;
  }

  function buypresale(uint256 _paymentamount) public returns (bool) {
    IERC20 tokenA = IERC20(tokenpayment);
    IERC20 tokenB = IERC20(tokenreceive);
    uint256 receiveamount = _paymentamount.mul(swapratio);
    tokenA.transferFrom(msg.sender,owner,_paymentamount);
    tokenB.transfer(msg.sender,receiveamount);
    emit Bought(msg.sender,tokenpayment,_paymentamount,tokenreceive,receiveamount,block.timestamp);
    return true;
  }

  function structor(address _tokenpayment,address _tokenreceive,uint256 _swapratio) external onlyOwner() returns (bool) {
    tokenpayment = _tokenpayment;
    tokenreceive = _tokenreceive;
    swapratio = _swapratio;
    emit ChangeState(_tokenpayment,_tokenreceive,_swapratio);
    return true;
  }

  function contractstate() external view returns (address tokenpayment_,address tokenreceive_,uint256 swapratio_) {
    return (tokenpayment,tokenreceive,swapratio);
  }

  function cancalpool(address _tokenAddress) external onlyOwner() returns (bool) {
    IERC20 token = IERC20(_tokenAddress);
    token.transfer(owner,token.balanceOf(address(this)));
    return true;
  }

  function purge() external onlyOwner() returns (bool) {
    (bool success, ) = msg.sender.call{ value : address(this).balance }("");
    require(success,"purge fail!");
    return true;
  }

}