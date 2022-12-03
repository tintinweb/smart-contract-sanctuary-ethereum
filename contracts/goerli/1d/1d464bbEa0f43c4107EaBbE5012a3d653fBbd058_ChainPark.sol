// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

// import IERC20 from openzeppelin
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ChainPark {
  address admin;
  IERC20 UBPC_CONTRACT;
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

  constructor(uint[] memory _lotMaxCapacities, address _ubpcContractAddr, uint256 _maxFee, uint _dailyIncome) {
    admin = msg.sender;
    lotMaxCapacities = _lotMaxCapacities;
    lotCurrentCapacities = new uint[](_lotMaxCapacities.length);
    UBPC_CONTRACT = IERC20(_ubpcContractAddr);
    maxFee = _maxFee;
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

  function getLotMaxCapacities() public view returns (uint[] memory) {
    return lotMaxCapacities;
  }

  function getLotCurrentCapacities() public view returns (uint[] memory) {
    return lotCurrentCapacities;
  }

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