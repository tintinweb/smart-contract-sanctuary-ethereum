/**
 *Submitted for verification at Etherscan.io on 2023-02-26
*/

// SPDX-License-Identifier: MIT
//китаец соси мой хуй

pragma solidity ^0.8.17;
interface Tokenint {
  function safeTransferFrom(address from, address to, uint256 id) external;
  function mint(address, uint256, address) external payable;
  function totalSupply() external view returns(uint256);
}
contract BaseMultiMinter {
    bytes miniProxy;

    constructor() {
		miniProxy = bytes.concat(bytes20(0x3D602d80600A3D3981F3363d3d373d3D3D363d73), bytes20(address(this)), bytes15(0x5af43d82803e903d91602b57fd5bf3));
	}

    function  MultiMint(address target, uint256 times)  public payable {
        uint256 price = 0.000777 ether;
        require(msg.value== times * price,"need ether");
        address master = msg.sender;
        bytes memory bytecode = miniProxy;
        Tokenint proxy;
        uint256 bnum = block.number;
        uint256 startId = Tokenint(target).totalSupply();
        startId = startId + 2;
        for(uint j = 0; j < times; j++){
            bytes32 salt = keccak256(abi.encodePacked(bnum, msg.sender, j));
			assembly {
	            proxy := create2(0, add(bytecode, 32), mload(bytecode), salt)
			}
			proxy.mint{value: 0.000777 ether}(master, startId + j, target);
        }
    }
    fallback() external { 
        (address target, uint256 times) = abi.decode(msg.data, (address,uint256));
        MultiMint(target, times);
    }
}