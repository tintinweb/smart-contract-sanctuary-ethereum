/**
 *Submitted for verification at Etherscan.io on 2023-01-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

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


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

contract MarkUp is Ownable { 
    
    // Variables of fee
    uint public feeERC20EOA = 300;
    uint public feeERC20Contract = 300;
    uint public feeETHEOA = 300;
    uint public feeETHContract = 300;
    // ERC20 list for tokens from the white list
    mapping(uint => IERC20) public ERC20;

    // Events for a transaction history
    event transferETH(uint amount, address recipient, uint fee);
    event transferERC20(uint indexed tokenID, uint amount, address recipient, uint fee);

    // Chacks addresses is EOA or contract address
    function isContract(address _addr) private view returns (bool) {
        return _addr.code.length > 0;
    }

    // Counting an percentage by basis points
    function calculate(uint256 amount, uint256 bps) private pure returns (uint256) {
        require((amount * bps) >= 10000);
        return amount * bps / 10000;
    }

    // Transfer function for ETH
    function transferETHWithFee(address payable recipient) public payable {
        // A fee is EOA by default
        uint _fee = feeETHEOA;
        // Checks recipient address 
        if (isContract(recipient)) {
            _fee = feeETHContract;
        }
        // Counts amount fee and amount without fee
        uint _feeAmount = calculate(msg.value, _fee);
        uint _amountMinuseFee = msg.value - _feeAmount;
        // Transfers to recipient  amount minus the commission 
        recipient.transfer(_amountMinuseFee);
        // Event of transaction for the history
        emit transferETH(_amountMinuseFee, recipient, _feeAmount);
    }

    // Transfer function for ERC20 tokens
    function transferERC20WithFee(uint tokenID, address recipient, uint _amount) public {
        // A fee is EOA by default
        uint _fee = feeERC20EOA;
        // Checks recipient address 
        if (isContract(recipient)) {
            _fee = feeERC20Contract;
        }
        // Transfers full amount to contract 
        ERC20[tokenID].transferFrom(msg.sender, address(this), _amount);
        // Counts amount fee and amount without fee
        uint _feeAmount = calculate(_amount, _fee);
        uint _amountMinuseFee = _amount - _feeAmount;
        // Transfers to recipient  amount minus the commission 
        ERC20[tokenID].transfer(recipient, _amountMinuseFee);
        // Event of transaction for the history
        emit transferERC20(tokenID, _amountMinuseFee, recipient, _feeAmount);
    }

    // Admin functions
    function setERC20(uint _id, IERC20 _address) public onlyOwner {
        ERC20[_id] = _address; 
    }

    // Sets the commission for ERC tokens, an externally owned account and a contract address
    function setFeeERC(uint _feeEOA, uint _feeContract) public onlyOwner {
        feeERC20EOA = _feeEOA; 
        feeERC20Contract = _feeContract;
    }
    // Sets the commission for ETH, an externally owned account and a contract address
    function setFeeETH(uint _feeEOA, uint _feeContract) public onlyOwner {
        feeETHEOA = _feeEOA;
        feeETHContract = _feeContract;
    }
}