/**
 *Submitted for verification at Etherscan.io on 2023-02-25
*/

/*********************************
    BatchMint(Base, Introduced)
*********************************/
pragma solidity ^0.8.0;

library Clones {
	function clone(address implementation) internal returns (address instance) {
		/// @solidity memory-safe-assembly
		assembly {
			mstore(
				0x00,
				or(
					shr(0xe8, shl(0x60, implementation)),
					0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000
				)
			)
			mstore(
				0x20,
				or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3)
			)
			instance := create(0, 0x09, 0x37)
		}
		require(instance != address(0), "ERC1167: create failed");
	}

	function cloneDeterministic(address implementation, bytes32 salt)
		internal
		returns (address instance)
	{
		/// @solidity memory-safe-assembly
		assembly {
			mstore(
				0x00,
				or(
					shr(0xe8, shl(0x60, implementation)),
					0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000
				)
			)
			mstore(
				0x20,
				or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3)
			)
			instance := create2(0, 0x09, 0x37, salt)
		}
		require(instance != address(0), "ERC1167: create2 failed");
	}

	function predictDeterministicAddress(
		address implementation,
		bytes32 salt,
		address deployer
	) internal pure returns (address predicted) {
		/// @solidity memory-safe-assembly
		assembly {
			let ptr := mload(0x40)
			mstore(add(ptr, 0x38), deployer)
			mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
			mstore(add(ptr, 0x14), implementation)
			mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
			mstore(add(ptr, 0x58), salt)
			mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
			predicted := keccak256(add(ptr, 0x43), 0x55)
		}
	}

	function predictDeterministicAddress(address implementation, bytes32 salt)
		internal
		view
		returns (address predicted)
	{
		return predictDeterministicAddress(implementation, salt, address(this));
	}
}

pragma solidity ^0.8.0;

interface IERC721Receiver {
	function onERC721Received(
		address operator,
		address from,
		uint256 tokenId,
		bytes calldata data
	) external returns (bytes4);
}

pragma solidity ^0.8.7;

interface IERC721Drop {
	function purchase(uint256 quantity) external payable returns (uint256);

	function transferFrom(
		address from,
		address to,
		uint256 tokenId
	) external;
}

contract GET is IERC721Receiver {
	function onERC721Received(
		address _operator,
		address _from,
		uint256 _tokenId,
		bytes memory _data
	) public override returns (bytes4) {
		return 0x150b7a02;
	}

	IERC721Drop private constant drop =
		IERC721Drop(0xD4307E0acD12CF46fD6cf93BC264f5D5D1598792);

	function purchase(uint256 quantity)
		external
		payable
		returns (uint256 firstMintedTokenId)
	{
		firstMintedTokenId = drop.purchase(quantity);
	}

	function transferFrom(
		address from,
		address to,
		uint256 tokenId
	) external {
		drop.transferFrom(from, to, tokenId);
	}
}

contract zoraMint {
	address private immutable _get;
	uint256 public createCountM;

	constructor() {
		_get = address(new GET());
	}

	function batchMint(uint256 count) public payable {
		uint256 start = createCountM;
		address get = _get;
		for (uint256 i; i < count; ++i) {
			address clone = Clones.cloneDeterministic(
				get,
				keccak256(abi.encodePacked(i + start))
			);
			uint256 firstMintedTokenId = GET(clone).purchase(1);
			GET(clone).transferFrom(clone, msg.sender, firstMintedTokenId + 1);
		}
		createCountM = createCountM + count;
	}
}