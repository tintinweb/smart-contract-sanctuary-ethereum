// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface FrontPage {
    function ownerOf(uint256 id) external view returns (address);

    function nextId() external view returns (uint256);
}

contract FrontPageReader {
    FrontPage public immutable frontPage;

    constructor(address _frontPage) {
        frontPage = FrontPage(_frontPage);
    }

    function balanceOf(address owner) external view returns (uint256 balance) {
        uint256 maxId = frontPage.nextId();

        for (uint256 id = 1; id < maxId; ) {
            if (frontPage.ownerOf(id) == owner) ++balance;

            unchecked {
                ++id;
            }
        }
    }
}