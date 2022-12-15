// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;


interface IDonationSBT {

    function safeMint(address to) external;
    function balanceOf(address owner) external view returns (uint256);
}

// SPDX-License-Identifier: NONE

pragma solidity 0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./interface/IDonationSBT.sol";


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting with custom message on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction underflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts with custom message on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
}

interface IPayoutFactory {

    function latestPayoutContract() external view returns (address);
}



contract Treasury is Context{
    using SafeMath for uint256;

    address public immutable daoToken;
    address public guardian;
    address public payoutFactory;
    address public donationSBT;
    uint256 public payoutAmount;

    bool public donationPaused;
    uint256 public threshold = 1000; // $1000 minimum donation for receiving SBT

    mapping (address => bool) public supportedTokens;
    // mapping (address => bool) public isStableToken;
    AggregatorV3Interface public constant priceFeedETH_USD = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
    mapping (address => bool) public payoutClaimed;

    modifier onlyGuardian() {
        require(guardian == _msgSender(), "Treasury: caller is not the guardian");
        _;
    }

    modifier isNotPaused() {
        require(!donationPaused, "Treasury: donations are paused");
        _;
    }

    event GuardianUpdated(address indexed guardian, address indexed newGuardian);
    event PayoutFactoryUpdated(address indexed payoutFactory, address indexed newPayoutFactory);
    event DonationSBTUpdated(address indexed donationSBT, address indexed newDonationSBT);
    event PayoutAmountUpdated(uint256 indexed payoutAmount, uint256 indexed newPayoutAmount);
    event DonationReceived(address indexed donator, address indexed token, uint256 amount, uint256 amountUSD);
    event SupportedTokenUpdated(address indexed token, bool indexed support);
    event PayoutClaimed(address indexed payoutContract, uint256 payoutAmount);
    event ExecuteTransaction(address indexed target, uint256 value, bytes data);

    constructor(address daoToken_, address guardian_, uint256 payoutAmount_) {
        daoToken = daoToken_;
        guardian = guardian_;
        payoutAmount = payoutAmount_;

        // updating some base supported tokens
        address[] memory tokens = new address[](2); 
        tokens[0] = address(0); // ETH
        tokens[1] = address(0x60DF13046ef7Ac1F9f812B8aD35A0dc73459e960); // DAI
        // tokens[2] = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48); // USDC
        // tokens[3] = address(0xdAC17F958D2ee523a2206206994597C13D831ec7); // USDT
        
        _updateSupportedToken(tokens, true);
        
        emit GuardianUpdated(address(0), guardian_);
        emit PayoutAmountUpdated(0, payoutAmount_);
    }

    function setPayoutFactory(address newPayoutFactory_) external onlyGuardian {
        require(newPayoutFactory_ != address(0), "Treasury::setPayoutFactory: Can not set to zero addess");
        emit PayoutFactoryUpdated(payoutFactory, newPayoutFactory_);
        payoutFactory = newPayoutFactory_;
    }

    function setDonationSBT(address newDonationSBT_) external onlyGuardian {
        require(newDonationSBT_ != address(0), "Treasury::setDonationSBT: Can not set to zero addess");
        emit DonationSBTUpdated(donationSBT, newDonationSBT_);
        donationSBT = newDonationSBT_;
    }
    
    function updatePayoutAmount(uint256 newPayoutAmount_) external onlyGuardian {
        require(newPayoutAmount_ <= IERC20(daoToken).totalSupply().div(1000), "Treasury::updatePayoutAmount: Cant exceeds 0.1% of total supply");
        emit PayoutAmountUpdated(payoutAmount, newPayoutAmount_);
        payoutAmount = newPayoutAmount_;
    }

    /// @notice only ETH and stables should be supported. 
    function updateSupportedToken(address[] memory tokens_, bool support_) public onlyGuardian {
        _updateSupportedToken(tokens_, support_);
    }

    function claimPayout() external {
        address payoutContract = IPayoutFactory(payoutFactory).latestPayoutContract();
        require(_msgSender() == payoutContract, "Treasury::claimPayout: Invalid payout contract");
        require(!payoutClaimed[payoutContract], "Treasury::claimPayout: Already claimed");

        payoutClaimed[payoutContract] = true;
        IERC20(daoToken).transfer(payoutContract, payoutAmount);

        emit PayoutClaimed(payoutContract, payoutAmount);
    } 

    // function withdrawUnsupportedTokens(address token_) external onlyGuardian{
    //     require(!supportedTokens[token_], "cant withdraw supported token");
    //     uint256 balance = IERC20(token_).balanceOf(address(this));
    //     IERC20(token_).transfer(guardian, balance);
    // }

    function pauseDonation() external onlyGuardian {
        donationPaused = true;
    }

    function unPauseDonation() external onlyGuardian {
        donationPaused = false;
    }

    function donate(address token_, uint256 amount_) external payable isNotPaused {
        require(supportedTokens[token_], "Treasury::donate: Token not supported");
        // checking the condition for ETH
        if (token_ == address(0)) {
            require(msg.value >= amount_, "Treasury::donate: Insufficient value provided");
            
        } else {
            IERC20(token_).transferFrom(_msgSender(), address(this), amount_);
        }

        // calculating $ equivallent
        uint256 amountUSD = _getUSDAmount(token_, amount_);

        // mint SBT if donation amount exceeds thershold
        if(amountUSD > threshold && donationSBT != address(0)) {
            // checking if user already holds SBT
            if(IDonationSBT(donationSBT).balanceOf(msg.sender) == 0)
                IDonationSBT(donationSBT).safeMint(msg.sender);
        }

        // TODO: mint the Donation receipt (if community decides)
        emit DonationReceived(_msgSender(), token_, amount_, amountUSD);
    }

    function executeTransaction(address target, uint256 value, bytes memory data) external onlyGuardian returns (bytes memory) {
        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call{ value: value }(data);
        require(success, 'Treasury::executeTransaction: Transaction execution reverted.');

        emit ExecuteTransaction(target, value, data);

        return returnData;
    }

    function _updateSupportedToken(address[] memory tokens_, bool support_) internal {
        for( uint256 i = 0; i < tokens_.length; i++ ) {
            supportedTokens[tokens_[i]] = support_;
            emit SupportedTokenUpdated(tokens_[i], support_); 
        }
    }

    function _getUSDAmount(address token_, uint256 amount_) internal view returns (uint256 _amountUSD) {
        if (token_ == address(0)) { // ETH
            (, int price , , ,) = priceFeedETH_USD.latestRoundData();

            uint priceFeedDecimal = priceFeedETH_USD.decimals();
            _amountUSD = (uint256(price) * amount_) / (10**priceFeedDecimal);
        } else { // stables
            uint decimals = IERC20(token_).decimals();
            _amountUSD = amount_.div(10**decimals);
        }
    }
}