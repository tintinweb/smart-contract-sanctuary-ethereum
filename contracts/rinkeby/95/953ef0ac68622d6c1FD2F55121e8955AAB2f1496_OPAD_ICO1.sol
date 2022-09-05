// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IVesting.sol";
import './interfaces/IOPAD.sol';

contract OPAD_ICO1 {
    using SafeMath for uint256;

    address private owner;

    struct PresaleBuyer {
        uint256 amountDepositedBUSD; // BUSD amount per recipient.
        uint256 amountOPAD; // Rewards token that needs to be vested.
    }

    mapping(address => PresaleBuyer) public recipients; // Presale Buyers

    uint256 public priceRate = 80; // OPAD : BUSD = 1 : 0.0125 = 80 : 1
    uint256 public MIN_ALLOC_BUSD = 200 * 1e18; // BUSD min allocation for each presale buyer
    uint256 public MAX_ALLOC_BUSD = 20000 * 1e18; // BUSD max allocation for each presale buyer
    uint256 public MIN_ALLOC_OPAD = priceRate * MIN_ALLOC_BUSD; // min OPAD allocation for each presale buyer
    uint256 public MAX_ALLOC_OPAD = priceRate * MAX_ALLOC_BUSD; // max OPAD allocation for each presale buyer
    uint256 public TotalPresaleAmnt = 1e6 * 1e18; // Total OPADToken amount for presale : 100,0000 OPAD
    
    uint256 public startTime; // Presale start time
    uint256 public PERIOD; // Presale Period
    address payable public multiSigAdmin; // MultiSig contract address : The address where to withdraw funds token to after presale

    // address public BUSD_Addr = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174; // BUSD on mainnet
    address public BUSD_Addr = 0x8E231c5A2A3675C875923A7749d6DC2D38F7f019; // BUSD on rinkeby

    bool private isPresaleStarted;
    uint256 public soldOPADAmount;

    IOPAD public OPADToken; // Rewards Token : Token for distribution as rewards.
    IERC20 public BUSDToken; // BUSD token contract
    IVesting private vestingContract; // Vesting Contract

    event PrevParticipantsRegistered(address[], uint256[],  uint256[]);
    event PresaleRegistered(address _registeredAddress, uint256 _weiAmount, uint256 _OPADAmount);
    event PresaleStarted(uint256 _startTime);
    event PresalePaused(uint256 _endTime);
    event PresalePeriodUpdated(uint256 _newPeriod);
    event MultiSigAdminUpdated(address _multiSigAdmin);

    /********************** Modifiers ***********************/
    modifier onlyOwner() {
        require(owner == msg.sender, "Requires Owner Role");
        _;
    }

    modifier whileOnGoing() {
        require(block.timestamp >= startTime, "Presale has not started yet");
        require(block.timestamp <= startTime + PERIOD, "Presale has ended");
        require(isPresaleStarted, "Presale has ended or paused");
        _;
    }

    modifier whileFinished() {
        require(block.timestamp > startTime + PERIOD, "Presale has not ended yet!");
        _;
    }

    modifier whileDeposited() {
        require(getDepositedOPAD() >= TotalPresaleAmnt, "Deposit enough OPAD tokens to the vesting contract first!");
        _;
    }

    constructor(address _OPADToken, address payable _multiSigAdmin) {
        owner = msg.sender;

        OPADToken = IOPAD(_OPADToken);
        BUSDToken = IERC20(BUSD_Addr);
        multiSigAdmin = _multiSigAdmin;
        PERIOD = 3 days;

        isPresaleStarted = false;
    }

    /********************** Internal ***********************/
    
    /**
     * @dev Get the OPADToken amount of vesting contract
     */
    function getDepositedOPAD() internal view returns (uint256) {
        address addrVesting = address(vestingContract);
        return OPADToken.balanceOf(addrVesting);
    }

    /**
     * @dev Get remaining OPADToken amount of vesting contract
     */
    function getUnsoldOPAD() internal view returns (uint256) {
        uint256 totalDepositedOPAD = getDepositedOPAD();
        return totalDepositedOPAD.sub(soldOPADAmount);
    }

    /********************** External ***********************/
    
    function remainingOPAD() external view returns (uint256) {
        return getUnsoldOPAD();
    }

    function isPresaleGoing() external view returns (bool) {
        return isPresaleStarted && block.timestamp >= startTime && block.timestamp <= startTime + PERIOD;
    }

    /**
     * @dev Start presale after checking if there's enough OPAD in vesting contract
     */
    function startPresale() external whileDeposited onlyOwner {
        require(!isPresaleStarted, "StartPresale: Presale has already started!");
        isPresaleStarted = true;
        startTime = block.timestamp;
        emit PresaleStarted(startTime);
    }

    /**
     * @dev Update Presale period
     */
    function setPresalePeriod(uint256 _newPeriod) external whileDeposited onlyOwner {
        PERIOD = _newPeriod;
        emit PresalePeriodUpdated(PERIOD);
    }

    /**
     * @dev Pause the ongoing presale by emergency
     */
    function pausePresaleByEmergency() external onlyOwner {
        isPresaleStarted = false;
        emit PresalePaused(block.timestamp);
    }

    /**
     * @dev All remaining funds will be sent to multiSig admin  
     */
    function setMultiSigAdminAddress(address payable _multiSigAdmin) external onlyOwner {
        require (_multiSigAdmin != address(0x00));
        multiSigAdmin = _multiSigAdmin;
        emit MultiSigAdminUpdated(multiSigAdmin);
    }

    function setOPADTokenAddress(address _OPADToken) external onlyOwner {
        require (_OPADToken != address(0x00));
        OPADToken = IOPAD(_OPADToken);
    }

    function setVestingContractAddress(address _vestingContract) external onlyOwner {
        require (_vestingContract != address(0x00));
        vestingContract = IVesting(_vestingContract);
    }

    /**
     * @dev function that sets price rate (OPAD : BUSD)
     */
    function setPriceRate(uint rate) external onlyOwner {
        priceRate = rate;
    }

    /**
     * @dev function that sets MIN_ALLOC_BUSD
     */
    function setMIN_ALLOC_BUSD(uint newMIN_ALLOC_BUSD) external onlyOwner {
        MIN_ALLOC_BUSD = newMIN_ALLOC_BUSD;
    }

    /**
     * @dev function that sets MAX_ALLOC_BUSD
     */
    function setMAX_ALLOC_BUSD(uint newMAX_ALLOC_BUSD) external onlyOwner {
        MAX_ALLOC_BUSD = newMAX_ALLOC_BUSD;
    }

    /**
     * @dev function that sets presale OPAD total amount
     */
    function setTotalPresaleAmnt(uint _totalPresaleAmnt) external onlyOwner {
        TotalPresaleAmnt = _totalPresaleAmnt;
    }

    /** 
     * @dev After presale ends, we withdraw BUSD tokens to the multiSig admin
     */ 
    function withdrawRemainingBUSDToken() external whileFinished onlyOwner returns (uint256) {
        require(multiSigAdmin != address(0x00), "Withdraw: Project Owner address hasn't been set!");

        uint256 BUSD_Balance = BUSDToken.balanceOf(address(this));
        require(BUSD_Balance > 0, "Withdraw: No BUSD balance to withdraw");

        BUSDToken.transfer(multiSigAdmin, BUSD_Balance);

        return BUSD_Balance;
    }

    /**
     * @dev After presale ends, we withdraw unsold OPADToken to multisig
     */ 
    function withdrawUnsoldOPADToken() external whileFinished onlyOwner returns (uint256) {
        require(multiSigAdmin != address(0x00), "Withdraw: Project Owner address hasn't been set!");
        require(address(vestingContract) != address(0x00), "Withdraw: Set vesting contract!");

        uint256 unsoldOPAD = getUnsoldOPAD();

        require(
            OPADToken.transferFrom(address(vestingContract), multiSigAdmin, unsoldOPAD),
            "Withdraw: can't withdraw OPAD tokens"
        );

        return unsoldOPAD;
    }

    /**
     * @dev Receive BUSD from presale buyers
     */ 
    function deposit(uint256 BUSD_amount) external payable whileOnGoing returns (uint256) {
        require(msg.sender != address(0x00), "Deposit: User address can't be null");
        require(multiSigAdmin != address(0x00), "Deposit: Project Owner address hasn't been set!");
        require(address(vestingContract) != address(0x00), "Withdraw: Set vesting contract!");
        require(BUSD_amount >= MIN_ALLOC_BUSD && BUSD_amount <= MAX_ALLOC_BUSD, "Deposit funds should be in range of MIN_ALLOC_BUSD ~ MAX_ALLOC_BUSD");

        BUSDToken.transferFrom(msg.sender, address(this), BUSD_amount); // Bring ICO contract address BUSD tokens from buyer
        uint256 newDepositedBUSD = recipients[msg.sender].amountDepositedBUSD.add(BUSD_amount);

        require(MAX_ALLOC_BUSD >= newDepositedBUSD, "Deposit: Can't exceed the MAX_ALLOC!");

        uint256 newOPADAmount = BUSD_amount.mul(priceRate);

        require(soldOPADAmount + newOPADAmount <= TotalPresaleAmnt, "Deposit: All sold out");

        recipients[msg.sender].amountDepositedBUSD = newDepositedBUSD;
        soldOPADAmount = soldOPADAmount.add(newOPADAmount);

        recipients[msg.sender].amountOPAD = recipients[msg.sender].amountOPAD.add(newOPADAmount);
        vestingContract.addNewRecipient(msg.sender, recipients[msg.sender].amountOPAD, true);

        require(BUSD_amount > 0, "Deposit: No BUSD balance to withdraw");

        BUSDToken.transfer(multiSigAdmin, BUSD_amount);

        emit PresaleRegistered(msg.sender, BUSD_amount, recipients[msg.sender].amountOPAD);

        return recipients[msg.sender].amountOPAD;
    }

    /**
     * @dev Update the data of participants who participated in presale before 
     * @param _oldRecipients the addresses to be added
     * @param _BUSDtokenAmounts integer array to indicate BUSD amount of participants
     * @param _OPADtokenAmounts integer array to indicate OPAD amount of participants
     */
    function addPreviousParticipants(address[] memory _oldRecipients, uint256[] memory _BUSDtokenAmounts, uint256[] memory _OPADtokenAmounts) external onlyOwner {
        for (uint256 i = 0; i < _oldRecipients.length; i++) {
            require(_BUSDtokenAmounts[i] >= MIN_ALLOC_BUSD && _BUSDtokenAmounts[i] <= MAX_ALLOC_BUSD, "addPreviousParticipants: BUSD amount should be in range of MIN_ALLOC_BUSD ~ MAX_ALLOC_BUSD");
            require(_OPADtokenAmounts[i] >= MIN_ALLOC_OPAD && _OPADtokenAmounts[i] <= MAX_ALLOC_OPAD, "addPreviousParticipants: OPAD amount should be in range of MIN_ALLOC_OPAD ~ MAX_ALLOC_OPAD");
            recipients[_oldRecipients[i]].amountDepositedBUSD = recipients[_oldRecipients[i]].amountDepositedBUSD.add(_BUSDtokenAmounts[i]);
            recipients[_oldRecipients[i]].amountOPAD = recipients[_oldRecipients[i]].amountOPAD.add(_OPADtokenAmounts[i]);
            soldOPADAmount = soldOPADAmount.add(_OPADtokenAmounts[i]);
        }

        emit PrevParticipantsRegistered(_oldRecipients, _BUSDtokenAmounts, _OPADtokenAmounts);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IVesting {
    function setVestingAllocation(uint256) external;
    function addNewRecipient(address, uint256, bool) external;
    function addNewRecipients(address[] memory, uint256[] memory, bool) external;
    function startVesting(uint256) external;
    function getLocked(address) external view returns (uint256);
    function getWithdrawable(address) external view returns (uint256);
    function withdrawToken(address) external returns (uint256);
    function getVested(address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IOPAD is IERC20 {
    function decimals() external view returns (uint8);
    function mint(address, uint256) external returns (bool);
    function burn(uint256) external returns (bool);
    function airdrop(address) external;
}