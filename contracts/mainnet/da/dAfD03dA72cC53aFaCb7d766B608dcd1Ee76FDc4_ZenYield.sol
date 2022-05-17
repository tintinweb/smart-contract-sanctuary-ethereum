/**
 *Submitted for verification at Etherscan.io on 2022-05-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

///////////////////////////////////////
//   ____       __  ___     __   __  //
//  /_  / ___ __\ \/ (_)__ / /__/ /  //
//   / /_/ -_) _ \  / / -_) / _  /   //
//  /___/\__/_//_/_/_/\__/_/\_,_/    //
//               by 0xInuarashi.eth  //
///////////////////////////////////////

abstract contract Ownable {
    address public owner; 
    constructor() { owner = msg.sender; }
    modifier onlyOwner { require(owner == msg.sender, "Not Owner!"); _; }
    function transferOwnership(address new_) external onlyOwner { owner = new_; }
}

interface iZen {
    function mintAsController(address to_, uint256 amount_) external;
}

interface iZenApe {
    function totalSupply() external view returns (uint256);
    function balanceOf(address address_) external view returns (uint256);
    function ownerOf(uint256 tokenId_) external view returns (address);
}

contract ZenYield is Ownable {

    // Interfaces
    iZen public Zen = iZen(0x884345a7B7E7fFd7F4298aD6115f5d5afb2F7660); 
    function setZen(address address_) external onlyOwner { 
        Zen = iZen(address_); 
    }

    iZenApe public ZenApe = iZenApe(0x838804a3dd7c717396a68F94E736eAf76b911632);
    function setZenApe(address address_) external onlyOwner {
        ZenApe = iZenApe(address_);
    }

    // Times
    uint256 public yieldStartTime = 1651327200; // Apr 30 2022 14:00:00 GMT+0000
    uint256 public yieldEndTime = 1682863200; // Apr 30 2023 14:00:00 GMT+0000
    function setYieldEndTime(uint256 yieldEndTime_) external onlyOwner { 
        yieldEndTime = yieldEndTime_; }

    // Yield Info
    uint256 public yieldRatePerToken = 5 ether; // 5 Zen per Day
    function setYieldRatePerToken(uint256 yieldRatePerToken_) external onlyOwner {
        yieldRatePerToken = yieldRatePerToken_;
    }

    // Yield Database
    mapping(uint256 => uint256) public tokenToLastClaimedTimestamp;

    // Events
    event Claim(address to_, uint256[] tokenIds_, uint256 totalClaimed_);

    // Internal Calculators
    function _getTimeCurrentOrEnded() internal view returns (uint256) {
        // Return block.timestamp if it's lower than yieldEndTime, otherwise
        // return yieldEndTime instead.
        return block.timestamp < yieldEndTime ? 
            block.timestamp : yieldEndTime;
    }
    function _getTimestampOfToken(uint256 tokenId_) internal view returns (uint256) {
        // Here, since we have intrinsic token yield, we need to take that into account.
        // We return the yieldStartTime if SSTORE of tokenToLastClaimedTimestamp is 0
        return tokenToLastClaimedTimestamp[tokenId_] == 0 ? 
            yieldStartTime : tokenToLastClaimedTimestamp[tokenId_];
    }

    // Yield Accountants
    function getPendingTokens(uint256 tokenId_) public view 
    returns (uint256) {
        
        // First, grab the timestamp of the token
        uint256 _lastClaimedTimestamp = _getTimestampOfToken(tokenId_);

        // Then, we grab the timestamp to compare it with
        uint256 _timeCurrentOrEnded = _getTimeCurrentOrEnded();

        // Lastly, we calculate the time-units in seconds of elapsed time 
        uint256 _timeElapsed = _timeCurrentOrEnded - _lastClaimedTimestamp;

        // Now, calculate the pending yield
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

    // Internal Timekeepers    
    function _updateTimestampOfTokens(uint256[] memory tokenIds_) internal { 
        uint256 _timeCurrentOrEnded = _getTimeCurrentOrEnded();
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            // Prevents duplicate setting of the same token in the same block
            require(tokenToLastClaimedTimestamp[tokenIds_[i]] != _timeCurrentOrEnded,
                "Unable to set timestamp duplication in the same block");

            tokenToLastClaimedTimestamp[tokenIds_[i]] = _timeCurrentOrEnded;
        }
    }

    // Public Claim
    function claim(uint256[] calldata tokenIds_) external {
        // Make sure the sender owns all the tokens
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            require(msg.sender == ZenApe.ownerOf(tokenIds_[i]),
                "You are not the owner!");
        }

        // Calculate the total Pending Tokens to be claimed
        uint256 _pendingTokens = getPendingTokensMany(tokenIds_);
        
        // Set on all the tokens the new timestamp (which sets pending to 0)
        _updateTimestampOfTokens(tokenIds_);
        
        // Mint the total tokens for the msg.sender
        Zen.mintAsController(msg.sender, _pendingTokens);

        // Emit claim of total tokens
        emit Claim(msg.sender, tokenIds_, _pendingTokens);
    }

    // Public View Functions for Helpers
    function walletOfOwner(address address_) public view returns (uint256[] memory) {
        uint256 _balance = ZenApe.balanceOf(address_);
        uint256[] memory _tokens = new uint256[] (_balance);
        uint256 _index;
        uint256 _loopThrough = ZenApe.totalSupply();
        for (uint256 i = 0; i < _loopThrough; i++) {
            address _ownerOf = ZenApe.ownerOf(i);
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