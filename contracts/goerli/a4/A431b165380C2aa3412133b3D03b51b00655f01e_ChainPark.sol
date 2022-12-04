// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

// import IERC20 from openzeppelin
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract IUBPC is IERC20 {
    function mint(address account, uint256 amount) public virtual;

    function claim_airdrop() public virtual;

    function setChainPark(address _chainParkAddr) public virtual;
}

contract ChainPark {
    // In reality this would be set to 1 day, but for testing purposes we set it to 1 minute
    uint256 public constant CLAIM_WAIT_PERIOD = 1 minutes; // 1 day
    // We dont want to wait days to be able to test claim, so we set it to 1 minute

    address admin;
    address public UBPC_CONTRACT; // address of the UBParkingCredits contract

    uint256 public maxFee; // the cost to park if you are the last person to park
    uint256 public dailyIncome; // the amount you will earn if you do not park for a day

    uint256 staffLot; // lotIndex of lot that is reserved for staff
    mapping(address => bool) staff;

    mapping(address => uint256) lastClaimed; // timestamp
    mapping(address => uint256) parksSinceClaim;

    mapping(address => uint256) public currentlyParked; // 0 if not parked, otherwise lotIndex

    uint256[] public lotMaxCapacities; // index 0 is not used. Lots are 1-indexed so that 0 can be used to represent not parked
    uint256[] public lotCurrentCapacities;

    event Parked(address indexed user, uint256 lotIndex);
    event Left(address indexed user, uint256 lotIndex);
    event Claimed(address indexed user, uint256 amount);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
        _;
    }

    modifier notFull(uint256 lotIndex) {
        require(
            lotCurrentCapacities[lotIndex] < lotMaxCapacities[lotIndex],
            "Lot is full."
        );
        _;
    }

    constructor(
        uint256[] memory _lotMaxCapacities,
        address _ubpcContractAddr,
        uint256 _maxFee,
        uint256 _dailyIncome,
        uint256 _staffLot
    ) {
        admin = msg.sender;
        lotMaxCapacities = _lotMaxCapacities;
        lotCurrentCapacities = new uint256[](_lotMaxCapacities.length);
        UBPC_CONTRACT = _ubpcContractAddr;
        maxFee = _maxFee;
        dailyIncome = _dailyIncome;
        staffLot = _staffLot;
    }

    function getFee(uint256 lotIndex) public view returns (uint256) {
        if (lotCurrentCapacities[lotIndex] == 0) {
            return 0; // free to park if no one is parked
        }
        return
            (maxFee * (lotCurrentCapacities[lotIndex] + 1)) /
            lotMaxCapacities[lotIndex];
    }

    function park(uint256 lotIndex) public notFull(lotIndex) {
        require(
            checkUBPCBalance(msg.sender) >= getFee(lotIndex),
            "Insufficient UBPC."
        );
        require(lotIndex != 0, "Lot index cannot be 0.");
        require(currentlyParked[msg.sender] == 0, "You are already parked.");

        if (lotIndex == staffLot) {
            require(staff[msg.sender], "Only staff can park in the staff lot.");
        }

        IUBPC(UBPC_CONTRACT).transferFrom(
            msg.sender,
            address(this),
            getFee(lotIndex)
        );

        lotCurrentCapacities[lotIndex]++;
        currentlyParked[msg.sender] = lotIndex;
        emit Parked(msg.sender, lotIndex);
    }

    function leave() public {
        require(currentlyParked[msg.sender] != 0, "You are not parked.");
        uint256 lotIndex = uint256(currentlyParked[msg.sender]);
        lotCurrentCapacities[lotIndex]--;
        currentlyParked[msg.sender] = 0;
        emit Left(msg.sender, lotIndex);
    }

    function claim() public {
        uint256 daysSinceClaim;
        if (lastClaimed[msg.sender] == 0) { // on first claim, set lastClaimed to now - wait period
            daysSinceClaim = block.timestamp - CLAIM_WAIT_PERIOD;
        } else {
            daysSinceClaim =
                (block.timestamp - lastClaimed[msg.sender]) /
                CLAIM_WAIT_PERIOD;
        }
        require(
            daysSinceClaim > parksSinceClaim[msg.sender],
            "You have not parked for a day."
        );
        uint256 amount = (daysSinceClaim - parksSinceClaim[msg.sender]) *
            dailyIncome; // you will not get paid for the days you parked
        lastClaimed[msg.sender] = block.timestamp;
        parksSinceClaim[msg.sender] = 0;
        mintUBPC(msg.sender, amount); // call mint function of UBPC contract
        emit Claimed(msg.sender, amount);
    }

    function checkUBPCBalance(address user) public view returns (uint256) {
        return IUBPC(UBPC_CONTRACT).balanceOf(user);
    }

    function mintUBPC(address account, uint256 amount) internal {
        IUBPC(UBPC_CONTRACT).mint(account, amount);
    }

    function withdraw() public onlyAdmin {
        payable(msg.sender).transfer(address(this).balance);
    }

    function getLotMaxCapacities() public view returns (uint256[] memory) {
        return lotMaxCapacities;
    }

    function getLotCurrentCapacities() public view returns (uint256[] memory) {
        return lotCurrentCapacities;
    }

    function setMaxCapacities(uint256[] memory _lotMaxCapacities)
        public
        onlyAdmin
    {
        lotMaxCapacities = _lotMaxCapacities;
    }

    function setMaxFee(uint256 _maxFee) public onlyAdmin {
        maxFee = _maxFee;
    }

    function setDailyIncome(uint256 _dailyIncome) public onlyAdmin {
        dailyIncome = _dailyIncome;
    }

    function setStaff(address _staffAddr) public onlyAdmin {
        staff[_staffAddr] = true;
    }

    function setAdmin(address _newAdmin) public onlyAdmin {
        admin = _newAdmin;
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