// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;


import "./ILyfeblocStorage.sol";
import "./Utils.sol";
import "./PermissionGroupsNoModifiers.sol";
import "./ILyfeblocHistory.sol";
import "./ILyfeblocNetwork.sol";


/**
 *   @title lyfeblocStorage contract
 *   The contract provides the following functions for lyfeblocNetwork contract:
 *   - Stores reserve and token listing information by the lyfeblocNetwork
 *   - Stores feeAccounted data for reserve types
 *   - Record contract changes for reserves and lyfeblocProxies
 *   - Points to historical contracts that record contract changes for lyfeblocNetwork,
 *        lyfeblocFeeHandler, lyfeblocDao and lyfeblocMatchingEngine
 */
contract LyfeblocStorage is ILyfeblocStorage, PermissionGroupsNoModifiers, Utils {
    // store current and previous contracts
    ILyfeblocHistory public lyfeblocNetworkHistory;
    ILyfeblocHistory public lyfeblocFeeHandlerHistory;
    ILyfeblocHistory public lyfeblocDaoHistory;
    ILyfeblocHistory public lyfeblocMatchingEngineHistory;

    ILyfeblocReserve[] internal reserves;
    ILyfeblocNetworkProxy[] internal lyfeblocProxyArray;

    mapping(bytes32 => address[]) internal reserveIdToAddresses;
    mapping(bytes32 => address) internal reserveRebateWallet;
    mapping(address => bytes32) internal reserveAddressToId;
    mapping(IERC20 => bytes32[]) internal reservesPerTokenSrc; // reserves supporting token to eth
    mapping(IERC20 => bytes32[]) internal reservesPerTokenDest; // reserves support eth to token
    mapping(bytes32 => IERC20[]) internal srcTokensPerReserve;
    mapping(bytes32 => IERC20[]) internal destTokensPerReserve;

    mapping(IERC20 => mapping(bytes32 => bool)) internal isListedReserveWithTokenSrc;
    mapping(IERC20 => mapping(bytes32 => bool)) internal isListedReserveWithTokenDest;

    uint256 internal feeAccountedPerType = 0xffffffff;
    uint256 internal entitledRebatePerType = 0xffffffff;
    mapping(bytes32 => uint256) internal reserveType; // type from enum ReserveType
    mapping(ReserveType => bytes32[]) internal reservesPerType;

    ILyfeblocNetwork public lyfeblocNetwork;

    constructor(
        address _admin,
        ILyfeblocHistory _lyfeblocNetworkHistory,
        ILyfeblocHistory _lyfeblocFeeHandlerHistory,
        ILyfeblocHistory _lyfeblocDaoHistory,
        ILyfeblocHistory _lyfeblocMatchingEngineHistory
    ) public PermissionGroupsNoModifiers(_admin) {
        require(_lyfeblocNetworkHistory != ILyfeblocHistory(0), "lyfeblocNetworkHistory 0");
        require(_lyfeblocFeeHandlerHistory != ILyfeblocHistory(0), "lyfeblocFeeHandlerHistory 0");
        require(_lyfeblocDaoHistory != ILyfeblocHistory(0), "lyfeblocDaoHistory 0");
        require(_lyfeblocMatchingEngineHistory != ILyfeblocHistory(0), "lyfeblocMatchingEngineHistory 0");

        lyfeblocNetworkHistory = _lyfeblocNetworkHistory;
        lyfeblocFeeHandlerHistory = _lyfeblocFeeHandlerHistory;
        lyfeblocDaoHistory = _lyfeblocDaoHistory;
        lyfeblocMatchingEngineHistory = _lyfeblocMatchingEngineHistory;
    }

    event LyfeblocNetworkUpdated(ILyfeblocNetwork newLyfeblocNetwork);
    event RemoveReserveFromStorage(address indexed reserve, bytes32 indexed reserveId);

    event AddReserveToStorage(
        address indexed reserve,
        bytes32 indexed reserveId,
        ILyfeblocStorage.ReserveType reserveType,
        address indexed rebateWallet
    );

    event ReserveRebateWalletSet(
        bytes32 indexed reserveId,
        address indexed rebateWallet
    );

    event ListReservePairs(
        bytes32 indexed reserveId,
        address reserve,
        IERC20 indexed src,
        IERC20 indexed dest,
        bool add
    );

    function setNetworkContract(ILyfeblocNetwork _lyfeblocNetwork) external {
        onlyAdmin();
        require(_lyfeblocNetwork != ILyfeblocNetwork(0), "lyfeblocNetwork 0");
        emit LyfeblocNetworkUpdated(_lyfeblocNetwork);
        lyfeblocNetworkHistory.saveContract(address(_lyfeblocNetwork));
        lyfeblocNetwork = _lyfeblocNetwork;
    }

    function setRebateWallet(bytes32 reserveId, address rebateWallet) external {
        onlyOperator();
        require(rebateWallet != address(0), "rebate wallet is 0");
        require(reserveId != bytes32(0), "reserveId = 0");
        require(reserveIdToAddresses[reserveId].length > 0, "reserveId not found");
        require(reserveIdToAddresses[reserveId][0] != address(0), "no reserve associated");

        reserveRebateWallet[reserveId] = rebateWallet;
        emit ReserveRebateWalletSet(reserveId, rebateWallet);
    }

    function setContracts(address _lyfeblocFeeHandler, address _lyfeblocMatchingEngine)
        external
        override
    {
        onlyNetwork();
        require(_lyfeblocFeeHandler != address(0), "lyfeblocFeeHandler 0");
        require(_lyfeblocMatchingEngine != address(0), "lyfeblocMatchingEngine 0");

        lyfeblocFeeHandlerHistory.saveContract(_lyfeblocFeeHandler);
        lyfeblocMatchingEngineHistory.saveContract(_lyfeblocMatchingEngine);
    }

    function setLyfeblocDaoContract(address _lyfeblocDao) external override {
        onlyNetwork();

        lyfeblocDaoHistory.saveContract(_lyfeblocDao);
    }

    /// @notice Can be called only by operator
    /// @dev Adds a reserve to the storage
    /// @param reserve The reserve address
    /// @param reserveId The reserve ID in 32 bytes.
    /// @param resType Type of the reserve out of enum ReserveType
    /// @param rebateWallet Rebate wallet address for this reserve
    function addReserve(
        address reserve,
        bytes32 reserveId,
        ReserveType resType,
        address payable rebateWallet
    ) external {
        onlyOperator();
        require(reserveAddressToId[reserve] == bytes32(0), "reserve has id");
        require(reserveId != bytes32(0), "reserveId = 0");
        require(
            (resType != ReserveType.NONE) && (uint256(resType) < uint256(ReserveType.LAST)),
            "bad reserve type"
        );
        require(feeAccountedPerType != 0xffffffff, "fee accounted data not set");
        require(entitledRebatePerType != 0xffffffff, "entitled rebate data not set");
        require(rebateWallet != address(0), "rebate wallet is 0");

        reserveRebateWallet[reserveId] = rebateWallet;

        if (reserveIdToAddresses[reserveId].length == 0) {
            reserveIdToAddresses[reserveId].push(reserve);
        } else {
            require(reserveIdToAddresses[reserveId][0] == address(0), "reserveId taken");
            reserveIdToAddresses[reserveId][0] = reserve;
        }

        reserves.push(ILyfeblocReserve(reserve));
        reservesPerType[resType].push(reserveId);
        reserveAddressToId[reserve] = reserveId;
        reserveType[reserveId] = uint256(resType);

        emit AddReserveToStorage(reserve, reserveId, resType, rebateWallet);
        emit ReserveRebateWalletSet(reserveId, rebateWallet);
    }

    /// @notice Can be called only by operator
    /// @dev Removes a reserve from the storage
    /// @param reserveId The reserve id
    /// @param startIndex Index to start searching from in reserve array
    function removeReserve(bytes32 reserveId, uint256 startIndex)
        external
    {
        onlyOperator();
        require(reserveIdToAddresses[reserveId].length > 0, "reserveId not found");
        address reserve = reserveIdToAddresses[reserveId][0];

        // delist all token pairs for reserve
        delistTokensOfReserve(reserveId);

        uint256 reserveIndex = 2**255;
        for (uint256 i = startIndex; i < reserves.length; i++) {
            if (reserves[i] == ILyfeblocReserve(reserve)) {
                reserveIndex = i;
                break;
            }
        }
        require(reserveIndex != 2**255, "reserve not found");
        reserves[reserveIndex] = reserves[reserves.length - 1];
        reserves.pop();
        // remove reserve from mapping to address
        require(reserveAddressToId[reserve] != bytes32(0), "reserve's existing reserveId is 0");
        reserveId = reserveAddressToId[reserve];

        // update reserve mappings
        reserveIdToAddresses[reserveId].push(reserveIdToAddresses[reserveId][0]);
        reserveIdToAddresses[reserveId][0] = address(0);

        // remove reserveId from reservesPerType
        bytes32[] storage reservesOfType = reservesPerType[ReserveType(reserveType[reserveId])];
        for (uint256 i = 0; i < reservesOfType.length; i++) {
            if (reserveId == reservesOfType[i]) {
                reservesOfType[i] = reservesOfType[reservesOfType.length - 1];
                reservesOfType.pop();
                break;
            }
        }

        delete reserveAddressToId[reserve];
        delete reserveType[reserveId];
        delete reserveRebateWallet[reserveId];

        emit RemoveReserveFromStorage(reserve, reserveId);
    }

    /// @notice Can be called only by operator
    /// @dev Allow or prevent a specific reserve to trade a pair of tokens
    /// @param reserveId The reserve id
    /// @param token Token address
    /// @param ethToToken Will it support ether to token trade
    /// @param tokenToEth Will it support token to ether trade
    /// @param add If true then list this pair, otherwise unlist it
    function listPairForReserve(
        bytes32 reserveId,
        IERC20 token,
        bool ethToToken,
        bool tokenToEth,
        bool add
    ) public {
        onlyOperator();

        require(reserveIdToAddresses[reserveId].length > 0, "reserveId not found");
        address reserve = reserveIdToAddresses[reserveId][0];
        require(reserve != address(0), "reserve = 0");

        if (ethToToken) {
            listPairs(reserveId, token, false, add);
            emit ListReservePairs(reserveId, reserve, ETH_TOKEN_ADDRESS, token, add);
        }

        if (tokenToEth) {
            lyfeblocNetwork.listTokenForReserve(reserve, token, add);
            listPairs(reserveId, token, true, add);
            emit ListReservePairs(reserveId, reserve, token, ETH_TOKEN_ADDRESS, add);
        }
    }

    /// @dev No. of lyfeblocProxies are capped
    function addLyfeblocProxy(address lyfeblocProxy, uint256 maxApprovedProxies)
        external
        override
    {
        onlyNetwork();
        require(lyfeblocProxy != address(0), "lyfeblocProxy 0");
        require(lyfeblocProxyArray.length < maxApprovedProxies, "max lyfeblocProxies limit reached");

        lyfeblocProxyArray.push(ILyfeblocNetworkProxy(lyfeblocProxy));
    }

    function removeLyfeblocProxy(address lyfeblocProxy) external override {
        onlyNetwork();
        uint256 proxyIndex = 2**255;

        for (uint256 i = 0; i < lyfeblocProxyArray.length; i++) {
            if (lyfeblocProxyArray[i] == ILyfeblocNetworkProxy(lyfeblocProxy)) {
                proxyIndex = i;
                break;
            }
        }

        require(proxyIndex != 2**255, "lyfeblocProxy not found");
        lyfeblocProxyArray[proxyIndex] = lyfeblocProxyArray[lyfeblocProxyArray.length - 1];
        lyfeblocProxyArray.pop();
    }

    function setFeeAccountedPerReserveType(
        bool fpr,
        bool apr,
        bool bridge,
        bool utility,
        bool custom,
        bool orderbook
    ) external {
        onlyAdmin();
        uint256 feeAccountedData;

        if (fpr) feeAccountedData |= 1 << uint256(ReserveType.FPR);
        if (apr) feeAccountedData |= 1 << uint256(ReserveType.APR);
        if (bridge) feeAccountedData |= 1 << uint256(ReserveType.BRIDGE);
        if (utility) feeAccountedData |= 1 << uint256(ReserveType.UTILITY);
        if (custom) feeAccountedData |= 1 << uint256(ReserveType.CUSTOM);
        if (orderbook) feeAccountedData |= 1 << uint256(ReserveType.ORDERBOOK);

        feeAccountedPerType = feeAccountedData;
    }

    function setEntitledRebatePerReserveType(
        bool fpr,
        bool apr,
        bool bridge,
        bool utility,
        bool custom,
        bool orderbook
    ) external {
        onlyAdmin();
        require(feeAccountedPerType != 0xffffffff, "fee accounted data not set");
        uint256 entitledRebateData;

        if (fpr) {
            require(feeAccountedPerType & (1 << uint256(ReserveType.FPR)) > 0, "fpr not fee accounted");
            entitledRebateData |= 1 << uint256(ReserveType.FPR);
        }

        if (apr) {
            require(feeAccountedPerType & (1 << uint256(ReserveType.APR)) > 0, "apr not fee accounted");
            entitledRebateData |= 1 << uint256(ReserveType.APR);
        }

        if (bridge) {
            require(feeAccountedPerType & (1 << uint256(ReserveType.BRIDGE)) > 0, "bridge not fee accounted");
            entitledRebateData |= 1 << uint256(ReserveType.BRIDGE);
        }

        if (utility) {
            require(feeAccountedPerType & (1 << uint256(ReserveType.UTILITY)) > 0, "utility not fee accounted");
            entitledRebateData |= 1 << uint256(ReserveType.UTILITY);
        }

        if (custom) {
            require(feeAccountedPerType & (1 << uint256(ReserveType.CUSTOM)) > 0, "custom not fee accounted");
            entitledRebateData |= 1 << uint256(ReserveType.CUSTOM);
        }

        if (orderbook) {
            require(feeAccountedPerType & (1 << uint256(ReserveType.ORDERBOOK)) > 0, "orderbook not fee accounted");
            entitledRebateData |= 1 << uint256(ReserveType.ORDERBOOK);
        }

        entitledRebatePerType = entitledRebateData;
    }

    /// @notice Should be called off chain
    /// @return An array of all reserves
    function getReserves() external view returns (ILyfeblocReserve[] memory) {
        return reserves;
    }

    function getReservesPerType(ReserveType resType) external view returns (bytes32[] memory) {
        return reservesPerType[resType];
    }

    function getReserveId(address reserve) external view override returns (bytes32) {
        return reserveAddressToId[reserve];
    }

    function getReserveIdsFromAddresses(address[] calldata reserveAddresses)
        external
        override
        view
        returns (bytes32[] memory reserveIds)
    {
        reserveIds = new bytes32[](reserveAddresses.length);
        for (uint256 i = 0; i < reserveAddresses.length; i++) {
            reserveIds[i] = reserveAddressToId[reserveAddresses[i]];
        }
    }

    function getReserveAddressesFromIds(bytes32[] calldata reserveIds)
        external
        view
        override
        returns (address[] memory reserveAddresses)
    {
        reserveAddresses = new address[](reserveIds.length);
        for (uint256 i = 0; i < reserveIds.length; i++) {
            reserveAddresses[i] = reserveIdToAddresses[reserveIds[i]][0];
        }
    }

    function getRebateWalletsFromIds(bytes32[] calldata reserveIds)
        external
        view
        override
        returns (address[] memory rebateWallets)
    {
        rebateWallets = new address[](reserveIds.length);
        for (uint256 i = 0; i < rebateWallets.length; i++) {
            rebateWallets[i] = reserveRebateWallet[reserveIds[i]];
        }
    }

    function getReserveIdsPerTokenSrc(IERC20 token)
        external
        view
        override
        returns (bytes32[] memory reserveIds)
    {
        reserveIds = reservesPerTokenSrc[token];
    }

    /// @dev lyfeblocNetwork is calling this function to approve (allowance) for list of reserves for a token
    ///      in case we have a long list of reserves, approving all of them could run out of gas
    ///      using startIndex and endIndex to prevent above scenario
    ///      also enable us to approve reserve one by one
    function getReserveAddressesPerTokenSrc(IERC20 token, uint256 startIndex, uint256 endIndex)
        external
        view
        override
        returns (address[] memory reserveAddresses)
    {
        bytes32[] memory reserveIds = reservesPerTokenSrc[token];
        if (reserveIds.length == 0) {
            return reserveAddresses;
        }
        uint256 endId = (endIndex >= reserveIds.length) ? (reserveIds.length - 1) : endIndex;
        if (endId < startIndex) {
            return reserveAddresses;
        }
        reserveAddresses = new address[](endId - startIndex + 1);
        for(uint256 i = startIndex; i <= endId; i++) {
            reserveAddresses[i - startIndex] = reserveIdToAddresses[reserveIds[i]][0];
        }
    }

    function getReserveIdsPerTokenDest(IERC20 token)
        external
        view
        override
        returns (bytes32[] memory reserveIds)
    {
        reserveIds = reservesPerTokenDest[token];
    }

    function getReserveAddressesByReserveId(bytes32 reserveId)
        external
        view
        override
        returns (address[] memory reserveAddresses)
    {
        reserveAddresses = reserveIdToAddresses[reserveId];
    }

    /// @notice Should be called off chain
    /// @dev Returns list of lyfeblocDao, lyfeblocFeeHandler, lyfeblocMatchingEngine and lyfeblocNetwork contracts
    /// @dev Index 0 is currently used contract address, indexes > 0 are older versions
    function getContracts()
        external
        view
        returns (
            address[] memory lyfeblocDaoAddresses,
            address[] memory lyfeblocFeeHandlerAddresses,
            address[] memory lyfeblocMatchingEngineAddresses,
            address[] memory lyfeblocNetworkAddresses
        )
    {
        lyfeblocDaoAddresses = lyfeblocDaoHistory.getContracts();
        lyfeblocFeeHandlerAddresses = lyfeblocFeeHandlerHistory.getContracts();
        lyfeblocMatchingEngineAddresses = lyfeblocMatchingEngineHistory.getContracts();
        lyfeblocNetworkAddresses = lyfeblocNetworkHistory.getContracts();
    }

    /// @notice Should be called off chain
    /// @return An array of LyfeblocNetworkProxies
    function getLyfeblocProxies() external view override returns (ILyfeblocNetworkProxy[] memory) {
        return lyfeblocProxyArray;
    }

    function isLyfeblocProxyAdded() external view override returns (bool) {
        return (lyfeblocProxyArray.length > 0);
    }

    /// @notice Returns information about a reserve given its reserve ID
    /// @return reserveAddress Address of the reserve
    /// @return rebateWallet address of rebate wallet of this reserve
    /// @return resType Reserve type from enum ReserveType
    /// @return isFeeAccountedFlag Whether fees are to be charged for the trade for this reserve
    /// @return isEntitledRebateFlag Whether reserve is entitled rebate from the trade fees
    function getReserveDetailsById(bytes32 reserveId)
        external
        view
        override
        returns (
            address reserveAddress,
            address rebateWallet,
            ReserveType resType,
            bool isFeeAccountedFlag,
            bool isEntitledRebateFlag
        )
    {
        address[] memory reserveAddresses = reserveIdToAddresses[reserveId];

        if (reserveAddresses.length != 0) {
            reserveAddress = reserveIdToAddresses[reserveId][0];
            rebateWallet = reserveRebateWallet[reserveId];
            uint256 resTypeUint = reserveType[reserveId];
            resType = ReserveType(resTypeUint);
            isFeeAccountedFlag = (feeAccountedPerType & (1 << resTypeUint)) > 0;
            isEntitledRebateFlag = (entitledRebatePerType & (1 << resTypeUint)) > 0;
        }
    }

    /// @notice Returns information about a reserve given its reserve ID
    /// @return reserveId The reserve ID in 32 bytes.
    /// @return rebateWallet address of rebate wallet of this reserve
    /// @return resType Reserve type from enum ReserveType
    /// @return isFeeAccountedFlag Whether fees are to be charged for the trade for this reserve
    /// @return isEntitledRebateFlag Whether reserve is entitled rebate from the trade fees
    function getReserveDetailsByAddress(address reserve)
        external
        view
        override
        returns (
            bytes32 reserveId,
            address rebateWallet,
            ReserveType resType,
            bool isFeeAccountedFlag,
            bool isEntitledRebateFlag
        )
    {
        reserveId = reserveAddressToId[reserve];
        rebateWallet = reserveRebateWallet[reserveId];
        uint256 resTypeUint = reserveType[reserveId];
        resType = ReserveType(resTypeUint);
        isFeeAccountedFlag = (feeAccountedPerType & (1 << resTypeUint)) > 0;
        isEntitledRebateFlag = (entitledRebatePerType & (1 << resTypeUint)) > 0;
    }

    function getListedTokensByReserveId(bytes32 reserveId)
        external
        view
        returns (
            IERC20[] memory srcTokens,
            IERC20[] memory destTokens
        )
    {
        srcTokens = srcTokensPerReserve[reserveId];
        destTokens = destTokensPerReserve[reserveId];
    }

    function getFeeAccountedData(bytes32[] calldata reserveIds)
        external
        view
        override
        returns (bool[] memory feeAccountedArr)
    {
        feeAccountedArr = new bool[](reserveIds.length);

        uint256 feeAccountedData = feeAccountedPerType;

        for (uint256 i = 0; i < reserveIds.length; i++) {
            feeAccountedArr[i] = (feeAccountedData & (1 << reserveType[reserveIds[i]]) > 0);
        }
    }

    function getEntitledRebateData(bytes32[] calldata reserveIds)
        external
        view
        override
        returns (bool[] memory entitledRebateArr)
    {
        entitledRebateArr = new bool[](reserveIds.length);

        uint256 entitledRebateData = entitledRebatePerType;

        for (uint256 i = 0; i < reserveIds.length; i++) {
            entitledRebateArr[i] = (entitledRebateData & (1 << reserveType[reserveIds[i]]) > 0);
        }
    }

    /// @dev Returns information about reserves given their reserve IDs
    ///      Also check if these reserve IDs are listed for token
    ///      Network calls this function to retrive information about fee, address and rebate information
    function getReservesData(bytes32[] calldata reserveIds, IERC20 src, IERC20 dest)
        external
        view
        override
        returns (
            bool areAllReservesListed,
            bool[] memory feeAccountedArr,
            bool[] memory entitledRebateArr,
            ILyfeblocReserve[] memory reserveAddresses)
    {
        feeAccountedArr = new bool[](reserveIds.length);
        entitledRebateArr = new bool[](reserveIds.length);
        reserveAddresses = new ILyfeblocReserve[](reserveIds.length);
        areAllReservesListed = true;

        uint256 entitledRebateData = entitledRebatePerType;
        uint256 feeAccountedData = feeAccountedPerType;

        mapping(bytes32 => bool) storage isListedReserveWithToken = (dest == ETH_TOKEN_ADDRESS) ?
            isListedReserveWithTokenSrc[src]:
            isListedReserveWithTokenDest[dest];

        for (uint256 i = 0; i < reserveIds.length; i++) {
            uint256 resType = reserveType[reserveIds[i]];
            entitledRebateArr[i] = (entitledRebateData & (1 << resType) > 0);
            feeAccountedArr[i] = (feeAccountedData & (1 << resType) > 0);
            reserveAddresses[i] = ILyfeblocReserve(reserveIdToAddresses[reserveIds[i]][0]);

            if (!isListedReserveWithToken[reserveIds[i]]){
                areAllReservesListed = false;
                break;
            }
        }
    }

    function delistTokensOfReserve(bytes32 reserveId) internal {
        // token to ether
        // memory declaration instead of storage because we are modifying the storage array
        IERC20[] memory tokensArr = srcTokensPerReserve[reserveId];
        for (uint256 i = 0; i < tokensArr.length; i++) {
            listPairForReserve(reserveId, tokensArr[i], false, true, false);
        }

        // ether to token
        tokensArr = destTokensPerReserve[reserveId];
        for (uint256 i = 0; i < tokensArr.length; i++) {
            listPairForReserve(reserveId, tokensArr[i], true, false, false);
        }
    }

    function listPairs(
        bytes32 reserveId,
        IERC20 token,
        bool isTokenToEth,
        bool add
    ) internal {
        uint256 i;
        bytes32[] storage reserveArr = reservesPerTokenDest[token];
        IERC20[] storage tokensArr = destTokensPerReserve[reserveId];
        mapping(bytes32 => bool) storage isListedReserveWithToken = isListedReserveWithTokenDest[token];

        if (isTokenToEth) {
            reserveArr = reservesPerTokenSrc[token];
            tokensArr = srcTokensPerReserve[reserveId];
            isListedReserveWithToken = isListedReserveWithTokenSrc[token];
        }

        for (i = 0; i < reserveArr.length; i++) {
            if (reserveId == reserveArr[i]) {
                if (add) {
                    return; // reserve already added, no further action needed
                } else {
                    // remove reserve from reserveArr
                    reserveArr[i] = reserveArr[reserveArr.length - 1];
                    reserveArr.pop();

                    break;
                }
            }
        }

        if (add) {
            // add reserve and token to reserveArr and tokensArr respectively
            reserveArr.push(reserveId);
            tokensArr.push(token);
            isListedReserveWithToken[reserveId] = true;
        } else {
            // remove token from tokenArr
            for (i = 0; i < tokensArr.length; i++) {
                if (token == tokensArr[i]) {
                    tokensArr[i] = tokensArr[tokensArr.length - 1];
                    tokensArr.pop();
                    break;
                }
            }
            delete isListedReserveWithToken[reserveId];
        }
    }

    function onlyNetwork() internal view {
        require(msg.sender == address(lyfeblocNetwork), "only lyfeblocNetwork");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;

import "./IERC20.sol";

interface ILyfeblocNetwork {
    event LyfeblocTrade(
        IERC20 indexed src,
        IERC20 indexed dest,
        uint256 ethWeiValue,
        uint256 networkFeeWei,
        uint256 customPlatformFeeWei,
        bytes32[] t2eIds,
        bytes32[] e2tIds,
        uint256[] t2eSrcAmounts,
        uint256[] e2tSrcAmounts,
        uint256[] t2eRates,
        uint256[] e2tRates
    );

    function tradeWithHintAndFee(
        address payable trader,
        IERC20 src,
        uint256 srcAmount,
        IERC20 dest,
        address payable destAddress,
        uint256 maxDestAmount,
        uint256 minConversionRate,
        address payable platformWallet,
        uint256 platformFeeBps,
        bytes calldata hint
    ) external payable returns (uint256 destAmount);

    function listTokenForReserve(
        address reserve,
        IERC20 token,
        bool add
    ) external;

    function enabled() external view returns (bool);

    function getExpectedRateWithHintAndFee(
        IERC20 src,
        IERC20 dest,
        uint256 srcQty,
        uint256 platformFeeBps,
        bytes calldata hint
    )
        external
        view
        returns (
            uint256 expectedRateAfterNetworkFee,
            uint256 expectedRateAfterAllFees
        );

    function getNetworkData()
        external
        view
        returns (
            uint256 negligibleDiffBps,
            uint256 networkFeeBps,
            uint256 expiryTimestamp
        );

    function maxGasPrice() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;


interface ILyfeblocHistory {
    function saveContract(address _contract) external;
    function getContracts() external view returns (address[] memory);
}

// SPDX-License-Identifier: MIT


pragma solidity 0.6.6;


contract PermissionGroupsNoModifiers {
    address public admin;
    address public pendingAdmin;
    mapping(address => bool) internal operators;
    mapping(address => bool) internal alerters;
    address[] internal operatorsGroup;
    address[] internal alertersGroup;
    uint256 internal constant MAX_GROUP_SIZE = 50;

    event AdminClaimed(address newAdmin, address previousAdmin);
    event AlerterAdded(address newAlerter, bool isAdd);
    event OperatorAdded(address newOperator, bool isAdd);
    event TransferAdminPending(address pendingAdmin);

    constructor(address _admin) public {
        require(_admin != address(0), "admin 0");
        admin = _admin;
    }

    function getOperators() external view returns (address[] memory) {
        return operatorsGroup;
    }

    function getAlerters() external view returns (address[] memory) {
        return alertersGroup;
    }

    function addAlerter(address newAlerter) public {
        onlyAdmin();
        require(!alerters[newAlerter], "alerter exists"); // prevent duplicates.
        require(alertersGroup.length < MAX_GROUP_SIZE, "max alerters");

        emit AlerterAdded(newAlerter, true);
        alerters[newAlerter] = true;
        alertersGroup.push(newAlerter);
    }

    function addOperator(address newOperator) public {
        onlyAdmin();
        require(!operators[newOperator], "operator exists"); // prevent duplicates.
        require(operatorsGroup.length < MAX_GROUP_SIZE, "max operators");

        emit OperatorAdded(newOperator, true);
        operators[newOperator] = true;
        operatorsGroup.push(newOperator);
    }

    /// @dev Allows the pendingAdmin address to finalize the change admin process.
    function claimAdmin() public {
        require(pendingAdmin == msg.sender, "not pending");
        emit AdminClaimed(pendingAdmin, admin);
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }

    function removeAlerter(address alerter) public {
        onlyAdmin();
        require(alerters[alerter], "not alerter");
        delete alerters[alerter];

        for (uint256 i = 0; i < alertersGroup.length; ++i) {
            if (alertersGroup[i] == alerter) {
                alertersGroup[i] = alertersGroup[alertersGroup.length - 1];
                alertersGroup.pop();
                emit AlerterAdded(alerter, false);
                break;
            }
        }
    }

    function removeOperator(address operator) public {
        onlyAdmin();
        require(operators[operator], "not operator");
        delete operators[operator];

        for (uint256 i = 0; i < operatorsGroup.length; ++i) {
            if (operatorsGroup[i] == operator) {
                operatorsGroup[i] = operatorsGroup[operatorsGroup.length - 1];
                operatorsGroup.pop();
                emit OperatorAdded(operator, false);
                break;
            }
        }
    }

    /// @dev Allows the current admin to set the pendingAdmin address
    /// @param newAdmin The address to transfer ownership to
    function transferAdmin(address newAdmin) public {
        onlyAdmin();
        require(newAdmin != address(0), "new admin 0");
        emit TransferAdminPending(newAdmin);
        pendingAdmin = newAdmin;
    }

    /// @dev Allows the current admin to set the admin in one tx. Useful initial deployment.
    /// @param newAdmin The address to transfer ownership to.
    function transferAdminQuickly(address newAdmin) public {
        onlyAdmin();
        require(newAdmin != address(0), "admin 0");
        emit TransferAdminPending(newAdmin);
        emit AdminClaimed(newAdmin, admin);
        admin = newAdmin;
    }

    function onlyAdmin() internal view {
        require(msg.sender == admin, "only admin");
    }

    function onlyAlerter() internal view {
        require(alerters[msg.sender], "only alerter");
    }

    function onlyOperator() internal view {
        require(operators[msg.sender], "only operator");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;

import "./IERC20.sol";

/**
 * @title Lyfebloc utility file
 * mostly shared constants and rate calculation helpers
 * inherited by most of Lyfebloc contracts.
 * previous utils implementations are for previous solidity versions.
 */
contract Utils {
    IERC20 internal constant ETH_TOKEN_ADDRESS = IERC20(
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
    );
    uint256 internal constant PRECISION = (10**18);
    uint256 internal constant MAX_QTY = (10**28); // 10B tokens
    uint256 internal constant MAX_RATE = (PRECISION * 10**7); // up to 10M tokens per eth
    uint256 internal constant MAX_DECIMALS = 18;
    uint256 internal constant ETH_DECIMALS = 18;
    uint256 constant BPS = 10000; // Basic Price Steps. 1 step = 0.01%
    uint256 internal constant MAX_ALLOWANCE = uint256(-1); // token.approve inifinite

    mapping(IERC20 => uint256) internal decimals;

    function getUpdateDecimals(IERC20 token) internal returns (uint256) {
        if (token == ETH_TOKEN_ADDRESS) return ETH_DECIMALS; // save storage access
        uint256 tokenDecimals = decimals[token];
        // moreover, very possible that old tokens have decimals 0
        // these tokens will just have higher gas fees.
        if (tokenDecimals == 0) {
            tokenDecimals = token.decimals();
            decimals[token] = tokenDecimals;
        }

        return tokenDecimals;
    }

    function setDecimals(IERC20 token) internal {
        if (decimals[token] != 0) return; //already set

        if (token == ETH_TOKEN_ADDRESS) {
            decimals[token] = ETH_DECIMALS;
        } else {
            decimals[token] = token.decimals();
        }
    }

    /// @dev get the balance of a user.
    /// @param token The token type
    /// @return The balance
    function getBalance(IERC20 token, address user) internal view returns (uint256) {
        if (token == ETH_TOKEN_ADDRESS) {
            return user.balance;
        } else {
            return token.balanceOf(user);
        }
    }

    function getDecimals(IERC20 token) internal view returns (uint256) {
        if (token == ETH_TOKEN_ADDRESS) return ETH_DECIMALS; // save storage access
        uint256 tokenDecimals = decimals[token];
        // moreover, very possible that old tokens have decimals 0
        // these tokens will just have higher gas fees.
        if (tokenDecimals == 0) return token.decimals();

        return tokenDecimals;
    }

    function calcDestAmount(
        IERC20 src,
        IERC20 dest,
        uint256 srcAmount,
        uint256 rate
    ) internal view returns (uint256) {
        return calcDstQty(srcAmount, getDecimals(src), getDecimals(dest), rate);
    }

    function calcSrcAmount(
        IERC20 src,
        IERC20 dest,
        uint256 destAmount,
        uint256 rate
    ) internal view returns (uint256) {
        return calcSrcQty(destAmount, getDecimals(src), getDecimals(dest), rate);
    }

    function calcDstQty(
        uint256 srcQty,
        uint256 srcDecimals,
        uint256 dstDecimals,
        uint256 rate
    ) internal pure returns (uint256) {
        require(srcQty <= MAX_QTY, "srcQty > MAX_QTY");
        require(rate <= MAX_RATE, "rate > MAX_RATE");

        if (dstDecimals >= srcDecimals) {
            require((dstDecimals - srcDecimals) <= MAX_DECIMALS, "dst - src > MAX_DECIMALS");
            return (srcQty * rate * (10**(dstDecimals - srcDecimals))) / PRECISION;
        } else {
            require((srcDecimals - dstDecimals) <= MAX_DECIMALS, "src - dst > MAX_DECIMALS");
            return (srcQty * rate) / (PRECISION * (10**(srcDecimals - dstDecimals)));
        }
    }

    function calcSrcQty(
        uint256 dstQty,
        uint256 srcDecimals,
        uint256 dstDecimals,
        uint256 rate
    ) internal pure returns (uint256) {
        require(dstQty <= MAX_QTY, "dstQty > MAX_QTY");
        require(rate <= MAX_RATE, "rate > MAX_RATE");

        //source quantity is rounded up. to avoid dest quantity being too low.
        uint256 numerator;
        uint256 denominator;
        if (srcDecimals >= dstDecimals) {
            require((srcDecimals - dstDecimals) <= MAX_DECIMALS, "src - dst > MAX_DECIMALS");
            numerator = (PRECISION * dstQty * (10**(srcDecimals - dstDecimals)));
            denominator = rate;
        } else {
            require((dstDecimals - srcDecimals) <= MAX_DECIMALS, "dst - src > MAX_DECIMALS");
            numerator = (PRECISION * dstQty);
            denominator = (rate * (10**(dstDecimals - srcDecimals)));
        }
        return (numerator + denominator - 1) / denominator; //avoid rounding down errors
    }

    function calcRateFromQty(
        uint256 srcAmount,
        uint256 destAmount,
        uint256 srcDecimals,
        uint256 dstDecimals
    ) internal pure returns (uint256) {
        require(srcAmount <= MAX_QTY, "srcAmount > MAX_QTY");
        require(destAmount <= MAX_QTY, "destAmount > MAX_QTY");

        if (dstDecimals >= srcDecimals) {
            require((dstDecimals - srcDecimals) <= MAX_DECIMALS, "dst - src > MAX_DECIMALS");
            return ((destAmount * PRECISION) / ((10**(dstDecimals - srcDecimals)) * srcAmount));
        } else {
            require((srcDecimals - dstDecimals) <= MAX_DECIMALS, "src - dst > MAX_DECIMALS");
            return ((destAmount * PRECISION * (10**(srcDecimals - dstDecimals))) / srcAmount);
        }
    }

    function minOf(uint256 x, uint256 y) internal pure returns (uint256) {
        return x > y ? y : x;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;

import "./IERC20.sol";
import "./ILyfeblocNetworkProxy.sol";
import "./ILyfeblocReserve.sol";





interface ILyfeblocStorage {
    enum ReserveType {NONE, FPR, APR, BRIDGE, UTILITY, CUSTOM, ORDERBOOK, LAST}

    function addLyfeblocProxy(address LyfeblocProxy, uint256 maxApprovedProxies)
        external;

    function removeLyfeblocProxy(address LyfeblocProxy) external;

    function setContracts(address _LyfeblocFeeHandler, address _LyfeblocMatchingEngine) external;

    function setLyfeblocDaoContract(address _LyfeblocDao) external;

    function getReserveId(address reserve) external view returns (bytes32 reserveId);

    function getReserveIdsFromAddresses(address[] calldata reserveAddresses)
        external
        view
        returns (bytes32[] memory reserveIds);

    function getReserveAddressesFromIds(bytes32[] calldata reserveIds)
        external
        view
        returns (address[] memory reserveAddresses);

    function getReserveIdsPerTokenSrc(IERC20 token)
        external
        view
        returns (bytes32[] memory reserveIds);

    function getReserveAddressesPerTokenSrc(IERC20 token, uint256 startIndex, uint256 endIndex)
        external
        view
        returns (address[] memory reserveAddresses);

    function getReserveIdsPerTokenDest(IERC20 token)
        external
        view
        returns (bytes32[] memory reserveIds);

    function getReserveAddressesByReserveId(bytes32 reserveId)
        external
        view
        returns (address[] memory reserveAddresses);

    function getRebateWalletsFromIds(bytes32[] calldata reserveIds)
        external
        view
        returns (address[] memory rebateWallets);

    function getLyfeblocProxies() external view returns (ILyfeblocNetworkProxy[] memory);

    function getReserveDetailsByAddress(address reserve)
        external
        view
        returns (
            bytes32 reserveId,
            address rebateWallet,
            ReserveType resType,
            bool isFeeAccountedFlag,
            bool isEntitledRebateFlag
        );

    function getReserveDetailsById(bytes32 reserveId)
        external
        view
        returns (
            address reserveAddress,
            address rebateWallet,
            ReserveType resType,
            bool isFeeAccountedFlag,
            bool isEntitledRebateFlag
        );

    function getFeeAccountedData(bytes32[] calldata reserveIds)
        external
        view
        returns (bool[] memory feeAccountedArr);

    function getEntitledRebateData(bytes32[] calldata reserveIds)
        external
        view
        returns (bool[] memory entitledRebateArr);

    function getReservesData(bytes32[] calldata reserveIds, IERC20 src, IERC20 dest)
        external
        view
        returns (
            bool areAllReservesListed,
            bool[] memory feeAccountedArr,
            bool[] memory entitledRebateArr,
            ILyfeblocReserve[] memory reserveAddresses);

    function isLyfeblocProxyAdded() external view returns (bool);
}

// SPDX-License-Identifier: MIT




pragma solidity 0.6.6;


interface IERC20 {
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function approve(address _spender, uint256 _value) external returns (bool success);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function decimals() external view returns (uint8 digits);

    function totalSupply() external view returns (uint256 supply);
}


// to support backward compatible contract name -- so function signature remains same
abstract contract ERC20 is IERC20 {

}

// SPDX-License-Identifier: MIT


pragma solidity 0.6.6;

import "./IERC20.sol";

interface ILyfeblocReserve {
    function trade(
        IERC20 srcToken,
        uint256 srcAmount,
        IERC20 destToken,
        address payable destAddress,
        uint256 conversionRate,
        bool validate
    ) external payable returns (bool);

    function getConversionRate(
        IERC20 src,
        IERC20 dest,
        uint256 srcQty,
        uint256 blockNumber
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;

import "./IERC20.sol";

interface ILyfeblocNetworkProxy {

    event ExecuteTrade(
        address indexed trader,
        IERC20 src,
        IERC20 dest,
        address destAddress,
        uint256 actualSrcAmount,
        uint256 actualDestAmount,
        address platformWallet,
        uint256 platformFeeBps
    );

    /// @notice backward compatible
    function tradeWithHint(
        ERC20 src,
        uint256 srcAmount,
        ERC20 dest,
        address payable destAddress,
        uint256 maxDestAmount,
        uint256 minConversionRate,
        address payable walletId,
        bytes calldata hint
    ) external payable returns (uint256);

    function tradeWithHintAndFee(
        IERC20 src,
        uint256 srcAmount,
        IERC20 dest,
        address payable destAddress,
        uint256 maxDestAmount,
        uint256 minConversionRate,
        address payable platformWallet,
        uint256 platformFeeBps,
        bytes calldata hint
    ) external payable returns (uint256 destAmount);

    function trade(
        IERC20 src,
        uint256 srcAmount,
        IERC20 dest,
        address payable destAddress,
        uint256 maxDestAmount,
        uint256 minConversionRate,
        address payable platformWallet
    ) external payable returns (uint256);

    /// @notice backward compatible
    /// @notice Rate units (10 ** 18) => destQty (twei) / srcQty (twei) * 10 ** 18
    function getExpectedRate(
        ERC20 src,
        ERC20 dest,
        uint256 srcQty
    ) external view returns (uint256 expectedRate, uint256 worstRate);

    function getExpectedRateAfterFee(
        IERC20 src,
        IERC20 dest,
        uint256 srcQty,
        uint256 platformFeeBps,
        bytes calldata hint
    ) external view returns (uint256 expectedRate);
}