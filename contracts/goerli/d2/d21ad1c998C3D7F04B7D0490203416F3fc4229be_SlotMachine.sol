pragma solidity ^0.8.9;

import "./AddSlotTokenERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SlotMachine is AddSlotTokenERC20 {

    address public slotMachineFunds;

    uint256 public coinPrice = 0.1 ether;
    address public rootOwner;
/* 
    address public owner; */

    event Rolled(address sender, uint rand1, uint rand2, uint rand3);

    mapping (address => uint) pendingWithdrawals;

  /*   modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    } */

      constructor() public { 
        rootOwner = msg.sender;
    }

    //the user plays one roll of the machine putting in money for the win
    function oneRoll() public payable {
        require(msg.value >= coinPrice);

        uint rand1 = randomGen(msg.value);
        uint rand2 = randomGen(msg.value + 10);
        uint rand3 = randomGen(msg.value + 20);

        uint result = calculatePrize(rand1, rand2, rand3);

        emit Rolled(msg.sender, rand1, rand2, rand3);

        pendingWithdrawals[msg.sender] += result;
        
    }
    
    function contractBalance() public returns(uint) {
        return address(this).balance;
    }

    function calculatePrize(uint rand1, uint rand2, uint rand3) public returns(uint) {
        if(rand1 == 5 && rand2 == 5 && rand3 == 5) {
            return coinPrice * 30;
        } else if (rand1 == 6 && rand2 == 5 && rand3 == 6) {
            return coinPrice * 20;
        } else if (rand1 == 4 && rand2 == 4 && rand3 == 4) {
            return coinPrice * 15;
        } else if (rand1 == 3 && rand2 == 3 && rand3 == 3) {
            return coinPrice * 12;
        } else if (rand1 == 2 && rand2 == 2 && rand3 == 2) {
            return coinPrice * 10;
        } else if (rand1 == 1 && rand2 == 1 && rand3 == 1) {
            return coinPrice * 5;
        } else if ((rand1 == rand2) || (rand1 == rand3) || (rand2 == rand3)) {
            return coinPrice;
        } else {
            return 0;
        }
    }

    function withdraw(address _tokenContractAddress) public {
        //todo : withdraw specific token
        uint amount = pendingWithdrawals[msg.sender];

        pendingWithdrawals[msg.sender] = 0;

        //msg.sender.transfer(amount);
        (bool sent, bytes memory data)  = msg.sender.call{value: amount}("");
    }

    function balanceOf(address user) public returns(uint) {
        return pendingWithdrawals[user];
    }

    function setCoinPrice(uint _coinPrice) public onlyOwner {
        coinPrice = _coinPrice;
    }

    function cashout(uint _amount) public onlyOwner {
        //msg.sender.transfer(_amount);
        //address rootOwner = owner();

        (bool sent, bytes memory data)  = rootOwner.call{value: _amount}("");
    }

    function randomGen(uint seed) private returns (uint randomNumber) {
        uint source = block.difficulty + block.timestamp;
        bytes memory source_b = toBytes(source);

        return (uint(keccak256(source_b)) % 6) + 1;
    }

    function toBytes(uint256 x) public returns (bytes memory b) {
    b = new bytes(32);
    assembly { mstore(add(b, 32), x) }
}

}

pragma solidity ^0.8.9;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./TwoLevelReferral.sol";

contract AddSlotTokenERC20 is ReentrancyGuard, TwoLevelReferral {

    uint256 public feeToAddToken = 3 ether; //ETH
    error ApplyToAddToken__TransferFailed();

    //public list of all tokens
    address[] public allTokenArray;
    //mapping to get token info right away
    mapping(address => TokenBundle) public allTokenBundles;

    event TokenContractAdded(address tokenContract);
    event TokenPrizesAdded(address tokenContract, uint256 amountOftokens);

    struct TokenBundle {
        address tokenAddress;
        bool isBanned; //false
    }

    function applyToAddToken(address _tokenContractAddress) public payable {

        //check if user paid the fee feeToAddToken in ether
        if(msg.value < feeToAddToken) revert ApplyToAddToken__TransferFailed();

        address rootOwner = owner();
        (bool sent, bytes memory data)  = rootOwner.call{value: msg.value}("");
        if (!sent) revert ApplyToAddToken__TransferFailed();
        //pay 2 

        allTokenBundles[_tokenContractAddress]=TokenBundle(
                _tokenContractAddress,
                false
        );
        allTokenArray.push(_tokenContractAddress);
        emit TokenContractAdded(_tokenContractAddress);
    }

//let users add token prize amount in the contract
    function addTokenPrizes(address _tokenContractAddress, uint256 _amount) public {

        IERC20(_tokenContractAddress).transferFrom(
                msg.sender,
                address(this),
                _amount
            );
       
        emit TokenPrizesAdded(_tokenContractAddress, _amount);
    }

    //Root Owner Functions below

    function banTokenType(address _tokenContractAddress) public onlyOwner{
        //ban the token address
    }

    function removeTokenType(address _tokenContractAddress) public onlyOwner{
        //remove the token address
    }

    function clearOtherTokens(IERC20 _tokenAddress, address _to)
        external
        onlyOwner
    {
        _tokenAddress.transfer(_to, _tokenAddress.balanceOf(address(this)));
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error TwoLevelReferral__TransferFailed();
error TwoLevelReferral__InvalidDenomination();

contract TwoLevelReferral is Ownable{
    mapping(address => address) public referralMap;

    function payReferral(
        address _depositor,
        address _referrerAddress,
        uint256 _denomination
    ) internal {
        address rootOwner = owner();

        if (_denomination == 0) {
            revert TwoLevelReferral__InvalidDenomination();
        }

        bool success;

        if (_referrerAddress != address(0)) {
            referralMap[_depositor] = _referrerAddress;

            if (referralMap[_referrerAddress] != address(0)) {
                // Send 0.5% to the refferer
                (success, ) = _referrerAddress.call{value: _denomination / 200}("");
                if (!success) revert TwoLevelReferral__TransferFailed();

                // Send 0.1% to the second level refferer
                address secondLevelReferrer = referralMap[_referrerAddress];
                (success, ) = secondLevelReferrer.call{value: _denomination / 1000}("");
                if (!success) revert TwoLevelReferral__TransferFailed();

                // Send 0.4% to the root owner
                (success, ) = rootOwner.call{value: _denomination / 250}("");
                if (!success) revert TwoLevelReferral__TransferFailed();
            } else {
                // Send 0.5% to the refferer
                (success, ) = _referrerAddress.call{value: _denomination / 200}("");
                if (!success) revert TwoLevelReferral__TransferFailed();

                // Send 0.5% to the root owner
                (success, ) = rootOwner.call{value: _denomination / 200}("");
                if (!success) revert TwoLevelReferral__TransferFailed();
            }
        } else {
            // Send 1% to the root owner
            (success, ) = rootOwner.call{value: _denomination / 100}("");
            if (!success) revert TwoLevelReferral__TransferFailed();
        }
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