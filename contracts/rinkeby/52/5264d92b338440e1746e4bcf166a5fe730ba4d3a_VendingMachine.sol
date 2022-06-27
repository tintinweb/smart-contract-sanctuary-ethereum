/**
 *Submitted for verification at Etherscan.io on 2022-06-27
*/

contract VendingMachine {
    // 1. has an owner that can load in donuts
    // 2. get donut balance
    // 3. allow other addresses to purchase donuts 

    // state 
    address public owner;
    mapping(address => uint) public donutBalance;
    // constructor -> function is called upon deploying the contract 
    // Python:L __init__()
    // Java: main()
    // set the owner to the adddress that deploys this contract 
    constructor() {
        owner = msg.sender; // set the owner to initial address
        donutBalance[address(this)] = 100; // set the initial stock to 100 
    }

    // transfer ownership 
    function setOwner(address newOwner) public {
        // condition 1: address must be vaild 
        require(newOwner != address(0), "Address is invalid");
        // condition 2: only the current owner can call this function 
        require(owner == msg.sender , "Only the current onwer can make transfer");
        // set the current owner to the new onwer; 
        owner = newOwner;
    }

    // 2. get donut balance
    function getVendingMachineBalance() public view returns (uint) {
        // return the balance of donuts from the owner 
        return donutBalance[address(this)];
    }
    // 1. has an owner that can load in donuts
    // = -> assigning some value
    // == -> comparing something 
    function restock(uint amount) public {
        require(msg.sender == owner, "Only the owner can restock");
        donutBalance[address(this)] += amount; 
    }

     // 3. allow other addresses to purchase donuts
     // msg.value -> the amount of ether the sender is sending
     // msg.sender -> the address of the sender
     function purchase(uint amount) public payable {
         // ensure people pay 1 ether per donut
         require(msg.value >= amount * 1 ether, "You must pay 1 ether for every donut!!!");
         // the amount purchased <= what we have in stock 
         require(amount <= donutBalance[address(this)], "Don't have enough stock");
        // reduce the amount of donut that owner has 
        donutBalance[address(this)] -= amount;
        // increase the amount od donut that the address has 
        donutBalance[msg.sender] += amount;
     }

}