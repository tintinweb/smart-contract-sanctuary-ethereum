/**
 *Submitted for verification at Etherscan.io on 2023-06-12
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/*
How to convert V1 tokens to V2 tokens:
1. Claim an existing box (A) OR create a new box (B)
   Option A: Call `claim()` on a claimable box (`owner` set to zero address)
   Option B: Call `newBox()` on the V2 token
3. Verify that the `owner` variable on the box is set to your address (!)
4. Send V1 tokens to the box
5. Call `mintV2()` on the box

Important: `mintV2()` resets the box `owner`. This way others can reuse the box.

How to convert V2 tokens to V1 tokens:
   Simply call `burnV2()` on the V2 token
*/

interface MyTokenV1 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external;
}

contract Box {
    MyTokenV1 public tokenV1;
    MyTokenV2 public tokenV2;
    address public owner;
    uint96 public boxId;

    constructor(MyTokenV1 _tokenV1, MyTokenV2 _tokenV2, address _owner, uint96 _boxId) {
        tokenV1 = _tokenV1;
        tokenV2 = _tokenV2;
        owner = _owner;
        boxId = _boxId;
    }

    function claim() external returns (bool) {
        if (owner != address(0)) {
            return false;
        }
        owner = msg.sender;
        return true;
    }

    function mintV2() external {
        uint256 value = tokenV1.balanceOf(address(this));
        tokenV1.transfer(address(tokenV2), value);
        tokenV2.mintV2(boxId, owner, value);
        owner = address(0);
    }
}

contract MyTokenV2 {
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    MyTokenV1 public tokenV1;
    mapping(uint96 => Box) public boxes;
    uint96 public boxCount;

    constructor(MyTokenV1 _tokenV1) {
        tokenV1 = _tokenV1;
    }

    function name() external view returns (string memory) {
        return tokenV1.name();
    }

    function symbol() external view returns (string memory) {
        return tokenV1.symbol();
    }

    function decimals() external view returns (uint8) {
        return tokenV1.decimals();
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        return transferFrom(msg.sender, to, value);
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(balanceOf[from] >= value);
        if (from != msg.sender && allowance[from][msg.sender] != type(uint256).max) {
            require(allowance[from][msg.sender] >= value);
            allowance[from][msg.sender] -= value;
        }
        balanceOf[from] -= value;
        balanceOf[to] += value;
        return true;
    }

    function newBox() external returns (Box) {
        Box box = new Box(tokenV1, this, msg.sender, boxCount);
        boxes[boxCount] = box;
        boxCount += 1;
        return box;
    }

    function mintV2(uint96 boxId, address boxOwner, uint256 value) external {
        require(boxId < boxCount && msg.sender == address(boxes[boxId]));
        totalSupply += value;
        balanceOf[boxOwner] += value;
    }

    function burnV2() external {
        burnV2(msg.sender, msg.sender, balanceOf[msg.sender]);
    }

    function burnV2(address from, address to, uint256 value) public {
        require(balanceOf[from] >= value);
        if (from != msg.sender && allowance[from][msg.sender] != type(uint256).max) {
            require(allowance[from][msg.sender] >= value);
            allowance[from][msg.sender] -= value;
        }
        balanceOf[from] -= value;
        totalSupply -= value;
        tokenV1.transfer(to, value);
    }
}

/*
V1 token source code (solidity compiler 0.1.6, 200 optimization runs):

contract MyToken {
    string public name;
    string public symbol;
    uint8 public decimals;

    mapping (address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function MyToken(uint256 _supply, string _name, string _symbol, uint8 _decimals) {
        if (_supply == 0) {
            _supply = 1000000;
        }
        balanceOf[msg.sender] = _supply;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function transfer(address _to, uint256 _value) {
        if (balanceOf[msg.sender] < _value) throw;
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        Transfer(msg.sender, _to, _value);
    }
}
*/

/*
Copyright 2023 MyTokenV2 Author(s)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/