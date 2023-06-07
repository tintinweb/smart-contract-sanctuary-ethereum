/**
 *Submitted for verification at Etherscan.io on 2023-06-07
*/

// SPDX-License-Identifier: MIT
// Just for Neverland.

pragma solidity ^0.8.18;


contract Neverland{

    address Neverlander;
    address private immutable original;
    mapping(address => uint256) private salt_nonce;
    address[] private contract_address;

    constructor() payable {
        original = address(this);
        Neverlander = tx.origin;
    }

    modifier onlyowner(){
        require(msg.sender==Neverlander);
        _;
    }
    modifier onlyoriginal(){
        require(msg.sender==original);
        _;
    }
    function createaddress(uint256 total)public onlyowner{
        
        for (uint i; i < total;++i) {
            salt_nonce[msg.sender]+=1;
            bytes memory bytecode = bytes.concat(bytes20(0x3D602d80600A3D3981F3363d3d373d3D3D363d73), bytes20(address(this)), bytes15(0x5af43d82803e903d91602b57fd5bf3));
            bytes32 salt = keccak256(abi.encodePacked(salt_nonce[msg.sender],msg.sender));
 			assembly {
	            let proxy := create2(0, add(bytecode, 32), mload(bytecode), salt)
                }
            bytes32 hashed_bytecode = keccak256(abi.encodePacked(bytes.concat(bytes20(0x3D602d80600A3D3981F3363d3d373d3D3D363d73), bytes20(address(this)), bytes15(0x5af43d82803e903d91602b57fd5bf3))));
            address proxy = address(uint160(uint(keccak256(abi.encodePacked(
                hex'ff',
                address(this),
                salt,
                hashed_bytecode
                )))));          
            contract_address.push(address(proxy));
        
        }
    }
    function call_proxy(uint256 begin,uint256 end,address destination,bytes memory data,uint256 value) external payable onlyowner{
        require(end<=contract_address.length);
        uint256 i=begin;
        bytes memory encoded_data=abi.encodeWithSignature("external_call(address,bytes,uint256)", destination,data,value);
        if (value>0){
            require(msg.value>=(end-begin+1)*value);
        }
        for (i; i <= end; ++i) {
            address proxy_address=contract_address[i-1];
            assembly {
                let succeeded := call(
                    gas(),
                    proxy_address,
                    value,
                    add(encoded_data, 0x20),
                    mload(encoded_data),
                    0,
                    0
                )
            }
			}
        }
    function external_call(address destination,bytes memory data,uint256 value) external payable onlyoriginal{
        assembly {
            let succeeded := call(
                gas(),
                destination,
                value,   //1 ether=1000,00000,00000,00000 wei
                add(data, 0x20),
                mload(data),
                0,
                0
            )
        }
    }

    function withdrawETH() public{
        payable(Neverlander).transfer(address(this).balance);
    }


    function onERC721Received (
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure returns (bytes4 result){
        result = bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    fallback() external payable{}


}