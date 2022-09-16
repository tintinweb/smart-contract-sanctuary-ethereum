/**
 *Submitted for verification at Etherscan.io on 2022-09-16
*/

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

// File: AntkPrivateTest.sol


pragma solidity 0.8.17;




/**
 * @title Private Sale ANTK
 *
 * @notice This contract is a pre sale contract
 *
 * @dev Buyers can buy only with ETH or USDT
 * @dev Can add whitelists address to buy first
 *
 * @dev Implementation of the {IERC20} interface
 * @dev Implementation of the {Ownable} contract
 * @dev Implementation of the {AggregatorV3Interface} contract
 *
 */

contract AntkPrivateTest is Ownable {
    /**
     * @dev tether is the only ERC20 asset to buy ANTK
     */
    address usdt = 0x05e797F41f54e7Ef542775143B43f0B224B11760;

    /**
     * @dev numberOfTokenToSell is the number of ANTK to sell
     * @dev It is update when someone buy
     */
    uint128 public numberOfTokenToSell = 500000000;

    /// save informations about the buyers
    struct Investor {
        bool isWhitelisted;
        uint128 numberOfTokensPurchased;
        uint128 amountSpendInDollars;
    }

    /// buyer's address  => buyer's informations
    mapping(address => Investor) public investors;

    /// status of this sales contract
    enum SalesStatus {
        AdminTime,
        SalesForWhitelist,
        SalesForAll
    }

    /// salesStatus is the status of the sales
    SalesStatus public salesStatus;

    /// event when owner change status
    event newStatus(SalesStatus newStatus);

    /// event when someone buy
    event TokensBuy(
        address addressBuyer,
        uint128 numberOfTokensPurchased,
        uint128 amountSpendInDollars
    );

    /**
     * @notice check that the purchase parameters are correct
     * @dev called in function buy with ETH and buy with USDT
     * @param _amount is the amount to buy in dollars
     */
    modifier requireToBuy(uint128 _amount) {
        require(
            (investors[msg.sender].isWhitelisted &&
                salesStatus == SalesStatus(1)) || salesStatus == SalesStatus(2),
            "Vous ne pouvez pas investir pour le moment !"
        );
        require(
            _amount>=1,
            "Ce montant est inferieur au montant minimum !"
        );
        require(
            calculNumberOfTokenToBuy(_amount) <= numberOfTokenToSell,
            "Il ne reste plus assez de tokens disponibles !"
        );
        _;
    }

    /**
     * @notice add the address to the whitelist
     * @dev only the Owner of the contract can call this function
     * @param _address is an array of address
     */
    function setWhitelist(address[] memory _address) external onlyOwner {
        for (uint256 i = 0; i < _address.length; i++) {
            investors[_address[i]].isWhitelisted = true;
        }
    }

    /**
     * @notice change the status of the sale
     * @dev only the Owner of the contract can call this function
     * @param _idStatus is the id of the status
     */
    function changeSalesStatus(uint256 _idStatus) external onlyOwner {
        salesStatus = SalesStatus(_idStatus);

        emit newStatus(SalesStatus(_idStatus));
    }

    /**
     * @notice calcul number of token to buy
     * @dev this is a public function, called in the modifier and buy function
     * @dev we use it with the dapp to show the number of token to buy
     * @param _amountDollars is the amount to buy in dollars
     */
    function calculNumberOfTokenToBuy(uint128 _amountDollars)
        public
        view
        returns (uint128)
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
     * @notice buy ANTK with USDT
     * @param _amountDollars is the amount to buy in dollars
     */
    function buyTokenWithTether(uint128 _amountDollars)
        external
        requireToBuy(_amountDollars)
    {
        require(
            IERC20(usdt).allowance(msg.sender, address(this)) >=
                _amountDollars * 10**6,
            "Vous n'avez pas approuve le transfert de Tether !"
        );
        require(
            IERC20(usdt).balanceOf(msg.sender) >= _amountDollars * 10**6,
            "Vous n'avez pas assez de Tether !"
        );

        uint128 numberOfTokenToBuy = calculNumberOfTokenToBuy(_amountDollars);

        bool result = IERC20(usdt).transferFrom(
            msg.sender,
            address(this),
            _amountDollars * 10**6
        );
        require(result, "Transfer from error");

        investors[msg.sender]
            .numberOfTokensPurchased += numberOfTokenToBuy;
        investors[msg.sender].amountSpendInDollars += _amountDollars;

        emit TokensBuy(
            msg.sender,
            numberOfTokenToBuy,
            _amountDollars
        );

        numberOfTokenToSell -= numberOfTokenToBuy;
    }

    /**
     * @notice Get price of ETH in $ with Chainlink
     */
    function getLatestPrice() public pure returns (uint128) {
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        // );
        // (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 price = 150000000000;
        return uint128(uint256(price));
    }

    /**
     * @notice buy ANTK with ETH
     * @dev msg.value is the amount of ETH to send buy the buyer
     */
    function buyTokenWithEth()
        external
        payable
        requireToBuy(uint128((msg.value * getLatestPrice()) / 10**26))
    {
        require(
            msg.sender.balance > msg.value,
            "Vous n'avez pas assez d'ETH !"
        );
        uint128 amountInDollars = uint128(
            (msg.value * getLatestPrice()) / 10**26
        );

        uint128 numberOfTokenToBuy = calculNumberOfTokenToBuy(amountInDollars);

        investors[msg.sender]
            .numberOfTokensPurchased += numberOfTokenToBuy;
        investors[msg.sender].amountSpendInDollars += amountInDollars;

        emit TokensBuy(
            msg.sender,
            numberOfTokenToBuy,
            amountInDollars
        );

        numberOfTokenToSell -= numberOfTokenToBuy;
    }

    /**
     * @notice send the USDT and the ETH to ANTK company
     * @dev only the Owner of the contract can call this function
     */
    function getFunds() external onlyOwner {
        IERC20(usdt).transfer(owner(), IERC20(usdt).balanceOf(address(this)));

        (bool sent, ) = owner().call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    /**
     * @notice see the USDT and the ETH on the contract
     */
    function seeFunds() external view returns (uint256 USDT, uint256 ETH) {
        return (IERC20(usdt).balanceOf(address(this)), address(this).balance);
    }
}

// ETH/USD Chainlink (ETH Mainet): 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419 (8 décimales)
// ETH/USD Chainlink (ETH Goerli Testnet): 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e (8 décimales)

// USDT mainet address 0xdAC17F958D2ee523a2206206994597C13D831ec7 (6 décimales)
// USDC Ropsten for tests : 0x07865c6E87B9F70255377e024ace6630C1Eaa37F (6 décimales)

//Interface     function investors (address _address) external view returns
//(bool isWhitelisted, address referrer, uint numberOfTokensPurchased, uint amountSpendInDollars, string memory asset);

// function getOwnerBalance(address addr) public view returns (uint) {
//     return addr.balance;
// }

// [0x1dCDc0A79dac4ff8Ed895453dFE89402f7248D04,0xdCCfba966ee4d796099F987e32ceb104C7FC6653,0x7569Bd912eBB96b427DD33A1Dfbcb0A04235B97f,0x5Ced2f3EE793Ec0106cf8C9b2dc9b0b2CAFc5c52,0x90707B780319c7cA040c7c6B041E285f837E130B,0x6E4294AAfb21Df95Bb0578E104E791EeFE378c7B,0x51eE6aE0c3574C7d39084280389e57Bf02fe09a5,0x1Bf9Ee786B600A294DFd0151D1aF027a286A8f4B,0x311EEfAE053Eeb0fB77C750Ee3d84dFd88B2c5b5,0x39C4Ce965b9F81de90D5F91127afB807bdd1F705,0x4412d9ec2Fc336C28D0bfFeE7aF70fb34eA0ad73,0x726C04AA475B0A3Ab02c462aA38018a1Cd483A31,0x54d5d33C8E70A87edBFE24BbF7eFf4353CD3a460,0x4005De8557D796631dA6539D3d11a715485Eb03C,0xC895f2a7E0e338F7996fE1E0233c22a24a2A2359,0x7C61135E243Fa101B6Cc0F166e341A034b208420,0x5eC00cD9ff8b2D14d968B440879D335AE7bB5EC7,0x7b50aF1EC8E6634B88d7dAb4e785Bc852f1ef130,0xc16E917FaB5e13FDfe9E319522A6d9844d481C8d,0x29903927DAA5b70BE16178Cb6F955C8DE144ecEE,0x2DbA0f48cdaA3A3E95a342bA2C2ce41F64E30994,0x23e9cCf6Fbaf8A6ACc0162a7cC19A25983407260,0x4589bF02926c184E1a26E2698e9d79acaB7A33f8,0x8ff48d01152C8116404E6a3347d15E39992cc32b,0xC8E59966D04aa1297583950e4FfE7Fb25084bC95,0x622BFeb402067662acFb40Ba68df9804c7d6BccA,0x84A651d21d432BdF4804f8bc44D978F0dd653475,0x19E35115C0d4E1036eEB963bc5400a37b513c72A,0x7D401190854336dE8F6F3060C464783c327abeA2,0x1dB8bca1761286345117D71dc6604f6Bc84ECFcB]
// [0x1dCDc0A79dac4ff8Ed895453dFE89402f7248D04,0xdCCfba966ee4d796099F987e32ceb104C7FC6653,0x7569Bd912eBB96b427DD33A1Dfbcb0A04235B97f]