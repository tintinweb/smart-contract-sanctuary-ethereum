pragma solidity 0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract MultiSender is Ownable {
    address operator;
    mapping(uint256 => bool) public nonces;
    bytes32 public immutable domainSeparator;
    uint256 public fee = 20;
    
    event Multisended(uint256 total, address tokenAddress);
    event ClaimedTokens(address token, address owner, uint256 balance);
    event MultisendedTokenWithSignature(address[] _contributors, uint256[] _balances, uint256 _total, address _token);
    event MultisendedEthWithSignature(address[] _contributors, uint256[] _balances, uint256 _total);

    modifier hasTokenFee(address _token, uint256 _total) {
        uint256 toDevFee = _total * fee / 1000;
        require(IERC20(_token).allowance(msg.sender, address(this)) >= _total + toDevFee, "Not enough tokens allowed");
        IERC20(_token).transferFrom(msg.sender, address(this), toDevFee);
        _;
    }

    modifier hasEtherFee(uint256 _total) {
        uint256 toDevFee = _total * fee / 1000;
        require(msg.value >= _total + toDevFee, "Not enough ether sended");
        _;
    }

    constructor (address _operator) {
        operator = _operator;

        domainSeparator = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes('MultiSender')),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }
    
    function changeFee(uint256 _newFee) public onlyOwner {
        fee = _newFee; 
    }

    function multisendToken(
        address _token, 
        address[] calldata _contributors, 
        uint256[] calldata  _balances, 
        uint256 _total
    ) hasTokenFee(_token, _total) external {
        for (uint256 i = 0; i < _contributors.length; i++)
            IERC20(_token).transferFrom(msg.sender, _contributors[i], _balances[i]);
        emit Multisended(_total, _token);
    }
    
    function multisendEther(
        address[] calldata _contributors, 
        uint256[] calldata  _balances, 
        uint256 _total
    ) hasEtherFee(_total) external payable {
        for (uint256 i = 0; i < _contributors.length; i++)
            payable(_contributors[i]).transfer(_balances[i]);
        emit Multisended(_total, address(0));
    }

    function multisendTokenWithSignature(
        address _token, 
        address[] calldata _contributors, 
        uint256[] calldata  _balances, 
        uint256 _total
    ) hasTokenFee(_token, _total) external {
        IERC20(_token).approve(address(this), _total);
        emit MultisendedTokenWithSignature(_contributors, _balances, _total, _token);
    }

    function multisendEtherWithSignature(
        address[] calldata _contributors,
        uint256[] calldata  _balances,
        uint256 _total
    ) hasEtherFee(_total) external payable {
        emit MultisendedEthWithSignature(_contributors, _balances, _total);
    }

    function claimWithSignature(
        address _token,
        uint256 _amount,
        uint256 _nonce,
        address from,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(!nonces[_nonce], "Request already processed");

        bytes32 permitDigest = getPermitDigest(
            domainSeparator,
            _token,
            msg.sender,
            _amount,
            _nonce
        );

        address signer = ecrecover(permitDigest, v, r, s);
        require(signer == operator, "Invalid signature");

        nonces[_nonce] = true;

        if (address(_token) == address(0)) {
            payable(msg.sender).transfer(_amount);
        } else {
            IERC20(_token).transferFrom(from, msg.sender, _amount);
        }
        
    }

    function claimTokens(address _token) public onlyOwner {
        if (_token == address(0x0)) {
            payable(owner()).transfer(address(this).balance);
            return;
        }
        uint256 balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(owner(), balance);
        emit ClaimedTokens(_token, owner(), balance);
    }

    function getPermitDigest(
        bytes32 _domainSeparator,
        address _token,
        address _to,
        uint256 _amount,
        uint256 _nonce
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    uint16(0x1901),
                    _domainSeparator,
                    keccak256(
                        abi.encode(
                            keccak256(
                                "Permit(address token,address spender,uint256 value,uint256 nonce)"
                            ),
                            _token,
                            _to,
                            _amount,
                            _nonce
                        )
                    )
                )
            );
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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