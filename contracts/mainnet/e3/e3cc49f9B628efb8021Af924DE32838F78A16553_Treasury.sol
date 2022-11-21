/**
 *Submitted for verification at Etherscan.io on 2022-11-21
*/

// Sources flattened with hardhat v2.10.2 https://hardhat.org

// File contracts/interfaces/treasury/ISeed.sol

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.12;

interface ISeed {
    function mint(address account, uint256 amount) external returns (bool);
}


// File contracts/interfaces/treasury/IERC20.sol

pragma solidity >=0.8.12;

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


// File contracts/interfaces/treasury/ITreasury.sol

pragma solidity >=0.8.12;

interface ITreasury {
    function mint(address receiver) external returns (uint256);
}


// File contracts/src/treasury/Treasury.sol

pragma solidity >=0.8.12;



contract Treasury is ITreasury {
    //A valid deployer of the contract
    address public owner;

    //A valid caller of the contract;
    address public caller;

    // The Treasury contract enables the token casting capability, which is disabled by default;
    bool public callable;

    address public seedToken;

    uint256 public lastWithdrawAmount = 0;
    uint64 public withdrawCnt = 0;
    //if true, means starting the halving withdrawal mode
    bool public enableHalf = false;

    //Due to the use of integer shift halving, the precision of the last bit may be lost in the future,
    //so one cycle is approximately 23.1 million tokens to be minted;
    uint256 MAX_MINTABLE_AMOUNT_IN_CYCLE = 23100000_000000000000000000;

    //The initial amount distributed to users will be halved every cycle;
    uint256 GENESIS_MINTABLE_AMOUNT_FOR_USER = 2100_000000000000000000;

    //The amount of tokens issued to the treasury contract along with the user's issuing behavior;
    //bytes: 10110110001001010101110111110101111101010000000010000000000000000000
    uint256 GENESIS_MINTABLE_AMOUNT_FOR_TREASURE = 210_000000000000000000;

    //Used to mark which minting cycle is currently in
    uint16 public cycle = 0;

    mapping(uint16 => string) public rules;
    uint16 public ruleSize;

    constructor(address _seed) {
        seedToken = _seed;
        owner = msg.sender;
        callable = false;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Treasury: only owner can do");
        _;
    }

    function setCaller(address _caller) public onlyOwner {
        caller = _caller;
        callable = true;
    }

    modifier mintable() {
        require(callable == true, "Treasury: caller is invalid");
        require(msg.sender == caller, "Treasury: only caller can do");
        _;
    }

    function addRule(string memory rule) external {
        require(bytes(rule).length > 0, "Treasury: msg empty");
        rules[ruleSize] = rule;
        ruleSize++;
    }

    function mint(address receiver) public override mintable returns (uint256) {
        //calculate which cycle is currently in BY totalSupply;
        uint256 totalSupply = IERC20(seedToken).totalSupply();

        // If the current cycle is different from the calculated one,
        // it means that the next token cycle is entered, and the value of cycle is updated at this time
        if (totalSupply / MAX_MINTABLE_AMOUNT_IN_CYCLE > cycle) {
            cycle = cycle + 1;
        }

        require(GENESIS_MINTABLE_AMOUNT_FOR_TREASURE >> cycle > 0, "Treasury: mint stop");

        ISeed(seedToken).mint(address(this), GENESIS_MINTABLE_AMOUNT_FOR_TREASURE >> cycle);

        ISeed(seedToken).mint(receiver, GENESIS_MINTABLE_AMOUNT_FOR_USER >> cycle);
        return GENESIS_MINTABLE_AMOUNT_FOR_USER >> cycle;
    }

    receive() external payable {}

    function setHalf(bool enable) external onlyOwner returns (bool) {
        enableHalf = enable;
        return true;
    }

    function withdraw(
        address receiver,
        address tokenAddress,
        uint256 amount
    ) external onlyOwner returns (bool) {
        require(receiver != address(0) && tokenAddress != address(0), "Treasury: ZERO ADDRESS");
        //The amount of each withdrawal does not exceed the normal amount of the previous amount,
        //When the number of withdrawals is not zero and the withdrawal amount is zero,
        //it means abandoning the withdrawal of SEED token
        if (tokenAddress == seedToken && enableHalf == true) {
            if (withdrawCnt > 0 && lastWithdrawAmount == 0) {
                return false;
            }
            if (withdrawCnt > 0 && amount > lastWithdrawAmount >> 1) {
                amount = lastWithdrawAmount >> 1;
            }

            lastWithdrawAmount = amount;
            withdrawCnt = withdrawCnt + 1;
        }

        require(IERC20(tokenAddress).balanceOf(address(this)) >= amount, "Treasury: amount invalid");
        IERC20(tokenAddress).transfer(receiver, amount);
        return true;
    }

    function withdrawETH(address payable receiver, uint256 amount) external onlyOwner returns (bool) {
        receiver.transfer(amount);
        return true;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Treasury: ZERO ADDRESS");
        owner = newOwner;
    }
}