// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";

import "./AggregatorV3Interface.sol";
import "./KeeperCompatible.sol";

import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";

import "./console.sol";

contract MyNftWeek5 is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable, VRFConsumerBaseV2, KeeperCompatibleInterface  {
    using Counters for Counters.Counter;


    Counters.Counter private _tokenIdCounter;


    uint public interval = 10;

    string nftName = "Week5 NFT of Alchemy";
    string nftDescript = "Alchemy the road goto the web3 week5 NFT contract.";
    uint64 s_subscriptionId = 19556;
    // https://rinkeby.etherscan.io/address/0xECe365B379E1dD183B20fc5f022230C044d51404
    address curPriceFeed = 0xcf0f51ca2cDAecb464eeE4227f5295F2384F84ED;  //BNB
    //  image
    string[] UpTestNftInfo = [
        "https://gateway.pinata.cloud/ipfs/QmTWVyR7C4Yq9kxgXSsjp6rLHfbzGP4R9PpLmayNjws5pd",
        "https://gateway.pinata.cloud/ipfs/QmTb9yHVuE7RbP1LruPYxv6fkojV8X26dLN6nr8VwP9jST",
        "https://gateway.pinata.cloud/ipfs/QmRzWGB8kgpfwivQgDSkpKqHoDY9uHFKD9ntPViai9JZ27"
    ];
    string[] DownTestNftInfo = [
        "https://gateway.pinata.cloud/ipfs/QmfNDp4ai7KBYUMcxShHbaSYQjHXYhhDo1aV36Q6H3wf4w",
        "https://gateway.pinata.cloud/ipfs/QmapyDiE9LsYmWdsojg9MmUreXpy6Qu7hfD24ZQVT3mK7f",
        "https://gateway.pinata.cloud/ipfs/QmfNDp4ai7KBYUMcxShHbaSYQjHXYhhDo1aV36Q6H3wf4w"
    ];


    AggregatorV3Interface public priceFeed;


    uint public lastTimeStamp;

    int256 public currentPrice;



    // random
    VRFCoordinatorV2Interface COORDINATOR;

    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    address vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;

    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    bytes32 keyHash = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;

    uint32 callbackGasLimit = 100000;

    uint16 requestConfirmations = 3;

    uint32 numWords =  2;
    uint256[] public s_randomWords;
    uint256 public s_requestId;



    event TokensUpdated(string marketTrend);

    constructor() ERC721(nftDescript, nftName) VRFConsumerBaseV2(vrfCoordinator) {
        
        priceFeed = AggregatorV3Interface(curPriceFeed);   

        lastTimeStamp = block.timestamp;


        currentPrice = getLatestPrice();

        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    }

    function safeMint(address _to) public {
        uint256 tokenId = _tokenIdCounter.current();

        _tokenIdCounter.increment();

        _safeMint(_to, tokenId);

        string memory defaultUri = UpTestNftInfo[s_randomWords[0]%3];
        _setTokenURI(tokenId, defaultUri);

        console.log(
            "DONE!!! minted token ",
            tokenId,
            " and assigned token url: ",
            defaultUri
        );
    }

    function checkUpkeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory /*performData*/){
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
    }

    function performUpkeep(bytes calldata) external override{
        if((block.timestamp - lastTimeStamp) > interval){
            lastTimeStamp = block.timestamp;
            int latestPrice = getLatestPrice();

            if(latestPrice == currentPrice){
                return;
            }else if(latestPrice < currentPrice){
                updateAllTokenUris("DOWN");
            }else{
                updateAllTokenUris("UP");
            }

            currentPrice = latestPrice;
        }
    }

    function getLatestPrice() public view returns(int256){
        (,
        int price,
        ,
        ,) = priceFeed.latestRoundData();
        return price;
    }

    function updateAllTokenUris(string memory trend) internal{
        if(compareStrings("DOWN", trend)){
            for(uint i=0; i< _tokenIdCounter.current(); i++){
                _setTokenURI(i,DownTestNftInfo[s_randomWords[0]%3]);
            }
        }else {
            for(uint i=0; i< _tokenIdCounter.current(); i++){
                _setTokenURI(i,UpTestNftInfo[s_randomWords[0]%3]);
            }
        }

        emit TokensUpdated(trend);
    }

    function setInterval(uint256 newInterval) public onlyOwner{
        interval = newInterval;
    }

    function setPriceFeed(address newFeed) public onlyOwner{
        priceFeed = AggregatorV3Interface(newFeed);
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool){
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function requestRandomWords() external onlyOwner {
        s_requestId = COORDINATOR.requestRandomWords(
        keyHash,
        s_subscriptionId,
        requestConfirmations,
        callbackGasLimit,
        numWords
        );
    }

    function fulfillRandomWords(
        uint256, 
        uint256[] memory randomWords
    ) internal override {
        s_randomWords = randomWords;
    }
}