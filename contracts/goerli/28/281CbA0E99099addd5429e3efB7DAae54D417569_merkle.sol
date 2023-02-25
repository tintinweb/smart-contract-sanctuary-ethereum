// license: MIT

pragma solidity ^0.6.2;



contract merkle  {
    // merkle tree
    bytes32[] public hashes;

    function generateMerkleTree(address[] memory addresses) public returns (bytes32[] memory) {


        // hash all addresses
        for (uint i = 0; i < addresses.length; i++) {
            hashes.push(keccak256(abi.encodePacked(addresses[i])));
        }
        // compute the merkle tree
        uint256 len_tmp;
        if(hashes.length % 2 != 0) {
            len_tmp = (hashes.length % 2) + 1;
        }
        else {
            len_tmp = hashes.length % 2;
        }
        bytes32[] memory tmp = new bytes32[](len_tmp);
        while(hashes.length > 1) {
            for (uint i = 0; i < hashes.length; i += 2) {
                if(i == hashes.length - 1) {
                    tmp[i] = keccak256(abi.encodePacked(hashes[i], hashes[i]));
                }
                else {
                    tmp[i] = keccak256(abi.encodePacked(hashes[i], hashes[i+1]));
                }
            }
            hashes = tmp;

            // reset tmp to empty
            tmp = new bytes32[](len_tmp);
        }

        return hashes;
    }
}