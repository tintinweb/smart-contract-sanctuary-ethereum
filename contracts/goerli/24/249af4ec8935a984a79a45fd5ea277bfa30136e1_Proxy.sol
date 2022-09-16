/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

contract Proxy{
 address delegate; // store the address of the delegate
 address owner = msg.sender; // store the address of the owner
/// @notice this function allows a new version of the delegate being used without the caller having to worry about it
 function upgradeDelegate(address _newDelegateAddress) public {
   require(msg.sender == owner);
   delegate = _newDelegateAddress;
 }

fallback () external payable {
  assembly {
  let _target := sload(0)
  calldatacopy(0x0, 0x0, calldatasize())
  let result := delegatecall(gas(), _target, 0x0, calldatasize(), 0x0, 0)
  returndatacopy(0x0, 0x0, returndatasize())
  switch result case 0 {revert(0,0)} default {return (0,   returndatasize())}
 }
 }
}