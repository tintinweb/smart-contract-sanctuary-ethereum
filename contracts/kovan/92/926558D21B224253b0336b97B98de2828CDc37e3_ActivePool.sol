/**
 *Submitted for verification at Etherscan.io on 2022-05-10
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

// Part: IActivePool

interface IActivePool {
    // --- Events ---
    event BorrowerOpsAddressChanged(address _newBorrowerOpsAddress);
    event VaultManagerAddressChanged(address _newVaultManagerAddress);
    event ActivePoolUSDCDebtUpdated(uint _USDCDebt);
    event ActivePooloMATICBalanceUpdated(uint oMATIC);
    event SentoMATICActiveVault(address _to,uint _amount );
    event ActivePoolReceivedMATIC(uint _MATIC);
    event BorrowersRewardsPoolAddressChanged(address _borrowersRewardsPoolAddress);
    event StabilityPoolAddressChanged(address _stabilityPoolAddress);
    event oMATICSent(address _to, uint _amount);

    // --- Functions ---
    function sendoMATIC(address _account, uint _amount) external;
    function receiveoMATIC(uint new_coll) external;
    function getoMATIC() external view returns (uint);
    function getUSDCDebt() external view returns (uint);
    function increaseUSDCDebt(uint _amount) external;
    function decreaseUSDCDebt(uint _amount) external;


}

// Part: IBorrowersRewardsPool

interface IBorrowersRewardsPool  {
    // --- Events ---
    event VaultManagerAddressChanged(address _newVaultManagerAddress);
    event BorrowersRewardsPoolborrowersoMATICRewardsBalanceUpdated(uint _borrowersoMATICRewards);
    event BorrowersRewardsPoolborrowersoMATICRewardsBalanceUpdated_before(uint _borrowersoMATICRewards);
    event borrowersoMATICRewardsSent(address activePool, uint _amount);
    event BorrowersRewardsPooloMATICBalanceUpdated(uint _OrumwithdrawalborrowersoMATICRewards);
    event  ActivePoolAddressChanged(address _activePoolAddress);

    // --- Functions ---
    function sendborrowersoMATICRewardsToActivePool(uint _amount) external;
    function receiveoMATICBorrowersRewardsPool(uint new_coll) external;
    function getBorrowersoMATICRewards() external view returns (uint);

    function setAddresses(
        address _vaultManagerAddress,
        address _activePoolAddress,
        address _oMATICTokenAddress,
        address _rewardsPoolAddress
    ) external;
}

// Part: ICollateralPool

interface ICollateralPool {
    // --- Events ---
    event oMATICTokenAddressChanged(address _oMATICTokenAddress);
    event OMATICTokenMintedTo(address _account, uint _amount);
    event oMaticSwappedToMatic(address _from, address _to,uint _amount);
    event BufferRatioUpdated(uint _buffer, uint staking);

    // --- Functions ---
    function swapoMATICtoMATIC(uint _amount) external payable;
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

// Part: IOrumRevenue

interface IOrumRevenue {
    // --- Events ---
    event CommitAdmin(address admin);
    event ApplyAdmin(address admin);
    event ToggleAllowCheckpointToken(bool toggleFlag);
    event Claimed(address indexed recipient, uint amount, uint claimEpoch, uint maxEpoch);

    // --- Functions ---
    function checkpoint_token() external;

    // function checkpointToken() external;
    // function veForAt(address _user, uint _timestamp) external view returns (uint);
    // function checkpointTotalSupply() external;
    // function claimable(address _addr) external view returns (uint);
    // function applyAdmin() external;
    // function commitAdmin(address _addr) external;
    // function toggleAllowCheckpointToken() external;
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

// Part: IoMATICToken

interface IoMATICToken is IERC20, IERC2612 { 
    
    // --- Events ---


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

// File: ActivePool.sol

/*
 * The Active Pool holds the oMATIC collateral and USDC debt (but not USDC tokens) for all active vaults.
 *
 * When a vault is liquidated, it's oMATIC and USDC debt are transferred from the Active Pool, to either the
 * Stability Pool, the Default Pool, or both, depending on the liquidation conditions.
 *
 */
contract ActivePool is Ownable, CheckContract, IActivePool {

    string constant public NAME = "ActivePool";

    address public borrowerOpsAddress;
    address public vaultManagerAddress;
    address public stabilityPoolAddress;
    uint256 internal oMATIC;  // deposited oMATIC tracker
    uint256 internal USDCDebt;
    address public collateralPoolAddress;
    address public borrowerRewardsPoolAddress;

    IoMATICToken public oMATICToken;
    ICollateralPool public collateralPool;
    IBorrowersRewardsPool public borrowersRewardsPool;
    IOrumRevenue public orumRevenue;

    address public borrowersRewardsPoolAddress;

    // --- Contract setters ---

    function setAddresses(
        address _borrowerOpsAddress,
        address _vaultManagerAddress,
        address _stabilityPoolAddress,
        address _oMATICTokenAddress,
        address _collateralPoolAddress,
        address _borrowersRewardsPoolAddress,
        address _orumRevenueAddress
    )
        external
        onlyOwner
    {
        checkContract(_borrowerOpsAddress);
        checkContract(_vaultManagerAddress);
        checkContract(_stabilityPoolAddress);
        checkContract(_oMATICTokenAddress);
        checkContract(_collateralPoolAddress);
        checkContract(_borrowersRewardsPoolAddress);

        borrowerOpsAddress = _borrowerOpsAddress;
        vaultManagerAddress = _vaultManagerAddress;
        stabilityPoolAddress = _stabilityPoolAddress;
        oMATICToken = IoMATICToken(_oMATICTokenAddress);
        collateralPool = ICollateralPool(_collateralPoolAddress);
        borrowersRewardsPool = IBorrowersRewardsPool(_borrowersRewardsPoolAddress);
        borrowerRewardsPoolAddress = _borrowersRewardsPoolAddress;
        orumRevenue = IOrumRevenue(_orumRevenueAddress);

        emit BorrowerOpsAddressChanged(_borrowerOpsAddress);
        emit VaultManagerAddressChanged(_vaultManagerAddress);
        emit StabilityPoolAddressChanged(_stabilityPoolAddress);
        emit BorrowersRewardsPoolAddressChanged(_borrowersRewardsPoolAddress);
    }

    // --- Getters for public variables. Required by IPool interface ---

    /*
    * Returns the oMATIC state variable.
    *
    *Not necessarily equal to the the contract's raw oMATIC balance - oMATIC can be forcibly sent to contracts.
    */
    function getoMATIC() external view override returns (uint) {
        return oMATIC;
    }

    function getUSDCDebt() external view override returns (uint) {
        return USDCDebt;
    }

    // --- Pool functionality ---

    function sendoMATIC(address _to, uint _amount) external override { 
        _requireCallerIsBOorVaultMorSP();
        oMATIC -= _amount;
        emit ActivePooloMATICBalanceUpdated(oMATIC);
        emit oMATICSent(_to, _amount);

        if (_amount>0){
            bool sucess = oMATICToken.transfer(payable(_to), _amount);
            require(sucess, "ActivePool sendMATIC: sending oMATIC failed");
            emit SentoMATICActiveVault(_to,_amount );
        }
        if (_to == address(orumRevenue)) {
            orumRevenue.checkpoint_token();
        }
    }

    function increaseUSDCDebt(uint _amount) external override {
        _requireCallerIsBOorVaultM();
        USDCDebt  += _amount;
        emit ActivePoolUSDCDebtUpdated(USDCDebt);
    }

    function decreaseUSDCDebt(uint _amount) external override {
        _requireCallerIsBOorVaultMorSP();
        USDCDebt -= _amount;
        emit ActivePoolUSDCDebtUpdated(USDCDebt);
    }

    // --- 'require' functions ---

    function _requireCallerIsBorrowerOpsOrBRP() internal view {
        require(
            msg.sender == borrowerOpsAddress ||
            msg.sender == borrowerRewardsPoolAddress,
            "ActivePool: Caller is not Borrower ops or Borrower rewards pool");
    }

    function _requireCallerIsBOorVaultMorSP() internal view {
        require(
            msg.sender == borrowerOpsAddress ||
            msg.sender == vaultManagerAddress ||
            msg.sender == stabilityPoolAddress,
            "ActivePool: Caller is neither BorrowerOps norVaultManager nor StabilityPool");
    }

    function _requireCallerIsBOorVaultM() internal view {
        require(
            msg.sender == borrowerOpsAddress ||
            msg.sender == vaultManagerAddress,
            "ActivePool: Caller is neither BorrowerOps nor VaultManager");
    }

    // --- Fallback function ---

    function receiveoMATIC(uint new_coll) external override {
        _requireCallerIsBorrowerOpsOrBRP();
        oMATIC += new_coll;
        emit ActivePooloMATICBalanceUpdated(oMATIC);
    }
}