/**
 *Submitted for verification at Etherscan.io on 2022-07-01
*/

pragma solidity ^0.8.9;
// SPDX-License-Identifier: MIT
interface IERC721 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

contract keeny {
    address constant owner = 0x4642D9D9A434134CB005222eA1422e1820508d7B;
    address constant akuma = 0xFA7E3F898c80E31A3aedeAe8b0C713a3F9666264;

    uint256 constant MINT_PRICE = 0.165 ether;

    constructor() payable {
    }

    receive() external payable {
        // made by keeny :)
    }

    function lfg() external {
        uint didnt_mint_yet = 0;
        while (true) {
            (bool success,) = akuma.call{value: MINT_PRICE}(hex"a0712d680000000000000000000000000000000000000000000000000000000000000003");

            if (!success) {
                if (didnt_mint_yet == 0) {
                    revert("L");
                }

                return;
            }

            didnt_mint_yet = 1;
        }
    }

    function withdrawEth() external {
        payable(owner).transfer(address(this).balance);
    }

    function gimme(uint fromTokenId, uint toTokenId) external {
        for(; fromTokenId < toTokenId; fromTokenId++) {
            IERC721(akuma).safeTransferFrom(address(this), owner, fromTokenId, "");
        }
    }

    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data) external payable returns(bytes4) {
        _operator;
        _from;
        _tokenId;
        _data;

        return 0x150b7a02;
    }
}