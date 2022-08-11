/**
 *Submitted for verification at Etherscan.io on 2022-08-11
*/

// Verified using https://dapp.tools

// hevm: flattened sources of contracts/2022/07/Proposal28.sol

pragma solidity =0.8.10 >=0.8.0 <0.9.0;

////// lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

/* pragma solidity ^0.8.0; */

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

////// utils/YAMGovernanceStorage.sol
/* pragma solidity 0.8.10; */

/* Copyright 2020 Compound Labs, Inc.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. */


contract YAMGovernanceStorage {
    /// @notice A record of each accounts delegate
    mapping(address => address) internal _delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping(uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping(address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice A record of states for signing / validating signatures
    mapping(address => uint) public nonces;
}

////// utils/YAMTokenStorage.sol
/* pragma solidity 0.8.10; */


// Storage for a YAM token
contract YAMTokenStorage {
    /**
     * @dev Guard variable for re-entrancy checks. Not currently used
     */
    bool internal _notEntered;

    /**
     * @notice EIP-20 token name for this token
     */
    string public name;

    /**
     * @notice EIP-20 token symbol for this token
     */
    string public symbol;

    /**
     * @notice EIP-20 token decimals for this token
     */
    uint8 public decimals;

    /**
     * @notice Governor for this contract
     */
    address public gov;

    /**
     * @notice Pending governance for this contract
     */
    address public pendingGov;

    /**
     * @notice Approved rebaser for this contract
     */
    address public rebaser;

    /**
     * @notice Approved migrator for this contract
     */
    address public migrator;

    /**
     * @notice Incentivizer address of YAM protocol
     */
    address public incentivizer;

    /**
     * @notice Total supply of YAMs
     */
    uint256 public totalSupply;

    /**
     * @notice Internal decimals used to handle scaling factor
     */
    uint256 public constant internalDecimals = 10**24;

    /**
     * @notice Used for percentage maths
     */
    uint256 public constant BASE = 10**18;

    /**
     * @notice Scaling factor that adjusts everyone's balances
     */
    uint256 public yamsScalingFactor;

    mapping (address => uint256) internal _yamBalances;

    mapping (address => mapping (address => uint256)) internal _allowedFragments;

    uint256 public initSupply;


    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    bytes32 public DOMAIN_SEPARATOR;
}

////// utils/YAMTokenInterface.sol
/* pragma solidity 0.8.10; */

/* import "./YAMTokenStorage.sol"; */
/* import "./YAMGovernanceStorage.sol"; */

abstract contract YAMTokenInterface is YAMTokenStorage, YAMGovernanceStorage {

    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    /**
     * @notice Event emitted when tokens are rebased
     */
    event Rebase(uint256 epoch, uint256 prevYamsScalingFactor, uint256 newYamsScalingFactor);

    /*** Gov Events ***/

    /**
     * @notice Event emitted when pendingGov is changed
     */
    event NewPendingGov(address oldPendingGov, address newPendingGov);

    /**
     * @notice Event emitted when gov is changed
     */
    event NewGov(address oldGov, address newGov);

    /**
     * @notice Sets the rebaser contract
     */
    event NewRebaser(address oldRebaser, address newRebaser);

    /**
     * @notice Sets the migrator contract
     */
    event NewMigrator(address oldMigrator, address newMigrator);

    /**
     * @notice Sets the incentivizer contract
     */
    event NewIncentivizer(address oldIncentivizer, address newIncentivizer);

    /* - ERC20 Events - */

    /**
     * @notice EIP20 Transfer event
     */
    event Transfer(address indexed from, address indexed to, uint amount);

    /**
     * @notice EIP20 Approval event
     */
    event Approval(address indexed owner, address indexed spender, uint amount);

    /* - Extra Events - */
    /**
     * @notice Tokens minted event
     */
    event Mint(address to, uint256 amount);

    /**
     * @notice Tokens burned event
     */
    event Burn(address from, uint256 amount);

    // Public functions
    function transfer(address to, uint256 value) virtual external returns(bool);
    function transferFrom(address from, address to, uint256 value) virtual external returns(bool);
    function balanceOf(address who) virtual external view returns(uint256);
    function balanceOfUnderlying(address who) virtual external view returns(uint256);
    function allowance(address owner_, address spender) virtual external view returns(uint256);
    function approve(address spender, uint256 value) virtual external returns (bool);
    function increaseAllowance(address spender, uint256 addedValue) virtual external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) virtual external returns (bool);
    function maxScalingFactor() virtual external view returns (uint256);
    function yamToFragment(uint256 yam) virtual external view returns (uint256);
    function fragmentToYam(uint256 value) virtual external view returns (uint256);

    /* - Governance Functions - */
    function getPriorVotes(address account, uint blockNumber) virtual external view returns (uint256);
    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) virtual external;
    function delegate(address delegatee) virtual external;
    function delegates(address delegator) virtual external view returns (address);
    function getCurrentVotes(address account) virtual external view returns (uint256);

    /* - Permissioned/Governance functions - */
    function mint(address to, uint256 amount) virtual external returns (bool);
    function burn(uint256 amount) virtual external returns (bool);
    function rebase(uint256 epoch, uint256 indexDelta, bool positive) virtual external returns (uint256);
    function _setRebaser(address rebaser_) virtual external;
    function _setIncentivizer(address incentivizer_) virtual external;
    function _setPendingGov(address pendingGov_) virtual external;
    function _acceptGov() virtual external;
}

////// contracts/2022/07/Proposal28.sol
/* pragma solidity 0.8.10; */

/* import {YAMTokenInterface} from "../../../utils/YAMTokenInterface.sol"; */
/* import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol"; */

interface IYVault {
    function deposit(uint256 amount, address recipient)
        external
        returns (uint256);

    function withdraw(uint256 amount) external returns (uint256);
}

contract Proposal28 {
    /// Contracts and ERC20 addresses
    IERC20 internal constant WETH =
        IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 internal constant YAM =
        IERC20(0x0AaCfbeC6a24756c20D41914F2caba817C0d8521);
    IYVault internal constant yUSDC =
        IYVault(0xa354F35829Ae975e850e23e9615b11Da1B3dC4DE);
    IERC20 internal constant USDC =
        IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    address internal constant RESERVES =
        0x97990B693835da58A281636296D2Bf02787DEa17;
    address internal constant MULTISIG =
        0x744D16d200175d20E6D8e5f405AEfB4EB7A962d1;

    function execute() public {
        // Withdraw yUSDC
        IERC20(address(yUSDC)).transferFrom(
            RESERVES,
            address(this),
            IERC20(address(yUSDC)).balanceOf(RESERVES)
        );
        yUSDC.withdraw(type(uint256).max);

        // Withdraw USDC
        IERC20(address(USDC)).transferFrom(
            RESERVES,
            address(this),
            IERC20(address(USDC)).balanceOf(RESERVES)
        );

        // Comp transfers

        // E
        compSend(0x8A8acf1cEcC4ed6Fe9c408449164CE2034AdC03f, 9917, 0, 1);
        // Chilly
        compSend(0x01e0C7b70E0E05a06c7cC8deeb97Fa03d6a77c9C, 8092, 0, 1);
        // Designer
        compSend(0x3FdcED6B5C1f176b543E5E0b841cB7224596C33C, 6545, 0, 1);
        // Ross
        compSend(0x88c868B1024ECAefDc648eb152e91C57DeA984d0, 8575, 0, 1);
        // Mona
        compSend(0xdADc6F71986643d9e9CB368f08Eb6F1333F6d8f9, 0, 0, 1);
        // // Feddas
        // compSend(0xbdac5657eDd13F47C3DD924eAa36Cf1Ec49672cc, 2975, 0, 1);

        // Return remaining USDC to reserves
        uint256 usdcBalance = 100000 * (10**6);
        USDC.transfer(RESERVES, usdcBalance);

        // Deposit yUSDC into reserves
        uint256 usdcBalanceTotal = USDC.balanceOf(address(this));
        USDC.approve(address(yUSDC), usdcBalanceTotal);
        yUSDC.deposit(usdcBalanceTotal, RESERVES);
    }

    // Function used to distribute comps
    function compSend(
        address _address,
        uint256 amountUSDC,
        uint256 amountYAM,
        uint256 months
    ) internal {
        if (amountUSDC > 0) {
            USDC.transfer(_address, amountUSDC * (10**6) * months);
        }
        if (amountYAM > 0) {
            YAM.transfer(_address, amountYAM * (10**18) * months);
        }
    }
}