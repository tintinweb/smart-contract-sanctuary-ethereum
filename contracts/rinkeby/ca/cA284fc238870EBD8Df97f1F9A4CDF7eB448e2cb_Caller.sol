pragma solidity ^0.8.4;

contract Caller {
    event Response(bool success, bytes data);
    
    function someAction(address addr) external view returns(uint) {
        Callee c = Callee(addr);
        return c.getValue(100);
    }
    
    function storeAction(address addr) external returns(uint) {
        Callee c = Callee(addr);
        c.storeValue(100);
        return c.getValues();
    }
    
    function someUnsafeAction(address addr) public {
        (bool success, bytes memory data) = addr.call(
          abi.encodeWithSignature("storeValue(uint256)", 100)
        );

        emit Response(success, data);
    }
}

interface Callee {
    function getValue(uint initialValue) external view returns(uint);
    function storeValue(uint value) external;
    function getValues() external view returns(uint);
}