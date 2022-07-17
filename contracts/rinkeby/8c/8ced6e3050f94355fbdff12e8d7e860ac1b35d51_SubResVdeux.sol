/**
 *Submitted for verification at Etherscan.io on 2022-07-17
*/

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

// File: SubResVdeux.sol





pragma solidity ^0.8.15;





///TO DO: Add transfertOwnership Func

///TO DO: Add DenisToken interactions



contract SubResVdeux is Ownable {

    IERC20 private addressDenisToken;

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////

    ///VARIABLES



    address payable private burnAddress; ///Debatable if public/private



    enum state {

        ONLINE,

        BURN_INITIATED

    }

    state public currState;



    uint256 public maxSupply;

    uint256 public currSupply;

    uint256 public lockedSupply;

    uint256 public freeSupply;



    uint256 private initTime;



    uint256 private _burnGoal;

    uint256 private _multiSigCount;



    struct user {

        bool registered;

        bool signed;

    }



    mapping(address => user) users;

    address[] private userAccounts;



    ////////////////////////////////////////////////////////////////////////////////////////////////////////////

    ///MODIFIERS



    ///Requires that only authorized addresses can perform this action

    modifier onlyAuthorized() {

        require(users[msg.sender].registered == true, "Non Authorized Address");

        _;

    }



    ///Requires that the State is ONLINE

    modifier contractReady() {

        require(currState == state.ONLINE, "Contract not ready");

        _;

    }



    ///Requires that the State is BURN_INITIATED

    modifier burnInitiated() {

        require(

            currState == state.BURN_INITIATED,

            "Contract is awaiting Burn action"

        );

        _;

    }



    ///Requires message Sender to not already have approuved (avoiding double signature)

    modifier notSigned() {

        require(users[msg.sender].signed == false, "User has already Signed");

        _;

    }



    ////////////////////////////////////////////////////////////////////////////////////////////////////////////

    ///FUNCTIONS

    constructor(

        address payable _burnAddress,

        uint256 _supplySubRes,

        IERC20 _tokenAddress

    ) {

        addressDenisToken = _tokenAddress; ///Smart Contract Address

        burnAddress = _burnAddress;

        maxSupply = _supplySubRes;

        currSupply = _supplySubRes;

        lockedSupply = 0;

        freeSupply = currSupply - lockedSupply;

        _burnGoal = 0;

        _multiSigCount = 0;

        users[msg.sender].registered = true;

        users[msg.sender].signed = false;

    }



    ///Set locked amount of Subscription Reserve

    function lockTokens(uint256 newLockedTokens) public onlyOwner {

        require(newLockedTokens <= currSupply, "Not enough Supply");

        lockedSupply = newLockedTokens;

        freeSupply = currSupply - lockedSupply;

    }



    /*

    ///Read Balance/Locked Amount/Free Amount

    function get() public view returns(uint, uint, uint) {

        return(LockedSupply, FreeSupply, CurrSupply);

    }

    */



    ///Set New authorized Address



    //Check if Address already authorized

    function newAddress(address newAuthorizedAddress) public onlyOwner {

        users[newAuthorizedAddress].registered = true;

        users[newAuthorizedAddress].signed = false;

        userAccounts.push(newAuthorizedAddress);

    }



    ///Initiate Burn by owner

    function initBurn(uint256 _amountToBurn)

        public

        onlyOwner

        notSigned

        contractReady

    {

        require(

            _amountToBurn <= freeSupply,

            "Burn amount greater than free supply"

        );

        _burnGoal = _amountToBurn;

        currState = state.BURN_INITIATED;

        _multiSigCount += 1;

        initTime = block.timestamp;

        users[msg.sender].signed = true; //true

    }



    ///Reset Burn by Owner

    function resetBurn() public onlyOwner burnInitiated {

        require(block.timestamp > initTime + 5 minutes, "Wait for cooldown");

        initTime = 0;

        _multiSigCount = 0;

        currState = state.ONLINE;

        _burnGoal = 0;

        resetAddresses();

    }



    ///Authorized Addresses Confirm Burn

    function confirmBurn(uint256 _amountToBurn)

        public

        onlyAuthorized

        burnInitiated

        notSigned

    {

        require(_amountToBurn == _burnGoal, "Not the right amount");

        require(block.timestamp < initTime + 5 minutes, "Time expired");

        users[msg.sender].signed = true;

        _multiSigCount += 1;

    }



    ///Burn Amount of token

    function burn() public onlyOwner burnInitiated {

        require(_multiSigCount >= 1, "Not enough Signatures");



        ///DO TRANSACTION

        IERC20(addressDenisToken).transfer(burnAddress, _burnGoal);



        currSupply -= _burnGoal;

        freeSupply -= _burnGoal;

        _burnGoal = 0;

        _multiSigCount = 0;

        resetAddresses();

        currState = state.ONLINE;

    }



    ///Reset Signed to False

    function resetAddresses() internal {

        for (uint256 i = 0; i < userAccounts.length; i++) {

            users[userAccounts[i]].signed = false;

        }

    }

}