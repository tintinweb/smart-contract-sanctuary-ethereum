// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC20.sol";
import "./DCall.sol";

contract ERC20D is ERC20, DCall { }

pragma solidity ^0.8.17;

// Basic ERC20 contract
contract ERC20 {
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    string public constant name = 'TestERC20';
    string public constant symbol = 'TST20';
    uint8 public constant decimals = 0;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    function mint(address owner, uint256 amount) public {
        require(owner != address(0), 'invalid owner');
        balanceOf[owner] += amount;
        emit Transfer(address(0), owner, amount);
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        return transferFrom(msg.sender, to, amount);
    }

    function transferFrom(address owner, address to, uint256 amount) public returns (bool) {
        require(to != address(0), 'invalid recipient');
        if (msg.sender != owner) {
            allowance[owner][msg.sender] -= amount;
        }
        balanceOf[owner] -= amount;
        balanceOf[to] += amount;
        emit Transfer(owner, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract DCall {
    enum CallType {
        Call,
        DelegateCall
    }
    struct DCallOp {
        bytes deployment;
        address to;
        bytes callData;
        CallType callType;
    }

    function dcall(DCallOp[] memory ops) external {
        for (uint256 i = 0; i < ops.length; ++i) {
            DCallOp memory op = ops[i];
            if (op.deployment.length > 0) {
                bytes memory deployment = op.deployment;
                assembly {
                    mstore(add(op, 0x20), create(0, add(deployment, 0x20), mload(deployment)))
                }
                require(op.to != address(0), 'deployment failed');
            }
            bool b;
            bytes memory r;
            if (op.callType == CallType.Call) {
                (b, r) = op.to.call(op.callData);
            } else {
                (b, r) = op.to.delegatecall(op.callData);
            }
            if (!b) {
                assembly { revert(add(r, 0x20), mload(r)) }
            }
        }
    }
}