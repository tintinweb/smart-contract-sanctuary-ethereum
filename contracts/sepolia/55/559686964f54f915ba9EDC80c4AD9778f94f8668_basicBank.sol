/**
 *Submitted for verification at Etherscan.io on 2023-06-11
*/

// File: basicBank.sol


pragma solidity >=0.6.0 <0.9.0;
contract basicBank {
event valueReceived(address sender, uint amount);
mapping (address => uint) public balance;
receive() external payable {
  emit valueReceived(msg.sender, msg.value);
  // React to receiving ETH or do nothing and just store it 
        }
fallback() external  {
	// React to a default function call
	}
function deposit() public payable 
{
  emit valueReceived(msg.sender, msg.value);
  balance[msg.sender]+=msg.value;
    } 
function withdraw() public payable returns (bool, bytes memory) 
{ 
  require(balance[msg.sender]>0);
  uint _balance=balance[msg.sender];
  balance[msg.sender]=0;
  (bool sent, bytes memory data) = msg.sender.call{value: _balance}("");
  return (sent, data);
    } 
}
// File: bankFactory.sol


pragma solidity >=0.6.0 <0.9.0;

contract bankFactory {
basicBank[] public branches; 
function createNewBranch() public {
     basicBank branch = new basicBank();
     branches.push(branch);
   }
function getTotalBalance() public view returns (uint){
     uint totalBalance;
     for (uint i=0;i<branches.length;i++){
     totalBalance+=basicBank(branches[i]).balance(msg.sender);
   }
   return totalBalance;
}
}