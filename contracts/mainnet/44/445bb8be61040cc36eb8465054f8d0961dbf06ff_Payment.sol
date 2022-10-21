/**
 *Submitted for verification at Etherscan.io on 2022-10-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

abstract contract Context {

    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256); 
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}

contract Ownable is Context {

    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }   
    
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function renouncedOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0x000000000000000000000000000000000000dEaD));
        _owner = address(0x000000000000000000000000000000000000dEaD);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        _status = _NOT_ENTERED;
    }

    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

contract Payment is Ownable, ReentrancyGuard {

    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event ERC20PaymentReleased(IERC20 indexed token, address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    uint256 private _totalShares;
    uint256 private _totalReleased;
    mapping (address => uint256) private _shares;
    mapping (address => uint256) private _released;
    address[] private _payees;
    mapping(IERC20 => uint256) private _erc20TotalReleased;
    mapping(IERC20 => mapping(address => uint256)) private _erc20Released;

    bool public paused;

    function deposit() public payable {}

    function addWallets(address[] memory payees, uint256[] memory shares_) public payable onlyOwner {
        require(payees.length == shares_.length, "PaymentSplitter: payees and shares length mismatch");
        require(payees.length > 0, "PaymentSplitter: no payees");

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
    }

    function _addPayee(address account, uint256 shares_) private {
        require(account != address(0), "PaymentSplitter: account is the zero address");
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(_shares[account] == 0, "PaymentSplitter: account already has shares");

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(account, shares_);
    }

    // function removeWallet(address account,address _token) public onlyOwner {
    //     require(account != address(0), "PaymentSplitter: account is the zero address");
    //     require(_shares[account] != 0, "PaymentSplitter: account already has no shares");
    //     uint _currentShare = _shares[account];
    //     // uint _currentReleased = _released[account];
    //     for(uint i = 0; i < _payees.length; i++) {
    //         if(_payees[i] == account) {
    //             _payees[i] = _payees[_payees.length - 1];
    //             _payees.pop();
    //             _shares[account] = 0;
    //             // _released[account] = 0;
    //             _totalShares = _totalShares - _currentShare;
    //             // _totalReleased = _totalReleased - _currentReleased;
    //             break;
    //         }
    //     }
    // }

    //native
    function release(address account) public nonReentrant() {
        require(!paused,"Contract is Paused!!");
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 payment = releasable(account);

        require(payment != 0, "PaymentSplitter: account is not due payment");

       _totalReleased += payment;

        unchecked {
            _released[account] += payment;
        }

        (bool os,) = payable(account).call{value: payment}("");
        require(os);
        emit PaymentReleased(account, payment);
    }

    //token
    function releaseErc20(IERC20 token, address account) public nonReentrant(){
        require(!paused,"Contract is Paused!!");
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 payment = releasableErc20(token, account);

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _erc20TotalReleased[token] += payment;
        unchecked {
            _erc20Released[token][account] += payment;
        }

        token.transfer(account, payment);
        emit ERC20PaymentReleased(token, account, payment);
    }

    function releasableErc20(IERC20 token, address account) public view returns (uint256) {
        uint256 totalReceived = token.balanceOf(address(this)) + totalErc20Released(token);
        return _pendingPayment(account, totalReceived, releasedErc20(token, account));
    }

    function totalErc20Released(IERC20 token) public view returns (uint256) {
        return _erc20TotalReleased[token];
    }

    function releasedErc20(IERC20 token, address account) public view returns (uint256) {
        return _erc20Released[token][account];
    }

    function releasable(address account) public view returns (uint256) {
        uint256 totalReceived = address(this).balance + totalReleased();
        return _pendingPayment(account, totalReceived, released(account));
    }

    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    function checkShare(address _wallet) public view returns (uint256) {
        return _shares[_wallet];
    }

    function totalShares() public view returns (uint256) {
        return _totalShares;
    }
   

    function totalPayee() public view returns (uint) {
        return _payees.length;
    }

    receive() external payable {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    function _pendingPayment(
        address account,
        uint256 totalReceived,
        uint256 alreadyReleased
    ) private view returns (uint256) {
        return (totalReceived * _shares[account]) / _totalShares - alreadyReleased;
    }

    function rescueFunds() public onlyOwner {
        (bool os,) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function rescueTokens(IERC20 _token) public onlyOwner {
        uint balance = _token.balanceOf(address(this));
        _token.transfer(owner(),balance);
    }

    function enablePauser(bool _status) public onlyOwner {
        paused = _status;
    }

    function checkContractToken(IERC20 _token) public view returns (uint) {
        return _token.balanceOf(address(this));
    }

    function checkBalance() public view returns (uint) {
        return address(this).balance;
    }


}