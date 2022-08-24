/**
 *Submitted for verification at Etherscan.io on 2022-08-24
*/

pragma solidity ^0.8.0;

contract fakeNFTtest {

    struct NFT {
		address contractAddress;
		uint256 tokenId;
	}

    uint256 public totalCount;
	mapping(uint256 => NFT) public nfts;

    function viewNFTs(uint256 _start, uint256 _maxLen) external view returns(NFT[] memory) {
		// return empty array if _start is out of bounds
		if (_start >= totalCount)
			return new NFT[](0);

		// limits _maxLen so we only return existing NFTs 
		if (_start + _maxLen > totalCount)
			_maxLen = totalCount - _start;

		NFT[] memory _nfts = new NFT[](_maxLen);
		for (uint256 i = 0; i < _maxLen; i++) {
			_nfts[i] = nfts[i + _start];
		}
		return _nfts;
	}

	function depositNFTs(address[] calldata _contracts, uint256[] calldata _tokenIds) public {
		require(_contracts.length == _tokenIds.length);
		
		uint256 len = _contracts.length;
		uint256 currentCount = totalCount;
		for (uint256 i = 0; i < len; i++) {
			nfts[currentCount++] = NFT(_contracts[i], _tokenIds[i]);
		}
		totalCount = currentCount;
	}

	function depositManyNFTs(address[] calldata _contracts, uint256[] calldata _tokenIds, uint256 _amount) external {
		for (uint256 i = 0; i < _amount; i++) {
			depositNFTs(_contracts, _tokenIds);
		}
	}
}