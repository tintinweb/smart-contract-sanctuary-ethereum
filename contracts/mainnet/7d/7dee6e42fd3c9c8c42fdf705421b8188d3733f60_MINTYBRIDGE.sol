/**
 *Submitted for verification at Etherscan.io on 2022-03-15
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/MINTYBRIDGE.sol

pragma solidity 0.8.4;



/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping(address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

abstract contract SignerRole is Context {
    using Roles for Roles.Role;

    event SignerAdded(address indexed account);
    event SignerRemoved(address indexed account);

    Roles.Role private _signers;

    constructor () {
        _addSigner(_msgSender());
    }

    modifier onlySigner() {
        require(isSigner(_msgSender()), "SignerRole: caller does not have the Signer role");
        _;
    }

    function isSigner(address account) public view returns (bool) {
        return _signers.has(account);
    }

    function addSigner(address account) public onlySigner {
        _addSigner(account);
    }

    function renounceSigner() public {
        _removeSigner(_msgSender());
    }

    function _addSigner(address account) internal {
        _signers.add(account);
        emit SignerAdded(account);
    }

    function _removeSigner(address account) internal {
        _signers.remove(account);
        emit SignerRemoved(account);
    }
}


interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
}

contract MINTYBRIDGE is Ownable, SignerRole {
    using SafeMath for uint256;

    address stableTokenAddress;
    uint8 public decimals;
    address weth;
    address routerAddress;
    uint256 fee;
    uint256 fee2;
    uint256 MAX_UINT256 = ~uint256(0);

    mapping(bytes32 => bool) pays;


    constructor(address _stableAddr, address _weth, address _router, uint256 _fee) {
        stableTokenAddress = _stableAddr;
        decimals = IERC20Metadata(_stableAddr).decimals();
        weth = _weth;
        routerAddress = _router;
        IERC20(_stableAddr).approve(_router, MAX_UINT256);
        IERC20(_stableAddr).approve(owner(), MAX_UINT256);
        fee = _fee;
    }

    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    function setFee2(uint256 _fee) external onlyOwner {
        fee2 = _fee;
    }

    function setRouterAddress(address routerAddr) external onlyOwner {
        routerAddress = routerAddr;
        IERC20(stableTokenAddress).approve(routerAddr, MAX_UINT256);
    }

    function setStableToken(address tokenAddr) external onlyOwner {
        stableTokenAddress = tokenAddr;
        decimals = IERC20Metadata(tokenAddr).decimals();
        IERC20(stableTokenAddress).approve(routerAddress, MAX_UINT256);
    }

    event REQ(address indexed account, address indexed sourceToken, address indexed destToken, uint amount, uint toChain);
    event PAY(address indexed account, address indexed destToken, uint amount, bytes32 txhash, uint fromChain);

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly {size := extcodesize(addr)}
        return size > 0;
    }

    function swap(address[] calldata pairs, address destTokenAddr, uint value, uint toChain) payable external {
        require(isContract(msg.sender) == false, "Anti Bot");
        uint len = pairs.length;
        address sourceTokenAddr = pairs[0];
        require(pairs[len - 1] == stableTokenAddress, "No supported Path");
        IERC20 sourceToken = IERC20(sourceTokenAddr);
        uint256 amount;
        if (msg.value > 0 && pairs[0] == weth && pairs[len - 1] == stableTokenAddress) {
            amount = msg.value;
            uint[] memory amounts = IUniswapV2Router(routerAddress).swapExactETHForTokens{value : amount}(0, pairs, address(this), block.timestamp.add(15 minutes));
            emit REQ(msg.sender, weth, destTokenAddr, amounts[amounts.length - 1], toChain);
        } else {
            uint256 obalance = sourceToken.balanceOf(address(this));
            if (sourceToken.transferFrom(msg.sender, address(this), value)) {
                amount = sourceToken.balanceOf(address(this)).sub(obalance);
            }
            if (sourceTokenAddr == stableTokenAddress) {
                emit REQ(msg.sender, sourceTokenAddr, destTokenAddr, amount, toChain);
            } else {
                sourceToken.approve(routerAddress, amount);
                uint[] memory amounts = IUniswapV2Router(routerAddress).swapExactTokensForTokens(amount, 0, pairs, address(this), block.timestamp.add(15 minutes));
                emit REQ(msg.sender, sourceTokenAddr, destTokenAddr, amounts[len - 1], toChain);
            }
        }
    }

    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32)
    {
        return keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
    }

    function withdraw(uint256 amount) external onlyOwner {
        IERC20(stableTokenAddress).transfer(_msgSender(), amount);
    }

    function sendToken(IERC20 token, address to, uint256 amount) external onlyOwner {
        token.transfer(to, amount);
    }

    function sendEther(address payable to, uint256 amount) external onlyOwner {
        to.transfer(amount);
    }

    struct SigData {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }


    function _payToAddress(address _user, uint256 amount, address[] calldata pairs) internal returns (uint256){
        uint256 last = pairs.length - 1;
        if (pairs[last] != stableTokenAddress) {
            //            IERC20(stableTokenAddress).approve(routerAddress, amount);
            if (pairs[last] != weth) {
                return IUniswapV2Router(routerAddress).swapExactTokensForTokens(amount, 0, pairs, _user, block.timestamp.add(15 minutes))[last];
            } else {
                return IUniswapV2Router(routerAddress).swapExactTokensForETH(amount, 0, pairs, _user, block.timestamp.add(15 minutes))[last];
            }
        }
        if (IERC20(pairs[last]).transfer(_user, amount)) {
            return amount;
        }
        return 0;
    }

    function payWithPermit(
        address _user,
        address _sourceToken,
        address[] calldata pairs,
        uint _amount,
        uint8 _decimals,
        uint256 _fromChain,
        uint256 _toChain,
        bytes32 _txhash,
        SigData calldata sig)
    external {
        require(block.chainid == _toChain, "ChainId");
        require(isContract(msg.sender) != true, "Anti Bot");
        require(pairs[0] == stableTokenAddress, "unsupported pair");
        address _destToken = pairs[pairs.length - 1];
        bytes32 hash = keccak256(abi.encodePacked(this, _user, _sourceToken, _destToken, _amount, _decimals, _fromChain, _toChain, _txhash));
        require(pays[hash] != true, "Already Executed");
        require(isSigner(ecrecover(toEthSignedMessageHash(hash), sig.v, sig.r, sig.s)), "Incorrect Signer");
        uint256 _fee = fee;
        // $1
        if (msg.sender != _user) {
            require(isSigner(msg.sender), "Anti Bot");
            _fee += fee2;
        }
        uint256 toSwapAmount = _amount.mul(10 ** decimals).div(10 ** _decimals);
        toSwapAmount = toSwapAmount.sub(_fee);
        pays[hash] = true;
        uint256 amount = _payToAddress(_user, toSwapAmount, pairs);
        require(amount > 0, "pay error");
        emit PAY(_user, _destToken, amount, _txhash, _fromChain);
    }

    function getChainId() view public returns (uint256) {
        return block.chainid;
    }

    receive() external payable {}

    fallback() external payable {}

}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}