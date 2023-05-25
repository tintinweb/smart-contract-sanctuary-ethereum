// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Contract interface for NFT Collection contract
abstract contract CollectionInterface {
    // Function definition of the `ownerOf` function on `Collection` smart contract
    function ownerOf(uint256 tokenId) public view virtual returns (address);
}

// Contract for Redemption of Sale Price 
contract Redemption {
    struct NFT {
        address nftContract;
        uint256 tokenId;
        uint256 salePriceAmount;
        bool released;
    }

    // mapping(uint256 => NFT) private idToNFT;
    // NFTContract => TokenID => Investor
    mapping(address => mapping(uint256 => NFT)) private _investors;

    struct Redeemed {
        address nftContract;
        uint256 tokenId;
        uint256 salePriceAmount;
        string investor;
        string accNumber;
    }

    // NFTContract => TokenID => Redeemed
    mapping(address => mapping(uint256 => Redeemed)) private _accounts;

    event RedeemedsalePriceAmount(
        address indexed nftContract,
        uint256 indexed tokenId,
        uint256 salePriceAmount,
        string investor,
        string accNumber
    );

    constructor() {}

    function recordInvestment(
        address[] memory nftContract,
        uint256[] memory tokenId,
        uint256 salePrice
    ) external payable {
        require(
            nftContract.length == tokenId.length,
            "Different length of inputs"
        );

        require(
            msg.value == salePrice,
            "Transaction value did not equal the recorded amount"
        );

        uint256 _salePrice = salePrice / nftContract.length;

        for (uint256 i = 0; i < nftContract.length; i++) {
            NFT memory _nft = NFT({
                nftContract: nftContract[i],
                tokenId: tokenId[i],
                salePriceAmount: _salePrice,
                released: false
            });

            _investors[nftContract[i]][tokenId[i]] = _nft;
        }
    }

    function beneficiary(
        address nftContract,
        uint256 tokenId
    ) public view returns (address) {
        CollectionInterface collectionContract = CollectionInterface(nftContract);

        return collectionContract.ownerOf(tokenId);
    }

    function redeemSalePrice(address nftContract, uint256 tokenId) internal {
        CollectionInterface collectionContract = CollectionInterface(nftContract);

        require(msg.sender == collectionContract.ownerOf(tokenId));
        require(_investors[nftContract][tokenId].released == false);

        _investors[nftContract][tokenId].released = true;

        uint256 _salePrice = _investors[nftContract][tokenId].salePriceAmount;

        (bool success, ) = payable(msg.sender).call{value: _salePrice}("");
        require(success);
    }

    function redeemsalePriceAmount(
        address nftContract,
        uint256 tokenId,
        string memory investor,
        string memory accNumber
    ) internal {
        CollectionInterface collectionContract = CollectionInterface(nftContract);

        require(msg.sender == collectionContract.ownerOf(tokenId));
        require(_investors[nftContract][tokenId].released == false);

        _investors[nftContract][tokenId].released = true; // true = redeemable

        uint256 _salePriceAmount = _investors[nftContract][tokenId].salePriceAmount;

        Redeemed memory _redeemed = Redeemed({
            nftContract: nftContract,
            tokenId: tokenId,
            salePriceAmount: _salePriceAmount,
            investor: investor,
            accNumber: accNumber
        });

        _accounts[nftContract][tokenId] = _redeemed;

        emit RedeemedsalePriceAmount(
            nftContract,
            tokenId,
            _salePriceAmount,
            investor,
            accNumber
        );
    }

    function redeemSalePrices(
        address[] memory nftContracts,
        uint256[] memory tokenIds
    ) external {
        for (uint i = 0; i < nftContracts.length; i++) {
            redeemSalePrice(nftContracts[i], tokenIds[i]);
        }
    }
}