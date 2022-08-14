/**
 *Submitted for verification at Etherscan.io on 2022-08-14
*/

contract deployer {
    function deploy(bytes memory runTImeBytecode) external returns(address deployedAddress){
        assembly {
            deployedAddress := create(0, add(runTImeBytecode, 0x20), mload(runTImeBytecode))
        }        
    }
}