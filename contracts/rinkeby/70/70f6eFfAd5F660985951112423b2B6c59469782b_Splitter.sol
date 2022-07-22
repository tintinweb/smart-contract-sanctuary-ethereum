// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

interface ISplitter {
    function split() external;
}

contract Splitter is ISplitter {
    constructor() {}

    function split() external {
        uint256 totBalance = address(this).balance;

        (bool hs1, ) = payable(0x5D7063f01b51AfA6d44D46797Cb9Ae5D90e3D64a).call{
            value: (totBalance * 27) / 100
        }("");
        require(hs1);

        (bool hs2, ) = payable(0xb0a5Cc4Ebe226e44445cAFDE6129b1e7d7cefaad).call{
            value: ((totBalance * 53) / 2) / 100
        }("");
        require(hs2);

        (bool hs3, ) = payable(0xa1f3a4887ba0A62dEA17FB137BB4bA9E46751068).call{
            value: ((totBalance * 53) / 2) / 100
        }("");
        require(hs3);

        (bool hs4, ) = payable(0xAcD4Df33daeee25dc09E3d9a3148A884797E18C2).call{
            value: (totBalance * 20) / 100
        }("");
        require(hs4);
    }
}