//SPDX.License.Identifier:MIT

pragma solidity ^0.8.0;

import "./Logic.sol";

contract DelegateCall{
    Logic public logic;
    address public owner;
    uint public num;

    constructor(address _logicAddress) payable{
        logic = Logic(_logicAddress);
        owner = msg.sender;
    }

    function withdraw() public{
        require(msg.sender == owner,"Caller is not the owner");
        payable(owner).transfer(address(this).balance);
    }

    function checkBalance() view public returns(uint){
        return address(this).balance;
    } 

    receive() external payable{}

    fallback() external payable{
        address(logic).delegatecall(msg.data);
    }
}

//SPDX.License.Identifier:MIT

pragma solidity ^0.8.0;

contract Logic{
    uint public num;

    function changeNum(uint _num) public{
        num = _num;
    }

    function addNum(uint _num) public{
        num += _num;
    }

    function mulNum(uint _num) public{
        num *= _num;
    }
}