// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {
    ERC721PartnerSeaDropUpgradeable
} from "../ERC721PartnerSeaDropUpgradeable.sol";

/*
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOl,.....'ckXMMMMMMMMWx'.lXMMMMMMMMKc.......';dXMMMW0l,....'cOWMNo..cXMMMMMMNl..lNMMk,.;0MMMMMMMMNo.........,
MMMMMMMMMMWWWWWMMMMMMMMMMMMMMMMMMMMMMMMWOc'..';:;,..'dNMMMMMMM0;..'xWMMMMMMMK:...,,,'...:0WWk,..';:,.,xNMNl..:XMMMMMMXc..cXMWx..,OMMMMMMMMNl...',,,,,:
MMMMMMWX00000000KNMMMMMMMMMMMMMMMMMMMMNd...ckXNWWX0dxXWMMMMMMK:....'kWMMMMMMK:..lXNNXO;..cXK;..cKNWNKKWMMNl..:XMMMMMMXc..cXMWx..'OMMMMMMMMNl..:0NNNNNN
MMMMNKOkxdooooddkk0XWMMMMMMMMMMMMMMMMWx..'xNMMMMMMMMMMMMMMMMXc..;:..,OWMMMMMK:..lXNNXO;..cXXl..'okKNWMMMMNl..:XMMMMMMXc..cXMWx..'OMMMMMMMMNl..,dkOkOXM
MMMNOkxo::;;;;;;cdxkOXWMMMMMMMMMMMMMMNl..:XMMMMMMMMMMMMMMMMXl..;0Xl..:0MMMMMK:...,,,,...:0WMXx:'...;lkXMMNl..:XMMMMMMXc..cXMMx..,OMMMMMMMMNl.......'kW
MMW0kklcc::;;;;;,;coxxOXMMMMMMMMMMMMMNl..:KMMMMMMMMMMMMMMMNd...lkOo'..cKMMMMK:..,ccclldONMMMMMWKOdc'..:0WNl..:XMMMMMMXc..cXMMx..'OMMMMMMMMNl..,dkkkOXM
MMNOkd:cc:;;;;;;,,,,:odxONMMMMMMMMMMMMO,..cKWMMMMMMWKKWMMWx'...........lXMMMK;..oNMMMMMMMMMMWNWMMMWO,..oNWd..,OWMMMMWO;..oWMMx..'OMMMMMMMMNl..:XMMMMMM
MMWOkkc;;;;;;;;,,,,'',lO0KXNMMMMMMMMMMWO:..'lxO00Odc''dNWk'..lkkkkkkd,..oNMMK:..oNMMMMMMMMWKl;cxO0Oo'..xWMKc..,ok00ko,..:KMMMx...okOOOOOKWNl..,dkkOOOO
MMMNOkxl:;;;;;,,,,,;lxkxdxxkOXWMMMMMMMMMXkc,.......';o0W0;..oNMMMMMMWk,.'xWMK:..oWMMMMMMMMW0o;.......:kNMMMXx:'......':dXMMMMk..........lNNo..........
MMMMNKOkxl;;;,,,,:okkl;,;;:oxkOXWMMMMMMMMMWX0kxxxkOKNMMWXOk0NMMMMMMMMWKkk0WMW0kkKWMMMMMMMMMMWN0kxxxkKNMMMMMMMNKOkxxxOKNMMMMMMXOkkkkkkkkkKWWKkkkkkkkkkO
MMMMMMNKOkdl;,,;oOkl,''''''';oxk0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMN0kxdcckOo;'''''''''',:dxk0NMMMMMMMMMMMMMMMMMMMN0kOXMMMMMMMWKkk0WMMMMMMWNKOxxxxOKNWMMMMMW0kkKWMMMMMMN0kOXMMMMNKkxxxk0NWMMW0kkkkkkkkk0WMMMMMMMM
MMMMMMMMMMN0kOK0c'''''''''''',,;lxO0XWMMMMMMMMMMMMMMMMM0;..dWMMMMMMNl..:KMMMMN0o;........;o0WMMMK:..oNMMMMMMK;..dWMNk:.......cKMMK:.........cKMMMMMMMM
MMMMMMMMMMMMNNXkdc,'''''''',,,;;:lk00NMMMMMMMMMMMMMMMMM0,..dWMMMMMMNl..:KMMMXl...:dO00Od:...oXMMK:..oNMMMMMM0;..dWWk'..lO0OxdOWMMK:..;xkOkOk0WMMMMMMMM
MMMMMMMMMMMMMMN0kxo:,'''''',;;;:ccx00NMMMMMMMMMMMMMMMMM0,..oXNNNNNNKc..:KMXOl..;kNMMMMMMNk,..lXMK:..oNMMMMMM0;..dWWx...oKNWMMMMMMK:..cKNNNNWMMMMMMMMMM
MMMMMMMMMMMMMMMMN0kxdc,'''',:c::clO0KWMMMMMMMMMMMMMMMMM0,...,,,,,,,,...:KMk:'..xWMMMMMMMMWx..'OMK:..oNMMMMMM0;..dWMXd,..';lx0NMMMK:...,,,,cKMMMMMMMMMM
MMMMMMMMMMMMMMMMMMN0kxdc,'',,;;:okO0NWMMMMMMMMMMMMMMMMM0,..,cllllllc'..:KMk;..'kMMMMMMMMMMk'..kMK:..lNMMMMMM0;..dWMMWXOdc,...:OWMK:..'cllldXMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMN0kxdolclodxkOKNMMMMMMMMMMMMMMMMMMM0,..dWMMMMMMNl..:KMKd;..cXMMMMMMMMXc..;KMXc..cXMMMMMMO,..xWMMMMMMWNO:..;0MK:..lNMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMNKOOOOOO00KNWMMMMMMMMMMMMMMMMMMMM0,..dWMMMMMMNl..:KMWWO;..;xKNWWNKx;..;OWMWx'..l0NWWXk:..:KMWKdd0XNWKl..,0MK:..cKNNNNNNWMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWMMMMMMMMMMMMMMMMMMMMMMMM0,..dWMMMMMMNl..:KMMMWKo,...,:;,...,dKWMMMNk:...,;;,..'lKWMNd'..,;;,..,kWMK:...,,,,,,c0MMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0:.'xWMMMMMMNo..cXMMMMMWKd;......:dKWMMMMMMMXd;.....'ckNMMMMNkc'....,o0WMMXc.........;OMMMMMMMM
*/

library CapsuleChestsStorage {
    struct Layout {
        /// @notice The Capsule Cards address that can burn chests to unpack
        ///         into cards.
        address capsuleCards;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("seaDrop.contracts.storage.capsuleChests");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

/*
 * @notice This contract uses ERC721PartnerSeaDrop,
 *         an ERC721A token contract that is compatible with SeaDrop.
 *         The set Capsule Cards contract is the only one that can call
 *         the burn function to unpack a chest into individual cards.
 */
contract CapsuleChests is ERC721PartnerSeaDropUpgradeable {
    using CapsuleChestsStorage for CapsuleChestsStorage.Layout;

    /**
     * @notice A token can only be burned by the set Capsule Cards address.
     */
    error BurnIncorrectSender();

    function YO3setCapsuleCardsAddress(address newCapsuleCardsAddress)
        external
        onlyOwner
    {
        CapsuleChestsStorage.layout().capsuleCards = newCapsuleCardsAddress;
    }

    function YO3getCapsuleCardsAddress() public view returns (address) {
        return CapsuleChestsStorage.layout().capsuleCards;
    }

    /**
     * @notice Destroys `tokenId`, only callable by the set Capsule Cards
     *         address.
     *
     * @param tokenId The token id to burn.
     */
    function burn(uint256 tokenId) external {
        if (msg.sender != CapsuleChestsStorage.layout().capsuleCards) {
            revert BurnIncorrectSender();
        }

        _burn(tokenId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
function c_827753e8(bytes8 c__827753e8) pure {}
function c_true827753e8(bytes8 c__827753e8) pure returns (bool){ return true; }
function c_false827753e8(bytes8 c__827753e8) pure returns (bool){ return false; }


import { ERC721SeaDropUpgradeable } from "./ERC721SeaDropUpgradeable.sol";

import { ISeaDropUpgradeable } from "./interfaces/ISeaDropUpgradeable.sol";

import { AllowListData, PublicDrop, TokenGatedDropStage, SignedMintValidationParams } from "./lib/SeaDropStructsUpgradeable.sol";

import { TwoStepAdministeredUpgradeable } from "../utility-contracts/src/TwoStepAdministeredUpgradeable.sol";
import { TwoStepAdministeredStorage } from "../utility-contracts/src/TwoStepAdministeredStorage.sol";

/**
 * @title  ERC721PartnerSeaDrop
 * @author James Wenzel (emo.eth)
 * @author Ryan Ghods (ralxz.eth)
 * @author Stephan Min (stephanm.eth)
 * @notice ERC721PartnerSeaDrop is a token contract that contains methods
 *         to properly interact with SeaDrop, with additional administrative
 *         functionality tailored for business requirements around partnered
 *         mints with off-chain agreements in place between two parties.
 *
 *         The "Owner" should control mint specifics such as price and start.
 *         The "Administrator" should control fee parameters.
 *
 *         Otherwise, for ease of administration, either Owner or Administrator
 *         should be able to configure mint parameters. They have the ability
 *         to override each other's actions in many circumstances, which is
 *         why the establishment of off-chain trust is important.
 *
 *         Note: An Administrator is not required to interface with SeaDrop.
 */
contract ERC721PartnerSeaDropUpgradeable is ERC721SeaDropUpgradeable, TwoStepAdministeredUpgradeable {
    using TwoStepAdministeredStorage for TwoStepAdministeredStorage.Layout;
function c_60c9757a(bytes8 c__60c9757a) internal pure {}
function c_true60c9757a(bytes8 c__60c9757a) internal pure returns (bool){ return true; }
function c_false60c9757a(bytes8 c__60c9757a) internal pure returns (bool){ return false; }
modifier c_modf14a66b2{ c_60c9757a(0x6b63414c92a572c0); /* modifier-post */ 
 _; }
modifier c_modfc7144ec{ c_60c9757a(0x89771e8aaddb4a1b); /* modifier-pre */ 
 _; }
modifier c_modfed485eb{ c_60c9757a(0x3866d9e83daa600f); /* modifier-post */ 
 _; }
modifier c_mode42dbd3d{ c_60c9757a(0x1d7e2a066c4b64eb); /* modifier-pre */ 
 _; }
modifier c_mod450f0345{ c_60c9757a(0x887f1a2c3ec57dc0); /* modifier-post */ 
 _; }
modifier c_mod0425b4f0{ c_60c9757a(0x7b58e7b26be55375); /* modifier-pre */ 
 _; }
modifier c_modb2da17f4{ c_60c9757a(0x85487e7e799289fa); /* modifier-post */ 
 _; }
modifier c_mod5f3892c8{ c_60c9757a(0x75ff3f05190066c2); /* modifier-pre */ 
 _; }
modifier c_mod11dd9477{ c_60c9757a(0x993cc62c19805681); /* modifier-post */ 
 _; }
modifier c_mod6cb9d867{ c_60c9757a(0xf601ce9065465f3b); /* modifier-pre */ 
 _; }
modifier c_modee32e96b{ c_60c9757a(0xe5a5aec627f1a296); /* modifier-post */ 
 _; }
modifier c_mod08f92c65{ c_60c9757a(0x35018dbbb4395c73); /* modifier-pre */ 
 _; }
modifier c_mod64a1778e{ c_60c9757a(0x10750da062b15134); /* modifier-post */ 
 _; }
modifier c_moddb1fb247{ c_60c9757a(0xbaffdc5ffc771447); /* modifier-pre */ 
 _; }
modifier c_mod2448366b{ c_60c9757a(0x6ce567c924cc4eb9); /* modifier-post */ 
 _; }
modifier c_mod5ee91b96{ c_60c9757a(0x08934a5cc8da8107); /* modifier-pre */ 
 _; }
modifier c_mod97a6928b{ c_60c9757a(0x43a8c46c69aa1ddc); /* modifier-post */ 
 _; }
modifier c_mod215415f4{ c_60c9757a(0xb0929e52b61a0b4d); /* modifier-pre */ 
 _; }
modifier c_mod3bc086f7{ c_60c9757a(0xbc1068ee70294d02); /* modifier-post */ 
 _; }
modifier c_mod0d64bc36{ c_60c9757a(0x9f7c8c867c938aa5); /* modifier-pre */ 
 _; }
modifier c_mod400c8bc6{ c_60c9757a(0xa53e559b7c5c6c10); /* modifier-post */ 
 _; }
modifier c_mod0933e736{ c_60c9757a(0xb80e0d75f7c30f23); /* modifier-pre */ 
 _; }
modifier c_mod910a6ae8{ c_60c9757a(0xc2b2ddb6363edf87); /* modifier-post */ 
 _; }
modifier c_modb829701c{ c_60c9757a(0x1371bab9dce5858f); /* modifier-pre */ 
 _; }
modifier c_modd7ef1442{ c_60c9757a(0x8230c2a275b1c47a); /* modifier-post */ 
 _; }
modifier c_mod2005f4a3{ c_60c9757a(0x5bde5daf75672baf); /* modifier-pre */ 
 _; }
modifier c_modb4df92e2{ c_60c9757a(0x05d3c77b1c14e383); /* modifier-post */ 
 _; }
modifier c_mod085fc00f{ c_60c9757a(0xce617cdee1c9798d); /* modifier-pre */ 
 _; }
modifier c_mod976c2dc8{ c_60c9757a(0x755e683a38d63af1); /* modifier-post */ 
 _; }
modifier c_mod76e882ec{ c_60c9757a(0xf82cdea9693e4b11); /* modifier-pre */ 
 _; }
modifier c_mod36fd2584{ c_60c9757a(0x0cd232b15cee718e); /* modifier-post */ 
 _; }
modifier c_mode60ba18b{ c_60c9757a(0x15124ed78baddda7); /* modifier-pre */ 
 _; }

    /// @notice To prevent Owner from overriding fees, Administrator must
    ///         first initialize with fee.
    error AdministratorMustInitializeWithFee();

    /**
     * @notice Deploy the token contract with its name, symbol,
     *         administrator, and allowed SeaDrop addresses.
     */
    function __ERC721PartnerSeaDrop_init(
        string memory name,
        string memory symbol,
        address administrator,
        address[] memory allowedSeaDrop
    ) internal onlyInitializing {
        __ERC721A_init_unchained(name, symbol);
        __ConstructorInitializable_init_unchained();
        __TwoStepOwnable_init_unchained();
        __ERC721ContractMetadata_init_unchained(name, symbol);
        __ReentrancyGuard_init_unchained();
        __ERC721SeaDrop_init_unchained(name, symbol, allowedSeaDrop);
        __TwoStepAdministered_init_unchained(administrator);
        __ERC721PartnerSeaDrop_init_unchained(name, symbol, administrator, allowedSeaDrop);
    }

    function __ERC721PartnerSeaDrop_init_unchained(
        string memory,
        string memory,
        address,
        address[] memory
    ) internal onlyInitializing {c_60c9757a(0x46227060ee4c1372); /* function */ 
}

    /**
     * @notice Mint tokens, restricted to the SeaDrop contract.
     *
     * @param minter   The address to mint to.
     * @param quantity The number of tokens to mint.
     */
    function mintSeaDrop(address minter, uint256 quantity)
        external
        payable
        virtual
        override
         c_mode60ba18b onlyAllowedSeaDrop(msg.sender) c_mod36fd2584 
    {c_60c9757a(0x49183c9c8aca4962); /* function */ 

        // Extra safety check to ensure the max supply is not exceeded.
c_60c9757a(0x0811ae00921e5e4e); /* line */ 
        c_60c9757a(0xa3bab4750d7fc687); /* statement */ 
if (_totalMinted() + quantity > maxSupply()) {c_60c9757a(0xae01f5ee1b8981e0); /* branch */ 

c_60c9757a(0x91eda2e7a01ed4ad); /* line */ 
            revert MintQuantityExceedsMaxSupply(
                _totalMinted() + quantity,
                maxSupply()
            );
        }else { c_60c9757a(0x46f59258bfdb83e3); /* branch */ 
}

        // Mint the quantity of tokens to the minter.
c_60c9757a(0xd48d819bf71bc721); /* line */ 
        c_60c9757a(0x1b35ec695b583986); /* statement */ 
_mint(minter, quantity);
    }

    /**
     * @notice Update the allowed SeaDrop contracts.
     *         Only the owner or administrator can use this function.
     *
     * @param allowedSeaDrop The allowed SeaDrop addresses.
     */
    function updateAllowedSeaDrop(address[] calldata allowedSeaDrop)
        external
        override
         c_mod76e882ec onlyOwnerOrAdministrator c_mod976c2dc8 
    {c_60c9757a(0x38e299f892b3f7a1); /* function */ 

c_60c9757a(0xd3da06e94ee2ce42); /* line */ 
        c_60c9757a(0xe272a36f66bd86c4); /* statement */ 
_updateAllowedSeaDrop(allowedSeaDrop);
    }

    /**
     * @notice Update the public drop data for this nft contract on SeaDrop.
     *         Only the owner or administrator can use this function.
     *
     *         The administrator can only update `feeBps`.
     *
     * @param seaDropImpl The allowed SeaDrop contract.
     * @param publicDrop  The public drop data.
     */
    function updatePublicDrop(
        address seaDropImpl,
        PublicDrop calldata publicDrop
    )
        external
        virtual
        override
         c_mod085fc00f onlyOwnerOrAdministrator c_modb4df92e2 
         c_mod2005f4a3 onlyAllowedSeaDrop(seaDropImpl) c_modd7ef1442 
    {c_60c9757a(0xa068d4789837b878); /* function */ 

        // Track the previous public drop data.
c_60c9757a(0x67903bb92879a819); /* line */ 
        c_60c9757a(0xef7e28f8939fc91b); /* statement */ 
PublicDrop memory retrieved = ISeaDropUpgradeable(seaDropImpl).getPublicDrop(
            address(this)
        );

        // Track the newly supplied drop data.
c_60c9757a(0x7888442f69136c42); /* line */ 
        c_60c9757a(0x96b74a8d0e536f51); /* statement */ 
PublicDrop memory supplied = publicDrop;

        // Only the administrator (OpenSea) can set feeBps.
c_60c9757a(0x79d12bedd0d1f4d0); /* line */ 
        c_60c9757a(0x9118c0bf4fa8ac23); /* statement */ 
if (msg.sender != TwoStepAdministeredStorage.layout().administrator) {c_60c9757a(0x8ac6dad8b7ee92a2); /* branch */ 

            // Administrator must first set fee.
c_60c9757a(0xbaef42845ae435d2); /* line */ 
            c_60c9757a(0x364b14e0af5e3046); /* statement */ 
if (retrieved.maxTotalMintableByWallet == 0) {c_60c9757a(0x1e80a7b9bfdc6ac5); /* branch */ 

c_60c9757a(0xff5e74443fdbef6b); /* line */ 
                revert AdministratorMustInitializeWithFee();
            }else { c_60c9757a(0xec5472bffe024ae4); /* branch */ 
}
c_60c9757a(0xd83f05cc4e901d3a); /* line */ 
            supplied.feeBps = retrieved.feeBps;
c_60c9757a(0x67b1f3e2d540ed38); /* line */ 
            supplied.restrictFeeRecipients = true;
        } else {c_60c9757a(0x40ab4d6fb81397d0); /* branch */ 

            // Administrator can only initialize
            // (maxTotalMintableByWallet > 0) and set
            // feeBps/restrictFeeRecipients.
c_60c9757a(0x67ce576f1d00a72e); /* line */ 
            c_60c9757a(0x30993261a38b29bb); /* statement */ 
uint16 maxTotalMintableByWallet = retrieved
                .maxTotalMintableByWallet;
c_60c9757a(0xeca5a176a25182b3); /* line */ 
            retrieved.maxTotalMintableByWallet = ((maxTotalMintableByWallet > 0 && c_true60c9757a(0xb4476ee656219d6f)) || c_false60c9757a(0x08c175bebc3d1e34))
                ? maxTotalMintableByWallet
                : 1;
c_60c9757a(0xc80087bc84526c4f); /* line */ 
            retrieved.feeBps = supplied.feeBps;
c_60c9757a(0x5841bbf8e4b2a8a0); /* line */ 
            retrieved.restrictFeeRecipients = true;
c_60c9757a(0xda192ae464c0c1c7); /* line */ 
            supplied = retrieved;
        }

        // Update the public drop data on SeaDrop.
c_60c9757a(0x816f5d2e87336bb6); /* line */ 
        c_60c9757a(0xbd43812c168d8490); /* statement */ 
ISeaDropUpgradeable(seaDropImpl).updatePublicDrop(supplied);
    }

    /**
     * @notice Update the allow list data for this nft contract on SeaDrop.
     *         Only the owner or administrator can use this function.
     *
     * @param seaDropImpl   The allowed SeaDrop contract.
     * @param allowListData The allow list data.
     */
    function updateAllowList(
        address seaDropImpl,
        AllowListData calldata allowListData
    )
        external
        virtual
        override
         c_modb829701c onlyOwnerOrAdministrator c_mod910a6ae8 
         c_mod0933e736 onlyAllowedSeaDrop(seaDropImpl) c_mod400c8bc6 
    {c_60c9757a(0x928ede3bd7a035aa); /* function */ 

        // Update the allow list on SeaDrop.
c_60c9757a(0x2e9366532b8ff172); /* line */ 
        c_60c9757a(0xe1c8034ca6d3d7e9); /* statement */ 
ISeaDropUpgradeable(seaDropImpl).updateAllowList(allowListData);
    }

    /**
     * @notice Update the token gated drop stage data for this nft contract
     *         on SeaDrop.
     *         Only the owner or administrator can use this function.
     *
     *         The administrator must first set `feeBps`.
     *
     *         Note: If two INonFungibleSeaDropToken tokens are doing
     *         simultaneous token gated drop promotions for each other,
     *         they can be minted by the same actor until
     *         `maxTokenSupplyForStage` is reached. Please ensure the
     *         `allowedNftToken` is not running an active drop during the
     *         `dropStage` time period.
     *
     * @param seaDropImpl     The allowed SeaDrop contract.
     * @param allowedNftToken The allowed nft token.
     * @param dropStage       The token gated drop stage data.
     */
    function updateTokenGatedDrop(
        address seaDropImpl,
        address allowedNftToken,
        TokenGatedDropStage calldata dropStage
    )
        external
        virtual
        override
         c_mod0d64bc36 onlyOwnerOrAdministrator c_mod3bc086f7 
         c_mod215415f4 onlyAllowedSeaDrop(seaDropImpl) c_mod97a6928b 
    {c_60c9757a(0xbc508548d930223c); /* function */ 

        // Track the previous drop stage data.
c_60c9757a(0xee8e20886803ca3b); /* line */ 
        c_60c9757a(0xf7e0cb840432b52e); /* statement */ 
TokenGatedDropStage memory retrieved = ISeaDropUpgradeable(seaDropImpl)
            .getTokenGatedDrop(address(this), allowedNftToken);

        // Track the newly supplied drop data.
c_60c9757a(0xa65ea46ece3a4875); /* line */ 
        c_60c9757a(0xf1a60b0ab40fba03); /* statement */ 
TokenGatedDropStage memory supplied = dropStage;

        // Only the administrator (OpenSea) can set feeBps on Partner
        // contracts.
c_60c9757a(0x0d31f10689b11617); /* line */ 
        c_60c9757a(0xda9d6d735e5e37bb); /* statement */ 
if (msg.sender != TwoStepAdministeredStorage.layout().administrator) {c_60c9757a(0x8b6cbe4ef41f2479); /* branch */ 

            // Administrator must first set fee.
c_60c9757a(0x8c61ec2942fc23f8); /* line */ 
            c_60c9757a(0xb9fe92944e0309e2); /* statement */ 
if (retrieved.maxTotalMintableByWallet == 0) {c_60c9757a(0x021f8385f360bdf2); /* branch */ 

c_60c9757a(0x3adc455b48220470); /* line */ 
                revert AdministratorMustInitializeWithFee();
            }else { c_60c9757a(0x447f888ab20ca5c6); /* branch */ 
}
c_60c9757a(0x506968fb366b66e6); /* line */ 
            supplied.feeBps = retrieved.feeBps;
c_60c9757a(0xf2b5636e81adc9eb); /* line */ 
            supplied.restrictFeeRecipients = true;
        } else {c_60c9757a(0xf99db162176f0f2f); /* branch */ 

            // Administrator can only initialize
            // (maxTotalMintableByWallet > 0) and set
            // feeBps/restrictFeeRecipients.
c_60c9757a(0x668f0cf8381f9502); /* line */ 
            c_60c9757a(0xc5bddaf4b7aca39a); /* statement */ 
uint16 maxTotalMintableByWallet = retrieved
                .maxTotalMintableByWallet;
c_60c9757a(0x6f1a8b3880cd915b); /* line */ 
            retrieved.maxTotalMintableByWallet = ((maxTotalMintableByWallet > 0 && c_true60c9757a(0x9e92c7037267b50e)) || c_false60c9757a(0x89e2705a0d3cc24d))
                ? maxTotalMintableByWallet
                : 1;
c_60c9757a(0x45b41060acbf9470); /* line */ 
            retrieved.feeBps = supplied.feeBps;
c_60c9757a(0xf808fcf0c638cbc4); /* line */ 
            retrieved.restrictFeeRecipients = true;
c_60c9757a(0xe5853d90c0c945ab); /* line */ 
            supplied = retrieved;
        }

        // Update the token gated drop stage.
c_60c9757a(0xdfb7179563fbf6d7); /* line */ 
        c_60c9757a(0x855221daac19c700); /* statement */ 
ISeaDropUpgradeable(seaDropImpl).updateTokenGatedDrop(allowedNftToken, supplied);
    }

    /**
     * @notice Update the drop URI for this nft contract on SeaDrop.
     *         Only the owner or administrator can use this function.
     *
     * @param seaDropImpl The allowed SeaDrop contract.
     * @param dropURI     The new drop URI.
     */
    function updateDropURI(address seaDropImpl, string calldata dropURI)
        external
        virtual
        override
         c_mod5ee91b96 onlyOwnerOrAdministrator c_mod2448366b 
         c_moddb1fb247 onlyAllowedSeaDrop(seaDropImpl) c_mod64a1778e 
    {c_60c9757a(0xbb6b7d8ad17f42bc); /* function */ 

        // Update the drop URI.
c_60c9757a(0x067fa3346b3387b2); /* line */ 
        c_60c9757a(0x172f119407c194c7); /* statement */ 
ISeaDropUpgradeable(seaDropImpl).updateDropURI(dropURI);
    }

    /**
     * @notice Update the allowed fee recipient for this nft contract
     *         on SeaDrop.
     *         Only the administrator can set the allowed fee recipient.
     *
     * @param seaDropImpl  The allowed SeaDrop contract.
     * @param feeRecipient The new fee recipient.
     * @param allowed      If the fee recipient is allowed.
     */
    function updateAllowedFeeRecipient(
        address seaDropImpl,
        address feeRecipient,
        bool allowed
    ) external override  c_mod08f92c65 onlyAdministrator c_modee32e96b   c_mod6cb9d867 onlyAllowedSeaDrop(seaDropImpl) c_mod11dd9477  {c_60c9757a(0x8ea0d1e9ffa6e145); /* function */ 

        // Update the allowed fee recipient.
c_60c9757a(0x15e7c6e393569512); /* line */ 
        c_60c9757a(0xc3b77d222f2061ac); /* statement */ 
ISeaDropUpgradeable(seaDropImpl).updateAllowedFeeRecipient(feeRecipient, allowed);
    }

    /**
     * @notice Update the server-side signers for this nft contract
     *         on SeaDrop.
     *         Only the owner or administrator can use this function.
     *
     * @param seaDropImpl                The allowed SeaDrop contract.
     * @param signer                     The signer to update.
     * @param signedMintValidationParams Minimum and maximum parameters to
     *                                   enforce for signed mints.
     */
    function updateSignedMintValidationParams(
        address seaDropImpl,
        address signer,
        SignedMintValidationParams memory signedMintValidationParams
    )
        external
        virtual
        override
         c_mod5f3892c8 onlyOwnerOrAdministrator c_modb2da17f4 
         c_mod0425b4f0 onlyAllowedSeaDrop(seaDropImpl) c_mod450f0345 
    {c_60c9757a(0x498b21a88c913e2a); /* function */ 

        // Track the previous signed mint validation params.
c_60c9757a(0xfe9d5a532a570a86); /* line */ 
        c_60c9757a(0xff3ec29044b988fa); /* statement */ 
SignedMintValidationParams memory retrieved = ISeaDropUpgradeable(seaDropImpl)
            .getSignedMintValidationParams(address(this), signer);

        // Track the newly supplied params.
c_60c9757a(0xf1a4626c61f0cc75); /* line */ 
        c_60c9757a(0xe32a1bc9732a0c96); /* statement */ 
SignedMintValidationParams memory supplied = signedMintValidationParams;

        // Only the administrator (OpenSea) can set feeBps on Partner
        // contracts.
c_60c9757a(0x09e1c20a7e5c9cb3); /* line */ 
        c_60c9757a(0x6b14e69c6e68f870); /* statement */ 
if (msg.sender != TwoStepAdministeredStorage.layout().administrator) {c_60c9757a(0x8642f1b6d1f82d83); /* branch */ 

            // Administrator must first set fee.
c_60c9757a(0x64838a3532078010); /* line */ 
            c_60c9757a(0xfc1d29270552f304); /* statement */ 
if (retrieved.maxMaxTotalMintableByWallet == 0) {c_60c9757a(0xd18b4cd86bc0bdc2); /* branch */ 

c_60c9757a(0xc361f269d203684f); /* line */ 
                revert AdministratorMustInitializeWithFee();
            }else { c_60c9757a(0xda8058a40df96aa5); /* branch */ 
}
c_60c9757a(0x405d2dfabdc3ff7b); /* line */ 
            supplied.minFeeBps = retrieved.minFeeBps;
c_60c9757a(0x767e30b005599cb1); /* line */ 
            supplied.maxFeeBps = retrieved.maxFeeBps;
        } else {c_60c9757a(0x8c04cc30ac09e6e8); /* branch */ 

            // Administrator can only initialize
            // (maxTotalMintableByWallet > 0) and set
            // feeBps/restrictFeeRecipients.
c_60c9757a(0x3dac27cf37be55d7); /* line */ 
            c_60c9757a(0x68f886779ffd0d78); /* statement */ 
uint24 maxMaxTotalMintableByWallet = retrieved
                .maxMaxTotalMintableByWallet;
c_60c9757a(0xe72137fc734d1ee9); /* line */ 
            retrieved
                .maxMaxTotalMintableByWallet = ((maxMaxTotalMintableByWallet > 0 && c_true60c9757a(0xbc0a1c4a73723737)) || c_false60c9757a(0x2c02638db7d11ec6))
                ? maxMaxTotalMintableByWallet
                : 1;
c_60c9757a(0xd0015be85c89a3fa); /* line */ 
            retrieved.minFeeBps = supplied.minFeeBps;
c_60c9757a(0x57bcd10590080432); /* line */ 
            retrieved.maxFeeBps = supplied.maxFeeBps;
c_60c9757a(0x70208e9f374958a2); /* line */ 
            supplied = retrieved;
        }

        // Update the signed mint validation params.
c_60c9757a(0xc1043e4f8abdacef); /* line */ 
        c_60c9757a(0xf35e9111d1ce2498); /* statement */ 
ISeaDropUpgradeable(seaDropImpl).updateSignedMintValidationParams(
            signer,
            supplied
        );
    }

    /**
     * @notice Update the allowed payers for this nft contract on SeaDrop.
     *         Only the owner or administrator can use this function.
     *
     * @param seaDropImpl The allowed SeaDrop contract.
     * @param payer       The payer to update.
     * @param allowed     Whether the payer is allowed.
     */
    function updatePayer(
        address seaDropImpl,
        address payer,
        bool allowed
    )
        external
        virtual
        override
         c_mode42dbd3d onlyOwnerOrAdministrator c_modfed485eb 
         c_modfc7144ec onlyAllowedSeaDrop(seaDropImpl) c_modf14a66b2 
    {c_60c9757a(0x0f3ba04544779ca4); /* function */ 

        // Update the payer.
c_60c9757a(0x8d9a9922f47f174b); /* line */ 
        c_60c9757a(0x20c1c7c28aa12b63); /* statement */ 
ISeaDropUpgradeable(seaDropImpl).updatePayer(payer, allowed);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
function c_465a6b07(bytes8 c__465a6b07) pure {}
function c_true465a6b07(bytes8 c__465a6b07) pure returns (bool){ return true; }
function c_false465a6b07(bytes8 c__465a6b07) pure returns (bool){ return false; }


import { ERC721ContractMetadataUpgradeable, ISeaDropTokenContractMetadataUpgradeable } from "./ERC721ContractMetadataUpgradeable.sol";

import { INonFungibleSeaDropTokenUpgradeable } from "./interfaces/INonFungibleSeaDropTokenUpgradeable.sol";

import { ISeaDropUpgradeable } from "./interfaces/ISeaDropUpgradeable.sol";

import { AllowListData, PublicDrop, TokenGatedDropStage, SignedMintValidationParams } from "./lib/SeaDropStructsUpgradeable.sol";

import { ERC721AUpgradeable } from "../ERC721A/contracts/ERC721AUpgradeable.sol";

import { ReentrancyGuardUpgradeable } from "../solmate/src/utils/ReentrancyGuardUpgradeable.sol";

import { IERC165Upgradeable } from "../openzeppelin-contracts/contracts/utils/introspection/IERC165Upgradeable.sol";

import { DefaultOperatorFilterer721Upgradeable } from "../operator-filter-registry/src/example/upgradeable/DefaultOperatorFilterer721Upgradeable.sol";
import { ERC721SeaDropStorage } from "./ERC721SeaDropStorage.sol";
import { ERC721ContractMetadataStorage } from "./ERC721ContractMetadataStorage.sol";

/**
 * @title  ERC721SeaDrop
 * @author James Wenzel (emo.eth)
 * @author Ryan Ghods (ralxz.eth)
 * @author Stephan Min (stephanm.eth)
 * @notice ERC721SeaDrop is a token contract that contains methods
 *         to properly interact with SeaDrop.
 */
contract ERC721SeaDropUpgradeable is
    ERC721ContractMetadataUpgradeable,
    INonFungibleSeaDropTokenUpgradeable,
    ReentrancyGuardUpgradeable,
    DefaultOperatorFilterer721Upgradeable
{
    using ERC721SeaDropStorage for ERC721SeaDropStorage.Layout;
    using ERC721ContractMetadataStorage for ERC721ContractMetadataStorage.Layout;
function c_d527060f(bytes8 c__d527060f) internal pure {}
function c_trued527060f(bytes8 c__d527060f) internal pure returns (bool){ return true; }
function c_falsed527060f(bytes8 c__d527060f) internal pure returns (bool){ return false; }
modifier c_mod3cfbb367{ c_d527060f(0x2074e9b39ec41e1a); /* modifier-post */ 
 _; }
modifier c_modfc5038a2{ c_d527060f(0xe1f17f1f24dadea6); /* modifier-pre */ 
 _; }
modifier c_mod43f1f644{ c_d527060f(0xdc74069346af692d); /* modifier-post */ 
 _; }
modifier c_mod10543891{ c_d527060f(0x6cd937e5844854fa); /* modifier-pre */ 
 _; }
modifier c_mod202a337c{ c_d527060f(0x4f018f5c6a852d7b); /* modifier-post */ 
 _; }
modifier c_mod6efbb7d2{ c_d527060f(0x9090bf53ae007a8a); /* modifier-pre */ 
 _; }
modifier c_modddb9c0ca{ c_d527060f(0x2de26df3a2d3c450); /* modifier-post */ 
 _; }
modifier c_modefb7bba3{ c_d527060f(0xbfcf44e4be25bff6); /* modifier-pre */ 
 _; }
modifier c_mod2b24e034{ c_d527060f(0x4c69ebf3b5c8ac92); /* modifier-post */ 
 _; }
modifier c_mod9b2b9d83{ c_d527060f(0xb5dcf175aeb32c0f); /* modifier-pre */ 
 _; }
modifier c_mod6422ee31{ c_d527060f(0xbcc7bafb163fd8b0); /* modifier-post */ 
 _; }
modifier c_mod9400e2b6{ c_d527060f(0x742cefba25d826a6); /* modifier-pre */ 
 _; }
modifier c_mod15fd79e8{ c_d527060f(0x23d3a7fe7d8bbfb8); /* modifier-post */ 
 _; }
modifier c_modafe22915{ c_d527060f(0x0c63039b371d61fb); /* modifier-pre */ 
 _; }
modifier c_mod954ed8e5{ c_d527060f(0x2ee540f28834f32c); /* modifier-post */ 
 _; }
modifier c_mod31d20c51{ c_d527060f(0xd680f65ebdb2fecb); /* modifier-pre */ 
 _; }
modifier c_mod96740165{ c_d527060f(0x7fcd41ada559f0e0); /* modifier-post */ 
 _; }
modifier c_mod676bd09a{ c_d527060f(0xe7b2d5f65ed47b2d); /* modifier-pre */ 
 _; }
modifier c_mode0c0e150{ c_d527060f(0xdbe6c16c16b4166b); /* modifier-post */ 
 _; }
modifier c_modfef441b2{ c_d527060f(0x351d9b3219bb5542); /* modifier-pre */ 
 _; }
modifier c_mod4602f1d0{ c_d527060f(0xd483f24672f003ae); /* modifier-post */ 
 _; }
modifier c_mod64041d1c{ c_d527060f(0x56f0216f7b480044); /* modifier-pre */ 
 _; }
modifier c_mod2d3609f7{ c_d527060f(0x65d754b5b701e7cc); /* modifier-post */ 
 _; }
modifier c_mod5109d810{ c_d527060f(0x2eb59f4802626a90); /* modifier-pre */ 
 _; }
modifier c_mod5a4bacf3{ c_d527060f(0x2fb80f4adb87a7b8); /* modifier-post */ 
 _; }
modifier c_mod81c4c3e7{ c_d527060f(0x021bf80cee431a15); /* modifier-pre */ 
 _; }
modifier c_mod4b291931{ c_d527060f(0x114d926e9ea94a51); /* modifier-post */ 
 _; }
modifier c_mod7ab1b03e{ c_d527060f(0x118b64ad912ed7bc); /* modifier-pre */ 
 _; }
modifier c_mod19d8392f{ c_d527060f(0x838673d4c141d72d); /* modifier-post */ 
 _; }
modifier c_mod071d6fb0{ c_d527060f(0xfd9bc5b522b4e808); /* modifier-pre */ 
 _; }
modifier c_mod97685826{ c_d527060f(0x2ede98c38c63ab14); /* modifier-post */ 
 _; }
modifier c_mod750dde0d{ c_d527060f(0x9cdc45b5dd60b3bd); /* modifier-pre */ 
 _; }
modifier c_modbc4574aa{ c_d527060f(0x256e1f2255be81e2); /* modifier-post */ 
 _; }
modifier c_mod14ddafe3{ c_d527060f(0xc6ce18ab58cda1fc); /* modifier-pre */ 
 _; }
modifier c_modd3b81e76{ c_d527060f(0xf2615412dce7b459); /* modifier-post */ 
 _; }
modifier c_modf92279c5{ c_d527060f(0x1ceb8edc6cfcc312); /* modifier-pre */ 
 _; }
modifier c_mod095ecc27{ c_d527060f(0x528da315e4a05462); /* modifier-post */ 
 _; }
modifier c_mod6de168d4{ c_d527060f(0xa3656824fd02120e); /* modifier-pre */ 
 _; }
modifier c_mod8065f47a{ c_d527060f(0xe30c8d217fb8d269); /* modifier-post */ 
 _; }
modifier c_mod03ecd475{ c_d527060f(0xec68f7c4b259ff74); /* modifier-pre */ 
 _; }
modifier c_mod4e2feaab{ c_d527060f(0xb36e6053c642f776); /* modifier-post */ 
 _; }
modifier c_modead411b8{ c_d527060f(0x928a5bc4b6de7b93); /* modifier-pre */ 
 _; }
modifier c_modb8599039{ c_d527060f(0xa81c166d6e36e3d0); /* modifier-post */ 
 _; }
modifier c_modf98a20e7{ c_d527060f(0x3fe03519fe9bdeea); /* modifier-pre */ 
 _; }

    /// @notice Revert with an error if mint exceeds the max supply.
    error MintQuantityExceedsMaxSupply(uint256 total, uint256 maxSupply);

    /**
     * @notice Modifier to restrict access exclusively to
     *         allowed SeaDrop contracts.
     */
    modifier onlyAllowedSeaDrop(address seaDrop) {c_d527060f(0x27928abdc8faee4b); /* function */ 

c_d527060f(0xea129d57fdca0eca); /* line */ 
        c_d527060f(0x5c1160364f3f7207); /* statement */ 
if (ERC721SeaDropStorage.layout()._allowedSeaDrop[seaDrop] != true) {c_d527060f(0xa36c85b02f617152); /* branch */ 

c_d527060f(0x6f91a426f7be2e69); /* line */ 
            revert OnlyAllowedSeaDrop();
        }else { c_d527060f(0x2363a9ac44d4dc5b); /* branch */ 
}
c_d527060f(0xa36b5f3b9554f61b); /* line */ 
        _;
    }

    /**
     * @notice Deploy the token contract with its name, symbol,
     *         and allowed SeaDrop addresses.
     */
    function __ERC721SeaDrop_init(
        string memory name,
        string memory symbol,
        address[] memory allowedSeaDrop
    ) internal onlyInitializing {
        __ERC721A_init_unchained(name, symbol);
        __ConstructorInitializable_init_unchained();
        __TwoStepOwnable_init_unchained();
        __ERC721ContractMetadata_init_unchained(name, symbol);
        __ReentrancyGuard_init_unchained();
        __DefaultOperatorFilterer721_init();
        __ERC721SeaDrop_init_unchained(name, symbol, allowedSeaDrop);
    }

    function __ERC721SeaDrop_init_unchained(
        string memory,
        string memory,
        address[] memory allowedSeaDrop
    ) internal onlyInitializing {c_d527060f(0xd59bab0b161f7183); /* function */ 

        // Put the length on the stack for more efficient access.
c_d527060f(0x99b0c9daa36d7b9a); /* line */ 
        c_d527060f(0xc583703545537775); /* statement */ 
uint256 allowedSeaDropLength = allowedSeaDrop.length;

        // Set the mapping for allowed SeaDrop contracts.
c_d527060f(0x4870add1d029360f); /* line */ 
        c_d527060f(0x680cbda7d2cb1ea2); /* statement */ 
for (uint256 i = 0; i < allowedSeaDropLength; ) {
c_d527060f(0x89fc9e03c661e347); /* line */ 
            ERC721SeaDropStorage.layout()._allowedSeaDrop[allowedSeaDrop[i]] = true;
c_d527060f(0xb9f33b175832c32d); /* line */ 
            unchecked {
c_d527060f(0x98b3a783a2240aa5); /* line */ 
                ++i;
            }
        }

        // Set the enumeration.
c_d527060f(0x5d6fee98e9843655); /* line */ 
        ERC721SeaDropStorage.layout()._enumeratedAllowedSeaDrop = allowedSeaDrop;
    }

    /**
     * @notice Update the allowed SeaDrop contracts.
     *         Only the owner or administrator can use this function.
     *
     * @param allowedSeaDrop The allowed SeaDrop addresses.
     */
    function updateAllowedSeaDrop(address[] calldata allowedSeaDrop)
        external
        virtual
        override
         c_modf98a20e7 onlyOwner c_modb8599039 
    {c_d527060f(0x368f513f792e8024); /* function */ 

c_d527060f(0xd1231250f562ab99); /* line */ 
        c_d527060f(0xf35dc1ddd52a20cd); /* statement */ 
_updateAllowedSeaDrop(allowedSeaDrop);
    }

    /**
     * @notice Internal function to update the allowed SeaDrop contracts.
     *
     * @param allowedSeaDrop The allowed SeaDrop addresses.
     */
    function _updateAllowedSeaDrop(address[] calldata allowedSeaDrop) internal {c_d527060f(0xd67fb1132ab4472a); /* function */ 

        // Put the length on the stack for more efficient access.
c_d527060f(0xbf061a3f651c023d); /* line */ 
        c_d527060f(0x08a87b2a0903d89c); /* statement */ 
uint256 enumeratedAllowedSeaDropLength = ERC721SeaDropStorage.layout()._enumeratedAllowedSeaDrop
            .length;
c_d527060f(0x8992e6249cf6ca93); /* line */ 
        c_d527060f(0x4416e17e29e3265a); /* statement */ 
uint256 allowedSeaDropLength = allowedSeaDrop.length;

        // Reset the old mapping.
c_d527060f(0xea8b594f5473519c); /* line */ 
        c_d527060f(0xeab27514d116b5d2); /* statement */ 
for (uint256 i = 0; i < enumeratedAllowedSeaDropLength; ) {
c_d527060f(0x5ad7f4bce2f1e613); /* line */ 
            ERC721SeaDropStorage.layout()._allowedSeaDrop[ERC721SeaDropStorage.layout()._enumeratedAllowedSeaDrop[i]] = false;
c_d527060f(0x553afa62eeac5631); /* line */ 
            unchecked {
c_d527060f(0x90a55b0b3d1c01ee); /* line */ 
                ++i;
            }
        }

        // Set the new mapping for allowed SeaDrop contracts.
c_d527060f(0x5f38fe22c9654492); /* line */ 
        c_d527060f(0x5b6f97db15c788d5); /* statement */ 
for (uint256 i = 0; i < allowedSeaDropLength; ) {
c_d527060f(0xd42c1124081d28c7); /* line */ 
            ERC721SeaDropStorage.layout()._allowedSeaDrop[allowedSeaDrop[i]] = true;
c_d527060f(0x6ee625c6d44ea700); /* line */ 
            unchecked {
c_d527060f(0xbe852319eaf19eac); /* line */ 
                ++i;
            }
        }

        // Set the enumeration.
c_d527060f(0x76a566fc9f49d01c); /* line */ 
        ERC721SeaDropStorage.layout()._enumeratedAllowedSeaDrop = allowedSeaDrop;

        // Emit an event for the update.
c_d527060f(0x094e4b9370fbbe73); /* line */ 
        c_d527060f(0x4219da2af5851ad4); /* statement */ 
emit AllowedSeaDropUpdated(allowedSeaDrop);
    }

    /**
     * @dev Overrides the `_startTokenId` function from ERC721A
     *      to start at token id `1`.
     *
     *      This is to avoid future possible problems since `0` is usually
     *      used to signal values that have not been set or have been removed.
     */
    function _startTokenId() internal view virtual override returns (uint256) {c_d527060f(0x95855e205a573b52); /* function */ 

c_d527060f(0x80ff55489acba68e); /* line */ 
        c_d527060f(0xdf80e5d5f916fa84); /* statement */ 
return 1;
    }

    /**
     * @notice Mint tokens, restricted to the SeaDrop contract.
     *
     * @dev    NOTE: If a token registers itself with multiple SeaDrop
     *         contracts, the implementation of this function should guard
     *         against reentrancy. If the implementing token uses
     *         _safeMint(), or a feeRecipient with a malicious receive() hook
     *         is specified, the token or fee recipients may be able to execute
     *         another mint in the same transaction via a separate SeaDrop
     *         contract.
     *         This is dangerous if an implementing token does not correctly
     *         update the minterNumMinted and currentTotalSupply values before
     *         transferring minted tokens, as SeaDrop references these values
     *         to enforce token limits on a per-wallet and per-stage basis.
     *
     *         ERC721A tracks these values automatically, but this note and
     *         nonReentrant modifier are left here to encourage best-practices
     *         when referencing this contract.
     *
     * @param minter   The address to mint to.
     * @param quantity The number of tokens to mint.
     */
    function mintSeaDrop(address minter, uint256 quantity)
        external
        payable
        virtual
        override
         c_modead411b8 onlyAllowedSeaDrop(msg.sender) c_mod4e2feaab 
         c_mod03ecd475 nonReentrant c_mod8065f47a 
    {c_d527060f(0x8011197d47a92018); /* function */ 

        // Extra safety check to ensure the max supply is not exceeded.
c_d527060f(0x9d08a328dcbce1c1); /* line */ 
        c_d527060f(0xe887122023326604); /* statement */ 
if (_totalMinted() + quantity > maxSupply()) {c_d527060f(0x85a6da34a81cf06b); /* branch */ 

c_d527060f(0x14ef566d4bcb388e); /* line */ 
            revert MintQuantityExceedsMaxSupply(
                _totalMinted() + quantity,
                maxSupply()
            );
        }else { c_d527060f(0x134325bb29a6ebcf); /* branch */ 
}

        // Mint the quantity of tokens to the minter.
c_d527060f(0x56845a593b6751de); /* line */ 
        c_d527060f(0x9ea23de8d2cbbaf6); /* statement */ 
_safeMint(minter, quantity);
    }

    /**
     * @notice Update the public drop data for this nft contract on SeaDrop.
     *         Only the owner can use this function.
     *
     * @param seaDropImpl The allowed SeaDrop contract.
     * @param publicDrop  The public drop data.
     */
    function updatePublicDrop(
        address seaDropImpl,
        PublicDrop calldata publicDrop
    ) external virtual override  c_mod6de168d4 onlyOwner c_mod095ecc27   c_modf92279c5 onlyAllowedSeaDrop(seaDropImpl) c_modd3b81e76  {c_d527060f(0x0ba52ce725d8029f); /* function */ 

        // Update the public drop data on SeaDrop.
c_d527060f(0xdba04330d4735121); /* line */ 
        c_d527060f(0x2403d6349add8d7e); /* statement */ 
ISeaDropUpgradeable(seaDropImpl).updatePublicDrop(publicDrop);
    }

    /**
     * @notice Update the allow list data for this nft contract on SeaDrop.
     *         Only the owner can use this function.
     *
     * @param seaDropImpl   The allowed SeaDrop contract.
     * @param allowListData The allow list data.
     */
    function updateAllowList(
        address seaDropImpl,
        AllowListData calldata allowListData
    ) external virtual override  c_mod14ddafe3 onlyOwner c_modbc4574aa   c_mod750dde0d onlyAllowedSeaDrop(seaDropImpl) c_mod97685826  {c_d527060f(0x8f3c7cc450e23c1d); /* function */ 

        // Update the allow list on SeaDrop.
c_d527060f(0x0a623160ed0ecdb1); /* line */ 
        c_d527060f(0xe9bcb92a52199d5a); /* statement */ 
ISeaDropUpgradeable(seaDropImpl).updateAllowList(allowListData);
    }

    /**
     * @notice Update the token gated drop stage data for this nft contract
     *         on SeaDrop.
     *         Only the owner can use this function.
     *
     *         Note: If two INonFungibleSeaDropToken tokens are doing
     *         simultaneous token gated drop promotions for each other,
     *         they can be minted by the same actor until
     *         `maxTokenSupplyForStage` is reached. Please ensure the
     *         `allowedNftToken` is not running an active drop during the
     *         `dropStage` time period.
     *
     * @param seaDropImpl     The allowed SeaDrop contract.
     * @param allowedNftToken The allowed nft token.
     * @param dropStage       The token gated drop stage data.
     */
    function updateTokenGatedDrop(
        address seaDropImpl,
        address allowedNftToken,
        TokenGatedDropStage calldata dropStage
    ) external virtual override  c_mod071d6fb0 onlyOwner c_mod19d8392f   c_mod7ab1b03e onlyAllowedSeaDrop(seaDropImpl) c_mod4b291931  {c_d527060f(0xaabee1ae560d54e8); /* function */ 

        // Update the token gated drop stage.
c_d527060f(0xffa228bb71642ad0); /* line */ 
        c_d527060f(0x6bf131be51c74f72); /* statement */ 
ISeaDropUpgradeable(seaDropImpl).updateTokenGatedDrop(allowedNftToken, dropStage);
    }

    /**
     * @notice Update the drop URI for this nft contract on SeaDrop.
     *         Only the owner can use this function.
     *
     * @param seaDropImpl The allowed SeaDrop contract.
     * @param dropURI     The new drop URI.
     */
    function updateDropURI(address seaDropImpl, string calldata dropURI)
        external
        virtual
        override
         c_mod81c4c3e7 onlyOwner c_mod5a4bacf3 
         c_mod5109d810 onlyAllowedSeaDrop(seaDropImpl) c_mod2d3609f7 
    {c_d527060f(0x02f9e83275c062d0); /* function */ 

        // Update the drop URI.
c_d527060f(0x759860a18861b3d7); /* line */ 
        c_d527060f(0x8472b7f20e9756cf); /* statement */ 
ISeaDropUpgradeable(seaDropImpl).updateDropURI(dropURI);
    }

    /**
     * @notice Update the creator payout address for this nft contract on SeaDrop.
     *         Only the owner can set the creator payout address.
     *
     * @param seaDropImpl   The allowed SeaDrop contract.
     * @param payoutAddress The new payout address.
     */
    function updateCreatorPayoutAddress(
        address seaDropImpl,
        address payoutAddress
    ) external  c_mod64041d1c onlyOwner c_mod4602f1d0   c_modfef441b2 onlyAllowedSeaDrop(seaDropImpl) c_mode0c0e150  {c_d527060f(0x97503474dc944dfc); /* function */ 

        // Update the creator payout address.
c_d527060f(0x387d89e270f9fe44); /* line */ 
        c_d527060f(0x15e081c291c4a856); /* statement */ 
ISeaDropUpgradeable(seaDropImpl).updateCreatorPayoutAddress(payoutAddress);
    }

    /**
     * @notice Update the allowed fee recipient for this nft contract
     *         on SeaDrop.
     *         Only the owner can set the allowed fee recipient.
     *
     * @param seaDropImpl  The allowed SeaDrop contract.
     * @param feeRecipient The new fee recipient.
     * @param allowed      If the fee recipient is allowed.
     */
    function updateAllowedFeeRecipient(
        address seaDropImpl,
        address feeRecipient,
        bool allowed
    ) external virtual  c_mod676bd09a onlyOwner c_mod96740165   c_mod31d20c51 onlyAllowedSeaDrop(seaDropImpl) c_mod954ed8e5  {c_d527060f(0xfcd812c62f261ead); /* function */ 

        // Update the allowed fee recipient.
c_d527060f(0x3d91b9a5600f05f9); /* line */ 
        c_d527060f(0x78c40b7ab5c7d3c9); /* statement */ 
ISeaDropUpgradeable(seaDropImpl).updateAllowedFeeRecipient(feeRecipient, allowed);
    }

    /**
     * @notice Update the server-side signers for this nft contract
     *         on SeaDrop.
     *         Only the owner can use this function.
     *
     * @param seaDropImpl                The allowed SeaDrop contract.
     * @param signer                     The signer to update.
     * @param signedMintValidationParams Minimum and maximum parameters to
     *                                   enforce for signed mints.
     */
    function updateSignedMintValidationParams(
        address seaDropImpl,
        address signer,
        SignedMintValidationParams memory signedMintValidationParams
    ) external virtual override  c_modafe22915 onlyOwner c_mod15fd79e8   c_mod9400e2b6 onlyAllowedSeaDrop(seaDropImpl) c_mod6422ee31  {c_d527060f(0x7681664a454dda99); /* function */ 

        // Update the signer.
c_d527060f(0xc55ac01663e0cc07); /* line */ 
        c_d527060f(0xf167387f0fb1624f); /* statement */ 
ISeaDropUpgradeable(seaDropImpl).updateSignedMintValidationParams(
            signer,
            signedMintValidationParams
        );
    }

    /**
     * @notice Update the allowed payers for this nft contract on SeaDrop.
     *         Only the owner can use this function.
     *
     * @param seaDropImpl The allowed SeaDrop contract.
     * @param payer       The payer to update.
     * @param allowed     Whether the payer is allowed.
     */
    function updatePayer(
        address seaDropImpl,
        address payer,
        bool allowed
    ) external virtual override  c_mod9b2b9d83 onlyOwner c_mod2b24e034   c_modefb7bba3 onlyAllowedSeaDrop(seaDropImpl) c_modddb9c0ca  {c_d527060f(0x2d56c977eff020ca); /* function */ 

        // Update the payer.
c_d527060f(0x8030c74fc9c91a8c); /* line */ 
        c_d527060f(0x312bc4fc2278a1f0); /* statement */ 
ISeaDropUpgradeable(seaDropImpl).updatePayer(payer, allowed);
    }

    /**
     * @notice Returns a set of mint stats for the address.
     *         This assists SeaDrop in enforcing maxSupply,
     *         maxTotalMintableByWallet, and maxTokenSupplyForStage checks.
     *
     * @dev    NOTE: Implementing contracts should always update these numbers
     *         before transferring any tokens with _safeMint() to mitigate
     *         consequences of malicious onERC721Received() hooks.
     *
     * @param minter The minter address.
     */
    function getMintStats(address minter)
        external
        view
        override
        returns (
            uint256 minterNumMinted,
            uint256 currentTotalSupply,
            uint256 maxSupply
        )
    {c_d527060f(0x1476a3c48286f8a1); /* function */ 

c_d527060f(0x2c50a543c460f181); /* line */ 
        minterNumMinted = _numberMinted(minter);
c_d527060f(0x9aaacbecf62e7843); /* line */ 
        currentTotalSupply = _totalMinted();
c_d527060f(0xe5760bbc18241737); /* line */ 
        maxSupply = ERC721ContractMetadataStorage.layout()._maxSupply;
    }

    /**
     * @notice Returns whether the interface is supported.
     *
     * @param interfaceId The interface id to check against.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165Upgradeable, ERC721AUpgradeable)
        returns (bool)
    {c_d527060f(0xcf6d379b2b73b84b); /* function */ 

c_d527060f(0x5858e42e0a79d49a); /* line */ 
        c_d527060f(0xf67c247233a5b16f); /* statement */ 
return
            ((interfaceId == type(INonFungibleSeaDropTokenUpgradeable).interfaceId && c_trued527060f(0x950245f740b9cc46)) ||
            (interfaceId == type(ISeaDropTokenContractMetadataUpgradeable).interfaceId && c_trued527060f(0xcf9226f9b38f004f)) && c_trued527060f(0x8b74e38188c8e713)) ||
            // ERC721A returns supportsInterface true for
            // ERC165, ERC721, ERC721Metadata
            (super.supportsInterface(interfaceId) && c_trued527060f(0x5a19a9fb8bb3021d));
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     * - The operator (msg.sender) must be allowed.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override  c_mod6efbb7d2 onlyAllowedOperator(from) c_mod202a337c  {c_d527060f(0xda7e351e7f12838f); /* function */ 

c_d527060f(0x037b13e1dc40d047); /* line */ 
        c_d527060f(0x28bd2b0e5e1921dc); /* statement */ 
super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override  c_mod10543891 onlyAllowedOperator(from) c_mod43f1f644  {c_d527060f(0xf2623cacb5078dcf); /* function */ 

c_d527060f(0xbfb0a08800570a68); /* line */ 
        c_d527060f(0x45f1f36d6111ddf7); /* statement */ 
super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     * - The operator (msg.sender) must be allowed.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override  c_modfc5038a2 onlyAllowedOperator(from) c_mod3cfbb367  {c_d527060f(0x37b110c976cc8171); /* function */ 

c_d527060f(0xed10de0be8894704); /* line */ 
        c_d527060f(0x762b6a2cf4778a49); /* statement */ 
super.safeTransferFrom(from, to, tokenId, data);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
function c_41c99668(bytes8 c__41c99668) pure {}
function c_true41c99668(bytes8 c__41c99668) pure returns (bool){ return true; }
function c_false41c99668(bytes8 c__41c99668) pure returns (bool){ return false; }


import { AllowListData, MintParams, PublicDrop, TokenGatedDropStage, TokenGatedMintParams, SignedMintValidationParams } from "../lib/SeaDropStructsUpgradeable.sol";

import { SeaDropErrorsAndEventsUpgradeable } from "../lib/SeaDropErrorsAndEventsUpgradeable.sol";

interface ISeaDropUpgradeable is SeaDropErrorsAndEventsUpgradeable {
    /**
     * @notice Mint a public drop.
     *
     * @param nftContract      The nft contract to mint.
     * @param feeRecipient     The fee recipient.
     * @param minterIfNotPayer The mint recipient if different than the payer.
     * @param quantity         The number of tokens to mint.
     */
    function mintPublic(
        address nftContract,
        address feeRecipient,
        address minterIfNotPayer,
        uint256 quantity
    ) external payable;

    /**
     * @notice Mint from an allow list.
     *
     * @param nftContract      The nft contract to mint.
     * @param feeRecipient     The fee recipient.
     * @param minterIfNotPayer The mint recipient if different than the payer.
     * @param quantity         The number of tokens to mint.
     * @param mintParams       The mint parameters.
     * @param proof            The proof for the leaf of the allow list.
     */
    function mintAllowList(
        address nftContract,
        address feeRecipient,
        address minterIfNotPayer,
        uint256 quantity,
        MintParams calldata mintParams,
        bytes32[] calldata proof
    ) external payable;

    /**
     * @notice Mint with a server-side signature.
     *         Note that a signature can only be used once.
     *
     * @param nftContract      The nft contract to mint.
     * @param feeRecipient     The fee recipient.
     * @param minterIfNotPayer The mint recipient if different than the payer.
     * @param quantity         The number of tokens to mint.
     * @param mintParams       The mint parameters.
     * @param salt             The sale for the signed mint.
     * @param signature        The server-side signature, must be an allowed
     *                         signer.
     */
    function mintSigned(
        address nftContract,
        address feeRecipient,
        address minterIfNotPayer,
        uint256 quantity,
        MintParams calldata mintParams,
        uint256 salt,
        bytes calldata signature
    ) external payable;

    /**
     * @notice Mint as an allowed token holder.
     *         This will mark the token id as redeemed and will revert if the
     *         same token id is attempted to be redeemed twice.
     *
     * @param nftContract      The nft contract to mint.
     * @param feeRecipient     The fee recipient.
     * @param minterIfNotPayer The mint recipient if different than the payer.
     * @param mintParams       The token gated mint params.
     */
    function mintAllowedTokenHolder(
        address nftContract,
        address feeRecipient,
        address minterIfNotPayer,
        TokenGatedMintParams calldata mintParams
    ) external payable;

    /**
     * @notice Returns the public drop data for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getPublicDrop(address nftContract)
        external
        view
        returns (PublicDrop memory);

    /**
     * @notice Returns the creator payout address for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getCreatorPayoutAddress(address nftContract)
        external
        view
        returns (address);

    /**
     * @notice Returns the allow list merkle root for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getAllowListMerkleRoot(address nftContract)
        external
        view
        returns (bytes32);

    /**
     * @notice Returns if the specified fee recipient is allowed
     *         for the nft contract.
     *
     * @param nftContract  The nft contract.
     * @param feeRecipient The fee recipient.
     */
    function getFeeRecipientIsAllowed(address nftContract, address feeRecipient)
        external
        view
        returns (bool);

    /**
     * @notice Returns an enumeration of allowed fee recipients for an
     *         nft contract when fee recipients are enforced
     *
     * @param nftContract The nft contract.
     */
    function getAllowedFeeRecipients(address nftContract)
        external
        view
        returns (address[] memory);

    /**
     * @notice Returns the server-side signers for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getSigners(address nftContract)
        external
        view
        returns (address[] memory);

    /**
     * @notice Returns the struct of SignedMintValidationParams for a signer.
     *
     * @param nftContract The nft contract.
     * @param signer      The signer.
     */
    function getSignedMintValidationParams(address nftContract, address signer)
        external
        view
        returns (SignedMintValidationParams memory);

    /**
     * @notice Returns the payers for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getPayers(address nftContract)
        external
        view
        returns (address[] memory);

    /**
     * @notice Returns if the specified payer is allowed
     *         for the nft contract.
     *
     * @param nftContract The nft contract.
     * @param payer       The payer.
     */
    function getPayerIsAllowed(address nftContract, address payer)
        external
        view
        returns (bool);

    /**
     * @notice Returns the allowed token gated drop tokens for the nft contract.
     *
     * @param nftContract The nft contract.
     */
    function getTokenGatedAllowedTokens(address nftContract)
        external
        view
        returns (address[] memory);

    /**
     * @notice Returns the token gated drop data for the nft contract
     *         and token gated nft.
     *
     * @param nftContract     The nft contract.
     * @param allowedNftToken The token gated nft token.
     */
    function getTokenGatedDrop(address nftContract, address allowedNftToken)
        external
        view
        returns (TokenGatedDropStage memory);

    /**
     * @notice Returns whether the token id for a token gated drop has been
     *         redeemed.
     *
     * @param nftContract       The nft contract.
     * @param allowedNftToken   The token gated nft token.
     * @param allowedNftTokenId The token gated nft token id to check.
     */
    function getAllowedNftTokenIdIsRedeemed(
        address nftContract,
        address allowedNftToken,
        uint256 allowedNftTokenId
    ) external view returns (bool);

    /**
     * The following methods assume msg.sender is an nft contract
     * and its ERC165 interface id matches INonFungibleSeaDropToken.
     */

    /**
     * @notice Emits an event to notify update of the drop URI.
     *
     * @param dropURI The new drop URI.
     */
    function updateDropURI(string calldata dropURI) external;

    /**
     * @notice Updates the public drop data for the nft contract
     *         and emits an event.
     *
     * @param publicDrop The public drop data.
     */
    function updatePublicDrop(PublicDrop calldata publicDrop) external;

    /**
     * @notice Updates the allow list merkle root for the nft contract
     *         and emits an event.
     *
     *         Note: Be sure only authorized users can call this from
     *         token contracts that implement INonFungibleSeaDropToken.
     *
     * @param allowListData The allow list data.
     */
    function updateAllowList(AllowListData calldata allowListData) external;

    /**
     * @notice Updates the token gated drop stage for the nft contract
     *         and emits an event.
     *
     *         Note: If two INonFungibleSeaDropToken tokens are doing simultaneous
     *         token gated drop promotions for each other, they can be
     *         minted by the same actor until `maxTokenSupplyForStage`
     *         is reached. Please ensure the `allowedNftToken` is not
     *         running an active drop during the `dropStage` time period.
     *
     * @param allowedNftToken The token gated nft token.
     * @param dropStage       The token gated drop stage data.
     */
    function updateTokenGatedDrop(
        address allowedNftToken,
        TokenGatedDropStage calldata dropStage
    ) external;

    /**
     * @notice Updates the creator payout address and emits an event.
     *
     * @param payoutAddress The creator payout address.
     */
    function updateCreatorPayoutAddress(address payoutAddress) external;

    /**
     * @notice Updates the allowed fee recipient and emits an event.
     *
     * @param feeRecipient The fee recipient.
     * @param allowed      If the fee recipient is allowed.
     */
    function updateAllowedFeeRecipient(address feeRecipient, bool allowed)
        external;

    /**
     * @notice Updates the allowed server-side signers and emits an event.
     *
     * @param signer                     The signer to update.
     * @param signedMintValidationParams Minimum and maximum parameters
     *                                   to enforce for signed mints.
     */
    function updateSignedMintValidationParams(
        address signer,
        SignedMintValidationParams calldata signedMintValidationParams
    ) external;

    /**
     * @notice Updates the allowed payer and emits an event.
     *
     * @param payer   The payer to add or remove.
     * @param allowed Whether to add or remove the payer.
     */
    function updatePayer(address payer, bool allowed) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { TwoStepOwnableUpgradeable } from "./TwoStepOwnableUpgradeable.sol";
import { TwoStepAdministeredStorage } from "./TwoStepAdministeredStorage.sol";
import "../../openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";

contract TwoStepAdministeredUpgradeable is Initializable, TwoStepOwnableUpgradeable {
    using TwoStepAdministeredStorage for TwoStepAdministeredStorage.Layout;
    event AdministratorUpdated(
        address indexed previousAdministrator,
        address indexed newAdministrator
    );
    event PotentialAdministratorUpdated(address newPotentialAdministrator);

    error OnlyAdministrator();
    error OnlyOwnerOrAdministrator();
    error NotNextAdministrator();
    error NewAdministratorIsZeroAddress();

    modifier onlyAdministrator() virtual {
        if (msg.sender != TwoStepAdministeredStorage.layout().administrator) {
            revert OnlyAdministrator();
        }

        _;
    }

    modifier onlyOwnerOrAdministrator() virtual {
        if (msg.sender != owner()) {
            if (msg.sender != TwoStepAdministeredStorage.layout().administrator) {
                revert OnlyOwnerOrAdministrator();
            }
        }
        _;
    }

    function __TwoStepAdministered_init(address _administrator) internal onlyInitializing {
        __ConstructorInitializable_init_unchained();
        __TwoStepOwnable_init_unchained();
        __TwoStepAdministered_init_unchained(_administrator);
    }

    function __TwoStepAdministered_init_unchained(address _administrator) internal onlyInitializing {
        _initialize(_administrator);
    }

    function _initialize(address _administrator) private onlyConstructor {
        TwoStepAdministeredStorage.layout().administrator = _administrator;
        emit AdministratorUpdated(address(0), _administrator);
    }

    function transferAdministration(address newAdministrator)
        public
        virtual
        onlyAdministrator
    {
        if (newAdministrator == address(0)) {
            revert NewAdministratorIsZeroAddress();
        }
        TwoStepAdministeredStorage.layout().potentialAdministrator = newAdministrator;
        emit PotentialAdministratorUpdated(newAdministrator);
    }

    function _transferAdministration(address newAdministrator)
        internal
        virtual
    {
        TwoStepAdministeredStorage.layout().administrator = newAdministrator;

        emit AdministratorUpdated(msg.sender, newAdministrator);
    }

    ///@notice Acept administration of smart contract, after the current administrator has initiated the process with transferAdministration
    function acceptAdministration() public virtual {
        address _potentialAdministrator = TwoStepAdministeredStorage.layout().potentialAdministrator;
        if (msg.sender != _potentialAdministrator) {
            revert NotNextAdministrator();
        }
        _transferAdministration(_potentialAdministrator);
        delete TwoStepAdministeredStorage.layout().potentialAdministrator;
    }

    ///@notice cancel administration transfer
    function cancelAdministrationTransfer() public virtual onlyAdministrator {
        delete TwoStepAdministeredStorage.layout().potentialAdministrator;
        emit PotentialAdministratorUpdated(address(0));
    }

    function renounceAdministration() public virtual onlyAdministrator {
        delete TwoStepAdministeredStorage.layout().administrator;
        emit AdministratorUpdated(msg.sender, address(0));
    }
    // generated getter for ${varDecl.name}
    function administrator() public view returns(address) {
        return TwoStepAdministeredStorage.layout().administrator;
    }

    // generated getter for ${varDecl.name}
    function potentialAdministrator() public view returns(address) {
        return TwoStepAdministeredStorage.layout().potentialAdministrator;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import { TwoStepAdministeredUpgradeable } from "./TwoStepAdministeredUpgradeable.sol";

library TwoStepAdministeredStorage {

  struct Layout {

    address administrator;
    address potentialAdministrator;
  
  }
  
  bytes32 internal constant STORAGE_SLOT = keccak256('openzepplin.contracts.storage.TwoStepAdministered');

  function layout() internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
function c_b16eb2fb(bytes8 c__b16eb2fb) pure {}
function c_trueb16eb2fb(bytes8 c__b16eb2fb) pure returns (bool){ return true; }
function c_falseb16eb2fb(bytes8 c__b16eb2fb) pure returns (bool){ return false; }


/**
 * @notice A struct defining public drop data.
 *         Designed to fit efficiently in one storage slot.
 * 
 * @param mintPrice                The mint price per token. (Up to 1.2m
 *                                 of native token, e.g. ETH, MATIC)
 * @param startTime                The start time, ensure this is not zero.
 * @param endTIme                  The end time, ensure this is not zero.
 * @param maxTotalMintableByWallet Maximum total number of mints a user is
 *                                 allowed. (The limit for this field is
 *                                 2^16 - 1)
 * @param feeBps                   Fee out of 10_000 basis points to be
 *                                 collected.
 * @param restrictFeeRecipients    If false, allow any fee recipient;
 *                                 if true, check fee recipient is allowed.
 */
struct PublicDrop {
    uint80 mintPrice; // 80/256 bits
    uint48 startTime; // 128/256 bits
    uint48 endTime; // 176/256 bits
    uint16 maxTotalMintableByWallet; // 224/256 bits
    uint16 feeBps; // 240/256 bits
    bool restrictFeeRecipients; // 248/256 bits
}

/**
 * @notice A struct defining token gated drop stage data.
 *         Designed to fit efficiently in one storage slot.
 * 
 * @param mintPrice                The mint price per token. (Up to 1.2m 
 *                                 of native token, e.g.: ETH, MATIC)
 * @param maxTotalMintableByWallet Maximum total number of mints a user is
 *                                 allowed. (The limit for this field is
 *                                 2^16 - 1)
 * @param startTime                The start time, ensure this is not zero.
 * @param endTime                  The end time, ensure this is not zero.
 * @param dropStageIndex           The drop stage index to emit with the event
 *                                 for analytical purposes. This should be 
 *                                 non-zero since the public mint emits
 *                                 with index zero.
 * @param maxTokenSupplyForStage   The limit of token supply this stage can
 *                                 mint within. (The limit for this field is
 *                                 2^16 - 1)
 * @param feeBps                   Fee out of 10_000 basis points to be
 *                                 collected.
 * @param restrictFeeRecipients    If false, allow any fee recipient;
 *                                 if true, check fee recipient is allowed.
 */
struct TokenGatedDropStage {
    uint80 mintPrice; // 80/256 bits
    uint16 maxTotalMintableByWallet; // 96/256 bits
    uint48 startTime; // 144/256 bits
    uint48 endTime; // 192/256 bits
    uint8 dropStageIndex; // non-zero. 200/256 bits
    uint32 maxTokenSupplyForStage; // 232/256 bits
    uint16 feeBps; // 248/256 bits
    bool restrictFeeRecipients; // 256/256 bits
}

/**
 * @notice A struct defining mint params for an allow list.
 *         An allow list leaf will be composed of `msg.sender` and
 *         the following params.
 * 
 *         Note: Since feeBps is encoded in the leaf, backend should ensure
 *         that feeBps is acceptable before generating a proof.
 * 
 * @param mintPrice                The mint price per token.
 * @param maxTotalMintableByWallet Maximum total number of mints a user is
 *                                 allowed.
 * @param startTime                The start time, ensure this is not zero.
 * @param endTime                  The end time, ensure this is not zero.
 * @param dropStageIndex           The drop stage index to emit with the event
 *                                 for analytical purposes. This should be
 *                                 non-zero since the public mint emits with
 *                                 index zero.
 * @param maxTokenSupplyForStage   The limit of token supply this stage can
 *                                 mint within.
 * @param feeBps                   Fee out of 10_000 basis points to be
 *                                 collected.
 * @param restrictFeeRecipients    If false, allow any fee recipient;
 *                                 if true, check fee recipient is allowed.
 */
struct MintParams {
    uint256 mintPrice; 
    uint256 maxTotalMintableByWallet;
    uint256 startTime;
    uint256 endTime;
    uint256 dropStageIndex; // non-zero
    uint256 maxTokenSupplyForStage;
    uint256 feeBps;
    bool restrictFeeRecipients;
}

/**
 * @notice A struct defining token gated mint params.
 * 
 * @param allowedNftToken    The allowed nft token contract address.
 * @param allowedNftTokenIds The token ids to redeem.
 */
struct TokenGatedMintParams {
    address allowedNftToken;
    uint256[] allowedNftTokenIds;
}

/**
 * @notice A struct defining allow list data (for minting an allow list).
 * 
 * @param merkleRoot    The merkle root for the allow list.
 * @param publicKeyURIs If the allowListURI is encrypted, a list of URIs
 *                      pointing to the public keys. Empty if unencrypted.
 * @param allowListURI  The URI for the allow list.
 */
struct AllowListData {
    bytes32 merkleRoot;
    string[] publicKeyURIs;
    string allowListURI;
}

/**
 * @notice A struct defining minimum and maximum parameters to validate for 
 *         signed mints, to minimize negative effects of a compromised signer.
 *
 * @param minMintPrice                The minimum mint price allowed.
 * @param maxMaxTotalMintableByWallet The maximum total number of mints allowed
 *                                    by a wallet.
 * @param minStartTime                The minimum start time allowed.
 * @param maxEndTime                  The maximum end time allowed.
 * @param maxMaxTokenSupplyForStage   The maximum token supply allowed.
 * @param minFeeBps                   The minimum fee allowed.
 * @param maxFeeBps                   The maximum fee allowed.
 */
struct SignedMintValidationParams {
    uint80 minMintPrice; // 80/256 bits
    uint24 maxMaxTotalMintableByWallet; // 104/256 bits
    uint40 minStartTime; // 144/256 bits
    uint40 maxEndTime; // 184/256 bits
    uint40 maxMaxTokenSupplyForStage; // 224/256 bits
    uint16 minFeeBps; // 240/256 bits
    uint16 maxFeeBps; // 256/256 bits
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
function c_1396a104(bytes8 c__1396a104) pure {}
function c_true1396a104(bytes8 c__1396a104) pure returns (bool){ return true; }
function c_false1396a104(bytes8 c__1396a104) pure returns (bool){ return false; }


import { ISeaDropTokenContractMetadataUpgradeable } from "./interfaces/ISeaDropTokenContractMetadataUpgradeable.sol";

import { ERC721AUpgradeable } from "../ERC721A/contracts/ERC721AUpgradeable.sol";

import { TwoStepOwnableUpgradeable } from "../utility-contracts/src/TwoStepOwnableUpgradeable.sol";
import { ERC721ContractMetadataStorage } from "./ERC721ContractMetadataStorage.sol";

/**
 * @title  ERC721ContractMetadata
 * @author James Wenzel (emo.eth)
 * @author Ryan Ghods (ralxz.eth)
 * @author Stephan Min (stephanm.eth)
 * @notice ERC721ContractMetadata is a token contract that extends ERC721A
 *         with additional metadata and ownership capabilities.
 */
contract ERC721ContractMetadataUpgradeable is
    ERC721AUpgradeable,
    TwoStepOwnableUpgradeable,
    ISeaDropTokenContractMetadataUpgradeable
{
    using ERC721ContractMetadataStorage for ERC721ContractMetadataStorage.Layout;
function c_723b74af(bytes8 c__723b74af) internal pure {}
function c_true723b74af(bytes8 c__723b74af) internal pure returns (bool){ return true; }
function c_false723b74af(bytes8 c__723b74af) internal pure returns (bool){ return false; }
modifier c_mod83167949{ c_723b74af(0xe25c5a0972047f35); /* modifier-post */ 
 _; }
modifier c_mod769268c4{ c_723b74af(0xbf20eddb6035ef0b); /* modifier-pre */ 
 _; }
modifier c_mod88b694a0{ c_723b74af(0x20f5f916a051498a); /* modifier-post */ 
 _; }
modifier c_mod7482c530{ c_723b74af(0x9b6a9c882066f1d2); /* modifier-pre */ 
 _; }
modifier c_modc42362c0{ c_723b74af(0x58fa60c41ffbe214); /* modifier-post */ 
 _; }
modifier c_mod9279af40{ c_723b74af(0x4ccb3b51ada937a4); /* modifier-pre */ 
 _; }
modifier c_mod87f2832d{ c_723b74af(0xb123198ad8764f78); /* modifier-post */ 
 _; }
modifier c_mod15ab1e2a{ c_723b74af(0x82f49d4b0188cac4); /* modifier-pre */ 
 _; }
modifier c_mod975375fe{ c_723b74af(0x2c4c4d69ad8668ab); /* modifier-post */ 
 _; }
modifier c_modc27c632b{ c_723b74af(0xf75d27c0ffd73aeb); /* modifier-pre */ 
 _; }

    /// @notice Throw if the max supply exceeds uint64, a limit
    //          due to the storage of bit-packed variables in ERC721A.
    error CannotExceedMaxSupplyOfUint64(uint256 newMaxSupply);

    /**
     * @notice Deploy the token contract with its name and symbol.
     */
    function __ERC721ContractMetadata_init(string memory name, string memory symbol) internal onlyInitializing {
        __ERC721A_init_unchained(name, symbol);
        __ConstructorInitializable_init_unchained();
        __TwoStepOwnable_init_unchained();
        __ERC721ContractMetadata_init_unchained(name, symbol);
    }

    function __ERC721ContractMetadata_init_unchained(string memory, string memory) internal onlyInitializing {c_723b74af(0xe2ba647946a42b4b); /* function */ 
}

    /**
     * @notice Returns the base URI for token metadata.
     */
    function baseURI() external view override returns (string memory) {c_723b74af(0xba2d899bed2a4722); /* function */ 

c_723b74af(0xf41f9a59e1b71ef6); /* line */ 
        c_723b74af(0x1bcb0d71b4121fdd); /* statement */ 
return _baseURI();
    }

    /**
     * @notice Returns the contract URI for contract metadata.
     */
    function contractURI() external view override returns (string memory) {c_723b74af(0x82974db9815fd426); /* function */ 

c_723b74af(0xd11b692d66598d24); /* line */ 
        c_723b74af(0x105a7ac6347a3a94); /* statement */ 
return ERC721ContractMetadataStorage.layout()._contractURI;
    }

    /**
     * @notice Sets the contract URI for contract metadata.
     *
     * @param newContractURI The new contract URI.
     */
    function setContractURI(string calldata newContractURI)
        external
        override
         c_modc27c632b onlyOwner c_mod975375fe 
    {c_723b74af(0x0d2f60cf76713e00); /* function */ 

        // Set the new contract URI.
c_723b74af(0x1d01d8a80236fe1a); /* line */ 
        ERC721ContractMetadataStorage.layout()._contractURI = newContractURI;

        // Emit an event with the update.
c_723b74af(0x9f9b74cf6e97d01e); /* line */ 
        c_723b74af(0x8e6a96a635a1413e); /* statement */ 
emit ContractURIUpdated(newContractURI);
    }

    /**
     * @notice Emit an event notifying metadata updates for
     *         a range of token ids.
     *
     * @param startTokenId The start token id.
     * @param endTokenId   The end token id.
     */
    function emitBatchTokenURIUpdated(uint256 startTokenId, uint256 endTokenId)
        external
         c_mod15ab1e2a onlyOwner c_mod87f2832d 
    {c_723b74af(0x9107aecd38fa6847); /* function */ 

        // Emit an event with the update.
c_723b74af(0xad7450fd30feabe2); /* line */ 
        c_723b74af(0x859bde0660c83dfa); /* statement */ 
emit TokenURIUpdated(startTokenId, endTokenId);
    }

    /**
     * @notice Returns the max token supply.
     */
    function maxSupply() public view returns (uint256) {c_723b74af(0xb9eb2077a44aecf6); /* function */ 

c_723b74af(0xe3955d7da9bc4b29); /* line */ 
        c_723b74af(0xa6034fd23068df14); /* statement */ 
return ERC721ContractMetadataStorage.layout()._maxSupply;
    }

    /**
     * @notice Returns the provenance hash.
     *         The provenance hash is used for random reveals, which
     *         is a hash of the ordered metadata to show it is unmodified
     *         after mint has started.
     */
    function provenanceHash() external view override returns (bytes32) {c_723b74af(0x7706a4197c05f008); /* function */ 

c_723b74af(0xd4191d2ea771ebcc); /* line */ 
        c_723b74af(0xf600d35f097a0938); /* statement */ 
return ERC721ContractMetadataStorage.layout()._provenanceHash;
    }

    /**
     * @notice Sets the provenance hash and emits an event.
     *         The provenance hash is used for random reveals, which
     *         is a hash of the ordered metadata to show it is unmodified
     *         after mint has started.
     *         This function will revert after the first item has been minted.
     *
     * @param newProvenanceHash The new provenance hash to set.
     */
    function setProvenanceHash(bytes32 newProvenanceHash) external  c_mod9279af40 onlyOwner c_modc42362c0  {c_723b74af(0x564b3b5aaf3bc08d); /* function */ 

        // Revert if any items have been minted.
c_723b74af(0xd0e57d578b36121b); /* line */ 
        c_723b74af(0x9dc1bf4fdd276f38); /* statement */ 
if (_totalMinted() > 0) {c_723b74af(0x1d4861c29a4fecf9); /* branch */ 

c_723b74af(0xb1b8e5af7d822432); /* line */ 
            revert ProvenanceHashCannotBeSetAfterMintStarted();
        }else { c_723b74af(0x9a61c5b124f13a86); /* branch */ 
}

        // Keep track of the old provenance hash for emitting with the event.
c_723b74af(0xe7cef1d82a669706); /* line */ 
        c_723b74af(0xc797b3afe993b2d7); /* statement */ 
bytes32 oldProvenanceHash = ERC721ContractMetadataStorage.layout()._provenanceHash;

        // Set the new provenance hash.
c_723b74af(0xf63f3e60e2b28949); /* line */ 
        ERC721ContractMetadataStorage.layout()._provenanceHash = newProvenanceHash;

        // Emit an event with the update.
c_723b74af(0xca90b70da73f22ea); /* line */ 
        c_723b74af(0xba3a1b71671cac13); /* statement */ 
emit ProvenanceHashUpdated(oldProvenanceHash, newProvenanceHash);
    }

    /**
     * @notice Sets the max token supply and emits an event.
     *
     * @param newMaxSupply The new max supply to set.
     */
    function setMaxSupply(uint256 newMaxSupply) external  c_mod7482c530 onlyOwner c_mod88b694a0  {c_723b74af(0xd5888fbb01ed36aa); /* function */ 

        // Ensure the max supply does not exceed the maximum value of uint64.
c_723b74af(0xd929252bdfd9a617); /* line */ 
        c_723b74af(0x8f8fe0ef0d58686d); /* statement */ 
if (newMaxSupply > 2**64 - 1) {c_723b74af(0x023b1bfce508b06a); /* branch */ 

c_723b74af(0x812daf2d04f368a9); /* line */ 
            revert CannotExceedMaxSupplyOfUint64(newMaxSupply);
        }else { c_723b74af(0xf2b3c48ef7fb8d38); /* branch */ 
}

        // Set the new max supply.
c_723b74af(0xbfde7994a5f7de3d); /* line */ 
        ERC721ContractMetadataStorage.layout()._maxSupply = newMaxSupply;

        // Emit an event with the update.
c_723b74af(0xcefeeeef4804de93); /* line */ 
        c_723b74af(0xcb3edd769d377774); /* statement */ 
emit MaxSupplyUpdated(newMaxSupply);
    }

    /**
     * @notice Sets the base URI for the token metadata and emits an event.
     *
     * @param newBaseURI The new base URI to set.
     */
    function setBaseURI(string calldata newBaseURI)
        external
        override
         c_mod769268c4 onlyOwner c_mod83167949 
    {c_723b74af(0x0fa32a59e7ed8179); /* function */ 

        // Set the new base URI.
c_723b74af(0x7456307f5093a1e6); /* line */ 
        ERC721ContractMetadataStorage.layout()._tokenBaseURI = newBaseURI;

        // Emit an event with the update.
c_723b74af(0xf81756eb494d8235); /* line */ 
        c_723b74af(0xc3857ee3eb8bb9a2); /* statement */ 
emit BaseURIUpdated(newBaseURI);
    }

    /**
     * @notice Returns the base URI for the contract, which ERC721A uses
     *         to return tokenURI.
     */
    function _baseURI() internal view virtual override returns (string memory) {c_723b74af(0x3b1c2a688d8980a0); /* function */ 

c_723b74af(0xf8bab1e0a0336a36); /* line */ 
        c_723b74af(0x6d61c67f1a57b3a0); /* statement */ 
return ERC721ContractMetadataStorage.layout()._tokenBaseURI;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import { ERC721SeaDropUpgradeable } from "./ERC721SeaDropUpgradeable.sol";
import { ERC721ContractMetadataUpgradeable } from "./ERC721ContractMetadataUpgradeable.sol";

library ERC721SeaDropStorage {

  struct Layout {

    /// @notice Track the allowed SeaDrop addresses.
    mapping(address => bool) _allowedSeaDrop;

    /// @notice Track the enumerated allowed SeaDrop addresses.
    address[] _enumeratedAllowedSeaDrop;
  
  }
  
  bytes32 internal constant STORAGE_SLOT = keccak256('openzepplin.contracts.storage.ERC721SeaDrop');

  function layout() internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import { ERC721ContractMetadataUpgradeable } from "./ERC721ContractMetadataUpgradeable.sol";

library ERC721ContractMetadataStorage {

  struct Layout {

    /// @notice Track the max supply.
    uint256 _maxSupply;

    /// @notice Track the base URI for token metadata.
    string _tokenBaseURI;

    /// @notice Track the contract URI for contract metadata.
    string _contractURI;

    /// @notice Track the provenance hash for guaranteeing metadata order
    ///         for random reveals.
    bytes32 _provenanceHash;
  
  }
  
  bytes32 internal constant STORAGE_SLOT = keccak256('openzepplin.contracts.storage.ERC721ContractMetadata');

  function layout() internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
function c_b6783655(bytes8 c__b6783655) pure {}
function c_trueb6783655(bytes8 c__b6783655) pure returns (bool){ return true; }
function c_falseb6783655(bytes8 c__b6783655) pure returns (bool){ return false; }


import { ISeaDropTokenContractMetadataUpgradeable } from "../interfaces/ISeaDropTokenContractMetadataUpgradeable.sol";

import { AllowListData, PublicDrop, TokenGatedDropStage, SignedMintValidationParams } from "../lib/SeaDropStructsUpgradeable.sol";

import { IERC165Upgradeable } from "../../openzeppelin-contracts/contracts/utils/introspection/IERC165Upgradeable.sol";

interface INonFungibleSeaDropTokenUpgradeable is ISeaDropTokenContractMetadataUpgradeable, IERC165Upgradeable {
    /**
     * @dev Revert with an error if a contract is not an allowed
     *      SeaDrop address.
     */
    error OnlyAllowedSeaDrop();

    /**
     * @dev Emit an event when allowed SeaDrop contracts are updated.
     */
    event AllowedSeaDropUpdated(address[] allowedSeaDrop);

    /**
     * @notice Update the allowed SeaDrop contracts.
     *         Only the owner or administrator can use this function.
     *
     * @param allowedSeaDrop The allowed SeaDrop addresses.
     */
    function updateAllowedSeaDrop(address[] calldata allowedSeaDrop) external;

    /**
     * @notice Mint tokens, restricted to the SeaDrop contract.
     *
     * @dev    NOTE: If a token registers itself with multiple SeaDrop
     *         contracts, the implementation of this function should guard
     *         against reentrancy. If the implementing token uses
     *         _safeMint(), or a feeRecipient with a malicious receive() hook
     *         is specified, the token or fee recipients may be able to execute
     *         another mint in the same transaction via a separate SeaDrop
     *         contract.
     *         This is dangerous if an implementing token does not correctly
     *         update the minterNumMinted and currentTotalSupply values before
     *         transferring minted tokens, as SeaDrop references these values
     *         to enforce token limits on a per-wallet and per-stage basis.
     *
     * @param minter   The address to mint to.
     * @param quantity The number of tokens to mint.
     */
    function mintSeaDrop(address minter, uint256 quantity) external payable;

    /**
     * @notice Returns a set of mint stats for the address.
     *         This assists SeaDrop in enforcing maxSupply,
     *         maxTotalMintableByWallet, and maxTokenSupplyForStage checks.
     *
     * @dev    NOTE: Implementing contracts should always update these numbers
     *         before transferring any tokens with _safeMint() to mitigate
     *         consequences of malicious onERC721Received() hooks.
     *
     * @param minter The minter address.
     */
    function getMintStats(address minter)
        external
        view
        returns (
            uint256 minterNumMinted,
            uint256 currentTotalSupply,
            uint256 maxSupply
        );

    /**
     * @notice Update the public drop data for this nft contract on SeaDrop.
     *         Only the owner or administrator can use this function.
     *
     *         The administrator can only update `feeBps`.
     *
     * @param seaDropImpl The allowed SeaDrop contract.
     * @param publicDrop  The public drop data.
     */
    function updatePublicDrop(
        address seaDropImpl,
        PublicDrop calldata publicDrop
    ) external;

    /**
     * @notice Update the allow list data for this nft contract on SeaDrop.
     *         Only the owner or administrator can use this function.
     *
     * @param seaDropImpl   The allowed SeaDrop contract.
     * @param allowListData The allow list data.
     */
    function updateAllowList(
        address seaDropImpl,
        AllowListData calldata allowListData
    ) external;

    /**
     * @notice Update the token gated drop stage data for this nft contract
     *         on SeaDrop.
     *         Only the owner or administrator can use this function.
     *
     *         The administrator, when present, must first set `feeBps`.
     *
     *         Note: If two INonFungibleSeaDropToken tokens are doing
     *         simultaneous token gated drop promotions for each other,
     *         they can be minted by the same actor until
     *         `maxTokenSupplyForStage` is reached. Please ensure the
     *         `allowedNftToken` is not running an active drop during the
     *         `dropStage` time period.
     *
     *
     * @param seaDropImpl     The allowed SeaDrop contract.
     * @param allowedNftToken The allowed nft token.
     * @param dropStage       The token gated drop stage data.
     */
    function updateTokenGatedDrop(
        address seaDropImpl,
        address allowedNftToken,
        TokenGatedDropStage calldata dropStage
    ) external;

    /**
     * @notice Update the drop URI for this nft contract on SeaDrop.
     *         Only the owner or administrator can use this function.
     *
     * @param seaDropImpl The allowed SeaDrop contract.
     * @param dropURI     The new drop URI.
     */
    function updateDropURI(address seaDropImpl, string calldata dropURI)
        external;

    /**
     * @notice Update the creator payout address for this nft contract on SeaDrop.
     *         Only the owner can set the creator payout address.
     *
     * @param seaDropImpl   The allowed SeaDrop contract.
     * @param payoutAddress The new payout address.
     */
    function updateCreatorPayoutAddress(
        address seaDropImpl,
        address payoutAddress
    ) external;

    /**
     * @notice Update the allowed fee recipient for this nft contract
     *         on SeaDrop.
     *         Only the administrator can set the allowed fee recipient.
     *
     * @param seaDropImpl  The allowed SeaDrop contract.
     * @param feeRecipient The new fee recipient.
     */
    function updateAllowedFeeRecipient(
        address seaDropImpl,
        address feeRecipient,
        bool allowed
    ) external;

    /**
     * @notice Update the server-side signers for this nft contract
     *         on SeaDrop.
     *         Only the owner or administrator can use this function.
     *
     * @param seaDropImpl                The allowed SeaDrop contract.
     * @param signer                     The signer to update.
     * @param signedMintValidationParams Minimum and maximum parameters
     *                                   to enforce for signed mints.
     */
    function updateSignedMintValidationParams(
        address seaDropImpl,
        address signer,
        SignedMintValidationParams memory signedMintValidationParams
    ) external;

    /**
     * @notice Update the allowed payers for this nft contract on SeaDrop.
     *         Only the owner or administrator can use this function.
     *
     * @param seaDropImpl The allowed SeaDrop contract.
     * @param payer       The payer to update.
     * @param allowed     Whether the payer is allowed.
     */
    function updatePayer(
        address seaDropImpl,
        address payer,
        bool allowed
    ) external;
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.2
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721AUpgradeable.sol';
import {ERC721AStorage} from './ERC721AStorage.sol';
import './ERC721A__Initializable.sol';

/**
 * @dev Interface of ERC721 token receiver.
 */
interface ERC721A__IERC721ReceiverUpgradeable {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @title ERC721A
 *
 * @dev Implementation of the [ERC721](https://eips.ethereum.org/EIPS/eip-721)
 * Non-Fungible Token Standard, including the Metadata extension.
 * Optimized for lower gas during batch mints.
 *
 * Token IDs are minted in sequential order (e.g. 0, 1, 2, 3, ...)
 * starting from `_startTokenId()`.
 *
 * Assumptions:
 *
 * - An owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 * - The maximum token ID cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721AUpgradeable is ERC721A__Initializable, IERC721AUpgradeable {
    using ERC721AStorage for ERC721AStorage.Layout;

    // =============================================================
    //                           CONSTANTS
    // =============================================================

    // Mask of an entry in packed address data.
    uint256 private constant _BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

    // The bit position of `numberMinted` in packed address data.
    uint256 private constant _BITPOS_NUMBER_MINTED = 64;

    // The bit position of `numberBurned` in packed address data.
    uint256 private constant _BITPOS_NUMBER_BURNED = 128;

    // The bit position of `aux` in packed address data.
    uint256 private constant _BITPOS_AUX = 192;

    // Mask of all 256 bits in packed address data except the 64 bits for `aux`.
    uint256 private constant _BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;

    // The bit position of `startTimestamp` in packed ownership.
    uint256 private constant _BITPOS_START_TIMESTAMP = 160;

    // The bit mask of the `burned` bit in packed ownership.
    uint256 private constant _BITMASK_BURNED = 1 << 224;

    // The bit position of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITPOS_NEXT_INITIALIZED = 225;

    // The bit mask of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITMASK_NEXT_INITIALIZED = 1 << 225;

    // The bit position of `extraData` in packed ownership.
    uint256 private constant _BITPOS_EXTRA_DATA = 232;

    // Mask of all 256 bits in a packed ownership except the 24 bits for `extraData`.
    uint256 private constant _BITMASK_EXTRA_DATA_COMPLEMENT = (1 << 232) - 1;

    // The mask of the lower 160 bits for addresses.
    uint256 private constant _BITMASK_ADDRESS = (1 << 160) - 1;

    // The maximum `quantity` that can be minted with {_mintERC2309}.
    // This limit is to prevent overflows on the address data entries.
    // For a limit of 5000, a total of 3.689e15 calls to {_mintERC2309}
    // is required to cause an overflow, which is unrealistic.
    uint256 private constant _MAX_MINT_ERC2309_QUANTITY_LIMIT = 5000;

    // The `Transfer` event signature is given by:
    // `keccak256(bytes("Transfer(address,address,uint256)"))`.
    bytes32 private constant _TRANSFER_EVENT_SIGNATURE =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================

    function __ERC721A_init(string memory name_, string memory symbol_) internal onlyInitializingERC721A {
        __ERC721A_init_unchained(name_, symbol_);
    }

    function __ERC721A_init_unchained(string memory name_, string memory symbol_) internal onlyInitializingERC721A {
        ERC721AStorage.layout()._name = name_;
        ERC721AStorage.layout()._symbol = symbol_;
        ERC721AStorage.layout()._currentIndex = _startTokenId();
    }

    // =============================================================
    //                   TOKEN COUNTING OPERATIONS
    // =============================================================

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Returns the next token ID to be minted.
     */
    function _nextTokenId() internal view virtual returns (uint256) {
        return ERC721AStorage.layout()._currentIndex;
    }

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex - _startTokenId()` times.
        unchecked {
            return ERC721AStorage.layout()._currentIndex - ERC721AStorage.layout()._burnCounter - _startTokenId();
        }
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view virtual returns (uint256) {
        // Counter underflow is impossible as `_currentIndex` does not decrement,
        // and it is initialized to `_startTokenId()`.
        unchecked {
            return ERC721AStorage.layout()._currentIndex - _startTokenId();
        }
    }

    /**
     * @dev Returns the total number of tokens burned.
     */
    function _totalBurned() internal view virtual returns (uint256) {
        return ERC721AStorage.layout()._burnCounter;
    }

    // =============================================================
    //                    ADDRESS DATA OPERATIONS
    // =============================================================

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return ERC721AStorage.layout()._packedAddressData[owner] & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return
            (ERC721AStorage.layout()._packedAddressData[owner] >> _BITPOS_NUMBER_MINTED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return
            (ERC721AStorage.layout()._packedAddressData[owner] >> _BITPOS_NUMBER_BURNED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return uint64(ERC721AStorage.layout()._packedAddressData[owner] >> _BITPOS_AUX);
    }

    /**
     * Sets the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal virtual {
        uint256 packed = ERC721AStorage.layout()._packedAddressData[owner];
        uint256 auxCasted;
        // Cast `aux` with assembly to avoid redundant masking.
        assembly {
            auxCasted := aux
        }
        packed = (packed & _BITMASK_AUX_COMPLEMENT) | (auxCasted << _BITPOS_AUX);
        ERC721AStorage.layout()._packedAddressData[owner] = packed;
    }

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // The interface IDs are constants representing the first 4 bytes
        // of the XOR of all function selectors in the interface.
        // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
        // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() public view virtual override returns (string memory) {
        return ERC721AStorage.layout()._name;
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() public view virtual override returns (string memory) {
        return ERC721AStorage.layout()._symbol;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, it can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    // =============================================================
    //                     OWNERSHIPS OPERATIONS
    // =============================================================

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return address(uint160(_packedOwnershipOf(tokenId)));
    }

    /**
     * @dev Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around over time.
     */
    function _ownershipOf(uint256 tokenId) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnershipOf(tokenId));
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct at `index`.
     */
    function _ownershipAt(uint256 index) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(ERC721AStorage.layout()._packedOwnerships[index]);
    }

    /**
     * @dev Initializes the ownership slot minted at `index` for efficiency purposes.
     */
    function _initializeOwnershipAt(uint256 index) internal virtual {
        if (ERC721AStorage.layout()._packedOwnerships[index] == 0) {
            ERC721AStorage.layout()._packedOwnerships[index] = _packedOwnershipOf(index);
        }
    }

    /**
     * Returns the packed ownership data of `tokenId`.
     */
    function _packedOwnershipOf(uint256 tokenId) private view returns (uint256) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr)
                if (curr < ERC721AStorage.layout()._currentIndex) {
                    uint256 packed = ERC721AStorage.layout()._packedOwnerships[curr];
                    // If not burned.
                    if (packed & _BITMASK_BURNED == 0) {
                        // Invariant:
                        // There will always be an initialized ownership slot
                        // (i.e. `ownership.addr != address(0) && ownership.burned == false`)
                        // before an unintialized ownership slot
                        // (i.e. `ownership.addr == address(0) && ownership.burned == false`)
                        // Hence, `curr` will not underflow.
                        //
                        // We can directly compare the packed value.
                        // If the address is zero, packed will be zero.
                        while (packed == 0) {
                            packed = ERC721AStorage.layout()._packedOwnerships[--curr];
                        }
                        return packed;
                    }
                }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct from `packed`.
     */
    function _unpackedOwnership(uint256 packed) private pure returns (TokenOwnership memory ownership) {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> _BITPOS_START_TIMESTAMP);
        ownership.burned = packed & _BITMASK_BURNED != 0;
        ownership.extraData = uint24(packed >> _BITPOS_EXTRA_DATA);
    }

    /**
     * @dev Packs ownership data into a single uint256.
     */
    function _packOwnershipData(address owner, uint256 flags) private view returns (uint256 result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // `owner | (block.timestamp << _BITPOS_START_TIMESTAMP) | flags`.
            result := or(owner, or(shl(_BITPOS_START_TIMESTAMP, timestamp()), flags))
        }
    }

    /**
     * @dev Returns the `nextInitialized` flag set if `quantity` equals 1.
     */
    function _nextInitializedFlag(uint256 quantity) private pure returns (uint256 result) {
        // For branchless setting of the `nextInitialized` flag.
        assembly {
            // `(quantity == 1) << _BITPOS_NEXT_INITIALIZED`.
            result := shl(_BITPOS_NEXT_INITIALIZED, eq(quantity, 1))
        }
    }

    // =============================================================
    //                      APPROVAL OPERATIONS
    // =============================================================

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);

        if (_msgSenderERC721A() != owner)
            if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                revert ApprovalCallerNotOwnerNorApproved();
            }

        ERC721AStorage.layout()._tokenApprovals[tokenId].value = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return ERC721AStorage.layout()._tokenApprovals[tokenId].value;
    }

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        ERC721AStorage.layout()._operatorApprovals[_msgSenderERC721A()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
    }

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return ERC721AStorage.layout()._operatorApprovals[owner][operator];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted. See {_mint}.
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return
            _startTokenId() <= tokenId &&
            tokenId < ERC721AStorage.layout()._currentIndex && // If within bounds,
            ERC721AStorage.layout()._packedOwnerships[tokenId] & _BITMASK_BURNED == 0; // and not burned.
    }

    /**
     * @dev Returns whether `msgSender` is equal to `approvedAddress` or `owner`.
     */
    function _isSenderApprovedOrOwner(
        address approvedAddress,
        address owner,
        address msgSender
    ) private pure returns (bool result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // Mask `msgSender` to the lower 160 bits, in case the upper bits somehow aren't clean.
            msgSender := and(msgSender, _BITMASK_ADDRESS)
            // `msgSender == owner || msgSender == approvedAddress`.
            result := or(eq(msgSender, owner), eq(msgSender, approvedAddress))
        }
    }

    /**
     * @dev Returns the storage slot and value for the approved address of `tokenId`.
     */
    function _getApprovedSlotAndAddress(uint256 tokenId)
        private
        view
        returns (uint256 approvedAddressSlot, address approvedAddress)
    {
        ERC721AStorage.TokenApprovalRef storage tokenApproval = ERC721AStorage.layout()._tokenApprovals[tokenId];
        // The following is equivalent to `approvedAddress = _tokenApprovals[tokenId].value`.
        assembly {
            approvedAddressSlot := tokenApproval.slot
            approvedAddress := sload(approvedAddressSlot)
        }
    }

    // =============================================================
    //                      TRANSFER OPERATIONS
    // =============================================================

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        if (address(uint160(prevOwnershipPacked)) != from) revert TransferFromIncorrectOwner();

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        // The nested ifs save around 20+ gas over a compound boolean condition.
        if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
            if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();

        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // We can directly increment and decrement the balances.
            --ERC721AStorage.layout()._packedAddressData[from]; // Updates: `balance -= 1`.
            ++ERC721AStorage.layout()._packedAddressData[to]; // Updates: `balance += 1`.

            // Updates:
            // - `address` to the next owner.
            // - `startTimestamp` to the timestamp of transfering.
            // - `burned` to `false`.
            // - `nextInitialized` to `true`.
            ERC721AStorage.layout()._packedOwnerships[tokenId] = _packOwnershipData(
                to,
                _BITMASK_NEXT_INITIALIZED | _nextExtraData(from, to, prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (ERC721AStorage.layout()._packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != ERC721AStorage.layout()._currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        ERC721AStorage.layout()._packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        transferFrom(from, to, tokenId);
        if (to.code.length != 0)
            if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
                revert TransferToNonERC721ReceiverImplementer();
            }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token IDs
     * are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token IDs
     * have been transferred. This includes minting.
     * And also called after one token has been burned.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Private function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * `from` - Previous owner of the given token ID.
     * `to` - Target address that will receive the token.
     * `tokenId` - Token ID to be transferred.
     * `_data` - Optional data to send along with the call.
     *
     * Returns whether the call correctly returned the expected magic value.
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try
            ERC721A__IERC721ReceiverUpgradeable(to).onERC721Received(_msgSenderERC721A(), from, tokenId, _data)
        returns (bytes4 retval) {
            return retval == ERC721A__IERC721ReceiverUpgradeable(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    // =============================================================
    //                        MINT OPERATIONS
    // =============================================================

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _mint(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = ERC721AStorage.layout()._currentIndex;
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // `balance` and `numberMinted` have a maximum limit of 2**64.
        // `tokenId` has a maximum limit of 2**256.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            ERC721AStorage.layout()._packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            ERC721AStorage.layout()._packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            uint256 toMasked;
            uint256 end = startTokenId + quantity;

            // Use assembly to loop and emit the `Transfer` event for gas savings.
            // The duplicated `log4` removes an extra check and reduces stack juggling.
            // The assembly, together with the surrounding Solidity code, have been
            // delicately arranged to nudge the compiler into producing optimized opcodes.
            assembly {
                // Mask `to` to the lower 160 bits, in case the upper bits somehow aren't clean.
                toMasked := and(to, _BITMASK_ADDRESS)
                // Emit the `Transfer` event.
                log4(
                    0, // Start of data (0, since no data).
                    0, // End of data (0, since no data).
                    _TRANSFER_EVENT_SIGNATURE, // Signature.
                    0, // `address(0)`.
                    toMasked, // `to`.
                    startTokenId // `tokenId`.
                )

                // The `iszero(eq(,))` check ensures that large values of `quantity`
                // that overflows uint256 will make the loop run out of gas.
                // The compiler will optimize the `iszero` away for performance.
                for {
                    let tokenId := add(startTokenId, 1)
                } iszero(eq(tokenId, end)) {
                    tokenId := add(tokenId, 1)
                } {
                    // Emit the `Transfer` event. Similar to above.
                    log4(0, 0, _TRANSFER_EVENT_SIGNATURE, 0, toMasked, tokenId)
                }
            }
            if (toMasked == 0) revert MintToZeroAddress();

            ERC721AStorage.layout()._currentIndex = end;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * This function is intended for efficient minting only during contract creation.
     *
     * It emits only one {ConsecutiveTransfer} as defined in
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309),
     * instead of a sequence of {Transfer} event(s).
     *
     * Calling this function outside of contract creation WILL make your contract
     * non-compliant with the ERC721 standard.
     * For full ERC721 compliance, substituting ERC721 {Transfer} event(s) with the ERC2309
     * {ConsecutiveTransfer} event is only permissible during contract creation.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {ConsecutiveTransfer} event.
     */
    function _mintERC2309(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = ERC721AStorage.layout()._currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();
        if (quantity > _MAX_MINT_ERC2309_QUANTITY_LIMIT) revert MintERC2309QuantityExceedsLimit();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are unrealistic due to the above check for `quantity` to be below the limit.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            ERC721AStorage.layout()._packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            ERC721AStorage.layout()._packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            emit ConsecutiveTransfer(startTokenId, startTokenId + quantity - 1, address(0), to);

            ERC721AStorage.layout()._currentIndex = startTokenId + quantity;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * See {_mint}.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal virtual {
        _mint(to, quantity);

        unchecked {
            if (to.code.length != 0) {
                uint256 end = ERC721AStorage.layout()._currentIndex;
                uint256 index = end - quantity;
                do {
                    if (!_checkContractOnERC721Received(address(0), to, index++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (index < end);
                // Reentrancy protection.
                if (ERC721AStorage.layout()._currentIndex != end) revert();
            }
        }
    }

    /**
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address to, uint256 quantity) internal virtual {
        _safeMint(to, quantity, '');
    }

    // =============================================================
    //                        BURN OPERATIONS
    // =============================================================

    /**
     * @dev Equivalent to `_burn(tokenId, false)`.
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        address from = address(uint160(prevOwnershipPacked));

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        if (approvalCheck) {
            // The nested ifs save around 20+ gas over a compound boolean condition.
            if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
                if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // Updates:
            // - `balance -= 1`.
            // - `numberBurned += 1`.
            //
            // We can directly decrement the balance, and increment the number burned.
            // This is equivalent to `packed -= 1; packed += 1 << _BITPOS_NUMBER_BURNED;`.
            ERC721AStorage.layout()._packedAddressData[from] += (1 << _BITPOS_NUMBER_BURNED) - 1;

            // Updates:
            // - `address` to the last owner.
            // - `startTimestamp` to the timestamp of burning.
            // - `burned` to `true`.
            // - `nextInitialized` to `true`.
            ERC721AStorage.layout()._packedOwnerships[tokenId] = _packOwnershipData(
                from,
                (_BITMASK_BURNED | _BITMASK_NEXT_INITIALIZED) | _nextExtraData(from, address(0), prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (ERC721AStorage.layout()._packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != ERC721AStorage.layout()._currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        ERC721AStorage.layout()._packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            ERC721AStorage.layout()._burnCounter++;
        }
    }

    // =============================================================
    //                     EXTRA DATA OPERATIONS
    // =============================================================

    /**
     * @dev Directly sets the extra data for the ownership data `index`.
     */
    function _setExtraDataAt(uint256 index, uint24 extraData) internal virtual {
        uint256 packed = ERC721AStorage.layout()._packedOwnerships[index];
        if (packed == 0) revert OwnershipNotInitializedForExtraData();
        uint256 extraDataCasted;
        // Cast `extraData` with assembly to avoid redundant masking.
        assembly {
            extraDataCasted := extraData
        }
        packed = (packed & _BITMASK_EXTRA_DATA_COMPLEMENT) | (extraDataCasted << _BITPOS_EXTRA_DATA);
        ERC721AStorage.layout()._packedOwnerships[index] = packed;
    }

    /**
     * @dev Called during each token transfer to set the 24bit `extraData` field.
     * Intended to be overridden by the cosumer contract.
     *
     * `previousExtraData` - the value of `extraData` before transfer.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _extraData(
        address from,
        address to,
        uint24 previousExtraData
    ) internal view virtual returns (uint24) {}

    /**
     * @dev Returns the next extra data for the packed ownership data.
     * The returned result is shifted into position.
     */
    function _nextExtraData(
        address from,
        address to,
        uint256 prevOwnershipPacked
    ) private view returns (uint256) {
        uint24 extraData = uint24(prevOwnershipPacked >> _BITPOS_EXTRA_DATA);
        return uint256(_extraData(from, to, extraData)) << _BITPOS_EXTRA_DATA;
    }

    // =============================================================
    //                       OTHER OPERATIONS
    // =============================================================

    /**
     * @dev Returns the message sender (defaults to `msg.sender`).
     *
     * If you are writing GSN compatible contracts, you need to override this function.
     */
    function _msgSenderERC721A() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Converts a uint256 to its ASCII string decimal representation.
     */
    function _toString(uint256 value) internal pure virtual returns (string memory str) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
            // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 word for the trailing zeros padding, 1 word for the length,
            // and 3 words for a maximum of 78 digits. Total: 5 * 0x20 = 0xa0.
            let m := add(mload(0x40), 0xa0)
            // Update the free memory pointer to allocate.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;
import { ReentrancyGuardStorage } from "./ReentrancyGuardStorage.sol";
import "../../../openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuardUpgradeable is Initializable {
    using ReentrancyGuardStorage for ReentrancyGuardStorage.Layout;
    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        ReentrancyGuardStorage.layout().locked = 1;
    }

    modifier nonReentrant() virtual {
        require(ReentrancyGuardStorage.layout().locked == 1, "REENTRANCY");

        ReentrancyGuardStorage.layout().locked = 2;

        _;

        ReentrancyGuardStorage.layout().locked = 1;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {OperatorFilterer721Upgradeable} from "./OperatorFilterer721Upgradeable.sol";

abstract contract DefaultOperatorFilterer721Upgradeable is OperatorFilterer721Upgradeable {
    address constant DEFAULT_SUBSCRIPTION = address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);

    function __DefaultOperatorFilterer721_init() public onlyInitializing {
        OperatorFilterer721Upgradeable.__OperatorFilterer721_init(DEFAULT_SUBSCRIPTION, true);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
function c_617a6f63(bytes8 c__617a6f63) pure {}
function c_true617a6f63(bytes8 c__617a6f63) pure returns (bool){ return true; }
function c_false617a6f63(bytes8 c__617a6f63) pure returns (bool){ return false; }


interface ISeaDropTokenContractMetadataUpgradeable {
    /**
     * @dev Emit an event when the max token supply is updated.
     */
    event MaxSupplyUpdated(uint256 newMaxSupply);

    /**
     * @dev Emit an event with the previous and new provenance hash after
     *      being updated.
     */
    event ProvenanceHashUpdated(bytes32 previousHash, bytes32 newHash);

    /**
     * @dev Emit an event when the URI for the collection-level metadata
     *      is updated.
     */
    event ContractURIUpdated(string newContractURI);

    /**
     * @dev Emit an event for partial reveals/updates.
     *      Batch update implementation should be left to contract.
     *
     * @param startTokenId The start token id.
     * @param endTokenId   The end token id.
     */
    event TokenURIUpdated(
        uint256 indexed startTokenId,
        uint256 indexed endTokenId
    );

    /**
     * @dev Emit an event for full token metadata reveals/updates.
     *
     * @param baseURI The base URI.
     */
    event BaseURIUpdated(string baseURI);

    /**
     * @notice Returns the contract URI.
     */
    function contractURI() external view returns (string memory);

    /**
     * @notice Sets the contract URI for contract metadata.
     *
     * @param newContractURI The new contract URI.
     */
    function setContractURI(string calldata newContractURI) external;

    /**
     * @notice Returns the base URI for token metadata.
     */
    function baseURI() external view returns (string memory);

    /**
     * @notice Sets the base URI for the token metadata and emits an event.
     *
     * @param tokenURI The new base URI to set.
     */
    function setBaseURI(string calldata tokenURI) external;

    /**
     * @notice Returns the max token supply.
     */
    function maxSupply() external view returns (uint256);

    /**
     * @notice Sets the max supply and emits an event.
     *
     * @param newMaxSupply The new max supply to set.
     */
    function setMaxSupply(uint256 newMaxSupply) external;

    /**
     * @notice Returns the provenance hash.
     *         The provenance hash is used for random reveals, which
     *         is a hash of the ordered metadata to show it is unmodified
     *         after mint has started.
     */
    function provenanceHash() external view returns (bytes32);

    /**
     * @notice Sets the provenance hash and emits an event.
     *         The provenance hash is used for random reveals, which
     *         is a hash of the ordered metadata to show it is unmodified
     *         after mint has started.
     *         This function will revert after the first item has been minted.
     *
     * @param newProvenanceHash The new provenance hash to set.
     */
    function setProvenanceHash(bytes32 newProvenanceHash) external;

    /**
     * @dev Revert with an error when attempting to set the provenance
     *      hash after the mint has started.
     */
    error ProvenanceHashCannotBeSetAfterMintStarted();
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import { ConstructorInitializableUpgradeable } from "./ConstructorInitializableUpgradeable.sol";
import { TwoStepOwnableStorage } from "./TwoStepOwnableStorage.sol";
import "../../openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";

/**
@notice A two-step extension of Ownable, where the new owner must claim ownership of the contract after owner initiates transfer
Owner can cancel the transfer at any point before the new owner claims ownership.
Helpful in guarding against transferring ownership to an address that is unable to act as the Owner.
*/
abstract contract TwoStepOwnableUpgradeable is Initializable, ConstructorInitializableUpgradeable {
    using TwoStepOwnableStorage for TwoStepOwnableStorage.Layout;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    event PotentialOwnerUpdated(address newPotentialAdministrator);

    error NewOwnerIsZeroAddress();
    error NotNextOwner();
    error OnlyOwner();

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function __TwoStepOwnable_init() internal onlyInitializing {
        __ConstructorInitializable_init_unchained();
        __TwoStepOwnable_init_unchained();
    }

    function __TwoStepOwnable_init_unchained() internal onlyInitializing {
        _initialize();
    }

    function _initialize() private onlyConstructor {
        _transferOwnership(msg.sender);
    }

    ///@notice Initiate ownership transfer to newPotentialOwner. Note: new owner will have to manually acceptOwnership
    ///@param newPotentialOwner address of potential new owner
    function transferOwnership(address newPotentialOwner)
        public
        virtual
        onlyOwner
    {
        if (newPotentialOwner == address(0)) {
            revert NewOwnerIsZeroAddress();
        }
        TwoStepOwnableStorage.layout().potentialOwner = newPotentialOwner;
        emit PotentialOwnerUpdated(newPotentialOwner);
    }

    ///@notice Claim ownership of smart contract, after the current owner has initiated the process with transferOwnership
    function acceptOwnership() public virtual {
        address _potentialOwner = TwoStepOwnableStorage.layout().potentialOwner;
        if (msg.sender != _potentialOwner) {
            revert NotNextOwner();
        }
        delete TwoStepOwnableStorage.layout().potentialOwner;
        emit PotentialOwnerUpdated(address(0));
        _transferOwnership(_potentialOwner);
    }

    ///@notice cancel ownership transfer
    function cancelOwnershipTransfer() public virtual onlyOwner {
        delete TwoStepOwnableStorage.layout().potentialOwner;
        emit PotentialOwnerUpdated(address(0));
    }

    function owner() public view virtual returns (address) {
        return TwoStepOwnableStorage.layout()._owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (TwoStepOwnableStorage.layout()._owner != msg.sender) {
            revert OnlyOwner();
        }
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
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = TwoStepOwnableStorage.layout()._owner;
        TwoStepOwnableStorage.layout()._owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library ERC721AStorage {
    // Bypass for a `--via-ir` bug (https://github.com/chiru-labs/ERC721A/pull/364).
    struct TokenApprovalRef {
        address value;
    }

    struct Layout {
        // =============================================================
        //                            STORAGE
        // =============================================================

        // The next token ID to be minted.
        uint256 _currentIndex;
        // The number of tokens burned.
        uint256 _burnCounter;
        // Token name
        string _name;
        // Token symbol
        string _symbol;
        // Mapping from token ID to ownership details
        // An empty struct value does not necessarily mean the token is unowned.
        // See {_packedOwnershipOf} implementation for details.
        //
        // Bits Layout:
        // - [0..159]   `addr`
        // - [160..223] `startTimestamp`
        // - [224]      `burned`
        // - [225]      `nextInitialized`
        // - [232..255] `extraData`
        mapping(uint256 => uint256) _packedOwnerships;
        // Mapping owner address to address data.
        //
        // Bits Layout:
        // - [0..63]    `balance`
        // - [64..127]  `numberMinted`
        // - [128..191] `numberBurned`
        // - [192..255] `aux`
        mapping(address => uint256) _packedAddressData;
        // Mapping from token ID to approved address.
        mapping(uint256 => ERC721AStorage.TokenApprovalRef) _tokenApprovals;
        // Mapping from owner to operator approvals
        mapping(address => mapping(address => bool)) _operatorApprovals;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256('ERC721A.contracts.storage.ERC721A');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable diamond facet contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */

import {ERC721A__InitializableStorage} from './ERC721A__InitializableStorage.sol';

abstract contract ERC721A__Initializable {
    using ERC721A__InitializableStorage for ERC721A__InitializableStorage.Layout;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializerERC721A() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(
            ERC721A__InitializableStorage.layout()._initializing
                ? _isConstructor()
                : !ERC721A__InitializableStorage.layout()._initialized,
            'ERC721A__Initializable: contract is already initialized'
        );

        bool isTopLevelCall = !ERC721A__InitializableStorage.layout()._initializing;
        if (isTopLevelCall) {
            ERC721A__InitializableStorage.layout()._initializing = true;
            ERC721A__InitializableStorage.layout()._initialized = true;
        }

        _;

        if (isTopLevelCall) {
            ERC721A__InitializableStorage.layout()._initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializingERC721A() {
        require(
            ERC721A__InitializableStorage.layout()._initializing,
            'ERC721A__Initializable: contract is not initializing'
        );
        _;
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        assembly {
            cs := extcodesize(self)
        }
        return cs == 0;
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.2
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721AUpgradeable {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
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
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
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
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
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
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
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
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base storage for the  initialization function for upgradeable diamond facet contracts
 **/

library ERC721A__InitializableStorage {
    struct Layout {
        /*
         * Indicates that the contract has been initialized.
         */
        bool _initialized;
        /*
         * Indicates that the contract is in the process of being initialized.
         */
        bool _initializing;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256('ERC721A.contracts.storage.initializable.facet');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;
import "../../openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";

/**
 * @author emo.eth
 * @notice Abstract smart contract that provides an onlyUninitialized modifier which only allows calling when
 *         from within a constructor of some sort, whether directly instantiating an inherting contract,
 *         or when delegatecalling from a proxy
 */
abstract contract ConstructorInitializableUpgradeable is Initializable {
    function __ConstructorInitializable_init() internal onlyInitializing {
        __ConstructorInitializable_init_unchained();
    }

    function __ConstructorInitializable_init_unchained() internal onlyInitializing {
    }
    error AlreadyInitialized();

    modifier onlyConstructor() {
        if (address(this).code.length != 0) {
            revert AlreadyInitialized();
        }
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import { TwoStepOwnableUpgradeable } from "./TwoStepOwnableUpgradeable.sol";

library TwoStepOwnableStorage {

  struct Layout {
    address _owner;

    address potentialOwner;
  
  }
  
  bytes32 internal constant STORAGE_SLOT = keccak256('openzepplin.contracts.storage.TwoStepOwnable');

  function layout() internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
function c_2dc713e7(bytes8 c__2dc713e7) pure {}
function c_true2dc713e7(bytes8 c__2dc713e7) pure returns (bool){ return true; }
function c_false2dc713e7(bytes8 c__2dc713e7) pure returns (bool){ return false; }


import { PublicDrop, TokenGatedDropStage, SignedMintValidationParams } from "./SeaDropStructsUpgradeable.sol";

interface SeaDropErrorsAndEventsUpgradeable {
    /**
     * @dev Revert with an error if the drop stage is not active.
     */
    error NotActive(
        uint256 currentTimestamp,
        uint256 startTimestamp,
        uint256 endTimestamp
    );

    /**
     * @dev Revert with an error if the mint quantity is zero.
     */
    error MintQuantityCannotBeZero();

    /**
     * @dev Revert with an error if the mint quantity exceeds the max allowed
     *      to be minted per wallet.
     */
    error MintQuantityExceedsMaxMintedPerWallet(uint256 total, uint256 allowed);

    /**
     * @dev Revert with an error if the mint quantity exceeds the max token
     *      supply.
     */
    error MintQuantityExceedsMaxSupply(uint256 total, uint256 maxSupply);

    /**
     * @dev Revert with an error if the mint quantity exceeds the max token
     *      supply for the stage.
     *      Note: The `maxTokenSupplyForStage` for public mint is
     *      always `type(uint).max`.
     */
    error MintQuantityExceedsMaxTokenSupplyForStage(
        uint256 total, 
        uint256 maxTokenSupplyForStage
    );
    
    /**
     * @dev Revert if the fee recipient is the zero address.
     */
    error FeeRecipientCannotBeZeroAddress();

    /**
     * @dev Revert if the fee recipient is not already included.
     */
    error FeeRecipientNotPresent();

    /**
     * @dev Revert if the fee basis points is greater than 10_000.
     */
     error InvalidFeeBps(uint256 feeBps);

    /**
     * @dev Revert if the fee recipient is already included.
     */
    error DuplicateFeeRecipient();

    /**
     * @dev Revert if the fee recipient is restricted and not allowed.
     */
    error FeeRecipientNotAllowed();

    /**
     * @dev Revert if the creator payout address is the zero address.
     */
    error CreatorPayoutAddressCannotBeZeroAddress();

    /**
     * @dev Revert with an error if the received payment is incorrect.
     */
    error IncorrectPayment(uint256 got, uint256 want);

    /**
     * @dev Revert with an error if the allow list proof is invalid.
     */
    error InvalidProof();

    /**
     * @dev Revert if a supplied signer address is the zero address.
     */
    error SignerCannotBeZeroAddress();

    /**
     * @dev Revert with an error if signer's signature is invalid.
     */
    error InvalidSignature(address recoveredSigner);

    /**
     * @dev Revert with an error if a signer is not included in
     *      the enumeration when removing.
     */
    error SignerNotPresent();

    /**
     * @dev Revert with an error if a payer is not included in
     *      the enumeration when removing.
     */
    error PayerNotPresent();

    /**
     * @dev Revert with an error if a payer is already included in mapping
     *      when adding.
     *      Note: only applies when adding a single payer, as duplicates in
     *      enumeration can be removed with updatePayer.
     */
    error DuplicatePayer();

    /**
     * @dev Revert with an error if the payer is not allowed. The minter must
     *      pay for their own mint.
     */
    error PayerNotAllowed();

    /**
     * @dev Revert if a supplied payer address is the zero address.
     */
    error PayerCannotBeZeroAddress();

    /**
     * @dev Revert with an error if the sender does not
     *      match the INonFungibleSeaDropToken interface.
     */
    error OnlyINonFungibleSeaDropToken(address sender);

    /**
     * @dev Revert with an error if the sender of a token gated supplied
     *      drop stage redeem is not the owner of the token.
     */
    error TokenGatedNotTokenOwner(
        address nftContract,
        address allowedNftToken,
        uint256 allowedNftTokenId
    );

    /**
     * @dev Revert with an error if the token id has already been used to
     *      redeem a token gated drop stage.
     */
    error TokenGatedTokenIdAlreadyRedeemed(
        address nftContract,
        address allowedNftToken,
        uint256 allowedNftTokenId
    );

    /**
     * @dev Revert with an error if an empty TokenGatedDropStage is provided
     *      for an already-empty TokenGatedDropStage.
     */
     error TokenGatedDropStageNotPresent();

    /**
     * @dev Revert with an error if an allowedNftToken is set to
     *      the zero address.
     */
     error TokenGatedDropAllowedNftTokenCannotBeZeroAddress();

    /**
     * @dev Revert with an error if an allowedNftToken is set to
     *      the drop token itself.
     */
     error TokenGatedDropAllowedNftTokenCannotBeDropToken();


    /**
     * @dev Revert with an error if supplied signed mint price is less than
     *      the minimum specified.
     */
    error InvalidSignedMintPrice(uint256 got, uint256 minimum);

    /**
     * @dev Revert with an error if supplied signed maxTotalMintableByWallet
     *      is greater than the maximum specified.
     */
    error InvalidSignedMaxTotalMintableByWallet(uint256 got, uint256 maximum);

    /**
     * @dev Revert with an error if supplied signed start time is less than
     *      the minimum specified.
     */
    error InvalidSignedStartTime(uint256 got, uint256 minimum);
    
    /**
     * @dev Revert with an error if supplied signed end time is greater than
     *      the maximum specified.
     */
    error InvalidSignedEndTime(uint256 got, uint256 maximum);

    /**
     * @dev Revert with an error if supplied signed maxTokenSupplyForStage
     *      is greater than the maximum specified.
     */
     error InvalidSignedMaxTokenSupplyForStage(uint256 got, uint256 maximum);
    
     /**
     * @dev Revert with an error if supplied signed feeBps is greater than
     *      the maximum specified, or less than the minimum.
     */
    error InvalidSignedFeeBps(uint256 got, uint256 minimumOrMaximum);

    /**
     * @dev Revert with an error if signed mint did not specify to restrict
     *      fee recipients.
     */
    error SignedMintsMustRestrictFeeRecipients();

    /**
     * @dev Revert with an error if a signature for a signed mint has already
     *      been used.
     */
    error SignatureAlreadyUsed();

    /**
     * @dev An event with details of a SeaDrop mint, for analytical purposes.
     * 
     * @param nftContract    The nft contract.
     * @param minter         The mint recipient.
     * @param feeRecipient   The fee recipient.
     * @param payer          The address who payed for the tx.
     * @param quantityMinted The number of tokens minted.
     * @param unitMintPrice  The amount paid for each token.
     * @param feeBps         The fee out of 10_000 basis points collected.
     * @param dropStageIndex The drop stage index. Items minted
     *                       through mintPublic() have
     *                       dropStageIndex of 0.
     */
    event SeaDropMint(
        address indexed nftContract,
        address indexed minter,
        address indexed feeRecipient,
        address payer,
        uint256 quantityMinted,
        uint256 unitMintPrice,
        uint256 feeBps,
        uint256 dropStageIndex
    );

    /**
     * @dev An event with updated public drop data for an nft contract.
     */
    event PublicDropUpdated(
        address indexed nftContract,
        PublicDrop publicDrop
    );

    /**
     * @dev An event with updated token gated drop stage data
     *      for an nft contract.
     */
    event TokenGatedDropStageUpdated(
        address indexed nftContract,
        address indexed allowedNftToken,
        TokenGatedDropStage dropStage
    );

    /**
     * @dev An event with updated allow list data for an nft contract.
     * 
     * @param nftContract        The nft contract.
     * @param previousMerkleRoot The previous allow list merkle root.
     * @param newMerkleRoot      The new allow list merkle root.
     * @param publicKeyURI       If the allow list is encrypted, the public key
     *                           URIs that can decrypt the list.
     *                           Empty if unencrypted.
     * @param allowListURI       The URI for the allow list.
     */
    event AllowListUpdated(
        address indexed nftContract,
        bytes32 indexed previousMerkleRoot,
        bytes32 indexed newMerkleRoot,
        string[] publicKeyURI,
        string allowListURI
    );

    /**
     * @dev An event with updated drop URI for an nft contract.
     */
    event DropURIUpdated(address indexed nftContract, string newDropURI);

    /**
     * @dev An event with the updated creator payout address for an nft
     *      contract.
     */
    event CreatorPayoutAddressUpdated(
        address indexed nftContract,
        address indexed newPayoutAddress
    );

    /**
     * @dev An event with the updated allowed fee recipient for an nft
     *      contract.
     */
    event AllowedFeeRecipientUpdated(
        address indexed nftContract,
        address indexed feeRecipient,
        bool indexed allowed
    );

    /**
     * @dev An event with the updated validation parameters for server-side
     *      signers.
     */
    event SignedMintValidationParamsUpdated(
        address indexed nftContract,
        address indexed signer,
        SignedMintValidationParams signedMintValidationParams
    );   

    /**
     * @dev An event with the updated payer for an nft contract.
     */
    event PayerUpdated(
        address indexed nftContract,
        address indexed payer,
        bool indexed allowed
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import { ReentrancyGuardUpgradeable } from "./ReentrancyGuardUpgradeable.sol";

library ReentrancyGuardStorage {

  struct Layout {
    uint256 locked;
  
  }
  
  bytes32 internal constant STORAGE_SLOT = keccak256('openzepplin.contracts.storage.ReentrancyGuard');

  function layout() internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IOperatorFilterRegistry} from "../../IOperatorFilterRegistry.sol";
import {Initializable} from "../../../../openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";

abstract contract OperatorFilterer721Upgradeable is Initializable {
    error OperatorNotAllowed(address operator);

    IOperatorFilterRegistry constant operatorFilterRegistry =
        IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);

    function __OperatorFilterer721_init(address subscriptionOrRegistrantToCopy, bool subscribe)
        public
        onlyInitializing
    {
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        if (address(operatorFilterRegistry).code.length > 0) {
            if (!operatorFilterRegistry.isRegistered(address(this))) {
                if (subscribe) {
                    operatorFilterRegistry.registerAndSubscribe(address(this), subscriptionOrRegistrantToCopy);
                } else {
                    if (subscriptionOrRegistrantToCopy != address(0)) {
                        operatorFilterRegistry.registerAndCopyEntries(address(this), subscriptionOrRegistrantToCopy);
                    } else {
                        operatorFilterRegistry.register(address(this));
                    }
                }
            }
        }
    }

    modifier onlyAllowedOperator(address from) virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(operatorFilterRegistry).code.length > 0) {
            // Allow spending tokens from addresses with balance
            // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
            // from an EOA.
            if (from == msg.sender) {
                _;
                return;
            }
            if (
                !(
                    operatorFilterRegistry.isOperatorAllowed(address(this), msg.sender)
                        && operatorFilterRegistry.isOperatorAllowed(address(this), from)
                )
            ) {
                revert OperatorNotAllowed(msg.sender);
            }
        }
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IOperatorFilterRegistry {
    function isOperatorAllowed(address registrant, address operator) external view returns (bool);
    function register(address registrant) external;
    function registerAndSubscribe(address registrant, address subscription) external;
    function registerAndCopyEntries(address registrant, address registrantToCopy) external;
    function updateOperator(address registrant, address operator, bool filtered) external;
    function updateOperators(address registrant, address[] calldata operators, bool filtered) external;
    function updateCodeHash(address registrant, bytes32 codehash, bool filtered) external;
    function updateCodeHashes(address registrant, bytes32[] calldata codeHashes, bool filtered) external;
    function subscribe(address registrant, address registrantToSubscribe) external;
    function unsubscribe(address registrant, bool copyExistingEntries) external;
    function subscriptionOf(address addr) external returns (address registrant);
    function subscribers(address registrant) external returns (address[] memory);
    function subscriberAt(address registrant, uint256 index) external returns (address);
    function copyEntriesOf(address registrant, address registrantToCopy) external;
    function isOperatorFiltered(address registrant, address operator) external returns (bool);
    function isCodeHashOfFiltered(address registrant, address operatorWithCode) external returns (bool);
    function isCodeHashFiltered(address registrant, bytes32 codeHash) external returns (bool);
    function filteredOperators(address addr) external returns (address[] memory);
    function filteredCodeHashes(address addr) external returns (bytes32[] memory);
    function filteredOperatorAt(address registrant, uint256 index) external returns (address);
    function filteredCodeHashAt(address registrant, uint256 index) external returns (bytes32);
    function isRegistered(address addr) external returns (bool);
    function codeHashOf(address addr) external returns (bytes32);
}