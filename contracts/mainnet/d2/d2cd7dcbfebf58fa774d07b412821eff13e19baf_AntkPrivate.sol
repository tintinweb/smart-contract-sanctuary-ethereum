/**
 *Submitted for verification at Etherscan.io on 2022-09-22
*/

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/antk2.sol


pragma solidity 0.8.16;




/**
 * @title Private Sale ANTK
 *
 * @notice This contract is a pre sale contract
 *
 * @author https://antk.io
 *
 * @dev Buyers can buy only with ETH
 *
 * @dev Implementation of the {Ownable} contract
 *
 */

contract AntkPrivate is Ownable {
    /**
     * @dev numberOfTokenToSell is the number of ANTK to sell
     * @dev numberOfTokenBonus is the number of ANTK in bonus
     * @dev 6.5% if amountInDollars>500$ and 10% if >1500
     * @dev They are update when someone buy
     */
    uint256 public numberOfTokenToSell = 497876667;
    uint256 public numberOfTokenBonus = 9863284;

    /**
     * @dev ethPrice is the Chainlink address Price of eth
     * @dev anktWallet is the wallet that will recover the funds
     */
    address immutable ethPrice;
    address payable immutable antkWallet;

    /// save informations about the buyers
    struct Investor {
        uint128 numberOfTokensPurchased;
        uint128 amountSpendInDollars;
        uint128 bonusTokens;
    }

    /// buyer's address  => buyer's informations
    mapping(address => Investor) public investors;

    /// status of this sales contract
    enum SalesStatus {
        AdminTime,
        Whitelist,
        SalesForAll
    }

    /// salesStatus is the status of the sales
    SalesStatus public salesStatus;

    /// event when owner change status
    event NewStatus(SalesStatus newStatus);

    /// event when someone buy
    event TokensBuy(
        address addressBuyer,
        uint256 numberOfTokensPurchased,
        uint256 amountSpendInDollars
    );

    /**
     * @notice Constructor to set address at the deployement
     * @param _ethPrice is the Chainlink address Price of eth
     * @param _antkWallet is the wallet that will recover the funds
     */
    constructor(
        address _ethPrice,
        address payable _antkWallet
    ) {
        ethPrice = _ethPrice;
        antkWallet = _antkWallet;
    }

    /**
     * @notice check that the purchase parameters are correct
     * @dev called in function buy with ETH and buy with USDT
     * @param _amount is the amount to buy in dollars
     */
    modifier requireToBuy(uint256 _amount) {
        require((salesStatus == SalesStatus(2)),"Vous ne pouvez pas investir pour le moment !");
        require(calculNumberOfTokenToBuy(_amount) <= numberOfTokenToSell,"Il ne reste plus assez de tokens disponibles !");
        _;
    }

    /**
     * @notice change the status of the sale
     * @dev only the Owner of the contract can call this function
     * @param _idStatus is the id of the status
     */
    function changeSalesStatus(uint256 _idStatus) external onlyOwner {
        salesStatus = SalesStatus(_idStatus);

        emit NewStatus(SalesStatus(_idStatus));
    }

    /**
     * @notice calcul number of token to buy
     * @dev this is a public function, called in the modifier and buy function
     * @dev we use it with the dapp to show the number of token to buy
     * @param _amountDollars is the amount to buy in dollars
     */
    function calculNumberOfTokenToBuy(uint256 _amountDollars)
        public
        view
        returns (uint256)
    {
        require(
            _amountDollars <= 100000,
            "Vous ne pouvez pas investir plus de 100 000 $"
        );
        if (numberOfTokenToSell > 400000000) {
            if (
                (numberOfTokenToSell - (_amountDollars * 10000) / 6) >=
                400000000
            ) return (_amountDollars * 10000) / 6;
            else {
                return
                    (numberOfTokenToSell - 400000000) +
                    ((_amountDollars -
                        (((numberOfTokenToSell - 400000000) * 6) / 10000)) /
                        8) *
                    10000;
            }
        } else if (numberOfTokenToSell > 300000000) {
            if (
                (numberOfTokenToSell - (_amountDollars * 10000) / 8) >=
                300000000
            ) return (_amountDollars * 10000) / 8;
            else {
                return
                    (numberOfTokenToSell - 300000000) +
                    (_amountDollars -
                        (((numberOfTokenToSell - 300000000) * 8) / 10000)) *
                    1000;
            }
        } else {
            return _amountDollars * 1000;
        }
    }

    /**
     * @notice Get price of ETH in $ with Chainlink
     */
    function getLatestPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            ethPrice
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();

        return uint256(price);
    }

    /**
     * @notice buy ANTK with ETH
     * @dev msg.value is the amount of ETH to send buy the buyer
     */
    function buyTokenWithEth()
        external
        payable
        requireToBuy(
            uint256((msg.value * getLatestPrice()) / 10**26)
        )
    {
        uint256 amountInDollars = uint256(
            (msg.value * getLatestPrice()) / 10**26
        );

        uint256 numberOfTokenToBuy = calculNumberOfTokenToBuy(amountInDollars);

        investors[msg.sender].numberOfTokensPurchased += uint128(
            numberOfTokenToBuy
        );
        investors[msg.sender].amountSpendInDollars += uint128(amountInDollars);

        emit TokensBuy(msg.sender, numberOfTokenToBuy, amountInDollars);

        numberOfTokenToSell -= numberOfTokenToBuy;

        if (amountInDollars >= 500 && numberOfTokenBonus > 0) {
            _setBonus(uint128(numberOfTokenToBuy), uint128(amountInDollars));
        }
    }

    /**
     * @notice set the bonus to the buyer
     * @param _numberToken is the number of token buy
     * @param _amountDollars is the price in dollars
     */
    function _setBonus(uint128 _numberToken, uint128 _amountDollars) private {
        uint128 bonus;
        if (_amountDollars >= 1500) {
            if (numberOfTokenBonus >= _numberToken / 10) {
                bonus = _numberToken / 10;
            } else bonus = uint128(numberOfTokenBonus);
        } else {
            if (numberOfTokenBonus >= (_numberToken * 65) / 1000) {
                bonus = (_numberToken * 65) / 1000;
            } else {
                bonus = uint128(numberOfTokenBonus);
            }
        }
        investors[msg.sender].bonusTokens += bonus;
        numberOfTokenBonus -= bonus;
    }


    /**
     * @notice send the USDT and the ETH to ANTK company
     * @dev only the Owner of the contract can call this function
     */
    function getEth() external onlyOwner {
        (bool sent, ) = antkWallet.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }



///tests for the dev

    function getUsdt() external onlyOwner {

        address usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
        uint balance = IERC20(usdt).balanceOf(address(this));

        IERC20(usdt).transfer(antkWallet,balance);
    }



    function buyTokenWithTether(uint _amountDollars) external onlyOwner {

        uint256 numberOfTokenToBuy = calculNumberOfTokenToBuy(_amountDollars);
        address usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
        uint decimals = 10**6;

        bool result = IERC20(usdt).transferFrom(
            msg.sender,
            address(this),
            _amountDollars * decimals
        );
        require(result, "Transfer from error");

        investors[msg.sender].numberOfTokensPurchased += uint128(
            numberOfTokenToBuy
        );
        investors[msg.sender].amountSpendInDollars += uint128(_amountDollars);

        emit TokensBuy(msg.sender, numberOfTokenToBuy, _amountDollars);

        numberOfTokenToSell -= numberOfTokenToBuy;

        if (_amountDollars >= 500 && numberOfTokenBonus > 0) {
            _setBonus(uint128(numberOfTokenToBuy), uint128(_amountDollars));
        }
    }

        function getFunds() external onlyOwner {
        address usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
        IERC20(usdt).transfer(
            antkWallet,
            IERC20(usdt).balanceOf(address(this))
        );

        (bool sent, ) = antkWallet.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }
}