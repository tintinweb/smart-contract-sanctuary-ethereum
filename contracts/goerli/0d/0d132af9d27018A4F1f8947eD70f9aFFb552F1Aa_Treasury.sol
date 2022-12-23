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
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IKonduxERC20 is IERC20 {
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./interfaces/IKonduxERC20.sol";
import "./types/AccessControlled.sol";

// import "hardhat/console.sol";

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
    mapping(address => bool) public isTokenApprooved;
    mapping(address => IKonduxERC20) public approvedTokens;

    address[] public approvedTokensList;
    uint256 public approvedTokensCount;

    address public stakingContract;

    /* ========== CONSTRUCTOR ========== */

    constructor(address _authority) AccessControlled(IAuthority(_authority)) {
        approvedTokensCount = 0;
    }


    /**
     * @notice allow approved address to deposit an asset for Kondux
     * @param _amount uint256
     * @param _token address
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

        // console.log(msg.sender);
        // console.log(tx.origin);
        IKonduxERC20(_token).transferFrom(tx.origin, address(this), _amount);
        IKonduxERC20(_token).increaseAllowance(stakingContract, _amount);
        uint256 allowance = IKonduxERC20(_token).allowance(address(this), stakingContract);
        // console.log("Allowance (deposit): %s", allowance);  

        emit Deposit(_token, _amount);
    }

    function depositEther () external payable {
        require(permissions[STATUS.RESERVEDEPOSITOR][msg.sender], notApproved);  
        // console.log("Deposit Ether: %s", msg.value);              
                
        emit DepositEther(msg.value);
    }

    /**
     * @notice allow approved address to withdraw Kondux from reserves
     * @param _amount uint256
     * @param _token address
     */
    function withdraw(uint256 _amount, address _token) external {
        require(permissions[STATUS.RESERVETOKEN][_token], notAccepted); // Only reserves can be used for redemptions
        require(permissions[STATUS.RESERVESPENDER][msg.sender], notApproved);

        IKonduxERC20(_token).transferFrom(address(this), msg.sender, _amount);

        emit Withdrawal(_token, _amount);
    }

    function withdrawTo(uint256 _amount, address _token, address _to) external  {
        require(permissions[STATUS.RESERVETOKEN][_token], notAccepted); // Only reserves can be used for redemptions
        require(permissions[STATUS.RESERVESPENDER][msg.sender], notApproved);

        // console.log("WithdrawTo: ", _to);
        // console.log("Msg.sender: ", msg.sender);
        // console.log("Tx.origin: ", tx.origin);
        uint256 allowance = IKonduxERC20(_token).allowance(address(this), msg.sender);
        // console.log("WithdrawTo Allowance: %s", allowance);
        // console.log("balanceOf: %s", IKonduxERC20(_token).balanceOf(address(this)));
        // console.log("amount: %s", _amount);
        // console.log("address this: %s", address(this));  

        IKonduxERC20(_token).transferFrom(address(this), _to, _amount);
        // console.log("balanceOf after: %s", IKonduxERC20(_token).balanceOf(address(this)));

        emit Withdrawal(_token, _amount);
    }

    receive() external payable {
        // console.log("Received Ether: %s", msg.value);
        emit EtherDeposit(msg.value);
    }

    fallback() external payable { 
        // console.log("Fallback Ether: %s", msg.value);
        emit EtherDeposit(msg.value); 
    }
    
    function withdrawEther(uint _amount) external {
        require(permissions[STATUS.RESERVESPENDER][msg.sender], notApproved);
        require(payable(msg.sender).send(_amount));

        emit EtherWithdrawal(msg.sender, _amount);
    }

    function setPermission(
        STATUS _status,
        address _address,
        bool _permission
    ) public onlyGovernor {
        permissions[_status][_address] = _permission;
        if (_status == STATUS.RESERVETOKEN) {
            isTokenApprooved[_address] = _permission;
            if (_permission) {
                approvedTokens[_address] = IKonduxERC20(_address);
                approvedTokensList.push(_address);
                approvedTokensCount++;                
            }
        }
    }

    function setStakingContract(address _stakingContract) public onlyGovernor {
        stakingContract = _stakingContract;
    }

    function erc20ApprovalSetup(address _token, uint256 _amount) public onlyGovernor {
        IKonduxERC20(_token).approve(address(this), _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

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

    modifier onlyRole(bytes32 _role){
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