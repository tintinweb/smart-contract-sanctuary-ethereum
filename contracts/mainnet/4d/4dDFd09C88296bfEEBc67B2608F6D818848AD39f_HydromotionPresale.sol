/**
 *Submitted for verification at Etherscan.io on 2023-06-12
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


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

// File: HydromotionPresale.sol


pragma solidity 0.8.17;



interface erc20 {
    function mint(address to, uint256 amount) external;

    function presaleTransfer(address to, uint256 amount)
        external
        returns (bool);
}

contract HydromotionPresale {
    uint256 public minBuy = 1000 * 10**2;
    uint256 public minBuyFiat = 10000 * 10**2;

    uint256 totalBought;

    address public erc20Address;
    address private OwnerIs;

    constructor(
        ) {
        OwnerIs = msg.sender;
    }

    function CurrentPrice() public view returns (uint256) {
        uint256 a = getEURtoUSDPrice() * 1 ether;
        uint256 b = getUSDtoETHPrice() * 1 ether;

        if (totalBought <= 10000000000 * 10**2) {
            return (1 ether / (b / a)) / 100;
        } else if (totalBought <= 20000000000 * 10**2) {
            return (1 ether / (b / a)) / 10;
        } else if (totalBought <= 30000000000 * 10**2) {
            return 1 ether / (b / a);
        } else if (totalBought <= 40000000000 * 10**2) {
            return (1 ether / (b / a)) * 10;
        } else {
            revert("Already Max Minted, Now Only Owner Can Mint");
        }
    }

    function getEURtoUSDPrice() internal view returns (uint256) {
        AggregatorV3Interface priceFeed;

        priceFeed = AggregatorV3Interface(
            0xb49f677943BC038e9857d61E7d053CaA2C1734C1
        );
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeed.latestRoundData();
        return uint256(price);
    }

    function getUSDtoETHPrice() internal view returns (uint256) {
        AggregatorV3Interface priceFeed;

        priceFeed = AggregatorV3Interface(
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        );
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeed.latestRoundData();
        return uint256(price);
    }

    function buy(uint256 amount) external payable {
        address caller = msg.sender;

        require(amount >= minBuy, "Low Amount Pass");

        require(
            msg.value >= (CurrentPrice() * (amount / 10**2)),
            "Low Value Pass"
        );
        IERC20(erc20Address).transfer(caller, (amount));

        totalBought = totalBought + (amount);
    }

    function fiatBuy(uint256 amount, address account) external onlyOwner {
        require(amount >= minBuyFiat, "Low Amount Pass");

        IERC20(erc20Address).transfer(account, (amount));

        totalBought = totalBought + (amount);
    }

    function transfer(uint256 amount, address account)
        public
        virtual
        returns (bool)
    {
        address caller = msg.sender;

        require(
            IERC20(erc20Address).balanceOf(caller) >= amount,
            "Not Enough tokens abailable"
        );

        erc20(erc20Address).presaleTransfer(account, amount);

        return false;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Failed to send amount");
    }

    function withdrawTokens(uint256 amount, address account)
        external
        onlyOwner
    {
        IERC20(erc20Address).transfer(account, amount);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        erc20(erc20Address).mint(to, amount);

        totalBought = totalBought + amount;
    }

    function transferOwnership(address account) external onlyOwner {
        OwnerIs = account;
    }

    function setTokenAddress(address tokenAddress) external onlyOwner {
        erc20Address = tokenAddress;
    }

    function setMinBuy(uint256 _minBuy) external onlyOwner {
        minBuy = _minBuy;
    }

    function setMinBuyFiat(uint256 _minBuyFiat) external onlyOwner {
        minBuyFiat = _minBuyFiat;
    }

    modifier onlyOwner() {
        require(msg.sender == OwnerIs, "only Owner Function");
        _;
    }
}