// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Child {
    uint256 public value;
    // address public owner;

    // constructor(address _owner, uint256  _value) payable {
    //     value = _value;
    //     owner = _owner;
        
    // }
    function inc()public returns(uint256){
        value = value+1; 
        return value;
    }

    function dec()public returns(uint256){
        value = value-1; 
        return value;
    }
}

contract FactoryV2 {
    Child[] public array;

    function create() public {
        Child c = new Child();
        array.push(c);
    }



    function getChild(uint _index)
        public
        view
        returns (
            uint256 value
        )
    {
        Child c = array[_index];

        return (c.value());
    }
}