//SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

//ERC20規格を読み込むための準備
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
}

contract  ExchangeV1forV2 is Ownable {

    IERC20 public jpyc_v1; // インターフェース
    IERC20 public jpyc_v2; // インターフェース
	uint8 public incentive; // インセンティブ率
	uint8 constant inecentive_max = 20; // 最大インセンティブ率

    // _incentiveは百分率で表示
	constructor(address _jpyc_v1, address _jpyc_v2, uint8 _incentive) {
		jpyc_v1 = IERC20(_jpyc_v1);
		jpyc_v2 = IERC20(_jpyc_v2);
		setIncentive(_incentive);
	}

    // JPYCv1と交換
	function swap() external {
		uint256 jpyc_v1_amount = jpyc_v1.balanceOf(msg.sender);
		uint256 jpyc_v2_amount = jpyc_v1_amount * (100 + incentive) / 100;
		jpyc_v1.transferFrom(msg.sender, owner(), jpyc_v1_amount);
		jpyc_v2.transferFrom(owner(), msg.sender, jpyc_v2_amount);
	}

	// インセンティブの設定
	function setIncentive(uint8 _incentive) onlyOwner public {
		require(_incentive <= inecentive_max, "_incentive is greater than max incentive");
		incentive = _incentive;
	}

    // ERC20を引き出す
	// JPYCv1とJPYCv2はこのコントラクトでは所有しないが念の為
	function withdrawERC20(address _tokenAddress, address to) onlyOwner external {
		uint256 ERC20_amount = IERC20(_tokenAddress).balanceOf(address(this));
		IERC20(_tokenAddress).transfer(to, ERC20_amount);
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