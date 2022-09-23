/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

//SPDX-License-Identifier: MIT
pragma solidity >0.8.0;


contract PreComputeAddress{
    event Deployed(address indexed preComputedAddress);
    
  bytes bytecode;   
  constructor(){
      bytecode = type(TestContract).creationCode;
}

    // we need bytecode of the contract to be deployed along with the constructor parameters
    function getBytecode() public pure returns (bytes memory){
        return type(TestContract).creationCode;
    }

    //compute the deployment address
    function computeAddress(bytes32 _salt)public view returns (address ){
        bytes32 hash_ = keccak256(abi.encodePacked(bytes1(0xff),address(this),_salt,keccak256(bytecode)));
        return address(uint160(uint256(hash_)));
    }

    //deploy the contract and check the event for the deployed address
    function deploy(bytes memory _byteCode, bytes32 _salt)public payable{
        address depAddr;

        assembly{
            depAddr:= create2(callvalue(),add(_byteCode,0x20), mload(_byteCode), _salt)
        
        if iszero(extcodesize(depAddr)){
            revert(0,0)
        }

        }
        emit Deployed(depAddr);
    }

}
contract TestContract{
    uint256 storedNumber;

    function increment() public {
        storedNumber++;
    }
}