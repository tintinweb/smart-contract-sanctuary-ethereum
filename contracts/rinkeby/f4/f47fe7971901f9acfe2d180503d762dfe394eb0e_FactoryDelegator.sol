/**
 *Submitted for verification at Etherscan.io on 2022-02-05
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10 <0.9.0;




contract FactoryDelegator {
    event Deployed(address addr, uint256 salt);

    address ticketAddr = 0x6a304dFdb9f808741244b6bfEe65ca7B3b3A6076;

    function getBytecode(address _owner) public view returns (bytes memory){ //CH?AGER PUBLIC
        bytes memory bytecode = type(Delegator).creationCode;
        return abi.encodePacked(bytecode, abi.encode(_owner, ticketAddr));
    }

    function getAddress(bytes memory bytecode, uint _salt) public view returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                _salt,
                keccak256(bytecode)
            )
        );
        return address(uint160(uint256(hash)));
    }

    function deploy(address _delegate, uint _salt) public {
        bytes memory bytecode = getBytecode(msg.sender);
        address contractAddress = getAddress(bytecode, _salt);
        _deploy(bytecode, _salt);

    }

    function _deploy(bytes memory bytecode, uint _salt) private {
        address addr;

        assembly {
            addr := create2(
                callvalue(),
                add(bytecode,0x20),
                mload(bytecode),
                _salt
            )
            if iszero(extcodesize(addr)) {
                revert(0,0)
            }
        }
        emit Deployed(addr, _salt);
    }


}



contract Delegator {
    address public owner;
    address public ticket;
    

    constructor(address _owner, address _ticketAddr) {
        owner = _owner;
        ticket = _ticketAddr;
    }

    function getOwner() public view returns (address){
        return owner;
    }


}