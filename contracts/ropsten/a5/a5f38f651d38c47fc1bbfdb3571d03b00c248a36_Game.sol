/**
 *Submitted for verification at Etherscan.io on 2022-03-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Game {

    uint totalSupply;
    mapping(address => uint) public balanceOf;
 
    string name = "ChI";
    string symbol = "ChI";
    uint8 decimals = 0;
    uint pc;
   
    uint[] data =    [0, 0, 1, 0, 1, 0, 0, 0, 0, 1,   // 1
                      0, 1, 0, 0, 0, 0, 0, 0, 1, 0,   // 2
                      1, 1, 0, 0, 0, 1, 0, 0, 0, 0,   // 3
                      0, 1, 1, 0, 0, 0, 1, 0, 0, 1,   // 4
                      1, 1, 0, 0, 0, 0, 0, 0, 0, 0,   // 5
                      1, 0, 1, 0, 0, 0, 0, 1, 1, 0,   // 6
                      0, 0, 0, 1, 0, 1, 0, 0, 0, 0,   // 7
                      0, 1, 0, 1, 0, 0, 1, 0, 0, 1,   // 8
                      1, 0, 0, 1, 0, 1, 0, 1, 0, 0,   // 9
                      0, 0, 1, 0, 0, 1, 1, 0, 1, 0];  // 10

    constructor() {
        mint(1000);
    }
  
    function transferFrom(address sender, address recipient, uint amount) private returns (bool) {
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        return true;
    }

    function mint(uint amount) private {
        balanceOf[msg.sender] += amount/2;
        balanceOf[address(this)] += amount/2;
        totalSupply += amount;
    }

    // There is vulnerability.
    function Random() private view returns(uint) {
        return data[(block.timestamp*block.timestamp%100)];
    }

    function Play(uint player) public returns(string memory){
        pc = Random(); 

        // Check condition.
        require(player == 0 || player == 1, "You only can bet 1 or 0!");
    
        // Player will get money from bank, If win, otherwise, chips will be deducted.
        if (player == 1 && pc == 1) {
            transferFrom(address(this), msg.sender, 3);
            return "Pc is 1, You won 3 token !";
        } else if (player == 0 && pc == 0) {
            transferFrom(address(this), msg.sender, 1);
            return "Pc is 0, You won 1 token !";
        } else {
            transferFrom(msg.sender, address(this), 2);
            return "You are different, lost 2 ether !";
        }
    }

}