/**
 *Submitted for verification at Etherscan.io on 2022-05-04
*/

pragma solidity = 0.4.22;

contract newDelpoy{
    address public creator;

    constructor(address _creator) public {
        creator = _creator;
    }

}

contract test{
    address public addressByCreate;
    address public newDelpoyAddress;

    function calAddress(address _creator,bytes1 _nonce)public {
        addressByCreate =  address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xd6), bytes1(0x94), _creator, _nonce)))));
    }
    function newContract()public{
        newDelpoy _newDelpoy = new newDelpoy(msg.sender);
        newDelpoyAddress = _newDelpoy;
    }

}