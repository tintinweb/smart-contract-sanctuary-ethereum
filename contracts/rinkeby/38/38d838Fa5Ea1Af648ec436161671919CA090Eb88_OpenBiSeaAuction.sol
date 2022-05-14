// SPDX-License-Identifier: UNLICENSED
// (c) Oleksii Vynogradov 2021, All rights reserved, contact [email protected] if you like to use code
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";


import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IOpenBiSea.sol";

contract OpenBiSeaAuction is Ownable,IERC721Receiver,IERC1155Receiver {

//    uint256 public totalIncomeNFT;
    uint256 public auctionsCount;

    address public openBiSeaMainContract;

    bool public needOBSForAuction = false;
    uint256 public minimalOBSforAuctionCreation = 10000; // need multiplier to decimals OBS support

    constructor (address _openBiSeaMainContract) {
        openBiSeaMainContract = _openBiSeaMainContract;
    }
    mapping(address => uint256) public tokenPriceToMainCoin; // mul 10 ** 18 for value, total += COIN_VALUE.mul(10 ** 18).div(tokenPriceToMainCoin[token]

    mapping(address => uint256) public consumersRevenueAmount;

    using SafeMath for uint256;

    mapping(uint => address) contractsWhitelisted;
    uint contractsWhitelistedCount;

    function _setNeedOBSForAuction(bool _needOBSForAuction) public onlyOwner {
        needOBSForAuction = _needOBSForAuction;
    }

    function _setMinimalOBSforAuctionCreation(uint256 _minimalOBSforAuctionCreation) public onlyOwner {
        minimalOBSforAuctionCreation = _minimalOBSforAuctionCreation;
    }

    function getTokenPriceToMainCoin(address token) public view returns (uint256) {
        return tokenPriceToMainCoin[token];
    }

    function _tokenPriceToMainCoin(address token, uint256 price) public onlyOwner {
        tokenPriceToMainCoin[token] = price;
    }

    function isContractNFTWhitelisted( address contractNFT ) public view returns (bool) {
        return (indexOfContractsWhitelisted(contractNFT) != type(uint256).max);
    }

    function contractsNFTWhitelisted() public view returns (address[] memory) {
        address[] memory contractsNFTWhitelistedReturn = new address[] (contractsWhitelistedCount);
        for (uint i=0; i< contractsWhitelistedCount; i++) {
            contractsNFTWhitelistedReturn[i] = contractsWhitelisted[i];
        }
        return contractsNFTWhitelistedReturn;
    }

    function indexOfContractsWhitelisted(address addressLooking) public view returns (uint256) {
        for (uint i=0; i< contractsWhitelistedCount; i++) {
            if (contractsWhitelisted[i] == addressLooking) {
                return i;
            }
        }
        return type(uint256).max;
    }

    event ContractNFTWhitelisted(address indexed contractNFT);

    function whitelistContractAdmin(address contractNFT) public onlyOwner {
        require(!isContractNFTWhitelisted(contractNFT), "OpenBiSeaAuction: contract whitelisted already");
        contractsWhitelisted[contractsWhitelistedCount] = contractNFT;
        contractsWhitelistedCount++;
        emit ContractNFTWhitelisted(contractNFT);
    }

    function whitelistContractAdminBatch(address[] memory contracts) public onlyOwner {
        for (uint i=0; i< contracts.length; i++) {
            whitelistContractAdmin(contracts[i]);
        }
    }

    event ContractNFTDeWhitelisted(address indexed contractNFT);

    function deWhitelistContractAdmin(address contractNFT) public onlyOwner {
        if (indexOfContractsWhitelisted(contractNFT) != type(uint256).max) delete contractsWhitelisted[indexOfContractsWhitelisted(contractNFT)];
        emit ContractNFTDeWhitelisted(contractNFT);
    }

    function whitelistContractCreator(address contractNFT) public {
        require(msg.sender == openBiSeaMainContract, "OpenBiSeaAuction: only main contract can send it");
        contractsWhitelisted[contractsWhitelistedCount] = contractNFT;
        contractsWhitelistedCount++;
        emit ContractNFTWhitelisted(contractNFT);
    }

    function whitelistContractCreatorTokens(address contractNFT) public {
        require(msg.sender == openBiSeaMainContract, "OpenBiSeaAuction: only main contract can send it");
        contractsWhitelisted[contractsWhitelistedCount] = contractNFT;
        contractsWhitelistedCount++;
        emit ContractNFTWhitelisted(contractNFT);
    }

    struct Auction {
        address seller;
        address latestBidder;
        uint256 latestBidTime;
        uint256 deadline;
        uint256 price;
        address token;
        bool isERC1155;
    }

    mapping(uint256 => Auction) public contractsPlusTokenIdsAuction;  // auctions (index -> NFT contract address plus tokenID))

    mapping(address => uint256[]) public contractsTokenIdList; // all tokenIDs per contract

//    mapping(address => uint256) public consumersDealFirstDate;
    mapping(uint256 => address) public auctionIDtoSellerAddress;

    struct NFTData {
        string nftURI;
        uint256 nftID;
        address nftContract;
    }

    bytes4 constant InterfaceSignature_ERC721Enumerable =
    bytes4(keccak256('totalSupply()')) ^
    bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) ^
    bytes4(keccak256('tokenByIndex(uint256)'));

    bytes4 constant InterfaceSignature_ERC20_PlusOptions =
    bytes4(keccak256('name()')) ^
    bytes4(keccak256('symbol()')) ^
    bytes4(keccak256('decimals()')) ^
    bytes4(keccak256('totalSupply()')) ^
    bytes4(keccak256('balanceOf(address)')) ^
    bytes4(keccak256('transfer(address,uint256)')) ^
    bytes4(keccak256('transferFrom(address,address,uint256)')) ^
    bytes4(keccak256('approve(address,uint256)')) ^
    bytes4(keccak256('allowance(address,address)'));

    function getNFTon(address wallet) public view returns (NFTData[] memory) {
        address[] memory contractsNFT = contractsNFTWhitelisted();
        uint nftListCount;
        for (uint i=0; i< contractsNFT.length; i++) {
            if (IERC721(contractsNFT[i]).supportsInterface(InterfaceSignature_ERC721Enumerable)) {
                uint balance = IERC721(contractsNFT[i]).balanceOf(wallet);
                if (balance > 0) {
                    while (balance > 0) {
                        balance--;
                        nftListCount++;
                    }
                }
            }
        }
        NFTData[] memory nftList = new NFTData[](nftListCount);
        uint finalCount;
        for (uint i=0; i< contractsNFT.length; i++) {
            uint balance = IERC721(contractsNFT[i]).balanceOf(wallet);
            if (balance > 0) {
                if (IERC721(contractsNFT[i]).supportsInterface(InterfaceSignature_ERC721Enumerable)) {
                    while (balance > 0) {
                        balance--;
                        uint256 tokenId = IERC721Enumerable(contractsNFT[i]).tokenOfOwnerByIndex(wallet, balance);
                        nftList[finalCount] = NFTData({
                            nftURI:IERC721Metadata(contractsNFT[i]).tokenURI(tokenId),
                            nftID:tokenId,
                            nftContract:contractsNFT[i]
                        });
                        finalCount++;
                    }
                }
            }
        }
        return nftList;
    }


    struct AuctionFullData {
        Auction auction;
        string nftURI;
        uint256 nftID;
        address nftContract;
        string tokenSymbol;
        uint8 tokenDecimals;
    }

    function getNFTsAuctionList(address contractNFT) public view returns (AuctionFullData[] memory) {
        AuctionFullData[] memory auctionList = new AuctionFullData[](contractsTokenIdList[contractNFT].length);
        for (uint i=0; i< contractsTokenIdList[contractNFT].length; i++) {
            uint256 tokenId = contractsTokenIdList[contractNFT][i];
            uint256 index = addressPlusTokenId(contractNFT, tokenId);
            string memory tokenURI;
            if (contractsPlusTokenIdsAuction[index].isERC1155) tokenURI = IERC1155MetadataURI(contractNFT).uri(tokenId);
            else tokenURI = IERC721Metadata(contractNFT).tokenURI(tokenId);
            string memory tokenSymbol;
            uint8 tokenDecimals = 18;
            if (contractsPlusTokenIdsAuction[index].token != address (0x0)) {
                tokenSymbol = IERC20Metadata(contractsPlusTokenIdsAuction[index].token).symbol();
                tokenDecimals = IERC20Metadata(contractsPlusTokenIdsAuction[index].token).decimals();
            }

            auctionList[i] = AuctionFullData({
                auction: contractsPlusTokenIdsAuction[index],
                nftURI:tokenURI,
                nftID:tokenId,
                nftContract:contractNFT,
                tokenSymbol: tokenSymbol,
                tokenDecimals: tokenDecimals
            });
        }
        return auctionList;
    }

    function getAllAuctionsList() public view returns (AuctionFullData[] memory) {
        AuctionFullData[] memory auctionList = new AuctionFullData[](auctionsCount);
        uint index;
        for (uint i=0; i< contractsWhitelistedCount; i++) {
            AuctionFullData[] memory auctionListContract = getNFTsAuctionList(contractsWhitelisted[i]);
            uint j=0;
            while (j < auctionListContract.length) {
                auctionList[index++] = auctionListContract[j++];
            }
        }
        return auctionList;
    }

    function indexOfNFTsAuctionList(address contractNFT, uint256 tokenId) public view returns (uint256) {
        for (uint i=0; i< contractsTokenIdList[contractNFT].length; i++) {
            if (contractsTokenIdList[contractNFT][i] == tokenId) {
                return i;
            }
        }
        return type(uint256).max;
    }

    function contractsTokenIdsListUpdated(address contractNFT, uint256 removedPosition) public view returns (uint256[] memory) {
        uint256[] memory array = new uint256[] (contractsTokenIdList[contractNFT].length - 1);
        uint arrayCount;
        for (uint i=0; i< contractsTokenIdList[contractNFT].length; i++) {
            if (contractsTokenIdList[contractNFT][i] != removedPosition) {
                array[arrayCount] = contractsTokenIdList[contractNFT][i];
                arrayCount++;
            }
        }
        return array;
    }


    function sellerAddressFor(uint256 auctionID) public view returns (address) {
        return auctionIDtoSellerAddress[auctionID];
    }

    function revenueFor(address consumer) public view returns (uint256) {
        return consumersRevenueAmount[consumer];
    }

    function zeroingRevenueFor(address consumer) public  {
        require(msg.sender == openBiSeaMainContract, "OpenBiSeaAuction: only main contract can send it");
        consumersRevenueAmount[consumer] = 0;
    }

    function addressPlusTokenId(address addressTo, uint256 tokenId) public view returns (uint256) {
        return uint256(bytes32(uint256(uint160(addressTo)) << 96)).add(tokenId);
    }

    function getAuction(
        address contractNFT,
        uint256 tokenId
    ) public view returns
    (
        address seller,
        address latestBidder,
        uint256 latestBidTime,
        uint256 deadline,
        uint price,
        address token,
        string memory tokenSymbol,
        uint tokenDecimals
    ) {
        uint256 index = addressPlusTokenId(contractNFT, tokenId);
        string memory symbol;
        uint decimals;

        if (contractsPlusTokenIdsAuction[index].token != address(0x0)) {
            symbol = IERC20Metadata(contractsPlusTokenIdsAuction[index].token).symbol();
            decimals = IERC20Metadata(contractsPlusTokenIdsAuction[index].token).decimals();
        }
        return (
            contractsPlusTokenIdsAuction[index].seller,
            contractsPlusTokenIdsAuction[index].latestBidder,
            contractsPlusTokenIdsAuction[index].latestBidTime,
            contractsPlusTokenIdsAuction[index].deadline,
            contractsPlusTokenIdsAuction[index].price,
            contractsPlusTokenIdsAuction[index].token,
            symbol,
            decimals
        );
    }

    event AuctionNFTCreated(address indexed contractNFT, uint256 tokenId,uint256 price,uint256 deadline, bool isERC1155,address seller, address token);

    function createAuction(
        address contractNFT,
        uint256 tokenId,
        uint256 price,
        uint256 deadline,
        bool isERC1155,
        address sender,
        address token
    ) public {
        require(msg.sender == openBiSeaMainContract, "OpenBiSeaAuction: only main contract can send it");
        require(isContractNFTWhitelisted(contractNFT), "OpenBiSeaAuction: contract must be whitelisted");
        require(indexOfNFTsAuctionList(contractNFT, tokenId) == type(uint256).max, "OpenBiSeaAuction: auction is already created");  //contractsTokenIdsList[contractNFT].contains(uint256(sender).add(tokenId))
        if (needOBSForAuction) require(IERC20(IOpenBiSea(openBiSeaMainContract).getTokenOBS()).balanceOf(sender) >= (10 ** uint256(18)).mul(minimalOBSforAuctionCreation).div(10000), "OpenBiSeaAuction: you must have minimal OBS on account to start");
        if (isERC1155) {
            IERC1155(contractNFT).safeTransferFrom( sender, address(this), tokenId,1, "0x0");
        } else {
            IERC721(contractNFT).safeTransferFrom( sender, address(this), tokenId);
        }
        if (token != address(0x0)) require(bytes(IERC20Metadata(token).symbol()).length > 0, "OpenBiSeaAuction: contract token must be ERC20 compliant with symbol()");

        Auction memory _auction = Auction({
            seller: sender,
            latestBidder: address(0),
            latestBidTime: 0,
            deadline: deadline,
            price: price,
            token: token,
            isERC1155:isERC1155
        });
        contractsPlusTokenIdsAuction[addressPlusTokenId(contractNFT,tokenId)] = _auction;
        auctionsCount++;
        auctionIDtoSellerAddress[addressPlusTokenId(sender, tokenId)] = sender;

        contractsTokenIdList[contractNFT].push(tokenId);

        emit AuctionNFTCreated(contractNFT, tokenId, price, deadline, isERC1155, sender, token);
    }


    function updateFirstDateAndValue(address buyer, address seller, uint256 value, address token) private {
        if (token == address (0x0) || IOpenBiSea(openBiSeaMainContract).getUsdContract() == token || tokenPriceToMainCoin[token] > 0) { // only usd or main coin can add income value
            uint256 valueFinal = value;
            if (IOpenBiSea(openBiSeaMainContract).getUsdContract() == token) {
                uint256 priceMainToUSD;
                uint8 decimals;
                if (IOpenBiSea(openBiSeaMainContract).getOracleContract().getIsOracle()) (priceMainToUSD,decimals) = IOpenBiSea(openBiSeaMainContract).getOracleContract().getLatestPrice();
                else {
                    priceMainToUSD =  IOpenBiSea(openBiSeaMainContract).getMainCoinToUSD();
                    decimals = 18;
                }
                valueFinal = value.mul(10 ** decimals).div(priceMainToUSD);
            }
            if (tokenPriceToMainCoin[token] > 0) valueFinal = value.mul(10 ** 18).div(tokenPriceToMainCoin[token]);
            consumersRevenueAmount[buyer] = consumersRevenueAmount[buyer].add(valueFinal.div(2));
            consumersRevenueAmount[seller] = consumersRevenueAmount[seller].add(valueFinal.div(2));
        }
    }


    event AuctionNFTBid(address indexed contractNFT, uint256 tokenId,uint256 price,uint256 deadline, bool isERC1155,address buyer,address seller, bool isDeal, address token);

    function _bidWin (
        Auction memory auction,
        address contractNFT,
        address sender,
        uint256 tokenId,
        uint256 bidValue
    ) private  {
        if (auction.isERC1155) {
            IERC1155(contractNFT).safeTransferFrom(address(this), sender, tokenId, 1, "0x0");
        } else {
            IERC721(contractNFT).safeTransferFrom(address(this), sender, tokenId);
        }
        updateFirstDateAndValue(sender, auction.seller, bidValue, auction.token);
        delete contractsPlusTokenIdsAuction[addressPlusTokenId(contractNFT,tokenId)];
        auctionsCount--;
        delete auctionIDtoSellerAddress[addressPlusTokenId(auction.seller,tokenId)];
        contractsTokenIdList[contractNFT] = contractsTokenIdsListUpdated(contractNFT, tokenId);
        emit AuctionNFTBid(contractNFT, tokenId, bidValue, auction.deadline, auction.isERC1155, sender, auction.seller, true, address (0x0));
    }

    function finalize(
        address contractNFT,
        uint256 tokenId
    ) public returns (bool, uint256, address, address, address) {
        require(msg.sender == openBiSeaMainContract, "OpenBiSeaAuction: only main contract can send it");
        require(isContractNFTWhitelisted(contractNFT), "OpenBiSeaAuction: contract must be whitelisted");
        Auction memory auction = contractsPlusTokenIdsAuction[addressPlusTokenId(contractNFT,tokenId)];
        if (block.timestamp > auction.deadline) {
            _bidWin(
                auction,
                contractNFT,
                auction.latestBidder,
                tokenId,
                auction.price
            );
            return (true, auction.price, auction.latestBidder , auction.token, auction.seller);
        }
        return (false, 0, auction.latestBidder, auction.token, auction.seller);
    }

    function bid(
        address contractNFT,
        uint256 tokenId,
        uint256 price,
        address sender,
        address token
    ) public returns (bool, uint256, address, address, address) {
        require(msg.sender == openBiSeaMainContract, "OpenBiSeaAuction: only main contract can send it");
        require(isContractNFTWhitelisted(contractNFT), "OpenBiSeaAuction: contract must be whitelisted");
        Auction memory auction = contractsPlusTokenIdsAuction[addressPlusTokenId(contractNFT,tokenId)];
        require(auction.token == token, "OpenBiSeaAuction: auction use correct token");
        require(auction.seller != address(0), "OpenBiSeaAuction: wrong seller address");

        require(indexOfNFTsAuctionList(contractNFT, tokenId) != type(uint256).max, "OpenBiSeaAuction: auction is not created");
        require(price > auction.price, "OpenBiSeaAuction: price must be more than previous bid");

        if (block.timestamp > auction.deadline) {
            _bidWin(
                auction,
                contractNFT,
                sender,
                tokenId,
                price
            );
            return (true, auction.price, auction.latestBidder , auction.token, auction.seller);
        } else {
            contractsPlusTokenIdsAuction[addressPlusTokenId(contractNFT,tokenId)].price = price;
            contractsPlusTokenIdsAuction[addressPlusTokenId(contractNFT,tokenId)].latestBidder = sender;
            contractsPlusTokenIdsAuction[addressPlusTokenId(contractNFT,tokenId)].latestBidTime = block.timestamp;
            emit AuctionNFTBid(contractNFT, tokenId, price,auction.deadline, auction.isERC1155, sender,auction.seller, false, auction.token);
            if (auction.latestBidder != address(0)) {
                return (false, auction.price, auction.latestBidder, auction.token, auction.seller);
            }
        }
        return (false, 0, auction.latestBidder, auction.token, auction.seller);
    }


    event AuctionNFTCanceled(address indexed contractNFT, uint256 tokenId,uint256 price,uint256 deadline, bool isERC1155,address seller);

    function _cancelAuction(
        address contractNFT,
        uint256 tokenId,
        address sender,
        bool isAdmin
    ) private {
        uint256 index = addressPlusTokenId(contractNFT, tokenId);
        Auction storage auction = contractsPlusTokenIdsAuction[index];
        if (!isAdmin) require(auction.seller == sender, "OpenBiSeaAuction: only seller can cancel");
        if (auction.isERC1155) {
            IERC1155(contractNFT).safeTransferFrom(address(this),auction.seller, tokenId, 1, "0x0");
        } else {
            IERC721(contractNFT).safeTransferFrom(address(this),auction.seller, tokenId);
        }

        address auctionSeller = address(auction.seller);
        emit AuctionNFTCanceled(contractNFT, tokenId,auction.price,auction.deadline, auction.isERC1155, auction.seller);
        delete contractsPlusTokenIdsAuction[index];
        auctionsCount--;
        delete auctionIDtoSellerAddress[addressPlusTokenId(auctionSeller,tokenId)];
        contractsTokenIdList[contractNFT] = contractsTokenIdsListUpdated(contractNFT, tokenId);
    }

    function cancelAuction(
        address contractNFT,
        uint256 tokenId,
        address sender    ) public returns (address, uint256, address){
        require(msg.sender == openBiSeaMainContract, "OpenBiSeaAuction: only main contract can send it");
        require(isContractNFTWhitelisted(contractNFT), "OpenBiSeaAuction: contract must be whitelisted");
        require(indexOfNFTsAuctionList(contractNFT, tokenId) != type(uint256).max, "OpenBiSeaAuction: auction is not created");
        uint256 index = addressPlusTokenId(contractNFT, tokenId);
        Auction storage auction = contractsPlusTokenIdsAuction[index];
        address latestBidder;
        uint256 price;
        address token;
        if (auction.latestBidder != address (0x0) && auction.price > 0) {
            latestBidder = address(auction.latestBidder);
            price = uint256(auction.price);
            token = address(auction.token);
        }
        _cancelAuction(contractNFT, tokenId, sender, false);
        return(latestBidder, price, token);
    }

    function cancelAuctionAdmin(
        address _contractNFT,
        uint256 _tokenId
    ) public onlyOwner {
        _cancelAuction(_contractNFT, _tokenId, address(0) , true);
    }


//    mapping(address => uint256) private _consumersReceivedMainTokenLatestDate;
//    uint256 minimalTotalIncome1 = 10000;
//    uint256 minimalTotalIncome2 = 500000;
//    uint256 minimalTotalIncome3 = 5000000;

//    function _tokensToDistribute(
//        uint256 amountTotalUSDwei,
//        uint256 priceMainToUSD,
//        bool newInvestor
//    ) private view returns (uint256,uint256) {
//        uint256 balanceLeavedOnThisContractProjectTokens = IERC20(IOpenBiSea(openBiSeaMainContract).getTokenOBS()).balanceOf(openBiSeaMainContract);/* if total sales > $10k and < $500k, balanceLeavedOnThisContractProjectTokens = balanceLeavedOnThisContractProjectTokens * 0.1%   if total sales >  $500k and total sales < $5M, balanceLeavedOnThisContractProjectTokens = balanceLeavedOnThisContractProjectTokens * 1% if total sales >  $5M, balanceLeavedOnThisContractProjectTokens = balanceLeavedOnThisContractProjectTokens * 10% */
//        uint256 totalIncomeUSDwei = totalIncomeNFT.mul(priceMainToUSD);
//        if (totalIncomeUSDwei < minimalTotalIncome1.mul(10 ** uint256(18))) {
//            balanceLeavedOnThisContractProjectTokens = balanceLeavedOnThisContractProjectTokens.div(10000); // balanceLeavedOnThisContractProjectTokens = 0;
//        } else if (totalIncomeUSDwei < minimalTotalIncome2.mul(10 ** uint256(18))) {
//            balanceLeavedOnThisContractProjectTokens = balanceLeavedOnThisContractProjectTokens.div(1000);
//        } else if (totalIncomeUSDwei < minimalTotalIncome3.mul(10 ** uint256(18))) {
//            balanceLeavedOnThisContractProjectTokens = balanceLeavedOnThisContractProjectTokens.div(30);
//        } else {
//            balanceLeavedOnThisContractProjectTokens = balanceLeavedOnThisContractProjectTokens.div(10);
//        } /*  amountTotalUSD / TAV - his percent of TAV balanceLeavedOnThisContractProjectTokens * his percent of pool = amount of tokens to pay if (newInvestor) amount of tokens to pay = amount of tokens to pay * 1.1 _investorsReceivedMainToken[msg.sender][time] = amount of tokens to pay*/
//        uint256 percentOfSales = amountTotalUSDwei.mul(10000).div(totalIncomeUSDwei);
//        if (newInvestor) {
//            return (balanceLeavedOnThisContractProjectTokens.mul(percentOfSales).div(10000).mul(11).div(10),percentOfSales);
//        } else {
//            return (balanceLeavedOnThisContractProjectTokens.mul(percentOfSales).div(10000),percentOfSales);
//        }
//    }

//    function checkTokensForClaim(
//        address customer,
//        uint256 priceMainToUSD
//    ) public view returns (uint256,uint256,uint256,bool) {
//        uint256 amountTotalForCustomer = consumersRevenueAmount[customer];
//        if (amountTotalForCustomer < 0 ether) { //10000 ether) {
//            return (0,0,0,false);
//        }
//        uint256 tokensForClaim;
//        uint256 percentOfSales;
//        bool newCustomer = ((block.timestamp.sub(consumersDealFirstDate[customer])) < 4 weeks);
//        if (_consumersReceivedMainTokenLatestDate[customer] > block.timestamp.sub(4 weeks)) {
//            return (tokensForClaim, amountTotalForCustomer,percentOfSales,newCustomer);// already receive reward 4 weeks ago
//        }
//        (tokensForClaim, percentOfSales) = _tokensToDistribute(amountTotalForCustomer,priceMainToUSD,newCustomer);
//        return (tokensForClaim, amountTotalForCustomer,percentOfSales,newCustomer);
//    }
//
//    function setConsumersReceivedMainTokenLatestDate(address _sender) public {
//        require(msg.sender == openBiSeaMainContract, "OpenBiSeaAuction: only main contract can send it");
//        _consumersReceivedMainTokenLatestDate[_sender] = block.timestamp;
//    }

    /**
     * Always returns `IERC721Receiver.onERC721Received.selector`.
    */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
    external
    override
    returns(bytes4)
    {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
    external
    override
    returns(bytes4)
    {
        return this.onERC1155BatchReceived.selector;
    }
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return this.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: UNLICENSED
// (c) Oleksii Vynogradov 2021, All rights reserved, contact [email protected] if you like to use code
pragma solidity ^0.8.0;
interface IOracle {
    function getLatestPrice() external view returns (uint256, uint8);
    function getIsOracle() external view returns (bool);
    function getCustomPrice(address aggregator) external view returns (uint256, uint8);
}

// SPDX-License-Identifier: UNLICENSED
// (c) Oleksii Vynogradov 2021, All rights reserved, contact [email protected] if you like to use code
pragma solidity ^0.8.0;
import "./IOracle.sol";

interface IOpenBiSea {
    function getTokenOBS() external view returns (address);
    function getMainCoinToUSD() external view returns (uint256);
    function getUsdContract() external view returns (address);
    function getOracleContract() external view returns (IOracle);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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