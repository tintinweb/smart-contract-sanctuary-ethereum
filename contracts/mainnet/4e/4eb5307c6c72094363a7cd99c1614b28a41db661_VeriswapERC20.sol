/**
 *Submitted for verification at Etherscan.io on 2022-07-27
*/

// File: contracts/SignataIdentity.sol





pragma solidity ^0.8.11;



contract SignataIdentity {

    uint256 private constant MAX_UINT256 = type(uint256).max;

    

    // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)")

    bytes32 private constant EIP712DOMAINTYPE_DIGEST = 0xd87cd6ef79d4e2b95e15ce8abf732db51ec771f1ca2edccf22a46c729ac56472;

    

    // keccak256("Signata")

    bytes32 private constant NAME_DIGEST = 0xfc8e166e81add347414f67a8064c94523802ae76625708af4cddc107b656844f;

    

    // keccak256("1")

    bytes32 private constant VERSION_DIGEST = 0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6;

    

    bytes32 private constant SALT = 0x233cdb81615d25013bb0519fbe69c16ddc77f9fa6a9395bd2aecfdfc1c0896e3;

    

    // keccak256("SignataIdentityCreateTransaction(address delegateKey, address securityKey)")

    bytes32 private constant TXTYPE_CREATE_DIGEST = 0x469a26f6afcc5806677c064ceb4b952f409123d7e70ab1fd0a51e86205b9937b;   

    

    // keccak256("SignataIdentityRolloverTransaction(address identity, address newDelegateKey, address newSecurityKey, uint256 rolloverCount)")

    bytes32 private constant TXTYPE_ROLLOVER_DIGEST = 0x3925a5eeb744076e798ef9df4a1d3e1d70bcca2f478f6df9e6f0496d7de53e1e;

    

    // keccak256("SignataIdentityUnlockTransaction(uint256 lockCount)")

    bytes32 private constant TXTYPE_UNLOCK_DIGEST = 0xd814812ff462bae7ba452aadd08061fe1b4bda9916c0c4a84c25a78985670a7b;

    

    // keccak256("SignataIdentityDestroyTransaction()");

    bytes32 private constant TXTYPE_DESTROY_DIGEST = 0x21459c8977584463672e32d031e5caf426140890a0f0d2172da41491b70ef9f5;

    

    bytes32 private immutable _domainSeperator;

    

    // storage

    mapping(address => address) private _delegateKeyToIdentity;

    mapping(address => uint256) private _identityLockCount;

    mapping(address => uint256) private _identityRolloverCount;

    mapping(address => address) private _identityToSecurityKey;

    mapping(address => address) private _identityToDelegateKey;

    mapping(address => bool) private _identityDestroyed;

    mapping(address => bool) private _identityExists;

    mapping(address => bool) private _identityLocked;

    

    constructor(uint256 chainId) {

        _domainSeperator = keccak256(

            abi.encode(

                EIP712DOMAINTYPE_DIGEST,

                NAME_DIGEST,

                VERSION_DIGEST,

                chainId,

                this,

                SALT

            )

        );

    }

    

    event Create(address indexed identity, address indexed delegateKey, address indexed securityKey);

    event Destroy(address indexed identity);

    event Lock(address indexed identity);

    event Rollover(address indexed identity, address indexed delegateKey, address indexed securityKey);

    event Unlock(address indexed identity);

    

    function create(

        uint8 identityV, 

        bytes32 identityR, 

        bytes32 identityS, 

        address delegateKey, 

        address securityKey

    ) external {

        require(

            _delegateKeyToIdentity[delegateKey] == address(0),

            "SignataIdentity: Delegate key must not already be in use."

        );

        

        bytes32 digest = keccak256(

            abi.encodePacked(

                "\x19\x01",

                _domainSeperator,

                keccak256(

                    abi.encode(

                        TXTYPE_CREATE_DIGEST,

                        delegateKey,

                        securityKey

                    )

                )

            )

        );

        

        address identity = ecrecover(digest, identityV, identityR, identityS);

        

        require(

            msg.sender == identity,

            "SignataIdentity: The identity to be created must match the address of the sender."

        );

        

        require(

            identity != delegateKey && identity != securityKey && delegateKey != securityKey,

            "SignataIdentity: Keys must be unique."

        );

        

        require(

            !_identityExists[identity],

            "SignataIdentity: The identity must not already exist."

        );

        

        _delegateKeyToIdentity[delegateKey] = identity;

        _identityToDelegateKey[identity] = delegateKey;

        _identityExists[identity] = true;

        _identityToSecurityKey[identity] = securityKey;

        

        emit Create(identity, delegateKey, securityKey);

    }

    

    function destroy(

        address identity,

        uint8 delegateV,

        bytes32 delegateR, 

        bytes32 delegateS,

        uint8 securityV,

        bytes32 securityR, 

        bytes32 securityS

    ) external {

        require(

            _identityExists[identity],

            "SignataIdentity: The identity must exist."

        );

        

        require(

            !_identityDestroyed[identity],

            "SignataIdentity: The identity has already been destroyed."

        );

        

        bytes32 digest = keccak256(

            abi.encodePacked(

                "\x19\x01",

                _domainSeperator,

                keccak256(abi.encode(TXTYPE_DESTROY_DIGEST))

            )

        );

        

        address delegateKey = ecrecover(digest, delegateV, delegateR, delegateS);

        

        require(

            _identityToDelegateKey[identity] == delegateKey,

            "SignataIdentity: Invalid delegate key signature provided."

        );

        

        address securityKey = ecrecover(digest, securityV, securityR, securityS);

        

        require(

            _identityToSecurityKey[identity] == securityKey,

            "SignataIdentity: Invalid security key signature provided."

        );

        

        _identityDestroyed[identity] = true;

        

        delete _delegateKeyToIdentity[delegateKey];

        delete _identityLockCount[identity];

        delete _identityRolloverCount[identity];

        delete _identityToSecurityKey[identity];

        delete _identityToDelegateKey[identity];

        delete _identityLocked[identity];

        

        emit Destroy(identity);

    }

    

    function lock(address identity) external {

        require(

            _identityExists[identity],

            "SignataIdentity: The identity must exist."

        );

        

        require(

            !_identityDestroyed[identity],

            "SignataIdentity: The identity has been destroyed."

        );

        

        require(

            !_identityLocked[identity],

            "SignataIdentity: The identity has already been locked."

        );

        

        require(

            msg.sender == _identityToDelegateKey[identity] || msg.sender == _identityToSecurityKey[identity],

            "SignataIdentity: The sender is unauthorised to lock identity."

        );

        

        _identityLocked[identity] = true;

        _identityLockCount[identity] += 1;

        

        emit Lock(identity);

    }

    

    function getDelegate(address identity)

        external

        view

        returns (address)

    {

        require(

            _identityExists[identity],

            "SignataIdentity: The identity must exist."

        );

        

        require(

            !_identityDestroyed[identity],

            "SignataIdentity: The identity has been destroyed."

        );

        

        return _identityToDelegateKey[identity];

    }

    

    function getIdentity(address delegateKey) 

        external

        view 

        returns (address) 

    {

        address identity = _delegateKeyToIdentity[delegateKey];

        

        require(

            identity != address(0),

            "SignataIdentity: The delegate key provided is not linked to an existing identity."

        );

        

        return identity;

    }



    function getLockCount(address identity)

        external

        view

        returns (uint256) 

    {

         require(

            _identityExists[identity],

            "SignataIdentity: The identity must exist."

        );

        

        require(

            !_identityDestroyed[identity],

            "SignataIdentity: The identity has been destroyed."

        );

        

        return _identityLockCount[identity];

    }    

    

    function getRolloverCount(address identity)

        external

        view

        returns (uint256) 

    {

        require(

            _identityExists[identity],

            "SignataIdentity: The identity must exist."

        );

        

        require(

            !_identityDestroyed[identity],

            "SignataIdentity: The identity has been destroyed."

        );

        

        return _identityRolloverCount[identity];

    }

    

    function isLocked(address identity)

        external

        view

        returns (bool) 

    {

        require(

            _identityExists[identity],

            "SignataIdentity: The identity must exist."

        );

        

        require(

            !_identityDestroyed[identity],

            "SignataIdentity: The identity has been destroyed."

        );

        

        return _identityLocked[identity];

    }

    

    function rollover(

        address identity,

        uint8 delegateV, 

        bytes32 delegateR, 

        bytes32 delegateS, 

        uint8 securityV, 

        bytes32 securityR, 

        bytes32 securityS,

        address newDelegateKey, 

        address newSecurityKey

    ) 

        external 

    {

        require(

            _identityExists[identity],

            "SignataIdentity: The identity must exist."

        );

        

        require(

            !_identityDestroyed[identity],

            "SignataIdentity: The identity has been destroyed."

        );

        

        require(

            identity != newDelegateKey && identity != newSecurityKey && newDelegateKey != newSecurityKey,

            "SignataIdentity: The keys must be unique."

        );

        

        require(

            _delegateKeyToIdentity[newDelegateKey] == address(0),

            "SignataIdentity: The new delegate key must not already be in use."

        );

        

        require(

            msg.sender == _identityToDelegateKey[identity] || msg.sender == _identityToSecurityKey[identity],

            "SignataIdentity: The sender is unauthorised to rollover the identity."

        );

        

        require(

            _identityRolloverCount[identity] != MAX_UINT256,

            "SignataIdentity: The identity has already reached the maximum number of rollovers allowed."

        );

        

        bytes32 digest = keccak256(

            abi.encodePacked(

                "\x19\x01",

                _domainSeperator,

                keccak256(

                    abi.encode(

                        TXTYPE_ROLLOVER_DIGEST,

                        newDelegateKey,

                        newSecurityKey,

                        _identityRolloverCount[identity]

                    )

                )

            )

        );

        

        address delegateKey = ecrecover(digest, delegateV, delegateR, delegateS);

        

        require(

            _identityToDelegateKey[identity] == delegateKey,

            "SignataIdentity: Invalid delegate key signature provided."

        );

        

        address securityKey = ecrecover(digest, securityV, securityR, securityS);

        

        require(

            _identityToSecurityKey[identity] == securityKey,

            "SignataIdentity: Invalid delegate key signature provided."

        );

        

        delete _delegateKeyToIdentity[delegateKey];

        

        _delegateKeyToIdentity[newDelegateKey] = identity;

        _identityToDelegateKey[identity] = newDelegateKey;

        _identityToSecurityKey[identity] = newSecurityKey;

        _identityRolloverCount[identity] += 1;

        

        emit Rollover(identity, newDelegateKey, newSecurityKey);

    }

    

    function unlock(

        address identity,

        uint8 delegateV, 

        bytes32 delegateR, 

        bytes32 delegateS, 

        uint8 securityV, 

        bytes32 securityR, 

        bytes32 securityS

    ) 

        external 

    {

        require(

            _identityExists[identity],

            "SignataIdentity: The identity must exist."

        );

        

        require(

            !_identityDestroyed[identity],

            "SignataIdentity: The identity has been destroyed."

        );

        

        require(

            _identityLocked[identity],

            "SignataIdentity: The identity is already unlocked."

        );

        

        require(

            _identityLockCount[identity] != MAX_UINT256,

            "SignataIdentity: The identity is permanently locked."

        );

        

        require(

            msg.sender == _identityToDelegateKey[identity] || msg.sender == _identityToSecurityKey[identity],

            "SignataIdentity: The sender is unauthorised to unlock the identity."

        );

        

        bytes32 digest = keccak256(

            abi.encodePacked(

                "\x19\x01",

                _domainSeperator,

                keccak256(

                    abi.encode(

                        TXTYPE_UNLOCK_DIGEST,

                        _identityLockCount[identity]

                    )

                )

            )

        );

        

        address delegateKey = ecrecover(digest, delegateV, delegateR, delegateS);

        

        require(

            _identityToDelegateKey[identity] == delegateKey,

            "SignataIdentity: Invalid delegate key signature provided."

        );

        

        address securityKey = ecrecover(digest, securityV, securityR, securityS);

        

        require(

            _identityToSecurityKey[identity] == securityKey,

            "SignataIdentity: Invalid security key signature provided."

        );

        

        _identityLocked[identity] = false;

        

        emit Unlock(identity);

    }

}
// File: contracts/openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: contracts/openzeppelin/contracts/utils/Context.sol


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

// File: contracts/openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: contracts/openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: contracts/VeriswapERC20.sol



pragma solidity ^0.8.14;







contract VeriswapERC20 is Ownable, ReentrancyGuard {

    SignataIdentity public signataIdentity;



    enum States {

        INVALID,

        OPEN,

        CLOSED,

        EXPIRED

    }



    struct AtomicSwap {

      address inputToken;

      uint256 inputAmount;

      address outputToken;

      uint256 outputAmount;

      address executor;

      address creator;

      bool requireIdentity;

      States state;

    }



    bool public canSwap = true;



    mapping (address => AtomicSwap) public swaps;



    event SwapCreated(AtomicSwap swapData);

    event SwapExecuted(address creatorAddress);

    event SwapCancelled(address creatorAddress);

    event ExecutorModified(address creatorAddress, address oldExecutor, address newExecutor);

    event IdentityContractChanged(SignataIdentity newIdentity);



    constructor(SignataIdentity _signataIdentity) {

        signataIdentity = _signataIdentity;

    }



    function createSwap(

      address _inputToken,

      uint256 _inputAmount,

      address _outputToken,

      uint256 _outputAmount,

      address _executor,

      bool _requireIdentity

    ) public {

        if (_requireIdentity) {

            require(!signataIdentity.isLocked(msg.sender), "createSwap::creator must not be locked.");

            // don't check the executor yet, just in case they go and register after the fact.

        }

        AtomicSwap memory swapToCheck = swaps[msg.sender];

        require(swapToCheck.state != States.OPEN, "createSwap::already have an open swap.");



        IERC20 inputToken = IERC20(_inputToken);



        // check allowance

        require(_inputAmount <= inputToken.allowance(msg.sender, address(this)), "createSwap::insufficient allowance");



        // transfer into escrow

        require(inputToken.transferFrom(msg.sender, address(this), _inputAmount), "createSwap::transferFrom failed");



        // store the details

        AtomicSwap memory newSwap = AtomicSwap({

          inputToken: _inputToken,

          inputAmount: _inputAmount,

          outputToken: _outputToken,

          outputAmount: _outputAmount,

          executor: _executor,

          creator: msg.sender,

          requireIdentity: _requireIdentity,

          state: States.OPEN

        });

        swaps[msg.sender] = newSwap;



        emit SwapCreated(newSwap);

    }



    function executeSwap(address creatorAddress) nonReentrant external {

      require(canSwap, "executeSwap::swaps not enabled!");



      // check the state

      AtomicSwap memory swapToExecute = swaps[creatorAddress];



      require(swapToExecute.state == States.OPEN, "executeSwap::not an open swap.");

      require(swapToExecute.executor == msg.sender, "executeSwap::only the executor can call this function.");



      // check identities

      if (swapToExecute.requireIdentity == true) {

        require(!signataIdentity.isLocked(msg.sender), "executeSwap::Sender must not be locked.");

        require(!signataIdentity.isLocked(swapToExecute.executor), "executeSwap::Trader must not be locked.");

      }



      IERC20 outputToken = IERC20(swapToExecute.outputToken);

      IERC20 inputToken = IERC20(swapToExecute.inputToken);



      swaps[swapToExecute.creator].state = States.CLOSED;



      // check allowance

      require(swapToExecute.outputAmount <= outputToken.allowance(msg.sender, address(this)));

      // send the input to the executor

      require(inputToken.transfer(swapToExecute.executor, swapToExecute.inputAmount));

      // send the output to the creator

      require(outputToken.transferFrom(msg.sender, swapToExecute.creator, swapToExecute.outputAmount));



      // send the parties their respective tokens

      emit SwapExecuted(creatorAddress);

    }



    function cancelSwap() nonReentrant external {

      AtomicSwap memory swapToCancel = swaps[msg.sender];

      require(swapToCancel.creator == msg.sender, "cancelSwap::not the creator.");

      require(swapToCancel.state == States.OPEN, "cancelSwap::not an open swap.");



      swaps[msg.sender].state = States.EXPIRED;



      // return the input back to the creator

      IERC20 inputToken = IERC20(swapToCancel.inputToken);

      require(inputToken.transfer(swapToCancel.creator, swapToCancel.inputAmount));



      emit SwapCancelled(swapToCancel.creator);

    }



    function changeExecutor(address newExecutor) external {

      require(newExecutor != address(0), "changeExecutor::cannot set to 0 address!");

      AtomicSwap memory swapToChange = swaps[msg.sender];



      address oldExecutor = swaps[msg.sender].executor;



      require(newExecutor != oldExecutor, "changeExecutor::not different values!");

      require(swapToChange.creator == msg.sender, "changeExecutor::not the creator!");

      require(swapToChange.state == States.OPEN, "changeExecutor::not an open swap!");



      swaps[msg.sender].executor = newExecutor;



      emit ExecutorModified(msg.sender, oldExecutor, newExecutor);

    }



    function enableSwaps() external onlyOwner { canSwap = true; }

    function disableSwaps() external onlyOwner { canSwap = false; }

    

    function updateSignataIdentity(SignataIdentity newIdentity) external onlyOwner {

        signataIdentity = newIdentity;

        emit IdentityContractChanged(newIdentity);

    }

}