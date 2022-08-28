/**
 *Submitted for verification at Etherscan.io on 2022-08-28
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract VanityProtocol {
    struct Commitment {
        address hunter;
        bytes32 hash;
    }

    struct Bounty {
        uint256 reward;
        Commitment[] commitments;
    }

    enum BountyType {
        ETH_ACCOUNT,
        ETH_CONTRACT,
        BTC_ADDRESS
    }

    mapping(bytes32 => Bounty) bounties;

    event BountySolution(bytes32 bountyHash, bytes32 solution);
    event BountyCreation(
        bytes32 bountyHash,
        BountyType bountyType,
        uint256 reward,
        uint256 prefixMin,
        uint256 prefixMax,
        uint256 param1,
        uint256 param2
    );

    uint256 public protocolFee = 100;
    address public protocolMaintainer;

    // 1,622,799 gas
    constructor() {
        protocolMaintainer = msg.sender;
    }

    // 62,728 gas
    function createBounty(
        BountyType bountyType,
        uint256 prefixMin,
        uint256 prefixMax,
        uint256 param1,
        uint256 param2
    ) public payable returns (bytes32) {
        bytes32 bountyHash = keccak256(
            abi.encodePacked(bountyType, prefixMin, prefixMax, param1, param2)
        );
        require(msg.value > 0, "Bounty must be nonzero");
        Bounty storage bounty = bounties[bountyHash];
        uint256 protocolFeeAmount = (msg.value * protocolFee) / 10000;
        bounty.reward += msg.value - protocolFeeAmount;
        payable(protocolMaintainer).transfer(protocolFeeAmount);
        emit BountyCreation(
            bountyHash,
            bountyType,
            bounty.reward,
            prefixMin,
            prefixMax,
            param1,
            param2
        );
        return bountyHash;
    }

    // 91,485 gas
    function postCommitment(bytes32 bountyHash, bytes32 commitmentHash) public {
        Bounty storage bounty = bounties[bountyHash];
        require(bounty.reward > 0, "Bounty does not exist");
        Commitment storage commitment = bounty.commitments.push();
        commitment.hunter = msg.sender;
        commitment.hash = commitmentHash;
    }

    function getReward(bytes32 bountyHash) public view returns (uint256) {
        Bounty storage bounty = bounties[bountyHash];
        return bounty.reward;
    }

    function _reveal(
        BountyType bountyType,
        uint256 prefixMin,
        uint256 prefixMax,
        uint256 param1,
        uint256 param2,
        bytes32 solution,
        uint256 vanity
    ) internal {
        bytes32 bountyHash = keccak256(
            abi.encodePacked(bountyType, prefixMin, prefixMax, param1, param2)
        );
        Bounty storage bounty = bounties[bountyHash];
        require(bounty.reward > 0, "Bounty is already resolved");
        address winner = getBountyWinner(bounty.commitments, solution);
        require(winner != address(0), "No matching valid commitment");
        require(vanity <= prefixMax, "Vanity address exceeds max prefix");
        require(vanity >= prefixMin, "Vanity address below min prefix");
        emit BountySolution(bountyHash, solution);
        payable(winner).transfer(bounty.reward);
        delete bounties[bountyHash];
    }

    // 48,360 gas
    function revealEthAccount(
        uint256 splitkey,
        uint256 prefixMin,
        uint256 prefixMax,
        uint256 pubX,
        uint256 pubY
    ) public {
        address vanity = getSplitKeyAddress(pubX, pubY, splitkey);
        _reveal(
            BountyType.ETH_ACCOUNT,
            prefixMin,
            prefixMax,
            pubX,
            pubY,
            bytes32(splitkey),
            uint256(uint160(vanity))
        );
    }

    function revealBtcAddress(
        uint256 splitkey,
        uint256 prefixMin,
        uint256 prefixMax,
        uint256 pubX,
        uint256 pubY,
        uint256 witnessX,
        uint256 witnessY
    ) public {
        require(
            getSplitKeyAddress(pubX, pubY, splitkey) ==
                getEthereumAddress(witnessX, witnessY),
            "Invalid witness for split key"
        );
        uint256 vanity = uint160(getBitcoinAddress(witnessX, witnessY));
        _reveal(
            BountyType.BTC_ADDRESS,
            prefixMin,
            prefixMax,
            pubX,
            pubY,
            bytes32(splitkey),
            vanity
        );
    }

    function revealEthContract(
        uint256 salt,
        uint256 prefixMin,
        uint256 prefixMax,
        address deployingAddress,
        bytes32 bytecodeHash
    ) public {
        address vanity = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            deployingAddress,
                            salt,
                            bytecodeHash
                        )
                    )
                ) & 0x00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
            )
        );
        _reveal(
            BountyType.ETH_CONTRACT,
            prefixMin,
            prefixMax,
            uint256(uint160(deployingAddress)),
            uint256(bytecodeHash),
            bytes32(salt),
            uint256(uint160(vanity))
        );
    }

    function getBitcoinAddress(uint256 witnessX, uint256 witnessY)
        private
        pure
        returns (bytes20)
    {
        return
            ripemd160(
                abi.encodePacked(
                    sha256(abi.encodePacked(bytes1(0x04), witnessX, witnessY))
                )
            );
    }

    function getEthereumAddress(uint256 witnessX, uint256 witnessY)
        private
        pure
        returns (address)
    {
        return
            address(
                uint160(
                    uint256(keccak256(abi.encodePacked(witnessX, witnessY))) &
                        0x00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
                )
            );
    }

    // This is based on the trick for using ecrecover to do arbitrary ecmul outlined in
    // https://ethresear.ch/t/you-can-kinda-abuse-ecrecover-to-do-ecmul-in-secp256k1-today/2384
    // The goal here is to compute keccak(G*splitkey + pubkey), i.e. the ultimate vanity
    // address that someone can obtain by adding splitkey  to a private key. We abusee
    // ecrecover with a specially crafted msghash which allows us to get this done in one step.
    // Without this trick, we would need to use something like 50x the amount of gas

    function getSplitKeyAddress(
        uint256 pubkeyX,
        uint256 pubkeyY,
        uint256 splitkey
    ) private pure returns (address) {
        uint256 N = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;
        bytes32 msghash = bytes32(mulmod(((N - splitkey) % N), pubkeyX, N));
        uint8 v = pubkeyY % 2 != 0 ? 28 : 27;
        return ecrecover(msghash, v, bytes32(pubkeyX), bytes32(pubkeyX));
    }

    function getBountyWinner(Commitment[] memory commitments, bytes32 solution)
        private
        pure
        returns (address)
    {
        for (uint256 i = 0; i < commitments.length; i++) {
            if (
                keccak256(abi.encodePacked(solution, commitments[i].hunter)) ==
                commitments[i].hash
            ) {
                return commitments[i].hunter;
            }
        }
        return address(0);
    }

    function setProtocolFee(uint256 newProtocolFee, address newMaintainer)
        public
    {
        require(
            msg.sender == protocolMaintainer,
            "Can only be called by maintainer"
        );
        protocolFee = newProtocolFee;
        protocolMaintainer = newMaintainer;
    }
}