// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



interface SmithyContract {
    function publicMint() external;
}

contract SmithyMinter {
    address public contr;
    SmithyContract public smithy;
    address owner = 0x4356DE64FF8ab294986837F1955e27eE43e57ccc;

    receive() external payable{
        pay();
    }
    
    constructor (address _contr) payable{
        contr = _contr;
        smithy = SmithyContract(address(contr));

    }

    fallback() external{
        pay();
    }

    function withdrawAll() public {
        address payable _to = payable(owner);
        _to.transfer(address(this).balance);
    }

    function pay() public payable{}

    function mint() public{
        smithy.publicMint();
        withdrawAll();
    }

    function getBalance() public view returns(uint balance){
        balance = address(this).balance;
    }
}



contract MultiMint {
    address owner;
    SmithyMinter[] public contracts;
    uint price = 1000000000000000000;
    address public contr;

    receive() external payable{
        pay();
    }

    fallback() external{
        pay();
    }

    function pay() public payable{}

    constructor (address _contr) payable {
        owner = msg.sender;
        contr = _contr;

    }

    function iteraction(uint _txCount) public {
        for (uint i = 0; i < _txCount; i++){
            SmithyMinter test = new SmithyMinter(contr);
            test.mint();
            contracts.push(test);
        }
    }

    function mintOne() public {
        SmithyMinter test = new SmithyMinter(contr);
        test.mint();
        contracts.push(test);
    }

    function getBalance() public view returns(uint balance){
        balance = address(this).balance;
    }
}




// contract Demo {

//     address owner;
//     event Paid(address indexed _from, uint amount, uint timestamp);

//     receive() external payable{
//         pay();
//     }

//     constructor() {
//         owner = msg.sender;
//     }

//     modifier onlyOwner(address _to){
//         require(msg.sender == owner, "You`re not an owner!");
//         require(_to != address(0), "incorrect address!");
//         _;

//     }

//     function withdrawAll(address payable _to) public onlyOwner(_to){
//         _to.transfer(address(this).balance);
//     }

//     function getBalance() public view returns(uint balance){
//         balance = address(this).balance;
//     }

//     function pay() public payable{
//         emit Paid(msg.sender, msg.value, block.timestamp);
//     }

//     function twizzyDisperse(address[] memory _adresses) external payable{
//         for (uint i = 0; i < _adresses.length; i++){
//             address payable _to = payable(_adresses[i]);
//             _to.transfer(msg.value / _adresses.length);
//         }
//     }

// }

// contract MyShop{
//     address public owner;
//     mapping (address => uint) public payments;

//     constructor() {
//         owner = msg.sender;
//     }

//     function payForItem()public payable{
//         payments[msg.sender] = msg.value;
//     }
    
//     function withdrawAll() public {
//         address payable _to = payable(owner);
//         address _thisContract = address(this); 
//         _to.transfer(_thisContract.balance);
//     }
// }