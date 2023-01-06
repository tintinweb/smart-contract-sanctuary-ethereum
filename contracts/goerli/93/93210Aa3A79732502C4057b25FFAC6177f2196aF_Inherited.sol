pragma solidity ^0.8.0;

contract Test {
    function hash(address addr, bytes32 salt) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(addr, salt));
    }
}


interface Base {
    function foo() external view returns (uint);
}

interface Base1 //is Base
{
    
}

contract Base2 is Base
{
    function foo() override virtual public view returns (uint) {
         return 2;
    }
}

contract Inherited is Base1, Base2
{
    // Derives from multiple bases defining foo(), so we must explicitly
    // override it
    //function foo() public override(Base1, Base2) {}
    function foo() override public view returns (uint) {
         return 2;
    }
}