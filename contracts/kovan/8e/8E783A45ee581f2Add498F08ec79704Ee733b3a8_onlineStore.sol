// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

contract onlineStore is KeeperCompatibleInterface, Ownable {
    address keeperRegistryAddress;
    IERC20 socialLegoToken; //address of SocialLego token

    modifier onlyKeeper() {
        require(msg.sender == keeperRegistryAddress);
        _;
    }

    uint256 public lastCheckIn = block.timestamp;
    uint256 public checkInTimeInterval = 864000; //default to six months
    address public nextOwner;

    uint256 public massivePurchaseTokenPrice = 0.001 * 10**18; // 1 Million tokens is 1 Ether
    uint256 public largePurchaseTokenPrice = 0.00015 * 10**18; // 100,000 tokens is 0.15 Ether
    uint256 public mediumPurchaseTokenPrice = 0.00004 * 10**18; // 20,0000 tokens is 0.04 Ether
    uint256 public smallPurchaseTokenPrice = 0.000025 * 10**18; // 10,0000 tokens is 0.025 Ether

    constructor(address _keeperRegistryAddress, address _socialLegoToken) {
        keeperRegistryAddress = _keeperRegistryAddress;
        socialLegoToken = IERC20(_socialLegoToken);
    }

    function buyMassiveTokens() public payable {
        // how many tokens they want to purchase
        require(
            socialLegoToken.balanceOf(address(this)) >= 1000000 * 10**10,
            "Not Enought Tokens in Contract"
        ); // require this contract to have at least 1,000,000 tokens before executing
        require(
            msg.value >= massivePurchaseTokenPrice,
            "Send the right amount of eth"
        ); // there is a bug when calling the contract through moralis that the msg.value did not equal required even though msg.value was correct.
        socialLegoToken.transfer(msg.sender, 1000000 * 10**18); // send a million tokens.
    }

    function buyLargeTokens() public payable {
        // how many tokens they want to purchase
        require(
            socialLegoToken.balanceOf(address(this)) >= 100000 * 10**10,
            "Not Enought Tokens in Contract"
        ); // require this contract to have at least 1,000,000 tokens before executing
        require(
            msg.value >= largePurchaseTokenPrice,
            "Send the right amount of eth"
        ); // require this contract to have at least 1,000,000 tokens before executing
        socialLegoToken.transfer(msg.sender, 100000 * 10**18); // send 100,0000 tokens.
    }

    function buyMediumTokens() public payable {
        // how many tokens they want to purchase
        require(
            socialLegoToken.balanceOf(address(this)) >= 20000 * 10**10,
            "Not Enought Tokens in Contract"
        ); // require this contract to have at least 1,000,000 tokens before executing
        require(
            msg.value >= mediumPurchaseTokenPrice,
            "Send the right amount of eth"
        ); // require this contract to have at least 1,000,000 tokens before executing
        socialLegoToken.transfer(msg.sender, 20000 * 10**18); // send 20,0000 tokens.
    }

    function buySmallTokens() public payable {
        // how many tokens they want to purchase
        require(
            socialLegoToken.balanceOf(address(this)) >= 10000 * 10**10,
            "Not Enought Tokens in Contract"
        ); // require this contract to have at least 1,000,000 tokens before executing
        require(
            msg.value >= smallPurchaseTokenPrice,
            "Send the right amount of eth"
        ); // require this contract to have at least 1,000,000 tokens before executing
        socialLegoToken.transfer(msg.sender, 10000 * 10**18); // send 10,0000 tokens.
    }

    function withdrawErc20(IERC20 token) public onlyOwner {
        //withdraw all ERC-20 that get accidently sent since this is an only ether store.
        require(
            token.transfer(msg.sender, token.balanceOf(address(this))),
            "Transfer failed"
        );
    }

    function withdraw(uint256 amount) public onlyOwner returns (bool) {
        require(amount <= address(this).balance);
        payable(msg.sender).transfer(amount); //if the owner send to sender
        return true;
    }

    function setMassiveStorePrice(uint256 newPrice) public onlyOwner {
        require(newPrice <= massivePurchaseTokenPrice * 2, "too high price"); // just in case you fat finger a number and accidently set a number too high or too low
        require(newPrice >= massivePurchaseTokenPrice / 2, "too low price");
        massivePurchaseTokenPrice = newPrice;
    }

    function setLargeStorePrice(uint256 newPrice) public onlyOwner {
        require(newPrice <= largePurchaseTokenPrice * 2, "too high price"); // just in case you fat finger a number and accidently set a number too high or too low
        require(newPrice >= largePurchaseTokenPrice / 2, "too low price");
        largePurchaseTokenPrice = newPrice;
    }

    function setMediumStorePrice(uint256 newPrice) public onlyOwner {
        require(newPrice <= mediumPurchaseTokenPrice * 2, "too high price"); // just in case you fat finger a number and accidently set a number too high or too low
        require(newPrice >= mediumPurchaseTokenPrice / 2, "too low price");
        mediumPurchaseTokenPrice = newPrice;
    }

    function setsmallStorePrice(uint256 newPrice) public onlyOwner {
        require(newPrice <= smallPurchaseTokenPrice * 2, "too high price"); // just in case you fat finger a number and accidently set a number too high or too low
        require(newPrice >= smallPurchaseTokenPrice / 2, "too low price");
        smallPurchaseTokenPrice = newPrice;
    }

    function changeInheritance(address newInheritor) public onlyOwner {
        nextOwner = newInheritor;
    }

    function ownerCheckIn() public onlyOwner {
        lastCheckIn = block.timestamp;
    }

    function changeCheckInTime(uint256 newCheckInTimeInterval)
        public
        onlyOwner
    {
        checkInTimeInterval = newCheckInTimeInterval; // let owner change check in case he know he will be away for a while.
    }

    function passDownInheritance() internal {
        transferOwnership(nextOwner);
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        //upkeepNeeded = (block.timestamp > (lastCheck + 5184000));
        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
        return (
            block.timestamp > (lastCheckIn + checkInTimeInterval),
            bytes("")
        ); // make sure to check in at least once every 6 months
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override onlyKeeper {
        passDownInheritance();
    }
}