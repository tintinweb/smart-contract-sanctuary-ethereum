/**
 *Submitted for verification at Etherscan.io on 2022-12-20
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.17;


contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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

abstract contract ReentrancyGuard {
    bool private _notEntered;

    constructor ()  {
        _notEntered = true;
    }
    
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        _notEntered = true;
    }
}


contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() external view returns (address) {
        return _owner;
    }   
    
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function renounceOwnership() external virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}

contract R33lzAirdrop is ReentrancyGuard, Context, Ownable{
    
    mapping(address => bool) public Claimed;
    mapping(address => bool) public _isWhitelisted;
    mapping(address => uint256) public _r33lzDrop;
    
    IERC20 public _token;
    bool public airdropLive;
    
    event AirdropClaimed(address receiver, uint256 amount);
    event WhitelistSetted(address[] recipient, uint256[] amount);
    event WhitelistRemoved(address[] recipient);
    
     
     //Start Airdrop
    function _startAirdrop(bool status) external onlyOwner{
        airdropLive = status;
    }

    //@dev can update token
    function _updateToken(IERC20 tokenAddress) external onlyOwner {
        _token = tokenAddress;
    }
    
     function _mapAirdrops(address[] calldata recipients, uint256[] calldata amount, bool state) external onlyOwner{
        for(uint i = 0; i< recipients.length; i++){
            require(recipients[i] != address(0));
            _r33lzDrop[recipients[i]] = amount[i];
            _isWhitelisted[recipients[i]] = state;
        }
        emit WhitelistSetted(recipients, amount);
    }

    function _removeMappedAirdrops(address[] calldata recipients) external onlyOwner{
        for(uint i = 0; i< recipients.length; i++){
            require(recipients[i] != address(0));
            _r33lzDrop[recipients[i]] = 0;
            _isWhitelisted[recipients[i]] = false;
        }
        emit WhitelistRemoved(recipients);
    }

    function _claimTokens() external nonReentrant {
        require(airdropLive, "Airdrop has not started yet");
        require(!Claimed[msg.sender], "Airdrop already claimed!");
        require(_isWhitelisted[msg.sender], "You are not whitelisted!");
        if(_token.balanceOf(address(this)) == 0) { airdropLive = false; return;}
        Claimed[msg.sender] = true;
        uint256 amount = _r33lzDrop[msg.sender] * 1e18;
        _token.transfer(msg.sender, amount);
        emit AirdropClaimed(msg.sender, amount);
    }
    
    function _withdrawETH() external onlyOwner {
         require(address(this).balance > 0, 'Contract has no money');
         address payable wallet = payable(msg.sender);
        wallet.transfer(address(this).balance);    
    }
    
    function _withdrawTokens(IERC20 tokenAddress) external onlyOwner{
        IERC20 tokenERC = tokenAddress;
        uint256 tokenAmt = tokenERC.balanceOf(address(this));
        require(tokenAmt > 0, "Token balance is 0");
        address payable wallet = payable(msg.sender);
        tokenERC.transfer(wallet, tokenAmt);
    }

}