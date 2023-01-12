/**
 *Submitted for verification at Etherscan.io on 2023-01-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

contract NFTCollection {
    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public stakedTokens;
    mapping(uint256 => address) public tokenOwner;
    mapping(uint256 => uint256) public tokenStakedTimestamp;
    uint256 public counter;

    function mint(address _to, uint256 _supply) public payable {
        require(_supply > 0 && _supply <= 50, "Invalid supply, max 50 tokens allowed");
        require(msg.value == _supply * 1 ether, "Invalid price, 1 ether per token");
        require(balanceOf[_to] + _supply <= 50, "Exceeded max limit of 50 tokens per address");
        for (uint256 i = 0; i < _supply; i++) {
            tokenOwner[counter] = _to;
            balanceOf[_to]++;
            counter++;
        }
    }

    
    function transferFunds() public {
        uint256 id = selectRandom();
        address tokenHolder = tokenOwner[id];
        require(tokenHolder != address(0), "Invalid token holder address");
        //(bool success, ) = address(tokenHolder).call.value(address(this).balance)("");
        (bool success, ) = address(tokenHolder).call{value:address(this).balance}("");
        require(success, "Transfer failed");
    }

    
    function stake(uint256 _tokens) public {
        require(balanceOf[msg.sender] >= _tokens, "Insufficient token balance");
        uint256 staked = 0;
        for(uint256 i = 0; i<counter; i++) {
            if(tokenOwner[i] == msg.sender && tokenStakedTimestamp[i] == 0) {
                tokenStakedTimestamp[i] = block.timestamp + 432000; // 432000 seconds = 5 days
                staked++;
                stakedTokens[msg.sender]++;
                if(staked >= _tokens) break;
            }
        }
        require(staked == _tokens, "tokens not available for staking" );
    }


    function selectRandom() private view returns (uint256) {
    uint256 id;
    do {
        id = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % counter;
    } while (tokenStakedTimestamp[id] != 0 && tokenStakedTimestamp[id] > block.timestamp);
    return id;
}
}