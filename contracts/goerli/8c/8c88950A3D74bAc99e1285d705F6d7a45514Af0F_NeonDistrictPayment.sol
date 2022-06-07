//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract NeonDistrictPayment is Ownable
{

    /**
     * Pricing Options
     **/

    // Package ID or Neon Count to Price, in Pennies (USD)
    mapping(uint256 => uint256) public packagePriceOptions;


    /**
     * ERC-20 Payment Contracts Supported
     **/

    // Contracts Enabled
    struct PaymentOption {
        address tokenContract; // Token contract, if non-native
        address aggregatorContract; // Chainlink Aggregator contract, must be set for a valid entry
        uint256 tokenDecimals;
        uint256 aggregatorDecimals;
    }

    // Symbol to PaymentOption
    mapping(string => PaymentOption) public paymentOptions;

    /**
     * Payout address
     **/
    address payable public payoutAddress;


    /**
     * Events
     **/

    event PackagePurchased(
        uint256 package,
        bytes32 uuid,
        string token
    );


    /**
     * Constructor & views
     **/

    constructor(
        string[] memory _tokens,
        address[] memory _tokenAddresses,
        address[] memory _aggregatorAddresses,
        uint256[] memory _tokenDecimals,
        uint256[] memory _aggregatorDecimals,
        uint256[] memory _packageNumbers,
        uint256[] memory _prices,
        address payable _payoutAddress
    ) {
        // Set defaults
        setPaymentOptions(_tokens, _tokenAddresses, _aggregatorAddresses, _tokenDecimals, _aggregatorDecimals);
        setPurchaseOptions(_packageNumbers, _prices);
        payoutAddress = _payoutAddress;
    }

    function name() external pure returns (string memory) {
        return "Neon District In-Game Payments";
    }

    function symbol() external pure returns (string memory) {
        return "NDPAYMENT";
    }


    /**
     * Purchase & views
     **/

    function purchase(
        string calldata _token,
        uint256 _packageNumber,
        bytes32 uuid
    )
        external
        payable
    {
        // Validation
        require(packagePriceOptions[_packageNumber] > 0, "Package number not supported");
        require(paymentOptions[_token].aggregatorContract != address(0), "Invalid payment method");

        // Get cost
        uint256 cost = getCost(_token, _packageNumber);
        require(cost != 0, "Cost can not be zero");

        // Is an ERC-20 token contract
        if (paymentOptions[_token].tokenContract != address(0)) {
            // Send tokens to this contract
            IERC20(paymentOptions[_token].tokenContract).transferFrom(msg.sender, address(this), cost);
        } else {
            // Calculate the cost, at 10^8 of a USD, with +/- % bounds for time delays
            // Multiply by remainder to get proper decimals
            require(msg.value >= cost * 99  / 100 && msg.value <= cost * 101 / 100, "Incorrect msg.value for purchase");
        }

        emit PackagePurchased(_packageNumber, uuid, _token);
    }

    function getCost(
        string calldata _token,
        uint256 _packageNumber
    )
        public
        view
        returns (
            uint256 cost
        )
    {
        // Get the current USD price of this token
        ( , int256 tokenPrice, , ,) = AggregatorV3Interface(paymentOptions[_token].aggregatorContract).latestRoundData();

        // Get the native USD cost of the package requested, multiplied by aggregator's decimals
        uint256 neonCost = getPrice(_packageNumber) * 10**(paymentOptions[_token].aggregatorDecimals - 2);

        // Return the price in wei (ie, native decimals for token)
        return 10**(paymentOptions[_token].tokenDecimals) * neonCost / uint256(tokenPrice);
    }

    function getPrice(
        uint256 _packageNumber
    )
        public
        view
        returns (uint256)
    {
        return packagePriceOptions[_packageNumber];
    }


    /**
     * Withdraw
     **/

    // Allow anyone to withdraw all of the contract balance for a native token or ERC-20
    function withdraw(
        string calldata _token
    )
        external
    {
        if (paymentOptions[_token].tokenContract != address(0)) {
            IERC20 erc20Contract = IERC20(paymentOptions[_token].tokenContract);
            erc20Contract.transfer(payoutAddress, erc20Contract.balanceOf(address(this)));
        } else {
            payable(payoutAddress).transfer(address(this).balance);
        }
    }


    /**
     * Owner-only functions
     **/

    // Set / unset package details
    function setPurchaseOptions(
        uint256[] memory _packageNumbers,
        uint256[] memory _prices
    )
        public
        onlyOwner
    {
        require(
            _packageNumbers.length == _prices.length,
            "Must have correct option count"
        );

        // Set the prices
        for (uint _idx; _idx < _packageNumbers.length; _idx++) {
            packagePriceOptions[_packageNumbers[_idx]] = _prices[_idx];
        }
    }

    // Set / unset accepted tokens
    function setPaymentOptions(
        string[] memory _tokens,
        address[] memory _tokenAddresses,
        address[] memory _aggregatorAddresses,
        uint256[] memory _tokenDecimals,
        uint256[] memory _aggregatorDecimals
    )
        public
        onlyOwner
    {
        require(
            _tokens.length == _tokenAddresses.length &&
            _tokens.length == _aggregatorAddresses.length &&
            _tokens.length == _tokenDecimals.length &&
            _tokens.length == _aggregatorDecimals.length,
            "Must have correct option count"
        );

        // Set the prices
        for (uint _idx; _idx < _tokens.length; _idx++) {
            if (_aggregatorAddresses[_idx] != address(0)) {
                paymentOptions[_tokens[_idx]] = PaymentOption(
                    _tokenAddresses[_idx],
                    _aggregatorAddresses[_idx],
                    _tokenDecimals[_idx],
                    _aggregatorDecimals[_idx]
                );
            } else {
                delete paymentOptions[_tokens[_idx]];
            }
        }
    }

    // Set recipient of tokens
    function setPayoutAddress(
        address payable _payoutAddress
    )
        external
        onlyOwner
    {
        require(_payoutAddress != address(0), "Can't burn payout");
        payoutAddress = _payoutAddress;
    }

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