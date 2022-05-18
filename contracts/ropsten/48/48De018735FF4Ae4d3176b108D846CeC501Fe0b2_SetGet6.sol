/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;



// Part: IERC20

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

// File: SetGet.sol

contract SetGet6 {
    mapping(address => uint256) balances;
    string value;
    address payable public owner;
    uint256 public creationTime = now;

    event TransferSent(address _from, address _destAddr, uint256 _amount);

    constructor() public {
        value = "myValue";
        owner = msg.sender;
    }

    function fund() public payable {
        balances[msg.sender] += msg.value;
    }

    function getBalance() public view returns (uint256 Finney) {
        return address(this).balance / 10**15;
    }

    function get() public view returns (string memory) {
        return value;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function set(string memory _value) public onlyOwner {
        value = _value;
    }

    modifier onlyBy(address _account) {
        require(msg.sender == _account, "Sender not authorized.");
        _;
    }

    modifier onlyAfter(uint256 _time) {
        require(now >= _time, "Function called too early.");
        _;
    }

    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }

    function disown() public onlyBy(owner) onlyAfter(creationTime + 5 minutes) {
        delete owner;
    }

    function withdraw() public onlyOwner {}

    function transferERC20(
        IERC20 token,
        address to,
        uint256 amount
    ) public {
        require(msg.sender == owner, "Only Owner can withdraw funds");
        uint256 erc20balance = token.balanceOf(address(this));
        require(amount <= erc20balance, "balance is low");
        token.transfer(to, amount);
        emit TransferSent(msg.sender, to, amount);
    }

    function close() external {
        selfdestruct(msg.sender);
    }
}