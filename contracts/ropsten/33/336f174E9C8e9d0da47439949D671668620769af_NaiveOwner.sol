pragma solidity >=0.4.21 <0.6.0;
import "../market/interface/OwnerProxyInterface.sol";

contract NaiveOwner is OwnerProxyInterface{
  mapping (bytes32 => address) public data;

  function ownerOf(bytes32 hash) public view returns(address){
    return data[hash];
  }
  function initOwnerOf(bytes32 hash, address owner) external returns(bool){
    if(data[hash] != address(0x0)) {
      return false;
    }
    data[hash] = owner;
    return true;
  }
}

contract NaiveOwnerFactory{
  event NewNaiveOwner(address addr);
  function createNaiveOwner() public returns(address){
    NaiveOwner no = new NaiveOwner();
    emit NewNaiveOwner(address(no));
    return address(no);
  }
}

pragma solidity >=0.4.21 <0.6.0;
contract OwnerProxyInterface{
  function ownerOf(bytes32 hash) public view returns(address);
  function initOwnerOf(bytes32 hash, address owner) external returns(bool);
}