/**
 *Submitted for verification at Etherscan.io on 2022-06-26
*/

contract Vendingmachine{
    // donut vending machine 
    // 0. declare I'm the onwer of the VM upon deployment 
    // 1. checking the stocks of donut in VM
    // 2. allow owner to restock
    // 3. allow different addresses to purchase 
    // state variables 
    address public owner; 
    mapping (address => uint) private DonutBalance; // the remaining donuts one can purchase 

    // 0. declare I'm the onwer of the VM upon deployment 
    constructor(){
        owner = msg.sender; // set the owner variable to the current address
        DonutBalance[address(this)] = 100; // give owner an initial stock of 100 donuts to every one
    }
    // 1. checking the stocks of donut in VM
    function getVendingMachineBalance() public view returns (uint){
        return DonutBalance[address(this)];
    }
    // 2. allow owner to restock
    function reStock(uint amount) public {
        require(msg.sender == owner, "Only onwer can restock");
        DonutBalance[address(this)] += amount;
    }
    // 3. allow different addresses to purchase 
    function purchaseDonut(uint amount) public payable {
        //require price per donut 
        require(msg.value >=  amount * 1 ether, "You must pay 1 ether per donut");
        require(DonutBalance[address(this)] >= amount, "not enough donut in stock");

        DonutBalance[address(this)] -= amount; // reduce total balance 
        DonutBalance[msg.sender] += amount;// add address balance
    }
}