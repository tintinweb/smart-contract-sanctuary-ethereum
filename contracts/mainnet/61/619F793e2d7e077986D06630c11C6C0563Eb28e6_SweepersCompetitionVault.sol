// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';
import './external/gelato/OpsReady.sol';
import './interfaces/IDust.sol';
import './interfaces/IRandomizer.sol';


contract SweepersCompetitionVault is ReentrancyGuard, Ownable, IERC721Receiver, IERC1155Receiver, OpsReady {

    IDust public DUST;
    IRandomizer public randomizer;
    address payable public sweepersTreasury;
    address payable public sweepersBuyer;
    address payable public legacyTreasury;

    address payable public Dev;
    address payable public VRF;
    uint256 public DevFee = 0.0025 ether;
    uint256 public VRFCost = .005 ether;
    uint256 public SettlementCost = .02 ether;
    uint256 public gasLimit = 60 gwei;

    uint16 public sweepersCut = 8500;
    uint16 public legacyCut = 500;
    uint16 public devCut = 1000;        

    // The competition info
    struct Comp {
        // The Token ID for the listed NFT
        uint256 tokenId;
        // The Contract Address for the listed NFT
        address contractAddress;
        // The NFT Contract Type
        bool is1155;
        // The entry limit per wallet 
        uint32 entryLimit;
        // The number of entries received
        uint32 numberEntries;
        // The raffle entry method restrictions
        bool onlyDust;
        bool onlyEth;
        // The statuses of the competition
        bool blind;
        bool revealed;
        bool settled;
        bool failed;
        string hiddenImage;
        string openseaSlug;
    }
    Comp[] public comps;

    struct CompETHPrices {
        uint8 id;
        uint32 numEntries;
        uint256 price;
    }
    struct CompDustPrices {
        uint8 id;
        uint32 numEntries;
        uint256 price;
    }
    mapping(uint256 => CompETHPrices[5]) public ethPrices;
    mapping(uint256 => CompDustPrices[5]) public dustPrices;

    struct CompTargetParams {
        uint256 minimumETH;
        uint256 maximumETH;
        uint32 startTime;
        uint32 endTime;
        uint32 entryCap;
        bool useETHParams;
        bool useTimeParams;
        bool useEntryParams; 
    }
    mapping(uint256 => CompTargetParams) public targetParams;

    struct CompDistributions {
        uint256 treasury;
        uint256 legacy;
        uint256 dev;
    }
    mapping(uint256 => CompDistributions) public distributions;

    mapping(uint256 => uint256) public cancelDate;
    uint256 public refundPeriod = 30 days;

    mapping(uint256 => uint256) public ethCollected;
    mapping(uint256 => uint256) public dustCollected;
    mapping(uint256 => uint256) public ethDistributed;

    struct Entries {
        address entrant;
        uint32 entryLength;
    }
    mapping(uint256 => Entries[]) public entries;

    struct UserEntries {
        uint32 numberEntries;
        uint256 ethSpent;
        uint256 dustSpent;
        bool claimed;
    }
    mapping(bytes32 => UserEntries) public userData;
    mapping(uint256 => bool) public winnerRequested;
    mapping(uint256 => address) public compWinner;
    mapping(uint256 => bytes32) public pickWinnerTaskId;

    struct Referrer {
        bool isValidReferrer;
        uint256 referralCount;
        uint256 referralCredits;
        address referrerAddress;
    }
    mapping(bytes32 => Referrer) public referrer;
    mapping(address => bytes32) public referrerId;
    mapping(bytes32 => mapping(address => uint256)) public referralExpiration;
    mapping(address => bool) public hasBonused;
    uint256 public earningRate = 10;
    uint32 public referreeBonus = 1;
    uint256 public referralPeriod = 30 days;

    modifier onlySweepersTreasury() {
        require(msg.sender == sweepersTreasury || msg.sender == owner() || msg.sender == sweepersBuyer, "Sender not allowed");
        _;
    }

    modifier onlyRandomizer() {
        require(msg.sender == address(randomizer), "Sender not allowed");
        _;
    }

    event CompCreated(uint256 indexed CompId, uint32 startTime, uint32 endTime, address indexed NFTContract, uint256 indexed TokenId, uint32 entryLimit, uint32 entryCap, bool BlindComp);
    event CompSettled(uint256 indexed CompId, address indexed NFTProjectAddress, uint256 tokenID, address winner, uint256 winningEntryID);
    event CompFailed(uint256 indexed CompId, address indexed NFTProjectAddress, uint256 tokenID);
    event CompCanceled(uint256 indexed CompId, address indexed NFTProjectAddress, uint256 tokenID);
    event EntryReceived(uint256 indexed CompId, address sender, uint256 entriesBought, uint256 currentEntryLength, uint256 compPriceId, bool withETH, uint256 timeStamp);
    event RefundClaimed(uint256 indexed CompId, uint256 ethRefunded, uint256 dustRefunded, address Entrant);
    event Received(address indexed From, uint256 Amount);

    constructor(
        address _dust,
        address payable _ops,
        IRandomizer _randomizer,
        address payable _vrf,
        address payable _legacy,
        address payable _treasury,
        address payable _buyer
    ) OpsReady(_ops) {
        DUST = IDust(_dust);
        Dev = payable(msg.sender);
        randomizer = _randomizer;
        VRF = _vrf;
        legacyTreasury = _legacy;
        sweepersTreasury = _treasury;
        sweepersBuyer = _buyer;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
        return interfaceID == this.supportsInterface.selector;
    }

    function setDust(address _dust) external onlyOwner {
        DUST = IDust(_dust);
    }

    function setDev(address _dev, uint256 _devFee) external onlyOwner {
        Dev = payable(_dev);
        DevFee = _devFee;
    }

    function setDistribution(uint16 _sweepersCut, uint16 _legacyCut, uint16 _devCut) external onlyOwner {
        require(_sweepersCut + _legacyCut + _devCut == 10000);
        sweepersCut = _sweepersCut;
        legacyCut = _legacyCut;
        devCut = _devCut;  
    }

    function setRefundPeriod(uint256 _period) external onlyOwner {
        refundPeriod = _period;
    }

    function setReferralParams(uint256 _rate, uint16 _bonus, uint256 _period) external onlyOwner {
        earningRate = _rate;
        referreeBonus = _bonus;
        referralPeriod = _period;
    }

    function updateSweepersTreasury(address payable _treasury) external onlyOwner {
        sweepersTreasury = _treasury;
    }

    function updateSweepersBuyer(address payable _buyer) external onlyOwner {
        sweepersBuyer = _buyer;
    }

    function updateLegacyTreasury(address payable _treasury) external onlyOwner {
        legacyTreasury = _treasury;
    }

    function updateSettlementParams(
        IRandomizer _randomizer, 
        address payable _vrf, 
        uint256 _vrfCost, 
        uint256 _settlementCost, 
        uint256 _gasLimit 
    ) external onlyOwner {
        randomizer = _randomizer;
        VRF = _vrf;
        VRFCost = _vrfCost;
        SettlementCost = _settlementCost;
        gasLimit = _gasLimit;
    }

    function createComp(
        address _nftContract, 
        uint256 _tokenId, 
        bool _is1155, 
        bool _blind,
        uint32 _startTime, 
        uint32 _endTime, 
        uint16 _entryCap,
        uint16 _entryLimit,
        uint256 _minETH,
        uint256 _maxETH,
        CompDustPrices[] calldata _dustPrices,
        CompETHPrices[] calldata _ethPrices,
        bool _onlyDust,
        bool _onlyEth,
        bool _ethParams,
        bool _timeParams,
        bool _entryParams,
        string calldata _hiddenImage, 
        string calldata _slug
    ) external payable onlySweepersTreasury returns (uint256) {
        require(msg.value == VRFCost + SettlementCost);
        require(_ethParams || _timeParams || _entryParams);
        require(_blind ? _tokenId == 0 : _tokenId != 0);

        Comp memory _comp = Comp({
            tokenId : _tokenId,
            contractAddress : _nftContract,
            is1155 : _is1155,
            entryLimit : _entryLimit,
            numberEntries : 0,
            onlyDust : _onlyDust,
            onlyEth : _onlyEth,
            blind : _blind,
            revealed : _blind ? false : true,
            settled : false,
            failed : false,
            hiddenImage : _blind ? _hiddenImage : 'null',
            openseaSlug : _slug
        });

        comps.push(_comp);

        if(!_onlyDust) {
            require(_ethPrices.length > 0, "No prices");

            for (uint256 i = 0; i < _ethPrices.length; i++) {
                require(_ethPrices[i].numEntries > 0, "numEntries is 0");

                CompETHPrices memory p = CompETHPrices({
                    id: uint8(i),
                    numEntries: _ethPrices[i].numEntries,
                    price: _ethPrices[i].price
                });

                ethPrices[comps.length - 1][i] = p;
            }
        }

        if(!_onlyEth) {
            require(_dustPrices.length > 0, "No prices");

            for (uint256 i = 0; i < _dustPrices.length; i++) {
                require(_dustPrices[i].numEntries > 0, "numEntries is 0");

                CompDustPrices memory d = CompDustPrices({
                    id: uint8(i),
                    numEntries: _dustPrices[i].numEntries,
                    price: _dustPrices[i].price
                });

                dustPrices[comps.length - 1][i] = d;
            }
        }

        targetParams[comps.length - 1] = CompTargetParams({
            minimumETH : _minETH,
            maximumETH : _maxETH,
            startTime : _startTime,
            endTime : _endTime,
            entryCap : _entryCap,
            useETHParams : _ethParams,
            useTimeParams : _timeParams,
            useEntryParams : _entryParams 
        });

        if(!_blind) {
            if(_is1155) {
                IERC1155(_nftContract).safeTransferFrom(msg.sender, address(this), _tokenId, 1, "");
            } else {
                IERC721(_nftContract).safeTransferFrom(msg.sender, address(this), _tokenId);
            }
        }

        startPickWinnerTask(comps.length - 1);

        emit CompCreated(comps.length - 1, _startTime, _endTime, _nftContract, _tokenId, _entryLimit, _entryCap, _blind);

        return comps.length - 1;
    }

    function updateBlindComp(uint32 _id, uint256 _tokenId) external onlySweepersTreasury {
        require(comps[_id].tokenId == 0, "Comp already updated");
        require(_tokenId != 0);
        comps[_id].tokenId = _tokenId;
        if(comps[_id].is1155) {
            IERC1155(comps[_id].contractAddress).safeTransferFrom(msg.sender, address(this), _tokenId, 1, "");
        } else {
            IERC721(comps[_id].contractAddress).safeTransferFrom(msg.sender, address(this), _tokenId);
        }
    }

    function updateBlindComp1155(uint256 _id, bool _is1155) external onlySweepersTreasury {
        comps[_id].is1155 = _is1155;
    }

    function updateBlindImage(uint256 _id, string calldata _hiddenImage) external onlySweepersTreasury {
        comps[_id].hiddenImage = _hiddenImage;
    }

    function updateOpenseaSlug(uint256 _id, string calldata _slug) external onlySweepersTreasury {
        comps[_id].openseaSlug = _slug;
    }

    function updateCompEndTime(uint256 _id, uint32 _endTime) external onlySweepersTreasury {
        targetParams[_id].endTime = _endTime;
    }

    function emergencyCancelComp(uint32 _id) external payable onlySweepersTreasury {
        require(compStatus(_id) == 1 || compStatus(_id) == 0, 'Can only cancel active comps');
        require(msg.value == ethDistributed[_id], 'Must send back enough ETH to cover refunds');
        _cancelComp(_id);
    }

    function _cancelComp(uint32 _id) private {
        comps[_id].failed = true;
        cancelDate[_id] = block.timestamp;

        stopTask(pickWinnerTaskId[_id]);

        if (comps[_id].tokenId != 0) {
            if(comps[_id].is1155) {
                IERC1155(comps[_id].contractAddress).safeTransferFrom(address(this), Dev, comps[_id].tokenId, 1, "");
            } else {
                IERC721(comps[_id].contractAddress).safeTransferFrom(address(this), Dev, comps[_id].tokenId);
            }
        }
        delete distributions[_id];
        delete ethDistributed[_id];
        emit CompCanceled(_id, address(comps[_id].contractAddress), comps[_id].tokenId);
    }

    function claimRefund(uint256 _id) external nonReentrant {
        require(compStatus(_id) == 4, "not failed");
        require(
            block.timestamp <= cancelDate[_id] + refundPeriod,
            "claim time expired"
        );

        UserEntries storage claimData = userData[
            keccak256(abi.encode(msg.sender, _id))
        ];

        require(claimData.claimed == false, "already refunded");

        ethCollected[_id] -= claimData.ethSpent;
        dustCollected[_id] -= claimData.dustSpent;

        claimData.claimed = true;
        if(claimData.ethSpent > 0) {
            (bool sentETH, ) = msg.sender.call{value: claimData.ethSpent}("");
            require(sentETH, "Fail send refund");
        }

        if(claimData.dustSpent > 0) { DUST.mint(msg.sender, claimData.dustSpent); }

        emit RefundClaimed(_id, claimData.ethSpent, claimData.dustSpent, msg.sender);
    }

    function emergencyRescueNFT(address _nft, uint256 _tokenId, bool _is1155) external onlySweepersTreasury {
        if(_is1155) {
            IERC1155(_nft).safeTransferFrom(address(this), Dev, _tokenId, 1, "");
        } else {
            IERC721(_nft).safeTransferFrom(address(this), Dev, _tokenId);
        }
    }

    function emergencyRescueETH(uint256 amount) external onlySweepersTreasury {
        (bool sent,) = Dev.call{value: amount}("");
        require(sent);
    }

    /**
     * @notice Buy a competition entry using DUST.
     */
    function buyEntryDust(uint256 _id, uint256 _priceId, bytes32 _referrer, uint16 _redeemEntries) external payable nonReentrant {
        require(compStatus(_id) == 1, 'Comp is not Active');
        require(!comps[_id].onlyEth, 'Comp is restricted to only ETH');

        CompDustPrices memory priceStruct = getDustPriceStructForId(_id, _priceId);
        require(msg.value == DevFee, 'Fee not covered');
        
        bytes32 hash = keccak256(abi.encode(msg.sender, _id));
        require(userData[hash].numberEntries + priceStruct.numEntries + _redeemEntries <= comps[_id].entryLimit, "Bought too many entries"); 
        if(targetParams[_id].useEntryParams) require(comps[_id].numberEntries + priceStruct.numEntries + _redeemEntries <= targetParams[_id].entryCap, "Not enough entries remaining"); 

        uint32 _numEntries = priceStruct.numEntries;
        if(_redeemEntries > 0) {
            bytes32 _ref = referrerId[msg.sender];
            require(referrer[_ref].referralCredits >= _redeemEntries * 1000, 'Not enough credits available');
            referrer[_ref].referralCredits -= (_redeemEntries * 1000);
            _numEntries += _redeemEntries;
        }

        if(referrer[_referrer].isValidReferrer) {
            if(referralExpiration[_referrer][msg.sender] == 0) {
                referralExpiration[_referrer][msg.sender] = block.timestamp + referralPeriod;
            }
            if(block.timestamp < referralExpiration[_referrer][msg.sender]) {
                referrer[_referrer].referralCount += priceStruct.numEntries;
                referrer[_referrer].referralCredits += (priceStruct.numEntries) * 1000 / earningRate;
                if(!hasBonused[msg.sender]) {
                    _numEntries += referreeBonus;
                    hasBonused[msg.sender] = true;
                }
            }
        }

        Entries memory entryBought = Entries({
            entrant: msg.sender,
            entryLength: comps[_id].numberEntries + _numEntries
        });
        entries[_id].push(entryBought);
  
        dustCollected[_id] += priceStruct.price;
        comps[_id].numberEntries += _numEntries;

        userData[hash].numberEntries += _numEntries;
        userData[hash].dustSpent += priceStruct.price;

        DUST.burnFrom(msg.sender, priceStruct.price);
        
        (bool sent,) = Dev.call{value: DevFee}("");
        require(sent);

        emit EntryReceived(
            _id,
            msg.sender,
            priceStruct.numEntries,
            _numEntries,
            _priceId,
            false,
            block.timestamp
        );
    }

    /**
     * @notice Buy a competition entry using ETH.
     */
    function buyEntryETH(uint32 _id, uint256 _priceId, bytes32 _referrer, uint16 _redeemEntries) external payable nonReentrant {
        require(compStatus(_id) == 1, 'Comp is not Active');
        require(!comps[_id].onlyDust, 'Comp is restricted to only DUST');

        CompETHPrices memory priceStruct = getEthPriceStructForId(_id, _priceId);
        require(msg.value == priceStruct.price, 'msg.value must be equal to the price');
        
        bytes32 hash = keccak256(abi.encode(msg.sender, _id));
        require(userData[hash].numberEntries + priceStruct.numEntries + _redeemEntries <= comps[_id].entryLimit, "Bought too many entries");
        if(targetParams[_id].useEntryParams) require(comps[_id].numberEntries + priceStruct.numEntries + _redeemEntries <= targetParams[_id].entryCap, "Not enough entries remaining"); 

        uint32 _numEntries = priceStruct.numEntries;
        if(_redeemEntries > 0) {
            bytes32 _ref = referrerId[msg.sender];
            require(referrer[_ref].referralCredits >= _redeemEntries * 1000, 'Not enough credits available');
            referrer[_ref].referralCredits -= (_redeemEntries * 1000);
            _numEntries += _redeemEntries;
        }

        if(referrer[_referrer].isValidReferrer) {
            if(referralExpiration[_referrer][msg.sender] == 0) {
                referralExpiration[_referrer][msg.sender] = block.timestamp + referralPeriod;
            }
            if(block.timestamp < referralExpiration[_referrer][msg.sender]) {
                referrer[_referrer].referralCount += priceStruct.numEntries;
                referrer[_referrer].referralCredits += (priceStruct.numEntries) * 1000 / earningRate;
                if(!hasBonused[msg.sender]) {
                    _numEntries += referreeBonus;
                    hasBonused[msg.sender] = true;
                }
            }
        }

        // add the entry to the entries array
        Entries memory entryBought = Entries({
            entrant: msg.sender,
            entryLength: comps[_id].numberEntries + _numEntries
        });
        entries[_id].push(entryBought);
  
        comps[_id].numberEntries += _numEntries;

        userData[hash].numberEntries += _numEntries;
        userData[hash].ethSpent += priceStruct.price;

        if(targetParams[_id].useETHParams) {
            if(ethCollected[_id] < targetParams[_id].minimumETH) {
                (bool sent,) = sweepersBuyer.call{value: msg.value}("");
                require(sent);
                ethDistributed[_id] += msg.value * (10000 - sweepersCut) / 10000;
            } else if(ethDistributed[_id] > 0) {
                uint256 adjuster = msg.value * (sweepersCut) / 10000;
                if(ethDistributed[_id] > adjuster) {
                    ethDistributed[_id] -= adjuster;
                } else {
                    distributions[_id].treasury += adjuster - ethDistributed[_id];
                    ethDistributed[_id] = 0;
                }
            } else {
                distributions[_id].treasury += msg.value * sweepersCut / 10000;
            }
        } else {
            distributions[_id].treasury += msg.value * sweepersCut / 10000;
        }
        distributions[_id].legacy += msg.value * legacyCut / 10000;
        distributions[_id].dev += msg.value * devCut / 10000;

        ethCollected[_id] += priceStruct.price;

        emit EntryReceived(
            _id,
            msg.sender,
            _numEntries,
            comps[_id].numberEntries,
            _priceId,
            true,
            block.timestamp
        );
    }

    function enrollReferrer(string calldata referralCode) external nonReentrant {
        require(referrerId[msg.sender] == 0, 'User already enrolled');
        bytes32 bytesCode = bytes32(bytes(referralCode)); 
        require(referrer[bytesCode].referralCount == 0 && !referrer[bytesCode].isValidReferrer && bytesCode != 0, 'referralCode already exists');
        referrerId[msg.sender] = bytesCode;
        referrer[bytesCode].isValidReferrer = true;
        referrer[bytesCode].referrerAddress = msg.sender;
    }

    function removeReferrer(bytes32 _referrerId, address _referrer) external onlySweepersTreasury {
        delete referrer[_referrerId];
        delete referrerId[_referrer];
    }

    function suspendReferrer(bytes32 _referrer) external onlySweepersTreasury {
        referrer[_referrer].isValidReferrer = false;
    }

    function getEthPriceStructForId(uint256 _idRaffle, uint256 _id)
        internal
        view
        returns (CompETHPrices memory)
    {
        if (ethPrices[_idRaffle][_id].id == _id) {
            return ethPrices[_idRaffle][_id];
        }
        return CompETHPrices({id: 0, numEntries: 0, price: 0});
    }

    function getDustPriceStructForId(uint256 _idRaffle, uint256 _id)
        internal
        view
        returns (CompDustPrices memory)
    {
        if (dustPrices[_idRaffle][_id].id == _id) {
            return dustPrices[_idRaffle][_id];
        }
        return CompDustPrices({id: 0, numEntries: 0, price: 0});
    }

    function startPickWinnerTask(uint256 _id) internal {
        pickWinnerTaskId[_id] = IOps(ops).createTaskNoPrepayment(
            address(this), 
            this._pickCompWinner.selector,
            address(this),
            abi.encodeWithSelector(this.canPickChecker.selector, _id),
            ETH
        );
    }

    function canPickChecker(uint256 _id) 
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {
        canExec = (compStatus(_id) == 2 && !winnerRequested[_id] && comps[_id].tokenId != 0);
        
        execPayload = abi.encodeWithSelector(
            this._pickCompWinner.selector,
            _id
        );
    }

    function pickCompWinner(uint256 _id) public {
        require(compStatus(_id) == 2, 'cant be settled now');
        require(comps[_id].tokenId != 0, 'update comp tokenID');
        
        if(comps[_id].numberEntries > 0) {
            randomizer.requestRandomWords(_id);
            winnerRequested[_id] = true;
            (bool sent,) = VRF.call{value: VRFCost}("");
            require(sent);
        } else {
            winnerRequested[_id] = true;
            _closeComp(_id);
        }
    }

    function _pickCompWinner(uint256 _id) external onlyOps {
        require(tx.gasprice < gasLimit, 'cant be settled now');
        (uint256 fee, address feeToken) = IOps(ops).getFeeDetails();
        _transfer(fee, feeToken);

        pickCompWinner(_id);

        stopTask(pickWinnerTaskId[_id]);
    }

    function earlyCloseConp(uint256 _id) external onlySweepersTreasury {
        require(targetParams[_id].useETHParams, 'Can only close with ETH params');
        require(ethCollected[_id] >= targetParams[_id].minimumETH && ethDistributed[_id] == 0, 'Can not close with current funding');
        require(comps[_id].tokenId != 0, 'Update comp tokenID');

        randomizer.requestRandomWords(_id);
        winnerRequested[_id] = true;
        (bool sent,) = VRF.call{value: VRFCost}("");
        require(sent);
    }
    
    /**
     * @notice Settle a competition, finalizing the bid and transferring the NFT to the winner.
     * @dev If there are no entries, the competition is failed and can be relisted.
     */
    function settleComp(uint256 _id) external {
        uint256 seed = randomizer.getRandomWord();
        _settleComp(_id, seed);
    }

    function autoSettleComp(uint256 _id, uint256 seed) external onlyRandomizer {
        _settleComp(_id, seed);
    }

    function _settleComp(uint256 _id, uint256 seed) internal {
        require(compStatus(_id) == 6, 'cant be settled now');
        require(comps[_id].numberEntries > 0, 'comp has no entries');

        comps[_id].settled = true;
        uint256 entryIndex = seed % comps[_id].numberEntries + 1;
        uint256 winnerIndex = findWinner(entries[_id], entryIndex);
        address _compWinner = entries[_id][winnerIndex].entrant;
        compWinner[_id] = _compWinner;

        if(comps[_id].is1155) {
            IERC1155(comps[_id].contractAddress).safeTransferFrom(address(this), _compWinner, comps[_id].tokenId, 1, "");
        } else {
            IERC721(comps[_id].contractAddress).safeTransferFrom(address(this), _compWinner, comps[_id].tokenId);
        }

        if(comps[_id].blind) {
            comps[_id].revealed = true;
        }

        if(distributions[_id].treasury > 0) {
            (bool sent1,) = sweepersTreasury.call{value: distributions[_id].treasury}("");
            require(sent1);
        }
        if(distributions[_id].legacy > 0) {
            (bool sent2,) = legacyTreasury.call{value: distributions[_id].legacy}("");
            require(sent2);
        }
        if(distributions[_id].dev > 0) {
            (bool sent3,) = Dev.call{value: distributions[_id].dev}("");
            require(sent3);
        }

        emit CompSettled(_id, address(comps[_id].contractAddress), comps[_id].tokenId, _compWinner, entryIndex);
    }

    function _closeComp(uint256 _id) internal {
        require(compStatus(_id) == 2, 'cant be settled now');
        require(comps[_id].numberEntries == 0, 'comp has entries');

        comps[_id].settled = true;
        uint256 entryIndex;
        address _compWinner;

        comps[_id].failed = true;
        if (comps[_id].tokenId != 0) {
            if(comps[_id].is1155) {
                IERC1155(comps[_id].contractAddress).safeTransferFrom(address(this), Dev, comps[_id].tokenId, 1, "");
            } else {
                IERC721(comps[_id].contractAddress).safeTransferFrom(address(this), Dev, comps[_id].tokenId);
            }
        }
        emit CompFailed(_id, address(comps[_id].contractAddress), comps[_id].tokenId);
        
        emit CompSettled(_id, address(comps[_id].contractAddress), comps[_id].tokenId, _compWinner, entryIndex);
    }

    function findWinner(Entries[] storage _array, uint256 entryIndex) internal pure returns (uint256) {
        Entries[] memory array = _array;
        
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid].entryLength > entryIndex) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1].entryLength == entryIndex) {
            return low - 1;
        } else {
            return low;
        }
    }

    function compStatus(uint256 _id) public view returns (uint8) {
        if (winnerRequested[_id] && !comps[_id].settled) {
            return 6; // AWAITING SETTLEMENT - Winner selected and awaiting settlement    
        }
        if (comps[_id].failed) {
            return 4; // FAILED - not sold by end time
        }
        if (comps[_id].settled) {
            return 3; // SUCCESS - Entrant won 
        }
        if(targetParams[_id].useTimeParams) {    
            if (block.timestamp >= targetParams[_id].endTime && comps[_id].tokenId == 0) {
                return 5; // AWAITING TOKENID - Comp finished
            }
            if (block.timestamp >= targetParams[_id].endTime || comps[_id].numberEntries == targetParams[_id].entryCap) {
                return 2; // AWAITING WINNER SELECTION - Comp finished
            }
            if (block.timestamp <= targetParams[_id].endTime && block.timestamp >= targetParams[_id].startTime) {
                return 1; // ACTIVE - entries enabled
            }
        } else if(targetParams[_id].useETHParams) {
            if (ethCollected[_id] >= targetParams[_id].maximumETH && comps[_id].tokenId == 0) {
                return 5; // AWAITING TOKENID - Comp finished
            }
            if (ethCollected[_id] >= targetParams[_id].maximumETH) {
                return 2; // AWAITING WINNER SELECTION - Comp finished
            }
            if (ethCollected[_id] < targetParams[_id].maximumETH && block.timestamp >= targetParams[_id].startTime) {
                return 1; // ACTIVE - entries enabled
            }
        } else if(targetParams[_id].useEntryParams) {
            if (comps[_id].numberEntries >= targetParams[_id].entryCap && comps[_id].tokenId == 0) {
                return 5; // AWAITING TOKENID - Comp finished
            }
            if (comps[_id].numberEntries >= targetParams[_id].entryCap) {
                return 2; // AWAITING WINNER SELECTION - Comp finished
            }
            if (comps[_id].numberEntries < targetParams[_id].entryCap && block.timestamp >= targetParams[_id].startTime) {
                return 1; // ACTIVE - entries enabled
            }
        }
        return 0; // QUEUED - awaiting start time
    }

    function getEntries(uint256 _id) external view returns (Entries[] memory) {
        return entries[_id];
    }

    function getUserData(uint256 _id, address _entrant) external view returns (UserEntries memory) {
        return userData[keccak256(abi.encode(_entrant, _id))];
    }

    function getCompsLength() external view returns (uint256) {
        return comps.length;
    }

    function getReferrerData(address _referrer) external view returns(bool isReferrer, bytes32 code, uint256 numReferrals, uint256 numCredits) {
        code = referrerId[_referrer];
        if(code == 0) {
            return (false, 0x0, 0, 0);
        } else {
            isReferrer = referrer[code].isValidReferrer;
            numReferrals = referrer[code].referralCount;
            numCredits = referrer[code].referralCredits;
        }
    }

    function stopTask(bytes32 taskId) internal {
        IOps(ops).cancelTask(taskId);
    }

    function manualStopTask(bytes32 taskId) external onlySweepersTreasury {
        stopTask(taskId);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IRandomizer {
    
    function getRandomWord() external returns (uint256);
    function requestRandomWords(uint256 _id) external;
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IDust {
	event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    function burn(uint256 _amount) external;
    function burnFrom(address _from, uint256 _amount) external;
    function mint(address _to, uint256 _amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import {
    SafeERC20,
    IERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IOps {
    function gelato() external view returns (address payable);
    function createTaskNoPrepayment(address _execAddress, bytes4 _execSelector, address _resolverAddress, bytes calldata _resolverData, address _feeToken) external returns (bytes32 task);
    function getFeeDetails() external view returns (uint256, address);
    function cancelTask(bytes32 task) external;
}

abstract contract OpsReady {
    address public immutable ops;
    address payable public immutable gelato;
    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    modifier onlyOps() {
        require(msg.sender == ops, "OpsReady: onlyOps");
        _;
    }

    constructor(address _ops) {
        ops = _ops;
        gelato = IOps(_ops).gelato();
    }

    function _transfer(uint256 _amount, address _paymentToken) internal {
        if (_paymentToken == ETH) {
            (bool success, ) = gelato.call{value: _amount}("");
            require(success, "_transfer: ETH transfer failed");
        } else {
            SafeERC20.safeTransfer(IERC20(_paymentToken), gelato, _amount);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}