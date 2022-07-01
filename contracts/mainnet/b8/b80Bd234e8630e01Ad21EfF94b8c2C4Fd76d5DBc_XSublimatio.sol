// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import { ERC721, ERC721Enumerable, Strings } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import { IXSublimatio } from "./interfaces/IXSublimatio.sol";

contract XSublimatio is IXSublimatio, ERC721Enumerable {

    using Strings for uint256;

    // Contains first 21 molecule availabilities (12 bits each).
    uint256 internal COMPACT_STATE_1 = uint256(60087470205620319587750252891185586116542855063423969629534558109603704138);

    // Contains next 42 molecule availabilities (6 bits each).
    uint256 internal COMPACT_STATE_2 = uint256(114873104402099400223353432978706708436353982610412083425164130989245597730);

    // Contains (right to left) 19 drug availabilities (8 bits each), total drugs available (11 bits), total molecules available (13 bits), and nonce (remaining 80 bits).
    uint256 internal COMPACT_STATE_3 = uint256(67212165445492353831982701316699907697777805738906362);

    uint256 public immutable LAUNCH_TIMESTAMP;

    address public owner;
    address public pendingOwner;
    address public proceedsDestination;

    bytes32 public assetGeneratorHash;

    string public baseURI;

    uint256 public pricePerTokenMint;

    mapping(address => bool) internal _canClaimFreeWater;

    constructor (
        string memory baseURI_,
        address owner_,
        uint256 pricePerTokenMint_,
        uint256 launchTimestamp_
    ) ERC721("XSublimatio", "XSUB") {
        baseURI = baseURI_;
        owner = owner_;
        pricePerTokenMint = pricePerTokenMint_;
        LAUNCH_TIMESTAMP = launchTimestamp_;
    }

    modifier onlyAfterLaunch() {
        require(block.timestamp >= LAUNCH_TIMESTAMP, "NOT_LAUNCHED_YET");
        _;
    }

    modifier onlyBeforeLaunch() {
        require(block.timestamp < LAUNCH_TIMESTAMP, "ALREADY_LAUNCHED");
        _;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "UNAUTHORIZED");

        _;
    }

    /***********************/
    /*** Admin Functions ***/
    /***********************/

    function acceptOwnership() external {
        require(pendingOwner == msg.sender, "UNAUTHORIZED");

        emit OwnershipAccepted(owner, msg.sender);
        owner = msg.sender;
        pendingOwner = address(0);
    }

    function proposeOwnership(address newOwner_) external onlyOwner {
        emit OwnershipProposed(owner, pendingOwner = newOwner_);
    }

    function setAssetGeneratorHash(bytes32 assetGeneratorHash_) external onlyOwner {
        require(assetGeneratorHash == bytes32(0) || block.timestamp < LAUNCH_TIMESTAMP, "ALREADY_LAUNCHED");
        emit AssetGeneratorHashSet(assetGeneratorHash = assetGeneratorHash_);
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        emit BaseURISet(baseURI = baseURI_);
    }

    function setPricePerTokenMint(uint256 pricePerTokenMint_) external onlyOwner onlyBeforeLaunch {
        emit PricePerTokenMintSet(pricePerTokenMint = pricePerTokenMint_);
    }

    function setProceedsDestination(address proceedsDestination_) external onlyOwner {
        require(proceedsDestination == address(0) || block.timestamp < LAUNCH_TIMESTAMP, "ALREADY_LAUNCHED");
        emit ProceedsDestinationSet(proceedsDestination = proceedsDestination_);
    }

    function setPromotionAccounts(address[] memory accounts_) external onlyOwner onlyBeforeLaunch {
        for (uint256 i; i < accounts_.length;) {
            address account = accounts_[i];
            _canClaimFreeWater[account] = true;
            emit PromotionAccountSet(account);

            unchecked {
                ++i;
            }
        }
    }

    function unsetPromotionAccounts(address[] memory accounts_) external onlyOwner onlyBeforeLaunch {
        for (uint256 i; i < accounts_.length;) {
            address account = accounts_[i];
            _canClaimFreeWater[account] = false;
            emit PromotionAccountUnset(account);

            unchecked {
                ++i;
            }
        }
    }

    function withdrawProceeds() external {
        uint256 amount = address(this).balance;
        address destination = proceedsDestination;
        destination = destination == address(0) ? owner : destination;

        require(_transferEther(destination, amount), "ETHER_TRANSFER_FAILED");
        emit ProceedsWithdrawn(destination, amount);
    }

    /**************************/
    /*** External Functions ***/
    /**************************/

    function brew(uint256[] calldata molecules_, uint256 drugType_, address destination_) external onlyAfterLaunch returns (uint256 drug_) {
        // Check that drugType_ is valid.
        require(drugType_ < 19, "INVALID_DRUG_TYPE");

        // Cache relevant compact state from storage.
        uint256 compactState3 = COMPACT_STATE_3;

        // Check that drug is available.
        require(_getDrugAvailability(compactState3, drugType_) != 0, "DRUG_NOT_AVAILABLE");

        uint256 specialWater;

        unchecked {
            // The specific special water moleculeType for this drug is 44 more than the drugType.
            specialWater = drugType_ + 44;
        }

        // Fetch the recipe from the pure function.
        uint8[] memory recipe = getRecipeOfDrug(drugType_);

        uint256 index;

        // For each moleculeType defined by the recipe, check that the provided moleculeType at that index is as expected, or the special water.
        while (index < recipe.length) {
            uint256 molecule = molecules_[index];

            // Check that the caller owns the token.
            require(ownerOf(molecule) == msg.sender, "NOT_OWNER");

            // Extract molecule type from token id.
            uint256 moleculeType = molecule >> 93;

            // Check that the molecule type matches what the recipe calls for, or the molecule is the special water.
            require(moleculeType == specialWater || recipe[index] == moleculeType, "INVALID_MOLECULE");

            unchecked {
                ++index;
            }
        }

        index = 0;

        address drugAsAddress = address(uint160(drug_ = _generateTokenId(drugType_ + 63, _generatePseudoRandomNumber(_getTokenNonce(compactState3)))));

        // Make the drug itself own all the molecules used.
        while (index < recipe.length) {
            uint256 molecule = molecules_[index];

            // Transfer the molecule.
            _transfer(msg.sender, drugAsAddress, molecule);

            unchecked {
                ++index;
            }
        }

        // Put token type as the leftmost 8 bits in the token id and mint the drug NFT (drugType + 63).
        _mint(destination_, drug_);

        // Decrement it's availability, decrement the total amount of drugs available, and increment the drug nonce, and set storage.
        COMPACT_STATE_3 = _decrementDrugAvailability(compactState3, drugType_);
    }

    function claimWater(address destination_) external returns (uint256 molecule_) {
        // NOTE: no need for the onlyBeforeLaunch modifier since `canClaimFreeWater` already checks the timestamp
        require(canClaimFreeWater(msg.sender), "CANNOT_CLAIM");

        _canClaimFreeWater[msg.sender] = false;

        ( COMPACT_STATE_1, COMPACT_STATE_2, COMPACT_STATE_3, molecule_ ) = _giveMolecule(COMPACT_STATE_1, COMPACT_STATE_2, COMPACT_STATE_3, 0, destination_);
    }

    function decompose(uint256 drug_) external {
        // NOTE: no need for onlyAfterLaunch modifier because drug cannot exist (be brewed) before launch, nor can water be burned before launch.
        // Check that the caller owns the token.
        require(ownerOf(drug_) == msg.sender, "NOT_OWNER");

        uint256 drugType = (drug_ >> 93);

        // Check that the token is a drug.
        require(drugType >= 63 && drugType < 82, "NOT_DRUG");

        unchecked {
            drugType -= 63;
        }

        address drugAsAddress = address(uint160(drug_));
        uint256 moleculeCount = balanceOf(drugAsAddress);

        for (uint256 i = moleculeCount; i > 0;) {
            uint256 molecule = tokenOfOwnerByIndex(drugAsAddress, --i);

            if (i == 0) {
                // Burn the water (which should be the first token).
                _burn(molecule);
                continue;
            }

            // Transfer the molecule to the owner.
            _transfer(drugAsAddress, msg.sender, molecule);
        }

        // Increment the drugs' availability, increment the total amount of drugs available, and set storage.
        COMPACT_STATE_3 = _incrementDrugAvailability(COMPACT_STATE_3, drugType);

        // Burn the drug.
        _burn(drug_);
    }

    function giveWaters(address[] memory destinations_, uint256[] memory amounts_) external onlyOwner onlyBeforeLaunch {
        // Cache relevant compact states from storage.
        uint256 compactState1 = COMPACT_STATE_1;
        uint256 compactState2 = COMPACT_STATE_2;
        uint256 compactState3 = COMPACT_STATE_3;

        for (uint256 i; i < destinations_.length;) {
            for (uint256 j; j < amounts_[i];) {
                ( compactState1, compactState2, compactState3, ) = _giveMolecule(compactState1, compactState2, compactState3, 0, destinations_[i]);

                unchecked {
                    ++j;
                }
            }

            unchecked {
                ++i;
            }
        }

        // Set relevant storage state fromm the cache ones.
        COMPACT_STATE_1 = compactState1;
        COMPACT_STATE_2 = compactState2;
        COMPACT_STATE_3 = compactState3;
    }

    function giveMolecules(address[] memory destinations_, uint256[] memory amounts_) external onlyOwner onlyBeforeLaunch {
        require(block.timestamp < LAUNCH_TIMESTAMP, "ALREADY_LAUNCHED");

        // Cache relevant compact states from storage.
        uint256 compactState1 = COMPACT_STATE_1;
        uint256 compactState2 = COMPACT_STATE_2;
        uint256 compactState3 = COMPACT_STATE_3;

        // Get the number of molecules available from compactState3.
        uint256 availableMoleculeCount = _getMoleculesAvailable(compactState3);

        for (uint256 i; i < destinations_.length;) {
            for (uint256 j; j < amounts_[i];) {
                // Get a pseudo random number.
                uint256 randomNumber = _generatePseudoRandomNumber(_getTokenNonce(compactState3));
                uint256 moleculeType;

                // Provide _drawMolecule with the 3 relevant cached compact states, and a random number between 0 and availableMoleculeCount - 1, inclusively.
                // The result is newly updated cached compact states. Also, availableMoleculeCount is pre-decremented so that each random number is within correct bounds.
                ( compactState1, compactState2, compactState3, moleculeType ) = _drawMolecule(compactState1, compactState2, compactState3, _limitTo(randomNumber, --availableMoleculeCount));

                // Generate a token id from the moleculeType and randomNumber (saving it in the array of token IDs) and mint the molecule NFT.
                _mint(destinations_[i], _generateTokenId(moleculeType, randomNumber));

                unchecked {
                    ++j;
                }
            }

            unchecked {
                ++i;
            }
        }

        // Set relevant storage state fromm the cache ones.
        COMPACT_STATE_1 = compactState1;
        COMPACT_STATE_2 = compactState2;
        COMPACT_STATE_3 = compactState3;
    }

    function purchase(address destination_, uint256 quantity_, uint256 minQuantity_) external payable onlyAfterLaunch returns (uint256[] memory molecules_) {
        // Cache relevant compact states from storage.
        uint256 compactState1 = COMPACT_STATE_1;
        uint256 compactState2 = COMPACT_STATE_2;
        uint256 compactState3 = COMPACT_STATE_3;

        // Get the number of molecules available from compactState3 and determine how many molecules will be purchased in this call.
        uint256 availableMoleculeCount = _getMoleculesAvailable(compactState3);
        uint256 count = availableMoleculeCount >= quantity_ ? quantity_ : availableMoleculeCount;

        // Prevent a purchase fo 0 nfts, as well as a purchase of less nfts than the user expected.
        require(count != 0, "NO_MOLECULES_AVAILABLE");
        require(count >= minQuantity_, "CANNOT_FULLFIL_REQUEST");

        // Compute the price this purchase will cost, since it will be needed later, and count will be decremented in a while-loop.
        uint256 totalCost;
        unchecked {
            totalCost = pricePerTokenMint * count;
        }

        // Require that enough ether was provided,
        require(msg.value >= totalCost, "INCORRECT_VALUE");

        if (msg.value > totalCost) {
            // If extra, require that it is successfully returned to the caller.
            unchecked {
                require(_transferEther(msg.sender, msg.value - totalCost), "TRANSFER_FAILED");
            }
        }

        // Initialize the array of token IDs to a length of the nfts to be purchased.
        molecules_ = new uint256[](count);

        while (count > 0) {
            // Get a pseudo random number.
            uint256 randomNumber = _generatePseudoRandomNumber(_getTokenNonce(compactState3));
            uint256 moleculeType;

            unchecked {
                // Provide _drawMolecule with the 3 relevant cached compact states, and a random number between 0 and availableMoleculeCount - 1, inclusively.
                // The result is newly updated cached compact states. Also, availableMoleculeCount is pre-decremented so that each random number is within correct bounds.
                ( compactState1, compactState2, compactState3, moleculeType ) = _drawMolecule(compactState1, compactState2, compactState3, _limitTo(randomNumber, --availableMoleculeCount));

                // Generate a token id from the moleculeType and randomNumber (saving it in the array of token IDs) and mint the molecule NFT.
                _mint(destination_, molecules_[--count] = _generateTokenId(moleculeType, randomNumber));
            }
        }

        // Set relevant storage state fromm the cache ones.
        COMPACT_STATE_1 = compactState1;
        COMPACT_STATE_2 = compactState2;
        COMPACT_STATE_3 = compactState3;
    }

    /***************/
    /*** Getters ***/
    /***************/

    function availabilities() external view returns (uint256[63] memory moleculesAvailabilities_, uint256[19] memory drugAvailabilities_) {
        moleculesAvailabilities_ = moleculeAvailabilities();
        drugAvailabilities_ = drugAvailabilities();
    }

    function canClaimFreeWater(address account_) public view returns (bool canClaimFreeWater_) {
        return block.timestamp < LAUNCH_TIMESTAMP && _canClaimFreeWater[account_];
    }

    function compactStates() external view returns (uint256 compactState1_, uint256 compactState2_, uint256 compactState3_) {
        return (COMPACT_STATE_1, COMPACT_STATE_2, COMPACT_STATE_3);
    }

    function contractURI() external view returns (string memory contractURI_) {
        return baseURI;
    }

    function drugAvailabilities() public view returns (uint256[19] memory availabilities_) {
        // Cache relevant compact states from storage.
        uint256 compactState3 = COMPACT_STATE_3;

        for (uint256 i; i < 19;) {
            availabilities_[i] = _getDrugAvailability(compactState3, i);

            unchecked {
                ++i;
            }
        }

    }

    function drugsAvailable() external view returns (uint256 drugsAvailable_) {
        drugsAvailable_ = _getDrugsAvailable(COMPACT_STATE_3);
    }

    function getAvailabilityOfDrug(uint256 drugType_) external view returns (uint256 availability_) {
        availability_ = _getDrugAvailability(COMPACT_STATE_3, drugType_);
    }

    function getAvailabilityOfMolecule(uint256 moleculeType_) external view returns (uint256 availability_) {
        availability_ = _getMoleculeAvailability(COMPACT_STATE_1, COMPACT_STATE_2, moleculeType_);
    }

    function getDrugContainingMolecule(uint256 molecule_) external view returns (uint256 drug_) {
        drug_ = uint256(uint160(ownerOf(molecule_)));
    }

    function getMoleculesWithinDrug(uint256 drug_) external view returns (uint256[] memory molecules_) {
        molecules_ = tokensOfOwner(address(uint160(drug_)));
    }

    function getRecipeOfDrug(uint256 drugType_) public pure returns (uint8[] memory recipe_) {
        if (drugType_ <= 7) {
            recipe_ = new uint8[](2);

            recipe_[1] =
                drugType_ == 0 ? 1 :  // Alcohol (Isolated)
                drugType_ == 1 ? 33 : // Chloroquine (Isolated)
                drugType_ == 2 ? 8 :  // Cocaine (Isolated)
                drugType_ == 3 ? 31 : // GHB (Isolated)
                drugType_ == 4 ? 15 : // Ketamine (Isolated)
                drugType_ == 5 ? 32 : // LSD (Isolated)
                drugType_ == 6 ? 2 :  // Methamphetamine (Isolated)
                14;                   // Morphine (Isolated)
        } else if (drugType_ == 16) {
            recipe_ = new uint8[](3);

            // Mate
            recipe_[1] = 3;
            recipe_[2] = 4;
        } else if (drugType_ == 11 || drugType_ == 12) {
            recipe_ = new uint8[](4);

            if (drugType_ == 11) { // Khat
                recipe_[1] = 5;
                recipe_[2] = 6;
                recipe_[3] = 7;
            } else {               // Lactuca Virosa
                recipe_[1] = 19;
                recipe_[2] = 20;
                recipe_[3] = 21;
            }
        } else if (drugType_ == 14 || drugType_ == 15 || drugType_ == 17) {
            recipe_ = new uint8[](5);

            if (drugType_ == 14) {        // Magic Truffle
                recipe_[1] = 25;
                recipe_[2] = 26;
                recipe_[3] = 27;
                recipe_[4] = 28;
            } else if (drugType_ == 15) { // Mandrake
                recipe_[1] = 16;
                recipe_[2] = 17;
                recipe_[3] = 18;
                recipe_[4] = 34;
            } else {                      // Opium
                recipe_[1] = 14;
                recipe_[2] = 22;
                recipe_[3] = 23;
                recipe_[4] = 24;
            }
        } else if (drugType_ == 9 || drugType_ == 10 || drugType_ == 18) {
            recipe_ = new uint8[](6);

            if (drugType_ == 9) {         // Belladonna
                recipe_[1] = 16;
                recipe_[2] = 17;
                recipe_[3] = 18;
                recipe_[4] = 29;
                recipe_[5] = 30;
            } else if (drugType_ == 10) { // Cannabis
                recipe_[1] = 9;
                recipe_[2] = 10;
                recipe_[3] = 11;
                recipe_[4] = 12;
                recipe_[5] = 13;
            } else {                      // Salvia Divinorum
                recipe_[1] = 35;
                recipe_[2] = 36;
                recipe_[3] = 40;
                recipe_[4] = 41;
                recipe_[5] = 42;
            }
        } else if (drugType_ == 8) {
            recipe_ = new uint8[](7);

            // Ayahuasca
            recipe_[1] = 8;
            recipe_[2] = 37;
            recipe_[3] = 38;
            recipe_[4] = 39;
            recipe_[5] = 43;
            recipe_[6] = 44;
        } else if (drugType_ == 13) {
            recipe_ = new uint8[](9);

            // Love Elixir
            recipe_[1] = 9;
            recipe_[2] = 45;
            recipe_[3] = 46;
            recipe_[4] = 47;
            recipe_[5] = 48;
            recipe_[6] = 49;
            recipe_[7] = 50;
            recipe_[8] = 51;
        } else {
            revert("INVALID_RECIPE");
        }

        // All recipes require Water, so recipe_[0] remains 0.
    }

    function moleculesAvailable() external view returns (uint256 moleculesAvailable_) {
        moleculesAvailable_ = _getMoleculesAvailable(COMPACT_STATE_3);
    }

    function moleculeAvailabilities() public view returns (uint256[63] memory availabilities_) {
        // Cache relevant compact states from storage.
        uint256 compactState1 = COMPACT_STATE_1;
        uint256 compactState2 = COMPACT_STATE_2;

        for (uint256 i; i < 63;) {
            availabilities_[i] = _getMoleculeAvailability(compactState1, compactState2, i);

            unchecked {
                ++i;
            }
        }
    }

    function tokensOfOwner(address owner_) public view returns (uint256[] memory tokenIds_) {
        uint256 balance = balanceOf(owner_);

        tokenIds_ = new uint256[](balance);

        for (uint256 i; i < balance;) {
            tokenIds_[i] = tokenOfOwnerByIndex(owner_, i);

            unchecked {
                ++i;
            }
        }
    }

    function tokenURI(uint256 tokenId_) public override view returns (string memory tokenURI_) {
        require(_exists(tokenId_), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURICache = baseURI;

        tokenURI_ = bytes(baseURICache).length > 0 ? string(abi.encodePacked(baseURICache, "/", tokenId_.toString())) : "";
    }

    /**************************/
    /*** Internal Functions ***/
    /**************************/

    function _beforeTokenTransfer(address from_, address to_, uint256 tokenId_) internal override {
        // Can mint before launch, but transfers and burns can only happen after launch.
        require(from_ == address(0) || block.timestamp >= LAUNCH_TIMESTAMP, "NOT_LAUNCHED_YET");
        super._beforeTokenTransfer(from_, to_, tokenId_);
    }

    function _clearBits(uint256 input_, uint256 mask_, uint256 shift_) internal pure returns (uint256 output_) {
        // Clear out bits in input with mask.
        output_ = (input_ & ~(mask_ << shift_));
    }

    function _constrainBits(uint256 input_, uint256 mask_, uint256 shift_, uint256 max_) internal pure returns (uint256 output_) {
        // Clear out bits in input with mask, and replace them with the removed bits constrained to some max.
        output_ = _clearBits(input_, mask_, shift_) | ((((input_ >> shift_) & mask_) % max_) << shift_);
    }

    function _decrementDrugAvailability(uint256 compactState3_, uint256 drugType_) internal pure returns (uint256 newCompactState3_) {
        unchecked {
            // Increment the token nonce, which is located left of 19 8-bit individual drug availabilities, an 11-bit total drug availability, and a 13-bit total molecule availability.
            // Decrement the total drug availability, which is located left of 19 8-bit individual drug availabilities.
            // Decrement the corresponding availability of a specific drug.
            // Clearer: newCompactState3_ = compactState4_
            //            + (1 << (19 * 8 + 11 + 13))
            //            - (1 << (19 * 8))
            //            - (1 << (drugType_ * 8));
            newCompactState3_ = compactState3_ + 95780965595127282823557164963750446178190649605488640 - (1 << (drugType_ * 8));
        }
    }

    function _decrementMoleculeAvailability(
        uint256 compactState1_,
        uint256 compactState2_,
        uint256 compactState3_,
        uint256 moleculeType_
    ) internal pure returns (uint256 newCompactState1_, uint256 newCompactState2_, uint256 newCompactState3_) {
        unchecked {
            // Increment the token nonce, which is located left of 19 8-bit individual drug availabilities, an 11-bit total drug availability, and a 13-bit total molecule availability.
            // Decrement the total molecule availability, which is located left of 19 8-bit individual drug availabilities and an 11-bit total drug availability.
            // Clearer: compactState3_ = compactState3_
            //            + (1 << (19 * 8 + 11 + 13))
            //            - (1 << (19 * 8 + 11));
            compactState3_ = compactState3_ + 95769279291019406424051059718232593712013947676131328;

            // Decrement the corresponding availability of a specific molecule, in a compact state given the molecule type.
            if (moleculeType_ < 21) return (compactState1_ - (1 << (moleculeType_ * 12)), compactState2_, compactState3_);

            return (compactState1_, compactState2_ - (1 << ((moleculeType_ - 21) * 6)), compactState3_);
        }
    }

    function _drawMolecule(
        uint256 compactState1_,
        uint256 compactState2_,
        uint256 compactState3_,
        uint256 randomNumber_
    ) internal pure returns (uint256 newCompactState1_, uint256 newCompactState2_, uint256 newCompactState3_, uint256 moleculeType_) {
        uint256 offset;

        while (moleculeType_ < 63) {
            unchecked {
                // Increment the offset by the availability of the molecule defined by moleculeType, and break if randomNumber is less than it.
                if (randomNumber_ < (offset += _getMoleculeAvailability(compactState1_, compactState2_, moleculeType_))) break;

                // If not (i.e. randomNumber does not corresponding to picking moleculeType), increment the moleculeType and try again.
                ++moleculeType_;
            }
        }

        // Decrement the availability of this molecule, decrement the total amount of available molecules, and increment some molecule nonce.
        // Give this pure function the relevant cached compact states and get back updated compact states.
        ( newCompactState1_, newCompactState2_, newCompactState3_ ) = _decrementMoleculeAvailability(compactState1_, compactState2_, compactState3_, moleculeType_);
    }

    function _generatePseudoRandomNumber(uint256 nonce_) internal view returns (uint256 pseudoRandomNumber_) {
        unchecked {
            pseudoRandomNumber_ = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), msg.sender, nonce_, gasleft())));
        }
    }

    function _generateTokenId(uint256 type_, uint256 pseudoRandomNumber_) internal pure returns (uint256 tokenId_) {
        // In right-most 100 bits, first 7 bits are the type and last 93 bits are from the pseudo random number.
        tokenId_ = (type_ << 93) | (pseudoRandomNumber_ >> 163);

        // From right to left:
        //  - 32 bits are to be used as an unsigned 32-bit (or signed 32-bit) seed.
        //  - 16 bits are to be used as an unsigned 16-bit for brt.
        //  - 16 bits are to be used as an unsigned 16-bit for sat.
        //  - 16 bits are to be used as an unsigned 16-bit for hue.

        if (type_ > 62) {
            tokenId_ = _clearBits(tokenId_, 1, 32 + 16 + 16 + 16);
            tokenId_ = _clearBits(tokenId_, 3, 32 + 16 + 16 + 16 + 1);
        } else {
            //  - 1 bit is to be used for 2 lighting types.
            tokenId_ = _constrainBits(tokenId_, 1, 32 + 16 + 16 + 16, 2);

            //  - 2 bits are to be used for 4 molecule integrity types.
            tokenId_ = _constrainBits(tokenId_, 3, 32 + 16 + 16 + 16 + 1, 4);
        }

        //  - 2 bits are to be used for 3 deformation types.
        tokenId_ = _constrainBits(tokenId_, 3, 32 + 16 + 16 + 16 + 1 + 2, 3);

        //  - 1 bit is to be used for 2 color shift types.
        tokenId_ = _constrainBits(tokenId_, 1, 32 + 16 + 16 + 16 + 1 + 2 + 2, 2);

        //  - 2 bits are to be used for 3 stripe amount types.
        tokenId_ = _constrainBits(tokenId_, 3, 32 + 16 + 16 + 16 + 1 + 2 + 2 + 1, 3);

        //  - 2 bits are to be used for 3 blob types.
        tokenId_ = _constrainBits(tokenId_, 3, 32 + 16 + 16 + 16 + 1 + 2 + 2 + 1 + 2, 3);

        //  - 3 bits are to be used for 6 palette types.
        tokenId_ = _constrainBits(tokenId_, 7, 32 + 16 + 16 + 16 + 1 + 2 + 2 + 1 + 2 + 2, 6);
    }

    function _getDrugAvailability(uint256 compactState3_, uint256 drugType_) internal pure returns (uint256 availability_) {
        unchecked {
            availability_ = (compactState3_ >> (drugType_ * 8)) & 255;
        }
    }

    function _getDrugsAvailable(uint256 compactState3_) internal pure returns (uint256 drugsAvailable_) {
        // Shift out 19 8-bit values (19 drug availabilities) from the right of the compact state, and mask as 11 bits.
        drugsAvailable_ = (compactState3_ >> 152) & 2047;
    }

    function _getMoleculeAvailability(
        uint256 compactState1_,
        uint256 compactState2_,
        uint256 moleculeType_
    ) internal pure returns (uint256 availability_) {
        unchecked {
            if (moleculeType_ < 21) return (compactState1_ >> (moleculeType_ * 12)) & 4095;

            return (compactState2_ >> ((moleculeType_ - 21) * 6)) & 63;
        }
    }

    function _getMoleculesAvailable(uint256 compactState3_) internal pure returns (uint256 moleculesAvailable_) {
        // Shift out 19 8-bit values (19 drug availabilities) and an 11-bit value (total drugs available), and mask as 13 bits.
        moleculesAvailable_ = (compactState3_ >> 163) & 8191;
    }

    function _getTokenNonce(uint256 compactState3_) internal pure returns (uint256 moleculeNonce_) {
        // Shift out 19 8-bit values (19 drug availabilities), an 11-bit value (total drugs available), and a 13-bit value (total molecules available).
        moleculeNonce_ = compactState3_ >> 176;
    }

    function _giveMolecule(
        uint256 compactState1_,
        uint256 compactState2_,
        uint256 compactState3_,
        uint256 moleculeType_,
        address destination_
    ) internal returns (uint256 newCompactState1_, uint256 newCompactState2_, uint256 newCompactState3_, uint256 molecule_) {
        require(_getMoleculeAvailability(compactState1_, compactState2_, moleculeType_) > 0, "NO_AVAILABILITY");

        // Get a pseudo random number.
        uint256 randomNumber = _generatePseudoRandomNumber(_getTokenNonce(compactState3_));

        // Decrement the availability of the molecule, decrement the total amount of available molecules, and increment some molecule nonce.
        // Give this pure function the relevant cached compact states and get back updated compact states.
        // Set relevant storage state fromm the cache ones.
        ( newCompactState1_, newCompactState2_, newCompactState3_ ) = _decrementMoleculeAvailability(compactState1_, compactState2_, compactState3_, moleculeType_);

        // Generate a token id from the moleculeType and randomNumber (saving it in the array of token IDs) and mint the molecule NFT.
        _mint(destination_, molecule_ = _generateTokenId(moleculeType_, randomNumber));
    }

    function _incrementDrugAvailability(uint256 compactState3_, uint256 drugType_) internal pure returns (uint256 newCompactState3_) {
        unchecked {
            // Increment the total drug availability, which is located left of 19 8-bit individual drug availabilities.
            // Increment the corresponding availability of a specific drug.
            // Clearer: newCompactState3_ = compactState3_
            //            + (1 << (19 * 8))
            //            + (1 << (drugType_ * 8));
            newCompactState3_ = compactState3_ + 5708990770823839524233143877797980545530986496 + (1 << (drugType_ * 8));
        }
    }

    function _limitTo(uint256 input_, uint256 max_) internal pure returns (uint256 output_) {
        output_ = 0 == max_ ? 0 : input_ % (max_ + 1);
    }

    function _transferEther(address destination_, uint256 amount_) internal returns (bool success_) {
        ( success_, ) = destination_.call{ value: amount_ }("");
    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import { IERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IXSublimatio is IERC721Enumerable {

    /// @notice Emitted when the base URI is set (or re-set).
    event AirdropSet(address indexed account);

    /// @notice Emitted when the hash of the asset generator is set.
    event AssetGeneratorHashSet(bytes32 indexed assetGeneratorHash);

    /// @notice Emitted when the base URI is set (or re-set).
    event BaseURISet(string baseURI);

    /// @notice Emitted when an account has decomposed of their drugs into its molecules.
    event DrugDecomposed(uint256 indexed drug, uint256[] molecules);

    /// @notice Emitted when an account has accepted ownership.
    event OwnershipAccepted(address indexed previousOwner, address indexed owner);

    /// @notice Emitted when owner proposed an account that can accept ownership.
    event OwnershipProposed(address indexed owner, address indexed pendingOwner);

    /// @notice Emitted when the price per token mint has been decreased.
    event PricePerTokenMintSet(uint256 price);

    /// @notice Emitted when proceeds have been withdrawn to proceeds destination.
    event ProceedsWithdrawn(address indexed destination, uint256 amount);

    /// @notice Emitted when an account is given the right to claim a free water molecule as a promotion.
    event PromotionAccountSet(address indexed account);

    /// @notice Emitted when an account is loses the right to claim a free water molecule as a promotion.
    event PromotionAccountUnset(address indexed account);

    /// @notice Emitted when an account is set as the destination where proceeds will be withdrawn to.
    event ProceedsDestinationSet(address indexed account);

    /*************/
    /*** State ***/
    /*************/

    function LAUNCH_TIMESTAMP() external returns (uint256 launchTimestamp_);

    function assetGeneratorHash() external returns (bytes32 assetGeneratorHash_);

    function baseURI() external returns (string memory baseURI_);

    function canClaimFreeWater(address account_) external returns (bool canClaimFreeWater_);

    function owner() external returns (address owner_);

    function pendingOwner() external returns (address pendingOwner_);

    function proceedsDestination() external returns (address proceedsDestination_);

    function pricePerTokenMint() external returns (uint256 pricePerTokenMint_);

    /***********************/
    /*** Admin Functions ***/
    /***********************/

    function acceptOwnership() external;

    function proposeOwnership(address newOwner_) external;

    function setAssetGeneratorHash(bytes32 assetGeneratorHash_) external;

    function setBaseURI(string calldata baseURI_) external;

    function setPricePerTokenMint(uint256 pricePerTokenMint_) external;

    function setProceedsDestination(address proceedsDestination_) external;

    function setPromotionAccounts(address[] memory accounts_) external;

    function unsetPromotionAccounts(address[] memory accounts_) external;

    function withdrawProceeds() external;

    /**************************/
    /*** External Functions ***/
    /**************************/

    function brew(uint256[] calldata molecules_, uint256 drugType_, address destination_) external returns (uint256 drug_);

    function claimWater(address destination_) external returns (uint256 molecule_);

    function decompose(uint256 drug_) external;

    function giveWaters(address[] memory destinations_, uint256[] memory amounts_) external;

    function giveMolecules(address[] memory destinations_, uint256[] memory amounts_) external;

    function purchase(address destination_, uint256 quantity_, uint256 minQuantity_) external payable returns (uint256[] memory molecules_);

    /***************/
    /*** Getters ***/
    /***************/

    function availabilities() external view returns (uint256[63] memory moleculesAvailabilities_, uint256[19] memory drugAvailabilities_);

    function compactStates() external view returns (uint256 compactState1_, uint256 compactState2_, uint256 compactState3_);

    function contractURI() external view returns (string memory contractURI_);

    function drugAvailabilities() external view returns (uint256[19] memory availabilities_);

    function drugsAvailable() external view returns (uint256 drugsAvailable_);

    function getAvailabilityOfDrug(uint256 drugType_) external view returns (uint256 availability_);

    function getAvailabilityOfMolecule(uint256 moleculeType_) external view returns (uint256 availability_);

    function getDrugContainingMolecule(uint256 molecule_) external view returns (uint256 drug_);

    function getMoleculesWithinDrug(uint256 drug_) external view returns (uint256[] memory molecules_);

    function getRecipeOfDrug(uint256 drugType_) external pure returns (uint8[] memory recipe_);

    function moleculesAvailable() external view returns (uint256 moleculesAvailable_);

    function moleculeAvailabilities() external view returns (uint256[63] memory availabilities_);

    function tokensOfOwner(address owner_) external view returns (uint256[] memory tokenIds_);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
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
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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