// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interface/Isettings.sol";
import "./interface/Icontroller.sol";

contract FeeController {
    IController public controller;
    Isettings public settings;

    enum HoldingLevels {
        COMMON,
        BETA,
        ALPHA
    }
    mapping(address => bool) public isExempted;

    struct tokenHolderIncentiveModel {
        uint256 incentivePercentage;
        uint256 threshold;
    }

    struct indexedTokenIncentiveModel {
        uint256 incentivePercentage;
        bool isActive;
    }

    struct indexedUserIncentiveModel {
        uint256 incentivePercentage;
        bool isActive;
    }

    bool public useExemption;
    bool public useBRDGHoldingIncentive;
    bool public useUserIncentive;
    bool public useAssetIncentive;

    uint256 public defaultUserIncentivePercentage = 10;
    uint256 public defaultAssetIncentivePercentage = 10;

    mapping(HoldingLevels => tokenHolderIncentiveModel)
        public tokenHolderIncentive;
    mapping(address => indexedTokenIncentiveModel) public indexedTokenIncentive;
    mapping(address => indexedUserIncentiveModel) public indexedUserIncentive;

    event BrgHoldingIncentiveStatusChanged(bool status);
    event UserIncentiveStatusChanged(bool status);
    event AssetIncentiveStatusChanged(bool status);
    event AddressExemptionStatusChanged(bool status);
    event AssetIncentiveUpdated(
        address indexed asset,
        uint256 oldIncentive,
        uint256 newIncentive
    );

    event userExemptStatusChanged(address indexed user, bool exemptionStatus);
    event UserIncentiveUpdate(
        address indexed user,
        uint256 previousIncentive,
        uint256 currentIncentive
    );

    event BrgHoldingThresholdUpdated(
        uint256 prevBrgHoldingThreshold,
        uint256 newBrgHoldingThreshold
    );

    event DefaultAssetIncentivePercentageUpdated(
        uint256 prevVal,
        uint256 newVal
    );

    event DefaultUserIncentivePercentageUpdated(
        uint256 prevVal,
        uint256 newVal
    );
    event BrgHoldingIncentiveUpdated(
        uint256 prevBrgHoldingIncentive,
        uint256 newBrgHoldingIncentive
    );

    modifier onlyOwner() {
        require(controller.owner() == msg.sender, "caller is not the owner");
        _;
    }

    modifier Admin() {
        require(
            controller.owner() == msg.sender || controller.isAdmin(msg.sender),
            "caller is not the admin"
        );
        _;
    }

    constructor(IController _controller, Isettings _settings) {
        controller = _controller;
        settings = _settings;
        tokenHolderIncentive[HoldingLevels.COMMON] = tokenHolderIncentiveModel(
            20,
            50000 ether
        );
        tokenHolderIncentive[HoldingLevels.BETA] = tokenHolderIncentiveModel(
            30,
            2000000 ether
        );
        tokenHolderIncentive[HoldingLevels.ALPHA] = tokenHolderIncentiveModel(
            50,
            10000000 ether
        );
    }

    function activateBRDGHoldingIncentive(bool status) public Admin {
        require(useBRDGHoldingIncentive != status, "already set");
        useBRDGHoldingIncentive = status;
        emit BrgHoldingIncentiveStatusChanged(status);
    }

    function activateUserIncentive(bool status) public Admin {
        require(useUserIncentive != status, "already set");
        useUserIncentive = status;
        emit UserIncentiveStatusChanged(status);
    }

    function activateAssetIncentive(bool status) public Admin {
        require(useAssetIncentive != status, "already set");
        useAssetIncentive = status;
        emit AssetIncentiveStatusChanged(status);
    }

    function updateDefaultAssetIncentivePercentage(uint256 percentage)
        external
        Admin
    {
        require(percentage < 50, "invalid %");
        DefaultAssetIncentivePercentageUpdated(
            defaultAssetIncentivePercentage,
            percentage
        );
        defaultAssetIncentivePercentage = percentage;
    }

    function updateDefaultUserIncentivePercentage(uint256 percentage)
        external
        Admin
    {
        require(percentage < 50, "invalid %");
        DefaultUserIncentivePercentageUpdated(
            defaultUserIncentivePercentage,
            percentage
        );
        defaultUserIncentivePercentage = percentage;
    }

    function updateBRDGHoldingIncentiveThreshold(
        HoldingLevels tokenHoldingLevel,
        uint256 threshold
    ) external Admin {
        HoldingLevels _tokenHoldingLevel = getTokenHolding(tokenHoldingLevel);

        if (_tokenHoldingLevel == HoldingLevels.ALPHA) {
            require(
                threshold >
                    tokenHolderIncentive[HoldingLevels.BETA].threshold &&
                    tokenHolderIncentive[HoldingLevels.BETA].threshold >
                    tokenHolderIncentive[HoldingLevels.COMMON].threshold &&
                    tokenHolderIncentive[HoldingLevels.COMMON].threshold > 0
            );
        } else if (_tokenHoldingLevel == HoldingLevels.BETA) {
            require(
                tokenHolderIncentive[HoldingLevels.ALPHA].threshold >
                    threshold &&
                    threshold >
                    tokenHolderIncentive[HoldingLevels.COMMON].threshold &&
                    tokenHolderIncentive[HoldingLevels.COMMON].threshold > 0
            );
        } else if (_tokenHoldingLevel == HoldingLevels.COMMON) {
            require(
                tokenHolderIncentive[HoldingLevels.ALPHA].threshold >
                    tokenHolderIncentive[HoldingLevels.BETA].threshold &&
                    tokenHolderIncentive[HoldingLevels.BETA].threshold >
                    threshold &&
                    threshold > 0
            );
        }
        emit BrgHoldingThresholdUpdated(
            tokenHolderIncentive[_tokenHoldingLevel].threshold,
            threshold
        );
        tokenHolderIncentive[_tokenHoldingLevel].threshold = threshold;
    }

    function exemptAddress(address user, bool status) external onlyOwner {
        require(isExempted[user] != status, "already set");
        emit userExemptStatusChanged(user, status);
        isExempted[user] = status;
    }

    function activateAddressExemption(bool status) public Admin {
        require(useExemption != status, "already set");
        AddressExemptionStatusChanged(status);
        useExemption = status;
    }

    function updateIndexedTokenIncentivePercentage(
        address asset,
        uint256 percentage
    ) public Admin {
        require(
            indexedTokenIncentive[asset].isActive,
            "FeeController: asset exemption not active"
        );
        uint256 previousPercentage = indexedTokenIncentive[asset]
            .incentivePercentage;
        indexedTokenIncentive[asset].incentivePercentage = percentage;

        emit AssetIncentiveUpdated(asset, previousPercentage, percentage);
    }

    function updateUserExemptionPercentage(address user, uint256 percentage)
        public
        Admin
    {
        require(
            indexedUserIncentive[user].isActive,
            "FeeController: user exemption not active"
        );
        uint256 previousPercentage = indexedUserIncentive[user]
            .incentivePercentage;
        indexedUserIncentive[user].incentivePercentage = percentage;

        emit UserIncentiveUpdate(user, previousPercentage, percentage);
    }

    function getTokenHolding(HoldingLevels tokenHoldingLevel)
        internal
        pure
        returns (HoldingLevels _tokenHoldingLevel)
    {
        if (tokenHoldingLevel == HoldingLevels.COMMON) {
            return HoldingLevels.COMMON;
        } else if (tokenHoldingLevel == HoldingLevels.BETA) {
            return HoldingLevels.BETA;
        } else if (tokenHoldingLevel == HoldingLevels.ALPHA) {
            return HoldingLevels.ALPHA;
        } else {
            revert();
        }
    }

    function updateTokenHoldingIncentivePercentage(
        HoldingLevels tokenHoldingLevel,
        uint256 percentage
    ) external Admin {
        HoldingLevels _tokenHoldingLevel = getTokenHolding(tokenHoldingLevel);
        uint256 previousPercentage = tokenHolderIncentive[_tokenHoldingLevel]
            .incentivePercentage;
        if (_tokenHoldingLevel == HoldingLevels.ALPHA) {
            require(
                percentage >
                    tokenHolderIncentive[HoldingLevels.BETA]
                        .incentivePercentage &&
                    tokenHolderIncentive[HoldingLevels.BETA]
                        .incentivePercentage >
                    tokenHolderIncentive[HoldingLevels.COMMON]
                        .incentivePercentage &&
                    tokenHolderIncentive[HoldingLevels.COMMON]
                        .incentivePercentage >
                    0
            );
        } else if (_tokenHoldingLevel == HoldingLevels.BETA) {
            require(
                tokenHolderIncentive[HoldingLevels.ALPHA].incentivePercentage >
                    percentage &&
                    percentage >
                    tokenHolderIncentive[HoldingLevels.COMMON]
                        .incentivePercentage &&
                    tokenHolderIncentive[HoldingLevels.COMMON]
                        .incentivePercentage >
                    0
            );
        } else if (_tokenHoldingLevel == HoldingLevels.COMMON) {
            require(
                tokenHolderIncentive[HoldingLevels.ALPHA].incentivePercentage >
                    tokenHolderIncentive[HoldingLevels.BETA]
                        .incentivePercentage &&
                    tokenHolderIncentive[HoldingLevels.BETA]
                        .incentivePercentage >
                    percentage &&
                    percentage > 0
            );
        }
        tokenHolderIncentive[tokenHoldingLevel]
            .incentivePercentage = percentage;

        emit BrgHoldingIncentiveUpdated(previousPercentage, percentage);
    }

    function activateIndexedTokenIncentive(address token, bool status)
        external
        Admin
    {
        require(indexedTokenIncentive[token].isActive != status, "already set");
        if (status) indexedTokenIncentive[token].isActive = status;
        else
            indexedTokenIncentive[token] = indexedTokenIncentiveModel(
                defaultAssetIncentivePercentage,
                status
            );
        emit AssetIncentiveStatusChanged(true);
    }

    function activateIndexedUserIncentive(address user, bool status)
        external
        Admin
    {
        require(indexedUserIncentive[user].isActive != status, "already set");
        indexedUserIncentive[user] = indexedUserIncentiveModel(
            defaultUserIncentivePercentage,
            status
        );

        emit userExemptStatusChanged(user, status);
    }

    function determineTokenHolderLevelPercentage(address holder)
        public
        view
        returns (uint256 percentage)
    {
        uint256 holdingAmount = IERC20(settings.brgToken()).balanceOf(holder);

        if (
            holdingAmount >= tokenHolderIncentive[HoldingLevels.ALPHA].threshold
        ) {
            return
                tokenHolderIncentive[HoldingLevels.ALPHA].incentivePercentage;
        } else if (
            holdingAmount <
            tokenHolderIncentive[HoldingLevels.ALPHA].threshold &&
            holdingAmount >= tokenHolderIncentive[HoldingLevels.BETA].threshold
        ) {
            return tokenHolderIncentive[HoldingLevels.BETA].incentivePercentage;
        } else if (
            holdingAmount <
            tokenHolderIncentive[HoldingLevels.BETA].threshold &&
            holdingAmount >=
            tokenHolderIncentive[HoldingLevels.COMMON].threshold
        ) {
            return
                tokenHolderIncentive[HoldingLevels.COMMON].incentivePercentage;
        } else {
            return 0;
        }
    }

    function getTotalIncentives(address sender, address asset)
        public
        view
        returns (uint256)
    {
        if (!settings.baseFeeEnable()) return 0;

        if (useExemption && isExempted[sender]) return 0;

        uint256 totalIncentive;

        if (useAssetIncentive) {
            if (indexedTokenIncentive[asset].isActive) {
                totalIncentive += indexedTokenIncentive[asset]
                    .incentivePercentage;
            }
        }

        if (useUserIncentive) {
            if (indexedUserIncentive[sender].isActive) {
                totalIncentive += indexedUserIncentive[sender]
                    .incentivePercentage;
            }
        }

        if (useBRDGHoldingIncentive) {
            uint256 holderPecentage = determineTokenHolderLevelPercentage(
                sender
            );
            totalIncentive += holderPecentage;
        }
        return totalIncentive;
    }

    function getBridgeFee(address sender, address asset)
        external
        view
        returns (uint256)
    {
        if (!settings.baseFeeEnable()) return 0;

        if (useExemption && isExempted[sender]) return 0;

        uint256 totalIncentive = getTotalIncentives(sender, asset);
        uint256 fees = settings.baseFeePercentage();
        if (totalIncentive >= 100) {
            return 0;
        } else {
            return fees - ((totalIncentive * fees) / 100);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

interface IController {
    function isAdmin(address account) external view returns (bool);

    function isRegistrar(address account) external view returns (bool);

    function isOracle(address account) external view returns (bool);

    function isValidator(address account) external view returns (bool);

    function owner() external view returns (address);

    function validatorsCount() external view returns (uint256);

    function settings() external view returns (address);

    function deployer() external view returns (address);

    function feeController() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

interface Isettings {
    function networkFee(uint256 chainId) external view returns (uint256);

    function minValidations() external view returns (uint256);

    function isNetworkSupportedChain(uint256 chainID)
        external
        view
        returns (bool);

    function feeRemitance() external view returns (address);

    function railRegistrationFee() external view returns (uint256);

    function railOwnerFeeShare() external view returns (uint256);

    function onlyOwnableRail() external view returns (bool);

    function updatableAssetState() external view returns (bool);

    function minWithdrawableFee() external view returns (uint256);

    function brgToken() external view returns (address);

    function getNetworkSupportedChains()
        external
        view
        returns (uint256[] memory);

    function baseFeePercentage() external view returns (uint256);

    function networkGas(uint256 chainID) external view returns (uint256);

    function gasBank() external view returns (address);

    function baseFeeEnable() external view returns (bool);

    function maxFeeThreshold() external view returns (uint256);

    function approvedToAdd(address token, address user)
        external
        view
        returns (bool);
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