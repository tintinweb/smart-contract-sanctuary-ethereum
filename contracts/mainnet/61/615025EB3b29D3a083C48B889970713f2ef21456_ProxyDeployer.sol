pragma solidity 0.8.8;

interface IOwnable {
    function transferOwnership(address owner) external;
}

contract ProxyDeployer {
    event Deployed(address indexed deployer, address contractAddress, bytes32 salt);

    function deploy(bytes32 salt, bytes memory bytecode) public returns (address addr) {
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
        emit Deployed(msg.sender, addr, salt);
    }

    function deployOwnable(bytes32 salt, bytes memory bytecode) public returns (address addr) {
        addr = deploy(salt, bytecode);
        IOwnable(addr).transferOwnership(msg.sender);
    }
}