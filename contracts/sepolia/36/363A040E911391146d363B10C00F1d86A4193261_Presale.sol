// SPDX-License-Identifier: UNLICENSED

// Deployed with the Atlas IDE
// https://app.atlaszk.com

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Presale is Ownable {
    // ERC20 tokens
    IERC20 public strk;

    // Structure of each vest
    struct Vest {
        uint256 amount; // the amount of strk the beneficiary will receive
        uint256 released; // the amount of strk released to the beneficiary
        bool ethTransferred; // whether the beneficiary has transferred the eth into the contract
    }

    // The mapping of vested beneficiary (beneficiary address => Vest)
    mapping(address => Vest) public vestedBeneficiaries;

    // beneficiary => eth deposited
    mapping(address => uint256) public ethDeposits;

    // Array of beneficiaries
    address[] public beneficiaries;

    // No. of beneficiaries
    uint256 public noOfBeneficiaries;

    // Whether the contract has been bootstrapped with the strk
    bool public bootstrapped;

    // Start time of the vesting
    uint256 public startTime;

    // The duration of the vesting
    uint256 public duration;

    // Price of each strk token in usd (1e8 precision)
    uint256 public strkPrice;

    // ETH/USD chainlink price aggregator
    AggregatorV3Interface internal priceFeed;

    /**
     * Network: Sepolia
     * Aggregator: ETH / USD
     * Address: 0x694AA1769357215DE4FAC081bf1f309aDC325306
     */

    constructor(address payable _priceFeedAddress, uint256 _strkPrice) {
        require(
            _priceFeedAddress != address(0),
            "Price feed address cannot be 0"
        );
        require(_strkPrice > 0, "strk price has to be higher than 0");
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
        strkPrice = _strkPrice;
    }

    /*---- EXTERNAL FUNCTIONS FOR OWNER ----*/

    /**
     * @notice Bootstraps the presale contract
     * @param _startTime the time (as Unix time) at which point vesting starts
     * @param _duration duration in seconds of the period in which the tokens will vest
     * @param _strkAddress address of strk erc20 token
     */
    function bootstrap(
        uint256 _startTime,
        uint256 _duration,
        address _strkAddress
    ) external onlyOwner returns (bool) {
        require(_strkAddress != address(0), "strk address is 0");
        require(_duration > 0, "Duration passed cannot be 0");
        require(
            _startTime > block.timestamp,
            "Start time cannot be before current time"
        );

        startTime = _startTime;
        duration = _duration;
        strk = IERC20(_strkAddress);

        uint256 totalstrkRequired;

        for (uint256 i = 0; i < beneficiaries.length; i = i + 1) {
            totalstrkRequired =
                totalstrkRequired +
                vestedBeneficiaries[beneficiaries[i]].amount;
        }

        require(totalstrkRequired > 0, "Total strk required cannot be 0");

        strk.transferFrom(msg.sender, address(this), totalstrkRequired);

        bootstrapped = true;

        emit Bootstrap(totalstrkRequired);

        return bootstrapped;
    }

    /**
     * @notice Adds a beneficiary to the contract. Only owner can call this.
     * @param _beneficiary the address of the beneficiary
     * @param _amount amount of strk to be vested for the beneficiary
     */
    function addBeneficiary(
        address _beneficiary,
        uint256 _amount
    ) public onlyOwner returns (bool) {
        require(
            _beneficiary != address(0),
            "Beneficiary cannot be a 0 address"
        );
        require(_amount > 0, "Amount should be larger than 0");
        require(
            !bootstrapped,
            "Cannot add beneficiary as contract has been bootstrapped"
        );
        require(
            vestedBeneficiaries[_beneficiary].amount == 0,
            "Cannot add the same beneficiary again"
        );

        beneficiaries.push(_beneficiary);

        vestedBeneficiaries[_beneficiary].amount = _amount;

        noOfBeneficiaries = noOfBeneficiaries + 1;

        emit AddBeneficiary(_beneficiary, _amount);

        return true;
    }

    /**
     * @notice Updates beneficiary amount. Only owner can call this.
     * @param _beneficiary the address of the beneficiary
     * @param _amount amount of strk to be vested for the beneficiary
     */
    function updateBeneficiary(
        address _beneficiary,
        uint256 _amount
    ) external onlyOwner {
        require(
            _beneficiary != address(0),
            "Beneficiary cannot be a 0 address"
        );
        require(
            !bootstrapped,
            "Cannot update beneficiary as contract has been bootstrapped"
        );
        require(
            vestedBeneficiaries[_beneficiary].amount != _amount,
            "New amount cannot be the same as old amount"
        );
        require(
            !vestedBeneficiaries[_beneficiary].ethTransferred,
            "Beneficiary should have not transferred ETH"
        );
        require(_amount > 0, "Amount cannot be smaller or equal to 0");
        require(
            vestedBeneficiaries[_beneficiary].amount != 0,
            "Beneficiary has not been added"
        );

        vestedBeneficiaries[_beneficiary].amount = _amount;

        emit UpdateBeneficiary(_beneficiary, _amount);
    }

    /**
     * @notice Removes a beneficiary from the contract. Only owner can call this.
     * @param _beneficiary the address of the beneficiary
     * @return whether beneficiary was deleted
     */
    function removeBeneficiary(
        address payable _beneficiary
    ) external onlyOwner returns (bool) {
        require(
            _beneficiary != address(0),
            "Beneficiary cannot be a 0 address"
        );
        require(
            !bootstrapped,
            "Cannot remove beneficiary as contract has been bootstrapped"
        );
        if (vestedBeneficiaries[_beneficiary].ethTransferred) {
            _beneficiary.transfer(ethDeposits[_beneficiary]);
        }
        for (uint256 i = 0; i < beneficiaries.length; i = i + 1) {
            if (beneficiaries[i] == _beneficiary) {
                noOfBeneficiaries = noOfBeneficiaries - 1;

                delete beneficiaries[i];
                delete vestedBeneficiaries[_beneficiary];

                emit RemoveBeneficiary(_beneficiary);

                return true;
            }
        }
        return false;
    }

    /**
     * @notice Withdraws eth deposited into the contract. Only owner can call this.
     */
    function withdraw() external onlyOwner {
        uint256 ethBalance = payable(address(this)).balance;

        payable(msg.sender).transfer(ethBalance);

        emit WithdrawEth(ethBalance);
    }

    /*---- EXTERNAL FUNCTIONS ----*/

    /**
     * @notice Transfers eth from beneficiary to the contract.
     */
    function transferEth() external payable returns (uint256 ethAmount) {
        require(
            !vestedBeneficiaries[msg.sender].ethTransferred,
            "Beneficiary has already transferred ETH"
        );
        require(
            vestedBeneficiaries[msg.sender].amount > 0,
            "Sender is not a beneficiary"
        );

        uint256 ethPrice = getLatestPrice();

        ethAmount =
            (vestedBeneficiaries[msg.sender].amount * strkPrice) /
            ethPrice;

        require(msg.value >= ethAmount, "Incorrect ETH amount sent");

        if (msg.value > ethAmount) {
            payable(msg.sender).transfer(msg.value - ethAmount);
        }

        ethDeposits[msg.sender] = ethAmount;

        vestedBeneficiaries[msg.sender].ethTransferred = true;

        emit TransferredEth(msg.sender, ethAmount, ethPrice);
    }

    /**
     * @notice Transfers vested tokens to beneficiary.
     */
    function release() external returns (uint256 unreleased) {
        require(bootstrapped, "Contract has not been bootstrapped");
        require(
            vestedBeneficiaries[msg.sender].ethTransferred,
            "Beneficiary has not transferred eth"
        );
        unreleased = releasableAmount(msg.sender);

        require(unreleased > 0, "No releasable amount");

        vestedBeneficiaries[msg.sender].released =
            vestedBeneficiaries[msg.sender].released +
            unreleased;

        strk.transfer(msg.sender, unreleased);

        emit TokensReleased(msg.sender, unreleased);
    }

    /*---- VIEWS ----*/

    /**
     * @notice Calculates the amount that has already vested but hasn't been released yet.
     * @param beneficiary address of the beneficiary
     */
    function releasableAmount(
        address beneficiary
    ) public view returns (uint256) {
        return
            vestedAmount(beneficiary) -
            vestedBeneficiaries[beneficiary].released;
    }

    /**
     * @notice Calculates the amount that has already vested.
     * @param beneficiary address of the beneficiary
     */
    function vestedAmount(address beneficiary) public view returns (uint256) {
        uint256 totalBalance = vestedBeneficiaries[beneficiary].amount;

        if (block.timestamp < startTime) {
            return 0;
        } else if (block.timestamp >= startTime + duration) {
            return totalBalance;
        } else {
            uint256 halfTotalBalance = totalBalance / 2;
            return
                (halfTotalBalance * (block.timestamp - startTime)) /
                duration +
                halfTotalBalance;
        }
    }

    /**
     * @notice Returns the latest price for ETH/USD
     */
    function getLatestPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price);
    }

    /*---- EVENTS ----*/

    event TokensReleased(address beneficiary, uint256 amount);

    event AddBeneficiary(address beneficiary, uint256 amount);

    event RemoveBeneficiary(address beneficiary);

    event UpdateBeneficiary(address beneficiary, uint256 amount);

    event TransferredEth(
        address beneficiary,
        uint256 ethAmount,
        uint256 ethPrice
    );

    event WithdrawEth(uint256 amount);

    event Bootstrap(uint256 totalstrkRequired);
}

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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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