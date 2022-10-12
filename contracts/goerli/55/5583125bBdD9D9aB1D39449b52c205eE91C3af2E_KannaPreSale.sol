/**
 *Submitted for verification at Etherscan.io on 2022-10-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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

/** @title KNN PreSale for KNN Token
    @author KANNA Team
    @custom:github  https://github.com/kanna-coin
    @custom:site https://kannacoin.io
    @custom:discord https://discord.gg/V5KDU8DKCh
    */
contract KannaPreSale is Ownable {
    IERC20 public immutable knnToken;
    AggregatorV3Interface public priceAggregator;
    uint256 public constant USD_AGGREGATOR_DECIMALS = 1e8;
    uint256 public constant KNN_DECIMALS = 1e18;
    uint256 public knnPriceInUSD;
    bool public available;

    event Purchase(
        address indexed holder,
        uint256 amountInWEI,
        uint256 knnPriceInUSD,
        uint256 ethPriceInUSD,
        uint256 indexed amountInKNN
    );

    event QuotationUpdate(address indexed sender, uint256 from, uint256 to);
    event Withdraw(address indexed recipient, uint256 amount);

    constructor(address _knnToken) {
        knnToken = IERC20(_knnToken);

        if (block.chainid == 1 || block.chainid == 31337) {
            // chainlink eth-usd feed @ mainnet
            priceAggregator = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        } else if (block.chainid == 5) {
            // chainlink eth-usd feed @ goerli testnet
            priceAggregator = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
        } else {
            revert("Unsupported chain");
        }
    }

    /**
     * @dev Withdraw ETH from sold tokens
     */
    function withdraw(address payable recipient) external onlyOwner {
        uint256 amount = address(this).balance;
        recipient.transfer(amount);

        emit Withdraw(recipient, amount);
    }

    /**
     * @dev Update Pre-Sale availability
     *
     * @param _available (true: available | false: unavailable)
     */
    function updateAvailablity(bool _available) external onlyOwner {
        available = _available;
    }

    /**
     * @dev Return non-sold tokens and ends pre-sale
     *
     */
    function end(address leftoverRecipient) external onlyOwner {
        available = false;
        uint256 leftover = knnToken.balanceOf(address(this));
        knnToken.transfer(leftoverRecipient, leftover);
    }

    /**
     * @dev Retrieves current token price in ETH
     */
    function price() external view returns (uint256) {
        require(knnPriceInUSD > 0, "Quotation unavailable");
        return knnPriceInUSD;
    }

    /**
     * @dev Update tokenQuotation to a new value in ETH
     *
     * Emits a {QuotationUpdate} event.
     *
     * @param targetQuotation unit price in ETH
     *
     */
    function updateQuotation(uint256 targetQuotation) external onlyOwner {
        require(targetQuotation > 0, "Invalid quotation");
        emit QuotationUpdate(msg.sender, knnPriceInUSD, targetQuotation);

        knnPriceInUSD = targetQuotation;
    }

    /**
     * @dev Converts a given amount {amountInKNN} to WEI
     */
    function convertToWEI(uint256 amountInKNN) public view returns (uint256, uint256) {
        require(knnPriceInUSD > 0, "KNN price not set");

        (, int256 answer, , , ) = priceAggregator.latestRoundData();

        uint256 ethPriceInUSD = uint256(answer);
        require(ethPriceInUSD > 0, "Invalid round answer");

        return ((amountInKNN * knnPriceInUSD) / ethPriceInUSD, ethPriceInUSD);
    }

    /**
     * @dev Converts a given amount {amountInWEI} to KNN
     */
    function convertToKNN(uint256 amountInWEI) public view returns (uint256, uint256) {
        require(knnPriceInUSD > 0, "KNN price not set");

        (, int256 answer, , , ) = priceAggregator.latestRoundData();

        uint256 ethPriceInUSD = uint256(answer);
        require(ethPriceInUSD > 0, "Invalid round answer");

        return ((amountInWEI * ethPriceInUSD) / knnPriceInUSD, ethPriceInUSD);
    }

    /**
     * @dev Allows users to buy tokens for ETH
     * See {tokenQuotation} for unitPrice.
     *
     * Emits a {Purchase} event.
     */
    function buyTokens() external payable {
        require(available, "Pre sale NOT started yet");
        require(msg.value > USD_AGGREGATOR_DECIMALS, "Invalid amount");

        (uint256 finalAmount, uint256 ethPriceInUSD) = convertToKNN(msg.value);

        require(knnToken.balanceOf(address(this)) >= finalAmount, "Insufficient supply!");
        require(knnToken.transfer(msg.sender, finalAmount), "Transaction reverted!");
        emit Purchase(msg.sender, msg.value, knnPriceInUSD, ethPriceInUSD, finalAmount);
    }

    fallback() external payable {
        revert("Fallback: Should call {buyTokens} function in order to swap ETH for KNN");
    }

    receive() external payable {
        revert("Cannot Receive: Should call {buyTokens} function in order to swap ETH for KNN");
    }
}