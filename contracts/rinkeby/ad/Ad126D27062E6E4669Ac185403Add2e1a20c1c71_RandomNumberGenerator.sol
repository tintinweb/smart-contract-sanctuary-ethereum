pragma solidity ^0.8.0;

contract RandomNumberGenerator {
   function calculateNumber (string memory clientSeed, bytes32 privateKey, uint minRange, uint maxRange) public pure returns (uint) {
      bytes32 hashToReturn = keccak256(abi.encodePacked(clientSeed, privateKey));
      uint number32 = getNumber32(hashToReturn);
      uint resultNumber = number32 % (maxRange - minRange + 1) + minRange;
      return resultNumber;
   }
   
   function calculateNumbersAndHashes(string memory clientSeed, bytes32 privateKey, uint minRange, uint maxRange, uint n) public pure returns (uint[] memory, bytes32[] memory, bytes32[] memory)
   {
       uint[] memory numbers= new uint[](n);
       bytes32[] memory serverSecrets = new bytes32[](n);
       bytes32[] memory numberGenerationHashes = new bytes32[](n);
        
        numberGenerationHashes[0] = keccak256(abi.encodePacked(clientSeed,privateKey)); 
        numbers[0]=calculateNumber(clientSeed, privateKey, minRange, maxRange);
        serverSecrets[0]=calculateServerSecret(numbers[0], numberGenerationHashes[0]);
        
        for (uint i=1;i<n;i++)
        {
            numberGenerationHashes[i] = keccak256(abi.encodePacked(clientSeed, serverSecrets[i-1])); 
            numbers[i]=calculateNumber(clientSeed, serverSecrets[i-1], minRange, maxRange);
            serverSecrets[i]=calculateServerSecret(numbers[i], numberGenerationHashes[i]);

        }
        return (numbers, numberGenerationHashes, serverSecrets);
   }
   
   function calculateServerSecret (uint resultNumber, bytes32 privateKey) public pure returns (bytes32) {
        bytes32 serverSecretHashBytes32 = keccak256(abi.encode(resultNumber, privateKey));
        return serverSecretHashBytes32;
   }
   
   function getNumber32 (bytes32 _bytes) public pure returns (uint) {
        bytes32 first32Bytes = bytes32(_bytes);
        bytes memory bytes32ToSend = abi.encodePacked(first32Bytes);
        uint number32 = bytesToUint(bytes32ToSend, 0);
        return number32;
    }
    
    function bytesToUint (bytes memory bs, uint start) public pure returns (uint) {
        require(bs.length >= start + 21, "slicing out of range");
        uint x;
        assembly {
            x := mload(add(bs, add(0x20, start)))
        }
        return x;
    }
}