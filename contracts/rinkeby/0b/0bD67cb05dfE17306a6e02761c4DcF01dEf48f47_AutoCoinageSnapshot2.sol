// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AutoCoinageSnapshotStorage2.sol";
// import "hardhat/console.sol";

import "../powerton/AutoRefactorCoinageI.sol";
import "../powerton/SeigManagerI.sol";
import "../powerton/Layer2RegistryI.sol";

import "../interfaces/IAutoCoinageSnapshot2.sol";

import "@openzeppelin/contracts/utils/Counters.sol";
import "../libraries/SArrays.sol";
import { DSMath } from "../libraries/DSMath.sol";

/// @title A snapshot contract that records the amount of staked TON on the tokamak network.
contract AutoCoinageSnapshot2 is AutoCoinageSnapshotStorage2, DSMath, IAutoCoinageSnapshot2 {
    using SArrays for uint256[];
    using Counters for Counters.Counter;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    /// @notice Set the address of seigManager and layer2Registry.
    /// @inheritdoc IAutoCoinageSnapshot2
    function setAddress(address _seigManager, address _layer2Registry) external override  onlyRole(ADMIN_ROLE) {
        require(_seigManager != address(0) && _layer2Registry != address(0) , "zero address");
        seigManager = _seigManager;
        layer2Registry = _layer2Registry;
    }

    /// @notice To support the basic interface of ERC20, set name, symbol, decimals.
    /// @inheritdoc IAutoCoinageSnapshot2
    function setNameSymbolDecimals(string memory name_, string memory symbol_, uint256 decimals_) external override onlyRole(ADMIN_ROLE) {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
    }

    /// @notice Managed Layer 2 addresses can be added by the administrator.
    /// @inheritdoc IAutoCoinageSnapshot2
    function addLayer2s(address[] memory _layers) external override onlyRole(ADMIN_ROLE) {

        for (uint256 i = 0; i < _layers.length; i++) {
            if (!existLayer2s[_layers[i]]) {
                existLayer2s[_layers[i]] = true;
                layer2s.push(_layers[i]);
            }
        }
    }

    /// @notice Managed Layer2 address can be deleted by the administrator.
    /// @inheritdoc IAutoCoinageSnapshot2
    function delLayer2(address _layer) external override onlyRole(ADMIN_ROLE) {

        if (existLayer2s[_layer]) {
            existLayer2s[_layer] = false;

            if (layer2s.length > 0) {
                if (layer2s[0] == _layer && layer2s.length == 1) {
                    layer2s.pop();
                } else if (layer2s[0] == _layer) {
                    layer2s[0] = layer2s[layer2s.length - 1];
                    layer2s.pop();
                } else {
                    uint256 maxIndex = layer2s.length - 1;
                    for (uint256 j = maxIndex; j > 0; j--) {
                        if (layer2s[j] == _layer && j < (layer2s.length - 1)) {
                            layer2s[j] = layer2s[layer2s.length - 1];
                            layer2s.pop();
                            break;
                        } else if (layer2s[j] == _layer && j == (layer2s.length - 1)) {
                            layer2s.pop();
                            break;
                        }
                    }
                }
            }
        }
    }

    /// @inheritdoc IAutoCoinageSnapshot2
    function addSync(address layer2, address account) public override onlyRole(ADMIN_ROLE) returns (uint256) {

        if (!existLayer2s[layer2]) {
            existLayer2s[layer2] = true;
            layer2s.push(layer2);
        }

        address[] memory accounts = needSyncs[layer2];
        for (uint256 i = 0; i < accounts.length; i++) {
            if(accounts[i] == account) return needSyncs[layer2].length;
        }
        needSyncs[layer2].push(account);

        emit AddSync(layer2, account);
        return needSyncs[layer2].length;
    }

    function _factorAt(address layer2, uint256 snapshotId) internal view virtual returns (bool, uint256, uint256) {

        FactorSnapshots storage snapshots = factorSnapshots[layer2];

        if (snapshotId > 0 && snapshotId <= getCurrentLayer2SnapshotId(layer2)) {
            uint256 index = snapshots.ids.findIndex(snapshotId);

            if (index == snapshots.ids.length) {
                return (false, 0, 0);
            } else {
                return (true, snapshots.factors[index], snapshots.refactorCounts[index]);
            }
        } else {
            return (false, 0, 0);
        }

    }


    function _getRefactoredCounts(address layer2, address account, uint256 index) internal view
        returns (uint256 refactoredCounts, uint256 remains)
    {
        refactoredCounts = 0;
        remains = 0;
        if (
            account != address(0)
            && accountRefactoredCounts[layer2][account][index] > 0
        ){
            refactoredCounts = accountRefactoredCounts[layer2][account][index];

        } else if (
            account == address(0)
            && totalSupplyRefactoredCounts[layer2][index] > 0
        ){
            refactoredCounts = totalSupplyRefactoredCounts[layer2][index];
        }

        if (
            account != address(0)
            && accountRemains[layer2][account][index] > 0
        ){
            remains = accountRemains[layer2][account][index];

        } else if (
            account != address(0)
            && totalSupplyRemains[layer2][index] > 0
        ){
            remains = totalSupplyRemains[layer2][index];
        }
    }

    function _valueAt(address layer2, uint256 snapshotId, BalanceSnapshots storage snapshots, address account) internal view
        returns (bool, uint256, uint256, uint256)
    {

        if (snapshotId > 0 && snapshotId <= getCurrentLayer2SnapshotId(layer2)) {
            uint256 index = snapshots.ids.findIndex(snapshotId);
            if (index == snapshots.ids.length) {
                // return (false, 0, 0, 0);
                if (index > 0) {
                    (uint256 refactoredCounts, uint256 remains) = _getRefactoredCounts(layer2, account, index-1);
                    return (true, snapshots.balances[index-1], refactoredCounts, remains);
                } else {
                    return (false, 0, 0, 0);
                }
            } else {
                (uint256 refactoredCounts, uint256 remains) = _getRefactoredCounts(layer2, account, index);
                return (true, snapshots.balances[index], refactoredCounts, remains);
            }
        } else {
            return (false, 0, 0, 0);
        }
    }

    function _balanceOfAt(address layer2, address account, uint256 snapshotId) internal view virtual
        returns (bool, uint256, uint256, uint256)
    {

        (bool snapshotted, uint256 balances, uint256 refactoredCounts, uint256 remains) = _valueAt(layer2, snapshotId, accountBalanceSnapshots[layer2][account], account);

        return (snapshotted, balances, refactoredCounts, remains);
        //return snapshotted ? value : balanceOf(account);
    }

    function _totalSupplyAt(address layer2, uint256 snapshotId) internal view virtual
        returns (bool, uint256, uint256, uint256)
    {
        (bool snapshotted, uint256 balances, uint256 refactoredCounts, uint256 remains)  = _valueAt(layer2, snapshotId, totalSupplySnapshots[layer2], address(0));

        return (snapshotted, balances, refactoredCounts, remains);
        //return snapshotted ? value : totalSupply();
    }

    /// @notice You can calculate the balance with the saved snapshot information.
    /// @inheritdoc IAutoCoinageSnapshot2
    function applyFactor(uint256 v, uint256 refactoredCount, uint256 _factor, uint256 refactorCount) public view override returns (uint256)
    {
        if (v == 0) {
            return 0;
        }

        v = rmul2(v, _factor);

        for (uint256 i = refactoredCount; i < refactorCount; i++) {
            v = v * REFACTOR_DIVIDER ;
        }

        return v;
    }

    function _snapshot(address layer2) internal virtual returns (uint256) {
        currentLayer2SnapshotId[layer2]++;
        // blockNumberBySnapshotId[layer2][currentLayer2SnapshotId[layer2]] = block.number;

        uint256 currentId = getCurrentLayer2SnapshotId(layer2);
        emit SnapshotLayer2(layer2, currentId);
        return currentId;

    }

    function _lastSnapshotId(uint256[] storage ids) internal view returns (uint256) {
        if (ids.length == 0) {
            return 0;
        } else {
            return ids[ids.length - 1];
        }
    }

    function _updateBalanceSnapshots(
            address layer2,
            BalanceSnapshots storage snapshots,
            uint256 balances,
            uint256 refactoredCounts,
            uint256 remains,
            address account
    ) internal  {

        uint256 currentId = getCurrentLayer2SnapshotId(layer2);

        uint256 index = _lastSnapshotId(snapshots.ids);

        if (index < currentId) {
            snapshots.ids.push(currentId);
            snapshots.balances.push(balances);

            if(refactoredCounts > 0 && account != address(0)) accountRefactoredCounts[layer2][account][snapshots.ids.length-1] = refactoredCounts;
            else if(refactoredCounts > 0 && account == address(0)) totalSupplyRefactoredCounts[layer2][snapshots.ids.length-1] = refactoredCounts;

            if(remains > 0 && account != address(0)) accountRemains[layer2][account][snapshots.ids.length-1] = remains;
            else if(remains > 0 && account == address(0)) totalSupplyRemains[layer2][snapshots.ids.length-1] = remains;
        }
    }

    function _updateFactorSnapshots(
        address layer2,
        FactorSnapshots storage snapshots,
        uint256 factors,
        uint256 refactorCounts
    ) internal {

        uint256 currentId = getCurrentLayer2SnapshotId(layer2);

        if (_lastSnapshotId(snapshots.ids) < currentId) {
            snapshots.ids.push(currentId);
            snapshots.factors.push(factors);
            snapshots.refactorCounts.push(refactorCounts);
        }
    }

    function updateLayer2Account(address layer2, address account, uint256 balances, uint256 refactoredCounts, uint256 remains) internal {

        _updateBalanceSnapshots(
            layer2,
            accountBalanceSnapshots[layer2][account],
            balances,
            refactoredCounts,
            remains,
            account
            );
    }


    function updateLayer2TotalSupply(address layer2, uint256 balances, uint256 refactoredCounts, uint256 remains) internal {

        _updateBalanceSnapshots(
            layer2,
            totalSupplySnapshots[layer2],
            balances,
            refactoredCounts,
            remains,
            address(0)
            );
    }

    function updateLayer2Factor(address layer2, uint256 factor, uint256 refactorCount) internal {

        _updateFactorSnapshots(
            layer2,
            factorSnapshots[layer2],
            factor,
            refactorCount
        );
    }

    /// @notice Snapshot all layer2 staking information.
    /// @inheritdoc IAutoCoinageSnapshot2
    function snapshot() public override returns (uint256) {
        snashotAggregatorTotal++;

        for (uint256 j = 0; j < layer2s.length;  j++) {
            Layer2Snapshots storage snapshot_ = snashotAggregator[snashotAggregatorTotal];
            address layer2 = layer2s[j];
            if (needSyncs[layer2].length > 0) syncBatch(layer2,  needSyncs[layer2]);

            snapshot_.layer2s.push(layer2);
            snapshot_.snapshotIds.push(getCurrentLayer2SnapshotId(layer2));

            if (needSyncs[layer2].length > 0) delete needSyncs[layer2];
        }

        emit Snapshot(snashotAggregatorTotal);
        return snashotAggregatorTotal;
    }

    /// @notice Snapshot the current staking information of a specific Layer2.
    /// @inheritdoc IAutoCoinageSnapshot2
    function snapshot(address layer2) public override returns (uint256) {
        return _snapshot(layer2);
    }

    /// @notice Synchronize the staking information of specific layer 2.
    /// @inheritdoc IAutoCoinageSnapshot2
    function sync(address layer2) public override returns (uint256){

        address coinage  = SeigManagerI(seigManager).coinages(layer2);
        require(coinage != address(0), "zero coinages");

        AutoRefactorCoinageI.Balance memory totalBalance  = AutoRefactorCoinageI(coinage)._totalSupply();
        uint256 tbalances = totalBalance.balance;
        uint256 trefactoredCounts = totalBalance.refactoredCount;
        uint256 tremains = totalBalance.remain;

        uint256 _factor  = AutoRefactorCoinageI(coinage)._factor();
        uint256 refactorCount  = AutoRefactorCoinageI(coinage).refactorCount();

        if (!existLayer2s[layer2]) {
            existLayer2s[layer2] = true;
            layer2s.push(layer2);
        }

        uint256 snapshotId = _snapshot(layer2);
        updateLayer2TotalSupply(layer2, tbalances, trefactoredCounts, tremains);
        updateLayer2Factor(layer2, _factor, refactorCount);

        emit SyncLayer2(layer2, snapshotId);
        return snapshotId;
    }

    /// @notice Synchronize the staking information of specific layer2's account.
    /// @inheritdoc IAutoCoinageSnapshot2
    function sync(address layer2, address account) public override returns (uint256) {

        address coinage  = SeigManagerI(seigManager).coinages(layer2);
        require(coinage != address(0), "zero coinages");
        require(account != address(0), "zero account");

        AutoRefactorCoinageI.Balance memory accountBalance  = AutoRefactorCoinageI(coinage).balances(account);
        AutoRefactorCoinageI.Balance memory totalBalance  = AutoRefactorCoinageI(coinage)._totalSupply();

        uint256 _factor  = AutoRefactorCoinageI(coinage)._factor();
        uint256 refactorCount  = AutoRefactorCoinageI(coinage).refactorCount();

        uint256 snapshotId = _snapshot(layer2);
        updateLayer2Account(layer2, account, accountBalance.balance, accountBalance.refactoredCount, accountBalance.remain);
        updateLayer2TotalSupply(layer2, totalBalance.balance, totalBalance.refactoredCount, totalBalance.remain);
        updateLayer2Factor(layer2, _factor, refactorCount);

        if (!existLayer2s[layer2]) {
            existLayer2s[layer2] = true;
            layer2s.push(layer2);
        }

        emit SyncLayer2Address(layer2, account, snapshotId);
        return snapshotId;
    }

    /// @inheritdoc IAutoCoinageSnapshot2
    function syncBatch(
        address layer2,
        address[] memory accounts
        )
        public override returns (uint256)
    {
        address coinage  = SeigManagerI(seigManager).coinages(layer2);
        require(coinage != address(0), "zero coinages");
        require(accounts.length > 0, "zero accounts");

        uint256 snapshotId = _snapshot(layer2);

        for (uint256 i = 0; i < accounts.length; i++) {
            AutoRefactorCoinageI.Balance memory accountBalance  = AutoRefactorCoinageI(coinage).balances(accounts[i]);
            updateLayer2Account(layer2, accounts[i], accountBalance.balance, accountBalance.refactoredCount, accountBalance.remain);
        }

        AutoRefactorCoinageI.Balance memory totalBalance  = AutoRefactorCoinageI(coinage)._totalSupply();
        uint256 _factor  = AutoRefactorCoinageI(coinage)._factor();
        uint256 refactorCount  = AutoRefactorCoinageI(coinage).refactorCount();

        updateLayer2TotalSupply(layer2, totalBalance.balance, totalBalance.refactoredCount, totalBalance.remain);
        updateLayer2Factor(layer2, _factor, refactorCount);

        if (!existLayer2s[layer2]) {
            existLayer2s[layer2] = true;
            layer2s.push(layer2);
        }

        emit SyncLayer2Batch(layer2, snapshotId);
        return snapshotId;
    }

    /// @inheritdoc IAutoCoinageSnapshot2
    function syncBactchOffline(
        address layer2,
        address[] memory accounts,
        uint256[] memory balances,
        uint256[] memory refactoredCounts,
        uint256[] memory remains,
        uint256[3] memory layerTotal,
        uint256[2] memory layerFactor
        )
        external onlyRole(ADMIN_ROLE) override returns (bool)
    {
        require(accounts.length == balances.length, "No balances same length");
        require(accounts.length == refactoredCounts.length, "No refactoredCounts same length");
        require(accounts.length == remains.length, "No remains same length");

        if (!existLayer2s[layer2]) {
            existLayer2s[layer2] = true;
            layer2s.push(layer2);
        }

        _snapshot(layer2);

        for (uint256 i = 0; i < accounts.length; i++) {
            updateLayer2Account(
                layer2,
                accounts[i],
                balances[i],
                refactoredCounts[i],
                remains[i]
                );
        }

        updateLayer2TotalSupply(layer2, layerTotal[0], layerTotal[1], layerTotal[2]);
        updateLayer2Factor(layer2, layerFactor[0], layerFactor[1]);

        return true;
    }

    /// @inheritdoc IAutoCoinageSnapshot2
    function layerSnapshotIds(uint256 snashotAggregatorId) public view override returns (address[] memory, uint256[] memory) {
        Layer2Snapshots memory snapshot_ = snashotAggregator[snashotAggregatorId];
        return (snapshot_.layer2s, snapshot_.snapshotIds);
    }

    /// @inheritdoc IAutoCoinageSnapshot2
    function getLayer2TotalSupplyInTokamak(address layer2) public view override
        returns (
                uint256 totalSupplyLayer2,
                uint256 balance,
                uint256 refactoredCount,
                uint256 remain
        )
    {
        address coinage  = SeigManagerI(seigManager).coinages(layer2);
        require(coinage != address(0), "zero coinages");

        totalSupplyLayer2 = AutoRefactorCoinageI(coinage).totalSupply();
        AutoRefactorCoinageI.Balance memory totalBalance  = AutoRefactorCoinageI(coinage)._totalSupply();

        balance = totalBalance.balance;
        refactoredCount = totalBalance.refactoredCount;
        remain = totalBalance.remain;
    }

    /// @inheritdoc IAutoCoinageSnapshot2
    function getLayer2BalanceOfInTokamak(address layer2, address user) public view override
        returns (
                uint256 balanceOfLayer2Amount,
                uint256 balance,
                uint256 refactoredCount,
                uint256 remain
        )
    {
        address coinage  = SeigManagerI(seigManager).coinages(layer2);
        require(coinage != address(0), "zero coinages");

        balanceOfLayer2Amount = AutoRefactorCoinageI(coinage).balanceOf(user);

        AutoRefactorCoinageI.Balance memory totalBalance  = AutoRefactorCoinageI(coinage).balances(user);
        balance = totalBalance.balance;
        refactoredCount = totalBalance.refactoredCount;
        remain = totalBalance.remain;
    }

    /// @inheritdoc IAutoCoinageSnapshot2
    function getBalanceOfInTokamak(address account) public view override
        returns (
                uint256 accountAmount
        )
    {
        uint256 numberOfLayer2s = Layer2RegistryI(layer2Registry).numLayer2s();
        accountAmount = 0;
        for (uint256 i = 0; i < numberOfLayer2s; i++) {
            address layer2 = Layer2RegistryI(layer2Registry).layer2ByIndex(i);
            address coinage  = SeigManagerI(seigManager).coinages(layer2);
            if(coinage != address(0)){
                accountAmount += AutoRefactorCoinageI(coinage).balanceOf(account);
            }
        }
    }

    /// @inheritdoc IAutoCoinageSnapshot2
    function getTotalStakedInTokamak() public view override
        returns (
                uint256 accountAmount
        )
    {
        uint256 numberOfLayer2s = Layer2RegistryI(layer2Registry).numLayer2s();
        accountAmount = 0;
        for (uint256 i = 0; i < numberOfLayer2s; i++) {
            address layer2 = Layer2RegistryI(layer2Registry).layer2ByIndex(i);
            address coinage  = SeigManagerI(seigManager).coinages(layer2);
            if (coinage != address(0)) {
                accountAmount += AutoRefactorCoinageI(coinage).totalSupply();
            }
        }
    }


    function currentAccountBalanceSnapshots(address layer2, address account) public view
        returns (
                bool ,
                uint256,
                uint256,
                uint256,
                uint256 ,
                AutoRefactorCoinageI.Balance memory
        )
    {
        address coinage  = SeigManagerI(seigManager).coinages(layer2);
        require(coinage != address(0), "zero coinages");

        uint256 currentBalanceOf = AutoRefactorCoinageI(coinage).balanceOf(account);
        AutoRefactorCoinageI.Balance memory accountBalance  = AutoRefactorCoinageI(coinage).balances(account);
        BalanceSnapshots storage snapshots = accountBalanceSnapshots[layer2][account];

        address account_ = account;
        address layer2_ = layer2;
        (bool snapshotted, uint256 snapShotBalance, uint256 snapShotRefactoredCount, uint256 snapShotRemain)
            = _valueAt(layer2_, getCurrentLayer2SnapshotId(layer2_), snapshots, account_);

        return (
            snapshotted, snapShotBalance, snapShotRefactoredCount, snapShotRemain,
            currentBalanceOf, accountBalance);
    }


    function currentTotalSupplySnapshots(address layer2) public view
        returns (
                bool ,
                uint256 ,
                uint256 ,
                uint256 ,
                uint256 ,
                AutoRefactorCoinageI.Balance memory
        )
    {
        address coinage  = SeigManagerI(seigManager).coinages(layer2);
        require(coinage != address(0), "zero coinages");

        uint256 currentTotalSupply = AutoRefactorCoinageI(coinage).totalSupply();
        AutoRefactorCoinageI.Balance memory totalBalance  = AutoRefactorCoinageI(coinage)._totalSupply();
        BalanceSnapshots storage snapshots = totalSupplySnapshots[layer2];

        address layer2_ = layer2;
        (bool snapshotted, uint256 snapShotBalance, uint256 snapShotRefactoredCount, uint256 snapShotRemain)
            = _valueAt(layer2_, getCurrentLayer2SnapshotId(layer2_), snapshots, address(0));

        return (snapshotted, snapShotBalance, snapShotRefactoredCount, snapShotRemain, currentTotalSupply, totalBalance);
    }

    /// @inheritdoc IAutoCoinageSnapshot2
    function currentFactorSnapshots(address layer2) public view override
        returns (
                bool snapshotted,
                uint256 snapShotFactor,
                uint256 snapShotRefactorCount,
                uint256 curFactorValue,
                uint256 curFactor,
                uint256 curRefactorCount
        )
    {
        address coinage  = SeigManagerI(seigManager).coinages(layer2);
        require(coinage != address(0), "zero coinages");

        curFactorValue = AutoRefactorCoinageI(coinage).factor();
        curFactor  = AutoRefactorCoinageI(coinage)._factor();
        curRefactorCount  = AutoRefactorCoinageI(coinage).refactorCount();

        uint256 currentId = getCurrentLayer2SnapshotId(layer2);

        (snapshotted, snapShotFactor, snapShotRefactorCount) = _factorAt(layer2, currentId);

    }

    /// @inheritdoc IAutoCoinageSnapshot2
    function getCurrentLayer2SnapshotId(address layer2) public view override returns (uint256) {
        return currentLayer2SnapshotId[layer2];
    }

    /// @inheritdoc IAutoCoinageSnapshot2
    function balanceOf(address account) public view override returns (uint256)
    {
        uint256 numberOfLayer2s = Layer2RegistryI(layer2Registry).numLayer2s();
        uint256 accountAmount = 0;

        for (uint256 i = 0; i < numberOfLayer2s; i++) {
            address layer2 = Layer2RegistryI(layer2Registry).layer2ByIndex(i);
            accountAmount += SeigManagerI(seigManager).stakeOf(layer2, account);
        }
        return accountAmount;
    }

    /// @inheritdoc IAutoCoinageSnapshot2
    function totalSupply() public view override returns (uint256)
    {
        uint256 numberOfLayer2s = Layer2RegistryI(layer2Registry).numLayer2s();
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < numberOfLayer2s; i++) {
            address layer2 = Layer2RegistryI(layer2Registry).layer2ByIndex(i);
            totalAmount += totalSupply(layer2);
        }
        return totalAmount;
    }

    /// @inheritdoc IAutoCoinageSnapshot2
    function balanceOf(address layer2, address account)
        public view override returns (uint256)
    {
        return balanceOfAt(layer2, account, getCurrentLayer2SnapshotId(layer2));
    }

    /// @inheritdoc IAutoCoinageSnapshot2
    function balanceOfAt(address layer2, address account, uint256 snapshotId)
        public view override returns (uint256)
    {
        if (snapshotId > 0) {
            (bool snapshotted1, uint256 balances, uint256 refactoredCounts, uint256 remains) = _balanceOfAt(layer2, account, snapshotId);
            (bool snapshotted2, uint256 factors, uint256 refactorCounts) = _factorAt(layer2, snapshotId);

            if (snapshotted1 && snapshotted2) {
                uint256 bal = applyFactor(balances, refactoredCounts, factors, refactorCounts);
                bal += remains;
                return bal;
            } else {
                return 0;
            }
        } else {
            return 0;
        }
    }

    /// @inheritdoc IAutoCoinageSnapshot2
    function balanceOfAt(address account, uint256 snashotAggregatorId)
        public view override returns (uint256 accountStaked)
    {
        accountStaked = 0;
        if (snashotAggregatorId <= snashotAggregatorTotal) {
            Layer2Snapshots memory snapshots = snashotAggregator[snashotAggregatorId];
            if (snapshots.layer2s.length == 0) return 0;
            for (uint256 i = 0; i< snapshots.layer2s.length; i++) {
                accountStaked += balanceOfAt(snapshots.layer2s[i], account, snapshots.snapshotIds[i]);
            }
        }
    }


    /// @inheritdoc IAutoCoinageSnapshot2
    function stakedAmountWithSnashotAggregator(address account, uint256 snashotAggregatorId)
        public view override returns (uint256 accountStaked, uint256 totalStaked)
    {
        accountStaked = 0;
        totalStaked = 0;
        if (snashotAggregatorId <= snashotAggregatorTotal) {
            Layer2Snapshots memory snapshots = snashotAggregator[snashotAggregatorId];
            if (snapshots.layer2s.length == 0) return (0, 0);
            for (uint256 i = 0; i< snapshots.layer2s.length; i++) {
                accountStaked += balanceOfAt(snapshots.layer2s[i], account, snapshots.snapshotIds[i]);
                totalStaked += totalSupplyAt(snapshots.layer2s[i], snapshots.snapshotIds[i]);
            }
        }
    }

    /// @inheritdoc IAutoCoinageSnapshot2
    function totalSupply(address layer2) public view override returns (uint256)
    {
        return totalSupplyAt(layer2, getCurrentLayer2SnapshotId(layer2));
    }

    /// @inheritdoc IAutoCoinageSnapshot2
    function totalSupplyAt(uint256 snashotAggregatorId) public view override returns (uint256 totalStaked)
    {
        totalStaked = 0;
        if (snashotAggregatorId <= snashotAggregatorTotal) {
            Layer2Snapshots memory snapshots = snashotAggregator[snashotAggregatorId];
            if (snapshots.layer2s.length == 0) return 0;
            for (uint256 i = 0; i < snapshots.layer2s.length; i++) {
                totalStaked += totalSupplyAt(snapshots.layer2s[i], snapshots.snapshotIds[i]);
            }
        }
    }

    /// @inheritdoc IAutoCoinageSnapshot2
    function totalSupplyAt(address layer2, uint256 snapshotId) public view override returns (uint256)
    {
        if (snapshotId > 0) {
            (bool snapshotted1, uint256 balances, uint256 refactoredCounts, uint256 remains) = _totalSupplyAt(layer2, snapshotId);
            (bool snapshotted2, uint256 factors, uint256 refactorCounts) = _factorAt(layer2, snapshotId);

            if (snapshotted1 &&  snapshotted2) {
                uint256 bal = applyFactor(balances, refactoredCounts, factors, refactorCounts);
                bal += remains;
                return bal;
            } else {
                return 0;
            }
        } else {
            address coinage  = SeigManagerI(seigManager).coinages(layer2);
            if (coinage != address(0)) return AutoRefactorCoinageI(coinage).totalSupply();
            return 0;
        }
    }

    /// @inheritdoc IAutoCoinageSnapshot2
    function lastSnapShotIndex(address layer2) public view override returns (uint256)
    {
        if (totalSupplySnapshots[layer2].ids.length == 0) return 0;
        return totalSupplySnapshots[layer2].ids.length-1;
    }

    /// @inheritdoc IAutoCoinageSnapshot2
    function getAccountBalanceSnapsByIds(uint256 id, address layer2, address account) public view override
        returns (uint256, uint256, uint256, uint256)
    {
        BalanceSnapshots memory snapshot_ =  accountBalanceSnapshots[layer2][account];
        uint256 len = snapshot_.ids.length;
        if (id >= len){
            (uint256 refactoredCounts, uint256 remains) = _getRefactoredCounts(layer2, account, len-1);
            return (snapshot_.ids[len-1], snapshot_.balances[len-1], refactoredCounts, remains);
        }
        (uint256 refactoredCounts, uint256 remains) = _getRefactoredCounts(layer2, account, id);
        return (snapshot_.ids[id], snapshot_.balances[id], refactoredCounts, remains);
    }

    /// @inheritdoc IAutoCoinageSnapshot2
    function getAccountBalanceSnapsBySnapshotId(uint256 snapshotId, address layer2, address account) public view override
        returns (uint256, uint256, uint256, uint256)
    {
        BalanceSnapshots storage snapshot_ =  accountBalanceSnapshots[layer2][account];

        if (snapshot_.ids.length == 0) return (0,0,0,0);

        if (snapshotId > 0 && snapshotId <= getCurrentLayer2SnapshotId(layer2)) {
            uint256 id = snapshot_.ids.findIndex(snapshotId);
            (uint256 refactoredCounts, uint256 remains) = _getRefactoredCounts(layer2, account, id);
            return (snapshot_.ids[id], snapshot_.balances[id], refactoredCounts, remains);
        } else {
            return (0,0,0,0);
        }
    }

    function transfer(address recipient, uint256 amount) public virtual returns (bool) {
        return false;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual  returns (bool) {
        return false;
    }

    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Arrays.sol";

contract AutoCoinageSnapshotStorage2 is AccessControl {
    using Arrays for uint256[];
    using Counters for Counters.Counter;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    struct Layer2Snapshots {
        address[] layer2s;
        uint256[] snapshotIds;
    }

    // struct BalanceSnapshots {
    //     uint256[] ids;
    //     uint256[] balances;
    //     uint256[] refactoredCounts;
    //     uint256[] remains;
    // }

    struct BalanceSnapshots {
        uint256[] ids;
        uint256[] balances;
    }

    struct FactorSnapshots {
        uint256[] ids;
        uint256[] factors;
        uint256[] refactorCounts;
    }

    uint256 public REFACTOR_BOUNDARY = 10 ** 28;
    uint256 public REFACTOR_DIVIDER = 2;

    address public seigManager ;
    address public layer2Registry ;

    // layer2- account - balance
    mapping(address => mapping(address => BalanceSnapshots)) internal accountBalanceSnapshots;
    // layer2- account - snapahot - RefactoredCounts
    mapping(address => mapping(address => mapping(uint256 => uint256))) internal accountRefactoredCounts;
    // layer2- account - snapahot - Remains
    mapping(address => mapping(address => mapping(uint256 => uint256))) internal accountRemains;

    // layer2- totalSupply
    mapping(address => BalanceSnapshots) internal totalSupplySnapshots;
    // layer2- totalSupply - snapahot - RefactoredCounts
    mapping(address => mapping(uint256 => uint256)) internal totalSupplyRefactoredCounts;
    // layer2- totalSupply - snapahot - Remains
    mapping(address => mapping(uint256 => uint256)) internal totalSupplyRemains;

    //layer2- factor
    mapping(address => FactorSnapshots) internal factorSnapshots;


    // layer2 ->currentLayer2SnapshotId
    mapping(address => uint256)  public currentLayer2SnapshotId;

    //layer2 -> snapshot -> blockNumber
    mapping(address => mapping(uint256 => uint256))  internal blockNumberBySnapshotId;

    //snashotAggregatorId ->
    mapping(uint256 => Layer2Snapshots)  internal snashotAggregator;
    uint256 public snashotAggregatorTotal;

    bool public pauseProxy;
    bool public migratedL2;


    //--- unused
    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) internal _allowances;

    uint256 internal _totalSupply;

    //---
    string public name;
    string public symbol;
    uint256 public decimals;


    //--
    address[] public layer2s;
    mapping(address => bool) public existLayer2s;

    // layer2 - accounts
    mapping(address => address[]) public needSyncs;

}

// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

interface AutoRefactorCoinageI {

  struct Balance {
    uint256 balance;
    uint256 refactoredCount;
    uint256 remain;
  }

  function factor() external view returns (uint256);
  function setFactor(uint256 factor_) external returns (bool);
  function burn(uint256 amount) external;
  function burnFrom(address account, uint256 amount) external;
  function mint(address account, uint256 amount) external returns (bool);
  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function addMinter(address account) external;
  function renounceMinter() external;
  function transferOwnership(address newOwner) external;

  function balances(address account) external view returns (Balance memory);
  function _totalSupply() external view returns (Balance memory);
  function _factor() external view returns (uint256);
  function refactorCount() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

interface SeigManagerI {
  function registry() external view returns (address);
  function depositManager() external view returns (address);
  function ton() external view returns (address);
  function wton() external view returns (address);
  function powerton() external view returns (address);
  function tot() external view returns (address);
  function coinages(address layer2) external view returns (address);
  function commissionRates(address layer2) external view returns (uint256);

  function lastCommitBlock(address layer2) external view returns (uint256);
  function seigPerBlock() external view returns (uint256);
  function lastSeigBlock() external view returns (uint256);
  function pausedBlock() external view returns (uint256);
  function unpausedBlock() external view returns (uint256);
  function DEFAULT_FACTOR() external view returns (uint256);

  function deployCoinage(address layer2) external returns (bool);
  function setCommissionRate(address layer2, uint256 commission, bool isCommissionRateNegative) external returns (bool);

  function uncomittedStakeOf(address layer2, address account) external view returns (uint256);
  function stakeOf(address layer2, address account) external view returns (uint256);
  function additionalTotBurnAmount(address layer2, address account, uint256 amount) external view returns (uint256 totAmount);

  function onTransfer(address sender, address recipient, uint256 amount) external returns (bool);
  function updateSeigniorage() external returns (bool);
  function onDeposit(address layer2, address account, uint256 amount) external returns (bool);
  function onWithdraw(address layer2, address account, uint256 amount) external returns (bool);

}

// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;


interface Layer2RegistryI {
  function layer2s(address layer2) external view returns (bool);

  function register(address layer2) external returns (bool);
  function numLayer2s() external view returns (uint256);
  function layer2ByIndex(uint256 index) external view returns (address);

  function deployCoinage(address layer2, address seigManager) external returns (bool);
  function registerAndDeployCoinage(address layer2, address seigManager) external returns (bool);
  function unregister(address layer2) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAutoCoinageSnapshot2 {

    /// @notice This event is emitted when taking a snapshot. You can check the snashotAggregatorId.
    /// @param snashotAggregatorId snashotAggregatorId, By using snashotAggregatorId, you can query the balance and total amount for a specific snashotAggregatorId.
    event Snapshot(uint256 snashotAggregatorId);

    /// @notice This event is emitted when taking a snapshot of a specific layer2,
    ///         You can check the snapshot ID of a specific layer2.
    /// @param layer2 a layer2 address
    /// @param id  a layer2's snapshotId
    event SnapshotLayer2(address indexed layer2, uint256 id);

    /// @notice This event is emitted when a specific layer2's staking information is synchronized and a snapshot is taken.
    /// @param layer2 a layer2 address
    /// @param id  a layer2's snapshotId
    event SyncLayer2(address indexed layer2, uint256 id);

    /// @notice This event is emitted when a specific layer2's and account's  staking information is synchronized and a snapshot is taken.
    /// @param layer2 a layer2 address
    /// @param account an account address
    /// @param id  a layer2's snapshotId
    event SyncLayer2Address(address indexed layer2, address account, uint256 id);

    /// @notice This event is emitted when synchronizes multiple accounts of a specific layer2, takes a snapshot.
    /// @param layer2 a layer2 address
    /// @param id  a layer2's snapshotId
    event SyncLayer2Batch(address indexed layer2, uint256 id);

    /// @notice This event is emitted when the PowerTONSwapper calls during staking and unstaking,
    ///         and you can know the Layer2 and account information that are saved for later syncs.
    /// @param layer2 a layer2 address
    /// @param account  an account
    event AddSync(address indexed layer2, address indexed account);


    /// @notice Set the segManager and layer2Registry address. onlyRole(ADMIN_ROLE) can call it.
    /// @param _seigManager a segManager address
    /// @param _layer2Registry  a layer2Registry address
    function setAddress(address _seigManager, address _layer2Registry) external;

    /// @notice To support the basic interface of ERC20, set name, symbol, decimals.
    /// @param name_ name
    /// @param symbol_  symbol
    /// @param decimals_  decimals
    function setNameSymbolDecimals(string memory name_, string memory symbol_, uint256 decimals_) external;

    /// @notice Managed Layer 2 addresses can be added by the administrator.
    /// @param _layers  layer2's addresses
    function addLayer2s(address[] memory _layers) external;

    /// @notice Managed Layer2 address can be deleted by the administrator.
    /// @param _layer  layer2's address
    function delLayer2(address _layer) external;

    /// @notice This functions is called when the PowerTONSwapper calls during staking and unstaking,
    ///         and  Layer2 and account information are saved for later syncs. onlyRole(ADMIN_ROLE) can call it.
    /// @param layer2 a layer2 address
    /// @param account  an account
    /// @return uint256  account's length in needSyncs's layer2
    function addSync(address layer2, address account) external returns (uint256);


    /// @notice This function is used to execute batch synchronization for the first time after contract deployment.
    ///          onlyRole(ADMIN_ROLE) can call it.
    /// @param layer2  layer2's addresses
    /// @param accounts  accounts's addresses
    /// @param balances  balances of AutoRefactorCoinageI(coinage).balances(account);
    /// @param refactoredCounts  refactoredCounts of AutoRefactorCoinageI(coinage).balances(account);
    /// @param remains  remains of AutoRefactorCoinageI(coinage).balances(account);
    /// @param layerTotal  _totalSupply of AutoRefactorCoinage(coinage)
    /// @param layerFactor  _factor, refactorCount of AutoRefactorCoinage(coinage)
    /// @return bool  true
    function syncBactchOffline(
        address layer2,
        address[] memory accounts,
        uint256[] memory balances,
        uint256[] memory refactoredCounts,
        uint256[] memory remains,
        uint256[3] memory layerTotal,
        uint256[2] memory layerFactor
        )
        external returns (bool) ;


    /// @notice You can calculate the balance with the saved snapshot information.
    /// @param v  balances of AutoRefactorCoinageI(coinage).balances(account);
    /// @param refactoredCount  refactoredCounts of AutoRefactorCoinageI(coinage).balances(account);
    /// @param _factor  _factor of AutoRefactorCoinage(coinage)
    /// @param refactorCount  refactorCount of AutoRefactorCoinage(coinage)
    /// @return balance  balance
    function applyFactor(uint256 v, uint256 refactoredCount, uint256 _factor, uint256 refactorCount) external view returns (uint256);

    /// @notice Snapshot all layer2 staking information.
    /// @return snashotAggregatorId
    function snapshot() external returns (uint256);

    /// @notice Snapshot the current staking information of a specific Layer2.
    /// @param layer2  layer2's address
    /// @return snashotId of layer2
    function snapshot(address layer2) external returns (uint256) ;

    /// @notice Synchronize the staking information of specific layer 2.
    /// @param layer2  layer2's address
    /// @return snashotId of layer2
    function sync(address layer2) external returns (uint256);

    /// @notice Synchronize the staking information of specific layer2's account.
    /// @param layer2  layer2's address
    /// @param account  account's address
    /// @return snashotId of layer2
    function sync(address layer2, address account) external returns (uint256);

    /// @notice Synchronize the staking information of specific layer2's accounts.
    /// @param layer2  layer2's address
    /// @param accounts  accounts's address
    function syncBatch(address layer2,  address[] memory accounts) external returns (uint256);


    /// @notice return snapshot ids for all layer2.
    /// @param snashotAggregatorId  a snashotAggregatorId
    /// @return layer2's addresses
    /// @return layer2's snashotIds
    function layerSnapshotIds(uint256 snashotAggregatorId) external view returns (address[] memory, uint256[] memory) ;


    /// @notice Total amount staked in Layer2 of Tokamak
    /// @param layer2  a layer2 address
    /// @return totalSupplyLayer2 totalSupply of layer2
    /// @return balance a balance of layer2.balances
    /// @return refactoredCount a refactoredCount of layer2.balances
    /// @return remain a remain of layer2.balances
    function getLayer2TotalSupplyInTokamak(address layer2) external view
        returns (
                uint256 totalSupplyLayer2,
                uint256 balance,
                uint256 refactoredCount,
                uint256 remain
        );

    /// @notice balance amount staked in Layer2's account of Tokamak
    /// @param layer2  a layer2 address
    /// @param user  account
    /// @return balanceOfLayer2Amount balanceOf of layer2's account
    /// @return balance a balance of layer2's account.balances
    /// @return refactoredCount a refactoredCount of layer2's account.balances
    /// @return remain a remain of layer2's account.balances
    function getLayer2BalanceOfInTokamak(address layer2, address user) external view
        returns (
                uint256 balanceOfLayer2Amount,
                uint256 balance,
                uint256 refactoredCount,
                uint256 remain
        );

    /// @notice balance amount staked in account of Tokamak
    /// @param account  account
    /// @return accountAmount  user's staked balance
    function getBalanceOfInTokamak(address account) external view
        returns (
                uint256 accountAmount
        );

    /// @notice total amount staked in Tokamak
    /// @return amount  total amount staked
    function getTotalStakedInTokamak() external view
        returns (
                uint256 amount
        );

    /*
    /// @notice Returns information staked in the current tokamak of layer2 and information stored in the current snapshot.
    /// @param layer2 a layer2 address
    /// @param account account
    /// @return snapshotted Whether a snapshot was taken
    /// @return snapShotBalance Balance in Snapshot
    /// @return snapShotRefactoredCount RefactoredCounts in Snapshot
    /// @return snapShotRemain Remain in Snapshot
    /// @return currentBalanceOf a current balanceOf in tokamak
    /// @return AutoRefactorCoinageI.Balance balances of layer's account in tokamak
    function currentAccountBalanceSnapshots(address layer2, address account) external view
        returns (
                bool snapshotted,
                uint256 snapShotBalance,
                uint256 snapShotRefactoredCount,
                uint256 snapShotRemain,
                uint256 currentBalanceOf,
                AutoRefactorCoinageI.Balance balances
        );


    /// @notice information staked in the current tokamak of layer2 and information stored in the current snapshot.
    /// @param layer2 a layer2 address
    /// @return snapshotted Whether a snapshot was taken
    /// @return snapShotBalance Balance in Snapshot
    /// @return snapShotRefactoredCount RefactoredCounts in Snapshot
    /// @return snapShotRemain Remain in Snapshot
    /// @return currentTotalSupply a current total staked amount in tokamak
    /// @return AutoRefactorCoinageI.Balance _totalSupply() of layer2 in tokamak
    function currentTotalSupplySnapshots(address layer2) external view
        returns (
                bool snapshotted,
                uint256 snapShotBalance,
                uint256 snapShotRefactoredCount,
                uint256 snapShotRemain,
                uint256 currentTotalSupply,
                AutoRefactorCoinageI.Balance _total
        );
    */

    /// @notice Returns factor in the current tokamak of layer2 and factor stored in the current snapshot.
    /// @param layer2 a layer2 address
    /// @return snapshotted Whether a snapshot was taken
    /// @return snapShotFactor factor in Snapshot
    /// @return snapShotRefactorCount RefactorCount in Snapshot
    /// @return curFactorValue a current FactorValue in tokamak
    /// @return curFactor a current Factor in tokamak
    /// @return curRefactorCount a current RefactorCount in tokamak
    function currentFactorSnapshots(address layer2) external view
        returns (
                bool snapshotted,
                uint256 snapShotFactor,
                uint256 snapShotRefactorCount,
                uint256 curFactorValue,
                uint256 curFactor,
                uint256 curRefactorCount
        );

    /// @notice Current snapshotId of the layer2
    /// @param layer2 a layer2 address
    /// @return Layer2SnapshotId Layer2's SnapshotId
    function getCurrentLayer2SnapshotId(address layer2) external view returns (uint256) ;

    /// @notice account's balance staked amount
    /// @param account a account address
    /// @return amount account's balance staked amount
    function balanceOf(address account) external view returns (uint256);

    /// @notice total staked amount in tokamak
    /// @return total staked amount
    function totalSupply() external view returns (uint256);


    /// @notice account's balance staked amount in current snapshot
    /// @param layer2 a layer2 address
    /// @param account a account address
    /// @return amount account's balance staked amount
    function balanceOf(address layer2, address account) external view returns (uint256);

    /// @notice account's balance staked amount in snashotAggregatorId
    /// @param account a account address
    /// @param snashotAggregatorId a snashotAggregatorId
    /// @return amount account's balance staked amount
    function balanceOfAt(address account, uint256 snashotAggregatorId) external view returns (uint256);

    /// @notice account's balance staked amount in snapshotId
    /// @param layer2 a layer2 address
    /// @param account a account address
    /// @param snapshotId a snapshotId
    /// @return amount account's balance staked amount
    function balanceOfAt(address layer2, address account, uint256 snapshotId) external view returns (uint256);

    /// @notice layer2's staked amount in current snapshot
    /// @param layer2 a layer2 address
    /// @return amount layer2's staked amount
    function totalSupply(address layer2) external view returns (uint256);

    /// @notice total staked amount in snashotAggregatorId
    /// @param snashotAggregatorId  snashotAggregatorId
    /// @return totalStaked total staked amount
    function totalSupplyAt(uint256 snashotAggregatorId) external view returns (uint256 totalStaked);

    /// @notice layer2's staked amount in snapshotId
    /// @param layer2 a layer2 address
    /// @param snapshotId a snapshotId
    /// @return layer2's staked amount
    function totalSupplyAt(address layer2, uint256 snapshotId) external view returns (uint256);

    /// @notice account's staked amount in snashotAggregatorId
    /// @param account a account address
    /// @return accountStaked  account's staked amount
    /// @return totalStaked   total staked amount
    function stakedAmountWithSnashotAggregator(address account, uint256 snashotAggregatorId) external view
        returns (uint256 accountStaked, uint256 totalStaked);

    /// @notice last SnapShotIndex
    /// @param layer2 a layer2 address
    /// @return SnapShotIndex  SnapShotIndex
    function lastSnapShotIndex(address layer2) external view returns (uint256);

    /// @notice snapshot's information by snapshotIndex
    /// @param id  id
    /// @param layer2 a layer2 address
    /// @param account a account address
    /// @return ids  snapshot's id
    /// @return balances  snapshot's balance
    /// @return refactoredCounts  snapshot's refactoredCount
    /// @return remains  snapshot's remain
    function getAccountBalanceSnapsByIds(uint256 id, address layer2, address account) external view
        returns (uint256, uint256, uint256, uint256);

    /// @notice snapshot's information by snapshotId
    /// @param snapshotId  snapshotId
    /// @param layer2 a layer2 address
    /// @param account a account address
    /// @return ids  snapshot's id
    /// @return balances  snapshot's balance
    /// @return refactoredCounts  snapshot's refactoredCount
    /// @return remains  snapshot's remain
    function getAccountBalanceSnapsBySnapshotId(uint256 snapshotId, address layer2, address account) external view
        returns (uint256, uint256, uint256, uint256);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Arrays.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "hardhat/console.sol";
/**
 * @dev Collection of functions related to array types.
 */
library SArrays {
    /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }




        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
        }
    }

    function findIndex(uint256[] storage array, uint256 element
    ) internal view returns (uint256) {
        if (array.length == 0) return 0;
       // console.log('findIndex %s %s %s',array.length, array[0], element);

        // Shortcut for the actual value
        if (element >= array[array.length-1])
            return (array.length-1);
        if (element < array[0]) return 0;

        // Binary search of the value in the array
        uint min = 0;
        uint max = array.length-1;
        while (max > min) {
            uint mid = (max + min + 1)/ 2;
            //console.log('findIndex mid %s %s',mid, array[mid]);

            if (array[mid] <= element) {
                min = mid;
            } else {
                max = mid-1;
            }
        }
        //console.log('findIndex return min %s %s',min, array[min]);
        return min;
    }



}

// SPDX-License-Identifier: MIT
pragma solidity >0.4.13;

contract DSMath {
  function add(uint x, uint y) internal pure returns (uint z) {
    require((z = x + y) >= x, "ds-math-add-overflow");
  }
  function sub(uint x, uint y) internal pure returns (uint z) {
    require((z = x - y) <= x, "ds-math-sub-underflow");
  }
  function mul(uint x, uint y) internal pure returns (uint z) {
    require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
  }

  function min(uint x, uint y) internal pure returns (uint z) {
    return x <= y ? x : y;
  }
  function max(uint x, uint y) internal pure returns (uint z) {
    return x >= y ? x : y;
  }
  function imin(int x, int y) internal pure returns (int z) {
    return x <= y ? x : y;
  }
  function imax(int x, int y) internal pure returns (int z) {
    return x >= y ? x : y;
  }

  uint constant WAD = 10 ** 18;
  uint constant RAY = 10 ** 27;

  function wmul(uint x, uint y) internal pure returns (uint z) {
    z = add(mul(x, y), WAD / 2) / WAD;
  }
  function rmul(uint x, uint y) internal pure returns (uint z) {
    z = add(mul(x, y), RAY / 2) / RAY;
  }
  function wdiv(uint x, uint y) internal pure returns (uint z) {
    z = add(mul(x, WAD), y / 2) / y;
  }
  function rdiv(uint x, uint y) internal pure returns (uint z) {
    z = add(mul(x, RAY), y / 2) / y;
  }

  function wmul2(uint x, uint y) internal pure returns (uint z) {
    z = mul(x, y) / WAD;
  }
  function rmul2(uint x, uint y) internal pure returns (uint z) {
    z = mul(x, y) / RAY;
  }
  function wdiv2(uint x, uint y) internal pure returns (uint z) {
    z = mul(x, WAD) / y;
  }
  function rdiv2(uint x, uint y) internal pure returns (uint z) {
    z = mul(x, RAY) / y;
  }

  // This famous algorithm is called "exponentiation by squaring"
  // and calculates x^n with x as fixed-point and n as regular unsigned.
  //
  // It's O(log n), instead of O(n) for naive repeated multiplication.
  //
  // These facts are why it works:
  //
  //  If n is even, then x^n = (x^2)^(n/2).
  //  If n is odd,  then x^n = x * x^(n-1),
  //   and applying the equation for even x gives
  //  x^n = x * (x^2)^((n-1) / 2).
  //
  //  Also, EVM division is flooring and
  //  floor[(n-1) / 2] = floor[n / 2].
  //
  function wpow(uint x, uint n) internal pure returns (uint z) {
    z = n % 2 != 0 ? x : WAD;

    for (n /= 2; n != 0; n /= 2) {
      x = wmul(x, x);

      if (n % 2 != 0) {
        z = wmul(z, x);
      }
    }
  }

  function rpow(uint x, uint n) internal pure returns (uint z) {
    z = n % 2 != 0 ? x : RAY;

    for (n /= 2; n != 0; n /= 2) {
      x = rmul(x, x);

      if (n % 2 != 0) {
        z = rmul(z, x);
      }
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Arrays.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
    /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}