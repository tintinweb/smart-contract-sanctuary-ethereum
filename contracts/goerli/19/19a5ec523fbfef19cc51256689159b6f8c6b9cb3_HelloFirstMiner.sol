// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract HelloFirstMiner is ERC721, ERC721Enumerable, Ownable {

    event Claimed(uint indexed ID, address indexed owner);

    uint public constant MAX_SUPPLY = 1000;
    uint public ID = 0;
    address receiver = 0x05a56E2D52c817161883f50c441c3228CFe54d9f;
    constructor() ERC721("HelloFirstMiner", "HFM") {}

    function claim(string memory _message) external {
        require(ID < MAX_SUPPLY, "Max supply exceeded.");

        receiver.call(abi.encode(_message));
        _mint(msg.sender, ID);

        emit Claimed(ID, msg.sender);

        ID += 1;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://hermitcrabs.mypinata.cloud/ipfs/QmUh238QNqAhNN9uHWzLqYz94BqTToSJViAExzCYdhT4Hr/jsons/";
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}