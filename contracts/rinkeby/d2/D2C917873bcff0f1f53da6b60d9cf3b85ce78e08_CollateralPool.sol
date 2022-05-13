/**
 *Submitted for verification at Etherscan.io on 2022-05-13
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;



// Part: CheckContract

contract CheckContract {
    /**
     * Check that the account is an already deployed non-destroyed contract.
     */
    function checkContract(address _account) internal view {
        require(_account != address(0), "Account cannot be zero address");

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(_account) }
        require(size > 0, "Account code size cannot be zero");
    }
}

// Part: IBufferPool

interface IBufferPool {
    // --- Events ---
    event BufferPoolETHUpdated(uint deposit);
    event BufferPoolUSDCUpdated(uint amount);

    event CollateralPoolAddress(address _collateralPoolAddress);
    event ActivePoolAddress(address _activePoolAddress);
    event LendingPoolAddress(address _lendingPoolAddress);
    event UsdcTokenAddress(address _usdcTokenAddress); 

    // --- Functions ---
    function sendETH(address _receiver, uint _amount) external payable returns (bool);
    function receiveUSDC(uint _amount) external ;
    function sendUSDC(address _receiver, uint _amount) external payable returns (bool);
    function sendETHToExteranlWallet(uint _amount) external payable returns (bool);
    function sendUSDCToExteranlWallet(uint _amount) external payable  returns (bool);
    function sendUSDCFromExteranlWallet(uint _amount) external payable returns (bool);
}

// Part: ICollateralPool

interface ICollateralPool {
    // --- Events ---
    event oETHTokenAddressChanged(address _oETHTokenAddress);
    event BufferPoolAddressChanged(address _bufferPoolAddress);
    event ExternalStakingAddressChanged(address _address);

    event OETHTokenMintedTo(address _account, uint _amount);
    event oethSwappedToeth(address _from, address _to,uint _amount);
    event BufferRatioUpdated(uint _buffer, uint staking);

    // --- Functions ---
    function swapoETHtoETH(uint _amount) external payable;
}

// Part: IERC20

/**
 * Based on the OpenZeppelin IER20 interface:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol
 *
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
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    
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

// Part: IERC2612

/**
 * @dev Interface of the ERC2612 standard as defined in the EIP.
 *
 * Adds the {permit} method, which can be used to change one's
 * {IERC20-allowance} without having to send a transaction, by signing a
 * message. This allows users to spend tokens without having to hold Ether.
 *
 * See https://eips.ethereum.org/EIPS/eip-2612.
 * 
 * Code adapted from https://github.com/OpenZeppelin/openzeppelin-contracts/pull/2237/
 */
interface IERC2612 {
    /**
     * @dev Sets `amount` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(address owner, address spender, uint256 amount, 
                    uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    
    /**
     * @dev Returns the current ERC2612 nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases `owner`'s nonce by one. This
     * prevents a signature from being used multiple times.
     *
     * `owner` can limit the time a Permit is valid for by setting `deadline` to 
     * a value in the near future. The deadline argument can be set to uint(-1) to 
     * create Permits that effectively never expire.
     */
    function nonces(address owner) external view returns (uint256);
    
    function version() external view returns (string memory);
    function permitTypeHash() external view returns (bytes32);
    function domainSeparator() external view returns (bytes32);
}

// Part: IStakingInterface

interface IStakingInterface  {
    // --- Events ---

    event UsdcTokenAddressChanged(address _usdcTokenAddress);
    event LendingPoolAddressChanged(address _lendingPoolAddress);


    // --- Functions ---

    function getTotalUSDC() external view returns (uint);

    function USDCWitdrawFromLendingPool(uint _amount) external;

    function USDCProvidedToLendingPool(uint _amount) external;
    
    // --- ETH Functions ---

    function getTotalETHDeposited() external returns (uint);

}

// Part: OpenZeppelin/[email protected]/Context

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

// Part: IoETHToken

interface IoETHToken is IERC20, IERC2612 { 
    
    // --- Events ---

    event BorrowerOpsAddressChanged(address _borrowerOpsAddress);
    event ActivePoolAddressChanged(address _activePoolAddress);
    event CollateralPoolAddressChanged(address _collateralPoolAddress);


    // --- Functions ---

    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;

    function sendToPool(address _sender,  address poolAddress, uint256 _amount) external;

    function returnFromPool(address poolAddress, address user, uint256 _amount ) external;
}

// Part: OpenZeppelin/[email protected]/Ownable

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

// File: CollateralPool.sol

/*
* Pool for swaping ETH and oETH
*/

contract CollateralPool is Ownable, CheckContract, ICollateralPool {
    uint256 public ETH_depoisted;
    uint256 public oETH_minted;

    uint256 DECIMAL_PRECISION = 1e18;

    struct BufferRatio {
        uint Staking;
        uint Buffer;
    }

    BufferRatio public bufferRatio;
    IoETHToken public oETHToken;
    IBufferPool bufferPool;
    IStakingInterface stakingInterface;

    address externalStakingAddress;


    function setAddresses(
        address _oETHTokenAddress,
        address _bufferPoolAddress
    )
        external
        onlyOwner
    {
        checkContract(_oETHTokenAddress);
        checkContract(_bufferPoolAddress);

        oETHToken = IoETHToken(_oETHTokenAddress);
        bufferPool = IBufferPool(_bufferPoolAddress);

        emit oETHTokenAddressChanged(_oETHTokenAddress);
        emit BufferPoolAddressChanged(_bufferPoolAddress);
    }

    function setExternalStaker(address _address) external onlyOwner {
        stakingInterface = IStakingInterface(_address);
        externalStakingAddress = _address;

        checkContract(_address);

        emit ExternalStakingAddressChanged(_address);
    }

    function setBuffer(uint _buffer, uint _staking) external onlyOwner {
        require((_buffer + _staking) == 100, "CollateralPool: Buffer ratios provided is invalid");

        bufferRatio.Buffer = _buffer;
        bufferRatio.Staking = _staking;
        emit BufferRatioUpdated(_buffer, _staking);
    }

    function _transferDepositedETH(uint _amount) internal {
        uint stakingAmount = (_amount * bufferRatio.Staking)/100;
        uint bufferAmount = (_amount * bufferRatio.Buffer)/100;

        (bool success, ) = payable(address(bufferPool)).call{ value: bufferAmount }("");
        require(success, "Collateral pool: eth transfer to buffer Pool failed");

        (success, ) = payable(externalStakingAddress).call{ value: stakingAmount }("");
        require(success, "Collateral pool: eth transfer to external staking address failed");
    }

    function swapoETHtoETH(uint _amount) external override payable {
        require( oETHToken.balanceOf(msg.sender) >= _amount );
        require(address(bufferPool).balance >= _amount, "not enough eth available in buffer pool");
        require(ETH_depoisted >= _amount, "cannot swap more oETH than deposited ETH");

        ETH_depoisted -= _amount;
        oETH_minted -= _amount;

        oETHToken.burn(msg.sender, _amount);

        bool success = bufferPool.sendETH(msg.sender, _amount);
        require(success, "Collateral pool: ETH transfer failed from BufferPool");
        emit oethSwappedToeth(address(this), msg.sender, _amount);
    }

    receive() external payable {
        ETH_depoisted += msg.value;
        oETH_minted += msg.value;

        oETHToken.mint(msg.sender, msg.value);
        _transferDepositedETH(msg.value);
        emit OETHTokenMintedTo(msg.sender, msg.value);
    }
}