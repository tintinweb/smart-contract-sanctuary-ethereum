// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC1155.sol";
import "Ownable.sol";
import "IERC20.sol";

contract MonsterSoccer is ERC1155, Ownable {
    //Events
    event RefferalHistory(
        address indexed from,
        address indexed to,
        uint256 indexed amount
    );
    event BuyWater(
        address indexed to,
        uint256 indexed ballCount,
        uint256 indexed waterCount
    );
    event NewMonster(address indexed to, MONSTER_TYPE indexed monster);
    event PlayHistory(address indexed player, uint256 indexed amountMST);
    //End of Events

    //Enums and Struct
    enum MONSTER_TYPE {
        NONE,
        LVL1,
        LVL2,
        LVL3,
        LVL4,
        LVL5,
        LVL6,
        COACH,
        COACHASSISTANT
    }

    struct Player {
        address playerAddress;
        uint256 nextAvailTime;
        uint256 waterCount;
        uint256 ballCount;
        uint256 refferalCode;
        address introducer;
        bool coachEnabled;
        bool coachAssistantEnabled;
        uint256 coachPlayCount;
        uint256 coachAssistantPlayCount;
    }

    struct MarketPlaceOrder {
        address owner;
        MONSTER_TYPE tokenID;
        uint256 priceInMST;
        uint256 id;
    }
    //End of Enums and Struct

    //Constants
    uint256 public constant COACH_POSITION = 10;
    uint256 public constant COACHASSISTANT_POSITION = 11;
    uint256 private constant INITIAL_PLAYER = 1000001;
    //End of Constants

    //ٰٰٰVars
    uint256[8] public _mintPrices;
    address public _MSTTokenAddress;
    uint256 public _refferalPercent = 10;
    uint256 public _marketplaceFee = 2;
    uint256 public _ballToWaterRatio = 33;
    uint256 public _CoachChargeAmount = 500;
    uint256 public _CoachChargeAmountAssistant = 500;
    uint256 public _minWithdrawal = 10;
    uint256 public _nextPlayPeriod = 2; //120;
    uint256 public _ballToMSTSwapFee = 5;
    uint256 public _ballToMSTRate = 65;
    uint256 public _ballToMSTRateNominator = 65;
    uint256 public _ballToMSTRateDenominator = 10000000;
    uint256 public _stakePeriod = 120; //86400 * 180;
    bool public _mintingEnable = true;
    //End of Vars

    //Mappings
    address[] public _players;
    mapping(address => Player) public _addressToPlayers;
    mapping(uint256 => address) public _refferalToAddress;

    mapping(address => MONSTER_TYPE[12]) public _playground;
    mapping(address => uint256[12]) public _unstakeTime;
    mapping(address => address[]) public _playerRefferals;
    mapping(address => mapping(address => uint256))
        public _earningsFromRefferal;

    mapping(address => mapping(uint256 => uint256)) public _lockedTokens;

    MarketPlaceOrder[] public _sellOrders;

    uint256[9] public _overalStacking;
    mapping(address => bool) public _ban;

    //End of Mappings

    constructor(address mstToken, string memory baseURI) ERC1155(baseURI) {
        _MSTTokenAddress = mstToken;
        _mintPrices[0] = 26307692;
        _mintPrices[1] = 49692307;
        _mintPrices[2] = 87692307;
        _mintPrices[3] = 160769230;
        _mintPrices[4] = 292307692;
        _mintPrices[5] = 584615384;
        _mintPrices[6] = 17538461;
        _mintPrices[7] = 11692307;

        Player memory newPlayer = Player(
            msg.sender,
            block.timestamp,
            0,
            0,
            INITIAL_PLAYER,
            msg.sender,
            false,
            false,
            0,
            0
        );

        _players.push(msg.sender);
        _addressToPlayers[msg.sender] = newPlayer;
        _refferalToAddress[INITIAL_PLAYER] = msg.sender;
    }

    function SubmitRefferal(uint256 code) public {
        _submitRefferal(code, msg.sender);
    }

    function _submitRefferal(uint256 code, address playerAddress) private {
        uint256 nounce = 0;
        uint256 newRefferalCode = 0;
        if (_players.length > 0) {
            require(
                _refferalToAddress[code] != address(0),
                "Refferal Code is wrong"
            );
        }
        do {
            nounce++;
            newRefferalCode = GetRandomCode(nounce, 10000000);
        } while (_refferalToAddress[newRefferalCode] != address(0));

        Player memory newPlayer = Player(
            playerAddress,
            block.timestamp,
            0,
            0,
            newRefferalCode,
            _refferalToAddress[code],
            false,
            false,
            0,
            0
        );

        _players.push(playerAddress);
        _addressToPlayers[playerAddress] = newPlayer;
        _refferalToAddress[newRefferalCode] = playerAddress;
        _playerRefferals[_refferalToAddress[code]].push(playerAddress);
    }

    function ChargeCoaches(MONSTER_TYPE tokenID) public {
        require(_ban[msg.sender] == false, "this account has been banned");
        require(
            tokenID == MONSTER_TYPE.COACH ||
                tokenID == MONSTER_TYPE.COACHASSISTANT,
            "This Monster Cannot Use Water"
        );
        if (tokenID == MONSTER_TYPE.COACH) {
            require(
                _playground[msg.sender][COACH_POSITION] != MONSTER_TYPE.NONE,
                "you have not any coach in the playground"
            );
            IERC20(_MSTTokenAddress).transferFrom(
                msg.sender,
                address(this),
                _mintPrices[uint256(tokenID) - 1] * (10**18)
            );
            _addressToPlayers[msg.sender].coachPlayCount += _CoachChargeAmount;
        } else {
            require(
                _playground[msg.sender][COACHASSISTANT_POSITION] !=
                    MONSTER_TYPE.NONE,
                "you have not any coachAssistant in the playground"
            );
            IERC20(_MSTTokenAddress).transferFrom(
                msg.sender,
                address(this),
                _mintPrices[uint256(tokenID) - 1] * (10**18)
            );
            _addressToPlayers[msg.sender]
                .coachAssistantPlayCount += _CoachChargeAmountAssistant;
        }
    }

    function MSTToBall(uint256 amount) public {
        IERC20(_MSTTokenAddress).transferFrom(
            msg.sender,
            address(this),
            amount * (10**18)
        );
        _addressToPlayers[msg.sender].ballCount += ((
            ((amount * _ballToMSTRateNominator))
        ) / 100);
    }

    function BallToWater(uint256 amount) public {
        require(
            _addressToPlayers[msg.sender].ballCount >= amount,
            "You dont have enough Balls"
        );
        uint256 waterCount = ((amount * _ballToWaterRatio) / 10);
        _addressToPlayers[msg.sender].ballCount -= (amount);
        _addressToPlayers[msg.sender].waterCount += waterCount;
        emit BuyWater(msg.sender, amount, waterCount);
    }

    function Swap(uint256 amount) public {
        require(_ban[msg.sender] == false, "this account has been banned");
        require(
            _addressToPlayers[msg.sender].ballCount >= _minWithdrawal,
            "you dont have minimum value to withdrawal"
        );
        require(
            _addressToPlayers[msg.sender].ballCount >= amount,
            "insufficient ball"
        );

        uint256 amountToSwap = (((amount * 100 * (10**18)) / _ballToMSTRate));
        amountToSwap -= (amountToSwap * _ballToMSTSwapFee) / 100;
        _addressToPlayers[msg.sender].ballCount -= (amount);
        IERC20(_MSTTokenAddress).transfer(msg.sender, amountToSwap);
    }

    function SellNFT(MONSTER_TYPE tokenID, uint256 amountInMST) public {
        require(_ban[msg.sender] == false, "this account has been banned");
        require(
            GetAvailableTokenCount(uint256(tokenID)) > 0,
            "You do not have this NFT available"
        );
        require(amountInMST > 0, "Invalid amount");
        _lockedTokens[msg.sender][uint256(tokenID)] += 1;
        _sellOrders.push(
            MarketPlaceOrder(
                msg.sender,
                tokenID,
                amountInMST,
                GetRandomCode(GetRandomCode(0, 10000000), 100000000)
            )
        );
    }

    function GetOrderbookIndex(uint256 id) public view returns (uint256 index) {
        for (uint256 i = 0; i < _sellOrders.length; i++) {
            if (_sellOrders[i].id == id) {
                return i;
            }
        }
        return 1000000;
    }

    function CancelOrder(uint256 id) public {
        uint256 index = GetOrderbookIndex(id);
        require(index != 1000000, "Item not found");
        require(_sellOrders[index].owner == msg.sender, "Invalid action");
        _lockedTokens[msg.sender][uint256(_sellOrders[index].tokenID)] -= 1;
        _removeFromOrderBook(index);
    }

    function BuyNFT(uint256 id) public {
        uint256 index = GetOrderbookIndex(id);
        require(index != 1000000, "Item not found");
        require(
            _sellOrders[index].owner != msg.sender,
            "this item is already yours"
        );
        uint256 refferalShare = (_sellOrders[index].priceInMST *
            _refferalPercent) / 100;

        uint256 marketplaceShare = (_sellOrders[index].priceInMST *
            _marketplaceFee) / 100;

        IERC20(_MSTTokenAddress).transferFrom(
            msg.sender,
            _sellOrders[index].owner,
            (_sellOrders[index].priceInMST - refferalShare - marketplaceShare) *
                (10**18)
        );
        IERC20(_MSTTokenAddress).transferFrom(
            msg.sender,
            address(this),
            (refferalShare + marketplaceShare) * (10**18)
        );

        uint256 ballAmount = (refferalShare * _ballToMSTRate) / 100;
        _addressToPlayers[_addressToPlayers[msg.sender].introducer]
            .ballCount += ballAmount;

        _lockedTokens[_sellOrders[index].owner][
            uint256(_sellOrders[index].tokenID)
        ] -= 1;
        _safeTransferFrom(
            _sellOrders[index].owner,
            msg.sender,
            uint256(_sellOrders[index].tokenID),
            1,
            ""
        );
        _earningsFromRefferal[_addressToPlayers[msg.sender].introducer][
            msg.sender
        ] += ballAmount;
        emit RefferalHistory(
            msg.sender,
            _addressToPlayers[msg.sender].introducer,
            ballAmount
        );

        _removeFromOrderBook(index);
    }

    function _removeFromOrderBook(uint256 index) private {
        if (_sellOrders.length == 0) {
            //Do nothing
        } else if (_sellOrders.length == 1) {
            _sellOrders.pop();
        } else {
            _sellOrders[index] = _sellOrders[_sellOrders.length - 1];
            _sellOrders.pop();
        }
    }

    function UnStakeMonster(uint256 position) public {
        require(
            _playground[msg.sender][position] != MONSTER_TYPE.NONE,
            "This position is Empty"
        );
        require(
            _unstakeTime[msg.sender][position] <= block.timestamp,
            "wait until expire date to unstake"
        );
        _lockedTokens[msg.sender][
            uint256(_playground[msg.sender][position])
        ] -= 1;
        _overalStacking[uint256(_playground[msg.sender][position])] -= 1;
        _playground[msg.sender][position] = MONSTER_TYPE.NONE;
        _unstakeTime[msg.sender][position] = 0;
    }

    function StakeMonster(MONSTER_TYPE tokenID, uint256 position) public {
        require(
            _playground[msg.sender][position] == MONSTER_TYPE.NONE,
            "This position is not empty"
        );
        if (tokenID != MONSTER_TYPE.COACH) {
            require(position != COACH_POSITION, "Invalid position");
        }
        if (tokenID == MONSTER_TYPE.COACH) {
            require(position == COACH_POSITION, "Invalid position");
        }
        if (tokenID != MONSTER_TYPE.COACHASSISTANT) {
            require(position != COACHASSISTANT_POSITION, "Invalid position");
        }
        if (tokenID == MONSTER_TYPE.COACHASSISTANT) {
            require(position == COACHASSISTANT_POSITION, "Invalid position");
        }
        require(
            GetAvailableTokenCount(uint256(tokenID)) > 0,
            "You do not have this NFT available"
        );
        _lockedTokens[msg.sender][uint256(tokenID)] += 1;
        _playground[msg.sender][position] = tokenID;
        _unstakeTime[msg.sender][position] = block.timestamp + _stakePeriod;
        _overalStacking[uint256(tokenID)] += 1;
        if (
            !(tokenID == MONSTER_TYPE.COACH ||
                tokenID == MONSTER_TYPE.COACHASSISTANT)
        ) {
            _addressToPlayers[msg.sender].waterCount +=
                WaterNeedPerMonster(tokenID) +
                1;
        }
    }

    function WaterNeedPerMonster(MONSTER_TYPE tokenID)
        public
        view
        returns (uint256)
    {
        return (
            (((((_mintPrices[uint256(tokenID) - 1] * 10000)) / 360) *
                _ballToMSTRateNominator) / _ballToMSTRateDenominator)
        );
    }

    function GetAvailableTokenCount(uint256 tokenID)
        public
        view
        returns (uint256)
    {
        return
            balanceOf(msg.sender, tokenID) - _lockedTokens[msg.sender][tokenID];
    }

    function GetCurrentPower(address playerAddress)
        public
        view
        returns (uint256)
    {
        uint256 power = 0;
        for (
            uint256 playgroundIndex;
            playgroundIndex < _playground[playerAddress].length - 2;
            playgroundIndex++
        ) {
            power += uint256(_playground[playerAddress][playgroundIndex]);
        }
        return power;
    }

    function CalculatePlayWater(address playerAddress)
        public
        view
        returns (uint256)
    {
        return (CalculateBallReward(playerAddress));
    }

    function CalculateBallReward(address playerAddress)
        public
        view
        returns (uint256)
    {
        uint256 ballCount = 0;
        for (
            uint256 playgroundIndex;
            playgroundIndex < _playground[playerAddress].length - 2;
            playgroundIndex++
        ) {
            if (
                _playground[playerAddress][playgroundIndex] != MONSTER_TYPE.NONE
            ) {
                ballCount +=
                    ((
                        (
                            ((_mintPrices[
                                uint256(
                                    _playground[playerAddress][playgroundIndex]
                                ) - 1
                            ] * 10000) / 360)
                        )
                    ) * _ballToMSTRateNominator) /
                    _ballToMSTRateDenominator;
            }
        }
        return ballCount;
    }

    function Play(address playerAddress, bool isAutomationAttempt) public {
        require(GetCurrentPower(playerAddress) > 0, "Your playground is empty");
        require(
            block.timestamp >= _addressToPlayers[playerAddress].nextAvailTime,
            "You must wait"
        );
        uint256 waterRequired = CalculatePlayWater(playerAddress);

        require(
            _addressToPlayers[playerAddress].waterCount >= waterRequired,
            "water is missing"
        );
        uint256 ballAcquire = CalculateBallReward(playerAddress);
        _addressToPlayers[playerAddress].nextAvailTime =
            block.timestamp +
            (_nextPlayPeriod * 60);
        _addressToPlayers[playerAddress].ballCount += ballAcquire;
        _addressToPlayers[playerAddress].waterCount -= waterRequired;
        if (isAutomationAttempt == false) {
            _addressToPlayers[playerAddress].coachEnabled = true;
            _addressToPlayers[playerAddress].coachAssistantEnabled = true;
        }
        emit PlayHistory(playerAddress, ballAcquire);
    }

    function PlayByCoaches() public {
        for (
            uint256 playersIndex;
            playersIndex < _players.length;
            playersIndex++
        ) {
            address playerAddress = _addressToPlayers[_players[playersIndex]]
                .playerAddress;
            if (
                block.timestamp >=
                _addressToPlayers[playerAddress].nextAvailTime
            ) {
                bool doAction = false;

                uint256 waterRequired = CalculatePlayWater(playerAddress);
                if (
                    _addressToPlayers[playerAddress].waterCount < waterRequired
                ) {
                    continue;
                }
                if (GetCurrentPower(playerAddress) <= 0) {
                    continue;
                }
                if (
                    _playground[playerAddress][uint256(COACH_POSITION)] !=
                    MONSTER_TYPE.NONE &&
                    _addressToPlayers[playerAddress].coachEnabled &&
                    _addressToPlayers[playerAddress].coachPlayCount > 0
                ) {
                    _addressToPlayers[playerAddress].coachPlayCount--;
                    if (
                        _addressToPlayers[playerAddress].coachPlayCount % 2 == 0
                    ) {
                        _addressToPlayers[playerAddress].coachEnabled = false;
                    }
                    doAction = true;
                } else if (
                    _playground[playerAddress][
                        uint256(COACHASSISTANT_POSITION)
                    ] !=
                    MONSTER_TYPE.NONE &&
                    _addressToPlayers[playerAddress].coachAssistantEnabled &&
                    _addressToPlayers[playerAddress].coachAssistantPlayCount > 0
                ) {
                    _addressToPlayers[playerAddress]
                        .coachAssistantEnabled = false;
                    _addressToPlayers[playerAddress].coachAssistantPlayCount--;
                    doAction = true;
                }
                if (doAction) {
                    Play(playerAddress, true);
                }
            }
        }
    }

    function MintMonster(MONSTER_TYPE tokenID, uint256 amount) public {
        require(tokenID != MONSTER_TYPE.NONE, "invalid tokenID");
        require(_mintingEnable, "minting is not enable at the moment");
        require(
            amount >= _mintPrices[uint256(tokenID) - 1],
            "Minimum mint fee is required"
        );
        IERC20(_MSTTokenAddress).transferFrom(
            msg.sender,
            address(this),
            amount * 10**18
        );

        uint256 refferalShare = (((amount * _refferalPercent) / 100) *
            _ballToMSTRate) / 100;
        _addressToPlayers[_addressToPlayers[msg.sender].introducer]
            .ballCount += (refferalShare);
        _earningsFromRefferal[_addressToPlayers[msg.sender].introducer][
            msg.sender
        ] += refferalShare;
        if (tokenID == MONSTER_TYPE.COACH) {
            _addressToPlayers[msg.sender].coachPlayCount += _CoachChargeAmount;
        }
        if (tokenID == MONSTER_TYPE.COACHASSISTANT) {
            _addressToPlayers[msg.sender]
                .coachAssistantPlayCount += _CoachChargeAmountAssistant;
        }

        _mint(msg.sender, uint256(tokenID), 1, "");
        emit NewMonster(msg.sender, tokenID);
        emit RefferalHistory(
            msg.sender,
            _addressToPlayers[msg.sender].introducer,
            refferalShare
        );
    }

    function MarketplaceTotalOrders() public view returns (uint256) {
        return _sellOrders.length;
    }

    function TotalPlayers() public view returns (uint256) {
        return _players.length;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        require(
            GetAvailableTokenCount(id) >= amount,
            "You do not have this NFT available"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        require(false, "Batch transfer is not allowed");
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function GetPlayground(address player)
        public
        view
        returns (MONSTER_TYPE[12] memory playground)
    {
        MONSTER_TYPE[12] memory _plg;
        _plg[0] = _playground[player][0];
        _plg[1] = _playground[player][1];
        _plg[2] = _playground[player][2];
        _plg[3] = _playground[player][3];
        _plg[4] = _playground[player][4];
        _plg[5] = _playground[player][5];
        _plg[6] = _playground[player][6];
        _plg[7] = _playground[player][7];
        _plg[8] = _playground[player][8];
        _plg[9] = _playground[player][9];
        _plg[10] = _playground[player][10];
        _plg[11] = _playground[player][11];
        return _plg;
    }

    function GetOrderBook()
        public
        view
        returns (MarketPlaceOrder[] memory orders)
    {
        MarketPlaceOrder[] memory _orders = new MarketPlaceOrder[](
            _sellOrders.length
        );
        for (uint256 i; i < _sellOrders.length; i++) {
            _orders[i] = _sellOrders[i];
        }
        return _orders;
    }

    function GetRefferalList(address player)
        public
        view
        returns (address[] memory refferals, uint256[] memory values)
    {
        address[] memory _refferals = new address[](
            _playerRefferals[player].length
        );
        uint256[] memory _values = new uint256[](
            _playerRefferals[player].length
        );
        for (uint256 i; i < _playerRefferals[player].length; i++) {
            _refferals[i] = _playerRefferals[player][i];
            _values[i] = _earningsFromRefferal[player][_refferals[i]];
        }
        return (_refferals, _values);
    }

    function GetUnstakeTimes(address player)
        public
        view
        returns (uint256[12] memory unstackTimes)
    {
        uint256[12] memory _ust;
        _ust[0] = _unstakeTime[player][0];
        _ust[1] = _unstakeTime[player][1];
        _ust[2] = _unstakeTime[player][2];
        _ust[3] = _unstakeTime[player][3];
        _ust[4] = _unstakeTime[player][4];
        _ust[5] = _unstakeTime[player][5];
        _ust[6] = _unstakeTime[player][6];
        _ust[7] = _unstakeTime[player][7];
        _ust[8] = _unstakeTime[player][8];
        _ust[9] = _unstakeTime[player][9];
        _ust[10] = _unstakeTime[player][10];
        _ust[11] = _unstakeTime[player][11];
        return _ust;
    }

    //Administration Parts
    function Airdrop(
        MONSTER_TYPE tokenID,
        address[] memory targetAirdropAddresses
    ) public onlyOwner {
        require(tokenID != MONSTER_TYPE.NONE, "invalid tokenID");
        for (uint256 i = 0; i < targetAirdropAddresses.length; i++) {
            if (
                _addressToPlayers[targetAirdropAddresses[i]].playerAddress ==
                address(0)
            ) {
                _submitRefferal(INITIAL_PLAYER, targetAirdropAddresses[i]);
            }
            _mint(targetAirdropAddresses[i], uint256(tokenID), 1, "");
        }
    }

    function ToggleBan(address player) public onlyOwner {
        if (_ban[player] == false) {
            _ban[player] = true;
        } else {
            _ban[player] = false;
        }
    }

    function UpdateMintPrices(
        uint256[] memory tokenIDs,
        uint256[] memory newPrices
    ) public onlyOwner {
        require(tokenIDs.length == newPrices.length, "Invalid input");
        require(tokenIDs.length == 8, "Invalid input");
        for (uint256 index; index < tokenIDs.length; index++) {
            _mintPrices[index] = newPrices[index];
        }
    }

    function Withdrawal(uint256 amount) public onlyOwner {
        if (amount == 0) {
            IERC20(_MSTTokenAddress).transfer(
                msg.sender,
                IERC20(_MSTTokenAddress).balanceOf(address(this))
            );
        } else {
            IERC20(_MSTTokenAddress).transfer(msg.sender, amount * 10**18);
        }
    }

    function UpdateConfigs2(
        uint256 ballToMSTRateDenominator,
        uint256 ballToMSTRateNominator
    ) public onlyOwner {
        if (ballToMSTRateDenominator > 0) {
            _ballToMSTRateDenominator = ballToMSTRateDenominator;
        }
        if (ballToMSTRateNominator > 0) {
            _ballToMSTRateNominator = ballToMSTRateNominator;
        }
    }

    function UpdateConfigs(
        uint256 refferalPercent,
        uint256 coachChargeAmountAssistant,
        uint256 coachChargeAmount,
        uint256 minWithdrawal,
        uint256 nextPlayPeriod,
        uint256 ballToWaterRatio,
        uint256 ballToMSTSwapFee,
        uint256 ballToMSTRate,
        uint256 stakePeriod,
        uint256 marketplaceFee,
        bool mintingEnable
    ) public onlyOwner {
        if (refferalPercent > 0) {
            _refferalPercent = refferalPercent;
        }
        if (coachChargeAmountAssistant > 0) {
            _CoachChargeAmountAssistant = coachChargeAmountAssistant;
        }
        if (coachChargeAmount > 0) {
            _CoachChargeAmount = coachChargeAmount;
        }
        if (minWithdrawal > 0) {
            _minWithdrawal = minWithdrawal;
        }
        if (nextPlayPeriod > 0) {
            _nextPlayPeriod = nextPlayPeriod;
        }
        if (ballToWaterRatio > 0) {
            _ballToWaterRatio = ballToWaterRatio;
        }
        if (ballToMSTSwapFee > 0) {
            _ballToMSTSwapFee = ballToMSTSwapFee;
        }
        if (ballToMSTRate > 0) {
            _ballToMSTRate = ballToMSTRate;
        }
        if (stakePeriod > 0) {
            _stakePeriod = stakePeriod;
        }

        if (marketplaceFee > 0) {
            _marketplaceFee = marketplaceFee;
        }

        _mintingEnable = mintingEnable;
    }

    //Utilities

    function GetRandomCode(uint256 nounce, uint256 modulus)
        public
        view
        returns (uint256)
    {
        uint256 randomHash = uint256(
            keccak256(
                abi.encodePacked(block.difficulty, block.timestamp, nounce)
            )
        );
        return randomHash % modulus;
    }
    //end of utilities
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "IERC1155.sol";
import "IERC1155Receiver.sol";
import "IERC1155MetadataURI.sol";
import "Address.sol";
import "Context.sol";
import "ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
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
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
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
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "IERC1155.sol";

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
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

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
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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