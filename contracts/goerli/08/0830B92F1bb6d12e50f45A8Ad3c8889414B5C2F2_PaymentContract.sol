/**
 *Submitted for verification at Etherscan.io on 2022-12-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.5.0;

contract PaymentContract {
    address private _owner;
    IERC20 private _token;
    mapping(string => Subscription) private _subscriptions;

    struct Subscription {
        address owner;
        uint64 timestamp;
        uint192 tokens;
        address tokenAddress;
    }

    constructor(address owner, address token) public nonZeroAddress(owner) nonZeroAddress(token) {
        _owner = owner;
        _token = IERC20(token);
    }

    event SubscriptionPaid(string indexed subscriptionId, uint64 timestampFrom, address indexed ownerAddress, uint192 tokens, address tokenAddress);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    event TokenChanged(address indexed previousToken, address indexed newToken);

    event Withdraw(address indexed byOwner, address indexed toAddress, uint256 amount);

    modifier nonZeroAddress(address account) {
        require(account != address(0), "new owner can't be with the zero address");
        _;
    }

    modifier onlyOwner(){
        require(msg.sender == _owner, "only owner can exec this function");
        _;
    }

    modifier isValidSubscription(string memory subscriptionId){
        require(bytes(subscriptionId).length > 0, "incorrect subscription id");
        require(bytes(subscriptionId).length < 13, "incorrect subscription id");
        require(_subscriptions[subscriptionId].owner == address(0), "subscription already exists");
        _;
    }

    function changeToken(address newToken) external onlyOwner {
        require(newToken != address(_token), "already in use");
        require(newToken != address(0), "invalid address");

        address oldToken = address(_token);
        _token = IERC20(newToken);

        emit TokenChanged(oldToken, newToken);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "new owner can't be the zero address");
        address oldOwner = _owner;
        _owner = newOwner;

        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function withdrawAll(address to) external onlyOwner returns (bool){
        uint256 amount = _token.balanceOf(address(this));
        bool success = _token.transfer(to, amount);
        require(success, "withdraw transfer failed");

        emit Withdraw(_owner, to, amount);

        return success;
    }

    function createSubscriptionIfSignatureMatch(uint8 v, bytes32 r, bytes32 s, address sender, uint256 deadline, string memory subscriptionId, uint192 tokens) public isValidSubscription(subscriptionId) {
        require(block.timestamp < deadline, "signed transaction expired");
        uint256 chainId;
        assembly {
            chainId := chainId
        }
        bytes32 eip712DomainHash = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("PaymentContract")),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
        bytes32 hashStruct = keccak256(
            abi.encode(
                keccak256("Payment(address sender,string subscriptionId,uint192 tokens,uint deadline)"),
                sender,
                subscriptionId,
                tokens,
                deadline
            )
        );
        bytes32 hash = keccak256(abi.encodePacked("\x19\x01", eip712DomainHash, hashStruct));
        address signer = ecrecover(hash, v, r, s);
        require(signer == sender, "CreateSubscription: invalid signature");
        require(signer != address(0), "ECDSA: invalid signature");

        _createSubscription(subscriptionId, tokens);
    }

    function _createSubscription(string memory subscriptionId, uint192 tokens) internal {
        address tokenAddress = address(_token);

        _subscriptions[subscriptionId] = Subscription(
            msg.sender, uint64(block.timestamp), tokens, tokenAddress
        );

        _token.transferFrom(msg.sender, address(this), tokens);

        emit SubscriptionPaid(subscriptionId, uint64(block.timestamp), msg.sender, tokens, tokenAddress);
    }

    function getSubscription(string memory subscriptionId) public view returns (address, uint64, uint192, address){
        return (_subscriptions[subscriptionId].owner, _subscriptions[subscriptionId].timestamp, _subscriptions[subscriptionId].tokens, address(_token));
    }

    function owner() external view returns (address){
        return _owner;
    }

    function token() external view returns (address){
        return address(_token);
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
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
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}