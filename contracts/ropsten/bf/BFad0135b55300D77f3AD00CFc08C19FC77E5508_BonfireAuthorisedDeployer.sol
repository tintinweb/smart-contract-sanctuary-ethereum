// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

contract BonfireAuthorisedDeployer {
    address public owner;
    mapping(address => bool) public authority;

    event Deployed(address indexed addr, uint256 indexed salt);
    event AuthorityUpdate(address indexed account, bool enabled);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    modifier authorised() {
        require(
            msg.sender == owner || authority[msg.sender],
            "BonfireAuthorisedDeployer: not authorised"
        );
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "BonfireAuthorisedDeployer: owner only");
        _;
    }

    constructor() {
        owner = address(0xBF007C28b08e925C0fe008A62ad5C2F32B465182);
        emit OwnershipTransferred(address(0), owner);
    }

    function transferOwnership(address newOwner) external {
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function setAuthorised(address account, bool enabled) external onlyOwner {
        authority[account] = enabled;
        emit AuthorityUpdate(account, enabled);
    }

    function authorisedDeploy(bytes memory bytecode, uint256 salt)
        public
        authorised
        returns (address addr)
    {
        assembly {
            addr := create2(0, add(bytecode, 32), mload(bytecode), salt)

            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        emit Deployed(addr, salt);
    }
}