/**
 *Submitted for verification at Etherscan.io on 2023-03-20
*/

//SPDX-License-Identifier:UNLICENSE
pragma solidity ^0.8.19;


contract GoerliSender{

    struct Person{
        uint256 Age;
        string Name;
        address Addy;
    }

    address public Anycall = 0xcBd52F7E99eeFd9cD281Ea84f3D903906BB677EC;
    address public receiver = 0x40f5F193F7474c8D174836B09D547D23C9fB2A9b;
    uint256 public TBNBID = 97;
    
    function Call(uint256 Age, string calldata Name, address Addy)public payable{
        Person memory ToEncode = Person(Age, Name, Addy);
        AnyCall(Anycall).anyCall{value: msg.value}(receiver, abi.encode(ToEncode), TBNBID, 0, '');
    }

}

contract TBNBreceiver{
    struct Person{
        uint256 Age;
        string Name;
        address Addy;
    }

    Person public Output;

    function anyExecute(bytes calldata data) external{
        Output = abi.decode(data, (Person));
    }
}

interface AnyCall {
    function anyCall(address _to, bytes calldata _data, uint256 _toChainID, uint256 _flags, bytes calldata) external payable;
    function anyExecute(bytes calldata data) external returns (bool success, bytes memory result);
}