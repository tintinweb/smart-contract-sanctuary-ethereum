pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

//     _ \                           |                   |
//    |   |   |   |    _` |    __|   __|    _ \    __|   |   |   |
//    |   |   |   |   (   |   |      |      __/   |      |   |   |
//   \__\_\  \__,_|  \__,_|  _|     \__|  \___|  _|     _|  \__, |
//                                                          ____/
//            __ )                              |
//            __ \     _ \    __ \    |   |    __)
//            |   |   (   |   |   |   |   |  \__ \
//           ____/   \___/   _|  _|  \__,_|  (   /
//                                             _|

contract QuarterlyBonus { 
    address payable private owner;
    address payable private burnWallet;
    mapping(address => bool) private Employees;
    
    address payable[] public aEmployees;
    uint256 public lastReset;
    uint256 public lastQtrPayout;
    uint256 private oneWeek;
    uint256 public quarterlyBonus;
    uint256 public thePot;
    uint256 private aDay;
    uint256 private round;
    uint256 private aQuarter;
    uint256 private approxGas;
    uint256 public payout;

    bool locked = false;

    mapping(address => uint256) public magicEarnyPoints;
    mapping(address => uint256) private earningsPerSecond;
    mapping(address => uint256) private redeemable;
    mapping(address => uint256) private lastRedeem;
    

    constructor() payable {
        owner = payable(0x502221275CdAB7502182979a26A3841e5F6C9Fca);
        burnWallet = payable(0xDeaDbeefdEAdbeefdEadbEEFdeadbeEFdEaDbeeF);
        lastReset = block.timestamp;
        lastQtrPayout = block.timestamp;
        thePot = msg.value;
        quarterlyBonus = 0;
        oneWeek = 604800;
        aDay = 86400;
        round = 0;
        aQuarter = 7890000;
        approxGas = 69651;
    }

    function getLastReset() public view returns (uint256) {
      return lastReset;
    }

    function hireEmployee(address payable _employee) private {
        Employees[_employee] = true;
        aEmployees.push(_employee);
    }

    function contains(address _employee) private view returns (bool) {
        return Employees[_employee];
    }

    function buyin() external payable {
        require(!locked, "Reentrant call detected!");
        locked = true;

        if (
            magicEarnyPoints[msg.sender] + msg.value >= 5 ether &&
            !contains(msg.sender)
        ) {
            hireEmployee(payable(msg.sender));
        }
        if (
            block.timestamp - lastReset > oneWeek &&
            address(this).balance < 1 ether
        ) {
            magicEarnyPoints[msg.sender] = 0;
            earningsPerSecond[msg.sender] = 0;
            redeemable[msg.sender] = 0;
            round += 1;
        }

        if (block.timestamp - lastQtrPayout > aQuarter) {
            payout =
                quarterlyBonus /
                aEmployees.length;

            for (uint256 i = 0; i < aEmployees.length; i++) {
                bool success = payable(aEmployees[i]).send(payout);
                require(success, "Payout failed.");
            }
            delete aEmployees;
            lastQtrPayout = block.timestamp;
        }

        magicEarnyPoints[msg.sender] += msg.value;
        // Deposits
        uint256 left = msg.value;
        uint256 devFee = msg.value / 13;

        bool devsuccess = payable(owner).send(devFee);
        require(devsuccess, ".send failed.");
        left -= devFee;
        
        quarterlyBonus += msg.value / 40;
        left -= msg.value / 40;
        
        bool burnsuccess = payable(burnWallet).send(msg.value / 256);
        require(burnsuccess, "Burn failed.");
        left -= msg.value / 256;
        
        thePot += left;
        
        locked = false;
        calcRedeemable();
    }

    function calcRedeemable() private {
        require(!locked, "Reentrant call detected!");
        locked = true;
        uint256 timeElapsedThisRound = block.timestamp - lastRedeem[msg.sender];

        earningsPerSecond[msg.sender] =
            magicEarnyPoints[msg.sender] /
            10 /
            aDay;
        redeemable[msg.sender] =
            earningsPerSecond[msg.sender] *
            timeElapsedThisRound;
        locked = false;
    }

    function getRedeemable() public returns (uint256) {
        calcRedeemable();
        return redeemable[msg.sender];
    }

    function redeem() public payable {
        uint256 amount = getRedeemable();
        require(!locked, "Reentrant call detected!");
        locked = true;
        // Deposits
        uint256 pay = amount;
        uint256 devFee = amount / 13;

        bool devsuccess = payable(owner).send(devFee);
        require(devsuccess, ".send failed.");
        pay -= devFee;
        quarterlyBonus += amount / 40;
        pay -= amount / 40;
        bool burnsuccess = payable(burnWallet).send(amount / 256);
        require(burnsuccess, "Burn failed.");
        pay -= amount / 256;

        bool success = payable(msg.sender).send(pay);
        require(success, ".send failed.");

        thePot -= amount;
        lastRedeem[msg.sender] = block.timestamp;
        redeemable[msg.sender] = 0;
        locked = false;
    }

    function getMagicEarnyPoints() public view returns(uint256) {
        return magicEarnyPoints[msg.sender];
    }
    function compound() public {
        calcRedeemable();
        require(!locked, "Reentrant call detected!");
        locked = true;

        magicEarnyPoints[msg.sender] += redeemable[msg.sender];
        redeemable[msg.sender] = 0;

        locked = false;
    }
}