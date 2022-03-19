// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./ERC20.sol";

contract ClaimableToken is ERC20 {
    mapping(address => bool) private _minted;
    uint256 private _nonowner_minted_wei = 0;
    uint256 private _owner_minted_wei = 0;
    bytes32 private _root;
    address private _creator_address;
    string public official_public_key_fingerprint =
        "0393 E867 815B 3770 7171 6974 58C2 D25B C472 3E97";
    bool public official_ipfs_address_locked = false;
    string public official_ipfs_address;

    constructor(
        string memory name_,
        string memory symbol_,
        bytes32 root_
    ) ERC20(name_, symbol_) {
        _creator_address = msg.sender;
        _root = root_;
    }

    function setIpfs(string memory official_ipfs_address_) public {
        require(!official_ipfs_address_locked, "IPFS Address is locked.");
        require(
            _creator_address == msg.sender,
            "Only the owner can call this function."
        );
        official_ipfs_address = official_ipfs_address_;
    }

    function lockIpfs() public // permanently locks ipfs address
    {
        require(
            _creator_address == msg.sender,
            "Only the owner can call this function."
        );
        official_ipfs_address_locked = true;
    }

    function computeLeafHash(address to, uint256 amount_wei)
        public
        pure
        returns (bytes32)
    {
        // Is it easy to create a collision here?? Need to think
        return keccak256(abi.encodePacked(to, amount_wei));
    }

    function claimable(
        address to,
        uint256 amount_wei,
        bytes32[] memory proof
    ) public view returns (bool) {
        bytes32 computedHash = computeLeafHash(to, amount_wei);
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            }
        }
        return computedHash == _root;
    }

    function claimToken(
        address to,
        uint256 amount_wei,
        bytes32[] memory proof
    ) public {
        require(claimable(to, amount_wei, proof), "Proof is invalid.");
        require(!_minted[to], "Token is already claimed.");
        _minted[to] = true;
        uint256 amount_tokens = amount_wei * 1000;
        _nonowner_minted_wei += amount_tokens;
        super._mint(to, amount_tokens);
    }

    function mineOwnerTokens() public {
        require(
            _creator_address == msg.sender,
            "Only the owner can call this function."
        );
        uint256 owner_supply = _nonowner_minted_wei / 20;
        uint256 owner_mintable_wei = owner_supply - _owner_minted_wei;
        require(
            owner_mintable_wei > 0,
            "All claimable tokens are already claimed."
        );
        _owner_minted_wei += owner_mintable_wei;
        super._mint(_creator_address, owner_mintable_wei);
    }
}