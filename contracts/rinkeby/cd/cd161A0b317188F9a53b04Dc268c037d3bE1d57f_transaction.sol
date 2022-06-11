// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract transaction {
    
    address public minter;
    mapping (address => uint) public balances;

    event Sent(address from, address to, uint amount);

    constructor() public {
        minter = msg.sender;
    }

    function mint(address receiver, uint amount) public {
        require(msg.sender == minter);
        balances[receiver] += amount;
    }

    error InsufficientBalance(uint requested,uint avaliable);

    function sent(address receiver, uint amount) public {
        if (balances[msg.sender] < amount)
            revert InsufficientBalance({
                requested: amount,
                avaliable: balances[msg.sender]
            });

        balances[msg.sender] -= amount;
        balances[receiver] += amount;
        emit Sent(msg.sender,receiver,amount);
    }

}