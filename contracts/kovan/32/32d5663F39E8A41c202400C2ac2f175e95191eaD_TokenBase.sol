/**
 *Submitted for verification at Etherscan.io on 2022-06-18
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;



// Part: OpenZeppelin/[email protected]/Context

/*
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

// Part: OpenZeppelin/[email protected]/IERC20

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// Part: smartcontractkit/[email protected]/AggregatorV3Interface

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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

// Part: OpenZeppelin/[email protected]/Ownable

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// Part: Exchange

//Interface name is not important, however functions in it are important
// interface TokenBaseInterface {
//     function sendReward(uint256 amount, address user) external;
// }

contract Exchange is Ownable {
    uint256 public creationTime = block.timestamp;
    uint256 public rate = 1e14; // tokens for 1 eth
    uint256 public rateMultiply = 1e5;
    event Bought(uint256 amount);
    event Sold(uint256 amount);

    IERC20 public token;
    // address public tokenBase;

    mapping(address => uint256) tokenPriceFeed;

    constructor(address _trantTokenAddress) {
        token = IERC20(_trantTokenAddress);
        // tokenBase = _tokenBase;
    }

    function checkBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function checkTokenBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    //10000 unit buy
    // should equal to 1 ether
    function buyToken(uint256 amountInEth) public payable {
        // uint256 amountTobuy = msg.value;
        uint256 dexBalance = token.balanceOf(address(this));
        require(amountInEth > 0, "You need to send some ether");
        // require(amountTobuy <= dexBalance, "Not enough tokens in the reserve");

        uint256 tokenReturn = (amountInEth * 1 ether) / rate;
        // require(amountTobuy >= costWei);
        assert(token.transfer(msg.sender, tokenReturn));
        emit Bought(amountInEth);
    }

    function buyTokenOnPayload() public payable {
        uint256 amountInEth = msg.value;
        // uint256 dexBalance = token.balanceOf(address(this));
        require(amountInEth > 0, "You need to send some ether");
        // require(amountTobuy <= dexBalance, "Not enough tokens in the reserve");

        uint256 tokenReturn = (amountInEth * 1 ether) / rate;
        // // require(amountTobuy >= costWei);
        // assert(token.transferFrom(address(this), msg.sender, tokenReturn));
        assert(token.transfer(msg.sender, tokenReturn));
        emit Bought(amountInEth);
    }

    function sellToken(uint256 amount) public {
        uint256 exchangeEth = (amount * 1 ether) / rateMultiply;
        require(amount > 0, "You need to sell at least some tokens");
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= amount, "Check the token allowance");
        token.transferFrom(msg.sender, address(this), amount);
        payable(msg.sender).transfer(exchangeEth);
        // emit Sold(amount);
    }

    function stakeTokens(uint256 _amount, address _token) public {
        //what tokens can they stake?
        // how much can they stake?
        require(_amount > 0, "Amount must be more than 0!");
        // require(tokenIsAllowed(_token), "Token is currently no allowed!");
        //transfer from function needed.
        // ERC20 2 types transfer(can be called by only the owner) and transferFrom
        IERC20(_token).transferFrom(msg.sender, address(this), _amount); //we have the ABI via this IERC20
    }

    // function sendPayment(
    //     uint256 _amount,
    //     address _token,
    //     address station
    // ) public {
    //     require(_amount > 0, "Amount must be more than 0!");
    //     // require(isTokenAllowed(_token), "You should send TRANT");
    //     // require(trantToken.balanceOf(address(msg.sender)) > _amount);
    //     token.transferFrom(msg.sender, station, _amount);
    //     // sendReward(10, msg.sender);
    // }

    function sendReward(uint256 amount, address user) external {
        //managerOnly {
        uint256 dexBalance = token.balanceOf(address(this));
        require(amount <= dexBalance, "Not enough tokens in the reserve");

        // uint256 tokenReturn = (1 * 1 ether) / rate;
        // token.approve(address(this), tokenReturn);
        assert(token.transfer(user, 1));
        emit Bought(1);
        // if (amount > 50) {
        //     uint256 tokenReturn = (5 * 1 ether) / rate;
        //     // require(amountTobuy >= costWei);
        //     token.approve(address(this), tokenReturn);
        //     assert(token.transfer(msg.sender, tokenReturn));
        //     // token.transfer(user, 5);
        // } else if (amount < 50 && amount < 20) {
        //     uint256 tokenReturn = (3 * 1 ether) / rate;
        //     token.approve(address(this), tokenReturn);
        //     token.transfer(user, tokenReturn);
        // } else {
        //     uint256 tokenReturn = (1 * 1 ether) / rate;
        //     token.approve(address(this), tokenReturn);
        //     token.transfer(user, tokenReturn);
        // }
    }
}

// File: TokenBase.sol

//Interface name is not important, however functions in it are important
// interface ExchangeInterface {
//     function sendReward(uint256 amount, address user) external;
// }

contract TokenBase is Ownable {
    address[] public allowedTokenList;
    // mapping token address -> staker address -> amount
    mapping(address => mapping(address => uint256))
        public tokenUserBalancePayment;

    // address public constant OTHER_CONTRACT =
    //     0x8016619281F888d011c84d2E2a5348d9417c775B;
    // ExchangeInterface GreeterContract = GreeterInterface();

    //user total paid for campaign

    address[] public users;

    address[] public stationList;

    // mapping(address => address) public tokenStation;

    // mapping(address => mapping(address => uint256)) public tokenStationBalance;

    AggregatorV3Interface internal ethUSDPriceFeed;
    AggregatorV3Interface internal sUSDPriceFeed;

    /**
     * Network: Kovan
     * Aggregator: ETH/USD
     * Address: 0x9326BFA02ADD2366b30bacB125260Af641031331
     **/
    IERC20 public trantToken;

    address public exchange;

    // There are 2 transfer function in ethereum chain
    // one is the transfer I can use it only I am the owner of the contract
    // transferFrom is the publicly used one. here used only one contract
    // this. But needed to expand peer to peer using this contract.
    constructor(
        address _priceFeedAddress,
        address _priceFeedAddressO,
        address _exchange,
        address _token
    ) {
        ethUSDPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        sUSDPriceFeed = AggregatorV3Interface(_priceFeedAddressO);
        trantToken = IERC20(_token);
        exchange = _exchange;
    }

    // ExchangeInterface IExchange = ExchangeInterface(exchange);

    // tested
    function getPriceFeedEth() public view returns (uint256) {
        (, int256 price, , , ) = ethUSDPriceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price) * 10**10; //because returned data is already has 8 decimals
        // return uint256(price);
        return adjustedPrice;
    }

    //tested
    function getPriceFeedS() public view returns (uint256) {
        (, int256 price, , , ) = sUSDPriceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price) * 10**10; //because returned data is already has 8 decimals
        //return uint256(price);
        return adjustedPrice;
    }

    //tested
    function sendToken(uint256 _amount) public {
        //what token can they use?
        // how much can they send?
        require(_amount > 0, "Amount must be more than 0!");
        // require(isTokenAllowed(_token), "You should send TRANT");
        require(trantToken.balanceOf(address(msg.sender)) > _amount);
        trantToken.transferFrom(msg.sender, address(this), _amount);
        //     trantToken.approve()
        //    token.approve(TransferToken.sol Contract Address, amount);
        //    transferToken.transferFrom(recipient, amount);
        // uint256 ret = getPriceFeedEth();
        // return ret;
        // users.push(msg.sender); // we added user to the users.
        // tokenStationBalance[_token][station] += _amount;
        //trantToken.transferFrom(exchange, msg.sender, calculateRate(_amount));

        // IExchange.sendReward(_amount, msg.sender);

        // exchange.call.gas(1000000).value(1 ether)(
        //     "sendReward",
        //     _amount,
        //     msg.sender
        // );

        Exchange ex = Exchange(exchange);
        ex.sendReward(_amount, msg.sender);
    }

    function sellToken(uint256 amount) public {
        // uint256 exchangeEth = (amount * 1 ether) / rateMultiply;
        require(amount > 0, "You need to sell at least some tokens");
        uint256 allowance = trantToken.allowance(msg.sender, address(this));
        require(allowance >= amount, "Check the token allowance");
        trantToken.transferFrom(msg.sender, address(this), amount);
        // payable(msg.sender).transfer(exchangeEth);
        // emit Sold(amount);
    }

    //tested
    function enrollStation(address _state) public onlyOwner {
        stationList.push(_state);
    }

    //tested
    function getStation(uint256 index) public view onlyOwner returns (address) {
        if (stationList.length > index) return stationList[index];
    }

    //tested
    function addAllowedTokens(address _token) public onlyOwner {
        allowedTokenList.push(_token);
    }

    //tested
    function getAllowedTokens(uint256 index)
        public
        view
        onlyOwner
        returns (address)
    {
        if (allowedTokenList.length > 0) return allowedTokenList[index];
    }

    // indirectly tested
    function isTokenAllowed(address _token) public returns (bool) {
        for (
            uint256 allowedTokenCounter = 0;
            allowedTokenCounter < allowedTokenList.length;
            allowedTokenCounter++
        ) {
            if (allowedTokenList[allowedTokenCounter] == _token) return true;
        }
        return false;
    }
}