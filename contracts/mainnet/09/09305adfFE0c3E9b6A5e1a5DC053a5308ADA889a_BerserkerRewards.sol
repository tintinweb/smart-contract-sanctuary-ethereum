/**
 *Submitted for verification at Etherscan.io on 2022-08-22
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

contract BerserkerRewards is Ownable, ReentrancyGuard {
    IERC721 public berserker;

    mapping(address => uint) public totalRecieved; // [ERC20][Amount]
    mapping(address => uint) public totalSent;     // [ERC20][Amount]
    mapping(address => bool) public tokenWhitelist;

    mapping(uint => mapping(address => uint)) public balances; // [ERC721][Token][Amount]

    constructor() {
        berserker = IERC721(0x8aE20BB9E02Bb7dB0669ba2232319A24D5856073);
    }

    // Internal helpers

    function getBalanceInBooks(address account, address tokenAddress) internal view returns (uint) {
        uint balance = 0;
        for(uint i = 0; i < 40; i++){
            if(berserker.ownerOf(i) == account) {
                balance += balances[i][tokenAddress];
            }
        }
        return balance;
    }

    function getBalanceOutOfBooksPerNFT(address tokenAddress) internal view returns(uint) {
        uint balanceOutOfBooksPerNFT;
        uint balanceInBooks = totalRecieved[tokenAddress] - totalSent[tokenAddress];
        if(balanceInBooks < IERC20(tokenAddress).balanceOf(address(this))){
            uint balanceOutOfBooks = IERC20(tokenAddress).balanceOf(address(this)) - balanceInBooks;
            balanceOutOfBooksPerNFT = balanceOutOfBooks / 40;
        }
        return balanceOutOfBooksPerNFT;
    }

    // View functions

    function getClaimableAmount(address account, address tokenAddress) external view returns (uint) {
        return getBalanceInBooks(account, tokenAddress)
            + berserker.balanceOf(account) * getBalanceOutOfBooksPerNFT(tokenAddress);
    }

    // Public functions

    function claim(address tokenAddress) public nonReentrant {
        require(berserker.balanceOf(msg.sender) > 0, "You are not a Berserker");
        require(tokenWhitelist[tokenAddress], "Token is not whitelisted");

        // Update balances
        uint balanceOutOfBooksPerNFT = getBalanceOutOfBooksPerNFT(tokenAddress);
        if(balanceOutOfBooksPerNFT > 0){
            for(uint i=0; i<40; i++) {
                balances[i][tokenAddress] += balanceOutOfBooksPerNFT;
            }
            totalRecieved[tokenAddress] += balanceOutOfBooksPerNFT * 40;
        }

        require(getBalanceInBooks(msg.sender, tokenAddress) > 0, "You claimed all your tokens");
        
        // Send balance to DAO member.
        uint claimAmount;
        for(uint j = 0; j< 40; j++){
            if(berserker.ownerOf(j) == msg.sender){
                claimAmount += balances[j][tokenAddress];
                totalSent[tokenAddress] += balances[j][tokenAddress];
                balances[j][tokenAddress] = 0;
            }
        }
        IERC20(tokenAddress).transfer(msg.sender, claimAmount);
    }

    // Owner functions

    function withdrawAssets(address tokenAddress) public onlyOwner {
        IERC20 asset = IERC20(tokenAddress);
        asset.transfer(owner(), asset.balanceOf(address(this)));
    }

    function setTokenWhitelist(address tokenAddress, bool value) public onlyOwner {
        tokenWhitelist[tokenAddress] = value;
    }
}