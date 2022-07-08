// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IAvenciaERC20 is IERC20 {
    function burn(uint256 amount) external;

    function mint(address to, uint256 amount) external;
}

contract Bridge is Ownable {
    IAvenciaERC20 _token;

    uint256 public minETHToCross = 1 * 10**12; // 0.000001 ETH
    uint256 public minTokenToCross = 1 * 10**18; // 1 Token
    uint256 chainId;
    mapping(uint256 => bool) supportedChainIds;

    event StartedTransferCrossChain(
        uint256,
        uint256,
        address,
        address,
        uint256
    );
    event BurntBridgeToken(uint256, uint256, address, address, uint256);
    event MintedBridgeToken(uint256, uint256, address, address, uint256);
    event FinalizedTransferCrossChain(
        uint256,
        uint256,
        address,
        address,
        uint256
    );
    event RescueWithdrewETH(address, uint256);
    event RescueWithdrewToken(address, uint256);

    constructor(address token_, uint256 chainId_) {
        _token = IAvenciaERC20(token_);
        chainId = chainId_;
        supportedChainIds[chainId_] = true;
    }

    function startTransferCrossChain(
        uint256 toChainId,
        address to,
        uint256 amount
    ) public payable {
        require(supportedChainIds[toChainId], "ToChain is not supported.");

        require(
            amount >= minTokenToCross,
            "Token amount should be greater than minimum amount"
        );
        require(
            msg.value >= minETHToCross,
            "ETH should be greater than minimum amount"
        );

        _token.transferFrom(msg.sender, address(this), amount);

        emit StartedTransferCrossChain(
            chainId,
            toChainId,
            msg.sender,
            to,
            amount
        );
    }

    function burnBridgeToken(
        uint256 fromChainId,
        uint256 toChainId,
        address from,
        address to,
        uint256 amount
    ) public onlyOwner {
        require(fromChainId == chainId, "Invalid fromChain.");
        require(supportedChainIds[toChainId], "ToChain is not supported.");

        require(amount > 0, "Amount should not be zero");

        _token.burn(amount);

        emit BurntBridgeToken(fromChainId, toChainId, from, to, amount);
    }

    function mintBridgeToken(
        uint256 fromChainId,
        uint256 toChainId,
        address from,
        address to,
        uint256 amount
    ) public onlyOwner {
        require(toChainId == chainId, "Invalid toChain.");
        require(supportedChainIds[fromChainId], "FromChain is not supported.");

        require(amount > 0, "Amount should not be zero");

        _token.mint(address(this), amount);

        emit MintedBridgeToken(fromChainId, toChainId, from, to, amount);
    }

    function finalizeTransferCrossChain(
        uint256 fromChainId,
        uint256 toChainId,
        address from,
        address to,
        uint256 amount
    ) public onlyOwner {
        require(toChainId == chainId, "Invalid toChain.");
        require(supportedChainIds[fromChainId], "FromChain is not supported.");

        require(amount > 0, "Amount should not be zero");

        _token.transfer(to, amount);

        emit FinalizedTransferCrossChain(
            fromChainId,
            toChainId,
            from,
            to,
            amount
        );
    }

    function rescueWithdrawETH(uint256 amount) public onlyOwner {
        require(amount > 0, "Amount should not be zero");

        payable(owner()).transfer(amount);

        emit RescueWithdrewETH(owner(), amount);
    }

    function rescueWithdrawToken(uint256 amount) public onlyOwner {
        require(amount > 0, "Amount should not be zero");

        _token.transfer(owner(), amount);

        emit RescueWithdrewToken(owner(), amount);
    }

    function setMinETHToCross(uint256 _minETHToCross) public onlyOwner {
        minETHToCross = _minETHToCross;
    }

    function getMinETHToCross() public view returns (uint256) {
        return minETHToCross;
    }

    function setMinTokenToCross(uint256 _minTokenToCross) public onlyOwner {
        minTokenToCross = _minTokenToCross;
    }

    function getMinTokenToCross() public view returns (uint256) {
        return minTokenToCross;
    }

    function addSupportedChainId(uint256 _chainId) public onlyOwner {
        require(_chainId != chainId);
        supportedChainIds[_chainId] = true;
    }

    function deleteSupportedChainId(uint256 _chainId) public onlyOwner {
        require(_chainId != chainId);
        supportedChainIds[_chainId] = false;
    }

    function getIsSupportedChainId(uint256 _chainId)
        public
        view
        returns (bool)
    {
        return supportedChainIds[_chainId];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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