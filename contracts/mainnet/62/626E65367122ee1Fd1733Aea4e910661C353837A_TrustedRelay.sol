/**
 *Submitted for verification at Etherscan.io on 2022-08-22
*/

/**
 *Submitted for verification at Etherscan.io on 2022-08-16
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2021 Dai Foundation
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

interface DsValueLike {
    function peek() external view returns (bytes32, bool);
}

// Relay messages automatically on the target domain
// User provides gasFee which is paid to the msg.sender
// Relay requests are signed by a trusted third-party (typically a backend orchestrating the withdrawal on behalf of the user)
contract TrustedRelay {

    mapping (address => uint256) public wards;   // Auth (Maker governance)
    mapping (address => uint256) public buds;    // Admin accounts managing trusted signers
    mapping (address => uint256) public signers; // Trusted signers
    
    uint256                public gasMargin; // in BPS (e.g 150% = 15000)

    DaiJoinLike            public immutable daiJoin;
    TokenLike              public immutable dai;
    TeleportOracleAuthLike public immutable oracleAuth;
    TeleportJoinLike       public immutable teleportJoin;
    DsValueLike            public immutable ethPriceOracle;

    uint256 constant public WAD_BPS = 10 ** 22; // WAD * BPS = 10^18 * 10^4
    
    event Rely(address indexed usr);
    event Deny(address indexed usr);
    event Kissed(address indexed usr);
    event Dissed(address indexed usr);
    event File(bytes32 indexed what, uint256 data);
    event SignersAdded(address[] signers);
    event SignersRemoved(address[] signers);

    modifier auth {
        require(wards[msg.sender] == 1, "TrustedRelay/not-authorized");
        _;
    }
    
    modifier toll { 
        require(buds[msg.sender] == 1, "TrustedRelay/non-manager"); 
        _;
    }

    constructor(address _oracleAuth, address _daiJoin, address _ethPriceOracle) {
        wards[msg.sender] = 1;
        emit Rely(msg.sender);
        oracleAuth = TeleportOracleAuthLike(_oracleAuth);
        daiJoin = DaiJoinLike(_daiJoin);
        dai = daiJoin.dai();
        teleportJoin = oracleAuth.teleportJoin();
        ethPriceOracle = DsValueLike(_ethPriceOracle);
    }

    function rely(address usr) external auth {
        wards[usr] = 1;
        emit Rely(usr);
    }

    function deny(address usr) external auth {
        wards[usr] = 0;
        emit Deny(usr);
    }

    function kiss(address usr) external auth {
        buds[usr] = 1;
        emit Kissed(usr);
    }

    function diss(address usr) external auth {
        buds[usr] = 0;
        emit Dissed(usr);
    }

    function file(bytes32 what, uint256 data) external auth {
        if (what == "margin") {
            gasMargin = data;
        } else {
            revert("TrustedRelay/file-unrecognized-param");
        }
        emit File(what, data);
    }

    function addSigners(address[] calldata signers_) external toll {
        for(uint256 i; i < signers_.length; i++) {
            signers[signers_[i]] = 1;
        }
        emit SignersAdded(signers_);
    }

    function removeSigners(address[] calldata signers_) external toll {
        for(uint256 i; i < signers_.length; i++) {
            signers[signers_[i]] = 0;
        }
        emit SignersRemoved(signers_);
    }

    /**
     * @notice Gasless relay for the Oracle fast path
     * The final signature is ABI-encoded `hashGUID`, `maxFeePercentage`, `gasFee`, `expiry`
     * @param teleportGUID The teleport GUID
     * @param signatures The byte array of concatenated signatures ordered by increasing signer addresses.
     * Each signature is {bytes32 r}{bytes32 s}{uint8 v}
     * @param maxFeePercentage Max percentage of the withdrawn amount (in WAD) to be paid as fee (e.g 1% = 0.01 * WAD)
     * @param gasFee DAI gas fee (in WAD)
     * @param expiry Maximum time for when the query is valid
     * @param v Part of ECDSA signature
     * @param r Part of ECDSA signature
     * @param s Part of ECDSA signature
     * @param to (optional) The address of an external contract to call after requesting the L1 DAI (address(0) if unused)
     * @param data (optional) The calldata to use for the call to the aforementionned external contract
     */
    function relay(
        TeleportGUID calldata teleportGUID,
        bytes calldata signatures,
        uint256 maxFeePercentage,
        uint256 gasFee,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s,
        address to,
        bytes calldata data
    ) external {
        uint256 startGas = gasleft();

        // Withdraw the L1 DAI to the receiver
        requestMint(teleportGUID, signatures, maxFeePercentage, gasFee, expiry, v, r, s);

        // Send the gas fee to the relayer
        dai.transfer(msg.sender, gasFee);

        // Optionally execute an external call
        if(to != address(0)) {
            (bool success,) = to.call(data);
            if (!success) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }
        }

        // If the eth price oracle is enabled, use its value to check that gasFee is within an allowable margin
        (bytes32 ethPrice, bool ok) = ethPriceOracle.peek();
        require(!ok || gasFee * WAD_BPS <= uint256(ethPrice) * gasMargin * gasprice() * (startGas - gasleft()), "TrustedRelay/excessive-gas-fee");
    }

    function requestMint(
        TeleportGUID calldata teleportGUID,
        bytes calldata signatures,
        uint256 maxFeePercentage,
        uint256 gasFee,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        require(block.timestamp <= expiry, "TrustedRelay/expired");
        bytes32 signHash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32", 
            keccak256(abi.encode(getGUIDHash(teleportGUID), maxFeePercentage, gasFee, expiry))
        ));
        address recovered = ecrecover(signHash, v, r, s);
        require(signers[recovered] == 1 || bytes32ToAddress(teleportGUID.receiver) == recovered, "TrustedRelay/invalid-signature");

        // Initiate mint and mark the teleport as done
        (uint256 postFeeAmount, uint256 totalFee) = oracleAuth.requestMint(teleportGUID, signatures, maxFeePercentage, gasFee);
        require(postFeeAmount + totalFee == teleportGUID.amount, "TrustedRelay/partial-mint-disallowed");
    }

    function gasprice() internal virtual view returns (uint256) {
        return tx.gasprice;
    }

}