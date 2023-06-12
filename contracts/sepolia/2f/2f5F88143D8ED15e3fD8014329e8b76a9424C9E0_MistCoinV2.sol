/**
 *Submitted for verification at Etherscan.io on 2023-06-12
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface MistCoinV1 {
    function balanceOf(address account) external returns (uint256);
    function transfer(address to, uint256 value) external;
}

contract Box {
    MistCoinV1 public tokenV1;
    MistCoinV2 public tokenV2;
    address public owner;
    uint40 public boxId;
    uint40 public claimable;

    constructor(MistCoinV1 _tokenV1, MistCoinV2 _tokenV2, address _owner, uint40 _boxId) {
        tokenV1 = _tokenV1;
        tokenV2 = _tokenV2;
        owner = _owner;
        boxId = _boxId;
        claimable = uint40(block.timestamp) + 604800;
    }

    function claim() external returns (bool) {
        uint40 timestamp = uint40(block.timestamp);
        if (timestamp < claimable) {
            return false;
        }
        owner = msg.sender;
        claimable = timestamp + 604800;
        return true;
    }

    function mintV2() external {
        uint256 value = tokenV1.balanceOf(address(this));
        tokenV1.transfer(address(tokenV2), value);
        tokenV2.mintV2(boxId, owner, value);
        claimable = 0;
    }
}

contract MistCoinV2 {
    string public constant name = "MistCoin";
    string public constant symbol = "MC";
    uint8 public constant decimals = 2;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    MistCoinV1 public tokenV1;
    mapping(uint40 => Box) public boxes;
    uint40 public boxCount;

    constructor(MistCoinV1 _tokenV1) {
        tokenV1 = _tokenV1;
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

    function mintV2(uint40 boxId, address account, uint256 value) external {
        require(boxId < boxCount && msg.sender == address(boxes[boxId]));
        totalSupply += value;
        balanceOf[account] += value;
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
Instructions:

How to convert V1 tokens to V2 tokens:
1. Claim an existing box or create a new box:
  a. Check if any existing boxes (`boxes` array on the V2 token) can be claimed, i.e.
     `claimable` on box < current UNIX timestamp
  b. If so, call `claim()` on that box
  c. If not, create a new box (call `newBox()` on the V2 token)
2. Ensure that the `owner` variable on the box is set to your address
3. Ensure that the `claimable` variable on the box is set to a timestamp in ~7 days
4. Send V1 tokens to the box
5. Call `mintV2()` on the box

Boxes can be reused to save gas. Anyone can claim a box 7 days after the owner
variable was last set. Call `mintV2()` before somebody else can claim the box.

How to convert V2 tokens to V1 tokens:
Simply call `burnV2()` on the V2 token
*/

/*
V1 token source code (solidity compiler 0.1.6, 200 optimizations):

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