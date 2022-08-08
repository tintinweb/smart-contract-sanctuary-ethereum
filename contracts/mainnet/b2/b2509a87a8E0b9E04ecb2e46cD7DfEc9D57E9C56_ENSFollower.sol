// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@ensdomains/ens-contracts/contracts/registry/ENS.sol";

contract ENSFollower {
    mapping(bytes32 => uint256) public followingCount;
    mapping(bytes32 => uint256) public followerCount;
    mapping(bytes32 => mapping(bytes32 => bool)) private followingBitMap;
    ENS public immutable registry;

    constructor(ENS registry_) {
        registry = registry_;
    }

    function isFollowing(bytes32 domain, bytes32 domainFollowed)
        external
        view
        returns (bool)
    {
        return followingBitMap[domain][domainFollowed];
    }

    function follow(
        address account,
        bytes32 domain,
        bytes32 domainToFollow
    ) external {
        if (followingBitMap[domain][domainToFollow] == true) {
            revert("Domain is already followed");
        }

        if (registry.owner(domain) != account) {
            revert("Domain not owned by this account");
        }

        followingBitMap[domain][domainToFollow] = true;
        followingCount[domain] = followingCount[domain] + 1;
        followerCount[domainToFollow] = followerCount[domainToFollow] + 1;

        emit Followed(account, domain, domainToFollow);
    }

    function unfollow(
        address account,
        bytes32 domain,
        bytes32 domainToUnfollow
    ) external {
        if (followingBitMap[domain][domainToUnfollow] == false) {
            revert("Domain is already not followed");
        }

        if (registry.owner(domain) != account) {
            revert("Domain not owned by this account");
        }

        followingBitMap[domain][domainToUnfollow] = false;
        followingCount[domain] = followingCount[domain] - 1;
        followerCount[domainToUnfollow] = followerCount[domainToUnfollow] - 1;

        emit Unfollowed(account, domain, domainToUnfollow);
    }

    // This event is triggered whenever a call to #follow succeeds.
    event Followed(address account, bytes32 domain, bytes32 domainToFollow);

    // This event is triggered whenever a call to #unfollow succeeds.
    event Unfollowed(address account, bytes32 domain, bytes32 domainToFollow);
}

pragma solidity >=0.8.4;

interface ENS {
    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);

    // Logged when an operator is added or removed.
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function setRecord(
        bytes32 node,
        address owner,
        address resolver,
        uint64 ttl
    ) external;

    function setSubnodeRecord(
        bytes32 node,
        bytes32 label,
        address owner,
        address resolver,
        uint64 ttl
    ) external;

    function setSubnodeOwner(
        bytes32 node,
        bytes32 label,
        address owner
    ) external returns (bytes32);

    function setResolver(bytes32 node, address resolver) external;

    function setOwner(bytes32 node, address owner) external;

    function setTTL(bytes32 node, uint64 ttl) external;

    function setApprovalForAll(address operator, bool approved) external;

    function owner(bytes32 node) external view returns (address);

    function resolver(bytes32 node) external view returns (address);

    function ttl(bytes32 node) external view returns (uint64);

    function recordExists(bytes32 node) external view returns (bool);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}