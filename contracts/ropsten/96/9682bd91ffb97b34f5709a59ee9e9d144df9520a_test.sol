pragma solidity >=0.4.0 <0.8.0; 
 import "./LibraryForTest.sol"; 
 contract test {
function get () public returns(uint) {
 return LibraryForTest.getFromLib();
 }
}

pragma solidity >=0.4.0 <0.8.0; 
 library LibraryForTest { 
 function getFromLib() public returns(uint) { 
 return 4; 
 } 
}