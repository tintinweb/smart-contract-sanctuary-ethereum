//SPDX-License-Identifier: Unlicense
//                                                      *****+=:.  .=*****+-.      -#@@#-.   .+*****=:.     .****+:   :*****+=:.   -***:  -+**=   =***.
//                ...:=*#%%#*=:..       .+%@*.          @@@@%@@@@* .#@@@%%@@@*.  [email protected]@@@%@@@-  :%@@@%%@@@-    [email protected]@@@@#   [email protected]@@@%@@@@+  [email protected]@@-   #@@@:  %@@%
//             .:=%@@@@@@@@@@@@@@#-.  .#@@@@%:          @@@% .#@@%=.#@@*  [email protected]@@= -%@@#: #@@@: :%@@- [email protected]@@@   [email protected]@@#@@#   [email protected]@@* :%@@*: [email protected]@@-   [email protected]@@+ [email protected]@@.
//           .-%@@@@@@%%%%%%%%@@@@@@+=%@@@%*.           @@@%  :@@@*.#@@*  [email protected]@@= [email protected]@@-  *@@@- :%@@=..%@@@   [email protected]@%[email protected]@%:  [email protected]@@* [email protected]@#: [email protected]@@-    *@@@:%@@+
//          -%@@@@%##=.      :*##@@@@@@@%#.             @@@@:-*@@%=.#@@#::*@@%- [email protected]@@-  [email protected]@@= :%@@*+#@@@=   [email protected]@%[email protected]@@#  [email protected]@@#+#@@@=  [email protected]@@-    .#@@[email protected]@%
//        [email protected]@@@#*:              *@@@@@#-               @@@@@@@@#+ .#@@@@@@@@=  [email protected]@@-  [email protected]@@+.:%@@%##@@#:   @@@#.%@@#  [email protected]@@%#%@@#-. [email protected]@@-     [email protected]@@@@:
//       :*@@@@+.              .=%@@@#*.                @@@@***+.  .#@@%+*%@@#: [email protected]@@-  *@@@+ :%@@-  %@@@. [email protected]@@#=*@@%- [email protected]@@* :*@@@= [email protected]@@-      #@@@#
//      .#@@@%=              .-#@@@%#:    :             @@@%       .#@@*  [email protected]@@= [email protected]@@=  *@@@- :%@@-  [email protected]@@= [email protected]@@@@@@@@* [email protected]@@*  [email protected]@@= [email protected]@@-      *@@@:
//      [email protected]@@@=              :*@@@@#-.   .-%:            @@@%       .#@@*  [email protected]@@= -%@@*=-%@@#. :%@@*=-%@@@: @@@@++*@@@# [email protected]@@#--*@@%- [email protected]@@*----. *@@@:
//     [email protected]@@@+             :=#@@@#+:    [email protected]@*.           @@@%       .#@@*  [email protected]@@=  -#@@@@@@#:  :%@@@@@@@*+ [email protected]@@#  .*@@%[email protected]@@@@@@@#-  [email protected]@@@@@@@: *@@@:
//     [email protected]@@%            .-#@@@%*:      *@@@@.           +++=       .=++-  :+++:   :++++++.   .++++++++.  :+++:   :+++-.+++++++=:   -++++++++. -+++.
//     #@@@%           :*@@@@#-.       -%@@@.
//     %@@@%         :+#@@@#=:         :%@@@.                             .                                                        .
//     [email protected]@@%       .=#@@@@*:           [email protected]@@@.           ++++=  :++=   :++***++: .=+++++++++. =++=  .+++-  +++=  .+++=. :+++-   :++***++:
//     :@@@%-     :*@@@@#-.            *@@@%.           @@@@%  [email protected]@#  :#@@@#%@@#:-%@@@@@@@@@: %@@%. :@@@*  @@@%  :@@@@+ [email protected]@@+  :#@@%#@@@#:
//      @@@@#   .*#@@@#=:             =%@@@=            @@@@@= [email protected]@# [email protected]@@+:=%@@*:---#@@@+--. %@@%. :@@@*  @@@%  :@@@@#:[email protected]@@+ :%@@*::*@@@-
//      [email protected]@@@+ =#@@@@*:              -%@@@#.            @@@#@% [email protected]@# :%@@*. [email protected]@%-   *@@@-    %@@%. :@@@*  @@@%  :@@@@@[email protected]@@+ [email protected]@@=  :---.
//       [email protected]@@@#%@@@#-.              =%@@@@-             @@@[email protected]@*[email protected]@# [email protected]@@*   [email protected]@@=   *@@@-    %@@@#*#@@@*  @@@%  :@@%[email protected]%*@@@+ [email protected]@@= -****:
//        [email protected]@@@@@%=.              :*@@@@%-              @@@-%@%[email protected]@# [email protected]@@*   [email protected]@@=   *@@@-    %@@@@@@@@@*  @@@%  :@@#[email protected]@%@@@+ [email protected]@@= [email protected]@@@-
//        [email protected]@@@@*.              -#%@@@@+:               @@@=:@@%@@# [email protected]@@*   [email protected]@@=   *@@@-    %@@%-:[email protected]@@*  @@@%  :@@#[email protected]@@@@+ [email protected]@@= .*@@@-
//      .%@@@@%:.    :*+-:-=*#%%@@@@@%-                 @@@=.#@@@@# .*@@%- :#@@#:   *@@@-    %@@%. :@@@*  @@@%  :@@# [email protected]@@@@+ [email protected]@@=  [email protected]@@-
//     *%@@@@=.    :#%@@@%@@@@@@@@@*:.                  @@@= :@@@@#  [email protected]@@%+#@@@+    *@@@-    %@@%. :@@@*  @@@%  :@@#  [email protected]@@@+ .*@@@*+%@@@- -#%%:
//   :%@@@@#.     .#@@@@@@@@@@@@*:.                     @@@= .#@@@#   [email protected]@@@@@@+     *@@@-    %@@%. :@@@*  @@@%  :@@#  [email protected]@@@+  -%@@@@@@@@- :%@@:
//    .:-:.         ....:::.....                        ..     ...     ..:::..       ...      ..    ...   ...    ..    ....     .::.....    ..
//
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IPNTokenSwap.sol";

/** @title Probably Nothing Token Swap from PN to PRBLY
 * @author 0xEwok and audie.eth
 * @notice This contract swaps PN tokens for PRBLY tokens and compensates PN
 *         taxes
 */
contract PNTokenSwap is IPNTokenSwap, ReentrancyGuard, Ownable {
    address private v1TokenAddress;
    address private v2TokenAddress;
    address private v1TokenTaker;
    bool private swapActive;

    mapping(address => uint256) private swappedAmount;

    constructor(address _v1Token, address _v2Token) {
        v1TokenAddress = _v1Token;
        v2TokenAddress = _v2Token;
    }

    /** @notice Provides address of token being swapped
     * @return v1Address address of the V1 token contract
     */
    function getV1TokenAddress() external view override returns (address) {
        return v1TokenAddress;
    }

    /** @notice Provides address of received from swap
     * @return v2Address address of the V2 token contract
     */
    function getV2TokenAddress() external view override returns (address) {
        return v2TokenAddress;
    }

    /** @notice Provides address that receives swapped tokens
     * @return tokenTaker address that receives swapped tokens
     */
    function getV1TokenTaker() public view override returns (address) {
        return v1TokenTaker;
    }

    /** @notice Allows owner to change who receives swapped tokens
     * @param newTokenTaker address to receive swapped tokens
     */
    function setV1TokenTaker(address newTokenTaker)
        external
        override
        onlyOwner
    {
        v1TokenTaker = newTokenTaker;
    }

    /** @notice Allows any caller to see if the swap function is active
     * @return swapActive boolean indicating whether swap is on or off
     */
    function isSwapActive() external view returns (bool) {
        return swapActive;
    }

    /** @notice Allows owner to pause use of the swap function
     * @dev Simply calling this function is enough to pause swapping
     */
    function pauseSwap() external onlyOwner {
        swapActive = false;
    }

    /** @notice Allows owner to activate the swap function if it's paused
     * @dev Ensure the token taker address is set before calling
     */
    function allowSwap() external onlyOwner {
        require(v1TokenTaker != address(0), "Must setV1TokenTaker");
        swapActive = true;
    }

    /** @notice Check an addresses cumulative swapped tokens (input)
     * @param swapper Address for which you want the cumulative balance
     */
    function getSwappedAmount(address swapper) external view returns (uint256) {
        return swappedAmount[swapper];
    }

    /** @notice Swaps PN v1 tokens for PN v2 tokens
     * @param amount The amount of v1 tokens to exchange for v2 tokens
     */
    function swap(uint256 amount) external override nonReentrant {
        require(swapActive, "Swap is paused");
        IERC20 v1Contract = IERC20(v1TokenAddress);
        require(
            v1Contract.balanceOf(msg.sender) >= amount,
            "Amount higher than user's balance"
        );
        require(
            // Tranfer tokens from sender to token taker
            v1Contract.transferFrom(msg.sender, v1TokenTaker, amount),
            "Token swap failed"
        );

        IERC20 v2Contract = IERC20(v2TokenAddress);

        // Transfer amount minus fees to sender
        v2Contract.transfer(msg.sender, swapAmount(amount));

        // record the amount of swapped v1 tokens
        swappedAmount[msg.sender] = swappedAmount[msg.sender] + amount;
    }

    /** @notice Allows Owner to withdraw unswapped v2 tokens
     * @param amount The amount of v2 tokens to withdraw
     */
    function withdrawV2(uint256 amount) external onlyOwner {
        IERC20(v2TokenAddress).transfer(msg.sender, amount);
    }

    /** @notice Given a v1 Amount, shows the number of v2 tokens swap will return
     * @param v1Amount The amount of v1 tokens to check
     * @return v2Amount number of V2 tokens to be swapped for V1
     */
    function swapAmount(uint256 v1Amount) public pure returns (uint256) {
        // This results in moving the decimal place 4 positions to the RIGHT!
        // The reason is because v1 was 9 decimals, and v2 is 18 decimals.
        return v1Amount * 100000;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IPNTokenSwap{
    function getV1TokenAddress() external view returns(address);
    function getV2TokenAddress() external view returns(address); 
    function getV1TokenTaker() external view returns(address);   
    function setV1TokenTaker(address _newTokenTaker) external; 
    function swap(uint256 amount) external;
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