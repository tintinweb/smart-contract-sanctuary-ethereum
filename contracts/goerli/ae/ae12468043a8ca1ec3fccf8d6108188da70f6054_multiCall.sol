/**
 *Submitted for verification at Etherscan.io on 2022-03-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface airdrop {
    function transfer(address recipient, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function claim() external;
}

contract multiCall{
    uint256 nonce = 1;
    function addressto(address _origin, uint256 _nonce) internal pure returns (address _address) {
        bytes memory data;
        if(_nonce == 0x00)          data = abi.encodePacked(bytes1(0xd6), bytes1(0x94), _origin, bytes1(0x80));
        else if(_nonce <= 0x7f)     data = abi.encodePacked(bytes1(0xd6), bytes1(0x94), _origin, uint8(_nonce));
        else if(_nonce <= 0xff)     data = abi.encodePacked(bytes1(0xd7), bytes1(0x94), _origin, bytes1(0x81), uint8(_nonce));
        else if(_nonce <= 0xffff)   data = abi.encodePacked(bytes1(0xd8), bytes1(0x94), _origin, bytes1(0x82), uint16(_nonce));
        else if(_nonce <= 0xffffff) data = abi.encodePacked(bytes1(0xd9), bytes1(0x94), _origin, bytes1(0x83), uint24(_nonce));
        else                        data = abi.encodePacked(bytes1(0xda), bytes1(0x94), _origin, bytes1(0x84), uint32(_nonce));
        bytes32 hash = keccak256(data);
        assembly {
            mstore(0, hash)
            _address := mload(0)
        }
    }
    function mycall(uint256 times) public {
        for(uint i=0;i<times;++i){
            address to = addressto(address(this), nonce);
            new claimer(to, address(msg.sender));
            nonce+=1;
        }
    }
}
contract claimer{
    constructor(address selfAdd, address receiver){
        address contra = address(0xbb2A2D70d6a4B80FA2C4d4Ca43a8525da430196c);
        airdrop(contra).claim();
        uint256 balance = airdrop(contra).balanceOf(selfAdd);
        require(balance>0,'Oh no');
        airdrop(contra).transfer(receiver, balance);
    }
}