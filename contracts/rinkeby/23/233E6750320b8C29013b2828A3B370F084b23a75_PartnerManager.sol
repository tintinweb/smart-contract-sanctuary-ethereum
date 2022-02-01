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

pragma solidity ^0.8.11;

import "./interfaces/IPartnerManager.sol";

/// @title Partner Manager
/// @author deus.finance
/// @notice synchronizer's partner manager
contract PartnerManager is IPartnerManager {
    address public platform; // platform multisig address
    uint256[] public minimumRegistrarFee; // platform minimum trading fee
    uint256 public scale = 1e18; // used for math
    mapping(address => bool) public isPartner; // partnership of address
    mapping(address => uint256) public partnerShare; // parner's share (e.g. 1e18 = 100%)
    mapping(address => uint256[]) public partnerTradingFee; // partner address => registrar fee list (e.g. 1e18 = 100%)s

    constructor(address platform_, uint256[] memory minimumRegistrarFee_) {
        platform = platform_;
        minimumRegistrarFee = minimumRegistrarFee_;
    }

    /// @notice to add partner
    /// @param owner address of partner multisig
    /// @param share share of partner
    /// @param registrarTradingFee fee os registrar type (e.g. 0: stock, 1: crypto, 2: forex)
    function addPartner(
        address owner,
        uint256 share,
        uint256[] memory registrarTradingFee
    ) external {
        require(!isPartner[owner], "SYNCHRONIZER: partner has been set");
        for (uint256 i = 0; i < minimumRegistrarFee.length; i++) {
            require(
                registrarTradingFee[i] - ((share * registrarTradingFee[i]) / scale) >= minimumRegistrarFee[i],
                "SYNCHRONIZER: invalid registrar fee"
            );
        }
        isPartner[owner] = true;
        partnerShare[owner] = share;
        partnerTradingFee[owner] = registrarTradingFee;
        emit PartnerAdded(owner, share, registrarTradingFee);
    }
}
//Dar panah khoda

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IPartnerManager {

    event PartnerAdded(address owner, uint256 share, uint256[] registrarTradingFee);

    function platform() external view returns (address);
    function minimumRegistrarFee(uint256 index) external view returns (uint256);
    function scale() external view returns (uint256);
    function isPartner(address partner) external view returns (bool);
    function partnerShare(address partner) external view returns (uint256);
    function partnerTradingFee(address partner, uint256 index) external view returns (uint256);
    function addPartner(
        address owner,
        uint256 share,
        uint256[] memory registrarTradingFee
    ) external;
}