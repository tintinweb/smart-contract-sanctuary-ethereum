pragma solidity ^0.8.2;

import "IERC20.sol";
import "Ownable.sol";
import "IWethGateway.sol";
import "IClaim.sol";
import "IRouterV2.sol";


contract BendDaoStragegy is Ownable {

	IERC20 public constant WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
	IERC20 public constant bendWETH = IERC20(0xeD1840223484483C0cb050E6fC344d1eBF0778a9);
	IERC20 public constant debtBendWETH = IERC20(0x87ddE3A3f4b629E389ce5894c9A1F34A7eeC5648);
	IERC20 public constant BEND = IERC20(0x0d02755a5700414B26FF040e1dE35D337DF56218);
	IWethGateway public constant WETH_GATEWAY = IWethGateway(0x3B968D2D299B895A5Fcf3BBa7A64ad0F566e6F88);
	IClaim public constant CLAIM_ADDRESS = IClaim(0x26FC1f11E612366d3367fc0cbFfF9e819da91C8d);
	IRouterV2 public constant UNI_V2 = IRouterV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

	mapping(address => bool) public authorised;
	mapping(address => bool) public admin;

	constructor() {
		bendWETH.approve(address(WETH_GATEWAY), type(uint256).max);
		BEND.approve(address(UNI_V2), type(uint256).max);
	}

	modifier isAuthorised() {
		require(authorised[msg.sender] || msg.sender == owner());
        _;
	}

	modifier isAdmin() {
		require(admin[msg.sender] || msg.sender == owner());
        _;
	}
	
	function setAuthorised(address _user, bool _val) external onlyOwner {
		authorised[_user] = _val;
	}
	function setAdmin(address _admin, bool _val) external onlyOwner {
		admin[_admin] = _val;
	}

	function deposit() external payable {
		WETH_GATEWAY.depositETH{value:msg.value}(address(this), uint16(0));
	}

	function withdraw() external {
		withdraw(type(uint256).max);
	}

	function withdraw(uint256 _amount) public isAuthorised {
		WETH_GATEWAY.withdrawETH(_amount, address(this));
		payable(owner()).transfer(address(this).balance);
	}

	function emergencyWithdraw() public onlyOwner {
		bendWETH.transfer(owner(), bendWETH.balanceOf(address(this)));
	}

	function harvest(uint256 _min) external isAuthorised {
		address[] memory assets = new address[](2);
		assets[0] = address(bendWETH);
		assets[1] = address(debtBendWETH);
		uint256 amount = 0x8000000000000000000000000000000000000000000000000000000000000000;
		uint256 claimed = CLAIM_ADDRESS.claimRewards(assets, amount);

		assets[0] = address(BEND);
		assets[1] = address(WETH);
		UNI_V2.swapExactTokensForTokens(claimed, _min, assets, owner(), block.timestamp + 20);
	}

	function exec(address _target, uint256 _value, bytes calldata _data) external payable isAdmin {
		(bool success, bytes memory data) = _target.call{value:_value}(_data);
		require(success);
	}

	receive() external payable {}
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

import "Context.sol";

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
    address internal _owner;

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

pragma solidity ^0.8.2;

interface IWethGateway {
	function depositETH(address onBehalfOf, uint16 referralCode) external payable;
	function withdrawETH(uint256 amount, address to) external;
}

pragma solidity ^0.8.2;

interface IClaim {
	function claimRewards(address[] calldata _assets, uint256 _amount) external returns (uint256);
}

pragma solidity ^0.8.2;

interface IRouterV2 {

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}