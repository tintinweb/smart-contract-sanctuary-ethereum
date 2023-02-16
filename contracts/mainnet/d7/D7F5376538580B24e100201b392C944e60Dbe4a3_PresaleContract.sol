/**
 *Submitted for verification at Etherscan.io on 2023-02-16
*/

// SPDX-License-Identifier: MIT
// dev: Team @Ecoterra - Robert
pragma solidity ^0.8.17;


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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

contract PresaleContract is ReentrancyGuard, Ownable, Pausable {
    struct User {
        //token colectionati
        uint256 tokens_amount;
        //usdt depozitat
        uint256 usdt_deposited;
        //daca a dat claim sau nu
        bool has_claimed;
    }

    struct Round {
        //adresa portofel in care sa ajunga bani
        address payable wallet;
        //cati token cumperi cu 1 usdt
        uint256 usdt_to_token_rate;
        //usdt + eth in usdt
        uint256 usdt_round_raised;
        //usdt + eth in usdt
        uint256 usdt_round_cap;
    }

    IERC20 public usdt_interface;
    IERC20 public token_interface;
    AggregatorV3Interface internal price_feed;

    mapping(address => User) public users_list;
    Round[] public round_list;

    uint8 public current_round_index;
    bool public presale_ended;

    event Deposit(address indexed _user_wallet, uint indexed _pay_method, uint _user_usdt_trans, uint _user_tokens_trans);
    //  _pay_method = ( 1:eth, 2:eth_card, 3:usdt )

    constructor(
        address oracle_, 
        address usdt_, 
        address token_,
        address payable wallet_,
        uint256 usdt_to_token_rate_,
        uint256 usdt_round_cap_
    ) {
        usdt_interface = IERC20(usdt_);
        token_interface = IERC20(token_);
        price_feed = AggregatorV3Interface(oracle_);

        current_round_index = 0;
        presale_ended = false;

        round_list.push(
            Round(wallet_, usdt_to_token_rate_, 0, usdt_round_cap_ * (10**6))
        );
    }

    modifier canPurchase(address user, uint256 amount) {
        require(user != address(0), "PURCHASE ERROR: User address is null!");
        require(amount > 0, "PURCHASE ERROR: Amount is 0!");
        require(presale_ended == false, "PURCHASE ERROR: Presale has ended!");
        _;
    }

    function get_eth_in_usdt() internal view returns (uint256) {
        (, int256 price, , , ) = price_feed.latestRoundData();
        price = price * 1e10;
        return uint256(price);
    }

    function buy_with_usdt(uint256 amount_)
        external
        nonReentrant
        whenNotPaused
        canPurchase(_msgSender(), amount_)
        returns (bool)
    {
        uint256 amount_in_usdt = amount_;
        require(
            round_list[current_round_index].usdt_round_raised + amount_in_usdt <
                round_list[current_round_index].usdt_round_cap,
            "BUY ERROR : Too much money already deposited."
        );

        uint256 allowance = usdt_interface.allowance(msg.sender, address(this));

        require(amount_ <= allowance, "BUY ERROR: Allowance is too small!");

        bool success_receive = usdt_interface.transferFrom(_msgSender(), round_list[current_round_index].wallet, amount_in_usdt);

        require(success_receive, "BUY ERROR: Transaction has failed!");

        uint256 amount_in_tokens = (amount_in_usdt *
            round_list[current_round_index].usdt_to_token_rate) * 1e3;

        users_list[_msgSender()].usdt_deposited += amount_in_usdt;
        users_list[_msgSender()].tokens_amount += amount_in_tokens;

        round_list[current_round_index].usdt_round_raised += amount_in_usdt;

        emit Deposit(_msgSender(), 3, amount_in_usdt, amount_in_tokens);

        return true;
    }

    function buy_with_eth()
        external
        payable
        nonReentrant
        whenNotPaused
        canPurchase(_msgSender(), msg.value)
        returns (bool)
    {

        uint256 amount_in_usdt = (msg.value * get_eth_in_usdt()) / 1e30;
        require(
            round_list[current_round_index].usdt_round_raised + amount_in_usdt <
                round_list[current_round_index].usdt_round_cap,
            "BUY ERROR : Too much money already deposited."
        );

        uint256 amount_in_tokens = (amount_in_usdt *
            round_list[current_round_index].usdt_to_token_rate) * 1e3;

        users_list[_msgSender()].usdt_deposited += amount_in_usdt;
        users_list[_msgSender()].tokens_amount += amount_in_tokens;

        round_list[current_round_index].usdt_round_raised += amount_in_usdt;

        (bool sent,) = round_list[current_round_index].wallet.call{value: msg.value}("");
        require(sent, "Failed to send Ether");

        emit Deposit(_msgSender(), 1, amount_in_usdt, amount_in_tokens);

        return true;
    }

    function buy_with_eth_wert(address user)
        external
        payable
        nonReentrant
        whenNotPaused
        canPurchase(user, msg.value)
        returns (bool)
    {

        uint256 amount_in_usdt = (msg.value * get_eth_in_usdt()) / 1e30;
        require(
            round_list[current_round_index].usdt_round_raised + amount_in_usdt <
                round_list[current_round_index].usdt_round_cap,
            "BUY ERROR : Too much money already deposited."
        );

        uint256 amount_in_tokens = (amount_in_usdt *
            round_list[current_round_index].usdt_to_token_rate) * 1e3;

        users_list[user].usdt_deposited += amount_in_usdt;
        users_list[user].tokens_amount += amount_in_tokens;

        round_list[current_round_index].usdt_round_raised += amount_in_usdt;

        (bool sent,) = round_list[current_round_index].wallet.call{value: msg.value}("");
        require(sent, "Failed to send Ether");

        emit Deposit(user, 2, amount_in_usdt, amount_in_tokens);

        return true;
    }

    function claim_tokens() external returns (bool) {
        require(presale_ended, "CLAIM ERROR : Presale has not ended!");
        require(
            users_list[_msgSender()].tokens_amount != 0,
            "CLAIM ERROR : User already claimed tokens!"
        );
        require(
            !users_list[_msgSender()].has_claimed,
            "CLAIM ERROR : User already claimed tokens"
        );

        uint256 tokens_to_claim = users_list[_msgSender()].tokens_amount;
        users_list[_msgSender()].tokens_amount = 0;
        users_list[_msgSender()].has_claimed = true;

        bool success = token_interface.transfer(_msgSender(), tokens_to_claim);

        require(success, "CLAIM ERROR : Couldn't transfer tokens to client!");

        return true;
    }

    function start_next_round(
        address payable wallet_,
        uint256 usdt_to_token_rate_,
        uint256 usdt_round_cap_
    ) external onlyOwner {
        current_round_index = current_round_index + 1;

        round_list.push(
            Round(wallet_, usdt_to_token_rate_, 0, usdt_round_cap_ * (10**6))
        );
    }

    function set_current_round(
        address payable wallet_,
        uint256 usdt_to_token_rate_,
        uint256 usdt_round_cap_
    ) external onlyOwner {
        round_list[current_round_index].wallet = wallet_;
        round_list[current_round_index]
            .usdt_to_token_rate = usdt_to_token_rate_;
        round_list[current_round_index].usdt_round_cap = usdt_round_cap_ * (10**6);
    }

    function get_current_round()
        external
        view
        returns (
            address,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            round_list[current_round_index].wallet,
            round_list[current_round_index].usdt_to_token_rate,
            round_list[current_round_index].usdt_round_raised,
            round_list[current_round_index].usdt_round_cap
        );
    }

    function get_current_raised() external view returns (uint256) {
        return round_list[current_round_index].usdt_round_raised;
    }

    function end_presale() external onlyOwner {
        presale_ended = true;
    }

    function withdrawToken(address tokenContract, uint256 amount) external onlyOwner {
        IERC20(tokenContract).transfer(_msgSender(), amount);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}