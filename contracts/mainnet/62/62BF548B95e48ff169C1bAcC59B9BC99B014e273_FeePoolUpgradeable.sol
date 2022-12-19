// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./TokenBridgeRegistryUpgradeable.sol";
import "./BridgeUpgradeable.sol";
import "./BridgeUtilsUpgradeable.sol";
import "./TokenUpgradeable.sol";

contract FeePoolUpgradeable is Initializable, OwnableUpgradeable {

    TokenBridgeRegistryUpgradeable public tokenBridgeRegistryUpgradeable;
    BridgeUpgradeable public bridgeUpgradeable;
    BridgeUtilsUpgradeable public bridgeUtilsUpgradeable;

    // tokenTicker => totalFees
    mapping(string => uint256) public totalFees;
    // tokenTicker => adminClaimedTillEpoch
    mapping(string => uint256) public adminClaimedTillEpoch;

    struct ConfirmedStartEpochFeeParams {
        string _tokenTicker;
        uint256 epochStartIndex;
        uint256 epochStartBlock;
        uint256 blockNo;
        uint256 depositedAmount;
        address _account;
        uint256 _index;
    }

    // tokenTicker => totalFees
    mapping(string => uint256) public feesInCurrentEpoch;

    event ClaimedRewards(
        uint256 indexed index,
        address indexed account,
        string tokenTicker,
        uint256 noOfTokens,
        uint256 claimTimestamp
    );

    function initialize(
        TokenBridgeRegistryUpgradeable _tokenBridgeRegistryUpgradeable,
        BridgeUpgradeable _bridgeUpgradeable
    ) initializer public {
        __Ownable_init();
        tokenBridgeRegistryUpgradeable = _tokenBridgeRegistryUpgradeable;
        bridgeUpgradeable = _bridgeUpgradeable;
    }

    function _isBridgeActive(string memory _tokenTicker) internal view {
        require(tokenBridgeRegistryUpgradeable.isBridgeActive() 
            && bridgeUtilsUpgradeable.isTokenBridgeActive(_tokenTicker), "BRIDGE_DISABLED");
    }

    function updateTokenBridgeRegistryAddress(TokenBridgeRegistryUpgradeable _newInstance) external onlyOwner {
        tokenBridgeRegistryUpgradeable = _newInstance;
    }

    function updateBridgeUpgradeableAddress(BridgeUpgradeable _newInstance) external onlyOwner {
        bridgeUpgradeable = _newInstance;
    }

    function updateBridgeUtilsUpgradeableAddress(BridgeUtilsUpgradeable _newInstance) external onlyOwner {
        bridgeUtilsUpgradeable = _newInstance;
    }

    function transferLpFee(
        string memory _tokenTicker,
        address _account,
        uint256 _index
    ) public {
        require(_msgSender() == address(bridgeUpgradeable), "ONLY_BRIDGE");
        // Calculate fee share
        uint256 feeShare = getUserConfirmedRewards(_tokenTicker, _account, _index);
        if(feeShare == 0)
            return;
        require(totalFees[_tokenTicker] >= feeShare, "INSUFFICIENT_FEES");
        // to prevent reentrancy attack
        bridgeUpgradeable.updateRewardClaimedTillIndex(_tokenTicker, _account, _index);

        uint8 feeType;
        (feeType, ) = bridgeUtilsUpgradeable.getFeeTypeAndFeeInBips(_tokenTicker);
        totalFees[_tokenTicker] -= feeShare;

        // Transfer Fees to LP user
        if(feeType == 0) {
            // fee in native chain token
            // (bool success, ) = _account.call{value: feeShare}("");
            // require(success, "TRANSFER_FAILED");
            payable(_account).transfer(feeShare);
        }
        else if(feeType == 1) {
            TokenUpgradeable token = bridgeUpgradeable.getToken(_tokenTicker);
            token.transfer(_account, feeShare);
        }
        
    }

    // function getLPsFee(
    //     uint256 epochTotalFees,
    //     string memory tokenTicker,
    //     uint256 epochIndex
    // ) internal view returns (uint256) {
    //     uint256 totalBoostedUsers = bridgeUpgradeable.totalBoostedUsers(tokenTicker, epochIndex);
    //     uint256 noOfDepositors;
    //     uint256 epochsLength = bridgeUpgradeable.getEpochsLength(tokenTicker);
    //     // calculation for the first epoch or the current ongoing epoch
    //     if((epochIndex == 1 && epochsLength == 0) || epochIndex == epochsLength + 1) {
    //         noOfDepositors = bridgeUtilsUpgradeable.getNoOfDepositors(tokenTicker);
    //     } else {
    //         noOfDepositors = bridgeUtilsUpgradeable.getEpochTotalDepositors(tokenTicker, epochIndex);
    //     }

    //     uint256 perUserFee = epochTotalFees / (2 * noOfDepositors);
        
    //     uint256 normalFees = (noOfDepositors - totalBoostedUsers) * perUserFee;
    //     uint256 extraBoostedFees = totalBoostedUsers * perUserFee * 3 / 2;
    //     return (extraBoostedFees + normalFees);
    // }

    // calculates (confirmed + unconfirmed) rewards
    function getUserUnconfirmedRewards(
        string memory _tokenTicker,
        address _account,
        uint256 _index
    ) public view returns (uint256) {
        (
            uint256 depositedAmount, 
            uint256 blockNo, 
            uint256 claimedTillEpochIndex, 
            uint256 epochStartIndex, 
            , 
            ,

        ) = bridgeUpgradeable.liquidityPosition(_tokenTicker, _account, _index);
        require(depositedAmount > 0, "INVALID_POSITION");

        uint256 feeEarned;
        
        uint256 epochsLength = bridgeUpgradeable.getEpochsLength(_tokenTicker);

        // user still in starting epoch
        if(epochsLength == epochStartIndex - 1) {
            return _getUnconfirmedStartEpochFee(_tokenTicker, blockNo, depositedAmount, _account, _index, epochsLength);
        }

        // starting epoch is over but user has claimed nothing
        if(epochStartIndex - 1 == claimedTillEpochIndex 
            && epochsLength > epochStartIndex - 1
        ) { 
            // ConfirmedStartEpochFeeParams memory params = ConfirmedStartEpochFeeParams(
            //     _tokenTicker,
            //     epochStartIndex,
            //     epochStartBlock,
            //     blockNo,
            //     depositedAmount,
            //     _account,
            //     _index
            // );
            // feeEarned = _getConfirmedStartEpochFee(params);
            claimedTillEpochIndex += 1;
        }

        // fees for all the completed epochs
        for (uint256 liqIndex = claimedTillEpochIndex + 1; liqIndex <= epochsLength; liqIndex++) {
            // feeEarned += _getConfirmedEpochsFee(_tokenTicker, liqIndex, depositedAmount, _account, _index);
            claimedTillEpochIndex += 1;
        }

        // fees for current ongoing epoch (not the starting epoch for user)
        if(epochsLength == claimedTillEpochIndex) {
            feeEarned += _getUnconfirmedCurrentEpochFee(_tokenTicker, claimedTillEpochIndex, depositedAmount, _account, _index, epochsLength);
        }

        return feeEarned;
    }

    function _getUnconfirmedStartEpochFee(
        string memory _tokenTicker,
        uint256 blockNo,
        uint256 depositedAmount,
        address _account,
        uint256 _index,
        uint256 epochsLength
    ) internal view returns (uint256) {
        uint256 totalFeeCollected = feesInCurrentEpoch[_tokenTicker];
        // uint256 lpsFee = getLPsFee(totalFeeCollected, _tokenTicker, epochsLength + 1);
        uint256 epochLpFees = totalFeeCollected / 2;
        uint256 totalActiveLiquidity = bridgeUpgradeable.totalLpLiquidity(_tokenTicker);
        
        uint256 liquidityBlocks = block.number - blockNo;
        uint256 epochLength = bridgeUtilsUpgradeable.getEpochLength(_tokenTicker);
        uint256 feeEarned = (depositedAmount * liquidityBlocks * epochLpFees) / (totalActiveLiquidity * epochLength);
        if(bridgeUpgradeable.hasBooster(_tokenTicker, _account, _index, epochsLength + 1)) {
            feeEarned = feeEarned * 3 / 2;
        }
        return feeEarned;
    }

    function _getConfirmedStartEpochFee(
        ConfirmedStartEpochFeeParams memory params
    ) internal view returns (uint256) {
        (
            , 
            uint256 epochLength, 
            uint256 totalFeesCollected, 
            uint256 totalActiveLiquidity, 
            
        ) = bridgeUpgradeable.epochs(params._tokenTicker, params.epochStartIndex-1);
        uint256 liquidityBlocks = params.epochStartBlock + epochLength - params.blockNo;
        // uint256 lpsFee = getLPsFee(totalFeesCollected, params._tokenTicker, params.epochStartIndex);
        uint256 epochLpFees = totalFeesCollected / 2;
        uint256 feeEarned = (params.depositedAmount * liquidityBlocks * epochLpFees) / (totalActiveLiquidity * epochLength);
        if(bridgeUpgradeable.hasBooster(params._tokenTicker, params._account, params._index, params.epochStartIndex)) {
            feeEarned = feeEarned * 3 / 2;
        }
        return feeEarned;
    }

    function _getConfirmedEpochsFee(
        string memory _tokenTicker,
        uint256 liqIndex,
        uint256 depositedAmount,
        address _account,
        uint256 _index
    ) internal view returns (uint256) {
        (
            , 
            , 
            uint256 totalFeesCollected, 
            uint256 totalActiveLiquidity, 
            
        ) = bridgeUpgradeable.epochs(_tokenTicker, liqIndex-1);
        // uint256 lpsFee = getLPsFee(totalFeesCollected, _tokenTicker, liqIndex);
        uint256 epochLpFees = totalFeesCollected / 2;
        uint256 epochFee = (depositedAmount * epochLpFees / totalActiveLiquidity);
        if(bridgeUpgradeable.hasBooster(_tokenTicker, _account, _index, liqIndex)) {
            epochFee = epochFee * 3 / 2;
        }
        return epochFee;
    }

    function _getUnconfirmedCurrentEpochFee(
        string memory _tokenTicker,
        uint256 claimedTillEpochIndex,
        uint256 depositedAmount,
        address _account,
        uint256 _index,
        uint256 epochsLength
    ) internal view returns (uint256) {
        uint256 totalActiveLiquidity = bridgeUpgradeable.totalLpLiquidity(_tokenTicker);
        // uint256 lpsFee = getLPsFee(totalFees[_tokenTicker], _tokenTicker, claimedTillEpochIndex + 1);
        uint256 epochLpFees = feesInCurrentEpoch[_tokenTicker] / 2;

        (
            uint256 startBlock, 
            uint256 epochLength, 
            , 
            , 
            
        ) = bridgeUpgradeable.epochs(_tokenTicker, claimedTillEpochIndex - 1);
        uint256 liquidityBlocks = block.number - (startBlock + epochLength);
        uint256 fixedEpochLength = bridgeUtilsUpgradeable.getEpochLength(_tokenTicker);
        uint256 feeEarned = (depositedAmount * liquidityBlocks * epochLpFees) / (totalActiveLiquidity * fixedEpochLength);
        if(bridgeUpgradeable.hasBooster(_tokenTicker, _account, _index, epochsLength + 1)) {
            feeEarned = feeEarned * 3 / 2;
        }
        return feeEarned;
    }

    function getUserConfirmedRewards(
        string memory _tokenTicker,
        address _account,
        uint256 _index
    ) public view returns (uint256) {
        (
            uint256 depositedAmount, 
            uint256 blockNo, 
            uint256 claimedTillEpochIndex, 
            uint256 epochStartIndex, 
            uint256 epochStartBlock, 
            ,

        ) = bridgeUpgradeable.liquidityPosition(_tokenTicker, _account, _index);
        require(depositedAmount > 0, "INVALID_POSITION");

        uint256 epochsLength = bridgeUpgradeable.getEpochsLength(_tokenTicker);

        uint256 feeEarned;
                
        // user still in starting epoch
        if(epochsLength == epochStartIndex - 1) {
            return feeEarned;
        }

        // starting epoch is over but user has claimed nothing
        if(epochStartIndex - 1 == claimedTillEpochIndex 
            && epochsLength > epochStartIndex - 1
        ) {
            ConfirmedStartEpochFeeParams memory params = ConfirmedStartEpochFeeParams(
                _tokenTicker,
                epochStartIndex,
                epochStartBlock,
                blockNo,
                depositedAmount,
                _account,
                _index
            );
            feeEarned = _getConfirmedStartEpochFee(params);
            claimedTillEpochIndex += 1;
        }

        // fees for all the completed epochs
        for (uint256 liqIndex = claimedTillEpochIndex + 1; liqIndex <= epochsLength; liqIndex++) {
            feeEarned += _getConfirmedEpochsFee(_tokenTicker, liqIndex, depositedAmount, _account, _index);
            claimedTillEpochIndex += 1;
        }

        return feeEarned;
    }

    function claimFeeShare(
        string calldata _tokenTicker, 
        uint256 _index
    ) public {
        _isBridgeActive(_tokenTicker);

        // adding any passed epochs
        bridgeUpgradeable.addPassedEpochs(_tokenTicker);

        address _account = _msgSender();
        (
            uint256 depositedAmount, 
            , 
            uint256 claimedTillEpochIndex, 
            , 
            , 
            ,
            
        ) = bridgeUpgradeable.liquidityPosition(_tokenTicker, _account, _index);
        require(depositedAmount > 0, "INVALID_POSITION");

        uint256 startEpoch = claimedTillEpochIndex + 1;
        uint256 feeEarned = getUserConfirmedRewards(_tokenTicker, _account, _index);
        require(feeEarned > 0, "NO_REWARD");
        require(totalFees[_tokenTicker] >= feeEarned, "INSUFFICIENT_FEES");
        bridgeUpgradeable.updateRewardClaimedTillIndex(_tokenTicker, _account, _index);

        uint256 endEpoch = bridgeUpgradeable.getEpochsLength(_tokenTicker);
        for (uint256 epochIndex = startEpoch; epochIndex <= endEpoch; epochIndex++) {
            bridgeUpgradeable.deleteHasBoosterMapping(_tokenTicker, _account, _index, epochIndex);
        }

        _transferFee(_tokenTicker, _account, feeEarned);

        emit ClaimedRewards(_index, _account, _tokenTicker, feeEarned, block.timestamp);
    }

    function _transferFee(
        string memory _tokenTicker,
        address _account,
        uint256 feeEarned
    ) internal {
        uint8 feeType;
        uint256 feeInBips;
        (feeType, feeInBips) = bridgeUtilsUpgradeable.getFeeTypeAndFeeInBips(_tokenTicker);
        totalFees[_tokenTicker] -= feeEarned;

        // fee in native chain token
        if(feeType == 0) {
            (bool success, ) = _account.call{value: feeEarned}("");
            require(success, "CLAIM_FEE_FAILED");
        }
        else if(feeType == 1) {
            TokenUpgradeable token = bridgeUpgradeable.getToken(_tokenTicker);
            token.transfer(_account, feeEarned);
        }
    }

    function getLastEpochLpFees(
        string memory _tokenTicker
    ) public view returns (uint256) {
        uint256 epochsLength = bridgeUpgradeable.getEpochsLength(_tokenTicker);
        if(epochsLength == 0)
            return 0;
        
        // uint256 noOfDepositors = bridgeUtilsUpgradeable.getEpochTotalDepositors(_tokenTicker, epochsLength);
        (
            , 
            , 
            uint256 totalFeesCollected, 
            uint256 totalActiveLiquidity, 
            uint256 noOfDepositors
        ) = bridgeUpgradeable.epochs(_tokenTicker, epochsLength-1);

        // for child token bridges
        if(noOfDepositors == 0) {
            return 0;
        }
        uint256 totalBoostedLiquidity = bridgeUpgradeable.totalBoostedLiquidity(_tokenTicker, epochsLength);
        uint256 totalNormalLiquidity = totalActiveLiquidity - totalBoostedLiquidity;

        uint256 boostedFees = (totalBoostedLiquidity * totalFeesCollected * 3) / (totalActiveLiquidity * 4);
        uint256 normalFees = (totalNormalLiquidity * totalFeesCollected) / (totalActiveLiquidity * 2);

        return (normalFees + boostedFees);
    }

    // function getAdminTokenFees(
    //     string memory _tokenTicker
    // ) public view onlyOwner returns (uint256) {
    //     uint256 epochsLength = bridgeUpgradeable.getEpochsLength(_tokenTicker);

    //     uint256 adminFees;
    //     for (uint256 epochIndex = adminClaimedTillEpoch[_tokenTicker] + 1; epochIndex <= epochsLength; epochIndex++) {
    //         uint256 noOfDepositors = bridgeUtilsUpgradeable.getEpochTotalDepositors(_tokenTicker, epochIndex);
    //         if(noOfDepositors == 0) {
    //             continue;
    //         }
    //         uint256 epochTotalFees = bridgeUtilsUpgradeable.getEpochTotalFees(_tokenTicker, epochIndex);
    //         uint256 totalBoostedUsers = bridgeUpgradeable.totalBoostedUsers(_tokenTicker, epochIndex);

    //         // uint256 perUserFee = epochTotalFees / (2 * noOfDepositors);
            
    //         // uint256 normalFees = (noOfDepositors - totalBoostedUsers) * perUserFee;
    //         // uint256 extraBoostedFees = totalBoostedUsers * perUserFee * 3 / 2;
    //         uint256 normalFees = (noOfDepositors - totalBoostedUsers) * epochTotalFees / (2 * noOfDepositors);
    //         uint256 extraBoostedFees = totalBoostedUsers * epochTotalFees * 3 / (4 * noOfDepositors);
    //         adminFees += epochTotalFees - normalFees - extraBoostedFees;
    //     }

    //     return adminFees;
    // }

    function getAdminTokenFees(
        string memory _tokenTicker,
        uint256 _limit
    ) public view returns (uint256) {
        uint256 startIndex = adminClaimedTillEpoch[_tokenTicker] + 1;
        uint256 endIndex = bridgeUpgradeable.getEpochsLength(_tokenTicker);
        if(_limit != 0) {
            require(startIndex + _limit - 1 <= endIndex, "LIMIT_EXCEEDS");
            endIndex = startIndex + _limit - 1;
        }

        uint256 adminFees;
        for (uint256 epochIndex = startIndex; epochIndex <= endIndex; epochIndex++) {
            // uint256 noOfDepositors = bridgeUtilsUpgradeable.getEpochTotalDepositors(_tokenTicker, epochIndex);
            // uint256 epochTotalFees = bridgeUtilsUpgradeable.getEpochTotalFees(_tokenTicker, epochIndex);
            (
                , 
                , 
                uint256 totalFeesCollected, 
                uint256 totalActiveLiquidity, 
                uint256 noOfDepositors
            ) = bridgeUpgradeable.epochs(_tokenTicker, epochIndex-1);

            // for child token bridges
            if(noOfDepositors == 0) {
                adminFees += totalFeesCollected;
                continue;
            }
            uint256 totalBoostedLiquidity = bridgeUpgradeable.totalBoostedLiquidity(_tokenTicker, epochIndex);
            uint256 totalNormalLiquidity = totalActiveLiquidity - totalBoostedLiquidity;

            uint256 boostedFees = (totalBoostedLiquidity * totalFeesCollected * 3) / (totalActiveLiquidity * 4);
            uint256 normalFees = (totalNormalLiquidity * totalFeesCollected) / (totalActiveLiquidity * 2);

            adminFees += totalFeesCollected - normalFees - boostedFees;
        }

        return adminFees;
    }

    function withdrawAdminTokenFees(
        string memory _tokenTicker,
        uint256 _limit
    ) public onlyOwner {
        // adding any passed epochs
        bridgeUpgradeable.addPassedEpochs(_tokenTicker);
        
        uint256 adminFees = getAdminTokenFees(_tokenTicker, _limit);
        require(adminFees > 0, "ZERO_FEES");

        totalFees[_tokenTicker] -= adminFees;
        if(_limit != 0)
            adminClaimedTillEpoch[_tokenTicker] += _limit;
        else
            adminClaimedTillEpoch[_tokenTicker] = bridgeUpgradeable.getEpochsLength(_tokenTicker);

        uint8 feeType;
        (feeType, ) = bridgeUtilsUpgradeable.getFeeTypeAndFeeInBips(_tokenTicker);
        
        // fee in native chain token
        if(feeType == 0) {
            (bool success, ) = _msgSender().call{value: adminFees}("");
            require(success, "CLAIM_FEE_FAILED");
        }
        else if(feeType == 1) {
            TokenUpgradeable token = bridgeUpgradeable.getToken(_tokenTicker);
            token.transfer(_msgSender(), adminFees);
        }
    }

    function withdrawAdminAllTokenFees(
        uint256 _limit
    ) public onlyOwner {
        string[] memory tokenBridges = tokenBridgeRegistryUpgradeable.getAllTokenBridges();

        for (uint256 index = 0; index < tokenBridges.length; index++) {
            withdrawAdminTokenFees(tokenBridges[index], _limit);
        }
    }

    function updateTotalFees(
        string calldata _tokenTicker,
        uint256 feesEarned,
        bool _isAddingFees
    ) public {
        require(_msgSender() == address(bridgeUpgradeable), "ONLY_BRIDGE");
        if(_isAddingFees) {
            totalFees[_tokenTicker] += feesEarned;
            feesInCurrentEpoch[_tokenTicker] += feesEarned;
        }
        else {
            totalFees[_tokenTicker] -= feesEarned;
        }
    }

    function resetFeesInCurrentEpoch(string calldata _tokenTicker) public {
        require(_msgSender() == address(bridgeUpgradeable), "ONLY_BRIDGE");
        feesInCurrentEpoch[_tokenTicker] = 0;
    }

    receive() external payable {}

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "./TokenUpgradeable.sol";
import "./BridgeUpgradeable.sol";
import "./RegistryStorage.sol";
import "./FeePoolUpgradeable.sol";

contract TokenBridgeRegistryUpgradeable is Initializable, OwnableUpgradeable, RegistryStorage {

    address public bridgeUpgradeable;
    address public feePoolUpgradeable;

    event BridgeEnabled();
    event BridgeDisabled();

    event BridgeAdded(
        string tokenTicker,
        string tokenName,
        string imageUrl
    );

    event BridgeRemoved(
        string tokenTicker
    );

    function initialize() public initializer {
        __Ownable_init();
    }

    function updateBridgeAddress(address _newBridgeAddress) external onlyOwner {
        require(_newBridgeAddress != address(0), "INVALID_BRIDGE");
        bridgeUpgradeable = _newBridgeAddress;
    }

    function updateFeePoolAddress(address _newFeePoolAddress) external onlyOwner {
        require(_newFeePoolAddress != address(0), "INVALID_FEEPOOL");
        feePoolUpgradeable = _newFeePoolAddress;
    }

    function deployChildToken(
        string calldata _name, 
        string calldata _imageUrl, 
        string calldata _ticker,
        uint8 _decimals
    ) public onlyOwner {
        require(bridgeTokenMetadata[_ticker].tokenAddress == address(0), "TOKEN_ALREADY_EXISTS");
        TokenUpgradeable newChildToken = new TokenUpgradeable();
        // newChildToken.initialize(_name, _ticker, _decimals, _msgSender());
        
        // deploy ProxyAdmin contract
        ProxyAdmin proxyAdmin = new ProxyAdmin();

        bytes memory data = abi.encodeWithSignature("initialize(string,string,uint8,address)", 
                                _name, _ticker, _decimals, _msgSender());
        // deploy TransparentUpgradeableProxy contract
        TransparentUpgradeableProxy transparentUpgradeableProxy = new TransparentUpgradeableProxy(address(newChildToken), address(proxyAdmin), data);
        
        // transfer ownership of token to bridge
        newChildToken = TokenUpgradeable(address(transparentUpgradeableProxy));
        newChildToken.transferOwnership(bridgeUpgradeable);
        // transfer ProxyAdmin ownership to the msg.sender so as to upgrade in future if reqd. 
        proxyAdmin.transferOwnership(_msgSender());

        BridgeTokenMetadata memory newBridgeTokenMetadata = BridgeTokenMetadata ({
            name: _name,
            imageUrl: _imageUrl,
            tokenAddress: address(transparentUpgradeableProxy)
        });
        bridgeTokenMetadata[_ticker] = newBridgeTokenMetadata;
    }

    function addTokenMetadata(
        address _tokenAddress, 
        string calldata _imageUrl
    ) public onlyOwner {
        TokenUpgradeable token = TokenUpgradeable(_tokenAddress);

        BridgeTokenMetadata memory newBridgeTokenMetadata = BridgeTokenMetadata ({
            name: token.name(),
            imageUrl: _imageUrl,
            tokenAddress: _tokenAddress
        });
        bridgeTokenMetadata[token.symbol()] = newBridgeTokenMetadata;
    }

    // function getTokenMetadata(string calldata tokenTicker) public view returns (BridgeTokenMetadata memory) {
    //     return bridgeTokenMetadata[tokenTicker];
    // }

    function addBridge(
        uint8 _bridgeType,
        string memory _tokenTicker,
        uint256 _epochLength,
        uint8 _feeType,
        uint256 _feeInBips
    ) public onlyOwner {
        BridgeTokenMetadata memory token = bridgeTokenMetadata[_tokenTicker];
        // address tokenAddress = bridgeTokenMetadata[_tokenTicker].tokenAddress;
        require(token.tokenAddress != address(0), "TOKEN_NOT_EXISTS");
        require(tokenBridge[_tokenTicker].startBlock == 0, "TOKEN_BRIDGE_ALREADY_EXISTS");
        require(_bridgeType == 0 || _bridgeType == 1, "INVALID_BRIDGE_TYPE");
        require(_feeType == 0 || _feeType == 1, "INVALID_FEE_TYPE");
        if(_bridgeType == 1) {
            TokenUpgradeable tokenInstance = TokenUpgradeable(token.tokenAddress);
            require(tokenInstance.owner() == bridgeUpgradeable, "BRIDGE_NOT_OWNER");
        }

        // add mapping to bridge
        // if(_feeType == 1) {
        //     _feeInBips *= 100;
        // }
        FeeConfig memory feeConfig = FeeConfig({
            feeType: _feeType,
            feeInBips: _feeInBips
        });
        TokenBridge memory newTokenBridge = TokenBridge({
            bridgeType: _bridgeType,
            tokenTicker: _tokenTicker,
            startBlock: block.number,
            epochLength: _epochLength,
            fee: feeConfig,
            // totalFeeCollected: 0,
            // totalActiveLiquidity: 0,
            noOfDepositors: 0,
            isActive: true
        });
        tokenBridge[_tokenTicker] = newTokenBridge;
        tokenBridges.push(_tokenTicker);

        // deploy setu version of token
        TokenUpgradeable primaryToken = TokenUpgradeable(bridgeTokenMetadata[_tokenTicker].tokenAddress);
        _deploySetuToken(token.name, _tokenTicker, primaryToken.decimals());

        BridgeUpgradeable(payable(bridgeUpgradeable)).initNextEpochBlock(_tokenTicker, _epochLength);
        
        emit BridgeAdded(_tokenTicker, bridgeTokenMetadata[_tokenTicker].name, bridgeTokenMetadata[_tokenTicker].imageUrl);
    }

    function _deploySetuToken(
        string memory _name, 
        string memory _ticker,
        uint8 _decimals
    ) internal {
        TokenUpgradeable setuToken = new TokenUpgradeable();
        // setuToken.initialize(_concatenate("setu", _name), _concatenate("setu", _ticker), _decimals, _msgSender());

        // deploy ProxyAdmin contract
        ProxyAdmin proxyAdmin = new ProxyAdmin();

        bytes memory data = abi.encodeWithSignature("initialize(string,string,uint8,address)", 
                                _concatenate("setu", _name), _concatenate("setu", _ticker), _decimals, _msgSender());
        // deploy TransparentUpgradeableProxy contract
        TransparentUpgradeableProxy transparentUpgradeableProxy = new TransparentUpgradeableProxy(address(setuToken), address(proxyAdmin), data);

        // transfer ownership of setu token to bridge
        setuToken = TokenUpgradeable(address(transparentUpgradeableProxy));
        setuToken.transferOwnership(bridgeUpgradeable);
        // transfer ProxyAdmin ownership to the msg.sender so as to upgrade in future if reqd. 
        proxyAdmin.transferOwnership(_msgSender());

        // Add to TokenBridge mapping
        BridgeTokenMetadata memory newBridgeTokenMetadata = BridgeTokenMetadata ({
            name: _concatenate("setu", _name),
            imageUrl: "",
            tokenAddress: address(transparentUpgradeableProxy)
        });
        bridgeTokenMetadata[_concatenate("setu", _ticker)] = newBridgeTokenMetadata;
    }

    function _concatenate(
        string memory a, 
        string memory b
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }

    function updateFeeConfig(
        string calldata _tokenTicker,
        uint8 _feeType,
        uint256 _feeInBips
    ) public onlyOwner {
        require(tokenBridge[_tokenTicker].startBlock > 0, "NO_TOKEN_BRIDGE_EXISTS");
        require(FeePoolUpgradeable(payable(feePoolUpgradeable)).totalFees(_tokenTicker) == 0, "FEE_PRESENT");
        require(_feeType == 0 || _feeType == 1, "INVALID_FEE_TYPE");
        require(_feeInBips > 0, "ZERO_FEE");
        // if(_feeType == 1) {
        //     _feeInBips *= 100;
        // }
        FeeConfig memory feeConfig = FeeConfig({
            feeType: _feeType,
            feeInBips: _feeInBips
        });
        tokenBridge[_tokenTicker].fee = feeConfig;
    }

    function updateEpochLength(
        string calldata _tokenTicker,
        uint256 _newEpochLength
    ) public onlyOwner {
        require(tokenBridge[_tokenTicker].startBlock > 0, "NO_TOKEN_BRIDGE_EXISTS");
        require(_newEpochLength > 0, "ZERO_EPOCH_LENGTH");
        tokenBridge[_tokenTicker].epochLength = _newEpochLength;
    }

    function disableBridgeToken(string calldata _tokenTicker) public onlyOwner {
        require(tokenBridge[_tokenTicker].startBlock > 0, "NO_TOKEN_BRIDGE_EXISTS");
        tokenBridge[_tokenTicker].isActive = false;
    }

    function enableBridgeToken(string calldata _tokenTicker) public onlyOwner {
        require(tokenBridge[_tokenTicker].startBlock > 0, "NO_TOKEN_BRIDGE_EXISTS");
        tokenBridge[_tokenTicker].isActive = true;
    }

    function disableBridge() public onlyOwner {
        isBridgeActive = false;
        emit BridgeDisabled();
    }

    function enableBridge() public onlyOwner {
        isBridgeActive = true;
        emit BridgeEnabled();
    }

    // function getFeeAndLiquidity(string calldata _tokenTicker) public view returns (uint256, uint256) {
    //     return (tokenBridge[_tokenTicker].totalFeeCollected, tokenBridge[_tokenTicker].totalActiveLiquidity);
    // }

    // function getEpochLength(string calldata _tokenTicker) public view returns (uint256) {
    //     return tokenBridge[_tokenTicker].epochLength;
    // }

    // function getStartBlockAndEpochLength(string calldata _tokenTicker) public view returns (uint256, uint256) {
    //     return (tokenBridge[_tokenTicker].startBlock, tokenBridge[_tokenTicker].epochLength);
    // } 

    // function getTokenAddress(string calldata _tokenTicker) public view returns (address) {
    //     return bridgeTokenMetadata[_tokenTicker].tokenAddress;
    // }

    // function getBridgeType(string calldata _tokenTicker) public view returns (uint8) {
    //     return tokenBridge[_tokenTicker].bridgeType;
    // }

    // function isTokenBridgeActive(string calldata _tokenTicker) public view returns (bool) {
    //     return tokenBridge[_tokenTicker].isActive;
    // }

    // function getFeeTypeAndFeeInBips(string calldata _tokenTicker) public view returns (uint8, uint256) {
    //     return (tokenBridge[_tokenTicker].fee.feeType, tokenBridge[_tokenTicker].fee.feeInBips);
    // }

    function updateNoOfDepositors(
        string calldata _tokenTicker,
        bool _isAddingLiquidity
    ) public {
        require(_msgSender() == bridgeUpgradeable, "ONLY_BRIDGE_ALLOWED");
        if(_isAddingLiquidity) {
            ++tokenBridge[_tokenTicker].noOfDepositors;
        }
        else {
            --tokenBridge[_tokenTicker].noOfDepositors;
        }
    }

    function getAllTokenBridges() public view returns (string[] memory) {
        return tokenBridges;
    }

    function removeBridgeToken(string calldata _tokenTicker) external onlyOwner {
        delete bridgeTokenMetadata[_tokenTicker];
    }

    function removeBridge(string memory _tokenTicker) external onlyOwner {
        require(BridgeUpgradeable(payable(bridgeUpgradeable)).totalLpLiquidity(_tokenTicker) == 0, "LIQ_PRESENT");
        require(FeePoolUpgradeable(payable(feePoolUpgradeable)).totalFees(_tokenTicker) == 0, "FEE_PRESENT");
        delete tokenBridge[_tokenTicker];

        uint256 len = tokenBridges.length;
        for (uint256 index = 0; index < len; index++) {
            // string memory token = tokenBridges[index];
            if(keccak256(abi.encodePacked(tokenBridges[index])) == keccak256(abi.encodePacked(_tokenTicker))) {
                if(index < len-1) {
                    tokenBridges[index] = tokenBridges[len-1];
                }
                tokenBridges.pop();
                break;
            }
        }

        emit BridgeRemoved(_tokenTicker);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./TokenBridgeRegistryUpgradeable.sol";
import "./FeePoolUpgradeable.sol";
import "@routerprotocol/router-crosstalk/contracts/RouterCrossTalkUpgradeable.sol";
import "./BridgeStorage.sol";
import "./BridgeUtilsUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BridgeUpgradeable is Initializable, OwnableUpgradeable, RouterCrossTalkUpgradeable, BridgeStorage {

    TokenBridgeRegistryUpgradeable public tokenBridgeRegistryUpgradeable;

    FeePoolUpgradeable public feePoolUpgradeable;

    BridgeUtilsUpgradeable public bridgeUtilsUpgradeable;

    event LiquidityAdded(
        uint256 indexed index,
        address indexed account,
        string tokenTicker,
        // string tokenName,
        // string imageUrl,
        uint256 noOfTokens
        // uint256 blockTimestamp
    );

    event LiquidityRemoved(
        uint256 indexed index,
        address indexed account,
        string tokenTicker,
        uint256 noOfTokens
    );

    // event BridgeTransactionInit(
    //     uint256 transferIndex,
    //     uint256 fromChainId,
    //     uint256 toChainId,
    //     address account,
    //     string tokenTicker,
    //     uint256 noOfTokens,
    //     uint8 status
    // );

    // event BridgeTransactionEnd(
    //     uint256 transferIndex,
    //     uint256 fromChainId,
    //     uint256 toChainId,
    //     address account,
    //     string tokenTicker,
    //     uint256 noOfTokens,
    //     uint8 status
    // );

    event BridgeTransaction(
        uint256 transferIndex,
        uint256 fromChainId,
        uint256 toChainId,
        address account,
        string tokenTicker,
        uint256 noOfTokens,
        uint8 status
    );

    modifier isBridgeActive(string memory _tokenTicker) {
        _isBridgeActive(_tokenTicker);
        _;
    }

    function _isBridgeActive(
        string memory _tokenTicker
    ) internal view {
        require(tokenBridgeRegistryUpgradeable.isBridgeActive() 
            && bridgeUtilsUpgradeable.isTokenBridgeActive(_tokenTicker), "BRIDGE_DISABLED");
    }

    function initialize(
        TokenBridgeRegistryUpgradeable _tokenBridgeRegistryUpgradeable,
        address _genericHandler,
        uint8 _chainId
    ) public initializer {
        __Ownable_init();
        __RouterCrossTalkUpgradeable_init(_genericHandler);
        tokenBridgeRegistryUpgradeable = _tokenBridgeRegistryUpgradeable;
        chainId = _chainId;
        maxBips = 1000;
        crossChainGas = 1000000;
    }

    function updateRegistryAddress(TokenBridgeRegistryUpgradeable _registryAddress) external onlyOwner {
        tokenBridgeRegistryUpgradeable = _registryAddress;
    }
    
    function updateFeePoolAddress(FeePoolUpgradeable _feePoolAddress) external onlyOwner {
        feePoolUpgradeable = _feePoolAddress;
    }

    function updateBridgeUtilsAddress(BridgeUtilsUpgradeable _bridgeUtilsAddress) external onlyOwner {
        bridgeUtilsUpgradeable = _bridgeUtilsAddress;
    }

    function updateMaxBips(uint256 _newMaxBips) external onlyOwner {
        maxBips = _newMaxBips;
    }

    function updateCrossChainGas(uint256 _newGasAmount) external onlyOwner {
        crossChainGas = _newGasAmount;
    }

    function setLinker(address _linker) external onlyOwner  {
        setLink(_linker);
    }
 
    function setFeeTokenAddress(address _feeAddress) external onlyOwner {
        setFeeToken(_feeAddress);
    }

    function approveRouterFee(address _feeToken, uint256 _value) external onlyOwner  {
        approveFees(_feeToken, _value);
    }

    function getToken(string memory _tokenTicker) public view returns (TokenUpgradeable) {
        address tokenAddress = bridgeUtilsUpgradeable.getTokenAddress(_tokenTicker);
        require(tokenAddress != address(0), "INVALID_TOKEN");
        TokenUpgradeable token = TokenUpgradeable(tokenAddress);
        return token;
    }

    function updateBoosterConfig(
        address _adminAccount,
        address _boosterToken,
        uint256 _perBoosterPrice,
        string calldata _imageUrl
    ) external onlyOwner {
        require(_adminAccount != address(0) && 
                _boosterToken != address(0) && 
                _perBoosterPrice > 0, "INVALID_PARAMS");

        boosterConfig = BoosterConfig({
            tokenAddress: _boosterToken,
            price: _perBoosterPrice,
            imageUrl: _imageUrl,
            adminAccount: _adminAccount
        });
    }

    function buyBoosterPacks(
        string calldata _tokenTicker,
        uint256 _index,
        uint256 _quantity
    ) public isBridgeActive(_tokenTicker) {
        LiquidityPosition storage position = liquidityPosition[_tokenTicker][_msgSender()][_index];
        require(position.depositedAmount > 0, "INVALID_POSITION");

        TokenUpgradeable boosterToken = TokenUpgradeable(boosterConfig.tokenAddress);
        boosterToken.transferFrom(_msgSender(), boosterConfig.adminAccount, boosterConfig.price * _quantity);

        // adding any passed epochs
        _addPassedEpochs(_tokenTicker);

        uint256 currentEpochIndex = epochs[_tokenTicker].length + 1;
        if(position.boosterEndEpochIndex >= currentEpochIndex) {
            _updateBoosterMapping(_tokenTicker, _index, _quantity, position.boosterEndEpochIndex + 1, position.depositedAmount, true);
            position.boosterEndEpochIndex += _quantity;
        }
        else {
            _updateBoosterMapping(_tokenTicker, _index, _quantity, currentEpochIndex, position.depositedAmount, true);
            position.boosterEndEpochIndex = currentEpochIndex + _quantity - 1;
        }
    }

    function _updateBoosterMapping(
        string calldata _tokenTicker,
        uint256 _index,
        uint256 _quantity,
        uint256 epoch,
        uint256 _tokenAmount,
        bool _isAddingLiquidity
    ) internal {
        for (uint256 epochIndex = epoch ; epochIndex <= epoch + _quantity - 1; epochIndex++) {
            if(_isAddingLiquidity) {
                hasBooster[_tokenTicker][_msgSender()][_index][epochIndex] = true;
                totalBoostedLiquidity[_tokenTicker][epochIndex] += _tokenAmount;
            }
            else {
                delete hasBooster[_tokenTicker][_msgSender()][_index][epochIndex];
                totalBoostedLiquidity[_tokenTicker][epochIndex] -= _tokenAmount;
            }
        }
    }

    function initNextEpochBlock(
        string memory _tokenTicker,
        uint256 epochLength
    ) public {
        require(_msgSender() == address(tokenBridgeRegistryUpgradeable), "ONLY_REGISTRY");
        nextEpochBlock[_tokenTicker] = block.number + epochLength - 1;
    }

    function _calculatePassedEpoch(
        string memory _tokenTicker
    ) internal returns (uint256, uint256) {
        uint256 passedEpochs;
        uint256 nextEpochStartBlock;
        if(block.number > nextEpochBlock[_tokenTicker]) {

            uint256 epochStartBlock;
            uint epochLength;
            (epochStartBlock, epochLength) = bridgeUtilsUpgradeable.getStartBlockAndEpochLength(_tokenTicker);

            if(epochs[_tokenTicker].length > 0) {
                Epoch memory epoch = epochs[_tokenTicker][epochs[_tokenTicker].length - 1];
                nextEpochStartBlock = epoch.startBlock + epoch.epochLength;
                passedEpochs = (block.number - nextEpochStartBlock) / epochLength;
                // nextEpochBlock[_tokenTicker] += passedEpochs * epochLength;
            } else {
                passedEpochs = (block.number - epochStartBlock) / epochLength;
                nextEpochStartBlock = epochStartBlock;
                // nextEpochBlock[_tokenTicker] = epochStartBlock + passedEpochs * epochLength - 1;
            }
            nextEpochBlock[_tokenTicker] += passedEpochs * epochLength;
        }
        return (passedEpochs, nextEpochStartBlock);
    }

    function _addPassedEpochs(
        string memory _tokenTicker
    ) internal {
        (uint256 passedEpochs, uint256 nextEpochStartBlock) = _calculatePassedEpoch(_tokenTicker);
        if(passedEpochs == 0)
            return;

        uint256 epochLength;
        (, epochLength) = bridgeUtilsUpgradeable.getStartBlockAndEpochLength(_tokenTicker);
        
        uint256 totalActiveLiquidity = totalLpLiquidity[_tokenTicker];

        uint256 noOfDepositors = bridgeUtilsUpgradeable.getNoOfDepositors(_tokenTicker);

        uint256 index;
        for (index = 0; index < passedEpochs - 1; index++) {
            Epoch memory epoch = Epoch({
                startBlock: nextEpochStartBlock + (index * epochLength),
                epochLength: epochLength,
                totalFeesCollected: 0, 
                totalActiveLiquidity: totalActiveLiquidity,
                noOfDepositors: noOfDepositors
            });
            epochs[_tokenTicker].push(epoch);
        }

        // pushing the last epoch
        uint256 feesInCurrentEpoch = feePoolUpgradeable.feesInCurrentEpoch(_tokenTicker);
        Epoch memory lastEpoch = Epoch({
            startBlock: nextEpochStartBlock + (index * epochLength),
            epochLength: epochLength,
            totalFeesCollected: feesInCurrentEpoch, 
            totalActiveLiquidity: totalActiveLiquidity,
            noOfDepositors: noOfDepositors
        });
        epochs[_tokenTicker].push(lastEpoch);

        feePoolUpgradeable.resetFeesInCurrentEpoch(_tokenTicker);
    }

    function addPassedEpochs(
        string memory _tokenTicker
    ) external {
        require(_msgSender() == address(feePoolUpgradeable));
        _addPassedEpochs(_tokenTicker);
    }

    function addLiquidity(
        string calldata _tokenTicker,
        uint256 _noOfTokens,
        uint256 _noOfBoosters
    ) public isBridgeActive(_tokenTicker) {
        require(_noOfTokens > 0, "NO_OF_TOKENS > 0");
        // adding any passed epochs
        _addPassedEpochs(_tokenTicker);

        uint256 epochStartIndex = 1;
        uint256 epochStartBlock;

        if(epochs[_tokenTicker].length > 0) {
            Epoch memory epoch = epochs[_tokenTicker][epochs[_tokenTicker].length - 1];
            epochStartIndex = epochs[_tokenTicker].length + 1;
            epochStartBlock = epoch.startBlock + epoch.epochLength;
        } else {
            // uint epochLength;
            // (epochStartBlock, epochLength) = tokenBridgeRegistryUpgradeable.getStartBlockAndEpochLength(_tokenTicker);
            // epochStartBlock = block.number - ((block.number - epochStartBlock) % epochLength);
            (epochStartBlock, ) = bridgeUtilsUpgradeable.getStartBlockAndEpochLength(_tokenTicker);
        }

        // Add new liquidity position
        LiquidityPosition memory position = LiquidityPosition({
            depositedAmount: _noOfTokens,
            blockNo: block.number,
            claimedTillEpochIndex: epochs[_tokenTicker].length,
            epochStartIndex: epochStartIndex,
            epochStartBlock: epochStartBlock,
            boosterEndEpochIndex: epochs[_tokenTicker].length,
            startTimestamp: block.timestamp
        });
        uint256 index = currentIndex[_tokenTicker][_msgSender()]++;
        liquidityPosition[_tokenTicker][_msgSender()][index] = position;

        totalLiquidity[_tokenTicker] += _noOfTokens; 
        totalLpLiquidity[_tokenTicker] += _noOfTokens; 
        tokenBridgeRegistryUpgradeable.updateNoOfDepositors(_tokenTicker, true);

        TokenUpgradeable token = getToken(_tokenTicker);
        token.transferFrom(_msgSender(), address(this), _noOfTokens);

        TokenUpgradeable setuToken = getToken(_concatenate("setu", _tokenTicker));
        setuToken.mintTokens(_msgSender(), _noOfTokens);
        // setuToken.transfer(_msgSender(), _noOfTokens);
        setuToken.lockTokens(_msgSender(), _noOfTokens);

        // to buy boosters along with adding the liquidity
        if(_noOfBoosters > 0) {
            buyBoosterPacks(_tokenTicker, index, _noOfBoosters);
        }

        // (string memory name, string memory imageUrl, ) = tokenBridgeRegistryUpgradeable.bridgeTokenMetadata(_tokenTicker);
        emit LiquidityAdded(index, _msgSender(), _tokenTicker, _noOfTokens);
    }

    function _concatenate(
        string memory a, 
        string memory b
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }

    function removeLiquidity(
        uint256 _index,
        string calldata _tokenTicker
    ) public isBridgeActive(_tokenTicker) {
        // adding any passed epochs
        _addPassedEpochs(_tokenTicker);

        LiquidityPosition memory position = liquidityPosition[_tokenTicker][_msgSender()][_index];
        require(position.depositedAmount > 0, "INVALID_POSITION");
        
        feePoolUpgradeable.transferLpFee(_tokenTicker, _msgSender(), _index);

        TokenUpgradeable setuToken = getToken(_concatenate("setu", _tokenTicker));
        setuToken.unlockToken(_msgSender(), position.depositedAmount);

        // Withdraw liquidity
        _withdrawLiquidity(_index, _tokenTicker);
    }

    // function _withdrawLiquidity(
    //     uint256 _index,
    //     string calldata _tokenTicker
    // ) internal {
    //     uint256 currentLiquidity = totalLiquidity[_tokenTicker];
    //     LiquidityPosition storage liquidityPos = liquidityPosition[_tokenTicker][_msgSender()][_index];
    //     uint256 noOfTokens = liquidityPos.depositedAmount;
    //     totalLpLiquidity[_tokenTicker] -= noOfTokens;
    //     uint256 currentEpochIndex = epochs[_tokenTicker].length + 1;
    //     if(liquidityPos.boosterEndEpochIndex >= currentEpochIndex) {
    //         _updateBoosterMapping(
    //             _tokenTicker,
    //             _index,
    //             liquidityPos.boosterEndEpochIndex - currentEpochIndex + 1,
    //             currentEpochIndex,
    //             noOfTokens,
    //             false
    //         );
    //     }

    //     // pool has less liquidity
    //     if(currentLiquidity < noOfTokens) {
    //         noOfTokens = currentLiquidity;
    //     }
        
    //     TokenUpgradeable setuToken = getToken(_concatenate("setu", _tokenTicker));
    //     setuToken.burnTokens(_msgSender(), noOfTokens);
        
    //     totalLiquidity[_tokenTicker] -= noOfTokens;
    //     tokenBridgeRegistryUpgradeable.updateNoOfDepositors(_tokenTicker, false);

    //     TokenUpgradeable token = getToken(_tokenTicker);
    //     token.transfer(_msgSender(), noOfTokens);
    //     // token.transferFrom(address(this), _msgSender(), noOfTokens);

    //     delete liquidityPosition[_tokenTicker][_msgSender()][_index];
    //     emit LiquidityRemoved(_index, _msgSender(), _tokenTicker, noOfTokens);
    // }

    function _withdrawLiquidity(
        uint256 _index,
        string calldata _tokenTicker
    ) internal {
        uint256 currentLiquidity = totalLiquidity[_tokenTicker];
        LiquidityPosition storage liquidityPos = liquidityPosition[_tokenTicker][_msgSender()][_index];
        uint256 noOfTokens = liquidityPos.depositedAmount;
        totalLpLiquidity[_tokenTicker] -= noOfTokens;
        uint256 currentEpochIndex = epochs[_tokenTicker].length + 1;
        if(liquidityPos.boosterEndEpochIndex >= currentEpochIndex) {
            _updateBoosterMapping(
                _tokenTicker,
                _index,
                liquidityPos.boosterEndEpochIndex - currentEpochIndex + 1,
                currentEpochIndex,
                noOfTokens,
                false
            );
        }
        delete liquidityPosition[_tokenTicker][_msgSender()][_index];
        
        TokenUpgradeable token = getToken(_tokenTicker);
        TokenUpgradeable setuToken = getToken(_concatenate("setu", _tokenTicker));
        
        tokenBridgeRegistryUpgradeable.updateNoOfDepositors(_tokenTicker, false);

        uint8 bridgeType = bridgeUtilsUpgradeable.getBridgeType(_tokenTicker);
        
        uint256 noOfTokensAvailable = noOfTokens;
        // pool has less liquidity
        if(currentLiquidity < noOfTokens) {
            noOfTokensAvailable = currentLiquidity;
        }

        if(noOfTokensAvailable > 0) {
            totalLiquidity[_tokenTicker] -= noOfTokensAvailable;
            token.transfer(_msgSender(), noOfTokensAvailable);
        }
        // 0 - liquidity bridge, 1 - child + liquidity bridge
        if(bridgeType == 0) {
            setuToken.burnTokens(_msgSender(), noOfTokensAvailable);
            emit LiquidityRemoved(_index, _msgSender(), _tokenTicker, noOfTokensAvailable);
        } 
        else if(bridgeType == 1) {
            setuToken.burnTokens(_msgSender(), noOfTokens);
            token.mintTokens(_msgSender(), noOfTokens - noOfTokensAvailable);
            emit LiquidityRemoved(_index, _msgSender(), _tokenTicker, noOfTokens);
        }

        // delete liquidityPosition[_tokenTicker][_msgSender()][_index];
    }

    // initiate bridge transaction on the source chain
    function transferIn(
        string calldata _tokenTicker,
        uint256 _noOfTokens,
        uint8 _toChainId,
        uint256 _gasPrice
    ) public isBridgeActive(_tokenTicker) returns (bool, uint256) {
        require(_noOfTokens > 0, "IA");
        TokenUpgradeable token = getToken(_tokenTicker);
        token.transferFrom(_msgSender(), address(this), _noOfTokens);
        
        TokenUpgradeable setuToken = getToken(_concatenate("setu", _tokenTicker));
        setuToken.mintTokens(_msgSender(), _noOfTokens);
        
        uint8 bridgeType = bridgeUtilsUpgradeable.getBridgeType(_tokenTicker);
        if(bridgeType == 0) {
            totalLiquidity[_tokenTicker] += _noOfTokens;
        }
        if(bridgeType == 1) {
            token.burnTokens(_msgSender(), _noOfTokens);
        }

        return crossChainTransferOut(_tokenTicker, _noOfTokens, _toChainId, _gasPrice);
    }

    function crossChainTransferOut(
        string memory _tokenTicker,
        uint256 _noOfTokens,
        uint8 _toChainId,
        uint256 _gasPrice
    ) public isBridgeActive(_tokenTicker) returns (bool, uint256) {
        // adding any passed epochs
        _addPassedEpochs(_tokenTicker);

        TokenUpgradeable setuToken = getToken(_concatenate("setu", _tokenTicker));
        setuToken.burnTokens(_msgSender(), _noOfTokens);

        bytes32 key = keccak256(abi.encode(_tokenTicker, _msgSender(), chainId, _toChainId));
        uint256 transferIndex = currentTransferIndex[key];
        ++currentTransferIndex[key];
        // bytes4 _interface = bytes4(keccak256("createCrossChainTransferMapping(address,uint256,string,uint256,uint8)"));
        // bytes memory data = abi.encode(_msgSender(), _noOfTokens, _tokenTicker, transferIndex, chainId);
        // ChainID - Selector - Data - Gas Usage - Gas Price
        (bool success, ) = routerSend(
                            _toChainId, 
                            bytes4(keccak256("createCrossChainTransferMapping(address,uint256,string,uint256,uint8)")), 
                            abi.encode(_msgSender(), _noOfTokens, _tokenTicker, transferIndex, chainId), 
                            crossChainGas, 
                            _gasPrice
                        );
        require(success, "ROUTER_ERROR");

        // // ( , string memory imageUrl, ) = tokenBridgeRegistryUpgradeable.bridgeTokenMetadata(_tokenTicker);
        emit BridgeTransaction(transferIndex, chainId, _toChainId, _msgSender(), _tokenTicker, _noOfTokens, 1);

        return (success, transferIndex);
        // addTransferMap(_tokenTicker, _noOfTokens, _toChainId);
        // return (true, transferIndex);
    }

    // function addTransferMap(string memory _tokenTicker, uint256 _noOfTokens, uint8 _toChainId) internal {
    //     // Create Transfer Mapping
    //     // TransferMapping memory transfer = TransferMapping({
    //     //     userAddress: _msgSender(),
    //     //     noOfTokens: _noOfTokens
    //     // });
    //     // transferMapping[_tokenTicker][currentTransferIndex[_tokenTicker][_msgSender()] - 1] = transfer;
    //     transferMapping[_tokenTicker][_msgSender()][chainId][currentTransferIndex[_tokenTicker][_msgSender()][_toChainId] - 1] = _noOfTokens;
    // }

    function _routerSyncHandler(
        bytes4 _interface,
        bytes memory _data
    ) internal virtual override  returns ( bool , bytes memory )
    {
        (address userAddress, uint256 noOfTokens, string memory tokenTicker, uint256 transferIndex, uint8 fromChain) = abi.decode(_data, (address, uint256, string, uint256, uint8));
        (bool success, bytes memory returnData) = 
            address(this).call( abi.encodeWithSelector(_interface, userAddress, noOfTokens, tokenTicker, transferIndex, fromChain));
        return (success, returnData);
    }

    function replayTransaction(
        bytes32 hash,
        uint256 _crossChainGasPrice
    ) external onlyOwner {
        routerReplay(
            hash,
            crossChainGas,
            _crossChainGasPrice
        );
    }

    function createCrossChainTransferMapping(
        address _userAddress,
        uint256 _noOfTokens,
        string calldata _tokenTicker,
        uint256 _transferIndex,
        uint8 _fromChain
    ) external isSelf {
        bytes32 indexKey = keccak256(abi.encode(_tokenTicker, _userAddress, _fromChain, chainId));
        require(_transferIndex == currentTransferIndex[indexKey], "INVALID_TRANSFER_INDEX");
        
        // Create Transfer Mapping
        // TransferMapping memory transfer = TransferMapping({
        //     userAddress: _userAddress,
        //     noOfTokens: _noOfTokens
        // });
        // transferMapping[_tokenTicker][currentTransferIndex[_tokenTicker][_userAddress][chainId]++] = transfer;
        bytes32 key = keccak256(abi.encode(_tokenTicker, _userAddress, _fromChain, chainId, currentTransferIndex[indexKey]++));
        transferMapping[key] = _noOfTokens;
        // transferMapping[_tokenTicker][_userAddress][_fromChain][chainId][currentTransferIndex[_tokenTicker][_userAddress][_fromChain][chainId]++] = _noOfTokens;

        emit BridgeTransaction(_transferIndex, _fromChain, chainId, _userAddress, _tokenTicker, _noOfTokens, 2);
    }

    function crossChainTransferIn(
        // address _userAddress,
        uint256 _noOfTokens,
        string calldata _tokenTicker,
        uint256 _index,
        uint8 _fromChain
    ) public payable isBridgeActive(_tokenTicker) {
        // require(transferMapping[_tokenTicker][_index].userAddress != address(0), "TRANSFER_MAPPING_NOT_EXISTS");
        // require(transferMapping[_tokenTicker][_index].userAddress == _msgSender(), "NOT_OWNER");
        // require(_noOfTokens <= transferMapping[_tokenTicker][_index].noOfTokens, "EXCESS_TOKENS_REQUESTED");
        bytes32 key = keccak256(abi.encode(_tokenTicker, _msgSender(), _fromChain, chainId, _index));
        require(transferMapping[key] > 0, "TMNE");  // TRANSFER_MAPPING_NOT_EXISTS
        require(_noOfTokens <= transferMapping[key], "ETR");    // EXCESS_TOKENS_REQUESTED

        TokenUpgradeable setuToken = getToken(_concatenate("setu", _tokenTicker));
        setuToken.mintTokens(_msgSender(), _noOfTokens);
        
        // transferMapping[_tokenTicker][_index].noOfTokens -= _noOfTokens;
        // if(transferMapping[_tokenTicker][_index].noOfTokens == 0) {
        //     delete transferMapping[_tokenTicker][_index];
        // }
        transferMapping[key] -= _noOfTokens;
        // if(transferMapping[key] == 0) {
        //     delete transferMapping[key];
        // }

        transferOut(_noOfTokens, _tokenTicker);

        emit BridgeTransaction(_index, _fromChain, chainId, _msgSender(), _tokenTicker, _noOfTokens, 3);
    }

    function transferOut(
        // address _userAddress,
        uint256 _noOfTokens,
        string calldata _tokenTicker
    ) public payable isBridgeActive(_tokenTicker) {
        // adding any passed epochs
        _addPassedEpochs(_tokenTicker);

        TokenUpgradeable setuToken = getToken(_concatenate("setu", _tokenTicker));
        TokenUpgradeable token = getToken(_tokenTicker);
        
        uint8 bridgeType = bridgeUtilsUpgradeable.getBridgeType(_tokenTicker);
        
        uint256 currentLiquidity = totalLiquidity[_tokenTicker];
        uint256 noOfTokens = _noOfTokens;
        // pool has less liquidity
        if(currentLiquidity < _noOfTokens) {
            noOfTokens = currentLiquidity;
        }

        // 0 - liquidity bridge, 1 - child + liquidity bridge
        if(bridgeType == 0) {
            uint256 feesDeducted = _calculateBridgingFees(_tokenTicker, noOfTokens);
            setuToken.burnTokens(_msgSender(), noOfTokens);
            totalLiquidity[_tokenTicker] -= noOfTokens;
            if(noOfTokens - feesDeducted > 0)
                token.transfer(_msgSender(), noOfTokens - feesDeducted);
            if(feesDeducted > 0) {
                token.transfer(address(feePoolUpgradeable), feesDeducted);
            }
        } 
        else if(bridgeType == 1) {
            uint256 feesDeducted = _calculateBridgingFees(_tokenTicker, _noOfTokens);
            setuToken.burnTokens(_msgSender(), _noOfTokens);
            totalLiquidity[_tokenTicker] -= noOfTokens;

            if(noOfTokens < feesDeducted) {
                // transfer the available tokens from the liquidity pool
                if(noOfTokens > 0)
                    token.transfer(_msgSender(), noOfTokens);
                token.mintTokens(_msgSender(), _noOfTokens - noOfTokens - feesDeducted);
                if(feesDeducted > 0) {
                    token.mintTokens(address(feePoolUpgradeable), feesDeducted);
                }
            }
            else {
                if(feesDeducted > 0) {
                    token.transfer(address(feePoolUpgradeable), feesDeducted);
                }
                // transfer the available tokens from the liquidity pool
                if(noOfTokens - feesDeducted > 0)
                    token.transfer(_msgSender(), noOfTokens - feesDeducted);
                token.mintTokens(_msgSender(), _noOfTokens - noOfTokens);
            }
        }
    }

    function _calculateBridgingFees(
        string calldata _tokenTicker,
        uint256 _noOfTokens
    ) internal returns (uint256) {
        uint8 feeType;
        uint256 feeInBips;
        uint256 fees;
        (feeType, feeInBips) = bridgeUtilsUpgradeable.getFeeTypeAndFeeInBips(_tokenTicker);

        // fee in native chain token
        if(feeType == 0) {
            require(msg.value >= feeInBips, "INSUFFICIENT_FEES");
            feePoolUpgradeable.updateTotalFees(_tokenTicker, feeInBips, true);
            (bool success, ) = address(feePoolUpgradeable).call{value: feeInBips}("");
            require(success, "PTF");    // POOL_TRANFER_FAILED
            // payable(address(feePoolUpgradeable)).transfer(feeInBips);

            // (success, ) = _msgSender().call{value: msg.value - feeInBips}("");
            // require(success, "SENT_BACK_FAILED");
            payable(_msgSender()).transfer(msg.value - feeInBips);
        }
        else if(feeType == 1) {
            fees = _noOfTokens * feeInBips / maxBips;
            feePoolUpgradeable.updateTotalFees(_tokenTicker, fees, true);
        }

        return fees;
    }

    function safeWithdrawLiquidity(
        string calldata _tokenTicker,
        uint256 _noOfTokens
    ) external onlyOwner {
        // require(_noOfTokens <= totalLiquidity[_tokenTicker], "AMOUNT_OVERFLOW");
        // totalLiquidity[_tokenTicker] -= _noOfTokens;

        TokenUpgradeable token = getToken(_tokenTicker);
        token.transfer(owner(), _noOfTokens);
    }

    function getEpochsLength(string memory _tokenTicker) public view returns (uint256) {
        return epochs[_tokenTicker].length;
    }

    function deleteHasBoosterMapping(
        string memory _tokenTicker,
        address _account,
        uint256 _index,
        uint256 epochIndex
    ) public {
        require(_msgSender() == address(feePoolUpgradeable), "ONLY_FEE_POOL");
        delete hasBooster[_tokenTicker][_account][_index][epochIndex];
    }

    function updateRewardClaimedTillIndex(
        string memory _tokenTicker,
        address _account,
        uint256 _index
        // uint256 epochIndex
    ) public {
        require(_msgSender() == address(feePoolUpgradeable), "ONLY_FEE_POOL");
        liquidityPosition[_tokenTicker][_account][_index].claimedTillEpochIndex = epochs[_tokenTicker].length;
    }

    // function getBackTokens(address tokenAddress) external onlyOwner {
    //     IERC20 token = IERC20(tokenAddress);
    //     token.transfer(_msgSender(), token.balanceOf(address(this)));
    // }

    // function getBackNativeTokens() external onlyOwner {
    //     (bool success, ) = _msgSender().call{value: address(this).balance}("");
    //     require(success, "TRANSFER_FAILED");
    // }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./TokenBridgeRegistryUpgradeable.sol";
import "./BridgeUpgradeable.sol";
import "./FeePoolUpgradeable.sol";
import "./RegistryStorage.sol";
import "./BridgeStorage.sol";

contract BridgeUtilsUpgradeable is Initializable, OwnableUpgradeable, RegistryStorage, BridgeStorage {

    TokenBridgeRegistryUpgradeable public tokenBridgeRegistryUpgradeable;

    BridgeUpgradeable public bridgeUpgradeable;

    FeePoolUpgradeable public feePoolUpgradeable;

    function initialize(
        TokenBridgeRegistryUpgradeable _tokenBridgeRegistryUpgradeable, 
        BridgeUpgradeable _bridgeUpgradeable, 
        FeePoolUpgradeable _feePoolUpgradeable
    ) public initializer {
        __Ownable_init();
        tokenBridgeRegistryUpgradeable = _tokenBridgeRegistryUpgradeable;
        bridgeUpgradeable = _bridgeUpgradeable;
        feePoolUpgradeable = _feePoolUpgradeable;
    }

    function updateRegistryAddress(TokenBridgeRegistryUpgradeable _registryAddress) external onlyOwner {
        tokenBridgeRegistryUpgradeable = _registryAddress;
    }

    function updateBridgeAddress(BridgeUpgradeable _bridgeAddress) external onlyOwner {
        bridgeUpgradeable = _bridgeAddress;
    }
    
    function updateFeePoolAddress(FeePoolUpgradeable _feePoolAddress) external onlyOwner {
        feePoolUpgradeable = _feePoolAddress;
    }

    function getEpochLength(string calldata _tokenTicker) public view returns (uint256) {
        (
            ,
            ,
            ,
            uint256 epochLength,
            ,
            ,
            
        ) = tokenBridgeRegistryUpgradeable.tokenBridge(_tokenTicker);
        return epochLength;
    }

    function getStartBlockAndEpochLength(string calldata _tokenTicker) public view returns (uint256, uint256) {
        (
            ,
            ,
            uint256 startBlock,
            uint256 epochLength,
            ,
            ,
            
        ) = tokenBridgeRegistryUpgradeable.tokenBridge(_tokenTicker);
        return (startBlock, epochLength);
    } 

    function getTokenAddress(string calldata _tokenTicker) public view returns (address) {
        (
            ,
            ,
            address tokenAddress
        ) = tokenBridgeRegistryUpgradeable.bridgeTokenMetadata(_tokenTicker);
        return tokenAddress;
    }

    function getBridgeType(string calldata _tokenTicker) public view returns (uint8) {
        (
            uint8 bridgeType,
            ,
            ,
            ,
            ,
            ,
            
        ) = tokenBridgeRegistryUpgradeable.tokenBridge(_tokenTicker);
        return bridgeType;
    }

    function isTokenBridgeActive(string calldata _tokenTicker) public view returns (bool) {
        (
            ,
            ,
            ,
            ,
            ,
            ,
            bool isActive
        ) = tokenBridgeRegistryUpgradeable.tokenBridge(_tokenTicker);
        return isActive;
    }

    function getFeeTypeAndFeeInBips(string calldata _tokenTicker) public view returns (uint8, uint256) {
        (
            ,
            ,
            ,
            ,
            FeeConfig memory fee,
            ,
            
        ) = tokenBridgeRegistryUpgradeable.tokenBridge(_tokenTicker);
        return (fee.feeType, fee.feeInBips);
    }

    function getNoOfDepositors(string calldata _tokenTicker) public view returns (uint256) {
        (
            ,
            ,
            ,
            ,
            ,
            uint256 noOfDepositors,
            
        ) = tokenBridgeRegistryUpgradeable.tokenBridge(_tokenTicker);
        return noOfDepositors;
    }



    function getUserTotalDeposit(
        string calldata tokenTicker,
        address account,
        uint256 index
    ) public view returns (uint256) {
        (
            uint256 depositedAmount,
            ,
            ,
            ,
            ,
            ,
            
        ) = bridgeUpgradeable.liquidityPosition(tokenTicker, account, index);
        return depositedAmount;
    }

    function getEpochTotalDepositors(
        string memory _tokenTicker,
        uint256 _epochIndex
    ) public view returns (uint256) {
        (
            ,
            ,
            ,
            ,
            uint256 noOfDepositors
        ) = bridgeUpgradeable.epochs(_tokenTicker, _epochIndex - 1);
        return noOfDepositors;
    } 

    function getEpochTotalFees(
        string memory _tokenTicker,
        uint256 _epochIndex
    ) public view returns (uint256) {
        (
            ,
            ,
            uint256 totalFeesCollected,
            ,
            
        ) = bridgeUpgradeable.epochs(_tokenTicker, _epochIndex-1);
        return totalFeesCollected;
    } 

    function getCurrentTransferIndexHash(
        string calldata _tokenTicker,
        address _userAddress,
        uint8 _fromChainId,
        uint8 _toChainId
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(_tokenTicker, _userAddress, _fromChainId, _toChainId));
    }

    function getTransferMappingHash(
        string calldata _tokenTicker,
        address _userAddress,
        uint8 _fromChainId,
        uint8 _toChainId,
        uint256 _index
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(_tokenTicker, _userAddress, _fromChainId, _toChainId, _index));
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

contract TokenUpgradeable is Initializable, ERC20Upgradeable, OwnableUpgradeable, PausableUpgradeable {

    address public admin;
    mapping(address => uint256) public lockedTokens;
    uint8 private _decimals;

    /**
     * @dev Throws if called by any account other than the master.
     */
    modifier onlyAdmin() {
        require(admin == _msgSender(), "NOT_ADMIN");
        _;
    }

    function initialize(
        string calldata _name, 
        string calldata _ticker, 
        uint8 _decimal, 
        address _admin
    ) public initializer {
        require(_admin != address(0), "INVALID_ADMIN");
        __ERC20_init(_name, _ticker);
        __Ownable_init();
        __Pausable_init();
        admin = _admin;
        _decimals = _decimal;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function mintTokens(address to, uint256 amount) public onlyOwner whenNotPaused {
        _mint(to, amount);
    }

    function burnTokens(address from, uint256 amount) public onlyOwner whenNotPaused {
        _burn(from, amount);
    }

    function renounceOwnership() public override onlyAdmin {
        _transferOwnership(admin);
    }

    function transferAdminOwnership(address _newAdmin) public onlyAdmin {
        require(_newAdmin != address(0), "INVALID_ADMIN");
        admin = _newAdmin;
    }
    
    function pauseTokens() public onlyOwner whenNotPaused {
        _pause();
    }

    function unpauseTokens() public onlyOwner whenPaused {
        _unpause();
    }

    /**
    * @notice lock the token of any token holder.
    * @dev balance should be greater than amount. function will revert will balance is less than amount.
    * @param holder the addrress of token holder.
    * @param amount number of tokens to burn.
    * @return true when lockToken succeeded.
    */

    function lockTokens(address holder, uint256 amount) external onlyOwner whenNotPaused returns (bool) {
        require(balanceOf(holder) >= amount, "INSUFFICIENT_BALANCE");

        // _balances[holder] = _balances[holder].sub(amount);
        burnTokens(holder, amount);
        lockedTokens[holder] += amount;

        return true;
    }

    /**
    * @notice unLock the token of any token holder.
    * @dev locked balance should be greater than amount. function will revert will locked balance is less than amount.
    * @param holder the addrress of token holder.
    * @param amount number of tokens to burn.
    * @return true when unLockToken succeeded.
    */

    function unlockToken(address holder, uint256 amount) external onlyOwner whenNotPaused returns (bool) {
        require(lockedTokens[holder] >= amount, "INSUFFICIENT_LOCKED_TOKENS");

        lockedTokens[holder] -= amount;
        mintTokens(holder, amount);

        return true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/transparent/ProxyAdmin.sol)

pragma solidity ^0.8.0;

import "./TransparentUpgradeableProxy.sol";
import "../../access/Ownable.sol";

/**
 * @dev This is an auxiliary contract meant to be assigned as the admin of a {TransparentUpgradeableProxy}. For an
 * explanation of why you would want to use this see the documentation for {TransparentUpgradeableProxy}.
 */
contract ProxyAdmin is Ownable {
    /**
     * @dev Returns the current implementation of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyImplementation(TransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("implementation()")) == 0x5c60da1b
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"5c60da1b");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Returns the current admin of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyAdmin(TransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("admin()")) == 0xf851a440
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"f851a440");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Changes the admin of `proxy` to `newAdmin`.
     *
     * Requirements:
     *
     * - This contract must be the current admin of `proxy`.
     */
    function changeProxyAdmin(TransparentUpgradeableProxy proxy, address newAdmin) public virtual onlyOwner {
        proxy.changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrades `proxy` to `implementation`. See {TransparentUpgradeableProxy-upgradeTo}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgrade(TransparentUpgradeableProxy proxy, address implementation) public virtual onlyOwner {
        proxy.upgradeTo(implementation);
    }

    /**
     * @dev Upgrades `proxy` to `implementation` and calls a function on the new implementation. See
     * {TransparentUpgradeableProxy-upgradeToAndCall}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgradeAndCall(
        TransparentUpgradeableProxy proxy,
        address implementation,
        bytes memory data
    ) public payable virtual onlyOwner {
        proxy.upgradeToAndCall{value: msg.value}(implementation, data);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/transparent/TransparentUpgradeableProxy.sol)

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967Proxy.sol";

/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 *
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 *
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 */
contract TransparentUpgradeableProxy is ERC1967Proxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {ERC1967Proxy-constructor}.
     */
    constructor(
        address _logic,
        address admin_,
        bytes memory _data
    ) payable ERC1967Proxy(_logic, _data) {
        _changeAdmin(admin_);
    }

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _getAdmin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function admin() external ifAdmin returns (address admin_) {
        admin_ = _getAdmin();
    }

    /**
     * @dev Returns the current implementation.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation() external ifAdmin returns (address implementation_) {
        implementation_ = _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
     */
    function changeAdmin(address newAdmin) external virtual ifAdmin {
        _changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newImplementation) external ifAdmin {
        _upgradeToAndCall(newImplementation, bytes(""), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable ifAdmin {
        _upgradeToAndCall(newImplementation, data, true);
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view virtual returns (address) {
        return _getAdmin();
    }

    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal virtual override {
        require(msg.sender != _getAdmin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        super._beforeFallback();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract RegistryStorage {

    struct BridgeTokenMetadata {
        string name;
        string imageUrl;
        address tokenAddress;
    }
    
    // ticker => BridgeTokenMetadata
    mapping(string => BridgeTokenMetadata) public bridgeTokenMetadata;


    struct FeeConfig {
        uint8 feeType; //0: parent chain; 1: % of tokens
        uint256 feeInBips;
    }

    struct TokenBridge {
        uint8 bridgeType;
        string tokenTicker;
        uint256 startBlock;
        uint256 epochLength;
        FeeConfig fee;
        // uint256 totalFeeCollected;
        // uint256 totalActiveLiquidity;
        uint256 noOfDepositors;
        bool isActive;
    }
    // tokenTicker => TokenBridge
    mapping(string => TokenBridge) public tokenBridge;

    // array of all the token tickers
    string[] public tokenBridges;

    bool public isBridgeActive;

    uint256[100] private __gap;

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/ERC1967/ERC1967Proxy.sol)

pragma solidity ^0.8.0;

import "../Proxy.sol";
import "./ERC1967Upgrade.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 */
contract ERC1967Proxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializing the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        _upgradeToAndCall(_logic, _data, false);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";

import "./interfaces/iGenericHandler.sol";
import "./interfaces/iRouterCrossTalkUpgradeable.sol";

/// @title RouterCrossTalkUpgradeable contract
/// @author Router Protocol
abstract contract RouterCrossTalkUpgradeable is
  Initializable,
  ContextUpgradeable,
  iRouterCrossTalkUpgradeable,
  ERC165Upgradeable
{
  using SafeERC20Upgradeable for IERC20Upgradeable;
  iGenericHandler private handler;

  address private linkSetter;

  address private feeToken;

  mapping(uint8 => address) private Chain2Addr; // CHain ID to Address

  mapping(bytes32 => ExecutesStruct) private executes;

  modifier isHandler() {
    require(
      _msgSender() == address(handler),
      "RouterSync : Only GenericHandler can call this function"
    );
    _;
  }

  modifier isLinkSet(uint8 _chainID) {
    require(
      Chain2Addr[_chainID] == address(0),
      "RouterSync : Cross Chain Contract to Chain ID set"
    );
    _;
  }

  modifier isLinkUnSet(uint8 _chainID) {
    require(
      Chain2Addr[_chainID] != address(0),
      "RouterCrossTalk : Cross Chain Contract to Chain ID is not set"
    );
    _;
  }

  modifier isLinkSync(uint8 _srcChainID, address _srcAddress) {
    require(
      Chain2Addr[_srcChainID] == _srcAddress,
      "RouterSync : Source Address Not linked"
    );
    _;
  }

  modifier isSelf() {
    require(
      _msgSender() == address(this),
      "RouterCrossTalk : Can only be called by Current Contract"
    );
    _;
  }

  function __RouterCrossTalkUpgradeable_init(address _handler)
    internal
    initializer
  {
    __Context_init_unchained();

    handler = iGenericHandler(_handler);
  }

  function __RouterCrossTalkUpgradeable_init_unchained() internal initializer {}

  ///  @notice Used to set linker address, this function is internal and can only be set by contract owner or admins
  /// @param _addr Address of linker.
  function setLink(address _addr) internal {
    linkSetter = _addr;
  }

  /// @notice Used to set fee Token address, this function is internal and can only be set by contract owner or admins
  /// @param _addr Address of linker.
  function setFeeToken(address _addr) internal {
    feeToken = _addr;
  }

  function fetchHandler() external view override returns (address) {
    return address(handler);
  }

  function fetchLinkSetter() external view override returns (address) {
    return linkSetter;
  }

  function fetchLink(uint8 _chainID) external view override returns (address) {
    return Chain2Addr[_chainID];
  }

  function fetchFeeToken() external view override returns (address) {
    return feeToken;
  }

  function fetchExecutes(bytes32 hash)
    external
    view
    override
    returns (ExecutesStruct memory)
  {
    return executes[hash];
  }

  /// @notice routerSend This is internal function to generate a cross chain communication request.
  /// @param destChainId Destination ChainID.
  /// @param _selector Selector to interface on destination side.
  /// @param _data Data to be sent on Destination side.
  /// @param _gasLimit Gas limit provided for cross chain send.
  /// @param _gasPrice Gas price provided for cross chain send.
  function routerSend(
    uint8 destChainId,
    bytes4 _selector,
    bytes memory _data,
    uint256 _gasLimit,
    uint256 _gasPrice
  ) internal isLinkUnSet(destChainId) returns (bool, bytes32) {
    bytes memory data = abi.encode(_selector, _data);
    uint64 nonce = handler.genericDeposit(
      destChainId,
      data,
      _gasLimit,
      _gasPrice,
      feeToken
    );

    bytes32 hash = _hash(destChainId, nonce);

    executes[hash] = ExecutesStruct(destChainId, nonce);
    emitCrossTalkSendEvent(destChainId, _selector, _data, hash);

    return (true, hash);
  }

  function emitCrossTalkSendEvent(
    uint8 destChainId,
    bytes4 selector,
    bytes memory data,
    bytes32 hash
  ) private {
    emit CrossTalkSend(
      handler.fetch_chainID(),
      destChainId,
      address(this),
      Chain2Addr[destChainId],
      selector,
      data,
      hash
    );
  }

  function routerSync(
    uint8 srcChainID,
    address srcAddress,
    bytes memory data
  )
    external
    override
    isLinkSync(srcChainID, srcAddress)
    isHandler
    returns (bool, bytes memory)
  {
    uint8 cid = handler.fetch_chainID();
    (bytes4 _selector, bytes memory _data) = abi.decode(data, (bytes4, bytes));

    (bool success, bytes memory _returnData) = _routerSyncHandler(
      _selector,
      _data
    );
    emit CrossTalkReceive(srcChainID, cid, srcAddress);
    return (success, _returnData);
  }

  function routerReplay(
    bytes32 hash,
    uint256 _gasLimit,
    uint256 _gasPrice
  ) internal {
    handler.replayGenericDeposit(
      executes[hash].chainID,
      executes[hash].nonce,
      _gasLimit,
      _gasPrice
    );
  }

  /// @notice _hash This is internal function to generate the hash of all data sent or received by the contract.
  /// @param _destChainId Destination ChainID.
  /// @param _nonce Nonce for the tx.
  function _hash(uint8 _destChainId, uint64 _nonce)
    internal
    pure
    returns (bytes32)
  {
    return keccak256(abi.encode(_destChainId, _nonce));
  }

  function Link(uint8 _chainID, address _linkedContract)
    external
    override
    isHandler
    isLinkSet(_chainID)
  {
    Chain2Addr[_chainID] = _linkedContract;
    emit Linkevent(_chainID, _linkedContract);
  }

  function Unlink(uint8 _chainID) external override isHandler {
    emit Unlinkevent(_chainID, Chain2Addr[_chainID]);
    Chain2Addr[_chainID] = address(0);
  }

  function approveFees(address _feeToken, uint256 _value) internal {
    IERC20Upgradeable token = IERC20Upgradeable(_feeToken);
    token.approve(address(handler), _value);
  }

  /// @notice _routerSyncHandler This is internal function to control the handling of various selectors and its corresponding .
  /// @param _selector Selector to interface.
  /// @param _data Data to be handled.
  function _routerSyncHandler(bytes4 _selector, bytes memory _data)
    internal
    virtual
    returns (bool, bytes memory);

  uint256[100] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract BridgeStorage {

    struct LiquidityPosition {
        uint256 depositedAmount;
        uint256 blockNo;
        uint256 claimedTillEpochIndex;
        uint256 epochStartIndex;
        uint256 epochStartBlock;
        uint256 boosterEndEpochIndex;
        uint256 startTimestamp;
    }

    // tokenTicker => userAddress => index => LiquidityPosition
    mapping(string => mapping(address => mapping(uint256 => LiquidityPosition))) public liquidityPosition;
    // tokenTicker => userAddress => index => epochIndex => hasBooster
    mapping(string => mapping(address => mapping(uint256 => mapping(uint256 => bool)))) public hasBooster;
    // tokenTicker => userAddress => index
    mapping(string => mapping(address => uint256)) public currentIndex;
    // tokenTicker => totalLiquidity
    mapping(string => uint256) public totalLiquidity;
    // tokenTicker => totalLiquidity
    mapping(string => uint256) public totalLpLiquidity;
    // tokenTicker => epochIndex => totalBoostedLiquidity
    mapping(string => mapping(uint256 => uint256)) public totalBoostedLiquidity;

    // to create a mapping for verifying the cross chain transfer
    // struct TransferMapping {
    //     address userAddress;
    //     uint256 noOfTokens;
    // }
    // tokenTicker => index => TransferMapping
    // mapping(string => mapping(uint256 => TransferMapping)) public transferMapping;
    // tokenTicker => userAddress => srcChain => destChain => index => noOfTokens
    // mapping(string => mapping(address => mapping(uint8 => mapping(uint8 => mapping(uint256 => uint256))))) public transferMapping;
    mapping(bytes32 => uint256) public transferMapping;

    // unique for each transfer mapping
    // tokenTicker => userAddress => srcChain => destChain => index
    // mapping(string => mapping(address => mapping(uint8 => mapping(uint8 => uint256)))) public currentTransferIndex;
    mapping(bytes32 => uint256) public currentTransferIndex;

    struct Epoch {
        uint256 startBlock;
        uint256 epochLength;
        uint256 totalFeesCollected;
        uint256 totalActiveLiquidity;
        uint256 noOfDepositors;
    }
    // tokenTicker => Epoch[]
    mapping(string => Epoch[]) public epochs;

    // to recalculate the fees and totalLiquidity once epoch ends
    // (updated on the first call after epoch ends)
    // ticker => nextEpochBlock
    mapping(string => uint256) public nextEpochBlock;

    // mapping(string => uint256) public adminClaimedTillEpoch;

    // minimum fee can be 0.1% (= 1 bip), so 100% = 1000bips (=maxBips)
    uint256 public maxBips;

    uint256 public crossChainGas;

    struct BoosterConfig {
        // uint8 tokenType;
        address tokenAddress;
        uint256 price;
        string imageUrl;
        address adminAccount;
    }
    BoosterConfig public boosterConfig;

    uint8 public chainId;

    uint256[100] private __gap;

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title GenericHandler contract interface for router Crosstalk
/// @author Router Protocol
interface iGenericHandler {
  struct RouterLinker {
    address _rSyncContract;
    uint8 _chainID;
    address _linkedContract;
  }

  /// @notice MapContract Maps the contract from the RouterCrossTalk Contract
  /// @dev This function is used to map contract from router-crosstalk contract
  /// @param linker The Data object consisting of target Contract , CHainid , Contract to be Mapped and linker type.
  function MapContract(RouterLinker calldata linker) external;

  /// @notice UnMapContract Unmaps the contract from the RouterCrossTalk Contract
  /// @dev This function is used to unmap contract from router-crosstalk contract
  /// @param linker The Data object consisting of target Contract , CHainid , Contract to be unMapped and linker type.
  function UnMapContract(RouterLinker calldata linker) external;

  /// @notice generic deposit on generic handler contract
  /// @dev This function is called by router crosstalk contract while initiating crosschain transaction
  /// @param _destChainID Chain id to be transacted
  /// @param _data Data to be transferred: contains abi encoded selector and data
  /// @param _gasLimit Gas limit specified for the contract function
  /// @param _gasPrice Gas price specified for the contract function
  /// @param _feeToken Fee Token Specified for the contract function
  function genericDeposit(
    uint8 _destChainID,
    bytes calldata _data,
    uint256 _gasLimit,
    uint256 _gasPrice,
    address _feeToken
  ) external returns (uint64);

  /// @notice Fetches ChainID for the native chain
  function fetch_chainID() external view returns (uint8);

  /// @notice Function to replay a transaction which was stuck due to underpricing of gas
  /// @param  _destChainID Destination ChainID
  /// @param  _depositNonce Nonce for the transaction.
  /// @param  _gasLimit Gas limit allowed for the transaction.
  /// @param  _gasPrice Gas Price for the transaction.
  function replayGenericDeposit(
    uint8 _destChainID,
    uint64 _depositNonce,
    uint256 _gasLimit,
    uint256 _gasPrice
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

/// @title iRouterCrossTalk contract interface for router Crosstalk
/// @author Router Protocol
interface iRouterCrossTalkUpgradeable is IERC165Upgradeable {
  struct ExecutesStruct {
    uint8 chainID;
    uint64 nonce;
  }

  /// @notice Link event is emitted when a new link is created.
  /// @param ChainID Chain id the contract is linked to.
  /// @param linkedContract Contract address linked to.
  event Linkevent(uint8 indexed ChainID, address indexed linkedContract);

  /// @notice UnLink event is emitted when a link is removed.
  /// @param ChainID Chain id the contract is unlinked to.
  /// @param linkedContract Contract address unlinked to.
  event Unlinkevent(uint8 indexed ChainID, address indexed linkedContract);

  /// @notice CrossTalkSend Event is emited when a request is generated in soruce side when cross chain request is generated.
  /// @param sourceChain Source ChainID.
  /// @param destChain Destination ChainID.
  /// @param sourceAddress Source Address.
  /// @param destinationAddress Destination Address.
  /// @param _selector Selector to interface on destination side.
  /// @param _data Data to interface on Destination side.
  /// @param _hash Hash of the data sent.
  event CrossTalkSend(
    uint8 indexed sourceChain,
    uint8 indexed destChain,
    address sourceAddress,
    address destinationAddress,
    bytes4 indexed _selector,
    bytes _data,
    bytes32 _hash
  );

  /// @notice CrossTalkReceive Event is emited when a request is recived in destination side when cross chain request accepted by contract.
  /// @param sourceChain Source ChainID.
  /// @param destChain Destination ChainID.
  /// @param sourceAddress Address of source contract.
  event CrossTalkReceive(
    uint8 indexed sourceChain,
    uint8 indexed destChain,
    address sourceAddress
  );

  /// @notice routerSync This is a public function and can only be called by Generic Handler of router infrastructure
  /// @param srcChainID Source ChainID.
  /// @param srcAddress Destination ChainID.
  /// @param _data  abi encoded selector and data to interface on Destination side.
  function routerSync(
    uint8 srcChainID,
    address srcAddress,
    bytes calldata _data
  ) external returns (bool, bytes memory);

  /// @notice Link This is a public function and can only be called by Generic Handler of router infrastructure
  /// @notice This function links contract on other chain ID's.
  /// @notice This is an administrative function and can only be initiated by linkSetter address.
  /// @param _chainID network Chain ID linked Contract linked to.
  /// @param _linkedContract Linked Contract address.
  function Link(uint8 _chainID, address _linkedContract) external;

  /// @notice UnLink This is a public function and can only be called by Generic Handler of router infrastructure
  /// @notice This function unLinks contract on other chain ID's.
  /// @notice This is an administrative function and can only be initiated by linkSetter address.
  /// @param _chainID network Chain ID linked Contract linked to.
  function Unlink(uint8 _chainID) external;

  /// @notice fetchLinkSetter This is a public function and fetches the linksetter address.
  function fetchLinkSetter() external view returns (address);

  /// @notice fetchLinkSetter This is a public function and fetches the address the contract is linked to.
  /// @param _chainID Chain ID information.
  function fetchLink(uint8 _chainID) external view returns (address);

  /// @notice fetchLinkSetter This is a public function and fetches the generic handler address.
  function fetchHandler() external view returns (address);

  /// @notice fetchFeeToken This is a public function and fetches the fee token set by admin.
  function fetchFeeToken() external view returns (address);

  /// @notice fetchExecutes This is a public function and fetches the executes struct.
  function fetchExecutes(bytes32 _hash)
    external
    view
    returns (ExecutesStruct memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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
interface IERC165Upgradeable {
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