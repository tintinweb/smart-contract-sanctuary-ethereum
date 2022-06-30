// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

library StageChecker {
    enum Stages {
        Premint,
        FreeWhitelist,
        Whitelist,
        Public
    }

    error ExceedsMaxLimit(uint256 maxLimit);
    error ExceedsMaxPerTx(Stages stage, uint64 quantity, uint64 maxPerTx);
    error ExceedsCapPerWallet(Stages stage, uint64 total, uint64 capPerWallet);
    error ExceedsMaxCapPerWallet(uint64 total, uint64 maxCapPerWallet);
    error ExceedsMaxSupply(Stages stage, uint64 total, uint64 maxSupply);
    error RequiredValuesNotSet(Stages stage, bool maxValuesSet, bool priceSet);

    function runGeneralChecks(
        Stages _stage,
        uint64 _quantity,
        uint64 _maxPerTx,
        uint256 _maxLimit,
        uint256 _totalMinted,
        uint64 _userFreeWhitelistTotal,
        uint64 _userWhitelistTotal,
        uint64 _userMintTotal,
        uint64 _maxCapPerWallet
    ) external pure {
        if (_quantity > _maxPerTx) revert ExceedsMaxPerTx(_stage, _quantity, _maxPerTx);

        if (_totalMinted + uint256(_quantity) > _maxLimit) revert ExceedsMaxLimit(_maxLimit);

        uint64 freeWhitelistTotal = _userFreeWhitelistTotal + _quantity;
        uint64 whitelistTotal = _userWhitelistTotal + _quantity;
        uint64 mintTotal = _userMintTotal + _quantity;

        uint64 total = freeWhitelistTotal + whitelistTotal + mintTotal;
        if (total > _maxCapPerWallet) revert ExceedsMaxCapPerWallet(total, _maxCapPerWallet);
    }

    function runFreeWhitelistChecks(
        Stages _stage,
        uint64 _userMintTotal,
        uint64 _userFreeWhitelistTotal,
        uint64 _freeWhitelistTotalMinted,
        uint64 _quantity,
        uint64 _capPerWallet,
        uint64 _freeWhitelistMaxSupply
    ) external pure {
        uint64 mintTotal = _userMintTotal + _quantity;
        uint64 freeWhitelistTotal = _userFreeWhitelistTotal + _quantity;
        uint64 totalFreeWhitelist = _freeWhitelistTotalMinted + _quantity;
        if (freeWhitelistTotal > _freeWhitelistMaxSupply)
            revert ExceedsMaxSupply(_stage, totalFreeWhitelist, _freeWhitelistMaxSupply);
        if (freeWhitelistTotal > _capPerWallet) revert ExceedsCapPerWallet(_stage, mintTotal, _capPerWallet);
    }

    function runWhitelistChecks(
        Stages _stage,
        bool _maxValueSet,
        bool _priceSet,
        uint64 _userWhitelistTotal,
        uint64 _quantity,
        uint64 _userMintTotal,
        uint64 _whitelistTotalMinted,
        uint64 _whitelistMaxSupply,
        uint64 _capPerWallet
    ) external pure {
        if (!_maxValueSet || !_priceSet) revert RequiredValuesNotSet(_stage, _maxValueSet, _priceSet);
        uint64 totalWhitelist = _whitelistTotalMinted + _quantity;
        uint64 mintTotal = _userMintTotal + _quantity;
        uint64 whitelistTotal = _userWhitelistTotal + _quantity;
        if (totalWhitelist > _whitelistMaxSupply) revert ExceedsMaxSupply(_stage, totalWhitelist, _whitelistMaxSupply);
        if (whitelistTotal > _capPerWallet) revert ExceedsCapPerWallet(_stage, mintTotal, _capPerWallet);
    }
}