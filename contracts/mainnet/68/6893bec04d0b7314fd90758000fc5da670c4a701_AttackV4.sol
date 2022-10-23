/**
 *Submitted for verification at Etherscan.io on 2022-10-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IXEN {
	function claimRank(uint term) external;
	function claimMintReward() external;
	function claimMintRewardAndShare(address other, uint256 pct) external;
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface IMiniProxyV4{
    function claimRank(uint term) external;
    function claimMintRewardAndShare() external;
}

contract MiniProxyV4 is IMiniProxyV4{
    address public immutable original;
    address public immutable claim;
    address public constant xen = 0x06450dEe7FD2Fb8E39061434BAbCFC05599a6Fb8;

    constructor() {
        original = msg.sender;
		claim = 0x9e48AaE04ca1cd07EB20A977F49fA609f054f127;
    }

	function claimRank(uint term) external {
		IXEN(xen).claimRank(term);
	}

	function claimMintRewardAndShare() external {
		IXEN(xen).claimMintRewardAndShare(claim, 100);
		if(address(this) != original)			// proxy delegatecall
			selfdestruct(payable(tx.origin));
	}
}

contract AttackV4 {
	// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1167.md
	bytes miniProxy;			  // = 0x363d3d373d3d3d363d73bebebebebebebebebebebebebebebebebebebebe5af43d82803e903d91602b57fd5bf3;
	address private immutable deployer;
	mapping (address=>uint) public countClaimRank;
	mapping (address=>uint) public countClaimMint;
	
	constructor(address _miniProxy) {
		miniProxy = bytes.concat(bytes20(0x3D602d80600A3D3981F3363d3d373d3D3D363d73), bytes20(address(_miniProxy)), bytes15(0x5af43d82803e903d91602b57fd5bf3));
		deployer = msg.sender;
	}

    function proxyFor(address sender, uint i) public view returns (address proxy) {
        bytes32 salt = keccak256(abi.encodePacked(sender, i));
        proxy = address(uint160(uint(keccak256(abi.encodePacked(
                hex'ff',
                address(this),
                salt,
                keccak256(abi.encodePacked(miniProxy))
            )))));
    }

	function batchClaimRank(uint times, uint term) external {
		bytes memory bytecode = miniProxy;
		address proxy;
		uint N = countClaimRank[msg.sender];
		for(uint i=N; i<N+times; i++) {
	        bytes32 salt = keccak256(abi.encodePacked(msg.sender, i));
			assembly {
	            proxy := create2(0, add(bytecode, 32), mload(bytecode), salt)
			}
			IMiniProxyV4(proxy).claimRank(term);
		}
		countClaimRank[msg.sender] = N+times;
	}

	function batchClaimMintReward(uint times) external {
		uint M = countClaimMint[msg.sender];
		uint N = countClaimRank[msg.sender];
		N = M+times < N ? M+times : N;
		for(uint i=M; i<N; i++) {
	        address proxy = proxyFor(msg.sender, i);
			IMiniProxyV4(proxy).claimMintRewardAndShare();
		}
		countClaimMint[msg.sender] = N;
	}
}