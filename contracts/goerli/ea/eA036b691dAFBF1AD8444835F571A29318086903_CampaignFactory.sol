// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Campaign.sol";

contract CampaignFactory {
    address payable public immutable owner;
    mapping(string => address) public campaigns;

    // in US cents
    uint256 private deposit = 33300;

    // in US cents
    uint256 private fee = 100;

    constructor() {
        owner = payable(msg.sender);
    }

    event campaignCreated(address campaignContractAddress);

    function createCampaign(
        uint256 _chainId,
        string memory _campaignId,
        address _prizeAddress,
        uint256 _prizeAmount,
        uint256 _maxEntries,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        bytes32 _sealedSeed,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) public {
        require(
            campaigns[_campaignId] == address(0),
            "Campaign with this id already exists"
        );

        bytes32 message = hashMessage(
            msg.sender,
            _chainId,
            _campaignId,
            _prizeAddress,
            _prizeAmount,
            _maxEntries,
            _startTimestamp,
            _endTimestamp,
            _sealedSeed
        );

        require(
            ecrecover(message, v, r, s) == owner,
            "You need signatures from the owner to create a campaign"
        );

        Campaign c = new Campaign(
            owner,
            msg.sender,
            _campaignId,
            _prizeAddress,
            _prizeAmount,
            _maxEntries,
            _startTimestamp,
            _endTimestamp,
            _sealedSeed,
            deposit,
            fee
        );

        campaigns[_campaignId] = address(c);
        emit campaignCreated(address(c));
    }

    function setDepositAmount(uint256 _deposit) public {
        require(msg.sender == owner, "Only owner can set deposit amount");
        deposit = _deposit;
    }

    function getDepositAmount() public view returns (uint256) {
        return deposit;
    }

    function setFeeAmount(uint256 _fee) public {
        require(msg.sender == owner, "Only owner can set fee amount");
        fee = _fee;
    }

    function getFeeAmount() public view returns (uint256) {
        return fee;
    }

    function hashMessage(
        address _campaignOwner,
        uint256 _chainId,
        string memory _campaignId,
        address _prizeAddress,
        uint256 _prizeAmount,
        uint256 _maxEntries,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        bytes32 _sealedSeed
    ) public view returns (bytes32) {
        bytes memory pack = abi.encodePacked(
            this,
            _campaignOwner,
            _chainId,
            _campaignId,
            _prizeAddress,
            _prizeAmount,
            _maxEntries,
            _startTimestamp,
            _endTimestamp,
            _sealedSeed
        );
        return keccak256(pack);
    }

    function getCampaignContractAddress(string memory _campaignId)
        public
        view
        returns (address)
    {
        return campaigns[_campaignId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

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

contract Campaign {
    string public campaignId;
    address payable immutable owner;
    address public immutable campaignOwner;
    address public immutable prizeAddress;
    uint256 public immutable prizeAmount;
    uint256 public immutable maxEntries;
    uint256 public immutable startTimestamp;
    uint256 public immutable endTimestamp;
    bytes32 private immutable sealedSeed;
    uint256 private immutable feeAmount;
    uint256 private immutable depositAmount;

    uint256 public revealBlockNumber;
    uint256 public confirmationEndTime;
    bytes32 public revealedSeed;

    mapping(address => address) private chain;
    mapping(uint256 => address) private cursorMap;

    uint256 public length = 0;

    uint256 private oldRand;
    bool private cancelled = false;
    bool private depositReceived = false;

    function getUSDInWEI() public view returns (uint256) {
        address dataFeed;
        if (block.chainid == 1) {
            //Mainnet ETH/USD
            dataFeed = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
        } else if (block.chainid == 5) {
            //Goerli ETH/USD
            dataFeed = 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e;
        } else if (block.chainid == 137) {
            //Polygon MATIC/USD
            dataFeed = 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0;
        } else if (block.chainid == 80001) {
            //Mumbai MATIC/USD
            dataFeed = 0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada;
        } else if (block.chainid == 56) {
            dataFeed = 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE;
        } else if (block.chainid == 97) {
            //BSC BNBT/USD
            dataFeed = 0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526;
        } else {
            // forTesting
            return 1e15;
        }
        AggregatorV3Interface priceFeed = AggregatorV3Interface(dataFeed);
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return 1e26 / uint256(price);
    }

    function getUSCentInWEI() public view returns (uint256) {
        return getUSDInWEI() / 100;
    }

    event CampaignCreated(
        address campaignAddress,
        address campaignOwner,
        string campaignId,
        address prizeAddress,
        uint256 prizeAmount,
        uint256 maxEntries,
        uint256 startTimestamp,
        uint256 endTimestamp
    );

    constructor(
        address payable _owner,
        address _campaignOwner,
        string memory _campaignId,
        address _prizeAddress,
        uint256 _prizeAmount,
        uint256 _maxEntries,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        bytes32 _sealedSeed,
        uint256 _deposit,
        uint256 _fee
    ) {
        owner = _owner;
        campaignOwner = _campaignOwner;
        campaignId = _campaignId;
        prizeAddress = _prizeAddress;
        prizeAmount = _prizeAmount;
        maxEntries = _maxEntries;
        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;
        sealedSeed = _sealedSeed;
        oldRand = uint256(_sealedSeed);
        uint256 cent = getUSCentInWEI();
        feeAmount = cent * _fee;
        depositAmount = cent * _deposit;
    }

    function getDetail()
        public
        view
        returns (
            address _campaignOwner,
            string memory _campaignId,
            address _prizeAddress,
            uint256 _prizeAmount,
            uint256 _maxEntries,
            uint256 _startTimestamp,
            uint256 _endTimestamp,
            uint256 _entryCount
        )
    {
        return (
            campaignOwner,
            campaignId,
            prizeAddress,
            prizeAmount,
            maxEntries,
            startTimestamp,
            endTimestamp,
            length
        );
    }

    function hashMessage(address _user, uint256 _timestamp)
        public
        view
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(this, _user, _timestamp));
    }

    function isStarted() public view returns (bool) {
        return block.timestamp >= startTimestamp;
    }

    function isNotClosed() public view returns (bool) {
        return block.timestamp < endTimestamp;
    }

    function isNotFull() public view returns (bool) {
        return length < maxEntries;
    }

    function isCancelled() public view returns (bool) {
        return cancelled;
    }

    function isDepositReceived() public view returns (bool) {
        return depositReceived;
    }

    function hasEntered(address _user) public view returns (bool) {
        return chain[_user] != address(0);
    }

    function getStatus()
        public
        view
        returns (
            bool _hasEntered,
            bool _isStarted,
            bool _isNotClosed,
            uint256 _totalEntries,
            uint256 _maxEntries,
            uint256 _fee
        )
    {
        return (
            hasEntered(msg.sender),
            isStarted(),
            isNotClosed(),
            length,
            maxEntries,
            feeAmount
        );
    }

    function getFee() public view returns (uint256) {
        return feeAmount;
    }

    function getEntryCount() public view returns (uint256) {
        return length;
    }

    function deposit() public payable {
        require(msg.sender == campaignOwner, "Only campaign owner can deposit");
        require(!depositReceived, "Deposit has already been received");
        require(!isCancelled(), "Campaign has been cancelled");
        require(isNotClosed(), "Campaign has ended");
        require(msg.value >= depositAmount, "You need to pay the deposit");
        depositReceived = true;
    }

    function getDepositAmount() public view returns (uint256) {
        return depositAmount;
    }

    function setEntry(
        uint256 _timestamp,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) public payable {
        require(isNotFull(), "Already reached the maximum number of entries");
        require(isStarted(), "Campaign has not started yet");
        require(isNotClosed(), "Campaign has ended");
        require(!isCancelled(), "Campaign has been cancelled");
        require(
            _timestamp + 5 minutes > block.timestamp,
            "Timestamp is not valid"
        );
        require(chain[msg.sender] == address(0), "You have already entered");
        require(msg.value >= feeAmount, "You need to pay the fee");

        bytes32 message = hashMessage(msg.sender, _timestamp);

        require(
            ecrecover(message, v, r, s) == owner,
            "You need signatures from the owner to set an entry"
        );

        uint256 rand = uint256(
            keccak256(abi.encodePacked(message, oldRand, length))
        );

        if (length == 0) {
            chain[msg.sender] = msg.sender;
            cursorMap[0] = msg.sender;
        } else {
            address cursor = cursorMap[rand % length];
            chain[msg.sender] = chain[cursor];
            chain[cursor] = msg.sender;
            cursorMap[length] = msg.sender;
        }
        length++;
        oldRand = rand;
    }

    function withdraw() public {
        require(!isNotClosed(), "Campaign has not ended yet");
        require(msg.sender == owner, "You are not the owner of the campaign");
        uint256 amount = length * feeAmount;
        if (isCancelled()) amount = getPaybackAmount();
        payable(owner).transfer(amount);
    }

    function withdrawAll() public {
        require(msg.sender == owner, "You are not the owner of the campaign");
        require(
            endTimestamp + 364 days < block.timestamp,
            "Campaign has not ended yet"
        );
        payable(owner).transfer(address(this).balance);
    }

    function getPaybackAmount() public view returns (uint256) {
        return (length * feeAmount) / 2;
    }

    function payback() public payable {
        require(
            msg.sender == campaignOwner,
            "You are not the owner of the campaign"
        );
        require(revealBlockNumber == 0, "Campaign has already been revealed");
        require(!isCancelled(), "Campaign has been cancelled already");

        require(
            msg.value >= getPaybackAmount(),
            "You need to pay 1/2 of the fee that user paid"
        );
        if (isDepositReceived()) payable(campaignOwner).transfer(depositAmount);
        cancelled = true;
    }

    function paybackWithdraw() public {
        require(isCancelled(), "Campaign has not been cancelled");
        require(
            chain[msg.sender] != address(0),
            "You don't have right to withdraw"
        );
        chain[msg.sender] = address(0);
        payable(msg.sender).transfer(feeAmount);
    }

    function revealSeed(bytes32 _seed) public {
        require(!isNotClosed(), "Campaign has not ended yet");
        require(!isCancelled(), "Campaign has been cancelled");
        require(revealBlockNumber == 0, "Seed has already been revealed");
        require(
            block.timestamp > endTimestamp + 7 days ||
                msg.sender == campaignOwner,
            "You can not reveal the seed"
        );
        require(
            keccak256(abi.encodePacked(campaignId, _seed)) == sealedSeed,
            "Seed is not correct"
        );
        revealBlockNumber = block.number + 1;
        confirmationEndTime = block.timestamp + 10 minutes;
        revealedSeed = _seed;
        if (isDepositReceived()) payable(msg.sender).transfer(depositAmount);
    }

    function canDraw() public view returns (bool) {
        return
            revealBlockNumber != 0 &&
            revealBlockNumber + 10 < block.number &&
            confirmationEndTime < block.timestamp;
    }

    function draw() public view returns (address[] memory _winners) {
        require(canDraw(), "Seed has not been confirmed yet");

        uint256 rand = uint256(
            keccak256(
                abi.encodePacked(blockhash(revealBlockNumber), revealedSeed)
            )
        );

        address[] memory winners = new address[](prizeAmount);
        uint256 winnerNum = prizeAmount < length ? prizeAmount : length;
        address cursor = cursorMap[rand % length];
        for (uint256 i = 0; i < winnerNum; i++) {
            winners[i] = chain[cursor];
            cursor = chain[cursor];
        }
        for (uint256 i = winnerNum; i < prizeAmount; i++) {
            winners[i] = campaignOwner;
        }

        return winners;
    }
}