/**
 *Submitted for verification at Etherscan.io on 2022-12-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;


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

pragma solidity ^0.8.0;

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 13. To select a different value for
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
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
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

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

interface ISlothRoob {
    function balanceOf(address _user) external view returns(uint256);
    function ownerOf(uint256 _tokenId) external view returns(address);
    function totalSupply() external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function setIsStake(uint256 _tokenId, bool _isStake) external;
}

contract Roob is ERC20("ROOB", "ROOB"), Ownable {
    address public SlothRoobContractAddress;
    struct TokenData {
        uint256 baseRate;
        bool isStaked;
        address user;
    }

    ISlothRoob public iSlothRoob;
    ISlothRoob public iCollection2;
    ISlothRoob public iCollection3;
    ISlothRoob public iCollection4;
    ISlothRoob public iCollection5;
    ISlothRoob public iCollection6;

    address public adminAddress = 0xFA51d16B08FF30Ff77A4Cf5bb1Df52EABF0356Ae;

    // Prevents new contracts from being added or changes to disbursement if permanently locked
    uint256 public totalStakedSlothRoob = 0;
    uint256 public totalStakedCollection2 = 0;
    uint256 public totalStakedCollection3 = 0;
    uint256 public totalStakedCollection4 = 0;
    uint256 public totalStakedCollection5 = 0;
    uint256 public totalStakedCollection6 = 0;
    uint256 public totalPaidReward = 0;
    address [] userAddressForStakedToken;
    uint256 public basicReward = 15;
    mapping(bytes32 => uint256) public slothRoobLastClaim;
    mapping(bytes32 => uint256) public collection2LastClaim;
    mapping(bytes32 => uint256) public collection3LastClaim;
    mapping(bytes32 => uint256) public collection4LastClaim;
    mapping(bytes32 => uint256) public collection5LastClaim;
    mapping(bytes32 => uint256) public collection6LastClaim;
    mapping(uint256 => TokenData) public stake;
    mapping(uint256 => TokenData) public stakeCollection2;
    mapping(uint256 => TokenData) public stakeCollection3;
    mapping(uint256 => TokenData) public stakeCollection4;
    mapping(uint256 => TokenData) public stakeCollection5;
    mapping(uint256 => TokenData) public stakeCollection6;

    mapping(address => uint256[])  userStakedToken;
    mapping(address => uint256[])  userStakedTokenCollection2;
    mapping(address => uint256[])  userStakedTokenCollection3;
    mapping(address => uint256[])  userStakedTokenCollection4;
    mapping(address => uint256[])  userStakedTokenCollection5;
    mapping(address => uint256[])  userStakedTokenCollection6;

    event RewardPaid(address indexed user, uint256 reward);

    constructor(address _slothRoobAddress) {
        // _mint(address(this),2000000000 * 10 ** 18);
        SlothRoobContractAddress = _slothRoobAddress;
        iSlothRoob = ISlothRoob(SlothRoobContractAddress);
    }

    function airDrop(address user, uint256 amount) public {
        require(msg.sender == adminAddress || msg.sender == owner(), "Invalid sender");
        _mint(user, amount * 10 ** 18);
        totalPaidReward += amount * 10 ** 18;
        userAddressForStakedToken.push(user);
    }

    function setRewardAmount(uint256 _numberOfTokensForReward) public {
        require(msg.sender == adminAddress || msg.sender == owner(), "Invalid sender");
        basicReward = _numberOfTokensForReward;
    }

    function stakeToken(uint256[] memory _tokenId) public {
        for(uint i = 0; i < _tokenId.length; i++){
        require(iSlothRoob.ownerOf(_tokenId[i]) == msg.sender, "Caller does not own the token being claimed for.");

        if(stake[_tokenId[i]].baseRate != 0){
            address oldUser = stake[_tokenId[i]].user;
            require(stake[_tokenId[i]].user != msg.sender, "Token is already staked");
            for(uint j=0; j<userStakedToken[oldUser].length; j++){
               if (userStakedToken[oldUser][j] == _tokenId[i]){
                   userStakedToken[oldUser][j] = 0;
               }
            }
        userStakedToken[msg.sender].push(_tokenId[i]);
        }
        else{
        userStakedToken[msg.sender].push(_tokenId[i]);
        }

        TokenData memory newTokenData;
        newTokenData.baseRate = basicReward;
        newTokenData.isStaked = true;
        newTokenData.user = msg.sender;

        stake[_tokenId[i]] = newTokenData;

        bytes32 lastClaimKey = keccak256(abi.encode(_tokenId[i]));
        slothRoobLastClaim[lastClaimKey] = block.timestamp;

        totalStakedSlothRoob = totalStakedSlothRoob + 1;
        }    
        userAddressForStakedToken.push(msg.sender);
    }

    function stakeTokenForCollection2(uint256[] memory _tokenId) public {
        for(uint i = 0; i < _tokenId.length; i++){
        require(iCollection2.ownerOf(_tokenId[i]) == msg.sender, "Caller does not own the token being claimed for.");

        if(stakeCollection2[_tokenId[i]].baseRate != 0){
            address oldUser = stakeCollection2[_tokenId[i]].user;
            require(stakeCollection2[_tokenId[i]].user != msg.sender, "Token is already staked");
            for(uint j=0; j<userStakedTokenCollection2[oldUser].length; j++){
               if (userStakedTokenCollection2[oldUser][j] == _tokenId[i]){
                   userStakedTokenCollection2[oldUser][j] = 0;
               }
            }
        userStakedTokenCollection2[msg.sender].push(_tokenId[i]);
        }
        else{
        userStakedTokenCollection2[msg.sender].push(_tokenId[i]);
        }

        TokenData memory newTokenData;
        newTokenData.baseRate = basicReward;
        newTokenData.isStaked = true;
        newTokenData.user = msg.sender;

        stakeCollection2[_tokenId[i]] = newTokenData;

        bytes32 lastClaimKey = keccak256(abi.encode(_tokenId[i]));
        collection2LastClaim[lastClaimKey] = block.timestamp;

        totalStakedCollection2 = totalStakedCollection2 + 1;
        } 
        userAddressForStakedToken.push(msg.sender);
    }

    function stakeTokenForCollection3(uint256[] memory _tokenId) public {
        for(uint i = 0; i < _tokenId.length; i++){
        require(iCollection3.ownerOf(_tokenId[i]) == msg.sender, "Caller does not own the token being claimed for.");

         if(stakeCollection3[_tokenId[i]].baseRate != 0){
            address oldUser = stakeCollection3[_tokenId[i]].user;
            require(stakeCollection3[_tokenId[i]].user != msg.sender, "Token is already staked");
            for(uint j=0; j<userStakedTokenCollection3[oldUser].length; j++){
               if (userStakedTokenCollection3[oldUser][j] == _tokenId[i]){
                   userStakedTokenCollection3[oldUser][j] = 0;
               }
            }
        userStakedTokenCollection3[msg.sender].push(_tokenId[i]);
        }
        else{
        userStakedTokenCollection3[msg.sender].push(_tokenId[i]);
        }

        TokenData memory newTokenData;
        newTokenData.baseRate = basicReward;
        newTokenData.isStaked = true;
        newTokenData.user = msg.sender;

        stakeCollection3[_tokenId[i]] = newTokenData;

        bytes32 lastClaimKey = keccak256(abi.encode(_tokenId[i]));
        collection3LastClaim[lastClaimKey] = block.timestamp;

        totalStakedCollection3 = totalStakedCollection3 + 1;
        }  
        userAddressForStakedToken.push(msg.sender);
    }

    function stakeTokenForCollection4(uint256[] memory _tokenId) public {
        for(uint i = 0; i < _tokenId.length; i++){
        require(iCollection4.ownerOf(_tokenId[i]) == msg.sender, "Caller does not own the token being claimed for.");

        if(stakeCollection4[_tokenId[i]].baseRate != 0){
            address oldUser = stakeCollection4[_tokenId[i]].user;
            require(stakeCollection4[_tokenId[i]].user != msg.sender, "Token is already staked");
            for(uint j=0; j<userStakedTokenCollection4[oldUser].length; j++){
               if (userStakedTokenCollection4[oldUser][j] == _tokenId[i]){
                   userStakedTokenCollection4[oldUser][j] = 0;
               }
            }
        userStakedTokenCollection4[msg.sender].push(_tokenId[i]);
        }
        else{
        userStakedTokenCollection4[msg.sender].push(_tokenId[i]);
        }

        TokenData memory newTokenData;
        newTokenData.baseRate = basicReward;
        newTokenData.isStaked = true;
        newTokenData.user = msg.sender;

        stakeCollection4[_tokenId[i]] = newTokenData;

        bytes32 lastClaimKey = keccak256(abi.encode(_tokenId[i]));
        collection4LastClaim[lastClaimKey] = block.timestamp;

        totalStakedCollection4 = totalStakedCollection4 + 1;
        }  
        userAddressForStakedToken.push(msg.sender);
    }

    function stakeTokenForCollection5(uint256[] memory _tokenId) public {
        for(uint i = 0; i < _tokenId.length; i++){
        require(iCollection5.ownerOf(_tokenId[i]) == msg.sender, "Caller does not own the token being claimed for.");

        if(stakeCollection5[_tokenId[i]].baseRate != 0){
            address oldUser = stakeCollection5[_tokenId[i]].user;
            require(stakeCollection5[_tokenId[i]].user != msg.sender, "Token is already staked");
            for(uint j=0; j<userStakedTokenCollection5[oldUser].length; j++){
               if (userStakedTokenCollection5[oldUser][j] == _tokenId[i]){
                   userStakedTokenCollection5[oldUser][j] = 0;
               }
            }
        userStakedTokenCollection5[msg.sender].push(_tokenId[i]);
        }
        else{
        userStakedTokenCollection5[msg.sender].push(_tokenId[i]);
        }

        TokenData memory newTokenData;
        newTokenData.baseRate = basicReward;
        newTokenData.isStaked = true;
        newTokenData.user = msg.sender;

        stakeCollection5[_tokenId[i]] = newTokenData;

        bytes32 lastClaimKey = keccak256(abi.encode(_tokenId[i]));
        collection5LastClaim[lastClaimKey] = block.timestamp;

        totalStakedCollection5 = totalStakedCollection5 + 1;
        }  
        userAddressForStakedToken.push(msg.sender);
    }

    function stakeTokenForCollection6(uint256[] memory _tokenId) public {
        for(uint i = 0; i < _tokenId.length; i++){
        require(iCollection6.ownerOf(_tokenId[i]) == msg.sender, "Caller does not own the token being claimed for.");

         if(stakeCollection6[_tokenId[i]].baseRate != 0){
            address oldUser = stakeCollection6[_tokenId[i]].user;
            require(stakeCollection6[_tokenId[i]].user != msg.sender, "Token is already staked");
            for(uint j=0; j<userStakedTokenCollection6[oldUser].length; j++){
               if (userStakedTokenCollection6[oldUser][j] == _tokenId[i]){
                   userStakedTokenCollection6[oldUser][j] = 0;
               }
            }
        userStakedTokenCollection6[msg.sender].push(_tokenId[i]);
        }
        else{
        userStakedTokenCollection6[msg.sender].push(_tokenId[i]);
        }

        TokenData memory newTokenData;
        newTokenData.baseRate = basicReward;
        newTokenData.isStaked = true;
        newTokenData.user = msg.sender;

        stakeCollection6[_tokenId[i]] = newTokenData;

        bytes32 lastClaimKey = keccak256(abi.encode(_tokenId[i]));
        collection6LastClaim[lastClaimKey] = block.timestamp;

        totalStakedCollection6 = totalStakedCollection6 + 1;
        } 
        userAddressForStakedToken.push(msg.sender);
    }



    function claimRewardsForSloothRoob(uint256[] calldata _slothRoobTokenIds) public returns (uint256) {

        uint256 totalUnclaimedReward = 0;


        for(uint i = 0; i < _slothRoobTokenIds.length; i++) {

            uint256 _slothRoobTokenId = _slothRoobTokenIds[i];
            require(stake[_slothRoobTokenId].isStaked == true && stake[_slothRoobTokenId].user == msg.sender, "Token is not stake yet");


            require(iSlothRoob.ownerOf(_slothRoobTokenId) == msg.sender, "Caller does not own the token being claimed for.");

            uint256 unclaimedReward = computeUnclaimedRewardSlothRoob(_slothRoobTokenId);
            
            

            totalUnclaimedReward = totalUnclaimedReward + unclaimedReward ;

            bytes32 lastClaimKey = keccak256(abi.encode(_slothRoobTokenId));
            slothRoobLastClaim[lastClaimKey] = block.timestamp;

        }
        // mint the tokens and distribute to msg.sender
        _mint(msg.sender, totalUnclaimedReward);

        totalPaidReward += totalUnclaimedReward;

        emit RewardPaid(msg.sender, totalUnclaimedReward);

        return totalUnclaimedReward;
    }

    function claimRewardsForCollection2(uint256[] calldata _collection2TokenIds) public returns (uint256) {

        uint256 totalUnclaimedReward = 0;


        for(uint i = 0; i < _collection2TokenIds.length; i++) {

            uint256 _slothRoobTokenId = _collection2TokenIds[i];
            require(stakeCollection2[_slothRoobTokenId].isStaked == true && stakeCollection2[_slothRoobTokenId].user == msg.sender, "Token is not stake yet");


            require(iCollection2.ownerOf(_slothRoobTokenId) == msg.sender, "Caller does not own the token being claimed for.");

            uint256 unclaimedReward = computeUnclaimedRewardCollection2(_slothRoobTokenId);

            totalUnclaimedReward = totalUnclaimedReward + unclaimedReward;

            bytes32 lastClaimKey = keccak256(abi.encode(_slothRoobTokenId));
            collection2LastClaim[lastClaimKey] = block.timestamp;

        }
        // mint the tokens and distribute to msg.sender
        _mint(msg.sender, totalUnclaimedReward);
        
        totalPaidReward += totalUnclaimedReward;

        emit RewardPaid(msg.sender, totalUnclaimedReward);

        return totalUnclaimedReward;
    }

    function claimRewardsForCollection3(uint256[] calldata _collection3TokenIds) public returns (uint256) {

        uint256 totalUnclaimedReward = 0;


        for(uint i = 0; i < _collection3TokenIds.length; i++) {

            uint256 _slothRoobTokenId = _collection3TokenIds[i];
            require(stakeCollection3[_slothRoobTokenId].isStaked == true && stakeCollection3[_slothRoobTokenId].user == msg.sender, "Token is not stake yet");


            require(iCollection3.ownerOf(_slothRoobTokenId) == msg.sender, "Caller does not own the token being claimed for.");

            uint256 unclaimedReward = computeUnclaimedRewardCollection3(_slothRoobTokenId);

            totalUnclaimedReward = totalUnclaimedReward + unclaimedReward;

            bytes32 lastClaimKey = keccak256(abi.encode(_slothRoobTokenId));
            collection3LastClaim[lastClaimKey] = block.timestamp;

        }
        // mint the tokens and distribute to msg.sender
        _mint(msg.sender, totalUnclaimedReward);

        totalPaidReward += totalUnclaimedReward;

        emit RewardPaid(msg.sender, totalUnclaimedReward);

        return totalUnclaimedReward;
    }

    function claimRewardsForCollection4(uint256[] calldata _collection4TokenIds) public returns (uint256) {

        uint256 totalUnclaimedReward = 0;


        for(uint i = 0; i < _collection4TokenIds.length; i++) {

            uint256 _slothRoobTokenId = _collection4TokenIds[i];
            require(stakeCollection4[_slothRoobTokenId].isStaked == true && stakeCollection4[_slothRoobTokenId].user == msg.sender, "Token is not stake yet");


            require(iCollection4.ownerOf(_slothRoobTokenId) == msg.sender, "Caller does not own the token being claimed for.");

            uint256 unclaimedReward = computeUnclaimedRewardCollection4(_slothRoobTokenId);

            totalUnclaimedReward = totalUnclaimedReward + unclaimedReward;

            bytes32 lastClaimKey = keccak256(abi.encode(_slothRoobTokenId));
            collection4LastClaim[lastClaimKey] = block.timestamp;

        }
        // mint the tokens and distribute to msg.sender
        _mint(msg.sender, totalUnclaimedReward);

        totalPaidReward += totalUnclaimedReward;

        emit RewardPaid(msg.sender, totalUnclaimedReward);

        return totalUnclaimedReward;
    }

    function claimRewardsForCollection5(uint256[] calldata _collection5TokenIds) public returns (uint256) {

        uint256 totalUnclaimedReward = 0;


        for(uint i = 0; i < _collection5TokenIds.length; i++) {

            uint256 _slothRoobTokenId = _collection5TokenIds[i];
            require(stakeCollection5[_slothRoobTokenId].isStaked == true && stakeCollection5[_slothRoobTokenId].user == msg.sender, "Token is not stake yet");


            require(iCollection5.ownerOf(_slothRoobTokenId) == msg.sender, "Caller does not own the token being claimed for.");

            uint256 unclaimedReward = computeUnclaimedRewardCollection5(_slothRoobTokenId);

            totalUnclaimedReward = totalUnclaimedReward + unclaimedReward;

            bytes32 lastClaimKey = keccak256(abi.encode(_slothRoobTokenId));
            collection5LastClaim[lastClaimKey] = block.timestamp;

        }
        // mint the tokens and distribute to msg.sender
        _mint(msg.sender, totalUnclaimedReward);

        totalPaidReward += totalUnclaimedReward;

        emit RewardPaid(msg.sender, totalUnclaimedReward);

        return totalUnclaimedReward;
    }

    function claimRewardsForCollection6(uint256[] calldata _collection6TokenIds) public returns (uint256) {

        uint256 totalUnclaimedReward = 0;


        for(uint i = 0; i < _collection6TokenIds.length; i++) {

            uint256 _slothRoobTokenId = _collection6TokenIds[i];
            require(stakeCollection6[_slothRoobTokenId].isStaked == true && stakeCollection6[_slothRoobTokenId].user == msg.sender, "Token is not stake yet");


            require(iCollection6.ownerOf(_slothRoobTokenId) == msg.sender, "Caller does not own the token being claimed for.");

            uint256 unclaimedReward = computeUnclaimedRewardCollection6(_slothRoobTokenId);
            
            

            totalUnclaimedReward = totalUnclaimedReward + unclaimedReward;

            bytes32 lastClaimKey = keccak256(abi.encode(_slothRoobTokenId));
            collection6LastClaim[lastClaimKey] = block.timestamp;

        }
        // mint the tokens and distribute to msg.sender
        _mint(msg.sender, totalUnclaimedReward);

        totalPaidReward += totalUnclaimedReward;

        emit RewardPaid(msg.sender, totalUnclaimedReward);

        return totalUnclaimedReward;
    }

    function getUnclaimedRewardsAmountForSloothRoob(uint256[] calldata _tokenIds) public view returns (uint256) {

        uint256 totalUnclaimedRewards = 0;

        for(uint256 i = 0; i < _tokenIds.length; i++) {
            totalUnclaimedRewards += computeUnclaimedRewardSlothRoob(_tokenIds[i]);
        }

        return totalUnclaimedRewards;
    }

    function getUnclaimedRewardsAmountForCollection2(uint256[] calldata _tokenIds) public view returns (uint256) {

        uint256 totalUnclaimedRewards = 0;

        for(uint256 i = 0; i < _tokenIds.length; i++) {
            totalUnclaimedRewards += computeUnclaimedRewardCollection2(_tokenIds[i]);
        }

        return totalUnclaimedRewards;
    }

    function getUnclaimedRewardsAmountForCollection3(uint256[] calldata _tokenIds) public view returns (uint256) {

        uint256 totalUnclaimedRewards = 0;

        for(uint256 i = 0; i < _tokenIds.length; i++) {
            totalUnclaimedRewards += computeUnclaimedRewardCollection3(_tokenIds[i]);
        }

        return totalUnclaimedRewards;
    }

    function getUnclaimedRewardsAmountForCollection4(uint256[] calldata _tokenIds) public view returns (uint256) {

        uint256 totalUnclaimedRewards = 0;

        for(uint256 i = 0; i < _tokenIds.length; i++) {
            totalUnclaimedRewards += computeUnclaimedRewardCollection4(_tokenIds[i]);
        }

        return totalUnclaimedRewards;
    }

    function getUnclaimedRewardsAmountForCollection5(uint256[] calldata _tokenIds) public view returns (uint256) {

        uint256 totalUnclaimedRewards = 0;

        for(uint256 i = 0; i < _tokenIds.length; i++) {
            totalUnclaimedRewards += computeUnclaimedRewardCollection5(_tokenIds[i]);
        }

        return totalUnclaimedRewards;
    }

    function getUnclaimedRewardsAmountForCollection6(uint256[] calldata _tokenIds) public view returns (uint256) {

        uint256 totalUnclaimedRewards = 0;

        for(uint256 i = 0; i < _tokenIds.length; i++) {
            totalUnclaimedRewards += computeUnclaimedRewardCollection6(_tokenIds[i]);
        }

        return totalUnclaimedRewards;
    }

    function getSloothRoobLastClaimedTime(uint256 _tokenId) public view returns (uint256) {

        bytes32 lastClaimKey = keccak256(abi.encode(_tokenId));

        return slothRoobLastClaim[lastClaimKey];
    }

    function getCollection2LastClaimedTime(uint256 _tokenId) public view returns (uint256) {

        bytes32 lastClaimKey = keccak256(abi.encode(_tokenId));

        return collection2LastClaim[lastClaimKey];
    }

    function getCollection3LastClaimedTime(uint256 _tokenId) public view returns (uint256) {

        bytes32 lastClaimKey = keccak256(abi.encode(_tokenId));

        return collection3LastClaim[lastClaimKey];
    }

    function getCollection4LastClaimedTime(uint256 _tokenId) public view returns (uint256) {

        bytes32 lastClaimKey = keccak256(abi.encode(_tokenId));

        return collection4LastClaim[lastClaimKey];
    }

    function getCollection5LastClaimedTime(uint256 _tokenId) public view returns (uint256) {

        bytes32 lastClaimKey = keccak256(abi.encode(_tokenId));

        return collection5LastClaim[lastClaimKey];
    }

    function getCollection6LastClaimedTime(uint256 _tokenId) public view returns (uint256) {

        bytes32 lastClaimKey = keccak256(abi.encode(_tokenId));

        return collection6LastClaim[lastClaimKey];
    }

    function getListOfUsers() public view returns (address [] memory) {
        return userAddressForStakedToken;
    }

    function getUserStakedToken(address user) public view returns (uint256[] memory) {
        return userStakedToken[user];
    }

    function getUserStakedTokenForCollection2(address user) public view returns (uint256[] memory) {
        return userStakedTokenCollection2[user];
    }

    function getUserStakedTokenForCollection3(address user) public view returns (uint256[] memory) {
        return userStakedTokenCollection3[user];
    }

    function getUserStakedTokenForCollection4(address user) public view returns (uint256[] memory) {
        return userStakedTokenCollection4[user];
    }

    function getUserStakedTokenForCollection5(address user) public view returns (uint256[] memory) {
        return userStakedTokenCollection5[user];
    }

    function getUserStakedTokenForCollection6(address user) public view returns (uint256[] memory) {
        return userStakedTokenCollection6[user];
    }


    function computeAccumulatedReward(uint256 _lastClaimDate, uint256 currentTime) internal pure returns (uint256) {
        require(currentTime > _lastClaimDate, "Last claim date must be smaller than block timestamp");

        uint256 secondsElapsed = currentTime - _lastClaimDate;
        uint256 accumulatedReward = (secondsElapsed * 10 ** 18 ) / 1 days;
        // uint256 accumulatedReward = (secondsElapsed * 10 ** 18 ) / 15; //for testing
        
        return accumulatedReward;
    }

    function computeUnclaimedRewardSlothRoob(uint256 _tokenId) internal view returns (uint256) {
        uint256 extraBouns = 0;

        // Will revert if tokenId does not exist
        iSlothRoob.ownerOf(_tokenId);

        if(stake[_tokenId].isStaked == true){

        // build the hash for lastClaim based on contractAddress and tokenId
        bytes32 lastClaimKey = keccak256(abi.encode(_tokenId));
        uint256 lastClaimDate = slothRoobLastClaim[lastClaimKey];

        // if there has been a lastClaim, compute the value since lastClaim
        uint256 time = computeAccumulatedReward(lastClaimDate, block.timestamp);
        uint256 reward = time * stake[_tokenId].baseRate;

        uint256 daysPass = time / 10 ** 18 ;
        if(daysPass >=15 && daysPass < 30){
        extraBouns = ( 5 * reward ) / 100;
        }else if (daysPass >= 30 ){
            extraBouns = ( 15 * reward ) / 100;
        }
        // return  () + extraBouns;   
        return  reward + extraBouns;   
        }else{
            return 0;
        }
    }

    function computeUnclaimedRewardCollection2(uint256 _tokenId) internal view returns (uint256) {
        uint256 extraBouns = 0;

        // Will revert if tokenId does not exist
        iCollection2.ownerOf(_tokenId);

        if(stakeCollection2[_tokenId].isStaked == true){

        // build the hash for lastClaim based on contractAddress and tokenId
        bytes32 lastClaimKey = keccak256(abi.encode(_tokenId));
        uint256 lastClaimDate = collection2LastClaim[lastClaimKey];

        // if there has been a lastClaim, compute the value since lastClaim
        uint256 time = computeAccumulatedReward(lastClaimDate, block.timestamp);
        uint256 reward = time * stakeCollection2[_tokenId].baseRate;

        uint256 daysPass = time / 10 ** 18 ;
        if(daysPass >=15 && daysPass < 30){
        extraBouns = ( 5 * reward ) / 100;
        }else if (daysPass >= 30 ){
            extraBouns = ( 15 * reward ) / 100;
        }

        return reward + extraBouns;  
        }else{
            return 0;
        }
    }

    function computeUnclaimedRewardCollection3(uint256 _tokenId) internal view returns (uint256) {
        uint256 extraBouns = 0;

        // Will revert if tokenId does not exist
        iCollection3.ownerOf(_tokenId);

        if(stakeCollection3[_tokenId].isStaked == true){

        // build the hash for lastClaim based on contractAddress and tokenId
        bytes32 lastClaimKey = keccak256(abi.encode(_tokenId));
        uint256 lastClaimDate = collection3LastClaim[lastClaimKey];

        // if there has been a lastClaim, compute the value since lastClaim
        uint256 time = computeAccumulatedReward(lastClaimDate, block.timestamp);
        uint256 reward = time * stakeCollection3[_tokenId].baseRate;


        uint256 daysPass = time / 10 ** 18;
        if(daysPass >=15 && daysPass < 30){
        extraBouns = ( 5 * reward ) / 100;
        }else if (daysPass >= 30 ){
            extraBouns = ( 15 * reward ) / 100;
        }
        
        return reward + extraBouns;   
        }else{
            return 0;
        }
    }

    function computeUnclaimedRewardCollection4(uint256 _tokenId) internal view returns (uint256) {
        uint256 extraBouns = 0;

        // Will revert if tokenId does not exist
        iCollection4.ownerOf(_tokenId);

        if(stakeCollection4[_tokenId].isStaked == true){

        // build the hash for lastClaim based on contractAddress and tokenId
        bytes32 lastClaimKey = keccak256(abi.encode(_tokenId));
        uint256 lastClaimDate = collection4LastClaim[lastClaimKey];

        // if there has been a lastClaim, compute the value since lastClaim
        uint256 time = computeAccumulatedReward(lastClaimDate, block.timestamp);
        uint256 reward = time * stakeCollection4[_tokenId].baseRate;

        uint256 daysPass = time / 10 ** 18;
        if(daysPass >=15 && daysPass < 30){
        extraBouns = ( 5 * reward ) / 100;
        }else if (daysPass >= 30 ){
            extraBouns = ( 15 * reward ) / 100;
        }

        return reward + extraBouns;
        }else{
            return 0;
        }
    }

    function computeUnclaimedRewardCollection5(uint256 _tokenId) internal view returns (uint256) {
        uint256 extraBouns = 0;

        // Will revert if tokenId does not exist
        iCollection5.ownerOf(_tokenId);

        if(stakeCollection5[_tokenId].isStaked == true){

        // build the hash for lastClaim based on contractAddress and tokenId
        bytes32 lastClaimKey = keccak256(abi.encode(_tokenId));
        uint256 lastClaimDate = collection5LastClaim[lastClaimKey];

        // if there has been a lastClaim, compute the value since lastClaim
        uint256 time = computeAccumulatedReward(lastClaimDate, block.timestamp);
        uint256 reward = time * stakeCollection5[_tokenId].baseRate;


        uint256 daysPass = time / 10 ** 18;
        if(daysPass >=15 && daysPass < 30){
        extraBouns = ( 5 * reward ) / 100;
        }else if (daysPass >= 30 ){
            extraBouns = ( 15 * reward ) / 100;
        }

        return reward + extraBouns;
        }else{
            return 0;
        }
    }

    function computeUnclaimedRewardCollection6(uint256 _tokenId) internal view returns (uint256) {
        uint256 extraBouns = 0;

        // Will revert if tokenId does not exist
        iCollection6.ownerOf(_tokenId);

        if(stakeCollection6[_tokenId].isStaked == true){

        // build the hash for lastClaim based on contractAddress and tokenId
        bytes32 lastClaimKey = keccak256(abi.encode(_tokenId));
        uint256 lastClaimDate = collection6LastClaim[lastClaimKey];

        // if there has been a lastClaim, compute the value since lastClaim
        uint256 time = computeAccumulatedReward(lastClaimDate, block.timestamp);
        uint256 reward = time * stakeCollection6[_tokenId].baseRate;


        uint256 daysPass = time / 10 ** 18;
        if(daysPass >=15 && daysPass < 30){
        extraBouns = ( 5 * reward ) / 100;
        }else if (daysPass >= 30 ){
            extraBouns = ( 15 * reward ) / 100;
        }
         
        return reward + extraBouns;   
        }else{
            return 0;
        }
    }

    function setSloothRoobAddress(address _slothRoobAddress) public {
        require(msg.sender == adminAddress || msg.sender == owner(), "Invalid sender");
	    SlothRoobContractAddress = _slothRoobAddress;
        iSlothRoob =  ISlothRoob(_slothRoobAddress);
	}

    function setCollection2Address(address _collection2Address) public {
        require(msg.sender == adminAddress || msg.sender == owner(), "Invalid sender");
        iCollection2 =  ISlothRoob(_collection2Address);
	}

    function setCollection3Address(address _collection3Address) public {
        require(msg.sender == adminAddress || msg.sender == owner(), "Invalid sender");
        iCollection3 =  ISlothRoob(_collection3Address);
	}

    function setCollection4Address(address _collection4Address) public {
        require(msg.sender == adminAddress || msg.sender == owner(), "Invalid sender");
        iCollection4 =  ISlothRoob(_collection4Address);
	}

    function setCollection5Address(address _collection5Address) public {
        require(msg.sender == adminAddress || msg.sender == owner(), "Invalid sender");
        iCollection5 =  ISlothRoob(_collection5Address);
	}

    function setCollection6Address(address _collection6Address) public {
        require(msg.sender == adminAddress || msg.sender == owner(), "Invalid sender");
        iCollection6 =  ISlothRoob(_collection6Address);
	}
}