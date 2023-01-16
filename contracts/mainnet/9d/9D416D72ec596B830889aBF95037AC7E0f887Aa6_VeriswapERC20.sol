/**
 *Submitted for verification at Etherscan.io on 2023-01-16
*/

// File: contracts/tokens/IERC721Receiver.sol





pragma solidity ^0.8.10;



interface IERC721Receiver {



    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);

}
// File: contracts/interfaces/ISignataIdentity.sol



pragma solidity ^0.8.14;



interface ISignataIdentity {

    function getIdentity(address delegateKey) external view returns (address);



    function isLocked(address identity) external view returns (bool);

}


// File: contracts/interfaces/ISignataRight.sol



pragma solidity ^0.8.14;



interface ISignataRight {

    function mintSchema(

        address minter,

        bool schemaTransferable,

        bool schemaRevocable,

        string calldata schemaURI

    ) external returns (uint256);



    function mintRight(

        uint256 schemaId,

        address to,

        bool unbound

    ) external;



    function holdsTokenOfSchema(address holder, uint256 schemaId)

        external

        view

        returns (bool);

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

// File: contracts/ClaimRight.sol



pragma solidity ^0.8.16;








contract ClaimRight is Ownable, IERC721Receiver, ReentrancyGuard {

    string public name;

    IERC20 public paymentToken;

    ISignataRight public signataRight;

    address public signingAuthority;

    uint256 public feeAmount = 100 * 1e18; // 100 SATA

    uint256 public schemaId;

    bytes32 public constant VERSION_DIGEST =

        0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6;

    bytes32 public constant SALT =

        0x03ea6995167b253ad0cf79271b4ddbacfb51c7a4fb2872207de8a19eb0cb724b;

    bytes32 public constant NAME_DIGEST =

        0xfc8e166e81add347414f67a8064c94523802ae76625708af4cddc107b656844f;

    bytes32 public constant EIP712DOMAINTYPE_DIGEST =

        0xd87cd6ef79d4e2b95e15ce8abf732db51ec771f1ca2edccf22a46c729ac56472;

    bytes32 public constant TXTYPE_CLAIM_DIGEST =

        0x8891c73a2637b13c5e7164598239f81256ea5e7b7dcdefd496a0acd25744091c;

    bytes32 public immutable domainSeparator;

    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    bool public collectNative = false;



    mapping(address => bytes32) public claimedRight;

    mapping(address => bool) public cancelledClaim;



    event EmergencyRightClaimed();

    event ModifiedFee(uint256 oldAmount, uint256 newAmount);

    event FeesTaken(uint256 feesAmount);

    event ClaimCancelled(address identity);

    event RightClaimed(address identity);

    event ClaimReset(address identity);

    event CollectNativeModified(bool newValue);

    event TokenModified(address newAddress);

    event PaymentTokenModified(address newToken);



    constructor(

        IERC20 _signataToken,

        ISignataRight _signataRight,

        address _signingAuthority,

        string memory _name

    ) {

        paymentToken = _signataToken;

        signataRight = _signataRight;

        signingAuthority = _signingAuthority;

        name = _name;



        domainSeparator = keccak256(

            abi.encode(

                EIP712DOMAINTYPE_DIGEST,

                NAME_DIGEST,

                VERSION_DIGEST,

                SALT

            )

        );

    }



    receive() external payable {}



    function onERC721Received(

        address operator,

        address from,

        uint256 tokenId,

        bytes calldata data

    ) external pure returns (bytes4) {

        return _ERC721_RECEIVED;

    }



    function mintSchema(string memory _schemaURI) external onlyOwner {

        schemaId = signataRight.mintSchema(

            address(this),

            false,

            true,

            _schemaURI

        );

    }



    function claimRight(

        address delegate,

        uint8 sigV,

        bytes32 sigR,

        bytes32 sigS,

        bytes32 salt

    ) external nonReentrant {

        // take the fee

        if (feeAmount > 0 && !collectNative) {

            paymentToken.transferFrom(msg.sender, address(this), feeAmount);

            emit FeesTaken(feeAmount);

        }

        if (feeAmount > 0 && collectNative) {

            (bool success, ) = payable(address(this)).call{value: feeAmount}(

                ""

            );

            require(success, "ClaimRight: Payment not received.");

        }



        // check if the right is already claimed

        require(!cancelledClaim[delegate], "ClaimRight: Claim cancelled");

        require(claimedRight[delegate] != salt, "ClaimRight: Already claimed");



        claimedRight[delegate] = salt;



        // validate the signature

        bytes32 digest = keccak256(

            abi.encodePacked(

                "\x19\x01",

                domainSeparator,

                keccak256(abi.encode(TXTYPE_CLAIM_DIGEST, delegate, salt))

            )

        );



        address signerAddress = ecrecover(digest, sigV, sigR, sigS);

        require(

            signerAddress == signingAuthority,

            "ClaimRight: Invalid signature"

        );



        // assign the right to the identity

        signataRight.mintRight(schemaId, delegate, false);



        emit RightClaimed(delegate);

    }



    function cancelClaim(address delegate) external onlyOwner {

        require(

            !cancelledClaim[delegate],

            "CancelClaim: Claim already cancelled"

        );



        cancelledClaim[delegate] = true;



        emit ClaimCancelled(delegate);

    }



    function resetClaim(address delegate) external onlyOwner {

        claimedRight[delegate] = 0;

        cancelledClaim[delegate] = false;



        emit ClaimReset(delegate);

    }



    function updateSigningAuthority(address _signingAuthority)

        external

        onlyOwner

    {

        signingAuthority = _signingAuthority;

    }



    function modifyFee(uint256 newAmount) external onlyOwner {

        uint256 oldAmount = feeAmount;

        feeAmount = newAmount;

        emit ModifiedFee(oldAmount, newAmount);

    }



    function modifyCollectNative(bool _collectNative) external onlyOwner {

        require(

            collectNative != _collectNative,

            "ModifyCollectNative: Already set to this value"

        );

        collectNative = _collectNative;

        emit CollectNativeModified(_collectNative);

    }



    function modifyPaymentToken(address newToken) external onlyOwner {

        require(

            address(paymentToken) != newToken,

            "ModifyPaymentToken: Already set to this value"

        );

        paymentToken = IERC20(newToken);

        emit PaymentTokenModified(newToken);

    }



    function withdrawCollectedFees() external onlyOwner {

        paymentToken.transferFrom(

            address(this),

            msg.sender,

            paymentToken.balanceOf(address(this))

        );

    }



    function withdrawNative() external onlyOwner returns (bool) {

        (bool success, ) = payable(msg.sender).call{

            value: address(this).balance

        }("");

        return success;

    }

}


// File: contracts/VeriswapERC20.sol



pragma solidity ^0.8.14;









interface SanctionsList {

    function isSanctioned(address addr) external view returns (bool);

}



contract VeriswapERC20 is Ownable, ReentrancyGuard {

    ISignataIdentity public signataIdentity;

    ISignataRight public signataRight; // rights for checking schema ownership

    ClaimRight public claimRight; // claim rights for checking schema identifier for kyc

    address public sanctionsContract; // sanctions list for checking if user is sanctioned



    enum States {

        INVALID,

        OPEN,

        CLOSED,

        EXPIRED

    }



    struct EscrowSwap {

        address inputToken;

        uint256 inputAmount;

        address outputToken;

        uint256 outputAmount;

        address executor;

        address creator;

        bool requireIdentity;

        bool requireKyc;

        bool requireSanctionCheck;

        States state;

    }



    bool public canSwap = true;



    mapping(address => EscrowSwap) public swaps;



    event SwapCreated(EscrowSwap swapData);

    event SwapExecuted(address creatorAddress);

    event SwapCancelled(address creatorAddress);

    event ExecutorModified(

        address creatorAddress,

        address oldExecutor,

        address newExecutor

    );

    event IdentityContractChanged(ISignataIdentity newIdentity);

    event RightsContractChanged(ISignataRight newRights);

    event ClaimRightContractChanged(ClaimRight newClaimRight);

    event SanctionsListChanged(address newSanctionsList);



    constructor(

        ISignataIdentity _signataIdentity,

        ISignataRight _signataRight,

        ClaimRight _kycClaimRight,

        address _sanctionsContract

    ) {

        signataIdentity = _signataIdentity;

        signataRight = _signataRight;

        claimRight = _kycClaimRight;

        sanctionsContract = _sanctionsContract;

    }



    function createSwap(

        address _inputToken,

        uint256 _inputAmount,

        address _outputToken,

        uint256 _outputAmount,

        address _executor,

        bool _requireIdentity,

        bool _requireKyc,

        bool _requireSanctionCheck

    ) public {

        if (_requireIdentity == true) {

            address senderId = signataIdentity.getIdentity(msg.sender);

            require(

                !signataIdentity.isLocked(senderId),

                "createSwap::Creator must not be locked"

            );

            // don't check the executor yet, just in case they go and register after the fact.

        }

        if (_requireKyc == true) {

            require(

                signataRight.holdsTokenOfSchema(

                    msg.sender,

                    claimRight.schemaId()

                ),

                "createSwap::Creator must have kyc nft"

            );

            // don't check the executor yet, just in case they go and kyc after the fact.

        }



        if (_requireSanctionCheck == true) {

            SanctionsList sanctionsList = SanctionsList(sanctionsContract);

            require(

                !sanctionsList.isSanctioned(msg.sender),

                "createSwap::Creator must not be sanctioned"

            );

            require(

                !sanctionsList.isSanctioned(_executor),

                "createSwap::Executor must not be sanctioned"

            );

        }



        EscrowSwap memory swapToCheck = swaps[msg.sender];

        require(

            swapToCheck.state != States.OPEN,

            "createSwap::already have an open swap"

        );



        IERC20 inputToken = IERC20(_inputToken);



        // check allowance

        require(

            _inputAmount <= inputToken.allowance(msg.sender, address(this)),

            "createSwap::insufficient allowance"

        );



        // transfer into escrow

        require(

            inputToken.transferFrom(msg.sender, address(this), _inputAmount),

            "createSwap::transferFrom failed"

        );



        // store the details

        EscrowSwap memory newSwap = EscrowSwap({

            inputToken: _inputToken,

            inputAmount: _inputAmount,

            outputToken: _outputToken,

            outputAmount: _outputAmount,

            executor: _executor,

            creator: msg.sender,

            requireIdentity: _requireIdentity,

            requireKyc: _requireKyc,

            requireSanctionCheck: _requireSanctionCheck,

            state: States.OPEN

        });

        swaps[msg.sender] = newSwap;



        emit SwapCreated(newSwap);

    }



    function executeSwap(address creatorAddress) external nonReentrant {

        require(canSwap, "executeSwap::swaps not enabled!");



        // check the state

        EscrowSwap memory swapToExecute = swaps[creatorAddress];



        require(

            swapToExecute.state == States.OPEN,

            "executeSwap::not an open swap"

        );

        require(

            swapToExecute.executor == msg.sender,

            "executeSwap::only the executor can call this function"

        );

        // check identities

        if (swapToExecute.requireIdentity == true) {

            // msg.sender will be the delegate key

            address senderId = signataIdentity.getIdentity(msg.sender);

            require(

                !signataIdentity.isLocked(senderId),

                "executeSwap::Sender must not be locked"

            );

            // and the executor will also be their delegate key

            address executorId = signataIdentity.getIdentity(swapToExecute.executor);

            require(

                !signataIdentity.isLocked(executorId),

                "executeSwap::Executor must not be locked"

            );

        }



        if (swapToExecute.requireKyc == true) {

            // holds token takes the delegate key and looks up identity

            require(

                signataRight.holdsTokenOfSchema(

                    msg.sender,

                    claimRight.schemaId()

                ),

                "executeSwap::Sender must have kyc nft"

            );

            require(

                signataRight.holdsTokenOfSchema(

                    swapToExecute.executor,

                    claimRight.schemaId()

                ),

                "executeSwap::Executor must have kyc nft"

            );

        }



        if (swapToExecute.requireSanctionCheck == true) {

            SanctionsList sanctionsList = SanctionsList(sanctionsContract);

            require(

                !sanctionsList.isSanctioned(msg.sender),

                "executeSwap::Sender must not be sanctioned"

            );

            require(

                !sanctionsList.isSanctioned(swapToExecute.executor),

                "executeSwap::Executor must not be sanctioned"

            );

        }



        IERC20 outputToken = IERC20(swapToExecute.outputToken);

        IERC20 inputToken = IERC20(swapToExecute.inputToken);



        swaps[swapToExecute.creator].state = States.CLOSED;



        // check allowance

        require(

            swapToExecute.outputAmount <=

                outputToken.allowance(msg.sender, address(this))

        );

        // send the input to the executor

        require(

            inputToken.transfer(

                swapToExecute.executor,

                swapToExecute.inputAmount

            )

        );

        // send the output to the creator

        require(

            outputToken.transferFrom(

                msg.sender,

                swapToExecute.creator,

                swapToExecute.outputAmount

            )

        );



        // send the parties their respective tokens

        emit SwapExecuted(creatorAddress);

    }



    function cancelSwap() external nonReentrant {

        EscrowSwap memory swapToCancel = swaps[msg.sender];

        require(

            swapToCancel.creator == msg.sender,

            "cancelSwap::not the creator"

        );

        require(

            swapToCancel.state == States.OPEN,

            "cancelSwap::not an open swap"

        );



        swaps[msg.sender].state = States.EXPIRED;



        // return the input back to the creator

        IERC20 inputToken = IERC20(swapToCancel.inputToken);

        require(

            inputToken.transfer(swapToCancel.creator, swapToCancel.inputAmount)

        );



        emit SwapCancelled(swapToCancel.creator);

    }



    function changeExecutor(address newExecutor) external {

        require(

            newExecutor != address(0),

            "changeExecutor::cannot set to 0 address"

        );

        EscrowSwap memory swapToChange = swaps[msg.sender];



        address oldExecutor = swaps[msg.sender].executor;



        require(

            newExecutor != oldExecutor,

            "changeExecutor::not different values"

        );

        require(

            swapToChange.creator == msg.sender,

            "changeExecutor::not the creator"

        );

        require(

            swapToChange.state == States.OPEN,

            "changeExecutor::not an open swap"

        );



        swaps[msg.sender].executor = newExecutor;



        emit ExecutorModified(msg.sender, oldExecutor, newExecutor);

    }



    function enableSwaps() external onlyOwner {

        canSwap = true;

    }



    function disableSwaps() external onlyOwner {

        canSwap = false;

    }



    function updateSignataIdentity(ISignataIdentity newIdentity)

        external

        onlyOwner

    {

        require(

            address(newIdentity) != address(signataIdentity),

            "updateSignataIdentity::not different values"

        );

        signataIdentity = newIdentity;

        emit IdentityContractChanged(newIdentity);

    }



    function updateSignataRight(ISignataRight newRights) external onlyOwner {

        require(

            address(newRights) != address(signataRight),

            "updateSignataRight::not different values"

        );

        signataRight = newRights;

        emit RightsContractChanged(newRights);

    }



    function updateSanctionsList(address newSanctionsContract)

        external

        onlyOwner

    {

        require(

            newSanctionsContract != address(sanctionsContract),

            "updateSanctionsList::not different values"

        );

        sanctionsContract = newSanctionsContract;

        emit SanctionsListChanged(newSanctionsContract);

    }



    function updateClaimRight(ClaimRight newClaimRight) external onlyOwner {

        require(

            address(newClaimRight) != address(claimRight),

            "updateClaimRight::not different values"

        );

        claimRight = newClaimRight;

        emit ClaimRightContractChanged(newClaimRight);

    }

}