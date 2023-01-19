/**
 *Submitted for verification at Etherscan.io on 2023-01-19
*/

pragma solidity ^0.6.0;

//input text, number and address
//output is a unique 32 byte hash
contract hashtest {
    // 0x2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824

    mapping (bytes32 => bytes32) public verifiedHash;
    bytes32[] public reviewsArray;

   event setHash(bytes32 kHash, bytes32 vHash,string  detail);


    function set(bytes32 kHash, bytes32 vHash,string memory detail) public  {
        verifiedHash[kHash] = vHash;
        reviewsArray.push(vHash);
        emit setHash(kHash, vHash, detail);

    }

    function getAll() external view returns (bytes32[] memory){
        return reviewsArray;
    }

     function hash(string memory _text, uint _num, address _addr) public {
         keccak256(abi.encode(_text, _num, _addr));
    }
    
}