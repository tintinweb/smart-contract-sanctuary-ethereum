/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

pragma solidity ^0.7.0;

/**
 * Mixer Contract
 *
 * This contract implements a mixer that can be used to anonymously
 * transfer Ether from one address to another. 
 */
contract Mixer {
    
    // The minimum amount of Ether required to use the mixer
    uint256 public minimumAmount = 0.1 ether;
    
    // The address that owns the mixer
    address public owner;
    
    // A mapping of addresses to balances for each address
    mapping (address => uint256) public balances;
    
    // The constructor sets the owner address
    constructor() public {
        owner = msg.sender;
    }
    
    // The function to deposit Ether into the mixer
    function deposit() public payable {
        // Reject any amount less than the minimum amount
        require(msg.value >= minimumAmount, "Amount must be greater than the minimum amount");
        
        // Add the deposited Ether to the address' balance
        balances[msg.sender] += msg.value;
    }
    
    // The function to withdraw Ether from the mixer
    function withdraw(uint256 _amount) public {
              require(_amount  > 0, "Amount must be greater than the minimum amount");
              require(_amount  <= balances[msg.sender], "insufficient funds");
                

              // Withdraw the requested amount
              msg.sender.transfer(_amount);
              
              // Reduce the address' balance
              balances[msg.sender] -= _amount;
    }
    
    // The function to transfer Ether from one address to another
    function transfer(address _to, uint256 _amount) public {
        require(_amount  > 0, "Amount must be greater than the minimum amount");
        require(_amount  <= balances[msg.sender], "insufficient funds");
        
        // Reduce the sender's balance
        balances[msg.sender] -= _amount;
    }
    
    // The function to withdraw all funds from the mixer
    function withdrawAll() public {
        uint256 _amount = balances[msg.sender];
        require(_amount  > 0, "Amount must be greater than the minimum amount");
        
        // Withdraw the requested amount
        msg.sender.transfer(_amount);
        
        // Reduce the address' balance
        balances[msg.sender] = 0;
       }
}