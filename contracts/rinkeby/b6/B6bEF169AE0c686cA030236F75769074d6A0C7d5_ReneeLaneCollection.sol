// SPDX-License-Identifier: MIT
/**
 * ___________________________________________________________________________
 * ___________________▄▄Æ█▀▀▀███Æ▄▄,_______,▄▄Æ▀██▀▀▀██▄▄_____________________
 * _______"▌^^^^^^▐█▀▀█^^█▀^^█▀^▀█▌╚▀▀▀""▀▀▀▀█▌^▀█^^^█^^█▀▀█▌^^^^^^^Γ_________
 * ________ ┐____▄▀█__╟▌_█___█>^_.─^``,,,_`"¬- `~█__ █_▐▌_ █╙█____,`__________
 * _________ \_ █▌_ █__█_╟▌,^ -`,⌐`__ ______ "-_*,`w]▌_█__█`_ █__/____________
 * ___________▐█ ▀▄_╙█_╟▌▐▀_⌐ ⌐ _______________ "▄",└▌▐▌_▓▀_▄▀_█▌_____________
 * ___________█▀█,_▀▄╙▌_█_┌_▄▄¬`___``¬,_,~^`____`¬▓_\_█_▐▌▄█ ,▄▀█_____________
 * __________▐▌_ ╬▀▓▄██▄ ╒_╛╙╕_______,^__-_______ ╨╨_\_¥██▄█▀╟__╟▌____________
 * __________█▀▀▀██▄▄▀█▌_─⌠_ _\___________ _____, ,_▐_b █▀▄▄▓▓▀▀╙█____________
 * __________█▄▄▄▄▄█▄██⌐j_▌__'_"___ _╒███▌__┌__╒ ,____│_████▄▄▄▄▄█____________
 * __________╟▌___,▄█▌_▌j_▌___ _ ç[__└███▀____Æ_'___ _╠_▌╠▀▄▄___]█____________
 * __________ █▄█▀`__▄█▌_▌╘_____ `▌_________,▀ _____⌠_⌐]█▄__└▀█▄█⌐____________
 * ___________╙▌__▄█▀`_╟▄└_%______└\_______,\______┌_Å_█_ ╙█▄__▐▌_____________
 * ____________▀█▀ _,▄▀└╙▄ ┐'______┌^_____/_______ƒ_┘_╛└▀█▄_ ▀██______________
 * _____________╙█▄▀╙__,▓▀█_²_'._____ ┐__∩_ ___,* / ▄▀█▄__└▀█▓▀_______________
 * ______________ █▄_▄█╙_,▓█*_`≈,`≈.,_`¼╛__.-^ -^_/██,_╙▀▄_╓█_________________
 * _▄█▀▀▀▀▄________╙█▄_▄█▀_▄█▌▐▌._`"~-----─¬` ,╤▌╙█▄_╙▀▄_╓█▀________▄█▀▀▀▓▄___
 * ▓▌_____█⌐_________╙█▄,▓▀`▄██ __  `"¬¬¬"``___ ██▄ ▀█,▄█╙_________ █_____╙█__
 * █_____╒█____________ ▀█▄▀╓█`½_______________╒ █▄▀██▀_____________╙⌐____ █__
 * └█_____________________,██▄__\_____________/__▄██▄_____________________█▀__
 * _ ▀▓,_______________,▄▀╙__ ╙▀█▓___________▓█▀╙___╙▀█▄_______________,▓▀____
 * _____▀▀█▄▄▄▄▄▄▄▄Æ▀▀▀__________ ╙█████████▀__________ ╙▀▀█▄▄▄▄▄▄▄▄█▀▀`______
 * ________________________________ ███████___________________________________
 * __________________________________╙████____________________________________
 * ___________________________________╙██_____________________________________
 * ____________________________________ ______________________________________
 * ___________________________________________________________________________
 *      Surrender   |   Submit  |   Sacrifice   |   Serve   |   Survive
 */

//* ---------------------------- Documentation ---------------------------- //
/**
 * @title The Renee Lane Collection
 * @author Scott Kostolni
 *
 * @notice Version 0.0.0 beta
 *
 * @notice This is a bespoke ERC-721 smart contract written to manage creation
 * and tracking of Non-Fungible Tokens for the Renee Lane Collection, a
 * 50-piece collection of artwork inspired by the author Ms. Renee Lane. The
 * artwork featured in this collection is being sold as limited edition
 * digital prints tracked on the blockchain. The proceeds from this project
 * are being split between the artists and the film-producer, Ms. Viola
 * Voltairine, who is bringing Ms. Renee Lane's book to life as an independent
 * film.
 *
 * @notice This contract allows for the minting of a limited number of
 * tokens for each piece of artwork in The Renee Lane Collection. The artwork
 * is tracked on the blockchain using the ERC-721 standard. Royalties are
 * paid to the artist for each piece minted, as well as through secondary
 * marketplace sales of the artwork. Royalty information is baked into the
 * tokens via the ERC-2981 standard. Metadata for these tokens are securely
 * stored off-chain in IPFS and cannot be altered later.
 *
 * @notice Investors who mint artwork from this collection are stored
 * permanently in the contract's storage so investors will always maintain
 * their benefits even if their artwork is sold or transferred.
 *
 * @notice OpenZeppelin's ERC7211, ERC721Royalties and Ownable contracts were
 * used to provide the standard NFT functionality using secure and tested
 * libraries.
 */

//* ------------------------ Modification History ------------------------- //
/**
 * 04-28-2022 | SRK | Project Created.
 * 04-30-2022 | SRK | Added counters to a struct to help save gas.
 * 05-03-2022 | SRK | Code imported into Renee Lane Collection Project.
 * 05-09-2022 | SRK | Minting Function Completed.
 * 05-10-2022 | SRK | Contract Ownership Functionality Added.
 * 05-15-2022 | SRK | Royalty Functionality Added.
 * 05-15-2022 | SRK | Version 0.1.0 Alpha released.
 * 05-18-2022 | SRK | mintArtwork() gas optimization pass.
 * 05-19-2022 | SRK | Implemented Minting and Royalty Payouts.
 * 05-19-2022 | SRK | Version 0.2.0 Alpha released.
 * 06-02-2022 | SRK | Implemented Investor List functionality.
 * 06-02-2022 | SRK | Version 0.3.0 Alpha released.
 * 06-06-2022 | SRK | Updated to pull-style payouts.
 * 06-06-2022 | SRK | Updated documentation to NatSpec standard.
 * 06-06-2022 | SRK | Version 0.4.0 Alpha released.
 * 06-07-2022 | SRK | Updated to follow Solidity and Project Style Guides.
 * 06-10-2022 | SRK | Adjusted Image prices for readability.
 * 06-12-2022 | SRK | Updated fund withdrawal with more secure logic.
 * 06-27-2022 | SRK | Updated to follow Solidity and Project Style Guides.
 * 06-27-2022 | SRK | Refactored to follow Solidity and Project Style Guides.
 * 06-27-2022 | SRK | Documentation and Comments Updated.
 * 06-29-2022 | SRK | Added Whitelist Functionality.
 * 06-30-2022 | SRK | Version 0.5.0 Alpha released.
 */

//* ----------------------------- Statistics ------------------------------ //
/**
 * @notice Current Gas Usage for version 0.0.0 beta - Optmizer: 1,000 Runs
 * ├─ deployment             -  avg: 5993711  avg (confirmed): 5993711  low: 5993711  high: 5993711 USD: $113.82
 * ├─ constructor            -  avg: 4882094  avg (confirmed): 4882094  low: 4882094  high: 4882094 USD:  $92.71
 * ├─ mintArtwork            -  avg:  139811  avg (confirmed):  153717  low:   22479  high:  211063 USD:   $4.01
 * ├─ addToWhitelist         -  avg:   43341  avg (confirmed):   44218  low:   22728  high:   44439 USD:   $0.84
 * ├─ withdrawPayout         -  avg:   26814  avg (confirmed):   29073  low:   21398  high:   48446 USD:   $0.92
 * ├─ transferOwnership      -  avg:   26474  avg (confirmed):   30154  low:   22794  high:   30154 USD:   $0.57
 * ├─ printInvestorList      -  avg:   24716  avg (confirmed):   24716  low:   23203  high:   26195 USD:   $0.50
 * ├─ name                   -  avg:   24519  avg (confirmed):   24519  low:   24519  high:   24519 USD:   $0.47
 * ├─ symbol                 -  avg:   24495  avg (confirmed):   24495  low:   24495  high:   24495 USD:   $0.47
 * ├─ tokenURI               -  avg:   24221  avg (confirmed):   25059  low:   22548  high:   25609 USD:   $0.49
 * ├─ artGallery             -  avg:   23456  avg (confirmed):   23456  low:   23456  high:   23456 USD:   $0.44
 * ├─ artist                 -  avg:   23280  avg (confirmed):   23280  low:   23280  high:   23280 USD:   $0.45
 * ├─ forcePayment           -  avg:   23139  avg (confirmed):   23076  low:   22752  high:   23656 USD:   $0.44
 * ├─ royaltyInfo            -  avg:   23020  avg (confirmed):   23020  low:   23014  high:   23026 USD:   $0.43
 * ├─ isInvestor             -  avg:   22751  avg (confirmed):   22751  low:   22751  high:   22763 USD:   $0.43
 * ├─ isWhitelisted          -  avg:   22742  avg (confirmed):   22742  low:   22742  high:   22742 USD:   $0.43
 * ├─ payoutsOwed            -  avg:   22741  avg (confirmed):   22741  low:   22741  high:   22741 USD:   $0.42
 * ├─ ownerOf                -  avg:   22484  avg (confirmed):   22484  low:   22484  high:   22484 USD:   $0.42
 * ├─ PROJECT_WALLET_ADDRESS -  avg:   22190  avg (confirmed):   22190  low:   22190  high:   22190 USD:   $0.42
 * ├─ owner                  -  avg:   22140  avg (confirmed):   22140  low:   22140  high:   22140 USD:   $0.41
 * ├─ supportsInterface      -  avg:   21903  avg (confirmed):   21903  low:   21795  high:   21958 USD:   $0.42
 * ├─ getContractBalance     -  avg:   21358  avg (confirmed):   21358  low:   21358  high:   21358 USD:   $0.41
 * ├─ removeFromWhitelist    -  avg:   20416  avg (confirmed):   14749  low:   14749  high:   23706 USD:   $0.45
 * └─ renounceOwnership      -  avg:   18500  avg (confirmed):   14775  low:   14775  high:   22226 USD:   $0.42
 * Note: USD Calculations based on Gas Price: 35 Wei and Ethereum price: $1208 from 6-26-2022.
 * Formula: TransactionCost =  (Gas (High) * Gas Price * Etherum USD Price) / 1,000,000,000
 */

//* ------------------------------- Tasks --------------------------------- //
/**
 * Todo: Release version 0.5.0 alpha
 * Todo: Deploy Renee Lane Collection contract for Beta testing.
 * Todo: Begin preparing for beta release.
 * Todo: Update _baseURI to new IPFS metdata address.
 * Todo: Gas Optimization Passes.
 */

//* ------------------------------ Resources ------------------------------ //
/**
 * @notice Pragma statements tell the compiler to use the version of
 * solidity this contract was designed for.
 */
pragma solidity 0.8.15;

/**
 * @notice Import statements allow the contract to access features of
 * other contracts. Specifically OpenZeppelin's ERC721, ERC721Royalty, and
 * Ownable libraries.
 */
import "ERC721.sol";
import "ERC721Royalty.sol";
import "Ownable.sol";

//* ------------------------------ Contract ------------------------------- //
/**
 * @notice The contract statement defines the contract's name, and the
 * libraries that it uses.
 *
 * @notice The Renee Lane Collection inherits OpenZeppelin's ERC721,
 * ERC721Royalty, and Ownable extensions to ensure compliance to the current
 * standards and provide a strong securit basis with code that has been vetted
 * elsewhere.
 */
contract ReneeLaneCollection is ERC721, ERC721Royalty, Ownable {
    //* ------------------------ Data Structures --------------------------- //
    /**
     * @notice Data structures are used to store data in the contract. They
     * represent real world objects in the code. In this contract there are
     * stuctures which represent pieces of artwork and the artists. There are
     * additional structures which represent collection investors, the art
     * gallery where the collection is managed, a whitelist of people who can
     * invest in the collection early, and a ledger which tracks the
     * collection's payouts owed to the artists and the project owner.
     */

    //* --------------------------- Structs -------------------------------- //
    /**
     * @notice Structs represent items with specific properties. This contract
     * uses two structs to define the Artwork and the Artists.
     */

    /**
     * @notice The Artwork struct is used to define the properties that each piece
     * of Artwork in this collection must have. In this case each piece of artwork
     * has an imageNumber (1 through 50), a price in wei, a currentTokenID number
     * a lastTokenID number and an artistID number (1-5).
     */
    struct Artwork {
        uint64 imgNumber;
        uint64 price;
        uint64 currentTokenID;
        uint64 lastTokenID;
        uint256 artistID;
    }

    /**
     * @notice The Artist struct is used to define the properties for each
     * artist. In this case each artist has a directAddress where they will be
     * paid their portion of the minting proceeds and a RoyaltyAddress where
     * proceed from secondary sales will be split between the artist and the
     * project.
     */
    struct Artist {
        address directAddress;
        address royaltyAddress;
    }

    //* --------------------------- Arrays -------------------------------- //
    /**
     * @notice Arrays are used to store collections of items.
     */

    /**
     * @notice The investorList array is used to permanently store the
     * addresses of anyone who mints a art piece from this collection. This
     * array is used in the printInvestorList() function.
     */
    address[] public investorList;

    //* -------------------------- Mappings ------------------------------- //
    /**
     * @notice Mappings are gas effecient ways to store collections of items.
     * They are similar to Arrays but only return specific information based
     * on a key (or question) provided to them.
     */

    /**
     * @notice The artGallery mapping stores information about each piece of
     * artwork using the Artwork struct. When given an image number
     * (1 through 50)the mapping will return the imageNumber, price,
     * currentTokenID,lastTokenID, and artistID for that piece of art.
     */
    mapping(uint256 => Artwork) public artGallery;

    /**
     * @notice The artist Mapping stores information about each artist. When
     * given an artistID (1-5) it will return the directAddress and
     * royaltyAddress for that artist.
     */
    mapping(uint256 => Artist) public artist;

    /**
     * @notice the isInvestoryapping stores information about each investor.
     * When given a wallet address it will return True if that address has
     * minted a piece of art from this collection. If they have not it will
     * return False.
     */
    mapping(address => bool) public isInvestor;

    /**
     * @notice The isWhitelisted mapping stores the whitelist status of
     * addresses. These are addresses that are allowed to mint tokens prior
     * to the collection launch. When given a wallet address it will return
     * True if that address is whitelisted. If they are not it will return
     * False.
     */
    mapping(address => bool) public isWhitelisted;

    /**
     * @notice The payoutsOwed mapping stores the payouts owed to each artist
     * and to the project owner. When given a wallet address this mapping will
     * return the amount of ether (in wei) that is owed to that address.
     */
    mapping(address => uint256) public payoutsOwed;

    //* ----------------------- State Variables --------------------------- //
    /**
     * @notice The PROJECT_OWNER_ADDRESS is address of the project owner. It
     * cannot be changed after the contract is deployed. Funds owed to the
     * project owner are paid to this address.
     */
    address public PROJECT_WALLET_ADDRESS = (
        0xbbd68C8318087E5641b28698C69c779F23E50FFB
    );

    //* --------------------------- Events -------------------------------- //
    /**
     * @notice Events are used to log important updates about what The Renee
     * Lane Collection is doing. When an event is triggered it will log the
     * information permanently on the blockchain.
     */

    /**
     * @notice The NewInvestorAdded event is triggered when a new investor is
     * added to the investor list and mapping. It logs the investor's address
     * and the token ID of the first piece of art they minted.
     *
     * @notice The NewInvestorAdded event is triggered when addNewInvestor()
     * function is called.
     */
    event NewInvestorAdded(
        address indexed investorAddress,
        uint256 indexed tokenID
    );
    /**
     * @notice The PaymentSplit event is triggered when a minting payment is
     * received and split between the artist and the project owner. It logs
     * the amount of ether (in wei) that is due to the artist and the amount
     * that is due to the project owner.
     *
     * @notice The PaymentSplit event is trigged when the splitPayment()
     * function is called.
     */
    event PaymentSplit(
        uint256 totalValueReceived,
        address indexed artistAddress,
        int256 indexed artistCut,
        int256 indexed projectCut
    );
    /**
     * @notice the PayoutSent event is triggered when a payout is sent from
     * the contract. It logs the address of the person who initiated the
     * payout, the address of the recipient and the amount of ether (in wei)
     * that was sent.
     *
     * @notice The PayoutSent event is triggered when the withdrawPayout() or
     * forcePayment() functions are called.
     */
    event PayoutSent(
        address indexed caller,
        address indexed recipientAddress,
        uint256 indexed amount
    );

    //* ------------------------- Constructor ----------------------------- //
    /**
     * @notice The constructor helps set up the initial state of the smart
     * contract. It is called when the contract is deployed.
     *
     * @notice It first sets the name of the Art Collection and the Symbol the
     * tokens will have.
     */
    constructor() ERC721("The Renee Lane Collection", "TRLC") {
        /**
         * @notice Here the constructor populates the artist mapping by
         * assigning the direct and royalty addresses to each artist by their
         * ID number.
         */
        artist[1] = Artist({
            directAddress: 0x110969C24Da5268842Fd3756F499299056EB4DBf,
            royaltyAddress: 0xE709Ebdb07B30052D241024b6f9a3cd9482a30Df
        });
        artist[2] = Artist({
            directAddress: 0x3CC74a8eAd939BfC631bad2e010cdE26D6d9f057,
            royaltyAddress: 0x3dC3c88E15e77F6d79A08b94cac30a59d04D1Ec0
        });
        artist[3] = Artist({
            directAddress: 0x58C6558fB57114444f23b77a42b475bBE9146107,
            royaltyAddress: 0xd39e01d5931A81a6ed2C8B77A2c6366b92378686
        });
        artist[4] = Artist({
            directAddress: 0x4cf55451AB4274b043D5d17dd8112ed825E565c9,
            royaltyAddress: 0x47eD0FF0A62383465199428290CFCAc406cCE64E
        });
        artist[5] = Artist({
            directAddress: 0x10B7D462EDe680429344B20f16e3245E01F22FA4,
            royaltyAddress: 0x68a53E615Ea6B30cd27Ae15c6A8D972eE1ff7867
        });

        /**
         * @notice Here the constructor populates the artGallery mapping by
         * creating Artwork objects for each image in the collection. The image
         * number, price, starting token ID, and artist who created the image
         * are all assigned. The lastTokenID is also set which limits the
         * number of tokens that can be minted for that piece of art.
         */
        artGallery[1] = Artwork(1, .12 ether, 1, 20, 1);
        for (uint64 index = 2; index <= 10; index++) {
            artGallery[index] = Artwork({
                imgNumber: index,
                price: .12 ether,
                currentTokenID: artGallery[index - 1].currentTokenID + 20,
                lastTokenID: artGallery[index - 1].lastTokenID + 20,
                artistID: 1
            });
        }
        for (uint64 index = 11; index <= 20; index++) {
            artGallery[index] = Artwork({
                imgNumber: index,
                price: .24 ether,
                currentTokenID: artGallery[index - 1].currentTokenID + 20,
                lastTokenID: artGallery[index - 1].lastTokenID + 20,
                artistID: 2
            });
        }
        artGallery[21] = Artwork(21, .36 ether, 401, 410, 3);
        for (uint64 index = 22; index <= 30; index++) {
            artGallery[index] = Artwork({
                imgNumber: index,
                price: .36 ether,
                currentTokenID: artGallery[index - 1].currentTokenID + 10,
                lastTokenID: artGallery[index - 1].lastTokenID + 10,
                artistID: 3
            });
        }
        artGallery[31] = Artwork(31, .48 ether, 501, 505, 4);
        for (uint64 index = 32; index <= 40; index++) {
            artGallery[index] = Artwork({
                imgNumber: index,
                price: .48 ether,
                currentTokenID: artGallery[index - 1].currentTokenID + 5,
                lastTokenID: artGallery[index - 1].lastTokenID + 5,
                artistID: 4
            });
        }
        artGallery[41] = Artwork(41, .6 ether, 551, 553, 5);
        for (uint64 index = 42; index <= 50; index++) {
            artGallery[index] = Artwork({
                imgNumber: index,
                price: .6 ether,
                currentTokenID: artGallery[index - 1].currentTokenID + 3,
                lastTokenID: artGallery[index - 1].lastTokenID + 3,
                artistID: 5
            });
        }
    }

    //* --------------------- External Functions -------------------------- //
    /**
     * @notice External functions can ONLY be called from other contracts, or
     * users.
     */

    /**
     * @notice The mintImage() function was renamed to mintArtwork() to better
     * fit the theme of the project. The minter must specify the number of the
     * image they wish to purchse, and pay the correct amount of Ether.
     *
     * @notice The function will check to see if the minter is authorized to
     * mint the image by checking the isWhitelisted mapping. It insures that
     * the minter has selected an art piece contained within the collection
     * and that there are still editions of that artpiece available.
     *
     * @notice If all checks are passed the token will be minted and assigned
     * to the minter via the _safeMint() function inherited from
     * OpenZeppelin's ERC721 contract. Royalty preferences for that token are
     * set using the _setTokenRoyalty() function inherited from OpenZeppelin's
     * ERC721Royalty contract and by using the ERC2981 royalty standard.
     *
     * @notice If this is the first artpiece purchased by the minter their
     * address will be added to the investorList and isInvestor mapping.
     *
     * @notice The payment received from the minter is split between the
     * artist and the PROJECT_WALLET_ADDRESS using the splitPayment()
     * function. These payouts can be withdrawn later.
     *
     * @notice Finally the mintArtwork() function increments the
     * currentTokenID for that artpiece removing one edition of that image
     * from the amount available.
     *
     * @param _imageNumber The number of the image the user wants to mint
     * (1-50).
     */
    function mintArtwork(uint256 _imageNumber) external payable {
        if (isWhitelisted[address(0)] == false) {
            require(
                isWhitelisted[msg.sender] == true,
                "You are not whitelisted"
            );
        }
        require(
            _imageNumber > 0 && _imageNumber < 51,
            "The image you have selected does not exist in this collection."
        );
        uint64 _newTokenID = artGallery[_imageNumber].currentTokenID;
        require(
            _newTokenID <= artGallery[_imageNumber].lastTokenID,
            "No more editions of this image are available."
        );
        require(
            msg.value == artGallery[_imageNumber].price,
            "You didn't send the correct amount of Ether."
        );
        Artist memory _artist = artist[artGallery[_imageNumber].artistID];
        _safeMint(msg.sender, _newTokenID);
        _setTokenRoyalty(_newTokenID, _artist.royaltyAddress, 1000);
        if (!isInvestor[msg.sender]) {
            addNewInvestor(msg.sender, _newTokenID);
        }
        splitPayment(_artist.directAddress, msg.value);
        artGallery[_imageNumber].currentTokenID++;
    }

    /**
     * @notice The withdrawPayout() function allows the caller to withdraw the
     * Ether owed to them. This function can be called by anyone but will
     * revert if no money is owed to them or if there is no Ether stored in
     * the contract. When called by the owner they payment will be disbursed
     * to the PROJECT_WALLET_ADDRESS, otherwise payment will be disbursed to
     * the caller's address.
     *
     * @notice Once the payment has been sent the PayoutSent event is
     * triggered to log the payout. The balance owed to that address is set to
     * 0.
     */
    function withdrawPayout() external {
        require(getContractBalance() > 0, "No money in contract.");
        address _address;
        if (msg.sender == owner()) {
            _address = PROJECT_WALLET_ADDRESS;
        } else {
            _address = msg.sender;
        }
        uint256 _amount = payoutsOwed[_address];
        require(_amount > 0, "No funds owed to this wallet.");
        payable(_address).transfer(_amount);
        emit PayoutSent(msg.sender, _address, _amount);
        payoutsOwed[_address] = 0;
    }

    //* -------------------- OnlyOwner Functions -------------------------- //
    /**
     * @notice OnlyOwner functions are only callable by the owner of the
     * contract. They are subclass of External Functions.
     */

    /**
     * @notice The addToWhitelist() function allows the contract owner to
     * authorize new addresses to mint tokens early by setting their address
     * to return True from the isWhitelisted mapping.
     *
     * @notice The function will first check to ensure the address is not
     * already whitelisted. This function can only be called by the owner.
     *
     *! @notice Note: If the owner adds the Zero Address to the whitelist the
     *! mintArtwork() function will allow ALL addresses to mint artwork.
     *
     * @param _address The address to be added to the whitelist.
     */
    function addToWhitelist(address _address) external onlyOwner {
        require(
            !isWhitelisted[_address],
            "Address is already on the whitelist."
        );
        isWhitelisted[_address] = true;
    }

    /**
     * @notice The removeFromWhitelist() function allows the contract owner to
     * deauthorize an address from minting tokens early by setting their
     * address to return False from the isWhitelisted mapping.
     *
     * @notice The function will first check to ensure the address is
     * currently on the whitelist. This function can only be called by the
     * owner.
     *
     * @param _address The address to be removed from the whitelist.
     */
    function removeFromWhitelist(address _address) external onlyOwner {
        require(isWhitelisted[_address], "Address is not on the whitelist.");
        isWhitelisted[_address] = false;
    }

    /**
     * @notice The forcePayment() function allows the contract owner to force
     * a payment to be sent to an address they specify. This function can only
     * be called by the owner and is designed to be used in a situation where
     * the artist cannot request their own payout using the withdrawPayout()
     * function.
     *! @notice This function is less secure than withdrawPayout() and should
     *! only be used when absolutely necessary. It does not follow the
     *! recommended pull design pattern.
     *
     * @notice This function will revert if no payment is owed to the
     * specified address, or when the caller is not the owner. After paying
     * the specified address, a PayoutSent event is triggered and the balance
     * owed to that address is set to 0.
     *
     * @param _addressToBePayed The address of the wallet payment will be sent
     * to.
     *
     */
    function forcePayment(address _addressToBePayed) external onlyOwner {
        uint256 _amountOwed = payoutsOwed[_addressToBePayed];
        require(_amountOwed > 0, "No money owed to this address.");
        payable(_addressToBePayed).transfer(_amountOwed);
        emit PayoutSent(msg.sender, _addressToBePayed, _amountOwed);
        payoutsOwed[_addressToBePayed] = 0;
    }

    //* ---------------------- Public Functions -------------------------- //
    /**
     * @notice Public functions can be seen and called from other contracts,
     * users as well as from the contract itself.
     */

    /**
     * @notice The getContractBalance() function returns the current balance
     * of Ether (in Wei) currently stored in the contract.
     *
     * @return contractBalance The amount of Ether (in Wei)
     */
    function getContractBalance()
        public
        view
        returns (uint256 contractBalance)
    {
        return address(this).balance;
    }

    /**
     * @notice The printInvestosList() function returns the list of investor
     * addresses from the investorList array.
     *
     * @return allInvestors The address stored on the investorList[] array.
     *
     */
    function printInvestorList()
        public
        view
        returns (address[] memory allInvestors)
    {
        return investorList;
    }

    /**
     * @notice The supportsInterface() function returns 'true' for supported
     * interfaces. Returns 'false' if the interface is not supported.
     *
     * @param interfaceID The 4 byte identifier for an interface.
     *
     * @return bool A True of False value.
     *
     */
    function supportsInterface(bytes4 interfaceID)
        public
        view
        override(ERC721, ERC721Royalty)
        returns (bool)
    {
        return super.supportsInterface(interfaceID);
    }

    /**
     * @notice The tokenURI() function returns the Token URI for the specified
     * tokenID. It will revert if the tokenID provided does not exist.
     *
     * @param tokenID - The number of the token for which the URI is being
     * set.
     *
     * @return string - The full tokenURI address for the specified token.
     *
     */
    function tokenURI(uint256 tokenID)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenID),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        return
            string(
                abi.encodePacked(baseURI, Strings.toString(tokenID), ".json")
            );
    }

    //* --------------------- Internal Functions -------------------------- //
    /**
     * @notice Internal functions are only callable by the contract itself.
     * They are not available to users, the owner, or other contracts.
     */

    /**
     * @notice The addNewInvestor() function will add a new investor to the
     * investorList and set their isInvestor mapping result to true.
     *
     * @notice This function emits the NewInvestorAdded event.
     *
     * @param _minterAddress Wallet address of the person who minted the
     * artwork.
     *
     * @param _tokenID the tokenID of the artwork they minted.
     */
    function addNewInvestor(address _minterAddress, uint64 _tokenID) internal {
        isInvestor[_minterAddress] = true;
        investorList.push(_minterAddress);
        emit NewInvestorAdded(_minterAddress, _tokenID);
    }

    /**
     * @notice The _baseURI() function returns the IPFS address where this
     * collection's metadata and assets are stored.
     *
     * @return string The baseURI address.
     *
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return
            "https://ipfs.io/ipfs/QmNvnTpZVSW9ej8PdS4xzuKDFqCwhFLkhVfTA1JiLBS8EN/"; // Old URI
    }

    /**
     * @notice The _burn() function is used to burn a token. This is function
     * which is required by the libraries this contract uses to interact with
     * the blockchain but there is no way to call this function
     * (or to burn tokens) for artwork from this collection.
     *
     * @notice If a token is burned it will be removed from the collection,
     * the royalty information will be erased.
     *
     *! @notice Burning a token is irreversible. If you burn your token it can
     *! NEVER be recovered.
     *
     * @param tokenID The token ID which is to be destroyed.
     *
     */
    function _burn(uint256 tokenID)
        internal
        virtual
        override(ERC721, ERC721Royalty)
    {
        super._burn(tokenID);
        _resetTokenRoyalty(tokenID);
    }

    /**
     * @notice The splitPayment() function splits payments received during
     * the minting process. The artist receives 10% of the payment, and the
     * project receives the remaining 90%.
     *
     * @notice This function emits the PayoutSplit event.
     *
     * @param _artistDirectAddress The address of the artist's wallet.
     *
     * @param valueSent The amount of Ether received when the artwork was
     * minted.
     */
    function splitPayment(address _artistDirectAddress, uint256 valueSent)
        internal
    {
        int256 _artistCut = int256(valueSent) / 10**1;
        int256 _projectCut = (int256(valueSent) - _artistCut);
        payoutsOwed[_artistDirectAddress] += uint256(_artistCut);
        payoutsOwed[PROJECT_WALLET_ADDRESS] += uint256(_projectCut);
        emit PaymentSplit(
            valueSent,
            _artistDirectAddress,
            _artistCut,
            _projectCut
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "IERC721.sol";
import "IERC721Receiver.sol";
import "IERC721Metadata.sol";
import "Address.sol";
import "Context.sol";
import "Strings.sol";
import "ERC165.sol";

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
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
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
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

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
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

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
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
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
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
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
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
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
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

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
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "IERC721.sol";

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

import "IERC165.sol";

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/ERC721Royalty.sol)

pragma solidity ^0.8.0;

import "ERC721.sol";
import "ERC2981.sol";
import "ERC165.sol";

/**
 * @dev Extension of ERC721 with the ERC2981 NFT Royalty Standard, a standardized way to retrieve royalty payment
 * information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC721Royalty is ERC2981, ERC721 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally clears the royalty information for the token.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "IERC2981.sol";
import "ERC165.sol";

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
     * - `tokenId` must be already minted.
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
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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