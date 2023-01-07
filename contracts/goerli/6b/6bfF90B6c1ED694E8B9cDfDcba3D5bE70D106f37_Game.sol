/**
 *Submitted for verification at Etherscan.io on 2023-01-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

contract Game is Ownable {
    mapping(address => uint256) private _depositETHAmount;
    mapping(address => mapping(address => uint256)) private _depositERC20Amount;

    event DepositETH(address depositor, uint256 amount);
    event DepositERC20(address depositor, address tokenAddress, uint256 amount);
    event WithdrawETH(address withdrawer, address receiveAddress, uint256 amount);
    event WithdrawERC20(address withdrawer, address receiveAddress, address tokenAddress, uint256 amount);

    constructor() {}

    function depositETHAmount(address _depositor) external view returns(uint256 amount) {
        return _depositETHAmount[_depositor];
    }

    function depositERC20Amount(address _depositor, address _tokenAddress) external view returns(uint256 amount) {
        return _depositERC20Amount[_depositor][_tokenAddress];
    }

    function depositETH() payable external {
        require(msg.value > 0, "depositETH: amount is 0");
        _depositETHAmount[msg.sender] += msg.value;
        emit DepositETH(msg.sender, msg.value);
    }

    function depositERC20(address _tokenAddress, uint256 _amount) external {
        require(_tokenAddress != address(0), "depositERC20: _tokenAddress is wrong");
        require(_amount > 0, "depositERC20: amount is 0");
        IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount);
        _depositERC20Amount[msg.sender][_tokenAddress] += _amount;
        emit DepositERC20(msg.sender, _tokenAddress, _amount);
    }

    function withdrawETH(address _receiveAddress, uint256 _amount) external {
        require(_receiveAddress != address(0), "withdrawETH: _receiveAddress is wrong");
        require(_amount > 0, "withdrawETH: amount is 0");
        require(_depositETHAmount[msg.sender] >= _amount, "withdrawETH: Not enough");
        _depositETHAmount[msg.sender] -= _amount;
        (bool isSuccess, ) = payable(_receiveAddress).call{value: _amount}("");
        require(isSuccess, "withdrawETH: withdraw ETH failed");
        emit WithdrawETH(msg.sender, _receiveAddress, _amount);
    }

    function withdrawERC20(address _receiveAddress, address _tokenAddress, uint256 _amount) external {
        require(_receiveAddress != address(0), "withdrawERC20: _receiveAddress is wrong");
        require(_tokenAddress != address(0), "withdrawERC20: _tokenAddress is wrong");
        require(_amount > 0, "withdrawERC20: amount is 0");
        require(_depositERC20Amount[msg.sender][_tokenAddress] >= _amount, "withdrawERC20: Not enough");
        _depositERC20Amount[msg.sender][_tokenAddress] -= _amount;
        IERC20(_tokenAddress).transfer(_receiveAddress, _amount);
        emit WithdrawERC20(msg.sender, _receiveAddress, _tokenAddress, _amount);
    }
}