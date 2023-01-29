// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10 <0.9.0;

interface IOnchainTokenUriSupplier {
	function tokenURI(uint256 _tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10 <0.9.0;
import "../interface/IOnchainTokenUriSupplier.sol";

contract OnchainTokenUriSupplier is IOnchainTokenUriSupplier {
	function tokenURI(uint256) external pure returns (string memory) {
		return "";
	}
}