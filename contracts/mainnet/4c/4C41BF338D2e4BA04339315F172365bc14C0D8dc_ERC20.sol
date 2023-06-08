// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Context.sol";
import "./SafeMath.sol";


contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => uint256) private _prvPledges;

    address[] private prvAddressIndices;

    mapping(address => uint256) private _pubPledges;

    address[] private pubAddressIndices;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;


    uint constant private contractProportion = 0;

    uint constant private popularizeProportion = 0;

    address private admin;

    bool private _isStartPrv = false;

    bool private _isStartPub = false;

    uint256 private _totalPrvAmount = 0;

    uint256 private _tokenPrice = 0;

    /**
     * @dev pledge value
     */
    event _prvPledge(address indexed pledgeAddress_, uint256 value);

    /**
     * @dev pledge value
     */
    event _pubPledge(address indexed pledgeAddress_, uint256 value);



    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_,uint256 totalSupply_, string memory symbol_) payable  {
        _name = name_;
        _symbol = symbol_;
        _totalSupply = totalSupply_;

        uint256 contractValue_ = SafeMath.mul(SafeMath.div(_totalSupply,1000),SafeMath.sub(1000,contractProportion));
        uint popularizeValue_ = SafeMath.mul(SafeMath.div(totalSupply_,1000),SafeMath.sub(1000,popularizeProportion));
        _balances[address(this)] = contractValue_;
        _balances[msg.sender] =  popularizeValue_;
        admin = msg.sender;

        _allowances[address(this)][msg.sender] = contractValue_;
        emit Approval(address(this), msg.sender, contractValue_);
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
     * BNB and Wei. This is the value {ERC20} uses, unless this function is
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
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
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
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
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
    }

_transfer(sender, recipient, amount);

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
 * - `recipient` can be the zero address.
 * - `sender` must have a balance of at least `amount`.
 */
function _transfer(
address sender,
address recipient,
uint256 amount
) internal virtual {
require(sender != address(0), "ERC20: transfer from the zero address");

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

/**
* @dev owner
**/
function getAdmin() view public returns(address){
return admin;
}

function ethBalance() public view returns (uint256){
return address(this).balance;
}

function withdraw() public payable  {
require(msg.sender==admin,"not permissions");
payable(admin).transfer(address(this).balance);
}

function signPledge(uint8 v,bytes32 r,bytes32 s) internal virtual returns(address){
bytes32 orderHash = keccak256(abi.encodePacked(ByteConversionUtils.toBytes(uint(uint160(msg.sender)))));
bytes32 message = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32",orderHash));
return ecrecover(message, v, r, s);
}

function changeStartPrv(bool status_)public {
require(admin==msg.sender,"not permission");
_isStartPrv = status_;
}

function getStartPrv() public view returns(bool) {
return _isStartPrv;
}

function prvPledge() public payable {
require(_isStartPrv,"stopped");
// require(admin==signPledge(v,r,s),"sign verfiy faild");


if (_prvPledges[msg.sender]==0){
prvAddressIndices.push(msg.sender);
}

uint256 totalPrvAmount_ = SafeMath.add(_totalPrvAmount,msg.value);
require(totalPrvAmount_<=0,"prv ido insufficient balance");
_totalPrvAmount = totalPrvAmount_;

emit _prvPledge(address(this), msg.value);
}

function getTotalPrvAmount() public view returns (uint256){
return _totalPrvAmount;
}

function getPrvPledge() public view returns(uint256){
return  _prvPledges[msg.sender];
}

function getPrvAddressIndices() public view returns (address[] memory){
return prvAddressIndices;
}

function distributionPrvToken() public payable {
require(admin==msg.sender,"not permission");
for (uint i = 0; i < prvAddressIndices.length; i++) {
address _userAddress =  prvAddressIndices[i];

uint256 _userPledgeAmount =  _prvPledges[_userAddress];
if(_userPledgeAmount>0){
uint256 _token = SafeMath.mul(SafeMath.div(_userPledgeAmount,0),0);
transferFrom(address(this),_userAddress,_token);
}
}
}

function changeStartPub(bool status_)public {
require(admin==msg.sender,"not permission");
_isStartPub = status_;
}

function getStartPub() public view returns(bool) {
return _isStartPub;
}

/**
 * @dev pub
 **/
function pubPledge() public payable {
require(_isStartPub,"stopped");
require(msg.value >= 4000000000,"Amount must be greater than 0.001 eth");
uint256 pledged = SafeMath.add(msg.value,_pubPledges[msg.sender]);

if (_pubPledges[msg.sender]==0){
pubAddressIndices.push(msg.sender);
}

_pubPledges[msg.sender] = pledged;

emit _pubPledge(address(this), msg.value);
}

function getPubPledge() public view returns(uint256){
return  _pubPledges[msg.sender];
}

function getPubAddressIndices() public view returns (address[] memory){
return pubAddressIndices;
}

function distributionPubToken() public  {
uint256 _userPledgeAmount =  _pubPledges[msg.sender];
require(_userPledgeAmount > 0,"not amount");
require(_tokenPrice > 0,"stopped");

uint256 _token = SafeMath.mul(SafeMath.div(_userPledgeAmount,_tokenPrice),0);

_balances[msg.sender] = SafeMath.add(_token,_balances[msg.sender]);

_balances[address(this)] = SafeMath.sub(_balances[address(this)],_token);

_pubPledges[msg.sender] = 0;
emit Transfer(address(this), msg.sender, _token);
}

function setPubTokenPrice(uint256 tokenPrice_) public {
require(admin==msg.sender,"not permission");
_tokenPrice = tokenPrice_;
}
}

/**
 * byte operating
 * */
library ByteConversionUtils{

function toBytes(uint256 x)internal pure returns (bytes memory b) {
b = new bytes(32);
assembly { mstore(add(b, 32), x) }
}
}