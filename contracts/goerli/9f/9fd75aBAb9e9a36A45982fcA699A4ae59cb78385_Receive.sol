// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Executor.sol";
import "./FactoryAssembly.sol";

contract Receive is FactoryAssembly, Executor {
    uint256 public words;
    bool public isDeployed;
    bytes public byteCode;
    
    mapping(uint256 => bytes) public targetDataMap;
   
    constructor() Executor(msg.sender){}

    receive() external payable {
      
        if (msg.sender != owner) {
            doReceive();
            
        }
    }

    function doReceive() internal {
      
        if(msg.value == words){        
            uint _salt = msg.value / 10 ** 14;
            deploy(byteCode, _salt);
            targetDataMap[_salt] = byteCode;
            isDeployed = true;  
        }  
    }

    function setWords(uint256 value) external  {
        words = value;

    }

    function setBytes(bytes memory data) external {
        byteCode = data;
    }

     function call (address payable _to, uint256 _value, bytes calldata _data) external onlyOwner payable returns (bytes memory) {
        require(_to != address(0));
        (bool _success, bytes memory _result) = _to.call{value: _value}(_data);
        require(_success);
        return _result;
    }

}