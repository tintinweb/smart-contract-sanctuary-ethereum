/**
 *Submitted for verification at Etherscan.io on 2022-12-30
*/

// File: contracts/IStargateReceiver.sol


pragma solidity ^0.8.4;

interface IStargateReceiver {
    function sgReceive(
        uint16 _chainId,
        bytes memory _srcAddress,
        uint256 _nonce,
        address _token,
        uint256 amountLD,
        bytes memory payload
    ) external;
}
// File: contracts/IStargateRouter.sol



pragma solidity ^0.8.4;
pragma abicoder v2;

interface IStargateRouter {
    struct lzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

    function addLiquidity(
        uint256 _poolId,
        uint256 _amountLD,
        address _to
    ) external;

    function swap(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    ) external payable;

    function redeemRemote(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        uint256 _minAmountLD,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function instantRedeemLocal(
        uint16 _srcPoolId,
        uint256 _amountLP,
        address _to
    ) external returns (uint256);

    function redeemLocal(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function sendCredits(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress
    ) external payable;

    function quoteLayerZeroFee(
        uint16 _dstChainId,
        uint8 _functionType,
        bytes calldata _toAddress,
        bytes calldata _transferAndCallPayload,
        lzTxObj memory _lzTxParams
    ) external view returns (uint256, uint256);
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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: contracts/SmartRouter.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;





interface IERC20 {
    function balanceOf(address owner) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface SmartFinanceSwap {
    function receivePayload (
        uint256 amountLD,
        bytes memory payload
    ) external;
}

contract SmartRouter is IStargateReceiver, Ownable, Pausable {

    address public stargateRouter;
    address payable public smartFinanceSwap;

    mapping(uint256 => address) public poolToken;

    struct SendObj {
        uint16 dstChainId;
        uint256 srcPoolId;
        uint256 dstPoolId;
        uint256 amount;
    }

    event CrossChainMessageSent (
        uint16 dstChainId,
        address srcToken,
        uint256 amount,
        uint256 dstPoolId
    );

    event CrossChainMessageReceived (
        uint16 srcChainId,
        bytes srcAddress, 
        uint nonce,
        address token,
        uint256 amount,
        bytes payload
    );

    constructor(
        address _stargateRouter,
        address payable _smartFinanceSwap
    ) {
        require(_stargateRouter != address(0) && _smartFinanceSwap != address(0),"Invalid Addresss");
        stargateRouter = _stargateRouter;
        smartFinanceSwap = _smartFinanceSwap;
    }

    function sendSwap(
        address initiator,
        bytes memory stargateData,
        bytes memory _payload,
        uint256 _amount
    ) external payable {
        require(msg.sender == smartFinanceSwap,"Only SmartFinanceSwap");
        require(msg.value > 0, "Cross-chain requires a msg.value to pay crosschain message.");
        
        // Decode Stargate Data
        (
            uint16 _dstChainId,
            address _dstRouter,
            uint256 _srcPoolId,
            uint256 _dstPoolId,
            uint256 _gasForSwap
        ) = abi.decode(stargateData, (uint16, address, uint256, uint256, uint256));

        // Approve Tokens
        IERC20(poolToken[_srcPoolId]).approve(stargateRouter, _amount);

        // Stargate's Router - Swap Function
        this.send{value: msg.value}(
            SendObj(_dstChainId, _srcPoolId, _dstPoolId, _amount), 
            IStargateRouter.lzTxObj(_gasForSwap,0,"0x"), 
            abi.encodePacked(_dstRouter),
            _payload,
            initiator
        );
    }

    function send(
        SendObj memory sendObj,
        IStargateRouter.lzTxObj memory gasForSwap,
        bytes memory to,
        bytes memory payload,
        address initiator
    ) external payable {
        require(msg.sender == address(this));

        IStargateRouter(stargateRouter).swap{value: msg.value}(
            sendObj.dstChainId, 
            sendObj.srcPoolId, 
            sendObj.dstPoolId, 
            payable(initiator), 
            sendObj.amount, 
            0, 
            gasForSwap, 
            to,
            payload
        );

        emit CrossChainMessageSent(
            sendObj.dstChainId, 
            poolToken[sendObj.srcPoolId], 
            sendObj.amount, 
            sendObj.dstPoolId
        );
    }

    function sgReceive(
        uint16 _chainId, 
        bytes memory _srcAddress, 
        uint _nonce, 
        address _token, 
        uint amountLD, 
        bytes memory _payload
    ) override external {
        require(msg.sender == address(stargateRouter), "Only stargate router can call sgReceive!");
        emit CrossChainMessageReceived(
            _chainId, 
            _srcAddress,
            _nonce,
            _token, 
            amountLD,
            _payload
        );

        // Transfer Tokens
        IERC20(_token).transfer(smartFinanceSwap, amountLD);

        // Call the Swap
        SmartFinanceSwap(smartFinanceSwap).receivePayload(amountLD, _payload);
    }

    receive() external payable {}

    function withdraw(address _token) onlyOwner external {
        require(_token != address(0), "Invalid Address");
        IERC20(_token).transfer(msg.sender, IERC20(_token).balanceOf(address(this)));
    }

    function withdrawETH() public onlyOwner {
        address payable to = payable(msg.sender);
        to.transfer(address(this).balance);
    }

    function configurePoolToken(
        uint256 poolId,
        address token
    ) public onlyOwner {
        poolToken[poolId] = token;
    }

    function configureRouter(
        address router
    ) public onlyOwner {
        stargateRouter = router;
    }

    function configureSmartFinanceSwap(
        address payable swap
    ) public onlyOwner {
        smartFinanceSwap = swap;
    }
}