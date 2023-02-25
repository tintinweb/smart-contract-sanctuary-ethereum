// SPDX-License-Identifier: MIT
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
pragma solidity ^0.8.7;

import "./interfaces/IExpy.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error Expy__MarketplaceisPaused();
error Expy__NotOwner();
error Expy__AddressisZero();
error Expy__IsZero();
error Expy__PriceisZero();
error Expy__SenderisNotPayer();
error Expy__SenderDoesNotHaveEnoughBalance();
error Expy__SenderDidNotSendCorrectAmount();

contract Expy is IExpy, ReentrancyGuard {

    address private immutable i_owner;
    address payable private beneficiary;
    bool public paused = false;

    modifier notPaused() {
        if(paused) { revert Expy__MarketplaceisPaused(); }
        _;
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) { revert Expy__NotOwner(); } 
        _;
    }

    constructor(address payable newBeneficiary) {
        ensureIsNotZeroAddr(newBeneficiary);
        i_owner = msg.sender;
        beneficiary = newBeneficiary;
    }


    function collect(address _PK, bytes32 _SK, address _token, uint256 amount) external notPaused {
        ensureIsNotZeroAddr(_PK);
        ensureIsNotZero(_SK);
        ensureIsNotZeroAddr(_token);
        ensureIsNotZeroPrice(amount);

        ensureSenderisPayer(_PK);
        ensureSenderHasAmount(IERC20(_token).balanceOf(msg.sender), amount);

        // Before this you should have approved the amount 
        // This will transfer the amount of  _token from caller to contract
        IERC20(_token).transferFrom(msg.sender, address(this), amount);

        emit IExpy.PaymentReceived(_PK, _SK, _token, amount);
    }

    function collectNative(address _PK, bytes32 _SK, uint256 amount) external payable notPaused {
        ensureIsNotZeroAddr(_PK);
        ensureIsNotZero(_SK);
        ensureIsNotZeroPrice(amount);
        ensureSenderisPayer(_PK);
        ensureValueEqualsAmount(amount, msg.value);
        emit IExpy.PaymentReceivedNative(_PK, _SK, amount);
    }

    // function withdraw(address _PK, bytes32 _SK, address _token, uint256 _price) external payable notPaused {
    //     ensureIsNotZeroAddr(_payerAddress);
    //     ensureIsNotZeroAddr(_playerAddress);
    //     ensureIsNotZeroAddr(_token);
    //     ensureIsNotZeroAddr(_price);

            // uint256 erc20balance = token.balanceOf(address(this));
            // require(amount <= erc20balance, "balance is low");
    //     emit IExpy.PaymentReceived(_PK, _SK, _token, _price);
    // }


      /////////////////////
     // Logic Functions //
    /////////////////////

    function ensureIsNotZeroAddr(address addr) private pure {
        if(addr == address(0)) {
            revert Expy__AddressisZero();
        }
    }

    function ensureIsNotZero(bytes32 _SK) private pure {
        if(_SK == 0) {
            revert Expy__IsZero();
        }
    }

    function ensureIsNotZeroPrice(uint256 amount) private pure {
        if(amount <= 0) {
            revert Expy__PriceisZero(); 
        }
    }

    function ensureSenderisPayer(address _PK) private view {
        if(_PK != msg.sender) {
            revert Expy__SenderisNotPayer(); 
        }
    }

    function ensureSenderHasAmount(uint256 payerBalance, uint256 amount) private pure {
        if(payerBalance < amount) {
            revert Expy__SenderDoesNotHaveEnoughBalance(); 
        }
    }

    function ensureValueEqualsAmount(uint256 amount, uint256 value) private pure {
        if(amount != value) {
            revert Expy__SenderDidNotSendCorrectAmount(); 
        }
    }

      /////////////////////////////////
     // Getter and Setter Functions //
    /////////////////////////////////

    function setBeneficiary(address payable newBeneficiary) external onlyOwner {
        beneficiary = newBeneficiary;
    }

    function getBeneficiary() external view returns (address) {
        return beneficiary;
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function setPaused(bool newPaused) external onlyOwner {
        paused = newPaused;
        if(paused) {
            emit MarketplacePaused(msg.sender);
        } else {
            emit MarketplaceUnPaused(msg.sender);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IExpy {

    event PaymentReceived(
        address indexed PK,
        bytes32 SK,
        address indexed token,
        uint256 price
    );

    event PaymentReceivedNative(
        address indexed PK,
        bytes32 SK,
        uint256 price
    );
    
    event PaymentClaimed(
        address indexed PK,
        bytes32 SK,
        address indexed token,
        uint256 price
    );

    event MarketplacePaused(
        address indexed owner
    );

    event MarketplaceUnPaused(
        address indexed owner
    );

    function collect(
        address PK,
        bytes32 SK,
        address token,
        uint256 amount
    ) external;

    function collectNative(
        address PK,
        bytes32 SK,
        uint256 amount
    ) external payable;

    // function withdraw(
    //     address PK,
    //     bytes32 SK,
    //     address token,
    //     uint256 price
    // ) external;

}