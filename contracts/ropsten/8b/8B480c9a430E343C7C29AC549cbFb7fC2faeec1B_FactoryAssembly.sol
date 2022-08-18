//SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

import "./Logic.sol";

contract FactoryAssembly{
    address payable public deploymentAddress;
    event Deploy(address addr);
    event Deployed(address addr, uint salt);

    function getByteCode(address _owner) public pure returns(bytes memory){
        bytes memory bytecode = type(Logic).creationCode;
        return abi.encodePacked(bytecode,abi.encode(_owner));
    }

    function getAddress(bytes memory bytecode, uint _salt) public{
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff),address(this),_salt,keccak256(bytecode)));
        deploymentAddress =  payable(address(uint160(uint(hash))));
    }

    function preSendEth() public payable{
        (bool success,) = deploymentAddress.call{value:msg.value}("");
        require(success,"Failed to send Ether.");
    }

    // function deployContract(bytes memory bytecode, uint _salt) public payable{
    //     address addr;
    //     assembly {
    //         addr := create2(
    //             callvalue(),
    //             add(bytecode,0x20),
    //             mload(bytecode),
    //             _salt
    //         )
    //         if iszero(extcodesize(addr)){
    //             revert(0,0)
    //         }
    //     }
    //     emit Deployed(addr,_salt);
    // }

    function deploy(uint _salt) external {
        Logic _contract = new Logic{ salt : bytes32(_salt) }(msg.sender);
        emit Deploy(address(_contract));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Logic{
    address payable public owner;

    constructor(address _owner){
        owner = payable(_owner);
    }

    function getEth() public{
        require(payable(msg.sender)==owner);
        owner.transfer(address(this).balance);
    }

}