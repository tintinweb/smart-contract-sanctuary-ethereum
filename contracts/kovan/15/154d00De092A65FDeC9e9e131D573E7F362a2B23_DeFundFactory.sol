// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./DeFundModel.sol";
import "./DeFund.sol";

    error DeFundFactory__deposit__zero_deposit();
    error DeFundFactory__deposit__less_than_declared();
    error DeFundFactory__deposit__token_not_allowed();
    error DeFundFactory__recurring__only_owner();
    error DeFundFactory__not_implemented();

contract DeFundFactory is KeeperCompatibleInterface, Ownable {
    /* State variables */
    uint private s_counterFundraisers = 0;
    uint private s_counterRecurringPayments = 0;
    uint public s_lastTimeStamp;
    address[] public s_allowedERC20Tokens;
    mapping(address => mapping(address => uint)) public s_userBalances;
    mapping(uint => address) public s_fundraisers;
    mapping(address => uint[]) public s_fundraisersByOwner;
    mapping(uint => DeFundModel.RecurringPaymentDisposition) public s_recurringPayments;
    mapping(address => uint[]) public s_recurringPaymentsByOwner;
    AggregatorV3Interface public s_priceFeed;
    uint i_recurringInterval = 1 hours;

    /* Events */
    event FundraiserCreated(uint indexed fundraiserId, address indexed creator, string title, DeFundModel.FundraiserType fundraiserType, DeFundModel.FundraiserCategory category, uint endDate, uint goalAmount);
    event UserBalanceChanged(address indexed creator, address tokenAddress, uint previousBalance, uint newBalance);


    /* Constructor - provide ETH/USD Chainlink price feed address */
    /* Kovan: 0x9326BFA02ADD2366b30bacB125260Af641031331 */
    constructor(/*address _ethUsdPriceFeed*/) {
        // s_priceFeed = AggregatorV3Interface(_ethUsdPriceFeed);
        s_priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
        s_lastTimeStamp = block.timestamp;
    }

    /* Deposit funds to the contract */
    function depositFunds(uint _amount, address _tokenAddress) external payable {
        if (_amount == 0) {
            revert DeFundFactory__deposit__zero_deposit();
        }
        uint currentBalance = s_userBalances[msg.sender][_tokenAddress];
        if (_tokenAddress == address(0)) {
            // ETH deposit
            if (msg.value < _amount) {
                revert DeFundFactory__deposit__less_than_declared();
            }

            s_userBalances[msg.sender][address(0)] = s_userBalances[msg.sender][address(0)] + _amount;
        } else {
            // ERC20 deposit
            if (!isTokenAllowed(_tokenAddress)) {
                revert DeFundFactory__deposit__token_not_allowed();
            }

            /// TODO
            revert DeFundFactory__not_implemented();
        }
        emit UserBalanceChanged(msg.sender, _tokenAddress, currentBalance, s_userBalances[msg.sender][_tokenAddress]);
    }

    /* Withdraw funds from the contract */
    function withdrawFunds(uint _amount, address _tokenAddress) public {
        require(_amount > 0, "Cannot withdraw 0");
        uint currentBalance = s_userBalances[msg.sender][_tokenAddress];
        require(_amount <= currentBalance, "Not enough balance");

        s_userBalances[msg.sender][_tokenAddress] = currentBalance - _amount;

        if (_tokenAddress == address(0)) {
            (bool success,) = msg.sender.call{value : _amount}("");
            require(success, "Transfer failed.");
        } else {
            // TODO
            revert DeFundFactory__not_implemented();
        }
        emit UserBalanceChanged(msg.sender, _tokenAddress, s_userBalances[msg.sender][_tokenAddress], currentBalance - _amount);
    }

    /* Add a new token to the list allowed for deposits and withdrawals */
    function allowToken(address _tokenAddress) public onlyOwner {
        s_allowedERC20Tokens.push(_tokenAddress);
    }

    /* Check if deposited token is supported */
    function isTokenAllowed(address _tokenAddress) public view returns (bool) {
        for (
            uint256 idx = 0;
            idx < s_allowedERC20Tokens.length;
            idx++
        ) {
            if (s_allowedERC20Tokens[idx] == _tokenAddress) {
                return true;
            }
        }
        return false;
    }

    /* Create a new fundraiser */
    function createFundraiser(
        DeFundModel.FundraiserType _type,
        DeFundModel.FundraiserCategory _category,
        string calldata _name,
        string calldata _description,
        uint _endDate,
        uint _goalAmount
    ) external returns (uint fundraiserId) {
        fundraiserId = s_counterFundraisers;
        s_counterFundraisers = s_counterFundraisers + 1;

        DeFund fundraiser = new DeFund(
            fundraiserId,
            msg.sender,
            _type,
            _category,
            _name,
            _description,
            _endDate,
            _goalAmount
        );

        s_fundraisers[fundraiserId] = address(fundraiser);
        s_fundraisersByOwner[msg.sender].push(fundraiserId);

        emit FundraiserCreated(fundraiserId, msg.sender, _name, _type, _category, _endDate, _goalAmount);

        return fundraiserId;
    }

    /* Donate to a fundraiser (lookup by ID) */
    function donateById(
        uint _fundraiserId,
        uint _amount,
        address _tokenAddress
    ) public {
        donateByAddress(s_fundraisers[_fundraiserId], _amount, _tokenAddress);
    }

    /* Donate to a fundraiser (lookup by address) */
    function donateByAddress(
        address _fundraiserAddress,
        uint _amount,
        address _tokenAddress
    ) public {
        require(_amount > 0, "Cannot donate 0");
        uint currentBalance = s_userBalances[msg.sender][_tokenAddress];
        require(_amount <= currentBalance, "Not enough balance");

        s_userBalances[msg.sender][_tokenAddress] = currentBalance - _amount;

        if (_tokenAddress == address(0)) {
            bool success = DeFund(_fundraiserAddress).makeDonation{value : _amount}(msg.sender, _amount, _tokenAddress);
            require(success, "Transfer failed.");
        } else {
            // TODO
            revert DeFundFactory__not_implemented();
        }
    }

    /* Get user balance */
    function getMyBalance(address _token) public view returns (uint balance) {
        return s_userBalances[msg.sender][_token];
    }

    /* Get user's recurring payments */
    function getMyRecurringPayments() public view returns (DeFundModel.RecurringPaymentDisposition[] memory recurringPayments) {
        recurringPayments = new DeFundModel.RecurringPaymentDisposition[](s_recurringPaymentsByOwner[msg.sender].length);
        for (uint i = 0; i < s_recurringPaymentsByOwner[msg.sender].length; i++) {
            recurringPayments[i] = s_recurringPayments[s_recurringPaymentsByOwner[msg.sender][i]];
        }
        return recurringPayments;
    }

    /* Create a recurring payment */
    function createRecurringPayment(
        address _targetFundraiser,
        address _tokenAddress,
        uint _amount,
        uint32 _intervalHours
    ) external returns (uint recurringPaymentId) {
        recurringPaymentId = s_counterRecurringPayments;
        s_counterRecurringPayments = s_counterRecurringPayments + 1;
        s_recurringPayments[recurringPaymentId].owner = msg.sender;
        s_recurringPayments[recurringPaymentId].target = _targetFundraiser;
        s_recurringPayments[recurringPaymentId].tokenAddress = _tokenAddress;
        s_recurringPayments[recurringPaymentId].amount = _amount;
        s_recurringPayments[recurringPaymentId].intervalHours = _intervalHours;
        s_recurringPayments[recurringPaymentId].status = DeFundModel.RecurringPaymentStatus.ACTIVE;

        s_recurringPaymentsByOwner[msg.sender].push(recurringPaymentId);

        executeRecurringPayment(recurringPaymentId);

        return recurringPaymentId;
    }

    /* Create a recurring payment */
    function cancelRecurringPayment(
        uint _id
    ) external {
        if (msg.sender != s_recurringPayments[_id].owner) {
            revert DeFundFactory__deposit__token_not_allowed();
        }

        if (s_recurringPayments[_id].status == DeFundModel.RecurringPaymentStatus.ACTIVE) {
            s_recurringPayments[_id].status = DeFundModel.RecurringPaymentStatus.CANCELLED;
        }
    }

    /* Execute recurring payment - called internally on upkeep */
    // TODO fix reentrancy vulnerability - multiple upkeeps at the same time
    function executeRecurringPayment(uint _id) internal {
        uint executorBalance = s_userBalances[s_recurringPayments[_id].owner][s_recurringPayments[_id].tokenAddress];
        if (executorBalance >= s_recurringPayments[_id].amount) {
            s_userBalances[s_recurringPayments[_id].owner][s_recurringPayments[_id].tokenAddress] = executorBalance - s_recurringPayments[_id].amount;

            DeFund fundraiser = DeFund(s_recurringPayments[_id].target);
            if (fundraiser.s_status() == DeFundModel.FundraiserStatus.ACTIVE && fundraiser.i_type() == DeFundModel.FundraiserType.RECURRING_DONATION) {
                fundraiser.makeDonation{value : s_recurringPayments[_id].amount}(s_recurringPayments[_id].owner, s_recurringPayments[_id].amount, s_recurringPayments[_id].tokenAddress);
            }
        }
        s_recurringPayments[_id].lastExecution = block.timestamp;
    }

    /* Keepers integration */
    function checkUpkeep(bytes memory /* checkData */) public override view returns (
        bool upkeepNeeded,
        bytes memory /* performData */
    ) {
        bool intervalPassed = (block.timestamp - s_lastTimeStamp) > i_recurringInterval;
        bool hasFundraisersAndPayments = s_counterFundraisers > 0 && s_counterRecurringPayments > 0;

        // TODO optimize - return IDs of payments in performData
        bool hasPaymentsToExecute = false;
        for (uint id = 0; id < s_counterRecurringPayments; id++) {
            if (s_recurringPayments[id].status != DeFundModel.RecurringPaymentStatus.ACTIVE) {
                continue;
            }

            if (DeFund(s_recurringPayments[id].target).i_type() != DeFundModel.FundraiserType.RECURRING_DONATION) {
                continue;
            }

            if (DeFund(s_recurringPayments[id].target).s_status() != DeFundModel.FundraiserStatus.ACTIVE) {
                continue;
            }

            if (s_userBalances[s_recurringPayments[id].owner][s_recurringPayments[id].tokenAddress] < s_recurringPayments[id].amount) {
                continue;
            }


            if (block.timestamp > s_recurringPayments[id].lastExecution + (s_recurringPayments[id].intervalHours * 60 * 60)) {
                hasPaymentsToExecute = true;
                break;
            }
        }

        upkeepNeeded = intervalPassed && hasFundraisersAndPayments && hasPaymentsToExecute;

        return (upkeepNeeded, "");
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        for (uint id = 0; id < s_counterRecurringPayments; id++) {
            if (s_recurringPayments[id].status != DeFundModel.RecurringPaymentStatus.ACTIVE) {
                continue;
            }

            if (DeFund(s_recurringPayments[id].target).i_type() != DeFundModel.FundraiserType.RECURRING_DONATION) {
                continue;
            }

            if (DeFund(s_recurringPayments[id].target).s_status() != DeFundModel.FundraiserStatus.ACTIVE) {
                continue;
            }

            if (s_userBalances[s_recurringPayments[id].owner][s_recurringPayments[id].tokenAddress] < s_recurringPayments[id].amount) {
                continue;
            }


            if (block.timestamp > s_recurringPayments[id].lastExecution + (s_recurringPayments[id].intervalHours * 60 * 60)) {
                executeRecurringPayment(id);
            }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.7;

library DeFundModel {
    enum FundraiserType {
        ONE_TIME_DONATION,
        RECURRING_DONATION,
        LOAN
    }

    enum FundraiserStatus {
        ACTIVE,
        FULLY_FUNDED,
        REPAYING,
        REPAID,
        CLOSED
    }

    enum FundraiserCategory {
        MEDICAL,
        EMERGENCY,
        FINANCIAL_EMERGENCY,
        COMMUNITY,
        ANIMALS,
        EDUCATION
    }

    enum RecurringPaymentStatus {
        ACTIVE,
        CANCELLED
    }

    struct RecurringPaymentDisposition {
        address owner;
        address target;
        address tokenAddress;
        uint amount;
        uint32 intervalHours;
        uint lastExecution;
        RecurringPaymentStatus status;
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./DeFundModel.sol";
import "./DeFundFactory.sol";
import "./RateConverter.sol";

error DeFund__not_implemented();

contract DeFund {
    using RateConverter for uint256;

    /* Immutable state variables */
    uint public immutable i_id;
    address public immutable i_owner;
    DeFundModel.FundraiserType public immutable i_type;
    DeFundModel.FundraiserCategory public immutable i_category;
    uint public immutable i_endDate;
    uint public immutable i_goalAmount;
    DeFundFactory private immutable i_factory;

    /* State variables */
    string[] public s_descriptions;
    string[] public s_images;
    uint public s_defaultImage;
    string public s_name;
    DeFundModel.FundraiserStatus public s_status;
    mapping(address => uint) public s_balances;
    mapping(address => mapping(address => uint)) public s_donors;

    /* Modifiers */
    modifier onlyOwner {
        require(msg.sender == i_owner, "You must be the owner of the fundraiser to perform this operation");
        _;
    }

    /* Create a new instance of a fundraiser */
    constructor(
        uint _id,
        address _owner,
        DeFundModel.FundraiserType _type,
        DeFundModel.FundraiserCategory _category,
        string memory _name,
        string memory _initialDescription,
        uint _endDate,
        uint _goalAmount
    ) {
        i_id = _id;
        i_owner = _owner;
        i_type = _type;
        i_category = _category;
        s_name = _name;
        s_descriptions.push(_initialDescription);
        i_factory = DeFundFactory(msg.sender);
        i_endDate = _endDate;
        i_goalAmount = _goalAmount; // in USD cents! 1 USD = 100 _goalAmount
        s_status = DeFundModel.FundraiserStatus.ACTIVE;
    }

    /* Donate funds to the fundraiser */
    function makeDonation(address _donorAddress, uint _amount, address _tokenAddress) external payable returns (bool) {
        require(s_status == DeFundModel.FundraiserStatus.ACTIVE, "You cannot donate to a fundraiser that is not active");
        require(_amount > 0, "Cannot deposit 0");
        if (_tokenAddress == address(0)) {
            // ETH deposit
            require(msg.value == _amount);
            s_donors[_donorAddress][address(0)] = s_donors[_donorAddress][address(0)] + _amount;
            s_balances[address(0)] = s_balances[address(0)] + _amount;
        } else {
            // TODO
            revert DeFund__not_implemented();
        }

        finalizeDonation();

        return true;

        // TODO emit
    }

    /* Withdraw funds from the contract */
    function withdrawFunds(uint _amount, address _tokenAddress) public onlyOwner {
        require(_amount > 0, "Cannot withdraw 0");
        require(s_status != DeFundModel.FundraiserStatus.ACTIVE, "You cannot donate to a fundraiser that is active");
        uint currentBalance = s_balances[_tokenAddress];
        require(_amount <= currentBalance, "Sorry, can't withdraw more than total donations");

        s_balances[_tokenAddress] = currentBalance - _amount;

        if (_tokenAddress == address(0)) {
            (bool success, ) = msg.sender.call{value: _amount}("");
            require(success, "Transfer failed.");
        } else {
            // TODO
            revert DeFund__not_implemented();
        }

        // TODO emit
    }

    /* Add a picture */
    function addImage(string memory _picture, bool makeDefault) external onlyOwner {
        s_images.push(_picture);
        if (makeDefault == true) {
            s_defaultImage = s_images.length - 1;
        }
    }

    /* Set picture as default */
    function setDefaultPicture(uint _pictureIdx) external onlyOwner {
        require(_pictureIdx < s_images.length, "Image not found");
        s_defaultImage = _pictureIdx;
    }

    /* Update description */
    function setDefaultPicture(string memory _description) external onlyOwner {
        s_descriptions.push(_description);
    }

    /* Close fundraiser and revert all donations */
    function closeAndRevertDonations() public onlyOwner {
        require(s_status == DeFundModel.FundraiserStatus.ACTIVE, "You can only close active fundraisers");
        // TODO return donations
        s_status = DeFundModel.FundraiserStatus.CLOSED;
    }

    /* Get all details */
    function getAllDetails() public view returns (
        uint id,
        address owner,
        DeFundModel.FundraiserType fType,
        DeFundModel.FundraiserCategory category,
        uint endDate,
        uint goalAmount,
        string[] memory descriptions,
        string[] memory images,
        uint defaultImage,
        string memory name,
        DeFundModel.FundraiserStatus status,
        uint balances
    ) {
        return (
            i_id,
            i_owner,
            i_type,
            i_category,
            i_endDate,
            i_goalAmount,
            s_descriptions,
            s_images,
            s_defaultImage,
            s_name,
            s_status,
            s_balances[address(0)]
        );
    }

    function finalizeDonation() internal {
        if (i_goalAmount > 0) {
            uint totalDonationsInCents = s_balances[address(0)].getConversionRate(i_factory.s_priceFeed());
            if (totalDonationsInCents >= i_goalAmount) {
                s_status = DeFundModel.FundraiserStatus.FULLY_FUNDED;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library RateConverter {
    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        (, int256 answer, , ,) = priceFeed.latestRoundData();
        return uint256(answer);
    }

    /* Return value in cents */
    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns (uint256 ethAmountInUSD) {
        uint256 ethPrice = getPrice(priceFeed);
        ethAmountInUSD = (ethPrice * ethAmount) / 1e24;
        return ethAmountInUSD;
    }
}