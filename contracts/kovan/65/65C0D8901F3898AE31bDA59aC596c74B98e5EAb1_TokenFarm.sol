// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ownable.sol";
import "IERC20.sol";
import "AggregatorV3Interface.sol";

contract TokenFarm is Ownable {
    // What we want to do:

    // stakeTokens
    // unStakeTokens
    // isssueTokens (reward for staking)
    // addAllowedTokens (add more tokens to farm for staking)
    // getValue (predpokladam bude vyuzivat Chainlink a zjistovat realnou hodnotu?)

    // jake mnozstvi tokenu ma kazdy staker nastejkovano??
    // mapping of: Token address -> (Staker address -> Amount)
    mapping(address => mapping(address => uint256)) public stakingBalance;
    // nemuzeme delat loop skrz mapping, takze potrebujeme pole (kde ulozime stakery)
    address[] public stakers;

    // kolik ruznych tokenu ma staker? (na zaklade toho ho muzeme pridat do pole..)
    mapping(address => uint256) public counterTokensStaked;

    address[] public allowedTokens;

    IERC20 public chillToken; // importovali sme interface ERC20, takze ho muzeme pouzit jako datatype
    mapping(address => address) public tokenPriceFeedMapping;

    constructor(address _chillTokenAddress) public {
        chillToken = IERC20(_chillTokenAddress); // ziskame ABI
    }

    function setPriceFeedContract(address _token, address _priceFeed)
        public
        onlyOwner
    {
        tokenPriceFeedMapping[_token] = _priceFeed;
    }

    function issueTokens() public onlyOwner {
        // budeme rozdavat bonbonky
        for (uint256 i = 0; i < stakers.length; i++) {
            address recipient = stakers[i];
            uint256 userTotalValue = getUserTotalValue(recipient); // potrebujeme kolik $$ celkem ma
            chillToken.transfer(recipient, userTotalValue); // stejne kolik ma $$, tolik mu posleme CHILLu ;) bonbonky 1:1
        }
    }

    function getUserTotalValue(address _user) public view returns (uint256) {
        // normalne se takhle odmeny nerozdavaji
        // lidi si recnou o airdrop
        // protoze loopy stoji hodne GAS!

        uint256 totalValue = 0;
        require(
            counterTokensStaked[_user] > 0,
            "No tokens staked yet! Bez prace nejsou kolace more!"
        );

        for (uint256 i = 0; i < allowedTokens.length; i++) {
            totalValue =
                totalValue +
                getUsersSingleTokenTotalValue(_user, allowedTokens[i]); //potrebuju vedet kolik $$ ma v kazdem coinu
        }
        return totalValue;
    }

    function getUsersSingleTokenTotalValue(address _user, address _token)
        public
        view
        returns (uint256)
    {
        // opet overime, jestli nejake tokeny ma, ale neudelame "require", protoze kdyz ne, chceme pokracovat.
        // takze udelame if
        if (counterTokensStaked[_user] <= 0) {
            return 0;
        }
        // totalValue = price of token * stakingBalance[_token][_user] (vytvorime funkci na price of token "getTokenValue")
        (uint256 price, uint256 decimals) = getTokenValue(_token);
        return ((stakingBalance[_token][_user] * price) / (10**decimals)); // obe hodnoty se posilaji ve WEI (10**18) takze je vydelim a dostanu $$
    }

    function getTokenValue(address _token)
        public
        view
        returns (uint256, uint256)
    {
        // potrebujeme priceFeedAddress
        address priceFeedAddress = tokenPriceFeedMapping[_token];
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            priceFeedAddress
        ); // ABI z interface
        (, int256 price, , , ) = priceFeed.latestRoundData(); // vytahneme jen cenu..
        uint256 decimals = uint256(priceFeed.decimals()); // vraci uint8 - prevedu na uint256 - WHY?? [and where the fuck "decimals" function IS??]
        return (uint256(price), decimals); // opet prevedu price na uint
    }

    function stakeTokens(uint256 _amount, address _token) public {
        // jake tokeny muzou stejkovat? => na to vytvorime specialni fci "tokenIsAllowed"
        // jake mnozstvi muzou stejkovat? => cokoli vetsi nez 0

        require(_amount > 0, "Amount must be more than 0 you freakenFck"); // bo uz jsme ve verzi 0.8, neni potreba SafeMath
        require(tokenIsAllowed(_token), "This token is not allowed!!");

        // "transferFrom" fce ERC20 => protoze nejsem majitele tokenu, tak nevolame "trasfer" fci
        // potrebujeme ABI => takze potrebujeme ERC20 interface (IERC20) => importujeme ho
        // IERC20(_token); tohle je ABI
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        updateCounterTokensStaked(msg.sender, _token); // pricteme dalsi token k stakerovi (az potom mu prictu mnozstvi..)
        stakingBalance[_token][msg.sender] += _amount;

        // pridani stakera do pole vsech staker adres (jen pokud poprve stakuje)
        // takhle zjistim, jesti uz na tom seznamu je nebo neni (aniz bych delal loop celym polem)
        if (counterTokensStaked[msg.sender] == 1) {
            stakers.push(msg.sender);
        }
    }

    // IS THAT VULNERABLE TO RE-ENTRANCY ATTACKS ??!!
    function unStakeTokens(address _token) public {
        require(
            counterTokensStaked[msg.sender] > 0,
            "You dont own any tokens!"
        );
        uint256 balance = stakingBalance[_token][msg.sender];
        require(balance > 0, "You dont own that token!");
        IERC20(_token).transfer(msg.sender, balance);
        stakingBalance[_token][msg.sender] = 0;
        counterTokensStaked[msg.sender] -= 1;
        // jeste vymazat z pole stakeru, pokud uz nema zadne tokeny?
    }

    function updateCounterTokensStaked(address _user, address _token) internal {
        // pokud ten token pridava poprve (jeste tam nema zadne mnozstvi), pricteme mu dalsi druh tokenu k jeho adrese
        if (stakingBalance[_token][_user] <= 0) {
            counterTokensStaked[_user] += 1;
        }
    }

    function addAllowedToken(address _token) public onlyOwner {
        // muze volat jen admin (takze importujem Ownable z OZ)
        allowedTokens.push(_token);
    }

    function tokenIsAllowed(address _token) public view returns (bool) {
        //bude view - nemenime jen cteme..
        // need some list or mapping of tokens, and loop in

        for (uint256 i = 0; i < allowedTokens.length; i++) {
            if (allowedTokens[i] == _token) {
                return true;
            }
        }
        return false;

        // musime vytvorit i fci na pridani allowed tokenu => "addAllowedToken"
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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