/**
 *Submitted for verification at Etherscan.io on 2022-11-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


contract BatchClaimXEN {
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1167.md
    bytes miniProxy;              // = 0x363d3d373d3d3d363d73bebebebebebebebebebebebebebebebebebebebe5af43d82803e903d91602b57fd5bf3;
    address private immutable original;
    address private immutable deployer;
    address private constant XEN = 0xca41f293A32d25c2216bC4B30f5b0Ab61b6ed2CB;
    mapping(address => uint) public countClaimRank;
    mapping(address => uint) public countClaimMint;

    constructor() {
        miniProxy = bytes.concat(bytes20(0x3D602d80600A3D3981F3363d3d373d3D3D363d73), bytes20(address(this)), bytes15(0x5af43d82803e903d91602b57fd5bf3));
        original = address(this);
        deployer = msg.sender;
    }

    struct MintInfo {
        address user;
        uint256 term;
        uint256 maturityTs;
        uint256 rank;
        uint256 amplifier;
        uint256 eaaRate;
    }

    function batchClaimRank(uint times, uint term) external {
        bytes memory bytecode = miniProxy;
        address proxy;
        uint N = countClaimRank[msg.sender];
        for (uint i = N; i < N + times; i++) {
            bytes32 salt = keccak256(abi.encodePacked(msg.sender, i));
            assembly {
                proxy := create2(0, add(bytecode, 32), mload(bytecode), salt)
            }
            BatchClaimXEN(proxy).claimRank(term);
        }
        countClaimRank[msg.sender] = N + times;
    }

    function claimRank(uint term) external {
        IXEN(XEN).claimRank(term);
    }


    function userMints(address account) public view returns (MintInfo memory) {
        IXEN.MintInfo memory _mt = IXEN(XEN).userMints(account);
        return MintInfo({
        user : _mt.user,
        term : _mt.term,
        maturityTs : _mt.maturityTs,
        rank : _mt.rank,
        amplifier : _mt.amplifier,
        eaaRate : _mt.eaaRate
        });
    }


    function proxyFor(address sender, uint i) public view returns (address proxy) {
        bytes32 salt = keccak256(abi.encodePacked(sender, i));
        proxy = address(uint160(uint(keccak256(abi.encodePacked(
                hex'ff',
                address(this),
                salt,
                keccak256(abi.encodePacked(miniProxy))
            )))));
    }

    function batchClaimMintReward(uint times) external {
        uint M = countClaimMint[msg.sender];
        uint N = countClaimRank[msg.sender];
        N = M + times < N ? M + times : N;
        for (uint i = M; i < N; i++) {
            address proxy = proxyFor(msg.sender, i);
            BatchClaimXEN(proxy).claimMintRewardTo(msg.sender);
        }
        countClaimMint[msg.sender] = N;
    }

    function queryClaimMintInfo() external view returns (MintInfo[] memory mintInfos){
        uint N = countClaimRank[msg.sender];
        MintInfo[] memory mints = new MintInfo[](N);
        for (uint i = 0; i < N; i++) {
            address proxy = proxyFor(msg.sender, i);
            MintInfo memory mint = BatchClaimXEN(proxy).userMints(proxy);
            mints[i] = mint;
        }
        return mints;
    }


    function claimMintRewardTo(address to) external {
        require(msg.sender == original);
        IXEN(XEN).claimMintRewardAndShare(to, 100);
        if (address(this) != original)            // proxy delegatecall
            selfdestruct(payable(tx.origin));
    }

}

interface IXEN {

    struct MintInfo {
        address user;
        uint256 term;
        uint256 maturityTs;
        uint256 rank;
        uint256 amplifier;
        uint256 eaaRate;
    }

    function claimRank(uint term) external;

    function claimMintReward() external;

    function claimMintRewardAndShare(address other, uint256 pct) external;

    function transfer(address recipient, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function userMints(address account) external view returns (MintInfo memory);


}