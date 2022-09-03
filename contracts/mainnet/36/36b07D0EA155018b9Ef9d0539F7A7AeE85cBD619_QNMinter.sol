/**
 *Submitted for verification at Etherscan.io on 2022-07-20
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

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

abstract contract Minter is Ownable {
    mapping(address => bool) public minters;
    modifier onlyMinter { require(minters[msg.sender], "Not Minter!"); _; }
    function setMinter(address address_, bool bool_) external onlyOwner {
        minters[address_] = bool_;
    }
}

interface iToken {
    function mint(address to_, uint256 amount_) external;
}

interface iNFT {
    function totalSupply() external view returns (uint256);
    function balanceOf(address address_) external view returns (uint256);
    function ownerOf(uint256 tokenId_) external view returns (address);
}

contract QNMinter is Ownable {

    //test
    iToken public Token = iToken(0x9EfC705Af7a48E3b61DDFAe9368b821dF4e7ff61); 
    iNFT public NFT = iNFT(0x79d43460f3CB215bB78a8761aca0C6808263b0d4);
    
    //honban
    uint256 public yieldStartTime = 1662044400;//22/09/02 00:00:00
    uint256 public yieldEndTime = 1816092000;//21/07/27 00:00:00
    uint256 public yieldRatePerToken = 1 ether;
    uint256 public etherDigit= 1000000000000000000;
    mapping(uint256 => uint256) public tokenToLastClaimedTimestamp;
    bool public paused = false;


    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function setToken(address address_) external onlyOwner { 
        Token = iToken(address_); 
    }

    function setNFT(address address_) external onlyOwner {
        NFT = iNFT(address_);
    }

    function setYieldEndTime(uint256 yieldEndTime_) external onlyOwner { 
        yieldEndTime = yieldEndTime_; 
    }

    function setYieldRatePerToken(uint256 yieldRatePerToken_) external onlyOwner {
        yieldRatePerToken = yieldRatePerToken_;
    }

    function getPendingTokensAmount() public view returns(uint256){
        require( NFT.balanceOf(msg.sender) != 0 , "You are not the owner!");
        uint256[] memory tokenIds;
        tokenIds = walletOfOwner(msg.sender);
        uint256 _pendingTokens = getPendingTokensMany(tokenIds);
        return _pendingTokens / etherDigit;
    }

    function claim() external {
        require(!paused, "the contract is paused");
        require( NFT.balanceOf(msg.sender) != 0 , "You are not the owner!");
        uint256[] memory tokenIds;
        tokenIds = walletOfOwner(msg.sender);
        uint256 _pendingTokens = getPendingTokensMany(tokenIds);
        _updateTimestampOfTokens(tokenIds);
        require( 0 < _pendingTokens , "Token Amount is Zero");

        Token.mint(msg.sender, _pendingTokens / etherDigit);
    }

    function _getTimeCurrentOrEnded() internal view returns (uint256) {
        return block.timestamp < yieldEndTime ? 
            block.timestamp : yieldEndTime;
    }

    function _getTimestampOfToken(uint256 tokenId_) internal view returns (uint256) {
        return tokenToLastClaimedTimestamp[tokenId_] == 0 ? 
            yieldStartTime : tokenToLastClaimedTimestamp[tokenId_];
    }

    function getPendingTokens(uint256 tokenId_) public view 
    returns (uint256) {
        uint256 _lastClaimedTimestamp = _getTimestampOfToken(tokenId_);
        uint256 _timeCurrentOrEnded = _getTimeCurrentOrEnded();
        uint256 _timeElapsed;
        if(_timeCurrentOrEnded < _lastClaimedTimestamp){
            _timeElapsed = 0;
        }else{
            _timeElapsed = _timeCurrentOrEnded - _lastClaimedTimestamp;            
        }
        return (_timeElapsed * yieldRatePerToken) / 1 days;
    }

    function getPendingTokensMany(uint256[] memory tokenIds_) public
    view returns (uint256) {
        uint256 _pendingTokens;
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            _pendingTokens += getPendingTokens(tokenIds_[i]);
        }
        return _pendingTokens;
    }
   
    function _updateTimestampOfTokens(uint256[] memory tokenIds_) internal { 
        uint256 _timeCurrentOrEnded = _getTimeCurrentOrEnded();
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            require(tokenToLastClaimedTimestamp[tokenIds_[i]] != _timeCurrentOrEnded, "Unable to set timestamp duplication in the same block");
            tokenToLastClaimedTimestamp[tokenIds_[i]] = _timeCurrentOrEnded;
        }
    }

    function walletOfOwner(address address_) public view returns (uint256[] memory) {
        uint256 _balance = NFT.balanceOf(address_);
        uint256[] memory _tokens = new uint256[] (_balance);
        uint256 _index;
        uint256 _loopThrough = NFT.totalSupply();
        for (uint256 i = 1; i <= _loopThrough; i++) {
            address _ownerOf = NFT.ownerOf(i);
            if (_ownerOf == address(0) && _tokens[_balance - 1] == 0) {
                _loopThrough++;
            }
            if (_ownerOf == address_) {
                _tokens[_index++] = i;
            }
        }
        return _tokens;
    }

    function getPendingTokensOfAddress(address address_) public view returns (uint256) {
        uint256[] memory _walletOfAddress = walletOfOwner(address_);
        return getPendingTokensMany(_walletOfAddress);
    }
}