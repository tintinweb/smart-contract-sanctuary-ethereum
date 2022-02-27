pragma solidity ^0.8.4;

contract Caller {
    event Response(bool success, bytes data);
    
    function someAction(address addr, uint256 num) external view returns(uint) {
        Callee c = Callee(addr);
        return c.getValue(num);
    }
    
    function storeAction(address addr, uint256 num) external returns(uint) {
        Callee c = Callee(addr);
        c.storeValue(num);
        return c.getValues();
    }
    
    function someUnsafeAction(address addr, uint256 num) public {
        (bool success, bytes memory data) = addr.call(
          abi.encodeWithSignature("storeValue(uint256)", num)
        );

        emit Response(success, data);
    }
}

interface Callee {
    function getValue(uint initialValue) external view returns(uint);
    function storeValue(uint value) external;
    function getValues() external view returns(uint);
}