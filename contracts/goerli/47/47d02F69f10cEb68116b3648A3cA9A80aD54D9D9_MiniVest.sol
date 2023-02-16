// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import "openzeppelin-contracts/security/ReentrancyGuard.sol";
import "./interfaces/IERC20.sol";

// import "./test/utils/Console2.sol";
/// @title MiniVest
/// @author parseb | @parseb | [email protected]
/// @notice Minimalist vesting contract study
/// @dev As expected. Experimental
/// @custom:security contact: [email protected]

contract MiniVest is ReentrancyGuard {
    /// @notice storage of vesting agreements  [token][beneficiary] = vesting
    mapping(address => mapping(address => uint256)) vestings;

    uint256 immutable k; //19
    uint256 immutable oneToken; //1e18
    address public WalllaWDAO;
    address public WalllaWToken;
    

    error VestingInProgress(address, address);

    event NewVesting(address indexed token, address indexed beneficiary, uint256 amt, uint256 bywhen);
    event VestingCompleted(address indexed token, address indexed beneficiary, uint256 amt);
    event WithdrewFromVest(address indexed token, address indexed beneficiary, uint256 partialAmt);

    /// @notice constructor sets immutable constant
    /// @param _k constant for vesting time and ammount encoding in 1 uint256
    /// @param WALLLAW_DAO address of WALLLAW DAO for permissionless vest withdrawal to
    /// @param WALLLAW_TOKEN WalllaW DAO governance and CSR backed token address
    constructor(uint256 _k, address WALLLAW_DAO, address WALLLAW_TOKEN) {
        k = _k;
        oneToken = 1e18;
        
        WalllaWDAO = WALLLAW_DAO;
        WalllaWToken = WALLLAW_TOKEN;
    }

    /// @notice create vesting agreement
    /// @param _token ERC20 token contract address to be vested
    /// @param _beneficiary beneficiary of the vesting agreement
    /// @param _amount amount of tokens to be vested for over period
    /// @param _days durration of vestion period in days
    function setVest(address _token, address _beneficiary, uint256 _amount, uint256 _days)
        public
        virtual
        returns (bool s)
    {
        if (vestings[_token][_beneficiary] != 0) revert VestingInProgress(_token, _beneficiary);
        require(IERC20(_token).balanceOf(_msgSender()) >= _amount * oneToken, "Insufficient funds");

        require(_amount * _days > 1, "Amount must be greater than 0");
        require(_beneficiary != address(0), "Beneficiary is 0");
        require(_amount < k, "Max amount is k-1");

        vestings[_token][_beneficiary] = _amount * k + (_days * 1 days + block.timestamp);

        s = IERC20(_token).transferFrom(_msgSender(), address(this), _amount * oneToken);

        emit NewVesting(_token, _beneficiary, _amount, _days);


        return s;
    }

    /// @notice withdraws all tokens that have vested for given ERC20 contract address and _msgSender()
    /// @param _token ERC20 contract of token to be withdrawn
    function withdrawAvailable(address _token) public virtual nonReentrant returns (bool s) {
        uint256 iv = vestings[_token][_msgSender()];
        require(vestings[_token][_msgSender()] != 0, "Nothing to bag");

        if (iv % k < block.timestamp) {
            vestings[_token][_msgSender()] = 0;
            s = IERC20(_token).transfer(_msgSender(), (iv / k) * oneToken);
            require(s, "Transfer failed");

            emit VestingCompleted(_token, _msgSender(), iv / k);
        } else {
            uint256 eligibleAmount = (iv / k) - (((iv / k) / (iv % k)) * ((iv % k) - block.timestamp));
            vestings[_token][_msgSender()] = (iv / k - eligibleAmount) * k + ((iv % k) - ((iv % k) - block.timestamp));

            s = IERC20(_token).transfer(_msgSender(), eligibleAmount * oneToken);
            require(s, "Transfer failed");

            emit WithdrewFromVest(_token, _msgSender(), eligibleAmount);
        }
    }


    /// @notice withdraws available balance to WalllaW DAO.
    function withdrawToWallaW() external returns (bool) {
       return withdrawAvailable(WalllaWToken);
    }

    function _msgSender() private returns (address) {
        return msg.sig == this.withdrawToWallaW.selector ? address(WalllaWDAO) : msg.sender;
    }



    /// @notice retrieves vesting data for a given token-beneficiary pair
    /// @param _token ERC20 token contract
    /// @param _beneficiary beneficiary of the vesting agreement
    function getVest(address _token, address _beneficiary) external view returns (uint256) {
        return vestings[_token][_beneficiary];
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}