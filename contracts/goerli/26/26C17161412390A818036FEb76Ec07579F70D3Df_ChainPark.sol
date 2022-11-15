// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract ChainPark {
  address admin;
  uint256 public maxFee; // the cost to park if you are the last person to park
  uint dailyIncome; // the amount you will earn if you do not park for a day
  //uint constant NOT_PARKED = 2**256 - 1; // use max uint to represent not parked
  // mapping(address=>bool) staff;
  mapping(address=>uint) lastClaimed; // timestamp
  mapping(address=>uint) parksSinceClaim;
  mapping(address=>uint) public currentlyParked; // NOT_PARKED if not parked, otherwise lotIndex
  uint[] public lotMaxCapacities; // index 0 is not used. Lots are 1-indexed so that 0 can be used to represent not parked
  uint[] public lotCurrentCapacities;
  // enum lotType {Staff, Student, Both}
  // lotType[] lotTypes;

  event Parked(address indexed user, uint lotIndex);
  event Left(address indexed user, uint lotIndex);
  event Claimed(address indexed user, uint amount);

  modifier onlyAdmin() {
    require(msg.sender == admin, "Only admin can call this function.");
    _;
  }

  // modifier onlyStaff() {
  //   require(staff[msg.sender], "Only staff can call this function.");
  //   _;
  // }

  modifier notFull(uint lotIndex) {
    require(lotCurrentCapacities[lotIndex] < lotMaxCapacities[lotIndex], "Lot is full.");
    _;
  }

  constructor(uint[] memory _lotMaxCapacities, uint256 _maxFee, uint _dailyIncome) {
    maxFee = _maxFee;
    admin = msg.sender;
    lotMaxCapacities = _lotMaxCapacities;
    lotCurrentCapacities = new uint[](_lotMaxCapacities.length);
    dailyIncome = _dailyIncome;
  }


  function getFee(uint lotIndex) public view returns (uint) {
    if (lotCurrentCapacities[lotIndex] == 0) {
      return 0;
    }
    return maxFee * (lotCurrentCapacities[lotIndex] + 1) / lotMaxCapacities[lotIndex];
  }

  function park(uint lotIndex) public payable notFull(lotIndex) {
    require(msg.value >= getFee(lotIndex), "Insufficient funds.");
    require(lotIndex != 0, "Lot index cannot be 0.");
    require(currentlyParked[msg.sender] == 0, "You are already parked.");

    // if (lotTypes[lotIndex] == lotType.Staff) {
    //   parkStaff(lotIndex);
    // } else {
    //   parkStudent(lotIndex);
    // }

    lotCurrentCapacities[lotIndex]++;
    currentlyParked[msg.sender] = lotIndex;
    emit Parked(msg.sender, lotIndex);
  }

  // function parkStudent(uint lotIndex) private {
  //   require(lotTypes[lotIndex] != lotType.Staff, "This lot is for staff only.");
  //   lotCurrentCapacities[lotIndex]++;
  //   currentlyParked[msg.sender] = lotIndex;
  //   emit Parked(msg.sender, lotIndex);
  // }

  // function parkStaff(uint lotIndex) private onlyStaff {
  //   require(lotTypes[lotIndex] != lotType.Student, "This lot is for students only.");
  //   lotCurrentCapacities[lotIndex]++;
  //   currentlyParked[msg.sender] = lotIndex;
  //   emit Parked(msg.sender, lotIndex);
  // }

  function leave() public {
    require(currentlyParked[msg.sender] != 0, "You are not parked.");
    uint lotIndex = uint(currentlyParked[msg.sender]);
    lotCurrentCapacities[lotIndex]--;
    currentlyParked[msg.sender] = 0;
    emit Left(msg.sender, lotIndex);
  }

  function claim() public { // this will interact with the ERC20 token contract eventualy
    uint daysSinceClaim = (block.timestamp - lastClaimed[msg.sender]) / 1 days;
    require(daysSinceClaim > parksSinceClaim[msg.sender], "You have not parked for a day.");
    uint amount = (daysSinceClaim - parksSinceClaim[msg.sender]) * dailyIncome; // you will not get paid for the days you parked
    lastClaimed[msg.sender] = block.timestamp;
    parksSinceClaim[msg.sender] = 0;
    payable(msg.sender).transfer(amount);
    emit Claimed(msg.sender, amount);
  }

  function withdraw() public onlyAdmin {
    payable(msg.sender).transfer(address(this).balance);
  }

  // function addStaff(address staffMember) public onlyAdmin {
  //   staff[staffMember] = true;
  // }


  function setMaxCapacities(uint[] memory _lotMaxCapacities) public onlyAdmin {
    lotMaxCapacities = _lotMaxCapacities;
  }

  // function setLotTypes(lotType[] memory _lotTypes) public onlyAdmin {
  //   lotTypes = _lotTypes;
  // }

  function setMaxFee(uint256 _maxFee) public onlyAdmin {
    maxFee = _maxFee;
  }

  function setDailyIncome(uint _dailyIncome) public onlyAdmin {
    dailyIncome = _dailyIncome;
  }

  function setAdmin(address newAdmin) public onlyAdmin {
    admin = newAdmin;
  }
}