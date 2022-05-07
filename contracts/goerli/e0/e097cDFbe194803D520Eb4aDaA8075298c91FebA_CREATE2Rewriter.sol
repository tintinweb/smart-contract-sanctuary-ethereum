// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;
/**
 *Submitted for verification at Etherscan.io on 2019-02-15
*/

// Jochem Brouwer <[email protected]>
// Proof of concept: deploy a contract at the same address but with different bytecode 
// Target address: 0x7973d5166b9526b9e4e63595293d6b895d2d4fe3
// Note: it is possible to replay this but if someone calls deployContract and deploys a contract without 
// the possibility to selfdestruct then deployTEST1 and deployTEST2 will not work anymore (as in, they will not deploy their target code);
// of course it is still possible to replay it using a different seed than 0x1337 

contract CREATE2DumpExternalBytecode {
    
    constructor() {
        // read external bytecode 
        
        CREATE2Rewriter sender = CREATE2Rewriter(msg.sender);
        
        bytes memory deployMe = sender.deployBytecode();
        
        uint bytecodeLength = deployMe.length;
    
        assembly {
            // this RETURN opcode reads two memory pointers from stack: the memory start position and the length 
            // this normally puts the bytecode in the RETURNVALUE field of a CALL but instead on here this is the 
            // actual code which gets deployed =)
            return (add(deployMe, 0x20), bytecodeLength)
        }
    }
}

contract HelloWorld1 {
    string public Hello = "Hello world!";
    
    function destroy() external { 
        selfdestruct(payable(msg.sender));
    }
}

contract HelloWorld2 {
    string public Hello = "HACKED";

    function destroy() external {
        selfdestruct(payable(msg.sender));
    }
}

contract CREATE2Rewriter {
    // CREATE2DumpExternalBytecode constructor code 
    bytes constant constructorCode = hex'6080604052348015600f57600080fd5b506000339050606081600160a060020a03166331d191666040518163ffffffff167c010000000000000000000000000000000000000000000000000000000002815260040160006040518083038186803b158015606b57600080fd5b505afa158015607e573d6000803e3d6000fd5b505050506040513d6000823e601f3d908101601f19168201604052602081101560a657600080fd5b81019080805164010000000081111560bd57600080fd5b8201602081018481111560cf57600080fd5b815164010000000081118282018710171560e857600080fd5b5050805190945092508291505060208301f3fe';
    bytes public deployBytecode;
    
    // HelloWorld1 / 2 bytecode which we want to deploy
    bytes constant HelloWorld1_bytecode = hex'608060405260043610610045577c0100000000000000000000000000000000000000000000000000000000600035046383197ef0811461004a578063bcdfe0d514610061575b600080fd5b34801561005657600080fd5b5061005f6100eb565b005b34801561006d57600080fd5b506100766100ee565b6040805160208082528351818301528351919283929083019185019080838360005b838110156100b0578181015183820152602001610098565b50505050905090810190601f1680156100dd5780820380516001836020036101000a031916815260200191505b509250505060405180910390f35b33ff5b6000805460408051602060026001851615610100026000190190941693909304601f810184900484028201840190925281815292918301828280156101745780601f1061014957610100808354040283529160200191610174565b820191906000526020600020905b81548152906001019060200180831161015757829003601f168201915b50505050508156fea165627a7a72305820d655aa9f37fe27daa8e218b7712a2e641f2c18b5c8a9911e69cfc1c8336640390029';
    bytes constant HelloWorld2_bytecode = hex'608060405260043610610045577c0100000000000000000000000000000000000000000000000000000000600035046383197ef0811461004a578063bcdfe0d514610061575b600080fd5b34801561005657600080fd5b5061005f6100eb565b005b34801561006d57600080fd5b506100766100ee565b6040805160208082528351818301528351919283929083019185019080838360005b838110156100b0578181015183820152602001610098565b50505050905090810190601f1680156100dd5780820380516001836020036101000a031916815260200191505b509250505060405180910390f35b33ff5b6000805460408051602060026001851615610100026000190190941693909304601f810184900484028201840190925281815292918301828280156101745780601f1061014957610100808354040283529160200191610174565b820191906000526020600020905b81548152906001019060200180831161015757829003601f168201915b50505050508156fea165627a7a72305820f54e3277e157b3ba1564c90516d898a6ac23e90c395e701e5f17b0d93069b8f90029';
    
    
    // check address 0x7973d5166b9526b9e4e63595293d6b895d2d4fe3 on etherscan 
    // also check extcodeHashes on 0x7973d5166b9526b9e4e63595293d6b895d2d4fe3 index 0 and 1 - they are different 
    // (and they are not empty account hashes =) )
    mapping(address => bytes32[]) public extcodeHashes;
    
    function deployContract(bytes memory deployThis, bytes32 seed) public payable returns (address) {

        address ret; 
        deployBytecode = deployThis;
        
        bytes memory constructorCode_mem = constructorCode;
        
        assembly {
            ret := create2(callvalue(), add(0x20, constructorCode_mem), mload(constructorCode_mem), seed)
        }
        bytes32 hash;
        assembly {
               hash := extcodehash(ret)
        }
        
        extcodeHashes[ret].push(hash);
        
        return ret;
    }
    
    function deployTEST1() external returns (address) {
        return deployContract(HelloWorld1_bytecode, bytes32(bytes2(0x1337)));
    }
    
    function deployTEST2() external returns (address) {
        return deployContract(HelloWorld2_bytecode, bytes32(bytes2(0x1337)));
    }
}