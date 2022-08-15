// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "../tierLevel/interfaces/IUserTier.sol";
import "../tierLevel/interfaces/IVCTier.sol";
import "../tierLevel/interfaces/IGovNFTTier.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../../admin/SuperAdminControl.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../../addressprovider/IAddressProvider.sol";

contract UserTier is IUserTier, OwnableUpgradeable, SuperAdminControl {
    address public addressProvider;
    address public govGovToken;
    address public govTier;
    address public govNFTTier;
    address public govVCTier;

    function initialize() external initializer {
        __Ownable_init();
    }

    /// @dev update the addresses from the address provider
    function updateAddresses() external onlyOwner {
        govGovToken = IAddressProvider(addressProvider).getgovGovToken();
        govTier = IAddressProvider(addressProvider).getGovTier();
        govNFTTier = IAddressProvider(addressProvider).getGovNFTTier();
        govVCTier = IAddressProvider(addressProvider).getVCTier();
    }

    /// @dev set the address provider in this contract
    function setAddressProvider(address _addressProvider) external onlyOwner {
        require(_addressProvider != address(0), "zero address");
        addressProvider = _addressProvider;
    }

    /// @dev this function returns the tierLevel data by user's Gov Token Balance
    /// @param userWalletAddress user address for check tier level data

    function getTierDatabyGovBalance(address userWalletAddress)
        external
        view
        override
        returns (TierData memory _tierData)
    {
        address govToken = IAddressProvider(addressProvider).govTokenAddress();

        require(govToken != address(0x0), "GTL: Gov Token not Configured");
        require(
            govGovToken != address(0x0),
            "GTL: govGov GToken not Configured"
        );
        uint256 userGovBalance = IERC20(govToken).balanceOf(userWalletAddress) +
            IERC20(govGovToken).balanceOf(userWalletAddress);

        bytes32[] memory tierKeys = IGovTier(govTier).getGovTierLevelKeys();
        uint256 lengthTierLevels = tierKeys.length;

        if (
            userGovBalance >=
            IGovTier(govTier).getSingleTierData(tierKeys[0]).govHoldings
        ) {
            return
                tierDatabyGovBalance(
                    userGovBalance,
                    lengthTierLevels,
                    tierKeys
                );
        } else {
            return
                getTierDatabyWallet(
                    userWalletAddress,
                    lengthTierLevels,
                    tierKeys
                );
        }
    }

    function tierDatabyGovBalance(
        uint256 _userGovBalance,
        uint256 _lengthTierLevels,
        bytes32[] memory _tierKeys
    ) private view returns (TierData memory _tierData) {
        for (uint256 i = 1; i < _lengthTierLevels; i++) {
            if (
                (_userGovBalance >=
                    IGovTier(govTier)
                        .getSingleTierData(_tierKeys[i - 1])
                        .govHoldings) &&
                (_userGovBalance <
                    IGovTier(govTier)
                        .getSingleTierData(_tierKeys[i])
                        .govHoldings)
            ) {
                return IGovTier(govTier).getSingleTierData(_tierKeys[i - 1]);
            } else if (
                _userGovBalance >=
                IGovTier(govTier)
                    .getSingleTierData(_tierKeys[_lengthTierLevels - 1])
                    .govHoldings
            ) {
                return
                    IGovTier(govTier).getSingleTierData(
                        _tierKeys[_lengthTierLevels - 1]
                    );
            }
        }
    }

    function getTierDatabyWallet(
        address _wallet,
        uint256 _lengthTierLevels,
        bytes32[] memory _tierKeys
    ) private view returns (TierData memory _tierData) {
        for (uint256 i = 0; i < _lengthTierLevels; i++) {
            if (_tierKeys[i] == IGovTier(govTier).getWalletTier(_wallet)) {
                return IGovTier(govTier).getSingleTierData(_tierKeys[i]);
            }
        }
        return IGovTier(govTier).getSingleTierData(0);
    }

    /// @dev Returns max loan amount a borrower can borrow
    /// @param _collateralTokeninStable amount of collateral in stable token amount
    /// @param _tierLevelLTVPercentage tier level percentage value
    function getMaxLoanAmount(
        uint256 _collateralTokeninStable,
        uint256 _tierLevelLTVPercentage
    ) external pure override returns (uint256) {
        uint256 maxLoanAmountAllowed = (_collateralTokeninStable *
            _tierLevelLTVPercentage) / 100;
        return maxLoanAmountAllowed;
    }

    /// @dev returns the max loan amount to value
    /// @param _collateralTokeninStable value of collateral in stable token
    /// @param _borrower address of the borrower
    /// @return uint256 returns the max loan amount in stable token
    function getMaxLoanAmountToValue(
        uint256 _collateralTokeninStable,
        address _borrower
    ) external view override returns (uint256) {
        TierData memory tierData = this.getTierDatabyGovBalance(_borrower);
        NFTTierData memory nftTier = IGovNFTTier(govNFTTier).getUserNftTier(
            _borrower
        );
        SingleSPTierData memory nftSpTier = IGovNFTTier(govNFTTier)
            .getSingleSpTier(nftTier.spTierId);

        VCNFTTier memory vcTier = IVCTier(govVCTier).getUserVCNFTTier(
            _borrower
        );

        if (tierData.govHoldings > 0) {
            return (_collateralTokeninStable * tierData.loantoValue) / 100;
        } else if (nftTier.isTraditional) {
            TierData memory traditionalTierData = IGovTier(govTier)
                .getSingleTierData(nftTier.traditionalTier);
            return
                (_collateralTokeninStable * traditionalTierData.loantoValue) /
                100;
        } else if (nftSpTier.ltv > 0) {
            return (_collateralTokeninStable * nftSpTier.ltv) / 100;
        } else if (vcTier.traditionalTier != 0) {
            TierData memory traditionalTierData = IGovTier(govTier)
                .getSingleTierData(vcTier.traditionalTier);
            return
                (_collateralTokeninStable * traditionalTierData.loantoValue) /
                100;
        } else {
            return 0;
        }
    }

    /// @dev Rules 1. User have gov balance tier, and they will
    // crerae single and multi token and nft loan according to tier level flags.
    // Rule 2. User have NFT tier level and it is traditional tier applies same rule as gov holding tier.
    // Rule 3. User have NFT tier level and it is SP Single Token, only SP token collateral allowed only single token loan allowed.
    // Rule 4. User have both NFT tier level and gov holding tier level. Invalid Tier.
    // Returns 200 if success all otther are differentt error codes
    /// @param _wallet address of the borrower
    /// @param _loanAmount loan amount in stable coin address
    /// @param _collateralinStable collateral amount in stable
    /// @param _stakedCollateralTokens staked collateral erc20 token addresses
    function isCreateLoanTokenUnderTier(
        address _wallet,
        uint256 _loanAmount,
        uint256 _collateralinStable,
        address[] memory _stakedCollateralTokens
    ) external view override returns (uint256) {
        //purpose of function is to return false in case any tier level related validation fails
        //Identify what tier it is.
        TierData memory tierData = this.getTierDatabyGovBalance(_wallet);
        NFTTierData memory nftTier = IGovNFTTier(govNFTTier).getUserNftTier(
            _wallet
        );
        SingleSPTierData memory nftSpTier = IGovNFTTier(govNFTTier)
            .getSingleSpTier(nftTier.spTierId);
        VCNFTTier memory vcTier = IVCTier(govVCTier).getUserVCNFTTier(_wallet);
        TierData memory vcTierData = IGovTier(govTier).getSingleTierData(
            vcTier.traditionalTier
        );

        if (
            (tierData.govHoldings > 0 && nftTier.nftContract != address(0)) ||
            (tierData.govHoldings > 0 && vcTierData.govHoldings > 0) ||
            (nftTier.nftContract != address(0) && vcTierData.govHoldings > 0)
        ) {
            //having all tiers not allowed, only one tier is allowed to create loan
            return 1;
        }
        if (tierData.govHoldings > 0) {
            //user has gov tier level
            return
                validateGovHoldingTierForToken(
                    _loanAmount,
                    _collateralinStable,
                    _stakedCollateralTokens,
                    tierData
                );
        }
        //determine if user nft tier is available
        // need to determinne is user one
        //of the nft holder in NFTTierData mapping
        else if (nftTier.isTraditional) {
            return
                validateNFTTier(
                    _loanAmount,
                    _collateralinStable,
                    _stakedCollateralTokens,
                    nftTier
                );
        } else if (nftSpTier.ltv > 0) {
            return
                validateNFTSpTier(
                    _loanAmount,
                    _collateralinStable,
                    _stakedCollateralTokens,
                    nftTier,
                    nftSpTier
                );
        } else {
            return
                validateVCTier(
                    _loanAmount,
                    _collateralinStable,
                    _stakedCollateralTokens,
                    vcTier
                );
        }
    }

    function validateGovHoldingTierForToken(
        uint256 _loanAmount,
        uint256 _collateralinStable,
        address[] memory _stakedCollateralTokens,
        TierData memory _tierData
    ) private view returns (uint256) {
        if (_tierData.singleToken || _tierData.multiToken) {
            if (!_tierData.multiToken) {
                if (_stakedCollateralTokens.length > 1) {
                    return 2; //multi-token loan not allowed in tier.
                }
            }
        } else {
            return 8; // single and multitoken not allowed in this tier
        }
        if (
            _loanAmount >
            this.getMaxLoanAmount(_collateralinStable, _tierData.loantoValue)
        ) {
            //allowed ltv
            return 3;
        }

        return 200;
    }

    function validateNFTTier(
        uint256 _loanAmount,
        uint256 _collateralinStable,
        address[] memory _stakedCollateralTokens,
        NFTTierData memory _nftTierData
    ) private view returns (uint256) {
        TierData memory traditionalTierData = IGovTier(govTier)
            .getSingleTierData(_nftTierData.traditionalTier);
        //start validatting loan offer
        if (traditionalTierData.singleToken || traditionalTierData.multiToken) {
            if (!traditionalTierData.multiToken) {
                if (_stakedCollateralTokens.length > 1) {
                    return 2; //multi-token loan not allowed in tier.
                }
            }
        } else {
            return 8; // single and multitoken not allowed in this tier
        }
        if (
            _loanAmount >
            this.getMaxLoanAmount(
                _collateralinStable,
                traditionalTierData.loantoValue
            )
        ) {
            //allowed ltv
            return 3;
        }

        return 200;
    }

    function validateNFTSpTier(
        uint256 _loanAmount,
        uint256 _collateralinStable,
        address[] memory _stakedCollateralTokens,
        NFTTierData memory _nftTierData,
        SingleSPTierData memory _nftSpTier
    ) private pure returns (uint256) {
        if (_stakedCollateralTokens.length > 1 && !_nftSpTier.multiToken && !_nftSpTier.singleToken) {
            //only single token allowed for sp tier, and having no single token in your current tier
            return 5;
        }
        uint256 maxLoanAmount = (_collateralinStable * _nftSpTier.ltv) / 100;
        if (_loanAmount > maxLoanAmount) {
            //loan to value is under tier
            return 6;
        }
        for (uint256 c = 0; c < _stakedCollateralTokens.length; c++) {
            bool found = false;
            for (uint256 x = 0; x < _nftTierData.allowedSuns.length; x++) {
                if (
                    //collateral can be either approved sun token or associated sp token
                    _stakedCollateralTokens[c] == _nftTierData.allowedSuns[x] ||
                    _stakedCollateralTokens[c] == _nftTierData.spToken
                ) {
                    //collateral can not be other then sp token or approved sun tokens
                    found = true;
                }
            }
            if (!found) {
                //can not be other then approved sun Tokens or approved SP token
                return 7;
            }
        }
        return 200;
    }

    function validateVCTier(
        uint256 _loanAmount,
        uint256 _collateralinStable,
        address[] memory _stakedCollateralTokens,
        VCNFTTier memory _vcTier
    ) private view returns (uint256) {
        TierData memory traditionalTierData = IGovTier(govTier)
            .getSingleTierData(_vcTier.traditionalTier);

        if (traditionalTierData.singleToken || traditionalTierData.multiToken) {
            if (!traditionalTierData.multiToken) {
                if (_stakedCollateralTokens.length > 1) {
                    return 2; //multi-token loan not allowed in tier.
                }
            }
        } else {
            return 8; // single and multitoken not allowed in this tier
        }

        if (
            _loanAmount >
            this.getMaxLoanAmount(
                _collateralinStable,
                traditionalTierData.loantoValue
            )
        ) {
            //loan to value is under tier, loan amount is greater than max loan amount
            return 3;
        }

        for (uint256 j = 0; j < _stakedCollateralTokens.length; j++) {
            bool found = false;

            uint256 spTokenLength = _vcTier.spAllowedTokens.length;
            for (uint256 a = 0; a < spTokenLength; a++) {
                if (_stakedCollateralTokens[j] == _vcTier.spAllowedTokens[a]) {
                    //collateral can not be other then sp token
                    found = true;
                }
            }

            if (!found) {
                //can not be other then approved sp tokens or approved sun tokens
                return 7;
            }
        }

        return 200;
    }

    function validateGovHoldingTierForNFT(
        uint256 _loanAmount,
        uint256 _collateralinStable,
        address[] memory _stakedCollateralNFTs,
        TierData memory _tierData
    ) private view returns (uint256) {
        //user has gov tier level
        //start validatting loan offer
        if (_tierData.singleNFT || _tierData.multiNFT) {
            if (!_tierData.multiNFT) {
                if (_stakedCollateralNFTs.length > 1) {
                    return 2; //multi-nft loan not allowed in gov tier.
                }
            }
        } else {
            return 8; // single and multi nft not allowed in this tier
        }
        if (
            _loanAmount >
            this.getMaxLoanAmount(_collateralinStable, _tierData.loantoValue)
        ) {
            //allowed ltv, loan amount is greater than max loan amount
            return 3;
        }

        return 200;
    }

    function validateNFTTierForNFTs(
        uint256 _loanAmount,
        uint256 _collateralinStable,
        address[] memory _stakedCollateralNFTs,
        NFTTierData memory _nftTierData
    ) private view returns (uint256 result) {
        TierData memory traditionalTierData = IGovTier(govTier)
            .getSingleTierData(_nftTierData.traditionalTier);
        //start validatting loan offer
        if (traditionalTierData.singleNFT || traditionalTierData.multiNFT) {
            if (!traditionalTierData.multiNFT) {
                if (_stakedCollateralNFTs.length > 1) {
                    result = 2;
                    return result; //multi-token loan not allowed in tier.
                }
            }
        } else {
            return 8; //single and multi nfts not allowed
        }
        if (
            _loanAmount >
            this.getMaxLoanAmount(
                _collateralinStable,
                traditionalTierData.loantoValue
            )
        ) {
            //allowed ltv
            result = 3;
            return result;
        }

        result = 200;
        return result;
    }

    function validateNFTSpTierforNFTs(
        uint256 _loanAmount,
        uint256 _collateralinStable,
        address[] memory _stakedCollateralNFTs,
        NFTTierData memory _nftTierData,
        SingleSPTierData memory _nftSpTier
    ) private pure returns (uint256) {
        if (_stakedCollateralNFTs.length > 1 && !_nftSpTier.multiNFT && !_nftSpTier.singleToken && !_nftSpTier.singleNft) {
            //only single nft or single token allowed for sp tier
            return 5;
        }
        uint256 maxLoanAmount = (_collateralinStable * _nftSpTier.ltv) / 100;
        if (_loanAmount > maxLoanAmount) {
            //loan to value is under tier
            return 6;
        }

        for (uint256 c = 0; c < _stakedCollateralNFTs.length; c++) {
            bool found = false;

            for (uint256 x = 0; x < _nftTierData.allowedNfts.length; x++) {
                if (_stakedCollateralNFTs[c] == _nftTierData.allowedNfts[x]) {
                    //collateral can not be other then sp token
                    found = true;
                }
            }

            if (!found) {
                //can not be other then approved sp nfts
                return 7;
            }
        }
        return 200;
    }

    function validateVCTierForNFTs(
        uint256 _loanAmount,
        uint256 _collateralinStable,
        address[] memory _stakedCollateralNFTs,
        VCNFTTier memory _vcTier
    ) private view returns (uint256) {
        TierData memory traditionalTierData = IGovTier(govTier)
            .getSingleTierData(_vcTier.traditionalTier);

        if (traditionalTierData.singleNFT || traditionalTierData.multiNFT) {
            if (!traditionalTierData.multiNFT) {
                if (_stakedCollateralNFTs.length > 1) {
                    return 2; //multi-nfts loan not allowed in nft traditional tier.
                }
            }
        }else {
            return 8; // single and multi nft not allowed in this tier
        }

        if (
            _loanAmount >
            this.getMaxLoanAmount(
                _collateralinStable,
                traditionalTierData.loantoValue
            )
        ) {
            //loan to value is under tier
            return 3;
        }

        for (uint256 j = 0; j < _stakedCollateralNFTs.length; j++) {
            bool found = false;

            uint256 spNFTLength = _vcTier.spAllowedNFTs.length;
            for (uint256 a = 0; a < spNFTLength; a++) {
                if (_stakedCollateralNFTs[j] == _vcTier.spAllowedNFTs[a]) {
                    //collateral can not be other then sp nft
                    found = true;
                }
            }

            if (!found) {
                //can not be other then approved sp nfts
                return 7;
            }
        }
        return 200;
    }

    /// @dev Rules 1. User have gov balance tier, and they will
    // crerae single and multi token and nft loan according to tier level flags.
    // Rule 2. User have NFT tier level and it is traditional tier applies same rule as gov holding tier.
    // Rule 3. User have NFT tier level and it is SP Single Token, only SP token collateral allowed only single token loan allowed.
    // Rule 4. User have both NFT tier level and gov holding tier level. Invalid Tier.
    // Returns 200 if success all otther are differentt error codes
    /// @param _wallet address of the borrower
    /// @param _loanAmount loan amount in stable coin address
    /// @param _collateralinStable collateral amount in stable
    /// @param _stakedCollateralNFTs staked collateral NFT token addresses
    function isCreateLoanNftUnderTier(
        address _wallet,
        uint256 _loanAmount,
        uint256 _collateralinStable,
        address[] memory _stakedCollateralNFTs
    ) external view override returns (uint256) {
        //purpose of function is to return false in case any tier level related validation fails
        //Identify what tier it is.
        TierData memory tierData = this.getTierDatabyGovBalance(_wallet);
        NFTTierData memory nftTier = IGovNFTTier(govNFTTier).getUserNftTier(
            _wallet
        );
        SingleSPTierData memory nftSpTier = IGovNFTTier(govNFTTier)
            .getSingleSpTier(nftTier.spTierId);
        VCNFTTier memory vcTier = IVCTier(govVCTier).getUserVCNFTTier(_wallet);
        TierData memory vcTierData = IGovTier(govTier).getSingleTierData(
            vcTier.traditionalTier
        );

        if (
            (tierData.govHoldings > 0 && nftTier.nftContract != address(0)) ||
            (tierData.govHoldings > 0 && vcTierData.govHoldings > 0) ||
            (nftTier.nftContract != address(0) && vcTierData.govHoldings > 0)
        ) {
            //having all tiers not allowed, only one tier is allowed to create loan
            return 1;
        }
        if (tierData.govHoldings > 0) {
            return
                validateGovHoldingTierForNFT(
                    _loanAmount,
                    _collateralinStable,
                    _stakedCollateralNFTs,
                    tierData
                );
        } else if (nftTier.isTraditional) {
            return
                validateNFTTierForNFTs(
                    _loanAmount,
                    _collateralinStable,
                    _stakedCollateralNFTs,
                    nftTier
                );
        } else if (nftSpTier.ltv > 0) {
            return
                validateNFTSpTierforNFTs(
                    _loanAmount,
                    _collateralinStable,
                    _stakedCollateralNFTs,
                    nftTier,
                    nftSpTier
                );
        } else {
            return
                validateVCTierForNFTs(
                    _loanAmount,
                    _collateralinStable,
                    _stakedCollateralNFTs,
                    vcTier
                );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "../../tierLevel/interfaces/IGovTier.sol";

interface IUserTier {
    function getTierDatabyGovBalance(address userWalletAddress)
        external
        view
        returns (TierData memory _tierData);

    function getMaxLoanAmount(
        uint256 _collateralTokeninStable,
        uint256 _tierLevelLTVPercentage
    ) external pure returns (uint256);

    function getMaxLoanAmountToValue(
        uint256 _collateralTokeninStable,
        address _borrower
    ) external view returns (uint256);

    function isCreateLoanTokenUnderTier(
        address _wallet,
        uint256 _loanAmount,
        uint256 collateralInBorrowed,
        address[] memory stakedCollateralTokens
    ) external view returns (uint256);

    function isCreateLoanNftUnderTier(
        address _wallet,
        uint256 _loanAmount,
        uint256 collateralInBorrowed,
        address[] memory stakedCollateralTokens
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

struct VCNFTTier {
    address nftContract;
    bytes32 traditionalTier;
    address[] spAllowedTokens;
    address[] spAllowedNFTs;
}

interface IVCTier {
    function getVCTier(address _vcTierNFT)
        external
        view
        returns (VCNFTTier memory);

    function getUserVCNFTTier(address _wallet)
        external
        view
        returns (VCNFTTier memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

struct SingleSPTierData {
    uint256 ltv;
    bool singleToken;
    bool multiToken;
    bool singleNft;
    bool multiNFT;
}

struct NFTTierData {
    address nftContract;
    bool isTraditional;
    address spToken; // strategic partner token address - erc20
    bytes32 traditionalTier;
    uint256 spTierId;
    address[] allowedNfts;
    address[] allowedSuns;
}

interface IGovNFTTier {
    function getUserNftTier(address _wallet)
        external
        view
        returns (NFTTierData memory nftTierData);

    function getSingleSpTier(uint256 _spTierId)
        external
        view
        returns (SingleSPTierData memory);
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "../admin/interfaces/IAdminRegistry.sol";

abstract contract SuperAdminControl {
    /// @dev modifier: onlySuper admin is allowed
    modifier onlySuperAdmin(address govAdminRegistry, address admin) {
        require(
            IAdminRegistry(govAdminRegistry).isSuperAdminAccess(admin),
            "not super admin"
        );
        _;
    }
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

pragma solidity ^0.8.3;

/// @dev interface use in all the gov platform contracts
interface IAddressProvider {
    function getAdminRegistry() external view returns (address);

    function getProtocolRegistry() external view returns (address);

    function getPriceConsumer() external view returns (address);

    function getClaimTokenContract() external view returns (address);

    function getGTokenFactory() external view returns (address);

    function getLiquidator() external view returns (address);

    function getTokenMarketRegistry() external view returns (address);

    function getTokenMarket() external view returns (address);

    function getNftMarket() external view returns (address);

    function getNetworkMarket() external view returns (address);

    function govTokenAddress() external view returns (address);

    function getGovTier() external view returns (address);

    function getgovGovToken() external view returns (address);

    function getGovNFTTier() external view returns (address);

    function getVCTier() external view returns (address);

    function getUserTier() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

struct TierData {
    // Gov  Holdings to check if it lies in that tier
    uint256 govHoldings;
    // LTV percentage of the Gov Holdings
    uint8 loantoValue;
    //checks that if tier level have following access
    bool govIntel;
    bool singleToken;
    bool multiToken;
    bool singleNFT;
    bool multiNFT;
    bool reverseLoan;
}

interface IGovTier {
    function getSingleTierData(bytes32 _tierLevelKey)
        external
        view
        returns (TierData memory);

    function isAlreadyTierLevel(bytes32 _tierLevel)
        external
        view
        returns (bool);

    function getGovTierLevelKeys() external view returns (bytes32[] memory);

    function getWalletTier(address _userAddress)
        external
        view
        returns (bytes32 _tierLevel);
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
pragma solidity ^0.8.3;

interface IAdminRegistry {
    struct AdminAccess {
        //access-modifier variables to add projects to gov-intel
        bool addGovIntel;
        bool editGovIntel;
        //access-modifier variables to add tokens to gov-world protocol
        bool addToken;
        bool editToken;
        //access-modifier variables to add strategic partners to gov-world protocol
        bool addSp;
        bool editSp;
        //access-modifier variables to add gov-world admins to gov-world protocol
        bool addGovAdmin;
        bool editGovAdmin;
        //access-modifier variables to add bridges to gov-world protocol
        bool addBridge;
        bool editBridge;
        //access-modifier variables to add pools to gov-world protocol
        bool addPool;
        bool editPool;
        //superAdmin role assigned only by the super admin
        bool superAdmin;
    }

    function isAddGovAdminRole(address admin) external view returns (bool);

    //using this function externally in Gov Tier Level Smart Contract
    function isEditAdminAccessGranted(address admin)
        external
        view
        returns (bool);

    //using this function externally in other Smart Contracts
    function isAddTokenRole(address admin) external view returns (bool);

    //using this function externally in other Smart Contracts
    function isEditTokenRole(address admin) external view returns (bool);

    //using this function externally in other Smart Contracts
    function isAddSpAccess(address admin) external view returns (bool);

    //using this function externally in other Smart Contracts
    function isEditSpAccess(address admin) external view returns (bool);

    //using this function in loan smart contracts to withdraw network balance
    function isSuperAdminAccess(address admin) external view returns (bool);
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