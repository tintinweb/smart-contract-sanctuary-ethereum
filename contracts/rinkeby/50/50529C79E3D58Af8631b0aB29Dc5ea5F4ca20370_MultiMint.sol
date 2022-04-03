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
    address public contr;
    uint amount = 10000000000000000;

    receive() external payable{
        pay();
    }

    fallback() external{
        pay();
    }

    function create() public {
        SmithyMinter test = new SmithyMinter(contr);
        address payable _to = payable(test);
        _to.transfer(amount);
        contracts.push(test);
    }

    function pay() public payable{}

    constructor (address _contr) payable {
        owner = msg.sender;
        contr = _contr;

    }

    function iteraction(uint _txCount) public {
        for (uint i = 0; i < _txCount; i++){
            SmithyMinter test = new SmithyMinter(contr);
            address payable _to = payable(test);
            _to.transfer(amount);
            test.mint();
            contracts.push(test);
        }
    }

    function withdrawAll() public {
        address payable _to = payable(owner);
        _to.transfer(address(this).balance);
    }

    function mintOne() public {
        SmithyMinter test = new SmithyMinter(contr);
        address payable _to = payable(test);
        _to.transfer(amount);
        test.mint();
        contracts.push(test);
    }

    function getBalance() public view returns(uint balance){
        balance = address(this).balance;
    }
}