/**
 *Submitted for verification at Etherscan.io on 2022-11-20
*/

/** 
 *  SourceUnit: /Users/kuldeep/ETHEREUM/interviews/Biconomy/contracts/TimeLockedWallet.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
}




/** 
 *  SourceUnit: /Users/kuldeep/ETHEREUM/interviews/Biconomy/contracts/TimeLockedWallet.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
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
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
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
 *  SourceUnit: /Users/kuldeep/ETHEREUM/interviews/Biconomy/contracts/TimeLockedWallet.sol
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity >=0.8.15;

////import "./interfaces/IERC20.sol";
////import "./lib/ReentrancyGuard.sol";

contract TimeLockedWallet is ReentrancyGuard {
    bytes public constant EIP712_NAME = bytes("TimeLockedWallet");
    bytes public constant EIP712_REVISION = bytes("1");
    bytes32 internal constant EIP712_DOMAIN =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
    bytes32 public constant CLAIM_TYPEHASH =
        keccak256("Claim(address token,uint256 amount,uint256 nonce)");
    bytes32 public DOMAIN_SEPARATOR;

    address public constant ETHER = address(0);
    struct LockedToken {
        uint256 amount;
        uint256 depositTimestamp;
        uint256 lockPeriod;
    }
    mapping(address => mapping(address => LockedToken)) lockedTokens;
    mapping(address => uint256) private nonces;

    constructor() {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                EIP712_DOMAIN,
                keccak256(EIP712_NAME),
                keccak256(EIP712_REVISION),
                block.chainid,
                address(this)
            )
        );
    }

    event Deposit(
        address indexed sender,
        address indexed receiver,
        address indexed token,
        uint256 amount
    );

    event Claim(
        address indexed receiver,
        address indexed token,
        uint256 amount
    );

    // deposit
    function deposit(
        address receiver,
        address token,
        uint256 amount,
        uint256 lockPeriod
    ) external payable nonReentrant {
        require(receiver != address(0), "TimeLockedWallet: invalid address");
        require(amount != 0, "TimeLockedWallet: invalid amount");
        require(lockPeriod > 0, "TimeLockedWallet: invalid lock period");

        LockedToken storage lockedToken = lockedTokens[receiver][token];

        if (token == address(ETHER)) {
            require(
                msg.value >= amount,
                "TimeLockedWallet: not sufficient ETH"
            );
            // in case depositor send more ETH, we need to transfer it back
            if (msg.value > amount) {
                (bool success, ) = msg.sender.call{value: msg.value - amount}(
                    ""
                );
                require(success, "TimeLockedWallet: transfer failed");
            }
        } else {
            IERC20(token).transferFrom(msg.sender, address(this), amount);
        }
        lockedToken.amount += amount;
        lockedToken.depositTimestamp = block.timestamp;
        lockedToken.lockPeriod = lockPeriod;

        emit Deposit(msg.sender, receiver, token, amount);
    }

    // claim
    function claim(
        address receiver,
        address token,
        uint256 amount,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) external nonReentrant {
        require(
            verify(receiver, token, amount, r, s, v),
            "TimeLockedWallet: invalid signature"
        );
        nonces[receiver]++;

        LockedToken storage lockedToken = lockedTokens[receiver][token];
        require(
            lockedToken.amount >= amount,
            "TimeLockedWallet: not enough balance"
        );
        require(
            block.timestamp >=
                lockedToken.depositTimestamp + lockedToken.lockPeriod,
            "TimeLockedWallet: tokens locked"
        );

        lockedToken.amount -= amount;
        if (token == address(ETHER)) {
            require(
                address(this).balance >= amount,
                "TimeLockedWallet: Not enough ETH"
            );
            (bool success, ) = receiver.call{value: amount}("");
            require(success, "TimeLockedWallet: transfer failed");
        } else {
            require(
                IERC20(token).balanceOf(address(this)) >= amount,
                "TimeLockedWallet: Not enough tokens"
            );
            IERC20(token).transfer(receiver, amount);
        }

        emit Claim(receiver, token, amount);
    }

    function verify(
        address receiver,
        address token,
        uint256 amount,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) internal view returns (bool) {
        bytes32 structHash = keccak256(
            abi.encode(CLAIM_TYPEHASH, token, amount, nonces[receiver])
        );
        bytes32 signingHash = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash)
        );
        address signer = ecrecover(signingHash, v, r, s);
        require(signer != address(0), "Invalid signature");
        return signer == receiver;
    }

    // checkBalance
    function checkClaimableBalance(address receiver, address token)
        public
        view
        returns (uint256)
    {
        return lockedTokens[receiver][token].amount;
    }

    function getNonce(address user) external view returns (uint256 nonce) {
        nonce = nonces[user];
    }
}