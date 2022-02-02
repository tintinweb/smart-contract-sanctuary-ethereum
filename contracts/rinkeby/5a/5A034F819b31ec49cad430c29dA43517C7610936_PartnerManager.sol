// Be name Khoda
// Bime Abolfazl
// SPDX-License-Identifier: MIT

// =================================================================================================================
//  _|_|_|    _|_|_|_|  _|    _|    _|_|_|      _|_|_|_|  _|                                                       |
//  _|    _|  _|        _|    _|  _|            _|            _|_|_|      _|_|_|  _|_|_|      _|_|_|    _|_|       |
//  _|    _|  _|_|_|    _|    _|    _|_|        _|_|_|    _|  _|    _|  _|    _|  _|    _|  _|        _|_|_|_|     |
//  _|    _|  _|        _|    _|        _|      _|        _|  _|    _|  _|    _|  _|    _|  _|        _|           |
//  _|_|_|    _|_|_|_|    _|_|    _|_|_|        _|        _|  _|    _|    _|_|_|  _|    _|    _|_|_|    _|_|_|     |
// =================================================================================================================
// ==================== Partner Manager ===================
// ========================================================
// DEUS Finance: https://github.com/DeusFinance

// Primary Author(s)
// Vahid: https://github.com/vahid-dev
// M.R.M: https://github.com/mrmousavi78

pragma solidity ^0.8.11;

import "./interfaces/IPartnerManager.sol";

/// @title Partner Manager
/// @author deus.finance
/// @notice synchronizer's partner manager
contract PartnerManager is IPartnerManager {

    uint256[3] public platformFee; // platform trading fee
    mapping(address => uint256[3]) public partnerFee; // partner address => PartnerFee (e.g. 1e18 = 100%)
    address public platform; // platform multisig address
    uint256 public scale = 1e18; // used for math
    mapping(address => bool) public isPartner; // partnership of address

    constructor(address platform_, uint256[3] memory platformFee_) {
        platform = platform_;
        platformFee = platformFee_;
    }

    /// @notice to add partner
    /// @param owner address of partner multisig
    /// @param stockFee stock's fee (e.g. 1e18 = 100%)
    /// @param cryptoFee crypto's fee (e.g. 1e18 = 100%)
    /// @param forexFee forex's fee (e.g. 1e18 = 100%)
    function addPartner(
        address owner,
        uint256 stockFee,
        uint256 cryptoFee,
        uint256 forexFee
    ) external {
        require(!isPartner[owner], "SYNCHRONIZER: partner has been set");
        require(stockFee >= platformFee[0], "SYNCHRONIZER: stock fee should be greater than or equal platform fee");
        require(cryptoFee >= platformFee[1], "SYNCHRONIZER: crypto fee should be greater than or equal platform fee");
        require(forexFee >= platformFee[2], "SYNCHRONIZER: forex fee should be greater than or equal platform fee");

        isPartner[owner] = true;
        partnerFee[owner] = [stockFee, cryptoFee, forexFee];
        emit PartnerAdded(owner, partnerFee[owner]);
    }
}
//Dar panah khoda

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IPartnerManager {

    event PartnerAdded(address owner, uint256[3] partnerFee);

    function platformFee(uint256 index) external view returns (uint256);
    function partnerFee(address partner, uint256 index) external view returns (uint256);
    function platform() external view returns (address);
    function scale() external view returns (uint256);
    function isPartner(address partner) external view returns (bool);

    function addPartner(
        address owner,
        uint256 stockFee,
        uint256 cryptoFee,
        uint256 forexFee
    ) external;
}