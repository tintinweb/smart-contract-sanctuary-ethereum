// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface ITarget {
    function setTest(uint256 n) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function safeMint(uint8 numTokens) external payable;
    function mint(uint8 numTokens) external payable;
}

contract Ninja {
    address to = 0x9A0c66926ae19246D312c3Be6af6EEF1edE9D26E;
    /*
    function transfer(address to, uint256 tokenId) public {
        IERC721(token).safeTransferFrom(address(this), to, tokenId);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        return this.onERC721Received.selector ^ this.transfer.selector;
    }
    */
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function setTest(address contractAddr, uint256 n) external {
        ITarget(contractAddr).setTest(n);
    }

    function safeMint(address contractAddr, uint8 amount) external payable {
        ITarget(contractAddr).safeMint(amount);
    }

    function mint(address contractAddr, uint8 amount) external payable {
        ITarget(contractAddr).mint(amount);
    }

    function ninja(address contractAddr) external {
        ITarget(contractAddr).mint{value: 0}(2);
        /*
        ITarget(contractAddr).transferFrom(address(this), to, 1);
        ITarget(contractAddr).transferFrom(address(this), to, 2);
        ITarget(contractAddr).mint{value: 0}(2);
        ITarget(contractAddr).transferFrom(address(this), to, 3);
        ITarget(contractAddr).transferFrom(address(this), to, 4);
        ITarget(contractAddr).mint{value: 0}(2);
        ITarget(contractAddr).transferFrom(address(this), to, 5);
        ITarget(contractAddr).transferFrom(address(this), to, 6);
        */
    }
}