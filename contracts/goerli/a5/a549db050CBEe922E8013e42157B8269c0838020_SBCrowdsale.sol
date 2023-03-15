/**
 *Submitted for verification at Etherscan.io on 2023-03-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

interface IERC20Permit {
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(address owner) external view returns (uint256);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
}


interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Pausable is Context {
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    constructor() {
        _paused = false;
    }

    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    modifier whenPaused() {
        _requirePaused();
        _;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

contract Crowdsale is Context, ReentrancyGuard {
    using SafeERC20 for IERC20;
    
    // The token being sold
    IERC20 private _token;
    IERC20 public USDT;

    // Address where funds are collected
    address payable private _wallet;
    address payable public _manager;

    uint256 public minBuy       = 100_000 * 1e18; 
    uint256 public maxBuy       = 5_000_000 * 1e18;
    uint256 public sale_price   = 0.0001 * 1e18;

    // Amount of wei raised
    uint256 public _weiRaised;
    uint256 public _tokenPurchased;
    bool public success;
    bool public finalized;
    bool public _buyable;
    
    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    
    mapping (address => uint256) public purchase;
    mapping (address => uint256) public claimed;
    mapping (address => uint256) public msgValue;

    uint256 current = block.timestamp * 1 seconds;

    uint256 public immutable buyTime;           //  60 days
    uint256 public immutable limitationtime ;   // 180 days
    uint256 public immutable claimeTime;        // 150 days
    
    constructor (uint256 buyTime_, uint256 lockTime, uint256 claimTime_, address payable manager_, 
        IERC20 token_, address payable wallet_) {
        require(address(token_) != address(0), "Crowdsale: token is the zero address");

        _manager = manager_;
        _token = token_;
        _wallet = wallet_;

        buyTime = block.timestamp + buyTime_ * 1 seconds;
        limitationtime = block.timestamp + (buyTime_ + lockTime) * 1 seconds;
        claimeTime = block.timestamp + (buyTime_ + lockTime + claimTime_) * 1 seconds;

        USDT = IERC20(0x509Ee0d083DdF8AC028f2a56731412edD63223B9);   // USDT address on Ethereum mainnet
    }
    
    /**
     * @dev fallback function ***DO NOT OVERRIDE***
     * Note that other contracts will transfer funds with a base gas stipend
     * of 2300, which is not enough to call buyTokens. Consider calling
     * buyTokens directly when purchasing tokens from a contract.
     */

    receive () external payable {
    }

    /**
     * @return the token being sold.
     */
    function token() public view returns (IERC20) {
        return _token;
    }

    /**
     * @return the address where funds are collected.
     */
    function wallet() public view returns (address payable) {
        return _wallet;
    }

    function getPrice() public view returns(uint256){
        return (10**18) / sale_price;
    }

    /**
     * @return the amount of wei raised.
     */
    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }

    function buyable()public returns(bool) { 
        if(buyTime > block.timestamp){
            _buyable = true;
        }
        return _buyable;
    }

    function buyTokens(uint256 amount) public nonReentrant {
        require(buyTime > block.timestamp, "Buy Time expired");
        require(amount >= minBuy && amount <= maxBuy,"Wrong amount range.");

        uint256 one = 1 ether;
        uint256 tokens =  (one * amount) / sale_price;
        require(_token.balanceOf(address(this)) >= tokens, "buy amount exceeds not enough Tokens remaining");

        USDT.safeTransferFrom(_msgSender(), address(this), amount);

        _tokenPurchased = _tokenPurchased + tokens;
        _weiRaised = _weiRaised + amount;
        
        msgValue[_msgSender()] = msgValue[_msgSender()] + amount;
        purchase[_msgSender()] = purchase[_msgSender()] + tokens;
    }

    function pendingTokens(address account) public view returns (uint256) {
        uint value;
        if (block.timestamp < limitationtime)
            value = 0;
        else if (block.timestamp >= claimeTime) {
            value = purchase[account] - claimed[account];
        }
        else {
            uint initValue = purchase[account] / 5;
            uint remainValue = purchase[account] - initValue;

            value = initValue;
            value += remainValue * (block.timestamp - limitationtime) / (claimeTime - limitationtime);
            value -= claimed[account];
        }

        return value;
    }

    function claim() public nonReentrant {
        require (block.timestamp > limitationtime);
        require (finalized,"IDO not finalized yet");

        uint256 tokenAmount = pendingTokens(_msgSender());  
        require (tokenAmount > 0, "0 tokens to claim");
        require(_token.balanceOf(address(this)) >= tokenAmount, "claim amount exceeds not enough Tokens remaining");

        _token.safeTransfer(_msgSender(), tokenAmount);

        claimed[_msgSender()] += tokenAmount;
    }
    
    function balance() public view returns(uint){
        return _token.balanceOf(address(this));
    }

    function finalize() public nonReentrant {
        require( buyTime < block.timestamp, "the crowdSale is in progress");
        require(!finalized,"already finalized");
        require(_msgSender() == _manager,"you are not the owner");

         uint256 remainingTokensInTheContract = _token.balanceOf(address(this)) - _tokenPurchased;
        _token.safeTransfer(address(_wallet), remainingTokensInTheContract);

        _forwardFunds(_weiRaised);
        finalized = true;
    }

    /**
     * @dev Determines how ETH is stored/forwarded on purchases.
     */
    function _forwardFunds(uint256 amount) internal {
      USDT.safeTransfer(_wallet, amount);
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
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

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
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

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
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

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


interface SOLIDBLOCK {
    function excludeFromFees(address account, bool excluded) external;
}

library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}


contract WhitelistAdminRole is Context {
    using Roles for Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    Roles.Role private _whitelistAdmins;

    constructor ()  {
        _addWhitelistAdmin(_msgSender());
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(_msgSender()), "WhitelistAdminRole: caller does not have the WhitelistAdmin role");
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
        _addWhitelistAdmin(account);
    }

    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(_msgSender());
    }

    function _addWhitelistAdmin(address account) internal {
        _whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    }

    function _removeWhitelistAdmin(address account) internal {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
}

contract WhitelistedRole is Context, WhitelistAdminRole {
    using Roles for Roles.Role;

    event WhitelistedAdded(address indexed account);
    event WhitelistedRemoved(address indexed account);

    Roles.Role private _whitelisteds;

    modifier onlyWhitelisted() {
        require(isWhitelisted(_msgSender()), "WhitelistedRole: caller does not have the Whitelisted role");
        _;
    }

    function isWhitelisted(address account) public view returns (bool) {
        return _whitelisteds.has(account);
    }

    function addWhitelisted(address account) public onlyWhitelistAdmin {
        _addWhitelisted(account);
    }

    function removeWhitelisted(address account) public onlyWhitelistAdmin {
        _removeWhitelisted(account);
    }

    function renounceWhitelisted() public {
        _removeWhitelisted(_msgSender());
    }

    function _addWhitelisted(address account) internal {
        _whitelisteds.add(account);
        emit WhitelistedAdded(account);
    }

    function _removeWhitelisted(address account) internal {
        _whitelisteds.remove(account);
        emit WhitelistedRemoved(account);
    }
}


contract SBCrowdsale is Context, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    SOLIDBLOCK token;
    address public ico_addr;
    address[] public rounds;
    uint256[] public roundAmount;

    event CreateTokenSale(uint256 locktime, uint256 amount, uint256 noRounds);
    event WithdrawToken(address recipient, uint256 amountToken);

    constructor() {
        token = SOLIDBLOCK(0xB24D4586eE515CF95145a7f7Aab9AAD5e137cA40);
    }

    receive() external payable {}

    function noRounds() public view returns (uint256) {
        return rounds.length;
    }

    function setToken() public onlyOwner {
        token = SOLIDBLOCK(0xB24D4586eE515CF95145a7f7Aab9AAD5e137cA40);
    }

    function getToken() public view returns (address) {
        return address(token);
    }

    function transfer(address recipient, uint256 amount)
        public
        payable
        virtual
        onlyOwner
        returns (bool) {
        require(amount <= IERC20(address(token)).balanceOf(address(this)), "not enough amount");
        IERC20(address(token)).safeTransfer(recipient, amount);
        return true;
    }

    function create_TokenSale(
        uint256 buyTime,
        uint256 lockTime,
        uint256 claimTime,
        uint256 amount
    ) public onlyOwner {
        require(getToken() != address(0), "set Token for Sale");

        if (rounds.length > 0) {
            bool status = isSaleFinalized();
            require(status == true, "Sale in progress");
        }

        require(amount <= IERC20(address(token)).balanceOf(address(this)), "not enough amount");

        Crowdsale ico;
        ico = new Crowdsale(
            buyTime,
            lockTime,
            claimTime,
            payable(owner()),
            IERC20(address(token)),
            payable(owner())
        );
        ico_addr = address(ico);

        token.excludeFromFees(ico_addr, true);

        require(transfer(ico_addr, amount));

        rounds.push(ico_addr);
        roundAmount.push(amount);

        emit CreateTokenSale(lockTime, amount, rounds.length);
    }

    function totalRoundSaleInfo() public view returns (uint256, uint256, uint256) {
        uint256 length = rounds.length;
        uint256 totalAmountToken;
        uint256 totalAmountPurchased;
        uint256 totalAmountFunds;
        for (uint8 i=0; i<length; i++) {
            (uint256 amountToken, uint256 amountPurchased, uint256 amountFunds) = roundSaleInfo(i);
            totalAmountToken += amountToken;
            totalAmountPurchased += amountPurchased;
            totalAmountFunds += amountFunds;
        }

        return (totalAmountToken, totalAmountPurchased, totalAmountFunds);
    }

    function roundSaleInfo(uint8 index) public view returns (uint256, uint256, uint256) {
        require(index < rounds.length, "Wrong Round Index.");
        uint256 amountToken;
        uint256 amountPurchased;
        uint256 amountFunds;

        amountToken += roundAmount[index];

        address sale_addr = rounds[index];
        Crowdsale sale = Crowdsale(payable(sale_addr));
        amountPurchased += sale._tokenPurchased();
        amountFunds += sale._weiRaised();

        return (amountToken, amountPurchased, amountFunds);
    }

    function isSaleFinalized() public view returns (bool) {
        require(rounds.length > 0, "No round");

        address sale_addr = rounds[rounds.length - 1];
        Crowdsale sale = Crowdsale(payable(sale_addr));

        return sale.finalized();
    }

    function withdrawToken() public onlyOwner {
        uint256 remainingTokensInTheContract = IERC20(address(token)).balanceOf(address(this));
        IERC20(address(token)).safeTransfer(msg.sender, remainingTokensInTheContract);

        emit WithdrawToken(msg.sender, remainingTokensInTheContract);
    }
}