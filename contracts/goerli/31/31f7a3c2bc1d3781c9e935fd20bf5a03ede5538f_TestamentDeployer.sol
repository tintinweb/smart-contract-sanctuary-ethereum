/**
 *Submitted for verification at Etherscan.io on 2022-12-05
*/

pragma solidity ^0.8.7; // Designate version of solidity

contract Testament {

    address owner;
    uint fortune;
    bool isDeceased;

    constructor() public payable {
        owner = msg.sender;
        fortune = msg.value;
        isDeceased = false;
    }

    modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }

    modifier mustBeDeceased() {
        require(isDeceased == true);
        _;
    }

    address payable[] familyWallets;

    mapping (address => uint) inheritance;

    function setInheritance(address payable wallet, uint inheritAmount) public onlyOwner {
        familyWallets.push(wallet);
        inheritance[wallet] = inheritAmount;
    }

    function payout() private mustBeDeceased {
        for (uint i=0; i<familyWallets.length; i++) {
            familyWallets[i].transfer(inheritance[familyWallets[i]]);
        }
    }

    function deceased() public onlyOwner {
        isDeceased = true;
        payout();
    }
}

contract TestamentDeployer {

    address[] public deployedContracts;
    uint public contractsCount;


    function createContract() public payable returns(Testament) {
        Testament newContract = new Testament{value: msg.value}();
        deployedContracts.push(address(newContract));
        contractsCount++;
        return newContract;
    }

    function getDeployedContract(uint index) public view returns(address ){
        return deployedContracts[index];
    }
}