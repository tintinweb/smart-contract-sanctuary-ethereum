// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IKonduxERC20.sol";
import "./types/AccessControlled.sol";

/**
 * @title Treasury
 * @dev This contract handles deposits and withdrawals of tokens and Ether.
 */
contract Treasury is AccessControlled {

    /* ========== EVENTS ========== */

    event Deposit(address indexed token, uint256 amount);
    event DepositEther(uint256 amount);
    event EtherDeposit(uint256 amount);
    event Withdrawal(address indexed token, uint256 amount);
    event EtherWithdrawal(address to, uint256 amount);

    /* ========== DATA STRUCTURES ========== */

    enum STATUS {
        RESERVEDEPOSITOR,
        RESERVESPENDER,
        RESERVETOKEN
    }

    /* ========== STATE VARIABLES ========== */

    string internal notAccepted = "Treasury: not accepted";
    string internal notApproved = "Treasury: not approved";
    string internal invalidToken = "Treasury: invalid token";

    mapping(STATUS => mapping(address => bool)) public permissions;
    mapping(address => bool) public isTokenApproved;
    
    address[] public approvedTokensList;
    uint256 public approvedTokensCount;

    address public stakingContract;

    /**
     * @dev Initializes the Treasury contract.
     * @param _authority The address of the authority contract.
     */
    constructor(address _authority) AccessControlled(IAuthority(_authority)) {
        approvedTokensCount = 0;
    }

    /**
     * @notice Allow approved address to deposit an asset for Kondux.
     * @dev Deposits a specified amount of the specified token.
     * @param _amount The amount of tokens to deposit.
     * @param _token The address of the token contract.
     */
    function deposit(
        uint256 _amount,
        address _token
    ) external {
        if (permissions[STATUS.RESERVETOKEN][_token]) {
            require(permissions[STATUS.RESERVEDEPOSITOR][msg.sender], notApproved);
        } else {
            revert(invalidToken);
        }

        IKonduxERC20(_token).transferFrom(tx.origin, address(this), _amount);
        // get allowance and increase it
        uint256 allowance = IKonduxERC20(_token).allowance(stakingContract, _token);
        IKonduxERC20(_token).approve(stakingContract, allowance + _amount);

        emit Deposit(_token, _amount);
    }

    /**
     * @notice Allow approved address to deposit Ether.
     * @dev Deposits Ether to the contract.
     */
    function depositEther () external payable {
        require(permissions[STATUS.RESERVEDEPOSITOR][msg.sender], notApproved);  
                
        emit DepositEther(msg.value);
    }

    /**
     * @notice Allow approved address to withdraw Kondux from reserves.
     * @dev Withdraws a specified amount of the specified token.
     * @param _amount The amount of tokens to withdraw.
     * @param _token The address of the token contract.
     */
    function withdraw(uint256 _amount, address _token) external {
        require(permissions[STATUS.RESERVETOKEN][_token], notAccepted); // Only reserves can be used for redemptions
        require(permissions[STATUS.RESERVESPENDER][msg.sender], notApproved);

        IKonduxERC20(_token).transfer(msg.sender,         _amount);

        emit Withdrawal(_token, _amount);
    }

    /**
     * @dev Receives Ether.
     */
    receive() external payable {
        emit EtherDeposit(msg.value);
    }

    /**
     * @dev Fallback function for receiving Ether.
     */
    fallback() external payable { 
        emit EtherDeposit(msg.value); 
    }
    
    /**
     * @notice Allow approved address to withdraw Ether.
     * @dev Withdraws a specified amount of Ether.
     * @param _amount The amount of Ether to withdraw.
     */
    function withdrawEther(uint _amount) external {
        require(permissions[STATUS.RESERVESPENDER][msg.sender], notApproved);
        require(payable(msg.sender).send(_amount));

        emit EtherWithdrawal(msg.sender, _amount);
    }

    /**
     * @dev Sets permissions for the specified address.
     * @param _status The status to set the permission for.
     * @param _address The address to set the permission for.
     * @param _permission The permission value to set.
     */
    function setPermission(
        STATUS _status,
        address _address,
        bool _permission
    ) public onlyGovernor {
        // Check if the address is non-zero
        require(_address != address(0), "Treasury Permission: zero address");
        permissions[_status][_address] = _permission;
        if (_status == STATUS.RESERVETOKEN) {
            isTokenApproved[_address] = _permission;
            if (_permission) {
                approvedTokensList.push(_address);
                approvedTokensCount++;                
            }
        }
    }

    /**
     * @dev Sets the staking contract address.
     * @param _stakingContract The address of the staking contract.
     */
    function setStakingContract(address _stakingContract) public onlyGovernor {
        // Check if the address is non-zero
        require(_stakingContract != address(0), "Treasury SetStakingContract: zero address");
        require(_stakingContract != stakingContract, "Treasury SetStakingContract: same address");
        
        stakingContract = _stakingContract;
    }

    /**
     * @dev Sets up the ERC20 token approval.
     * @param _token The address of the token contract.
     * @param _amount The amount to approve.
     */
    function erc20ApprovalSetup(address _token, uint256 _amount) public onlyGovernor {
        IKonduxERC20(_token).approve(stakingContract, _amount);
    }

    // Getters

    /**
     * @dev Returns the list of approved tokens.
     * @return An array of approved token addresses.
     */
    function getApprovedTokensList() public view returns (address[] memory) {
        return approvedTokensList;
    }

    /**
     * @dev Returns the count of approved tokens.
     * @return The number of approved tokens.
     */
    function getApprovedTokensCount() public view returns (uint256) {
        return approvedTokensCount;
    }

    /**
     * @dev Returns the approved token at the specified index.
     * @param _index The index of the approved token.
     * @return The address of the approved token at the given index.
     */
    function getApprovedToken(uint256 _index) public view returns (address) {
        return approvedTokensList[_index];
    }

    /**
     * @dev Returns the allowance of the approved token for the staking contract.
     * @param _token The address of the approved token.
     * @return The allowance of the approved token for the staking contract.
     */
    function getApprovedTokenAllowance(address _token) public view returns (uint256) {
        return IKonduxERC20(_token).allowance(stakingContract, _token);
    }

    /**
     * @dev Returns the balance of the approved token in the treasury.
     * @param _token The address of the approved token.
     * @return The balance of the approved token in the treasury.
     */
    function getApprovedTokenBalance(address _token) public view returns (uint256) {
        return IKonduxERC20(_token).balanceOf(address(this));
    }

    /**
     * @dev Returns the Ether balance of the treasury.
     * @return The Ether balance of the treasury.
     */
    function getEtherBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Returns the address of the staking contract.
     * @return The address of the staking contract.
     */
    function getStakingContract() public view returns (address) {
        return stakingContract;
    }

    /**
     * @dev Returns the allowance of the token for the staking contract.
     * @param _token The address of the token.
     * @return The allowance of the token for the staking contract.
     */
    function getStakingContractAllowance(address _token) public view returns (uint256) {
        return IKonduxERC20(_token).allowance(address(this), stakingContract);
    }

    /**
     * @dev Returns the balance of the token in the staking contract.
     * @param _token The address of the token.
     * @return The balance of the token in the staking contract.
     */
    function getStakingContractBalance(address _token) public view returns (uint256) {
        return IKonduxERC20(_token).balanceOf(stakingContract);
    }

    /**
     * @dev Returns the Ether balance of the staking contract.
     * @return The Ether balance of the staking contract.
     */
    function getStakingContractEtherBalance() public view returns (uint256) {
        return stakingContract.balance;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.9;

interface IAuthority {
    /* ========== EVENTS ========== */

    event GovernorPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event GuardianPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event PolicyPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event VaultPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event RolePushed(address indexed account, bytes32 _role);

    event GovernorPulled(address indexed from, address indexed to);
    event GuardianPulled(address indexed from, address indexed to);
    event PolicyPulled(address indexed from, address indexed to);
    event VaultPulled(address indexed from, address indexed to);

    /* ========== VIEW ========== */

    function governor() external view returns (address);

    function guardian() external view returns (address);

    function policy() external view returns (address);

    function vault() external view returns (address);

    function roles(address _addr) external view returns (bytes32);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IKonduxERC20 is IERC20 {
    function excludedFromFees(address) external view returns (bool);
    function tradingOpen() external view returns (bool);
    function taxSwapMin() external view returns (uint256);
    function taxSwapMax() external view returns (uint256);
    function _isLiqPool(address) external view returns (bool);
    function taxRateBuy() external view returns (uint8);
    function taxRateSell() external view returns (uint8);
    function antiBotEnabled() external view returns (bool);
    function excludedFromAntiBot(address) external view returns (bool);
    function _lastSwapBlock(address) external view returns (uint256);
    function taxWallet() external view returns (address);

    event TokensAirdropped(uint256 totalWallets, uint256 totalTokens);
    event TokensBurned(address indexed burnedByWallet, uint256 tokenAmount);
    event TaxWalletChanged(address newTaxWallet);
    event TaxRateChanged(uint8 newBuyTax, uint8 newSellTax);

    function initLP() external;
    function enableTrading() external;
    function burnTokens(uint256 amount) external;
    function enableAntiBot(bool isEnabled) external;
    function excludeFromAntiBot(address wallet, bool isExcluded) external;
    function excludeFromFees(address wallet, bool isExcluded) external;
    function adjustTaxRate(uint8 newBuyTax, uint8 newSellTax) external;
    function setTaxWallet(address newTaxWallet) external;
    function taxSwapSettings(uint32 minValue, uint32 minDivider, uint32 maxValue, uint32 maxDivider) external;

    function totalSupply() external view returns (uint256);
	function decimals() external view returns (uint8);
	function symbol() external view returns (string memory);
	function name() external view returns (string memory);
	function getOwner() external view returns (address);
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
	function allowance(address _owner, address spender) external view returns (uint256);
	function approve(address spender, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../interfaces/IAuthority.sol";

/// @dev Reasoning for this contract = modifiers literaly copy code
/// instead of pointing towards the logic to execute. Over many
/// functions this bloats contract size unnecessarily.
/// imho modifiers are a meme.
abstract contract AccessControlled {
    /* ========== EVENTS ========== */

    event AuthorityUpdated(IAuthority authority);

    /* ========== STATE VARIABLES ========== */

    IAuthority public authority;

    /* ========== Constructor ========== */

    constructor(IAuthority _authority) {
        require(address(_authority) != address(0), "Authority cannot be zero address");
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }

    /* ========== "MODIFIERS" ========== */

    modifier onlyGovernor {
        _onlyGovernor();
        _;
    }

    modifier onlyGuardian {
        _onlyGuardian();
        _;
    }

    modifier onlyPolicy {
        _onlyPolicy();
        _;
    }

    modifier onlyVault {
        _onlyVault();
        _;
    }

    modifier onlyGlobalRole(bytes32 _role){
        _onlyRole(_role);
        _;
    }

    /* ========== GOV ONLY ========== */

    function initializeAuthority(IAuthority _newAuthority) internal {
        require(authority == IAuthority(address(0)), "AUTHORITY_INITIALIZED");
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }

    function setAuthority(IAuthority _newAuthority) external {
        _onlyGovernor();
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }

    /* ========== INTERNAL CHECKS ========== */

    function _onlyGovernor() internal view {
        require(msg.sender == authority.governor(), "UNAUTHORIZED");
    }

    function _onlyGuardian() internal view {
        require(msg.sender == authority.guardian(), "UNAUTHORIZED");
    }

    function _onlyPolicy() internal view {
        require(msg.sender == authority.policy(), "UNAUTHORIZED");        
    }

    function _onlyVault() internal view {
        require(msg.sender == authority.vault(), "UNAUTHORIZED");                
    }

    function _onlyRole(bytes32 _role) internal view {
        require(authority.roles(msg.sender) == _role, "UNAUTHORIZED");
    }
  
}