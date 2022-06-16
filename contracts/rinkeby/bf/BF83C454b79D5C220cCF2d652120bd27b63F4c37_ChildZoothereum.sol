// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface INFT {
    function mint(address _to, uint256 _tokenId) external;

    function tokenTypeAndPrice(uint256 _tokenId)
        external
        view
        returns (string memory _tokenType, uint256 _price);

    function ownerOf(uint256 _tokenId) external returns (address owner);
}

contract ChildZoothereum {
    INFT public zoothereumContract;
    //check if tokeId in minted array, if minted ++ else counter +1 if limit of range revert
    mapping(uint256 => bool) mintedNfts;
    uint16[9] maxSupplyPerRange = [250, 450, 600, 700, 790, 835, 865, 885, 900];
    uint256[9] public rangesCurrTokenId = [
        1,
        251,
        451,
        601,
        701,
        791,
        836,
        866,
        886
    ];

    // MODIFIERS

    /*
     * @notice checks if range selected is valid and has available nfts to mint
     * @param _range uint of the position in the array of the specified range
     */
    modifier checkValidRange(uint256 _range) {
        require(_range >= 0 && _range < 9, "selected range not available");
        require(
            rangesCurrTokenId[_range] < maxSupplyPerRange[_range],
            "Can't mint more nfts for that range"
        );
        _;
    }

    /*
     * @param _zoothereumAddress address of deployed zoothereum contract
     * @param _mintedNfts array of tokenIds already minted in the main contract
     */
    constructor(address _zoothereumAddress, uint256[] memory _mintedNfts) {
        setMintedNfts(_mintedNfts);
        zoothereumContract = INFT(_zoothereumAddress);
    }

    /*
     * @notice Function to buy nft for a range
     * @param _range range of the nft to buy, must be a valid one
     */
    function buy(uint256 _range) external payable checkValidRange(_range) {
        uint256 tokenId = getTokenIdForRange(_range);

        (, uint256 price) = zoothereumContract.tokenTypeAndPrice(tokenId);
        require(msg.value >= price, "Invalid value sent");

        zoothereumContract.mint(msg.sender, tokenId);
    }

    /*
     * @notice get current valid tokenId for selected range to be minted
     * @param _range range to get tokenId for
     * @dev it will return tokenId to be minted, if range is completed reverts and updates rangeCurrTokenID
     */
    function getTokenIdForRange(uint256 _range)
        internal
        returns (uint256 _tokenId)
    {
        uint256 counter = rangesCurrTokenId[_range];

        while (
            mintedNfts[counter] && counter + 1 <= maxSupplyPerRange[_range]
        ) {
            unchecked {
                counter++;
            }

            if (mintedNfts[counter] && counter == maxSupplyPerRange[_range]) {
                rangesCurrTokenId[_range] = counter;
                revert("range completed, could not perform mint");
            }
        }

        rangesCurrTokenId[_range] = counter + 1;

        return counter;
    }

    /*
     * @notice funcion called by the constructor to set the snapShot of zooethereum contract
     * @param _mintedNfts array of tokenIds minted in zooethereum contract
     */
    function setMintedNfts(uint256[] memory _mintedNfts) internal {
        // Gas expensive funcition, would be nice to find a more efficient structure to store the
        // minted tokenIds
        for (uint256 i = 0; i < _mintedNfts.length; ) {
            mintedNfts[_mintedNfts[i]] = true;
            unchecked {
                ++i;
            }
        }
    }
}