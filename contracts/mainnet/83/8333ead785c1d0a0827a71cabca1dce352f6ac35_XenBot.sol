/**
 *Submitted for verification at Etherscan.io on 2022-10-08
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: contracts/bot.sol


pragma solidity ^0.8.4;


contract XenBot {
    constructor() {
    }
    mapping (address => uint256) public usersCounter;
    mapping (address => mapping (uint256 => address)) public users;
    function deploy_holding(uint256 term) private {
        holdingContract hc = new holdingContract(msg.sender, term);
        uint256 num_by_user = usersCounter[msg.sender];
        users[msg.sender][num_by_user] = address(hc);
        usersCounter[msg.sender]=usersCounter[msg.sender]+1;
    } 
    function deploy_holdings(uint256 num, uint256 term) external {
        for (uint256 j = 0; j<num; j++) {
        deploy_holding(term);
        }
    }
}

contract holdingContract {
    address public FLUSH_ADDRESS;
    address public constant XEN_CONTRACT_ADDRESS = 0x06450dEe7FD2Fb8E39061434BAbCFC05599a6Fb8;
    XenContract xc = XenContract(XEN_CONTRACT_ADDRESS);
    constructor (address flush_address, uint256 term) {
        FLUSH_ADDRESS =flush_address;
        xc.claimRank(term);
    }
    function claimMintReward() external {
        require(msg.sender==FLUSH_ADDRESS);
        xc.claimMintReward();
        IERC20(XEN_CONTRACT_ADDRESS).transfer(FLUSH_ADDRESS, IERC20(XEN_CONTRACT_ADDRESS).balanceOf(address(this)));
    }
}
contract XenContract {
    // INTERNAL TYPE TO DESCRIBE A XEN MINT INFO
    struct MintInfo {
        address user;
        uint256 term;
        uint256 maturityTs;
        uint256 rank;
        uint256 amplifier;
        uint256 eaaRate;
    }

    // INTERNAL TYPE TO DESCRIBE A XEN STAKE
    struct StakeInfo {
        uint256 term;
        uint256 maturityTs;
        uint256 amount;
        uint256 apy;
    }
function getGrossReward(
        uint256 rankDelta,
        uint256 amplifier,
        uint256 term,
        uint256 eaa
    ) public pure returns (uint256) {
        //return reward128.div(uint256(1_000).fromUInt()).toUInt();
    }

    /**
     * @dev returns User Mint object associated with User account address
     */
    function getUserMint() external view returns (MintInfo memory) {
       // return userMints[_msgSender()];
    }

    /**
     * @dev returns XEN Stake object associated with User account address
     */
    function getUserStake() external view returns (StakeInfo memory) {
       // return userStakes[_msgSender()];
    }

    /**
     * @dev returns current AMP
     */
    function getCurrentAMP() external view returns (uint256) {
       // return _calculateRewardAmplifier();
    }

    /**
     * @dev returns current EAA Rate
     */
    function getCurrentEAAR() external view returns (uint256) {
        //return _calculateEAARate();
    }

    /**
     * @dev returns current APY
     */
    function getCurrentAPY() external view returns (uint256) {
       // return _calculateAPY();
    }

    /**
     * @dev returns current MaxTerm
     */
    function getCurrentMaxTerm() external view returns (uint256) {
        //return _calculateMaxTerm();
    }
    mapping(address => MintInfo) public userMints;
    // PUBLIC STATE-CHANGING METHODS

    /**
     * @dev accepts User cRank claim provided all checks pass (incl. no current claim exists)
     */
    function claimRank(uint256 term) external {}

    /**
     * @dev ends minting upon maturity (and within permitted Withdrawal Time Window), gets minted XEN
     */
    function claimMintReward() external {}

    /**
     * @dev  ends minting upon maturity (and within permitted Withdrawal time Window)
     *       mints XEN coins and splits them between User and designated other address
     */
    function claimMintRewardAndShare(address other, uint256 pct) external {}

    /**
     * @dev  ends minting upon maturity (and within permitted Withdrawal time Window)
     *       mints XEN coins and stakes 'pct' of it for 'term'
     */
    function claimMintRewardAndStake(uint256 pct, uint256 term) external {}

    /**
     * @dev initiates XEN Stake in amount for a term (days)
     */
    function stake(uint256 amount, uint256 term) external {}

    /**
     * @dev ends XEN Stake and gets reward if the Stake is mature
     */
    function withdraw() external {}

    /**
     * @dev burns XEN tokens and creates Proof-Of-Burn record to be used by connected DeFi services
     */
    function burn(address user, uint256 amount) public {}}