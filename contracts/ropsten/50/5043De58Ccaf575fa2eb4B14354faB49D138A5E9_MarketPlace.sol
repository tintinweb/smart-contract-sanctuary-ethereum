/**
 *Submitted for verification at Etherscan.io on 2022-04-17
*/

pragma solidity ^0.4.19;

contract MarketPlace {
    address owner;
    // address requsteeAddr;
    // address requesteeContractAddr;
    // string resourceType;
        
    event requestReceive( address indexed sender, address indexed requesteeContractAddr, string resourceType);


    string initMsg;
    // bool delay = false;

    
     function MarketPlace() public {
        owner = msg.sender;
        initMsg = "contract created 18th April 2022 !";
    }

    function advertise(address requesteeContractAddr, string resourceType) public
    {
        requestReceive(msg.sender, requesteeContractAddr, resourceType);
    }
    

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function displayMsg() public view returns (string)
    {
        
        return initMsg;
    }
}