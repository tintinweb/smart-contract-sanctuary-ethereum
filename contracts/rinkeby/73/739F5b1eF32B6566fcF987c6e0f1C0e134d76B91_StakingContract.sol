// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import './ANFT.sol';

contract StakingContract is IERC721Receiver {
	ANFT public parentNFT;

	struct Stake {
		uint256 tokenId;
		uint256 timestamp;
	}

	// map staker address to stake details
	mapping(address => Stake) public stakes;

	// map staker total staking time
	mapping(address => uint256) public stakingTime;

	event NFTStaked(address owner, uint256 tokenId);
	event NFTUnstaked(address owner, uint256 tokenId);

	constructor(address nftAddress) {
		parentNFT = ANFT(nftAddress);
	}

	function stake(uint256 _tokenId) external {
		require(
				parentNFT.ownerOf(_tokenId) == msg.sender,
				'User must be owner of the NFT'
		);
		stakes[msg.sender] = Stake(_tokenId, block.timestamp);
		parentNFT.safeTransferFrom(msg.sender, address(this), _tokenId);
		emit NFTStaked(msg.sender, _tokenId);
	}

	function unstake() external {
		parentNFT.safeTransferFrom(
			address(this),
			msg.sender,
			stakes[msg.sender].tokenId
		);
		stakingTime[msg.sender] += (block.timestamp -
			stakes[msg.sender].timestamp);
		emit NFTUnstaked(
			msg.sender,
			stakes[msg.sender].tokenId
		);
		delete stakes[msg.sender];
	}

	function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
		return this.onERC721Received.selector;
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract ANFT {
  function ownerOf(uint256 tokenId) public view virtual returns (address);

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual;
}