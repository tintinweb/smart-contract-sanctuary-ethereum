/**
 *Submitted for verification at Etherscan.io on 2022-05-22
*/

/** 
 *  SourceUnit: c:\Users\ADMIN\Desktop\United-WorldEx-Contract\contracts\Oracle.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
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




/** 
 *  SourceUnit: c:\Users\ADMIN\Desktop\United-WorldEx-Contract\contracts\Oracle.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.0;

interface IOracle {
    function getTargetValue() external view returns(uint256, uint256);
}



/** 
 *  SourceUnit: c:\Users\ADMIN\Desktop\United-WorldEx-Contract\contracts\Oracle.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity 0.8.7;

interface IController {
    function admins(address) external view returns(bool);
    function ttl() external view returns(uint256);
    function lockTime() external view returns(uint256);
    function minCollateralRatio() external view returns(uint16);
    function maxCollateralRatio() external view returns(uint16);
    function calculationDecimal() external pure returns(uint16);
    function discountRates(address) external view returns(uint16);
    function acceptedCollateral(address) external view returns(bool);
    function mintContract() external view returns(address);
    function lockContract() external view returns(address);
    function limitOfferContract() external view returns(address);
    function router() external view returns(address);
    function oracles(address) external view returns(address);
    function pools(address) external view returns(address);
    function collateralForToken(address) external view returns(address);
    function tokenForOracle(address) external view returns(address);
    function royaltyFeeRatio() external view returns(uint256);
    function recieverAddress() external view returns(address);
}



/** 
 *  SourceUnit: c:\Users\ADMIN\Desktop\United-WorldEx-Contract\contracts\Oracle.sol
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
 *  SourceUnit: c:\Users\ADMIN\Desktop\United-WorldEx-Contract\contracts\Oracle.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

////import "../utils/Context.sol";

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


/** 
 *  SourceUnit: c:\Users\ADMIN\Desktop\United-WorldEx-Contract\contracts\Oracle.sol
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.0;

////import "@openzeppelin/contracts/access/Ownable.sol";
////import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
////import {IController} from "./interfaces/IController.sol";
////import "./interfaces/IOracle.sol";

contract Oracle is IOracle, Ownable {
  
    uint256 targetPrice;
    uint256 updatedTime;
    address public controller;

    event UpdatePrice(
        address indexed tokenAddress,
        uint256 targetPrice,
        uint256 updatedTime
    );


    
    /**
     * Network: Rinkeby
     * Oracle:  0xc57B33452b4F7BB189bB5AfaE9cc4aBa1f7a4FD8 (Chainlink Devrel Node)
     * Job ID: d5270d1c311941d0b08bead21fea7747
     * Fee: 0.1 LINK
     */
    constructor(address _controller) {
        setController(_controller);
    }

    modifier onlyAdmin() {
        require(IController(controller).admins(msg.sender) || msg.sender == owner(), "Only admin can update price");
        _;
    }
    
    function setController(address _addr) public onlyOwner {
        controller = _addr;
    }

    function update(uint256 _targetPrice) public onlyAdmin {
        address tokenAddress = IController(controller).tokenForOracle(address(this));
        targetPrice = _targetPrice;
        updatedTime = block.timestamp;
        emit UpdatePrice(tokenAddress, targetPrice, updatedTime);
    }

    function getTargetValue() external view override returns(uint256, uint256) {
        return (targetPrice, updatedTime);
    }
}