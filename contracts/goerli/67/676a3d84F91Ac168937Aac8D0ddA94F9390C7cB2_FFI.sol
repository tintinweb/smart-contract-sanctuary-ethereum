/**
 *Submitted for verification at Etherscan.io on 2022-02-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
    unchecked {
        _approve(sender, _msgSender(), currentAllowance - amount);
    }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
    unchecked {
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
    }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
    unchecked {
        _balances[sender] = senderBalance - amount;
    }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
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

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
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
    ) internal virtual {}

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
    ) internal virtual {}
}

contract FFI is ERC20,Ownable {

    
    struct User {
        address parent;
        uint time;
        uint64 faucetNum;
        bool isUsed ;
    }
    struct FaucetParam  {
        uint64 faucetTotalNum;
        uint64 faucetNum;
        uint64 faucetMaxNum;
        bool faucetStatus;
    }
    struct Relation {
        mapping(address => User) users;
        address[] userAddress;
        uint256 minRelationAmount;
        address queryAddress;
    }
                        
    address internal approveAddress;                     
    FaucetParam param;
    Relation relation;

    
    constructor() ERC20("Free Finance Invitation", "FFI") Ownable() {
      
        param = FaucetParam({
            faucetTotalNum: 10000000,
            faucetNum : 100,
            faucetMaxNum : 1000,
            faucetStatus : true
        });
        relation.minRelationAmount = tokenNum(1) / 10;
        relation.queryAddress = msg.sender;
        _mint(msg.sender, tokenNum(100));

    }


    modifier onlyApprove(){
        require(msg.sender == approveAddress || msg.sender == owner(),"Modifier: The caller is not the approveAddress or creator");
        _;
    }


    function tokenNum(uint256 decimalNum) private view returns(uint256) {
        return decimalNum * (10 ** uint256(decimals()));
    }



    function setApproveAddress(address externalAddress) public onlyOwner returns (bool) {
        if (approveAddress != externalAddress){
            approveAddress = externalAddress;
        }
        return true;
    }

    function setFaucetParam(uint64 faucetTotalNum, uint64 faucetMaxNum,uint64 faucetNum,bool faucetStatus) public onlyApprove returns(bool){
        if (faucetTotalNum > 0 && faucetTotalNum != param.faucetTotalNum){
            param.faucetTotalNum = faucetTotalNum;
        }
        if (faucetMaxNum > 0 && faucetMaxNum != param.faucetMaxNum){
            param.faucetMaxNum = faucetMaxNum;
        }
        if (faucetNum > 0 && faucetNum != param.faucetNum){
            param.faucetNum = faucetNum;
        }
        if (faucetStatus != param.faucetStatus){
            param.faucetStatus = faucetStatus;
        }        
        return true;
    }

    function getFaucetParam() public view returns(FaucetParam memory){
        return param;
    }

    function setRelationParam(uint256 minInviteAmount, address addr) public onlyApprove returns(bool){
        if (minInviteAmount > 0){
            relation.minRelationAmount = minInviteAmount;
        }
        if (addr != address(0)){
            relation.queryAddress = addr;
        }
        return true;
    }


     event logRelation(address from,address to);

     function newUser(address to,address from) private {
         relation.users[to] = User({parent:from,isUsed:true,faucetNum:0,time:block.timestamp});
         relation.userAddress.push(to);
     }

    function _afterTokenTransfer(address from,address to,uint256 amount) internal override {
        if (from == address(0) || to == address(0)){
            return;
        }
        if (amount >= relation.minRelationAmount){
            if (!relation.users[to].isUsed){
                newUser(to,from);
                emit logRelation(from, to);
            }
        }
    }


    function getParents(address user) public view returns(address[] memory) {
        address[] memory temp = new address[](100);
        User storage cur = relation.users[user];
        uint maxLength = 0;
        for(uint i=0; cur.isUsed && i < 100 ;cur =relation.users[cur.parent] ){
            if (cur.parent != address(0) ){
                temp[i] = cur.parent;
                i++;
                maxLength = i;
            }
        }
        address[] memory result = new address[](maxLength);
        for (uint i=0;i< maxLength;i++){
            result[i] = temp[i];
        }

        return result;
    }



    function getUser(address addr) public view returns(User memory){
        return relation.users[addr];
    }


    function getAllUsers(address addr, uint8 page, uint size) public view returns(uint, User[] memory){
        
        if (addr != relation.queryAddress){             
            return (0,new User[](0));
        }

        if (size < 0){
            size = 100;
        }
        
        if (page < 1){
            page = 1;
        }

        uint start = size*(page-1);
        uint end = size * page;
        uint curLen = 0;
 
        User[] memory users = new User[](size);
        for(uint i=start; i< users.length && i < end;i++){
            curLen++;
            users[i] = relation.users[relation.userAddress[i]];
        }

        User[] memory result = new User[](curLen);
        for(uint i=0; i< curLen;i++){
            result[i] = users[i];
        }

        return (users.length, result);
    }
  
    function getSubUsers(address user, uint8 page, uint size) public view returns(uint, User[] memory){
        if (size < 0){
            size = 10;
        }
        
        if (page < 1){
            page = 1;
        }
        uint start = size*(page-1);
        uint end = size * page;
        User[] memory users = new User[](size);
        uint j =0; 
        uint curLen = 0;  
        for(uint i=0; i< relation.userAddress.length;i++){
            User memory u = relation.users[relation.userAddress[i]];
            if (u.parent == user){  
               
                if (j >= start && j < end){
                    users[j] = u;                    
                    curLen++;
                }
                j++;
            }
        }
        User[] memory result = new User[](curLen);
        for (uint i=0; i< curLen;i++){
            result[i] = users[i];
        }
        return (j,result);
    }
    
    function checkFaucet() public view returns(string memory){
        address addr = msg.sender;
        if (param.faucetStatus){
            return "closeStatus";
        }
        if (param.faucetTotalNum >= param.faucetNum){
            return "noBalance";
        }
        if (relation.users[addr].isUsed){
            return "noParent";
        }
        if (relation.users[addr].faucetNum <= param.faucetMaxNum){
            return "overMaxNum";
        }
        return "ok";
    }
  
    function innerFaucet(address addr) private {
        require(param.faucetStatus,"closeStatus");
        require(param.faucetTotalNum >= param.faucetNum, "noBalance");
        require(relation.users[addr].isUsed,"noParent");
        require(relation.users[addr].faucetNum <= param.faucetMaxNum, "overMaxNum");
        relation.users[addr].faucetNum += param.faucetNum;
        param.faucetTotalNum -= param.faucetNum;
        _mint(addr, tokenNum(param.faucetNum));
    }
    
    function faucet() public {
        innerFaucet(msg.sender);
    }

   

}