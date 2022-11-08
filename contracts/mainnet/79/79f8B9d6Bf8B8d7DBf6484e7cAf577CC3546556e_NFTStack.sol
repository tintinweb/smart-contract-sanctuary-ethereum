// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract NFTStack is IERC721Receiver {
  struct StackingInfo {
    address owner;
    uint256 tokenId;
    uint256 startTime;
  }

  struct StackHistoryInfo {
    address owner;
    uint256 tokenId;
    uint256 startTime;
    uint256 endTime;
  }

  ERC721 public immutable nft; 

  /**
   * KEY: tokenId
   * VALUE: StackingInfo
   */
  mapping (uint256 => StackingInfo) private _stackingInfoMap;

  StackHistoryInfo[] private _stackHistoryInfos;

  constructor(address _nft) {
    nft = ERC721(_nft);
  }

  function tokensOfOwner(address owner) external view returns (uint256[] memory) {
		uint256 index = 0;
		uint256 totalMinted = nft.totalMinted();
		uint256 tokenIdsLen = nft.balanceOf(owner);
		uint256[] memory tokenIds = new uint256[](tokenIdsLen);

		for (uint256 tokenId = 1; index < tokenIdsLen && tokenId <= totalMinted; tokenId++) {
			if (owner == nft.ownerOf(tokenId)) {
				tokenIds[index] = tokenId;
				index++;
			}
		}

		return tokenIds;
	}

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "Must from user");
    _;
  }

  function deposit(uint256[] calldata tokenIds) external callerIsUser {
    for (uint256 i = 0; i < tokenIds.length; i++) {
      uint256 tokenId = tokenIds[i];
      nft.safeTransferFrom(msg.sender, address(this), tokenId);
      _stackingInfoMap[tokenId] = StackingInfo(msg.sender, tokenId, block.timestamp);
    }
  }

  function withdraw(uint256[] calldata tokenIds) external callerIsUser {
    for (uint256 i = 0; i < tokenIds.length; i++) {
      uint256 tokenId = tokenIds[i];
      StackingInfo memory info = _stackingInfoMap[tokenId];

      require(info.owner == msg.sender, "You are not the nft's onwer");

      _stackHistoryInfos.push(StackHistoryInfo(info.owner, info.tokenId, info.startTime, block.timestamp));
      _stackingInfoMap[tokenId].owner = address(0);
      nft.safeTransferFrom(address(this), msg.sender, tokenId);
    }
  }

  function getStackingDuration(uint256[] calldata tokenIds) view external returns (uint256[] memory) {
    uint256[] memory durations = new uint256[](tokenIds.length);

    for (uint256 i = 0; i < tokenIds.length; i++) {
      StackingInfo memory info = _stackingInfoMap[tokenIds[i]];

      if (info.owner != address(0)) {
        durations[i] = block.timestamp - info.startTime;
      } else {
        durations[i] = 0;
      }
    }

    return durations;
  }

  function queryStackingInfoByTokenId(uint256[] calldata tokenIds) view external returns (StackingInfo[] memory) {
    StackingInfo[] memory infos = new StackingInfo[](tokenIds.length);
    for (uint256 i = 0; i < tokenIds.length; i++) {
      infos[i] = _stackingInfoMap[tokenIds[i]];
    }
    return infos;
  }

  function queryStackingInfoByOwner(address owner) view external returns (StackingInfo[] memory) {
    StackingInfo[] memory infos = new StackingInfo[](0);
    uint256 totalMinted = nft.totalMinted();

    for (uint256 tokenId = 1; tokenId <= totalMinted; tokenId++) {
      StackingInfo memory info = _stackingInfoMap[tokenId];
      if (info.owner == owner) {
        infos = _stackingInfoPush(infos, info);
      }
    }

    return infos;
  }

  function getStackingInfo() view external returns (StackingInfo[] memory) {
    StackingInfo[] memory infos = new StackingInfo[](0);
    uint256 totalMinted = nft.totalMinted();

    for (uint256 tokenId = 1; tokenId <= totalMinted; tokenId++) {
      StackingInfo memory info = _stackingInfoMap[tokenId];
      if (info.owner != address(0)) {
        infos = _stackingInfoPush(infos, info);
      }
    }

    return infos;
  }

  function getStackHistory() view external returns (StackHistoryInfo[] memory) {
    return _stackHistoryInfos;
  }

  function _stackingInfoPush(StackingInfo[] memory infos, StackingInfo memory info) private pure returns(StackingInfo[] memory) {
    StackingInfo[] memory temp = new StackingInfo[](infos.length + 1);
    for (uint256 index = 0; index < infos.length; index++) {
      temp[index] = infos[index];
    }
    temp[temp.length - 1] = info;
    return temp;
  }

  function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
    return IERC721Receiver.onERC721Received.selector;
  }
}

interface ERC721 {
  function totalMinted() external view returns(uint256);
  function balanceOf(address owner) external view returns (uint256);
  function ownerOf(uint256 tokenId) external view returns (address);
  function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}