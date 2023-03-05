/**
 *Submitted for verification at Etherscan.io on 2023-03-05
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.20 <0.5;
//import "hardhat/console.sol";
//import "contracts/TF_erc20.sol";
//import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
//import "@openzeppelin/contracts/access/Ownable.sol";
//import "@openzeppelin/contracts/access/AccessControl.sol";

contract TrustFund{
  Logger public TrustLog;
  string name;
  address owner;
  address admin;
  uint256 public minDeposit;
  uint256 public percent = 100;
  mapping (address => uint256) balances;

  Checker public Getter;
  //TF public Token;

  
  struct Change {
    address new_owner;
    string name;
  }

  Change[] public owner_history;

  constructor (address _logger, address _getter) public payable {
  //constructor (address _logger, address _getter, address _token) public payable {
    owner = msg.sender;
    name = "contract creator";
    minDeposit = 100e18;        // in USD
    TrustLog = Logger(_logger);
    Getter = Checker(_getter);
    //Token = TF(_token);
  }



  function setPercent(uint256 _p) public {
    percent = _p;
  }

  function _setRoleAdmin(address _to) public {
    require(msg.sender == owner);
    admin = _to; 
  }

  function transferOwner(address _to, string memory _name) public {
    require(msg.sender == owner || msg.sender == admin);

    Change change;
    change.new_owner = _to;
    change.name = _name;

    //console.log(address(TrustLog));

    if (owner == _to){              
      owner_history.push(change);
      owner = _to;
      name = _name;
    }
  }

  function getEP() public view returns (uint256){
    return  Getter.getETHPrice() * percent / 1e20; // 1e18 
  }


  function deposit() public payable returns (bool) {
    uint256 ep = getEP();
    //uint256 bp = getBP();
    //console.log("price ETH: ", ep);
    //console.log("price BTC: ", bp);

    uint256 deposit_value = msg.value * ep;

    if (deposit_value >= minDeposit) {//100 TF tokens
      //console.log("Supple", Token.balanceOf(this));
      //console.log("Transf", deposit_value);
      //Token.transfer(msg.sender, deposit_value);
      balances[msg.sender]+=msg.value;
      //console.log("enough msg.value");
      TrustLog.LogTransfer(msg.sender,msg.value,"deposit");
    } else {
        //console.log("value:", msg.value);
      //console.log("Not enough msg.value");
      TrustLog.LogTransfer(msg.sender,msg.value,"depositFailed");
    }
  }

  function withdraw(uint256 _amount) public {
    if(_amount <= balances[msg.sender]) {
      //console.log("Finish transfer?");
      if(msg.sender.call.value(_amount)("")) {
        balances[msg.sender] -= _amount;
        //Token.transferFrom(msg.sender, this, _amount);
        TrustLog.LogTransfer(msg.sender, _amount, "withdraw");
      } else {
        TrustLog.LogTransfer(msg.sender, _amount, "withdrawFailed");
      }
    }
  }

  function checkBalance(address _addr) public view returns (uint256) {
    return balances[_addr];
  }
}

contract Checker {
  function getETHPrice() public view returns (uint256){
    return 1567933900000000000000;
  }
}

contract Logger {
  struct Message {
    address sender;
    uint256 amount;
    string note;
  }

  Message[] History;
  Message public LastLine;

  function LogTransfer(address _sender, uint256 _amount, string memory _note) public {
    LastLine.sender = _sender;
    LastLine.amount = _amount;
    LastLine.note = _note;
    History.push(LastLine);
  }
}