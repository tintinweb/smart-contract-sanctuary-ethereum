//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.13;

import "./interfaces/IERC721A.sol";

contract ERC721AWalletOfOwner {

    /// @author devberry.eth

    constructor(){}

    function walletOfOwner(address _contract, address owner) public view returns (uint256[] memory) {

        IERC721A target = IERC721A(_contract);

        uint256 totalSupply = target.totalSupply();

        uint256 totalOwned = target.balanceOf(owner);

        uint256 index;

        uint256[] memory tokenIds = new uint256[](totalOwned);

        for(uint256 i = 0; i < totalSupply; i++){
            try target.ownerOf(i) returns (address _owner) {
                if(_owner==owner){
                    tokenIds[index++] = i;
                }
            } catch {
                totalSupply++;
            }
            if(index == totalOwned){
                break;
            }
        }

        return tokenIds;

    }

}

pragma solidity ^0.8.13;

interface IERC721A {
    function totalSupply() external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function balanceOf(address owner) external view returns (uint256);
}