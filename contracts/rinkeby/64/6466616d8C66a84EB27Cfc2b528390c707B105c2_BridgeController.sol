pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ISwapTokenUniswapV2.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./bridges/IBridgeToken.sol";

contract BridgeController is Ownable {
    mapping(uint256 => address) public swapContract;
    mapping(uint256 => address) public stableCoin;

    mapping(uint128 => address) public registeredBridge;
    mapping(address => bool) public enabledBridge;

    mapping(uint128 => address) public addressBridge;

    function registerBridge(uint128 chainId, address _bridge) public onlyOwner {
        registeredBridge[chainId] = _bridge;
    }

    function registerSwapContract(uint256 _chainId, address _address)
        public
        onlyOwner
    {
        swapContract[_chainId] = _address;
    }

    function registerStableCoinContract(uint256 _chainId, address _address)
        public
        onlyOwner
    {
        stableCoin[_chainId] = _address;
    }

    function swap(
        address _token1,
        uint256 _amount,
        uint128 _chainId, // Original Chain
        bytes calldata payload //Flexibal for use another services
    ) public {
        IERC20(_token1).transferFrom(msg.sender, address(this), _amount);

        uint256 amount = _swap(
            _token1,
            _amount,
            swapContract[_chainId],
            _chainId
        );

        _bridge(amount, _chainId, payload);
    }

    function _swap(
        address _token1,
        uint256 _amount,
        address _swapContract,
        uint256 _chainId
    ) private returns (uint256 amount) {
        IERC20(_token1).approve(swapContract[_chainId], _amount);
        require(
            IERC20(_token1).allowance(address(this), swapContract[_chainId]) >
                0,
            "Not Approve"
        );

        amount = ISwapTokenUniswapV2(_swapContract).swapToken(
            _token1,
            stableCoin[_chainId],
            _amount,
            _chainId
        );
    }

    function _bridge(
        uint256 amount,
        uint128 _chainId,
        bytes calldata payload
    ) internal {
        IERC20(stableCoin[_chainId]).approve(
            registeredBridge[_chainId],
            amount
        );
        IBridgeToken(registeredBridge[_chainId]).bridge(amount, payload);
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

pragma solidity ^0.8.0;

interface ISwapTokenUniswapV2 {
    function swapToken(
        address _token1,
        address _token2,
        uint256 _amount,
        uint256 _chainId
    ) external returns (uint256 amounts);

    function swapExactTokensForTokensDesstination(
        address _token1,
        address _token2,
        uint256 _amount,
        address _destinationAddress,
        uint256 _chainId
    ) external returns (uint256 amounts);
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

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;
import "../BridgeController.sol";

abstract contract IBridgeToken {
    BridgeController public immutable controller;

    constructor(address _controller) {
        controller = BridgeController(_controller);
    }

    modifier onlyController() {
        require(msg.sender == address(controller), "Not Controller");
        _;
    }

    function _bridge(uint256 amount, bytes calldata payload) internal virtual;

    function bridge(uint256 amount, bytes calldata payload)
        public
        payable
        onlyController
    {
        _bridge(amount, payload);
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