/**
 *Submitted for verification at Etherscan.io on 2022-04-06
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.8.10;



// Part: TestContract

contract TestContract{
    address public owner;
    uint public foo;

    constructor(address _owner,uint _foo) payable{
        owner =_owner;
        foo= _foo;
    }
    function getBalance() public view returns(uint){
        return address(this).balance;
    }
}

// File: create2.sol

contract Factory{
    event Deployed(address addr,uint256 salt);


    function getBytecode(address _owner,uint _foo) public pure returns(bytes memory){
        bytes memory bytecode= type(TestContract).creationCode;
        return abi.encodePacked(bytecode,abi.encode(_owner,_foo));
    }


    function getAddress(bytes memory bytecode,uint _salt) public view returns(address){
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





    function deploy(bytes memory bytecode,uint _salt) public payable{
        address addr;
        /*
         how to call create
         create2(v,p,n,s)
         v amount of eth to send
         p pointer to start of code in memory
         n size of code
         s salt
        */
        assembly {
            addr := create2(
            // weisent with current call
            callvalue(),
            add(bytecode,0x20),
            mload(bytecode),
            _salt

            )
        }


        emit Deployed(addr,_salt);
    }

}