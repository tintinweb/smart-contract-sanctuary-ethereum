/**
 *Submitted for verification at Etherscan.io on 2022-07-10
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

interface ERC20 {
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    // don't need to define other functions, only using `transfer()` in this case
}

contract BankContract { 
    struct client_account{
        int client_id;
        address client_address;
        uint client_balance_in_ether;
    }    
    client_account[] clients;

    int clientCounter;

    address payable manager;
    mapping(address => uint) public interestDate;

    constructor() {
        clientCounter = 0;
    }


    modifier onlyManager() {
        require(msg.sender == manager, "Only manager can call!");
        _;
    }
    modifier onlyClients() {
        bool isClient = false;
        for(uint i=0;i<clients.length;i++){
            if(clients[i].client_address == msg.sender){
                isClient = true;
                break;
            }
        }
        require(isClient, "Only clients can call!");
        _;
    }


    receive() external payable { }



    function setManager(address managerAddress) public returns(string memory){
     manager = payable(managerAddress);
     return "";
    }

    function joinAsClient() public payable returns(string memory){
     interestDate[msg.sender] = block.timestamp;
     clients.push(client_account(clientCounter++, msg.sender, address(msg.sender).balance));
     return "";
    }


    function deposit() public payable onlyClients{
     payable(address(this)).transfer(msg.value);
    }

    function withdraw(uint amount) public payable onlyClients{
        address sender_temp;
        sender_temp = msg.sender;
     payable(sender_temp).transfer(amount * 1 wei);
    }

    function sendInterest() public payable onlyManager{
     for(uint i=0;i<clients.length;i++){
          address initialAddress = clients[i].client_address;
          uint lastInterestDate = interestDate[initialAddress];
          if(block.timestamp < lastInterestDate + 10 seconds){
               revert("It's just been less than 10 seconds!");
          }
          payable(initialAddress).transfer(1 ether);
          interestDate[initialAddress] = block.timestamp;
     }
    }


  

    function getCountClient() public view returns(uint){
        uint count = clients.length;
     return count;
    }

    function getClients() public view returns (address[] memory,uint[] memory) {


      address[] memory client_address = new address[](clients.length);
      uint[]    memory client_balance_in_ether = new uint[](clients.length);

        for (uint i = 0; i < clients.length; i++) {
            //Person storage person = people[indexes[i]];
            client_address[i] = clients[i].client_address;
            client_balance_in_ether[i] = clients[i].client_balance_in_ether;
        }
        
        return (client_address, client_balance_in_ether);

   }

   function getContractBalance() public view returns(uint){
        return address(this).balance;
    }

   function sendCoke(address _from, address _to, uint _value) external {
         // This is the mainnet USDT contract address
         // Using on other networks (rinkeby, local, ...) would fail
         //  - there's no contract on this address on other networks
        ERC20 coke = ERC20(address(0xd9145CCE52D386f254917e481eB44e9943F39138));
        
        // transfers USDT that belong to your contract to the specified address
        coke.transferFrom(_from,_to,_value);
    }
}