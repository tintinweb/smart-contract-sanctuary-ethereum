/**
 *Submitted for verification at Etherscan.io on 2022-08-03
*/

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

contract Biscuss {
    address public owner;

    event Create(string i18, uint256 node, string title, string content);
    event Append(uint256 chain_id, string hash, string content);
    event Repay(uint256 chain_id, string hash, string content);
    event RepayTo(
        uint256 chain_id,
        string hash,
        string content,
        uint256 repay_to_chain_id,
        string repay_to_hash
    );
    event Pick(uint256 chain_id, string hash);
    event Attributes(bytes[] data);

    constructor() {
        owner = msg.sender;
    }

    // TODO: 如果 node 有 owner，必须owner才可以添加
    function create(
        string memory i18,
        uint256 node,
        string memory title,
        string memory content
    ) public {
        emit Create(i18, node, title, content);
    }

    // TODO: only hash's msg.sender
    function append(
        uint256 chain_id,
        string memory hash,
        string memory content
    ) public {
        emit Append(chain_id, hash, content);
    }

    function repay(
        uint256 chain_id,
        string memory hash,
        string memory content
    ) public {
        emit Repay(chain_id, hash, content);
    }

    function repay(
        uint256 chain_id,
        string memory hash,
        string memory content,
        uint256 repay_to_chain_id,
        string memory repay_to_hash
    ) public {
        emit RepayTo(chain_id, hash, content, repay_to_chain_id, repay_to_hash);
    }

    // pick
    function pick(uint256 chain_id, string memory hash) public {
        emit Pick(chain_id, hash);
    }

    // Attrs
    function attributes(bytes[] calldata data) public {
        emit Attributes(data);
    }
}