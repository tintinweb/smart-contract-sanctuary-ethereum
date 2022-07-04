/**
 *Submitted for verification at Etherscan.io on 2022-07-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract ReEntrancyGuard {
    bool internal locked;

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }
}

contract Pinball is ReEntrancyGuard {
    address private immutable owner;
    address private machine;
    uint256 private playFee = 0.01 ether;
    uint256 private accuDiscount = 200;
    uint256 private initReward = 0.05 ether;
    uint256 private waitTimes = 5;
    uint256 public playCount;
    uint256 public accuReward;
    uint256 public StrengthMax = 100;
    uint256 public StrengthMin = 30;
    address[] public winPlayers;
    uint256[] public winAmount;
    mapping(address => uint) public rewardList;

    modifier onlyOwner() {
        require(msg.sender == owner, "You need to be owner");
        _;
    }

    modifier onlyMachineOrOwner() {
        require(
            msg.sender == machine || msg.sender == owner,
            "You need to be machine or owner"
        );
        _;
    }

    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    /* Events */
    event ShootBall(address player, uint256 strength, uint256 newReward);
    event GetWinner(address player, uint256 oldReward, uint256 newReward);
    event NewAccuReward(uint256 accuReward);
    event NewPlayFee(uint256 playFee);

    // Payable constructor can receive Ether
    constructor(
        address _machine_address,
        uint256 _playFee,
        uint256 _initReward,
        uint256 _waitTimes
    ) {
        owner = payable(msg.sender);
        machine = _machine_address;
        playFee = _playFee;
        initReward = _initReward;
        accuReward = initReward;
        waitTimes = _waitTimes;
    }

    function shoot(uint256 strength) external payable {
        require(msg.value >= playFee, "You need to spend enough play fee.");
        require(strength <= StrengthMax, "You pull too hard.");
        require(strength >= StrengthMin, "You pull too weak.");
        playCount += 1;
        if (playCount > waitTimes)
            accuReward += (playFee * (1000 - accuDiscount)) / 1000;
        emit ShootBall(msg.sender, strength, accuReward);
    }

    function hit(address winner) external onlyMachineOrOwner noReentrant {
        uint256 tmpAccuReward;
        // if (accuReward > address(this).balance)
        // accuReward = address(this).balance;
        require(accuReward > 0, "Contract not enough Ether");
        rewardList[winner] += accuReward;
        tmpAccuReward = accuReward;
        accuReward = initReward;
        playCount = 0;
        winPlayers.push(winner);
        winAmount.push(tmpAccuReward);

        emit GetWinner(winner, tmpAccuReward, accuReward);
    }

    function getReward() external noReentrant {
        uint256 reward = rewardList[msg.sender];
        require(reward > 0, "You have no reward");
        rewardList[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: reward}("");
        require(success, "Failed to send Ether to winner");
    }

    function withdraw() external onlyOwner {
        uint amount = address(this).balance;
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Failed to send Ether");
    }

    // Set function
    function setMachine(address _newMachine) public onlyOwner {
        require(_newMachine != address(0), "Cannot be zero address");
        machine = _newMachine;
    }

    function setPlayFee(uint256 _newPlayFee) public onlyOwner {
        playFee = _newPlayFee;
        emit NewPlayFee(playFee);
    }

    function setInitReward(uint256 _newReward) public onlyOwner {
        initReward = _newReward;
    }

    function setAccuDiscount(uint256 _newDiscount) public onlyOwner {
        require(_newDiscount <= 1000, "Need under 1000");
        accuDiscount = _newDiscount;
    }

    function setAccuReward(uint256 _newReward) public onlyOwner {
        accuReward = _newReward;
        emit NewAccuReward(accuReward);
    }

    function setWaitTimes(uint256 _waitTimes) public onlyOwner {
        waitTimes = _waitTimes;
    }

    // Get function
    function getOwner() public view returns (address) {
        return owner;
    }

    function getMachine() public view returns (address) {
        return machine;
    }

    function getAccuReward() public view returns (uint256) {
        return accuReward;
    }

    function getPlayFee() public view returns (uint256) {
        return playFee;
    }

    function getWaitTimes() public view returns (uint256) {
        return waitTimes;
    }

    function getAddressToReward(address player) public view returns (uint256) {
        return rewardList[player];
    }

    // helper
    function _isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}