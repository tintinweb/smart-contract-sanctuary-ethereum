pragma solidity >=0.4.22 <0.9.0;
import "./LibraryForTest2.sol";
contract test {
    event Transfer(uint value);
    function get () public returns(uint) {
        emit Transfer(LibraryForTest2.get3());
        return LibraryForTest2.get3();    
    }
}

pragma solidity >=0.4.22 <0.6.0;
library LibraryForTest2 {
    function get3() public pure returns(uint) {
        return 5;
    }
}