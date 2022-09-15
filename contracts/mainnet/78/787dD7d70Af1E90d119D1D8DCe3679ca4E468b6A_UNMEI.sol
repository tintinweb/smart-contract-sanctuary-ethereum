// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;
 
import "./ERC721.sol";
import "./Strings.sol";
import "./Ownable.sol";

contract UNMEI is ERC721, Ownable 
{
    using Strings for uint256;


    mapping (address => bool) whiteList;

    string baseURI;

    constructor(string memory _baseURI) ERC721("UNMEI", "UNMEI") {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return string(abi.encodePacked(baseURI, id.toString()));
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function mintNow() public onlyOwner {
        _bulkMint(msg.sender, 0, 44);
    }

    // Bulk mint functin for ERC721, thanks to deltadevelopers llamaverse contract
    function _bulkMint(
        address to,
        uint256 id,
        uint256 count
    ) internal {
        unchecked {
            balanceOf[to] += count;
        }

        for (uint256 i = id; i < id + count; i++) {
            ownerOf[i] = to;
            emit Transfer(address(0), to, i);
        }
    }

    // OWNER ONLY
    function withdrawETH() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    /* @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        pure
        override(ERC721, Ownable)
        returns (bool)
    {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f || // ERC165 Interface ID for ERC721Metadata
            interfaceId == 0x7f5828d0; // ERC165 Interface ID for ERC173
    }
}