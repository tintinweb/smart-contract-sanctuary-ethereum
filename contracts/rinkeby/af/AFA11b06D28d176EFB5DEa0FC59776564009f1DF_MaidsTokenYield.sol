// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IMaidsToken.sol";

interface IMaidsNFT {
    function totalSupply() external view returns (uint256);
    function balanceOf(address address_) external view returns (uint256);
    function ownerOf(uint256 tokenId_) external view returns (address);
}

contract MaidsTokenYield is Ownable {

    // claim token per day
    struct yieldRate {
        uint256 day;
        uint256 rate;
    }

    // Events
    event Claim(address to_, uint256[] tokenIds_, uint256 totalClaimed_);

    // Interfaces
    IMaidsToken public Token = IMaidsToken(0xDE3793B9691eA7de076373AC901B4dfbdf8C059d); 
    IMaidsNFT public NFT = IMaidsNFT(0xd73fcBc1417Ce5d65eA7016BC034E2d6D65ABD6d);

    // Times
    uint256 public yieldStartTime = 1661958000; // 2022/09/01 00:00:00 GMT+0900
    uint256 public yieldEndTime = 1767193199; // 2025/12/31 23:59:59 GMT+0900

    // Yield Info
    yieldRate[] private yieldRateData;

    // Yield Database
    mapping(uint256 => uint256) public tokenToLastClaimedTimestamp;

    constructor()  {
        yieldRateData.push(yieldRate(0, 10));
    }

    function renounceOwnership() public override onlyOwner {}
    
    function setToken(address address_) external onlyOwner { 
        Token = IMaidsToken(address_); 
    }

    function setNFT(address address_) external onlyOwner {
        NFT = IMaidsNFT(address_);
    }

    function setYieldStartTime(uint256 yieldStartTime_) external onlyOwner { 
        yieldStartTime = yieldStartTime_;
    }

    function setYieldEndTime(uint256 yieldEndTime_) external onlyOwner { 
        yieldEndTime = yieldEndTime_;
    }

    function setYieldRateData(uint256 day_, uint256 rate_) external onlyOwner {
        for (uint256 i = 0; i < yieldRateData.length; i++) {
            yieldRate storage data = yieldRateData[i];
            if (data.day == day_) {
                data.rate = rate_;
                return;
            }
        }
        yieldRateData.push(yieldRate(day_, rate_));
    }

    function getYieldRateData() external view returns (yieldRate[] memory) {
        return yieldRateData;
    }

    // test
    function setTimestampOfToken(uint256 tokenId_,uint256 timestamp_) external onlyOwner {
        tokenToLastClaimedTimestamp[tokenId_] = timestamp_;
    }
    // test

    // Internal Calculators
    function _getTimestampOfToken(uint256 tokenId_) internal view returns (uint256) {
        //return tokenToLastClaimedTimestamp[tokenId_] == 0 ? yieldStartTime : tokenToLastClaimedTimestamp[tokenId_];
        return tokenToLastClaimedTimestamp[tokenId_] < yieldStartTime ? yieldStartTime : tokenToLastClaimedTimestamp[tokenId_];
    }
    
    function _getCurrentTimeOrEnded() internal view returns (uint256) {
        return block.timestamp < yieldEndTime ? block.timestamp : yieldEndTime;
    }

    function _getYieldRate(uint256 day_) internal view returns (uint256) {
        uint256 rate = 0;
        for (uint256 i = 0; i < yieldRateData.length; i++) {
            yieldRate memory data = yieldRateData[i];
            if (data.day <= day_ && rate < data.rate) {
                rate = data.rate;
            }
        }
        return rate * 1 ether;
    }

    // Yield Accountants
    function getPendingTokens(uint256 tokenId_) public view returns (uint256) {
        uint256 _lastClaimedTimestamp = _getTimestampOfToken(tokenId_);
        uint256 _timeCurrentOrEnded = _getCurrentTimeOrEnded();
        uint256 _timeElapsed = _timeCurrentOrEnded - _lastClaimedTimestamp;
        uint256 rate = _getYieldRate((_timeElapsed / 1 days));
        return (_timeElapsed * rate) / 1 days;
    }

    function getPendingTokensMany(uint256[] memory tokenIds_) public view returns (uint256) {
        uint256 _pendingTokens;
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            _pendingTokens += getPendingTokens(tokenIds_[i]);
        }
        return _pendingTokens;
    }
   
    // Internal Timekeepers
    function _updateTimestampOfTokens(uint256[] memory tokenIds_) internal { 
        uint256 _timeCurrentOrEnded = _getCurrentTimeOrEnded();
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            // require(tokenToLastClaimedTimestamp[tokenIds_[i]] != _timeCurrentOrEnded,
            //     "Unable to set timestamp duplication in the same block");
            if (tokenToLastClaimedTimestamp[tokenIds_[i]] == _timeCurrentOrEnded) revert("Unable to set timestamp duplication in the same block");

            tokenToLastClaimedTimestamp[tokenIds_[i]] = _timeCurrentOrEnded;
        }
    }

    // Public Claim
    function claim(uint256[] calldata tokenIds_) public returns (uint256) {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            // require(msg.sender == NFT.ownerOf(tokenIds_[i]),
            //     "You are not the owner!");
            if (msg.sender != NFT.ownerOf(tokenIds_[i])) revert("You are not the owner!");
        }

        uint256 _pendingTokens = getPendingTokensMany(tokenIds_);
        
        _updateTimestampOfTokens(tokenIds_);

        Token.mint(msg.sender, _pendingTokens);

        emit Claim(msg.sender, tokenIds_, _pendingTokens);

        return _pendingTokens;
    } 
    
    // Public View Functions for Helpers
    function walletOfOwner(address address_) public view returns (uint256[] memory) {
        uint256 _balance = NFT.balanceOf(address_);
        uint256[] memory _tokens = new uint256[] (_balance);
        uint256 _index;
        uint256 _loopThrough = NFT.totalSupply();
        for (uint256 i = 0; i < _loopThrough; i++) {
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
        uint256[] memory _tokenIds = walletOfOwner(address_);
        return getPendingTokensMany(_tokenIds);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IMaidsToken {
    function mint(address to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}