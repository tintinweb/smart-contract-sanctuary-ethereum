/**
 *Submitted for verification at Etherscan.io on 2022-05-07
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;


contract DeploymentFactory{
    event Deployed(address indexed preComputedAddress);

    function memcpy(uint dest, uint src, uint len) internal pure {
        // Copy word-length chunks while possible
        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        unchecked {
            uint mask = (256 ** (32 - len)) - 1;
            assembly {
                let srcpart := and(mload(src), not(mask))
                let destpart := and(mload(dest), mask)
                mstore(dest, or(destpart, srcpart))
            }
        }
    }

    function substring(bytes memory self, uint offset, uint len) internal pure returns(bytes memory) {
        require(offset + len <= self.length,"substring!");

        bytes memory ret = new bytes(len);
        uint dest;
        uint src;

        assembly {
            dest := add(ret, 32)
            src := add(add(self, 32), offset)
        }
        memcpy(dest, src, len);

        return ret;
    }
    
    function shortenByteCode(bytes memory _byteCode) internal pure returns (bytes memory) {
      uint len = _byteCode.length-2;
      uint newLen = len-(len % 64);
      require((newLen % 64)==0,"shortenByteCode failed");
      
      bytes memory returnVal = substring(_byteCode, 0, newLen);
      return returnVal;
    }


    // we need bytecode of the contract to be deployed along with the constructor parameters
    function getBytecode() public pure returns (bytes memory){
        return type(TestContract).creationCode;
    }

    //compute the deployment address
    function computeAddress(bytes memory _byteCode, uint256 _salt)public view returns (address ){
        bytes32 hash_ = keccak256(abi.encodePacked(bytes1(0xff),address(this),_salt,keccak256(shortenByteCode(_byteCode))));
        return address(uint160(uint256(hash_)));
    }

    //deploy the contract and check the event for the deployed address
    function deploy(bytes memory _byteCode, uint256 _salt)public payable{
        address depAddr;
        bytes memory shortByteCode = shortenByteCode(_byteCode);

        assembly{
            depAddr:= create2(callvalue(),add(shortByteCode,0x20), mload(shortByteCode), _salt)
        
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