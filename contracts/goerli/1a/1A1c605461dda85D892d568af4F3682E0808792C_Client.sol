// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "./IHelloworld.sol";


contract Client{

IHelloworld public helloworld;


    constructor(IHelloworld _helloworld) {
      helloworld = _helloworld;
    }
    function initialize(IHelloworld _helloworld) external {
        helloworld = _helloworld;
    }
    function GetSetIntegerValue() public returns (uint) {
        helloworld.setValue(100);
        return helloworld.getValue();
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IHelloworld {
    function getValue() external view returns(uint);
    function setValue(uint _value) external; 
}