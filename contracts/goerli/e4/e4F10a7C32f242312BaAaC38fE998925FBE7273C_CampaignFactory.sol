// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

// import "../node_modules/@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract CampaignFactory {
    address payable public owner;
    mapping(string => address) public campaigns;

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
        bytes32 _sealedSeed
    ) public {
        require(
            campaigns[_campaignId] == address(0),
            "Campaign with this id already exists"
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
            _sealedSeed
        );

        campaigns[_campaignId] = address(c);
        emit campaignCreated(address(c));
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

contract Campaign {
    address payable owner;
    address public token;

    address public campaignOwner;
    address public prizeAddress;

    string public campaignId;

    uint256 public prizeAmount;
    uint256 public maxEntries;

    uint256 public startTimestamp;
    uint256 public endTimestamp;

    bytes32 sealedSeed;

    uint256 public revealBlockNumber;
    bytes32 public revealedSeed;

    mapping(uint256 => address) public entries;
    mapping(address => uint256) public entryAddress;

    uint256 totalEntries;

    address dataFeedAddress;

    uint256 fee;

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
        bytes32 _sealedSeed
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

        fee = getUSDInWEI(); //1 USD
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
            totalEntries
        );
    }

    function hashMessage(address _user) public view returns (bytes32) {
        bytes memory pack = abi.encodePacked(this, _user);
        return keccak256(pack);
    }

    function isStarted() public view returns (bool) {
        return block.timestamp >= startTimestamp;
    }

    function isNotClosed() public view returns (bool) {
        return block.timestamp < endTimestamp;
    }

    function isNotFull() public view returns (bool) {
        return totalEntries < maxEntries;
    }

    function hasEntered(address _user) public view returns (bool) {
        return entryAddress[_user] > 0;
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
            totalEntries,
            maxEntries,
            fee
        );
    }

    function getUSDInWEI() public view returns (uint256) {
        return 0;
    }

    function getFee() public view returns (uint256) {
        return fee;
    }

    function setEntry(
    ) public payable {
        require(isNotFull(), "Already reached the maximum number of entries");
        require(isStarted(), "Campaign has not started yet");
        require(isNotClosed(), "Campaign has ended");
        require(entryAddress[msg.sender] == 0, "You have already entered");

        // 1-origin
        totalEntries++;
        entries[totalEntries] = msg.sender;
        entryAddress[msg.sender] = totalEntries;
        owner.transfer(msg.value);
    }

    function getEntryCount() public view returns (uint256) {
        return totalEntries;
    }

    function revealSeed(bytes32 _seed) public {
        require(!isNotClosed(), "Campaign has not ended yet");
        require(revealBlockNumber == 0, "Seed has already been revealed");
        require(
            msg.sender == owner || msg.sender == campaignOwner,
            "You are not the owner of the campaign"
        );
        revealBlockNumber = block.number + 1;
        revealedSeed = _seed;
    }

    function draw() public view returns (address[] memory _winners) {
        require(
            revealBlockNumber != 0 && revealBlockNumber < block.number,
            "Seed has not been revealed yet"
        );

        address[] memory winners = new address[](prizeAmount);

        if (totalEntries > 0) {
            for (uint256 i = 0; i < prizeAmount; i++) {
                uint256 winnerId = (
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                blockhash(revealBlockNumber),
                                i,
                                revealedSeed
                            )
                        )
                    ) % totalEntries) + 1;

                winners[i] = entries[winnerId];
            }
        } else {
            for (uint256 i = 0; i < prizeAmount; i++) {
                winners[i] = campaignOwner;
            }
        }
        return winners;
    }
}