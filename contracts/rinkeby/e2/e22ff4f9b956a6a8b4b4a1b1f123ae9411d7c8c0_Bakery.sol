/**
 *Submitted for verification at Etherscan.io on 2022-05-28
*/

pragma solidity ^0.5.16;

contract Bakery {

  // index of created contracts

  address[] public contracts;

  // useful to know the row count in contracts index

  function getContractCount() 
    public
    view
    returns(uint contractCount)
  {
    return contracts.length;
  }

  // deploy a new contract

  function newCookie(address _addr, address token0, address token1)
    public
    returns(address pair)
  {
    /*Cookie c = new Cookie();
    newContract = address(c);
    contracts.push(newContract);*/
    bytes memory bytecode = at(_addr);
    bytes32 salt = keccak256(abi.encodePacked(token0, token1));       
    assembly {
        pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
    }
  }

  function at(address _addr) public view returns (bytes memory o_code) {
    assembly {
        // retrieve the size of the code, this needs assembly
        let size := extcodesize(_addr)
        // allocate output byte array - this could also be done without assembly
        // by using o_code = new bytes(size)
        o_code := mload(0x40)
        // new "memory end" including padding
        mstore(0x40, add(o_code, and(add(add(size, 0x20), 0x1f), not(0x1f))))
        // store length in memory
        mstore(o_code, size)
        // actually retrieve the code, this needs assembly
        extcodecopy(_addr, add(o_code, 0x20), 0, size)
    }
  }
}


contract Cookie {

  // suppose the deployed contract has a purpose

  function getFlavor()
    public
    pure
    returns (string memory)
  {
    return  "mmm ... chocolate chip";
  }    
}