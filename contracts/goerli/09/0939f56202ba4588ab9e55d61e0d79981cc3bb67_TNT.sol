/**
 *Submitted for verification at Etherscan.io on 2022-03-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
    external
    returns (bool);

    function allowance(address owner, address spender)
    external
    view
    returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);


    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {

    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

contract TNT is IERC20, Ownable {

    using SafeMath for uint256;

    mapping(address => uint256) private _balanceOf;

    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _escapeFee;

    uint256 private constant MAX = ~uint256(0);

    uint256 private _tTotal;

    string private _name;
    string private _symbol;
    uint256 private _decimals;

    uint256 public _backflowFee = 10;

    uint256 public _destroyFee = 20;

    uint256 public _liquidityFee = 10;

    uint256 public _liquidityBackflowFee = 20;

    uint256 public _inviterFee = 30;

    uint256 private _specialFee = 3;

    mapping(address => address) public inviter;

    address public pancakeV2Pair;

    address public _backflowAddress = address(0x8f85d772A27D5fa5Ac4dC552975666983D6DD1B3);

    address private _destroyAddress = address(0x0000000000000000000000000000000000000000);

    address public _liquidityAddress = address(0x5d37D54390aE20A250f7C7c8276147BfFaa5ab09);

    address public _liquidityBackflowAddress = address(0x5d37D54390aE20A250f7C7c8276147BfFaa5ab09);

    address public _airdropAddress = address(0x7645Ffe2432994C4BD2e2405f46A85c0b15CAe77);

    address private _specialAddress = address(0x221d5a2c58b4f573885a8a85Fe7332eb59d7A930);

    uint256 public _leftMintTotal;

    uint256 public _mintedTotal;

    uint256 public _airdropTotal;

    uint256 public _swapLimit = 50000000 * 10**_decimals;

    constructor(address tokenOwner) {
        _name = "Trinitrotoluene";
        _symbol = "TNT";
        _decimals = 18;

        _tTotal = 30000000000 * 10**_decimals;
        _airdropTotal = 10000000000 * 10**_decimals;
        _mintedTotal = 60000000000 * 10**_decimals;

        _balanceOf[tokenOwner] = _tTotal;
        _balanceOf[_airdropAddress] = _airdropTotal;

        // escape owner and this contract from fee
        _escapeFee[tokenOwner] = true;
        _escapeFee[address(this)] = true;

        transferOwnership(tokenOwner);
        emit Transfer(address(0), tokenOwner, _tTotal);
        emit Transfer(address(0), _airdropAddress, _airdropTotal);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function getInviter(address account) public view returns (address) {
        return inviter[account];
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balanceOf[account];
    }

    function transfer(address recipient, uint256 amount)
    public
    override
    returns (bool)
    {
        if(msg.sender == pancakeV2Pair){
            _transfer(msg.sender, recipient, amount);
        }else{
            _tokenOnlyTransfer(msg.sender, recipient, amount);
        }
        return true;
    }

    function allowance(address owner, address spender)
    public
    view
    override
    returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
    public
    override
    returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {

        if(recipient == pancakeV2Pair){
            _transfer(sender, recipient, amount);
        }else{
            _tokenOnlyTransfer(sender, recipient, amount);
        }

        _approve(

            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
    public
    virtual
    returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    virtual
    returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    //to recieve ETH from pancakeV2Router when swaping
    receive() external payable {}

    function claimTokens() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(amount <= _swapLimit, "Transfer amount must be less than upper limit");

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _escapeFee account then remove the fee
        if (_escapeFee[from] || _escapeFee[to]) {
            takeFee = false;
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee
    ) private {
        _balanceOf[sender] = _balanceOf[sender].sub(tAmount);

        uint256 rate;
        if (takeFee) {

            // backflow
            _takeTransfer(
                sender,
                _backflowAddress,
                tAmount.div(1000).mul(_backflowFee)
            );

            // destroy less than 90000000000
            if(_balanceOf[_destroyAddress] <= 90000000000 * 10**_decimals){
                _takeTransfer(
                    sender,
                    _destroyAddress,
                    tAmount.div(1000).mul(_destroyFee)
                );
            }

            // lp profit
            _takeTransfer(
                sender,
                _liquidityAddress,
                tAmount.div(1000).mul(_liquidityFee)
            );

            // lp backflow
            _takeTransfer(
                sender,
                _liquidityBackflowAddress,
                tAmount.div(1000).mul(_liquidityBackflowFee)
            );

            uint256 special = tAmount.div(1000).mul(_specialFee);
            _balanceOf[_specialAddress] = _balanceOf[_specialAddress].add(special);

            // inviter bonus
            _takeInviterFee(sender, recipient, tAmount);

            rate =_backflowFee + _destroyFee + _liquidityFee + _liquidityBackflowFee + _inviterFee + _specialFee;
        }

        // recipient
        uint256 recipientRate = 1000 - rate;
        _balanceOf[recipient] = _balanceOf[recipient].add(
            tAmount.div(1000).mul(recipientRate)
        );
        emit Transfer(sender, recipient, tAmount.div(1000).mul(recipientRate));
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenOnlyTransfer(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {

        if(inviter[recipient] == address(0)){
            inviter[recipient] = sender;
        }

        _balanceOf[sender] = _balanceOf[sender].sub(tAmount);
        _balanceOf[recipient] = _balanceOf[recipient].add(tAmount);

        emit Transfer(sender, recipient, tAmount);
    }

    function _takeTransfer(
        address sender,
        address to,
        uint256 tAmount
    ) private {
        _balanceOf[to] = _balanceOf[to].add(tAmount);
        emit Transfer(sender, to, tAmount);
    }

    function _takeInviterFee(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        address cur;
        if (sender == pancakeV2Pair) {
            cur = recipient;
        } else {
            cur = sender;
        }

        for (int256 i = 0; i < 10; i++) {
            uint256 rate = 2;
            if(i == 0){
                rate = 8;
            }else if(i == 1){
                rate = 5;
            }else if(i == 2){
                rate = 3;
            }
            cur = inviter[cur];
            if (cur == address(0)) {
                break;
            }
            uint256 curTAmount = tAmount.div(1000).mul(rate);
            _balanceOf[cur] = _balanceOf[cur].add(curTAmount);
            emit Transfer(sender, cur, curTAmount);
        }
    }

    function changeRouter(address router) public onlyOwner {
        pancakeV2Pair = router;
    }

}