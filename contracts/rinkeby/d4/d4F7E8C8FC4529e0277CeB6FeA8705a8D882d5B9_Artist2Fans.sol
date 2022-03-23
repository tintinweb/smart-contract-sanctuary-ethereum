/**
 *Submitted for verification at Etherscan.io on 2022-03-23
*/

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
//
// ----------------------------------------------------------------------------
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

// ----------------------------------------------------------------------------
// Safe Math Library
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); c = a - b; } function safeMul(uint a, uint b) public pure returns (uint c) { c = a * b; require(a == 0 || c / a == b); } function safeDiv(uint a, uint b) public pure returns (uint c) { require(b > 0);
        c = a / b;
    }
}

// Context Library
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// Ownable Library
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


contract Artist2Fans is IERC20, Ownable, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals; // 18 decimals is the strongly suggested default, avoid changing it

    uint256 public _totalSupply;

    struct holder {
      uint lockupAmount;
      uint unlockTime;
      bool bCreated;
    }

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    mapping(address => holder) holders;

    address private _rewardPoolAddress = 0x0e1C239046d92Bb13A4534A269C45a2e9C7dB32D;
    address private _developmentAddress = 0x566D977b82FD3F08256FCB7C69C1D55234d41C7e;
    address private _MKTAddress = 0x1B7e5e261EC73955670b5386206749EfdE19241E;
    address private _burnAddress = 0x1FdCB3c71b37F7E6193FAf1F4575E091eA4C064F;
    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() {
        name = "Artist2Fans";
        symbol = "A2F";
        decimals = 9;
        _totalSupply = 10000000000 * 10 ** 9;
        //8 000 000 000 tokens to owner
        //2 000 000 000 tokens to liquidity pool
        uint256 amount2Owner = _totalSupply - 2000000000 * 10 ** 9;
        balances[msg.sender] = amount2Owner;
        balances[_rewardPoolAddress] = 2000000000 * 10 ** 9;
        emit Transfer(address(0), msg.sender, amount2Owner);
    }

    function totalSupply() public override view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public override view returns (uint balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public override view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint tokens) public override returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transfer(address to, uint tokens) public override returns (bool success) {
        //25% of tokens is locked only first time.
        if (!holders[to].bCreated) {
          holders[to].lockupAmount = tokens * 25 / 100;
          holders[to].unlockTime = block.timestamp + 2 * 365 * 24 * 3600;
          holders[to].bCreated = true;
        }

        require(tokens > holders[msg.sender].lockupAmount, "You can not send locked tokens");
        require(block.timestamp > holders[msg.sender].unlockTime, "You can unlock tokens after 2 years from initial mintTime");

        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        //2.5% of transaction goes to burn address
        //2.5% goes to development address
        //2.5% goes to MKT address
        uint amount2to = tokens * 925 / 1000;
        uint amountPiece = tokens * 25 / 1000;

        balances[to] = safeAdd(balances[to], amount2to);
        balances[_MKTAddress] = safeAdd(balances[_MKTAddress], amountPiece);
        balances[_developmentAddress] = safeAdd(balances[_developmentAddress],amountPiece);
        _burn(msg.sender, amountPiece);

        emit Transfer(msg.sender, to, amount2to);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public override returns (bool success) {
        //25% of tokens is locked only first time.
        if (!holders[to].bCreated) {
          holders[to].lockupAmount = tokens * 25 / 100;
          holders[to].unlockTime = block.timestamp + 2 * 365 * 24 * 3600;
          holders[to].bCreated = true;
        }

        require(tokens > holders[from].lockupAmount, "You can not send locked tokens");
        require(block.timestamp > holders[from].unlockTime, "You can unlock tokens after 2 years from initial mintTime");

        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        //2.5% of transaction goes to burn address
        //2.5% goes to development address
        //2.5% goes to MKT address
        uint amount2to = tokens * 925 / 1000;
        uint amountPiece = tokens * 25 / 1000;

        balances[to] = safeAdd(balances[to], amount2to);
        balances[_MKTAddress] = safeAdd(balances[_MKTAddress], amountPiece);
        balances[_developmentAddress] = safeAdd(balances[_developmentAddress],amountPiece);
        _burn(from, amountPiece);
        emit Transfer(from, to, amount2to);
        return true;
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), 'BRC20: mint to the zero address');

        _totalSupply = safeAdd(_totalSupply, amount);
        balances[account] = safeAdd(balances[account], amount);
        emit Transfer(address(0), account, amount);
    }

    function mint(uint256 amount) public onlyOwner returns (bool) {
        _mint(_msgSender(), amount);
        return true;
    }

    function setOwnerAddress(address newAddress) public onlyOwner {
        _MKTAddress = newAddress;
    }

    function _burn(address account, uint256 amount) private {
      require(account != address(0) && account != _burnAddress, "You attempted to send from zero address");
      require(balances[account] > amount, "burn amount exceeds balance");

      balances[account] = safeSub(balances[account], amount);
      balances[_burnAddress] = safeAdd(balances[_burnAddress], amount);
      _totalSupply -= amount;
    }
}