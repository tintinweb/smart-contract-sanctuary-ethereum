/**
 *Submitted for verification at Etherscan.io on 2022-11-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// Fix by https://bscscan.com/address/0xD68a9936Bd48A0BD9274eB4e2BF0542822630De0#code
contract BatchClaimXEN {
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1167.md
    bytes miniProxy; // = 0x363d3d373d3d3d363d73bebebebebebebebebebebebebebebebebebebebe5af43d82803e903d91602b57fd5bf3;
    address private immutable original;
    address private immutable deployer;
    //address private constant XEN = 0x4DE35392c51885e88bCeF722A5DE8ab200628254;
    address private constant XEN = 0x06450dEe7FD2Fb8E39061434BAbCFC05599a6Fb8;
    mapping(address => uint256) public countClaimRank;
    mapping(address => uint256) public countClaimMint;

    constructor() {
        miniProxy = bytes.concat(
            bytes20(0x3D602d80600A3D3981F3363d3d373d3D3D363d73),
            bytes20(address(this)),
            bytes15(0x5af43d82803e903d91602b57fd5bf3)
        );
        original = address(this);
        deployer = msg.sender;
    }

    function batchClaimRank(uint256 times, uint256 term) external {
        bytes memory bytecode = miniProxy;
        address proxy;
        uint256 N = countClaimRank[msg.sender];
        for (uint256 i = N; i < N + times; i++) {
            bytes32 salt = keccak256(abi.encodePacked(msg.sender, i));
            assembly {
                proxy := create2(0, add(bytecode, 32), mload(bytecode), salt)
            }
            BatchClaimXEN(proxy).claimRank(term);
        }
        countClaimRank[msg.sender] = N + times;
    }

    function claimRank(uint256 term) external {
        IXEN(XEN).claimRank(term);
    }

    function proxyFor(address sender, uint256 i)
        public
        view
        returns (address proxy)
    {
        bytes32 salt = keccak256(abi.encodePacked(sender, i));
        proxy = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            address(this),
                            salt,
                            keccak256(abi.encodePacked(miniProxy))
                        )
                    )
                )
            )
        );
    }

    function batchClaimMintReward(uint256 times) external {
        uint256 M = countClaimMint[msg.sender];
        uint256 N = countClaimRank[msg.sender];
        N = M + times < N ? M + times : N;
        for (uint256 i = M; i < N; i++) {
            address proxy = proxyFor(msg.sender, i);
            BatchClaimXEN(proxy).claimMintRewardTo(msg.sender);
        }
        countClaimMint[msg.sender] = N;
    }

    function claimMintRewardTo(address to) external {
        require(msg.sender == original);
        IXEN(XEN).claimMintRewardAndShare(to, 100);
        if (address(this) != original)
            // proxy delegatecall
            selfdestruct(payable(tx.origin));
    }
}

interface IXEN {
    function claimRank(uint256 term) external;

    function claimMintReward() external;

    function claimMintRewardAndShare(address other, uint256 pct) external;

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function balanceOf(address account) external view returns (uint256);
}