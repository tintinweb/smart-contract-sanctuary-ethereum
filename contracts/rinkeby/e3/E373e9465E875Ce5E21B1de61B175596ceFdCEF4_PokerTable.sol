// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PokerTable {
    IERC20 public PKX;
    address public owner;
    string public name;
    string public banner;

    mapping(address => uint256) public balances;
    bool[7] public seats;

    event PlayerJoin(address indexed, uint, uint256);
    event PlayerCall(address indexed, uint, uint256, uint256);
    event PlayerRaise(address indexed, uint, uint256, uint256);
    event PlayerBet(address indexed, uint, uint256, uint256);
    event PlayerAllIn(address indexed, uint, uint256, uint256);
    event PlayerAddChip(address indexed, uint256);
    event PlayerClaim(address indexed, uint256);
    event SetWinner(address indexed, uint256);

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    constructor(address _owner, string memory _name) {
        owner = _owner;
        name = _name;
    }

    function setName(string memory _name) external onlyOwner {
        name = _name;
    }

    function setBanner(string memory _banner) external onlyOwner {
        banner = _banner;
    }    

    function updateSitting(uint num, bool sitting) external onlyOwner {
        seats[num] = sitting;
    }

    function join(uint num, uint256 amount) external {
        address account = msg.sender;
        require(!seats[num], "not able to join");
        PKX.transferFrom(account, address(this), amount);

        seats[num] = true;
        balances[account] = amount;

        emit PlayerJoin(account, num, amount);
    }

    function call(address account, uint pos, uint256 amount, uint256 pot) external onlyOwner {
        emit PlayerCall(account, pos, amount, pot);
    }

    function raise(address account, uint pos, uint256 amount, uint256 pot) external onlyOwner {
        emit PlayerRaise(account, pos, amount, pot);
    }

    function bet(address account, uint pos, uint256 amount, uint256 pot) external onlyOwner {
        emit PlayerBet(account, pos, amount, pot);
    }

    function allin(address account, uint pos, uint256 amount, uint256 pot) external onlyOwner {
        emit PlayerAllIn(account, pos, amount, pot);
    }

    function setWinner(address winner, uint256 amount) external onlyOwner {
        balances[winner] += amount;
        emit SetWinner(winner, amount);
    }

    function addChips(uint256 amount) external {
        address account = msg.sender;
        PKX.transferFrom(account, address(this), amount);
        balances[account] += amount;
        emit PlayerAddChip(account, amount);
    }

    function claim() external {
        address account = msg.sender;
        uint256 amount = balances[account];
        PKX.transfer(account, amount);
        balances[account] = 0;
        emit PlayerClaim(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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