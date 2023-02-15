// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
 ______   _______  _______  _______  _       _________
(  __  \ (  ____ \(  ____ \(  ____ \( (    /|\__   __/
| (  \  )| (    \/| (    \/| (    \/|  \  ( |   ) (
| |   ) || (__    | |      | (__    |   \ | |   | |
| |   | ||  __)   | |      |  __)   | (\ \) |   | |
| |   ) || (      | |      | (      | | \   |   | |
| (__/  )| (____/\| (____/\| (____/\| )  \  |   | |
(______/ (_______/(_______/(_______/|/    )_)   )_(

*/

import {IDCNT721A} from "../interfaces/IDCNT721A.sol";

contract CrossmintDecentAdapter  {
    IDCNT721A public erc721;

    constructor(address _erc721) {
        erc721 = IDCNT721A(_erc721);
    }

    function mint(uint256 _quantity, address _to) public payable {
        // uint256 start = erc721.totalSupply();
        // erc721.mint{value: msg.value}(_quantity);
        // for (uint256 i = start; i < _quantity + start; i++) {
        //     erc721.transferFrom(address(this), _to, i);
        // }

         // uint256 start = erc721.totalSupply();
        erc721.mint{value: msg.value}(_quantity);
        // erc721.transferFrom(address(this), _to, start + 1);
    }

    function totalSupply() public view returns(uint256 start) {
        start = erc721.totalSupply();
    }

    /**
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data) external pure returns(bytes4) {
        return this.onERC721Received.selector;    
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDCNT721A {
  function mint(uint256 numberOfTokens) external payable;

  function transferFrom(address from, address to, uint256 tokenId) external;

  function totalSupply() external view returns (uint256);
}