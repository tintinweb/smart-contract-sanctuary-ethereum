// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

interface ERC20 {
    function mint(address _to, uint amount) external;
}

contract Faucet {
    uint256 public waitTime = 24 hours;

    struct TokenData {
        uint256 amount;
        ERC20 token;
    }
    TokenData[] tokensData;
    mapping(address => uint256) public lastAccessTime;
    address owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function mintTokens() public {
        require(allowedToMint(msg.sender), "WAIT_TIME_NOT_PASSED");
        for (uint i=0; i<tokensData.length;) {
            tokensData[i].token.mint(msg.sender, tokensData[i].amount);
            unchecked { i++; }
        }
        lastAccessTime[msg.sender] = block.timestamp;
    }

    function allowedToMint(address _address) public view returns (bool) {
        if(lastAccessTime[_address] == 0) {
            return true;
        } else if(block.timestamp >= lastAccessTime[_address] + waitTime) {
            return true;
        }
        return false;
    }

    function setTokens(TokenData[] calldata _tokensData) external onlyOwner {
        for (uint i=0; i<_tokensData.length; i++) {
            tokensData.push(
                TokenData(_tokensData[i].amount, _tokensData[i].token)
            );
        }
    }
    
    function setWaitTime(uint256 _waitTime) external onlyOwner {
        require(_waitTime > 0);
        waitTime = _waitTime;
    }
}