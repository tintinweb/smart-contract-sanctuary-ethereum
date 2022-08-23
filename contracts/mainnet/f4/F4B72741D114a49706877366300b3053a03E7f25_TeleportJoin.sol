/**
 *Submitted for verification at Etherscan.io on 2022-08-22
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

interface VatLike {
    function dai(address) external view returns (uint256);
    function live() external view returns (uint256);
    function urns(bytes32, address) external view returns (uint256, uint256);
    function frob(bytes32, address, address, address, int256, int256) external;
    function hope(address) external;
    function move(address, address, uint256) external;
    function nope(address) external;
    function slip(bytes32, address, int256) external;
}

interface DaiJoinLike {
    function dai() external view returns (TokenLike);
    function exit(address, uint256) external;
    function join(address, uint256) external;
}

interface TokenLike {
    function approve(address, uint256) external returns (bool);
}

interface FeesLike {
    function getFee(TeleportGUID calldata, uint256, int256, uint256, uint256) external view returns (uint256);
}

// Primary control for extending Teleport credit
contract TeleportJoin {
    mapping (address =>        uint256) public wards;     // Auth
    mapping (bytes32 =>        address) public fees;      // Fees contract per source domain
    mapping (bytes32 =>        uint256) public line;      // Debt ceiling per source domain
    mapping (bytes32 =>         int256) public debt;      // Outstanding debt per source domain (can be < 0 when settlement occurs before mint)
    mapping (bytes32 => TeleportStatus) public teleports; // Approved teleports and pending unpaid

    address public vow;

    uint256 internal art; // We need to preserve the last art value before the position being skimmed (End)

    VatLike     immutable public vat;
    DaiJoinLike immutable public daiJoin;
    bytes32     immutable public ilk;
    bytes32     immutable public domain;

    uint256 constant public WAD = 10 ** 18;
    uint256 constant public RAY = 10 ** 27;

    event Rely(address indexed usr);
    event Deny(address indexed usr);
    event File(bytes32 indexed what, address data);
    event File(bytes32 indexed what, bytes32 indexed domain, address data);
    event File(bytes32 indexed what, bytes32 indexed domain, uint256 data);
    event Register(bytes32 indexed hashGUID, TeleportGUID teleportGUID);
    event Mint(
        bytes32 indexed hashGUID, TeleportGUID teleportGUID, uint256 amount, uint256 maxFeePercentage, uint256 operatorFee, address originator
    );
    event Settle(bytes32 indexed sourceDomain, uint256 batchedDaiToFlush);

    struct TeleportStatus {
        bool    blessed;
        uint248 pending;
    }

    constructor(address vat_, address daiJoin_, bytes32 ilk_, bytes32 domain_) {
        wards[msg.sender] = 1;
        emit Rely(msg.sender);
        vat = VatLike(vat_);
        daiJoin = DaiJoinLike(daiJoin_);
        vat.hope(daiJoin_);
        daiJoin.dai().approve(daiJoin_, type(uint256).max);
        ilk = ilk_;
        domain = domain_;
    }

    function _min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x <= y ? x : y;
    }

    modifier auth {
        require(wards[msg.sender] == 1, "TeleportJoin/not-authorized");
        _;
    }

    function rely(address usr) external auth {
        wards[usr] = 1;
        emit Rely(usr);
    }

    function deny(address usr) external auth {
        wards[usr] = 0;
        emit Deny(usr);
    }

    function file(bytes32 what, address data) external auth {
        if (what == "vow") {
            vow = data;
        } else {
            revert("TeleportJoin/file-unrecognized-param");
        }
        emit File(what, data);
    }

    function file(bytes32 what, bytes32 domain_, address data) external auth {
        if (what == "fees") {
            fees[domain_] = data;
        } else {
            revert("TeleportJoin/file-unrecognized-param");
        }
        emit File(what, domain_, data);
    }

    function file(bytes32 what, bytes32 domain_, uint256 data) external auth {
        if (what == "line") {
            require(data <= uint256(type(int256).max), "TeleportJoin/not-allowed-bigger-int256");
            line[domain_] = data;
        } else {
            revert("TeleportJoin/file-unrecognized-param");
        }
        emit File(what, domain_, data);
    }

    /**
    * @dev External view function to get the total debt used by this contract [RAD]
    **/
    function cure() external view returns (uint256 cure_) {
        cure_ = art * RAY;
    }

    /**
    * @dev Internal function that executes the mint after a teleport is registered
    * @param teleportGUID Struct which contains the whole teleport data
    * @param hashGUID Hash of the prev struct
    * @param maxFeePercentage Max percentage of the withdrawn amount (in WAD) to be paid as fee (e.g 1% = 0.01 * WAD)
    * @param operatorFee The amount of DAI to pay to the operator
    * @return postFeeAmount The amount of DAI sent to the receiver after taking out fees
    * @return totalFee The total amount of DAI charged as fees
    **/
    function _mint(
        TeleportGUID calldata teleportGUID,
        bytes32 hashGUID,
        uint256 maxFeePercentage,
        uint256 operatorFee
    ) internal returns (uint256 postFeeAmount, uint256 totalFee) {
        require(teleportGUID.targetDomain == domain, "TeleportJoin/incorrect-domain");

        bool vatLive = vat.live() == 1;

        uint256 line_ = vatLive ? line[teleportGUID.sourceDomain] : 0;

        int256 debt_ = debt[teleportGUID.sourceDomain];

        // Stop execution if there isn't anything available to withdraw
        uint248 pending = teleports[hashGUID].pending;
        if (int256(line_) <= debt_ || pending == 0) {
            emit Mint(hashGUID, teleportGUID, 0, maxFeePercentage, operatorFee, msg.sender);
            return (0, 0);
        }

        uint256 amtToTake = _min(
                                pending,
                                uint256(int256(line_) - debt_)
                            );

        uint256 fee = vatLive ? FeesLike(fees[teleportGUID.sourceDomain]).getFee(teleportGUID, line_, debt_, pending, amtToTake) : 0;
        require(fee <= maxFeePercentage * amtToTake / WAD, "TeleportJoin/max-fee-exceed");

        // No need of overflow check here as amtToTake is bounded by teleports[hashGUID].pending
        // which is already a uint248. Also int256 >> uint248. Then both castings are safe.
        debt[teleportGUID.sourceDomain] +=  int256(amtToTake);
        teleports[hashGUID].pending     -= uint248(amtToTake);

        if (debt_ >= 0 || uint256(-debt_) < amtToTake) {
            uint256 amtToGenerate = debt_ < 0
                                    ? uint256(int256(amtToTake) + debt_) // amtToTake - |debt_|
                                    : amtToTake;
            // amtToGenerate doesn't need overflow check as it is bounded by amtToTake
            vat.slip(ilk, address(this), int256(amtToGenerate));
            vat.frob(ilk, address(this), address(this), address(this), int256(amtToGenerate), int256(amtToGenerate));
            // Query the actual value as someone might have repaid debt without going through settle (if vat.live == 0 prev frob will revert)
            (, art) = vat.urns(ilk, address(this));
        }
        totalFee = fee + operatorFee;
        postFeeAmount = amtToTake - totalFee;
        daiJoin.exit(bytes32ToAddress(teleportGUID.receiver), postFeeAmount);

        if (fee > 0) {
            vat.move(address(this), vow, fee * RAY);
        }
        if (operatorFee > 0) {
            daiJoin.exit(bytes32ToAddress(teleportGUID.operator), operatorFee);
        }

        emit Mint(hashGUID, teleportGUID, amtToTake, maxFeePercentage, operatorFee, msg.sender);
    }

    /**
    * @dev External authed function that registers the teleport and executes the mint after
    * @param teleportGUID Struct which contains the whole teleport data
    * @param maxFeePercentage Max percentage of the withdrawn amount (in WAD) to be paid as fee (e.g 1% = 0.01 * WAD)
    * @param operatorFee The amount of DAI to pay to the operator
    * @return postFeeAmount The amount of DAI sent to the receiver after taking out fees
    * @return totalFee The total amount of DAI charged as fees
    **/
    function requestMint(
        TeleportGUID calldata teleportGUID,
        uint256 maxFeePercentage,
        uint256 operatorFee
    ) external auth returns (uint256 postFeeAmount, uint256 totalFee) {
        bytes32 hashGUID = getGUIDHash(teleportGUID);
        require(!teleports[hashGUID].blessed, "TeleportJoin/already-blessed");
        teleports[hashGUID].blessed = true;
        teleports[hashGUID].pending = teleportGUID.amount;
        emit Register(hashGUID, teleportGUID);
        (postFeeAmount, totalFee) = _mint(teleportGUID, hashGUID, maxFeePercentage, operatorFee);
    }

    /**
    * @dev External function that executes the mint of any pending and available amount (only callable by operator or receiver)
    * @param teleportGUID Struct which contains the whole teleport data
    * @param maxFeePercentage Max percentage of the withdrawn amount (in WAD) to be paid as fee (e.g 1% = 0.01 * WAD)
    * @param operatorFee The amount of DAI to pay to the operator
    * @return postFeeAmount The amount of DAI sent to the receiver after taking out fees
    * @return totalFee The total amount of DAI charged as fees
    **/
    function mintPending(
        TeleportGUID calldata teleportGUID,
        uint256 maxFeePercentage,
        uint256 operatorFee
    ) external returns (uint256 postFeeAmount, uint256 totalFee) {
        require(bytes32ToAddress(teleportGUID.receiver) == msg.sender || 
            bytes32ToAddress(teleportGUID.operator) == msg.sender, "TeleportJoin/not-receiver-nor-operator");
        (postFeeAmount, totalFee) = _mint(teleportGUID, getGUIDHash(teleportGUID), maxFeePercentage, operatorFee);
    }

    /**
    * @dev External function that repays debt with DAI previously pushed to this contract (in general coming from the bridges)
    * @param sourceDomain domain where the DAI is coming from
    * @param batchedDaiToFlush Amount of DAI that is being processed for repayment
    **/
    function settle(bytes32 sourceDomain, uint256 batchedDaiToFlush) external {
        require(batchedDaiToFlush <= uint256(type(int256).max), "TeleportJoin/overflow");
        daiJoin.join(address(this), batchedDaiToFlush);
        if (vat.live() == 1) {
            (, uint256 art_) = vat.urns(ilk, address(this)); // rate == RAY => normalized debt == actual debt
            uint256 amtToPayBack = _min(batchedDaiToFlush, art_);
            vat.frob(ilk, address(this), address(this), address(this), -int256(amtToPayBack), -int256(amtToPayBack));
            vat.slip(ilk, address(this), -int256(amtToPayBack));
            unchecked {
                art = art_ - amtToPayBack; // Always safe operation
            }
        }
        debt[sourceDomain] -= int256(batchedDaiToFlush);
        emit Settle(sourceDomain, batchedDaiToFlush);
    }
}