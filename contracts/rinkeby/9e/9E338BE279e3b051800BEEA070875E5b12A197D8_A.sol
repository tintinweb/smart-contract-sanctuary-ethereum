pragma solidity ^0.4.0; 
contract A {
    address public temp1;
    uint256 public temp2;
    uint256 public temp3;
    constructor(address addr) public {
            temp1 = addr;
    }
    function call1(address addr,address _addr2) public {
            addr.call(bytes4(keccak256("call1(address)")),_addr2);                 // 情况1
            //addr.delegatecall(bytes4(keccak256("test()")));       // 情况2
            //addr.callcode(bytes4(keccak256("test()")));           // 情况3   
    }
    function dele_call(address addr,address _addr2) public {
            //addr.call(bytes4(keccak256("test()")));                 // 情况1
            addr.delegatecall(bytes4(keccak256("dele_call(address)")),_addr2);       // 情况2
            //addr.callcode(bytes4(keccak256("test()")));           // 情况3   
    }
    function call_code(address addr,address _addr2) public {
            //addr.call(bytes4(keccak256("test()")));                 // 情况1
            //addr.delegatecall(bytes4(keccak256("test()")));       // 情况2
            addr.callcode(bytes4(keccak256("call_code(address)")),_addr2);           // 情况3   
    }
} 

contract B {
    address public temp1x;
    uint256 public temp2x;    
    address public owner;
    uint256 public temp4;    

    function call1(address addr) public {
            addr.call(bytes4(keccak256("test()")));                 // 情况1
            //addr.delegatecall(bytes4(keccak256("test()")));       // 情况2
            //addr.callcode(bytes4(keccak256("test()")));           // 情况3   
    }
    function dele_call(address addr) public {
            //addr.call(bytes4(keccak256("test()")));                 // 情况1
            addr.delegatecall(bytes4(keccak256("test()")));       // 情况2
            //addr.callcode(bytes4(keccak256("test()")));           // 情况3   
    }
    function call_code(address addr) public {
            //addr.call(bytes4(keccak256("test()")));                 // 情况1
            //addr.delegatecall(bytes4(keccak256("test()")));       // 情况2
            addr.callcode(bytes4(keccak256("test()")));           // 情况3   
    }
}

contract C {
    address public temp1xx;
    uint256 public temp2xx;    
    address public ownerx;
    uint256 public temp4x;    
    function test() public  {
            temp1xx = msg.sender;     
            ownerx = msg.sender;  
             temp2xx = 100; 
             temp4x =555;   
    }
}