pragma solidity >=0.4.21 <0.6.0;

contract MMR {
    uint constant NHASHES = 64;
    uint public initialBlock;
    
    uint public nblock;
    bytes32 public nhash;
    
    uint public nhashes;
    bytes32[NHASHES] public hashes;
    
    event MerkleMountainRange(uint noblock, bytes32 blockhash, bytes32 mmr);
    
    constructor() public {
        nblock = block.number;
        initialBlock = block.number;
    }
    
    function calculate() public {
        uint current = block.number;
        
        while (current > nblock)
            calculateBlock();
    }
    
    function calculateBlock() private {
        bytes32 bhash = blockhash(nblock);
        bytes32 hash = bhash;
        
        for (uint k = 0; k < NHASHES; k++) {
            if (uint(hashes[k]) == 0) {
                hashes[k] = hash;
                
                if (k + 1 > nhashes)
                    nhashes = k + 1;
                    
                break;
            }
            
            hash = keccak256(abi.encodePacked(hashes[k], hash));
            hashes[k] = 0;
        }
        
        nblock++;
        
        bytes32 newhash;
        
        for (uint k = 0; k < nhashes; k++) {
            if (uint(hashes[k]) == 0)
                continue;
            
            if (newhash == bytes32(0))
                newhash = hashes[k];
            else
                newhash = keccak256(abi.encodePacked(hashes[k], newhash));
        }
        
        nhash = newhash;
        
        emit MerkleMountainRange(nblock, bhash, nhash);
    }
}