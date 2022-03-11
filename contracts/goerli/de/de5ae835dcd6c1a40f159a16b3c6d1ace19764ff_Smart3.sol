/**
 *Submitted for verification at Etherscan.io on 2022-03-10
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Smart3
 */
contract Smart3 {

    string private name;
    mapping(address => uint256) private balances;

    event Minted(address receiver, uint256 amount);
    event Transferred(address sender, address receiver, uint256 amount);

    constructor(string memory myName) {
        name = myName;
    }

    function mint(address receiver, uint256 amount) public {
        balances[receiver] = balances[receiver] + amount;
        emit Minted(receiver, amount);
    }

    function transfer(address sender, address receiver, uint256 amount) public {
        require(balances[sender] >= amount, "You are not able to do this transaction!"); 
        balances[sender] = balances[sender] - amount;
        balances[receiver] = balances[receiver] + amount;
        emit Transferred(sender, receiver, amount);
    }

    function transferFromMe(address receiver, uint256 amount) public {
        require(balances[msg.sender] >= amount, "You are not able to do this transaction!"); 
        balances[msg.sender] = balances[msg.sender] - amount; 
        balances[receiver] = balances[receiver] + amount;
        emit Transferred(msg.sender, receiver, amount);
    }

    function burn(uint256 amount) public {
        require(balances[msg.sender] >= amount, "You are not able to do this transaction!"); 
        balances[msg.sender] = balances[msg.sender] - amount; 
        emit Transferred(msg.sender, address(0), amount);
    }

    function balanceOf(address user) public view returns (uint256) {
        return balances[user];
    }

    function getName() public view returns (string memory){
        return name;
    }
}