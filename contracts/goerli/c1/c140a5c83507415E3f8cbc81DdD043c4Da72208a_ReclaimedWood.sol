// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contract interface
abstract contract TreesInterface {
    // Function definition of the `ownerOf` function on `Trees` smart contract
    function ownerOf(uint256 tokenId) public view virtual returns (address);
}

contract ReclaimedWood {
    struct NFT {
        address nftContract;
        uint256 tokenId;
        uint256 profitAmount;
        bool released;
    }

    // mapping(uint256 => NFT) private idToNFT;
    // NFTContract => TokenID => Investor
    mapping(address => mapping(uint256 => NFT)) private _investors;

    constructor() {}

    // Input: ([Ox...123, 0x...456, 0x...789, 0x...123], [2, 1, 3, 4], 6000000000000000000)
    function recordInvestment(
        address[] memory nftContract,
        uint256[] memory tokenId,
        uint256 profit
    ) external payable {
        require(
            nftContract.length == tokenId.length,
            "Different length of inputs"
        );

        require(
            msg.value == profit,
            "Transaction value did not equal the recorded amount"
        );

        uint256 _profit = profit / nftContract.length;

        for (uint256 i = 0; i < nftContract.length; i++) {
            NFT memory _nft = NFT({
                nftContract: nftContract[i],
                tokenId: tokenId[i],
                profitAmount: _profit,
                released: false
            });

            _investors[nftContract[i]][tokenId[i]] = _nft;
        }
    }

    function beneficiary(address nftContract, uint256 tokenId)
        public
        view
        returns (address)
    {
        TreesInterface treesContract = TreesInterface(nftContract);

        return treesContract.ownerOf(tokenId);
    }

    function redeemProfit(address nftContract, uint256 tokenId) external {
        TreesInterface treesContract = TreesInterface(nftContract);

        require(msg.sender == treesContract.ownerOf(tokenId));

        uint256 _profit = _investors[nftContract][tokenId].profitAmount;

        (bool success, ) = payable(msg.sender).call{
            value: _profit
        }("");
        require(success);
    }
}