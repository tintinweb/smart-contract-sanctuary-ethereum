// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.6;

// OpenZeppelin
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Bridge is Ownable {

    struct BridgeRequest {
        address account;
        uint256 amount;
        uint256 blockNumber;
        uint256 timestamp;
    }

    event RequestSent (uint256 _id, address indexed _account, uint256 _amount, uint256 _blocknumber);
    event RequestReceived (uint256 _id, address indexed _account, uint256 _amount, uint256 _blocknumber);

    constructor() {
        outgoingTransferFee = 0.1 * 10**18;
        settlingAgent = payable(msg.sender);
    }

    uint256 public depositedTokens;

    address payable public settlingAgent;
    function setSettlingAgent(address _address) public onlyOwner {
        settlingAgent = payable(_address);
    }

    address public tokenAddress;
    function setTokenAddress(address _address) public onlyOwner {
        tokenAddress = payable(_address);
    }

    uint256 public outgoingTransferFee;
    function setOutgoingTransferFee(uint256 _amount) public onlyOwner {
        outgoingTransferFee = _amount;
    }

    modifier onlyAgent() {
        require(msg.sender == settlingAgent, "This action can only be executed by the settling agent");
        _;
    }

    uint256 public sentRequestCount;
    mapping (uint256 => BridgeRequest) public sentRequests;

    uint256 public receivedRequestCount;
    mapping (uint256 => bool) public receivedRequests;

    function depositTokens(uint256 _amount) public onlyOwner {
        require(_amount > 0, "Amount must be larger than zero");

        IERC20 erc20 = IERC20(tokenAddress) ;
        erc20.transferFrom (msg.sender, address(this) , _amount);
        depositedTokens += _amount;
    }

    function withdrawETH() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
    function withdrawToken(address _tokenAddress) public onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        token.transfer(owner(), token.balanceOf(address(this)));
    }

    function bridgeToken(uint256 _amount) public payable  {
        require(msg.value >= outgoingTransferFee, "Underpaid transaction: please provide the outgoing transfer fee." );

        sentRequestCount++;
        IERC20 erc20 = IERC20(tokenAddress);

        uint256 balanceBefore = erc20.balanceOf(address(this));
        erc20.transferFrom (msg.sender, address(this) , _amount);

        uint256 balanceExpected = balanceBefore + _amount;
        require(erc20.balanceOf(address(this)) >= balanceExpected, "Did not receive enough tokens from sender. Is the bridge exempted from taxes?");

        settlingAgent.transfer(msg.value);

        depositedTokens += _amount;
        sentRequests[sentRequestCount].account =  msg.sender;
        sentRequests[sentRequestCount].amount = _amount;
        sentRequests[sentRequestCount].blockNumber = block.number;
        sentRequests[sentRequestCount].timestamp = block.timestamp;

        emit RequestSent(sentRequestCount, msg.sender, _amount, block.number);
    }
    function settleRequest(uint256 _id, address _account, uint256 _amount) public onlyAgent {
        require (!receivedRequests[_id], "This request was already settled");
        require (depositedTokens >= _amount, "Token deposit insufficient for settlement");

        receivedRequestCount++;
        receivedRequests[receivedRequestCount] = true;

        IERC20 erc20 = IERC20(tokenAddress);
        erc20.transfer(_account, _amount);

        depositedTokens -= _amount;
        emit RequestReceived(receivedRequestCount, _account, _amount, block.number);
    }

    receive() external payable {}
    fallback() external payable {}
}

// SPDX-License-Identifier: MIT
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