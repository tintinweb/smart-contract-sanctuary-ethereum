// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// ERC20 tokens interface
import "AggregatorV3Interface.sol";
import "IERC20.sol";

// lockX vesting contract 0.0.1 alpha
contract event_001 {
    // variables
    IERC20 public token; // holds tokens' contract address
    address public owner; // authorized wallet address to get the vesting
    uint256 public vested_amount; // amount of token in wei (18 decimals) which will/is deposited/vested
    uint256 public start_date; // start date of the vesting, in unix timestamp
    uint256 public end_date; // end date of the vesting, in unix timestamp
    uint256 public last_due; // keeps the last eligible claim date in unix timestamp
    uint256 public frequency; // how many vesting should happen
    string public ipfs_hash; // keeps the hash to the IPFS file which includes the event metadata
    bool public is_native_token = false; // this will show whether the token which is vested is the native token of the blockchain or not

    // events
    event funded(address indexed _owner, uint256 _amount);
    event claimed(address indexed _owner, uint256 _amount, uint256 _nextDue);

    // ToDo:
    // 1- checking how many decimal the token has in order to calculate things currectly

    constructor(
        address _token,
        address _owner,
        uint256 _amount,
        uint256 _start_date,
        uint256 _end_date,
        string memory _ipfs_hash,
        uint256 _freq,
        bool _is_native
    ) {
        // checking whether the start date of the event is before the end date
        require(
            _start_date < _end_date && _start_date > 1000 && _end_date > 5000,
            "The start date of the event should be before the end date of the event!"
        );
        // validating the amount to be more than zero
        require(
            _amount > 0,
            "the vested amount MUST be more than 0 and in wei"
        );
        // validating the IPFS hash to be long enough
        require(
            bytes(_ipfs_hash).length > 0,
            "Please enter a valid IPFS/IPNS hash/address!"
        );
        // validating frequency of the claims to be more than 1
        require(_freq > 1, "the frequency of the claims should be at least 2");
        // if the vesting token is the native token of the blockchain
        // the contract address should be blank and not used later on
        // and if not, creator should send tokens while contract is being created
        // ** approve and allowance should be call directly from users' wallet
        // this should happend through front end to initiate this
        if (_is_native == is_native_token) {
            // when its not the native token
            token = IERC20(_token);
            //token.approve(msg.sender, _amount);
            /// emit an event here
        } else {
            // if its the native token
            is_native_token = _is_native;
        }

        // the amount that will be locked inside this contract
        vested_amount = _amount;
        // the start date of the vesting for later calculations
        start_date = _start_date;
        // the end of vesting for later calculations
        end_date = _end_date;
        // frequency of vested token withdrawal
        frequency = _freq;
        // the address which has the right to claim the vested token
        owner = _owner;
        // // ipfs hash of the metadata file for this event
        ipfs_hash = _ipfs_hash;
        // calculating the next due
        last_due = start_date + ((end_date - start_date) / frequency);
    }

    // getting all the current available info of the contract
    function get_info()
        public
        view
        returns (
            address, // token contract address
            uint256, // amount vested
            uint256, // start date
            uint256, // end date
            string memory,
            uint256, // frequency of withdrawal
            bool // whether the token is the native token of the blockchain
        )
    {
        return (
            address(token),
            vested_amount,
            start_date,
            end_date,
            ipfs_hash,
            frequency,
            is_native_token
        );
    }

    // funding the contract with ETH as the vested token
    function fund_native() external payable {
        require(
            is_native_token && msg.value == vested_amount,
            "The amount you want to send is not equal to the amount you wanted to invest"
        );
        emit funded(msg.sender, msg.value);
    }

    // funding the contract with a token other than native token
    // for this function to work properly we need to have allowance which is happend
    // after the contract is created through a UI call to wallet, then funding of this
    // contract is initiated.
    function fund_token() external {
        require(
            !is_native_token && vested_amount > 0,
            "You need to vest at least some tokens, vested token is zero"
        );
        require(
            token.allowance(msg.sender, address(this)) >= vested_amount,
            "Check the token allowance!"
        );
        token.transferFrom(msg.sender, address(this), vested_amount);
        emit funded(msg.sender, vested_amount);
    }

    // only owner address should has the right to withdraw vested tokens
    modifier onlyOwner() {
        //is the message sender owner of the contract?
        //require(msg.sender == owner, "Only the authorized address can withdraw funds!");
        require(
            msg.sender == owner,
            "Only the authorized address can withdraw funds!"
        );
        _;
    }

    // claim function
    // here we calculate how many withdrawal is due
    // and transfer the amount to users wallet
    function claim() public onlyOwner {
        // checking whether the due date even startedd or is there any balance left
        require(
            block.timestamp > last_due &&
                (token.balanceOf(address(this)) > 0 ||
                    address(this).balance > 0),
            "it's not the time to claim any vested tokens"
        );

        // claimable counts how many payments are due
        uint256 claimable = (block.timestamp - last_due) /
            ((end_date - start_date) / frequency);

        // again check whether there is any claimable to be paid
        require(claimable > 0, "nothing to withdraw");
        // we update the last due here in order to prevent re-entry problem
        last_due += ((end_date - start_date) / frequency) * claimable;
        // in case its the last claim
        if (last_due > end_date) {
            last_due = end_date;
        }
        // is there is due payment, we will multiply it by
        // amount of each vesting to get the total payment for current withdrawal
        uint256 w_amount = claimable * (vested_amount / frequency);

        // if the amount of the payment is more than balance (due to not exact calculation of the last payment)
        // we will set the amoun to total current balance
        if (is_native_token) {
            if (w_amount > address(this).balance) {
                w_amount = address(this).balance;
            }
            payable(owner).transfer(w_amount);
            emit claimed(owner, w_amount, last_due);
        } else {
            if (w_amount > token.balanceOf(address(this))) {
                w_amount = token.balanceOf(address(this));
            }
            token.transfer(owner, w_amount);
            emit claimed(owner, w_amount, last_due);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

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

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}