/**
 *Submitted for verification at Etherscan.io on 2022-11-23
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2022 Dai Foundation
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.8.15;

// Standard Maker Teleport GUID
struct TeleportGUID {
    bytes32 sourceDomain;
    bytes32 targetDomain;
    bytes32 receiver;
    bytes32 operator;
    uint128 amount;
    uint80 nonce;
    uint48 timestamp;
}

// solhint-disable-next-line func-visibility
function bytes32ToAddress(bytes32 addr) pure returns (address) {
    return address(uint160(uint256(addr)));
}

// solhint-disable-next-line func-visibility
function addressToBytes32(address addr) pure returns (bytes32) {
    return bytes32(uint256(uint160(addr)));
}

// solhint-disable-next-line func-visibility
function getGUIDHash(TeleportGUID memory teleportGUID) pure returns (bytes32 guidHash) {
    guidHash = keccak256(abi.encode(
        teleportGUID.sourceDomain,
        teleportGUID.targetDomain,
        teleportGUID.receiver,
        teleportGUID.operator,
        teleportGUID.amount,
        teleportGUID.nonce,
        teleportGUID.timestamp
    ));
}

interface DaiJoinLike {
    function dai() external view returns (TokenLike);
    function exit(address, uint256) external;
    function join(address, uint256) external;
}

interface TokenLike {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
}

interface TeleportOracleAuthLike {
    function requestMint(
        TeleportGUID calldata teleportGUID,
        bytes calldata signatures,
        uint256 maxFeePercentage,
        uint256 operatorFee
    ) external returns (uint256 postFeeAmount, uint256 totalFee);
    function teleportJoin() external view returns (TeleportJoinLike);
}

interface TeleportJoinLike {
    function teleports(bytes32 hashGUID) external view returns (bool, uint248);
}

// Relay messages automatically on the target domain
// User provides gasFee which is paid to the msg.sender
contract BasicRelay {

    mapping (address => uint256) public wards;    // Auth
    mapping (address => uint256) public relayers; // Whitelisted relayers

    DaiJoinLike            public immutable daiJoin;
    TokenLike              public immutable dai;
    TeleportOracleAuthLike public immutable oracleAuth;
    TeleportJoinLike       public immutable teleportJoin;

    event Rely(address indexed usr);
    event Deny(address indexed usr);
    event RelayersAdded(address[] relayers);
    event RelayersRemoved(address[] relayers);

    modifier auth {
        require(wards[msg.sender] == 1, "BasicRelay/not-authorized");
        _;
    }

    constructor(address _oracleAuth, address _daiJoin) {
        wards[msg.sender] = 1;
        emit Rely(msg.sender);
        oracleAuth = TeleportOracleAuthLike(_oracleAuth);
        daiJoin = DaiJoinLike(_daiJoin);
        dai = daiJoin.dai();
        teleportJoin = oracleAuth.teleportJoin();
    }

    function rely(address usr) external auth {
        wards[usr] = 1;
        emit Rely(usr);
    }

    function deny(address usr) external auth {
        wards[usr] = 0;
        emit Deny(usr);
    }

    function addRelayers(address[] calldata relayers_) external auth {
        for(uint256 i; i < relayers_.length; i++) {
            relayers[relayers_[i]] = 1;
        }
        emit RelayersAdded(relayers_);
    }

    function removeRelayers(address[] calldata relayers_) external auth {
        for(uint256 i; i < relayers_.length; i++) {
            relayers[relayers_[i]] = 0;
        }
        emit RelayersRemoved(relayers_);
    }

    /**
     * @notice Gasless relay for the Oracle fast path
     * The final signature is ABI-encoded `hashGUID`, `maxFeePercentage`, `gasFee`, `expiry`.
     * Must be called by a whitelisted relayer account with the feeCollector address appended
     * at the end of the calldata, e.g.: `(bool success,) = address(basicRelay).call(abi.encodePacked(relayData, feeCollector));`
     * @param teleportGUID The teleport GUID
     * @param signatures The byte array of concatenated signatures ordered by increasing signer addresses.
     * Each signature is {bytes32 r}{bytes32 s}{uint8 v}
     * @param maxFeePercentage Max percentage of the withdrawn amount (in WAD) to be paid as fee (e.g 1% = 0.01 * WAD)
     * @param gasFee DAI gas fee (in WAD)
     * @param expiry Maximum time for when the query is valid
     * @param v Part of ECDSA signature
     * @param r Part of ECDSA signature
     * @param s Part of ECDSA signature
     */
    function relay(
        TeleportGUID calldata teleportGUID,
        bytes calldata signatures,
        uint256 maxFeePercentage,
        uint256 gasFee,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(relayers[msg.sender] == 1, "BasicRelay/not-whitelisted");
        require(block.timestamp <= expiry, "BasicRelay/expired");
        bytes32 signHash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32", 
            keccak256(abi.encode(getGUIDHash(teleportGUID), maxFeePercentage, gasFee, expiry))
        ));
        address recovered = ecrecover(signHash, v, r, s);
        require(bytes32ToAddress(teleportGUID.receiver) == recovered, "BasicRelay/invalid-signature");

        // Initiate mint and mark the teleport as done
        (uint256 postFeeAmount, uint256 totalFee) = oracleAuth.requestMint(teleportGUID, signatures, maxFeePercentage, gasFee);
        require(postFeeAmount + totalFee == teleportGUID.amount, "BasicRelay/partial-mint-disallowed");

        // Send the gas fee to the fee collector
        address feeCollector;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            feeCollector := shr(96, calldataload(sub(calldatasize(), 20))) // Gelato passes the feeCollector in the same way as in EIP-2771
        }
        dai.transfer(feeCollector, gasFee);
    }

}