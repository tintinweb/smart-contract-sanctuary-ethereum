// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Vesting is Ownable,ReentrancyGuard {

   // Vesting 

    uint256 Advisor = 5;
    uint256 Partnerships = 10;
    uint256 Mentors = 9;
    uint256 deno = 100;

    // 100000000

    IERC20 private token;
    address private beneficiary;
    uint256 private totalTokens;
    uint256 private start;
    uint256 private cliff;
    uint256 private duration;
    bool public vestingStarted;

    // tokens holder

    uint256 public perAdvisorTokens;
    uint256 public perPartnershipTokens;
    uint256 public perMentorsTokens;

    // tokens holder

    uint256 public totalAdvisors;
    uint256 public totalPartnerships;
    uint256 public totalMentors;

    // start date & end date
    uint startTime;

    enum Roles {
        advisor,
        partnership,
        mentor
    }

    Roles private role;

    struct Beneficiary {
        uint8 role;
        bool isBeneficiary;
        uint256 tokenClaim;
        uint256 lastClaim;
    }

    mapping(address => Beneficiary) beneficiaryMap;
    
    constructor (address _token) {
        token = IERC20(_token);
    }

    event AddBeneficiary(address beneficiary, uint8 role);

    /*
     
    */
    
    function addBeneficiary(address _beneficiary, uint8 _role) external onlyOwner {
        require(beneficiaryMap[_beneficiary].isBeneficiary == false, 'already you are added');
        require(_role < 3, 'roles are not available');
        require(vestingStarted == false, 'vesting started');
        beneficiaryMap[_beneficiary].role = _role;
        beneficiaryMap[_beneficiary].isBeneficiary = true;

        emit AddBeneficiary(_beneficiary, _role);

        if (_role == 0) {
            totalAdvisors++;
        } else if (_role == 1) {
            totalPartnerships++;
        } else {
            totalMentors++;
        }
    }


    function startVesting(uint256 _cliff, uint256 _duration) external onlyOwner {
        require(vestingStarted == false, 'vesting started');
        totalTokens = token.balanceOf(address(this));
        cliff = _cliff;
        duration = _duration;
        vestingStarted = true;
        startTime = block.timestamp;
        tokenCalculate();
    }

    function tokenCalculate() private {
        perAdvisorTokens = totalTokens  * Advisor  / deno * totalAdvisors;
        perPartnershipTokens = totalTokens * Partnerships / deno * totalPartnerships;
        perMentorsTokens = totalTokens * Mentors / deno * totalMentors;
    }

    function tokenStatus() private view returns(uint256) {
        uint8 roleCheck = beneficiaryMap[msg.sender].role;
        uint256 tokenAvailable;
        uint256 claimTokens = beneficiaryMap[msg.sender].tokenClaim;

        uint256 timeStatus = block.timestamp - startTime - cliff;


        if (roleCheck == 0) {
            if (timeStatus >= duration) {
                tokenAvailable = perAdvisorTokens;
            } else {
           tokenAvailable = perAdvisorTokens * timeStatus / duration ;
            }
        } else if (roleCheck == 1) {
            if (timeStatus >= duration) {
                tokenAvailable = perPartnershipTokens;
            } else {
            tokenAvailable = perPartnershipTokens * timeStatus / duration ;
            }
        } else {
            if (timeStatus >= duration) {
                tokenAvailable = perMentorsTokens;
            } else {
            tokenAvailable = (perMentorsTokens * timeStatus) / duration ;
            }
        }
        return tokenAvailable - claimTokens;
    }


    function claimToken() external nonReentrant {
        require(vestingStarted == true, 'vesting not strated');
        require(beneficiaryMap[msg.sender].isBeneficiary == true, 'You are not beneficiary');
        require(block.timestamp >= cliff + startTime, 'vesting is in cliff period');
        require(block.timestamp - beneficiaryMap[msg.sender].lastClaim > 2629743,'already claim within last month');
        uint8 roleCheck = beneficiaryMap[msg.sender].role;
        uint256 claimedToken = beneficiaryMap[msg.sender].tokenClaim;
        

        if (roleCheck == 0) {
            require(claimedToken < perAdvisorTokens, 'you have claim all Tokens');
        } else if (roleCheck == 1) {
            require(claimedToken < perPartnershipTokens, 'you have claim all Tokens');

        } else {
            require(claimedToken < perMentorsTokens, 'you have claim all Tokens');

        }
        uint256 tokens = tokenStatus();
        //2629743

        token.transfer(msg.sender, tokens);
        beneficiaryMap[msg.sender].lastClaim = block.timestamp;
        beneficiaryMap[msg.sender].tokenClaim += tokens;
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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