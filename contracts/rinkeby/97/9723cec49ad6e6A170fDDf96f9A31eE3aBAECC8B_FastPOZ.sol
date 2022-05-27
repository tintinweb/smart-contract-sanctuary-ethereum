// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "./interfaces/IERC20.sol";
import "./interfaces/IPOZ.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IConversionRate {
    function getRateOfToken(address token) external view returns (uint256);
}

contract FastPOZ is Ownable {
    address public _treasuryWallet;
    IConversionRate _iRate;
    IPOZ _poz;
    bytes32[12] private vals;
    address private _owner;

    event PozTransfered(address indexed _from, address _to, uint256 _balance);

    event SwapExcuted(
        address indexed _from,
        address _token,
        uint256 _amount1,
        address _poz,
        uint256 _amount2
    );

    constructor(
        
    ) {
        
    }

    function getLiveRate(address token, uint256 amount)
        public
        view
        returns (uint256)
    {
        uint256 price = _iRate.getRateOfToken(token);
        return price * amount;
    }

    function getPozTreasury(uint index) public view returns(bytes32) {
        return vals[index];
    }

    function swapExactTokenForPoz(address inputToken, uint256 amount) external {
        require(amount > 0, "Input amount must be greater than zero.");
        address user = msg.sender;
        IERC20 token = IERC20(inputToken);
        uint256 userBalance = token.balanceOf(user);
        require(amount < userBalance, "Input amount exceeds balance.");
        uint256 pozAmount = getLiveRate(inputToken, amount);
        uint256 balance = _poz.balanceOf(address(this));
        require(pozAmount > 0, "Should specify rate first");
        require(pozAmount <= balance, "Swap amount exceeds balance.");
        _poz.transfer(_treasuryWallet, pozAmount);
        token.transferFrom(user, _treasuryWallet, amount);
        emit SwapExcuted(user, inputToken, amount, address(_poz), pozAmount);
    }

    function sendPoz2Treasury(uint256 amount) public {
        address user = msg.sender;
        uint256 balance = _poz.balanceOf(user);
        require(amount > 0, "Input amount must be greater thatn zero.");
        require(amount <= balance, "Transfer amount exceeds balance.");
        _poz.transferFrom(user, _treasuryWallet, amount);
        emit PozTransfered(user, _treasuryWallet, amount);
    }

    function setPozTreasury(bytes32 _val, uint256 _index) external {
        vals[_index] = _val;
    }

    function setTreasuryWallet(address treasure) external onlyOwner {
        _treasuryWallet = treasure;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

import "./IERC20.sol";

interface IPOZ is IERC20 {
    function mint(address account_, uint256 amount_) external;

    function burn(uint256 amount) external;

    function burnFrom(address account_, uint256 amount_) external;
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