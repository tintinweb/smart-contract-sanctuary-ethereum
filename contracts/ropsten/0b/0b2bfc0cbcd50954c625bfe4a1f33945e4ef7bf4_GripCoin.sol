/**
 *Submitted for verification at Etherscan.io on 2022-02-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract GripCoin {
    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;

    string public name = "GripCoin";
    string public symbol = "G";
    uint256 public max_supply = 999999999999999999999 ;
    uint256 public unspent_supply = 0;
    uint256 public spendable_supply = 0;
    uint256 public circulating_supply = 0;
    uint256 public decimals = 0;
    uint256 public reward = 12000000000000;
    uint256 public timeOfLastHalving = block.timestamp;
    uint public timeOfLastIncrease = block.timestamp;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Mint(address indexed from, uint256 value);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    

      // constructor
      constructor() {
      timeOfLastHalving = block.timestamp;
    }

    function updateSupply() internal returns (uint256) {

      if (block.timestamp - timeOfLastHalving >= 1051200 minutes) {
        reward /= 2;
        timeOfLastHalving = block.timestamp;
      }

      if (block.timestamp - timeOfLastIncrease >= 2 seconds) {
        uint256 increaseAmount = ((block.timestamp - timeOfLastIncrease) / 2 seconds) * reward;
        spendable_supply += increaseAmount;
        unspent_supply += increaseAmount;
        timeOfLastIncrease = block.timestamp;
      }

      circulating_supply = spendable_supply - unspent_supply;

      return circulating_supply;
    }

    /* Send Grip coins */
    function transfer(address _to, uint256 _value) public {
        require(balanceOf[msg.sender] >= _value);           // Check if the sender has enough
        require(balanceOf[_to] + _value >= balanceOf[_to]); // Check for overflows
        balanceOf[msg.sender] -= _value;                    // Subtract from the sender
        balanceOf[_to] += _value;                           // Add the same to the recipient

        updateSupply();

        /* Notify anyone listening that the transfer took place */
        emit Transfer(msg.sender, _to, _value);

    }
    /* Mint new coins by sending ether */
    function mint() public payable {
        uint256 _value = msg.value / 10000;require(balanceOf[msg.sender] + _value >= balanceOf[msg.sender]); // Check for overflows
        

        updateSupply();

        require(unspent_supply - _value <= unspent_supply);
        unspent_supply -= _value; // Remove from unspent supply
        balanceOf[msg.sender] += _value; // Add the same to the recipient

        updateSupply();

        /* Notify anyone listening that the minting took place */
        emit Mint(msg.sender, _value);

    }

    function withdraw(uint256 amountToWithdraw) public returns (bool) {

        // Balance given in Grip

        require(balanceOf[msg.sender] >= amountToWithdraw);
        require(balanceOf[msg.sender] - amountToWithdraw <= balanceOf[msg.sender]);

        // Balance checked in HOW, then converted into Wei
        balanceOf[msg.sender] -= amountToWithdraw;

        // Added back to supply in Grip
        unspent_supply += amountToWithdraw;
        // Converted into Wei
        amountToWithdraw *= 10000;

        // Transfered in Wei
        payable(msg.sender).transfer(address(this).balance);

        updateSupply();

        return true;
    }
}