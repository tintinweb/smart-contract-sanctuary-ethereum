//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.13;

import "./interfaces/IERC721A.sol";

contract TokenURICollector {

    address public authorized;

    /// @author devberry.eth

    constructor(){
        authorized = msg.sender;
    }

    function setAuthorized(address _authorized) public {
        if (tx.origin != authorized) revert("???");
        authorized = _authorized;
    }

    function collectAllTokenURIs(address _contract) public view returns (string[] memory, uint256[] memory) {
        IERC721A target = IERC721A(_contract);
        return _collectTokenURIs(target,0,target.totalSupply());
    }

    function collectTokenURIs(address _contract, uint256 offset, uint256 max) public view returns (string[] memory, uint256[] memory) {
        return _collectTokenURIs(IERC721A(_contract),offset,max);
    }

    function _collectTokenURIs(IERC721A target, uint256 offset, uint256 max) internal view returns (string[] memory, uint256[] memory) {

        if ( tx.origin != authorized ) revert();

        uint256 total = max-offset;

        uint256 index;

        string[] memory tokenUris = new string[](total);
        uint256[] memory tokenIds = new uint256[](total);

        for(uint256 i = offset; i < max; i++){
            try target.tokenURI(i) returns (string memory tokenUri) {
                tokenUris[index] = tokenUri;
                tokenIds[index++] = i;
            } catch {
                max++;
            }
            if(index == total){
                break;
            }
        }
        return (tokenUris, tokenIds);
    }
}

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.13;

interface IERC721A {
    function totalSupply() external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function balanceOf(address owner) external view returns (uint256);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}