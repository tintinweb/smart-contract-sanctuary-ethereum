//        __  ___ __ __  _   _  _   _   _ _  ___  __    __ ____ __ ___ 
//       / _|| o \\ V / / \ | \| | / \ | | ||_ _|/ _|   \ V /\ V /|_ / 
//      ( (_ |   / \ / ( o )| \\ || o || U | | | \_ \    ) (  \ /  /(_ 
//       \__||_|\\ |_|  \_/ |_|\_||_n_||___| |_| |__/() /_n_\ |_| /___|
//                                                               
//
//                                    ..........                                   
//           .-:::::::::::::::::::::*          +:::::::::::::::::::::-.           
//   .=#@#-*%@*:::::::::::::::::::::+  .::-:.  =:::::::::::::::::::::[email protected]@*=*@%+:   
//   #*=-+*=. =                     =  :=:.=.  =                     -..-+*-=+%   
//   ==.=     +.....................+  :==-:   =.....................=:    = ==   
//   ==:-.-+#@#---------------------*          =------------------=--*@%*=.::==   
//   +=#@@#++:   =            ::::::::::::::::::::::::            =    *=#@@#+*   
//   -++-   ::++-=        .:::                        .:::        +:++.=   .*+=   
//     -=:. :[email protected]@@@#++++++%#***###%%%%%%%%%%%%%%%%%%####***%++++++*@@@@-=  ::+.    
//   [email protected]#:-=+-: -+%%@@@@@@@@@@@@@@@%%############%%@@@@@@@@@@@@@@@%%+-. ===-.*@*   
//   @@-.- -*:   =   =.   =#@@#*=-.   =*       ..::=#%@@%=    =.  =    #= [email protected]@.  
//   :*#=+----:  =  =   [email protected]@%=   *%-  *%%*  =#:         :#@@+   =. =  :-:-:*-##-   
//     ::-:=: .+-= +   *@@%-%#=+%%%+*%%%%#+%%%*-     .:--#@@#   + +:+: .-=::=     
//     ::-:.:++  =+-: *@@- -%%%%%%%%%%%%%%%%%%%%%#+=-:   [email protected]@# .:++  === -::=     
//     ::=:.:: -=- :@*@@*  %%%%%%%%%%%%%%%%%%%%%%%%%%%%*. [email protected]@*@= :=-. = --:=     
//     ::-- ::   ***%%@%::.=#%%%%%%%%%%%%%%%%%%%%%%%%%%%%--=%@@%#+#    = --.=     
//     ::   ::   *[email protected]@+    [email protected]%%%%@%%%@%%%%%%%%%%%%%%%%%%   [email protected]@--.*    =    =     
//     :-*+=-:   +  [email protected]@*-:  ##:-+**+=+*#*%%%%%%%%%%%%%%%%[email protected]@+  +    =-++:=     
//    .-- :*=:   =  [email protected]@.   :%=            .-=+***@@@%%%%#    %@*  +    +*- :-.    
//   -: .:-:::   =  [email protected]@=-. :%:                    +%%%%%+ .-=%@*  +    =:-=. .-   
//   - =:   ::   =  [email protected]@     %:=***++:      .....  #%%%%@:    #@*  +    =    * .:  
//   - -=+#%::   =  [email protected]@:.   :-:+*##*-   :-+**##=:=#%%%%%   .:%@*  +    =*#+=+ :.  
//   .: --+%::   =  [email protected]@.    .=+++#**# .:+#*###@@*+#@@+.:=: ..%@*  +    =#*:+ .:   
//    :  =-%::   =  [email protected]@      +. :%@*=--:%%#%%+%@#*+-=--. *   #@*  +    =*=:: :    
//   .. :-=%::   =  [email protected]@-:    =:.:==:::-.=#@%%%%*+= .++++*+::-%@*  +    =#*:= ..   
//  :. --=++::   =  [email protected]@      =   .. - .. .:---:.   .*--+=    #@*  +    ==+=-+  -  
//  = .:=:::=:   =  [email protected]@-.    +      ..             ::..    .-%@*  +    +:::--. -  
//  = . -=%@%+   =  [email protected]@      ::     :...:=-        +         #@*  +   +#@%+= . -  
//  .:  .-**%#+  =  [email protected]@:.     :-     .-=:        .=        .:%@*  +  =*%#*=.. .:  
//   .-. .+-+=-- =  [email protected]@         -:             --:           #@*  +  +-+=+.  -.   
//     .::  :=*- =  [email protected]@           :--:....:-*#*+=            #@*  +  +*-. .::     
//        +==+=- =  [email protected]@:.             *+++=-.  .=...       .-%@*  +  =+++*        
//        +:-:-- =  [email protected]@           .-+*@         %***=-       #@*  +  +:-:+        
//        =   .- =   [email protected]%:       .+*+**%         #*++*#*.   :#@#.  +  -   =        
//        =   .- =    %@+     :-=*+*%*.         #%*+**#***=*@@    +  -   =        
//      -::::=+***-   %@*:-+**+-*+*%#    .     *@*++**#%+++#@@   :+**++::::-      
//     =     [email protected]*....:-#@#=*+*#*++*##*.        =*#=+++###*++#@@::[email protected]:    +     
//     -:    =##--   = [email protected]%*+*#-++##   . --.... --+*+*#%#*+%@+ =   :-+%=.   .=     
//      ::-::-++=++  -  %@*+#+=**#*    [email protected]#    .=++**#%*++*@@  =  =+==+=::-::      
//        =   .- ==  -  %@**%=++*#%    [email protected]%    .+++*#%%*=+*@@  =  -=  -   =     
//
//                          https://cryonauts.xyz/mint
//
// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./AccessControlEnumerable.sol";
import "./ERC2981.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./ERC721.sol";

contract NftMinter is ERC721, AccessControlEnumerable, ERC2981 {
    using Counters for Counters.Counter;
    bytes32 public constant PAYOUT_ROLE = keccak256("PAYOUT_ROLE");
    bytes32 public constant LEGENDARY_PROVIDER_ROLE =
        keccak256("LEGENDARY_PROVIDER_ROLE");

    Counters.Counter private _tokenIds;
    uint256 public maxSupply;
    uint256 public pricePerNft;
    uint256 public whitelistPricePerNft;
    string private _baseUri;
    bool private _baseUriSettable = true;
    uint64 public whitelistMintStartTime = 0;    
    uint64 public mintStartTime = 0;
    // The default end time is 2030/12/31 at 23:59:59.
    uint64 public whitelistMintEndTime = 1925009999;
    uint64 public mintEndTime = 1925009999;
    bool public mintingAllowed = true;
    bytes32 public whitelistProofRoot = 0x0;
    mapping(address => uint256) public whitelistMinted;
    string public legendaryStatus;

    /**
     * @dev Emitted when tokens are minted via the mintCryonautsXyz() function.
     */
    event TokensMinted(uint256 numTokensMinted, string clientInfo);

    /**
     * @dev Initializes the NftMinter with default admin and payout roles.
     *
     * @param name_ the name of the NFT collection.
     * @param symbol_ the symbol of the NFT collection.
     * @param maxSupply_ the maximum number of items in the collection.
     * @param pricePerNft_ the price per NFT.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxSupply_,
        uint256 pricePerNft_,
        uint256 whitelistPricePerNft_
    ) ERC721(name_, symbol_) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(LEGENDARY_PROVIDER_ROLE, _msgSender());
        maxSupply = maxSupply_;
        pricePerNft = pricePerNft_;
        whitelistPricePerNft = whitelistPricePerNft_;
        _baseUri = "";
        legendaryStatus = "Verified Still Valid (Unused)";
        super._setRoleAdmin(LEGENDARY_PROVIDER_ROLE, LEGENDARY_PROVIDER_ROLE);
    }

    /**
     * @dev Set price per NFT.
     */
    function setPricePerNft(uint256 pricePerNft_)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        pricePerNft = pricePerNft_;
    }

    /**
     * @dev Set whitelist price per NFT.
     */
    function setWhitelistPricePerNft(uint256 whitelistPricePerNft_)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        whitelistPricePerNft = whitelistPricePerNft_;
    }

    /**
     * @dev Public facing minting function.
     */
    function mintCryonautsXyz(uint256 numTokensToMint, string memory clientInfo)
        public
        payable
    {
        uint256 currentPayment = numTokensToMint * pricePerNft;
        require(msg.value == currentPayment, "Invalid payment amount.");
        require(mintStartTime <= block.timestamp, "Minting is not open yet.");
        uint256 startTokenId = _tokenIds.current();
        _mintCommon(numTokensToMint);
        emit TokensMinted(_tokenIds.current() - startTokenId, clientInfo);
    }

    /**
     * @dev Minting function for buys on a whitelist. The price and start time can be different from
     *  the regular minting function.
     */
    function whitelistMintCryonautsXyz(
        bytes32[] memory proof,
        uint256 maxMintableTokens,
        uint256 numTokensToMint,
        string memory clientInfo
    ) public payable {
        require(
            whitelistMinted[_msgSender()] + numTokensToMint <=
                maxMintableTokens,
            "Trying to mint more whitelist tokens than allowed."
        );
        require(
            onWhitelist(_msgSender(), maxMintableTokens, proof),
            "Invalid proof."
        );
        require(
            msg.value == numTokensToMint * whitelistPricePerNft,
            "Invalid payment value."
        );
        require(whitelistMintStartTime <= block.timestamp, "Minting not open.");
        require(block.timestamp <= whitelistMintEndTime, "Minting closed.");
        uint256 startTokenId = _tokenIds.current();
        _mintCommon(numTokensToMint);
        whitelistMinted[_msgSender()] += numTokensToMint;
        emit TokensMinted(_tokenIds.current() - startTokenId, clientInfo);
    }

    /**
     * @dev Irreversibly stops all future minting.
     */
    function stopFutureMinting() public onlyRole(DEFAULT_ADMIN_ROLE) {
        mintingAllowed = false;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        require(getRoleMemberCount(DEFAULT_ADMIN_ROLE) == 1);
        return getRoleMember(DEFAULT_ADMIN_ROLE, 0);
    }

    /**
     * @dev Sets the address that will get royalties.
     */
    function setRoyalty(address receiver, uint96 royaltyBps)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setDefaultRoyalty(receiver, royaltyBps);
    }

    /**
     * @dev Allows administrators to mint for free. This could be used
     *  for raffles or listing NFTs on marketplaces such as OpenSea or
     *  Rarible. This can happen prior to the mint opening, but not
     *  after minting has closed and cannot be used to increase the
     *  number of NFTs beyond the max supply.
     */
    function adminMintCryonautsXyz(uint256 numTokensToMint)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _mintCommon(numTokensToMint);
    }

    /**
     * @dev Allows token holders to burn their tokens. This is irreversible.
     */
    function burn(uint256 tokenId) public {
        require(
            super.ownerOf(tokenId) == msg.sender,
            "Only token owner can burn."
        );
        super._burn(tokenId);
    }

    /**
     * @dev Remaining number of tokens that can be minted.
     */
    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    /**
     * @dev Withdraw ETH from this contract to an account in `PAYOUT_ROLL`.
     */
    function withdraw() public onlyRole(PAYOUT_ROLE) {
        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        require(sent, "Send failed.");
    }

    /**
     * @dev Updates the baseUri of the NFTs. For example, when artwork is ready.
     */
    function setBaseUri(string memory baseUri)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_baseUriSettable, "URIs frozen.");
        _baseUri = baseUri;
    }

    /**
     * @dev Prohibits future updating of the metadata.
     */
    function freezeCryonauts() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseUriSettable = false;
    }

    /**
     * @dev Sets when minting can begin.
     */
    function setMintStartTime(uint64 mintStartTime_)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        mintStartTime = mintStartTime_;
    }

    /**
     * @dev Sets when whitelist minting can begin.
     */
    function setWhitelistMintStartTime(uint64 whitelistMintStartTime_)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        whitelistMintStartTime = whitelistMintStartTime_;
    }

    /**
     * @dev Sets when whitelist minting ends.
     */
    function setWhitelistMintEndTime(uint64 whitelistMintEndTime_)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        whitelistMintEndTime = whitelistMintEndTime_;
    }

    /**
     * @dev Sets when minting ends. No minting of any kind of permitted after this time.
     */
    function setMintEndTime(uint64 mintEndTime_)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(mintEndTime_ <= mintEndTime, "New end time must be sooner.");
        mintEndTime = mintEndTime_;
    }

    /**
     * @dev Updates the status of the legendary NFT once it has been allocated.
     */
    function setLegendaryStatus(string memory legendaryStatus_)
        public
        onlyRole(LEGENDARY_PROVIDER_ROLE)
    {
        legendaryStatus = legendaryStatus_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, AccessControlEnumerable, ERC2981)
        returns (bool)
    {
        return
            interfaceId == type(IAccessControlEnumerable).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Sets the root hash of a Merkel tree to recreate a white list.
     */
    function setWhitelistProof(bytes32 whitelistProofRoot_)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        whitelistProofRoot = whitelistProofRoot_;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    /**
     * @dev Checks if `claimant` is on a white list, specified by a Merkel tree.
     */
    function onWhitelist(
        address claimant,
        uint256 maxMintableTokens,
        bytes32[] memory proof
    ) internal view returns (bool) {
        if (whitelistProofRoot == 0x0) {
            return false;
        }
        bytes32 computedHash = keccak256(
            abi.encodePacked(claimant, maxMintableTokens)
        );
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            }
        }
        return computedHash == whitelistProofRoot;
    }

    function _mintCommon(uint256 numTokensToMint) internal {
        require(mintingAllowed, "Minting unallowed.");
        require(block.timestamp <= mintEndTime, "Minting closed.");
        for (uint256 i = 0; i < numTokensToMint; ++i) {
            _tokenIds.increment();
            uint256 newItemId = _tokenIds.current();
            require(newItemId <= maxSupply, "Can't mint that many NFTs.");

            super._safeMint(msg.sender, newItemId);
        }
    }
}