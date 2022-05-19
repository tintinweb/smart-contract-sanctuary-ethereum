/**
 *Submitted for verification at Etherscan.io on 2022-05-19
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/// @title Recurring Payments & Subscriptions on Ethereum
/// @author Jonathan Becker <[email protected]>
/// @notice This is an implementation of recurring payments & subscriptions
///                 on ethereum which utilizes an application of ERC20's approval
///                 as well as a timelocked proxy of ERC20's transferFrom() to safely
///                 handle recurring payments that can be cancelled any time
/// @dev Unlimited approval is not required. We only require an approval of
///            > ( subscriptionCost * 2 ) ERC20 tokens
/// @custom:experimental This is an experimental contract, and is still a PoC
/// https://jbecker.dev/research/ethereum-recurring-payments/

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

contract IERC20 {
    function approve(address spender, uint256 value) public virtual returns (bool) {}
    function transfer(address to, uint256 value) public virtual returns (bool) {}
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {}
    function name() public view virtual returns (string memory) {}
    function symbol() public view virtual returns (string memory) {}
    function decimals() public view virtual returns (uint256) {}
    function totalSupply() public view virtual returns (uint256) {}
    function balanceOf(address account) public view virtual returns (uint256) {}
    function allowance(address owner, address spender) public view virtual returns (uint256) {}
}

contract Subtesting is Ownable {

    address public tokenAddress = 0x3B00Ef435fA4FcFF5C209a37d1f3dcff37c705aD; // USDT Rinkeby Address

    event NewSubscription(
        address Customer,
        address Payee,
        uint256 Allowance,
        // address TokenAddress,
        string Name,
        string Description,
        uint256 LastExecutionDate,
        uint256 SubscriptionPeriod
    );
    event SubscriptionCancelled(
        address Customer,
        address Payee
    );
    event SubscriptionPaid(
        address Customer,
        address Payee,
        uint256 PaymentDate,
        uint256 PaymentAmount,
        uint256 NextPaymentDate
    );

    /// @dev Correct mapping is _customer, then _payee. Holds information about
    ///            an addresses subscriptions using the Subscription struct
    mapping(address => mapping(address => Subscription)) public subscriptions;

    /// @dev Mapping that holds an list of subscriptions for _customer
    mapping(address => SubscriptionReceipt[]) public receipts;

    /// @notice This is the subscription struct which holds all information on a
    ///                 subscription
    /// @dev        TokenAddress must be a conforming ERC20 contract that supports the
    ///                 IERC20
    /// @param Customer                     : The customer's address 
    /// @param Payee                            : The payee's address 
    /// @param Allowance                    : Total cost of ERC20 tokens per SubscriptionPeriod
    /// @param TokenAddress             : A conforming ERC20 token contract address
    /// @param Name                             : Name of the subscription
    /// @param Description                : A short description of the subscription
    /// @param LastExecutionDate    : The last time this subscription was paid (UNIX)
    /// @param SubscriptionPeriod : UNIX time for subscription period. For example
    ///                                                         86400 would be 1 day, which means this Subscription
    ///                                                         would be charged every day
    /// @param IsActive                     : A boolean that marks if this subscription is active 
    ///                                                         or has been cancelled
    struct Subscription {
        address Customer;
        address Payee;
        uint256 Allowance;
        // address TokenAddress;
        string Name;
        string Description;
        uint256 LastExecutionDate;
        uint256 SubscriptionPeriod;
        bool IsActive;
        bool Exists;
    }

    /// @notice This is the enum we use for storing a users role within a
    ///                 SubscriptionReceipt
    enum role {
        CUSTOMER,
        PAYEE
    }

    /// @notice This is a receipt for subscriptions. It will never be changed once pushed
    ///                 to subscriptionReceipts 
    /// @dev        TokenAddress must be a conforming ERC20 contract that supports the
    ///                 IERC20
    /// @param Customer                     : The customer's address 
    /// @param Payee                            : The payee's address 
    /// @param Allowance                    : Total cost of ERC20 tokens per SubscriptionPeriod
    /// @param TokenAddress             : A conforming ERC20 token contract address
    /// @param Name                             : Name of the subscription
    /// @param Description                : A short description of the subscription
    /// @param CreationDate             : The last time this subscription was first created
    /// @param Role                             : Role enum for reciept. Shows if user is customer or payee
    struct SubscriptionReceipt {
        address Customer;
        address Payee;
        uint256 Allowance;
        // address TokenAddress;
        string Name;
        string Description;
        uint256 CreationDate;
        role Role;
    }

    constructor() {
    }

    function setSubscriptionToken(address _token) public onlyOwner {
        tokenAddress = _token;
    }

    /// @notice Returns the subscription of _customer and _payee
    /// @dev        Will return regardless if found or not. Use getSubscription(_customer, _payee)
    ///                 Exists to test if the subscription really exists
    /// @param _customer : The customer's address 
    /// @param _payee        : The payee's address
    /// @return Subscription from mapping subscriptions
    function getSubscription(address _customer, address _payee) public view returns(Subscription memory){
        return subscriptions[_customer][_payee];
    }

    /// @notice Returns a list of subscriptions that are owned by _customer
    /// @param _customer : The customer's address 
    /// @return List of subscriptions that the _customer owns
    function getSubscriptionReceipts(address _customer) public view returns(SubscriptionReceipt[] memory){
        return receipts[_customer];
    }

    /// @notice Returns time in seconds remaining before this subscription may be executed
    /// @dev        A return of 0 means the subscripion is ready to be executed
    /// @param _customer : The customer's address 
    /// @param _payee        : The payee's address
    /// @return Time in seconds until this subscription comes due
    function subscriptionTimeRemaining(address _customer, address _payee) public view returns(uint256){
        uint256 remaining = getSubscription(_customer, _payee).LastExecutionDate+getSubscription(_customer, _payee).SubscriptionPeriod;
        if(block.timestamp > remaining){
            return 0;
        }
        else {
            return remaining - block.timestamp;
        }
    }

    /// @notice Creates a new subscription. Must be called by the customer. This will automatically
    ///                 create the first subscription charge of _subscriptionCost tokens
    /// @dev        Emits an ERC20 {Transfer} event, as well as {NewSubscription} and {SubscriptionPaid}
    ///                 Requires at least an ERC20 allowance to this contract of (_subscriptionCost * 2) tokens
    /// @param _payee                            : The payee's address
    /// @param _subscriptionCost     : The cost in ERC20 tokens that will be charged every _subscriptionPeriod
    ///// @param _token                            : The ERC20 compliant token address
    /// @param _name                             : Name of the subscription
    /// @param _description                : A short description of the subscription
    /// @param _subscriptionPeriod : UNIX time for subscription period. For example
    ///                                                            86400 would be 1 day, which means this Subscription
    ///                                                            would be charged every day
    function createSubscription(
        address _payee,
        uint256 _subscriptionCost, 
        // address _token, 
        string memory _name, 
        string memory _description, 
        uint256 _subscriptionPeriod ) public virtual {
        IERC20 tokenInterface;
        // tokenInterface = IERC20(_token);
        tokenInterface = IERC20(tokenAddress);

        require(getSubscription(msg.sender, _payee).IsActive != true, "0xSUB: Active subscription already exists.");
        require(_subscriptionCost <= tokenInterface.balanceOf(msg.sender), "0xSUB: Insufficient token balance.");
        require(_subscriptionPeriod > 0, "0xSUB: Subscription period must be greater than 0.");

        subscriptions[msg.sender][_payee] = Subscription(
            msg.sender,
            _payee,
            _subscriptionCost,
            // _token,
            _name,
            _description,
            block.timestamp,
            _subscriptionPeriod,
            true,
            true
        );
        receipts[msg.sender].push(SubscriptionReceipt(
            msg.sender,
            _payee,
            _subscriptionCost,
            // _token,
            _name,
            _description,
            block.timestamp,
            role.CUSTOMER
        ));
        receipts[_payee].push(SubscriptionReceipt(
            msg.sender,
            _payee,
            _subscriptionCost,
            // _token,
            _name,
            _description,
            block.timestamp,
            role.PAYEE
        ));
        require((tokenInterface.allowance(msg.sender, address(this)) >= (_subscriptionCost * 2)) && (tokenInterface.allowance(msg.sender, address(this)) <= 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff), "0xSUB: Allowance of (_subscriptionCost * 2) required.");
        require(tokenInterface.transferFrom(msg.sender, _payee, _subscriptionCost), "0xSUB: Initial subscription payment failed.");

        // emit NewSubscription(msg.sender, _payee, _subscriptionCost, _token, _name, _description, block.timestamp, _subscriptionPeriod);
        emit NewSubscription(msg.sender, _payee, _subscriptionCost, _name, _description, block.timestamp, _subscriptionPeriod);
        emit SubscriptionPaid(msg.sender, _payee, block.timestamp, _subscriptionCost, block.timestamp+_subscriptionPeriod);
    }
    
    /// @notice Cancells a subscription. May be called by either customer or payee
    /// @dev        Emits a {SubscriptionCancelled} event, and disallows execution of future
    ///                 subscription charges
    /// @param _customer : The customer's address 
    /// @param _payee        : The payee's address
    function cancelSubscription(
        address _customer,
        address _payee ) public virtual {
        require((getSubscription(_customer, _payee).Customer == msg.sender || getSubscription(_customer, _payee).Payee == msg.sender), "0xSUB: Only subscription parties can cancel a subscription.");
        require(getSubscription(_customer, _payee).IsActive == true, "0xSUB: Subscription already inactive.");

        subscriptions[_customer][_payee].IsActive = false;

        emit SubscriptionCancelled(_customer, _payee);
    }

    /// @notice Executes a subscription payment. Must be called by the _payee
    /// @dev Emits a {SubscriptionPaid} event. Requires SubscriptionPeriod to have a passed since LastExecutionDate,
    ///                 as well as an ERC20 transferFrom to succeed
    /// @param _customer : The customer's address 
    function executePayment(
        address _customer
    ) public virtual {
        require(getSubscription(_customer, msg.sender).Payee == msg.sender, "0xSUB: Only subscription payees may execute a subscription payment.");
        require(getSubscription(_customer, msg.sender).IsActive == true, "0xSUB: Subscription already inactive.");
        require(_subscriptionPaid(_customer, msg.sender) != true, "0xSUB: Subscription already paid for this period.");

        IERC20 tokenInterface;
        // tokenInterface = IERC20(getSubscription(_customer, msg.sender).TokenAddress);
        tokenInterface = IERC20(tokenAddress);

        subscriptions[_customer][msg.sender].LastExecutionDate = block.timestamp;
        require(tokenInterface.transferFrom(_customer, msg.sender, getSubscription(_customer, msg.sender).Allowance), "0xSUB: Subscription payment failed.");

        emit SubscriptionPaid(_customer, msg.sender, block.timestamp, getSubscription(_customer, msg.sender).Allowance, block.timestamp+getSubscription(_customer, msg.sender).SubscriptionPeriod);
    }

    /// @notice Determines wether or not this subscription has been paid this period
    /// @param _customer : The customer's address 
    /// @param _payee        : The payee's address
    /// @return Returns a boolean true if the subscription has been charged for this period, false if otherwise
    function _subscriptionPaid(address _customer, address _payee) internal view returns(bool){
        uint256 remaining = getSubscription(_customer, _payee).LastExecutionDate+getSubscription(_customer, _payee).SubscriptionPeriod;
        if(block.timestamp > remaining){
            return false;
        }
        else {
            return true;
        }
    }
}