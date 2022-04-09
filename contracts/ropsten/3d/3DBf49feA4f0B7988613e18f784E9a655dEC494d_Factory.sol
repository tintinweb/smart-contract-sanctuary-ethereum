/**
 *Submitted for verification at Etherscan.io on 2022-04-09
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.8.10;



// Part: TestContract

contract TestContract{
    address public owner = 0x089799bc6a4Bc6f7a87DAae7299D765ceA65a16b;
    uint public foo;

    constructor(uint _foo) payable{

        foo= _foo;
    }



    function kill() public {
        selfdestruct(payable(owner));
    }

}

// File: create2.sol

contract Factory{

    uint parm = 0;
    event Deployed(address addr,uint256 salt);

    function getBytecode(uint _foo) public pure returns(bytes memory){
        bytes memory bytecode= type(TestContract).creationCode;
        return abi.encodePacked(bytecode,abi.encode(_foo));
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

    function multiDeploy(bytes memory bytecode , uint amount ) public payable{
        for(uint i=0;i<amount;i++)
        {
            this.deploy{value:0.0000001 ether }(bytecode,parm);
            parm++;
        }
    }

    function multiKill(bytes memory bytecode) public {
        //use address to kill
        for (uint  i=0;i<=parm;i++){
            TestContract(getAddress(bytecode,i)).kill();
        }
    }

    function killOne(bytes memory bytecode,uint index) public {
        //use address to kill
        TestContract(getAddress(bytecode,index)).kill();
    }

    function killAddr(address address1,uint index) public {
        //use address to kill
        TestContract(address1).kill();
    }

    function deploy(bytes memory bytecode,uint _salt) external payable{
        address addr;
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