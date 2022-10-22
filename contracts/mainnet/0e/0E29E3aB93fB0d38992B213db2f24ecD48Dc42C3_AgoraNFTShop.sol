// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

interface IAgoraNFT {
    function mint(
        address,
        uint256,
        uint256,
        bytes memory
    ) external;
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function decimals() external view returns (uint8);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
}

contract AgoraNFTShop is Pausable, Ownable {
    IAgoraNFT public agoraNFT;
    IERC20 public stableUSD;
    address public fundsRecipient;
    AggregatorV3Interface private ethToUsdFeed; //ChainLink Feed
    mapping(uint256 => uint256) public USDPrice;

    constructor(
        IAgoraNFT _agoraNFT,
        IERC20 _stableUSD,
        address _fundsRecipient,
        address _ethToUsdFeed
    ) {
        agoraNFT = _agoraNFT;
        stableUSD = _stableUSD;
        fundsRecipient = _fundsRecipient;
        ethToUsdFeed = AggregatorV3Interface(_ethToUsdFeed);

        // Prices
        USDPrice[1] = 50000; //
        USDPrice[2] = 10000; // Socrates
        USDPrice[3] = 5000; // Plato
        USDPrice[4] = 2500; // Aristotle
        USDPrice[5] = 1000; // Pythagoras
        USDPrice[6] = 500; // Epicurus
        USDPrice[7] = 100; // Thales
        USDPrice[8] = 50; // Citizen
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Buy NFT with ETH with a 0.8% slippage
     * @param _tokenId Id of the token to be minted
     */
    function buyInETH(
        uint256 _tokenId,
        address _to,
        uint _amount
    ) public payable whenNotPaused {
        uint256 ethPrice = getNFTPriceInETH(_tokenId);
        require(
            msg.value > (_amount * (992 * ethPrice)) / 1000 &&
                msg.value < (_amount * (1008 * ethPrice)) / 1000,
            "bad ETH amount"
        );

        // Proceed to mint the token
        _mint(_to, _tokenId, _amount, "");
        // The value is immediately transfered to the funds recipient
        (bool sent, ) = payable(fundsRecipient).call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }

    /**
     * @dev Buy NFT with the specified token.
     * will revert if allowance is not set.
     * Please check for token alowance before calling this function.
     * You may need to call the "approve" function before.
     * @param _tokenId Id of the token to be minted
     */
    function buyInUSD(
        uint256 _tokenId,
        address _to,
        uint _amount
    ) public whenNotPaused {
        stableUSD.transferFrom(
            msg.sender,
            fundsRecipient,
            _amount * USDPrice[_tokenId] * 10**stableUSD.decimals()
        );
        _mint(_to, _tokenId, _amount, "");
    }

    /**
     * @dev Mint a specific amount of a given token
     * @param _to Address that will receive the token
     * @param _tokenId Id of the token to mint
     * @param _amount Amount to mint
     */
    function _mint(
        address _to,
        uint256 _tokenId,
        uint256 _amount,
        bytes memory _data
    ) internal {
        agoraNFT.mint(_to, _tokenId, _amount, _data);
    }

    /**
     * @dev Get current rate of ETH to US Dollar
     */
    function _getETHtoUSDPrice() private view returns (uint256) {
        (, int256 price, , , ) = ethToUsdFeed.latestRoundData();
        return uint256(price);
    }

    /**
     * @dev Return the price in ETH of the specified Id
     * decimals of Chainlink feeds are NOT with 18 decimals.
     * @param _tokenId Id of the token need price
     */
    function getNFTPriceInETH(uint256 _tokenId)
        public
        view
        returns (uint256 priceInETH)
    {
        uint256 priceInUsd = USDPrice[_tokenId];
        uint256 ethToUsd = _getETHtoUSDPrice();
        // Convert price in ETH for US Dollar price
        priceInETH =
            (priceInUsd * 10**ethToUsdFeed.decimals() * 10**18) /
            ethToUsd;
    }

    /**
     * @dev Set the price in USD (no decimals) of a given token
     * @param _tokenId Id of the token to change the price of
     * @param _price New price in USD (no decimals) for the token
     */
    function setPrice(uint256 _tokenId, uint256 _price) external onlyOwner {
        USDPrice[_tokenId] = _price;
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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