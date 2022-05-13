// SPDX-License-Identifier: UNLICENSED
// (c) Oleksii Vynogradov 2021, All rights reserved, contact [email protected] if you like to use code

pragma solidity ^0.8.2;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "./IMotoDEXnft.sol";

contract MotoDEX is Ownable,IERC721Receiver {
    using SafeMath for uint256;
    address public nftContract;
    uint256 public minimalFeeInUSD;
    AggregatorV3Interface internal priceFeed;
    // tracks:
    uint8 public constant TRACK_LONDON = 100;
    uint8 public constant TRACK_DUBAI = 101;
    uint8 public constant TRACK_ABU_DHABI = 102;
    uint8 public constant TRACK_BEIJIN = 103;
    uint8 public constant TRACK_MOSCOW = 104;
    uint8 public constant TRACK_MELBURN = 105;
    uint8 public constant TRACK_PETERBURG = 106;
    uint8 public constant TRACK_TAIPEI = 107;
    uint8 public constant TRACK_PISA = 108;
    uint8 public constant TRACK_ISLAMABAD = 109;

    // motos:
    uint8 public constant RED_BULLER = 0;
    uint8 public constant ZEBRA_GRRR = 1;
    uint8 public constant ROBO_HORSE = 2;
    uint8 public constant METAL_EYES = 3;
    uint8 public constant BROWN_KILLER = 4;
    uint8 public constant CRAZY_LINE = 5;

    mapping(uint256 => address) public tracksOwners;
    mapping(uint256 => address) public motoOwners;
    mapping(uint256 => uint256) public motoOwnersFeeAmount;
    uint256 balanceOf;

    uint256 public motoOwnersFeesSum;

    struct GameSession {
        uint256 latestUpdateTime;
        uint256 latestTrackTimeResult;
        uint8 attempts;
    }

    struct GameBid {
        uint256 amount;          // Amount of funds
        uint8 trackId;
        uint8 motoId;
        uint256 timestamp;
        address bidder;
    }

    mapping(uint256 => mapping(uint256 => GameSession)) public gameSessions;
    mapping(uint => GameBid) public gameBids;
    uint256 gameBidsCount;
    mapping(uint256 => uint256) gameBidsSumPerTrack;


    function getLatestPrice() public view returns (uint256, uint8) {
        (,int256 price,,,) = priceFeed.latestRoundData();
        uint8 decimals = priceFeed.decimals();
        return (uint256(price), decimals);
    }

    constructor(uint256 networkId, address _nftContract) {
        nftContract =_nftContract;
        if (networkId == 1)  priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419); // ETH mainnet
        if (networkId == 4) priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);// ETH rinkeby
        if (networkId == 42) priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);// ETH kovan
        if (networkId == 56) priceFeed = AggregatorV3Interface(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE);// BCS mainnet
        if (networkId == 97) priceFeed = AggregatorV3Interface(0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526);// BCS testnet
        if (networkId == 80001) priceFeed = AggregatorV3Interface(0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada);// Matic testnet
        if (networkId == 137) priceFeed = AggregatorV3Interface(0xAB594600376Ec9fD91F8e885dADF0CE036862dE0);// Matic mainnet
        minimalFeeInUSD = 500000000000000000; // $0.5
        latestEpochUpdate = block.timestamp;
    }
    /*
        getters/setters
    */
    function _setNftContract(address _nftContract) public onlyOwner nonReentrant {
        nftContract =_nftContract;
    }

    function _setEpochMinimalInterval(uint256 _epochMinimalInterval) public onlyOwner nonReentrant {
        epochMinimalInterval = _epochMinimalInterval;
    }

    function _setMinimalFee(uint256 _minimalFeeInUSD) public onlyOwner nonReentrant {
        minimalFeeInUSD = _minimalFeeInUSD;
    }

    function _setTrackOwnerAdmin(address trackOwner, uint256 tokenId) public onlyOwner nonReentrant {
        tracksOwners[tokenId] = trackOwner;
    }

    function _setMotoOwnerAdmin(address motoOwner, uint256 tokenId) public onlyOwner nonReentrant {
        motoOwners[tokenId] = motoOwner;
    }

    function _setGameSessionAdmin(uint8 trackTokenId, uint8 motoTokenId, uint256 latestTrackTimeResult) public onlyOwner nonReentrant {
        bool isUpdate = false;

        if (latestTrackTimeResult == 0) gameSessions[trackTokenId][motoTokenId] = GameSession(block.timestamp, 0, 0);
        else {
            gameSessions[trackTokenId][motoTokenId].latestUpdateTime = block.timestamp;
            gameSessions[trackTokenId][motoTokenId].latestTrackTimeResult = latestTrackTimeResult;
            gameSessions[trackTokenId][motoTokenId].attempts = gameSessions[trackTokenId][motoTokenId].attempts + 1;
        }
        emit CreateOrUpdateGameSession(trackTokenId, motoTokenId, latestTrackTimeResult, block.timestamp, isUpdate);
    }

    function _removeSessionAdmin(uint8 trackTokenId, uint8 motoTokenId) public onlyOwner nonReentrant {
        delete gameSessions[trackTokenId][motoTokenId];
    }

    function getNftContract() public view returns (address) {
        return nftContract;
    }

    function getMinimalFee() public view returns (uint256) {
        return minimalFeeInUSD;
    }

    function getTrackOwner(uint256 tokenId) public view returns (address) {
        return tracksOwners[tokenId];
    }

    function getMotoOwner(uint256 tokenId) public view returns (address) {
        return motoOwners[tokenId];
    }

    function getGameSession(uint8 trackTokenId, uint8 motoTokenId) public view returns (uint256, uint256, uint8) {
        GameSession storage gs = gameSessions[trackTokenId][motoTokenId];
        return (gs.latestUpdateTime, gs.latestTrackTimeResult, gs.attempts);
    }


    function isTokenIdPresent(uint256 [] memory allIds, uint256 tokenId) public view returns (bool) {
        for (uint i; i < allIds.length; i++) {
            if (allIds[i] == tokenId) {
                return true;
            }
        }
        return false;
    }

    function indexOf(uint256 [] memory elements, uint256 searchItem) public view returns (uint256) {
        for (uint256 i; i < elements.length; i++) {
            if (elements[i] == searchItem) {
                return i;
            }
        }
        return type(uint256).max;
    }

    struct GameSessionGet {
        uint256 trackTokenId;
        uint256 motoTokenId;
        uint256 latestUpdateTime;
        uint256 latestTrackTimeResult;
        uint8 attempts;
    }

    struct GameSessionForTrack {
        uint256 trackTokenId;
        GameSessionGet [] sessions;
        uint256 sessionsCount;
    }


    function getAllGameBids() public view returns (GameBid [] memory, uint256) {
        GameBid [] memory gameBidsFor = new GameBid[](gameBidsCount);
        for (uint i; i < gameBidsCount; i++) {
            gameBidsFor[i] = gameBids[i];
        }
        return (gameBidsFor, gameBidsCount);
    }

    /*
        main functions
    */
    function valueInMainCoin(uint256 valueInUSD) public view returns (uint256) {
        uint256 priceMainToUSDreturned;
        uint8 decimals;
        (priceMainToUSDreturned,decimals) = getLatestPrice();
        uint256 valueToCompare = valueInUSD.mul(10 ** decimals).div(priceMainToUSDreturned);
        return valueToCompare;
    }

    function _checkTypeMoto(uint256 tokenId) private {
        uint8 typeForID = IMotoDEXnft(nftContract).getTypeForId(tokenId);
        require(
            typeForID == RED_BULLER ||
            typeForID == ZEBRA_GRRR ||
            typeForID == ROBO_HORSE ||
            typeForID == METAL_EYES ||
            typeForID == BROWN_KILLER ||
            typeForID == CRAZY_LINE
        , "MotoDEX: must be moto type");
    }

    function _checkTypeTrack(uint256 tokenId) private {
        uint8 typeForID = IMotoDEXnft(nftContract).getTypeForId(tokenId);
        require(
            typeForID == TRACK_LONDON ||
            typeForID == TRACK_DUBAI ||
            typeForID == TRACK_ABU_DHABI ||
            typeForID == TRACK_BEIJIN ||
            typeForID == TRACK_MOSCOW ||
            typeForID == TRACK_MELBURN ||
            typeForID == TRACK_PETERBURG ||
            typeForID == TRACK_TAIPEI ||
            typeForID == TRACK_PISA ||
            typeForID == TRACK_ISLAMABAD
        , "MotoDEX: must be track type");
    }

    event AddTrack(uint256 indexed tokenId, uint256 value);

    function addTrack(uint256 tokenId) payable public nonReentrant {
        require(msg.value > valueInMainCoin(minimalFeeInUSD).sub(10000), "MotoDEX: value must be more than minimal required");
        _checkTypeTrack(tokenId);
        IERC721(nftContract).safeTransferFrom(msg.sender, address(this), tokenId);
        tracksOwners[tokenId] = msg.sender;
        balanceOf++;
        emit AddTrack(tokenId,msg.value);
    }

    event ReturnTrack(uint256 indexed tokenId);

    function returnTrack(uint256 tokenId) public nonReentrant {
        require(msg.sender == tracksOwners[tokenId], "MotoDEX: you are not owner of this track NFT");
        _checkTypeTrack(tokenId);
        IERC721(nftContract).safeTransferFrom(address(this), msg.sender , tokenId);
        balanceOf--;
        delete tracksOwners[tokenId];
        emit ReturnTrack(tokenId);
    }

    event AddMoto(uint256 indexed tokenId, uint256 value);

    function addMoto(uint256 tokenId) payable public nonReentrant {
        require(msg.value > valueInMainCoin(minimalFeeInUSD).sub(100000), "MotoDEX: value must be more than minimal required");
        _checkTypeMoto(tokenId);
        IERC721(nftContract).safeTransferFrom(msg.sender, address(this), tokenId);
        motoOwners[tokenId] = msg.sender;
        motoOwnersFeeAmount[tokenId] =  motoOwnersFeeAmount[tokenId] + msg.value;
        balanceOf++;
        emit AddMoto(tokenId, msg.value);
    }

    event ReturnMoto(uint256 indexed tokenId);

    function returnMoto(uint256 tokenId) public nonReentrant {
        require(msg.sender == motoOwners[tokenId], "MotoDEX: you are not owner of this track NFT");
        _checkTypeMoto(tokenId);
        IERC721(nftContract).safeTransferFrom(address(this), msg.sender , tokenId);
        balanceOf--;
        delete motoOwners[tokenId];
        emit ReturnMoto(tokenId);
    }


    event CreateOrUpdateGameSession(uint8 indexed trackTokenId,uint8 indexed motoTokenId, uint256 latestTrackTimeResult,uint256 timestamp, bool isUpdate);

    function createOrUpdateGameSessionFor(uint8 trackTokenId, uint8 motoTokenId, uint256 latestTrackTimeResult) public {
        require(msg.sender == IMotoDEXnft(nftContract).getGameServer(),'MotoDEXnft: only server account can operate game');
        require(IERC721(nftContract).ownerOf(trackTokenId) == address(this),'MotoDEXnft: contract must be owner of track');
        require(IERC721(nftContract).ownerOf(motoTokenId) == address(this),'MotoDEXnft: contract must be owner of moto');
        if (latestTrackTimeResult == 0) {
            gameSessions[trackTokenId][motoTokenId] = GameSession(block.timestamp, 0, 0);
            emit CreateOrUpdateGameSession(
                trackTokenId,
                motoTokenId,
                gameSessions[trackTokenId][motoTokenId].latestTrackTimeResult,
                gameSessions[trackTokenId][motoTokenId].latestUpdateTime,
                false);
        } else {
            gameSessions[trackTokenId][motoTokenId].latestUpdateTime = block.timestamp;
            gameSessions[trackTokenId][motoTokenId].attempts++;
            gameSessions[trackTokenId][motoTokenId].latestTrackTimeResult = latestTrackTimeResult;
            emit CreateOrUpdateGameSession(
                trackTokenId,
                motoTokenId,
                gameSessions[trackTokenId][motoTokenId].latestTrackTimeResult,
                gameSessions[trackTokenId][motoTokenId].latestUpdateTime,
                true);
        }
    }

    uint256 latestEpochUpdate;
    uint256 epochMinimalInterval;


    function isPresentIn(EpochPayment [] memory payments, uint256 paymentsCount, address bidder) public view returns (bool, uint) {
        for (uint indexPayment; indexPayment < paymentsCount; indexPayment++) {
            EpochPayment memory epochPayment = payments[indexPayment];
            if (epochPayment.to == bidder) return (true,indexPayment);
        }
        return (false,type(uint256).max);
    }

    enum ReceiverType{ TRACK, MOTO, BIDDER, PLATFORM}
    event EpochPayFor(uint256 indexed tokenId, address receiver, uint256 amount, ReceiverType receiverType); // 0 - track owner, 1 - moto, 2 - bidder

    struct EpochPayment {
        uint256 amount;
        address to;
        uint256 trackTokenId;
        uint256 motoTokenId;
        uint256 indexForDelete;
        ReceiverType receiverType;
        uint256 amountPlatform;
    }

    function decreasedByHealthLevel(uint256 amount, uint256 tokenId) public view returns (uint256) {
        return amount.mul(IMotoDEXnft(nftContract).getHealthForId(tokenId)).div(IMotoDEXnft(nftContract).getPriceForType(IMotoDEXnft(nftContract).getTypeForId(tokenId)));
    }

    function syncEpochResultsMotos() public view returns (EpochPayment [] memory, uint256) {
        uint256 balanceOfLocal = balanceOf;//IERC721(nftContract).balanceOf(address (this));
        uint256 [] memory trackIds = new uint256 [](balanceOf);
        uint256 trackIdsCount;
        uint256 [] memory motoIds = new uint256 [](balanceOf);
        uint256 motoIdsCount;
        uint256 [] memory trackIdsMotosFeesSum = new uint256 [](balanceOf);
        uint256 [] memory trackIdsBestTime = new uint256 [](balanceOf);
        uint256 [] memory trackIdsMotoIdIndexWinner = new uint256 [](balanceOf);

        while (balanceOfLocal > 0) {
            balanceOfLocal = balanceOfLocal - 1;
            uint256 tokenIdOfOwnerByIndex = IERC721Enumerable(nftContract).tokenOfOwnerByIndex(address (this), balanceOfLocal);
            uint8 typeForId = IMotoDEXnft(nftContract).getTypeForId(tokenIdOfOwnerByIndex);
            if (typeForId < 100 && (tokenIdOfOwnerByIndex == 0 || !isTokenIdPresent(motoIds, tokenIdOfOwnerByIndex))) {
                motoIds[motoIdsCount] = tokenIdOfOwnerByIndex;
                motoIdsCount++;
            } else if (typeForId >= 100 && (tokenIdOfOwnerByIndex == 0 || !isTokenIdPresent(trackIds, tokenIdOfOwnerByIndex))) {
                trackIds[trackIdsCount] = tokenIdOfOwnerByIndex;
                trackIdsCount++;
            }
        }
        for (uint trackIdIndex; trackIdIndex < trackIdsCount; trackIdIndex++) {
            uint256 trackTokenId = trackIds[trackIdIndex];

            for (uint motoIdIndex = 0; motoIdIndex < motoIdsCount; motoIdIndex++) {
                uint256 motoTokenId = motoIds[motoIdIndex];
                if (gameSessions[trackTokenId][motoTokenId].latestUpdateTime > 0) {
                    trackIdsMotosFeesSum[trackIdIndex] = trackIdsMotosFeesSum[trackIdIndex] + motoOwnersFeeAmount[motoTokenId];

                    if (trackIdsBestTime[trackIdIndex] == 0) {
                        trackIdsBestTime[trackIdIndex] = gameSessions[trackTokenId][motoTokenId].latestTrackTimeResult;
                        trackIdsMotoIdIndexWinner[trackIdIndex] = motoIdIndex;
                    } else {
                        // if trackIdsBestTime higher than new - set  latestTrackTimeResult and trackIdsMotoIdIndexWinner index as winner of track
                        if (trackIdsBestTime[trackIdIndex] < gameSessions[trackTokenId][motoTokenId].latestTrackTimeResult) {
                            trackIdsBestTime[trackIdIndex] = gameSessions[trackTokenId][motoTokenId].latestTrackTimeResult;
                            trackIdsMotoIdIndexWinner[trackIdIndex] = motoIdIndex;
                        }
                    }
                }
            }
        }

        EpochPayment [] memory payments = new EpochPayment[](trackIdsCount.mul(2));
        uint256 paymentsCount;

        for (uint trackIdIndex; trackIdIndex < trackIdsCount; trackIdIndex++) {
            if (trackIdsMotosFeesSum[trackIdIndex] > 0) {

//                require(trackOwner != address(0x0000000000000000000000000000000000000000), "syncEpochResultsMotos() trackOwner == 0x0");
//                require(motoOwner != address(0x0000000000000000000000000000000000000000), "syncEpochResultsMotos() motoOwner == 0x0");

                payments[paymentsCount] = EpochPayment(
                    decreasedByHealthLevel(trackIdsMotosFeesSum[trackIdIndex].mul(60).div(100),  motoIds[trackIdsMotoIdIndexWinner[trackIdIndex]]),
                    motoOwners[motoIds[trackIdsMotoIdIndexWinner[trackIdIndex]]],
                    trackIds[trackIdIndex],
                    motoIds[trackIdsMotoIdIndexWinner[trackIdIndex]],
                    type(uint256).max,
                    ReceiverType.MOTO,
                    trackIdsMotosFeesSum[trackIdIndex].mul(10).div(100)
                );
                paymentsCount++;

                payments[paymentsCount] = EpochPayment(
                    decreasedByHealthLevel(trackIdsMotosFeesSum[trackIdIndex].mul(30).div(100), trackIds[trackIdIndex]),
                    tracksOwners[trackIds[trackIdIndex]],
                    trackIds[trackIdIndex],
                    motoIds[trackIdsMotoIdIndexWinner[trackIdIndex]],
                    type(uint256).max,
                    ReceiverType.TRACK,
                    0
                );
                paymentsCount++;
            }
        }
        return (payments, paymentsCount);
    }

    function syncEpochResultsPaymentsAggregate(
        EpochPayment [] memory _payments, uint256 _paymentsCount
    ) public view returns (
        EpochPayment [] memory, uint256
    ) {
        EpochPayment [] memory payments = new EpochPayment[](_paymentsCount);
        uint256 paymentsCount;

        for (uint i; i < _paymentsCount; i++) {
            EpochPayment memory _payment = _payments[i];
            bool isPresent = false;
            uint256 paymentIndex;
            (isPresent, paymentIndex) = isPresentIn(payments, paymentsCount, _payment.to);
            if (isPresent) {
                payments[paymentIndex].amount = payments[paymentIndex].amount + _payment.amount;
                payments[paymentIndex].amountPlatform = payments[paymentIndex].amountPlatform + _payment.amountPlatform;
            } else {
                payments[paymentsCount] = _payment;
                paymentsCount++;
            }
        }
        return (payments, paymentsCount);
    }

    function syncEpochResultsMotosFinal() public view returns (
        EpochPayment [] memory, uint256
    ) {
        EpochPayment [] memory payments;
        uint256 paymentsCount;
        (payments, paymentsCount) = syncEpochResultsMotos();

        EpochPayment [] memory paymentsFinal;
        uint256 paymentsFinalCount;
        (paymentsFinal, paymentsFinalCount) = syncEpochResultsPaymentsAggregate(payments, paymentsCount);

        return (paymentsFinal,paymentsFinalCount);
    }


    function syncEpochResultsBids() public view returns (EpochPayment [] memory, uint256) {
        EpochPayment [] memory payments = new EpochPayment[](gameBidsCount.mul(2));
        uint256 paymentsCount;
        uint256 balanceOfLocal = balanceOf;//IERC721(nftContract).balanceOf(address (this));
        uint256 [] memory trackIds = new uint256 [](balanceOf);
        uint256 trackIdsCount = 0;
        uint256 [] memory motoIds = new uint256 [](balanceOf);
        uint256 motoIdsCount = 0;
        uint256 [] memory trackIdsBestTime = new uint256 [](balanceOf);
        uint256 [] memory trackIdsMotoIdIndexWinner = new uint256 [](balanceOf);

        while (balanceOfLocal > 0) {
            balanceOfLocal = balanceOfLocal - 1;
            uint256 tokenIdOfOwnerByIndex = IERC721Enumerable(nftContract).tokenOfOwnerByIndex(address (this), balanceOfLocal);
            uint8 typeForId = IMotoDEXnft(nftContract).getTypeForId(tokenIdOfOwnerByIndex);
            if (typeForId < 100 && (tokenIdOfOwnerByIndex == 0 || !isTokenIdPresent(motoIds, tokenIdOfOwnerByIndex))) {
                motoIds[motoIdsCount] = tokenIdOfOwnerByIndex;
                motoIdsCount++;
            } else if (typeForId >= 100 && (tokenIdOfOwnerByIndex == 0 || !isTokenIdPresent(trackIds, tokenIdOfOwnerByIndex))) {
                trackIds[trackIdsCount] = tokenIdOfOwnerByIndex;
                trackIdsCount++;
            }
        }
        for (uint trackIdIndex; trackIdIndex < trackIdsCount; trackIdIndex++) {
            uint256 trackTokenId = trackIds[trackIdIndex];

            for (uint motoIdIndex = 0; motoIdIndex < motoIdsCount; motoIdIndex++) {
                uint256 motoTokenId = motoIds[motoIdIndex];
                if (gameSessions[trackTokenId][motoTokenId].latestUpdateTime > 0) {
                    // if trackIdsBestTime zero - set  latestTrackTimeResult and trackIdsMotoIdIndexWinner index as winner of track
                    if (trackIdsBestTime[trackIdIndex] == 0) {
                        trackIdsBestTime[trackIdIndex] = gameSessions[trackTokenId][motoTokenId].latestTrackTimeResult;
                        trackIdsMotoIdIndexWinner[trackIdIndex] = motoIdIndex;
                    } else {
                        // if trackIdsBestTime higher than new - set  latestTrackTimeResult and trackIdsMotoIdIndexWinner index as winner of track
                        if (trackIdsBestTime[trackIdIndex] < gameSessions[trackTokenId][motoTokenId].latestTrackTimeResult) {
                            trackIdsBestTime[trackIdIndex] = gameSessions[trackTokenId][motoTokenId].latestTrackTimeResult;
                            trackIdsMotoIdIndexWinner[trackIdIndex] = motoIdIndex;
                        }
                    }
                }
            }
        }
        for (uint indexGameBid; indexGameBid < gameBidsCount; indexGameBid++) {
            GameBid memory gameBid = gameBids[indexGameBid];
            if (gameBid.amount > 0) {
                uint256 trackTokenIdIndex = indexOf(trackIds, gameBid.trackId);
                uint256 motoTokenIdIndex = indexOf(motoIds, gameBid.motoId);

                if (trackIdsMotoIdIndexWinner[trackTokenIdIndex] == motoTokenIdIndex) {
                    payments[paymentsCount] = EpochPayment(
                        gameBidsSumPerTrack[gameBid.trackId].mul(60).div(100),
                        gameBid.bidder,
                        gameBid.trackId,
                        gameBid.motoId,
                        indexGameBid,
                        ReceiverType.BIDDER,
                        gameBidsSumPerTrack[gameBid.trackId].mul(10).div(100)
                    );
                    paymentsCount++;
                    payments[paymentsCount] = EpochPayment(
                        decreasedByHealthLevel(gameBidsSumPerTrack[gameBid.trackId].mul(30).div(100), gameBid.trackId),
                        tracksOwners[gameBid.trackId],
                        gameBid.trackId,
                        gameBid.motoId,
                        indexGameBid,
                        ReceiverType.TRACK,
                        0 // already added 10% from previous payment
                    );
                    paymentsCount++;

                }
            }
        }
        return (payments, paymentsCount);
    }



    function syncEpochResultsBidsFinal() public view returns (
        EpochPayment [] memory, uint256
    ) {
        EpochPayment [] memory payments;
        uint256 paymentsCount;
        // TODO gameBidsForDelete
        (payments, paymentsCount) = syncEpochResultsBids();

        EpochPayment [] memory paymentsFinal;
        uint256 paymentsFinalCount;
        (paymentsFinal, paymentsFinalCount) = syncEpochResultsPaymentsAggregate(payments, paymentsCount);

        return (paymentsFinal,paymentsFinalCount);
    }

    function tokenIdsAndOwners() public returns (uint256 [] memory, uint256, address [] memory, uint256 [] memory, uint256, address [] memory){
        uint256 balanceOfLocal = balanceOf;//IERC721(nftContract).balanceOf(address (this));
        uint256 [] memory trackIds = new uint256 [](balanceOf);
        uint256 trackIdsCount;
        address [] memory trackIdsOwners = new address [](balanceOf);

        uint256 [] memory motoIds = new uint256 [](balanceOf);
        uint256 motoIdsCount;
        address [] memory motoIdsOwners = new address [](balanceOf);


        while (balanceOfLocal > 0) {
            balanceOfLocal = balanceOfLocal - 1;
            uint256 tokenIdOfOwnerByIndex = IERC721Enumerable(nftContract).tokenOfOwnerByIndex(address (this), balanceOfLocal);
            uint8 typeForId = IMotoDEXnft(nftContract).getTypeForId(tokenIdOfOwnerByIndex);
            if (typeForId < 100 && (tokenIdOfOwnerByIndex == 0 || !isTokenIdPresent(motoIds, tokenIdOfOwnerByIndex))) {
                motoIds[motoIdsCount] = tokenIdOfOwnerByIndex;
                motoIdsOwners[motoIdsCount] = motoOwners[tokenIdOfOwnerByIndex];
                motoIdsCount++;
            } else if (typeForId >= 100 && (tokenIdOfOwnerByIndex == 0 || !isTokenIdPresent(trackIds, tokenIdOfOwnerByIndex))) {
                trackIds[trackIdsCount] = tokenIdOfOwnerByIndex;
                trackIdsOwners[motoIdsCount] = tracksOwners[tokenIdOfOwnerByIndex];
                trackIdsCount++;
            }
        }
        return (motoIds,motoIdsCount,motoIdsOwners,trackIds,trackIdsCount,trackIdsOwners);
    }


    function _syncEpochDelete() private {
        uint256 balanceOfLocal = balanceOf;//IERC721(nftContract).balanceOf(address (this));
        uint256 [] memory trackIds = new uint256 [](balanceOf);
        uint256 trackIdsCount;
        uint256 [] memory motoIds = new uint256 [](balanceOf);
        uint256 motoIdsCount;
        uint256 [] memory trackIdsMotosFeesSum = new uint256 [](balanceOf);
        uint256 [] memory trackIdsBestTime = new uint256 [](balanceOf);
        uint256 [] memory trackIdsMotoIdIndexWinner = new uint256 [](balanceOf);

        while (balanceOfLocal > 0) {
            balanceOfLocal = balanceOfLocal - 1;
            uint256 tokenIdOfOwnerByIndex = IERC721Enumerable(nftContract).tokenOfOwnerByIndex(address (this), balanceOfLocal);
            uint8 typeForId = IMotoDEXnft(nftContract).getTypeForId(tokenIdOfOwnerByIndex);
            if (typeForId < 100 && (tokenIdOfOwnerByIndex == 0 || !isTokenIdPresent(motoIds, tokenIdOfOwnerByIndex))) {
                motoIds[motoIdsCount] = tokenIdOfOwnerByIndex;
                motoIdsCount++;
            } else if (typeForId >= 100 && (tokenIdOfOwnerByIndex == 0 || !isTokenIdPresent(trackIds, tokenIdOfOwnerByIndex))) {
                trackIds[trackIdsCount] = tokenIdOfOwnerByIndex;
                trackIdsCount++;
            }
        }
        for (uint trackIdIndex; trackIdIndex < trackIdsCount; trackIdIndex++) {
            uint256 trackTokenId = trackIds[trackIdIndex];
            delete gameBidsSumPerTrack[trackTokenId];
            for (uint motoIdIndex = 0; motoIdIndex < motoIdsCount; motoIdIndex++) {
                uint256 motoTokenId = motoIds[motoIdIndex];
                if (gameSessions[trackTokenId][motoTokenId].latestUpdateTime > 0)  delete gameSessions[trackTokenId][motoTokenId];
                if (motoOwnersFeeAmount[motoTokenId] > 0) delete motoOwnersFeeAmount[motoTokenId];
            }
        }
        for (uint i; i < gameBidsCount; i++) {
            delete gameBids[i];
        }
        gameBidsCount = 0;
    }

    function syncEpoch() public {
        // TODO - configure percents on contract with change possibility
        // all bids distributed around winners bidders (minus 30% to track/moto owners and minus 10% to platform)
        // all moto adding fees distributed to winner (minus 30% to track owners and minus 10% to platform)
        // motos return back to owners, track leaves
        require(msg.sender == IMotoDEXnft(nftContract).getGameServer(),'MotoDEXnft: only server account can operate game');
        require(block.timestamp - latestEpochUpdate > epochMinimalInterval,'MotoDEXnft: bellow epochMinimalInterval');
        EpochPayment [] memory payments;
        uint256 paymentsCount;
        uint256 platformTenPercent;
        (payments, paymentsCount) = syncEpochResultsBidsFinal();
        for (uint i; i < paymentsCount; i++) {
            EpochPayment memory payment = payments[i];
            require(payment.to != address(0x0000000000000000000000000000000000000000), "syncEpochResultsBids() cant pay to 0x0");

            platformTenPercent = platformTenPercent + payment.amountPlatform;
            //payable(payment.to).transfer(payment.amount); // ALREADY minus 30% to track/moto owners and 10% to platform
//            (bool success, ) = payment.to.call{value:payment.amount}("");
//            require(success, "MotoDEXnft: Transfer failed.");
            Address.sendValue(payable(payment.to), payment.amount);
            emit EpochPayFor(payment.motoTokenId, payment.to, payment.amount, payment.receiverType);
        }

        // all moto adding fees distributed to winner and 30% to crack owners also included (minus 30% to track owners and minus 10% to platform)
        (payments, paymentsCount) = syncEpochResultsMotosFinal();
        for (uint i; i < paymentsCount; i++) {
            EpochPayment memory payment = payments[i];
            require(payment.to != address(0x0000000000000000000000000000000000000000), "syncEpochResultsMotos() cant pay to 0x0");
            platformTenPercent = platformTenPercent + payment.amountPlatform;
            //payable(payment.to).transfer(payment.amount); // already minus 30% to track/moto owners BUT NO MINUS 10% to platform
//            (bool success, ) = payment.to.call{value:payment.amount}("");
//            require(success, "MotoDEXnft: Transfer failed.");
            Address.sendValue(payable(payment.to), payment.amount);
            emit EpochPayFor(payment.motoTokenId, payment.to, payment.amount, payment.receiverType);
        }

        _syncEpochDelete();

        // 10% to motoDEX platform

//        (bool success, ) = owner().call{value:platformTenPercent}("");
//        require(success, "MotoDEXnft: Transfer failed.");
        Address.sendValue(payable(owner()), platformTenPercent);

        emit EpochPayFor(type(uint256).max, owner(), platformTenPercent, ReceiverType.PLATFORM);
    }

    event BidFor(uint8 indexed trackTokenId,uint8 indexed motoTokenId, uint256 amount, address bidder);

    function bidFor(uint8 trackTokenId, uint8 motoTokenId) payable public nonReentrant {
        require(msg.value > valueInMainCoin(minimalFeeInUSD).sub(10000), "MotoDEX: value must be more than minimal required");
        _checkTypeMoto(motoTokenId);
        _checkTypeTrack(trackTokenId);
        gameBids[gameBidsCount] = GameBid(msg.value, trackTokenId, motoTokenId, block.timestamp, msg.sender);
        gameBidsCount++;
        gameBidsSumPerTrack[trackTokenId] = gameBidsSumPerTrack[trackTokenId] + msg.value;
        emit BidFor(trackTokenId, motoTokenId, msg.value, msg.sender);
    }


    function _withdrawSuperAdmin(address token, uint256 amount, uint256 tokenId) public onlyOwner nonReentrant returns (bool) {
        if (amount > 0) {
            if (token == address(0)) {
//                (bool success, ) = msg.sender.call{value:amount}("");
//                require(success, "MotoDEXnft: Transfer failed.");
                Address.sendValue(payable(msg.sender), amount);
                return true;
            } else {
                IERC20(token).transfer(msg.sender, amount);
                return true;
            }
        } else {
            IERC721(nftContract).safeTransferFrom(address(this), msg.sender , tokenId);
        }
        return false;
    }


    /**
       * Always returns `IERC721Receiver.onERC721Received.selector`.
      */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;
    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }


}

// SPDX-License-Identifier: UNLICENSED
// (c) Oleksii Vynogradov 2021, All rights reserved, contact [email protected] if you like to use code

pragma solidity ^0.8.2;
interface IMotoDEXnft {
    function getTypeForId(uint256 tokenId) external view returns (uint8);
    function getHealthForId(uint256 tokenId) external view returns (uint256);
    function getPriceForType(uint8 typeNft) external view returns (uint256);
    function getGameServer() external returns (address);
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}