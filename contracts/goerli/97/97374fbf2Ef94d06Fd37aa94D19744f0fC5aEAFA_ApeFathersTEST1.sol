// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;
import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

     ////NFT OWNER AGREEMENT

// This “Owner Agreement” is between and by GSKNNFT Inc. (“Licensor”) and the individual or entity that owns a Digital Asset (as defined below) (the “Owner”), and is effective as of the date ownership of the Digital Asset is transferred to the Owner (the “Effective Date”).
// The Licensor shall retain all right, including personal and commercial Intellectual Property rights, where not expressly granted herewithin, title, and interest in and to the following;
    // (i) GSKNNFT Inc. and all associated Digital Assets, including any Digital Objects directly associated with the Main Asset.
    // (ii) The ApeFathers NFT Brand and any associated documentation, codebase, materials, products, events, contracts, agreements, smart contracts, Digital Asset(s), blockchain technology, or any and all products, services and associated items or methods created by, and released by GSKNNFT Inc. 
    // (iii) "GSKNNFT BURNTOMINT ERC721A Contract" and any associated documentation, materials, codebase, contracts, smart contract, 

// OWNER ACKNOWLEDGES RECEIPT AND UNDERSTANDING OF THIS OWNER AGREEMENT, AND AGREES TO BE BOUND BY ITS TERMS.
// OWNER’S ACCEPTANCE OF A DIGITAL ASSET SHALL BE DEEMED ACCEPTANCE OF THESE TERMS AND CONSENT TO BE GOVERNED THEREBY.
// IF THE OWNER DOES NOT AGREE TO BE BOUND BY THESE TERMS, THIS LICENSE AUTOMATICALLY TERMINATES.

// In consideration of the premises and the mutual covenants set forth herein and for other good and valuable consideration, the receipt and sufficiency of which is hereby acknowledged, and intending to be bound hereby, the parties agree as follows:

// 1. LICENSES & RESTRICTIONS.
    // 1.1 NFT. These “NFTs” are defined as non-fungible tokens.
    // Ownership of which this specific collection is registered on the ethereum blockchain as;
        // Name: “The ApeFathers NFT” (the “Business”) - the NFT "project" operations, employees, agents, representatives and subcontractors,
        // Token Tracker: “DAPES” (the “Token”) - the tracker ID for the Digital Assets on the ethereum blockchain,
        // Contract: “ApeFathers.sol” (the “NFT Contract”) - this specific contract deployed on the ethereum blockchain,
        // Artist: "Tahliazr" (the "Artist") - designed and created the traits conceptualized by GSKNNFT Inc., and furthermore signed the contract ("NFT Licensing Agreement") to transfer the Licenses of the traits created by their ("The Artist's") own hand,
        // Artist Contract: ("NFT Licensing Agreement") - Contract for the transfer of original Intellectual Property of the individual trait images created by The Artist and formally signed by both parties (The Artist and GSKNNFT Inc.),
        // Created by: (“Licensor”) - Gordon Skinner of GSKNNFT Inc. ("@GSKNNFT", "gsknnft.eth", "[email protected]").

    // For the case of this NFT Owner Agreement; any NFT within The ApeFathers NFT collection sold or otherwise transferred to Owner pursuant to this Agreement shall be a “Digital Asset.”
    // The Digital Asset(s) are associated with digital objects (which may include images and/or other digital works) (“Digital Object(s)”).
    // A copy of this contract can be found within the Digital Asset itself, for review by Owner at any time; and enforceable unless voided by the terms therein.
    // The Licensor guarantees the IP to the Digital Objects that were created for The ApeFathers NFT collection have been agreed upon and signed in a seperate contract ("NFT Licensing Agreement") is owned by and paid in full by GSKNNFT Inc, which includes;
    // The IP Agreement formally signed by both parties ("The Artist") and Licensor, who created the traits for compiling the Digital Object(s) through random generation.
        // A copy of the Artist Contract can be found on the Official The ApeFathers NFT website, which can be referenced and reviewed by Owner and Licensor for review at any time; and enforceable unless voided by the terms therein.
    // As detailed below, the Owner may own a Digital Asset, with a full commercial IP license to the Digital Object(s) subject to the terms and conditions set forth herein.
    // Purchase of the ApeFathers NFT (the “Main Asset”) may entitle the purchaser to be declared the Owner, and to utilize their specific held asset(s) for their own personal use of the Intellectual Property (“IP”) of ONLY the associated media tied to the Digital Asset on the blockchain.
    // For the avoidance of doubt, the term “Digital Asset(s),” as used herein, includes both the Main Asset and any Digital Objects directly associated with the Main Asset.

    // 1.2. Digital Asset(s).
        // The Digital Asset(s) are subject to copyright and other intellectual property protections, which rights are and shall remain owned by solely the Owner of the individual NFT(s).

    // 1.3. Licenses.
        // Main Asset.
            // Upon a valid transfer of Main Asset to Owner, Licensor hereby grants Owner a limited, transferable, non-sublicensable, royalty free license to use, publish and display the Digital Object(s) associated with the Main Asset during the Term, subject to Owner’s compliance with the terms and conditions set forth herein, including without limitation, any restrictions in Section 1.4 below, solely for the following purposes: 
                // (a) for their own personal, or commercial use; or 
                // (ii) to display the Main Asset for resale.
        // Upon expiration of the Term or breach of any conditions of this Owner Agreement by Owner, all license rights shall immediately terminate.

    // 1.4. License Restrictions.
        // The Digital Asset(s) provided pursuant to this Owner Agreement are licensed, not sold, and Owner receives title to or ownership of the Digital Asset(s) or the intellectual property rights therein.
        // Except for the license expressly set forth herein, no other rights (express or implied) to the Digital Assets(s) are granted. Licensor reserves all rights not expressly granted.
        // Subject to the terms and conditions of this Agreement, the Licensor grants the User a non-exclusive, non-transferable license to use the full Commercial IP solely for the purpose of utilizing the Main Asset and any associated Digital Objects held by the Owner on the blockchain.
        // Without limiting the generality of the foregoing, Owner shall have the license through this agreement to: 
            // (a) copy, modify, or distribute the Digital Asset(s);
            // (b) use the Digital Asset(s) to advertise, market or sell a product and/or service;
            // (c) incorporate the Digital Asset(s) in videos or other media; or
            // (d) sell merchandise incorporating the Digital Asset(s).
        // Upon a permitted transfer of ownership of the Digital Asset(s) by Owner to a third party, the license to the Digital Assets(s) associated therewith shall be transferable solely subject to the terms and conditions set forth herein, including those in Section 6.3, and the Owner’s license to such Digital Assets(s) terminates immediately upon transfer to such third party.
        // Upon transfer of the NFT to a new owner, all ownership and rights to the underlying IP associated with the NFT are also transferred to the new owner, and for the sake of this agreement, the transfer date will be considered the "Effective Date" of the individul, now representative as the "Owner", and subject to any limitations or restrictions explicitly stated in this agreement.
        // Upon a non-permitted transfer of ownership of the Digital Asset(s) by Owner to a third party, the Owner’s license to the Digital Assets(s) associated therewith terminates immediately, and any purported transfer of the license to such Digital Assets(s) to such third party shall be void.
        //  Owner shall not, and shall not permit any third party to, do any of the following:
            // (a) Use the Digital Asset in connection with any illegal activity or for any unlawful purpose;
            // (b) use or publish any modification of the Digital Asset(s) in any way that would be immoral or goes against the standards of practice set out by “The ApeFathers NFT”, and/or GSKNNFT Inc, including without limitation, any link or other reference to license information.
            // (c) Use the Digital Asset in a manner that infringes the rights of any third party, including but not limited to intellectual property rights;
            // (d) Remove or alter any trademark, logo, copyright, other legal notices or proprietary notices, metadata legends, symbols, or labels associated with, in or on the Digital Asset(s) or Digital Object(s);
            // (e) Transfer the Digital Asset in violation of any applicable law, including without limitation the securities laws of any jurisdiction;
            // (f) Use the Digital Asset to compete with Licensor or the Business in any way.
        // Failure to comply with the conditions set forth in Sections 1.3 and 1.4 constitutes a material breach.

// 2. IP Rights in the Digital Asset.
    // Except as expressly set forth herein, Owner retains all right, title, and interest in and to any claim to, or use of the commercial intellectual property rights in the Digital Asset(s).
        // The Owner shall not, and shall not permit the use of a third party to;
            // reproduce, distribute, display, or create derivative works based on the IP without the prior written consent of the Owner.
        // Any and all full Intellectual Property rights of the material stated in this contract, belong to the User subject to the terms and conditions, excluding where otherwise stated or provided by the Owner ("GSKNNFT Inc."), will maintain validity as any and all explicitly named here, including;
            // through any future Owner-invoked evolutions (changes as per the Owner's own decision with the proof of such logged as a transaction on the Ethereum blockchain), specifically and exclusively offered by the Owner ("GSKNNFT Inc.") through any mechanism, platform, tool, or method used.
// 3. Replica(s).
    // The Owner understands and agrees that Licensor has no control over, and shall have no liability for, any Replicas.
    // Owner understands and agrees that the Platforms and/or any Replica(s) may be unavailable or cease to exist at any time.

// 4. Disclaimer.
    // LICENSOR MAKES NO WARRANTIES, EITHER EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION ANY IMPLIED WARRANTY OF NONINFRINGEMENT.
    // OWNER ACKNOWLEDGES AND AGREES THAT THE DIGITAL ASSET IS PROVIDED “AS IS” AND WITHOUT WARRANTY OF ANY KIND, WHETHER EXPRESS, IMPLIED, OR STATUTORY, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, TITLE, AND NON-INFRINGEMENT.
    // Owner agrees not to use the Permissable Work, Digital Asset(s) or Digital Object(s) to commit any criminal offense, nor to distribute any malicious, harmful, offensive or obscene material.
    // Owner understands and accepts the risks of blockchain technology.
    // Without limiting the generality of the foregoing, Licensor does not warrant that the Digital Asset(s) will perform without error.
    // Further, Licensor provides no warranty regarding, and will have no responsibility for, any claim arising out of:
        // (i) a modification of the Digital Asset(s) made by anyone other than Licensor and/or Owner, unless Licensor or Owner approves such modification in writing;
        // (ii) Owner’s misuse of or misrepresentation regarding the Digital Asset(s); or 
        // (iii) any technology, including without limitation, any Replica or Platform, that fails to perform or ceases to exist.
    // Licensor shall not be obligated to provide any support to Owner or any subsequent owner of the Digital Asset(s).

// 5. LIMITATION OF LIABILITY; INDEMNITY.
    // 5.1. Dollar Cap.
        // LICENSOR’S CUMULATIVE LIABILITY FOR ALL CLAIMS ARISING OUT OF OR RELATED TO THIS OWNER AGREEMENT WILL NOT EXCEED THE AMOUNT OWNER(S) PAID THE LICENSOR FOR DIGITAL ASSET(S).
    // 5.2. Excluded Damages. 
        // IN NO EVENT WILL LICENSOR BE LIABLE FOR LOST PROFITS OR LOSS OF BUSINESS OR FOR ANY CONSEQUENTIAL, INDIRECT, SPECIAL, INCIDENTAL, OR PUNITIVE DAMAGES ARISING OUT OF OR RELATED TO THIS OWNER AGREEMENT.
    // 5.3. Clarifications & Disclaimers.
        // THE LIABILITIES LIMITED BY THIS SECTION 4 APPLY:
            // (a) TO LIABILITY FOR NEGLIGENCE;
            // (b) REGARDLESS OF THE FORM OF ACTION, WHETHER IN CONTRACT, TORT, STRICT PRODUCT LIABILITY, OR OTHERWISE;
            // (c) EVEN IF LICENSOR IS ADVISED IN ADVANCE OF THE POSSIBILITY OF THE DAMAGES IN QUESTION AND EVEN IF SUCH DAMAGES WERE FORESEEABLE; AND
            // (d) EVEN IF OWNER’S REMEDIES FAIL OF THEIR ESSENTIAL PURPOSE.
        // If applicable law limits the application of the provisions of this Section 4, Licensor’s liability will be limited to the maximum extent permissible.
            // OWNER DOES NOT REPRESENT OR WARRANT THAT THE DIGITAL ASSET WILL BE SECURE, UNINTERRUPTED, OR ERROR-FREE, OR THAT ANY DEFECTS WILL BE CORRECTED.
            // USER ASSUMES ALL RISKS ASSOCIATED WITH THE USE OF THE DIGITAL ASSET.
            // IN NO EVENT SHALL LICENSOR BE LIABLE TO OWNER OR ANY THIRD PARTY FOR ANY INDIRECT, SPECIAL, INCIDENTAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES OF ANY KIND, INCLUDING BUT NOT LIMITED TO LOST PROFITS, LOST REVENUE, LOST DATA, OR BUSINESS INTERRUPTION, ARISING OUT OF OR IN CONNECTION WITH THIS OWNER AGREEMENT OR THE USE OR INABILITY TO USE THE DIGITAL ASSET, WHETHER BASED ON CONTRACT, TORT, STRICT LIABILITY, OR ANY OTHER THEORY OF LIABILITY, EVEN IF LICENSOR HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
        // For the avoidance of doubt, Licensor’s liability limits and other rights set forth in this Section 4 apply likewise to Licensor’s affiliates, licensors, suppliers, advertisers, agents, sponsors, directors, officers, employees, consultants, and other representatives.
    // 5.4. Indemnity.
        // Owner will indemnify, defend and hold harmless Licensors and its affiliates, and any of their respective officers, directors, employees, representatives, contractors, and agents (“Licensor Indemnitees”) from and against any and all claims, causes of action, liabilities, damages, losses, costs and expenses (including reasonable attorneys' fees and legal costs, which shall be reimbursed as incurred) arising out of, related to, or alleging Owner’s breach of any provision in this agreement, including but not limited to Owner’s failure to comply with the licensing conditions set forth in Section 1.

// 6. Term & Termination.
    // 6.1. Term.
        // This Owner Agreement shall continue until terminated pursuant to Subsection 6.2 or 6.3 below (the “Term”).
    // 6.2. Termination for Transfer.
        // The license granted in Section 1 above applies only to the extent that Owner continues to possess the applicable Digital Asset.
        // If at any time the Owner sells, trades, donates, gives away, transfers, or otherwise disposes of a Digital Asset for any reason, this Owner Agreement, including without limitation, the license rights granted to Owner in Section 1 will immediately terminate, with respect to such Digital Asset, without the requirement of notice, and Owner will have no further rights in or to such Digital Asset or Digital Object(s) associated therewith.
    // 6.3. Termination for Cause.
        // Licensor may terminate this Owner Agreement for Owner’s material breach by written notice specifying in detail the nature of the breach, effective in thirty (30) days unless the Owner first cures such breach, or effective immediately if the breach is not subject to cure.
    // 6.4. Effects of Termination.
        // Upon termination of this Owner Agreement, Owner shall cease all use of the Digital Object(s) and delete, destroy, or return all copies of the Digital Object(s) in its possession or control.
        // Any provision of this Owner Agreement that must survive to fulfill its essential purpose will survive termination or expiration.

// 7. MISCELLANEOUS.
    // 7.1. Independent Contractors.
        // The parties are independent contractors and shall so represent themselves in all regards.
        // Neither party is the agent of the other, and neither may make commitments on the other’s behalf.
    // 7.2. Force Majeure.
        // No delay, failure, or default, other than a failure to pay fees when due, will constitute a breach of this Owner Agreement to the extent caused by acts of;
            // war, terrorism, hurricanes, earthquakes, epidemics, other acts of God or of nature, strikes or other labor disputes, riots or other acts of civil disorder, embargoes, government orders responding to any of the foregoing, or other causes beyond the performing party’s reasonable control.
    // 7.3. Counterparts.
        //  This Agreement may be executed in counterparts, each of which shall be deemed an original, but all of which together shall constitute one and the same instrument.
    // 7.4. Assignment & Successors. 
        // Subject to the transfer restrictions set forth herein, including in Sections 1.4 and this Section 6.3, Owner may transfer ownership of the Digital Asset(s) to a third-party, provided that Owner:
            // (i) has not breached this Owner Agreement prior to the transfer;
            // (ii) notifies such third party that Licensor shall receive a royalty equal of up to 10% of the purchase price for any sale of a Digital Asset by such third-party; and
            // (iii) Owner ensures that such third party is made aware of this Owner Agreement and agrees to be bound by the obligations and restrictions set forth herein.
        // If the third party does not agree to be bound by the obligations and restrictions set forth herein, then the licenses granted herein shall terminate.
        // In no case shall any of the license rights or other rights granted herein be transferrable apart from ownership of the Digital Asset.
        // Except to the extent forbidden in this Section 6.3, this Owner Agreement will be binding upon and inure to the benefit of the parties’ respective successors and assigns.
        // Any purported assignment or transfer in violation of this Section 6.3, including the transfer restriction in Section 1.4, shall be void.
        // Only a single entity may own each entire Digital Asset at any time, with the exclusion of fractionalization ownership, and only the entities previously named shall have a license to the Digital Object(s) associated therewith.
        // Owner may fractionalize the use of Digital Asset, but ownership is never forfeited.        
        // In the case of fractionalized ownership, the owner with the majority fractionalized portions of the Digital Asset(s) retains the Intellectual Property and any rights and limitations as stated by this agreement shall be considered valid and in force.
        // Upon transfer of a Digital Asset from a first user to a second user, the license to the first user for the Digital Object(s) associated with such Digital Asset shall immediately terminate.

    // 7.5. Severability.
        // To the extent permitted by applicable law, the parties hereby waive any provision of law that would render any clause of this Owner Agreement invalid or otherwise unenforceable in any respect.
        // In the event that a provision of this Owner Agreement is held to be invalid or otherwise unenforceable, such provision will be interpreted to fulfill its intended purpose to the maximum extent permitted by applicable law, and the remaining provisions of this Owner Agreement will continue in full force and effect.
    // 7.6. No Waiver.
        // Neither party will be deemed to have waived any of its rights under this Owner Agreement by lapse of time or by any statement or representation other than by an authorized representative in an explicit written waiver.
        // No waiver of a breach of this Owner Agreement will constitute a waiver of any other breach of this Owner Agreement.
    // 7.7. Choice of Law & Jurisdiction:
        // This Owner Agreement is governed by Canadian law, or any federal, provincial, or state law where the Licensor (GSKNNFT INC.) is located and conducts their business in the future, and both parties submit to the exclusive jurisdiction of the provincial and federal courts located in Canada or any federal jurisdiction as per the location of the Licensor, and waive any right to challenge personal jurisdiction or venue.
    // 7.8. Entire Agreement.
        // This Owner Agreement sets forth the entire agreement of the parties and supersedes all prior or contemporaneous writings, negotiations, and discussions with respect to its subject matter, exclusive of the NFT Licensing Agreement as stated herewithin..
        // Neither party has relied upon any such prior or contemporaneous communications, exclusive of the NFT Licensing Agreement as stated herewithin.
    // 7.9. Amendment.
        // This Owner Agreement may not be amended in any way except through a written agreement by authorized representatives of the Licensor and the current owner of the Digital Asset(s).

    // Disclaimer:
        //  ApeFathers NFT is not an investment business.
        //  GSKNNFT Inc. and The ApeFathers NFT brand offer a gamified NFT ecosystem, membership access to a community, IRL collaborations and opportunities for potential not yet actualized.
        //  All elements of the Digital Asset(s) are subject to change without notice.
        //  Any future token (on-chain or off-chain) that is released from or utilized by The ApeFathers NFT or GSKNNFT Inc. should only be used within the network of projects of which GSKNNFT Inc. and The ApeFathers NFT brand has permitted through writing.


    /**
    * @author gsknnft.eth
    * @notice This smart contract handles burning "The ApeDads(DAPES)" tokens for a free mint of The ApeFathers token, and includes a paid for The ApeFathers NFT tokens.
    */
    contract ApeFathersTEST1 is ERC721A, ERC721AQueryable, Ownable, Pausable, ReentrancyGuard, ERC2981 {
            using SafeMath for uint256;

        address public royaltyAddress = 0xa8750034896B0747b290f98439B6f5969070084A;
        address[] public payoutAddresses = [
            0xa8750034896B0747b290f98439B6f5969070084A,
            0x1FA95261FA842bC9c6AB4C0e925daee53feFE430
        ];
        address public constant burnAddress = 0x0000000000000000000000000000000000000000;
        ERC721A public burnClaimAddress = ERC721A(address(0x7d83f206DE2E16564e5EFD4332a755c9F4615AC1));
        
        uint256 maxGasIncrease = 10000; // this is the cap that can be set
        uint256 gasIncrement = 1000;// you can initialize the gasIncrement with a default value in wei
        uint256 gasUsed = gasleft(); 
        uint256 gas = 6000000;
        uint256 batchSize = 10;
        // If true tokens can be burned in order to mint
        bool public isBurnClaimActive = false;
        bool public isPublicSaleActive = false;
        // Permanently freezes metadata so it can never be changed
        bool public metadataFrozen = false;
        // If true, payout addresses and basis points are permanently frozen and can never be updated
        bool public payoutAddressesFrozen = true;
        string public baseTokenURI =
            "ipfs://bafybeigqicwgfc2lyro3gkvv6wj6it5epm7kcnlnbnxh4apflwmvnscmwe/";
        // Maximum supply of tokens that can be minted
        uint256 public MAX_SUPPLY = 4000;
        uint256 public publicPrice = 0.08 ether;
        uint256 public MintsAllowedPerTx = 10;
        uint256 public MintsAllowedPerClaim = 10;   
        // The respective share of funds to be sent to each address in payoutAddresses in basis points
        uint256[] public payoutBasisPoints = [8500, 1500];
        uint96 public royaltyFee = 1000;


        constructor() ERC721A("The ApeFathers NFT", "DAPES") {
            _setDefaultRoyalty(royaltyAddress, royaltyFee);
            require(
                payoutAddresses.length == payoutBasisPoints.length,
                "PAYOUT_ADDRESSES_AND_PAYOUT_BASIS_POINTS_MUST_BE_SAME_LENGTH"
            );
            uint256 totalPayoutBasisPoints = 0;
            for (uint256 i = 0; i < payoutBasisPoints.length; i++) {
                totalPayoutBasisPoints += payoutBasisPoints[i];
            }
            require(
                totalPayoutBasisPoints == 10000,
                "TOTAL_PAYOUT_BASIS_POINTS_MUST_BE_10000"
            );
        }

        modifier originalUser() {
            require(tx.origin == msg.sender, "CANNOT_CALL_FROM_CONTRACT");
            _;
        }
        /**
        * @dev Overrides the default ERC721A _startTokenId() so tokens begin at 1 instead of 0
        */
        function _startTokenId() internal view virtual override returns (uint256) {
            return 1;
        }
        /**
        * @dev Used to directly approve a token for transfers by the current msg.sender
        */
        function _directApproveMsgSenderFor(uint256 tokenId) internal {
            assembly {
                mstore(0x00, tokenId)
                mstore(0x20, 6) // '_tokenApprovals' is at slot 6.
                sstore(keccak256(0x00, 0x40), caller())
            }
        }
        // https://chiru-labs.github.io/ERC721A/#/migration?id=supportsinterface 
        function supportsInterface(bytes4 interfaceId)
            public
            view
            virtual
            override(ERC2981, ERC721A, IERC721A)
            returns (bool)
        {
            // Supports the following interfaceIds:
            // - IERC165: 0x01ffc9a7
            // - IERC721: 0x80ac58cd
            // - IERC721Metadata: 0x5b5e139f
            // - IERC2981: 0x2a55205a
            return
                ERC721A.supportsInterface(interfaceId) ||
                ERC2981.supportsInterface(interfaceId);
        }
    function _baseURI() internal view virtual override returns (string memory) {
            return baseTokenURI;
        }

        /**
        * @notice Change the royalty fee for the collection
        */
        function setRoyaltyFee(uint96 _feeNumerator) external onlyOwner {
            royaltyFee = _feeNumerator;
            _setDefaultRoyalty(royaltyAddress, royaltyFee);
        }

        /**
        * @notice Change the royalty address where royalty payouts are sent
        */
        function setRoyaltyAddress(address _royaltyAddress) external onlyOwner {
            royaltyAddress = _royaltyAddress;
            _setDefaultRoyalty(royaltyAddress, royaltyFee);
        }

        /**
        * @notice Wraps and exposes publicly _numberMinted() from ERC721A
        */
        function numberMinted(address owner) public view returns (uint256) {
            return _numberMinted(owner);
        }

        /**
        * @notice Update the base token URI
        */
        function setBaseURI(string calldata _newBaseURI) external onlyOwner {
            require(!metadataFrozen, "METADATA_HAS_BEEN_FROZEN");
            baseTokenURI = _newBaseURI;
        }

        /**
        * @notice Allow owner to send gifts to multiple addresses
        */
        function gift(address[] calldata receivers, uint256[] calldata mintNumber)
            external
            onlyOwner
        {
            require(
                receivers.length == mintNumber.length,
                "RECEIVERS_AND_MINT_NUMBERS_MUST_BE_SAME_LENGTH"
            );
            uint256 totalMint = 0;
            for (uint256 i = 0; i < mintNumber.length; i++) {
                totalMint += mintNumber[i];
            }
            require(totalSupply() + totalMint <= 4000, "MINT_TOO_LARGE");
            for (uint256 i = 0; i < receivers.length; i++) {
                _safeMint(receivers[i], mintNumber[i]);
            }
        }
        /**
        * @notice Update the public mint price
        */
        function setPublicPrice(uint256 _publicPrice) external onlyOwner {
            publicPrice = _publicPrice;
        }

        /**
        * @notice Set the maximum public mints allowed per a given transaction
        */
        function setMintsAllowedPerTx(uint256 _mintsAllowed)
            external
            onlyOwner
        {
            MintsAllowedPerTx = _mintsAllowed;
        }
        /**
        * @notice To be updated by contract owner to allow public sale minting
        */
        function setPublicSaleState(bool _saleActiveState) external onlyOwner {
            require(
                isPublicSaleActive != _saleActiveState,
                "NEW_STATE_IDENTICAL_TO_OLD_STATE"
            );
            isPublicSaleActive = _saleActiveState;
        }
        /**
        * @notice To be updated by contract owner to allow burning to claim a token for free + gas
        */
        function setBurnClaimState(bool _burnClaimActive) external onlyOwner {
            require(
                isBurnClaimActive != _burnClaimActive,
                "NEW_STATE_IDENTICAL_TO_OLD_STATE"
            );
        isBurnClaimActive = _burnClaimActive;
        }
        /**
        * @notice Allow for public minting of tokens
        */
        function mint(uint256 numTokens)
            external
            payable
            nonReentrant
            originalUser
        {
            require(isPublicSaleActive, "PUBLIC__NOT_ACTIVE");

            require(
                numTokens <= MintsAllowedPerTx,
                "MAX_MINTS_PER_TX_EXCEEDED"
            );
            require(totalSupply() + numTokens <= MAX_SUPPLY, "MAX_SUPPLY_EXCEEDED");
            require(msg.value == publicPrice * numTokens, "PAYMENT_INCORRECT");

            _safeMint(msg.sender, numTokens);

            if (totalSupply() >= MAX_SUPPLY) {
                isPublicSaleActive = false;
            }
        }
        /**
        * @notice Withdraws all funds held within contract
        */
        function withdraw() external nonReentrant onlyOwner {
            require(address(this).balance > 0, "NO_BALANCE");
            uint256 balance = address(this).balance;
            for (uint256 i = 0; i < payoutAddresses.length; i++) {
                require(
                    payable(payoutAddresses[i]).send(
                        (balance * payoutBasisPoints[i]) / 10000
                    )
                );
            }
        }
    /**
        * @dev to set the gas limit (in wei) of a given function, and to modify the variable as needed
        */
    function gascap() private {
        gas = gas + maxGasIncrease;
    }
    function setGas(uint256 _gas) external onlyOwner {
        gas = _gas;
    }
    /**
    * @dev to set the gas increments (in wei) of a given function, and to modify the variable as needed
    */
    function setGasIncrement(uint256 _gasIncrement) external onlyOwner {
        gasIncrement = _gasIncrement;
    }

    // @notice DYNAMIC gas increaser - incrementally
    event GasLimitIncreasedDynamically(uint256 gasIncrease);

    /**
    * @dev to set the gas limit (in wei) of a given function, and to modify the variable as needed
    */
    function setGasLimitAndCheck(uint256 _gasInGwei) external onlyOwner {
        uint256 gasInWei = _gasInGwei * 1e9;
        gas = gasInWei;
        checkGas();
    }

    function checkGas() private {
        uint256 gasIncrease = gasleft() - gas;
        if (gasIncrease <= maxGasIncrease) {
            return;
        }
        uint256 lastGasUsed = gasUsed - gasleft();
        uint256 increment = lastGasUsed * 3 / 10; // increase gas limit by 30% of the gas used in the last function
        increment = (increment + gasIncrement - 1) / gasIncrement * gasIncrement; // round up to the nearest gas increment
        gas += increment;
        gascap();
        emit GasLimitIncreasedDynamically(gasIncrease);
        gasUsed = gasleft();
    }

    /**
    * @notice Sets Approval for All Tokens set for the Contract Address of the token to burn - Full legal Copyright and ownership of the code function below as is, belongs to and was written by Gordon Skinner (@gsknnft) of GSKNNFT Inc.
    */
    event ApprovalComplete(address indexed _sender, uint256[] _tokenIds);

    // Build the TokenApproval struct 
    struct TokenApproval {
        uint256 tokenId;
        mapping(address => bool) approvals;
    }
    
    mapping(uint256 => TokenApproval) public tokenApprovals;

    ERC721A ExternalERC721BurnContract = ERC721A(burnClaimAddress);
    // Approve the tokenIds from the contract deployed as "ExternalERC721BurnContract" (ApeDads.sol) to approved by msg.sender to transfer
    function setApproval(uint256[] memory _tokenIds) public {
        require(_tokenIds.length > 0, "ERROR: INVALID NUMBER OF TOKENS");

        for (uint256 i = 0; i < _tokenIds.length; ++i) {
            uint256 tokenId = _tokenIds[i];
            require(ExternalERC721BurnContract.ownerOf(tokenId) == msg.sender, "ERROR: SENDER IS NOT OWNER OF TOKEN");
            // Set the approval for the msg.sender for this tokenId
            tokenApprovals[tokenId].approvals[msg.sender] = true;
            assert(ExternalERC721BurnContract.isApprovedForAll(msg.sender, address(this)));
        }
        emit ApprovalComplete(msg.sender, _tokenIds);
    }
      
        function setBatchSize(uint256 _batchSize) external onlyOwner {
            require(_batchSize > 0, "Batch size must be greater than zero");
        batchSize = _batchSize;
    }

    function batchTransfer(uint256[] memory _tokenIds, address _to) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            transferFrom(msg.sender, _to, _tokenIds[i]);
        }
    }

    function burnClaim(uint256[] memory _tokenIds) external {
        assert(address(ExternalERC721BurnContract) != address(0));
        require(isBurnClaimActive, "ERROR: BURN CLAIM IS NOT ACTIVE");
        uint256 numberOfTokens = _tokenIds.length;
        require(numberOfTokens > 0, "ERROR: INVALID NUMBER OF TOKENS");

        // Check if the user has confirmed the transfer of ownership
        bool confirmed = false;
        if (!confirmed) {
            uint256[] memory approvedTokenIds = new uint256[](numberOfTokens);
            for (uint256 i = 0; i < numberOfTokens; ++i) {
                uint256 tokenId = _tokenIds[i];
                require(tokenApprovals[tokenId].approvals[msg.sender], "ERROR: TOKEN NOT APPROVED");
                approvedTokenIds[i] = tokenId;
            }
            setApproval(approvedTokenIds);
            require(isApprovedForAll(msg.sender, msg.sender), "You not approved to transfer the token");
        }
        checkGas();
        // Batch the tokenIds from the contract deployed as "ExternalERC721BurnContract" (ApeDads.sol) to burn the tokens owned and now approved by msg.sender to burn - (THIS IS IRREVERSABLE)
        require(gasUsed < gas, "ERROR: GAS LIMIT EXCEEDED");
        uint256 numBatches = (numberOfTokens + batchSize - 1) / batchSize; // round up
        uint256[] memory batchIds = new uint256[](batchSize);
        uint256 j = 0;
        for (uint256 b = 0; b < numBatches; ++b) {
            uint256 start = b * batchSize;
            uint256 end = start + batchSize;
            if (end > numberOfTokens) {
                end = numberOfTokens;
            }
            for (uint256 i = start; i < end; ++i) {
                batchIds[j] = _tokenIds[i];
                j++;
                if (j == batchSize) {
                    batchTransfer(batchIds, burnAddress);
                    j = 0;
                }
            }
        }
        if (j > 0) {
            uint256[] memory remainingIds = new uint256[](j);
            for (uint256 i = 0; i < j; i++) {
                remainingIds[i] = batchIds[i];
            }
            batchTransfer(remainingIds, burnAddress);
        }
        checkGas();
        require(gasUsed < gas, "ERROR: GAS LIMIT EXCEEDED");
        emit ApprovalComplete(msg.sender, _tokenIds);
        // Mint a new Token from this contract "ApeFathers"
        super._safeMint(msg.sender, numberOfTokens);
    }
}

////__ERC721A Contract - GSKNNFT Inc. BURNTOMINT USE OF RIGHTS AGREEMENT__

    // This “USE OF RIGHTS AGREEMENT” is between and by GSKNNFT Inc. ("Owner") and the individual or entity (as defined below) (the "User"),that uses the contract in any form, fashion, manner, including modifying any code, or using any of the code below wihin the contract without explicit written approval by GSKNNFT Inc.
    // The "GSKNNFT Inc. BURNTOMINT ERC721A Contract - USE OF RIGHTS AGREEMENT" ("GSKNNFT Inc. BURNTOMINT Use Of Rights Agreement") is effective as of the first instance of use (the “Effective Date”) of which the User initiated any transaction or use of the code provided below of this specific contract "BURNTOMINTNFT ERC721A Contract" (the "BurnMintContract").
    // The contract does not require any transfer, event, or action to be successfully completed in order to prove it's existance and legitimacy.

    // OWNER ACKNOWLEDGES RECEIPT AND UNDERSTANDING OF THIS USE OF RIGHTS AGREEMENT, AND AGREES TO BE BOUND BY ITS TERMS.
    // OWNER’S ACCEPTANCE OF THE USE OF THE "GSKNNFT BURNTOMINT ERC721A Contract" SHALL BE DEEMED IN ACCEPTANCE OF THESE TERMS AND CONSENT TO BE GOVERNED THEREBY.
    // IF THE OWNER DOES NOT AGREE TO BE BOUND BY THESE TERMS, THIS LICENSE AUTOMATICALLY TERMINATES.

    // In consideration of the premises and the mutual covenants set forth herein and for other good and valuable consideration, the receipt and sufficiency of which is hereby acknowledged, and intending to be bound hereby, the parties agree as follows:

    // 1. WARRANTIES, REPRESENTATIONS, USAGE & RESTRICTIONS.
        // 1.1 NFT. This "GSKNNFT BURNTOMINT ERC721A Contract" is not an NFT minting contract itself, it interacts with the blockchain to approve and send any contract's token's (as pointed to by this contract) to a burn address in replacement for another contract's mint.
        // The conditions of this ERC721A smart-contract include that the calling smart-contracts must fulfill certain conditions (described below).
        // Any contract that attempts to interact with the "GSKNNFT BURNTOMINT ERC721A Contract" that fails to implement standard ERC721A functions such as "mint", and "safetransferFrom", can not use this contract without consulting GSKNNFT Inc. for additional measures to accomplish the task.
        // "NFTs" are defined as non-fungible tokens, assets that can be minted, owned, and destroyed on the blockchain.
        // Ownership of which this specific contract is registered here on the ethereum blockchain as;
            // Owner: “GSKNNFT Inc.” (the “Business”) - the NFT Project Management/Advisory/Development including any and all operations, employees, agents, representatives and subcontractors,
            // Contract: GSKNNFTBURNTOMINT.sol” (the “Main Asset”) - this specific contract deployed on the ethereum blockchain,
            // Created by: ("Owner") - Gordon Skinner of GSKNNFT Inc. ("@GSKNNFT", "gsknnft.eth", "[email protected]").

    // For the case of this USE OF RIGHTS AGREEMENT; the first instance of any interaction with this "GSKNNFT BURNTOMINT ERC721A Contract" or use of otherwise pursuant to this Agreement shall be considered as (the “Effective Date”), a indicated and described above.
    // Digital Asset(s) are associated with digital objects (which may include images and/or other digital works) (“Digital Object(s)”), together, they makeup the properties of a Non-Fungible Token "NFT".
    // A copy of this contract can be found within the ethereum blockchain, on the "GSKNNFT BURNTOMINT ERC721A Contract" itself, for review by Owner at any time; and enforceable unless voided by the terms therein.
    // The Owner guarantees the IP to the"GSKNNFT BURNTOMINT ERC721A Contract" was developed created and is owned by GSKNNFT Inc.

    // As detailed below, the User may own a Digital Asset, and by their own action on the blockchain, commit to sending their owned Digital Object(s) to a burn address in replacement for any number of tokens to a new contract, subject to the terms and conditions mentioned in this agreement.
    // The Owner understands that, as it could also be deflationary, the tokens may not always be returned in equivalence, should the burn require >= 2 or more tokens, in return for 1 based on the conditions of the project, subject to the terms and conditions set forth herein.
    // Use of the "GSKNNFT BURNTOMINT ERC721A Contract" (the “Main Asset”) entitles the user to be declared as the "User".
    // For the avoidance of doubt, the term “Digital Asset(s),” as used herein, includes both the Main Asset and any Digital Objects directly associated with the Main Asset.
    // For the avoidance of doubt, the term "Main Asset" as used herein, describes the code within the smart contract in this .sol file that is deployed on the ethereum blockchain for use by GSKNNFT Inc. and those permitted use of by the Owner.     
    // For the avoidance of doubt, the term "NFT Asset" as used herein, describes the Digital Media(s) themselves which generally, where applicable, can have the IP rights owned by the "User", or in this instance, the "NFT Owner".
        
    // 1.2  WARRANTIES.
    // OWNER GSKNNFT Inc. warrants and represents that it has the right and authority to enter into this agreement and to grant the licenses and rights granted herein.
    // USER The User warrants and represents that it has the right and authority to enter into this agreement and to perform its obligations hereunder, and that its use of the code and interaction with the "GSKNNFT BURNTOMINT ERC721A Contract" will not violate any applicable laws or regulations, or infringe upon or misappropriate any third-party rights.
    
    // 1.3. Main Asset.
            // The Main Asset is subject to copyright and other intellectual property protections, which rights are and shall remain owned by solely the Owner ("GSKNNFT Inc.", "Gordon Skinner", "@GSKNNFT", "[email protected]").
            // The Owner shall retain all right, title, and interest in and to the "GSKNNFT BURNTOMINT ERC721A Contract" and all associated Digital Assets, including any Digital Objects directly associated with the Main Asset. 
            //  The Owner's rights include all intellectual property rights in the Main Asset and any associated Digital Objects.

    // 1.4. Licenses.
        // Main Asset.
            // Upon a valid transfer any Asset, Owner is hereby the only individual who has the authority to use, or permit the use of;
            // Subject to User's compliance with the terms and conditions set forth herein, including without limitation, any restrictions in Section 1.4 below, solely for the following purposes: 
                // (i) for their own personal, or commercial use; or 
                // (ii) to display the Main Asset for resale.
                // (iii) to modify or otherwise use the code below for the individual's purpose without prior contact with GSKNNFT Inc. (contact information listed above).
            // Upon expiration of the Term or breach of any conditions of this "GSKNNFT Inc. BURNTOMINT Use Of Rights Agreement" by any individual or User, excluding the Owner, all license rights shall immediately terminate.

    // 1.5. Usage Restrictions.
        // The Main Asset(s) provided pursuant to this Owner Agreement is not licensed, nor sold, and Owner receives title to and ownership of the Main Asset(s) including the commercial intellectual property rights therein.
        // Except for the license expressly set forth herein, no other rights (express or implied) to the Main Assets(s) are granted.
        // Owner reserves all rights not expressly granted.
        // Without limiting the generality of the foregoing, Owner shall have the license through this agreement to: 
            // (a) copy, modify, or distribute the Main Asset(s);
            // (b) use the Main Asset(s) to advertise, market or sell a product and/or service;
            // (c) incorporate the Main Asset(s) in videos or other media; or
            // (d) sell merchandise incorporating the Main Asset(s).
        // Upon a permitted transfer of ownership of the Main Asset(s) by Owner to any third party, the license and this agreement herewithin to the Main Assets(s) associated therewith shall be transferable solely subject to the terms and conditions set forth herein, including those in Section 6.3, and the previous Owner’s license to such Main Assets(s) terminates immediately upon transfer of the contract ownership to any such third party. 
        // Upon a non-permitted transfer of ownership of the Main Asset(s) by Owner to any third party, the Owner’s license to the Digital Assets(s) associated therewith terminates immediately, and any purported transfer of the license to such Main Assets(s) to any such third party shall be void.
            // Owner may have the power to:
                // (a) remove any copyright or other legal notices associated with the Main Asset(s);
                // (b) remove or alter any metadata of the Main Asset(s), excluding the embedded functions within the smart-contract of which the Main Asset was intended to perform over it's lifetime; or 
                // (c) use or publish any modification of the Main Asset(s) in any way that would be immoral or goes against the standards of practice set out by GSKNNFT Inc, including without limitation, any link or other reference to license information.
            // Failure to comply with the conditions set forth in Sections 1.3 and 1.4 constitutes a material breach.

    // 2. IP Rights in the Main Asset.
        // Except as expressly set forth herein, Owner retains all right, title, and interest in and to any claim to, or use of the full personal & commercial intellectual property rights in the Main Asset(s), and any future creation by GSKNNFT Inc. as per this contract, unless explicitly stated by GSKNNFT Inc.
        // The Owner shall not use the IP for any purpose other than as expressly permitted in this Agreement.
        // The Owner shall not, and shall not permit the use of a third party to;
            // reproduce, distribute, display, or create derivative works based on the IP without the prior written consent of the Owner.
        // Any and all full Intellectual Property rights of the material stated in this contract, belong to the Owner ("GSKNNFT Inc.") subject to the terms and conditions, excluding where otherwise stated or provided by the Owner ("GSKNNFT Inc."), will maintain validity as any and all explicitly named here, including;
            // through any future Owner-invoked evolutions (changes as per the Owner's own decision with the proof of such logged as a transaction on the Ethereum blockchain), specifically and exclusively offered by the Owner ("GSKNNFT Inc.") through any mechanism, platform, tool, or method used.

    // 3. Replica(s).
        // The User understands and agrees that Owner has no control over, and shall have no liability for, any Replicas.
        // The User understands and agrees that the Platforms and/or any Replica(s) may be unavailable or cease to exist at any time.

    // 4. Disclaimer.
        // Owner MAKES NO WARRANTIES, EITHER EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION ANY IMPLIED WARRANTY OF NONINFRINGEMENT.
        // User agrees not to use this contract to commit any criminal offense, nor to distribute or associate this contract with any malicious, harmful, offensive or obscene material.
        // User understands and accepts the risks of blockchain technology.
        // Without limiting the generality of the foregoing, Owner does not warrant that the "BURNNFTTOMINT" ERC721A Contract will ever perform without error.
        // Further, Owner provides no warranty regarding, and will have no responsibility for, any claim arising out of:
            // (i) a modification of the "BURNNFTTOMINT" ERC721A Contract made by anyone other than Owner, unless Owner approve such modification in writing;
            // (ii) User's misuse of or misrepresentation regarding the "BURNNFTTOMINT" ERC721A Contract; or 
            // (iii) any technology, including without limitation, any Replica or Platform, that fails to perform or ceases to exist.
        // Owner shall not be obligated to provide any support to User, user or any subsequent owner, or user of the "BURNNFTTOMINT" ERC721A Contract.

    // 5. LIMITATION OF LIABILITY; INDEMNITY.
        // 5.1. Dollar Cap.
            // OWNER's CUMULATIVE LIABILITY FOR ALL CLAIMS ARISING OUT OF OR RELATED TO THIS AGREEMENT WILL NOT EXCEED THE AMOUNT USER(S) PAID THE OWNER FOR USE OF THE MAIN ASSET(S).
        // 5.2. THE AGGREGATE LIABILITY OF EITHER PARTY TO THE OTHER PARTY FOR ALL CLAIMS ARISING OUT OF OR RELATED TO THIS AGREEMENT, WHETHER IN CONTRACT, TORT OR OTHERWISE, SHALL NOT EXCEED THE AMOUNT PAID BY USER TO GSKNNFT INC. DURING THE SIX MONTH PERIOD PRECEDING THE EVENT GIVING RISE TO THE CLAIM.
        // 5.3. Excluded Damages. 
            // IN NO EVENT WILL OWNER BE LIABLE FOR LOST PROFITS OR LOSS OF BUSINESS OR FOR ANY CONSEQUENTIAL, INDIRECT, SPECIAL, INCIDENTAL, OR PUNITIVE DAMAGES ARISING OUT OF OR RELATED TO THIS AGREEMENT.
        // 5.4. Clarifications & Disclaimers.
            // THE LIABILITIES LIMITED BY THIS SECTION 4 APPLY:
                // (a) TO LIABILITY FOR NEGLIGENCE;
                // (b) REGARDLESS OF THE FORM OF ACTION, WHETHER IN CONTRACT, TORT, STRICT PRODUCT LIABILITY, OR OTHERWISE;
                // (c) EVEN IF USER IS ADVISED IN ADVANCE OF THE POSSIBILITY OF THE DAMAGES IN QUESTION AND EVEN IF SUCH DAMAGES WERE FORESEEABLE; AND
                // (d) EVEN IF OWNER'S REMEDIES FAIL OF THEIR ESSENTIAL PURPOSE.
            // If applicable law limits the application of the provisions of this Section 4, Owner's liability will be limited to the maximum extent permissible.
            // USER ACKNOWLEDGES AND AGREES THAT THE DIGITAL ASSET IS PROVIDED “AS IS” AND WITHOUT WARRANTY OF ANY KIND, WHETHER EXPRESS, IMPLIED, OR STATUTORY, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, TITLE, AND NON-INFRINGEMENT.
            // OWNER DOES NOT REPRESENT OR WARRANT THAT THE DIGITAL ASSET WILL BE SECURE, UNINTERRUPTED, OR ERROR-FREE, OR THAT ANY DEFECTS WILL BE CORRECTED.
            // USER ASSUMES ALL RISKS ASSOCIATED WITH THE USE OF THE DIGITAL ASSET.
            // IN NO EVENT SHALL OWNER BE LIABLE TO USER OR ANY THIRD PARTY FOR ANY INDIRECT, SPECIAL, INCIDENTAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES OF ANY KIND, INCLUDING BUT NOT LIMITED TO LOST PROFITS, LOST REVENUE, LOST DATA, OR BUSINESS INTERRUPTION, ARISING OUT OF OR IN CONNECTION WITH THIS OWNER AGREEMENT OR THE USE OR INABILITY TO USE THE DIGITAL ASSET, WHETHER BASED ON CONTRACT, TORT, STRICT LIABILITY, OR ANY OTHER THEORY OF LIABILITY, EVEN IF LICENSOR HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
            // For the avoidance of doubt, Owner's liability limits and other rights set forth in this Section 4 apply likewise to Owner's affiliates, Owner's, suppliers, advertisers, agents, sponsors, directors, officers, employees, consultants, and other representatives.
        // 5.5. Indemnity.
            // (a) INDEMNIFICATION BY USER.
                // The User agrees to indemnify, defend, and hold harmless GSKNNFT Inc., and its officers, directors, employees, agents, successors, and assigns from and against any and all claims, damages, liabilities, costs, and expenses (including reasonable attorneys' fees) arising out of or in connection with any breach by the User of any warranty or representation made in this agreement, or any unauthorized use of the code or interaction with the "GSKNNFT BURNTOMINT ERC721A Contract".
                // User will indemnify, defend and hold harmless the Owner and its affiliates, and any of their respective officers, directors, employees, representatives, contractors, and agents (“Owner Indemnitees”) from and against any and all claims, causes of action, liabilities, damages, losses, costs and expenses (including reasonable attorneys' fees and legal costs, which shall be reimbursed as incurred) arising out of, related to, or alleging Owner’s breach of any provision in this agreement, including but not limited to User's own failure to comply with the usage conditions set forth in Section 1.
            //  (b) INDEMNIFICATION BY OWNER.
                //  GSKNNFT Inc. agrees to indemnify, defend, and hold harmless the User, and its officers, directors, employees, agents, successors, and assigns from and against any and all claims, damages, liabilities, costs, and expenses (including reasonable attorneys' fees) arising out of or in connection with any breach by GSKNNFT Inc. of any warranty or representation made in this agreement.
        // 5.6. IN NO EVENT SHALL EITHER PARTY BE LIABLE TO THE OTHER PARTY FOR ANY INDIRECT, INCIDENTAL, CONSEQUENTIAL, SPECIAL OR EXEMPLARY DAMAGES, INCLUDING WITHOUT LIMITATION, LOST PROFITS, LOST BUSINESS OR LOST DATA, ARISING OUT OF OR IN CONNECTION WITH THIS AGREEMENT, WHETHER BASED ON BREACH OF CONTRACT, TORT (INCLUDING NEGLIGENCE), PRODUCT LIABILITY OR OTHERWISE, EVEN IF THE PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

    // 6. Term & Termination.
        // 6.1. Term.
            // This agreement shall commence on the Effective Date and shall continue until terminated as provided herein.
            // This Agreement shall continue until terminated pursuant to Subsection 6.2 or 6.3 below (the “Term”).
        // 6.2. Termination for Transfer.
            // The license granted in Section 1 above applies only to the extent that User continues to use the applicable Main Asset in any fashion.
            // If at any time the User disposes of any Digital Asset(s) through the use of this smart-contract by destroying/burning (disposing) of any Digital Asset(s) by sending them to a zero (0) address on the ethereum blockchain, this specific Agreement, including without limitation, any rights that have been granted to the User with regards to their Digital Asset(s) burned, and the usage of the Main Asset will immediately be enforced by this contract, with respect to use of the Main Asset, without the requirement of notice, and User will have no additional licenses or rights of such Main Asset(s) associated herewith.
        // 6.3. Termination for Cause.
            // Owner may terminate this Agreement for User's material breach by written notice specifying in detail the nature of the breach, effective in thirty (30) days unless the User first cures such breach, or effective immediately if the breach is not subject to cure.
        // 6.4. Effects of Termination.
            // Upon termination of this Agreement, User shall be forced to cease any and all interactions with the Main Asset indefinitely.
            // Any provision of this Agreement that must survive to fulfill its essential purpose will survive termination or expiration.

    // 7. MISCELLANEOUS.
        // 7.1. Independent Contractors.
            // The parties are independent contractors and shall so represent themselves in all regards.
            // Neither party is the agent of the other, and neither may make commitments on the other’s behalf.
        // 7.2. Force Majeure.
            // No delay, failure, or default, other than a failure to pay fees when due, will constitute a breach of this Owner Agreement to the extent caused by acts of;
                // war, terrorism, hurricanes, earthquakes, epidemics, other acts of God or of nature, strikes or other labor disputes, riots or other acts of civil disorder, embargoes, government orders responding to any of the foregoing, or other causes beyond the performing party’s reasonable control.
        // 7.3. Counterparts.
            //  This Agreement may be executed in counterparts, each of which shall be deemed an original, but all of which together shall constitute one and the same instrument.
        // 7.4. Assignment & Successors. 
            // Subject to the transfer restrictions set forth herein, including in Sections 1.4 and this Section 6.3, User may, and will be required through the use of this contract, transfer ownership of any Digital Asset(s) to an ethereum zero (0) ("burn address"), provided that User:
                // (i) has not breached this Agreement prior to the transfer;
                // (ii) Agrees that Owner may receive payment for use of the Main Asset; and
                // (iii) Owner ensures that such third party is made aware of this Usage Agreement and agrees to be bound by the obligations and restrictions set forth herein.
            // If the third party does not agree to be bound by the obligations and restrictions set forth herein, then the licenses granted herein shall terminate.
            // In no case shall any of the license rights or other rights granted herein be transferrable apart from ownership of the Digital Asset.
            // Except to the extent forbidden in this Section 6.3, this Usage Agreement will be binding upon and inure to the benefit of the parties’ respective successors and assigns.
            // Any purported assignment or transfer in violation of this Section 6.3, including the transfer restriction in Section 1.4, shall be void.
            // Only a single entity may own each entire Digital Asset at any time, with the exclusion of fractionalization ownership, and only the entities previously named shall have a license to the Digital Object(s) associated therewith.
            // Upon transfer of a Digital Asset from any User to the ethereum zero ("burn address"), any license provided to the User for the Digital Object(s) associated with such Digital Asset shall be forever and indefinitely theirs, where applicable and granted.
        // 7.5. Severability.
            // To the extent permitted by applicable law, the parties hereby waive any provision of law that would render any clause of this Agreement invalid or otherwise unenforceable in any respect.
            // In the event that a provision of this Agreement is held to be invalid or otherwise unenforceable, such provision will be interpreted to fulfill its intended purpose to the maximum extent permitted by applicable law, and the remaining provisions of this Usage Agreement will continue in full force and effect.
        // 7.6. No Waiver.
            // Neither party will be deemed to have waived any of its rights under this Agreement by lapse of time or by any statement or representation other than by an authorized representative in an explicit written waiver.
            // No waiver of a breach of this Agreement will constitute a waiver of any other breach of this Usage Agreement.
        // 7.7. Choice of Law & Jurisdiction:
            // This Agreement shall be governed by and construed in accordance with the laws of the jurisdiction in which the Owner is incorporated.
            // This Agreement is governed by Canadian law, or any federal, provincial, or state law where the Owner (GSKNNFT INC.) is located and conducts their business in the future, and both parties submit to the exclusive jurisdiction of the provincial and federal courts located in Canada or any federal jurisdiction as per the location of the Owner, and waive any right to challenge personal jurisdiction or venue.
        // 7.8. Entire Agreement.
            // This Agreement sets forth the entire agreement of the parties and supersedes all prior or contemporaneous writings, negotiations, and discussions with respect to its subject matter, exclusive of the NFT Licensing Agreement as stated herewithin..
            // Neither party has relied upon any such prior or contemporaneous communications, exclusive of agreements not yet signed by GSKNNFT Inc.
        // 7.9. Amendment.
            // This Usage Agreement may not be amended in any way except through a written agreement by authorized representatives of the Owner and the current user of the Main Asset.

        // Disclaimer:
            //  GSKNNFT Inc. is not an investment business.
            //  GSKNNFT Inc. offers a deployed contract that can be altered to burn tokens from one contract, in return for a token to be minted from the new contract.
            //  Any and all elements of the Main Asset(s) are subject to change without notice.
            //  Any future token, smart contract, DApp, website, technology, or any physical, or digital creation (on-chain or off-chain) that is released from or utilized by GSKNNFT Inc. should only be used within the network of projects of which GSKNNFT Inc. has permitted through writing.
            //  Any future product, including any physical, or digital creation (on-chain or off-chain) that is released from or utilized by GSKNNFT Inc. shall and will be enforced by this contract.
            //  All legal and commercial IP rights regarding any product, material, merchandise, documentation, smart contracts, Digital Asset(s) or any other item or service provided, will immediately and indefinitely held by GSKNNFT Inc. where applicable.
            //  These rights will remain held by GSKNNFT Inc., notwithstanding any future contracts, or legal transfers of ownership made in writing by GSKNNFT Inc., that may be enforced regarding new projects not yet conceptualized or actualized.

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
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
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721AQueryable.sol';
import '../ERC721A.sol';

/**
 * @title ERC721AQueryable.
 *
 * @dev ERC721A subclass with convenience query functions.
 */
abstract contract ERC721AQueryable is ERC721A, IERC721AQueryable {
    /**
     * @dev Returns the `TokenOwnership` struct at `tokenId` without reverting.
     *
     * If the `tokenId` is out of bounds:
     *
     * - `addr = address(0)`
     * - `startTimestamp = 0`
     * - `burned = false`
     * - `extraData = 0`
     *
     * If the `tokenId` is burned:
     *
     * - `addr = <Address of owner before token was burned>`
     * - `startTimestamp = <Timestamp when token was burned>`
     * - `burned = true`
     * - `extraData = <Extra data when token was burned>`
     *
     * Otherwise:
     *
     * - `addr = <Address of owner>`
     * - `startTimestamp = <Timestamp of start of ownership>`
     * - `burned = false`
     * - `extraData = <Extra data at start of ownership>`
     */
    function explicitOwnershipOf(uint256 tokenId) public view virtual override returns (TokenOwnership memory) {
        TokenOwnership memory ownership;
        if (tokenId < _startTokenId() || tokenId >= _nextTokenId()) {
            return ownership;
        }
        ownership = _ownershipAt(tokenId);
        if (ownership.burned) {
            return ownership;
        }
        return _ownershipOf(tokenId);
    }

    /**
     * @dev Returns an array of `TokenOwnership` structs at `tokenIds` in order.
     * See {ERC721AQueryable-explicitOwnershipOf}
     */
    function explicitOwnershipsOf(uint256[] calldata tokenIds)
        external
        view
        virtual
        override
        returns (TokenOwnership[] memory)
    {
        unchecked {
            uint256 tokenIdsLength = tokenIds.length;
            TokenOwnership[] memory ownerships = new TokenOwnership[](tokenIdsLength);
            for (uint256 i; i != tokenIdsLength; ++i) {
                ownerships[i] = explicitOwnershipOf(tokenIds[i]);
            }
            return ownerships;
        }
    }

    /**
     * @dev Returns an array of token IDs owned by `owner`,
     * in the range [`start`, `stop`)
     * (i.e. `start <= tokenId < stop`).
     *
     * This function allows for tokens to be queried if the collection
     * grows too big for a single call of {ERC721AQueryable-tokensOfOwner}.
     *
     * Requirements:
     *
     * - `start < stop`
     */
    function tokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) external view virtual override returns (uint256[] memory) {
        unchecked {
            if (start >= stop) revert InvalidQueryRange();
            uint256 tokenIdsIdx;
            uint256 stopLimit = _nextTokenId();
            // Set `start = max(start, _startTokenId())`.
            if (start < _startTokenId()) {
                start = _startTokenId();
            }
            // Set `stop = min(stop, stopLimit)`.
            if (stop > stopLimit) {
                stop = stopLimit;
            }
            uint256 tokenIdsMaxLength = balanceOf(owner);
            // Set `tokenIdsMaxLength = min(balanceOf(owner), stop - start)`,
            // to cater for cases where `balanceOf(owner)` is too big.
            if (start < stop) {
                uint256 rangeLength = stop - start;
                if (rangeLength < tokenIdsMaxLength) {
                    tokenIdsMaxLength = rangeLength;
                }
            } else {
                tokenIdsMaxLength = 0;
            }
            uint256[] memory tokenIds = new uint256[](tokenIdsMaxLength);
            if (tokenIdsMaxLength == 0) {
                return tokenIds;
            }
            // We need to call `explicitOwnershipOf(start)`,
            // because the slot at `start` may not be initialized.
            TokenOwnership memory ownership = explicitOwnershipOf(start);
            address currOwnershipAddr;
            // If the starting slot exists (i.e. not burned), initialize `currOwnershipAddr`.
            // `ownership.address` will not be zero, as `start` is clamped to the valid token ID range.
            if (!ownership.burned) {
                currOwnershipAddr = ownership.addr;
            }
            for (uint256 i = start; i != stop && tokenIdsIdx != tokenIdsMaxLength; ++i) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            // Downsize the array to fit.
            assembly {
                mstore(tokenIds, tokenIdsIdx)
            }
            return tokenIds;
        }
    }

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(`totalSupply`) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K collections should be fine).
     */
    function tokensOfOwner(address owner) external view virtual override returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721A.sol';

/**
 * @dev Interface of ERC721 token receiver.
 */
interface ERC721A__IERC721Receiver {
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
contract ERC721A is IERC721A {
    // Bypass for a `--via-ir` bug (https://github.com/chiru-labs/ERC721A/pull/364).
    struct TokenApprovalRef {
        address value;
    }

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
    //                            STORAGE
    // =============================================================

    // The next token ID to be minted.
    uint256 private _currentIndex;

    // The number of tokens burned.
    uint256 private _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

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
    mapping(uint256 => uint256) private _packedOwnerships;

    // Mapping owner address to address data.
    //
    // Bits Layout:
    // - [0..63]    `balance`
    // - [64..127]  `numberMinted`
    // - [128..191] `numberBurned`
    // - [192..255] `aux`
    mapping(address => uint256) private _packedAddressData;

    // Mapping from token ID to approved address.
    mapping(uint256 => TokenApprovalRef) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
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
        return _currentIndex;
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
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view virtual returns (uint256) {
        // Counter underflow is impossible as `_currentIndex` does not decrement,
        // and it is initialized to `_startTokenId()`.
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev Returns the total number of tokens burned.
     */
    function _totalBurned() internal view virtual returns (uint256) {
        return _burnCounter;
    }

    // =============================================================
    //                    ADDRESS DATA OPERATIONS
    // =============================================================

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return _packedAddressData[owner] & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> _BITPOS_NUMBER_MINTED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> _BITPOS_NUMBER_BURNED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return uint64(_packedAddressData[owner] >> _BITPOS_AUX);
    }

    /**
     * Sets the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal virtual {
        uint256 packed = _packedAddressData[owner];
        uint256 auxCasted;
        // Cast `aux` with assembly to avoid redundant masking.
        assembly {
            auxCasted := aux
        }
        packed = (packed & _BITMASK_AUX_COMPLEMENT) | (auxCasted << _BITPOS_AUX);
        _packedAddressData[owner] = packed;
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
        return _name;
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
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
        return _unpackedOwnership(_packedOwnerships[index]);
    }

    /**
     * @dev Initializes the ownership slot minted at `index` for efficiency purposes.
     */
    function _initializeOwnershipAt(uint256 index) internal virtual {
        if (_packedOwnerships[index] == 0) {
            _packedOwnerships[index] = _packedOwnershipOf(index);
        }
    }

    /**
     * Returns the packed ownership data of `tokenId`.
     */
    function _packedOwnershipOf(uint256 tokenId) private view returns (uint256) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr)
                if (curr < _currentIndex) {
                    uint256 packed = _packedOwnerships[curr];
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
                            packed = _packedOwnerships[--curr];
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
    function approve(address to, uint256 tokenId) public payable virtual override {
        address owner = ownerOf(tokenId);

        if (_msgSenderERC721A() != owner)
            if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                revert ApprovalCallerNotOwnerNorApproved();
            }

        _tokenApprovals[tokenId].value = to;
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

        return _tokenApprovals[tokenId].value;
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
        _operatorApprovals[_msgSenderERC721A()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
    }

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
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
            tokenId < _currentIndex && // If within bounds,
            _packedOwnerships[tokenId] & _BITMASK_BURNED == 0; // and not burned.
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
        TokenApprovalRef storage tokenApproval = _tokenApprovals[tokenId];
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
    ) public payable virtual override {
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
            --_packedAddressData[from]; // Updates: `balance -= 1`.
            ++_packedAddressData[to]; // Updates: `balance += 1`.

            // Updates:
            // - `address` to the next owner.
            // - `startTimestamp` to the timestamp of transfering.
            // - `burned` to `false`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                to,
                _BITMASK_NEXT_INITIALIZED | _nextExtraData(from, to, prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
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
    ) public payable virtual override {
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
    ) public payable virtual override {
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
        try ERC721A__IERC721Receiver(to).onERC721Received(_msgSenderERC721A(), from, tokenId, _data) returns (
            bytes4 retval
        ) {
            return retval == ERC721A__IERC721Receiver(to).onERC721Received.selector;
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
        uint256 startTokenId = _currentIndex;
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
            _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
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

            _currentIndex = end;
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
        uint256 startTokenId = _currentIndex;
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
            _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            emit ConsecutiveTransfer(startTokenId, startTokenId + quantity - 1, address(0), to);

            _currentIndex = startTokenId + quantity;
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
                uint256 end = _currentIndex;
                uint256 index = end - quantity;
                do {
                    if (!_checkContractOnERC721Received(address(0), to, index++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (index < end);
                // Reentrancy protection.
                if (_currentIndex != end) revert();
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
            _packedAddressData[from] += (1 << _BITPOS_NUMBER_BURNED) - 1;

            // Updates:
            // - `address` to the last owner.
            // - `startTimestamp` to the timestamp of burning.
            // - `burned` to `true`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                from,
                (_BITMASK_BURNED | _BITMASK_NEXT_INITIALIZED) | _nextExtraData(from, address(0), prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    // =============================================================
    //                     EXTRA DATA OPERATIONS
    // =============================================================

    /**
     * @dev Directly sets the extra data for the ownership data `index`.
     */
    function _setExtraDataAt(uint256 index, uint24 extraData) internal virtual {
        uint256 packed = _packedOwnerships[index];
        if (packed == 0) revert OwnershipNotInitializedForExtraData();
        uint256 extraDataCasted;
        // Cast `extraData` with assembly to avoid redundant masking.
        assembly {
            extraDataCasted := extraData
        }
        packed = (packed & _BITMASK_EXTRA_DATA_COMPLEMENT) | (extraDataCasted << _BITPOS_EXTRA_DATA);
        _packedOwnerships[index] = packed;
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

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '../IERC721A.sol';

/**
 * @dev Interface of ERC721AQueryable.
 */
interface IERC721AQueryable is IERC721A {
    /**
     * Invalid query range (`start` >= `stop`).
     */
    error InvalidQueryRange();

    /**
     * @dev Returns the `TokenOwnership` struct at `tokenId` without reverting.
     *
     * If the `tokenId` is out of bounds:
     *
     * - `addr = address(0)`
     * - `startTimestamp = 0`
     * - `burned = false`
     * - `extraData = 0`
     *
     * If the `tokenId` is burned:
     *
     * - `addr = <Address of owner before token was burned>`
     * - `startTimestamp = <Timestamp when token was burned>`
     * - `burned = true`
     * - `extraData = <Extra data when token was burned>`
     *
     * Otherwise:
     *
     * - `addr = <Address of owner>`
     * - `startTimestamp = <Timestamp of start of ownership>`
     * - `burned = false`
     * - `extraData = <Extra data at start of ownership>`
     */
    function explicitOwnershipOf(uint256 tokenId) external view returns (TokenOwnership memory);

    /**
     * @dev Returns an array of `TokenOwnership` structs at `tokenIds` in order.
     * See {ERC721AQueryable-explicitOwnershipOf}
     */
    function explicitOwnershipsOf(uint256[] memory tokenIds) external view returns (TokenOwnership[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`,
     * in the range [`start`, `stop`)
     * (i.e. `start <= tokenId < stop`).
     *
     * This function allows for tokens to be queried if the collection
     * grows too big for a single call of {ERC721AQueryable-tokensOfOwner}.
     *
     * Requirements:
     *
     * - `start < stop`
     */
    function tokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) external view returns (uint256[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(`totalSupply`) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K collections should be fine).
     */
    function tokensOfOwner(address owner) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721A {
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
    ) external payable;

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

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
    ) external payable;

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
    function approve(address to, uint256 tokenId) external payable;

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
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
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