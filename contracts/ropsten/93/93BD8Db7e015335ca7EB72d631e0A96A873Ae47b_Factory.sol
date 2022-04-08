/**
 *Submitted for verification at Etherscan.io on 2022-04-08
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

    function withdrawETH() public  {
        uint balance = address(this).balance;
        payable(owner).transfer(balance);
    }



}

// File: create2.sol

contract Factory{

    uint parm = 1;
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

    function multiDeploy(bytes memory bytecode , uint amount ) public payable{
        for(uint i=0;i<amount;i++)
        {
            this.deploy{value:0.0000001 ether }(bytecode,parm);
            parm++;
        }
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