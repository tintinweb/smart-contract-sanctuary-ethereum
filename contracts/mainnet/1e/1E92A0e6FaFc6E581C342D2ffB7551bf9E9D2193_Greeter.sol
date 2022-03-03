pragma solidity ^0.8.2;

contract Mortal {
    /* Define variable owner of the type address */
    address owner;

    /* This function is executed at initialization and sets the owner of the contract */
    constructor()  { owner = msg.sender; }

    /* Function to recover the funds on the contract */
    function kill() public  { if (msg.sender == owner) selfdestruct(payable(owner)); }
}

contract Greeter is Mortal {
    /* Define variable greeting of the type string */
    string greeting;
    uint16 __num;

    /* This runs when the contract is executed */
    constructor(uint16 _num)  {
        __num = _num;
        greeting = string(abi.encodePacked("Hello World! ", _num));
    }

    /* Main function */
    function greet() public view returns (string memory) {
        return string(greeting);
    }
}