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
    function minttoken(address to_, uint256 amount_) external;
}

interface iOP {
    function totalSupply() external view returns (uint256);
    function balanceOf(address address_) external view returns (uint256);
    function ownerOf(uint256 tokenId_) external view returns (address);
}

contract ChancoShop is Ownable {

    iToken public Token = iToken(0xced7c61617aD24b076729Af8EE607A4b30CBf2E4); 
    iOP public OP = iOP(0x9CE4f6FDC1bf735329d1dDeD7EbD706C3c9452a1);
    uint256 public yieldStartTime = 1658325600;//21/07/22 00:00:00
    uint256 public yieldEndTime = 1816092000;//21/07/27 00:00:00
    uint256 public yieldRatePerToken = 5 ether;
    mapping(uint256 => uint256) public tokenToLastClaimedTimestamp;
    event Claim(address to_, uint256[] tokenIds_, uint256 totalClaimed_);


    function setToken(address address_) external onlyOwner { 
        Token = iToken(address_); 
    }

    function setOP(address address_) external onlyOwner {
        OP = iOP(address_);
    }

    function setYieldEndTime(uint256 yieldEndTime_) external onlyOwner { 
        yieldEndTime = yieldEndTime_; }

    
    function setYieldRatePerToken(uint256 yieldRatePerToken_) external onlyOwner {
        yieldRatePerToken = yieldRatePerToken_;
    }

    function claim(uint256[] calldata tokenIds_) external {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            require(msg.sender == OP.ownerOf(tokenIds_[i]),
                "You are not the owner!");
        }
        uint256 _pendingTokens = getPendingTokensMany(tokenIds_);
        

        _updateTimestampOfTokens(tokenIds_);
        

        Token.minttoken(msg.sender, _pendingTokens);

        emit Claim(msg.sender, tokenIds_, _pendingTokens);
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
        uint256 _timeElapsed = _timeCurrentOrEnded - _lastClaimedTimestamp;
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
            require(tokenToLastClaimedTimestamp[tokenIds_[i]] != _timeCurrentOrEnded,
                "Unable to set timestamp duplication in the same block");

            tokenToLastClaimedTimestamp[tokenIds_[i]] = _timeCurrentOrEnded;
        }
    }

    function walletOfOwner(address address_) public view returns (uint256[] memory) {
        uint256 _balance = OP.balanceOf(address_);
        uint256[] memory _tokens = new uint256[] (_balance);
        uint256 _index;
        uint256 _loopThrough = OP.totalSupply();
        for (uint256 i = 0; i < _loopThrough; i++) {
            address _ownerOf = OP.ownerOf(i);
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