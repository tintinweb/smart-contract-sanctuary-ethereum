/**
 *Submitted for verification at Etherscan.io on 2023-01-30
*/

contract Test {
function getAllTokenIds() public returns (uint256[] memory) {
        uint256 count = 0;
        for (uint256 i = 1; i < 10_000; i++) {
            if (_exists(i)) {
                count++;
            }
        }
        uint256[] memory tokenIds = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 1; i < 10_000; i++) {
            if (_exists(i)) {
                tokenIds[index] = i;
                index++;
            }
        }
        return tokenIds;
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return false;
    }
}