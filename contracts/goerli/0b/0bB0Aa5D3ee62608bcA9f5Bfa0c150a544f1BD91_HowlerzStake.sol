// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface IChamps {
  function transferFrom(address from, address to, uint256 tokenId) external;
  function registerChampion(uint tokenId) external;
}

contract HowlerzStake is IERC721Receiver {
  address constant public testnetHowlerz = 0xE9964885611ce5b2923e65f98347e536CB3fe774;

  mapping (address => uint[]) public stakedChamps;
  
  function stakeChamps (uint[] memory champIds) public {
    IChamps champs = IChamps(testnetHowlerz);
    for (uint i = 0; i < champIds.length; i++) {
      champs.transferFrom(msg.sender, address(this), champIds[i]);
      champs.registerChampion(champIds[i]);
    }
  }

  function returnChamps () public {
    IChamps champs = IChamps(testnetHowlerz);
    for (uint i = 0; i < stakedChamps[msg.sender].length; i++) {
      champs.transferFrom(address(this), msg.sender, stakedChamps[msg.sender][i]);
    }
  }

  function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) public override returns (bytes4) {
    stakedChamps[from].push(tokenId);
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