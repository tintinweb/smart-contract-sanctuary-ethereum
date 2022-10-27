// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IGovTier} from "./../../interfaces/IGovTier.sol";
import {IGovNFTTier} from "./../../interfaces/IGovNFTTier.sol";
import {IVCTier} from "./../../interfaces/IVCTier.sol";
import {Modifiers} from "./../../shared/libraries/LibAppStorage.sol";
import {LibGovTierStorage} from "./../govTier/LibGovTierStorage.sol";
import {LibUserTier} from "./../userTier/LibUserTier.sol";
import {LibGovNFTTierStorage} from "./../nftTier/LibGovNFTTierStorage.sol";
import {LibVCTierStorage} from "./../vcTier/LibVCTierStorage.sol";
import {LibMarketStorage} from "./../../facets/market/libraries/LibMarketStorage.sol";

contract UserTierFacet is Modifiers {
    /// @dev this function returns the tierLevel data by user's Gov Token Balance
    /// @param userWalletAddress user address for check tier level data

    function getTierDatabyGovBalance(address userWalletAddress)
        external
        view
        returns (LibGovTierStorage.TierData memory _tierData)
    {
        require(s.govToken != address(0x0), "GTL: Gov Token not Configured");
        require(
            s.govGovToken != address(0x0),
            "GTL: govGov GToken not Configured"
        );
        uint256 userGovBalance = IERC20(s.govToken).balanceOf(
            userWalletAddress
        ) + IERC20(s.govGovToken).balanceOf(userWalletAddress);

        bytes32[] memory tierKeys = IGovTier(address(this))
            .getGovTierLevelKeys();
        uint256 lengthTierLevels = tierKeys.length;

        if (
            userGovBalance >=
            IGovTier(address(this)).getSingleTierData(tierKeys[0]).govHoldings
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
    ) private view returns (LibGovTierStorage.TierData memory _tierData) {
        for (uint256 i = 1; i < _lengthTierLevels; i++) {
            if (
                (_userGovBalance >=
                    IGovTier(address(this))
                        .getSingleTierData(_tierKeys[i - 1])
                        .govHoldings) &&
                (_userGovBalance <
                    IGovTier(address(this))
                        .getSingleTierData(_tierKeys[i])
                        .govHoldings)
            ) {
                return
                    IGovTier(address(this)).getSingleTierData(_tierKeys[i - 1]);
            } else if (
                _userGovBalance >=
                IGovTier(address(this))
                    .getSingleTierData(_tierKeys[_lengthTierLevels - 1])
                    .govHoldings
            ) {
                return
                    IGovTier(address(this)).getSingleTierData(
                        _tierKeys[_lengthTierLevels - 1]
                    );
            }
        }
    }

    function getTierDatabyWallet(
        address _wallet,
        uint256 _lengthTierLevels,
        bytes32[] memory _tierKeys
    ) private view returns (LibGovTierStorage.TierData memory _tierData) {
        for (uint256 i = 0; i < _lengthTierLevels; i++) {
            if (
                _tierKeys[i] == IGovTier(address(this)).getWalletTier(_wallet)
            ) {
                return IGovTier(address(this)).getSingleTierData(_tierKeys[i]);
            }
        }
        return IGovTier(address(this)).getSingleTierData(0);
    }

    /// @dev Returns max loan amount a borrower can borrow
    /// @param _collateralTokeninStable amount of collateral in stable token amount
    /// @param _tierLevelLTVPercentage tier level percentage value
    function getMaxLoanAmount(
        uint256 _collateralTokeninStable,
        uint256 _tierLevelLTVPercentage
    ) external pure returns (uint256) {
        return
            LibUserTier.getMaxLoanAmount(
                _collateralTokeninStable,
                _tierLevelLTVPercentage
            );
    }

    /// @dev returns the max loan amount to value
    /// @param _collateralTokeninStable value of collateral in stable token
    /// @param _borrower address of the borrower
    /// @return uint256 returns the max loan amount in stable token
    function getMaxLoanAmountToValue(
        uint256 _collateralTokeninStable,
        address _borrower,
        LibMarketStorage.TierType _tierType
    ) external view returns (uint256) {
        LibGovTierStorage.TierData memory tierData = this
            .getTierDatabyGovBalance(_borrower);
        LibGovNFTTierStorage.NFTTierData memory nftTier = IGovNFTTier(
            address(this)
        ).getUserNftTier(_borrower);
        LibGovNFTTierStorage.SingleSPTierData memory nftSpTier = IGovNFTTier(
            address(this)
        ).getSingleSpTier(nftTier.spTierId);

        LibVCTierStorage.VCNFTTier memory vcTier = IVCTier(address(this))
            .getUserVCNFTTier(_borrower);

        if (
            tierData.govHoldings > 0 &&
            _tierType == LibMarketStorage.TierType.GOV_TIER
        ) {
            return (_collateralTokeninStable * tierData.loantoValue) / 100;
        } else if (
            nftTier.isTraditional &&
            _tierType == LibMarketStorage.TierType.NFT_TIER
        ) {
            LibGovTierStorage.TierData memory traditionalTierData = IGovTier(
                address(this)
            ).getSingleTierData(nftTier.traditionalTier);
            return
                (_collateralTokeninStable * traditionalTierData.loantoValue) /
                100;
        } else if (
            nftSpTier.ltv > 0 &&
            _tierType == LibMarketStorage.TierType.NFT_SP_TIER
        ) {
            return (_collateralTokeninStable * nftSpTier.ltv) / 100;
        } else if (
            vcTier.traditionalTier != 0 &&
            _tierType == LibMarketStorage.TierType.VC_TIER
        ) {
            LibGovTierStorage.TierData memory traditionalTierData = IGovTier(
                address(this)
            ).getSingleTierData(vcTier.traditionalTier);
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
        address[] memory _stakedCollateralTokens,
        LibMarketStorage.TierType _tierType
    ) external view returns (uint256) {
        //purpose of function is to return false in case any tier level related validation fails
        //Identify what tier it is.
        LibGovTierStorage.TierData memory tierData = this
            .getTierDatabyGovBalance(_wallet);
        LibGovNFTTierStorage.NFTTierData memory nftTier = IGovNFTTier(
            address(this)
        ).getUserNftTier(_wallet);
        LibGovNFTTierStorage.SingleSPTierData memory nftSpTier = IGovNFTTier(
            address(this)
        ).getSingleSpTier(nftTier.spTierId);
        LibVCTierStorage.VCNFTTier memory vcTier = IVCTier(address(this))
            .getUserVCNFTTier(_wallet);
        LibGovTierStorage.TierData memory vcTierData = IGovTier(address(this))
            .getSingleTierData(vcTier.traditionalTier);

        if (
            tierData.govHoldings > 0 &&
            _tierType == LibMarketStorage.TierType.GOV_TIER
        ) {
            //user has gov tier level
            return
                LibUserTier.validateGovHoldingTierForToken(
                    _loanAmount,
                    _collateralinStable,
                    _stakedCollateralTokens,
                    tierData
                );
        }
        //determine if user nft tier is available
        // need to determinne is user one
        //of the nft holder in NFTTierData mapping
        else if (
            nftTier.isTraditional &&
            _tierType == LibMarketStorage.TierType.NFT_TIER
        ) {
            return
                LibUserTier.validateNFTTier(
                    _loanAmount,
                    _collateralinStable,
                    _stakedCollateralTokens,
                    nftTier
                );
        } else if (
            nftSpTier.ltv > 0 &&
            _tierType == LibMarketStorage.TierType.NFT_SP_TIER
        ) {
            return
                LibUserTier.validateNFTSpTier(
                    _loanAmount,
                    _collateralinStable,
                    _stakedCollateralTokens,
                    nftTier,
                    nftSpTier
                );
        } else if (
            vcTierData.govHoldings > 0 &&
            _tierType == LibMarketStorage.TierType.VC_TIER
        ) {
            return
                LibUserTier.validateVCTier(
                    _loanAmount,
                    _collateralinStable,
                    _stakedCollateralTokens,
                    vcTier
                );
        } else {
            return 1;
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
    /// @param _stakedCollateralNFTs staked collateral NFT token addresses
    function isCreateLoanNftUnderTier(
        address _wallet,
        uint256 _loanAmount,
        uint256 _collateralinStable,
        address[] memory _stakedCollateralNFTs,
        LibMarketStorage.TierType _tierType
    ) external view returns (uint256) {
        //purpose of function is to return false in case any tier level related validation fails
        //Identify what tier it is.
        LibGovTierStorage.TierData memory tierData = this
            .getTierDatabyGovBalance(_wallet);
        LibGovNFTTierStorage.NFTTierData memory nftTier = IGovNFTTier(
            address(this)
        ).getUserNftTier(_wallet);
        LibGovNFTTierStorage.SingleSPTierData memory nftSpTier = IGovNFTTier(
            address(this)
        ).getSingleSpTier(nftTier.spTierId);
        LibVCTierStorage.VCNFTTier memory vcTier = IVCTier(address(this))
            .getUserVCNFTTier(_wallet);
        LibGovTierStorage.TierData memory vcTierData = IGovTier(address(this))
            .getSingleTierData(vcTier.traditionalTier);

        if (
            tierData.govHoldings > 0 &&
            _tierType == LibMarketStorage.TierType.GOV_TIER
        ) {
            return
                LibUserTier.validateGovHoldingTierForNFT(
                    _loanAmount,
                    _collateralinStable,
                    _stakedCollateralNFTs,
                    tierData
                );
        } else if (
            nftTier.isTraditional &&
            _tierType == LibMarketStorage.TierType.NFT_TIER
        ) {
            return
                LibUserTier.validateNFTTierForNFTs(
                    _loanAmount,
                    _collateralinStable,
                    _stakedCollateralNFTs,
                    nftTier
                );
        } else if (
            nftSpTier.ltv > 0 &&
            _tierType == LibMarketStorage.TierType.NFT_SP_TIER
        ) {
            return
                LibUserTier.validateNFTSpTierforNFTs(
                    _loanAmount,
                    _collateralinStable,
                    _stakedCollateralNFTs,
                    nftTier,
                    nftSpTier
                );
        } else if (
            vcTierData.govHoldings > 0 &&
            _tierType == LibMarketStorage.TierType.VC_TIER
        ) {
            return
                LibUserTier.validateVCTierForNFTs(
                    _loanAmount,
                    _collateralinStable,
                    _stakedCollateralNFTs,
                    vcTier
                );
        } else {
            return 1;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import {LibGovTierStorage} from "./../facets/govTier/LibGovTierStorage.sol";

interface IGovTier {
    function getSingleTierData(bytes32 _tierLevelKey)
        external
        view
        returns (LibGovTierStorage.TierData memory);

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
pragma solidity ^0.8.10;

import {LibVCTierStorage} from "./../facets/vcTier/LibVCTierStorage.sol";

interface IVCTier {
    function getVCTier(address _vcTierNFT)
        external
        view
        returns (LibVCTierStorage.VCNFTTier memory);

    function getUserVCNFTTier(address _wallet)
        external
        view
        returns (LibVCTierStorage.VCNFTTier memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {LibGovNFTTierStorage} from "./../facets/nftTier/LibGovNFTTierStorage.sol";

interface IGovNFTTier {
    function getUserNftTier(address _wallet)
        external
        view
        returns (LibGovNFTTierStorage.NFTTierData memory nftTierData);

    function getSingleSpTier(uint256 _spTierId)
        external
        view
        returns (LibGovNFTTierStorage.SingleSPTierData memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {LibDiamond} from "./../../shared/libraries/LibDiamond.sol";
import {LibAdminStorage} from "./../../facets/admin/LibAdminStorage.sol";
import {LibLiquidatorStorage} from "./../../facets/liquidator/LibLiquidatorStorage.sol";
import {LibProtocolStorage} from "./../../facets/protocolRegistry/LibProtocolStorage.sol";
import {LibPausable} from "./../../shared/libraries/LibPausable.sol";

struct AppStorage {
    address govToken;
    address govGovToken;
}

library LibAppStorage {
    function appStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }
}

contract Modifiers {
    AppStorage internal s;
    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    modifier onlySuperAdmin(address admin) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        require(es.approvedAdminRoles[admin].superAdmin, "not super admin");
        _;
    }

    /// @dev modifer only admin with edit admin access can call functions
    modifier onlyEditTierLevelRole(address admin) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        require(
            es.approvedAdminRoles[admin].editGovAdmin,
            "not edit tier role"
        );
        _;
    }

    modifier onlyLiquidator(address _admin) {
        LibLiquidatorStorage.LiquidatorStorage storage es = LibLiquidatorStorage
            .liquidatorStorage();
        require(es.whitelistLiquidators[_admin], "not liquidator");
        _;
    }

    //modifier: only admin with AddTokenRole can add Token(s) or NFT(s)
    modifier onlyAddTokenRole(address admin) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        require(es.approvedAdminRoles[admin].addToken, "not add token role");
        _;
    }

    //modifier: only admin with EditTokenRole can update or remove Token(s)/NFT(s)
    modifier onlyEditTokenRole(address admin) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        require(es.approvedAdminRoles[admin].editToken, "not edit token role");
        _;
    }

    //modifier: only admin with AddSpAccessRole can add SP Wallet
    modifier onlyAddSpRole(address admin) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();
        require(es.approvedAdminRoles[admin].addSp, "not add sp role");
        _;
    }

    //modifier: only admin with EditSpAccess can update or remove SP Wallet
    modifier onlyEditSpRole(address admin) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();
        require(es.approvedAdminRoles[admin].editSp, "not edit sp role");
        _;
    }

    modifier whenNotPaused() {
        LibPausable.enforceNotPaused();
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {IGovTier} from "./../../interfaces/IGovTier.sol";
import {LibGovTierStorage} from "./../govTier/LibGovTierStorage.sol";
import {LibGovNFTTierStorage} from "./../../facets/nftTier/LibGovNFTTierStorage.sol";
import {LibVCTierStorage} from "./../../facets/vcTier/LibVCTierStorage.sol";
import {LibAppStorage, AppStorage, Modifiers} from "./../../shared/libraries/LibAppStorage.sol";

library LibUserTier {
    function validateGovHoldingTierForToken(
        uint256 _loanAmount,
        uint256 _collateralinStable,
        address[] memory _stakedCollateralTokens,
        LibGovTierStorage.TierData memory _tierData
    ) internal pure returns (uint256) {
        if (_tierData.singleToken || _tierData.multiToken) {
            if (!_tierData.multiToken) {
                if (_stakedCollateralTokens.length > 1) {
                    return 2; //multi-token loan not allowed in tier.
                }
            }
        }

        if (
            _loanAmount >
            getMaxLoanAmount(_collateralinStable, _tierData.loantoValue)
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
        LibGovNFTTierStorage.NFTTierData memory _nftTierData
    ) internal view returns (uint256) {
        LibGovTierStorage.TierData memory traditionalTierData = IGovTier(
            address(this)
        ).getSingleTierData(_nftTierData.traditionalTier);
        //start validatting loan offer
        if (traditionalTierData.singleToken || traditionalTierData.multiToken) {
            if (!traditionalTierData.multiToken) {
                if (_stakedCollateralTokens.length > 1) {
                    return 2; //multi-token loan not allowed in tier.
                }
            }
        }

        if (
            _loanAmount >
            getMaxLoanAmount(
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
        LibGovNFTTierStorage.NFTTierData memory _nftTierData,
        LibGovNFTTierStorage.SingleSPTierData memory _nftSpTier
    ) internal pure returns (uint256) {
        if (_stakedCollateralTokens.length > 1 && !_nftSpTier.multiToken) {
            //only single token allowed for sp tier, and having no single token in your current tier
            return 5;
        }
        uint256 maxLoanAmount = (_collateralinStable * _nftSpTier.ltv) / 100;
        if (_loanAmount > maxLoanAmount) {
            //loan to value is under tier
            return 6;
        }

        bool found = false;

        for (uint256 c = 0; c < _stakedCollateralTokens.length; c++) {
            if (_stakedCollateralTokens[c] == _nftTierData.spToken) {
                found = true;
            }

            for (uint256 x = 0; x < _nftTierData.allowedSuns.length; x++) {
                if (
                    //collateral can be either approved sun token or associated sp token
                    _stakedCollateralTokens[c] == _nftTierData.allowedSuns[x]
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
        LibVCTierStorage.VCNFTTier memory _vcTier
    ) internal view returns (uint256) {
        LibGovTierStorage.TierData memory traditionalTierData = IGovTier(
            address(this)
        ).getSingleTierData(_vcTier.traditionalTier);

        if (traditionalTierData.singleToken || traditionalTierData.multiToken) {
            if (!traditionalTierData.multiToken) {
                if (_stakedCollateralTokens.length > 1) {
                    return 2; //multi-token loan not allowed in tier.
                }
            }
        }

        if (
            _loanAmount >
            getMaxLoanAmount(
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
        LibGovTierStorage.TierData memory _tierData
    ) internal pure returns (uint256) {
        //user has gov tier level
        //start validatting loan offer
        if (_tierData.singleNFT || _tierData.multiNFT) {
            if (!_tierData.multiNFT) {
                if (_stakedCollateralNFTs.length > 1) {
                    return 2; //multi-nft loan not allowed in gov tier.
                }
            }
        }

        if (
            _loanAmount >
            getMaxLoanAmount(_collateralinStable, _tierData.loantoValue)
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
        LibGovNFTTierStorage.NFTTierData memory _nftTierData
    ) internal view returns (uint256) {
        LibGovTierStorage.TierData memory traditionalTierData = IGovTier(
            address(this)
        ).getSingleTierData(_nftTierData.traditionalTier);
        //start validatting loan offer
        if (traditionalTierData.singleNFT || traditionalTierData.multiNFT) {
            if (!traditionalTierData.multiNFT) {
                if (_stakedCollateralNFTs.length > 1) {
                    return 2; //multi-token loan not allowed in tier.
                }
            }
        }

        if (
            _loanAmount >
            getMaxLoanAmount(
                _collateralinStable,
                traditionalTierData.loantoValue
            )
        ) {
            //allowed ltv
            return 3;
        }

        return 200;
    }

    function validateNFTSpTierforNFTs(
        uint256 _loanAmount,
        uint256 _collateralinStable,
        address[] memory _stakedCollateralNFTs,
        LibGovNFTTierStorage.NFTTierData memory _nftTierData,
        LibGovNFTTierStorage.SingleSPTierData memory _nftSpTier
    ) internal pure returns (uint256) {
        if (_stakedCollateralNFTs.length > 1 && !_nftSpTier.multiNFT) {
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
        LibVCTierStorage.VCNFTTier memory _vcTier
    ) internal view returns (uint256) {
        LibGovTierStorage.TierData memory traditionalTierData = IGovTier(
            address(this)
        ).getSingleTierData(_vcTier.traditionalTier);

        if (traditionalTierData.singleNFT || traditionalTierData.multiNFT) {
            if (!traditionalTierData.multiNFT) {
                if (_stakedCollateralNFTs.length > 1) {
                    return 2; //multi-nfts loan not allowed in nft traditional tier.
                }
            }
        }

        if (
            _loanAmount >
            getMaxLoanAmount(
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

    /// @dev Returns max loan amount a borrower can borrow
    /// @param _collateralTokeninStable amount of collateral in stable token amount
    /// @param _tierLevelLTVPercentage tier level percentage value
    function getMaxLoanAmount(
        uint256 _collateralTokeninStable,
        uint256 _tierLevelLTVPercentage
    ) internal pure returns (uint256) {
        uint256 maxLoanAmountAllowed = (_collateralTokeninStable *
            _tierLevelLTVPercentage) / 100;
        return maxLoanAmountAllowed;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library LibGovTierStorage {
    bytes32 constant GOVTIER_STORAGE_POSITION =
        keccak256("diamond.standard.GOVTIER.storage");

    struct TierData {
        uint256 govHoldings; // Gov  Holdings to check if it lies in that tier
        uint8 loantoValue; // LTV percentage of the Gov Holdings
        bool govIntel; //checks that if tier level have following access
        bool singleToken;
        bool multiToken;
        bool singleNFT;
        bool multiNFT;
        bool reverseLoan;
    }

    struct GovTierStorage {
        mapping(bytes32 => TierData) tierLevels; //data of the each tier level
        mapping(address => bytes32) tierLevelbyAddress;
        bytes32[] allTierLevelKeys; //list of all added tier levels. Stores the key for mapping => tierLevels
        address[] allTierLevelbyAddress;
        address addressProvider;
        bool isInitializedGovtier;
    }

    function govTierStorage()
        internal
        pure
        returns (GovTierStorage storage es)
    {
        bytes32 position = GOVTIER_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library LibVCTierStorage {
    bytes32 constant VCTIER_STORAGE_POSITION =
        keccak256("diamond.standard.VCTIER.storage");
    struct VCNFTTier {
        address nftContract;
        bytes32 traditionalTier;
        address[] spAllowedTokens;
        address[] spAllowedNFTs;
    }

    struct VCTierStorage {
        mapping(address => VCNFTTier) vcNftTiers;
        address[] vcTiersKeys;
    }

    function vcTierStorage() internal pure returns (VCTierStorage storage es) {
        bytes32 position = VCTIER_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library LibGovNFTTierStorage {
    bytes32 constant GOVNFTTIER_STORAGE_POSITION =
        keccak256("diamond.standard.GOVNFTTier.storage");

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

    struct GovNFTTierStorage {
        mapping(uint256 => SingleSPTierData) spTierLevels;
        mapping(address => NFTTierData) nftTierLevels;
        address[] nftTierLevelsKeys;
        uint256[] spTierLevelKeys;
    }

    function govNftTierStorage()
        internal
        pure
        returns (GovNFTTierStorage storage es)
    {
        bytes32 position = GOVNFTTIER_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

library LibMarketStorage {
    bytes32 constant MARKET_STORAGE_POSITION =
        keccak256("diamond.standard.MARKET.storage");

    enum TierType {
        GOV_TIER,
        NFT_TIER,
        NFT_SP_TIER,
        VC_TIER
    }

    enum LoanStatus {
        ACTIVE,
        INACTIVE,
        CLOSED,
        CANCELLED,
        LIQUIDATED
    }

    enum LoanTypeToken {
        SINGLE_TOKEN,
        MULTI_TOKEN
    }

    enum LoanTypeNFT {
        SINGLE_NFT,
        MULTI_NFT
    }

    struct LenderDetails {
        address lender;
        uint256 activationLoanTimeStamp;
        bool autoSell;
    }

    struct LenderDetailsNFT {
        address lender;
        uint256 activationLoanTimeStamp;
    }

    struct LoanDetailsToken {
        uint256 loanAmountInBorrowed; //total Loan Amount in Borrowed stable coin
        uint256 termsLengthInDays; //user choose terms length in days
        uint32 apyOffer; //borrower given apy percentage
        LoanTypeToken loanType; //Single-ERC20, Multiple staked ERC20,
        bool isPrivate; //private loans will not appear on loan market
        bool isInsured; //Future use flag to insure funds as they go to protocol.
        address[] stakedCollateralTokens; //single - or multi token collateral tokens wrt tokenAddress
        uint256[] stakedCollateralAmounts; // collateral amounts
        address borrowStableCoin; // address of the stable coin borrow wants
        LoanStatus loanStatus; //current status of the loan
        address borrower; //borrower's address
        uint256 paybackAmount; // track the record of payback amount
        bool[] isMintSp; // flag for the mint VIP token at the time of creating loan
        TierType tierType;
    }

    struct LoanDetailsNFT {
        address[] stakedCollateralNFTsAddress; //single nft or multi nft addresses
        uint256[] stakedCollateralNFTId; //single nft id or multinft id
        uint256[] stakedNFTPrice; //single nft price or multi nft price //price fetch from the opensea or rarible or maunal input price
        uint256 loanAmountInBorrowed; //total Loan Amount in USD
        uint32 apyOffer; //borrower given apy percentage
        LoanTypeNFT loanType; //Single NFT and multiple staked NFT
        LoanStatus loanStatus; //current status of the loan
        uint56 termsLengthInDays; //user choose terms length in days
        bool isPrivate; //private loans will not appear on loan market
        bool isInsured; //Future use flag to insure funds as they go to protocol.
        address borrower; //borrower's address
        address borrowStableCoin; //borrower stable coin,
        TierType tierType;
    }

    struct LoanDetailsNetwork {
        uint256 loanAmountInBorrowed; //total Loan Amount in Borrowed stable coin
        uint256 termsLengthInDays; //user choose terms length in days
        uint32 apyOffer; //borrower given apy percentage
        bool isPrivate; //private loans will not appear on loan market
        bool isInsured; //Future use flag to insure funds as they go to protocol.
        uint256 collateralAmount; // collateral amount in native coin
        address borrowStableCoin; // address of the borrower requested stable coin
        LoanStatus loanStatus; //current status of the loan
        address payable borrower; //borrower's address
        uint256 paybackAmount; // paybacked amount of the indiviual loan
    }

    struct MarketStorage {
        mapping(uint256 => LoanDetailsToken) borrowerLoanToken; //saves the loan details for each loanId
        mapping(uint256 => LenderDetails) activatedLoanToken; //saves the information of the lender for each loanId of the token loan
        mapping(address => uint256[]) borrowerLoanIdsToken; //erc20 tokens loan offer mapping
        mapping(address => uint256[]) activatedLoanIdsToken; //mapping address of lender => loan Ids
        mapping(uint256 => LoanDetailsNFT) borrowerLoanNFT; //Single NFT or Multi NFT loan offers mapping
        mapping(uint256 => LenderDetailsNFT) activatedLoanNFT; //mapping saves the information of the lender across the active NFT Loan Ids
        mapping(address => uint256[]) borrowerLoanIdsNFT; //mapping of borrower address to the loan Ids of the NFT.
        mapping(address => uint256[]) activatedLoanIdsNFTs; //mapping address of the lender to the activated loan offers of NFT
        mapping(uint256 => LoanDetailsNetwork) borrowerLoanNetwork; //saves information in loanOffers when createLoan function is called
        mapping(uint256 => LenderDetails) activatedLoanNetwork; // mapping saves the information of the lender across the active loanId
        mapping(address => uint256[]) borrowerLoanIdsNetwork; // users loan offers Ids
        mapping(address => uint256[]) activatedLoanIdsNetwork; // mapping address of lender to the loan Ids
        mapping(address => uint256) stableCoinWithdrawable; // mapping for storing the plaform Fee and unearned APY Fee at the time of payback or liquidation     // [token or nft or network MarketFacet][stableCoinAddress] += platformFee OR Unearned APY Fee
        mapping(address => uint256) collateralsWithdrawableToken; // mapping to add the extra collateral token amount when autosell off,   [TokenMarket][collateralToken] += exceedaltcoins;  // liquidated collateral on autsell off
        mapping(address => uint256) collateralsWithdrawableNetwork; // mapping to add the exceeding collateral amount after transferring the lender amount,  when liquidation occurs on autosell off
        mapping(address => uint256) loanActivateLimit; // loan lend limit of each market for each wallet address
        uint256[] loanOfferIdsToken; //array of all loan offer ids of the ERC20 tokens Single or Multiple.
        uint256[] loanOfferIdsNFTs; //array of all loan offer ids of the NFT tokens Single or Multiple
        uint256[] loanOfferIdsNetwork; //array of all loan offer ids of the native coin
        uint256 loanIdToken;
        uint256 loanIdNft;
        uint256 loanIdNetwork;
        address aggregator1Inch;
        mapping(address => mapping(address => uint256)) liquidatedSUNTokenbalances; //mapping of wallet address to track the approved claim token balances when loan is liquidated // wallet address lender => sunTokenAddress => balanceofSUNToken
    }

    function marketStorage() internal pure returns (MarketStorage storage es) {
        bytes32 position = MARKET_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
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
pragma solidity ^0.8.10;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamond Standard: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import {IDiamondCut} from "../interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "../interfaces/IDiamondLoupe.sol";
import {IERC165} from "../interfaces/IERC165.sol";
import {IERC173} from "../interfaces/IERC173.sol";
import {LibMeta} from "./LibMeta.sol";

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint16 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint16 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferredDiamond(
        address indexed previousOwner,
        address indexed newOwner
    );

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferredDiamond(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(
            LibMeta.msgSender() == diamondStorage().contractOwner,
            "LibDiamond: Must be contract owner"
        );
    }

    event DiamondCut(
        IDiamondCut.FacetCut[] _diamondCut,
        address _init,
        bytes _calldata
    );

    function addDiamondFunctions(
        address _diamondCutFacet,
        address _diamondLoupeFacet,
        address _ownershipFacet
    ) internal {
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](3);
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = IDiamondCut.diamondCut.selector;
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: _diamondCutFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
        functionSelectors = new bytes4[](5);
        functionSelectors[0] = IDiamondLoupe.facets.selector;
        functionSelectors[1] = IDiamondLoupe.facetFunctionSelectors.selector;
        functionSelectors[2] = IDiamondLoupe.facetAddresses.selector;
        functionSelectors[3] = IDiamondLoupe.facetAddress.selector;
        functionSelectors[4] = IERC165.supportsInterface.selector;
        cut[1] = IDiamondCut.FacetCut({
            facetAddress: _diamondLoupeFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
        functionSelectors = new bytes4[](2);
        functionSelectors[0] = IERC173.transferOwnership.selector;
        functionSelectors[1] = IERC173.owner.selector;
        cut[2] = IDiamondCut.FacetCut({
            facetAddress: _ownershipFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
        diamondCut(cut, address(0), "");
    }

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (
            uint256 facetIndex;
            facetIndex < _diamondCut.length;
            facetIndex++
        ) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        // uint16 selectorCount = uint16(diamondStorage().selectors.length);
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Add facet can't be address(0)"
        );
        uint16 selectorPosition = uint16(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            enforceHasContractCode(
                _facetAddress,
                "LibDiamondCut: New facet has no code"
            );
            ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition = uint16(ds.facetAddresses.length);
            ds.facetAddresses.push(_facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(
                oldFacetAddress == address(0),
                "LibDiamondCut: Can't add function that already exists"
            );
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(
                selector
            );
            ds
                .selectorToFacetAndPosition[selector]
                .facetAddress = _facetAddress;
            ds
                .selectorToFacetAndPosition[selector]
                .functionSelectorPosition = selectorPosition;
            selectorPosition++;
        }
    }

    function replaceFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Add facet can't be address(0)"
        );
        uint16 selectorPosition = uint16(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            enforceHasContractCode(
                _facetAddress,
                "LibDiamondCut: New facet has no code"
            );
            ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition = uint16(ds.facetAddresses.length);
            ds.facetAddresses.push(_facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(
                oldFacetAddress != _facetAddress,
                "LibDiamondCut: Can't replace function with same function"
            );
            removeFunction(oldFacetAddress, selector);
            // add function
            ds
                .selectorToFacetAndPosition[selector]
                .functionSelectorPosition = selectorPosition;
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(
                selector
            );
            ds
                .selectorToFacetAndPosition[selector]
                .facetAddress = _facetAddress;
            selectorPosition++;
        }
    }

    function removeFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(
            _facetAddress == address(0),
            "LibDiamondCut: Remove facet address must be address(0)"
        );
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            removeFunction(oldFacetAddress, selector);
        }
    }

    function removeFunction(address _facetAddress, bytes4 _selector) internal {
        DiamondStorage storage ds = diamondStorage();
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Can't remove function that doesn't exist"
        );
        // an immutable function is a function defined directly in a diamond
        require(
            _facetAddress != address(this),
            "LibDiamondCut: Can't remove immutable function"
        );
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition;
        uint256 lastSelectorPosition = ds
            .facetFunctionSelectors[_facetAddress]
            .functionSelectors
            .length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds
                .facetFunctionSelectors[_facetAddress]
                .functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[
                    selectorPosition
                ] = lastSelector;
            ds
                .selectorToFacetAndPosition[lastSelector]
                .functionSelectorPosition = uint16(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[
                    lastFacetAddressPosition
                ];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds
                    .facetFunctionSelectors[lastFacetAddress]
                    .facetAddressPosition = uint16(facetAddressPosition);
            }
            ds.facetAddresses.pop();
            delete ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata)
        internal
    {
        if (_init == address(0)) {
            require(
                _calldata.length == 0,
                "LibDiamondCut: _init is address(0) but_calldata is not empty"
            );
        } else {
            require(
                _calldata.length > 0,
                "LibDiamondCut: _calldata is empty but _init is not address(0)"
            );
            if (_init != address(this)) {
                enforceHasContractCode(
                    _init,
                    "LibDiamondCut: _init address has no code"
                );
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (success == false) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(
        address _contract,
        string memory _errorMessage
    ) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize != 0, _errorMessage);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

library LibProtocolStorage {
    bytes32 constant PROTOCOLREGISTRY_STORAGE_POSITION =
        keccak256("diamond.standard.PROTOCOLREGISTRY.storage");

    enum TokenType {
        ISDEX,
        ISELITE,
        ISVIP
    }

    // Token Market Data
    struct Market {
        address dexRouter;
        address gToken;
        bool isMint;
        TokenType tokenType;
        bool isTokenEnabledAsCollateral;
    }

    struct ProtocolStorage {
        uint256 govPlatformFee;
        uint256 govAutosellFee;
        uint256 govThresholdFee;
        mapping(address => address[]) approvedSps; // tokenAddress => spWalletAddress
        mapping(address => Market) approvedTokens; // tokenContractAddress => Market struct
        mapping(address => bool) approveStable; // stable coin address enable or disable in protocol registry
        address[] allApprovedSps; // array of all approved SP Wallet Addresses
        address[] allapprovedTokenContracts; // array of all Approved ERC20 Token Contracts
    }

    function protocolRegistryStorage()
        internal
        pure
        returns (ProtocolStorage storage es)
    {
        bytes32 position = PROTOCOLREGISTRY_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

library LibLiquidatorStorage {
    bytes32 constant LIQUIDATOR_STORAGE =
        keccak256("diamond.standard.LIQUIDATOR.storage");
    struct LiquidatorStorage {
        mapping(address => bool) whitelistLiquidators; // list of already approved liquidators.
        mapping(address => mapping(address => uint256)) liquidatedSUNTokenbalances; //mapping of wallet address to track the approved claim token balances when loan is liquidated // wallet address lender => sunTokenAddress => balanceofSUNToken
        address[] whitelistedLiquidators; // list of all approved liquidator addresses. Stores the key for mapping approvedLiquidators
        address aggregator1Inch;
        bool isInitializedLiquidator;
    }

    function liquidatorStorage()
        internal
        pure
        returns (LiquidatorStorage storage ls)
    {
        bytes32 position = LIQUIDATOR_STORAGE;
        assembly {
            ls.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

library LibAdminStorage {
    bytes32 constant ADMINREGISTRY_STORAGE_POSITION =
        keccak256("diamond.standard.ADMINREGISTRY.storage");

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

    struct AdminStorage {
        mapping(address => AdminAccess) approvedAdminRoles; // approve admin roles for each address
        mapping(uint8 => mapping(address => AdminAccess)) pendingAdminRoles; // mapping of admin role keys to admin addresses to admin access roles
        mapping(uint8 => mapping(address => address[])) areByAdmins; // list of admins approved by other admins, for the specific key
        //admin role keys
        uint8 PENDING_ADD_ADMIN_KEY;
        uint8 PENDING_EDIT_ADMIN_KEY;
        uint8 PENDING_REMOVE_ADMIN_KEY;
        uint8[] PENDING_KEYS; // ADD: 0, EDIT: 1, REMOVE: 2
        address[] allApprovedAdmins; //list of all approved admin addresses
        address[][] pendingAdminKeys; //list of pending addresses for each key
        address superAdmin;
    }

    function adminRegistryStorage()
        internal
        pure
        returns (AdminStorage storage es)
    {
        bytes32 position = ADMINREGISTRY_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {LibMeta} from "./../../shared/libraries/LibMeta.sol";

/**
 * @dev Library version of the OpenZeppelin Pausable contract with Diamond storage.
 * See: https://docs.openzeppelin.com/contracts/4.x/api/security#Pausable
 * See: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/Pausable.sol
 */
library LibPausable {
    struct Storage {
        bool paused;
    }

    bytes32 private constant STORAGE_SLOT =
        keccak256("diamond.standard.Pausable.storage");

    /**
     * @dev Returns the storage.
     */
    function _storage() private pure returns (Storage storage s) {
        bytes32 slot = STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            s.slot := slot
        }
    }

    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev Reverts when paused.
     */
    function enforceNotPaused() internal view {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Reverts when not paused.
     */
    function enforcePaused() internal view {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() internal view returns (bool) {
        return _storage().paused;
    }

    /**
     * @dev Triggers stopped state.
     */
    function _pause() internal {
        _storage().paused = true;
        emit Paused(LibMeta.msgSender());
    }

    /**
     * @dev Returns to normal state.
     */
    function _unpause() internal {
        _storage().paused = false;
        emit Unpaused(LibMeta.msgSender());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
    /// These functions are expected to be called frequently
    /// by tools.

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet)
        external
        view
        returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses()
        external
        view
        returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector)
        external
        view
        returns (address facetAddress_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library LibMeta {
    function msgSender() internal view returns (address sender_) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender_ := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender_ = msg.sender;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
/* is ERC165 */
interface IERC173 {
    /// @notice Get the address of the owner
    /// @return owner_ The address of the owner.
    function owner() external view returns (address owner_);

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
}