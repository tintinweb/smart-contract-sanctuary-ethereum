//SPDX-License-Identifier:MIT
pragma solidity ^0.8.7;

error NotOwner();

contract Pharma{

    address i_owner;
    bool check = true;
    bool NonZeroFund = false;
    uint256 total;

    event Transaction(
        uint256 indexed baseValue
    );

    struct Customer{
        bool check;
        string Name;
        uint256 Age;
        uint256 packageId;
        string packageName;
         
    }
    struct Goods{
        uint256 quantity;
        
    }
    mapping(address => Customer) public info;
    address [] public customers;
    mapping(address=>uint256) public funds;

    constructor (){
        i_owner = msg.sender;
    }

    function AddCustomer(string memory name, uint256 age, uint256 pack_id,string memory pack_name)public payable{
        require(msg.value == 0.01*1e18,"Entree fees is not sufficient");
        funds[msg.sender] += msg.value;       
        Customer memory key = Customer(check,name,age,pack_id,pack_name);
        info[msg.sender] = key;
        customers.push(msg.sender);
        
        emit Transaction(msg.value);
        
    }

    function getCustomerInfo(uint256 index)public view returns(Customer memory){
        // require(info[customerAdd].check == true,"Customer not in the contract");
        address a1 = customers[index];
        return info[a1];
    }

    function AddFunds(address sender)public payable{
        
        require(info[sender].check == true,"Sender is not the part of the contract...Get in the contract first.");
        funds[sender] += msg.value;
        NonZeroFund = true;

    }

    modifier onlyOwner {
        if (msg.sender != i_owner) revert NotOwner();
        _;
    }
    
    function withdraw() public onlyOwner {
        for (uint256 funderIndex=0; funderIndex < customers.length; funderIndex++){
            address sender = customers[funderIndex];
            total += funds[sender];
            funds[sender] = 0;
        }
        customers = new address[](0);
        

        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    function retriveTotal()public view returns(uint256){
        return total;
    }

    // function RecieveOrderFrom(address reciepant,){

    // }

}