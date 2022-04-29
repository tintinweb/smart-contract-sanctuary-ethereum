/**
 *Submitted for verification at Etherscan.io on 2022-04-29
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

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

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

 contract Pausable is Ownable {

    event Paused(address account);

    event Unpaused(address account);

    bool private _paused;

    constructor() {
        _paused = false;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    function pause() external onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    function unpause() external onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

contract presale is Pausable{

    address public ElonOneToken;
    uint256 public TokenPerETH;
    address public treasury;

    constructor(address _elonToken, uint256 _tokenPerEth, address _treasuryWallet) {
        require(_elonToken != address(0x0),"Invalid address");
        require(_treasuryWallet != address(0x0),"Invalid address");
        ElonOneToken = _elonToken;
        TokenPerETH = _tokenPerEth;
        treasury = _treasuryWallet;
    }

    function swap() external payable whenNotPaused {
        require(msg.value > 0,"Invalid amount");
        uint256 swapAmount = viewSwapingAmount(msg.value);
        IERC20(ElonOneToken).transfer(_msgSender(), swapAmount);
        require(payable(treasury).send(msg.value),"failed transaction");
    }

    function viewSwapingAmount(uint256 _ethAmount) public view returns(uint256){
        return _ethAmount * TokenPerETH / 1e18;
    }

    function setTokenPerEth(uint256 _tokenPerEth) external onlyOwner {
        TokenPerETH = _tokenPerEth;
    }

    function setTreasury(address _treasuryWallet) external onlyOwner {
        require(_treasuryWallet != address(0x0),"Invalid address");
        treasury = _treasuryWallet;
    }

    function setElonToken(address _elonToken) external onlyOwner {
        require(_elonToken != address(0x0),"Invalid address");
        ElonOneToken = _elonToken;
    }

    function elonBalance() external view returns(uint256){
        return IERC20(ElonOneToken).balanceOf(address(this));
    }

    function recoverToken(address _tokenAddress, uint256 _amount) external onlyOwner {
        IERC20(_tokenAddress).transfer(_msgSender(), _amount);
    }
}