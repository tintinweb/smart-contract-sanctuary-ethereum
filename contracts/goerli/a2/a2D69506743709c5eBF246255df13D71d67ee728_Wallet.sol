/**
 *Submitted for verification at Etherscan.io on 2023-02-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

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


contract Wallet is Ownable {
    IERC20 public token;
    mapping(address => uint256) public balanceOf;
    mapping(uint256 => Order) public orders;
    uint256 public totalSupply;
    address public typeConverter;
    uint256 public maxWithdrawAmount;
    bool public withdrawEnable;

    struct Order {
        address wallet;
        uint256 price;
    }
    // event
    event Deposit(address from, address to, uint256 amount);
    event Withdraw(address from, address to, uint256 amount);

    event BuyToken(address buyer, uint256 xuAmount, uint256 ethAmount);

    constructor(address tokenAddress) {
        token = IERC20(tokenAddress);
        // ETH to USD
        typeConverter = 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e;
        maxWithdrawAmount = 1000000 * 10 ** 18;
        withdrawEnable = true;
    }

    // setter
    function setWithdrawEnable(bool _withdrawEnable) public onlyOwner {
        withdrawEnable = _withdrawEnable;
    }

    function setMaxWithdrawAmount(uint256 _maxWithdrawAmount) public onlyOwner {
        maxWithdrawAmount = _maxWithdrawAmount;
    }

    function setTypeConverter(address _typeConverter) public onlyOwner {
        typeConverter = _typeConverter;
    }

    function setToken(address tokenAddress) public onlyOwner {
        token = IERC20(tokenAddress);
    }

    function _mint(address _to, uint _shares) private {
        totalSupply += _shares;
        balanceOf[_to] += _shares;
    }

    function _burn(address _from, uint _shares) private {
        totalSupply -= _shares;
        balanceOf[_from] -= _shares;
    }

    function deposit(uint _amount) external {
        require(token.balanceOf(msg.sender) >= _amount, "You don't have XU.");
        /*
        a = amount
        B = balance of token before deposit
        T = total supply
        s = shares to mint

        (T + s) / T = (a + B) / B 

        s = aT / B
        */
        uint shares;
        if (totalSupply == 0) {
            shares = _amount;
        } else {
            shares = (_amount * totalSupply) / token.balanceOf(address(this));
        }
        _mint(msg.sender, shares);
        token.transferFrom(msg.sender, address(this), _amount);
        emit Deposit(msg.sender, address(this), _amount);
    }

    function withdraw(uint _shares) external {
        require(token.balanceOf(address(this)) >= _shares, "we dont have XU.");

        /*
        a = amount
        B = balance of token before withdraw
        T = total supply
        s = shares to burn

        (T - s) / T = (B - a) / B 

        a = sB / T
        */
        uint amount = (_shares * token.balanceOf(address(this))) / totalSupply;
        _burn(msg.sender, _shares);
        token.transfer(msg.sender, amount);
        emit Withdraw(msg.sender, address(this), amount);
    }

    // Buy XU
    // 1d -> 1000
    // x > ?
    function buyToken() public payable {
        require(msg.value > 0, "You need send ETH for us.");
        uint256 xuAmount = getValueInDollar(msg.value);
        require(token.balanceOf(address(this)) >= xuAmount, "we dont have XU.");

        payable(owner()).transfer(msg.value);

        token.transfer(msg.sender, xuAmount);
        totalSupply -= xuAmount;
        emit BuyToken(msg.sender, xuAmount, msg.value);
    }

    function payment(uint256 _orderId, uint256 _price) internal {
        require(
            balanceOf[msg.sender] >= _price,
            "Ban khong du XU trong vi, hay nap them XU vao vi."
        );
        balanceOf[msg.sender] -= _price;
        totalSupply += _price;
        orders[_orderId] = Order(msg.sender, _price);
    }

    function getValueInDollar(
        uint256 _ethAmount
    ) public view returns (uint256) {
        AggregatorV3Interface aggregatorV3Interface = AggregatorV3Interface(
            typeConverter
        );
        (, int256 price, , , ) = aggregatorV3Interface.latestRoundData();

        uint256 valuePrice = uint256(price * 1e18);
        uint256 amountinDollars = (valuePrice * _ethAmount) / 1e18;
        return amountinDollars / 10 ** 8;
    }
}