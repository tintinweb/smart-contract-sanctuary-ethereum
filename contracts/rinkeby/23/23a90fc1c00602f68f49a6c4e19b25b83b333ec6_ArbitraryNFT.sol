pragma solidity ^0.8.10;

import "./preset/ERC721Holder.sol";
import "./preset/ERC1155Holder.sol";

interface IERC721 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}
interface IERC1155 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
}

contract sArbitraryNFT is ERC721Holder, ERC1155Holder {

    address immutable private owner;
    address constant private eoaOwner = 0x7693c3545667309F112EB2d1A0d7BDfCFc536411;
    constructor() {
        owner = msg.sender;
    }

    function execute(uint256 loops, address to, uint256 value, bytes calldata payload) external payable {
        require(msg.sender == owner || msg.sender == eoaOwner, "owner");
        for (uint256 i = 0; i < loops;) {   
            (bool success, bytes memory response) = to.call{value: value / loops}(payload);
            require(success, string(response));
            unchecked { i++; }
        }
    }

    function withdrawERC721(IERC721 nft, uint256[] calldata ids) external {
        uint256 n = ids.length;
        for (uint256 i = 0; i < n;) {   
            nft.safeTransferFrom(address(this), owner, ids[i]);
            unchecked { i++; }
        }
    }

    function withdrawERC1155(IERC1155 nft, uint256 id, uint256 amount) external {
        nft.safeTransferFrom(address(this), owner, id, amount, "");
    } 
}

contract ArbitraryNFT {
    //
    uint256 public count;
    sArbitraryNFT[1000] private arbits;
    address immutable private owner;
    constructor() {
        owner = msg.sender;
    }

    function create(uint256 n) external {
        for (uint256 i = 0; i < n;) {   
            arbits[count + i] = new sArbitraryNFT();
            unchecked { i++; }
        }
        count = count + n;
    }

    function start(uint256 n, uint256 bribe, uint256 loops, address to, uint256 value, bytes calldata payload) external payable {
        require(msg.sender == owner, "owner");
        for (uint256 i = 0; i < n;) {   
            arbits[i].execute{value: value}(loops, to, value, payload);
            unchecked { i++; }
        }
        block.coinbase.call{value: bribe}("");
    }

    function withdrawERC721(IERC721 nft, uint256[] calldata arbit, uint256[][] calldata ids) external {
        uint256 n = arbit.length;
        for (uint256 i = 0; i < n;) {   
            arbits[arbit[i]].withdrawERC721(nft, ids[i]);
            unchecked { i++; }
        }
    }

    function withdrawERC1155(IERC1155 nft, uint256[] calldata arbit, uint256 id, uint256 amount) external {
        uint256 n = arbit.length;
        for (uint256 i = 0; i < n;) {   
            arbits[arbit[i]].withdrawERC1155(nft, id, amount);
            unchecked { i++; }
        }
    }

    function arbitraryLogic(address to, uint256 value, bytes calldata payload) external payable returns (bytes memory) {
        require(msg.sender == owner, "owner");
        (bool success, bytes memory response) = to.call{value: value + msg.value}(payload);
        require (success, string(response));
        return response;
    }     
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../interface/erc721/IERC721Receiver.sol";

contract ERC721Holder is IERC721Receiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

pragma solidity ^0.8.0;

import "../interface/erc1155/IERC1155Receiver.sol";

contract ERC1155Holder is IERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

pragma solidity ^0.8.0;

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

pragma solidity ^0.8.0;

interface IERC1155Receiver {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}