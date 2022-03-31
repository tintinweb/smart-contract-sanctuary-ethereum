// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./Encoding.sol";

import "./DegenFetcherInterface.sol";
import "./Metadata.sol";
import "./SVG.sol";
import "./BokkyPooBahsDateTimeContract.sol";

contract DegenBlues is ERC721, Ownable {
    enum Coin{ ETH, BTC }
    struct FeedInfo {
        address feed;
        uint dataPointsToFetchPerDay;
    }

    uint80 constant MEASURES = 3;
    uint80 constant PERPETUAL_JAM_DAYS = 2;

    BokkyPooBahsDateTimeContract dates;
    Metadata metadata;
    DegenFetcherInterface fetcher;
    SVG svg;
    uint80 constant SECONDS_PER_DAY = 3600*24;
    uint mintPrice = 0.15 * 10**18; 
    bool publicMintingAllowed = false;
    FeedInfo priceFeedETH;
    FeedInfo priceFeedBTC;
    mapping(address => uint8) private allowList;


    constructor(address dateTimeAddress, address priceFeedAddressETH, address priceFeedAddressBTC, address fetcherAddress) ERC721("Degen Blues", "DGB") {
        fetcher = DegenFetcherInterface(address(fetcherAddress));
        dates = BokkyPooBahsDateTimeContract(address(dateTimeAddress));
        // dates = new BokkyPooBahsDateTimeContract();
        priceFeedETH = FeedInfo(
            address(priceFeedAddressETH),
            8*MEASURES
        );
        priceFeedBTC = FeedInfo(
            address(priceFeedAddressBTC),
            4*MEASURES
        );
        metadata = new Metadata(dates);
        svg = new SVG(metadata);

        // Mint Edition Zero
        _safeMint(msg.sender, 0);
    }

    // Determines whether members of the public can mint
    function setPublicMintingAllowed(bool _allow) onlyOwner external {
        publicMintingAllowed = _allow;
    }

    function getPublicMintingAllowed() external view returns (bool) {
        return publicMintingAllowed;
    }

    /* Returns 0 if sender is not specifically whitelisted
     * otherwise returns the number of mints allowed */
    function getMyMintingQuota() external view returns (int) {
        return int256(int8(allowList[msg.sender]));
    }

    /* Returns 0 if sender is not specifically whitelisted
     * otherwise returns the number of mints allowed */
    function getMintingQuotaFor(address addr) external view returns (int) {
        return int256(int8(allowList[addr]));
    }

    function setAllowList(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            allowList[addresses[i]] = numAllowedToMint;
        }
    }

    function getFeedInfoForCoin(Coin coin) internal view returns (FeedInfo memory) {
        if (coin == Coin.ETH) {
            return priceFeedETH;
        } else {
            return priceFeedBTC;
        }
    }

    function getStartOfDay(uint timestamp) internal view returns (uint) {
        uint year = dates.getYear(timestamp);
        uint month = dates.getMonth(timestamp);
        uint day = dates.getDay(timestamp);
        return dates.timestampFromDate(year,month,day);
    }

	function getNFTPrice() public view returns (uint) /*wei*/ {
		return mintPrice; 
	}

    function setNFTPrice(uint newPrice) public onlyOwner {
        mintPrice = newPrice;
    }

    function withdraw() public onlyOwner payable {
        payable(owner()).transfer(payable(address(this)).balance);
    }

    uint constant EPOCH_DATE = 1601942400; /* Oct 6, 2020 */

    function mint(uint fromTimestamp) public payable returns (uint256) {
        return mintTo(fromTimestamp, msg.sender);
    }

    function mintTo(uint fromTimestamp, address recipient) public payable returns (uint256) {
        if (msg.sender != owner()) {
            require(getNFTPrice() <= msg.value, "Not enough ether sent");
            require((allowList[msg.sender] > 0) || publicMintingAllowed, "Minting disabled");
        }

        if (fromTimestamp > 0) {
            // Verify that fromTimestamp is the beginning of a day between EPOCH_DATE and yesterday
            require(fromTimestamp == getStartOfDay(fromTimestamp));
            require(fromTimestamp + SECONDS_PER_DAY < block.timestamp);
            require(fromTimestamp >= EPOCH_DATE);
        } 

        if (!publicMintingAllowed && (allowList[msg.sender] > 0)) {
            allowList[msg.sender] -= 1;
        }

        uint256 newItemId = tokenIdForDate(fromTimestamp);

        _safeMint(recipient, newItemId);
        return newItemId;
    }

    function fetchCoinPriceData(uint256 fromTimestamp, uint80 daysToFetch, Coin coin) internal view returns (int32[] memory) {
        FeedInfo memory feedInfo = getFeedInfoForCoin(coin);
        return fetcher.fetchPriceDataForFeed(feedInfo.feed, fromTimestamp, daysToFetch, feedInfo.dataPointsToFetchPerDay);
    }    

    function perpetualDataStartTime() internal view returns (uint256) {
        return (block.timestamp - PERPETUAL_JAM_DAYS*SECONDS_PER_DAY);
    }

    // Will fetch perpetual data if tokenId is zero
    function getPriceDataForCoin(uint256 tokenId, Coin coin) internal view returns (int32[] memory) {
        uint256 fromTimestamp = dateForTokenId(tokenId);
        uint80 daysToFetch;
        if (tokenId == 0) {
            daysToFetch = PERPETUAL_JAM_DAYS;
        } else {
            daysToFetch = 1;
        }
        return fetchCoinPriceData(fromTimestamp, daysToFetch, coin);
    }

    struct DayData {
        uint fromTimestamp;
        address owner;
        uint256 tokenId;
        string ethData;
        string btcData;
        string ethStats;
    }

    function getAllDataForDays(uint256[] memory fromTimestamps) external view returns (DayData[] memory) {
        DayData[] memory dayData = new DayData[](fromTimestamps.length);
        for (uint i = 0; i < fromTimestamps.length; i++) {
            dayData[i] = getAllDataForDay(fromTimestamps[i]);
        }
        return dayData;
    }

    function getAllDataForGoldMaster() public view returns (DayData memory) {
        int32[] memory ethData = getPriceDataForCoin(0, Coin.ETH);
        int32[] memory btcData = getPriceDataForCoin(0, Coin.BTC);
        string memory ethDataString = Encoding.encode(ethData);
        string memory btcDataString = Encoding.encode(btcData);
        
        address owner = _exists(0) ? ownerOf(0) : address(0);

        return DayData(0, owner, 0, ethDataString, btcDataString, '');

    }

    function tokenIdForDate(uint256 fromTimestamp) internal pure returns (uint256 tokenId) {
        if (fromTimestamp == 0) {
            return 0;
        } else {
            return 1 + (fromTimestamp - EPOCH_DATE)/SECONDS_PER_DAY;
        }
    }

    function dateForTokenId(uint256 tokenId) internal view returns (uint256 fromTimestamp) {
        if (tokenId == 0) {
            return perpetualDataStartTime();
        } else {
            return EPOCH_DATE + SECONDS_PER_DAY*(tokenId - 1);
        }
    }

    function getAllDataForDay(uint256 fromTimestamp) public view returns (DayData memory) {
        require(fromTimestamp == getStartOfDay(fromTimestamp));
        require(fromTimestamp > 0);

        int32[] memory ethData = fetchCoinPriceData(fromTimestamp, 1, Coin.ETH);
        int32[] memory btcData = fetchCoinPriceData(fromTimestamp, 1, Coin.BTC);
        string memory ethDataString = Encoding.encode(ethData);
        string memory btcDataString = Encoding.encode(btcData);
        string memory ethStats = metadata.getAttributes(ethData, fromTimestamp);

        uint256 tokenId = tokenIdForDate(fromTimestamp);
        address owner = _exists(tokenId) ? ownerOf(tokenId) : address(0);

        return DayData(fromTimestamp, owner, tokenId, ethDataString, btcDataString, ethStats);
    }


    function getSVGImageWith(uint256 tokenId, int32[] memory ethPriceData) internal view returns (string memory) {
        return tokenId == 0 ? svg.masterImageWith() : svg.printImageWith(ethPriceData, tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string memory name = metadata.getNameForTokenId(tokenId);
        uint fromTimestamp = dateForTokenId(tokenId);
        string memory description = metadata.descriptionForTokenId(tokenId, fromTimestamp);
        string memory svgImage;
        string memory attributesStr;

        string memory animationUrl;
        {
            int32[] memory ethPriceData = getPriceDataForCoin(tokenId, Coin.ETH);
            int32[] memory btcPriceData = getPriceDataForCoin(tokenId, Coin.ETH);
            string memory ethPriceDataString = Encoding.encode(ethPriceData);
            svgImage = getSVGImageWith(tokenId, ethPriceData);
            attributesStr = metadata.getAttributes(ethPriceData, fromTimestamp);
            animationUrl = metadata.getAnimationUrl(ethPriceDataString, Encoding.encode(btcPriceData));
        }

        return string(
            abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(
                bytes(
                abi.encodePacked(
                    '{',
                    '"description":"', description,
                    '"',
                    unicode', "name":"', name,
                    '"',
                    ', "external_url":"',
                    'https://degenblues.xyz/?t=',
                    Encoding.uint2str(tokenId),
                    '"',
                    ', "image":"',
                    "data:image/svg+xml;base64,",
                    Base64.encode(bytes(svgImage)),
                    '"',
                    ', "animation_url":"',
                    animationUrl,
                    '"',
                    ', "attributes": ', attributesStr,
                    '}'
                )
                )
            )
            )
        );
    }


    function contractURI() external pure returns (string memory) {
        return 'ar://9Ss1lqwIUVtl_WXqp-bDfx-C4fK6O--DP9Ac0sf6ewM';
        // Arweave version of 'https://degenblues.xyz/projects/degen-blues/contract.json';
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./Encoding.sol";
import "./Metadata.sol";

contract SVG {
    Metadata metadata;

    constructor(Metadata m) {
        metadata = m;
    }
    string internal constant svg1 = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 600 600" fill="none"><style>text{font-size:6px; font-family:Impact,-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Helvetica,Arial,sans-serif,"Apple Color Emoji","Segoe UI Emoji","Segoe UI Symbol";fill:#fff;text-shadow:0 1px 5px rgba(0,0,0,10%)}.svgTokenId{font-size:27px;font-weight: bold}';
    string internal constant svg2 = '</style><defs><linearGradient id="bgGradient" gradientTransform="rotate(90)"><stop offset="0%" class="stop1"/><stop offset="33%" class="stop2"/><stop offset="67%" class="stop3"/><stop offset="100%" class="stop4"/></linearGradient></defs><path d="M0 0h6e2v6e2H0z" fill="url(#bgGradient)"/>';
    string internal constant svg5 = '<svg x="30" y="0" width="100%" height="100%" viewBox="0 0 600 600"><rect width="108.276" height="110" rx="4.34783" fill="#9F0D84"/><rect x="112.609" width="108.276" height="110" rx="4.34783" fill="#5200FF"/><path d="M15.5316 60.4759C16.7895 60.4759 18.0383 61.0957 19.2779 62.3354V53.2021H25.4853V98.7866H19.2779V96.8725C18.3664 98.5132 17.1359 99.3335 15.5863 99.3335C14.2008 99.3335 13.0888 98.9872 12.2502 98.2944C11.4116 97.5834 10.8374 96.6628 10.5274 95.5325C10.2358 94.4023 10.0899 92.9894 10.0899 91.294V68.5428C10.0899 65.9541 10.491 63.967 11.2931 62.5815C12.1135 61.1778 13.5263 60.4759 15.5316 60.4759ZM17.7739 93.8645C18.7766 93.8645 19.2779 93.117 19.2779 91.6222V68.324C19.2779 66.7927 18.7766 66.027 17.7739 66.027C16.8077 66.027 16.3246 66.7927 16.3246 68.324V91.5128C16.3246 93.0806 16.8077 93.8645 17.7739 93.8645ZM37.4899 84.4577H43.6973V91.294C43.6973 92.4972 43.597 93.5454 43.3965 94.4387C43.1959 95.3138 42.8313 96.1432 42.3026 96.9271C41.7922 97.711 41.0083 98.3126 39.951 98.7319C38.8936 99.133 37.5719 99.3335 35.9859 99.3335C34.7098 99.3335 33.6069 99.1877 32.6771 98.896C31.7474 98.6225 30.9999 98.2579 30.4348 97.8022C29.8879 97.3282 29.4504 96.7357 29.1222 96.0247C28.7941 95.2955 28.5753 94.5663 28.4659 93.8371C28.3566 93.0897 28.3019 92.242 28.3019 91.294V68.5428C28.3019 67.5948 28.3566 66.7562 28.4659 66.027C28.5753 65.2796 28.7941 64.5503 29.1222 63.8394C29.4504 63.1102 29.8879 62.5177 30.4348 62.0619C30.9817 61.5879 31.72 61.2051 32.6498 60.9134C33.5977 60.6217 34.7098 60.4759 35.9859 60.4759C37.262 60.4759 38.3649 60.6217 39.2947 60.9134C40.2426 61.2051 40.9901 61.5879 41.537 62.0619C42.1021 62.5177 42.5488 63.1102 42.8769 63.8394C43.205 64.5503 43.4238 65.2796 43.5332 66.027C43.6426 66.7562 43.6973 67.5948 43.6973 68.5428V81.9966H34.5366V91.5128C34.5366 93.0806 35.0197 93.8645 35.9859 93.8645C36.9886 93.8645 37.4899 93.0806 37.4899 91.5128V84.4577ZM34.5366 76.1174H37.4899V68.324C37.4899 66.7927 36.9886 66.027 35.9859 66.027C35.0197 66.027 34.5366 66.7927 34.5366 68.324V76.1174ZM55.7018 96.3802C54.8815 97.5287 53.6509 98.103 52.0102 98.103C50.9529 98.0848 50.0596 97.8933 49.3304 97.5287C48.6012 97.1459 48.036 96.5899 47.635 95.8607C47.2339 95.1315 46.9422 94.3111 46.7599 93.3996C46.5959 92.4699 46.5138 91.3761 46.5138 90.1182V68.5428C46.5138 67.2849 46.5959 66.1911 46.7599 65.2613C46.9422 64.3316 47.2339 63.493 47.635 62.7456C48.036 61.9981 48.6012 61.433 49.3304 61.0501C50.0596 60.6673 50.9529 60.4759 52.0102 60.4759C53.4139 60.4759 54.6445 61.1686 55.7018 62.5541V61.0501H61.8545V97.6108C61.8545 100.163 61.0342 102.105 59.3934 103.435C57.771 104.784 55.7383 105.459 53.2954 105.459C50.9255 105.459 48.7197 104.894 46.6779 103.763L48.8108 99.4156C49.8864 100.035 51.1534 100.345 52.6118 100.345C53.5051 100.345 54.2434 100.145 54.8268 99.7437C55.4101 99.3426 55.7018 98.7046 55.7018 97.8295V96.3802ZM54.1978 92.6886C55.2005 92.6886 55.7018 92.0688 55.7018 90.8291V68.324C55.7018 66.7927 55.2005 66.027 54.1978 66.027C53.177 66.027 52.6665 66.7927 52.6665 68.324V90.3369C52.6665 91.9047 53.177 92.6886 54.1978 92.6886ZM73.8591 84.4577H80.0665V91.294C80.0665 92.4972 79.9662 93.5454 79.7657 94.4387C79.5651 95.3138 79.2005 96.1432 78.6719 96.9271C78.1614 97.711 77.3775 98.3126 76.3202 98.7319C75.2628 99.133 73.9411 99.3335 72.3551 99.3335C71.079 99.3335 69.9761 99.1877 69.0463 98.896C68.1166 98.6225 67.3691 98.2579 66.804 97.8022C66.2571 97.3282 65.8196 96.7357 65.4914 96.0247C65.1633 95.2955 64.9445 94.5663 64.8352 93.8371C64.7258 93.0897 64.6711 92.242 64.6711 91.294V68.5428C64.6711 67.5948 64.7258 66.7562 64.8352 66.027C64.9445 65.2796 65.1633 64.5503 65.4914 63.8394C65.8196 63.1102 66.2571 62.5177 66.804 62.0619C67.3509 61.5879 68.0892 61.2051 69.019 60.9134C69.967 60.6217 71.079 60.4759 72.3551 60.4759C73.6312 60.4759 74.7341 60.6217 75.6639 60.9134C76.6119 61.2051 77.3593 61.5879 77.9062 62.0619C78.4713 62.5177 78.918 63.1102 79.2461 63.8394C79.5743 64.5503 79.793 65.2796 79.9024 66.027C80.0118 66.7562 80.0665 67.5948 80.0665 68.5428V81.9966H70.9058V91.5128C70.9058 93.0806 71.3889 93.8645 72.3551 93.8645C73.3578 93.8645 73.8591 93.0806 73.8591 91.5128V84.4577ZM70.9058 76.1174H73.8591V68.324C73.8591 66.7927 73.3578 66.027 72.3551 66.027C71.3889 66.027 70.9058 66.7927 70.9058 68.324V76.1174ZM92.8641 60.4759C94.8876 60.4759 96.2913 61.1595 97.0752 62.5268C97.8774 63.8941 98.2784 65.8811 98.2784 68.4881V98.7866H92.071V68.324C92.071 66.7927 91.5697 66.027 90.567 66.027C89.6008 66.027 89.1177 66.7927 89.1177 68.324V98.7866H82.883V61.0501H89.1177V62.9917C90.0475 61.3145 91.2963 60.4759 92.8641 60.4759Z" fill="white"/><path d="M134.101 60.4759C136.125 60.4759 137.538 61.1686 138.34 62.5541C139.16 63.9396 139.57 65.9358 139.57 68.5428V91.294C139.57 93.9009 139.169 95.888 138.367 97.2553C137.583 98.6225 136.179 99.3153 134.156 99.3335C132.552 99.3335 131.303 98.5314 130.41 96.9271V98.7866H124.175V53.2021H130.41V62.9917C131.376 61.3145 132.606 60.4759 134.101 60.4759ZM131.859 66.027C130.893 66.027 130.41 66.7927 130.41 68.324V91.5128C130.41 93.0806 130.893 93.8645 131.859 93.8645C132.862 93.8645 133.363 93.0806 133.363 91.5128V68.324C133.363 66.7927 132.862 66.027 131.859 66.027ZM142.387 53.2021H148.622V98.7866H142.387V53.2021ZM156.852 99.4156C154.847 99.4156 153.434 98.7228 152.614 97.3373C151.812 95.9336 151.411 93.9374 151.411 91.3487V61.0501H157.645V91.5128C157.645 93.0441 158.147 93.8098 159.149 93.8098C160.116 93.8098 160.599 93.0441 160.599 91.5128V61.0501H166.806V98.7866H160.599V96.8178C159.633 98.5496 158.384 99.4156 156.852 99.4156ZM178.811 84.4577H185.018V91.294C185.018 92.4972 184.918 93.5454 184.717 94.4387C184.517 95.3138 184.152 96.1432 183.623 96.9271C183.113 97.711 182.329 98.3126 181.272 98.7319C180.214 99.133 178.893 99.3335 177.307 99.3335C176.031 99.3335 174.928 99.1877 173.998 98.896C173.068 98.6225 172.321 98.2579 171.756 97.8022C171.209 97.3282 170.771 96.7357 170.443 96.0247C170.115 95.2955 169.896 94.5663 169.787 93.8371C169.677 93.0897 169.623 92.242 169.623 91.294V68.5428C169.623 67.5948 169.677 66.7562 169.787 66.027C169.896 65.2796 170.115 64.5503 170.443 63.8394C170.771 63.1102 171.209 62.5177 171.756 62.0619C172.303 61.5879 173.041 61.2051 173.971 60.9134C174.919 60.6217 176.031 60.4759 177.307 60.4759C178.583 60.4759 179.686 60.6217 180.616 60.9134C181.563 61.2051 182.311 61.5879 182.858 62.0619C183.423 62.5177 183.87 63.1102 184.198 63.8394C184.526 64.5503 184.745 65.2796 184.854 66.027C184.963 66.7562 185.018 67.5948 185.018 68.5428V81.9966H175.857V91.5128C175.857 93.0806 176.341 93.8645 177.307 93.8645C178.309 93.8645 178.811 93.0806 178.811 91.5128V84.4577ZM175.857 76.1174H178.811V68.324C178.811 66.7927 178.309 66.027 177.307 66.027C176.341 66.027 175.857 66.7927 175.857 68.324V76.1174ZM193.769 71.0038C193.769 71.9153 193.969 72.763 194.37 73.5469C194.789 74.3308 195.3 74.9871 195.902 75.5158C196.521 76.0445 197.187 76.637 197.898 77.2932C198.627 77.9495 199.292 78.6058 199.894 79.2621C200.514 79.9184 201.024 80.7843 201.425 81.8599C201.845 82.9172 202.054 84.1022 202.054 85.4148V92.798C202.054 94.7486 201.48 96.3255 200.331 97.5287C199.183 98.7319 197.351 99.3335 194.835 99.3335C192.301 99.3335 190.451 98.7319 189.284 97.5287C188.135 96.3073 187.561 94.7304 187.561 92.798V84.403H193.769V92.2238C193.769 93.3176 194.124 93.8645 194.835 93.8645C195.51 93.8645 195.847 93.3176 195.847 92.2238V87.0282C195.847 86.0437 195.692 85.1504 195.382 84.3483C195.09 83.5462 194.698 82.8626 194.206 82.2974C193.714 81.7323 193.176 81.1945 192.593 80.6841C192.009 80.1554 191.417 79.5994 190.815 79.016C190.232 78.4326 189.694 77.7946 189.202 77.1018C188.71 76.4091 188.309 75.534 187.999 74.4767C187.707 73.4193 187.561 72.2252 187.561 70.8944V67.0388C187.561 65.1064 188.135 63.5295 189.284 62.308C190.451 61.0866 192.301 60.4759 194.835 60.4759C197.351 60.4759 199.183 61.0866 200.331 62.308C201.48 63.5112 202.054 65.0881 202.054 67.0388V73.1914H195.847V67.6404C195.847 66.5648 195.51 66.027 194.835 66.027C194.124 66.027 193.769 66.5648 193.769 67.6404V71.0038Z" fill="white"/></svg><svg x="186" y="186" width="228" height="228" viewBox="0 0 409 409"><path d="m13 204.11c0-105.54 85.568-191.11 191.11-191.11 105.55 0 191.11 85.567 191.11 191.11 0 105.54-85.561 191.11-191.11 191.11-105.54 0-191.11-85.565-191.11-191.11z" fill="black" fill-opacity=".2" stroke="#fff" stroke-width="26"/><path d="m160.18 294.42 126.37-72.471c17.004-9.754 17.004-25.568 0-35.32l-126.37-72.466c-17.004-9.748-30.781-1.775-30.781 17.827v144.6c0 19.597 13.778 27.584 30.781 17.834z" fill="#fff"/></svg></svg>';
    
    function ethDotsSVG(int32[] memory ethPriceData) internal view returns (string memory) {
        (uint32 high, uint32 low, , ) = metadata.getStats(ethPriceData);

        uint span = high-low;
        string memory str = string(
            abi.encodePacked(
                '<svg x="10%" y="10%" width="80%" height="80%" viewBox="0 0 24 ',
                Encoding.uint2str(span),
                '" preserveAspectRatio="none">'
            )
        );


        for (uint i = 0; i < ethPriceData.length; i++) {
            uint32 hue = hueForPrice(uint32(ethPriceData[i])) + 180 % 360;
            str = string(
                abi.encodePacked(
                    str,
                    '<rect x="',
                    Encoding.uint2str(uint32(i)),
                    '" y="',
                    Encoding.uint2str(uint32(int32(high) - int32(ethPriceData[i]))),
                    '" width="1" height="5%" rx="0.5%" fill="hsl(', Encoding.uint2str(hue), ',100%,70%)"/>'
                )
            );
        }

        str = string(
            abi.encodePacked(
                str,
                '</svg>'
            )
        );
        
        return str;
    }

    function hueForPrice(uint32 price) internal pure returns (uint32) {
        uint32 num = price;
        while (num > 256) { // Bit shift the price until we get the two most significant hexadecimal digits
            num = num >> 1;
        }
        uint32 hue = 4 * (360 * num / 256) % 360;
        return hue;
    }

    function cssBackgroundGradient(int32[] memory ethPriceData) internal view returns (string memory) {
        (uint32 high, uint32 low, , ) = metadata.getStats(ethPriceData);

        uint256 bgHue1 = hueForPrice(high);
        uint256 bgHue2 = hueForPrice(low + 2*(high-low)/3);
        uint256 bgHue3 = hueForPrice(low + 1*(high-low)/3);
        uint256 bgHue4 = hueForPrice(low);

        return string(
            abi.encodePacked(
                '.stop1 { stop-color: hsl(', Encoding.uint2str(bgHue1), ',100%,60%); }',
                '.stop2 { stop-color: hsl(', Encoding.uint2str(bgHue2), ',100%,60%); }',
                '.stop3 { stop-color: hsl(', Encoding.uint2str(bgHue3), ',100%,60%); }',
                '.stop4 { stop-color: hsl(', Encoding.uint2str(bgHue4), ',100%,60%); }'
            )
        );
    }

    function printImageWith(int32[] memory ethPriceData, uint256 tokenId) external view returns (string memory) {

        return string(
            abi.encodePacked(
                svg1,
                cssBackgroundGradient(ethPriceData),
                svg2,
                ethDotsSVG(ethPriceData),
                '<text class="svgTokenId" x="95%" y="9%" text-anchor="end">#',
                Encoding.uint2str(tokenId),
                '</text>',
                svg5));
    }

    function masterImageWith() external pure returns (string memory) {
        return string(
            abi.encodePacked(
                svg1,
                '.stop1 { stop-color: hsl(0,0%,10%); }',
                '.stop2 { stop-color: hsl(0,0%,20%); }',
                svg2,
                '<text class="svgTokenId" x="95%" y="9%" text-anchor="end">#0</text>',
                svg5));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./Encoding.sol";
import "./Base64.sol";
import "./BokkyPooBahsDateTimeContract.sol";

contract Metadata {
    BokkyPooBahsDateTimeContract dates;
    mapping(uint => string) MAJOR_CHORDS;
    mapping(uint => string) JAZZ_MINOR_CHORDS;
    mapping(uint => string) DIMINISHED_CHORDS;
    constructor(BokkyPooBahsDateTimeContract d) {
        dates = d;

        MAJOR_CHORDS[1] = unicode'Maj7';
        MAJOR_CHORDS[2] = unicode'm7';
        MAJOR_CHORDS[4] = unicode'Maj7 ♯11';
        MAJOR_CHORDS[5] = unicode'7';

        JAZZ_MINOR_CHORDS[1] = unicode'm (Maj7)';
        JAZZ_MINOR_CHORDS[2] = unicode'sus7';
        JAZZ_MINOR_CHORDS[4] = unicode'7 ♯11';
        JAZZ_MINOR_CHORDS[5] = unicode'7 ♭13';

        DIMINISHED_CHORDS[1] = unicode'7 ♭9';
        DIMINISHED_CHORDS[2] = unicode'dim7';
        DIMINISHED_CHORDS[4] = unicode'dim7';
        DIMINISHED_CHORDS[5] = unicode'7 ♭9';

    }

    function getStats(int32[] memory ethPriceData) public pure returns (uint32, uint32, uint, uint) {
        uint sum = 0;
        uint32 hi = 0;
        uint32 lo = type(uint32).max;
        uint numValues = 0;
        for (uint i = 0; i < ethPriceData.length; i++) {
            uint32 price = uint32(ethPriceData[i]);
            sum += uint32(price);

            if (price > 0) {
                if (price > hi) {
                    hi = price;
                }
                if (price < lo) {
                    lo = price;
                }
                numValues++;
            }
        }
        uint mean = 0; 
        uint vari = 0; 
        if (numValues > 0) {
            mean = sum/numValues;
            uint deviations = 0;
            for (uint i = 0; i < ethPriceData.length; i++) {
                if (ethPriceData[i] > 0) {
                    int256 delta = ethPriceData[i] - int32(int256(mean));
                    deviations += uint256(delta*delta);
                }
            }
            vari = deviations/numValues;

        }
        return (hi,lo,mean,vari);
    }

    function getVibeAndChordStrings(int32 open, int32 close, uint mean, uint variance) internal view returns (string memory, string memory, string memory) {
        string memory volaStr = '';
        uint vola = 0;
        uint mode = 0;
        if (mean > 0) {
            vola = 100*variance/mean;
        }
        if (vola < 50) {
            mode = 1;
            volaStr = 'Normal';
        } else if (vola < 75) {
            mode = 2;
            volaStr = 'High';
        } else if (vola < 100) {
            mode = 4;
            volaStr = 'Very high';
        } else {
            mode = 5;
            volaStr = 'Extreme';
        }

        int32 delta = close - open;
        int32 increase = 0;
        if (open > 0) {
            increase = 100*delta/open; /*pct*/
        }
        string memory vibeStr = '';
        string memory chordStr = '';

        if (increase < -5) {
            vibeStr = "DOOM";
            chordStr = DIMINISHED_CHORDS[mode];
        } else if (increase < 5) {
            vibeStr = "HODL";
            chordStr = JAZZ_MINOR_CHORDS[mode];
        } else {
            vibeStr = "MOON";
            chordStr = MAJOR_CHORDS[mode];
        }
        

        return (vibeStr, chordStr, volaStr);
    }

    function getAttributes(int32[] memory ethPriceData, uint fromTimestamp) external view returns (string memory) {
        (uint32 high, uint32 low, uint mean, uint variance) = getStats(ethPriceData);

        int32 open = 0;
        int32 close = 0;
         for (uint i = 0; i < ethPriceData.length; i++) {
            if (open == 0) {
                open = ethPriceData[i];
            }
            if (ethPriceData[i] > 0) {
                close = ethPriceData[i];
            }
        }
            
        (string memory vibeStr, string memory chordStr, string memory volaStr) = getVibeAndChordStrings(open, close, mean, variance); 
        return string(
            abi.encodePacked(
                '[',
                '{',
                    '"display_type": "date",',
                    '"trait_type": "Date (UTC)",',
                    '"value": ', Encoding.uint2str(fromTimestamp),
                '},',
                '{',
                    '"trait_type": "Vibe",',
                    '"value": "', vibeStr, '"',
                '},',
                '{',
                    '"trait_type": "Volatility",',
                    '"value": "', volaStr, '"',
                '},',
                '{',
                    '"trait_type": "Chord",',
                    '"value": "', chordStr, '"',
                '},',
                '{',
                    '"trait_type": "High",',
                    '"value": ', Encoding.uint2str(high),
                '},',
                '{',
                    '"trait_type": "Low",',
                    '"value": ', Encoding.uint2str(low),
                '}',

                ']'
            ));
    }

    function getAnimationUrl(string memory ethPriceDataString, string memory btcPriceDataString) public pure returns (string memory) {
        return string(
                abi.encodePacked(
                    'ar://ef9QIeEVW94Rb-GM_bb-jISEXzp21aLlN9wyhCbxFng/?',
                    // Arweave version of 'https://degenblues.xyz/projects/degen-blues/r?'
                    'ETH=', ethPriceDataString,
                    '&BTC=', btcPriceDataString
                )
            );
    }

    function getNameForTokenId(uint256 tokenId) public pure returns (string memory) {
        if (tokenId == 0) {
            return "Degen Blues Edition Zero";
        } else {
            return string(
                abi.encodePacked(
                    "Degen Blues #",
                    Encoding.uint2str(tokenId)
                )
            );
        }
    }

    function dateToString(uint timestamp) public view returns (string memory) {
        uint year = dates.getYear(timestamp);
        uint month = dates.getMonth(timestamp);
        uint day = dates.getDay(timestamp);

        string memory displayDate = string(
            abi.encodePacked(
                Encoding.uint2str(month), '/', Encoding.uint2str(day), '/', Encoding.uint2str(year)
            ));
        return displayDate;
    }

    function descriptionForTokenId(uint256 tokenId, uint fromTimestamp) external view returns (string memory) {
        string memory displayDate = dateToString(fromTimestamp);

        return (tokenId == 0) ? 
            'Edition Zero is a one-of-a-kind NFT from the Degen Blues connection. The melody is dynamically generated on-chain Ethereum price data from the last 48 hours. Refresh metadata every 30 minutes to hear a fresh melody.' :
            string(
                abi.encodePacked(
                    'Degen Blues is a collection of NFTs dynamically generated from on-chain price data. This melody was generated based on movements of the Ethereum price on ',
                    displayDate,
                    '.'
                )
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Base64.sol";

library Encoding {

    function encode(int32[] memory prices) internal pure returns (string memory) {
        uint256 encodedLen = prices.length * 3;

        // Round up to the nearest length divisible by 4. Otherwise it's not a valid base64 string
        if (encodedLen % 4 > 0) {
            encodedLen += (4 - (encodedLen % 4));
        }
        bytes memory data = new bytes(encodedLen);
        uint80 i;

        for (i = 0; i < prices.length; i++) {
            int32 price = prices[i];
            
            int32 lgByte = (price >> 12) % 64;
            int32 medByte = (price >> 6) % 64;
            int32 smByte = price % 64;

            data[3*i] = Base64.TABLE[uint32(lgByte)];
            data[3*i + 1] = Base64.TABLE[uint32(medByte)];
            data[3*i + 2] = Base64.TABLE[uint32(smByte)];
        }  
        for (i = uint80(3*prices.length); i < encodedLen; i++) {
            data[i] = '='; // ASCII '='
        }
        return string(data);
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface DegenFetcherInterface{
	function fetchPriceDataForFeed(address feedAddress, uint fromTimestamp, uint80 daysToFetch, uint dataPointsToFetchPerDay) external view returns (int32[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.01
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
// ----------------------------------------------------------------------------

library BokkyPooBahsDateTimeLibrary {

    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_MINUTE = 60;
    int constant OFFSET19700101 = 2440588;

    uint constant DOW_MON = 1;
    uint constant DOW_TUE = 2;
    uint constant DOW_WED = 3;
    uint constant DOW_THU = 4;
    uint constant DOW_FRI = 5;
    uint constant DOW_SAT = 6;
    uint constant DOW_SUN = 7;

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(uint year, uint month, uint day) internal pure returns (uint _days) {
        require(year >= 1970);
        int _year = int(year);
        int _month = int(month);
        int _day = int(day);

        int __days = _day
          - 32075
          + 1461 * (_year + 4800 + (_month - 14) / 12) / 4
          + 367 * (_month - 2 - (_month - 14) / 12 * 12) / 12
          - 3 * ((_year + 4900 + (_month - 14) / 12) / 100) / 4
          - OFFSET19700101;

        _days = uint(__days);
    }

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function timestampFromDate(uint year, uint month, uint day) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }
    function timestampFromDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR + minute * SECONDS_PER_MINUTE + second;
    }
    function timestampToDate(uint timestamp) internal pure returns (uint year, uint month, uint day) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function timestampToDateTime(uint timestamp) internal pure returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    function isValidDate(uint year, uint month, uint day) internal pure returns (bool valid) {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }
    function isValidDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (bool valid) {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }
    function isLeapYear(uint timestamp) internal pure returns (bool leapYear) {
        (uint year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }
    function _isLeapYear(uint year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }
    function isWeekDay(uint timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }
    function isWeekEnd(uint timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }
    function getDaysInMonth(uint timestamp) internal pure returns (uint daysInMonth) {
        (uint year, uint month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }
    function _getDaysInMonth(uint year, uint month) internal pure returns (uint daysInMonth) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }
    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint timestamp) internal pure returns (uint dayOfWeek) {
        uint _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = (_days + 3) % 7 + 1;
    }

    function getYear(uint timestamp) internal pure returns (uint year) {
        (year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getMonth(uint timestamp) internal pure returns (uint month) {
        (,month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getDay(uint timestamp) internal pure returns (uint day) {
        (,,day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getHour(uint timestamp) internal pure returns (uint hour) {
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }
    function getMinute(uint timestamp) internal pure returns (uint minute) {
        uint secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }
    function getSecond(uint timestamp) internal pure returns (uint second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = (month - 1) % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }
    function addMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }
    function addSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    function subYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = yearMonth % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }
    function subMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }
    function subSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _years) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear,,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear,,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }
    function diffMonths(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _months) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear, uint fromMonth,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear, uint toMonth,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }
    function diffDays(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }
    function diffHours(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _hours) {
        require(fromTimestamp <= toTimestamp);
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }
    function diffMinutes(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _minutes) {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }
    function diffSeconds(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _seconds) {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.00 - Contract Instance
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018.
//
// GNU Lesser General Public License 3.0
// https://www.gnu.org/licenses/lgpl-3.0.en.html
// ----------------------------------------------------------------------------

import "./BokkyPooBahsDateTimeLibrary.sol";

contract BokkyPooBahsDateTimeContract {
    uint public constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint public constant SECONDS_PER_HOUR = 60 * 60;
    uint public constant SECONDS_PER_MINUTE = 60;
    int public constant OFFSET19700101 = 2440588;

    uint public constant DOW_MON = 1;
    uint public constant DOW_TUE = 2;
    uint public constant DOW_WED = 3;
    uint public constant DOW_THU = 4;
    uint public constant DOW_FRI = 5;
    uint public constant DOW_SAT = 6;
    uint public constant DOW_SUN = 7;

    // function _now() public view returns (uint timestamp) {
    //     timestamp = now;
    // }
    // function _nowDateTime() public view returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
    //     (year, month, day, hour, minute, second) = BokkyPooBahsDateTimeLibrary.timestampToDateTime(now);
    // }
    function _daysFromDate(uint year, uint month, uint day) public pure returns (uint _days) {
        return BokkyPooBahsDateTimeLibrary._daysFromDate(year, month, day);
    }
    function _daysToDate(uint _days) public pure returns (uint year, uint month, uint day) {
        return BokkyPooBahsDateTimeLibrary._daysToDate(_days);
    }
    function timestampFromDate(uint year, uint month, uint day) public pure returns (uint timestamp) {
        return BokkyPooBahsDateTimeLibrary.timestampFromDate(year, month, day);
    }
    function timestampFromDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) public pure returns (uint timestamp) {
        return BokkyPooBahsDateTimeLibrary.timestampFromDateTime(year, month, day, hour, minute, second);
    }
    function timestampToDate(uint timestamp) public pure returns (uint year, uint month, uint day) {
        (year, month, day) = BokkyPooBahsDateTimeLibrary.timestampToDate(timestamp);
    }
    function timestampToDateTime(uint timestamp) public pure returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
        (year, month, day, hour, minute, second) = BokkyPooBahsDateTimeLibrary.timestampToDateTime(timestamp);
    }

    function isValidDate(uint year, uint month, uint day) public pure returns (bool valid) {
        valid = BokkyPooBahsDateTimeLibrary.isValidDate(year, month, day);
    }
    function isValidDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) public pure returns (bool valid) {
        valid = BokkyPooBahsDateTimeLibrary.isValidDateTime(year, month, day, hour, minute, second);
    }
    function isLeapYear(uint timestamp) public pure returns (bool leapYear) {
        leapYear = BokkyPooBahsDateTimeLibrary.isLeapYear(timestamp);
    }
    function _isLeapYear(uint year) public pure returns (bool leapYear) {
        leapYear = BokkyPooBahsDateTimeLibrary._isLeapYear(year);
    }
    function isWeekDay(uint timestamp) public pure returns (bool weekDay) {
        weekDay = BokkyPooBahsDateTimeLibrary.isWeekDay(timestamp);
    }
    function isWeekEnd(uint timestamp) public pure returns (bool weekEnd) {
        weekEnd = BokkyPooBahsDateTimeLibrary.isWeekEnd(timestamp);
    }

    function getDaysInMonth(uint timestamp) public pure returns (uint daysInMonth) {
        daysInMonth = BokkyPooBahsDateTimeLibrary.getDaysInMonth(timestamp);
    }
    function _getDaysInMonth(uint year, uint month) public pure returns (uint daysInMonth) {
        daysInMonth = BokkyPooBahsDateTimeLibrary._getDaysInMonth(year, month);
    }
    function getDayOfWeek(uint timestamp) public pure returns (uint dayOfWeek) {
        dayOfWeek = BokkyPooBahsDateTimeLibrary.getDayOfWeek(timestamp);
    }

    function getYear(uint timestamp) public pure returns (uint year) {
        year = BokkyPooBahsDateTimeLibrary.getYear(timestamp);
    }
    function getMonth(uint timestamp) public pure returns (uint month) {
        month = BokkyPooBahsDateTimeLibrary.getMonth(timestamp);
    }
    function getDay(uint timestamp) public pure returns (uint day) {
        day = BokkyPooBahsDateTimeLibrary.getDay(timestamp);
    }
    function getHour(uint timestamp) public pure returns (uint hour) {
        hour = BokkyPooBahsDateTimeLibrary.getHour(timestamp);
    }
    function getMinute(uint timestamp) public pure returns (uint minute) {
        minute = BokkyPooBahsDateTimeLibrary.getMinute(timestamp);
    }
    function getSecond(uint timestamp) public pure returns (uint second) {
        second = BokkyPooBahsDateTimeLibrary.getSecond(timestamp);
    }

    function addYears(uint timestamp, uint _years) public pure returns (uint newTimestamp) {
        newTimestamp = BokkyPooBahsDateTimeLibrary.addYears(timestamp, _years);
    }
    function addMonths(uint timestamp, uint _months) public pure returns (uint newTimestamp) {
        newTimestamp = BokkyPooBahsDateTimeLibrary.addMonths(timestamp, _months);
    }
    function addDays(uint timestamp, uint _days) public pure returns (uint newTimestamp) {
        newTimestamp = BokkyPooBahsDateTimeLibrary.addDays(timestamp, _days);
    }
    function addHours(uint timestamp, uint _hours) public pure returns (uint newTimestamp) {
        newTimestamp = BokkyPooBahsDateTimeLibrary.addHours(timestamp, _hours);
    }
    function addMinutes(uint timestamp, uint _minutes) public pure returns (uint newTimestamp) {
        newTimestamp = BokkyPooBahsDateTimeLibrary.addMinutes(timestamp, _minutes);
    }
    function addSeconds(uint timestamp, uint _seconds) public pure returns (uint newTimestamp) {
        newTimestamp = BokkyPooBahsDateTimeLibrary.addSeconds(timestamp, _seconds);
    }

    function subYears(uint timestamp, uint _years) public pure returns (uint newTimestamp) {
        newTimestamp = BokkyPooBahsDateTimeLibrary.subYears(timestamp, _years);
    }
    function subMonths(uint timestamp, uint _months) public pure returns (uint newTimestamp) {
        newTimestamp = BokkyPooBahsDateTimeLibrary.subMonths(timestamp, _months);
    }
    function subDays(uint timestamp, uint _days) public pure returns (uint newTimestamp) {
        newTimestamp = BokkyPooBahsDateTimeLibrary.subDays(timestamp, _days);
    }
    function subHours(uint timestamp, uint _hours) public pure returns (uint newTimestamp) {
        newTimestamp = BokkyPooBahsDateTimeLibrary.subHours(timestamp, _hours);
    }
    function subMinutes(uint timestamp, uint _minutes) public pure returns (uint newTimestamp) {
        newTimestamp = BokkyPooBahsDateTimeLibrary.subMinutes(timestamp, _minutes);
    }
    function subSeconds(uint timestamp, uint _seconds) public pure returns (uint newTimestamp) {
        newTimestamp = BokkyPooBahsDateTimeLibrary.subSeconds(timestamp, _seconds);
    }

    function diffYears(uint fromTimestamp, uint toTimestamp) public pure returns (uint _years) {
        _years = BokkyPooBahsDateTimeLibrary.diffYears(fromTimestamp, toTimestamp);
    }
    function diffMonths(uint fromTimestamp, uint toTimestamp) public pure returns (uint _months) {
        _months = BokkyPooBahsDateTimeLibrary.diffMonths(fromTimestamp, toTimestamp);
    }
    function diffDays(uint fromTimestamp, uint toTimestamp) public pure returns (uint _days) {
        _days = BokkyPooBahsDateTimeLibrary.diffDays(fromTimestamp, toTimestamp);
    }
    function diffHours(uint fromTimestamp, uint toTimestamp) public pure returns (uint _hours) {
        _hours = BokkyPooBahsDateTimeLibrary.diffHours(fromTimestamp, toTimestamp);
    }
    function diffMinutes(uint fromTimestamp, uint toTimestamp) public pure returns (uint _minutes) {
        _minutes = BokkyPooBahsDateTimeLibrary.diffMinutes(fromTimestamp, toTimestamp);
    }
    function diffSeconds(uint fromTimestamp, uint toTimestamp) public pure returns (uint _seconds) {
        _seconds = BokkyPooBahsDateTimeLibrary.diffSeconds(fromTimestamp, toTimestamp);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return '';

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}