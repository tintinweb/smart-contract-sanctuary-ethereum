//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./Ownable.sol";

interface ITetherSucks {
    function allowance(address owner, address spender) external view returns (uint);
    function transferFrom(address from, address to, uint value) external;
    function transfer(address to, uint value) external returns (bool);
    function balanceOf(address user) external view returns (uint256);
}

contract SeedRound is Ownable {

    // Donor Structure
    struct Donor {
        uint256 totalDonated;
        mapping ( uint8 => uint256 ) donatedPerStage;
    }

    // Address => User
    mapping ( address => Donor ) public donors;

    // List Of All Donors
    address[] private _allDonors;

    // Total Amount Donated
    uint256 private _totalDonated;

    // Receiver Of Donation
    address private presaleReceiver = 0xc792e5FA3539FD1b469383D61361fFc01b91935f;

    // maximum contribution
    uint256 public min_contribution = 20 * 10**6;

    // soft / hard cap
    uint256 public hardCap = 3_000_000 * 10**6;

    // Stage Structure
    struct Stage {
        uint256 hardCap;
        uint256 totalDonated;
    }

    // Stage => Stage Structure
    mapping ( uint8 => Stage ) public stages;

    // Current Stage
    uint8 public currentStage;

    // sale has ended
    bool public hasStarted;

    // Raise Token
    ITetherSucks public raiseToken = ITetherSucks(0xdAC17F958D2ee523a2206206994597C13D831ec7);

    // Donation Event, Trackers Donor And Amount Donated
    event Donated(address donor, uint256 amountDonated, uint256 totalInSale, uint256 totalInStage);


    constructor () {

        stages[0].hardCap = 2_000_000 * 10**6;
        stages[1].hardCap = 1_250_000 * 10**6;
        stages[2].hardCap = 1_500_000 * 10**6;
        stages[3].hardCap = 1_750_000 * 10**6;
        stages[4].hardCap = 2_000_000 * 10**6;
        stages[5].hardCap = 2_250_000 * 10**6;
        stages[6].hardCap = 2_500_000 * 10**6;
        stages[7].hardCap = 2_750_000 * 10**6;
        stages[8].hardCap = 3_000_000 * 10**6;
        stages[9].hardCap = 19_000_000 * 10**6;

        changeOwner(0xc792e5FA3539FD1b469383D61361fFc01b91935f);
    }

    function startSale() external onlyOwner {
        hasStarted = true;
    }

    function endSale() external onlyOwner {
        hasStarted = false;
    }

    function withdraw(ITetherSucks token_) external onlyOwner {
        token_.transfer(presaleReceiver, token_.balanceOf(address(this)));
    }

    function setMinContribution(uint min) external onlyOwner {
        min_contribution = min;
    }

    function setHardCap(uint8 stage, uint hardCap_) external onlyOwner {
        stages[stage].hardCap = hardCap_;
    }

    function setPresaleReceiver(address newReceiver) external onlyOwner {
        require(
            newReceiver != address(0),
            'Zero Address'
        );
        presaleReceiver = newReceiver;
    }

    function nextStage() external onlyOwner {
        currentStage++;
    }

    function donate(uint256 amount) external {
        uint received = _transferIn(amount);
        _process(msg.sender, received);
    }

    function currentHardCap() external view returns (uint256) {
        return stages[currentStage].hardCap;
    }

    function currentRaise() external view returns (uint256) {
        return stages[currentStage].totalDonated;
    }

    function donated(address user, uint8 stage) external view returns(uint256) {
        return donors[user].donatedPerStage[stage];
    }

    function totalUserDonated(address user) external view returns(uint256) {
        return donors[user].totalDonated;
    }

    function allDonors() external view returns (address[] memory) {
        return _allDonors;
    }

    function allDonorsAndDonationAmounts() external view returns (address[] memory, uint256[] memory) {
        uint len = _allDonors.length;
        uint256[] memory amounts = new uint256[](len);

        for (uint i = 0; i < len;) {
            amounts[i] = donors[_allDonors[i]].totalDonated;
            unchecked { ++i; }
        }
        return (_allDonors, amounts);
    }

    function amountDonatedAtEachStage(address user) external view returns (uint256[] memory) {
        uint len = currentStage + 1;
        uint256[] memory amounts = new uint256[](len);

        for (uint i = 0; i < len;) {
            amounts[i] = donors[user].donatedPerStage[uint8(i)];
            unchecked { ++i; }
        }
        return (amounts);
    }

    function donorAtIndex(uint256 index) external view returns (address) {
        return _allDonors[index];
    }

    function numberOfDonors() external view returns (uint256) {
        return _allDonors.length;
    }

    function totalDonated() external view returns (uint256) {
        return _totalDonated;
    }

    function _process(address user, uint amount) internal {
        require(
            amount > 0,
            'Zero Amount'
        );
        require(
            hasStarted,
            'Sale Has Not Started'
        );

        // add to donor list if first donation
        if (donors[user].totalDonated == 0) {
            _allDonors.push(user);
        }

        // increment amounts donated
        unchecked {
            stages[currentStage].totalDonated += amount;
            donors[user].totalDonated += amount;
            donors[user].donatedPerStage[currentStage] += amount;
            _totalDonated += amount;
        }

        require(
            donors[user].donatedPerStage[currentStage] >= min_contribution,
            'Contribution too low'
        );
        require(
            stages[currentStage].totalDonated <= stages[currentStage].hardCap,
            'Hard Cap Reached'
        );
        emit Donated(user, amount, _totalDonated, stages[currentStage].totalDonated);
    }

    function _transferIn(uint amount) internal returns (uint256) {
        require(
            raiseToken.allowance(msg.sender, address(this)) >= amount,
            'Insufficient Allowance'
        );

        // to presale recipient
        raiseToken.transferFrom(
            msg.sender,
            presaleReceiver,
            amount
        );
        
        return amount;
    }
}