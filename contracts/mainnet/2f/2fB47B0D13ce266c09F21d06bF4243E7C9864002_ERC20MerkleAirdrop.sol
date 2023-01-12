/**
 *Submitted for verification at Etherscan.io on 2023-01-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library MerkleProof {
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);


    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
pragma solidity ^0.8.0;

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity ^0.8.0;

contract ERC20MerkleAirdrop is Ownable {
    //this value should be set by template
    bytes32 public immutable merkleRoot = 0x3c1fc7abfa02d7d5800b1f826860a774f63ffccd49c8a5c4cb26d3034239504a;

    //this value should be set by template; ERC20 token address that will be used for airdrop
    address public immutable tokenAddress = 0x45979d96Db0858B9859c922dc826676f09399957;

    //comes from template, timestamp of start and end data of compaign
    uint256 public immutable startAt = 1673535610743;
    uint256 public immutable endAt = 1673548200000;

    //id of airdrop created in database
    uint256 public immutable airdropID = 1;

    //comes from template too
    uint256 public immutable totalTokens = 0x3635c9adc5dea00000;
    uint256 public claimedTokens  = 0;
    uint256 public availableTokens = 1000000000000000000000;

    //Mapping  claimed users
    mapping(address => bool) public claimed;

    event Claimed(address account, uint256 amount);

    function claim(
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) public payable {
        require(claimed[account] == false, "user already claimed");

        bytes32 node = keccak256(abi.encodePacked(account, amount));

        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            "invalid proof"
        );

        claimed[account] = true;
        claimedTokens += amount;
        availableTokens -= amount;
        require(IERC20(tokenAddress).transfer(account, amount), "transfer failed");

        emit Claimed(account, amount);
    }

    function checkTime() private view {
        require(endAt == 0 || endAt >= block.timestamp, "airdrop already expired");
        require(startAt == 0 || startAt <= block.timestamp, "airdrop not started yet");
    }

    function claimLeftover(address account) public onlyOwner {
        require(endAt < block.timestamp, "airdrop not finished yet");
        uint256 leftOver = IERC20(tokenAddress).balanceOf(address(this));
        require(IERC20(tokenAddress).transfer(account, leftOver), "transfer failed");
    }
}