/**
 *Submitted for verification at Etherscan.io on 2023-01-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC721Receiver {

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract ERC721Holder is IERC721Receiver {

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
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

interface IERC721 {
    
        function balanceOf(address owner) external view returns (uint256 balance);

        function ownerOf(uint256 tokenId) external view returns (address owner);

        function safeTransferFrom(
            address from,
            address to,
            uint256 tokenId,
            bytes calldata data
        ) external;

        function safeTransferFrom(
            address from,
            address to,
            uint256 tokenId
        ) external;

        function transferFrom(
            address from,
            address to,
            uint256 tokenId
        ) external;

        function approve(address to, uint256 tokenId) external;

        function setApprovalForAll(address operator, bool _approved) external;

        function getApproved(uint256 tokenId) external view returns (address operator);

        function isApprovedForAll(address owner, address operator) external view returns (bool);

        function totalSupply() external view returns (uint);
}

error CantUnstakeNow();
error NotFound();

contract SOSADStaking is Ownable, ERC721Holder {

    IERC721 public NFT = IERC721(0x5AD0955256b62999b9231b4Dc6E99C0E6c981fFF);  //original one
    IERC20 public Token = IERC20(0xF424701D8FaD901948BFC97B316abDF7145E620C);

    uint256 public perSecReward = 138888;  //0.138888 dec 6
    uint256 public minHolding;

    uint256 public minStakeDuration = 604800; //7 days

    struct poolToken {
        uint256 _tokenId;
        uint256 _startTime;
        uint256 _stakeDuration;
    }

    struct pool {
        address _user;
        uint256 _NftCount;
        poolToken[] _Ledger;
    }

    mapping(address => pool) public _Stakers;
    uint256 public totalStakers;
    uint256 public rewardDistributed;
    bool public paused;

    constructor() {
        uint totalSupply = Token.totalSupply();
        minHolding = totalSupply*2/1000;
    }

    function stake(uint256 tokenId,uint256 _duration) public {
        require(!paused,"Error: Staking is Currently Paused Now!!");
        address account = msg.sender;
        uint holdingbal = Token.balanceOf(account);
        require(_duration >= minStakeDuration,"Invalid Duration");
        require(holdingbal >= minHolding,"Error: Insufficient Holding Balance!");
        NFT.safeTransferFrom(account, address(this), tokenId);
        if(_Stakers[account]._user == address(0)) {
            _Stakers[account]._user = account;
            totalStakers++;
        }
        _Stakers[account]._NftCount++;
        poolToken memory _rec = poolToken(tokenId,block.timestamp,_duration);
        _Stakers[account]._Ledger.push(_rec);
    }

    function unstakeAndClaim(uint256 tokenId) public {
        require(!paused,"Error: Staking is Currently Paused Now!!");
        address account = msg.sender;
        uint length = _Stakers[account]._Ledger.length;
        uint _index = getIndex(account,tokenId,length);
        poolToken memory arr = _Stakers[account]._Ledger[_index];
        require(_Stakers[account]._NftCount > 0,"Error: No Nft Staked!");
        if(block.timestamp <= arr._startTime + arr._stakeDuration) {
            revert CantUnstakeNow();
        }
        uint sec = block.timestamp - arr._startTime;
        uint reward = perSecReward * sec;
        _Stakers[account]._Ledger[_index] = _Stakers[account]._Ledger[length - 1];
        _Stakers[account]._Ledger.pop();
        NFT.safeTransferFrom(address(this),account, tokenId);
        Token.transfer(account, reward);
        rewardDistributed += reward;
        _Stakers[account]._NftCount--;
    }

    function terminate(uint256 tokenId) public {
        address account = msg.sender;
        uint length = _Stakers[account]._Ledger.length;
        uint _index = getIndex(account,tokenId,length);
        require(_Stakers[account]._NftCount > 0,"Error: No Nft Staked!");
        _Stakers[account]._Ledger[_index] = _Stakers[account]._Ledger[length - 1];
        _Stakers[account]._Ledger.pop();
        NFT.safeTransferFrom(address(this),account, tokenId);
        _Stakers[account]._NftCount--;
    }

    function getTokenInfo(address account,uint _pid) public view returns (poolToken memory, uint _eReward){
        uint _start = _Stakers[account]._Ledger[_pid]._startTime;
        uint _tsec = block.timestamp - _start;
        uint _reward = perSecReward * _tsec;
        return (_Stakers[account]._Ledger[_pid],_reward);
    }

    function getIndex(address _account,uint256 _tokenId,uint256 _length) public view returns (uint _i){
        for(uint i = 0; i < _length; i++){
            if(_Stakers[_account]._Ledger[i]._tokenId == _tokenId){
                return i;
            }   
        }
        revert NotFound();
    }

    function getTime() external view returns (uint256) {
        return block.timestamp;
    }

    function setNft(address _adr) external onlyOwner {
        NFT = IERC721(_adr);
    }

    function setToken(address _adr) external onlyOwner {
        Token = IERC20(_adr);
    }

    function setReward(uint _newReward) external onlyOwner {
        perSecReward = _newReward;
    }

    function setMinHolding(uint _newSet) external onlyOwner {
        minHolding = _newSet;
    }

    function setPauser(bool _status) external onlyOwner {
        require(paused != _status,"Error: Not Changed!");
        paused = _status;
    }

    function setMinDuration(uint _newDuration)  external onlyOwner {
        minStakeDuration = _newDuration;
    }

    function rescueFunds() external onlyOwner {
        (bool os,) = payable(msg.sender).call{value: address(this).balance}("");
        require(os);
    }

    function rescueToken(address _token) external onlyOwner {
        uint balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(msg.sender,balance);
    }

    function rescueNft(address _token,uint256 _id) external onlyOwner {
        IERC721(_token).safeTransferFrom(address(this),msg.sender,_id);
    }

    receive() external payable {}

}