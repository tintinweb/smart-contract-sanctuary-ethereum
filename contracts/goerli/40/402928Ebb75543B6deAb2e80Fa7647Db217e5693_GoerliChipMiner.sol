// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract GoerliChipMiner {
    // constants
    uint constant GOERLICHIP_TO_MINING_MINER = 1080000;
    uint constant PSN = 10000;
    uint constant PSNH = 5000;

    // attributes
    uint public marketGoerliChip;
    uint public startTime = 6666666666;
    address public owner;
    address public address2;
    mapping(address => uint) private lastmining;
    mapping(address => uint) private miningminers;
    mapping(address => uint) private claimedGoerliChip;
    mapping(address => uint) private tempClaimedGoerliChip;
    mapping(address => address) private referrals;
    mapping(address => ReferralData) private referralData;

    // structs
    struct ReferralData {
        address[] invitees;
        uint rebates;
    }

    // modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    modifier onlyOpen() {
        require(block.timestamp > startTime, "not open");
        _;
    }

    modifier onlyStartOpen() {
        require(marketGoerliChip > 0, "not start open");
        _;
    }

    // events
    event Create(address indexed sender, uint indexed amount);
    event Merge(address indexed sender, uint indexed amount);

    constructor() {
        owner = msg.sender;
        address2 = 0x59Ae558980e9FDb66516D529dF59DC541dAdC1f9;
    }

    // Create GoerliChip
    function createGoerliChip(address _ref) external payable onlyStartOpen {
        uint GoerliChipDivide = calculateGoerliChipDivide(
            msg.value,
            address(this).balance - msg.value
        );
        GoerliChipDivide -= devFee(GoerliChipDivide);
        uint fee = devFee(msg.value);

        // dev fee
        (bool ownerSuccess, ) = owner.call{value: (fee * 35) / 100}("");
        require(ownerSuccess, "owner pay failed");
        (bool address2Success, ) = address2.call{value: (fee * 65) / 100}("");
        require(address2Success, "address2 pay failed");

        claimedGoerliChip[msg.sender] += GoerliChipDivide;
        divideGoerliChip(_ref);

        emit Create(msg.sender, msg.value);
    }

    // Divide GoerliChip
    function divideGoerliChip(address _ref) public onlyStartOpen {
        if (_ref == msg.sender || _ref == address(0) || miningminers[_ref] == 0) {
            _ref = owner;
        }

        if (referrals[msg.sender] == address(0)) {
            referrals[msg.sender] = _ref;
            referralData[_ref].invitees.push(msg.sender);
        }

        uint GoerliChipUsed = getMyGoerliChip(msg.sender);
        uint newminers = GoerliChipUsed / GOERLICHIP_TO_MINING_MINER;
        miningminers[msg.sender] += newminers;
        claimedGoerliChip[msg.sender] = 0;
        lastmining[msg.sender] = block.timestamp > startTime ? block.timestamp : startTime;

        // referral rebate
        uint GoerliChipRebate = (GoerliChipUsed * 13) / 100;
        if (referrals[msg.sender] == owner) {
            claimedGoerliChip[owner] += (GoerliChipRebate * 35) / 100;
            claimedGoerliChip[address2] += (GoerliChipRebate * 65) / 100;
            tempClaimedGoerliChip[owner] += (GoerliChipRebate * 35) / 100;
            tempClaimedGoerliChip[address2] += (GoerliChipRebate * 65) / 100;
        } else {
            claimedGoerliChip[referrals[msg.sender]] += GoerliChipRebate;
            tempClaimedGoerliChip[referrals[msg.sender]] += GoerliChipRebate;
        }

        marketGoerliChip += GoerliChipUsed / 5;
    }

    // Merge GoerliChip
    function mergeGoerliChip() external onlyOpen {
        uint hasGoerliChip = getMyGoerliChip(msg.sender);
        uint GoerliChipValue = calculateGoerliChipMerge(hasGoerliChip);
        uint fee = devFee(GoerliChipValue);
        uint realReward = GoerliChipValue - fee;

        if (tempClaimedGoerliChip[msg.sender] > 0) {
            referralData[msg.sender].rebates += calculateGoerliChipMerge(
                tempClaimedGoerliChip[msg.sender]
            );
        }

        // dev fee
        (bool ownerSuccess, ) = owner.call{value: (fee * 35) / 100}("");
        require(ownerSuccess, "owner pay failed");
        (bool address2Success, ) = address2.call{value: (fee * 65) / 100}("");
        require(address2Success, "address2 pay failed");

        claimedGoerliChip[msg.sender] = 0;
        tempClaimedGoerliChip[msg.sender] = 0;
        lastmining[msg.sender] = block.timestamp;
        marketGoerliChip += hasGoerliChip;

        (bool success1, ) = msg.sender.call{value: realReward}("");
        require(success1, "msg.sender pay failed");

        emit Merge(msg.sender, realReward);
    }

    // only owner
    function seedMarket(uint _startTime) external payable onlyOwner {
        require(marketGoerliChip == 0);
        startTime = _startTime;
        marketGoerliChip = 108000000000;
    }

    function GoerliChipRewards(address _address) public view returns (uint) {
        return calculateGoerliChipMerge(getMyGoerliChip(_address));
    }

    function getMyGoerliChip(address _address) public view returns (uint) {
        return claimedGoerliChip[_address] + getGoerliChipSinceLastDivide(_address);
    }

    function getClaimGoerliChip(address _address) public view returns (uint) {
        return claimedGoerliChip[_address];
    }

    function getGoerliChipSinceLastDivide(address _address) public view returns (uint) {
        if (block.timestamp > startTime) {
            uint secondsPassed = min(
                GOERLICHIP_TO_MINING_MINER,
                block.timestamp - lastmining[_address]
            );
            return secondsPassed * miningminers[_address];
        } else {
            return 0;
        }
    }

    function getTempClaimGoerliChip(address _address) public view returns (uint) {
        return tempClaimedGoerliChip[_address];
    }

    function getPoolAmount() public view returns (uint) {
        return address(this).balance;
    }

    function getminingminers(address _address) public view returns (uint) {
        return miningminers[_address];
    }

    function getReferralData(address _address) public view returns (ReferralData memory) {
        return referralData[_address];
    }

    function getReferralAllRebate(address _address) public view returns (uint) {
        return referralData[_address].rebates;
    }

    function getReferralAllInvitee(address _address) public view returns (uint) {
        return referralData[_address].invitees.length;
    }

    function calculateGoerliChipDivide(
        uint _eth,
        uint _contractBalance
    ) private view returns (uint) {
        return calculateTrade(_eth, _contractBalance, marketGoerliChip);
    }

    function calculateGoerliChipMerge(uint GoerliChip) public view returns (uint) {
        return calculateTrade(GoerliChip, marketGoerliChip, address(this).balance);
    }

    function calculateTrade(uint256 rt, uint256 rs, uint256 bs) private pure returns (uint) {
        return (PSN * bs) / (PSNH + ((PSN * rs + PSNH * rt) / rt));
    }

    function devFee(uint _amount) private pure returns (uint) {
        return (_amount * 288) / 10000;
    }

    function min(uint a, uint b) private pure returns (uint) {
        return a < b ? a : b;
    }
}